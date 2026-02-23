#!/bin/bash
set -e

VERSION=${1:-latest}
IMAGE_NAME="kkday-b2d-internagent"

echo "Building Docker image: $IMAGE_NAME:$VERSION"
docker build -t $IMAGE_NAME:$VERSION .

if [ "$VERSION" != "latest" ]; then
    echo "Tagging $IMAGE_NAME:$VERSION as $IMAGE_NAME:latest"
    docker tag $IMAGE_NAME:$VERSION $IMAGE_NAME:latest
fi

echo "Build complete!"
echo "Images built:"
docker images | grep $IMAGE_NAME
