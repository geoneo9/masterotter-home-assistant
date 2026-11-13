#!/bin/sh
# MasterOtter Server add-on entrypoint. Keep this POSIX sh: the image is Alpine.
set -e
umask 077

OPTIONS=/data/options.json

# Old installations wrote their private volume as root. Repair only that volume,
# never the user's shared media, then run the application and downloads as node.
if [ "$(id -u)" = "0" ]; then
  mkdir -p /data/masterotter
  cp /data/options.json /data/masterotter/haos-options.json
  chmod 0600 /data/masterotter/haos-options.json
  chown -R node:node /data/masterotter
  if node -e 'process.exit(require("/data/options.json").download_demo_library===true?0:1)'; then
    mkdir -p /share/masterotter-demo/Movies
    chown -R node:node /share/masterotter-demo
  fi
  exec su-exec node:node /run.sh
fi
OPTIONS=/data/masterotter/haos-options.json

# Read one key from the Supervisor's options file. node is guaranteed present; jq is not.
opt() {
  node -e 'const o=require(process.argv[1]);const v=o[process.argv[2]];process.stdout.write(v==null?"":String(v))' "$OPTIONS" "$1" 2>/dev/null || true
}

# /data is the add-on's persistent volume: database, artwork cache, JWT secret, transcode
# scratch. Everything survives updates and restarts.
export MO_PLATFORM=haos
export MO_DATA_DIR=/data/masterotter
mkdir -p "$MO_DATA_DIR"

# A server's Cloud identity must be unique and stable. The Windows launcher generates a GUID at
# install; without this the add-on fell back to the shared "local-dev-server" id, which collides
# with every other unconfigured install on the planet. Generated once, kept in /data forever.
ID_FILE="$MO_DATA_DIR/server-id"
if [ ! -f "$ID_FILE" ]; then
  node -e 'process.stdout.write(require("crypto").randomUUID())' > "$ID_FILE"
fi
export MO_SERVER_ID="$(cat "$ID_FILE")"
export MO_HOST=0.0.0.0
# Listen port. Host networking means this binds the machine's real interfaces, so it must not
# clash with anything else running on this box. Note the Open Web UI button always assumes the
# default 32480 (the Supervisor cannot resolve an option into that button); the log below prints
# the real URL. external_port stays separate: it is the ROUTER-facing number you forward, and the
# forward should point at THIS machine's listen port.
LISTEN_PORT="$(opt port)"
export MO_PORT="${LISTEN_PORT:-32480}"
EXT_PORT="$(opt external_port)"
if [ -n "$EXT_PORT" ]; then
  export MO_EXTERNAL_PORT="$EXT_PORT"
fi
export MO_CLOUD_URL=https://masterotter.com

TMDB_KEY="$(opt tmdb_api_key)"
if [ -n "$TMDB_KEY" ]; then
  export MO_TMDB_API_KEY="$TMDB_KEY"
fi

# UPnP stays disabled by default even on the host network: an unattended demo box must never
# rewrite the router, and the earlier port-lease hijack of a sibling server is not a risk worth
# a convenience feature.
export MO_DISABLE_UPNP=1

# Optional demo library: three open-licence Blender films with real TMDB entries, named so the
# scanner matches them first try. Runs in the BACKGROUND on purpose: 2 GB of downloads must never
# stand between the user and a running server (the first version did exactly that, and the add-on
# looked dead while it silently downloaded). Files are fetched to .part names and renamed only
# when complete, so a scan can never ingest a half-written film; rescan (or wait for the folder
# watcher) once the log says the library is ready.
fetch_demo() {
  DEMO_DIR=/share/masterotter-demo/Movies
  mkdir -p "$DEMO_DIR"

  if [ ! -f "$DEMO_DIR/Sintel (2010).mkv" ]; then
    echo "[demo] Downloading Sintel (1.1 GB)..."
    wget -q -O "$DEMO_DIR/Sintel (2010).mkv.part" \
      "https://download.blender.org/durian/movies/Sintel.2010.1080p.mkv" \
      && mv "$DEMO_DIR/Sintel (2010).mkv.part" "$DEMO_DIR/Sintel (2010).mkv" \
      && echo "[demo] Sintel done." \
      || echo "[demo] Sintel download failed; will retry on next start."
  fi

  if [ ! -f "$DEMO_DIR/Tears of Steel (2012).mov" ]; then
    echo "[demo] Downloading Tears of Steel (372 MB)..."
    wget -q -O "$DEMO_DIR/Tears of Steel (2012).mov.part" \
      "https://download.blender.org/demo/movies/ToS/tears_of_steel_720p.mov" \
      && mv "$DEMO_DIR/Tears of Steel (2012).mov.part" "$DEMO_DIR/Tears of Steel (2012).mov" \
      && echo "[demo] Tears of Steel done." \
      || echo "[demo] Tears of Steel download failed; will retry on next start."
  fi

  if [ ! -f "$DEMO_DIR/Big Buck Bunny (2008).mov" ]; then
    echo "[demo] Downloading Big Buck Bunny (417 MB, zipped)..."
    wget -q -O /tmp/bbb.zip \
      "https://download.blender.org/peach/bigbuckbunny_movies/big_buck_bunny_720p_h264.mov.zip" \
      && unzip -o -q /tmp/bbb.zip -d /tmp/bbb \
      && mv "$(find /tmp/bbb -name '*.mov' | head -n 1)" "$DEMO_DIR/Big Buck Bunny (2008).mov" \
      && rm -rf /tmp/bbb /tmp/bbb.zip \
      && echo "[demo] Big Buck Bunny done." \
      || echo "[demo] Big Buck Bunny download failed; will retry on next start."
  fi

  echo "[demo] Demo library ready at $DEMO_DIR. Add it as a Movies library (or rescan) now."
}

if [ "$(opt download_demo_library)" = "true" ]; then
  fetch_demo &
fi

echo "Starting MasterOtter Server on host port $MO_PORT (data: $MO_DATA_DIR)"
if [ "$MO_PORT" != "32480" ]; then
  echo "NOTE: the Open Web UI button always points at port 32480 and will be wrong."
fi
echo "Web UI: http://$(hostname -i 2>/dev/null | cut -d' ' -f1 || echo "<this-machine>"):$MO_PORT"
exec node /opt/masterotter/main.js
