#!/bin/bash

set -ouex pipefail

OSNAME="tinados"

##########################################################
# PACKAGES
##########################################################

# Save package lists in  /usr/local/share/
mkdir -p /usr/share/$OSNAME
mkdir -p /usr/local/share/$OSNAME
jq -r .packages[] /usr/share/rpm-ostree/treefile.json > /usr/local/share/$OSNAME/packages-base-image
cp /ctx/build/kde/packages-add /usr/local/share/$OSNAME/packages-add
cp /ctx/build/kde/packages-remove /usr/local/share/$OSNAME/packages-remove
chmod  0644 /usr/local/share/$OSNAME/*

# Third parties repositories
dnf5 -y install 'dnf5-command(copr)'
dnf5 -y copr enable atim/starship
dnf5 -y copr enable lihaohong/yazi
dnf5 -y copr enable varlad/zellij
dnf5 -y copr enable avengemedia/dms

# Install listed packages
grep -vE '^#' /usr/local/share/$OSNAME/packages-add | xargs dnf5 -y install --allowerasing

# Remove unnecessary packages
grep -vE '^#' /usr/local/share/$OSNAME/packages-remove | xargs dnf5 -y remove

# Cleanup
dnf5 -y autoremove
dnf5 -y copr disable atim/starship
dnf5 -y copr disable lihaohong/yazi
dnf5 -y copr disable varlad/zellij
dnf5 -y copr disable avengemedia/dms

##########################################################
# NIRI & DMS CONFIG
##########################################################
# https://github.com/YaLTeR/niri/wiki/Getting-Started
# https://github.com/AvengeMedia/DankMaterialShell
# https://danklinux.com/docs/dankgreeter

add_wants_niri() {
    sed -i "s/\[Unit\]/\[Unit\]\nWants=$1/" "/usr/lib/systemd/user/niri.service"
}

add_wants_niri dms.service
add_wants_niri foot.service
add_wants_niri udiskie.service
add_wants_niri swayidle.service
systemctl enable --global gnome-keyring-daemon.socket
systemctl enable --global gnome-keyring-daemon.service

# dms-greeter
mkdir /var/cache/dms-greeter
chown greetd:greetd /var/cache/dms-greeter
sed -i 's|user = "greeter"|user = "greetd"|' "/etc/greetd/config.toml"
sed -i '/gnome_keyring.so/ s/-auth/auth/ ; /gnome_keyring.so/ s/-session/session/' /etc/pam.d/greetd

systemctl enable greetd

#######################################################################
# SERVICES
#######################################################################

systemctl set-default graphical.target

system_services=(
#     chronyd.service
    firewalld.service
    nix-daemon.service
    systemd-timesyncd.service
    systemd-resolved.service
    systemd-homed.service
#     virtqemud.service
#     zcfan.service # Thinkpad fan control
)

user_services=(
    podman.socket
)

mask_services=(
    logrotate.timer
    logrotate.service
    rpm-ostree-countme.timer
    rpm-ostree-countme.service
    systemd-remount-fs.service
    flatpak-add-fedora-repos.service
    NetworkManager-wait-online.service
)

systemctl enable "${system_services[@]}"
systemctl --global enable "${user_services[@]}"
systemctl mask "${mask_services[@]}"


#######################################################################
# TROUBLESHOOTING
#######################################################################

## The systemd-sysusers service is failing to started
# systemd-sysusers return the following error : /etc/shadow: Group "usbmuxd" already exists.
# the sysusers config is defined in the /usr/lib/sysusers.d/usbmuxd.conf
#       g usbmuxd 113
#       u usbmuxd 113:113 "usbmuxd user"
# we can remove the package usbmuxd
rm -f /usr/lib/sysusers.d/brltty.conf
rm -f /usr/lib/sysusers.d/usbmuxd.conf
