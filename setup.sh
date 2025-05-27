#!/usr/bin/env bash
# setup.sh
# Script to set up an Ubuntu environment with Homebrew and various packages.
# Author: twoofthree
# Date: 2024-10-01
# Usage: ./setup.sh
# Note: Do not run as root.

# This script is licensed under the MIT License.
# See the LICENSE file in the project root for license information.

#💥 There it is, Captain — the holy trinity of Bash discipline
set -euo pipefail

# Log output to a file
# exec > >(tee -i setup.log)
# exec 2>&1

# Check if running as root
if [[ $EUID -eq 0 ]]; then
    echo "This script should not be run as root."
    exit 1
fi

#echo "This script will require administrative privileges. You may be prompted for your password."
#sudo -v

# Get the directory of the script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Determine installation states
HOMEBREW_INSTALLED=false
JAVA_INSTALLED=false

pause() {
    read -n1 -rsp $'Press any key to continue...\n'
}

if command -v brew &>/dev/null; then
    HOMEBREW_INSTALLED=true
fi

# Check if Java installed via Homebrew (linuxbrew)
if command -v java &>/dev/null; then
    JAVA_PATH=$(command -v java)
    if [[ "$JAVA_PATH" == *"linuxbrew"* ]]; then
        JAVA_INSTALLED=true
    fi
fi


install_development()
{
    
    echo ""
    echo "📦 Installing Build Essentials"
    echo ""
    
    #libtool-bin # Different from libtool
    
    sudo apt install --no-install-recommends \
    cmake ninja-build automake autoconf autopoint libtool g++ pkg-config swig \
    doxygen dpkg-dev graphviz libltdl-dev libc6-dev libcurl4-openssl-dev gettext intltool \
    python3-setuptools python3-pip python3-wheel \
    subversion git curl ccache
    
    echo ""
    echo "✅ Build Essentials Installed"
    echo ""
    
    #pause
    
}

##REMOVE

# Function for full setup
full_setup() {
    
    # Prompt for Homebrew installation
    #read -p "Do you want to install the Homebrew environment? (y/N): " INSTALL_HB
    #if [[ "$INSTALL_HB" =~ ^[Yy]$ ]]; then
    #install_homebrew
    #else
    #echo "Skipping Homebrew installation."
    #fi
    
    #install_homebrew_java
    install_development
    
    install_nodejs
    
    # Prompt for Kubuntu desktop installation
    read -p "Do you want to install the Plasma desktop environment? (y/N): " INSTALL_PLASMA
    if [[ "$INSTALL_PLASMA" =~ ^[Yy]$ ]]; then
        install_kde_plasma_desktop
    else
        echo "Skipping Plasma desktop installation."
    fi
    
    install_apt_apps
    install_deb_packages
    install_appimages
    
    echo ""
    echo "Full Setup Finished"
    echo ""
    
    #pause
}

# Function to install Homebrew
install_homebrew() {
    if ! $HOMEBREW_INSTALLED; then
        echo "Installing Homebrew..."
        
        # Install dependencies
        sudo apt update
        sudo apt install -y build-essential curl file git
        
        # Run the Homebrew installation script
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        
        # Add Homebrew to the PATH in .bashrc
        if ! grep -qxF '# Homebrew configuration' "$HOME/.bashrc"; then
            {
                echo '# Homebrew configuration'
                echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"'
            } >> "$HOME/.bashrc"
        fi
        
        # Evaluate Homebrew environment for the current script
        eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
        HOMEBREW_INSTALLED=true
    else
        echo "Homebrew is already installed."
        # Ensure brew shellenv is evaluated
        eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
    fi
    
    #FIX
    #brew uninstall --ignore-dependencies python
    
    # Update and upgrade Homebrew
    brew update && brew upgrade && brew cleanup
    
    # Install applications via Homebrew
    brew install cocoapods
    brew install arduino-cli
    brew install esptool
    #brew install node@23
    
    # Set up CocoaPods
    echo "Setting up CocoaPods..."
    pod setup
    
    #pause
}

# Function to install Java
install_homebrew_java() {
    if ! $JAVA_INSTALLED; then
        echo "Installing Java..."
        
        if $HOMEBREW_INSTALLED; then
            
            brew install openjdk
            
            # Find the Java home directory
            JAVA_HOME_DIR=$(brew --prefix openjdk)/libexec/openjdk.jdk
            if [ ! -d "$JAVA_HOME_DIR" ]; then
                JAVA_HOME_DIR=$(brew --prefix openjdk)
            fi
            
            # Add JAVA_HOME to .bashrc with precise comments
            if ! grep -qxF '# Java configuration' "$HOME/.bashrc"; then
                {
                    echo '# Java configuration'
                    echo 'export LC_ALL=en_US.UTF-8'
                    echo "export JAVA_HOME=$JAVA_HOME_DIR"
                    echo 'export PATH=$JAVA_HOME/bin:$PATH'
                } >> "$HOME/.bashrc"
            fi
            
            # Source the updated .bashrc
            source "$HOME/.bashrc"
            JAVA_INSTALLED=true
            echo "Java has been installed and configured."
            echo "Please restart your terminal for the changes to take effect."
            
        else
            
            echo "Java install requires Homebrew"
        fi
        
    else
        echo "Java is already installed."
    fi
    
    #pause
}

# Function to remove Java
remove_java() {
    
    sudo apt purge -y openjdk*
    
    if $JAVA_INSTALLED; then
        echo "Removing Java..."
        
        # Find the installed Java package
        JAVA_PACKAGE=$(brew list --formula | grep -E '^openjdk(@[0-9]+)?$' || true)
        if [ -n "$JAVA_PACKAGE" ]; then
            brew uninstall "$JAVA_PACKAGE"
        else
            echo "Java package not found in Homebrew. Skipping brew uninstall."
        fi
        
        # Remove Java configuration from .bashrc
        sed -i.bak '/# Java configuration/,/^$/d' "$HOME/.bashrc"
        
        # Source the updated .bashrc
        source "$HOME/.bashrc"
        JAVA_INSTALLED=false
        echo "Java has been removed."
        echo "Please restart your terminal for the changes to take effect."
    else
        echo "Java is not installed."
    fi
    
    #pause
}

##REMOVE
manage_java_old() {
    echo "--------------------------------------------"
    echo "Java Management"
    echo "--------------------------------------------"
    
    if $JAVA_INSTALLED; then
        echo "Java is currently installed."
        read -p "Do you want to remove Java? (y/N): " REMOVE_JAVA
        if [[ "$REMOVE_JAVA" =~ ^[Yy]$ ]]; then
            remove_java
        else
            echo "Java will not be removed."
        fi
    else
        echo "Java is not installed."
        read -p "Do you want to install Java? (y/N): " INSTALL_JAVA
        if [[ "$INSTALL_JAVA" =~ ^[Yy]$ ]]; then
            install_homebrew
            install_homebrew_java
        else
            echo "Java will not be installed."
        fi
    fi
}

manage_java() {
    
    clear
    echo "--------------------------------------------"
    echo "Java Management"
    echo "--------------------------------------------"
    echo "Select the Java version to install:"
    echo "1) default-jre"
    echo "2) openjdk-8-jre-headless"
    echo "3) openjdk-11-jre-headless"
    echo "4) openjdk-17-jre-headless"
    echo "5) openjdk-21-jre-headless"
    echo "6) openjdk-22-jre-headless"
    echo "7) openjdk-23-jre-headless"
    echo "8) openjdk-24-jre-headless"
    #echo "9) Homebrew Java (openjdk)"
    echo "r) Remove Java"
    echo "q) Quit"
    echo
    
    read -p "Enter your choice: " java_choice
    
    case "$java_choice" in
        1)  sudo apt install -y default-jre ;;
        2)  sudo apt install -y openjdk-8-jre-headless ;;
        3)  sudo apt install -y openjdk-11-jre-headless ;;
        4)  sudo apt install -y openjdk-17-jre-headless ;;
        5)  sudo apt install -y openjdk-21-jre-headless ;;
        6)  sudo apt install -y openjdk-22-jre-headless ;;
        7)  sudo apt install -y openjdk-23-jre-headless ;;
        8)  sudo apt install -y openjdk-24-jre-headless ;;
        9)
            echo "Installing Java via Homebrew."
            install_homebrew
            install_homebrew_java
        ;;
        r|R)
            remove_java
        ;;
        q|Q)
            echo "Aborted Java management."
            #main_menu
        ;;
        *)
            echo "Invalid choice. No action taken."
        ;;
    esac
    
    pause
    main_menu
}


################################################################################
######                          Node.JS
################################################################################

install_nodejs(){
    
    local options="${1:-}"
    
    #🌐 Networking & Downloads
    sudo apt install -y --no-install-recommends curl
    
    ##########
    # Node.js
    ##########
    #https://www.jemrf.com/pages/how-to-install-nvm-and-node-js-on-raspberry-pi
    echo "Installing Node.js..."
    curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.33.11/install.sh | bash
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # This loads nvm
    command -v nvm
    nvm install stable
    npm install -g npm@11.2.0
    node -v
    
    # Reinstall TileServer GL from source
    # git clone https://github.com/maptiler/tileserver-gl.git
    # cd tileserver-gl/
    # nvm install 18
    # nvm use 18
    
    # echo "18" > .nvmrc
    # nvm use
    
    # npm install
    
    #npm install -g --build-from-source tileserver-gl
    #sudo ln -s /usr/lib/aarch64-linux-gnu/libjpeg.so.62 /usr/lib/aarch64-linux-gnu/libjpeg.so.8
    #sudo apt install -y libvips libvips-dev build-essential
    
    #sudo apt install -y --no-install-recommends nodejs
    echo "Installation of Node.js complete..."
    
    # Skip pause if "-s" is passed
    #if [ "$options" != "-s" ]; then
        #pause
    #fi
    
}

install_kde_plasma_desktop(){
    
    # Prompt for Kubuntu desktop installation
    #read -p "Do you want to install the Plasma desktop environment? (y/N): " INSTALL_PLASMA
    #if [[ "$INSTALL_PLASMA" =~ ^[Yy]$ ]]; then
        
        echo "Installing KDE Plasma desktop..."
        
        #https://packages.debian.org/bookworm/kde/
        
        base_desktop=(
            # Core Plasma shell and settings
            kde-plasma-desktop
            systemsettings
            powerdevil
            kscreen
            #
            kinfocenter
            aha  clinfo  edid-decode  libdisplay-info-bin  libpulsedsp  mesa-utils  mesa-utils-bin  pulseaudio-utils  vulkan-tools  wayland-utils
            #
            kwin-x11
            kdeconnect
            qml6-module-org-kde-kdeconnect
            kde-config-screenlocker
            kde-config-gtk-style
            qt5-gtk-platformtheme
            kde-config-plymouth
            kde-config-sddm
            kde-config-tablet
            kde-config-updates
            kde-config-cron
            kde-config-cddb
            kde-config-flatpak
            kde-config-gtk-style-preview
            xdg-desktop-portal-kde
            
            # Plasma Discover (app store + backends)
            plasma-discover
            plasma-discover-backend-flatpak
            plasma-discover-backend-snap
            plasma-discover-backend-fwupd
            
            # System tray and desktop extensions
            plasma-pa                # Audio control
            plasma-nm                # Network control
            plasma-systemmonitor     # New system monitor UI
            plasma-thunderbolt       # Thunderbolt settings
            plasma-firewall          # Firewall GUI
            plasma-vault             # Encrypted vaults
            
            # Update and release notifications
            plasma-discover-notifier
            plasma-distro-release-notifier
            
            # Browser integration and welcome
            plasma-browser-integration
            #plasma-welcome
            
            # Widgets, calendar, engine add-ons
            plasma-calendar-addons
            plasma-dataengines-addons
            plasma-widgets-addons
            
            # Appearance (themes, visuals)
            plasma-theme-oxygen
            plasma-workspace-wallpapers
            plasma-wallpapers-addons
            kdegraphics-thumbnailers
            ffmpegthumbs
            kio-extras
            plymouth-theme-breeze
            plymouth-theme-kubuntu-logo
            plymouth-theme-kubuntu-text
        )
        
        essential_kde_utilities=(
            kmenuedit
            ksshaskpass
            kwalletmanager
            ksystemlog
            khelpcenter
            kdf
            partitionmanager
            plasma-browser-integration
            plasma-discover-notifier
            plasma-disks
            kcalc
            kcharselect
            kamera
            bluedevil
            print-manager
        )
        
        #sddm
        #sddm-theme
        #qt6-virtualkeyboard-plugin
        
        all_packages=(
            "${base_desktop[@]}"
            "${essential_kde_utilities[@]}"
        )
        
        install_apps "${all_packages[@]}"
        
    #else
    #    echo "Skipping Plasma desktop installation."
    #fi
    
    #pause
    
}

# Function to install Kubuntu desktop
install_kde_desktop() {
    # Prompt for Kubuntu desktop installation
    read -p "Do you want to install the Full KDE desktop environment? (y/N): " INSTALL_KDE
    if [[ "$INSTALL_KDE" =~ ^[Yy]$ ]]; then
        
        echo "Installing Kubuntu desktop environment..."
        sudo apt update
        sudo apt install kubuntu-desktop
        echo "Kubuntu desktop has been installed."
        reboot_system
    else
        echo "Skipping Kubuntu desktop installation."
    fi
    
    #pause
}

# Function to remove Kubuntu desktop
remove_kde_desktop() {
    read -p "Do you want to remove the Full KDE desktop environment? (y/N): " REMOVE_KDE
    if [[ "$REMOVE_KDE" =~ ^[Yy]$ ]]; then
        echo "Removing Kubuntu desktop environment..."
        sudo apt purge -y kubuntu-desktop
        sudo apt autoremove -y
        echo "Kubuntu desktop has been removed."
        reboot_system
    else
        echo "Skipping Kubuntu desktop installation."
    fi
    
    #pause
}

# Function to reboot system
reboot_system() {
    read -p "The system will need to reboot to complete the installation/removal of Kubuntu desktop. Reboot now? (y/N): " REBOOT
    if [[ "$REBOOT" =~ ^[Yy]$ ]]; then
        sudo reboot
    else
        echo "Please remember to reboot your system later to apply the changes."
    fi
}

# Helper function for updating and upgrading the system
update_upgrade() {
    #do-release-upgrade
    echo "🧩 Updating APT package lists..."
    sudo apt update
    
    echo "📦 Upgrading installed APT packages..."
    sudo apt upgrade -y
    
    echo "🔁 Performing full APT distribution upgrade..."
    sudo apt full-upgrade -y
    
    echo "🧹 Autoremoving orphaned packages..."
    sudo apt autoremove -y
    
    echo "🧽 Cleaning APT package cache..."
    sudo apt clean
    
    if command -v snap &> /dev/null; then
        echo "📦 Updating Snap packages..."
        sudo snap refresh
    fi
    
    if command -v flatpak &> /dev/null; then
        echo "📦 Updating Flatpak packages..."
        flatpak update -y
    fi
    
    echo ""
    echo "✅ System update complete."
    echo ""
    #pause
}

install_apps() {
    local packages=("$@")
    echo "Installing: ${packages[*]}"
    sudo apt install --no-install-recommends "${packages[@]}"
}

install_applications_all(){
    
    install_apt_apps -s
    install_snap_apps -s
    install_deb_packages -s
    install_appimages -s
    
    echo ""
    echo "✅ Full Setup Finished"
    echo ""
    
    #pause
}
# Function to install applications
install_apt_apps() {
    
    local options="${1:-}"
    
    echo "Installing applications..."
    
    # Update and upgrade apt packages
    # update_upgrade
    
    
    ### 🧰 Development Tools
    dev_tools=(
        flex
        bison
        patch
        #ant
        python-is-python3
        protobuf-compiler
        ragel
        lua5.4
    )
    ### 🐧 System Utilities
    system_utils=(
        unzip dos2unix flatpak fwupd geany gparted gpart
        htop rpi-imager mtools kpartx subversion
    )
    ### 💾 File System & Disk Tools
    fs_disk_tools=(
        exfatprogs jfsutils reiserfsprogs xfsprogs udftools libparted-dev
    )
    ### 🔐 Security & Auth
    security_tools=(
        opensc pcscd fido2-tools yubico-piv-tool libpam-pkcs11 xca
    )
    ### 🖥️ Multimedia / GUI / OBS
    gui_apps=(
        #libwebkit2gtk-4.1-dev \
        mpv obs-studio
    )
    ### 📱 Mobile / Flash / Embedded
    embedded_tools=(
        adb binwalk
    )
    ### 🌍 Web & Remote Tools
    remote_tools=(
        curl wget elinks
    )
    ### 🛠 Miscellaneous / Special Purpose
    misc_tools=(
        rpi-imager python-is-python3
        #dotnet-sdk-9.0
    )
    
    all_packages=(
        "${dev_tools[@]}"
        "${system_utils[@]}"
        "${fs_disk_tools[@]}"
        "${security_tools[@]}"
        "${gui_apps[@]}"
        "${embedded_tools[@]}"
        "${misc_tools[@]}"
    )
    
    install_apps "${all_packages[@]}"
    
    
    # Skip pause if "-s" is passed
    #if [ "$options" != "-s" ]; then
        #pause
    #fi
    
}

install_snap_apps(){
    
    local options="${1:-}"
    
    # Install snap packages from snap_list.txt
    echo "Installing snap packages..."
    if [ -f "$SCRIPT_DIR/snap_list.txt" ]; then
        while IFS= read -r package; do
            echo "Installing $package..."
            sudo snap install "$package"
        done < "$SCRIPT_DIR/snap_list.txt"
    else
        echo "snap_list.txt not found in $SCRIPT_DIR."
    fi
    
    # Install snaps with classic confinement
    echo "Installing snap packages with classic confinement..."
    sudo snap install android-studio --classic
    sudo snap install blender --classic
    sudo snap install code --classic
    sudo snap install codium --classic
    sudo snap install intellij-idea-ultimate --classic
    
    # Skip pause if "-s" is passed
    #if [ "$options" != "-s" ]; then
        #pause
    #fi
    
}

# Function to install .deb packages
install_deb_packages() {
    
    local options="${1:-}"
    
    DEB_URLS=(
        "https://download1.repetier.com/files/server/debian-amd64/Repetier-Server-1.4.16-Linux.deb"
        "https://github.com/balena-io/etcher/releases/download/v1.19.25/balena-etcher_1.19.25_amd64.deb"
        "https://launchpad.net/veracrypt/trunk/1.26.14/+download/veracrypt-1.26.14-Ubuntu-24.04-amd64.deb"
    )
    DOWNLOAD_DIR="$HOME/Downloads"
    
    echo "Downloading and installing .deb packages..."
    
    for url in "${DEB_URLS[@]}"; do
        filename=$(basename "$url")
        filepath="$DOWNLOAD_DIR/$filename"
        if [ -f "$filepath" ]; then
            echo "$filename already exists in $DOWNLOAD_DIR. Skipping download."
        else
            echo "Downloading $filename..."
            wget --progress=bar:force -O "$filepath" "$url"
        fi
        echo "Installing $filename..."
        sudo dpkg -i "$filepath" || sudo apt install -f -y
    done
    
    echo ".deb packages installation complete."
    
    # Skip pause if "-s" is passed
    #if [ "$options" != "-s" ]; then
        #pause
    #fi
}

# Function to install AppImages
install_appimages() {
    
    local options="${1:-}"
    
    APPIMAGE_URLS=(
        "https://github.com/audacity/audacity/releases/download/Audacity-3.7.1/audacity-linux-3.7.1-x64-22.04.AppImage"
        "https://github.com/SoftFever/OrcaSlicer/releases/download/v2.2.0/OrcaSlicer_Linux_Ubuntu2404_V2.2.0.AppImage"
        "https://github.com/OpenShot/openshot-qt/releases/download/v3.3.0/OpenShot-v3.3.0-x86_64.AppImage"
    )
    APP_NAMES=(
        "Audacity"
        "OrcaSlicer"
        "OpenShot Video Editor"
    )
    DOWNLOAD_DIR="$HOME/Downloads"
    APPIMAGE_DIR="$HOME/AppImages"
    
    echo "Downloading AppImage packages..."
    
    # Create APPIMAGE_DIR if it doesn't exist
    if [ ! -d "$APPIMAGE_DIR" ]; then
        mkdir -p "$APPIMAGE_DIR"
    fi
    
    for index in "${!APPIMAGE_URLS[@]}"; do
        url="${APPIMAGE_URLS[$index]}"
        app_name="${APP_NAMES[$index]}"
        filename=$(basename "$url")
        filepath="$DOWNLOAD_DIR/$filename"
        target_path="$APPIMAGE_DIR/$filename"
        
        # Check if the AppImage already exists at the final location
        if [ -f "$target_path" ]; then
            echo "$filename already exists in $APPIMAGE_DIR. Skipping download."
        else
            echo "Downloading $filename..."
            wget --progress=bar:force -O "$filepath" "$url"
            chmod +x "$filepath"
            mv "$filepath" "$target_path"
            echo "Moved $filename to $APPIMAGE_DIR."
        fi
        
        # Create .desktop file
        desktop_file="$HOME/.local/share/applications/${filename%.AppImage}.desktop"
        if [ ! -f "$desktop_file" ]; then
            echo "Creating desktop entry for $app_name..."
            mkdir -p "$(dirname "$desktop_file")"
            cat > "$desktop_file" << EOL
[Desktop Entry]
Name=$app_name
Exec=$target_path
Icon=$target_path
Type=Application
Categories=AudioVideo;Audio;Video;Editor;
Terminal=false
EOL
            echo "Desktop entry created at $desktop_file."
        else
            echo "Desktop entry for $app_name already exists. Skipping."
        fi
    done
    
    echo "AppImage packages installation complete."
    
    
    # Skip pause if "-s" is passed
    #if [ "$options" != "-s" ]; then
        #pause
    #fi
}


# Function to install and start ssh-server

setup_ssh() {
    echo "Installing and configuring SSH Server..."
    echo ""
    
    # Update and install OpenSSH server
    sudo apt update
    sudo apt install -y openssh-server
    
    # Enable and start SSH
    sudo systemctl enable ssh
    sudo systemctl start ssh
    
    # Configure firewall
    sudo ufw allow ssh
    sudo ufw reload
    
    # Check SSH status
    sudo systemctl status ssh --no-pager
    
    echo ""
    echo "SSH Server installed and started."
    echo ""
    
    # Provide a brief message about further SSH config
    # Gather hostname and local IP info for user reference
    local hostnameInfo
    local ipAddress
    
    hostnameInfo=$(hostname)
    # Attempt to fetch first detected IP (may need adjustment in multi-NIC systems)
    ipAddress=$(hostname -I | awk '{print $1}')
    
    echo "Further configuration:"
    echo " - To edit SSH settings, run: sudo nano /etc/ssh/sshd_config"
    echo " - Then restart SSH with:   sudo systemctl restart ssh"
    echo ""
    echo "You can connect to this machine via SSH using one of these methods:"
    echo "    ssh <username>@${ipAddress}"
    echo "    ssh <username>@${hostnameInfo}"
    echo ""
    
    #pause
    
}

################################################################################
######       MENUs
################################################################################

# Main Menu
main_menu(){
    
    while true; do
        
        clear
        echo "--------------------------------------------"
        echo "Ubuntu Setup Menu"
        echo "--------------------------------------------"
        echo "1) System Applications"
        echo "2) Snap Applications"
        echo "3) Deb Packages"
        echo "4) App Images"
        echo "5) All Applications (1,2,3,4)"
        echo "6) Development Tools (make, etc...)"
        echo "7) Add/Remove Java"
        echo "8) Add Node.js®"
        echo "9) Install Plasma Desktop"
        echo "--------------------------------------------"
        echo "10) Install Kubuntu Desktop"
        echo "11) Remove Kubuntu Desktop"
        echo "--------------------------------------------"
        echo "12) Install Homebrew"
        echo "--------------------------------------------"
        echo "13) Set Up SSH Server"
        echo "14) Full Applications and System Wide Update(s)"
        echo "--------------------------------------------"
        echo "15) Exit"
        read -rp "Please select an option [1-15]: " choice
        case $choice in
            1)
                install_apt_apps
            ;;
            2)
                install_snap_apps
            ;;
            3)
                install_deb_packages
            ;;
            4)
                install_appimages
            ;;
            5)
                install_applications_all
            ;;
            6)
                install_development
            ;;
            7)
                manage_java
            ;;
            8)
                install_nodejs
            ;;
            9)
                install_kde_plasma_desktop
            ;;
            10)
                # Add Kubuntu Desktop
                install_kde_desktop
            ;;
            11)
                # Remove Kubuntu Desktop
                remove_kde_desktop
            ;;
            12)
                # Install Homebrew
                install_homebrew
            ;;
            13)
                # Set Up SSH
                setup_ssh
            ;;
            14)
                # Helper function for updating and upgrading the system
                update_upgrade
            ;;
            15)
                echo "Exiting."
                exit 0
            ;;
            *)
                echo "Invalid option. Please try again."
                
            ;;
        esac
        pause
    done
}

main_menu
