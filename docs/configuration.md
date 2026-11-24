# play configuration

## Config file

Optional: `~/.config/play/config`, or the path in `PLAY_CONFIG`. `play.sh`
sources it as shell code before doing anything else; only create it from a
trusted source. The tracked template is [`../config.example`](../config.example):

```bash
cp config.example ~/.config/play/config
```

| Key | Default | Meaning |
| --- | --- | --- |
| `WINE_BIN` | newest `~/.local/share/GE-Proton*/files/bin/wine`, else system `wine` | Wine executable |
| `GPU_NAME` | auto-detected discrete GPU | DXVK device filter override |
| `WINEPREFIX` | `~/.wine` | Wine prefix used for DLL installation |
| `DXVK_VER` | auto: `1.10.3` on NVIDIA legacy/unknown Vulkan < 1.3, `latest` otherwise | Forces a bundled/system DXVK version |
| `HMNTR_METERS` | `cpu gpu ram fps` | HUD meters (config file is sourced into the shell, so these are inherited) |
| `HMNTR_INTERVAL` | `1` | HUD refresh seconds |
| `HMNTR_OPACITY` | `0.75` | HUD opacity (clamped 0.35–1.0) |

## Environment variables read or written

### Inputs

| Variable | Read by | Default / effect |
| --- | --- | --- |
| `PLAY_CONFIG` | `play.sh` | `~/.config/play/config` |
| `PLAY_CACHE_DIR` | `play.sh` | `~/.cache/play` for compiled C helpers, `dxvk.conf`, build logs |
| `PLAY_FPS_FILE` | `hud`, `fpslayer/play_fps.c` | HUD default `/tmp/play/fps.txt`; `play.sh` sets `/tmp/play/fps-<game>.txt` in game+HUD mode |
| `HMNTR_METERS` | `hud` | `cpu gpu ram fps`; unknown names are reported to stderr |
| `HMNTR_INTERVAL` | `hud` | `1`, clamped to 0.1–3600 |
| `HMNTR_OPACITY` | `hud` | `0.75`, clamped to 0.35–1.0 |
| `DISPLAY` | `hud` | presence forces `GDK_BACKEND=x11` when unset |
| `GDK_BACKEND` | `hud` | respected if already set |
| `PLAY_VERSION` | `install.sh` | `latest` release tag |
| `PLAY_HOME` | `install.sh` | `~/.local/share/play` |
| `PLAY_BIN_DIR` | `install.sh` | `~/.local/bin` |
| `ZSH_VERSION`, `BASH_VERSION` | `install.sh` | choose `.zshrc` vs `.bashrc` for PATH |
| `dxvk_lib32`, `dxvk_lib64` | bundled `dxvk/1.10.3/setup_dxvk.sh` | `x32`, `x64` (upstream helper; not called by `play.sh`) |

### Exports set by the launcher

| Variable | Set when | Value / purpose |
| --- | --- | --- |
| `WINEDLLOVERRIDES` | `Bep` mode; DXVK install | appends `winhttp=n,b`; DXVK registry step uses `mscoree,mshtml=` locally |
| `MANGOHUD` | `MangoHud` mode | `1` |
| `MANGOHUD_CONFIG` | `MangoHud` mode | appends `autostart_log=1,output_folder=/tmp/play,log_interval=100,log_duration=0` |
| `VK_LAYER_PATH` | `hud` mode | compiled FPS layer directory |
| `VK_INSTANCE_LAYERS` | `hud` mode | appends `VK_LAYER_PLAY_fps` |
| `PLAY_FPS_FILE` | `hud` mode | per-game FPS file |
| `DXVK_FILTER_DEVICE_NAME` | GPU detected | selected GPU name |
| `__NV_PRIME_RENDER_OFFLOAD`, `__GLX_VENDOR_LIBRARY_NAME`, `__VK_LAYER_NV_optimus` | NVIDIA GPU detected | `1`, `nvidia`, `NVIDIA_only` |
| `DRI_PRIME` | AMD GPU detected | `1` |
| `WINEESYNC`, `WINEFSYNC` | every game launch | both `1` |
| `DXVK_CONFIG_FILE` | legacy NVIDIA + DXVK 1.9/1.10, no game-local `dxvk.conf` | `$PLAY_CACHE_DIR/dxvk.conf` with `dxvk.syncInterval = 0` |
| `WINEPREFIX` | every game launch | config value or `~/.wine` |
| `WINEDEBUG` | DXVK registration and upstream helper | `-all` |

## Flags and modes

| Token | Effect |
| --- | --- |
| `-h`, `--help` | `play.sh` banner and usage |
| `-v`, `--version` | prints `play 0.9.2` |
| `hud`, `--hud` (as first and only arg) | standalone HUD via `exec "$PLAY_DIR/hud"` |
| `Bep`, `bep`, `bepinex` | BepInEx override |
| `hud`, `Hud`, `hmntr` | start HUD with the game |
| `MangoHud`, `mangohud` | MangoHud overlay and FPS log |
| `install.sh -d`, `install.sh --deps` | distro dependencies only |

Mode tokens are consumed only immediately after the game path; the first other
token and everything after it are passed to Wine untouched.

HUD's own flags: `-h`/`--help`, `-n`/`--interval SECS`, `--opacity 0.35-1.0`.

## Local files and runtime state

| Path | Written by | Notes |
| --- | --- | --- |
| `~/.config/play/config` | user | optional; template only in repo |
| `~/.local/share/play` | `install.sh` | installed program files |
| `~/.local/bin/play` | `install.sh` | symlink to `play.sh` |
| `~/.bashrc` or `~/.zshrc` | `install.sh` | adds `PLAY_BIN_DIR` to PATH if missing |
| `~/.cache/play/fpslayer/` | `play.sh` | `play_fps.so`, manifest, build.log |
| `~/.cache/play/vkdevs/vkdevs` | `play.sh` | compiled GPU probe |
| `~/.cache/play/dxvk.conf` | `play.sh` | legacy NVIDIA immediate present |
| `/tmp/play/fps-<game>.txt` | FPS layer | per-game FPS value; HUD ignores values older than two seconds |
| `/tmp/play/fps.txt` | FPS layer fallback | used by standalone `hud` and the C layer default |
| `/tmp/play` | MangoHud | FPS logs with `autostart_log=1` |
| `$WINEPREFIX/drive_c/windows/system32`, `syswow64` | `install_dxvk()` | DXVK DLL copies |
| Wine registry `HKCU\Software\Wine\DllOverrides` | `wine reg add` | native overrides for `dxgi`, `d3d9`, `d3d10`, `d3d10_1`, `d3d10core`, `d3d11` |

The HUD keeps GPU readings in an in-memory cache; there is no database,
browser storage, or application telemetry upload.

## Security notes

- The config file is sourced by Bash: do not copy an untrusted config.
- The documented installer pipes a remote script into `bash`; review it before
  running if that matters for your threat model.
- DXVK downloads use HTTPS from GitHub releases; the repository does not pin
  checksums.
- `install.sh` deletes and recreates `PLAY_HOME` and appends to a shell RC file.
- No credentials or secrets are required; do not place them in the config file
  because it is shell-sourced and may be shared with game processes via the
  environment.

## Sources

[`../config.example`](../config.example), [`../play.sh`](../play.sh),
[`../install.sh`](../install.sh), [`../hud`](../hud),
[`../fpslayer/play_fps.c`](../fpslayer/play_fps.c),
[`../fpslayer/play_fps.json`](../fpslayer/play_fps.json),
[`../dxvk/1.10.3/setup_dxvk.sh`](../dxvk/1.10.3/setup_dxvk.sh).
