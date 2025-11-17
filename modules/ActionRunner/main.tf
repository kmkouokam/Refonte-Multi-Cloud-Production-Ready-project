 

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

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y git docker unzip jq curl
              systemctl enable docker
              systemctl start docker
              usermod -aG docker ec2-user

              # Install AWS CLI v2
              curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
              unzip awscliv2.zip
              sudo ./aws/install


              # Install kubectl
              curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
              chmod +x kubectl
              mv kubectl /usr/local/bin/

              # Configure kubeconfig for EKS
              aws eks update-kubeconfig --name ${var.eks_cluster_name} --region ${var.aws_region}

              # Install GitHub Actions Runner
              mkdir /home/ec2-user/actions-runner && cd /home/ec2-user/actions-runner
              curl -o actions-runner-linux-x64-2.329.0.tar.gz -L https://github.com/actions/runner/releases/download/v2.329.0/actions-runner-linux-x64-2.329.0.tar.gz
              echo "194f1e1e4bd02f80b7e9633fc546084d8d4e19f3928a324d512ea53430102e1d  actions-runner-linux-x64-2.329.0.tar.gz" | shasum -a 256 -c
              # Extract the installer
              tar xzf ./actions-runner-linux-x64-2.329.0.tar.gz

              # Create the runner and start the configuration experience
              # TODO: replace with your repo URL and token

              sudo -u ec2-user ./config.sh --url https://github.com/kmkouokam/Refonte-Multi-Cloud-Production-Ready-project --token AWPCBF7HIBVNRSWMXBGSNY3JDNQ3I
              sudo -u ec2-user ./svc.sh install
              sudo -u ec2-user ./svc.sh start
              EOF

  tags = {
    Name = "GitHubActionsRunner"
  }
}
