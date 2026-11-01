#!/usr/bin/env bash
# Habit Island'ı macOS'ta 720x1280 dikey pencerede başlatır.
set -euo pipefail

cd "$(dirname "$0")"

if ! command -v godot >/dev/null 2>&1; then
	echo "Hata: 'godot' komutu bulunamadı. Kurulum: brew install --cask godot" >&2
	exit 1
fi

# Temiz kopyada font gibi kaynaklar henüz içe aktarılmamıştır.
if [ ! -d .godot/imported ]; then
	godot --headless --path . --import
fi

godot --path . --resolution 720x1280 &
