#!/usr/bin/env bash

set -euo pipefail

LIST_FILE="${1:-flatpak.list}"

########################################
# EXPORT EXISTING STATE (--export-user)
########################################

if [[ "$LIST_FILE" == "--export-user" ]]; then
    # Export installed user apps only (one per line)
    flatpak --user list --app --columns=application | sort -u
    exit 0
fi

########################################
# FETCH DECLARED AND INSTALLED USER APPS
########################################

# Ensure file exists
if [[ ! -f "$LIST_FILE" ]]; then
    echo "Error: file '$LIST_FILE' not found."
    exit 1
fi

mapfile -t DECLARED < <(
    grep -vE '^\s*($|#)' "$LIST_FILE" | xargs -L1 echo
)

mapfile -t INSTALLED < <(flatpak --user list --app --columns=application)

INSTALLED_SORTED=$(printf "%s\n" "${INSTALLED[@]}" | sort -u)
DECLARED_SORTED=$(printf "%s\n" "${DECLARED[@]}" | sort -u)

TO_REMOVE=$(comm -23 <(echo "$INSTALLED_SORTED") <(echo "$DECLARED_SORTED"))
TO_INSTALL=$(comm -13 <(echo "$INSTALLED_SORTED") <(echo "$DECLARED_SORTED"))

echo "=== Flatpaks to be removed ==="
[[ -n "$TO_REMOVE" ]] && echo "$TO_REMOVE"
echo "=== Flatpaks to be installed  ==="
[[ -n "$TO_INSTALL" ]] && echo "$TO_INSTALL"


########################################
# ENFORCE FLATHUB AS THE ONLY REMOTE
########################################

echo "=== Ensuring flathub (verified subset) is the default remote ==="

# Get current user remotes
mapfile -t EXISTING_REMOTES < <(flatpak --user remotes --columns=name)

# Disable all remotes except flathub
for r in "${EXISTING_REMOTES[@]}"; do
    if [[ "$r" != "flathub" && "$r" !=  "" ]]; then
        echo "Disabling remote: $r"
        # flatpak --user remote-delete "$r"
        flatpak --user remote-modify --disable "$r"
    fi
done

# Add flathub if missing
if ! printf "%s\n" "${EXISTING_REMOTES[@]}" | grep -qx "flathub"; then
    echo "Adding flathub remote"
    flatpak --user remote-add --if-not-exists --subset=verified flathub https://dl.flathub.org/repo/flathub.flatpakrepo
fi

# Ensure the flag subset=verified is set on the flathub remote
FLATHUB_INFO=$(flatpak --user remotes --columns=name,subset | grep "flathub")
if ! echo "$FLATHUB_INFO" | grep -q "verified"; then
    echo "Applying subset=verified to flathub"
    flatpak --user remote-modify --subset=verified flathub
fi

########################################
# REMOVE APPS NOT DECLARED
########################################

if [[ -n "$TO_REMOVE" ]]; then
    echo "=== Removing apps NOT in declarative list ==="
    for app in $TO_REMOVE; do
        echo "Removing: $app"
        flatpak --user uninstall -y "$app"
    done
fi

echo "=== Removing unused dependencies ==="
flatpak --user uninstall -y --unused

########################################
# INSTALL MISSING APPS
########################################

if [[ -n "$TO_INSTALL" ]]; then
    echo "=== Installing missing apps from flathub ==="
    for app in $TO_INSTALL; do
        echo "Installing: $app"
        flatpak --user install -y flathub "$app"
    done
fi

echo "=== Check and repair dependencies ==="
flatpak --user repair

echo "Done! User Flatpaks now match '$LIST_FILE'."
