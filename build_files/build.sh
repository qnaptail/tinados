#!/bin/bash

set -ouex pipefail

### Install packages

# Packages can be installed from any enabled yum repo on the image.
# RPMfusion repos are available by default in ublue main images
# List of rpmfusion packages can be found here:
# https://mirrors.rpmfusion.org/mirrorlist?path=free/fedora/updates/39/x86_64/repoview/index.html&protocol=https&redirect=1

# this installs a package from fedora repos
# dnf5 install -y tmux

# install niri and core desktop packages
# dnf5 install -y niri xdg-desktop-portal-wlr waybar acpi swaybg swaylock swayidle mako fuzzel brightnessctl gammastep pavucontrol egl-wayland xwayland-satellite yad

# install niri and dankmaterialshell
# https://github.com/YaLTeR/niri/wiki/Getting-Started
# dnf -y install dnf5-plugins
# dnf config-manager addrepo --from-repofile=https://pkgs.tailscale.com/stable/fedora/tailscale.repo

dnf -y upgrade --refresh
dnf -y copr enable avengemedia/dms
dnf -y install niri dms
dnf -y copr disable avengemedia/dms

# install Distrobox and Flatpak
dnf -y install distrobox flatpak

# install foot terminal and fira code fonts
dnf -y install foot fira-code-fonts

# Use a COPR Example:
#
# dnf5 -y copr enable ublue-os/staging
# dnf5 -y install package
# Disable COPRs so they don't end up enabled on the final image:
# dnf5 -y copr disable ublue-os/staging

#### Example for enabling a System Unit File

systemctl enable podman.socket
