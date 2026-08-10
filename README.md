# play

Run Windows games on Linux via Wine + DXVK, favouring your discrete GPU,
plus `hmntr`, a terminal health monitor.

## Requirements

- Wine with Vulkan support (GE-Proton recommended)
- DXVK installed in your Wine prefix
- Vulkan drivers for your GPU
- Optional: `mangohud` for the FPS meter (`sudo apt install mangohud`)

## Install

```bash
sudo ln -s "$(pwd)/play.sh" /usr/local/bin/play
sudo ln -s "$(pwd)/hmntr"   /usr/local/bin/hmntr
```

## Usage

```bash
play "/path/to/game.exe"            # launch a game
play "/path/to/game.exe" Bep        # launch with BepInEx mod loader
play "/path/to/game.exe" Hud        # launch with MangoHud overlay + FPS log
play "/path/to/game.exe" Bep -windowed   # extra args pass through to the game
```

### Modes

| Mode | Effect |
|---|---|
| `Bep` | Sets `WINEDLLOVERRIDES=winhttp=n,b` for BepInEx mods |
| `Hud` | Enables MangoHud and writes its FPS log to `/tmp/play/mangohud.log` |

### Config

Optional config file at `~/.config/play/config` (see `config.example`):

```bash
WINE_BIN="$HOME/.local/share/GE-Proton11-3/files/bin/wine"
GPU_NAME="NVIDIA GeForce MX130"   # auto-detected if unset
WINEPREFIX="$HOME/.wine"
```

The discrete GPU is auto-detected from `vulkaninfo` when `GPU_NAME` is unset.

## hmntr — minimal one-line health bar

A single subtle line (NVIDIA-overlay style) refreshed in place; it never
clears the screen or swallows the terminal:

```text
CPU 17%  GPU 0% 46C  RAM 8G/14G  TMP 52C  FPS 60
```

```bash
hmntr                        # all meters
hmntr --cpu --gpu            # only CPU and GPU
hmntr --exclude-fps          # all except FPS
hmntr -n 2                   # refresh every 2 seconds
```

Meters: `cpu`, `gpu`, `ram`, `fps`, `cputemp`.

- `cpu` / `ram` — read from `/proc` (no deps)
- `gpu` — `nvidia-smi` (usage + temp), or `/sys/class/drm/.../gpu_busy_percent`
- `cputemp` — from `/sys/class/thermal`
- `fps` — reads MangoHud's log, so start the game with `play game.exe Hud`

Values turn yellow above 70% and red above 90%; temps yellow above 65C and
red above 80C.

## License

MIT
