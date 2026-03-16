#!/bin/bash

set -ouex pipefail

#######################################################################
# PREPARE
#######################################################################

dnf5 -y install 'dnf5-command(copr)'

mkdir -p /etc/skel/.config/
mkdir -p /etc/skel/.local/bin/
cp -ravf /ctx/rootfs/etc/skel/.local/bin/tinados /etc/skel/.local/bin/

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
    pipewire
    pipewire-pulseaudio
    pipewire-alsa
    pipewire-jack-audio-connection-kit
    pipewire-plugin-libcamera
    wireplumber
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

dnf5 -y install "${packages[@]}" --allowerasing

##########################################################
# PACKAGES & SOFTWARE MANAGEMENT
##########################################################

# TODO: Install NIX

# https://github.com/89luca89/distrobox
# https://docs.flatpak.org/en/latest/getting-started.html

packages=(
    distrobox
    flatpak
    nix
    nix-daemon
)
dnf5 -y install "${packages[@]}"

cp -ravf /ctx/rootfs/etc/skel/flatpak.list /etc/skel/

# tar --create --verbose --preserve-permissions \
#   --same-owner \
#   --file /etc/nix-setup.tar \
#   -C / nix

#   mkdir -p /var/lib/nix; \
#   tar --extract --verbose --preserve-permissions --same-owner \
#       --strip-components=1 \
#       --file /etc/nix-setup.tar \
#       -C /var/lib/nix; \

mkdir -p /var/lib/
cp -ravf /nix /var/lib/
rm -rf /nix
ln -s /var/lib/nix /nix

## Symlink /nix to /var/nix to make the nix store writable (does not work)
# cp -r /nix /var/ && rm -rf /nix && ln -s /var/nix /nix

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
