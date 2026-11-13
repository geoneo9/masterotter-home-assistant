# MasterOtter for Home Assistant

Run MasterOtter Server on Home Assistant OS (amd64 or aarch64).

[Add the repository to Home Assistant](https://my.home-assistant.io/redirect/supervisor_add_addon_repository/?repository_url=https%3A%2F%2Fgithub.com%2Fgeoneo9%2Fmasterotter-home-assistant)

Or add `https://github.com/geoneo9/masterotter-home-assistant` under Settings > Add-ons > Add-on store > Repositories. Install **MasterOtter Server** from this repository. Home Assistant checks this repository for updates; install updates through Home Assistant.

The server is built on your device. The first installation can take several minutes. Your library, users and settings are stored in the add-on's persistent data volume. Media is read from `/media` and `/share`.

## Existing Local add-on installations

A Local add-on and a repository add-on have separate Home Assistant identities and data volumes. Adding this repository alone does not convert your existing installation. **Do not uninstall the Local add-on or start a second server against the same files.** Keep it running until its data has been backed up and migrated. A Home Assistant backup protects the existing installation but does not automatically move its data to the new identity.

## Accounts and sharing

A local owner can administer the server without a Cloud account. Invitations for existing MasterOtter Cloud users require the server to be claimed by a Cloud owner. Linking a personal account and claiming a server are separate steps. Create a Cloud account at [MasterOtter](https://masterotter.com/login?mode=signup).

## Distribution

This repository contains only the Home Assistant wrapper, documentation and artwork. During the image build it downloads the versioned compiled server from masterotter.com, verifies its exact size and SHA-256, and installs locked runtime dependencies. No server source or compiled server bundle is committed to this repository. Private extensions, operator configuration, accounts and credentials are excluded from both the wrapper and runtime. MasterOtter is proprietary; see LICENSE and the runtime's third-party notices.

[Setup documentation](masterotter/DOCS.md) · [What's new](https://masterotter.com/whats-new)
