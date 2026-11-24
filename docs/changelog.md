# play changelog

There is no `CHANGELOG.md`, `RELEASES.md`, or release-notes file committed in
this project. The current version is the `VERSION="0.9.2"` constant in
[`../play.sh`](../play.sh), which is what `play --version` prints. The
`PLAY_VERSION=v0.8.1` value in [`../README.md`](../README.md) is only an
example of installing a specific tag, not the current version.

## Release history in Git metadata

Local Git tags and commit metadata are the only release history available from
the repository. The dates below are from the tagged commits; summaries are the
tag annotation subjects.

| Tag | Tagged commit | Date | Recorded summary |
| --- | --- | --- | --- |
| `v0.8.0` | `290a09c` | 2026-08-10 | Add `--version`, release installer, README install docs |
| `v0.8.1` | `64f8684` | 2026-08-11 | HUD CPU/GPU temperature inline, RAM in GB, drag-to-move, GTK deprecation cleanup, `nvidia-smi` caching, per-meter sampling |
| `v0.9.0` | `fd93a17` | 2026-08-14 | Fedora support: distro-aware package hints and `--deps` installer |
| `v0.9.2` | `5253d60` | 2026-08-15 | Automatic GPU detection via `vkdevs`, automatic DXVK install, PRIME white-screen fix |

`v0.9.2` is both the latest local tag and the version in `play.sh`. No `v0.9.1`
tag exists locally. GitHub release bodies were not consulted, so no additional
release notes or download counts are claimed here.

## Where to look next

- [`../play.sh`](../play.sh) — current behavior and version constant.
- [`../README.md`](../README.md) — user-facing feature and install history.
- [`deployment.md`](./deployment.md) — how releases are installed and where
  files land.
- Git tags and log in the project checkout — the source of the table above.

## Sources

[`../play.sh`](../play.sh), [`../README.md`](../README.md), local `git tag -n99`
and `git log --tags --no-walk` output from the `play` checkout.
