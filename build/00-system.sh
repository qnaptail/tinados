#!/bin/bash

set -ouex pipefail

#######################################################################
# PREPARE
#######################################################################

# Enable third party repos
dnf5 -y install 'dnf5-command(copr)'

cp -ravf "/ctx/rootfs/etc/skel/.bashrc" /etc/skel/.bashrc

##########################################################
# HARDWARE & SYSTEM PACKAGES
##########################################################

packages=(

    @hardware-support

    ### INFOS
    pciutils
    usbutils
    vulkan-tools
    libva-utils
    lm_sensors

    ### DISK
    ntfs-3g
    nfs-utils

    ### NETWORK
    NetworkManager
    NetworkManager-wifi
    nmap
    bind-utils
    firewalld
    wireguard-tools
    tailscale
    wget
    wol

    ### MULTIMEDIA
    easyeffects
    feh

    ### POWER MANAGEMENT
    power-profiles-daemon
    powertop
    #tlp
    zcfan

    ### FINGERPRINT SENSOR
    fprintd
    fprintd-pam

    ### LOCALE & FONTS
    glibc-all-langpacks
    default-fonts-core-emoji
    google-noto-color-emoji-fonts
    google-noto-emoji-fonts
    fira-code-fonts
    fontawesome-fonts-all
    jetbrains-mono-fonts

    ### VIRTUALISATION
    incus
    incus-tools
    libvirt-daemon-kvm
    libvirt-daemon-config-network
    virt-install
    virt-viewer
    virt-manager

)

dnf5 -y install "${packages[@]}"

##########################################################
# PACKAGES & SOFTWARE MANAGEMENT
##########################################################

# https://github.com/89luca89/distrobox
# https://docs.flatpak.org/en/latest/getting-started.html

packages=(
    distrobox
    flatpak
)
dnf5 -y install "${packages[@]}"

# TODO: Install NIX
#nix

#######################################################################
# ENABLE ZRAM
#######################################################################

tee /usr/lib/systemd/zram-generator.conf <<'EOF'
[zram0]
zram-size = min(ram / 2, 8192)
EOF

#######################################################################
# USERS
#######################################################################

# TODO: systemhomed
## Create default user for VM images
useradd -m  tinados
usermod -aG wheel tinados
echo "tinados:tinados" | chpasswd
