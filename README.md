# play

Run Windows games on Linux via Wine + DXVK, favouring your discrete GPU,
with an optional translucent HUD overlay.

## Requirements

- Wine with Vulkan support (GE-Proton recommended)
- DXVK installed in your Wine prefix
- Vulkan drivers for your GPU
- `gcc` — only needed to build the HUD's FPS layer on first use
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
play "/path/to/game.exe" MangoHud   # launch with MangoHud overlay + FPS log
play "/path/to/game.exe" Bep -windowed   # extra args pass through to the game
```

### Modes

| Mode | Effect |
|---|---|
| `Bep` | Sets `WINEDLLOVERRIDES=winhttp=n,b` for BepInEx mods |
| `hud` | Shows a translucent always-on-top HUD overlay with system stats + FPS |
| `MangoHud` | Runs MangoHud's in-game overlay and logs FPS to `/tmp/play` |

## hud — translucent HUD overlay

`play <game> hud` launches the game plus a small always-on-top overlay in the
bottom-right corner (self-updating, no screen clearing):

```text
CPU 34%  GPU 0% 48C  RAM 11G/14G  TMP 65C  FPS 60
```

- **Left-drag** to move it, **scroll wheel** to change opacity, **right-click** to quit.
- **FPS is independent of MangoHud**: `play` builds a tiny Vulkan layer
  (`fpslayer/`) that counts presented frames and writes the rate to
  `/tmp/play/fps.txt`. No MangoHud needed for FPS in `hud` mode.

The overlay is a Python GTK3 app (`hud`); python3-gi is required.

HUD options (environment):

| Variable | Default | Meaning |
|---|---|---|
| `HMNTR_METERS` | `cpu gpu ram fps cputemp` | meters to show |
| `HMNTR_INTERVAL` | `1` | refresh seconds |
| `HMNTR_OPACITY` | `0.75` | initial overlay opacity |
| `PLAY_FPS_FILE` | `/tmp/play/fps.txt` | FPS file written by the play layer |

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

The discrete GPU is auto-detected from `vulkaninfo` when `GPU_NAME` is unset.

## License

MIT
