# play product

## Problem and audience

Running Windows games under Wine on Linux often means hand-picking a GPU,
finding a compatible DXVK build, registering DLL overrides, and then bolting on
a separate FPS monitor. `play` is for Linux gamers who want one command that
sets those pieces up and launches the game, with an optional desktop overlay
for live telemetry.

The launcher is a set of shell scripts and small C helpers, not a GUI app; its
visual conventions are in [`visual-identity.md`](./visual-identity.md).

## What it does today

- Launches a Windows `.exe` through Wine and DXVK
  ([`../play.sh`](../play.sh), lines ending in `exec "$WINE_BIN"`).
- Picks a discrete GPU using a purpose-built Vulkan probe
  ([`../vkdevs/vkdevs.c`](../vkdevs/vkdevs.c)), with `nvidia-smi` and
  `vulkaninfo` fallbacks in `play.sh`.
- Selects DXVK automatically: bundled `dxvk/<ver>` first, distro paths next,
  GitHub download last; registers `native` DLL overrides in the Wine prefix
  ([`../play.sh`](../play.sh), [`../dxvk/`](../dxvk/)).
- Applies vendor-specific environment for NVIDIA PRIME offload and DRI_PRIME
  for AMD, plus a legacy NVIDIA immediate-present `dxvk.conf`
  ([`../play.sh`](../play.sh)).
- Supports combinable modes `Bep`, `hud`, and `MangoHud` parsed left-to-right
  after the game path ([`../play.sh`](../play.sh)).
- Runs a standalone `play hud` GTK3 overlay as a system monitor
  ([`../hud`](../hud)).
- Counts FPS with its own Vulkan instance layer instead of requiring MangoHud
  ([`../fpslayer/play_fps.c`](../fpslayer/play_fps.c),
  [`../fpslayer/play_fps.json`](../fpslayer/play_fps.json)).
- Installs from GitHub releases with distro-aware dependency hints
  ([`../install.sh`](../install.sh)).

## Feature inventory

| Area | Implementation | Source |
| --- | --- | --- |
| CLI | `-h/--help`, `-v/--version`, `hud`/`--hud`, game path, mode tokens, pass-through game args | [`../play.sh`](../play.sh) |
| Modes | `Bep`/`bep`/`bepinex` sets `winhttp=n,b`; `hud`/`Hud`/`hmntr` starts overlay; `MangoHud`/`mangohud` sets `MANGOHUD*` and logs to `/tmp/play` | [`../play.sh`](../play.sh) |
| Wine selection | `WINE_BIN`, else newest `GE-Proton*/files/bin/wine`, else system `wine` | [`../play.sh`](../play.sh) |
| GPU selection | `GPU_NAME` override, compiled Vulkan probe, NVIDIA fallback, `vulkaninfo` fallback | [`../play.sh`](../play.sh), [`../vkdevs/vkdevs.c`](../vkdevs/vkdevs.c) |
| DXVK | version selection (1.10.3 for legacy NVIDIA / Vulkan < 1.3, `latest` otherwise), `dxvk_src_dir()`, `fetch_dxvk()`, `install_dxvk()` | [`../play.sh`](../play.sh), [`../dxvk/`](../dxvk/) |
| HUD | CPU/RAM from `/proc`, CPU temp from sysfs, GPU via `nvidia-smi`, FPS from file, GTK3 overlay with drag/scroll/right-click | [`../hud`](../hud) |
| FPS | Vulkan layer hooks `vkQueuePresentKHR`, writes rounded FPS to `PLAY_FPS_FILE` | [`../fpslayer/play_fps.c`](../fpslayer/play_fps.c) |
| Installer | latest/tagged tarball, `PLAY_HOME`, `PLAY_BIN_DIR`, PATH setup, `--deps` | [`../install.sh`](../install.sh) |
| Branding | ANSI-art banner via `typo.sh`, `typo.png` logo | [`../typo.sh`](../typo.sh), [`../typo.png`](../typo.png) |

## Non-goals and explicit limitations

- The overlay does not recolor or modify the game's own rendering; game output
  stays as produced by Wine/DXVK
  ([`visual-identity.md`](./visual-identity.md)).
- FPS from the custom layer is available only for Vulkan games (which DXVK
  games are). MangoHud is an alternative, not a replacement
  ([`../README.md`](../README.md)).
- On Wayland-only sessions without `DISPLAY`/XWayland, the HUD cannot position
  itself in the top-right corner.
- No fixed web-style color palette is claimed; appearance varies with desktop
  theme and MangoHud mode.

## Known gaps

- No automated test suite or CI; only manual/syntax checks are documented in
  [`testing.md`](./testing.md).
- No committed release notes; see [`changelog.md`](./changelog.md).
- The first-run DXVK download and GE-Proton selection depend on external
  GitHub/distro state that is not pinned in this repository.
- `~/.config/play/config` is optional and user-owned; only a template exists.

## Sources

[`../README.md`](../README.md), [`../play.sh`](../play.sh),
[`../install.sh`](../install.sh), [`../hud`](../hud),
[`../fpslayer/`](../fpslayer/), [`../vkdevs/`](../vkdevs/),
[`../dxvk/`](../dxvk/).
