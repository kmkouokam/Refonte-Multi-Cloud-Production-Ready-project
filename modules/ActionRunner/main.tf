 
 
# ------------------------------
# IAM Role for EC2 to access EKS
# ------------------------------
resource "aws_iam_role" "github_runner_role" {
  name = "github-actions-runner-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}


resource "aws_iam_role_policy" "github_runner_ecr_policy" {
  name = "github-runner-ecr-policy"
  role = aws_iam_role.github_runner_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:PutImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload"
        ],
        Resource = "*"
      }
    ]
  })
}



resource "aws_iam_role_policy_attachment" "eks_access" {
  role       = aws_iam_role.github_runner_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "eks_cni" {
  role       = aws_iam_role.github_runner_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "eks_full" {
  role       = aws_iam_role.github_runner_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_instance_profile" "runner_instance_profile" {
  name = "github-runner-instance-profile"
  role = aws_iam_role.github_runner_role.name
}

# ------------------------------
# Security Group
# ------------------------------
resource "aws_security_group" "runner_sg" {
  name        = "github-runner-sg"
  description = "Allow outbound traffic to EKS cluster"
  vpc_id      = var.aws_vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # must be edited to your IP
  }
}

# Get latest Amazon Linux 2023 AMI via SSM
data "aws_ssm_parameter" "amazon_linux_ami" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

# Look up the AMI by ID
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "image-id"
    values = [data.aws_ssm_parameter.amazon_linux_ami.value]
  }
}

# ------------------------------
# EC2 Instance (Self-Hosted Runner)
# ------------------------------
resource "aws_instance" "github_runner" {
  ami                  = data.aws_ami.amazon_linux.id # e.g., Amazon Linux 2023
  instance_type        = "t3.medium"
  subnet_id            = var.aws_public_subnet_ids[0]
  iam_instance_profile = aws_iam_instance_profile.runner_instance_profile.name
  vpc_security_group_ids     = [aws_security_group.runner_sg.id]
  key_name             = var.ssh_key # optional, for SSH

  user_data = <<EOF
  #!/bin/bash
  set -e

  # Update system
  sudo dnf update -y

  # Install required tools
  sudo dnf install -y git unzip jq curl tar docker  
  sudo dnf install -y libicu libicu-devel
  sudo dnf install -y icu

  # Start Docker
  sudo systemctl enable docker
  sudo systemctl start docker
  sudo usermod -aG docker ec2-user

  # Install AWS CLI v2
  sudo curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
  sudo unzip awscliv2.zip
  sudo ./aws/install

  # Install kubectl
  sudo curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
  sudo chmod +x kubectl
  sudo mv kubectl /usr/local/bin/

  # Configure kubeconfig for EKS
   aws eks update-kubeconfig --name ${var.eks_cluster_name} --region ${var.aws_region}
   sudo yum install -y amazon-ecr-credential-helper
   sudo mkdir -p /home/ec2-user/.docker
   sudo chown -R ec2-user:ec2-user /home/ec2-user/.docker
   sudo chmod 700 /home/ec2-user/.docker
   cat > /home/ec2-user/.docker/config.json <<JSON
   {
    "credsStore": "ecr-login"
   }
   JSON
   


  sudo  mkdir -p /home/ec2-user/.ecr
  sudo chown -R ec2-user:ec2-user /home/ec2-user/.ecr
  sudo chmod 700 /home/ec2-user/.ecr


  aws ecr get-login-password --region $AWS_REGION | \
  docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com


  # Install GitHub Actions Runner
  sudo mkdir actions-runner
  sudo cd actions-runner

  sudo curl -o actions-runner-linux-x64-2.329.0.tar.gz -L https://github.com/actions/runner/releases/download/v2.329.0/actions-runner-linux-x64-2.329.0.tar.gz
  sudo tar xzf ./actions-runner-linux-x64-2.329.0.tar.gz

  sudo chown -R ec2-user:ec2-user .

  sudo chmod -R u+rwx ../actions-runner

  # Register runner (replace with actual token)
  ./config.sh --unattended \
    --url https://github.com/kmkouokam/Refonte-Multi-Cloud-Production-Ready-project \
    --token ${var.github_runner_token} \
    --labels self-hosted,linux,vpc-runner \
    --name github-runner-1 \
    --work _work

  # sudo ./run.sh

  # Create systemd service
  cat <<EOL >/etc/systemd/system/github-runner.service
  [Unit]
  Description=GitHub Actions Runner
  After=network.target

  [Service]
  Type=simple
  User=ec2-user
  WorkingDirectory=%h/actions-runner
  ExecStart=./run.sh
  Environment=DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=1
  Restart=always

  [Install]
  WantedBy=multi-user.target
  EOL

  # Start the service
  sudo systemctl daemon-reload
  sudo systemctl enable github-runner
  sudo systemctl start github-runner
  EOF

    tags = {
      Name = "GitHubActionsRunner"
    }
  }
