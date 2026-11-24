# play deployment

`play` has no build manifest: [`../play.sh`](../play.sh) and
[`../install.sh`](../install.sh) are Bash scripts, [`../hud`](../hud) is a
Python 3 script, and the two C helpers are compiled locally on first use.
Deployment therefore means installing the script tree, linking the launcher,
and letting the launcher build its optional helpers at runtime.

## Install commands

Commands from [`../README.md`](../README.md):

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

After installation, use `play --version` to confirm the `VERSION` value printed
by the launcher; [`../install.sh`](../install.sh) runs that same check at the end
of a successful install.

## What the installer does

[`../install.sh`](../install.sh) needs `curl` and `tar`. It resolves the latest
GitHub release through `https://api.github.com/repos/Omar-Khaled-57/play/releases/latest`,
or builds a tag URL for an explicit `PLAY_VERSION`, downloads the tarball into
a temporary staging directory, and checks that the extracted tree contains
`play.sh`.

| Input | Default | Effect |
| --- | --- | --- |
| `PLAY_VERSION` | `latest` | `latest` resolves the API; any other value becomes an archive tag URL |
| `PLAY_HOME` | `~/.local/share/play` | Destination directory; existing contents are removed before install |
| `PLAY_BIN_DIR` | `~/.local/bin` | Directory for the `play` symlink |
| `-d` / `--deps` | off | Install distro dependencies and exit without installing `play` |

The installer makes `play.sh`, `hud`, and `typo.sh` executable, creates
`$PLAY_BIN_DIR/play` as a symlink to `$PLAY_HOME/play.sh`, and appends a PATH
line to `~/.bashrc` (or `~/.zshrc` when `ZSH_VERSION` is set and
`BASH_VERSION` is not) if that directory is not already on `PATH`. Restarting
the shell is required after that change.

`--deps` maps Debian-style package names through `pkg_mgr()` /
`pkg_name()` and installs `curl`, `tar`, `gcc`, Vulkan headers, GTK3 Python
bindings, and `vulkan-tools` using `apt`, `dnf`, `pacman`, or `zypper`.

## Build artifacts and runtime files

No binaries are shipped as build outputs; the following are produced or copied
at runtime:

| Artifact | Producer | Location |
| --- | --- | --- |
| Installed program tree | `install.sh` | `$PLAY_HOME` |
| `play` symlink | `install.sh` | `$PLAY_BIN_DIR/play` |
| FPS Vulkan layer | `ensure_fps_layer()` in [`../play.sh`](../play.sh) | `$PLAY_CACHE_DIR/fpslayer/play_fps.so`, with `play_fps.json` and `build.log` |
| Vulkan GPU probe | `ensure_vkdevs()` in [`../play.sh`](../play.sh) | `$PLAY_CACHE_DIR/vkdevs/vkdevs`, with `build.log` |
| Immediate-present config | `setup_dxvk_config()` | `$PLAY_CACHE_DIR/dxvk.conf` on legacy NVIDIA without a game-local `dxvk.conf` |
| DXVK DLLs | `install_dxvk()` | `$WINEPREFIX/drive_c/windows/system32` and `syswow64` |
| FPS values / MangoHud logs | FPS layer and MangoHud | `/tmp/play/` |
| Bundled DXVK copies | checked in | [`../dxvk/1.10.3/`](../dxvk/1.10.3/) and [`../dxvk/latest/`](../dxvk/latest/) |

`PLAY_CACHE_DIR` defaults to `~/.cache/play`. The FPS layer build needs `gcc`
and `vulkan/vulkan.h`; the GPU probe build tries `-lvulkan` and then the full
`libvulkan.so.1` path from `ldconfig`. If the FPS layer cannot be built, the
game still launches without the HUD's FPS meter.

## Target platforms

- Linux only. The launcher reads `/etc/os-release`, uses `/tmp`, Wine prefixes,
  and POSIX symlinks; README names Ubuntu and Fedora, with Arch and openSUSE
  package hints also present in both scripts.
- A Vulkan-capable GPU driver and Wine with Vulkan support are required for the
  game path. GE-Proton is preferred but is user-managed; the installer does not
  download it.
- No Windows or macOS target, Docker image, systemd unit, package recipe,
  desktop-entry file, or CI/CD workflow exists in the project directory.

## Verification and rollback

Useful post-install checks are `play --version` and `play --help`; the manual
checks that were actually run are recorded in [`testing.md`](./testing.md).
Game, GPU, and installer behavior still needs real hardware and a disposable
environment.

Uninstall commands from [`../README.md`](../README.md):

```bash
rm -f ~/.local/bin/play               # remove the launcher symlink
rm -rf ~/.local/share/play            # remove the program
rm -rf ~/.cache/play                  # remove the compiled FPS layer
rm -rf ~/.config/play                 # remove the config file (optional)
```

Then remove the `# play launcher` PATH line from `~/.bashrc` if it was added.
With custom `PLAY_HOME` or `PLAY_BIN_DIR`, remove those paths instead.

## Known gaps

- No signed artifacts or checksums: the installer and DXVK download paths use
  HTTPS but pin no hashes.
- `install.sh` deletes and recreates `PLAY_HOME`; it does not preserve local
  edits or provide a versioned rollback.
- No automated post-install smoke test; only the CLI and syntax checks in
  [`testing.md`](./testing.md) were performed here.
- Installer behavior, GitHub downloads, DXVK fallback paths, and Wine launches
  were not executed in this environment.

## Sources

[`../README.md`](../README.md), [`../install.sh`](../install.sh),
[`../play.sh`](../play.sh), [`../config.example`](../config.example),
[`../dxvk/`](../dxvk/), [`testing.md`](./testing.md).
