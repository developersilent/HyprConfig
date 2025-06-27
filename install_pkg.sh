#!/usr/bin/env bash
# shellcheck disable=SC2154
# shellcheck disable=SC1091


scrDir=$(dirname "$(realpath "$0")")
if ! source "${scrDir}/global.sh"; then
    echo "Error: unable to source global.sh..."
    exit 1
fi

flg_DryRun=${flg_DryRun:-0}
export log_section="package"

"${scrDir}/install_aur.sh" "${getAur}" 2>&1
chk_list "aurhlpr" "${aurList[@]}"
listPkg="${1:-"${scrDir}/pkg_core.lst"}"
archPkg=()
aurhPkg=()
ofs=$IFS
IFS='|'

#-----------------------------#
# remove blacklisted packages #
#-----------------------------#
if [ -f "${scrDir}/pkg_black.lst" ]; then
    grep -v -f <(grep -v '^#' "${scrDir}/pkg_black.lst" | sed 's/#.*//;s/ //g;/^$/d') <(sed 's/#.*//' "${scrDir}/install_pkg.lst") >"${scrDir}/install_pkg_filtered.lst"
    mv "${scrDir}/install_pkg_filtered.lst" "${scrDir}/install_pkg.lst"
fi

while read -r pkg deps; do
    pkg="${pkg// /}"
    if [ -z "${pkg}" ]; then
        continue
    fi

    if [ -n "${deps}" ]; then
        deps="${deps%"${deps##*[![:space:]]}"}"
        while read -r cdep; do
            pass=$(cut -d '#' -f 1 "${listPkg}" | awk -F '|' -v chk="${cdep}" '{if($1 == chk) {print 1;exit}}')
            if [ -z "${pass}" ]; then
                if pkg_installed "${cdep}"; then
                    pass=1
                else
                    break
                fi
            fi
        done < <(xargs -n1 <<<"${deps}")

        if [[ ${pass} -ne 1 ]]; then
            print_log -warn "missing" "dependency [ ${deps} ] for ${pkg}..."
            continue
        fi
    fi

    if pkg_installed "${pkg}"; then
        print_log -y "[skip] " "${pkg}"
    elif pkg_available "${pkg}"; then
        repo=$(pacman -Si "${pkg}" | awk -F ': ' '/Repository / {print $2}' | tr '\n' ' ')
        print_log -b "[queue] " "${pkg}" -b " :: " -g "${repo}"
        archPkg+=("${pkg}")
    elif aur_available "${pkg}"; then
        print_log -b "[queue] " "${pkg}" -b " :: " -g "aur"
        aurhPkg+=("${pkg}")
    else
        print_log -r "[error] " "unknown package ${pkg}..."
    fi
done < <(cut -d '#' -f 1 "${listPkg}")

IFS=${ofs}

# Handle Hyprland ecosystem dependency conflicts
if grep -q "hyprland" "${scrDir}/install_pkg.lst"; then
    print_log -sec "hyprland" -warn "Resolving" "Hyprland ecosystem dependency conflicts..."
    
    # Remove conflicting packages first if they exist
    conflicting_packages=("hyprutils" "aquamarine" "hyprgraphics" "hyprpaper" "hyprlang" "hyprland-qtutils")
    for pkg in "${conflicting_packages[@]}"; do
        if pacman -Q "$pkg" >/dev/null 2>&1; then
            print_log -sec "hyprland" -stat "removing" "$pkg (resolving conflicts)"
            if [ "${flg_DryRun}" -ne 1 ]; then
                sudo pacman -Rdd "$pkg" --noconfirm || true
            fi
        fi
    done
    
    # Install Hyprland and its ecosystem together
    print_log -sec "hyprland" -stat "installing" "Hyprland ecosystem as a group"
    if [ "${flg_DryRun}" -ne 1 ]; then
        sudo pacman -S hyprland --noconfirm || {
            print_log -sec "hyprland" -warn "fallback" "Installing from AUR"
            ${aurhlpr} -S hyprland-git --noconfirm
        }
    fi
fi

install_packages() {
    local -n pkg_array=$1
    local pkg_type=$2
    local install_cmd=$3

    if [[ ${#pkg_array[@]} -gt 0 ]]; then
        print_log -b "[install] " "$pkg_type packages..."
        if [ "${flg_DryRun}" -eq 1 ]; then
            for pkg in "${pkg_array[@]}"; do
                print_log -b "[pkg] " "${pkg}"
            done
        else
            $install_cmd ${use_default:+"$use_default"} -S "${pkg_array[@]}"
        fi
    fi
}

echo ""
install_packages archPkg "arch" "sudo pacman"
echo ""
install_packages aurhPkg "aur" "${aurhlpr}"
