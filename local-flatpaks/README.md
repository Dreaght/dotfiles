# Local Flatpaks

This directory hosts local Flatpak manifests plus a generic updater that:

- scans every app manifest under `apps/`
- refreshes externally-versioned sources with `flatpak-external-data-checker`
- rebuilds changed apps with `flatpak-builder`
- exports them into a local OSTree repo

## Layout

- `apps/`: one subdirectory per app
- `scripts/update-local-flatpaks`: bulk checker/build/export entrypoint
- `scripts/bootstrap-local-flatpak-repo`: creates the local repo and remote

## First-time setup

```bash
/home/dreaght/local-flatpaks/scripts/bootstrap-local-flatpak-repo
/home/dreaght/local-flatpaks/scripts/update-local-flatpaks
flatpak install --user local-flatpaks ru.yandex.Music
```

## Updates

Manual:

```bash
/home/dreaght/local-flatpaks/scripts/update-local-flatpaks
flatpak update
```

Automatic:

```bash
systemctl --user daemon-reload
systemctl --user enable --now local-flatpak-updater.timer
```

The timer refreshes manifests and republishes new builds into the local repo.
Once the local repo has a newer commit, `flatpak update` sees it like any other
Flatpak remote.
