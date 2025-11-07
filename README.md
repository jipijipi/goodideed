# goodideed
goodideed.com

## Update manifest for apps
- The manifest lives at `versions/manifest.json`, which GitHub Pages serves at `https://goodideed.com/versions/manifest.json`.
- Update this file whenever you need to raise minimum/recommended app or content versions; commit and push to redeploy.
- Use `app.minVersion` for hard blocks and `app.softVersion` for nudges; mirror that pattern with `content.minVersion` vs `content.latestVersion`.
- Point each `content.bundles[].url` to the hosted JSON/zip bundle and refresh the `hash` so the client can verify downloads.
- Add or rename bundles as you introduce more sequence packs; clients should treat unknown bundles as optional.
- Keep `schemaVersion` incrementing whenever you make breaking changes to the manifest structure.
