#!/bin/bash

set -ouex pipefail

#######################################################################
# SYSTEMD UNITS
#######################################################################

systemctl enable podman.socket
systemctl enable systemd-timesyncd
systemctl enable systemd-resolved.service
# systemctl enable virtqemud
# systemctl enable zcfan.service # Thinkpad fan control

systemctl disable NetworkManager-wait-online.service # Disabling wait-online to decrease the boot time
systemctl disable flatpak-add-fedora-repos.service

systemctl mask rpm-ostree-countme.timer

#######################################################################
# TROUBLESHOOTING
#######################################################################

## The systemd-remount-fs service fails on boot because the root filesystem on an ostree system is read-only by design.
# We can mask it to avoid harmless log errors.
# https://gitlab.com/fedora/ostree/sig/-/issues/72
systemctl mask systemd-remount-fs.service

## The systemd-sysusers service is failing to started
# systemd-sysusers return the following error : /etc/shadow: Group "usbmuxd" already exists.
# the sysusers config is defined in the /usr/lib/sysusers.d/usbmuxd.conf
#       g usbmuxd 113
#       u usbmuxd 113:113 "usbmuxd user"
# we can remove the package usbmuxd
rm -f /usr/lib/sysusers.d/brltty.conf
rm -f /usr/lib/sysusers.d/usbmuxd.conf
