#!/bin/bash
# play.sh <game.exe> [modes...] [args...]
# Run a Windows game via Wine + DXVK, favouring the discrete GPU.
#
# Modes (any number, any order):
#   Bep|bep|bepinex    BepInEx mod loader (winhttp=n,b)
#   hud|Hud|hmntr      translucent HUD overlay (FPS from play's own Vulkan layer)
#   MangoHud|mangohud  MangoHud overlay + FPS log (needs: mangohud package)
#
# Config (optional, sourced if present):
#   $PLAY_CONFIG  or  ~/.config/play/config
#     WINE_BIN="/path/to/wine"          # default: GE-Proton, else system wine
#     GPU_NAME="NVIDIA GeForce MX130"   # default: auto-detected discrete GPU
#     WINEPREFIX="$HOME/.wine"
#   HUD options (env): HMNTR_METERS, HMNTR_INTERVAL, HMNTR_OPACITY
set -u

VERSION="0.9.0"

C_RESET="$(tput sgr0 2>/dev/null)"
C_BOLD="$(tput bold 2>/dev/null)"
C_DIM="$(tput dim 2>/dev/null)"
C_WHITE="$(tput setaf 7 2>/dev/null)"
C_GRAY="$(tput setaf 8 2>/dev/null)"
[ -z "$C_GRAY" ] && C_GRAY="$C_DIM"
C_ACCENT="$(tput setaf 12 2>/dev/null)"
[ -z "$C_ACCENT" ] && C_ACCENT="$(tput setaf 6 2>/dev/null)"

CONFIG="${PLAY_CONFIG:-$HOME/.config/play/config}"
[ -f "$CONFIG" ] && . "$CONFIG"

PLAY_DIR="$(dirname "$(readlink -f "$0")")"

# Distro-aware package hints. play is developed on Ubuntu but supports Fedora
# (dnf), Arch (pacman) and openSUSE (zypper) out of the box.
pkg_mgr() {
  if [ -r /etc/os-release ]; then
    case "$(sed -n 's/^ID=//p' /etc/os-release | tr -d '"')" in
      fedora|rhel|centos|rocky|alma) echo dnf ;;
      arch|manjaro|endeavouros) echo pacman ;;
      opensuse*|suse) echo zypper ;;
      *) echo apt ;;
    esac
  else
    echo apt
  fi
}
pkg_name() { # debian-style package name -> this distro's name
  case "$(pkg_mgr)" in
    dnf|pacman)
      case "$1" in
        libvulkan-dev) echo vulkan-headers ;;
        python3-gi) echo python3-gobject ;;
        gir1.2-gtk-3.0) echo gtk3 ;;
        *) echo "$1" ;;
      esac ;;
    *) echo "$1" ;;
  esac
}
pkg_hint() { # echo the install command for the given deps
  local pkgs p
  for p in "$@"; do pkgs="${pkgs:+$pkgs }$(pkg_name "$p")"; done
  case "$(pkg_mgr)" in
    dnf) echo "sudo dnf install $pkgs" ;;
    pacman) echo "sudo pacman -S $pkgs" ;;
    zypper) echo "sudo zypper install $pkgs" ;;
    *) echo "sudo apt install $pkgs" ;;
  esac
}

help() {
  cat <<EOF

${C_ACCENT}   ✦ play ${C_GRAY}v$VERSION${C_RESET}
${C_GRAY}   ─────────────────────────────────────${C_RESET}

EOF
  if [ -f "$PLAY_DIR/typo.sh" ]; then
    bash "$PLAY_DIR/typo.sh" | sed 's/^/   /'
  else
    printf '%s\n' \
      '   ████ █     ██  █  █' \
      '   █  █ █    █  █ █  █' \
      '   ████ █    ████  ██' \
      '   █    █    █  █  █' \
      '   █    ████ █  █  █'
  fi
  cat <<EOF

${C_ACCENT}${C_BOLD}usage${C_RESET}   ${C_GRAY}play.sh /path/to/game.exe [modes...] [game-args...]${C_RESET}

${C_ACCENT}${C_BOLD}modes${C_RESET}
${C_WHITE}${C_BOLD}   Bep${C_RESET}     ${C_DIM}BepInEx mod loader (winhttp=n,b)${C_RESET}
${C_WHITE}${C_BOLD}   hud${C_RESET}     ${C_DIM}translucent HUD overlay (FPS from play's Vulkan layer)${C_RESET}
${C_WHITE}${C_BOLD}   MangoHud${C_RESET}${C_DIM} MangoHud overlay + FPS log (needs: $(pkg_hint mangohud))${C_RESET}
${C_DIM}${C_WHITE}${C_BOLD}   ─ modes combine in any order, e.g. 'game.exe Bep hud'${C_RESET}

${C_ACCENT}${C_BOLD}config${C_RESET}  ${C_GRAY}${PLAY_CONFIG:-~/.config/play/config}${C_RESET}
${C_WHITE}   WINE_BIN${C_RESET}    ${C_DIM}wine binary (default newest GE-Proton, else system wine)${C_RESET}
${C_WHITE}   GPU_NAME${C_RESET}    ${C_DIM}DXVK device filter (auto-detected)${C_RESET}
${C_WHITE}   WINEPREFIX${C_RESET}  ${C_DIM}wine prefix (default ~/.wine)${C_RESET}
${C_WHITE}   HMNTR_*${C_RESET}     ${C_DIM}HUD options: METERS / INTERVAL / OPACITY (see README)${C_RESET}

${C_ACCENT}${C_BOLD}examples${C_RESET}
${C_WHITE}${C_BOLD}   play.sh game.exe${C_RESET}
${C_WHITE}${C_BOLD}   play.sh game.exe Bep -windowed${C_RESET}
${C_WHITE}${C_BOLD}   play.sh game.exe hud${C_RESET}
${C_WHITE}${C_BOLD}   play.sh game.exe Bep hud${C_RESET}${C_DIM}   modes combine (mod + HUD)${C_RESET}
${C_WHITE}${C_BOLD}   play.sh game.exe MangoHud${C_RESET}
${C_WHITE}${C_BOLD}   play.sh hud${C_RESET}${C_DIM}      standalone HUD (no game)${C_RESET}
EOF
  exit 0
}

GAME="${1:-}"
case "$GAME" in
  -h|--help) help ;;
  -v|--version) echo "play $VERSION"; exit 0 ;;
esac
if { [ "$GAME" = "hud" ] || [ "$GAME" = "--hud" ]; } && [ $# -eq 1 ]; then
  if [ -x "$PLAY_DIR/hud" ]; then
    exec "$PLAY_DIR/hud"
  else
    echo "play: hud not found at $PLAY_DIR/hud" >&2
    exit 1
  fi
fi
if [ -z "$GAME" ]; then
  echo "usage: play.sh /path/to/game.exe [modes...] [game-args...]"
  echo "modes: Bep (BepInEx), hud (HUD overlay), MangoHud (overlay + log)"
  echo "       modes combine, e.g. 'play game.exe Bep hud'"
  echo "       play.sh hud - standalone HUD (no game)"
  exit 1
fi
if [ ! -f "$GAME" ]; then
  echo "game not found: $GAME"
  exit 1
fi
GAME="$(readlink -f "$GAME")"
shift

FPS_LAYER_SRC="$PLAY_DIR/fpslayer"
FPS_LAYER_DIR="${PLAY_CACHE_DIR:-$HOME/.cache/play}/fpslayer"

ensure_fps_layer() {
  command -v gcc >/dev/null 2>&1 || { echo "play: gcc not found - HUD FPS disabled ($(pkg_hint gcc))" >&2; return 1; }
  mkdir -p "$FPS_LAYER_DIR" /tmp/play
  if ! printf '#include <vulkan/vulkan.h>\n#include <vulkan/vk_layer.h>\n' | gcc -x c -fsyntax-only - >/dev/null 2>&1; then
    echo "play: Vulkan headers not found - HUD FPS disabled ($(pkg_hint libvulkan-dev))" >&2
    return 1
  fi
  if [ ! -f "$FPS_LAYER_DIR/play_fps.so" ] || [ "$FPS_LAYER_SRC/play_fps.c" -nt "$FPS_LAYER_DIR/play_fps.so" ]; then
    if ! gcc -shared -fPIC -O2 -o "$FPS_LAYER_DIR/play_fps.so" "$FPS_LAYER_SRC/play_fps.c" -lpthread 2>"$FPS_LAYER_DIR/build.log"; then
      echo "play: FPS layer build failed (see $FPS_LAYER_DIR/build.log)" >&2
      return 1
    fi
  fi
  cp "$FPS_LAYER_SRC/play_fps.json" "$FPS_LAYER_DIR/" 2>/dev/null
  export VK_LAYER_PATH="$FPS_LAYER_DIR"
  export VK_INSTANCE_LAYERS="${VK_INSTANCE_LAYERS:+$VK_INSTANCE_LAYERS:}VK_LAYER_PLAY_fps"
  export PLAY_FPS_FILE="${PLAY_FPS_FILE:-/tmp/play/fps-$(basename "$GAME").txt}"
}

HUD=0
while [ $# -gt 0 ]; do
  case "$1" in
    Bep|bep|bepinex)
      shift
      export WINEDLLOVERRIDES="${WINEDLLOVERRIDES:+$WINEDLLOVERRIDES;}winhttp=n,b"
      ;;
    hud|Hud|hmntr)
      shift
      HUD=1
      ensure_fps_layer
      ;;
    MangoHud|mangohud)
      shift
      export MANGOHUD=1
      export MANGOHUD_CONFIG="${MANGOHUD_CONFIG:+$MANGOHUD_CONFIG,}autostart_log=1,output_folder=/tmp/play,log_interval=100,log_duration=0"
      mkdir -p /tmp/play
      ;;
    *)
      break
      ;;
  esac
done

detect_gpu() {
  command -v vulkaninfo >/dev/null 2>&1 || return 1
  vulkaninfo --summary 2>/dev/null \
    | grep -i "deviceName" \
    | grep -viE "intel|llvmpipe|software" \
    | head -1 \
    | sed 's/.*= *//'
}

export WINEPREFIX="${WINEPREFIX:-$HOME/.wine}"
if [ -n "${GPU_NAME:-}" ]; then
  GPU_ACTIVE="$GPU_NAME"
  export DXVK_FILTER_DEVICE_NAME="$GPU_NAME"
else
  GPU_ACTIVE="$(detect_gpu)"
  [ -n "$GPU_ACTIVE" ] && export DXVK_FILTER_DEVICE_NAME="$GPU_ACTIVE"
fi
case "$GPU_ACTIVE" in
  *NVIDIA*|*nvidia*)
    export __NV_PRIME_RENDER_OFFLOAD=1
    export __GLX_VENDOR_LIBRARY_NAME=nvidia
    ;;
esac
export WINEESYNC=1
export WINEFSYNC=1

WINE_BIN="${WINE_BIN:-}"
if [ -z "$WINE_BIN" ]; then
  WINE_BIN="$(ls -d "$HOME"/.local/share/GE-Proton*/files/bin/wine 2>/dev/null | sort -V | tail -n 1)"
  [ -x "$WINE_BIN" ] || WINE_BIN="$(command -v wine)"
fi

cd "$(dirname "$GAME")" || exit 1

if [ "$HUD" -eq 1 ]; then
  HUD_BIN="$PLAY_DIR/hud"
  if [ -x "$HUD_BIN" ]; then
    "$HUD_BIN" &
    HUD_PID=$!
    cleanup_hud() { kill "$HUD_PID" 2>/dev/null; }
    trap 'exit' INT TERM
    trap cleanup_hud EXIT
    "$WINE_BIN" "$GAME" "$@"
    rc=$?
    exit "$rc"
  else
    echo "play: hud not found/executable at $HUD_BIN - running game without HUD" >&2
  fi
fi
exec "$WINE_BIN" "$GAME" "$@"
