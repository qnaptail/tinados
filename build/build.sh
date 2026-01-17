#!/bin/bash

set -ouex pipefail

# RELEASE="$(rpm -E %fedora)"
OSNAME="tinados"


#######################################################################
# INSTALL PACKAGES
#######################################################################
# TODO: Use dnf install_weak_deps flag to manage dependencies in a finer way

## Prepare packages lists
## Save base/added/removed package lists in /usr/
mkdir -p /usr/share/$OSNAME
mkdir -p /usr/local/share/$OSNAME
jq -r .packages[] /usr/share/rpm-ostree/treefile.json > /usr/local/share/$OSNAME/packages-base-image
cp /ctx/build/packages-add /usr/local/share/$OSNAME/packages-add
cp /ctx/build/packages-remove /usr/local/share/$OSNAME/packages-remove
chmod  0644 /usr/local/share/$OSNAME/*

## Install third party repositories
dnf5 -y install 'dnf5-command(copr)'
dnf5 -y copr enable avengemedia/dms
dnf5 -y copr enable atim/starship
dnf5 -y copr enable lihaohong/yazi
dnf5 -y copr enable varlad/zellij
dnf5 -y copr enable bieszczaders/kernel-cachyos

## Install and remove packages
# grep -vE '^#' /usr/local/share/$OSNAME/packages-add | xargs dnf5 -y install --allowerasing --setopt=install_weak_deps=False
grep -vE '^#' /usr/local/share/$OSNAME/packages-add | xargs dnf5 -y install --allowerasing
grep -vE '^#' /usr/local/share/$OSNAME/packages-remove | xargs dnf5 -y remove


#######################################################################
# SWITCH KERNEL TO CACHYOS KERNEL
#######################################################################

## Create a shims to bypass kernel install triggering dracut/rpm-ostree
pushd /usr/lib/kernel/install.d
mv 05-rpmostree.install 05-rpmostree.install.bak
mv 50-dracut.install 50-dracut.install.bak
printf '%s\n' '#!/bin/sh' 'exit 0' > 05-rpmostree.install
printf '%s\n' '#!/bin/sh' 'exit 0' > 50-dracut.install
chmod +x  05-rpmostree.install 50-dracut.install
popd

# dnf5 -y remove --no-autoremove kernel kernel-core kernel-modules kernel-modules-core kernel-modules-extra
dnf5 -y remove kernel kernel-core kernel-modules kernel-modules-core kernel-modules-extra
dnf5 -y install kernel-cachyos #kernel-cachyos-devel-matched

pushd /usr/lib/kernel/install.d
mv -f 05-rpmostree.install.bak 05-rpmostree.install
mv -f 50-dracut.install.bak 50-dracut.install
popd

## Rebuild initramfs
QUALIFIED_KERNEL="$(dnf5 repoquery --installed --queryformat='%{evr}.%{arch}' "kernel-cachyos")"
/usr/bin/dracut --no-hostonly --kver "$QUALIFIED_KERNEL" --reproducible --zstd -v --add ostree -f "/usr/lib/modules/$QUALIFIED_KERNEL/initramfs.img"
chmod 0600 /usr/lib/modules/"$QUALIFIED_KERNEL"/initramfs.img

## Lastly if you use SELinux, you need to enable the necessary policy to be able to load kernel modules.
setsebool -P domain_kernel_load_modules on


#######################################################################
# SETUP DESKTOP ENVIRONMENT
#######################################################################

## Niri startup services
add_wants_niri() {
    sed -i "s/\[Unit\]/\[Unit\]\nWants=$1/" "/usr/lib/systemd/user/niri.service"
}

add_wants_niri dms.service
add_wants_niri udiskie.service
add_wants_niri swayidle.service
add_wants_niri foot.service

systemctl enable --global gnome-keyring-daemon.socket
systemctl enable --global gnome-keyring-daemon.service

## Display manager / greeter
mkdir /var/cache/dms-greeter
chown greetd:greetd /var/cache/dms-greeter
sed -i 's|user = "greeter"|user = "greetd"|' "/etc/greetd/config.toml"
sed -i '/gnome_keyring.so/ s/-auth/auth/ ; /gnome_keyring.so/ s/-session/session/' /etc/pam.d/greetd
systemctl enable greetd


#######################################################################
# MISC
#######################################################################

# TODO: Users management (?)
## Create default user for VM images
useradd -m  tinados
usermod -aG wheel tinados
echo "tinados:tinados" | chpasswd

# TODO: Install nix (https://gist.github.com/queeup/1666bc0a5558464817494037d612f094)
# https://packages.fedoraproject.org/pkgs/nix/nix/
## Symlink /nix to /var/nix to make the nix store writable (does not work)
# cp -r /nix /var/ && rm -rf /nix && ln -s /var/nix /nix

## Enable Zram (ram compression to avoid swaping)
tee /usr/lib/systemd/zram-generator.conf <<'EOF'
[zram0]
zram-size = min(ram / 2, 8192)
EOF

## Systemd units
systemctl enable podman.socket
# systemctl enable virtqemud
systemctl enable systemd-timesyncd
systemctl enable systemd-resolved.service
systemctl mask rpm-ostree-countme.timer

# Lenovo thinkpad fan control
# systemctl enable zcfan.service

# Disabling wait-online to decrease the boot time
systemctl disable NetworkManager-wait-online.service
systemctl disable flatpak-add-fedora-repos.service

#######################################################################
# CONFIGURATION
#######################################################################

## Copy all config files to the system
cp -avf "/ctx/rootfs"/. /


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

#######################################################################
# IMAGE INFOS
#######################################################################

IMAGE_VENDOR="qnaptail"
IMAGE_NAME="tinados"
IMAGE_PRETTY_NAME="TinadOS"
IMAGE_REF="ostree-image-signed:docker://ghcr.io/$IMAGE_VENDOR/$IMAGE_NAME"
HOME_URL="https://github.com/$IMAGE_VENDOR/$IMAGE_NAME"
FEDORA_MAJOR_VERSION=$(awk -F= '/VERSION_ID/ {print $2}' /etc/os-release)
BASE_IMAGE_NAME="Fedora bootc $FEDORA_MAJOR_VERSION"
BASE_IMAGE="quay.io/fedora/fedora-bootc"

IMAGE_INFO="/usr/share/$IMAGE_NAME/image-info.json"
cat >$IMAGE_INFO <<EOF
{
  "image-name": "$IMAGE_NAME",
  "image-vendor": "$IMAGE_VENDOR",
  "image-ref": "$IMAGE_REF",
  "image-tag":"latest",
  "base-image-name": "$BASE_IMAGE_NAME",
  "base-image": "$BASE_IMAGE",
  "fedora-version": "$FEDORA_MAJOR_VERSION"
}
EOF

echo "$IMAGE_NAME" | tee "/etc/hostname"

sed -i -f - /usr/lib/os-release <<EOF
s|^NAME=.*|NAME=\"$IMAGE_NAME\"|
s|^PRETTY_NAME=.*|PRETTY_NAME=\"$IMAGE_PRETTY_NAME\"|
s|^VERSION_CODENAME=.*|VERSION_CODENAME=\"$IMAGE_NAME\"|
s|^VARIANT_ID=.*|VARIANT_ID=""|
s|^HOME_URL=.*|HOME_URL=\"${HOME_URL}\"|
s|^BUG_REPORT_URL=.*|BUG_REPORT_URL=\"${HOME_URL}/issues\"|
s|^SUPPORT_URL=.*|SUPPORT_URL=\"${HOME_URL}/issues\"|
s|^DOCUMENTATION_URL=.*|DOCUMENTATION_URL=\"${HOME_URL}\"|
s|^DEFAULT_HOSTNAME=.*|DEFAULT_HOSTNAME="$IMAGE_NAME"|

/^REDHAT_BUGZILLA_PRODUCT=/d; /^REDHAT_BUGZILLA_PRODUCT_VERSION=/d; /^REDHAT_SUPPORT_PRODUCT=/d; /^REDHAT_SUPPORT_PRODUCT_VERSION=/d
EOF

# Fix issues caused by ID no longer being fedora
sed -i "s|^EFIDIR=.*|EFIDIR=\"fedora\"|" /usr/sbin/grub2-switch-to-blscfg


#######################################################################
# CLEANUP
#######################################################################

## Clean up packages
dnf5 -y autoremove

## Disable repositories so they don't appear in final image
dnf5 -y copr disable avengemedia/dms
dnf5 -y copr disable atim/starship
dnf5 -y copr disable lihaohong/yazi
dnf5 -y copr disable varlad/zellij
dnf5 -y copr disable bieszczaders/kernel-cachyos

## Remove unnecessary files
rm -rf /usr/share/doc
rm -rf /usr/src

## Clean all build files
dnf5 clean all
rpm-ostree cleanup --repomd
rm -rf /tmp/* || true

# Clean /var directory while preserving essential files
find /var/* -maxdepth 0 -type d \! -name cache \! -name home \! -name nix -exec rm -fr {} \;
find /var/cache/* -maxdepth 0 -type d \! -name libdnf5 \! -name rpm-ostree -exec rm -fr {} \;

mkdir -p /var/tmp
chmod -R 1777 /var/tmp
