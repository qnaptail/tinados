#!/bin/bash

set -ouex pipefail

### Install packages

# Packages can be installed from any enabled yum repo on the image.
# RPMfusion repos are available by default in ublue main images
# List of rpmfusion packages can be found here:
# https://mirrors.rpmfusion.org/mirrorlist?path=free/fedora/updates/39/x86_64/repoview/index.html&protocol=https&redirect=1

## Hardware and system packages
dnf5 -y group install \
        hardware-support \
        glibc-langpack-fr

# Network
dnf5 -y install \
        NetworkManager-wifi

# Audio
dnf5 -y install \
        alsa-firmware \
        alsa-sof-firmware \
        alsa-tools-firmware \
        intel-audio-firmware

## Desktop environment : Niri window manager and DankMaterial shell
# https://github.com/YaLTeR/niri/wiki/Getting-Started
# https://github.com/AvengeMedia/DankMaterialShell
# dnf5 install -y niri xdg-desktop-portal-wlr waybar acpi swaybg swaylock swayidle mako fuzzel brightnessctl gammastep pavucontrol egl-wayland xwayland-satellite yad
dnf5 -y install 'dnf5-command(copr)'
dnf5 -y copr enable avengemedia/dms
dnf5 -y install \
        niri \
        dms
dnf5 -y copr disable avengemedia/dms

# systemctl --user add-wants niri.service dms

## Package and software management : Distrobox, Flatpak and Nix
# https://github.com/89luca89/distrobox
# https://docs.flatpak.org/en/latest/getting-started.html
# dnf5 -y install \
#         distrobox \
#         flatpak

dnf5 -y install \
        distrobox

## Terminal utils
dnf5 -y install \
        foot \
        fish \
        vim \
        fira-code-fonts

### Systemd units
systemctl enable podman.socket
systemctl enable systemd-timesyncd
systemctl enable systemd-resolved.service
