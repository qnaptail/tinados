#!/bin/bash

set -ouex pipefail

# Remove unnecessary files
rm -rf /usr/share/doc
rm -rf /usr/src

# Clean all build files
dnf5 clean all
rpm-ostree cleanup --repomd
rm -rf /tmp/* || true

# Clean /var directory while preserving essential files
find /var/* -maxdepth 0 -type d \! -name cache \! -name home \! -name nix -exec rm -fr {} \;
find /var/cache/* -maxdepth 0 -type d \! -name libdnf5 \! -name rpm-ostree -exec rm -fr {} \;

mkdir -p /var/tmp
chmod -R 1777 /var/tmp
