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
dnf5 -y copr enable bieszczaders/kernel-cachyos

# INSTALL PACKAGES
# grep -vE '^#' /usr/local/share/os-template/packages-add | xargs dnf5 -y install --allowerasing --setopt=install_weak_deps=False
# grep -vE '^#' /usr/local/share/os-template/packages-add | xargs dnf5 -y install --allowerasing

# REMOVE UNNECESSARY AND PROBLEMATIC PACKAGES
# grep -vE '^#' /usr/local/share/os-template/packages-remove | xargs dnf5 -y remove

# SWITCH KERNEL TO CACHYOS KERNEL
# create a shims to bypass kernel install triggering dracut/rpm-ostree
pushd /usr/lib/kernel/install.d
mv 05-rpmostree.install 05-rpmostree.install.bak
mv 50-dracut.install 50-dracut.install.bak
printf '%s\n' '#!/bin/sh' 'exit 0' > 05-rpmostree.install
printf '%s\n' '#!/bin/sh' 'exit 0' > 50-dracut.install
chmod +x  05-rpmostree.install 50-dracut.install
popd

dnf5 -y remove --no-autoremove kernel kernel-core kernel-modules kernel-modules-core kernel-modules-extra
dnf5 -y install kernel-cachyos kernel-cachyos-devel-matched

pushd /usr/lib/kernel/install.d
mv -f 05-rpmostree.install.bak 05-rpmostree.install
mv -f 50-dracut.install.bak 50-dracut.install
popd

# Lastly if you use SELinux, you need to enable the necessary policy to be able to load kernel modules.
setsebool -P domain_kernel_load_modules on

# CLEANUP
# Disable repos so they don't appear in final image
dnf5 -y autoremove
dnf5 -y copr disable avengemedia/dms
dnf5 -y copr disable atim/starship
dnf5 -y copr disable lihaohong/yazi
dnf5 -y copr disable varlad/zellij
dnf5 -y copr disable bieszczaders/kernel-cachyos
dnf5 clean all

## Package and software management : Distrobox, Flatpak and Nix
# TODO: Install nix (https://gist.github.com/queeup/1666bc0a5558464817494037d612f094)
# https://github.com/89luca89/distrobox
# https://docs.flatpak.org/en/latest/getting-started.html

## DESKTOP ENVIRONMENT : Niri window manager and DankMaterial shell
# https://github.com/YaLTeR/niri/wiki/Getting-Started
# https://github.com/AvengeMedia/DankMaterialShell

# add_wants_niri() {
#     sed -i "s/\[Unit\]/\[Unit\]\nWants=$1/" "/usr/lib/systemd/user/niri.service"
# }
#
# add_wants_niri dms.service
# add_wants_niri udiskie.service
# # add_wants_niri swayidle.service
# add_wants_niri foot.service
#
# # sed -i 's|spawn-at-startup "waybar"|// spawn-at-startup "waybar"|' "/usr/share/doc/niri/default-config.kdl"
# #
# systemctl enable --global gnome-keyring-daemon.socket
# systemctl enable --global gnome-keyring-daemon.service
#
# mkdir /var/cache/dms-greeter
# chown greetd:greetd /var/cache/dms-greeter
# sed -i 's|user = "greeter"|user = "greetd"|' "/etc/greetd/config.toml"
# sed -i '/gnome_keyring.so/ s/-auth/auth/ ; /gnome_keyring.so/ s/-session/session/' /etc/pam.d/greetd
# systemctl enable greetd

## MISC
# Enable Zram (ram compression to avoid swaping)
tee /usr/lib/systemd/zram-generator.conf <<'EOF'
[zram0]
zram-size = min(ram / 2, 8192)
EOF

### Systemd units
systemctl enable podman.socket
systemctl enable systemd-timesyncd
systemctl enable systemd-resolved.service
systemctl mask rpm-ostree-countme.timer
# Lenovo thinkpad fan control
# systemctl enable zcfan.service
# Disabling wait-online to decrease the boot time
systemctl disable NetworkManager-wait-online.service


### Troubleshooting
## The systemd-remount-fs service fails on boot because the root filesystem on an ostree system is read-only by design.
# We can mask it to avoid harmless log errors.
# https://gitlab.com/fedora/ostree/sig/-/issues/72
systemctl mask systemd-remount-fs.service
