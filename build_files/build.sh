#!/bin/bash

set -ouex pipefail

### Install packages

# Packages can be installed from any enabled yum repo on the image.
# RPMfusion repos are available by default in ublue main images
# List of rpmfusion packages can be found here:
# https://mirrors.rpmfusion.org/mirrorlist?path=free/fedora/updates/39/x86_64/repoview/index.html&protocol=https&redirect=1

# PREPARE PACKAGES
# Save package list in /usr/
mkdir -p /usr/local/share/os-template
cp /ctx/packages-add /usr/local/share/os-template/packages-add
cp /ctx/packages-remove /usr/local/share/os-template/packages-remove
jq -r .packages[] /usr/share/rpm-ostree/treefile.json > /usr/local/share/os-template/packages-fedora-bootc
chmod  0644 /usr/local/share/os-template/*

# INSTALL THIRD PARTY REPOS
dnf5 -y install 'dnf5-command(copr)'
dnf5 -y copr enable avengemedia/dms
dnf5 -y copr enable atim/starship
dnf5 -y copr enable lihaohong/yazi
dnf5 -y copr enable varlad/zellij

# INSTALL PACKAGES
grep -vE '^#' /usr/local/share/os-template/packages-add | xargs dnf5 -y install --allowerasing --setopt=install_weak_deps=False

# REMOVE PACKAGES
# grep -vE '^#' /usr/local/share/os-template/packages-remove | xargs dnf5 -y remove
# dnf5 -y autoremove
# dnf5 clean all

# Disable repos so they don't appear in final image
dnf5 -y copr disable avengemedia/dms
dnf5 -y copr disable atim/starship
dnf5 -y copr disable lihaohong/yazi
dnf5 -y copr disable varlad/zellij

## Hardware and system packages
# Lenovo thinkpad fan control
systemctl enable zcfan.service

# Zram (ram compression to avoid swaping)
tee /usr/lib/systemd/zram-generator.conf <<'EOF'
[zram0]
zram-size = min(ram / 2, 8192)
EOF


## Desktop environment : Niri window manager and DankMaterial shell
# https://github.com/YaLTeR/niri/wiki/Getting-Started
# https://github.com/AvengeMedia/DankMaterialShell

add_wants_niri() {
    sed -i "s/\[Unit\]/\[Unit\]\nWants=$1/" "/usr/lib/systemd/user/niri.service"
}

add_wants_niri dms.service
add_wants_niri udiskie.service
# add_wants_niri swayidle.service
# add_wants_niri foot.service

# sed -i 's|spawn-at-startup "waybar"|// spawn-at-startup "waybar"|' "/usr/share/doc/niri/default-config.kdl"
#
# systemctl enable --global gnome-keyring-daemon.socket
# systemctl enable --global gnome-keyring-daemon.service

mkdir /var/cache/dms-greeter
chown greetd:greetd /var/cache/dms-greeter
sed -i 's|user = "greeter"|user = "greetd"|' "/etc/greetd/config.toml"
sed -i '/gnome_keyring.so/ s/-auth/auth/ ; /gnome_keyring.so/ s/-session/session/' /etc/pam.d/greetd
systemctl enable greetd

## Package and software management : Distrobox, Flatpak and Nix
# TODO: Install nix (https://gist.github.com/queeup/1666bc0a5558464817494037d612f094)
# https://github.com/89luca89/distrobox
# https://docs.flatpak.org/en/latest/getting-started.html


# Replace fedora flatpak repos with flathub
# mkdir -p /etc/flatpak/remotes.d/
# curl --retry 3 -Lo /etc/flatpak/remotes.d/flathub.flatpakrepo https://dl.flathub.org/repo/flathub.flatpakrepo
# rm -rf /usr/lib/systemd/system/flatpak-add-fedora-repos.service
# systemctl enable flatpak-add-flathub-repos.service

### Systemd units
systemctl enable podman.socket
systemctl enable systemd-timesyncd
systemctl enable systemd-resolved.service

systemctl mask rpm-ostree-countme.timer

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
# dnf5 -y remove usbmuxd
