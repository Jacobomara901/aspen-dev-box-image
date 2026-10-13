#!/bin/sh
set -eu

INTERVAL=${EVERGREEN_SYNC_INTERVAL:-120}
SUPPLEMENTAL_EVERY=3600
HEARTBEAT_EVERY=1800

SELF_ID=$(cat /etc/hostname)
PROJECT=$(docker inspect --format '{{ index .Config.Labels "com.docker.compose.project"}}' "$SELF_ID")
EVERGREEN_PROJECT=${EVERGREEN_STACK:-egdev}

SEEN=""
STARTED=0
SUPPLEMENTAL_AT=0
HEARTBEAT_AT=0
ASPEN_CONTAINER=""
EVERGREEN_CONTAINER=""
ILS_DIR=""

container_id() {
  docker ps -q \
    --filter "label=com.docker.compose.project=$1" \
    --filter "label=com.docker.compose.service=$2" | head -n1
}

heartbeat() {
  NOW=$(date +%s)
  if [ $((NOW - HEARTBEAT_AT)) -lt "$HEARTBEAT_EVERY" ]; then
    return 0
  fi
  HEARTBEAT_AT=$NOW
  echo "evergreen-sync: $1"
}

exclude() {
  if [ -z "$2" ]; then
    echo "$1"
    return 0
  fi
  echo "$1" | grep -vxF "$2" || true
}

remember() {
  if [ -z "$SEEN" ]; then
    SEEN=$1
    return 0
  fi
  SEEN=$(printf '%s\n%s' "$SEEN" "$1")
}

listing() {
  docker exec "$EVERGREEN_CONTAINER" sh -c "ls -1 '/exports/$1' 2>/dev/null" || true
}

copy_file() {
  SRC="/exports/$1"
  DEST="$ILS_DIR/$1"
  PART="$DEST.part"

  if ! docker exec "$EVERGREEN_CONTAINER" cat "$SRC" \
    | docker exec -i "$ASPEN_CONTAINER" sh -c "cat > '$PART'"; then
    docker exec "$ASPEN_CONTAINER" rm -f "$PART"
    echo "evergreen-sync: failed to copy $1" >&2
    return 1
  fi

  SRC_SIZE=$(docker exec "$EVERGREEN_CONTAINER" stat -c %s "$SRC" 2>/dev/null || true)
  DEST_SIZE=$(docker exec "$ASPEN_CONTAINER" stat -c %s "$PART" 2>/dev/null || true)

  if [ -z "$SRC_SIZE" ] || [ "$SRC_SIZE" != "$DEST_SIZE" ]; then
    docker exec "$ASPEN_CONTAINER" rm -f "$PART"
    echo "evergreen-sync: short copy of $1, will retry" >&2
    return 1
  fi

  docker exec "$ASPEN_CONTAINER" mv "$PART" "$DEST"
  docker exec "$ASPEN_CONTAINER" chown www-data:www-data "$DEST"
  echo "evergreen-sync: copied $1"
}

copy_supplemental() {
  NOW=$(date +%s)
  if [ $((NOW - SUPPLEMENTAL_AT)) -lt "$SUPPLEMENTAL_EVERY" ]; then
    return 0
  fi
  SUPPLEMENTAL_AT=$NOW
  for NAME in $(listing supplemental | grep '\.csv$' || true); do
    copy_file "supplemental/$NAME" || true
  done
}

sync_pass() {
  ASPEN_CONTAINER=$(container_id "$PROJECT" aspen-dev-box)
  EVERGREEN_CONTAINER=$(container_id "$EVERGREEN_PROJECT" evergreen)

  if [ -z "$ASPEN_CONTAINER" ] || [ -z "$EVERGREEN_CONTAINER" ]; then
    heartbeat "waiting for containers (aspen=${ASPEN_CONTAINER:-none} evergreen=${EVERGREEN_CONTAINER:-none})"
    return 0
  fi

  if ! docker exec "$EVERGREEN_CONTAINER" test -f /eg_ready 2>/dev/null; then
    heartbeat "waiting for evergreen readiness"
    return 0
  fi

  SITE=$(docker inspect --format '{{range .Config.Env}}{{println .}}{{end}}' "$ASPEN_CONTAINER" \
    | sed -n 's/^SITE_NAME=//p' | head -n1)

  if [ -z "$SITE" ]; then
    heartbeat "aspen container has no SITE_NAME"
    return 0
  fi

  ILS_DIR="/data/aspen-discovery/$SITE/ils"
  docker exec "$ASPEN_CONTAINER" mkdir -p "$ILS_DIR/marc_delta" "$ILS_DIR/supplemental"

  NAMES=$(listing marc_delta)

  if [ "$STARTED" = 0 ]; then
    STARTED=1
    SEEN=$NAMES
    SUPPLEMENTAL_AT=$(date +%s)
    echo "evergreen-sync: watching $ILS_DIR/marc_delta every ${INTERVAL}s"
    return 0
  fi

  NEW=$(exclude "$NAMES" "$SEEN")
  SEEN=$(exclude "$NAMES" "$NEW")

  if [ -z "$NEW" ]; then
    heartbeat "no new files since the last pass"
    copy_supplemental
    return 0
  fi

  for NAME in $NEW; do
    copy_file "marc_delta/$NAME" || continue
    remember "$NAME"
  done

  copy_supplemental
}

while true; do
  sync_pass || true
  sleep "$INTERVAL"
done
