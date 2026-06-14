# dotfiles

Personal dotfiles repository for the Hyprland desktop and Quickshell music panel setup.

## Contents

- `.config/hypr/`
  - Hyprland Lua config split into small modules
  - `hypridle.conf`, `hyprlock.conf`, and `hyprpaper.conf`
- `.config/uwsm/env`
  - session environment for Hyprland under `uwsm`
- `.config/quickshell/`
  - Quickshell panel config
  - CAVA feed helper
  - shader source and compiled `.qsb`
  - vector like icons
- `.config/systemd/user/quickshell.service`
  - starts Quickshell as the active panel
- `.config/systemd/user/docksync-waybar.service`
  - local WebSocket helper used by the Yandex Music DockSync addon
- `.config/quickshell/scripts/docksync-helper`
  - DockSync state/cache helper script used by the Quickshell setup
- `.config/git/`
  - Global git settings

## Apply

From the repository root:

```bash
rsync -av --exclude '.git/' ./ ~/ 
systemctl --user daemon-reload
systemctl --user enable --now docksync-waybar.service quickshell.service
systemctl --user disable --now waybar.service
```

## Notes

- Hyprland itself is configured through `.config/hypr/hyprland.lua`, which loads the split Lua modules in the same directory.
- `hypridle`, `hyprlock`, and `hyprpaper` still use their own `*.conf` files because they are not part of the Hyprland Lua migration.
- `uwsm` is expected to manage the Hyprland session; session env vars live in `.config/uwsm/env` instead of `hyprland.lua`.
- The shader binary `audio_aura.frag.qsb` is committed alongside the source so Quickshell can run immediately.
- If you edit `audio_aura.frag`, rebuild it with:

```bash
/usr/lib/qt6/bin/qsb --glsl '100 es,120,150' --hlsl 50 --msl 12 -o ~/.config/quickshell/shaders/audio_aura.frag.qsb ~/.config/quickshell/shaders/audio_aura.frag
```
