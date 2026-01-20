#!/bin/bash

set -ouex pipefail

#######################################################################
# NIRI WM
#######################################################################

# https://github.com/YaLTeR/niri/wiki/Getting-Started

add_wants_niri() {
    sed -i "s/\[Unit\]/\[Unit\]\nWants=$1/" "/usr/lib/systemd/user/niri.service"
}

packages=(
  niri
  fuzzel
  udiskie
  waybar
  swayidle
  swaylock
  cliphist
  wl-clipboard
  # brightnessctl
  # gammastep
  # pavucontrol
  # mako
  adw-gtk3-theme
  qt6ct
  # fontawesome-6-brands-fonts
  # fontawesome-6-free-fonts
  gnome-keyring
  gnome-keyring-pam
  xdg-desktop-portal-gnome
  xwayland-satellite
)
dnf5 -y install "${packages[@]}" --setopt=install_weak_deps=False

# Services
add_wants_niri foot.service
add_wants_niri udiskie.service
add_wants_niri swayidle.service
systemctl enable --global gnome-keyring-daemon.socket
systemctl enable --global gnome-keyring-daemon.service

# Config
cp -ravf /ctx/rootfs/etc/skel/.config/niri /etc/skel/.config/
cp -ravf /ctx/rootfs/etc/skel/.config/fuzzel /etc/skel/.config/
cp -ravf /ctx/rootfs/usr/share/xdg-desktop-portal /usr/share/


#######################################################################
# DANK MATERIAL SHELL
#######################################################################

# https://github.com/AvengeMedia/DankMaterialShell

dnf5 -y copr enable avengemedia/dms
packages=(
  dms
  NetworkManager
  cava
  danksearch
  matugen
  xdg-utils
  xdriinfo
)
dnf5 -y install "${packages[@]}" --setopt=install_weak_deps=False
dnf5 -y copr disable avengemedia/dms

add_wants_niri dms.service


#######################################################################
# DISPLAY MANAGER
#######################################################################

# https://danklinux.com/docs/dankgreeter/

dnf5 -y copr enable avengemedia/dms
packages=(
  greetd
  greetd-selinux
  dms-greeter
  acl
)
dnf5 -y install "${packages[@]}" --setopt=install_weak_deps=False
dnf5 -y copr disable avengemedia/dms

mkdir /var/cache/dms-greeter
chown greetd:greetd /var/cache/dms-greeter
sed -i 's|user = "greeter"|user = "greetd"|' "/etc/greetd/config.toml"
sed -i '/gnome_keyring.so/ s/-auth/auth/ ; /gnome_keyring.so/ s/-session/session/' /etc/pam.d/greetd

systemctl enable greetd
