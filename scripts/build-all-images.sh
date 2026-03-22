#!/bin/bash
set -euo pipefail

# ============================================================================
# Build and push all Epsilon Docker images (multi-arch: amd64 + arm64)
# ============================================================================

GITHUB_ORG="epsilon-data"
GHCR="ghcr.io/${GITHUB_ORG}"
TAG="${1:-latest}"

# Image → build context mapping
declare -A IMAGES
IMAGES=(
  ["api"]="../../api"
  ["frontend"]="../../frontend"
  ["job-scheduler"]="../ResearchWorkspace"
  ["coordinator"]="../epsilon-cordinator"
  ["epsilon-trust-center"]="../epsilon-trust-center"
  ["epsilon-middleware"]="/Users/nizzle1994/PycharmProjects/epsilon/middleware"
)

# Special Dockerfiles (if different from default)
declare -A DOCKERFILES
DOCKERFILES=(
  ["epsilon-middleware"]="/Users/nizzle1994/Developments/WebStorm/Epsilon/epsilon/images/middleware/Dockerfile.local"
)

# Build args
declare -A BUILD_ARGS
BUILD_ARGS=(
  ["api"]="--build-arg GITHUB_NPM_TOKEN=${GITHUB_NPM_TOKEN:-}"
  ["frontend"]="--build-arg GITHUB_NPM_TOKEN=${GITHUB_NPM_TOKEN:-} --build-arg VITE_EPSILON_API_PREFIX=/api/v1 --build-arg VITE_EPSILON_COOKIE_PREFIX=epsilon --build-arg VITE_EPSILON_BASE_URL=http://localhost:3000"
  ["coordinator"]="--build-arg GITHUB_TOKEN=${GITHUB_TOKEN:-}"
  ["job-scheduler"]="--build-arg VITE_TRUST_CENTER_URL=http://localhost:3001"
)

echo "============================================"
echo "Epsilon Multi-Arch Image Builder"
echo "Tag: ${TAG}"
echo "Registry: ${GHCR}"
echo "============================================"

# Setup buildx
echo ""
echo "Setting up Docker buildx..."
docker buildx create --name epsilon-multiarch --use 2>/dev/null || docker buildx use epsilon-multiarch

# Login
echo "Logging in to GHCR..."
echo "${GITHUB_TOKEN}" | docker login ghcr.io -u "${GITHUB_USERNAME:-$(git config user.name)}" --password-stdin

# Build each image
for IMAGE in "${!IMAGES[@]}"; do
  CONTEXT="${IMAGES[$IMAGE]}"
  DOCKERFILE_ARG=""
  EXTRA_ARGS="${BUILD_ARGS[$IMAGE]:-}"

  if [[ -n "${DOCKERFILES[$IMAGE]:-}" ]]; then
    DOCKERFILE_ARG="-f ${DOCKERFILES[$IMAGE]}"
  fi

  echo ""
  echo "============================================"
  echo "Building: ${IMAGE} (${CONTEXT})"
  echo "============================================"

  docker buildx build \
    --platform linux/amd64,linux/arm64 \
    -t "${GHCR}/${IMAGE}:${TAG}" \
    -t "${GHCR}/${IMAGE}:latest" \
    ${DOCKERFILE_ARG} \
    ${EXTRA_ARGS} \
    --push \
    "${CONTEXT}"

  echo "✅ ${IMAGE} pushed"
done

echo ""
echo "============================================"
echo "All images pushed successfully!"
echo "============================================"
echo ""
for IMAGE in "${!IMAGES[@]}"; do
  echo "  ${GHCR}/${IMAGE}:${TAG}"
done
