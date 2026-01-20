#!/bin/bash

set -ouex pipefail

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
# REMOVE PACKAGES FROM IMAGE
#######################################################################

packages=(
  PackageKit-command-not-found    # Helper to install package on the command line - Not compatible with bootc
  at    # Utility for time-oriented job control - systemd-timer is better alternative
  iptables-services   # IPTables are deprecated
  iptables-utils
  rsyslog   # Enhance logging, but heavy in resources - journalctl is better alternative
  dracut-config-rescue    # Generates rescue initramfs image - Bootc already provides rollback image
  dnf-data  # Remove DNF
)
dnf5 -y remove "${packages[@]}"

#######################################################################
# CLEANUP
#######################################################################

# Clean up packages
dnf5 -y autoremove

# Remove unnecessary files
rm -rf /usr/share/doc
rm -rf /usr/src

# Clean all build files
dnf5 clean all
rpm-ostree cleanup --repomd
rm -rf /tmp/* || true

# Clean /var directory while preserving essential files
find /var/* -maxdepth 0 -type d \! -name cache \! -name home \! -name nix -exec rm -fr {} \;
find /var/cache/* -maxdepth 0 -type d \! -name libdnf5 \! -name rpm-ostree -exec rm -fr {} \;

mkdir -p /var/tmp
chmod -R 1777 /var/tmp
