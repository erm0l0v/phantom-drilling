# Phantoms

Godot 4.7 game jam project.

## Публикация на itch.io

Пуш тега вида `v*` запускает `.github/workflows/build-and-publish.yml`, который собирает Windows- и Web-билды и публикует их на itch.io через butler:

```
git tag v1.0.0
git push origin v1.0.0
```

Либо запустить вручную: вкладка **Actions** → *Build and publish to itch.io* → **Run workflow**.

Перед первым запуском создайте на itch.io игру и добавьте в **Settings → Secrets and variables → Actions** репозитория:

- `BUTLER_API_KEY` — ключ с https://itch.io/user/settings/api-keys
- `ITCH_TARGET` — `username/game-slug` вашей страницы на itch.io
