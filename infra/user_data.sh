#!/bin/bash
# User Data Script - Runs on EC2 boot
# Installs Docker, pulls image from ECR, and runs container

set -e

# Update system
yum update -y

# Install Docker
yum install -y docker
systemctl enable docker
systemctl start docker

# Add ec2-user to docker group
usermod -aG docker ec2-user

# Install AWS CLI v2 (for ECR login)
yum install -y unzip
curl -s "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip -q awscliv2.zip
./aws/install
rm -rf aws awscliv2.zip

# Create deployment script (used by CI/CD)
cat > /opt/deploy.sh << 'DEPLOY_SCRIPT'
#!/bin/bash
set -e

AWS_REGION="${aws_region}"
ECR_REPO="${ecr_repo_url}"
APP_PORT="${app_port}"

echo "Logging into ECR..."
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_REPO

echo "Pulling latest image..."
docker pull $ECR_REPO:latest || docker pull $ECR_REPO:initial

echo "Stopping existing container..."
docker stop flask-app 2>/dev/null || true
docker rm flask-app 2>/dev/null || true

echo "Starting new container..."
docker run -d \
  --name flask-app \
  --restart unless-stopped \
  -p $APP_PORT:$APP_PORT \
  $ECR_REPO:latest || docker run -d \
  --name flask-app \
  --restart unless-stopped \
  -p $APP_PORT:$APP_PORT \
  $ECR_REPO:initial

echo "Container started successfully!"
docker ps
DEPLOY_SCRIPT

chmod +x /opt/deploy.sh

# Run initial deployment (will fail gracefully if no image yet)
echo "Attempting initial deployment..."
/opt/deploy.sh || echo "No image in ECR yet - container will start after first CI/CD push"
