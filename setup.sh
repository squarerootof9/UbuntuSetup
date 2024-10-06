#!/usr/bin/env bash
# setup.sh
# Script to set up an Ubuntu environment with Homebrew and various packages.
# Author: twoofthree
# Date: 2024-10-01
# Usage: ./setup.sh
# Note: Do not run as root.

# This script is licensed under the MIT License.
# See the LICENSE file in the project root for license information.

set -euo pipefail

# Log output to a file
# exec > >(tee -i setup.log)
# exec 2>&1

# Check if running as root
if [[ $EUID -eq 0 ]]; then
    echo "This script should not be run as root."
    exit 1
fi

echo "This script will require administrative privileges. You may be prompted for your password."
sudo -v

# Get the directory of the script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Determine installation states
HOMEBREW_INSTALLED=false
JAVA_INSTALLED=false

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

    # Update and upgrade Homebrew
    brew update && brew upgrade && brew cleanup
}

# Function to install Java
install_java() {
    if ! $JAVA_INSTALLED; then
        echo "Installing Java..."
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
        echo "Java is already installed."
    fi
}

# Function to remove Java
remove_java() {
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
}

# Function to install Kubuntu desktop
install_kde() {
    echo "Installing Kubuntu desktop environment..."
    sudo apt update
    sudo apt install -y kubuntu-desktop
    echo "Kubuntu desktop has been installed."
    reboot_system
}

# Function to remove Kubuntu desktop
remove_kde() {
    echo "Removing Kubuntu desktop environment..."
    sudo apt purge -y kubuntu-desktop
    sudo apt autoremove -y
    echo "Kubuntu desktop has been removed."
    reboot_system
}

# Function to reboot system
reboot_system() {
    read -p "The system needs to reboot to complete the installation/removal of Kubuntu desktop. Reboot now? (y/N): " REBOOT
    if [[ "$REBOOT" =~ ^[Yy]$ ]]; then
        sudo reboot
    else
        echo "Please remember to reboot your system later to apply the changes."
    fi
}

# Function to install applications
install_apps() {
    echo "Installing applications..."

    # Update and upgrade apt packages
    sudo apt update
    sudo apt upgrade -y

    # Install necessary packages via apt
    sudo apt install -y \
        adb \
        automake \
        ant \
        autopoint \
        binwalk \
        bison \
        build-essential \
        cmake \
        curl \
        dmraid \
        dos2unix \
        elinks \
        exfatprogs \
        flex \
        gpart \
        gparted \
        git \
        jfsutils \
        kpartx \
        libparted-dev \
        libtool-bin \
        libwebkit2gtk-4.1-dev \
        lua5.4 \
        mtools \
        patch \
        pkg-config \
        protobuf-compiler \
        python-is-python3 \
        ragel \
        reiser4progs \
        reiserfsprogs \
        subversion \
        udftools \
        unzip \
        wget \
        xfsprogs

    # Install applications via Homebrew
    brew install cocoapods
    brew install arduino-cli
    brew install esptool

    # Set up CocoaPods
    echo "Setting up CocoaPods..."
    pod setup

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
}

# Function to install .deb packages
install_deb_packages() {
    DEB_URLS=(
        "https://download1.repetier.com/files/server/debian-amd64/Repetier-Server-1.4.16-Linux.deb"
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
}

# Function to install AppImages
install_appimages() {
    APPIMAGE_URLS=(
        "https://github.com/audacity/audacity/releases/download/Audacity-3.5.1/audacity-linux-3.5.1-x64.AppImage"
        "https://github.com/SoftFever/OrcaSlicer/releases/download/v2.0.0/OrcaSlicer_Linux_V2.0.0.AppImage"
        "https://github.com/OpenShot/openshot-qt/releases/download/daily/OpenShot-v3.1.1-dev-daily-11909-a9e34a9b-8e9d7edc-x86_64.AppImage"
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
}

# Function for full setup
full_setup() {
    install_homebrew
    install_java
    install_apps
    install_deb_packages
    install_appimages

    # Prompt for Kubuntu desktop installation
    read -p "Do you want to install the Kubuntu desktop environment? (y/N): " INSTALL_KDE
    if [[ "$INSTALL_KDE" =~ ^[Yy]$ ]]; then
        install_kde
    else
        echo "Skipping Kubuntu desktop installation."
    fi
}

# Menu system
show_menu() {
    echo "--------------------------------------------"
    echo "Setup Script Menu"
    echo "--------------------------------------------"
    echo "1) Full setup (Homebrew, Java, Apps)"
    echo "2) Add/Remove Java"
    echo "3) Add Kubuntu Desktop"
    echo "4) Remove Kubuntu Desktop"
    echo "5) Exit"
    echo "--------------------------------------------"
    read -rp "Please select an option [1-5]: " choice
    case $choice in
        1)
            full_setup
            ;;
        2)
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
                    install_java
                else
                    echo "Java will not be installed."
                fi
            fi
            ;;
        3)
            # Add Kubuntu Desktop
            install_kde
            ;;
        4)
            # Remove Kubuntu Desktop
            remove_kde
            ;;
        5)
            echo "Exiting."
            exit 0
            ;;
        *)
            echo "Invalid option. Please try again."
            show_menu
            ;;
    esac
}

# Main script execution
show_menu

