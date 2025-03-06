#!/bin/bash

## Keyitdev https://github.com/Keyitdev/sddm-astronaut-theme
## Copyright (C) 2022-2025 Keyitdev
## Distributed under the GPLv3+ License https://www.gnu.org/licenses/gpl-3.0.html

red='\033[0;31m'
green='\033[0;32m'
no_color='\033[0m'
date=$(date +%s)

path_to_git_clone="$HOME"

install_dependencies(){
    # Download
    wget https://mirrors.ocf.berkeley.edu/qt/official_releases/qt/6.8/6.8.2/single/qt-everywhere-src-6.8.2.zip
    # unzip
    unzip qt-everywhere-src-6.8.2.zip
    # Build
    mkdir -p ~/dev/qt-build
    cd ~/dev/qt-build
    /tmp/qt-everywhere-src-6.8.2/configure
    # If configure runs successfully, then proceed with building the libraries and tools:
    cmake --build . --parallel
    # After building, you need to install the libraries and tools in the appropriate place (unless you enabled a developer build):
    sudo cmake --install .
    # Add to PATH
    export PATH=/usr/local/Qt-6.8.2/bin:$PATH

    sudo apt-get -y install libqt6svg6-dev libqt6svg6 libqt6svgwidgets6 qt6-virtualkeyboard-plugin qt6-virtualkeyboard-dev qt6-multimedia-dev libqt6multimedia6 
    # Window Manager
    sudo apt-get update
    sudo apt-get install -y --no-install-recommends sddm
    sudo systemctl enable sddm
}

# Set SDDM as the default
sudo update-alternatives --set default-displaymanager /usr/lib/X11/displaymanagers/sddm

git_clone(){
    umask 022
    echo -e "${green}[*] Cloning theme to $path_to_git_clone.${no_color}"
    if [ -d "$path_to_git_clone/sddm-astronaut-theme" ]; then
        sudo mv "$path_to_git_clone/sddm-astronaut-theme" "$path_to_git_clone/sddm-astronaut-theme_$date"
        echo -e "${green}[*] Old configs detected in $path_to_git_clone, backing up.${no_color}"
    fi
    git clone -b master --depth 1 https://github.com/keyitdev/sddm-astronaut-theme.git "$path_to_git_clone/sddm-astronaut-theme"
}

copy_files(){
    umask 022
    echo -e "${green}[*] Copying theme from $path_to_git_clone to /usr/share/sddm/themes/.${no_color}"
    if [ -d /usr/share/sddm/themes/sddm-astronaut-theme ]; then
        sudo mv /usr/share/sddm/themes/sddm-astronaut-theme /usr/share/sddm/themes/sddm-astronaut-theme_$date
        echo -e "${green}[*] Old configs detected in /usr/share/sddm/themes/sddm-astronaut-theme, backing up.${no_color}"
    fi
    sudo mkdir -p /usr/share/sddm/themes/sddm-astronaut-theme
    sudo cp -r "$path_to_git_clone/sddm-astronaut-theme/"* /usr/share/sddm/themes/sddm-astronaut-theme
    sudo cp -r /usr/share/sddm/themes/sddm-astronaut-theme/Fonts/* /usr/share/fonts/
    echo -e "${green}[*] Setting up theme.${no_color}"
    echo -e "[Theme]\nCurrent=sddm-astronaut-theme" | sudo tee /etc/sddm.conf
    echo -e "[General]\nInputMethod=qtvirtualkeyboard" | sudo tee /etc/sddm.conf.d/virtualkbd.conf
}

select_theme(){
    path_to_metadata="/usr/share/sddm/themes/sddm-astronaut-theme/metadata.desktop"
    text="ConfigFile=Themes/"

    line=$(grep "$text" "$path_to_metadata")

    themes="astronaut black_hole cyberpunk hyprland_kath jake_the_dog japanese_aesthetic pixel_sakura pixel_sakura_static post-apocalyptic_hacker purple_leaves"
    
    echo -e "${green}[*] Select theme (enter number e.g. astronaut - 1).${no_color}"
    echo -e "${green}[*] 0. Other (choose if you created your own theme).${no_color}"
    echo -e "${green}[*] 1. Astronaut                   2. Black hole${no_color}"
    echo -e "${green}[*] 3. Cyberpunk                   4. Hyprland Kath (animated)${no_color}"
    echo -e "${green}[*] 5. Jake the dog (animated)     6. Japanese aesthetic${no_color}"
    echo -e "${green}[*] 7. Pixel sakura (animated)     8. Pixel sakura (static)${no_color}"
    echo -e "${green}[*] 9. Post-apocalyptic hacker    10. Purple leaves${no_color}"
    read -p "[*] Your choice: " new_number
    
    if [ "$new_number" -eq 0 ] 2>/dev/null; then
        echo -e "${green}[*] Enter name of the config file (without .conf).${no_color}"
        read -p "[*] Theme name: " answer
        selected_theme="$answer"
    elif [ "$new_number" -ge 1 ] 2>/dev/null && [ "$new_number" -le 10 ] 2>/dev/null; then
        set -- $themes
        selected_theme=$(echo "$@" | cut -d ' ' -f $new_number)
        echo -e "${green}[*] You selected: $selected_theme ${no_color}"
    else
        echo -e "${red}[*] Error: invalid number or input.${no_color}"
        exit 1
    fi

    modified_line="$text$selected_theme.conf"

    sudo sed -i "s|^$text.*|$modified_line|" "$path_to_metadata"
    echo -e "${green}[*] Changed: $line -> $modified_line${no_color}"
}

while true; do
    clear
    echo -e "${green}sddm-astronaut-theme made by Keyitdev${no_color}"
    echo -e "${green}[*] Choose option.${no_color}"
    echo -e "1. All of the below."
    echo -e "2. Install dependencies with package manager."
    echo -e "3. Clone theme from github.com to $path_to_git_clone."
    echo -e "4. Copy theme from $path_to_git_clone to /usr/share/sddm/themes/."
    echo -e "5. Select theme (/usr/share/sddm/themes/)."
    echo -e "6. Preview the set theme (/usr/share/sddm/themes/)."
    echo -e "7. Exit."
    read -p "[*] Your choice: " x
    case $x in
        1 ) install_dependencies; git_clone; copy_files; select_theme; exit 0;;
        2 ) install_dependencies; exit 0;;
        3 ) git_clone; exit 0;;
        4 ) copy_files; exit 0;;
        5 ) select_theme; exit 0;;
        6 ) sddm-greeter-qt6 --test-mode --theme /usr/share/sddm/themes/sddm-astronaut-theme/; exit 0;;
        7 ) exit 0;;
        * )  echo -e "${red}[*] Error: invalid number or input.${no_color}";;
    esac
done
