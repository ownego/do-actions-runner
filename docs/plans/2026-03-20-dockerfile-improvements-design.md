# Dockerfile Improvements Design

## Summary

Best-practices overhaul of the Dockerfile covering bugs, image size, security, and layer optimization.

## Changes

### Bug fixes
- Removed `sudo` from Docker GPG key and repo setup (running as root, sudo unnecessary)
- Fixed `parcel-bundler` (deprecated) to `parcel`
- Removed meaningless `--save-dev` from global npm install
- Removed redundant `npm install -g npm`

### Image size
- Added `rm -rf /var/lib/apt/lists/*` after every apt-get layer
- Runner tarball cleaned up after extraction
- Combined Docker install steps into single layer

### Security and portability
- Added `DEBIAN_FRONTEND=noninteractive`
- Dynamic architecture detection via `dpkg --print-architecture` (Docker repo and runner download)
- Architecture mapping: `amd64` → `x64` for GitHub runner download
- Used `$(. /etc/os-release && echo "$VERSION_CODENAME")` instead of `lsb_release -cs`
- Added `.dockerignore` to exclude `.git`, `.idea`, `images/`, docs from build context

### Layer optimization
- Proper variable quoting throughout
- Combined Docker GPG + repo + install into one RUN layer
