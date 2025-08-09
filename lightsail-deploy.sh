#!/usr/bin/env bash
set -e

DOCKER_COMPOSE_URL="https://raw.githubusercontent.com/talentscoutco/talent-scout-free-build/master/docker-compose.yml"

# Check Docker permission (exit if fails)
if ! docker info &>/dev/null; then
  echo "ERROR: Docker permission denied. Make sure you've logged out and back in after running the install script."
  exit 1
fi

echo "Downloading docker-compose.yml..."
curl -LfsS "$DOCKER_COMPOSE_URL" -o docker-compose.yml || {
  echo "Failed to download docker-compose.yml"
  exit 1
}

# [rest of your original deploy.sh prompts and .env setup here]

echo "Pulling Docker images..."
docker-compose pull

echo "Preparing storage directory..."
mkdir -p ./storage
chmod -R 755 ./storage
chown -R "$USER":"$USER" ./storage || true

echo "Starting application..."
docker-compose up -d

echo "✅ Deployment complete! Containers are starting..."
