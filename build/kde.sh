#!/bin/bash

set -ouex pipefail

##########################################################
# HARDWARE & SYSTEM PACKAGES
##########################################################

dnf5 -y install 'dnf5-command(copr)'

packages=(

    @hardware-support

    ### INFOS
    pciutils
    usbutils
    vulkan-tools
    libva-utils
    lm_sensors

    ### DISK
    ntfs-3g
    nfs-utils

    ### NETWORK
    NetworkManager
    NetworkManager-wifi
    nmap
    bind-utils
    firewalld
    wireguard-tools
    tailscale
    wget
    wol

    ### MULTIMEDIA
    pipewire
    pipewire-pulseaudio
    pipewire-alsa
    pipewire-jack-audio-connection-kit
    pipewire-plugin-libcamera
    wireplumber
    easyeffects
    feh

    ### POWER MANAGEMENT
    power-profiles-daemon
    powertop
    #tlp
    zcfan

    ### FINGERPRINT SENSOR
    fprintd
    fprintd-pam

    ### LOCALE & FONTS
    glibc-all-langpacks
    default-fonts-core-emoji
    google-noto-color-emoji-fonts
    google-noto-emoji-fonts
    fira-code-fonts
    fontawesome-fonts-all
    jetbrains-mono-fonts

    ### VIRTUALISATION
    incus
    incus-tools
    libvirt-daemon-kvm
    libvirt-daemon-config-network
    virt-install
    virt-viewer
    virt-manager

)

dnf5 -y install "${packages[@]}" --allowerasing


##########################################################
# TERMINAL & SHELL
##########################################################

dnf5 -y copr enable atim/starship
dnf5 -y copr enable lihaohong/yazi
dnf5 -y copr enable varlad/zellij

packages=(
    #alacritty
    foot
    zellij

    fish
    starship
    zoxide
    fzf
    bat
    ripgrep
    fd-find
    tldr
    fastfetch

    vim-default-editor
    stow
    just
    jq
    yazi
    git
    gitui
    gh
    p7zip

    #opentofu
    #ansible
    #vim-ansible
)

dnf5 -y install "${packages[@]}" --allowerasing
dnf5 -y copr disable atim/starship
dnf5 -y copr disable lihaohong/yazi
dnf5 -y copr disable varlad/zellij


#######################################################################
# DESKTOP ENVIRONMENT
#######################################################################

dnf5 -y install @kde-desktop-environment --allowerasing


##########################################################
# PACKAGES & SOFTWARE MANAGEMENT
##########################################################

# TODO: Install NIX

# https://github.com/89luca89/distrobox
# https://docs.flatpak.org/en/latest/getting-started.html

packages=(
    distrobox
    flatpak
    nix
    nix-daemon
)
dnf5 -y install "${packages[@]}"


#######################################################################
# REMOVE PACKAGES FROM IMAGE
#######################################################################

# Clean up packages
dnf5 -y autoremove

packages=(
  PackageKit-command-not-found    # Helper to install package on the command line - Not compatible with bootc
  at    # Utility for time-oriented job control - systemd-timer is better alternative
  iptables-services   # IPTables are deprecated
  iptables-utils
  rsyslog   # Enhance logging, but heavy in resources - journalctl is better alternative
  dracut-config-rescue    # Generates rescue initramfs image - Bootc already provides rollback image
  dnf-data  # Remove DNF
  console-login-helper-messages
  qemu-user-static*
  toolbox
)
dnf5 -y remove "${packages[@]}"


#######################################################################
# ENABLE ZRAM
#######################################################################

tee /usr/lib/systemd/zram-generator.conf <<'EOF'
[zram0]
zram-size = min(ram / 2, 8192)
EOF


#######################################################################
# SWITCH KERNEL TO CACHYOS KERNEL
#######################################################################

# Create a shim to bypass kernel install triggering dracut/rpm-ostree
pushd /usr/lib/kernel/install.d
mv 05-rpmostree.install 05-rpmostree.install.bak
mv 50-dracut.install 50-dracut.install.bak
printf '%s\n' '#!/bin/sh' 'exit 0' > 05-rpmostree.install
printf '%s\n' '#!/bin/sh' 'exit 0' > 50-dracut.install
chmod +x  05-rpmostree.install 50-dracut.install
popd

# Remove default kernel, install kernel-cachyos
dnf5 -y copr enable bieszczaders/kernel-cachyos
dnf5 -y remove kernel kernel-core kernel-modules kernel-modules-core kernel-modules-extra
dnf5 -y install kernel-cachyos kernel-cachyos-devel-matched
dnf5 -y copr disable bieszczaders/kernel-cachyos

# Remove the shim
pushd /usr/lib/kernel/install.d
mv -f 05-rpmostree.install.bak 05-rpmostree.install
mv -f 50-dracut.install.bak 50-dracut.install
popd

# Rebuild initramfs
QUALIFIED_KERNEL="$(dnf5 repoquery --installed --queryformat='%{evr}.%{arch}' "kernel-cachyos")"
/usr/bin/dracut --no-hostonly --kver "$QUALIFIED_KERNEL" --reproducible --zstd -v --add ostree -f "/usr/lib/modules/$QUALIFIED_KERNEL/initramfs.img"
chmod 0600 /usr/lib/modules/"$QUALIFIED_KERNEL"/initramfs.img

# Lastly if you use SELinux, you need to enable the necessary policy to be able to load kernel modules.
setsebool -P domain_kernel_load_modules on


#######################################################################
# USERS
#######################################################################

# TODO: systemhomed
## Create default user for VM images
useradd -m  tinados
usermod -aG wheel tinados
echo "tinados:tinados" | chpasswd


#######################################################################
# SYSTEMD UNITS
#######################################################################

system_services=(
#     chronyd.service
    firewalld.service
#     nix.mount
#     nix-setup.service
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
# CONFIGURATION
#######################################################################

## Copy all config files to the system
cp -avf "/ctx/rootfs"/. /


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

mkdir "/usr/share/$IMAGE_NAME"
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
