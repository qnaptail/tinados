#!/bin/bash

set -ouex pipefail

### Install packages

# Packages can be installed from any enabled yum repo on the image.
# RPMfusion repos are available by default in ublue main images
# List of rpmfusion packages can be found here:
# https://mirrors.rpmfusion.org/mirrorlist?path=free/fedora/updates/39/x86_64/repoview/index.html&protocol=https&redirect=1

## Hardware and system packages
dnf5 -y group install \
        hardware-support

dnf5 -y install \
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

# Lenovo thinkpad power and fan control
dnf5 -y install \
        thinkfan

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
dnf5 -y install \
        distrobox \
        flatpak

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

### Troubleshooting

## The systemd-remount-fs service fails on boot because the root filesystem on an ostree system is read-only by design.
# We can mask it to avoid harmless log errors.
# https://gitlab.com/fedora/ostree/sig/-/issues/72
systemctl mask systemd-remount-fs.service

## The systemd-sysusers service is failing to started
# systemd-sysusers return the following error : /etc/shadow: Group "usbmuxd" already exists.
# seems like the group is defined twice in the /usr/lib/sysusers.d/usbmuxd.conf
#       g usbmuxd 113
#       u usbmuxd 113:113 "usbmuxd user"
# we can comment the first line in the config file :
# sed -i 's|\(g\s*usbmuxd\s*113\)|# \1|' /usr/lib/sysusers.d/usbmuxd.conf
# we can also remove the package :
dnf5 -y remove usbmuxd
