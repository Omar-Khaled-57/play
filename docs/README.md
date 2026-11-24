# play — documentation index

Everything needed to install, run, configure, and contribute to `play`, a Linux
Wine + DXVK game launcher with an optional system/FPS HUD.

## Start here

- [`../README.md`](../README.md) — pitch, features, requirements, install,
  quick start, modes, HUD controls, configuration, and troubleshooting.
- [`product.md`](./product.md) — what the launcher does and what it does not
  promise.
- [`configuration.md`](./configuration.md) — config file, environment
  variables, defaults, and files written at runtime.
- [`testing.md`](./testing.md) — manual verification only; there is no
  automated test suite.

## Documentation index

| Page | Covers |
| --- | --- |
| [`../README.md`](../README.md) | User guide, install, modes, HUD, config summary, troubleshooting, license |
| [`product.md`](./product.md) | Problem, audience, feature inventory, non-goals, gaps |
| [`architecture.md`](./architecture.md) | Bash/Python/C components, entry points, startup and launch flow |
| [`development.md`](./development.md) | Prerequisites, local run, command reference, conventions, manual checks |
| [`configuration.md`](./configuration.md) | `config.example`, all env vars, modes, paths, security notes |
| [`testing.md`](./testing.md) | Syntax/CLI checks that were actually run; unverified runtime paths |
| [`deployment.md`](./deployment.md) | Release installer, install paths, platforms, rollback |
| [`changelog.md`](./changelog.md) | Release history pointers (or their absence) |
| [`visual-identity.md`](./visual-identity.md) | HUD visual contract |
| [`../config.example`](../config.example) | Template config file |

## Canonical sources of truth

| Subject | File |
| --- | --- |
| Launcher behavior and version (`0.9.2`) | [`../play.sh`](../play.sh) |
| Installer behavior | [`../install.sh`](../install.sh) |
| HUD rendering, controls, env reads | [`../hud`](../hud) |
| FPS layer implementation | [`../fpslayer/play_fps.c`](../fpslayer/play_fps.c), [`../fpslayer/play_fps.json`](../fpslayer/play_fps.json) |
| GPU probe implementation | [`../vkdevs/vkdevs.c`](../vkdevs/vkdevs.c) |
| Config keys and defaults | [`../config.example`](../config.example), [`../README.md`](../README.md) |
| Bundled DXVK versions | [`../dxvk/1.10.3/`](../dxvk/1.10.3/), [`../dxvk/latest/`](../dxvk/latest/) |

## Known gaps

- No automated test suite, test runner, or CI configuration exists; see
  [`testing.md`](./testing.md).
- No `CHANGELOG.md` or release-notes file is committed; release history exists
  only as local Git tags and commit metadata; see [`changelog.md`](./changelog.md).
- `~/.config/play/config` is user-owned and not committed; only
  `config.example` is tracked.
- The HUD script's own docstring defaults `PLAY_FPS_FILE` to
  `/tmp/play/fps.txt`, while `play.sh` sets a per-game path
  `/tmp/play/fps-<game>.txt` when `hud` mode is used with a game. Both are
  documented in [`configuration.md`](./configuration.md).
- Wayland-only sessions cannot rely on HUD corner positioning; the launcher
  needs `DISPLAY`/XWayland for that behavior.

## Sources

[`../README.md`](../README.md), [`../play.sh`](../play.sh),
[`../install.sh`](../install.sh), [`../hud`](../hud),
[`../config.example`](../config.example), [`../dxvk/`](../dxvk/).
