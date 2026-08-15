#!/bin/bash
# play.sh <game.exe> [modes...] [args...]
# Run a Windows game via Wine + DXVK, always favouring the discrete GPU.
#
# Modes (any number, any order):
#   Bep|bep|bepinex    BepInEx mod loader (winhttp=n,b)
#   hud|Hud|hmntr      translucent HUD overlay (FPS from play's own Vulkan layer)
#   MangoHud|mangohud  MangoHud overlay + FPS log (needs: mangohud package)
#
# GPU selection works on any vendor / any setup:
#   - a tiny Vulkan probe (vkdevs/) picks a discrete GPU if one exists,
#     otherwise the integrated one (no display / PRIME setup included)
#   - NVIDIA: PRIME render offload + optimus layer + DXVK device filter
#   - AMD/Intel: DRI_PRIME + DXVK device filter where applicable
#   - GPU_NAME (config) overrides everything
#
# DXVK is obtained automatically (first run): bundled in
# $PLAY_DIR/dxvk/<ver>, else the distro's DXVK (/usr/share/dxvk ...),
# else downloaded from GitHub. Native DLL overrides are registered in the
# Wine prefix so DXVK is actually used. On NVIDIA 470-class (Vulkan 1.2)
# DXVK 1.10.x gets immediate present forced (PRIME offload white-screen fix).
#
# Config (optional, sourced if present):
#   $PLAY_CONFIG  or  ~/.config/play/config
#     WINE_BIN="/path/to/wine"          # default: GE-Proton, else system wine
#     GPU_NAME="NVIDIA GeForce MX130"   # default: auto-detected discrete GPU
#     WINEPREFIX="$HOME/.wine"
#     DXVK_VER="1.10.3"                 # default: auto (1.10.x on Vulkan<1.3)
#   HUD options (env): HMNTR_METERS, HMNTR_INTERVAL, HMNTR_OPACITY
set -u

VERSION="0.9.2"

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
PLAY_CACHE_DIR="${PLAY_CACHE_DIR:-$HOME/.cache/play}"

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
${C_WHITE}   GPU_NAME${C_RESET}    ${C_DIM}DXVK device filter (auto-detected: discrete GPU)${C_RESET}
${C_WHITE}   WINEPREFIX${C_RESET}  ${C_DIM}wine prefix (default ~/.wine)${C_RESET}
${C_WHITE}   DXVK_VER${C_RESET}    ${C_DIM}force a DXVK version (default: auto)${C_RESET}
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
FPS_LAYER_DIR="$PLAY_CACHE_DIR/fpslayer"

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

VKDEVS_SRC="$PLAY_DIR/vkdevs/vkdevs.c"
VKDEVS_BIN="$PLAY_CACHE_DIR/vkdevs/vkdevs"

# Build the tiny Vulkan GPU probe. Tries -lvulkan first, then links the
# loader by full path (some distros only ship libvulkan.so.1).
ensure_vkdevs() {
  command -v gcc >/dev/null 2>&1 || return 1
  [ -f "$VKDEVS_SRC" ] || return 1
  mkdir -p "$(dirname "$VKDEVS_BIN")"
  if [ ! -x "$VKDEVS_BIN" ] || [ "$VKDEVS_SRC" -nt "$VKDEVS_BIN" ]; then
    local lib=""
    if ! gcc -O2 -o "$VKDEVS_BIN" "$VKDEVS_SRC" -lvulkan 2>"$(dirname "$VKDEVS_BIN")/build.log"; then
      lib="$(ldconfig -p 2>/dev/null | awk '$1=="libvulkan.so.1" {print $NF; exit}')"
      if [ -n "$lib" ] && gcc -O2 -o "$VKDEVS_BIN" "$VKDEVS_SRC" "$lib" 2>"$(dirname "$VKDEVS_BIN")/build.log"; then
        :
      else
        echo "play: could not build the Vulkan GPU probe (see $(dirname "$VKDEVS_BIN")/build.log)" >&2
        return 1
      fi
    fi
  fi
}

# Print the discrete GPU name (or the best fallback) + its Vulkan API
# version. Emits: "<name>|<major.minor>". Empty on failure.
detect_gpu() {
  if [ -n "${GPU_NAME:-}" ]; then
    echo "$GPU_NAME|"
    return 0
  fi
  if ensure_vkdevs; then
    local pick
    pick="$("$VKDEVS_BIN" 2>/dev/null | sed -n 's/^PICK //p' | head -1)"
    [ -n "$pick" ] && { echo "$pick"; return 0; }
  fi
  command -v nvidia-smi >/dev/null 2>&1 && {
    local nv
    nv="$(nvidia-smi --query-gpu=name --format=csv,noheader 2>/dev/null | head -1)"
    [ -n "$nv" ] && { echo "$nv|"; return 0; }
  }
  command -v vulkaninfo >/dev/null 2>&1 && {
    local v
    v="$(vulkaninfo --summary 2>/dev/null | grep -i "deviceName" | grep -viE "intel|llvmpipe|software" | head -1 | sed 's/.*= *//')"
    [ -n "$v" ] && { echo "$v|"; return 0; }
  }
  return 1
}

# DXVK version to use. DXVK 2.x+ needs Vulkan 1.3; older drivers (e.g.
# NVIDIA 470, Vulkan 1.2) get DXVK 1.10.x. DXVK_VER overrides everything.
choose_dxvk_ver() {
  if [ -n "${DXVK_VER:-}" ]; then
    echo "$DXVK_VER"
    return 0
  fi
  case "$GPU_API" in
    1.3.*|1.4.*|2.*) echo latest ;;
    *)
      # unknown API: NVIDIA legacy drivers are the only common 1.2 case, so
      # play it safe there; everything else can take the latest DXVK
      case "${GPU_ACTIVE,,}" in
        *nvidia*) echo 1.10.3 ;;
        *) echo latest ;;
      esac
      ;;
  esac
}

# Echo a directory that contains <ver>/x64 dlls, preferring the play-bundled
# copy, then the distro's, else empty.
dxvk_src_dir() {
  local ver="$1" src
  for src in "$PLAY_DIR/dxvk/$ver" /usr/share/dxvk /usr/lib/dxvk /usr/lib64/dxvk; do
    [ -d "$src/x64" ] && { echo "$src"; return 0; }
  done
  return 1
}

fetch_dxvk() {
  local ver="$1" tag="" url tmp
  command -v curl >/dev/null 2>&1 || return 1
  command -v tar  >/dev/null 2>&1 || return 1
  mkdir -p "$PLAY_DIR/dxvk"
  if [ "$ver" = "latest" ]; then
    tag="$(curl -fsSL --max-time 20 https://api.github.com/repos/doitsujin/dxvk/releases/latest 2>/dev/null \
      | grep -o '"tag_name": *"[^"]*"' | head -1 | sed 's/.*"tag_name": *"//;s/["\r]*$//')"
  else
    tag="$ver"
  fi
  tag="${tag#v}"
  [ -n "$tag" ] || return 1
  url="https://github.com/doitsujin/dxvk/releases/download/v$tag/dxvk-$tag.tar.gz"
  tmp="$(mktemp -d)"
  if curl -fsSL --max-time 120 "$url" | tar -xz -C "$tmp" 2>/dev/null; then
    rm -rf "$PLAY_DIR/dxvk/$ver"
    mv "$tmp/dxvk-$tag" "$PLAY_DIR/dxvk/$ver" 2>/dev/null
  fi
  rm -rf "$tmp"
  [ -d "$PLAY_DIR/dxvk/$ver/x64" ]
}

# Copy DXVK into the Wine prefix and register native overrides so Wine
# actually loads it (Wine ignores native dlls without an override).
install_dxvk() {
  local ver="$1" src base dll
  src="$(dxvk_src_dir "$ver")"
  if [ -z "$src" ]; then
    echo "play: DXVK $ver not bundled or in system paths - downloading..." >&2
    fetch_dxvk "$ver" || { echo "play: could not obtain DXVK $ver; continuing without it" >&2; return 1; }
    src="$(dxvk_src_dir "$ver")"
    [ -n "$src" ] || return 1
  fi
  local sys32="$WINEPREFIX/drive_c/windows/system32"
  local syswow="$WINEPREFIX/drive_c/windows/syswow64"
  mkdir -p "$sys32" "$syswow"
  for dll in "$src"/x64/*.dll; do cp -f "$dll" "$sys32/"; done
  if [ -d "$src/x32" ]; then for dll in "$src"/x32/*.dll; do cp -f "$dll" "$syswow/"; done; fi
  for dll in "$src"/x64/*.dll; do
    base="$(basename "$dll" .dll)"
    case "$base" in dxgi|d3d9|d3d10|d3d10_1|d3d10core|d3d11)
      WINEDEBUG=-all WINEDLLOVERRIDES="mscoree,mshtml=" "$WINE_BIN" reg add \
        "HKCU\\Software\\Wine\\DllOverrides" /v "$base" /d native /f >/dev/null 2>&1
      ;;
    esac
  done
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

export WINEPREFIX="${WINEPREFIX:-$HOME/.wine}"

# Resolve the wine binary before we need to touch the prefix.
WINE_BIN="${WINE_BIN:-}"
if [ -z "$WINE_BIN" ]; then
  WINE_BIN="$(ls -d "$HOME"/.local/share/GE-Proton*/files/bin/wine 2>/dev/null | sort -V | tail -n 1)"
  [ -x "$WINE_BIN" ] || WINE_BIN="$(command -v wine)"
fi

# Pick the GPU and set the env to actually use it.
GPU_INFO="$(detect_gpu)"
GPU_ACTIVE="${GPU_INFO%%|*}"
GPU_API="${GPU_INFO#*|}"
[ "$GPU_API" = "$GPU_INFO" ] && GPU_API=""

case "${GPU_ACTIVE,,}" in
  *nvidia*)
    export __NV_PRIME_RENDER_OFFLOAD=1
    export __GLX_VENDOR_LIBRARY_NAME=nvidia
    export __VK_LAYER_NV_optimus=NVIDIA_only
    ;;
  *radeon*|*amd*|*advanced*)
    export DRI_PRIME=1
    ;;
esac
if [ -n "$GPU_ACTIVE" ]; then
  export DXVK_FILTER_DEVICE_NAME="$GPU_ACTIVE"
fi

# DXVK 1.x presents with the default swap interval (vsync). On NVIDIA PRIME
# offload the GPU has no attached display, so that can stall on the first
# present (white screen). Force immediate present for legacy NVIDIA + DXVK 1.x
# unless the game ships its own dxvk.conf (a DXVK_CONFIG_FILE would ignore it).
setup_dxvk_config() {
  case "$DXVK_VER" in
    1.9.*|1.10.*)
      case "${GPU_ACTIVE,,}" in
        *nvidia*)
          [ -f "$(dirname "$GAME")/dxvk.conf" ] && return 0
          printf 'dxvk.syncInterval = 0\n' > "$PLAY_CACHE_DIR/dxvk.conf"
          export DXVK_CONFIG_FILE="$PLAY_CACHE_DIR/dxvk.conf"
          ;;
      esac
      ;;
  esac
}

DXVK_VER="$(choose_dxvk_ver)"
export WINEESYNC=1
export WINEFSYNC=1
install_dxvk "$DXVK_VER"
setup_dxvk_config

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
