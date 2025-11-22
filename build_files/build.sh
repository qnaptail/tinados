#!/bin/bash

set -ouex pipefail

### Install packages

# Packages can be installed from any enabled yum repo on the image.
# RPMfusion repos are available by default in ublue main images
# List of rpmfusion packages can be found here:
# https://mirrors.rpmfusion.org/mirrorlist?path=free/fedora/updates/39/x86_64/repoview/index.html&protocol=https&redirect=1

## Hardware and system packages
# dnf5 -y install \
#         @hardware-support

dnf5 -y install \
        pciutils \
        usbutils \
        usb_modeswitch

# Network
dnf5 -y install \
        NetworkManager-wifi \
        iwlwifi-dvm-firmware \
        iwlwifi-mld-firmware \
        iwlwifi-mvm-firmware

# Audio
dnf5 -y install \
        alsa-firmware \
        alsa-sof-firmware \
        alsa-tools-firmware \
        intel-audio-firmware

# Lenovo thinkpad power and fan control
dnf5 -y install \
        power-profiles-daemon \
        zcfan

systemctl enable zcfan.service

# Zram (ram compression to avoid swaping)
tee /usr/lib/systemd/zram-generator.conf <<'EOF'
[zram0]
zram-size = min(ram / 2, 8192)
EOF

## Desktop environment : Niri window manager and DankMaterial shell
# https://github.com/YaLTeR/niri/wiki/Getting-Started
# https://github.com/AvengeMedia/DankMaterialShell
# dnf5 install -y niri xdg-desktop-portal-wlr waybar acpi swaybg swaylock swayidle mako fuzzel brightnessctl gammastep pavucontrol egl-wayland xwayland-satellite yad
dnf5 -y install \
        niri \
        greetd \
        greetd-selinux \
        udiskie \
        gnome-keyring \
        gnome-keyring-pam \
        fprintd \
        fprintd-pam

dnf5 -y install 'dnf5-command(copr)'
dnf5 -y copr enable avengemedia/dms
dnf5 -y install --setopt=install_weak_deps=False \
        dms \
        dms-greeter


# dnf5 -y install --setopt=install_weak_deps=False \
#         dms \
#         dms-cli \
#         dms-greeter \
#         dgop
dnf5 -y copr disable avengemedia/dms

add_wants_niri() {
    sed -i "s/\[Unit\]/\[Unit\]\nWants=$1/" "/usr/lib/systemd/user/niri.service"
}
add_wants_niri dms.service
# add_wants_niri swayidle.service
add_wants_niri udiskie.service
# add_wants_niri foot.service

# sed -i 's|spawn-at-startup "waybar"|// spawn-at-startup "waybar"|' "/usr/share/doc/niri/default-config.kdl"
#
# systemctl enable --global gnome-keyring-daemon.socket
# systemctl enable --global gnome-keyring-daemon.service

mkdir /var/cache/dms-greeter
chown greetd:greetd /var/cache/dms-greeter
# chown greeter:greeter /var/cache/dms-greeter

sed -i 's|user = "greeter"|user = "greetd"|' "/etc/greetd/config.toml"
sed -i '/gnome_keyring.so/ s/-auth/auth/ ; /gnome_keyring.so/ s/-session/session/' /etc/pam.d/greetd

systemctl enable greetd

## Package and software management : Distrobox, Flatpak and Nix
# TODO: Install nix (https://gist.github.com/queeup/1666bc0a5558464817494037d612f094)
# https://github.com/89luca89/distrobox
# https://docs.flatpak.org/en/latest/getting-started.html
dnf5 -y install \
        distrobox \
        flatpak

# Replace fedora flatpak repos with flathub
# mkdir -p /etc/flatpak/remotes.d/
# curl --retry 3 -Lo /etc/flatpak/remotes.d/flathub.flatpakrepo https://dl.flathub.org/repo/flathub.flatpakrepo
# rm -rf /usr/lib/systemd/system/flatpak-add-fedora-repos.service
# systemctl enable flatpak-add-flathub-repos.service


## Terminal utils

# Locale and fonts
dnf5 -y install \
        glibc-langpack-fr \
        glibc-langpack-en \
        default-fonts-core-emoji \
        google-noto-color-emoji-fonts \
        google-noto-emoji-fonts \
        fira-code-fonts

# Theming
dnf5 -y install \
        adw-gtk3-theme

# Terminal utils
# (foot)
dnf5 -y install \
        fish \
        vim \
        zoxide \
        fzf

dnf5 -y copr enable atim/starship
dnf5 -y install starship
dnf5 -y copr disable atim/starship

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
