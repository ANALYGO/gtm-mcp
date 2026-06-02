#!/bin/sh
# wrangler dev does not automatically inherit container environment
# variables.  This script writes them into .dev.vars (the standard
# wrangler mechanism for local dev secrets) before starting the
# dev server.
set -eu

DEV_VARS="${DEV_VARS_FILE:-/app/.dev.vars}"

# wrangler reads .dev.vars automatically.  Only write vars that
# are actually set.
: > "$DEV_VARS"

if [ -n "${GOOGLE_CLIENT_ID:-}" ]; then
  echo "GOOGLE_CLIENT_ID=${GOOGLE_CLIENT_ID}" >> "$DEV_VARS"
fi
if [ -n "${GOOGLE_CLIENT_SECRET:-}" ]; then
  echo "GOOGLE_CLIENT_SECRET=${GOOGLE_CLIENT_SECRET}" >> "$DEV_VARS"
fi
if [ -n "${COOKIE_ENCRYPTION_KEY:-}" ]; then
  echo "COOKIE_ENCRYPTION_KEY=${COOKIE_ENCRYPTION_KEY}" >> "$DEV_VARS"
fi
if [ -n "${HOSTED_DOMAIN:-}" ]; then
  echo "HOSTED_DOMAIN=${HOSTED_DOMAIN}" >> "$DEV_VARS"
fi
if [ -n "${WORKER_HOST:-}" ]; then
  echo "WORKER_HOST=${WORKER_HOST}" >> "$DEV_VARS"
fi

exec npx wrangler dev \
  --ip "0.0.0.0" \
  --port "3000" \
  --remote=false \
  --persist-to "/data" \
  "$@"
