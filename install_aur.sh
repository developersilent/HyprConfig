#!/usr/bin/env bash

scrDir=$(dirname "$(realpath "$0")")
# shellcheck disable=SC1091
if ! source "${scrDir}/global.sh"; then
    echo "Error: unable to source global.sh..."
    exit 1
fi

# shellcheck disable=SC2154
if chk_list "aurhlpr" "${aurList[@]}"; then
    echo ${aurList[@]}
    print_log -sec "AUR" -stat "Detected" "${aurhlpr}"
    exit 0
fi

aurhlpr="${1:-paru}"

if pkg_installed git; then
    git clone "https://aur.archlinux.org/${aurhlpr}.git" "$HOME/Clone/${aurhlpr}"
else
    print_log -sec "AUR" -stat "missing" "'git' as dependency..."
    exit 1
fi

cd "$HOME/Clone/${aurhlpr}" || exit
# shellcheck disable=SC2154
if makepkg "${use_default}" -si; then
    print_log -sec "AUR" -stat "installed" "${aurhlpr} aur helper..."
    exit 0
else
    print_log -r "AUR" -stat "failed" "${aurhlpr} installation failed..."
    echo "${aurhlpr} installation failed..."
    exit 1
fi
