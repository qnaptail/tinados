#!/bin/bash

set -ouex pipefail

#######################################################################
# ENABLE ZRAM
#######################################################################

tee /usr/lib/systemd/zram-generator.conf <<'EOF'
[zram0]
zram-size = min(ram / 2, 8192)
EOF

#######################################################################
# CREATE DEFAULT USER
#######################################################################

## Create default user for VM images
# useradd -m  tinados
# usermod -aG wheel tinados
# echo "tinados:tinados" | chpasswd

#######################################################################
# CONFIGURATION
#######################################################################

## Copy all config files from rootfs directory to the system
cp -avf "/ctx/rootfs"/. /

