#!/bin/bash

GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
ENDCOLOR='\033[0m'

display_header() {
    echo -e "${GREEN}===========================================================${ENDCOLOR}"
    echo -e "${BLUE}      ______            __      __  _                _  __  ${ENDCOLOR}"
    echo -e "${BLUE}     / ____/   ______  / /_  __/ /_(_)___  ____     | |/ /  ${ENDCOLOR}"
    echo -e "${BLUE}    / __/ | | / / __ \/ / / / / __/ / __ \/ __ \    |   /   ${ENDCOLOR}"
    echo -e "${BLUE}   / /___ | |/ / /_/ / / /_/ / /_/ / /_/ / / / /   /   |    ${ENDCOLOR}"
    echo -e "${BLUE}  /_____/ |___/\____/_/\__,_/\__/_/\____/_/ /_/   /_/|_|    ${ENDCOLOR}"
    echo -e "${BLUE}                                                            ${ENDCOLOR}"
    echo -e "${BLUE}                     XDA thread generator                   ${ENDCOLOR}"
    echo -e "${BLUE}                                                            ${ENDCOLOR}"
    echo -e "${BLUE}                         #KeepEvolving                      ${ENDCOLOR}"
    echo -e "${GREEN}===========================================================${ENDCOLOR}"
}

generate_thread() {

  clear && display_header

    # Device manufacturer
    while true; do
        read -p "Manufacturer name: " manufacturer
        if [[ $manufacturer =~ [0-9] ]]; then
            echo "Manufacturer name should not contain numbers. Please try again."
            continue
        fi

        manufacturer_lowercase=$(echo "$manufacturer" | tr '[:upper:]' '[:lower:]')

        case $manufacturer_lowercase in
            "google")
                manufacturer_name="[SIZE=6][B][COLOR=rgb(0, 96, 255)]G[/COLOR][COLOR=rgb(184, 49, 47)]o[/COLOR][COLOR=rgb(250, 197, 28)]o[/COLOR][COLOR=rgb(0, 96, 255)]g[/COLOR][COLOR=rgb(97, 189, 109)]l[/COLOR][COLOR=rgb(184, 49, 47)]e[/COLOR][/B][/SIZE]"
                ;;
            "oneplus")
                manufacturer_name="[B][COLOR=rgb(226, 80, 65)][SIZE=6]OnePlus[/SIZE][/COLOR][/B]"
                ;;
            "xiaomi")
                manufacturer_name="[B][COLOR=rgb(251, 160, 38)][SIZE=6]Xiaomi[/SIZE][/COLOR][/B]"
                ;;
            *)
                manufacturer_name="[B][COLOR=rgb(0, 96, 255)][SIZE=6]$(tr '[:lower:]' '[:upper:]' <<< ${manufacturer:0:1})${manufacturer:1}[/SIZE][/COLOR][/B]"
                ;;
        esac
        break
    done

    # Device name & codename
    if [ ! -z "$manufacturer_name" ]; then
        echo "Device names (separated by ',' and/or '&' e.g Pixel 7, 7 Pro & 7a): "
        read -r devices
        devices=$(echo "$devices" | sed 's/\s*\(,\|&\)\s*/\1/g')
        IFS=',&' read -ra device_array <<< "$devices"

        device_count=${#device_array[@]}

        if [ $device_count -eq 1 ]; then
            device="${device_array[0]}"
            device_name="[COLOR=rgb(0, 96, 255)][B][SIZE=6]$device[/SIZE][/B][/COLOR]"
            echo "Codename for $device: "
            read codename
            codenames="[COLOR=rgb(0, 96, 255)][B][SIZE=6][$codename][/SIZE][/B][/COLOR]"
        else
            device_name="[COLOR=rgb(0, 96, 255)][B][SIZE=6]"
            codenames="[COLOR=rgb(0, 96, 255)][B][SIZE=6]"
            for ((i=0; i<$device_count; i++)); do
                device="${device_array[i]}"
                device_name+="$device"
                echo "Codename for $device: "
                read codename
                codenames+="[$codename]"
                if [ $i -ne $(($device_count - 1)) ]; then
                    if [ $i -eq $(($device_count - 2)) ]; then
                        device_name+=" & "
                        codenames+=""
                    else
                        device_name+=", "
                        codenames+=""
                    fi
                fi
            done
            device_name+="[/SIZE][/B][/COLOR]"
            codenames+="[/SIZE][/B][/COLOR]"
        fi

        # Banner styles
        while true; do
                echo "Choose the banner style:"
                echo "1. Center punch-hole notch"
                echo "2. Left side punch-hole notch"
                echo "3. No notch"
                echo "4. Pop up camera"
                echo "5. Tablet"
                read -p "Enter your choice (1-5): " banner_style

                case $banner_style in
                        1) banner_image="banner_style_1.png"; break;;
                        2) banner_image="banner_style_2.png"; break;;
                        3) banner_image="banner_style_3.png"; break;;
                        4) banner_image="banner_style_4.png"; break;;
                        5) banner_image="banner_style_5.png"; break;;
                        *) echo "Invalid choice. Please enter a number between 1 and 5.";;
                esac
        done

        # Security patch URL/Name
        while true; do
            read -p "Security patch level (mm/yyyy): " security_patch_level
            patch_month=${security_patch_level%%/*}
            patch_year=${security_patch_level##*/}

            if [[ $security_patch_level =~ ^[0-9]{2}/[0-9]{4}$ && $patch_month -ge 1 && $patch_month -le 12 ]]; then
                patch_month_full=$(date -d "$patch_month/1" +%B)
                security_patch_level_date="$patch_month_full $patch_year"
                security_patch_url="https://source.android.com/security/bulletin/$patch_year-$patch_month-01"
                current_date=$(date +%Y%m)
                provided_date=$(printf "%d%02d" "$patch_year" "$patch_month")
                if [[ $provided_date -le $current_date ]]; then
                    break
                else
                    echo -e "${RED}The provided date is in the future. Please enter a valid date.${ENDCOLOR}"
                fi
            else
                echo -e "${RED}Invalid format or out of range. Please use mm/yyyy format with a valid month and year.${ENDCOLOR}"
            fi
        done

        # XDA second post URL
        while true; do
            read -p "XDA thread second post URL (this is where your download links should reside): " installation_images_url
            if [[ $installation_images_url =~ ^https://xdaforums\.com/t/ ]]; then
                break
            else
                echo -e "${RED}Invalid format. Please enter a URL starting with 'https://xdaforums.com/t/'.${ENDCOLOR}"
            fi
        done

        # Manifest URL & Android version
        while true; do
            branches=($(curl -s "https://api.github.com/repos/Evolution-X/manifest/branches" | jq -r '.[].name'))

            echo "Available branches:"
            for index in "${!branches[@]}"; do
                printf "%s) %s\n" "$((index+1))" "${branches[index]}"
            done

            read -p "Select the manifest branch used for compilation: " branch_index

            if [[ ! "$branch_index" =~ ^[0-9]+$ || $branch_index -le 0 || $branch_index -gt ${#branches[@]} ]]; then
                echo -e "${RED}Invalid selection. Please enter a valid option (1-${#branches[@]}).${ENDCOLOR}"
                continue
            fi

            selected_branch=${branches[$((branch_index-1))]}
            raw_manifest_url="https://raw.githubusercontent.com/Evolution-X/manifest/$selected_branch/default.xml"
            xml_data=$(curl -s "$raw_manifest_url")
            tree_url="https://github.com/Evolution-X/manifest/tree/$selected_branch"

            if [[ ! -z "$xml_data" ]]; then
                android_version=$(echo "$xml_data" | grep -oP '(?<=<default revision="refs/tags/android-)[^"]+')

                if [[ ! -z "$android_version" ]]; then
                    echo -e "${GREEN}Android version detected: $android_version${ENDCOLOR}"
                    blob_manifest_url="https://github.com/Evolution-X/manifest/blob/$selected_branch/"
                    break
                else
                    echo -e "${RED}Android version not found in the XML.${ENDCOLOR}"
                fi
            else
                echo -e "${RED}Failed to fetch XML data from $raw_manifest_url.${ENDCOLOR}"
            fi
        done

        # Kernel source URL
        while true; do
            read -p "Kernel Source URL: " kernel_source_url
            if [[ $kernel_source_url =~ ^(https?://)?(www\.)?(github\.com|gitlab\.com|bitbucket\.org|git\.com|android.googlesource\.com)(.*) ]]; then
                break
            else
                echo -e "${RED}Invalid format. Please enter a valid URL from GitHub, GitLab, Bitbucket, or any other Git hosting service.${ENDCOLOR}"
            fi
        done

        # Clang version
        while true; do
            read -p "Clang Version: " clang_version
            if [[ $clang_version =~ ^[0-9]+(\.[0-9]+)*$ ]]; then
                break
            else
                echo -e "${RED}Invalid format. Please enter a Clang version in the format of only numbers with optional decimal points (e.g., 14.0.7).${ENDCOLOR}"
            fi
        done

        # Maintainer name
        while true; do
            read -p "Your full name: " maintainer_name
            if [[ ! $maintainer_name =~ [0-9] ]]; then
                break
            else
                echo -e "${RED}Invalid name. Please enter your full name without numbers.${ENDCOLOR}"
            fi
        done

        # XDA profile URL
        while true; do
            read -p "XDA profile URL: " xda_profile_url_full
            if [[ $xda_profile_url_full =~ ^https://xdaforums\.com/m/[[:alnum:]]+\.[[:digit:]]+/ ]]; then
                break
            else
                echo -e "${RED}Invalid format. Please enter a URL in the format: https://xdaforums.com/m/username.123456/${ENDCOLOR}"
            fi
        done

        xda_username=$(echo "$xda_profile_url_full" | awk -F'/' '{print $(NF-1)}')
        xda_profile_url="https://xdaforums.com/m/$xda_username/"

        # Donation URL
        while true; do
            read -p "Donation URL: " donation_url
            if [[ $donation_url =~ ^https?:// ]]; then
                break
            else
                echo -e "${RED}Invalid format. Please enter a valid URL starting with 'http://' or 'https://'.${ENDCOLOR}"
            fi
        done

        # Device support URL
        while true; do
            read -p "Device support URL: " device_support_url
            if [[ $device_support_url =~ ^(https?://)?(www\.)?(discord\.com|discord\.gg|t\.me|telegram\.me|telegram\.org)(.*) ]]; then
                break
            else
                echo -e "${RED}Invalid format. Please enter a valid URL from Discord or Telegram.${ENDCOLOR}"
             fi
        done

        cat << EOF > /tmp/generated_xda_thread.txt
[CENTER]
$manufacturer_name $device_name
$codenames

[IMG]https://raw.githubusercontent.com/Evolution-X-Devices/official_devices/master/xda/xda_assets/$banner_image[/IMG]

[SIZE=5][B][COLOR=#0060FF][B]Pixel UI, customization and more, we are Evolution X![/B][/COLOR][/B][/SIZE]

[URL='https://xdaforums.com/m/joeyhuab.4936496/']Joey Huab[/URL] - Founder/Lead Developer
[URL='https://xdaforums.com/m/anierinb.7125966/']Anierin Bliss[/URL] - Co-Founder/Project Specialist
[URL='https://xdaforums.com/m/realakito.9008281/']Akito Mizukito[/URL] - Co-Founder/Project Manager

[I]Reach us on Twitter! [URL='https://twitter.com/EvolutionXROM']@EvolutionXROM[/URL][/I]
Check out our [URL='https://evolution-x.org/']website[/URL]!

[IMG]https://raw.githubusercontent.com/Evolution-X-Devices/official_devices/master/xda/xda_assets/features.png[/IMG]

[URL='https://github.com/Evolution-X-Devices/official_devices/blob/master/xda/features.md']Added features[/URL]

[IMG]https://raw.githubusercontent.com/Evolution-X-Devices/official_devices/master/xda/xda_assets/known_issues.png[/IMG]

[SIZE=5][B][COLOR=red]DO NOT FLASH GAPPS, THEY ARE ALREADY INCLUDED[/COLOR][/B][/SIZE]

[B][IMG]https://raw.githubusercontent.com/Evolution-X-Devices/official_devices/master/xda/xda_assets/installation.png[/IMG][/B]

[SPOILER]
[SIZE=5][B][COLOR=rgb(0, 96, 255)][SIZE=5][B]First Time Install[/B][/SIZE][/COLOR][/B][/SIZE]
[COLOR=rgb(251, 160, 38)](Note: These releases include firmware)[/COLOR]
1. Download boot, dtbo, vendor_kernel_boot, vendor_boot & rom for your device from [URL='$installation_images_url']here[/URL]
2. Reboot to bootloader
3. fastboot flash boot boot.img
fastboot flash dtbo dtbo.img
fastboot flash vendor_kernel_boot vendor_kernel_boot.img
fastboot flash vendor_boot vendor_boot.img
fastboot reboot recovery
4. While in recovery, navigate to Factory reset -> Format data/factory reset and confirm to format the device.
5. When done formatting, go back to the main menu and then navigate to Apply update -> Apply from ADB
6. adb sideload rom.zip (replace "rom" with actual filename)
7 (optional). Reboot to recovery (fully) to sideload any add-ons (e.g magisk)
8. Reboot to system & #KeepEvolving

[SIZE=5][B][COLOR=rgb(0, 96, 255)]Update[/COLOR][/B][/SIZE]
[SIZE=3]1. Reboot to recovery
2. While in recovery, navigate to Apply update -> Apply from ADB
3. adb sideload rom.zip (replace "rom" with  actual filename)[/SIZE]
4 (optional). Reboot to recovery to sideload any add-ons (e.g magisk)
[SIZE=3]5. Reboot to system & #KeepEvolving

[COLOR=rgb(0, 96, 255)][SIZE=5][B]OTA[/B][/SIZE][/COLOR][/SIZE]
[SIZE=3]1. Check for update. If available, select "Download and install" (approx 10-15 min)
2. Reboot & #KeepEvolving[/SIZE]
[/SPOILER]

[URL='$donation_url'][IMG width="200px" height="180px"]https://raw.githubusercontent.com/Evolution-X-Devices/official_devices/master/xda/xda_assets/donate_to_me.png[/IMG][/URL][URL='https://discord.gg/3qbSZHx'][IMG width="200px" height="180px"]https://raw.githubusercontent.com/Evolution-X-Devices/official_devices/master/xda/xda_assets/official_chat.png[/IMG][/URL][URL='$device_support_url'][IMG width="200px" height="180px"]https://raw.githubusercontent.com/Evolution-X-Devices/official_devices/master/xda/xda_assets/device_support.png[/IMG][/URL][/CENTER]

[TABLE]
[TR]
[TD][IMG]https://raw.githubusercontent.com/Evolution-X-Devices/official_devices/master/xda/xda_assets/source.png[/IMG][/TD]
[/TR]
[TR]
[TD][B][COLOR=rgb(97, 189, 109)]Android version[/COLOR]:[/B] [URL='$tree_url']$android_version[/URL][/TD]
[/TR]
[TR]
[TD][B][COLOR=rgb(184, 49, 47)]Security patch level[/COLOR]:[/B] [URL='$security_patch_url']$security_patch_level_date[/URL][/TD]
[/TR]
[TR]
[TD][B][COLOR=rgb(41, 105, 176)]Build author[/COLOR]:[/B] [URL='$xda_profile_url']$maintainer_name[/URL][/TD]
[/TR]
[TR]
[TD][B][COLOR=rgb(65, 168, 95)]Kernel Source[/COLOR]:[/B] [URL]$kernel_source_url[/URL][/TD]
[/TR]
[TR]
[TD][COLOR=rgb(243, 121, 52)][B]Clang version:[/B] $clang_version[/COLOR][/TD]
[/TR]
[TR]
[TD][B][COLOR=rgb(41, 105, 176)]ROM Developer[/COLOR]:[/B] [URL='https://xdaforums.com/member.php?u=4936496']Joey Huab[/URL][/TD]
[/TR]
[TR]
[TD][B][COLOR=rgb(97, 189, 109)]Source code[/COLOR]:[/B] [URL]https://github.com/Evolution-X[/URL][/TD]
[/TR]
[/TABLE]
[CENTER][/CENTER]
EOF
        echo -e "${GREEN}Thread saved to '/tmp/generated_xda_thread.txt'${ENDCOLOR}"
    fi
}

generate_thread
