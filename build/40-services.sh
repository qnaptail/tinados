#!/bin/bash

set -ouex pipefail

#######################################################################
# SYSTEMD UNITS
#######################################################################

system_services=(
#     chronyd.service
    firewalld.service
    nix.mount
    nix-setup.service
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
