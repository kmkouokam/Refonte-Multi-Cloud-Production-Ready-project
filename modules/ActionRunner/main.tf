resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"] # GitHub thumbprint
}


# ------------------------------
# IAM Role for EC2 and GitHub Actions to access EKS
# ------------------------------
resource "aws_iam_role" "github_runner_role" {
  name = "github-actions-runner-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      },
      {
        Effect = "Allow",
        Principal = {
          Federated = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/token.actions.githubusercontent.com"
        },
        Action = "sts:AssumeRoleWithWebIdentity",
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:sub" = "repo:kmkouokam/Refonte-Multi-Cloud-Production-Ready-project:ref:refs/heads/main"
          }
        }
      }
    ]
  })
}

# ECR & EKS policy for the role
resource "aws_iam_role_policy" "github_runner_ecr_policy" {
  name = "github-runner-ecr-policy"
  role = aws_iam_role.github_runner_role.name

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid = "ECRAccess"
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:PutImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:ListImages"
        ]
        Resource = "*"
      },
      {
        Sid = "EKSDescribeAndList"
        Effect = "Allow"
        Action = [
          "eks:DescribeCluster",
          "eks:DescribeNodegroup",
          "eks:ListClusters",
          "eks:ListNodegroups"
        ]
        Resource = "*"
      },
      {
        Sid = "STSGetCaller"
        Effect = "Allow"
        Action = [
          "sts:GetCallerIdentity"
        ]
        Resource = "*"
      }
    ]
  })
}


# ------------------------------
# Policy to allow runner role to assume the cluster role
# ------------------------------
resource "aws_iam_policy" "github_runner_assume_cluster_role" {
  name        = "github-runner-assume-cluster-role"
  description = "Allow EC2/GitHub runner to assume EKS cluster role"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = ["sts:AssumeRole"],
        Resource = "arn:aws:iam::435329769674:role/multi-cloud-cluster-eks-cluster-role"
      }
    ]
  })
}

# Attach AWS-managed policies
resource "aws_iam_role_policy_attachment" "eks_access" {
  role       = aws_iam_role.github_runner_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "ecr_read" {
  role       = aws_iam_role.github_runner_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
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

resource "aws_iam_role_policy_attachment" "attach_assume_cluster_role" {
  role       = aws_iam_role.github_runner_role.name
  policy_arn = aws_iam_policy.github_runner_assume_cluster_role.arn
}


 


# Needed to get account ID dynamically
data "aws_caller_identity" "current" {}


 

 
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
  ami                    = data.aws_ami.amazon_linux.id # e.g., Amazon Linux 2023
  instance_type          = "t3.medium"
  subnet_id              = var.aws_public_subnet_ids[0]
  iam_instance_profile   = aws_iam_instance_profile.runner_instance_profile.name
  vpc_security_group_ids = [aws_security_group.runner_sg.id]
  key_name               = var.ssh_key # optional, for SSH

  user_data = <<EOF
  #!/bin/bash
  set -e

  # Update system
  sudo yum update -y
  # sudo yum install -y ca-certificates
  # sudo update-ca-trust force-enable
  # sudo update-ca-trust extract

  # Install required tools
  sudo yum install -y git unzip jq curl tar docker --allowerasing 
  sudo yum install -y libicu libicu-devel
  sudo yum install -y icu

  # Start Docker
  sudo systemctl enable docker
  sudo systemctl start docker
  sudo usermod -aG docker ec2-user

  # Install AWS CLI v2
  sudo curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
  sudo unzip awscliv2.zip
  sudo ./aws/install

  # Install kubectl
  curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
  chmod +x kubectl
  sudo mv kubectl /usr/local/bin

  # Install eksctl
  curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
   sudo mv /tmp/eksctl /usr/local/bin


  
  # -----------------------------
  # Wait for EKS cluster to be ACTIVE
   # -----------------------------
  CLUSTER_NAME="multi-cloud-cluster"
  # REGION="us-east-1"
  # while true; do
  #   STATUS=$(aws eks describe-cluster --name $CLUSTER_NAME --region $REGION --query "cluster.status" --output text)
  #   echo "Cluster status: $STATUS"
  #   if [ "$STATUS" == "ACTIVE" ]; then
  #       break
  #   fi
  #   sleep 15
  # done

  # Configure kubeconfig for EKS
  aws eks update-kubeconfig --name ${var.eks_cluster_name} --region ${var.aws_region}
   
  # Install Amazon ECR Credential Helper
    # sudo yum install -y amazon-ecr-credential-helper


  # -----------------------------
  # Docker / ECR setup
  # -----------------------------
  
   sudo mkdir -p /home/ec2-user/.docker
   sudo chown -R ec2-user:ec2-user /home/ec2-user/.docker
   sudo chmod 700 /home/ec2-user/.docker
   
   aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin 435329769674.dkr.ecr.$REGION.amazonaws.com

   
  #  #attach your EC2 IAM role to cluster-admin via eksctl
  #  eksctl create iamidentitymapping \
  # --cluster multi-cloud-cluster \
  # --arn arn:aws:iam::435329769674:role/multi-cloud-cluster-eks-cluster-role \
  # --group system:masters \
  #  --region us-east-1 \
  # --username admin


  #or 
  # aws sts assume-role \
  # --role-arn arn:aws:iam::435329769674:role/multi-cloud-cluster-eks-cluster-role \
  # --role-session-name eks-admin-session


  #add your EC2 role as an EKS admin
  # aws eks create-access-entry \
  # --cluster-name multi-cloud-cluster \
  # --principal-arn arn:aws:iam::435329769674:role/github-actions-runner-role \
  # --kubernetes-groups system:masters \
  # --region us-east-1

  #Then associate a default access policy:
  aws eks associate-access-policy \
  --cluster-name multi-cloud-cluster \
  # --principal-arn arn:aws:iam::435329769674:role/github-actions-runner-role \
  # --policy-arn arn:aws:eks::aws:cluster-admin-policy \
  # --region us-east-1


  #  cat > /home/ec2-user/.docker/config.json <<JSON
  #  {
  #    "auths": {}
  #  }
  #  JSON
   
  # -----------------------------
  # Wait until aws-auth ConfigMap exists
  # -----------------------------
  # This assumes aws-auth was applied manually by admin
  # Skip if already applied
  until kubectl get configmap aws-auth -n kube-system > /dev/null 2>&1; do
    echo "Waiting for aws-auth configmap..."
    sleep 10
  done

  # -----------------------------
  # ECR Login
  # -----------------------------
   

  sudo  mkdir -p /home/ec2-user/.ecr
  sudo chown -R ec2-user:ec2-user /home/ec2-user/.ecr
  sudo chmod 700 /home/ec2-user/.ecr


  aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin 435329769674.dkr.ecr.us-east-1.amazonaws.com

  
   

  # Install GitHub Actions Runner
  sudo mkdir actions-runner
  sudo cd actions-runner

   # Download and extract runner
  sudo curl -o actions-runner-linux-x64-2.329.0.tar.gz -L https://github.com/actions/runner/releases/download/v2.329.0/actions-runner-linux-x64-2.329.0.tar.gz
  sudo tar xzf ./actions-runner-linux-x64-2.329.0.tar.gz

   sudo chown -R ec2-user:ec2-user ./actions-runner
   sudo chmod -R u+rwx ./actions-runner
   chmod +x ./bin/*
   
   # to set _diag folder
   sudo mkdir -p /home/ec2-user/_diag
   sudo chown -R ec2-user:ec2-user ./_diag
   sudo  chmod -R u+rwx ./_diag
   # Make sure ec2-user owns all runner files
    sudo chown -R ec2-user:ec2-user .
    # Make runner binaries executable
    chmod +x ./bin/*


   #to set _work folder 
   sudo mkdir -p ./actions-runner/_work
   sudo chown -R ec2-user:ec2-user ./actions-runner/_work
   sudo chmod -R u+rwx ./actions-runner/_work

   # Ensure runner binaries are executable
   sudo chmod +x ./actions-runner

  #Ensure ec2-user can write to its home
  sudo chown -R ec2-user:ec2-user /home/ec2-user
  chmod -R u+rwX /home/ec2-user


  # Register runner (replace with actual token)
  ./config.sh --unattended \
    --url https://github.com/kmkouokam/Refonte-Multi-Cloud-Production-Ready-project \
    --token ${var.github_runner_token} \
    --labels self-hosted,linux,vpc-runner \
    --name github-runner-1 \
    --work _work

  #
   nohup ./run.sh > runner.log 2>&1 &


  # Create systemd service
  # cat <<EOL >/etc/systemd/system/github-runner.service
  # [Unit]
  # Description=GitHub Actions Runner
  # After=network.target

  # [Service]
  # Type=simple
  # User=ec2-user
  # WorkingDirectory=%h/actions-runner
  # ExecStart=./run.sh
  # Environment=DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=1
  # Restart=always

  # [Install]
  # WantedBy=multi-user.target
  # EOL

  # Start the service
  sudo systemctl daemon-reload
  sudo systemctl enable github-runner
  sudo systemctl start github-runner
  EOF

  tags = {
    Name = "GitHubActionsRunner"
  }
}
