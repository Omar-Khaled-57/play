# play development

## Prerequisites

From [`../README.md`](../README.md):

- Wine with Vulkan support (GE-Proton recommended) and Vulkan drivers.
- `gcc` plus Vulkan headers (`vulkan/vulkan.h`) to build the FPS layer and GPU
  probe on first use.
- `python3-gi` / GTK3 for the HUD.
- Optional: `mangohud` for the `MangoHud` mode.

Distro package hints in the launcher and installer cover Ubuntu/Debian (`apt`),
Fedora/RHEL (`dnf`), Arch (`pacman`), and openSUSE (`zypper`) by reading
`/etc/os-release`.

## Install and run

Installer commands from [`../README.md`](../README.md):

```bash
curl -fsSL https://raw.githubusercontent.com/Omar-Khaled-57/play/main/install.sh | bash
```

```bash
PLAY_VERSION=v0.8.1 curl -fsSL https://raw.githubusercontent.com/Omar-Khaled-57/play/main/install.sh | bash
```

```bash
curl -fsSL https://raw.githubusercontent.com/Omar-Khaled-57/play/main/install.sh | bash -s -- --deps
```

Manual install from a checkout:

```bash
sudo ln -s "$(pwd)/play.sh" /usr/local/bin/play
```

Run from a checkout or after installation:

```bash
play "/path/to/game.exe"
play "/path/to/game.exe" hud
play hud
play --help
```

## Command reference

| Command | Source | Purpose |
| --- | --- | --- |
| `play /path/to/game.exe [modes...] [game-args...]` | `play.sh` help | Launch a game; modes must come immediately after the path |
| `play hud` / `play --hud` | `play.sh` | Standalone HUD; right-click or Ctrl-C to quit |
| `play --help` / `play -h` | `play.sh` | Banner and usage |
| `play --version` / `play -v` | `play.sh` | Print `play 0.9.2` |
| `hud --help`, `hud -n SECS`, `hud --opacity 0.35-1.0` | `hud` | HUD's own options |
| `bash -n play.sh`, `bash -n install.sh`, `bash -n typo.sh` | manual checks | Syntax-check Bash files |
| `python3 -m py_compile hud` | manual check | Syntax-check the Python overlay |
| `./play.sh --version`, `./play.sh --help` | manual checks | CLI smoke checks from a checkout |

## Repository structure

See the directory map in [`architecture.md`](./architecture.md). The executable
pieces are `play.sh`, `install.sh`, `hud`, `typo.sh`, and the two C helpers;
DXVK DLLs are vendored binaries under `dxvk/`.

## Conventions

- `play.sh` intentionally uses `set -u` (not `set -e`): several optional steps
  are allowed to fail and continue (for example DXVK download and FPS layer
  compile).
- Config is sourced as shell code; keep config keys simple scalar assignments.
- Modes are recognized only immediately after the game path. The first unknown
  token ends mode parsing and is passed through to the game along with all
  following arguments.
- New environment inputs should be documented in
  [`configuration.md`](./configuration.md) and in `help()` in `play.sh`.
- HUD colors live in the Python file's `C_NORM`/`C_DIM`/`C_WARN`/`C_CRIT`
  constants; the visual contract is in [`visual-identity.md`](./visual-identity.md).
- Do not edit the bundled DXVK DLLs; add a new `dxvk/<ver>` directory instead.

## Adding a feature

1. Decide whether the change belongs in `play.sh`, `hud`, or a C helper, using
   [`architecture.md`](./architecture.md) as the map.
2. Add the mode/flag/parser branch and expose any new option in `help()` and
   `config.example` when user-facing.
3. Update [`configuration.md`](./configuration.md) with defaults and where the
   value is read.
4. Run the manual checks in [`testing.md`](./testing.md); game/GPU behavior
   must be verified on real hardware because there is no automated suite.

## Troubleshooting

| Symptom | Evidence and next step |
| --- | --- |
| `hud not found at <dir>/hud` | `play.sh` requires an executable `hud` next to the launcher; keep the folder intact |
| `play: gcc not found - HUD FPS disabled` | `ensure_fps_layer()` checks `command -v gcc`; install distro `gcc` |
| `play: Vulkan headers not found - HUD FPS disabled` | Header syntax probe in `play.sh`; install `libvulkan-dev` / `vulkan-headers` |
| `play: could not build the Vulkan GPU probe` | `ensure_vkdevs()` tries `-lvulkan` then the full path from `ldconfig`; see the written `build.log` |
| `hud: python3-gi (GTK3) required for the HUD` | `hud` prints a distro-specific install hint from `gi_pkg_hint()` |
| `play: DXVK <ver> not bundled or in system paths - downloading...` | `dxvk_src_dir()` checks bundled and system dirs; `fetch_dxvk()` needs `curl` and `tar` and network access |
| `MangoHud` does nothing | Requires the external `mangohud` package; see README |

## Sources

[`../README.md`](../README.md), [`../play.sh`](../play.sh),
[`../install.sh`](../install.sh), [`../hud`](../hud),
[`../config.example`](../config.example), [`testing.md`](./testing.md).
