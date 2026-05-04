#!/bin/bash

set -euo pipefail

: "${TAILSCALE_AUTHKEY:?TAILSCALE_AUTHKEY must be set}"

TAILSCALE_SOCKET="/var/run/tailscale/tailscaled.sock"
TAILSCALE_STATE="/var/lib/tailscale/tailscaled.state"

# Start tailscaled
./tailscaled \
  --state=${TAILSCALE_STATE} \
  --socket=${TAILSCALE_SOCKET} &

# Wait for socket to exist (daemon ready)
until [ -S "$TAILSCALE_SOCKET" ]; do
  sleep 0.2
done

# Bring up Tailscale
./tailscale \
  --socket=${TAILSCALE_SOCKET} \
  up \
  --authkey=${TAILSCALE_AUTHKEY} \
  --hostname=${FLY_APP_NAME} \
  --accept-routes

# Wait until it's ready instead of blind sleep
until ./tailscale --socket=${TAILSCALE_SOCKET} status >/dev/null 2>&1; do
  sleep 0.5
done

uv run python manage.py migrate --noinput
uv run python manage.py collectstatic --noinput

# Start your app (important: last process)
uv run gunicorn mysite.wsgi:application --bind 0.0.0.0:8000 &

# Expose app via Tailscale
./tailscale serve --bg http://127.0.0.1:8000

# Keep container alive
wait -n