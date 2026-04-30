# dotfiles

Personal dotfiles repository for the Quickshell music panel setup.

## Contents

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

## Apply

From the repository root:

```bash
rsync -av --exclude '.git/' ./ ~/ 
systemctl --user daemon-reload
systemctl --user enable --now docksync-waybar.service quickshell.service
systemctl --user disable --now waybar.service
```

## Notes

- The shader binary `audio_aura.frag.qsb` is committed alongside the source so Quickshell can run immediately.
- If you edit `audio_aura.frag`, rebuild it with:

```bash
/usr/lib/qt6/bin/qsb --glsl '100 es,120,150' --hlsl 50 --msl 12 -o ~/.config/quickshell/shaders/audio_aura.frag.qsb ~/.config/quickshell/shaders/audio_aura.frag
```
