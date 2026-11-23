# HuggingChat (huggingface/chat-ui) for Railway, behind a password.
# Upstream's v0.10.0 release has no image (its release build failed), so this pins the
# official image built from main at 152ee7d, the commit right before the v0.10.0 tag
# (v0.10.0 only adds a CSS margin tweak on top of it).
FROM caddy:2.11.9@sha256:4851e54a46b206517c574821bb5cc67f170d2156041e9fbc4c9193b45e84a75b AS caddy

FROM ghcr.io/huggingface/chat-ui:sha-152ee7d@sha256:b9726b361a982dee035d503221ed1f66f1d993a2a8e86df4019c57cc02d28795

COPY --from=caddy /usr/bin/caddy /usr/local/bin/caddy
COPY --chown=1000 Caddyfile /app/railway/Caddyfile
COPY --chown=1000 --chmod=755 start.sh /app/railway/start.sh
COPY --chown=1000 wait-for-mongo.mjs /app/wait-for-mongo.mjs

ENV XDG_DATA_HOME=/tmp/caddy-data XDG_CONFIG_HOME=/tmp/caddy-config
EXPOSE 8080
CMD ["/app/railway/start.sh"]
