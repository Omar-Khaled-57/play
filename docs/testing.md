# play testing

## No automated suite

`play` has no test runner, test directory, manifest-declared scripts, or CI
configuration in this repository. There are no unit tests, integration tests,
snapshots, or coverage reports. Nothing in this document should be read as an
automated pass.

## Manual verification performed

These checks were run from the repository root and from `play/` respectively.
They verify syntax and the non-interactive CLI only.

| Check | Command | Result |
| --- | --- | --- |
| Bash syntax | `bash -n play/play.sh` | passed |
| Bash syntax | `bash -n play/install.sh` | passed |
| Bash syntax | `bash -n play/typo.sh` | passed |
| Python syntax | `python3 -m py_compile play/hud` | passed |
| Version flag | `./play.sh --version` | printed `play 0.9.2` |
| Help flag | `./play.sh --help` | printed banner, usage, modes, config keys, and examples |

`python3 -m py_compile` may create a `.pyc` bytecode cache; remove
`__pycache__/` if you want a clean checkout.

## What a developer should verify manually

The following require a real desktop, Wine, GPU drivers, and a game; they were
**not** run during documentation:

| Area | Manual check |
| --- | --- |
| Game launch | `play /path/to/game.exe` starts Wine with the expected GPU and DXVK DLLs |
| Modes | `play game.exe Bep hud`, `play game.exe MangoHud`, and mode-after-argument behavior |
| HUD | `play hud` overlay appears, drag/scroll/right-click work, values update |
| FPS layer | compile succeeds and FPS appears for a Vulkan/DXVK game |
| GPU probe | `vkdevs/vkdevs.c` builds and `PICK` selects the discrete card |
| DXVK fallback | bundled, distro, and download paths each work on the target distro |
| Installer | `install.sh`, `--deps`, `PLAY_VERSION`, `PLAY_HOME`, `PLAY_BIN_DIR` in a disposable environment |
| Wayland | document where the HUD appears when there is no `DISPLAY` |

Useful non-destructive entry points for these checks are `play --help`,
`play --version`, and `play hud` (quit with right-click or Ctrl-C).

## Known gaps

- No automated regression protection for the mode parser, DXVK selection, or
  HUD rendering.
- No hardware-in-the-loop tests, no recorded game sessions, no screenshots
  committed for visual comparison.
- `README.md` describes expected behavior, but this document records only what
  was actually observed in this environment.

## Sources

[`../play.sh`](../play.sh), [`../install.sh`](../install.sh), [`../hud`](../hud),
[`../README.md`](../README.md); command output from the manual checks above.
