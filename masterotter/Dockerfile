# MasterOtter Server for Home Assistant OS.
#
# node:24 because the server uses node:sqlite, which is flag-free from Node 23.4+ (the Windows
# build runs the same). ffmpeg comes from Alpine's package — an ordinary, replaceable binary,
# exactly as the licences page promises. The Supervisor builds this image on the HA machine
# itself, so the architecture always matches the host.
FROM node:24-alpine@sha256:116b800c3754b440ee0aa3ed2f20f5bf3d99a554bfd9adeea09ea8017f6e85f5 AS runtime
WORKDIR /build
COPY runtime.json fetch-runtime.mjs ./
RUN node fetch-runtime.mjs
WORKDIR /opt/masterotter
RUN npm ci --omit=dev --ignore-scripts --no-audit --no-fund && npm cache clean --force

FROM node:24-alpine@sha256:116b800c3754b440ee0aa3ed2f20f5bf3d99a554bfd9adeea09ea8017f6e85f5
RUN apk add --no-cache ffmpeg wget unzip su-exec

WORKDIR /opt/masterotter

COPY --from=runtime /opt/masterotter/ ./
COPY run.sh /run.sh
RUN chmod 0555 /run.sh && chmod -R go-w /opt/masterotter

CMD ["/run.sh"]
