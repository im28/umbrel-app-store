# im28's Umbrel Community App Store

Personal [umbrelOS](https://umbrel.com) app store.

| App | What it does |
|---|---|
| `im28-photos-share` | [Immich Public Proxy](https://github.com/alangrainger/immich-public-proxy) with its own Tailscale node (`photos`) and Funnel. Shared Immich links are public, and Immich itself stays private. |
| `im28-storyteller` | [Storyteller](https://storyteller-platform.dev): turns ebooks plus audiobooks into read-along books. Files → Books is the watched folder. |
| `im28-t3-code` | [T3 Code](https://t3.codes) server: runs Claude Code agents on the Umbrel, driven from the T3 desktop, web and mobile apps. Its image is built from `images/t3-code` by GitHub Actions. |

Add this repo's URL in umbrelOS → App Store → ⋯ → Community App Stores.

This repo holds no secrets. The Tailscale auth key is placed on the device after install
(`${APP_DATA_DIR}/data/tailscale/authkey`), used once, then deleted.
