# rcm-installer

Public installer for **RemoteCodeManager** (the source repo is private).

Install on a fresh Debian/Ubuntu box:

    curl -fsSL https://raw.githubusercontent.com/Anh-Jo/rcm-installer/main/bootstrap.sh | sh

It installs the prerequisites (git, tmux, build tools via one `sudo apt`; a local
Node with no root), downloads the latest release tarball, and runs the installer
wizard (which asks for the bind address and public origin). The daemon then
serves the whole app on one port.

Release tarballs (`rcm.tar.gz`) are published here automatically by CI on each
RemoteCodeManager release.
