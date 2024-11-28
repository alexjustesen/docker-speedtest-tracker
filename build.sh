#!/bin/bash

# Set default tag
TAG="speedtest-tracker-docker"

# Determine the release tag
RELEASE_TAG=${1:-current}

# Build the Docker image with dynamic tagging
docker buildx build \
    --build-arg RELEASE_TAG=${RELEASE_TAG} \
    -t ${TAG}:${RELEASE_TAG} \
    .

echo "Image built and tagged as ${TAG}:${RELEASE_TAG}"
