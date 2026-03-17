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
coprs=(
  atim/starship
  lihaohong/yazi
  varlad/zellij
)
dnf5 -y copr enable "${coprs[@]}"

# Install listed packages
grep -vE '^#' /usr/local/share/$OSNAME/packages-add | xargs dnf5 -y install --allowerasing

# Remove unnecessary packages
grep -vE '^#' /usr/local/share/$OSNAME/packages-remove | xargs dnf5 -y remove

# Cleanup
dnf5 -y autoremove
dnf5 -y copr disable "${coprs[@]}"


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
# rm -f /usr/lib/sysusers.d/brltty.conf
# rm -f /usr/lib/sysusers.d/usbmuxd.conf
