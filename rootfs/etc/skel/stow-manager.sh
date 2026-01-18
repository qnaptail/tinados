#!/usr/bin/env bash

set -euo pipefail

########################################################
# Configuration
########################################################

STOW_DIR="$HOME/.dotfiles"
BACKUP_ROOT="$HOME/.backup-dotfiles"

mkdir -p "$BACKUP_ROOT"


########################################################
# Helper functions
########################################################

# The paths we want to find are :
# level 2 files (.dotfiles/app/level1/level2.file)
#   - .dotfiles/starship/.config/starship.toml
# level x > 3 directories containing files (.dotfiles/app/level1/level2/level3)
#   - .dotfiles/starship/.config/fuzzel/
#   - .dotfiles/fuzzel/.local/var/flatpak/fuzzel/
# We ONLY want directories containing files, not all subdirectories

app_paths() {
    local app="$1"
    {
        find "$STOW_DIR/$app" -maxdepth 2 -type f -printf '%P\n'
        find "$STOW_DIR/$app" -mindepth 3 -type f -printf '%P\n' \
            | sed 's|/[^/]*$||' \
            | sort -u
    }
}

is_stowed() {
    while IFS= read -r p; do
        local target="$HOME/$p"
        [[ -L "$target" ]] && return 0
    done < <(app_paths "$1")
    return 1
}

all_apps() {
    find "$STOW_DIR" -mindepth 1 -maxdepth 1 -type d -printf '%P\n'
}


########################################################
# Backup / restore
########################################################

backup_app() {
    local p
    while IFS= read -r p; do
        local target="$HOME/$p"
        local backup="$BACKUP_ROOT/$p"
        if [[ -e "$target" && ! -L "$target" ]]; then
            echo "  → Backup $target to $backup"
            mkdir -p "$(dirname "$backup")"
            mv "$target" "$backup"
        fi
    done < <(app_paths "$1")
}

restore_app() {
    local p
    while IFS= read -r p; do
        local target="$HOME/$p"
        local backup="$BACKUP_ROOT/$p"
        if [[ -e "$backup" ]]; then
            echo "  → Restore $backup to $target"
            mv "$backup" "$target"
        fi
    done < <(app_paths "$1")
}

########################################################
# Stow / unstow
########################################################

stow_apps() {
    for app in "$@"; do
        echo "• App: $app"

        # Check if the app exists in .dotfiles
        if [[ ! -d "$STOW_DIR/$app" ]]; then
            echo "  → No Config available: $STOW_DIR/$app does not exists."
            continue
        fi

        # If the app is already stowed, we don't do anything
        if is_stowed "$app"; then
            echo "  → Already stowed. Skipping."
            continue
        fi

        # Else we backup the current config, then stow the app
        backup_app "$app"
        echo "  → stow $app"
        (cd "$STOW_DIR" && stow "$app")
    done
}

unstow_apps() {
    for app in "$@"; do
        echo "• App: $app"

        # Check if the app exists in .dotfiles
        if [[ ! -d "$STOW_DIR/$app" ]]; then
            echo "  → No Config available: $STOW_DIR/$app does not exists."
            continue
        fi

        # We first unstow the app, then we restore config from backup
        echo "  → unstow $app"
        (cd "$STOW_DIR" && stow -D "$app")
        restore_app "$app"
    done
}

########################################################
# CLI Handling
########################################################

if [[ $# -lt 1 ]]; then
    echo "Usage: $0 {stow|unstow} [apps...]"
    exit 1
fi

# Separate command (stow/unstow) and arguments ([apps...])
cmd="$1"
shift || true

# If no app is given ($@ is now empty), we stow/unstow all the apps in the .dotfiles directory
case "$cmd" in
    stow)
        [[ $# -gt 0 ]] && stow_apps "$@" || stow_apps $(all_apps)
        ;;
    unstow)
        [[ $# -gt 0 ]] && unstow_apps "$@" || unstow_apps $(all_apps)
        ;;
    *)
        echo "Unknown command: $cmd"
        exit 1
        ;;
esac
