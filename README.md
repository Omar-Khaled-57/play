<p align="center">
  <img src="typo.png" alt="play" width="480">
</p>

# play

A simple launcher that runs Windows games on Linux via **Wine + DXVK**, always
favouring your discrete GPU, with an optional translucent **HUD overlay** that
shows live system stats and FPS.

## Features

- Launch any Windows `.exe` with Wine + DXVK, automatically picking your
  discrete GPU (NVIDIA optimisations are only applied on NVIDIA hardware).
- Combine multiple modes in one command: `play game.exe Bep hud`.
- HUD overlay pinned to the top-right corner with CPU / GPU / RAM / temp / FPS
  — no MangoHud needed for FPS (it uses its own Vulkan layer).
- Standalone `play hud` mode turns the overlay into a plain system monitor.
- BepInEx mod loader support (one keyword).
- MangoHud overlay + FPS logging as an alternative.

## Requirements

| What | Why |
|---|---|
| Wine with Vulkan support (GE-Proton recommended) | runs the game |
| DXVK installed in your Wine prefix | translates Direct3D to Vulkan |
| Vulkan drivers for your GPU | needed by DXVK |
| `gcc` + Vulkan headers (`vulkan/vulkan.h`) | build the HUD's FPS layer on first use |
| python3-gi (GTK3) | the `hud` overlay |
| `mangohud` *(optional)* | only for the `MangoHud` mode: `sudo apt install mangohud` |

## Install

**Recommended** — one-liner (installs to `~/.local/share/play` and links
`play` into `~/.local/bin`, no sudo):

```bash
curl -fsSL https://raw.githubusercontent.com/Omar-Khaled-57/play/main/install.sh | bash
```

To install a specific release instead of the latest:

```bash
PLAY_VERSION=v0.8.0 curl -fsSL https://raw.githubusercontent.com/Omar-Khaled-57/play/main/install.sh | bash
```

The installer downloads the release archive from GitHub, so it never mixes
old and new files — re-run it any time to update.

**Manual** — clone or copy the `play` folder and symlink the launcher:

```bash
sudo ln -s "$(pwd)/play.sh" /usr/local/bin/play
```

After installing, `~/.local/bin` is added to your `PATH` in `~/.bashrc` the
first time (or use `PLAY_BIN_DIR` to pick a directory already on your PATH).
Restart your shell, then verify with `play --version`.

## Quick start

```bash
play "/path/to/game.exe"           # just run the game
play "/path/to/game.exe" hud       # run the game + HUD overlay
play hud                           # HUD overlay only (system monitor)
play --help                        # show help with the banner
```

That's it. The first time you use `hud`, the FPS Vulkan layer is compiled
automatically (you'll see a message if `gcc` or the Vulkan headers are
missing — the game still runs, just without the FPS meter).

## Usage

```
play /path/to/game.exe [modes...] [game-args...]
```

Everything after the game path is read left to right: any token that is a mode
name is applied, and the first token that isn't a mode ends the mode list —
everything after it is passed straight to the game.

### Modes

| Mode | Effect |
|---|---|
| `Bep` | Enables the BepInEx mod loader (`WINEDLLOVERRIDES=winhttp=n,b`) |
| `hud` | Shows the translucent always-on-top HUD overlay with stats + FPS |
| `MangoHud` | Runs MangoHud's in-game overlay and logs FPS to `/tmp/play` |

### Combining modes

Modes combine in any order, so one command can do several things:

```bash
play ULTRAKILL.exe Bep hud          # BepInEx + HUD overlay
play game.exe MangoHud Bep          # MangoHud + BepInEx (order doesn't matter)
play game.exe Bep -windowed         # BepInEx, then pass -windowed to the game
```

Note: a mode placed *after* a game argument is treated as a game argument
(modes must come right after the game path).

### Standalone HUD

```bash
play hud
play --hud                          # same thing
```

Runs only the overlay as a general machine monitor — no game. It keeps
running until you right-click it or press Ctrl-C.

## The HUD overlay

`play <game> hud` launches the game and, at the same time, a small
always-on-top overlay pinned to the **top-right corner** of your screen:

```text
CPU 34%  GPU 0% 48C  RAM 11G/14G  TMP 65C  FPS 60
```

### Controls

- **Scroll wheel** — change overlay opacity.
- **Right-click** — close the overlay and quit (`play hud` standalone mode).
- The overlay is not draggable by design.
- When launched with a game, the overlay **closes automatically when the game
  exits** (including Ctrl-C).

### What it shows

Meters shown by default: `cpu gpu ram fps cputemp`. Values turn yellow above
70% and red above 90%; temperatures yellow above 65C and red above 80C. Meters
with no data yet (e.g. FPS before the game presents its first frame, or GPU
temp without `nvidia-smi`) are hidden until they become available.

### How FPS works (no MangoHud required)

`play` builds a tiny Vulkan instance layer (`fpslayer/play_fps.c`) that counts
presented frames and writes the rate to a file. The HUD reads that file.

- FPS appears only for **Vulkan** games (which DXVK games are).
- The FPS file defaults to `/tmp/play/fps-<game>.txt` (one per game).

### HUD options (environment variables)

| Variable | Default | Meaning |
|---|---|---|
| `HMNTR_METERS` | `cpu gpu ram fps cputemp` | space-separated meters to show |
| `HMNTR_INTERVAL` | `1` | refresh interval in seconds |
| `HMNTR_OPACITY` | `0.75` | initial overlay opacity (0.35 – 1.0) |
| `PLAY_FPS_FILE` | `/tmp/play/fps-<game>.txt` | FPS file written by the play layer |

Example:

```bash
HMNTR_INTERVAL=2 HMNTR_OPACITY=0.9 play game.exe hud
```

### Notes / limitations

- On a **Wayland-only** session (no `DISPLAY`), the overlay can't position
  itself, so it appears where the compositor places it instead of top-right.
- The overlay is a Python GTK3 app; it needs `python3-gi` (GTK3) and an X11 /
  XWayland display.

## MangoHud mode

```bash
play game.exe MangoHud
```

Runs the game with MangoHud's in-game overlay and writes an FPS log to
`/tmp/play` (`autostart_log=1`, 100 ms interval). Requires `mangohud`
installed. This is an alternative to the `hud` overlay, not a replacement —
you can even use both at once.

## Configuration

Optional config file at `~/.config/play/config` (a template is in
`config.example`). Copy it and edit:

```bash
cp config.example ~/.config/play/config
```

All variables are optional; defaults are automatic.

| Variable | Default | Meaning |
|---|---|---|
| `WINE_BIN` | newest GE-Proton in `~/.local/share`, else system `wine` | the wine binary to use |
| `GPU_NAME` | auto-detected discrete GPU | DXVK device filter |
| `WINEPREFIX` | `~/.wine` | Wine prefix to use |

Example:

```bash
WINE_BIN="$HOME/.local/share/GE-Proton11-3/files/bin/wine"
GPU_NAME="NVIDIA GeForce MX130"
WINEPREFIX="$HOME/.wine"
```

Notes:

- If `WINE_BIN` is unset, the newest GE-Proton in `~/.local/share` is used
  (`GE-Proton*/files/bin/wine`), falling back to the system `wine`.
- The discrete GPU is auto-detected from `vulkaninfo` when `GPU_NAME` is
  unset. NVIDIA-only optimisations (`__NV_PRIME_RENDER_OFFLOAD`,
  `__GLX_VENDOR_LIBRARY_NAME`) are applied only when an NVIDIA GPU is
  detected, so AMD/Intel machines are unaffected.
- HUD options (`HMNTR_*`, `PLAY_FPS_FILE`) can also be set here or as
  environment variables.

## Troubleshooting

| Problem | Fix |
|---|---|
| "hud not found" | `play` looks for `hud` next to `play.sh` — make sure the whole `play` folder is intact and the file is executable. |
| No FPS in the HUD | `gcc` or Vulkan headers missing → install them (e.g. `sudo apt install gcc libvulkan-dev`). FPS only shows for Vulkan games. |
| HUD not in the corner | You're on Wayland without XWayland/`DISPLAY` — see *Notes* above. |
| `MangoHud` does nothing | `sudo apt install mangohud`. |
| Wrong GPU being used | Set `GPU_NAME` in the config, or install Vulkan drivers for the discrete GPU. |
| Overlay too transparent / bright | Scroll the wheel, or set `HMNTR_OPACITY`. |

## Uninstall

```bash
rm -f ~/.local/bin/play               # remove the launcher symlink
rm -rf ~/.local/share/play            # remove the program
rm -rf ~/.cache/play                  # remove the compiled FPS layer
rm -rf ~/.config/play                 # remove the config file (optional)
```

Then remove the `# play launcher` PATH line from `~/.bashrc` if you don't want
`~/.local/bin` anymore.

## License

MIT
