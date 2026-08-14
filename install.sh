#!/usr/bin/env bash
# play installer — installs the play launcher and links it into your PATH.
#
#   curl -fsSL https://raw.githubusercontent.com/Omar-Khaled-57/play/main/install.sh | bash
#
# Options (environment variables):
#   PLAY_VERSION   release tag to install, or "latest" (default: latest)
#   PLAY_HOME      install directory (default: ~/.local/share/play)
#   PLAY_BIN_DIR   directory for the play symlink (default: ~/.local/bin)
set -euo pipefail

REPO="Omar-Khaled-57/play"
VERSION="${PLAY_VERSION:-latest}"
INSTALL_DIR="${PLAY_HOME:-$HOME/.local/share/play}"
BIN_DIR="${PLAY_BIN_DIR:-$HOME/.local/bin}"

info() { printf '\033[32m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[33m!\033[0m %s\n' "$*"; }
die() { printf '\033[31merror:\033[0m %s\n' "$*" >&2; exit 1; }

# Distro-aware package helpers. play is developed on Ubuntu but is a first-class
# citizen on Fedora (dnf), Arch (pacman) and openSUSE (zypper) out of the box.
pkg_mgr() {
  if [ -r /etc/os-release ]; then
    case "$(sed -n 's/^ID=//p' /etc/os-release | tr -d '"')" in
      fedora|rhel|centos|rocky|alma) echo dnf ;;
      arch|manjaro|endeavouros) echo pacman ;;
      opensuse*|suse) echo zypper ;;
      *) echo apt ;;
    esac
  else
    echo apt
  fi
}
pkg_name() { # debian-style package name -> this distro's name
  case "$(pkg_mgr)" in
    dnf|pacman)
      case "$1" in
        libvulkan-dev) echo vulkan-headers ;;
        python3-gi) echo python3-gobject ;;
        python3-gi-cairo) echo python3-cairo ;;
        gir1.2-gtk-3.0) echo gtk3 ;;
        *) echo "$1" ;;
      esac ;;
    *) echo "$1" ;;
  esac
}
pkg_install() { # echo the package-manager command to install the given deps
  local pkgs p
  for p in "$@"; do pkgs="${pkgs:+$pkgs }$(pkg_name "$p")"; done
  case "$(pkg_mgr)" in
    dnf) echo "sudo dnf install $pkgs" ;;
    pacman) echo "sudo pacman -S --needed $pkgs" ;;
    zypper) echo "sudo zypper install $pkgs" ;;
    *) echo "sudo apt install $pkgs" ;;
  esac
}

command -v curl >/dev/null 2>&1 || die "curl is required ($(pkg_install curl))"
command -v tar  >/dev/null 2>&1 || die "tar is required"

case "${1:-}" in
  -d|--deps)
    info "installing play's runtime dependencies for your distro..."
    eval "$(pkg_install curl tar gcc libvulkan-dev python3-gi gir1.2-gtk-3.0 vulkan-tools)"
    info "dependencies installed. re-run without --deps to install play."
    exit 0
    ;;
esac

if [ "$VERSION" = latest ]; then
  info "resolving latest release of $REPO"
  TARBALL_URL="$(curl -fsSL "https://api.github.com/repos/$REPO/releases/latest" \
    | grep -o '"tarball_url": *"[^"]*"' \
    | sed 's/.*"\(http[^"]*\)".*/\1/')"
  [ -n "$TARBALL_URL" ] || die "could not resolve the latest release of $REPO"
else
  TARBALL_URL="https://github.com/$REPO/archive/refs/tags/$VERSION.tar.gz"
fi

STAGE="$(mktemp -d)"
trap 'rm -rf "$STAGE"' EXIT

info "downloading $TARBALL_URL"
curl -fsSL "$TARBALL_URL" | tar -xz -C "$STAGE"

SRC="$STAGE/$(ls "$STAGE" | head -n 1)"
[ -f "$SRC/play.sh" ] || die "downloaded archive has no play.sh — is $VERSION a valid release?"

mkdir -p "$(dirname "$INSTALL_DIR")" "$BIN_DIR"
info "installing to $INSTALL_DIR"
rm -rf "$INSTALL_DIR"
mv "$SRC" "$INSTALL_DIR"
chmod +x "$INSTALL_DIR/play.sh" "$INSTALL_DIR/hud" "$INSTALL_DIR/typo.sh" 2>/dev/null || true

info "linking $BIN_DIR/play -> $INSTALL_DIR/play.sh"
ln -sf "$INSTALL_DIR/play.sh" "$BIN_DIR/play"

case ":$PATH:" in
  *":$BIN_DIR:"*) ;;
  *)
    if [ -n "${ZSH_VERSION:-}" ] && [ -z "${BASH_VERSION:-}" ]; then
      SHELLRC="$HOME/.zshrc"
    else
      SHELLRC="$HOME/.bashrc"
    fi
    {
      printf '\n# play launcher\nexport PATH="%s:$PATH"\n' "$BIN_DIR"
    } >> "$SHELLRC"
    warn "added $BIN_DIR to PATH in $SHELLRC (restart your shell, or run: export PATH=\"$BIN_DIR:\$PATH\")"
    ;;
esac

"$BIN_DIR/play" --version
printf '\nDone. Run \033[1mplay --help\033[0m to get started.\n'
