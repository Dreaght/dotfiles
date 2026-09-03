#!/usr/bin/env bash
set -euo pipefail

exec /app/opt/yandex-music/yandexmusic --gtk-version=3 --no-sandbox "$@"
