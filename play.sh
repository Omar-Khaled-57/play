#!/bin/bash
# play.sh <game.exe> [mode] [args...]
# Run a Windows game via Wine + DXVK, favouring the discrete GPU.
#
# Modes:
#   Bep|bep|bepinex    BepInEx mod loader (winhttp=n,b)
#   Hud|hud|mangohud   MangoHud overlay + FPS log (needs: sudo apt install mangohud)
#
# Config (optional, sourced if present):
#   $PLAY_CONFIG  or  ~/.config/play/config
#     WINE_BIN="/path/to/wine"          # default: GE-Proton, else system wine
#     GPU_NAME="NVIDIA GeForce MX130"   # default: auto-detected discrete GPU
#     WINEPREFIX="$HOME/.wine"
set -u

CONFIG="${PLAY_CONFIG:-$HOME/.config/play/config}"
[ -f "$CONFIG" ] && . "$CONFIG"

GAME="${1:-}"
case "$GAME" in
  -h|--help)
    echo "usage: play.sh /path/to/game.exe [mode] [game-args...]"
    echo
    echo "Run a Windows game via Wine + DXVK, favouring the discrete GPU."
    echo
    echo "modes:"
    echo "  Bep|bep|bepinex    BepInEx mod loader (winhttp=n,b)"
    echo "  Hud|hud|mangohud   MangoHud overlay + FPS log (needs: sudo apt install mangohud)"
    echo
    echo "config (optional): ${PLAY_CONFIG:-~/.config/play/config}"
    echo "  WINE_BIN, GPU_NAME, WINEPREFIX"
    echo
    echo "examples:"
    echo "  play.sh game.exe"
    echo "  play.sh game.exe Bep -windowed"
    echo "  play.sh game.exe Hud"
    exit 0
    ;;
esac
if [ -z "$GAME" ]; then
  echo "usage: play.sh /path/to/game.exe [mode] [game-args...]"
  echo "modes: Bep (BepInEx), Hud (MangoHud)"
  exit 1
fi
if [ ! -f "$GAME" ]; then
  echo "game not found: $GAME"
  exit 1
fi
GAME="$(readlink -f "$GAME")"
shift

MODE="${1:-}"
case "$MODE" in
  Bep|bep|bepinex)
    shift
    export WINEDLLOVERRIDES="${WINEDLLOVERRIDES:+$WINEDLLOVERRIDES;}winhttp=n,b"
    ;;
  Hud|hud|mangohud)
    shift
    export MANGOHUD=1
    export MANGOHUD_LOG_FILE="${MANGOHUD_LOG_FILE:-/tmp/play/mangohud.log}"
    mkdir -p "$(dirname "$MANGOHUD_LOG_FILE")"
    ;;
esac

detect_gpu() {
  command -v vulkaninfo >/dev/null 2>&1 || return 1
  vulkaninfo --summary 2>/dev/null \
    | grep -i "deviceName" \
    | grep -viE "intel|llvmpipe|software" \
    | head -1 \
    | sed 's/.*= *//'
}

export WINEPREFIX="${WINEPREFIX:-$HOME/.wine}"
export __NV_PRIME_RENDER_OFFLOAD=1
export __GLX_VENDOR_LIBRARY_NAME=nvidia
if [ -n "${GPU_NAME:-}" ]; then
  export DXVK_FILTER_DEVICE_NAME="$GPU_NAME"
else
  AUTO_GPU="$(detect_gpu)"
  [ -n "$AUTO_GPU" ] && export DXVK_FILTER_DEVICE_NAME="$AUTO_GPU"
fi
export WINEESYNC=1
export WINEFSYNC=1

WINE_BIN="${WINE_BIN:-$HOME/.local/share/GE-Proton11-3/files/bin/wine}"
[ -x "$WINE_BIN" ] || WINE_BIN="$(command -v wine)"

cd "$(dirname "$GAME")" || exit 1
exec "$WINE_BIN" "$GAME" "$@"
