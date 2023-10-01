#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
ORANGE='\033[0;33m'
ENDCOLOR='\033[0m'

display_header() {
    echo -e "${GREEN}===========================================================${ENDCOLOR}"
    echo -e "${BLUE}      ______            __      __  _                _  __  ${ENDCOLOR}"
    echo -e "${BLUE}     / ____/   ______  / /_  __/ /_(_)___  ____     | |/ /  ${ENDCOLOR}"
    echo -e "${BLUE}    / __/ | | / / __ \/ / / / / __/ / __ \/ __ \    |   /   ${ENDCOLOR}"
    echo -e "${BLUE}   / /___ | |/ / /_/ / / /_/ / /_/ / /_/ / / / /   /   |    ${ENDCOLOR}"
    echo -e "${BLUE}  /_____/ |___/\____/_/\__,_/\__/_/\____/_/ /_/   /_/|_|    ${ENDCOLOR}"
    echo -e "${BLUE}                                                            ${ENDCOLOR}"
    echo -e "${BLUE}                     Device group generator                 ${ENDCOLOR}"
    echo -e "${BLUE}                                                            ${ENDCOLOR}"
    echo -e "${BLUE}                         #KeepEvolving                      ${ENDCOLOR}"
    echo -e "${GREEN}===========================================================${ENDCOLOR}"
}

dependencies="jq coreutils fzf"

missing_dependencies=()
for dependency in $dependencies; do
  if ! dpkg -s "$dependency" >/dev/null 2>&1 && ! rpm -q "$dependency" >/dev/null 2>&1 && ! pacman -Q "$dependency" >/dev/null 2>&1 && ! equery -q list "$dependency" >/dev/null 2>&1; then
    missing_dependencies+=("$dependency")
  fi
done

if [ ${#missing_dependencies[@]} -ne 0 ]; then
  clear && display_header
  echo -e "${ORANGE}Missing dependencies:${ENDCOLOR}"
  for dependency in "${missing_dependencies[@]}"; do
    case $dependency in
      jq)
        echo -e "${BLUE}$dependency: A lightweight and flexible command-line tool for parsing and manipulating JSON data.${ENDCOLOR}"
        ;;
      coreutils)
        echo -e "${BLUE}$dependency: A collection of essential command-line utilities for basic file and text manipulation.${ENDCOLOR}"
        ;;
    esac
  done

  while true; do
    read -p "Do you want to install these dependencies? (y/n): " choice
    case $choice in
      [Yy]|[Yy][Ee][Ss])
        if [ -x "$(command -v apt-get)" ]; then
          clear && display_header
          echo -e "${ORANGE}Debian/Ubuntu detected, installing required dependencies...${ENDCOLOR}"
          sudo apt-get update && sudo apt-get install -y "${missing_dependencies[@]}" || {
            echo -e "${RED}Error: Failed to install required dependencies using apt-get.${ENDCOLOR}"
            exit 1
          }
        elif [ -x "$(command -v pacman)" ]; then
          clear && display_header
          echo -e "${ORANGE}Arch detected, installing required dependencies...${ENDCOLOR}"
          sudo pacman -Sy --noconfirm "${missing_dependencies[@]}" || {
            echo -e "${RED}Error: Failed to install required dependencies using pacman.${ENDCOLOR}"
            exit 1
          }
        elif [ -x "$(command -v dnf)" ]; then
          clear && display_header
          echo -e "${ORANGE}Fedora detected, installing required dependencies...${ENDCOLOR}"
          sudo dnf update -y && sudo dnf install -y "${missing_dependencies[@]}" || {
            echo -e "${RED}Error: Failed to install required dependencies using dnf.${ENDCOLOR}"
            exit 1
          }
      elif [ -x "$(command -v emerge)" ]; then
        echo -e "${ORANGE}Gentoo detected, installing required dependencies...${ENDCOLOR}"
        clear && display_header
        sudo emerge -av "${missing_dependencies[@]}" || {
          echo -e "${RED}Error: Failed to install required dependencies using emerge.${ENDCOLOR}"
          exit 1
        }
        else
          clear && display_header
          echo -e "${RED}Error: Unsupported distro or package manager detected.${ENDCOLOR}"
          exit 1
        fi
        clear && display_header
        echo -e "${GREEN}Dependencies successfully installed. Generating device groups...${ENDCOLOR}"
        break
        ;;
      [Nn]|[Nn][Oo])
        clear
        echo -e "${RED}Dependencies not satisfied... Exiting!${ENDCOLOR}"
        exit 0
        ;;
      *)
        echo "Invalid selection. Please enter 'y' or 'n'."
        ;;
    esac
  done
fi

devices=$(<devices.json)

declare -A device_groups

{
    echo "/save device_groups"
    for device in $(echo "${devices}" | jq -r '.[] | @base64'); do
        _jq() {
            echo "${device}" | base64 --decode | jq -r "${1}"
        }
        brand=$(_jq '.brand')
        device_group=$(_jq '.supported_versions[].device_group')

        if [[ -n $device_group ]]; then
            device_group="@${device_group}"
        fi

        if [ -z "${device_groups["${brand}"]}" ]; then
            device_groups["${brand}"]="${device_group}\n"
        else
            device_groups["${brand}"]+="${device_group}\n"
        fi
    done

    for brand in $(echo "${!device_groups[@]}" | tr ' ' '\n' | sort); do
        echo "${brand}:"
        echo -e "${device_groups[${brand}]}" | sort -u | awk NF
        echo
    done
} > /tmp/device_groups.txt

sed -i -e :a -e '/^\n*$/{$d;N;ba' -e '}' /tmp/device_groups.txt

check_command() {
    if ! command -v "$1" &>/dev/null; then
        clear && display_header
        echo -e "${RED}Error: $1 is not installed! Please install it and try again.${ENDCOLOR}"
        sleep 1
        return 1
    fi
}

clear
while true; do
    clear
    display_header
    sleep 1

    choices=$(echo "Exit-Regenerate (Restart script)-Enter your own command-Emacs-Gedit-Nvim-Vim-Nano" | tr '-' '\n')
    selection=$(echo "$choices" | fzf)

    case "$selection" in
        "Nano")
            if check_command "nano"; then
                clear
                nano /tmp/device_groups.txt
            fi
            ;;
        "Vim")
            if check_command "vim"; then
                clear
                vim /tmp/device_groups.txt
            fi
            ;;
        "Nvim")
            if check_command "nvim"; then
                clear
                nvim /tmp/device_groups.txt
            fi
            ;;
        "Gedit")
            if check_command "gedit"; then
                clear
                gedit /tmp/device_groups.txt
            fi
            ;;
        "Emacs")
            if check_command "emacs"; then
                clear
                emacs /tmp/device_groups.txt
            fi
            ;;
        "Enter your own command")
            clear && display_header
            read -p "Enter a valid program name to open device_groups with (/tmp/device_groups.txt will be appended): " custom_cmd
            if command -v "$custom_cmd" &>/dev/null; then
                eval "$custom_cmd /tmp/device_groups.txt"
            else
                clear && display_header
                echo -e "${ORANGE}$custom_cmd not found, returing to the main menu..${ENDCOLOR}"
                sleep 1
            fi
            ;;
        "Regenerate (Restart script)")
            clear && display_header
            echo -e "${GREEN}Regenerating device groups...${ENDCOLOR}"
            exec "$0"
            ;;
        "Exit")
            clear
            echo -e "${RED}Session ended.${ENDCOLOR}"
            break
            ;;
        *)
            clear && display_header
            echo -e "${ORANGE}Invalid selection! Try again. (1-7).${ENDCOLOR}"
            sleep 1
            ;;
    esac
done
