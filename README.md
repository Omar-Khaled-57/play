# play

Run Windows games on Linux via Wine + DXVK, favouring your discrete GPU,
with an optional translucent HUD overlay.

## Requirements

- Wine with Vulkan support (GE-Proton recommended)
- DXVK installed in your Wine prefix
- Vulkan drivers for your GPU
- `gcc` + Vulkan headers (`vulkan/vulkan.h`) — only needed to build the
  HUD's FPS layer on first use
- python3-gi (GTK3) — for the `hud` overlay
- Optional: `mangohud` for the MangoHud mode (`sudo apt install mangohud`)

## Install

```bash
sudo ln -s "$(pwd)/play.sh" /usr/local/bin/play
```

## Usage

```bash
play "/path/to/game.exe"            # launch a game
play "/path/to/game.exe" Bep        # launch with BepInEx mod loader
play "/path/to/game.exe" hud        # launch with the translucent HUD overlay
play "/path/to/game.exe" Bep hud    # combine modes: mod loader + HUD
play "/path/to/game.exe" MangoHud   # launch with MangoHud overlay + FPS log
play hud                           # standalone HUD, no game (system monitor)
play "/path/to/game.exe" Bep -windowed   # extra args pass through to the game
```

`play hud` (or `play --hud`) runs just the overlay for general reading of the
machine — no game, keeps running until right-clicked or Ctrl-C'd.

Modes combine in any order: `play game.exe Bep hud` enables the BepInEx loader
**and** the HUD overlay. Anything that isn't a mode is passed to the game as
an argument.

### Modes

| Mode | Effect |
|---|---|
| `Bep` | Sets `WINEDLLOVERRIDES=winhttp=n,b` for BepInEx mods |
| `hud` | Shows a translucent always-on-top HUD overlay with system stats + FPS |
| `MangoHud` | Runs MangoHud's in-game overlay and logs FPS to `/tmp/play` |

Multiple modes combine in any order (`play game.exe Bep hud`); other
arguments are passed through to the game.

## hud — translucent HUD overlay

`play <game> hud` launches the game plus a small always-on-top overlay pinned
to the top-right corner (self-updating, no screen clearing):

```text
CPU 34%  GPU 0% 48C  RAM 11G/14G  TMP 65C  FPS 60
```

- **Scroll wheel** changes opacity, **right-click** quits.
- **FPS is independent of MangoHud**: `play` builds a tiny Vulkan layer
  (`fpslayer/`) that counts presented frames and writes the rate to
  `/tmp/play/fps-<game>.txt`. No MangoHud needed for FPS in `hud` mode.
  (The FPS meter only appears for Vulkan games.)
- On a Wayland-only session (no `DISPLAY`) the overlay cannot position itself,
  so it appears where the compositor places it instead of top-right.

The overlay is a Python GTK3 app (`hud`); python3-gi is required.

HUD options (environment):

| Variable | Default | Meaning |
|---|---|---|
| `HMNTR_METERS` | `cpu gpu ram fps cputemp` | meters to show |
| `HMNTR_INTERVAL` | `1` | refresh seconds |
| `HMNTR_OPACITY` | `0.75` | initial overlay opacity |
| `PLAY_FPS_FILE` | `/tmp/play/fps-<game>.txt` | FPS file written by the play layer |

Values turn yellow above 70% and red above 90%; temps yellow above 65C and
red above 80C. Meters with no data (e.g. FPS before the game presents a
frame, or GPU temp without nvidia-smi) are hidden until available.

## Config

Optional config file at `~/.config/play/config` (see `config.example`):

```bash
WINE_BIN="$HOME/.local/share/GE-Proton11-3/files/bin/wine"
GPU_NAME="NVIDIA GeForce MX130"   # auto-detected if unset
WINEPREFIX="$HOME/.wine"
```

If `WINE_BIN` is unset, the newest GE-Proton in `~/.local/share` is used,
falling back to the system `wine`. The discrete GPU is auto-detected from
`vulkaninfo` when `GPU_NAME` is unset; NVIDIA-only optimisations
(`__NV_PRIME_RENDER_OFFLOAD`, `__GLX_VENDOR_LIBRARY_NAME`) are applied only
when an NVIDIA GPU is detected, so AMD/Intel machines are unaffected.

## License

MIT
