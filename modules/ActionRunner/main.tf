# resource "aws_iam_openid_connect_provider" "github" {
#   url             = "https://token.actions.githubusercontent.com"
#   client_id_list  = ["sts.amazonaws.com"]
#   thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"] # GitHub thumbprint
# }


# ------------------------------
# Needed to get account ID dynamically
# ------------------------------
data "aws_caller_identity" "current" {}

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
      # {
        # Effect = "Allow",
        # Principal = {
        #   Federated = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/token.actions.githubusercontent.com"
        # },
        # Action = "sts:AssumeRoleWithWebIdentity",
        # Condition = {
        #   StringEquals = {
        #     "token.actions.githubusercontent.com:sub" = "repo:kmkouokam/Refonte-Multi-Cloud-Production-Ready-project:ref:refs/heads/main"
        #   }
        # }
      # }
    ]
  })
}

# policy granting required ECR/EKS basics and STS GetCallerIdentity
resource "aws_iam_role_policy" "github_runner_ecr_policy" {
  name = "github-runner-ecr-policy"
  role = aws_iam_role.github_runner_role.name

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid: "ECRAccess",
        Effect: "Allow",
        Action: [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:PutImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:ListImages"
        ],
        Resource: "*"
      },
      {
        Sid: "EKSDescribe",
        Effect: "Allow",
        Action: [
          "eks:DescribeCluster",
          "eks:ListClusters",
          "eks:AccessKubernetesApi",
          "eks:DescribeClusterVersions",
          "eks:DescribeNodegroup",
          "eks:ListNodegroups"

        ],
        Resource: "*"
      },
      {
        Sid: "STSAssume",
        Effect: "Allow",
        Action: [
          "sts:AssumeRole",
          "sts:AssumeRoleWithWebIdentity"
        ],
        Resource: "*"
      },
      {
        Sid: "STSCaller",
        Effect: "Allow",
        Action: [
          "sts:GetCallerIdentity"
        ],
        Resource: "*"
      },
      {
        Sid: "EC2Ops",
        Effect: "Allow",
        Action: [
          "ec2:AssociateIamInstanceProfile",
          "ec2:DescribeInstances",
          "iam:PassRole"
        ],
        Resource: "*"
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
        Resource = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/multi-cloud-cluster-eks-cluster-role"
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
  depends_on = [ aws_iam_policy.github_runner_assume_cluster_role ]
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
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.runner_instance_type
  subnet_id              = var.aws_public_subnet_ids[0]
  iam_instance_profile   = aws_iam_instance_profile.runner_instance_profile.name
  vpc_security_group_ids = [aws_security_group.runner_sg.id]
  key_name               = var.ssh_key

  tags = {
    Name = "GitHubActionsRunner"
  }

  user_data = templatefile("${path.module}/runner_user_data.sh", {
    AWS_REGION           = var.aws_region
    ACCOUNT_ID           = data.aws_caller_identity.current.account_id
    GITHUB_RUNNER_TOKEN  = var.github_runner_token
    EC2_HOME            = "/home/ec2-user" 
    RUNNER_DIR          = "/home/ec2-user/actions-runner"
    DIAG_DIR            = "/home/ec2-user/actions-runner/_diag" 
    DOCKER_HOME = "/home/ec2-user/.docker"
    RUNNER_VERSION = "2.329.0" 
    RUNNER_WORK_DIR = "/home/ec2-user/actions-runner/_work"
    RUNNER_LOG = "/home/ec2-user/actions-runner/_diag/runner.log"
  })
}
