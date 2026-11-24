# play architecture

## Technology stack

| Layer | Technology | Source |
| --- | --- | --- |
| Launcher and installer | Bash (`play.sh` uses `set -u`; `install.sh` uses `set -euo pipefail`) | [`../play.sh`](../play.sh), [`../install.sh`](../install.sh) |
| HUD overlay | Python 3 + GTK3 via `python3-gi`, Pango markup, GTK CSS | [`../hud`](../hud) |
| FPS counter | C Vulkan instance layer `VK_LAYER_PLAY_fps` | [`../fpslayer/play_fps.c`](../fpslayer/play_fps.c), [`../fpslayer/play_fps.json`](../fpslayer/play_fps.json) |
| GPU probe | C program using the Vulkan loader | [`../vkdevs/vkdevs.c`](../vkdevs/vkdevs.c) |
| Compatibility | Wine/GE-Proton + DXVK DLLs; optional MangoHud | [`../play.sh`](../play.sh), [`../dxvk/`](../dxvk/) |
| Presentation | Bash ANSI art + PNG logo | [`../typo.sh`](../typo.sh), [`../typo.png`](../typo.png) |

There is no package manifest, build system, or dependency lockfile. The two C
helpers are compiled on demand by `play.sh`.

## Entry points

- `play` (installed symlink or `play.sh`) → [`../play.sh`](../play.sh):
  parses `--help`/`--version`, handles standalone `hud`/`--hud`, validates game
  path, sources config, resolves Wine/GPU/DXVK, then execs Wine.
- `play hud` → `exec "$PLAY_DIR/hud"` → [`../hud`](../hud): GTK main loop.
- `install.sh` → [`../install.sh`](../install.sh): `--deps` path installs
  packages; default path downloads a release tarball, installs it, links the
  launcher, and patches the shell RC PATH.
- `dxvk/1.10.3/setup_dxvk.sh` is a bundled DXVK upstream helper; `play.sh`
  does **not** call it — `install_dxvk()` copies DLLs and writes registry
  overrides itself.

## Directory map

| Path | Responsibility |
| --- | --- |
| [`../play.sh`](../play.sh) | Mode parser, config sourcing, Wine/GPU/DXVK setup, process launch |
| [`../install.sh`](../install.sh) | Release/dependency installer |
| [`../config.example`](../config.example) | Commented template for `~/.config/play/config` |
| [`../hud`](../hud) | Overlay rendering, telemetry collection, mouse controls |
| [`../fpslayer/`](../fpslayer/) | Vulkan layer source + manifest |
| [`../vkdevs/`](../vkdevs/) | Vulkan physical-device enumeration helper |
| [`../dxvk/1.10.3/`](../dxvk/1.10.3/) | Bundled DXVK 1.10.3 x32/x64 DLLs + upstream setup script |
| [`../dxvk/latest/`](../dxvk/latest/) | Bundled “latest” x32/x64 DLL set |
| [`../typo.sh`](../typo.sh), [`../typo.png`](../typo.png) | Help banner art and logo |
| [`../docs/`](./README.md) | Documentation set |

## Launcher flow

```text
play.sh <game> [modes...] [args...]
  │
  ├─ source ${PLAY_CONFIG:-~/.config/play/config} if present
  ├─ special flags: --help, --version, hud/--hud → exec hud
  ├─ validate game file, resolve abs path, shift modes
  ├─ mode loop: Bep → WINEDLLOVERRIDES; hud → build FPS layer;
  │             MangoHud → MANGOHUD_CONFIG; other token → stop, rest are game args
  ├─ WINEPREFIX default ~/.wine; WINE_BIN from config/GE-Proton/system wine
  ├─ detect_gpu(): GPU_NAME → vkdevs PICK → nvidia-smi → vulkaninfo
  ├─ vendor env: NVIDIA offload vars / DRI_PRIME; DXVK_FILTER_DEVICE_NAME
  ├─ choose_dxvk_ver(): DXVK_VER → Vulkan API hint → NVIDIA legacy fallback
  ├─ install_dxvk(): bundled → system dirs → GitHub download; copy DLLs + reg add
  ├─ setup_dxvk_config(): legacy NVIDIA dxvk.syncInterval=0 unless game has dxvk.conf
  ├─ cd game dir
  └─ hud mode: start hud in background + trap cleanup, run wine;
      otherwise: exec wine with remaining args
```

FPS layer activation is a side effect of `hud` mode: `ensure_fps_layer()`
compiles `fpslayer/play_fps.c` into `$PLAY_CACHE_DIR/fpslayer/play_fps.so`,
copies the JSON manifest, and exports `VK_LAYER_PATH`,
`VK_INSTANCE_LAYERS=VK_LAYER_PLAY_fps`, and `PLAY_FPS_FILE` for the game
process. The GPU probe is compiled similarly into
`$PLAY_CACHE_DIR/vkdevs/vkdevs` by `ensure_vkdevs()`.

## HUD process and data flow

[`../hud`](../hud) runs a GTK main loop. `build_markup()` polls:

- `/proc/stat` for CPU usage and `/sys/class/thermal/thermal_zone*` for CPU
  temperature.
- `/proc/meminfo` for used/total RAM.
- `nvidia-smi --query-gpu=utilization.gpu,temperature.gpu` for GPU stats, with a
  two-second cache.
- `PLAY_FPS_FILE` for FPS; values older than two seconds are hidden.

Markup uses `C_NORM`, `C_DIM`, `C_WARN`, and `C_CRIT` thresholds (70/90% for
load, 65/80 °C for temperature). Mouse handlers set opacity on scroll, move
the window on left-drag, and quit on right-click. SIGINT/SIGTERM also quit. On
X11, `set_override_redirect()` uses `ctypes` and `libX11.so.6` to mark the
window override-redirect so window managers do not decorate or manage it.

## Storage and integration boundaries

| Boundary | Details |
| --- | --- |
| Config | `PLAY_CONFIG` or `~/.config/play/config`, sourced as Bash |
| User install | `PLAY_HOME` default `~/.local/share/play`; symlink `PLAY_BIN_DIR/play` default `~/.local/bin/play`; PATH line in `~/.bashrc` or `~/.zshrc` |
| Runtime cache | `PLAY_CACHE_DIR` default `~/.cache/play`: compiled `fpslayer/` and `vkdevs/` binaries, `dxvk.conf`, build logs |
| Temporary data | `/tmp/play`: FPS files and MangoHud logs |
| Wine prefix | `WINEPREFIX` default `~/.wine`; DLLs copied into `drive_c/windows/system32` and `syswow64`; overrides via `wine reg add` |
| Network | `curl` to GitHub API/releases for DXVK and installer tarballs |
| External programs | `gcc`, `curl`, `tar`, `nvidia-smi`, `vulkaninfo`, `mangohud`, Wine, `ldconfig`, package managers |

No database, server, or persistent application state beyond those files exists.

## Sources

[`../play.sh`](../play.sh), [`../install.sh`](../install.sh), [`../hud`](../hud),
[`../fpslayer/`](../fpslayer/), [`../vkdevs/`](../vkdevs/),
[`../dxvk/`](../dxvk/), [`../config.example`](../config.example).
