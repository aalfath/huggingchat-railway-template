#!/bin/bash
# Starts chat-ui on 127.0.0.1:3000 and Caddy (password + health check) on $PORT.
# If either process stops, the container exits non-zero so Railway restarts it.
set -u

export CADDY_PORT="${PORT:-8080}"
export BASIC_AUTH_USER="${BASIC_AUTH_USER:-admin}"
if [ -z "${BASIC_AUTH_PASSWORD:-}" ]; then
	echo "[railway] BASIC_AUTH_PASSWORD is empty: refusing to start an open chat UI" >&2
	exit 1
fi
if [ -z "${MONGODB_URL:-}" ]; then
	echo "[railway] MONGODB_URL is empty" >&2
	exit 1
fi
if ! BASIC_AUTH_HASH="$(caddy hash-password --plaintext "$BASIC_AUTH_PASSWORD")"; then
	echo "[railway] could not hash BASIC_AUTH_PASSWORD" >&2
	exit 1
fi
export BASIC_AUTH_HASH

# chat-ui settings (each can be overridden with a service variable)
export MONGODB_DB_NAME="${MONGODB_DB_NAME:-chat-ui}"
export MONGODB_DIRECT_CONNECTION="${MONGODB_DIRECT_CONNECTION:-true}"
export TRUSTED_EMAIL_HEADER="${TRUSTED_EMAIL_HEADER:-x-auth-user}"
export NODE_OPTIONS="${NODE_OPTIONS:---max-old-space-size=320}"
export UV_THREADPOOL_SIZE="${UV_THREADPOOL_SIZE:-2}"
export VIPS_CONCURRENCY="${VIPS_CONCURRENCY:-1}"
if [ -n "${PUBLIC_ORIGIN:-}" ]; then
	export ORIGIN="${ORIGIN:-$PUBLIC_ORIGIN}"
fi

cd /app
node /app/wait-for-mongo.mjs || exit 1

export PUBLIC_VERSION="$(node -p "require('./package.json').version")"
HOST=127.0.0.1 PORT=3000 dotenv -e /app/.env -c -- node --dns-result-order=ipv4first /app/build/index.js &
APP_PID=$!
caddy run --config /app/railway/Caddyfile --adapter caddyfile &
CADDY_PID=$!

stop() {
	kill -TERM "$APP_PID" "$CADDY_PID" 2>/dev/null
	wait "$APP_PID" "$CADDY_PID" 2>/dev/null
	exit 0
}
trap stop TERM INT

wait -n "$APP_PID" "$CADDY_PID"
code=$?
echo "[railway] a process exited with code $code; stopping the container" >&2
kill -TERM "$APP_PID" "$CADDY_PID" 2>/dev/null
[ "$code" -eq 0 ] && code=1
exit "$code"
