#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
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
    echo -e "${BLUE}                        Json OTA helper                     ${ENDCOLOR}"
    echo -e "${BLUE}                                                            ${ENDCOLOR}"
    echo -e "${BLUE}                         #KeepEvolving                      ${ENDCOLOR}"
    echo -e "${GREEN}===========================================================${ENDCOLOR}"
}

clear

dependencies="coreutils git jq"

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
      coreutils)
        echo -e "${BLUE}$dependency: A collection of essential command-line utilities for basic file and text manipulation.${ENDCOLOR}"
        ;;
      git)
        echo -e "${BLUE}$dependency: A distributed version control system.${ENDCOLOR}"
        ;;
      jq)
        echo -e "${BLUE}$dependency: A lightweight and flexible command-line tool for parsing and manipulating JSON data.${ENDCOLOR}"
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
        clear
        echo -e "${GREEN}Dependencies successfully installed. Running...${ENDCOLOR}"
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

clear && display_header

display_help() {
    echo
    echo -e "${BLUE}Usage:${ENDCOLOR} $0 ${ORANGE}<input_json_from_out_dir>${ENDCOLOR}"
    echo -e "${CYAN}Updates the information from the input JSON file to the corresponding codename.json file.${ENDCOLOR}"
    echo
    echo -e "${BLUE}Arguments:${ENDCOLOR}"
    echo -e "${ORANGE}input_json_from_out_dir${ENDCOLOR}   ${CYAN}The JSON file used to update ./builds/codename.json${ENDCOLOR}"
    echo
    echo -e "${RED}Note:${ENDCOLOR} The input file should follow the format 'evolution_<codename>-ota-<>.json'"
}

if [ $# -ne 1 ]; then
    display_help
    exit 1
fi

input_json="$1"

if [ ! -f "$input_json" ]; then
    echo -e "${RED}Input file, ${CYAN}$input_json${RED} not found!${ENDCOLOR}"
    display_help
    exit 1
fi

codename=$(basename "$input_json" | sed -E 's/^evolution_([^.-]+)-ota-.+$/\1/')
input_data=$(cat "$input_json")
filename=$(echo "$input_data" | jq -r '.filename')

if [ -z "$codename" ] || [ -z "$filename" ]; then
    echo "Invalid input file name: $input_json"  
    echo "Please make sure the input file follows the format 'evolution_<codename>-ota-<>.json'"
    exit 1
fi

output_json="./builds/${codename}.json"

datetime=$(echo "$input_data" | jq -r '.datetime')
filehash=$(echo "$input_data" | jq -r '.filehash')
id=$(echo "$input_data" | jq -r '.id')
size=$(echo "$input_data" | jq -r '.size')

url="https://sourceforge.net/projects/evolution-x/files/${codename}/${filename}/download/"

if [ -f "$output_json" ]; then
    old_data=$(cat "$output_json")

    if [ "$input_data" = "$old_data" ]; then
        echo "No changes required. All properties match."
        exit 0
    fi

    display_diff() {
        local old_value=$1
        local new_value=$2
        local property=$3

        if [ "$old_value" != "$new_value" ]; then
            echo -e "  ${CYAN}${property}:${ENDCOLOR}"
            echo -e "    ${CYAN}Old:${ENDCOLOR} ${RED}${old_value}${ENDCOLOR}"
            echo -e "    ${CYAN}New:${ENDCOLOR} ${GREEN}${new_value}${ENDCOLOR}"
            return 1
        fi
    }

    echo -e "${ORANGE}Updating ${codename}.json:${ENDCOLOR}"
    changes_found=0

    display_diff "$(echo "$old_data" | jq -r '.datetime')" "$datetime" "datetime" || changes_found=1
    display_diff "$(echo "$old_data" | jq -r '.filehash')" "$filehash" "filehash" || changes_found=1
    display_diff "$(echo "$old_data" | jq -r '.id')" "$id" "id" || changes_found=1
    display_diff "$(echo "$old_data" | jq -r '.size')" "$size" "size" || changes_found=1
    display_diff "$(echo "$old_data" | jq -r '.url')" "$url" "url" || changes_found=1
    display_diff "$(echo "$old_data" | jq -r '.filename')" "$filename" "filename" || changes_found=1

    if [ "$changes_found" -eq 0 ]; then
        echo -e "${ORANGE}No changes required. All properties match.${ENDCOLOR}"
        exit 0
    fi
fi

temp_file=$(mktemp)

jq --arg datetime "$datetime" --arg filehash "$filehash" --arg id "$id" --arg size "$size" --arg url "$url" --arg filename "$filename" \
    '.datetime = $datetime
     | .filehash = $filehash
     | .id = $id
     | .size = $size
     | .url = $url
     | .filename = $filename' \
    "$output_json" > "$temp_file"

echo -e "${GREEN}Updated ${codename}.json${ENDCOLOR}"
echo
jq --indent 3 . "$temp_file" > "$temp_file.indented"
jq . "$temp_file.indented"
echo

mv "$temp_file.indented" "$output_json"

add_changelog() {
    read -p "Do you want to add a changelog? (yes/no): " answer
    if [[ $answer == "yes" ]]; then
        select_changelog_edit_method
    else
        exit 0
    fi
}

check_command() {
    if ! command -v "$1" &>/dev/null; then
        clear && display_header
        echo -e "${RED}Error: $1 is not installed! Please install it and try again.${ENDCOLOR}"
        sleep 1
        return 1
    fi
}

git_commit() {
    git add ./builds/${codename}.json
    git add changelogs/${codename}/${filename}.txt

    commit_name="$(tr '[:lower:]' '[:upper:]' <<< ${codename:0:1})${codename:1}: $(date +'%m/%d/%Y') Update"
    echo "Commit Name: $commit_name"

    read -p "Do you want to sign the commit? (yes/no): " sign_commit
    if [[ $sign_commit =~ ^[Yy][Ee][Ss]$ ]]; then
        git commit -s -m "$commit_name"
        echo -e "${GREEN}Commit created successfully.${ENDCOLOR}"
        exit 0
    else
        git commit -m "$commit_name"
        echo -e "${GREEN}Commit created successfully.${ENDCOLOR}"
        exit 0
    fi
}

select_changelog_edit_method() {
    clear
    display_header

    read -p "Select an editor to create the changelog with:
    1. Nano
    2. Vim
    3. Gedit
    4. Emacs
    5. Enter your own command
    6. Exit
    (1-6): " selection

    case "$selection" in
        1)
            if check_command "nano"; then
                clear
                nano changelogs/${codename}/${filename}.txt
                git_commit
            fi
            ;;
        2)
            if check_command "vim"; then
                clear
                vim changelogs/${codename}/${filename}.txt
                git_commit
            fi
            ;;
        3)
            if check_command "gedit"; then
                clear
                gedit changelogs/${codename}/${filename}.txt
                git_commit
            fi
            ;;
        4)
            if check_command "emacs"; then
                clear
                emacs changelogs/${codename}/${filename}.txt
                git_commit
            fi
            ;;
        5)
            clear && display_header
            read -p "Enter a valid program name to open the changelog file (changelogs/${codename}/${filename}.txt): " custom_cmd
            if command -v "$custom_cmd" &>/dev/null; then
                eval "$custom_cmd changelogs/${codename}/${filename}.txt"
                git_commit
            else
                clear && display_header
                echo -e "${ORANGE}$custom_cmd not found, returning to the main menu..${ENDCOLOR}"
                sleep 1
            fi
            ;;
        6)
            clear
            echo -e "${RED}Session ended.${ENDCOLOR}"
            exit 0
            ;;
        *)
            clear && display_header
            echo -e "${ORANGE}Invalid selection! Try again. (1-6).${ENDCOLOR}"
            sleep 1
            select_changelog_edit_method
            ;;
    esac
}

add_changelog
select_changelog_edit_method
