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
package_managers=("dpkg" "rpm" "pacman" "equery" "apt-get" "pacman" "dnf" "emerge")
for dependency in $dependencies; do
  found=false
  for package_manager in "${package_managers[@]}"; do
    if command -v "$package_manager" >/dev/null 2>&1; then
      if "$package_manager" -s "$dependency" >/dev/null 2>&1 || \
         "$package_manager" -q "$dependency" >/dev/null 2>&1 || \
         "$package_manager" -Q "$dependency" >/dev/null 2>&1 || \
         "$package_manager" -q list "$dependency" >/dev/null 2>&1; then
        found=true
        break
      fi
    fi
  done
  if [ "$found" = false ]; then
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
        clear && display_header
        echo -e "${GREEN}Dependencies successfully installed. Running...${ENDCOLOR}"
        break
        ;;
      [Nn]|[Nn][Oo])
        clear
        echo -e "${RED}Dependencies not satisfied... Exiting!${ENDCOLOR}"
        exit 0
        ;;
      *)
        echo "Invalid selection. Please enter 'yes' or 'no'."
        ;;
    esac
  done
fi

clear && display_header

display_help() {
    echo
    echo -e "${BLUE}Usage:${ENDCOLOR} ./json_ota_helper.sh ${ORANGE}<input_json>${ENDCOLOR}"
    echo
    echo -e "${RED}Note:${ENDCOLOR} The input json should contain the following properties:"
    echo -e "${CYAN} - datetime: Unix timestamp of the build"
    echo -e " - filehash: md5 checksum of the build.zip"
    echo -e " - filename: Name of the build.zip"
    echo -e " - id: sha256 checksum of the build.zip"
    echo -e " - size: Size of the build.zip in bytes${ENDCOLOR}"
}

if [ $# -ne 1 ]; then
    display_help
    exit 1
fi

input_json="$1"
if [ ! -f "$input_json" ]; then
    echo -e "${RED}Input json, ${CYAN}$input_json${RED} not found!${ENDCOLOR}"
    display_help
    exit 1
fi

filename=$(jq -r '.filename' "$input_json")
if [ -z "$filename" ]; then
    echo -e "${RED}Invalid input json: ${CYAN}$input_json${RED}"
    echo "The input JSON file is missing the 'filename' property or has an invalid format."
    echo "Please make sure the input json contains a 'filename' property in the format 'evolution_<codename>-ota-<>.json'"
    exit 1
fi

codename=$(echo "$filename" | sed -E 's/^evolution_([^.-]+)-ota-.+$/\1/')
if [ -z "$codename" ]; then
    display_help
    exit 1
fi

output_json="./builds/${codename}.json"
if [ ! -f "$output_json" ]; then
    echo -e "${RED}Output json, ${CYAN}$output_json${RED} not found!${ENDCOLOR}"
    exit 1
fi

old_data=$(cat "$output_json")

if [ "$(<"$input_json")" = "$old_data" ]; then
    echo "No changes required. All properties match."
    exit 0
fi

required_properties=("datetime" "filehash" "filename" "id" "size")
for prop in "${required_properties[@]}"; do
    if ! jq -e ".${prop}" "$input_json" >/dev/null; then
        echo -e "${RED}Invalid input json: ${CYAN}$input_json${RED}"
        echo "The input JSON file is missing the '${prop}' property."
        echo "Please make sure the input json contains all the required properties:"
        for req_prop in "${required_properties[@]}"; do
            echo "- ${req_prop}"
        done
        exit 1
    fi
done

datetime=$(jq -r '.datetime' "$input_json")
filehash=$(jq -r '.filehash' "$input_json")
id=$(jq -r '.id' "$input_json")
size=$(jq -r '.size' "$input_json")

split_name=(${filename//-/ })
first_char=${split_name[2]:0:1}

if [ "$first_char" = "u" ]; then
    version="14"
else
    version="13"
fi

url="https://sourceforge.net/projects/evolution-x/files/${codename}/${version}/${filename}/download/"

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

temp_file=$(mktemp)

jq --argjson datetime "$datetime" --arg filehash "$filehash" --arg id "$id" --argjson size "$size" --arg url "$url" --arg filename "$filename" \
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
    if [[ $answer =~ ^[Yy][Ee][Ss]$ ]]; then
        select_changelog_edit_method
    elif [[ $answer =~ ^[Nn][Oo]$ ]]; then
        exit 0
    else
        echo "Invalid selection. Please enter 'yes' or 'no'."
        add_changelog
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
    elif [[ $sign_commit =~ ^[Nn][Oo]$ ]]; then
        git commit -m "$commit_name"
        echo -e "${GREEN}Commit created successfully.${ENDCOLOR}"
        exit 0
    else
        echo "Invalid selection. Please enter 'yes' or 'no'."
        git_commit
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

select_changelog_edit_method() {
    clear
    display_header

    read -p "Select an editor to create the changelog with:
    1. Nano
    2. Vim
    3. Gedit
    4. Emacs
    5. VSCode
    6. Enter your own command
    7. Exit
    (1-7): " selection

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
            if check_command "code"; then
                clear
                code --wait changelogs/${codename}/${filename}.txt
                git_commit
            fi
            ;;
        6)
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
        7)
            clear
            echo -e "${RED}Session ended.${ENDCOLOR}"
            exit 0
            ;;
        *)
            clear && display_header
            echo -e "${ORANGE}Invalid selection. Please enter (1-6).${ENDCOLOR}"
            sleep 1
            select_changelog_edit_method
            ;;
    esac
}

add_changelog
select_changelog_edit_method
