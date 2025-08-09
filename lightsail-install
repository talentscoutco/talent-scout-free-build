#!/usr/bin/env bash
set -e

echo "=== Updating system packages ==="
sudo dnf upgrade -y

echo "=== Installing Docker ==="
if ! command -v docker &>/dev/null; then
  sudo dnf install -y docker
  sudo systemctl enable docker
  sudo systemctl start docker
else
  echo "Docker already installed."
fi

echo "=== Installing Docker Compose ==="
if ! command -v docker-compose &>/dev/null; then
  sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" \
    -o /usr/local/bin/docker-compose
  sudo chmod +x /usr/local/bin/docker-compose
else
  echo "Docker Compose already installed."
fi

echo "=== Adding current user to docker group ==="
sudo usermod -aG docker $USER

echo "=== Docker and Docker Compose installation complete ==="
echo "IMPORTANT: Please log out and log back in to apply Docker permissions."
echo "Then run your deploy script to start the application."
