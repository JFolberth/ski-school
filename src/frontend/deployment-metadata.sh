#!/bin/sh
set -eu

image=${IMAGE_NAME:-}
deployed_at=${DEPLOYED_AT:-}

case "$image" in
  *[!a-zA-Z0-9._/@:-]*)
    echo "Invalid image name in deployment metadata." >&2
    exit 1
    ;;
esac
case "$deployed_at" in
  *[!0-9TZ:.-]*)
    echo "Invalid deployment timestamp in deployment metadata." >&2
    exit 1
    ;;
esac

printf '{"image":"%s","deployedAt":"%s"}\n' "$image" "$deployed_at" > /tmp/deployment.json
