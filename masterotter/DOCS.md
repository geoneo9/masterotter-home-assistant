# MasterOtter Server add-on

## Install

1. Settings → Add-ons → Add-on store → ⋮ → Repositories → add this repository's URL.
2. Install **MasterOtter Server** and start it. The first start builds the image on the host.
3. Open the Web UI. The guided setup asks for an account (MasterOtter Cloud or a local one), a
   name for this server, an optional TMDB key, the first library and shows the apps to install.

## Options

| Option | What it does |
|---|---|
| `tmdb_api_key` | A free TMDB v3 key for posters and summaries. Can also be entered in the guided setup or under Settings. |
| `port` | The port the server listens on (default 32480). The Web UI button follows the default only. |
| `external_port` | The public port to advertise when a router forwards a different one. |
| `download_demo_library` | Fetch three open films into `/share/masterotter-demo/Movies` to try the server without your own files. |

## Where things live

- Media: `/share` and `/media` are mounted read-write; pick a folder under them in the guided setup.
- Data: `/data/masterotter` holds the database, the artwork cache and the nightly snapshots.

## Home Assistant entity

A `media_player` entity for each MasterOtter server is provided by the separate
`custom_components/masterotter` integration (HACS or manual copy). It shows what is playing and
can stop a stream. It signs in with a local account on the server.
