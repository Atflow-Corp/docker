#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
IMAGE_NAME="python_docker"
BUILDX_BUILDER="${BUILDX_BUILDER:-atflow-multiarch}"

if (($#)); then
  versions=("$@")
else
  read -r -a versions <<< "${PYTHON_VERSIONS:-3.13 3.14 3.15}"
fi

for version in "${versions[@]}"; do
  case "$version" in
    3.13|3.14|3.15) ;;
    *) echo "Unsupported Python version: $version. Use 3.13, 3.14 or 3.15." >&2; exit 1 ;;
  esac
done

ensure_builder() {
  if ! docker buildx inspect "$BUILDX_BUILDER" >/dev/null 2>&1; then
    docker buildx create --name "$BUILDX_BUILDER" --driver docker-container >/dev/null
  fi

  docker buildx inspect --bootstrap "$BUILDX_BUILDER" >/dev/null
}

# CR_USER: github user id
# CR_PAT: https://docs.github.com/en/free-pro-team@latest/packages/managing-container-images-with-github-container-registry/pushing-and-pulling-docker-images#authenticating-to-github-container-registry
if [[ ${CR_USER:-} ]] && [[ ${CR_PAT:-} ]]
then
  echo "$CR_PAT" | docker login ghcr.io -u "$CR_USER" --password-stdin
  ensure_builder
else
  echo "CR_USER, CR_PAT environment variables not set; images will be built but not pushed."
fi

for version in "${versions[@]}"; do
  name_tag="${IMAGE_NAME}:${version}"
  local_tag="atflow-corp/${name_tag}"
  remote_tag="ghcr.io/atflow-corp/docker/${name_tag}"
  python_variant="${PYTHON_VARIANT:-bookworm}"
  platforms="${PLATFORM:-linux/amd64,linux/arm64}"

  echo "Building $name_tag from python:${version}-${python_variant} for $platforms"

  if [[ ${CR_USER:-} ]] && [[ ${CR_PAT:-} ]]
  then
    docker buildx build \
      --builder "$BUILDX_BUILDER" \
      --pull \
      --no-cache \
      --platform "$platforms" \
      --build-arg "PYTHON_VERSION=$version" \
      --build-arg "PYTHON_VARIANT=$python_variant" \
      --push \
      -t "$remote_tag" \
      "$SCRIPT_DIR"
  else
    IFS=',' read -r -a platform_list <<< "$platforms"

    for platform in "${platform_list[@]}"; do
      platform_tag="$local_tag"
      if [[ "$platform" != "linux/amd64" ]]; then
        platform_tag="${local_tag}-${platform//\//-}"
      fi

      docker buildx build \
        --pull \
        --no-cache \
        --platform "$platform" \
        --build-arg "PYTHON_VERSION=$version" \
        --build-arg "PYTHON_VARIANT=$python_variant" \
        --load \
        -t "$platform_tag" \
        "$SCRIPT_DIR"
    done
  fi
done
