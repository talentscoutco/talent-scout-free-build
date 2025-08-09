#!/usr/bin/env bash
set -e

DOCKER_COMPOSE_URL="https://raw.githubusercontent.com/talentscoutco/talent-scout-free-build/master/docker-compose.yml"

echo "=== Step 1: Updating system packages ==="
sudo dnf upgrade -y

echo "=== Step 2: Installing Docker ==="
if ! command -v docker &>/dev/null; then
  sudo dnf install -y docker
  sudo systemctl enable docker
  sudo systemctl start docker
else
  echo "Docker already installed."
fi

echo "=== Step 3: Installing Docker Compose ==="
if ! command -v docker-compose &>/dev/null; then
  sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" \
    -o /usr/local/bin/docker-compose
  sudo chmod +x /usr/local/bin/docker-compose
else
  echo "Docker Compose already installed."
fi

echo "=== Step 4: Adding current user to docker group ==="
sudo usermod -aG docker $USER
newgrp docker || true

# Check Docker permission
if ! docker info &>/dev/null; then
  echo "ERROR: Current user doesn't have permission to run Docker."
  echo "Please re-login and run this script again."
  exit 1
fi

echo "=== Step 5: Downloading docker-compose.yml ==="
curl -LfsS "$DOCKER_COMPOSE_URL" -o docker-compose.yml || {
  echo "Failed to download docker-compose.yml"
  exit 1
}

# Ask for License Key (mandatory)
read -p "Enter your License Key: " LICENSE_KEY
if [[ -z "$LICENSE_KEY" ]]; then
  echo "Error: License Key is required."
  exit 1
fi

# Ask for OpenAI Key (optional)
read -p "Enter your OpenAI API Key (or press Enter to skip): " OPENAI_KEY

# Check if Mongo port is free
if lsof -i :27017 &>/dev/null; then
  echo "ERROR: Port 27017 is already in use. Please free it or update the docker-compose.yml to use a different port."
  exit 1
fi

# AWS S3 configuration (optional)
read -p "Use AWS S3 for storage? (y/N): " use_s3
use_s3=${use_s3:-n}
if [[ "$use_s3" =~ ^[Yy]$ ]]; then
  read -p "AWS S3 Bucket Name: " AWS_CV_BUCKET_NAME
  read -p "AWS Access Key ID: " AWS_ACCESS_KEY
  read -p "AWS Secret Access Key: " AWS_SECRET_KEY
  STORAGE_PROVIDER="awsS3"
else
  AWS_CV_BUCKET_NAME=""
  AWS_ACCESS_KEY=""
  AWS_SECRET_KEY=""
  STORAGE_PROVIDER="local"
fi

# Generate JWT secret (32-byte hex)
JWT_SECRET=$(openssl rand -hex 32)
echo "Generated JWT_SECRET."

# Create .env file for Docker Compose
cat > .env <<EOF
SPRING_DATA_MONGODB_URI=mongodb://mongo:27017/skillsource
SPRING_DATA_MONGODB_DATABASE=skillsource
LICENSE_KEY=${LICENSE_KEY}
OPENAI_KEY=${OPENAI_KEY}
AWS_ACCESS_KEY=${AWS_ACCESS_KEY}
AWS_SECRET_KEY=${AWS_SECRET_KEY}
AWS_CV_BUCKET_NAME=${AWS_CV_BUCKET_NAME}
JWT_SECRET=${JWT_SECRET}
STORAGE_PROVIDER=${STORAGE_PROVIDER}
EOF

echo "=== Step 6: Pulling Docker images ==="
docker-compose pull

echo "=== Step 7: Preparing storage directory ==="
mkdir -p ./storage
chmod -R 755 ./storage
chown -R "$USER":"$USER" ./storage || true

echo "=== Step 8: Starting application ==="
docker-compose up -d

echo "✅ Deployment complete! Containers are starting..."
