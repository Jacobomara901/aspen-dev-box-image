#!/bin/sh
set -eu

SELF_ID=$(cat /etc/hostname)
PROJECT=$(docker inspect --format '{{ index .Config.Labels "com.docker.compose.project"}}' "$SELF_ID")

ASPEN_CONTAINER=$(docker ps -q \
  --filter "label=com.docker.compose.project=$PROJECT" \
  --filter "label=com.docker.compose.service=aspen-dev-box" | head -n1)

EVERGREEN_CONTAINER=$(docker ps -q \
  --filter "label=com.docker.compose.project=${EVERGREEN_STACK:-egdev}" \
  --filter "label=com.docker.compose.service=evergreen" | head -n1)

if [ -z "$ASPEN_CONTAINER" ] || [ -z "$EVERGREEN_CONTAINER" ]; then
  echo "evergreen-import: could not locate containers (aspen=$ASPEN_CONTAINER evergreen=$EVERGREEN_CONTAINER)" >&2
  exit 1
fi

SITE=$(docker inspect --format '{{range .Config.Env}}{{println .}}{{end}}' "$ASPEN_CONTAINER" \
  | sed -n 's/^SITE_NAME=//p' | head -n1)

if [ -z "$SITE" ]; then
  echo "evergreen-import: aspen container has no SITE_NAME" >&2
  exit 1
fi

ILS_DIR="/data/aspen-discovery/$SITE/ils"

DEADLINE=$(($(date +%s) + 1200))

while [ "$(date +%s)" -lt "$DEADLINE" ]; do
  if docker exec "$EVERGREEN_CONTAINER" test -f /eg_ready 2>/dev/null; then
    break
  fi
  echo "evergreen-import: waiting for evergreen readiness..."
  sleep 10
done

if ! docker exec "$EVERGREEN_CONTAINER" test -f /eg_ready 2>/dev/null; then
  echo "evergreen-import: evergreen never signaled ready, aborting" >&2
  exit 1
fi

echo "evergreen-import: copying the export into $ILS_DIR"

EXPORT_TAR=$(mktemp)
docker exec "$EVERGREEN_CONTAINER" tar -C /exports/aspen -cf - . > "$EXPORT_TAR"
docker exec "$ASPEN_CONTAINER" mkdir -p "$ILS_DIR"
docker exec -i "$ASPEN_CONTAINER" tar -C "$ILS_DIR" -xf - < "$EXPORT_TAR"
rm -f "$EXPORT_TAR"

if ! docker exec "$ASPEN_CONTAINER" test -f "$ILS_DIR/marc/all_bibs.mrc"; then
  echo "evergreen-import: copy finished without marc/all_bibs.mrc" >&2
  exit 1
fi

docker exec "$ASPEN_CONTAINER" chown -R www-data:www-data "$ILS_DIR"

echo "evergreen-import: export copied, aspen indexes it on its next evergreen export run"
