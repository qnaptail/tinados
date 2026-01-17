#!/usr/bin/env bash

set -euo pipefail

STOW_DIR="$HOME/.stow"
BACKUP_ROOT="$HOME/.backup-stow"
mkdir -p "$BACKUP_ROOT"

# --------------------------------------
# Determine all top-level FILES/FOLDERS
# in a stow package (e.g. .config, .local, .zshrc)
# --------------------------------------
app_paths() {
    local app="$1"
    find "$STOW_DIR/$app" -mindepth 1 -maxdepth 1 -printf "%f\n"
}

# --------------------------------------
# Test if an app is already stowed
# (all its top-level paths must be symlinks in $HOME)
# --------------------------------------
is_stowed() {
    local app="$1"
    for p in $(app_paths "$app"); do
        local target="$HOME/$p"
        [[ -L "$target" ]] || return 1
    done
    return 0
}

# --------------------------------------
# Backup paths overwritten by a package
# --------------------------------------
backup_app() {
    local app="$1"
    local backup_dir="$BACKUP_ROOT/$app"
    mkdir -p "$backup_dir"

    echo "  → Backing up overwritten files to $backup_dir"

    for p in $(app_paths "$app"); do
        local target="$HOME/$p"

        if [[ -e "$target" && ! -L "$target" ]]; then
            echo "    • Backup: $p"
            mkdir -p "$(dirname "$backup_dir/$p")"
            mv "$target" "$backup_dir/"
        fi
    done
}

# --------------------------------------
# Restore backup
# --------------------------------------
restore_app() {
    local app="$1"
    local backup_dir="$BACKUP_ROOT/$app"

    if [[ ! -d "$backup_dir" ]]; then
        return
    fi

    echo "  → Restoring backups from $backup_dir"

    find "$backup_dir" -mindepth 1 -maxdepth 999 -print0 | while IFS= read -r -d '' file; do
        rel="${file#$backup_dir/}"
        echo "    • Restore: $rel"
        mv "$file" "$HOME/$rel"
    done

    rm -rf "$backup_dir"
}

# --------------------------------------
# Actual stow and unstow
# --------------------------------------

do_stow() {
    local app="$1"
    echo "  → stow $app"
    (cd "$STOW_DIR" && stow "$app")
}

do_unstow() {
    local app="$1"
    echo "  → stow -D $app"
    (cd "$STOW_DIR" && stow -D "$app")
}

# --------------------------------------
# High-level commands
# --------------------------------------

stow_apps() {
    local apps=("$@")
    for app in "${apps[@]}"; do
        echo "• App: $app"

        if is_stowed "$app"; then
            echo "  → Already stowed. Skipping."
            continue
        fi

        backup_app "$app"
        do_stow "$app"
    done
}

unstow_apps() {
    local apps=("$@")
    for app in "${apps[@]}"; do
        echo "• App: $app"
        do_unstow "$app"
        restore_app "$app"
    done
}

# --------------------------------------
# CLI
# --------------------------------------

all_apps() {
    ls "$STOW_DIR"
}

if [[ $# -lt 1 ]]; then
    echo "Usage: $0 {stow|unstow} [apps...]"
    exit 1
fi

cmd="$1"
shift || true

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
