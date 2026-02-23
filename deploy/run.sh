#!/bin/bash
set -e

VERSION=${1:-latest}
IMAGE_NAME="kkday-b2d-internagent"
CONTAINER_NAME="kkday-b2d"

# Check if .env.production exists
if [ ! -f ".env.production" ]; then
    echo "Error: .env.production file not found!"
    echo "Please create .env.production with your production configuration."
    exit 1
fi

# Stop and remove existing container if it exists
if [ "$(docker ps -aq -f name=$CONTAINER_NAME)" ]; then
    echo "Stopping existing container..."
    docker stop $CONTAINER_NAME 2>/dev/null || true
    docker rm $CONTAINER_NAME 2>/dev/null || true
fi

echo "Starting container: $CONTAINER_NAME"
docker run -d \
  --name $CONTAINER_NAME \
  --restart unless-stopped \
  -p 5000:80 \
  --env-file .env.production \
  --health-cmd="curl -f http://localhost/health/live || exit 1" \
  --health-interval=30s \
  --health-timeout=10s \
  --health-retries=3 \
  --health-start-period=40s \
  $IMAGE_NAME:$VERSION

echo "Container started!"
echo "View logs: docker logs -f $CONTAINER_NAME"
echo "Check health: docker inspect --format='{{.State.Health.Status}}' $CONTAINER_NAME"
