#!/bin/sh
#
# RemoteCodeManager bootstrap — install on a fresh Debian/Ubuntu box with:
#
#   curl -fsSL <host>/bootstrap.sh | sh
#
# It installs system packages (git, tmux, build tools — one sudo prompt), a
# LOCAL Node (no system Node, no root; corepack provides pnpm), downloads the
# app tarball, and runs the installer wizard (which asks for the bind address
# and public origin). The user never touches Node or pnpm.
#
# Override via env: RCM_TARBALL_URL, RCM_DIR, NODE_VERSION, RCM_HOST, RCM_ORIGIN.
set -eu

RCM_TARBALL_URL="${RCM_TARBALL_URL:-https://github.com/Anh-Jo/rcm-installer/releases/latest/download/rcm.tar.gz}"
RCM_DIR="${RCM_DIR:-$HOME/rcm}"
NODE_VERSION="${NODE_VERSION:-22.11.0}"
NODE_DIR="$HOME/.local/share/rcm/node"

say() { printf '\033[1;36m==>\033[0m %s\n' "$*"; }
die() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

command -v curl >/dev/null 2>&1 || die "curl is required"

# 1) System packages (need root). Node stays user-local in step 2.
need=0
for c in git tmux make cc python3; do
  command -v "$c" >/dev/null 2>&1 || need=1
done
if [ "$need" -eq 1 ]; then
  command -v sudo >/dev/null 2>&1 ||
    die "git/tmux/build tools missing and no sudo; install them, then re-run"
  say "Installing system packages (git, tmux, build tools) — sudo"
  sudo apt-get update -y
  sudo apt-get install -y git tmux build-essential python3
fi

# 2) Local Node (cached in $NODE_DIR; no root). corepack provides pnpm.
if [ ! -x "$NODE_DIR/bin/node" ]; then
  case "$(uname -m)" in
    x86_64) narch=x64 ;;
    aarch64 | arm64) narch=arm64 ;;
    *) die "unsupported architecture $(uname -m)" ;;
  esac
  say "Installing Node $NODE_VERSION (local, no root)"
  node_tar="$(mktemp)"
  curl -fsSL "https://nodejs.org/dist/v$NODE_VERSION/node-v$NODE_VERSION-linux-$narch.tar.xz" -o "$node_tar"
  mkdir -p "$NODE_DIR"
  tar -xJf "$node_tar" -C "$NODE_DIR" --strip-components=1
  rm -f "$node_tar"
fi
PATH="$NODE_DIR/bin:$PATH"
export PATH
corepack enable >/dev/null 2>&1 || true

# 3) Download and extract the app tarball.
say "Downloading RemoteCodeManager"
app_tar="$(mktemp)"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp" "$app_tar"' EXIT
curl -fsSL "$RCM_TARBALL_URL" -o "$app_tar"
tar -xzf "$app_tar" -C "$tmp"
src="$(find "$tmp" -mindepth 1 -maxdepth 1 -type d | head -1)"
[ -n "$src" ] || die "unexpected tarball layout"
mkdir -p "$(dirname "$RCM_DIR")"
rm -rf "$RCM_DIR"
mv "$src" "$RCM_DIR"

# 4) Run the wizard. install.sh is bash and reads prompts from /dev/tty, so it
#    stays interactive even though this script arrived on stdin (curl | sh).
say "Installing into $RCM_DIR"
cd "$RCM_DIR"
exec bash scripts/install.sh
