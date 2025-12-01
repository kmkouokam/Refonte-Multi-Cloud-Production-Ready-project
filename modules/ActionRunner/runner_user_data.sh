#!/bin/bash


# Injected from Terraform
export REGION="${AWS_REGION}"
export ACCOUNT_ID="${ACCOUNT_ID}"

# -------------------------------
# Ensure ec2-user can write to home directory
# -------------------------------
EC2_HOME="/home/ec2-user"
sudo chown -R ec2-user:ec2-user "${EC2_HOME}"
sudo chmod -R u+rwX "${EC2_HOME}"



# GitHub runner token (from Terraform variable)
 GITHUB_RUNNER_TOKEN="${GITHUB_RUNNER_TOKEN}"
RUNNER_DIR="${EC2_HOME}/actions-runner"
RUNNER_WORK_DIR="${RUNNER_DIR}/_work"
RUNNER_LOG="${RUNNER_DIR}/runner.log"
DOCKER_HOME="${EC2_HOME}/.docker"

# -------------------------------
# Prepare runner directory
# -------------------------------
sudo -u ec2-user mkdir -p "${RUNNER_DIR}"
sudo chown -R ec2-user:ec2-user "${RUNNER_DIR}"
 
sudo chmod -R u+rwx "${RUNNER_DIR}"

# -------------------------------
# Make runner binaries executable
# -------------------------------
sudo chmod +x "${RUNNER_DIR}/bin/*"

# -------------------------------
# Prepare _diag folder
# -------------------------------
DIAG_DIR="/home/ec2-user/actions-runner/_diag"
sudo mkdir -p "${DIAG_DIR}"
sudo chown -R ec2-user:ec2-user "${DIAG_DIR}"
sudo chmod -R u+rwx "${DIAG_DIR}"

# Write GitHub runner token securely
sudo echo "${GITHUB_RUNNER_TOKEN}" | sudo tee /tmp/runner_token >/dev/null
sudo chmod 600 /tmp/runner_token

# Basic updates & tools
sudo yum update -y
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

# Clean up AWS CLI installer
sudo rm -rf awscliv2.zip aws

# Install kubectl (stable)
sudo curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo chmod +x kubectl
sudo mv kubectl /usr/local/bin

# Install eksctl
sudo curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
sudo mv /tmp/eksctl /usr/local/bin

 
# Prepare docker home for ec2-user
sudo -u ec2-user mkdir -p "${DOCKER_HOME}"
sudo chown -R ec2-user:ec2-user "${DOCKER_HOME}"
sudo chmod 700 "${DOCKER_HOME}"

# Login to ECR only if IAM role works
if aws sts get-caller-identity >/dev/null 2>&1; then
  echo "IAM role detected — logging in to ECR..."
  aws ecr get-login-password --region "${AWS_REGION}" \
    | docker login \
        --username AWS \
        --password-stdin "${ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
else
  echo "Warning: IAM role not available — ECR login skipped."
fi

# Install GitHub Actions Runner
sudo -u ec2-user mkdir -p "${RUNNER_DIR}"
sudo cd "${RUNNER_DIR}"

# -------------------------------
# Install GitHub Actions Runner
# -------------------------------
RUNNER_VERSION="2.329.0"
sudo -u ec2-user curl -o "${RUNNER_DIR}/actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz" -L \
  https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz

sudo -u ec2-user tar xzf "${RUNNER_DIR}/actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz" -C "${RUNNER_DIR}"

# Make runner binaries executable
sudo chown -R ec2-user:ec2-user "${RUNNER_DIR}"
sudo chmod +x "${RUNNER_DIR}/bin/*"

#Clean up tar file
sudo rm -f "${RUNNER_DIR}/actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz"


 


# -------------------------------
# Prepare _work folder inside runner
# -------------------------------
sudo -u ec2-user mkdir -p "${RUNNER_WORK_DIR}"
sudo chown -R ec2-user:ec2-user "${RUNNER_WORK_DIR}"
sudo chmod -R u+rwx ${RUNNER_WORK_DIR}


# Register runner (requires token stored in environment or a secure mechanism).
# IMPORTANT: inject the registration token into the instance via SSM parameter or other secure mechanism.
# Example below expects /tmp/runner_token to be written at deploy time (replace with your secure approach)

if [ -f /tmp/runner_token ]; then
  GITHUB_RUNNER_TOKEN="$(cat /tmp/runner_token)"
  sudo rm -f /tmp/runner_token

  # Configure runner as ec2-user
  sudo -u ec2-user "${RUNNER_DIR}/config.sh" --unattended \
    --url "https://github.com/kmkouokam/Refonte-Multi-Cloud-Production-Ready-project" \
    --token "${GITHUB_RUNNER_TOKEN}" \
    --labels "self-hosted,linux,vpc-runner" \
    --name "github-runner-1" \
    --work "${RUNNER_WORK_DIR}"

  # Start runner in background as ec2-user
  sudo -u ec2-user nohup "${RUNNER_DIR}/run.sh" > "${RUNNER_LOG}" 2>&1 &
fi


# Optional: create a systemd service to manage the runner (uncomment if desired)
# cat <<EOL >/etc/systemd/system/github-runner.service
# [Unit]
# Description=GitHub Actions Runner
# After=network.target
#
# [Service]
# Type=simple
# User=ec2-user
# WorkingDirectory=/home/ec2-user/actions-runner
# ExecStart=/home/ec2-user/actions-runner/run.sh
# Restart=always
#
# [Install]
# WantedBy=multi-user.target
# EOL
#
# systemctl daemon-reload
# systemctl enable github-runner
# systemctl start github-runner
