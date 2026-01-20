#!/bin/bash

set -ouex pipefail

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

# Config
cp -avf /ctx/rootfs/etc/skel/.bashrc /etc/skel/.config/.bashrc
cp -avf /ctx/rootfs/etc/skel/.config/fish /etc/skel/.config/fish
cp -avf /ctx/rootfs/etc/skel/.config/starship.toml /etc/skel/.config/starship.toml
