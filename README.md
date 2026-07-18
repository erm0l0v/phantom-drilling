# Phantoms

Godot 4.7 game jam project.

## Publishing to itch.io

Every push to `main` or `master` triggers `.github/workflows/build-and-publish.yml`, which builds Windows and Web versions and publishes them to itch.io via butler. It can also be run manually from the **Actions** tab → *Build and publish to itch.io* → **Run workflow**.

Before the first run, create the game page on itch.io and add these secrets under **Settings → Secrets and variables → Actions**:

- `BUTLER_API_KEY` — key from https://itch.io/user/settings/api-keys
- `ITCH_TARGET` — `username/game-slug` of your itch.io page
