#!/bin/bash
set -euo pipefail

UTILS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IMAGES_DIR="${WHANOS_IMAGES_DIR:-/images}"
REGISTRY="${WHANOS_REGISTRY:?WHANOS_REGISTRY must be set}"

cat << "EOF"
               ##         .
         ## ## ##        ==
      ## ## ## ## ##    ===
  /"""""""""""""""""\___/ ===
 ~~~ {~~ ~~~~ ~~~ ~~~~ ~~~ ~ /  ===- ~~~
      \______ o          __/
        \    \        __/
         \____\______/
EOF

language="$(bash "$UTILS_DIR/language_detector.sh")"
echo "Detected language: $language"

name="$(printf '%s' "${JOB_BASE_NAME:?}" | tr '[:upper:]' '[:lower:]' | sed -e 's/[^a-z0-9-]/-/g' -e 's/^-*//' -e 's/-*$//')"
image="$REGISTRY/$name"
tag="build-${BUILD_NUMBER:?}"

if [ -f Dockerfile ]; then
    echo "Custom Dockerfile found: building on top of whanos-$language"
    if ! docker image inspect "whanos-$language" > /dev/null 2>&1; then
        docker build -t "whanos-$language" - < "$IMAGES_DIR/$language/Dockerfile.base"
    fi
    docker build -t "$image:$tag" -t "$image:latest" .
else
    echo "No Dockerfile found: using the whanos-$language standalone image"
    docker build -t "$image:$tag" -t "$image:latest" -f "$IMAGES_DIR/$language/Dockerfile.standalone" .
fi

docker push "$image:$tag"
docker push "$image:latest"

if [ -f whanos.yml ]; then
    python3 "$UTILS_DIR/whanos_deploy.py" whanos.yml "$name" "$image:$tag"
else
    echo "No whanos.yml found: skipping deployment"
fi
