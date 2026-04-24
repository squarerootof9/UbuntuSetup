#!/usr/bin/env bash
# setup.sh
# Script to set up an Ubuntu environment with various packages.
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
JAVA_INSTALLED=false

# Check if Java installed via Homebrew (linuxbrew)
if command -v java &>/dev/null; then
	JAVA_PATH=$(command -v java)
	if [[ "$JAVA_PATH" == *"linuxbrew"* ]]; then
		JAVA_INSTALLED=true
	fi
fi

#######
# GUI #
#######

################################################################################
######       MENUs
################################################################################

# Text attributes
BOLD='\033[1m'
DIM='\033[2m'
ITALIC='\033[3m' # Not supported in all terminals
UNDERLINE='\033[4m'
INVERT='\033[7m'

# Reset (clears *all* attributes)
RESET='\033[0m'

# Colors (foreground)
RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
BLUE='\033[34m'
MAGENTA='\033[35m'
CYAN='\033[36m'
WHITE='\033[37m'

# Colors (bright)
BRIGHT_RED='\033[91m'
BRIGHT_GREEN='\033[92m'
BRIGHT_YELLOW='\033[93m'
BRIGHT_BLUE='\033[94m'
BRIGHT_MAGENTA='\033[95m'
BRIGHT_CYAN='\033[96m'
BRIGHT_WHITE='\033[97m'

msg_confirm() {
	local message="${1:-}"
	# Usage: msg_confirm "message" || return 1
	echo -en "${CYAN}$message${RESET} ${YELLOW}[Y/n]${RESET}: "
	read -r ans
	case "${ans,,}" in
	y | yes | "") return 0 ;;
	*)
		echo -e "${RED}✗ Operation cancelled.${RESET}\n"
		return 1
		;;
	esac
}

msg_pause() {
	read -n1 -rsp $'Press any key to continue...\n'
}

msg_start() {
	local message="${1:-}"
	echo -e "\n${CYAN}➜ ${message}${RESET}"
}

msg_end() {
	local message="${1:-}"
	echo -e "\n${GREEN}✓ ${message}${RESET}\n"
}

msg_text() {
	local message="${1:-}"
	echo -e "${YELLOW}${message}${RESET}"
}

install_development() {

	############################################
	## This function is shared across scripts ##
	##          Ignore duplicates             ##
	############################################
	echo ""
	echo "📦 Installing Build Essentials"
	echo ""

	#libtool-bin # Different from libtool?

	#flex bison ant	ragel lua5.4

	#python3-venv python3-pip python3-dev build-essential libasound2-dev

	#build-essential  libdbus-1-dev  libgeoclue-2-dev  libglib2.0-dev  libgps-dev  libsystemd-dev  meson

	# Core build toolchain (C/C++ friendly)
	PKGS_BUILD_CORE=(
		build-essential
		make
		g++
		libc6-dev
		dpkg-dev
	)

	# Autotools / build systems
	PKGS_BUILD_SYSTEMS=(
		cmake
		ninja-build
		automake
		autoconf
		autopoint
		libtool
		libtool-bin
		texinfo
		help2man
		pkg-config
		ccache
	)

	# Docs / diagrams
	PKGS_DOCS=(
		doxygen
		graphviz
	)

	# C/C++ libs & dev headers
	PKGS_CPP_DEPS=(
		libcurl4-openssl-dev
		libltdl-dev
		libncurses-dev
	)

	# i18n / localization tooling
	PKGS_I18N=(
		gettext
		intltool
	)

	# Python tooling (packaging)
	PKGS_PYTHON=(
		python-is-python3
		python3-venv
		python3-pip
		python3-setuptools
		python3-wheel
		pipx
		python3-dev
	)

	# VCS / network utilities
	PKGS_VCS_NET=(
		git
		subversion
		curl
	)

	# Codegen / interface glue
	PKGS_CODEGEN=(
		swig
		protobuf-compiler
	)

	# Misc build helpers
	PKGS_MISC=(
		patch
	)

	all_packages=(
		"${PKGS_BUILD_CORE[@]}"
		"${PKGS_BUILD_SYSTEMS[@]}"
		"${PKGS_DOCS[@]}"
		"${PKGS_CPP_DEPS[@]}"
		"${PKGS_I18N[@]}"
		"${PKGS_PYTHON[@]}"
		"${PKGS_VCS_NET[@]}"
		"${PKGS_CODEGEN[@]}"
		"${PKGS_MISC[@]}"
	)

	install_apps "${all_packages[@]}"

	echo ""
	echo "✅ Build Essentials Installed"
	echo ""
}

# Function to install Homebrew
install_homebrew() {

	if ! command -v brew &>/dev/null; then
		echo "Installing Homebrew..."

		# Install dependencies
		sudo apt install -y curl git

		# Run the Homebrew installation script
		/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

		#tmp_log="/tmp/brew_install.log"

		#/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" \
		#	>"$tmp_log" 2>&1

		# Add Homebrew to the PATH in .bashrc
		if ! grep -qxF '# Homebrew configuration' "$HOME/.bashrc"; then
			{
				echo '# Homebrew configuration'
				echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"'
			} >>"$HOME/.bashrc"
		fi

		# Evaluate Homebrew environment for the current script
		eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

	else
		echo "Homebrew is already installed."
		# Ensure brew shellenv is evaluated (not sure why)
		eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
	fi

	#FIX
	#brew uninstall --ignore-dependencies python

	# Update and upgrade Homebrew
	brew update && brew upgrade && brew cleanup

	# Install applications via Homebrew
	#brew install cocoapods
	#brew install arduino-cli
	#brew install esptool
	#brew install node@23

	# Set up CocoaPods
	#echo "Setting up CocoaPods..."
	#pod setup

	echo ""
	echo "Homebrew installed."
	echo ""
	echo "######################################"
	echo "Restart your session to finish install"
	echo "######################################"
	echo ""

}

remove_homebrew() {
	echo "Removing Homebrew…"

	# Default Linux prefix
	BREW_PREFIX="/home/linuxbrew/.linuxbrew"

	# Fallback if installed in user’s home (rare, but possible)
	if [ ! -d "$BREW_PREFIX" ]; then
		if [ -d "$HOME/.linuxbrew" ]; then
			BREW_PREFIX="$HOME/.linuxbrew"
		fi
	fi

	if [ ! -d "$BREW_PREFIX" ]; then
		echo "Homebrew is not installed."
		return 0
	fi

	echo "Found Homebrew at: $BREW_PREFIX"

	# Remove the directory
	sudo rm -rf "$BREW_PREFIX"

	# Remove environment entries from shell configs
	# These usually appear in .bashrc / .zshrc
	for rc in "$HOME/.bashrc" "$HOME/.zshrc"; do
		if [ -f "$rc" ]; then
			sed -i '/linuxbrew/d' "$rc"
			sed -i '/Homebrew/d' "$rc"
			sed -i '/brew shellenv/d' "$rc"
		fi
	done

	# Clean up symlinks placed in /usr/local/bin (optional safety)
	if [ -d "/usr/local/bin" ]; then
		find /usr/local/bin -lname "$BREW_PREFIX/*" -exec sudo rm -f {} \;
	fi

	echo ""
	echo "Homebrew removed."
	echo ""
	echo "######################################"
	echo "Restart your session to finish removal"
	echo "######################################"
	echo ""
}

# Function to install Java
install_homebrew_java() {
	if ! $JAVA_INSTALLED; then
		echo "Installing Java..."

		#check for brew removed

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
			} >>"$HOME/.bashrc"
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

	sudo apt purge openjdk*

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

###KDE

build_kde() {
	#https://develop.kde.org/docs/getting-started/building/kde-builder-setup/
	cd ~
	curl 'https://invent.kde.org/sdk/kde-builder/-/raw/master/scripts/initial_setup.sh' >initial_setup.sh
	chmod +x initial_setup.sh
	bash initial_setup.sh
	#source $HOME/kde/env.sh
	kde-builder --generate-config
	kde-builder --install-distro-packages
	kde-builder kcalc
	kde-builder --run kcalc

}

################################################################################
######                          Node.JS®
################################################################################

install_nodejs() {

	# Install dependencies
	sudo apt install -y curl git

	##########
	# Node.js
	##########
	#https://www.jemrf.com/pages/how-to-install-nvm-and-node-js-on-raspberry-pi
	echo "Installing Node.js®..."
	curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
	export NVM_DIR="$HOME/.nvm"
	[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"                   # This loads nvm
	[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion" # This loads nvm bash_completion

	command -v nvm
	nvm install stable
	npm install -g npm@latest
	node -v
	npm -v

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
	echo "Installation of Node.js® complete..."
	echo ""
	echo "####################################"
	echo "Restart your session to use Node.js®"
	echo "####################################"
	echo ""
}

remove_nodejs() {
	echo "Removing Node.js® (NVM install)..."

	# 1) Remove NVM directory (safe if missing)
	if [ -d "$HOME/.nvm" ]; then
		echo " - Removing $HOME/.nvm"
		rm -rf "$HOME/.nvm"
	else
		echo " - $HOME/.nvm already removed"
	fi

	# 2) Remove npm cache
	if [ -d "$HOME/.npm" ]; then
		echo " - Removing $HOME/.npm cache"
		rm -rf "$HOME/.npm"
	else
		echo " - $HOME/.npm cache already removed"
	fi

	# 3) Remove NVM-related lines from $HOME/.bashrc
	echo " - Cleaning up $HOME/.bashrc entries"

	# Patterns to remove (quiet if absent)
	sed -i '/export NVM_DIR=.*/d' "$HOME/.bashrc"
	sed -i '\|nvm.sh|d' "$HOME/.bashrc"
	sed -i '\|bash_completion.*nvm|d' "$HOME/.bashrc"

	#only works in current shell
	command -v nvm >/dev/null && nvm unload

	echo "Node.js® (NVM) removed."
	echo ""
	echo "######################################"
	echo "Restart your session to finish removal"
	echo "######################################"
	echo ""
}

install_kde_plasma_desktop() {

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
		konsole
		#
		kwin-x11
		kdeconnect
		qml6-module-org-kde-kdeconnect
		kde-config-screenlocker
		kde-config-gtk-style
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
		plasma-pa            # Audio control
		plasma-nm            # Network control
		plasma-systemmonitor # New system monitor UI
		plasma-thunderbolt   # Thunderbolt settings
		plasma-firewall      # Firewall GUI
		plasma-vault         # Encrypted vaults

		# Update and release notifications
		plasma-discover-notifier
		plasma-distro-release-notifier

		# Browser integration and welcome
		plasma-browser-integration
		#plasma-welcome

		# testing
		plasma-integration
		kaccounts-integration

		# Widgets, calendar, engine add-ons
		plasma-calendar-addons
		qt6-base-dev # needed for x86_64-linux-gnu-qtpaths6 by plasma-calendar-addons)
		plasma-dataengines-addons
		plasma-runners-addons
		plasma-widgets-addons
		kwin-addons

		# Appearance (themes, visuals)
		plasma-theme-oxygen
		breeze-gtk-theme
		plymouth-theme-breeze
		plymouth-theme-kubuntu-logo
		plymouth-theme-kubuntu-text

		plasma-wallpapers-addons
		#plasma-workspace-wallpapers (185M)

		#add this only after it's updated to qt6
		#plasma-wallpaper-dynamic

		kdegraphics-thumbnailers
		ffmpegthumbs #video thumbnail generator for KDE file managers
		ffmpegthumbnailer
		kimageformat6-plugins

		#capturing desktop screenshots
		kde-spectacle

		#for CHM help files
		#kchmviewer qt5 🤔 apt rdepends --installed libqt5core5t64
	)

	kde_kio_modules=(
		# === Ubuntu-Available KIO Modules ===
		kio-admin       # Root/administrator access (PolicyKit integration)
		kio-audiocd     # Access audio CDs
		kio-extras      # Adds common protocols (ftp, smb, tar, man, etc.)
		kio-extras-data # Data for kio-extras
		kio-fuse        # Mount KIO paths as FUSE filesystems
		kio-gdrive      # Google Drive integration
		#kio-gopher      # Gopher protocol (yes, still exists!) #qt5 🤔 apt rdepends --installed libqt5core5t64
		kio-ldap    # LDAP directory browsing
		kio-perldoc # Perl documentation integration
	)

	bluetooth_libs=(
		bluez
		bluez-obexd
		bluedevil
		bluetooth
		bluez-tools
	)

	essential_kde_utilities=(
		dolphin-plugins
		kmenuedit
		ksshaskpass
		kwalletmanager
		libpam-kwallet5
		ksystemlog
		khelpcenter
		kdf
		kate
		kgpg
		kpartx
		partitionmanager
		plasma-browser-integration
		plasma-discover-notifier
		plasma-disks
		kcalc
		kcharselect
		kamera
		#digikam
		krecorder
		print-manager
	)

	kde_pim=(
		#kdepim-runtime
		#Merkuro Suite:
		merkuro kmail kleopatra accountwizard
		#qml6-module-org-kde-kirigamiaddons-settings
		#qml6-module-qtlocation
	)

	# kaccounts-providers nextcloud-desktop owncloud-client telepathy-mission-control-5
	#kdenetwork-filesharing

	all_packages=(
		"${base_desktop[@]}"
		"${kde_kio_modules[@]}"
		"${bluetooth_libs[@]}"
		"${essential_kde_utilities[@]}"
	)

	install_apps "${all_packages[@]}"

	sudo snap install icon-theme-breeze
	#sudo snap install kde-frameworks-5-99-qt-5-15-7-core20

	echo ""
	echo "🚀 Applying first-boot Plasma theme settings..."
	kde_firstboot
	echo "✨ First-boot configuration complete."
	echo ""

	mkdir -p "$HOME/.gnupg"
	chmod 700 "$HOME/.gnupg"
	touch "$HOME/.gnupg/gpg.conf"
	chmod 600 "$HOME/.gnupg/gpg.conf"

	#add "always on top" (F) to window toolbar
	kwriteconfig6 --file kwinrc --group org.kde.kdecoration2 --key ButtonsOnRight "FIAX"

	cat <<EOF >"$HOME/.xinputrc"
# set by setup script
run_im none
EOF

	mkdir -p "$HOME/.config/gtk-3.0"
	cat >"$HOME/.config/gtk-3.0/settings.ini" <<EOF
[Settings]
gtk-application-prefer-dark-theme=true
gtk-icon-theme-name=breeze-dark
EOF

}

install_sddm() {

	sddm=(
		sddm
		sddm-theme-breeze
		xserver-xorg-input-libinput
		## Mostly used by LXQt / XFCE users; KDE already provides its own SDDM settings.
		#sddm-conf
	)

	#To force SDDM → Wayland
	#sudo mkdir -p /etc/sddm.conf.d
	#echo -e "[General]\nDisplayServer=wayland" | sudo tee /etc/sddm.conf.d/10-wayland.conf

	echo ""
	read -p "⌨️  Install touchscreen virtual keyboard support? [y/N]: " INSTALL_VK
	if [[ "$INSTALL_VK" =~ ^[Yy]$ ]]; then
		echo "✔ Adding virtual keyboard support..."
		sddm_pkgs+=("qt6-virtualkeyboard-plugin")
	else
		echo "⏭️  Skipping virtual keyboard."
	fi
	echo ""
	echo "🚀 Installing SDDM..."
	echo ""
	#old pre-libinput event driver
	#xserver-xorg-input-evdev
	#old touchpad driver (deprecated)
	#xserver-xorg-input-synaptics
	#pre-USB PS/2 mouse fallback
	#xserver-xorg-input-mouse
	#old XKB keyboard fallback
	#xserver-xorg-input-keyboard
	#meta-package that installs everything
	#xserver-xorg-input-all

	install_apps "${sddm[@]}"

	sudo mkdir -p /etc/sddm.conf.d

	sudo tee /etc/sddm.conf.d/numlock.conf >/dev/null <<EOF
[General]
Numlock=on
EOF

}

kde_settings() {

	################################
	# Configure Plasma/Dolphin/KDE #
	################################

	#https://github.com/shalva97/kde-configuration-files

	echo "Configuring Plasma/Dolphin/KDE..."

	# Single-click opens items
	kwriteconfig6 --file kdeglobals --group "KDE" --key "SingleClick" true

	# NumLock=0 (0=On, 1=Off, 2=Leave unchanged)
	kwriteconfig6 --file kcminputrc --group Keyboard --key NumLock 0

	#Virtual Keyboard
	kwriteconfig6 --file kcmkeyboardrc --group Keyboard --key VirtualKeyboard IBusWayland

	# Dolphin startup location and behavior
	kwriteconfig6 --file dolphinrc --group "General" --key "HomeUrl" "file:///$HOME"
	kwriteconfig6 --file dolphinrc --group "General" --key "RememberOpenedTabs" false
	kwriteconfig6 --file dolphinrc --group "General" --key "ShowHomeUrlOnStartup" true

	# Screen locking behavior
	#kwriteconfig6 --file kscreenlockerrc --group Daemon --key Autolock true
	#kwriteconfig6 --file kscreenlockerrc --group Daemon --key Timeout 5  # minutes
	kwriteconfig6 --file kscreenlockerrc --group Daemon --key Autolock false
	kwriteconfig6 --file kscreenlockerrc --group Daemon --key Timeout 0 # minutes

	# Power Management: AC profile configuration
	kwriteconfig6 --file powerdevilrc --group "AC" --group "Display" --key UseProfileSpecificDisplayBrightness true
	kwriteconfig6 --file powerdevilrc --group "AC" --group "Display" --key DisplayBrightness 45
	kwriteconfig6 --file powerdevilrc --group "AC" --group "Display" --key DimDisplayIdleTimeoutSec 300
	kwriteconfig6 --file powerdevilrc --group "AC" --group "Display" --key DimDisplayWhenIdle true
	# kwriteconfig6 --file powerdevilrc --group "AC" --group "Display" --key DimDisplayIdleTimeoutSec -1
	# kwriteconfig6 --file powerdevilrc --group "AC" --group "Display" --key DimDisplayWhenIdle false
	kwriteconfig6 --file powerdevilrc --group "AC" --group "Display" --key TurnOffDisplayIdleTimeoutSec 600
	kwriteconfig6 --file powerdevilrc --group "AC" --group "Display" --key TurnOffDisplayWhenIdle true
	kwriteconfig6 --file powerdevilrc --group "AC" --group "Display" --key TurnOffDisplayIdleTimeoutWhenLockedSec 0

	kwriteconfig6 --file powerdevilrc --group "AC" --group "SuspendAndShutdown" --key AutoSuspendAction 0
	kwriteconfig6 --file powerdevilrc --group "AC" --group "SuspendAndShutdown" --key AutoSuspendIdleTimeoutSec 60
	kwriteconfig6 --file powerdevilrc --group "AC" --group "SuspendAndShutdown" --key PowerButtonAction 0
	kwriteconfig6 --file powerdevilrc --group "AC" --group "SuspendAndShutdown" --key LidAction 0

	qdbus6 org.kde.Solid.PowerManagement /org/kde/Solid/PowerManagement refreshStatus 2>/dev/null || true

	echo "✔ Finished adding settings."

}

kde_firstboot() {

	mkdir -p "$HOME/.config/autostart"
	cat <<EOF >"$HOME/.config/autostart/plasma-firstboot.desktop"
[Desktop Entry]
Type=Application
Exec=/usr/local/bin/plasma-firstboot.sh
Hidden=false
NoDisplay=true
X-GNOME-Autostart-enabled=true
Name=Plasma First Boot Config
EOF

	sudo tee /usr/local/bin/plasma-firstboot.sh >/dev/null <<'EOF'
#!/bin/bash

# --- APPLY FIRST-BOOT SETTINGS ---
# Global Breeze Dark theme
lookandfeeltool -a org.kde.breezedark.desktop

# Single-click
kwriteconfig6 --file kdeglobals --group "KDE" --key "SingleClick" true

# Add any additional first-run Plasma tweaks here…
# Example:
# kwriteconfig6 --file kdeglobals --group "General" --key "ColorScheme" "BreezeDark"

# --- CLEANUP ---
# Remove autostart entry so this only runs once
rm -f $HOME/.config/autostart/plasma-firstboot.desktop

# Remove this script if you prefer to keep the system clean
# Comment this line out if you want to re-run or debug later:
rm -f /usr/local/bin/plasma-firstboot.sh

EOF

	sudo chmod +x /usr/local/bin/plasma-firstboot.sh

}

# Function to reboot system
reboot_system() {
	read -p "The system will need to reboot to complete the installation/removal of Kubuntu desktop. Reboot now? [y/N]: " REBOOT
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
	sudo apt update --allow-releaseinfo-change

	echo "📦 Upgrading installed APT packages..."
	sudo apt upgrade --fix-missing -y || {
		echo "⚠️ First attempt failed, retrying after 5 seconds..."
		sleep 5
		sudo apt upgrade --fix-missing -y || {
			echo "❌ Still failing. Mirrors may be broken. Exiting."
			return 1
		}
	}

	echo "🔁 Performing full APT distribution upgrade..."
	sudo apt full-upgrade -y

	echo "🧹 Autoremoving orphaned packages..."
	sudo apt autoremove -y

	echo "🧽 Cleaning APT package cache..."
	sudo apt clean

	if command -v snap &>/dev/null; then
		echo "📦 Updating Snap packages..."
		sudo snap refresh
	fi

	if command -v flatpak &>/dev/null; then
		echo "📦 Updating Flatpak packages..."
		sudo flatpak update -y
	fi

	if command -v brew &>/dev/null; then
		echo "📦 Updating Brew packages..."
		brew update && brew upgrade && brew cleanup
	fi

	echo ""
	echo "✅ System update complete."
	echo ""
}

update_system() {

	read -p "Check for system upgrade now? [y/N]: " UPGRADE
	if [[ "$UPGRADE" =~ ^[Yy]$ ]]; then
		#( sudo do-release-upgrade )
		echo "The upgrade process may reboot or exit this script."
		echo "Continue? [y/N]"
		read -r ans
		[[ "$ans" =~ ^[Yy]$ ]] && exec sudo do-release-upgrade
	else
		echo "Skipping system update."
	fi

}

install_apps() {
	local packages=("$@")
	echo "Installing: ${packages[*]}"
	sudo apt install --no-install-recommends "${packages[@]}"
}

install_apt_apps() {

	local options="${1:-}"

	echo "Installing applications..."

	# Update and upgrade apt packages
	# update_upgrade

	### 🐧 System Utilities
	system_utils=(
		unzip dos2unix fwupd geany gparted gpart
		htop mtools lm-sensors
		#rpi-imager #qt5 🤔 apt rdepends --installed libqt5core5t64
		pv tree ripgrep fzf #jq file
		smartmontools usbutils usb-modeswitch
		sleuthkit #autopsy  mac-robber
		gtkhash
		libfuse2
	)

	### 🗜️ Compression Tools
	compression_pkgs=(
		zip
		unzip
		7zip
		7zip-rar
		bzip2
		xz-utils
		rpm2cpio
	)

	### 💾 File System & Disk Tools
	fs_disk_tools=(
		exfatprogs jfsutils reiserfsprogs xfsprogs udftools libparted-dev
	)

	### 🔐 Security & Auth
	security_tools=(
		opensc pcscd pcsc-tools fido2-tools yubikey-manager yubico-piv-tool libpam-pkcs11 xca wireguard
	)

	#sudo apt install pcsc-tools pcscd libccid
	#sudo systemctl enable --now pcscd

	### 🖥️ Multimedia / GUI / OBS
	media_apps=(
		obs-studio
		obs-plugins
		audacity
		mpv
		mplayer mplayer-gui mencoder
		#vlc #qt5 🤔 apt rdepends --installed libqt5core5t64
		#smplayer #qt5 🤔

		ffmpeg
		imagemagick
		yt-dlp
		dvd+rw-tools

		#Command-line PulseAudio utilities (PipeWire implements PulseAudio compatibility)
		pulseaudio-utils
		libpulsedsp #DSP plugin library for PulseAudio. (🤔?)
	)

	#########################################################
	#mplayer-skin-blue breaks mplayer-skins install
	sudo tee /etc/apt/preferences.d/blacklist-mplayer-skin-blue >/dev/null <<EOF
Package: mplayer-skin-blue
Pin: release *
Pin-Priority: -1
EOF
	media_apps+=("mplayer-skins")
	#########################################################

	### 📱 Mobile / Flash / Embedded
	embedded_tools=(
		adb binwalk esptool mtd-utils
	)

	### 🌍 Web & Remote Tools
	remote_tools=(
		curl git wget tigervnc-viewer
	)

	cli_apps=(
		elinks iptraf twin irssi
	)

	### 🌐 Network Utilities
	network_tools=(
		arp-scan
		net-tools
		traceroute
		bind9-dnsutils
		netcat-openbsd
		whois
		# iperf3: on-demand network throughput testing (do not enable systemd service by default)
		# lksctp-tools: SCTP protocol tools (telecom/niche) – intentionally not installed
	)

	### 🛰️ Nmap & Companion Tools
	nmap_tools=(
		nmap
		ncat
		ndiff
		zenmap
	)

	### 🐍 Python Packages ###
	python_pkgs=(
		python-is-python3
		python3-venv
		python3-pip
		python3-setuptools
		python3-wheel
		pipx
		python3-pil # pillow image compression
		#python3-bs4
		#python3-html5lib
		#python3-pyqtgraph #qt5 🤔 #pip install pyqtgraph PyQt6 or PySide6
	)

	### 🛠 Miscellaneous / Special Purpose
	misc_tools=(
		#synaptic
		#dotnet-sdk-9.0
		libchm-bin #for CHM help files

		aha #Ansi Hilight to HTML.

		clinfo              #Shows OpenCL platform/device info.
		edid-decode         #Decodes EDID info from monitors
		libdisplay-info-bin #Tools for parsing/displaying monitor/video capability

		#Classic Mesa/GPU OpenGL helper tools:
		mesa-utils mesa-utils-bin
		mesa-va-drivers
		#radeontop nvidia-utils-580 intel-gpu-tools

		vulkan-tools wayland-utils

		mc
		sqlite3
		exif
		sox
		#rpm
		#wimtools

	)

	all_packages=(
		"${system_utils[@]}"
		"${fs_disk_tools[@]}"
		"${compression_pkgs[@]}"
		"${security_tools[@]}"
		"${media_apps[@]}"
		"${embedded_tools[@]}"
		"${remote_tools[@]}"
		"${cli_apps[@]}"
		"${network_tools[@]}"
		"${nmap_tools[@]}"
		"${python_pkgs[@]}"
		"${misc_tools[@]}"
	)

	install_apps "${all_packages[@]}"

	echo ""
	echo "[pipx] Running: ensurepath"
	echo ""

	pipx ensurepath
	rc=$?

	echo ""
	echo "[pipx] Result: exit code $rc"
	echo ""

	firefox_policy_install_addons

	#pipx install piper-tts --include-deps
}

install_audio_studio() {

	### 🖥️ Audio / Video / Music
	audio_apps=(

		pavucontrol   # simple volume/mixer UI for Pulse/PipeWire
		qpwgraph      # PipeWire/JACK patchbay (no need for helvum)
		pipewire-jack # JACK compatibility layer on PipeWire
		#easyeffects   # system-wide PipeWire FX/EQ for in/out audio

		meterbridge       # JACK peak/VU/PPM meters
		fmit              # instrument tuner
		kmetronome        # KDE/Qt metronome
		hydrogen          # drum machine + pattern sequencer
		hydrogen-drumkits # (~166 MB)
		rubberband-cli

		jack-keyboard # JACK virtual MIDI keyboard
		vmpk          # virtual MIDI piano keyboard (Qt)
		vkeybd        # lightweight X11 virtual MIDI keyboard

		qsynth             # GUI front-end for Fluidsynth (software synth)
		fluid-soundfont-gm # General MIDI soundfont (~130 MB)
		fluid-soundfont-gs # Roland GS-style soundfont
		qtractor           # MIDI+audio multitrack sequencer/DAW
		#musescore3         # notation/score editor (MuseScore Studio 3; 4.x via AppImage/Snap)

		rakarrack    # real-time guitar effects rack
		calf-plugins # LV2/LADSPA suite (EQ, comp, synths, etc.)
		lsp-plugins  # pro-grade LV2/LADSPA/CLAP/VST plugin bundle
		x42-plugins  # meters/utility + audio/video-friendly plugins
		zam-plugins  # ZamAudio LV2/LADSPA FX (compressors, EQ, etc.) (~40 MB)
		mda-lv2      # classic LV2 plugin pack (bread-and-butter FX)
		carla        # modular plugin host for LV2/VST/etc.

		ardour                # full DAW (multitrack audio/MIDI)
		ardour-video-timeline # video timeline integration for Ardour

		xjadeo # non-linear video editor (open source)

		##################
		# future thoughts
		# carla-control   # optional remote GUI for Carla
		# kdenlive        # non-linear video editor
		# lmms            # pattern/loop-based DAW
		# minuet          # KDE ear-training (intervals, chords, scales…)
		# MuseScore 4+    # handle via AppImage/Snap as “MuseScore Studio”
	)

	#systemctl --user --now enable pipewire pipewire-pulse wireplumber.service
	#systemctl --user restart pipewire pipewire-pulse wireplumber.service

	install_apps "${audio_apps[@]}"

	systemctl --user restart pipewire

	msg_start "Adding 'Multimedia (LSP)' category to plasma menu."
	desktop_menu_category
	msg_start "Setting JACK apps to use PipeWire's pw-jack shim instead of expecting a real jackd daemon."
	echo ""
	jackify_dir_desktops /usr/share/applications
	echo ""
	jackify_dir_desktops "$HOME/.local/share/applications"
	echo ""

}

all_applications=(
	meterbridge
	net.sourceforge.kmetronome.desktop
	jack-keyboard
	vkeybd
	org.rncbc.qsynth
	org.rncbc.qtractor
	rakarrack
	calf
	in.lsp_plug.lsp_plugins_*
	carla
	ardour
	xjadeo
)

jackify_dir_desktops() {
	local dir="$1"

	# optional: ignore non-matching globs instead of keeping literals
	shopt -s nullglob
	for app in "${all_applications[@]}"; do
		for f in "$dir"/$app.desktop; do
			[[ -f "$f" ]] || continue
			jackify_desktop_exec "$f"
		done
	done
	shopt -u nullglob
}

# ------------------------------------------------------------
# Prefix a .desktop Exec= line with pw-jack
# Usage: jackify_desktop_exec /usr/share/applications/xjadeo.desktop
# Result: Exec=/usr/bin/xjadeo
#      -> Exec=pw-jack /usr/bin/xjadeo
# ------------------------------------------------------------
jackify_desktop_exec() {
	local file="$1"

	if [[ -z "$file" ]]; then
		echo "jackify_desktop_exec: no file specified" >&2
		return 1
	fi

	if [[ ! -f "$file" ]]; then
		echo "jackify_desktop_exec: file not found: $file" >&2
		return 1
	fi

	# Show what we're about to touch (for sanity)
	# echo "Jackifying Exec= in: $file"
	echo -en "${YELLOW}.${RESET}"

	# This makes the change idempotent:
	# - If Exec=/usr/bin/xjadeo        -> Exec=pw-jack /usr/bin/xjadeo
	# - If Exec=pw-jack /usr/bin/xjadeo -> stays Exec=pw-jack /usr/bin/xjadeo
	sudo sed -i -E 's|^Exec=(pw-jack[[:space:]]+)?(.+)$|Exec=pw-jack \2|' "$file"
}

desktop_menu_category() {

	# Desktop entry
	sudo mkdir -p /usr/share/extra-xdg-menus
	sudo tee /usr/share/extra-xdg-menus/lsp-plugins.menu >/dev/null <<'EOF'
<!DOCTYPE Menu PUBLIC "-//freedesktop//DTD Menu 1.0//EN"
 "http://www.freedesktop.org/standards/menu-spec/1.0/menu.dtd">
<Menu>
  <Name>Applications</Name>
  <Menu>
    <Name>MM Plugins</Name>
    <Directory>lsp-plugins.directory</Directory>
    <Include>
        <Category>X-LSP-Plugins</Category>
    </Include>
  </Menu> <!-- End -->
</Menu>
EOF
	# menu entry name
	sudo mkdir -p /usr/share/desktop-directories
	sudo tee /usr/share/desktop-directories/lsp-plugins.directory >/dev/null <<'EOF'
[Desktop Entry]
Type=Directory
Name=Multimedia (LSP)
Icon=applications-multimedia
EOF

	#this symlink needs remade for the system to see changes (when testing)
	sudo rm /etc/xdg/menus/applications-merged/lsp-plugins.menu
	sudo ln -s /usr/share/extra-xdg-menus/lsp-plugins.menu /etc/xdg/menus/applications-merged/lsp-plugins.menu

}

install_snap_apps_old() {

	local options="${1:-}"

	# Install snap packages from snap_list.txt
	echo "Installing snap packages..."
	if [ -f "$SCRIPT_DIR/snap_list.txt" ]; then
		while IFS= read -r package; do
			echo "Installing $package..."
			sudo snap install "$package"
		done <"$SCRIPT_DIR/snap_list.txt"
	else
		echo "snap_list.txt not found in $SCRIPT_DIR."
	fi

}

install_snap_apps() {

	sudo snap install btop
	#sudo snap install musikcube
	#sudo snap install ncspot
}

install_graphics() {

	echo "Installing snap graphics packages..."

	sudo snap install blender --classic
	sudo snap install gimp
	sudo snap install inkscape
	sudo snap install upscayl
}

install_etcher_portable() {

	# Install dependencies
	sudo apt install -y curl

	echo "Installing Balena Etcher (portable)..."

	local base_dir="$HOME/.local/share/balena-etcher"
	local downloadFile="balenaEtcher-linux-x64-2.1.4"
	local archive="${downloadFile}.zip"

	mkdir -p "$base_dir"
	cd "$base_dir" || {
		echo "Failed to enter $base_dir"
		return 1
	}

	# Download if missing
	if [[ ! -f "$archive" ]]; then
		echo "Downloading $archive..."
		curl -L -o "$archive" \
			"https://github.com/balena-io/etcher/releases/download/v2.1.4/${archive}"
	fi

	# Unpack
	unzip -oq "$archive"
	mv -f "$base_dir/balenaEtcher-linux-x64" "$base_dir/$downloadFile"
	cd "$base_dir/$downloadFile" || {
		echo "Unzip failed."
		return 1
	}

	# Get Icon
	wget -O balenaEtcher.png https://raw.githubusercontent.com/balena-io/etcher/master/assets/icon.png
	sudo mv balenaEtcher.png /usr/share/pixmaps/

	# Fix sandbox permissions
	chmod +x balena-etcher
	sudo chown root:root chrome-sandbox
	sudo chmod 4755 chrome-sandbox

	# Create/refresh system-wide link
	sudo ln -sf "$base_dir/$downloadFile/balena-etcher" /usr/local/bin/balena-etcher

	# Desktop entry
	mkdir -p "$HOME/.local/share/applications"
	cat <<EOF >"$HOME/.local/share/applications/balena-etcher.desktop"
[Desktop Entry]
Type=Application
Name=Balena Etcher
Exec=/usr/local/bin/balena-etcher
Icon=balenaEtcher.png
Categories=Utility;
EOF

	#clean up zip
	#rm "$archive"

	echo "✅ Etcher installed. Run with: balena-etcher"
}

install_ledger_live() {

	# ---- Config ----
	local ver="2.133.0"
	local app="ledger-live-desktop-${ver}-linux-x86_64"
	local archive="${app}.AppImage"
	local url="https://download.live.ledger.com/${archive}"

	local base_dir="$HOME/.local/share/ledger-live"
	local install_dir="$base_dir/$app"
	local cache_dir="$base_dir/_cache"
	local cache_appimage="$cache_dir/$archive"

	echo "Installing Ledger Live ${ver}..."

	# ---- Deps ----
	# We avoid FUSE by using --appimage-extract, so no libfuse2 needed here.
	sudo apt-get update -y >/dev/null
	sudo apt-get install -y curl ca-certificates coreutils findutils >/dev/null

	mkdir -p "$base_dir" "$cache_dir"

	# ---- Download (if missing) ----
	if [[ ! -f "$cache_appimage" ]]; then
		echo "Downloading: $url"
		curl -L --fail -o "$cache_appimage" "$url"
	else
		echo "Using cached: $cache_appimage"
	fi

	chmod +x "$cache_appimage"

	# ---- Extract (idempotent) ----
	if [[ -d "$install_dir" ]]; then
		echo "Already extracted: $install_dir"
	else
		echo "Extracting AppImage..."
		(
			cd "$base_dir"
			# Extracts to ./squashfs-root
			"$cache_appimage" --appimage-extract >/dev/null
			mv -f "$base_dir/squashfs-root" "$install_dir"
		)
	fi

	# ---- Fix chrome-sandbox (Electron) ----
	# Find it wherever Ledger placed it.
	local sandbox_path=""
	sandbox_path="$(find "$install_dir" -type f -name 'chrome-sandbox' -print -quit || true)"
	if [[ -n "$sandbox_path" ]]; then
		echo "Fixing chrome-sandbox: $sandbox_path"
		# Must be owned by root and setuid for the sandbox to work
		sudo chown root:root "$sandbox_path"
		sudo chmod 4755 "$sandbox_path"
	else
		echo "Note: chrome-sandbox not found (may not be required in this build)."
	fi

	# ---- Install icon (auto-discover) ----
	# Prefer largest hicolor icon if present.
	local icon_src=""
	icon_src="$(find "$install_dir" \
		-type f \( -path '*/usr/share/icons/hicolor/*/apps/*.png' -o -path '*/usr/share/pixmaps/*.png' \) \
		-print 2>/dev/null | head -n 1 || true)"

	# Put a stable user-level icon name: ledger-live.png
	local icon_dir="$HOME/.local/share/icons/hicolor/512x512/apps"
	local icon_dst="$icon_dir/ledger-live.png"

	if [[ -n "$icon_src" ]]; then
		mkdir -p "$icon_dir"
		cp -f "$icon_src" "$icon_dst"
		echo "Icon installed: $icon_dst"
	else
		echo "Note: Could not auto-find an icon inside AppImage."
	fi

	# ---- Create launcher in /usr/local/bin ----
	# The extracted root should have AppRun; use it as the stable entrypoint.
	if [[ ! -x "$install_dir/AppRun" ]]; then
		echo "ERROR: AppRun not found/executable at: $install_dir/AppRun"
		return 1
	fi

	sudo ln -sf "$install_dir/AppRun" /usr/local/bin/ledger-live

	# ---- Desktop entry ----
	mkdir -p "$HOME/.local/share/applications"
	cat >"$HOME/.local/share/applications/ledger-live.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=Ledger Live
Exec=/usr/local/bin/ledger-live %U
Icon=ledger-live
Categories=Finance;Utility;
Terminal=false
StartupNotify=true
EOF

	# Refresh desktop db (optional; harmless if absent)
	command -v update-desktop-database >/dev/null 2>&1 && update-desktop-database "$HOME/.local/share/applications" >/dev/null 2>&1 || true

	# 1) Install Ledger udev rules (official)
	wget -qO- https://raw.githubusercontent.com/LedgerHQ/udev-rules/master/add_udev_rules.sh | sudo bash

	# 1.5) Tighten up mode 666 to 660
	sudo tee /etc/udev/rules.d/99-ledger-local.rules >/dev/null <<'EOF'
SUBSYSTEM=="hidraw", ATTRS{idVendor}=="2c97", MODE="0660", GROUP="plugdev", TAG+="uaccess"
EOF

	# 2) Make sure you’re in plugdev (common target group for these rules)
	sudo usermod -aG plugdev "$USER"

	# 3) Reload rules, then unplug/replug the Ledger
	sudo udevadm control --reload-rules
	sudo udevadm trigger

	# unplug/replug (or reboot)

	echo "✅ Installed. Run: ledger-live"
}

install_discord() {

	# ---- Config ----
	local api_url="https://discord.com/api/download?platform=linux&format=tar.gz"

	local base_dir="$HOME/.local/share/discord"
	local cache_dir="$base_dir/_cache"

	local final_url=""
	local archive=""
	local version=""
	local app="discord"
	local cache_archive=""
	local install_dir=""
	local extracted_dir=""
	local launcher=""
	local sandbox_path=""
	local icon_src=""
	local icon_dir="$HOME/.local/share/icons/hicolor/512x512/apps"
	local icon_dst="$icon_dir/discord.png"

	echo "Installing Discord (latest Linux tar.gz)..."

	# ---- Deps ----
	#sudo apt-get update -y >/dev/null
	#sudo apt-get install -y curl ca-certificates coreutils findutils tar >/dev/null

	mkdir -p "$base_dir" "$cache_dir"

	# ---- Resolve current release URL/filename ----
	# We ask curl what URL it ended up at after redirects.
	final_url="$(curl -fsSL -o /dev/null -w '%{url_effective}' "$api_url")"

	if [[ -z "$final_url" || "$final_url" == "$api_url" ]]; then
		echo "ERROR: Could not resolve Discord download URL."
		return 1
	fi

	archive="$(basename "${final_url%%\?*}")"
	if [[ -z "$archive" || "$archive" != *.tar.gz ]]; then
		echo "ERROR: Resolved filename does not look like a Discord tar.gz: $archive"
		return 1
	fi

	version="$(sed -nE 's/^discord-([0-9][0-9.]+)\.tar\.gz$/\1/p' <<<"$archive")"
	if [[ -z "$version" ]]; then
		echo "ERROR: Could not parse Discord version from filename: $archive"
		return 1
	fi

	cache_archive="$cache_dir/$archive"
	install_dir="$base_dir/discord-$version"

	echo "Resolved Discord version: $version"
	echo "Resolved archive: $archive"

	# ---- Download (if missing) ----
	if [[ ! -f "$cache_archive" ]]; then
		echo "Downloading: $final_url"
		curl -L --fail -o "$cache_archive" "$final_url"
	else
		echo "Using cached: $cache_archive"
	fi

	# ---- Extract (idempotent per version) ----
	if [[ -d "$install_dir" ]]; then
		echo "Already extracted: $install_dir"
	else
		echo "Extracting Discord..."
		rm -rf "$base_dir/_extract-discord"
		mkdir -p "$base_dir/_extract-discord"

		tar -xzf "$cache_archive" -C "$base_dir/_extract-discord"

		extracted_dir="$(find "$base_dir/_extract-discord" -mindepth 1 -maxdepth 1 -type d -name 'Discord' -print -quit || true)"
		if [[ -z "$extracted_dir" ]]; then
			echo "ERROR: Extracted Discord directory not found."
			rm -rf "$base_dir/_extract-discord"
			return 1
		fi

		mv -f "$extracted_dir" "$install_dir"
		rm -rf "$base_dir/_extract-discord"
	fi

	# ---- Fix chrome-sandbox (Electron) ----
	sandbox_path="$(find "$install_dir" -type f -name 'chrome-sandbox' -print -quit || true)"
	if [[ -n "$sandbox_path" ]]; then
		echo "Fixing chrome-sandbox: $sandbox_path"
		sudo chown root:root "$sandbox_path"
		sudo chmod 4755 "$sandbox_path"
	else
		echo "Note: chrome-sandbox not found."
	fi

	# ---- Install icon ----
	icon_src="$(find "$install_dir" \
		-type f \( -iname 'discord.png' -o -path '*/share/icons/*/apps/discord.png' -o -path '*/share/pixmaps/*.png' \) \
		-print 2>/dev/null | head -n 1 || true)"

	if [[ -n "$icon_src" ]]; then
		mkdir -p "$icon_dir"
		cp -f "$icon_src" "$icon_dst"
		echo "Icon installed: $icon_dst"
	else
		echo "Note: Could not auto-find a Discord icon inside the tarball."
	fi

	# ---- Create launcher in /usr/local/bin ----
	launcher="$install_dir/Discord"
	if [[ ! -x "$launcher" ]]; then
		echo "ERROR: Discord launcher not found/executable at: $launcher"
		return 1
	fi

	sudo ln -sf "$launcher" /usr/local/bin/discord

	# ---- Desktop entry ----
	mkdir -p "$HOME/.local/share/applications"
	cat >"$HOME/.local/share/applications/discord.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=Discord
Exec=/usr/local/bin/discord --password-store=basic --enable-features=WebRTCPipeWireCapturer %U
Icon=discord
Categories=Network;InstantMessaging;Chat;
Terminal=false
StartupNotify=true
EOF

	command -v update-desktop-database >/dev/null 2>&1 &&
		update-desktop-database "$HOME/.local/share/applications" >/dev/null 2>&1 || true

	echo "✅ Installed Discord $version. Run: discord"
}

# Function to install .deb packages
install_deb_packages() {

	local options="${1:-}"

	DEB_URLS=$options

	#DEB_URLS=(
	#"https://download1.repetier.com/files/server/debian-amd64/Repetier-Server-1.4.16-Linux.deb"
	#"https://launchpad.net/veracrypt/trunk/1.26.14/+download/veracrypt-1.26.14-Ubuntu-24.04-amd64.deb"
	#)

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

app_install() {
	local appimage="$1"
	local target="$2"
	local workdir="squashfs-root"
	local icon_dir="/usr/share/pixmaps"
	local desktop_dir="$HOME/.local/share/applications"

	# sanity checks
	if [[ -z "$appimage" || ! -f "$appimage" ]]; then
		echo "Error: AppImage not found: $appimage"
		return 1
	fi

	mkdir -p "$icon_dir" "$desktop_dir"

	# Extract
	"$appimage" --appimage-extract >/dev/null 2>&1
	if [[ ! -d "$workdir" ]]; then
		echo "Error: extraction failed."
		return 1
	fi

	# Copy icons
	sudo find "$workdir" -maxdepth 1 \( -name "*.svg" -o -name "*.png" \) -exec cp {} "$icon_dir/" \;

	#find "$workdir" -maxdepth 1 -regextype posix-extended \
	#-regex ".*/.*\.(svg|png)$" \
	#-exec cp {} "$icon_dir/" \;

	# Copy desktop files
	desktop_file=$(basename "$workdir"/*.desktop)

	sed -i "s|^Exec=.*|Exec=$target|" "$workdir/$desktop_file"

	sudo find "$workdir" -maxdepth 1 -name "*.desktop" -exec cp {} "$desktop_dir/" \;

	# Clean up
	rm -rf "$workdir"

	echo "✓ Installed icons → $icon_dir"
	echo "✓ Installed desktop files → $desktop_dir"
}

# Function to install AppImages
install_appimages() {

	local options="${1:-}"

	APPIMAGE_URLS=$options

	#APPIMAGE_URLS=(
	#"https://github.com/SoftFever/OrcaSlicer/releases/download/v2.3.1/OrcaSlicer_Linux_AppImage_Ubuntu2404_V2.3.1.AppImage"
	#"https://github.com/OpenShot/openshot-qt/releases/download/v3.3.0/OpenShot-v3.3.0-x86_64.AppImage"
	#)

	#APP_NAMES=(
	#"OrcaSlicer"
	#"OpenShot Video Editor"
	#)

	DOWNLOAD_DIR="$HOME/Downloads"
	APPIMAGE_DIR="$HOME/AppImages"

	echo "Downloading AppImage packages..."

	# Create APPIMAGE_DIR if it doesn't exist
	if [ ! -d "$APPIMAGE_DIR" ]; then
		echo "Making App Image Directory"
		mkdir -p "$APPIMAGE_DIR"
	fi

	for index in "${!APPIMAGE_URLS[@]}"; do
		url="${APPIMAGE_URLS[$index]}"
		#app_name="${APP_NAMES[$index]}"
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

			##
			app_install "$filepath" "$target_path"

			##
			mv "$filepath" "$target_path"
			echo "Moved $filename to $APPIMAGE_DIR."
		fi

	done

	echo "AppImage packages installation complete."
}

install_cups() {

	echo "Installing CUPS..."
	sudo apt install -y cups cups-filters printer-driver-all
	sudo systemctl enable --now cups

	read -p "Do you want to support AirPrint or network discovery? [y/N]: " NETDIS
	if [[ "$NETDIS" =~ ^[Yy]$ ]]; then
		sudo apt install -y avahi-daemon
		sudo systemctl enable --now avahi-daemon
	else
		echo "Skipping network discovery setup."

	fi

	echo "Finished installation."

}

iptables_save() {

	if ! command -v netfilter-persistent &>/dev/null; then
		sudo DEBIAN_FRONTEND=noninteractive apt install --no-install-recommends -y iptables-persistent netfilter-persistent
	fi

	# Try the standard save; on failure, write rules directly and enable service
	if ! sudo netfilter-persistent save; then
		echo "netfilter-persistent save failed; writing rules directly..."
		sudo mkdir -p /etc/iptables
		sudo iptables-save | sudo tee /etc/iptables/rules.v4 >/dev/null
		sudo ip6tables-save | sudo tee /etc/iptables/rules.v6 >/dev/null
		sudo systemctl enable --now netfilter-persistent
	fi

	echo "✅ iptables and ip6tables saved."
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

	IFACE=$(ip route show default 2>/dev/null | awk '{print $5; exit}')
	[[ -n "$IFACE" ]] || {
		echo "No default interface found"
		return 1
	}

	# Ask user whether to expose it
	echo ""
	read -rp "Would you like to expose SSH (port 22) to the network on interface $IFACE? [y/N]: " reply
	case "$reply" in
	[yY] | [yY][eE][sS])
		echo "🔓 Opening port 22 on interface $IFACE..."

		sudo iptables -C INPUT -i "$IFACE" -p tcp --dport 22 -j ACCEPT 2>/dev/null ||
			sudo iptables -A INPUT -i "$IFACE" -p tcp --dport 22 -j ACCEPT

		sudo ip6tables -C INPUT -i "$IFACE" -p tcp --dport 22 -j ACCEPT 2>/dev/null ||
			sudo ip6tables -A INPUT -i "$IFACE" -p tcp --dport 22 -j ACCEPT

		echo "✅ SSH port exposed on "$IFACE"."

		iptables_save

		;;
	*)
		echo "❌ SSH exposure canceled."
		;;
	esac
	echo ""

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

	echo ""
	echo "Further configuration:"
	echo " - To edit SSH settings, run: sudo nano /etc/ssh/sshd_config"
	echo " - Then restart SSH with:   sudo systemctl restart ssh"
	echo ""
	echo "You can connect to this machine via SSH using one of these methods:"
	echo "    ssh <username>@${ipAddress}"
	echo "    ssh <username>@${hostnameInfo}"
	echo ""
}

setup_git_ssh_signing() {

	# ---- edit these (or export NAME/EMAIL before running) ----
	#: "${NAME:=""}"
	#: "${EMAIL:=""}"
	# ---------------------------------------------------------

	local NAME="${1:-}"
	local EMAIL="${2:-}"

	local SIGNING_KEY="$HOME/.ssh/id_ecdsa"
	local GITHUB_IDENTITY="$HOME/.ssh/id_ecdsa_auth"
	local ALLOWED_SIGNERS_DIR="$HOME/.config/git"
	local ALLOWED_SIGNERS_FILE="$ALLOWED_SIGNERS_DIR/allowed_signers"
	local SSHCONF="$HOME/.ssh/config"

	echo ""
	echo "Provide GITHUB account information for GIT config."
	[[ -z "$NAME" ]] && read -r -p "Enter account name: " NAME
	[[ -z "$EMAIL" ]] && read -r -p "Enter account email: " EMAIL
	echo ""

	# Required keys
	[[ -f "$SIGNING_KEY" ]] || {
		echo "Missing signing key: $SIGNING_KEY"
		return 1
	}
	[[ -f "$SIGNING_KEY.pub" ]] || {
		echo "Missing public key: $SIGNING_KEY.pub"
		return 1
	}
	[[ -f "$GITHUB_IDENTITY" ]] || {
		echo "Missing GitHub identity key: $GITHUB_IDENTITY"
		return 1
	}

	# SSH dir + config
	mkdir -p "$HOME/.ssh"
	chmod 700 "$HOME/.ssh"
	touch "$SSHCONF"
	chmod 600 "$SSHCONF" || true

	# Key perms (don’t die if a .pub is missing)
	chmod 600 "$SIGNING_KEY" "$GITHUB_IDENTITY" 2>/dev/null || true
	chmod 644 "$SIGNING_KEY.pub" "$GITHUB_IDENTITY.pub" 2>/dev/null || true

	# allowed_signers (for local verification of ssh-signed commits/tags)
	mkdir -p "$ALLOWED_SIGNERS_DIR"
	(
		umask 077
		awk -v email="$EMAIL" '{print email, $1, $2}' "$SIGNING_KEY.pub" >"$ALLOWED_SIGNERS_FILE"
	)

	# Git config (does NOT overwrite ~/.gitconfig)
	git config --global user.name "$NAME"
	git config --global user.email "$EMAIL"
	git config --global gpg.format ssh
	git config --global user.signingkey "$SIGNING_KEY"
	git config --global gpg.ssh.allowedSignersFile "$ALLOWED_SIGNERS_FILE"
	git config --global commit.gpgsign true
	git config --global tag.gpgsign true

	# Ensure github.com uses your preferred identity key
	if ! grep -qE '^[[:space:]]*Host[[:space:]]+github\.com([[:space:]]|$)' "$SSHCONF"; then
		cat >>"$SSHCONF" <<EOF

Host github.com
  HostName github.com
  User git
  IdentityFile $GITHUB_IDENTITY
  IdentitiesOnly yes
EOF
	fi

	echo ""
	echo "Testing GitHub SSH..."
	ssh -T git@github.com || true
	echo ""

	#git log --show-signature -1 || true
}

iptables_reset() {

	echo ">>> Flushing all iptables rules and allowing all traffic (IPv4 + IPv6)"

	# IPv4
	sudo iptables -F
	sudo iptables -X
	sudo iptables -t nat -F
	sudo iptables -t nat -X
	sudo iptables -t mangle -F
	sudo iptables -t mangle -X
	sudo iptables -t raw -F
	sudo iptables -t raw -X

	sudo iptables -P INPUT ACCEPT
	sudo iptables -P FORWARD ACCEPT
	sudo iptables -P OUTPUT ACCEPT

	# IPv6 (if enabled)
	sudo ip6tables -F
	sudo ip6tables -X
	sudo ip6tables -t nat -F 2>/dev/null || true
	sudo ip6tables -t nat -X 2>/dev/null || true
	sudo ip6tables -t mangle -F
	sudo ip6tables -t mangle -X
	sudo ip6tables -t raw -F
	sudo ip6tables -t raw -X

	sudo ip6tables -P INPUT ACCEPT
	sudo ip6tables -P FORWARD ACCEPT
	sudo ip6tables -P OUTPUT ACCEPT

	echo ">>> All rules cleared. Everything is now allowed."

	iptables_save

}

iptables_flush() {

	# Flush existing rules
	sudo iptables -F
	sudo iptables -X
	sudo iptables -t nat -F
	sudo iptables -t nat -X
	sudo iptables -t mangle -F
	sudo iptables -t mangle -X
	sudo iptables -t raw -F
	sudo iptables -t raw -X

	# Default policies: DROP inbound/forward, ALLOW outbound
	sudo iptables -P INPUT DROP
	sudo iptables -P FORWARD DROP
	sudo iptables -P OUTPUT ACCEPT

	#Drop invalids (cheap noise filter)
	sudo iptables -A INPUT -m conntrack --ctstate INVALID -j DROP

	# Allow loopback
	sudo iptables -A INPUT -i lo -j ACCEPT

	# Allow established/related traffic
	sudo iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

	###

	sudo ip6tables -F
	sudo ip6tables -X
	sudo ip6tables -t nat -F
	sudo ip6tables -t nat -X
	sudo ip6tables -t mangle -F
	sudo ip6tables -t mangle -X
	sudo ip6tables -t raw -F
	sudo ip6tables -t raw -X

	# Default policies: DROP inbound/forward, ALLOW outbound
	sudo ip6tables -P INPUT DROP
	sudo ip6tables -P FORWARD DROP
	sudo ip6tables -P OUTPUT ACCEPT

	#Drop invalids (cheap noise filter)
	sudo ip6tables -A INPUT -m conntrack --ctstate INVALID -j DROP

	# Allow loopback
	sudo ip6tables -A INPUT -i lo -j ACCEPT

	# Allow established/related traffic
	sudo ip6tables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

}

iptables_secure() {

	iptables_flush

	# --- adjust these if needed ---
	#WG_IF="firefly"
	#WG_PORT="50120"          # WireGuard UDP port
	IFACE=$(ip route show default 2>/dev/null | awk '{print $5; exit}')
	[[ -n "$IFACE" ]] || {
		echo "No default interface found"
		return 1
	}
	# ------------------------------

	# --- OpenSSH detection & optional exposure ---

	# Check if openssh-server is installed
	if dpkg -l | awk '$2 == "openssh-server" && $1 == "ii" {found=1} END {exit !found}'; then
		echo "✅ OpenSSH Server detected on this system."

		# Ask user whether to expose it
		read -rp "Would you like to expose SSH (port 22) to the network on interface $IFACE? [y/N]: " reply_ssh
		case "$reply_ssh" in
		[yY] | [yY][eE][sS])
			iptables_ssh
			;;
		*)
			echo "❌ SSH exposure canceled."
			;;
		esac
	fi
	#else
	#echo "⚠️  OpenSSH Server not detected. Install with: sudo apt install openssh-server"
	#fi

	# Ask user whether to expose mDNS
	read -rp "Enable mDNS (port 5353) to the network on interface $IFACE? [y/N]: " reply_mDNS
	case "$reply_mDNS" in
	[yY] | [yY][eE][sS])
		iptables_mdns
		;;
	*)
		echo "❌ mDNS exposure canceled."
		;;
	esac

	############
	#   PING   #
	############

	# Ask user whether to expose
	read -rp "Enable ping to this machine from the network on interface $IFACE? [y/N]: " reply_ping
	case "$reply_ping" in
	[yY] | [yY][eE][sS])
		iptables_ping
		;;
	*)
		echo "❌ ping exposure canceled."
		;;
	esac

	############
	#   KDE    #
	############

	# Ask user whether to expose
	read -rp "Enable access to this machine with KDE Connect on interface $IFACE? [y/N]: " reply_kde
	case "$reply_kde" in
	[yY] | [yY][eE][sS])
		iptables_kde_connect
		;;
	*)
		echo "❌ kde connect exposure canceled."
		;;
	esac

	############
	#   VNC    #
	############

	# Ask user whether to expose
	read -rp "Enable access to this machine with VNC on interface $IFACE? [y/N]: " reply_vnc
	case "$reply_vnc" in
	[yY] | [yY][eE][sS])
		iptables_vnc
		;;
	*)
		echo "❌ vnc exposure canceled."
		;;
	esac

	############
	#   RDP    #
	############

	# Ask user whether to expose
	read -rp "Enable access to this machine with RPD (Remote Desktop Protocol) on interface $IFACE? [y/N]: " reply_rdp
	case "$reply_rdp" in
	[yY] | [yY][eE][sS])
		iptables_rdp
		;;
	*)
		echo "❌ rdp exposure canceled."
		;;
	esac

	iptables_save

}

iptables_ssh() {

	IFACE=$(ip route show default 2>/dev/null | awk '{print $5; exit}')
	[[ -n "$IFACE" ]] || {
		echo "No default interface found"
		return 1
	}

	echo "🔓 Opening port 22 on interface $IFACE..."

	sudo iptables -C INPUT -i "$IFACE" -p tcp --dport 22 -j ACCEPT 2>/dev/null ||
		sudo iptables -A INPUT -i "$IFACE" -p tcp --dport 22 -j ACCEPT

	sudo ip6tables -C INPUT -i "$IFACE" -p tcp --dport 22 -j ACCEPT 2>/dev/null ||
		sudo ip6tables -A INPUT -i "$IFACE" -p tcp --dport 22 -j ACCEPT

	echo "✅ SSH port exposed on "$IFACE"."

}

iptables_mdns() {

	IFACE=$(ip route show default 2>/dev/null | awk '{print $5; exit}')
	[[ -n "$IFACE" ]] || {
		echo "No default interface found"
		return 1
	}

	echo "🔓 Opening port 5353 on interface $IFACE..."

	sudo iptables -C INPUT -i "$IFACE" -p udp --dport 5353 -j ACCEPT 2>/dev/null ||
		sudo iptables -A INPUT -i "$IFACE" -p udp --dport 5353 -j ACCEPT

	sudo ip6tables -C INPUT -i "$IFACE" -p udp --dport 5353 -j ACCEPT 2>/dev/null ||
		sudo ip6tables -A INPUT -i "$IFACE" -p udp --dport 5353 -j ACCEPT

	echo "✅ mDNS port exposed on "$IFACE"."

}

iptables_ping() {

	IFACE=$(ip route show default 2>/dev/null | awk '{print $5; exit}')
	[[ -n "$IFACE" ]] || {
		echo "No default interface found"
		return 1
	}

	echo "🔓 Opening ping on interface $IFACE..."

	# limit to 10 pings/sec burst 20
	# iptables -R INPUT $(sudo iptables -L INPUT --line-numbers | awk '/icmp/ {print $1; exit}') -p icmp --icmp-type echo-request -m limit --limit 10/second --limit-burst 20 -j ACCEPT
	# ip6tables -R INPUT $(sudo ip6tables -L INPUT --line-numbers | awk '/ipv6-icmp/ {print $1; exit}') -p ipv6-icmp --icmpv6-type echo-request -m limit --limit 10/second --limit-burst 20 -j ACCEPT

	# OR: only allow ping on the WG iface and remove the global one

	sudo iptables -C INPUT -i "$IFACE" -p icmp --icmp-type echo-request -j ACCEPT 2>/dev/null ||
		sudo iptables -A INPUT -i "$IFACE" -p icmp --icmp-type echo-request -j ACCEPT

	sudo ip6tables -C INPUT -i "$IFACE" -p ipv6-icmp --icmpv6-type echo-request -j ACCEPT 2>/dev/null ||
		sudo ip6tables -A INPUT -i "$IFACE" -p ipv6-icmp --icmpv6-type echo-request -j ACCEPT

	# iptables -D INPUT <line-number-of-global-icmp-rule>
	# ip6tables -D INPUT <line-number-of-global-icmp-rule>

	echo "✅ ping exposed on "$IFACE"."

}

iptables_kde_connect() {

	local PORT_RANGE="1714:1764"

	IFACE=$(ip route show default 2>/dev/null | awk '{print $5; exit}')
	[[ -n "$IFACE" ]] || {
		echo "No default interface found"
		return 1
	}

	echo "🔓 Opening ports 1714:1764 tcp/udp on interface $IFACE..."

	# IPv4 rules
	sudo iptables -C INPUT -i "$IFACE" -p tcp --dport "$PORT_RANGE" -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT 2>/dev/null ||
		sudo iptables -A INPUT -i "$IFACE" -p tcp --dport "$PORT_RANGE" -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT
	sudo iptables -C INPUT -i "$IFACE" -p udp --dport "$PORT_RANGE" -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT 2>/dev/null ||
		sudo iptables -A INPUT -i "$IFACE" -p udp --dport "$PORT_RANGE" -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT

	sudo iptables -C OUTPUT -o "$IFACE" -p tcp --dport "$PORT_RANGE" -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT 2>/dev/null ||
		sudo iptables -A OUTPUT -o "$IFACE" -p tcp --dport "$PORT_RANGE" -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT
	sudo iptables -C OUTPUT -o "$IFACE" -p udp --dport "$PORT_RANGE" -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT 2>/dev/null ||
		sudo iptables -A OUTPUT -o "$IFACE" -p udp --dport "$PORT_RANGE" -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT

	sudo ip6tables -C INPUT -i "$IFACE" -p tcp --dport "$PORT_RANGE" -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT 2>/dev/null ||
		sudo ip6tables -A INPUT -i "$IFACE" -p tcp --dport "$PORT_RANGE" -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT
	sudo ip6tables -C INPUT -i "$IFACE" -p udp --dport "$PORT_RANGE" -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT 2>/dev/null ||
		sudo ip6tables -A INPUT -i "$IFACE" -p udp --dport "$PORT_RANGE" -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT

	sudo ip6tables -C OUTPUT -o "$IFACE" -p tcp --dport "$PORT_RANGE" -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT 2>/dev/null ||
		sudo ip6tables -A OUTPUT -o "$IFACE" -p tcp --dport "$PORT_RANGE" -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT
	sudo ip6tables -C OUTPUT -o "$IFACE" -p udp --dport "$PORT_RANGE" -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT 2>/dev/null ||
		sudo ip6tables -A OUTPUT -o "$IFACE" -p udp --dport "$PORT_RANGE" -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT

	echo "✅ KDE Connect ports exposed on "$IFACE"."

}

iptables_vnc() {

	IFACE=$(ip route show default 2>/dev/null | awk '{print $5; exit}')
	[[ -n "$IFACE" ]] || {
		echo "No default interface found"
		return 1
	}

	echo "🔓 Opening port 5900 tcp/udp on interface $IFACE..."

	sudo iptables -C INPUT -i "$IFACE" -p tcp --dport 5900 -j ACCEPT 2>/dev/null ||
		sudo iptables -A INPUT -i "$IFACE" -p tcp --dport 5900 -j ACCEPT

	sudo iptables -C INPUT -i "$IFACE" -p udp --dport 5900 -j ACCEPT 2>/dev/null ||
		sudo iptables -A INPUT -i "$IFACE" -p udp --dport 5900 -j ACCEPT

	sudo ip6tables -C INPUT -i "$IFACE" -p tcp --dport 5900 -j ACCEPT 2>/dev/null ||
		sudo ip6tables -A INPUT -i "$IFACE" -p tcp --dport 5900 -j ACCEPT

	sudo ip6tables -C INPUT -i "$IFACE" -p udp --dport 5900 -j ACCEPT 2>/dev/null ||
		sudo ip6tables -A INPUT -i "$IFACE" -p udp --dport 5900 -j ACCEPT

	echo "✅ VNC port exposed on "$IFACE"."

}

iptables_rdp() {

	IFACE=$(ip route show default 2>/dev/null | awk '{print $5; exit}')
	[[ -n "$IFACE" ]] || {
		echo "No default interface found"
		return 1
	}

	echo "🔓 Opening port 3389 tcp/udp on interface $IFACE..."

	sudo iptables -C INPUT -i "$IFACE" -p tcp --dport 3389 -j ACCEPT 2>/dev/null ||
		sudo iptables -A INPUT -i "$IFACE" -p tcp --dport 3389 -j ACCEPT

	sudo iptables -C INPUT -i "$IFACE" -p udp --dport 3389 -j ACCEPT 2>/dev/null ||
		sudo iptables -A INPUT -i "$IFACE" -p udp --dport 3389 -j ACCEPT

	sudo ip6tables -C INPUT -i "$IFACE" -p tcp --dport 3389 -j ACCEPT 2>/dev/null ||
		sudo ip6tables -A INPUT -i "$IFACE" -p tcp --dport 3389 -j ACCEPT

	sudo ip6tables -C INPUT -i "$IFACE" -p udp --dport 3389 -j ACCEPT 2>/dev/null ||
		sudo ip6tables -A INPUT -i "$IFACE" -p udp --dport 3389 -j ACCEPT

	echo "✅ RPD port exposed on "$IFACE"."

}

#######
# DNS #
#######

install_cloudflare_dns() {
	local CONF="/etc/systemd/resolved.conf"
	local BACKUP="${CONF}.stealthdns.bak"

	if ! command -v cloudflared >/dev/null 2>&1; then
		wget -O cloudflared-linux-amd64.deb \
			https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb

		sudo apt-get install ./cloudflared-linux-amd64.deb
	fi

	sudo tee "/etc/systemd/system/cloudflared.service" >/dev/null <<EOCONF
[Unit]
Description=Cloudflared DNS over HTTPS proxy
After=network-online.target
Wants=network-online.target

[Service]
User=root
ExecStart=/usr/local/bin/cloudflared --config /etc/cloudflared/config.yml proxy-dns
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOCONF

	sudo mkdir -p /etc/cloudflared
	sudo tee "/etc/cloudflared/config.yml" >/dev/null <<EOCF
# Run a local DNS proxy
proxy-dns: true
proxy-dns-address: 127.0.0.1
proxy-dns-port: 53

# Upstream DoH endpoints (Cloudflare)
proxy-dns-upstream:
  - https://1.1.1.1/dns-query
  - https://1.0.0.1/dns-query
EOCF

	sudo systemctl daemon-reload
	sudo systemctl enable --now cloudflared
	sudo systemctl status cloudflared

	echo "🕵️‍♂️🔐 Enabling stealth DNS (Cloudflare DNS over HTTPS)..."

	# Basic sanity checks
	if ! command -v systemctl >/dev/null 2>&1; then
		echo "❌ systemctl not found. This function assumes a systemd-based system."
		return 1
	fi

	# Check that the unit is known at all
	if ! systemctl list-unit-files systemd-resolved.service >/dev/null 2>&1; then
		echo "❌ systemd-resolved.service unit not found. Not touching DNS."
		return 1
	fi

	# Backup existing config once
	if [[ -f "$CONF" && ! -f "$BACKUP" ]]; then
		echo "📦 Backing up existing $CONF to $BACKUP"
		sudo cp "$CONF" "$BACKUP" || {
			echo "❌ Failed to create backup; aborting."
			return 1
		}
	fi

	echo "✍️  Writing $CONF ..."
	sudo tee "$CONF" >/dev/null <<EOF
[Resolve]
DNS=127.0.0.1
DNSOverTLS=no
FallbackDNS=
EOF

	echo "🔄 Restarting systemd-resolved..."
	if sudo systemctl restart systemd-resolved; then
		echo "✅ Stealth DNS enabled via systemd-resolved (Cloudflare over DoH)."
	else
		echo "❌ Failed to restart systemd-resolved."
		return 1
	fi
}

remove_cloudflare_dns() {
	local CONF="/etc/systemd/resolved.conf"
	local BACKUP="${CONF}.stealthdns.bak"

	echo "🧹 Removing stealth DNS settings..."

	if [[ -f "$BACKUP" ]]; then
		echo "↩️ Restoring backup $BACKUP → $CONF"
		sudo mv "$BACKUP" "$CONF" || {
			echo "❌ Failed to restore backup."
			return 1
		}
	else
		echo "ℹ️ No backup found; writing a minimal reset config to $CONF"
		sudo tee "$CONF" >/dev/null <<EOF
# Reset by remove_cloudflare_dns()
[Resolve]
#DNS=
#FallbackDNS=
#DNSOverTLS=no
EOF
	fi

	echo "🔄 Restarting systemd-resolved..."
	if sudo systemctl restart systemd-resolved; then
		echo "✅ Stealth DNS settings removed; systemd-resolved restarted."
	else
		echo "❌ Failed to restart systemd-resolved."
		return 1
	fi
}

stealth_dns_nm_apply_all() {
	local ipv4_dns="1.1.1.1 1.0.0.1"
	local ipv6_dns="2606:4700:4700::1111 2606:4700:4700::1001" # CF IPv6

	if ! command -v nmcli >/dev/null 2>&1; then
		echo "❌ nmcli not found. NetworkManager is required for this function."
		return 1
	fi

	echo "🥷🌐 Applying stealth DNS to all NetworkManager connections..."
	echo "    IPv4 → ${ipv4_dns}"
	echo "    IPv6 → ${ipv6_dns}"
	echo

	nmcli -t -f NAME connection show | while IFS= read -r conn; do
		[[ -z "$conn" ]] && continue
		[[ "$conn" == "lo" ]] && {
			echo "⏭️  Skipping loopback (lo)"
			continue
		}

		# Get methods
		local m4 m6
		m4="$(nmcli -g ipv4.method connection show "$conn" 2>/dev/null)"
		m6="$(nmcli -g ipv6.method connection show "$conn" 2>/dev/null)"

		echo "⚙️  Connection: ${conn}"
		echo "    ipv4.method=${m4:-<none>}  ipv6.method=${m6:-<none>}"

		# IPv4: only touch if auto/manual/shared
		case "$m4" in
		auto | manual | shared)
			echo "    → Setting IPv4 DNS..."
			sudo nmcli connection modify "$conn" ipv4.dns "$ipv4_dns"
			sudo nmcli connection modify "$conn" ipv4.ignore-auto-dns yes
			;;
		"")
			echo "    → Skipping IPv4 (no IPv4 config)."
			;;
		*)
			echo "    → Skipping IPv4 (method=${m4}, DNS not allowed)."
			;;
		esac

		# IPv6: only touch if auto/manual
		case "$m6" in
		auto | manual)
			echo "    → Setting IPv6 DNS..."
			sudo nmcli connection modify "$conn" ipv6.dns "$ipv6_dns"
			sudo nmcli connection modify "$conn" ipv6.ignore-auto-dns yes
			;;
		"")
			echo "    → Skipping IPv6 (no IPv6 config)."
			;;
		*)
			echo "    → Skipping IPv6 (method=${m6}, DNS not allowed)."
			;;
		esac

		echo
	done

	echo "✅ Stealth DNS applied where supported."
	echo ""
	echo "ℹ️ Active connections will need to be re-connected to apply changes."
	echo "   (You can reconnect a specific connection with:"
	echo "    sudo nmcli connection down \"<name>\" && sudo nmcli connection up \"<name>\")"
	echo
	echo "View dns info with 'resolvectl status'."
}

stealth_dns_nm_reset_all() {
	if ! command -v nmcli >/dev/null 2>&1; then
		echo "❌ nmcli not found. NetworkManager is required for this function."
		return 1
	fi

	echo "🧹 Resetting DNS for all NetworkManager connections to use DHCP/auto..."

	nmcli -t -f NAME connection show | while IFS= read -r conn; do
		[[ -z "$conn" ]] && continue
		[[ "$conn" == "lo" ]] && {
			echo "⏭️  Skipping loopback (lo)"
			continue
		}

		local m4 m6
		m4="$(nmcli -g ipv4.method connection show "$conn" 2>/dev/null)"
		m6="$(nmcli -g ipv6.method connection show "$conn" 2>/dev/null)"

		echo "⚙️  Connection: ${conn}"
		echo "    ipv4.method=${m4:-<none>}  ipv6.method=${m6:-<none>}"

		case "$m4" in
		auto | manual | shared)
			echo "    → Resetting IPv4 DNS to auto..."
			sudo nmcli connection modify "$conn" ipv4.dns ""
			sudo nmcli connection modify "$conn" ipv4.ignore-auto-dns no
			;;
		*)
			echo "    → Skipping IPv4 reset (method=${m4})."
			;;
		esac

		case "$m6" in
		auto | manual)
			echo "    → Resetting IPv6 DNS to auto..."
			sudo nmcli connection modify "$conn" ipv6.dns ""
			sudo nmcli connection modify "$conn" ipv6.ignore-auto-dns no
			;;
		*)
			echo "    → Skipping IPv6 reset (method=${m6})."
			;;
		esac

		echo
	done

	echo "✅ DNS reset to automatic where supported."
	echo ""
	echo "ℹ️ Active connections will need to be re-connected to apply changes."
	echo "   (You can reconnect a specific connection with:"
	echo "    sudo nmcli connection down \"<name>\" && sudo nmcli connection up \"<name>\")"
	echo
	echo "View dns info with 'resolvectl status'."
}

menu_dns() {

	while true; do

		clear
		echo "╭──────────────────────────────────────────╮"
		echo -e "│       ${BOLD}${CYAN}🌐 Cloudflare DNS Menu 🌐${RESET}          │"
		echo "╰──────────────────────────────────────────╯"
		echo "1) Add Cloudflare DNS"
		echo "2) Remove Cloudflare DNS"
		echo "3) 🔙 Back to Main Menu"
		echo ""
		read -p "Enter your choice [1-3]:" dns_choice

		case "$dns_choice" in
		1)
			echo
			echo "Installing Cloudflare DNS..."
			echo
			install_cloudflare_dns
			stealth_dns_nm_apply_all
			echo
			echo "Cloudflare DNS is now enabled."
			echo
			echo "✅ You can verify your encrypted DNS here: https://one.one.one.one/help/"
			echo
			;;
		2)
			echo
			echo "Removing Cloudflare DNS..."
			echo
			remove_cloudflare_dns
			stealth_dns_nm_reset_all
			echo
			echo "Cloudflare DNS is now disabled."
			echo
			echo "✅ You can verify your standard DNS here: https://one.one.one.one/help/"
			echo
			;;
		3)
			menu_main
			;;
		*)
			echo "Invalid option. Please try again."
			;;
		esac
		msg_pause
	done
}

#########
## VPN ##
#########

# --- WireGuard helpers (wg-quick + Ubuntu AppArmor workaround) ----------------

_vpn_need_name() {
	local name="$1"
	if [[ -z "$name" ]]; then
		echo "usage: $2 <name>"
		return 2
	fi
	# basic sanity: keep interface names simple
	if [[ ! "$name" =~ ^[a-zA-Z0-9_.-]+$ ]]; then
		echo "invalid name: '$name' (use letters/numbers/._-)"
		return 2
	fi
	return 0
}

vpn_setup() {

	local dir_prefix=""

	if [[ "$(uname -s)" == "Darwin" ]]; then
		local dir_prefix="/usr/local"
	fi

	local name="$1"
	local src="${2:-${name}.conf}"
	local dst="${dir_prefix}/etc/wireguard/${name}.conf"

	_vpn_need_name "$name" "vpn_setup" || return $?

	if [[ ! -f "$src" ]]; then
		echo "✗ missing config: $src"
		return 2
	fi

	echo "▶ Setting up WireGuard profile: $name"
	echo "  - source: $src"
	echo "  - target: $dst"

	# REMOVE FOR MAC
	# START AppArmor workaround for wg-quick + uutils coreutils 'stat' mount table reads START

	local aa_file="/etc/apparmor.d/local/wg-quick"
	local aa_tmp
	aa_tmp="$(mktemp)"

	cat >"$aa_tmp" <<'EOF'
# workaround for https://bugs.launchpad.net/ubuntu/+source/apparmor/+bug/2127851
file r @{PROC}/@{pid}/mounts,
file r @{PROC}/@{pid}/mountinfo,
EOF

	sudo mkdir -p /etc/apparmor.d/local

	if ! sudo test -f "$aa_file" || ! sudo cmp -s "$aa_tmp" "$aa_file"; then
		echo "  - applying AppArmor workaround (wg-quick/stat)"
		sudo tee "$aa_file" >/dev/null <"$aa_tmp"
		sudo systemctl reload apparmor
	else
		echo "  - AppArmor workaround already present"
	fi

	rm -f "$aa_tmp"

	# END AppArmor workaround END

	# Install config securely
	sudo mkdir -p "${dir_prefix}/etc/wireguard"
	sudo chmod 700 "${dir_prefix}/etc/wireguard"

	if sudo test -f "$dst" && sudo cmp -s "$src" "$dst"; then
		echo "  - config already installed (no change)"
	else
		if [[ "$(uname -s)" == "Darwin" ]]; then
			echo "  - installing config (root:wheel, 600)"
			sudo install -o root -g wheel -m 600 "$src" "$dst"
		else
			echo "  - installing config (root:root, 600)"
			sudo install -o root -g root -m 600 "$src" "$dst"
		fi
	fi

	echo "✓ Setup complete for: $name"
}

vpn_up() {
	local name="$1"
	_vpn_need_name "$name" "vpn_up" || return $?

	if ip link show dev "$name" >/dev/null 2>&1; then
		echo "✓ $name is already up"
		return 0
	fi

	echo "▶ Bringing up: $name"
	sudo wg-quick up "$name"
}

vpn_down() {
	local name="$1"
	_vpn_need_name "$name" "vpn_down" || return $?

	echo "▶ Bringing down: $name"

	local out rc
	out="$(sudo wg-quick down "$name" 2>&1)"
	rc=$?

	# Graceful no-op cases (already down / doesn't exist / nothing to do)
	if [[ $rc -eq 0 ]] ||
		grep -qiE 'does not exist|not found|Cannot find device|No such device|Unknown device|is not a WireGuard interface' <<<"$out"; then
		echo "✓ Down: $name"
		return 0
	fi

	# Unexpected error: show output and return non-zero
	echo "$out" >&2
	echo "✗ Failed to bring down: $name" >&2
	return $rc
}

# Config dir: keep your manual toggle if you want, but put it in ONE place.
# Linux: /etc/wireguard
# macOS (brew): /usr/local/etc/wireguard   (or /opt/homebrew/etc/wireguard on Apple Silicon)
WG_CONF_DIR="${WG_CONF_DIR:-/usr/local/etc/wireguard}"

_vpn_find_iface() {
	local name="$1"
	local conf="${WG_CONF_DIR}/${name}.conf"

	# 1) Linux/common case: interface name == profile name
	if sudo wg show "$name" >/dev/null 2>&1; then
		echo "$name"
		return 0
	fi

	# 2) macOS case: interface is utunX. Match by interface public key.
	if ! sudo test -r "$conf"; then
		return 1
	fi

	local priv pub interfaces iface iface_pub
	priv="$(sudo awk -F= '/^[[:space:]]*PrivateKey[[:space:]]*=/{gsub(/[[:space:]]/,"",$2); print $2; exit}' "$conf")"
	[[ -n "$priv" ]] || return 1

	# Fix common missing base64 padding (43 -> 44)
	if [[ ${#priv} -eq 43 ]]; then
		priv="${priv}="
	fi

	# Validate length (WireGuard base64 key should be 44 chars)
	if [[ ${#priv} -ne 44 ]]; then
		echo "✗ Invalid PrivateKey length in $conf (${#priv} chars, expected 44)."
		return 1
	fi

	pub="$(printf '%s' "$priv" | wg pubkey 2>/dev/null)" || return 1
	[[ -n "$pub" ]] || return 1

	interfaces="$(sudo wg show interfaces 2>/dev/null || true)"
	for iface in $interfaces; do
		# "wg show <iface> public-key" exists on most installs; fallback to parsing.
		iface_pub="$(sudo wg show "$iface" public-key 2>/dev/null ||
			sudo wg show "$iface" 2>/dev/null | awk -F': ' '/public key:/{print $2; exit}')"
		if [[ "$iface_pub" == "$pub" ]]; then
			echo "$iface"
			return 0
		fi
	done

	return 1
}

vpn_status() {
	local name="$1"
	_vpn_need_name "$name" "vpn_status" || return $?

	local iface=""
	iface="$(_vpn_find_iface "$name" 2>/dev/null || true)"

	echo "▶ Status: $name"
	if [[ -z "$iface" ]]; then
		echo "  - link: DOWN"
		return 0
	fi

	if [[ "$iface" != "$name" ]]; then
		echo "  - interface: $iface (profile: $name)"
	else
		echo "  - interface: $iface"
	fi

	sudo wg show "$iface" || true
	# Optional: show IP without getting fancy; only tiny branching
	if command -v ip >/dev/null 2>&1; then
		ip -brief addr show dev "$iface" 2>/dev/null || true
	elif command -v ifconfig >/dev/null 2>&1; then
		ifconfig "$iface" 2>/dev/null | awk '/inet /{print $2}' | head -n1 | awk '{print "  - ip: " $1}'
	fi
}

menu_vpn() {
	local default_name="${1:-}"
	local name="${default_name:-}"

	while true; do
		clear
		echo "╭──────────────────────────────────────────╮"
		echo -e "│       ${BOLD}${CYAN}🌐       VPN Menu      🌐${RESET}          │"
		echo "╰──────────────────────────────────────────╯"
		echo "Profile: ${name:-<not set>}"
		echo
		echo "1) Set/Change profile name"
		echo "2) Setup wireguard client (install config + AppArmor workaround)"
		echo "3) START wireguard"
		echo "4) STOP wireguard"
		echo "5) Status"
		echo "6) 🔙 Back to Main Menu"
		echo
		read -r -p "Enter your choice [1-6]: " vpn_choice

		case "$vpn_choice" in
		1)
			read -r -p "Enter profile name (interface/config base name): " name
			;;
		2)
			if [[ -z "$name" ]]; then echo "✗ set a profile name first (option 1)"; else vpn_setup "$name"; fi
			;;
		3)
			if [[ -z "$name" ]]; then echo "✗ set a profile name first (option 1)"; else vpn_up "$name"; fi
			;;
		4)
			if [[ -z "$name" ]]; then echo "✗ set a profile name first (option 1)"; else vpn_down "$name"; fi
			;;
		5)
			if [[ -z "$name" ]]; then echo "✗ set a profile name first (option 1)"; else vpn_status "$name"; fi
			;;
		6)
			menu_main
			return 0
			;;
		*)
			echo "Invalid option."
			;;
		esac

		# Use your existing pause() if you already have one in setup.sh
		if command -v pause >/dev/null 2>&1; then
			pause
		else
			read -r -p "Press Enter to continue..." _
		fi
	done
}

## AI ##

install_ollama() {

	curl -fsSL https://ollama.com/install.sh | sh

	sudo useradd -r -s /bin/false -U -m -d /usr/share/ollama ollama
	sudo usermod -a -G ollama $(whoami)

	#DEFAULT 4096 MAX 32000
	#OLLAMA_CONTEXT_LENGTH=32000

	cat >"/etc/systemd/system/ollama.service" <<EOF
[Unit]
Description=Ollama Service
After=network-online.target

[Service]
ExecStart=/usr/bin/ollama serve
User=ollama
Group=ollama
Restart=always
RestartSec=3
Environment="PATH=$PATH"
Environment="OLLAMA_CONTEXT_LENGTH=4096"

[Install]
WantedBy=multi-user.target
EOF

	sudo systemctl daemon-reload
	sudo systemctl enable ollama

	pipx install piper-tts --include-deps

}

#######

lock_out() {

	qdbus6 org.freedesktop.ScreenSaver /ScreenSaver Lock
}

qt5check() {

	# check_qt_stack.sh — verifies that your KDE/Plasma environment is running entirely on Qt 6
	# It scans loaded libraries, installed packages, and key processes for any Qt 5 remnants.

	echo "=== Checking active Qt libraries ==="
	sudo lsof -n | grep '/libqt' | grep -v snap | sort -u

	echo -e "\n=== Checking installed KDE/Qt package versions ==="
	dpkg -l | grep -E 'libqt6|libkf6|plasma|kwin|kio' | awk '{print $2, $3}' | column -t | sort

	echo -e "\n=== Checking runtime processes for Qt version ==="
	ps -e | grep -E 'plasmashell|kwin|systemsettings|dolphin' |
		awk '{print $4}' | xargs -r ldd 2>/dev/null | grep -E 'libQt' | sort -u

}

repository_add() {
	echo ""
	msg_confirm "Add the Kubuntu Backports PPA?" || return 1

	msg_start "Adding Kubuntu Backports PPA…"
	msg_text "  (Official Kubuntu repo providing newer KDE Plasma packages)"

	sudo add-apt-repository -y ppa:kubuntu-ppa/backports
	sudo apt update

	msg_end "Kubuntu Backports PPA added successfully."
}

repository_remove() {
	echo ""
	msg_confirm "Remove the Kubuntu Backports PPA?" || return 1

	msg_start "Removing Kubuntu Backports PPA…"
	msg_text "  (Returning to standard Ubuntu KDE packages)"

	sudo add-apt-repository -y --remove ppa:kubuntu-ppa/backports
	sudo apt update

	msg_end "Kubuntu Backports PPA removed successfully."
}

visualstudio_add() {

	# Install dependencies
	sudo apt install -y curl shfmt

	msg_start "Adding Microsoft VS Code repository…"

	# Import GPG key (modern method)
	curl -fsSL https://packages.microsoft.com/keys/microsoft.asc |
		sudo gpg --dearmor -o /usr/share/keyrings/microsoft.gpg

	# Add repository file

	#Legacy .list format
	#echo "deb [arch=amd64 signed-by=/usr/share/keyrings/microsoft.gpg] \
	#https://packages.microsoft.com/repos/code stable main" |
	#sudo tee /etc/apt/sources.list.d/vscode.list >/dev/null

	#Modern Deb822 format (multi-line key: value style)
	sudo tee /etc/apt/sources.list.d/vscode.sources >/dev/null <<'EOF'
Types: deb
URIs: https://packages.microsoft.com/repos/code
Suites: stable
Components: main
Architectures: amd64
Signed-By: /usr/share/keyrings/microsoft.gpg
EOF

	sudo apt update
	sudo apt install -y code

	### make vscode a context menu item
	for mime in text/plain text/markdown application/json text/x-shellscript text/x-python; do
		xdg-mime default code.desktop "$mime" >/dev/null 2>&1 || true
	done
	kbuildsycoca6 --noincremental >/dev/null 2>&1 || true
	###

	msg_end "VS Code installed successfully."

	visualstudio_stealth
	visualstudio_stealth_hosts

}

visualstudio_stealth() {

	CONFIG_DIR="${HOME}/.config/Code/User"
	SETTINGS="${CONFIG_DIR}/settings.json"

	echo "➜ Applying VS Code privacy/telemetry settings for user: $USER"

	mkdir -p "$CONFIG_DIR"

	if [[ -f "$SETTINGS" ]]; then
		backup="${SETTINGS}.bak.$(date +%Y%m%d-%H%M%S)"
		echo "  - Existing settings.json found, backing up to:"
		echo "    $backup"
		cp "$SETTINGS" "$backup"
	else
		echo "  - No existing settings.json, creating a new one"
	fi

	python3 - "$SETTINGS" <<'EOF'
import json, os, sys

path = sys.argv[1]

# Load existing settings if valid JSON, otherwise start fresh
data = {}
if os.path.exists(path):
    try:
        with open(path, "r", encoding="utf-8") as f:
            data = json.load(f)
    except Exception:
        # Corrupt or non-JSON file: keep it backed up, start clean overrides
        data = {}

overrides = {
    # Telemetry / crash reporting
    "telemetry.telemetryLevel": "off",
    "telemetry.enableTelemetry": False,
    "telemetry.enableCrashReporter": False,

    # Experiments / remote feature toggles
    "workbench.enableExperiments": False,

    # Updates / background chatter
    "update.mode": "none",
    "update.enableWindowsBackgroundUpdates": False,
    "update.enableLinuxBackgroundUpdates": False,
    "update.showReleaseNotes": False,

    # Extensions: no auto-recommendations / auto-updates
    "extensions.autoUpdate": False,
    "extensions.autoCheckUpdates": False,
    "extensions.gallery.autoCheckUpdates": False,
    "extensions.gallery.autoUpdate": False,
    "extensions.ignoreRecommendations": True,
    "extensions.showRecommendationsOnlyOnDemand": True,
}

data.update(overrides)

with open(path, "w", encoding="utf-8") as f:
    json.dump(data, f, indent=4, sort_keys=True)
    f.write("\n")
EOF

	echo "✓ VS Code privacy settings applied."

}

visualstudio_stealth_hosts() {

	echo "➜ Adding VS Code telemetry blocklist to /etc/hosts…"

	# Marker comment – used for grep detection
	MARKER="# VS_CODE_TELEMETRY_BLOCK_START"

	# Check if the block is already present
	if ! grep -q "$MARKER" /etc/hosts; then
		sudo tee -a /etc/hosts >/dev/null <<'EOF'

# VS_CODE_TELEMETRY_BLOCK_START
0.0.0.0 vscodeexperiments.azureedge.net
0.0.0.0 default.exp-tas.com
0.0.0.0 exp-tas.com
0.0.0.0 az764295.vo.msecnd.net
0.0.0.0 vscode-sync-insiders.trafficmanager.net
# VS_CODE_TELEMETRY_BLOCK_END

EOF

		echo "✓ Telemetry endpoints added."
	else
		echo "✓ Telemetry block already present. No changes made."
	fi

}

visualstudio_ext_add() {

	echo "➜ Adding VS Code extensions…"

	while IFS= read -r ext; do
		[[ -z "$ext" ]] && continue
		[[ "$ext" =~ ^# ]] && continue
		code --install-extension "$ext"
	done <"$SCRIPT_DIR/vscode-extensions.txt"

	echo "✓ VS Code extensions added."

}

visualstudio_remove() {

	msg_start "Removing Microsoft VS Code and repository…"

	sudo apt purge -y code
	sudo apt autoremove -y

	sudo rm -f /usr/share/keyrings/microsoft.gpg
	sudo rm -f /etc/apt/sources.list.d/vscode.*
	sudo apt update

	msg_end "VS Code and repository removed."

	read -r -p "Remove all VS Code user data (settings + extensions) for $USER? [y/N]: " reply
	case "$reply" in
	[yY] | [yY][eE][sS])
		rm -rf "$HOME/.vscode"
		rm -rf "$HOME/.config/Code"
		echo "VS Code user data removed."
		;;
	*)
		echo "Skipped removing VS Code user data."
		;;
	esac

}

firefox_add() {

	echo "Firefox"
	echo ""
	echo "This will REMOVE your current Firefox and ALL IT'S FILES."
	echo "NO CUURENT BACKUP"
	echo ""

	read -p "Do you want to upgrade to Firefox ESR? [y/N]: " UPGRADE_FIREFOX
	if [[ "$UPGRADE_FIREFOX" =~ ^[Yy]$ ]]; then

		msg_start "Removing Previous Mozilla Firefox…"

		sudo snap remove firefox
		sudo apt purge -y firefox
		sudo apt autoremove -y

		msg_start "Adding Mozilla Firefox ESR repository…"

		sudo add-apt-repository -y ppa:mozillateam/ppa

		# Prevent Snap Firefox from stealing priority
		msg_text "➜ Setting APT priority to prefer deb over snap…"
		sudo tee /etc/apt/preferences.d/mozillateam.pref >/dev/null <<'EOF'
Package: firefox*
Pin: release o=LP-PPA-mozillateam
Pin-Priority: 1001
EOF
		msg_start "Updating apt…"
		sudo apt update

		msg_start "Installing firefox-esr…"
		sudo apt install -y firefox-esr

		msg_end "Firefox ESR installed successfully."

	fi

}

firefox_policy_install_addons() {

	#https://mozilla.github.io/policy-templates/

	# AMO "latest" endpoints (not pinned to a specific file build)
	local -a addon_urls=(
		"https://addons.mozilla.org/firefox/downloads/latest/adblock-for-youtube/latest.xpi"
		"https://addons.mozilla.org/firefox/downloads/latest/privacy-badger17/latest.xpi"
	)

	local policy_dir="/etc/firefox/policies"

	if [[ "$(uname -s)" == "Darwin" ]]; then
		policy_dir="/Applications/Firefox.app/Contents/Resources/distribution"
	fi

	sudo mkdir -p "$policy_dir"

	local policy_file="$policy_dir/policies.json"
	# Backup if it exists (keeps your scripts idempotent & reversible)
	if sudo test -f "$policy_file"; then
		sudo cp -a "$policy_file" "$policy_file.bak.$(date +%F_%H%M%S)"
	fi

	# Write a minimal policies.json that installs these extensions
	sudo tee "$policy_file" >/dev/null <<JSON
{
  "policies": {
    "Extensions": {
      "Install": [
        "${addon_urls[0]}",
        "${addon_urls[1]}"
      ]
    }
  }
}
JSON

	echo "✅ Wrote $policy_file"
	echo "   Restart Firefox to apply (the add-ons install on startup)."
}

firefox_remove() {
	msg_start "Removing Firefox ESR and Mozilla repository…"

	sudo apt purge -y firefox-esr
	sudo apt autoremove -y

	sudo rm -f /etc/apt/preferences.d/mozillateam.pref
	sudo add-apt-repository -y --remove ppa:mozillateam/ppa

	sudo apt update

	msg_end "Firefox ESR and repository removed."
}

install_openshot() {

	#flatpak install flathub org.openshot.OpenShot

	msg_start "Adding OpenShot Video Editor PPA and installing…"

	sudo add-apt-repository -y ppa:openshot.developers/ppa
	sudo apt update
	sudo apt install -y openshot-qt python3-openshot

	msg_end "OpenShot Video Editor installed successfully."
}

remove_openshot() {
	msg_start "Removing OpenShot Video Editor and its PPA…"

	sudo apt purge -y openshot-qt python3-openshot
	sudo apt autoremove -y

	sudo add-apt-repository -y --remove ppa:openshot.developers/ppa
	sudo apt update

	msg_end "OpenShot Video Editor and PPA removed."
}

install_androidstudio() {
	msg_start "Adding Android Studio PPA and installing…"

	sudo add-apt-repository -y ppa:maarten-fonville/android-studio
	sudo apt update
	sudo apt install -y android-studio

	msg_end "Android Studio installed successfully."
}

remove_androidstudio() {
	msg_start "Removing Android Studio and its PPA…"

	sudo apt purge -y android-studio
	sudo apt autoremove -y

	sudo add-apt-repository -y --remove ppa:maarten-fonville/android-studio
	sudo apt update

	msg_end "Android Studio and PPA removed."
}

install_musecore() {

	sudo snap install musescore --candidate

	sudo snap connect musescore:alsa
	sudo snap connect musescore:removable-media

}

#apt rdepends --installed libqt5core5t64

#lsblk -o NAME,MODEL,SIZE,ROTA
#sudo dmidecode -t memory
#sudo dmidecode -s system-product-name
#sudo lspci | grep -i network
#sudo lshw -C network
#nmcli dev wifi list

################################################################################
######       MENUs
################################################################################

menu_java() {

	while true; do

		clear

		echo "╭──────────────────────────────────────────╮"
		echo -e "│             ${BOLD}${CYAN}Java Management${RESET}              │"
		echo "╰──────────────────────────────────────────╯"
		msg_text "Select the Java version to install:"
		echo "1) default-jre"
		echo "2) openjdk-8-jre-headless"
		echo "3) openjdk-11-jre-headless"
		echo "4) openjdk-17-jre-headless"
		echo "5) openjdk-21-jre-headless"
		echo "6) openjdk-22-jre-headless"
		echo "7) openjdk-23-jre-headless"
		echo "8) openjdk-24-jre-headless"
		#echo "9) Homebrew Java (openjdk)"
		echo ""
		echo "r) Remove Java"
		echo "q) 🔙 Back to Main Menu"
		echo

		read -p "Enter your choice: " java_choice

		case "$java_choice" in
		1) sudo apt install default-jre ;;
		2) sudo apt install openjdk-8-jre-headless ;;
		3) sudo apt install openjdk-11-jre-headless ;;
		4) sudo apt install openjdk-17-jre-headless ;;
		5) sudo apt install openjdk-21-jre-headless ;;
		6) sudo apt install openjdk-22-jre-headless ;;
		7) sudo apt install openjdk-23-jre-headless ;;
		8) sudo apt install openjdk-24-jre-headless ;;
		99)
			echo "Installing Java via Homebrew."
			install_homebrew
			install_homebrew_java
			;;
		r | R)
			remove_java
			;;
		q | Q)
			menu_main
			;;
		*)
			echo "Invalid option. Please try again."
			;;
		esac
		msg_pause
	done
}

menu_nodejs() {

	while true; do

		clear

		echo "╭──────────────────────────────────────────╮"
		echo -e "│               ${BOLD}${CYAN}Node.JS® Menu${RESET}              │"
		echo "╰──────────────────────────────────────────╯"
		msg_text "Node.JS® Setup"
		echo "1) Install Node.JS®"
		echo "2) Remove Node.JS®"
		echo "3) 🔙 Back to Main Menu"
		echo ""
		read -rp "Please select an option [1-3]: " choice

		case $choice in
		1)
			install_nodejs
			;;
		2)
			remove_nodejs
			;;
		3)
			menu_main
			;;
		*)
			echo "Invalid option. Please try again."
			;;
		esac
		msg_pause
	done

}

menu_homebrew() {

	while true; do

		clear

		echo "╭──────────────────────────────────────────╮"
		echo -e "│               ${BOLD}${CYAN}Homebrew Menu${RESET}              │"
		echo "╰──────────────────────────────────────────╯"
		msg_text "Homebrew Setup"
		echo "1) Install Homebrew"
		echo "2) Remove Homebrew"
		echo "3) 🔙 Back to Main Menu"
		echo ""
		read -rp "Please select an option [1-3]: " choice

		case $choice in
		1)
			install_homebrew
			;;
		2)
			remove_homebrew
			;;
		3)
			menu_main
			;;
		*)
			echo "Invalid option. Please try again."
			;;
		esac
		msg_pause
	done

}

menu_flatpak() {

	while true; do

		clear

		echo "╭──────────────────────────────────────────╮"
		echo -e "│               ${BOLD}${CYAN}Flatpak Menu${RESET}               │"
		echo "╰──────────────────────────────────────────╯"
		msg_text "Flatpak Setup"
		echo "1) Install Flatpak"
		echo "2) Remove Flatpak"
		echo "3) 🔙 Back to Main Menu"
		echo ""
		read -rp "Please select an option [1-3]: " choice

		case $choice in
		1)
			msg_start "Installing Flatpak…"
			sudo apt install flatpak
			msg_start "Adding Flathub remote repository…"
			flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

			;;
		2)
			msg_start "Removing Flatpak…"
			sudo apt remove flatpak
			sudo apt autoremove
			;;
		3)
			menu_main
			;;
		*)
			echo "Invalid option. Please try again."
			;;
		esac
		msg_pause
	done

}

menu_dev() {

	while true; do

		clear

		echo "╭──────────────────────────────────────────╮"
		echo -e "│      ${BOLD}${CYAN}Development Applications Menu${RESET}       │"
		echo "╰──────────────────────────────────────────╯"
		echo "1) Development Utilities (make, etc...)"
		echo "2) Android Studio"
		echo "3) Visual Studio Code"
		echo "4) Visual Studio Code - Extensions"
		echo "5) IntelliJ IDEA"
		echo "6) JetBrains WebStorm"
		echo "7) Arduino"
		echo "8) Glade (GTK+ UI Designer)"
		echo "9) Flutter/Dart"
		echo "10) Deploy bash shell tools → ~/.bash_aliases"
		echo "11) Setup GIT ssh signing/authentication keys"
		echo "12) 🔙 Back to Main Menu"
		echo ""
		read -rp "Please select an option [1-12]: " choice

		case $choice in
		1)
			install_development
			;;
		2)
			install_androidstudio
			;;
		3)
			visualstudio_add
			#sudo snap install codium --classic
			;;
		4)
			visualstudio_ext_add
			;;
		5)
			sudo snap install intellij-idea-ultimate --classic
			;;
		6)
			sudo snap install webstorm --classic
			;;
		7)
			sudo apt install -y arduino
			;;
		8)
			sudo snap install glade
			;;
		9)
			sudo snap install flutter --classic
			flutter --version
			dart --version
			;;
		10)
			# Copy examples only if the target file doesn't exist yet
			[[ -f "$HOME/.bash_aliases" ]] || cp --update=none "./bash_aliases.example" "$HOME/.bash_aliases"
			;;
		11)
			setup_git_ssh_signing
			;;
		12)
			menu_main
			;;
		*)
			echo "Invalid option. Please try again."
			;;
		esac
		msg_pause
	done

}
# Main Menu
menu_main() {

	while true; do

		clear

		SEC_TOP=""
		#SEC_TOP="--------------------------------------------"

		SEC_BOT=""
		#SEC_BOT="--------------------------------------------"

		echo "╭──────────────────────────────────────────╮"
		echo -e "│             ${BOLD}${CYAN}Ubuntu Setup Menu${RESET}            │"
		echo "╰──────────────────────────────────────────╯"
		msg_text "Core Application Setup"
		echo "1) System Applications"
		echo "2) Audio Studio"
		echo "3) Install btop"
		echo "4) Install Balena-Etcher"
		echo "5) Install Veracypt"
		echo $SEC_BOT
		msg_text "Development Tools"
		echo "6) Development Applications"
		echo "7) Add/Remove Java"
		echo "8) Add/Remove Node.js®"
		echo "9) Add/Remove Homebrew"
		echo "10) Add/Remove Flatpak"
		echo $SEC_BOT
		msg_text "Desktop Environment"
		echo "11) Install Plasma/KDE Desktop"
		echo "12) Add Plasma/KDE Settings"
		echo "13) Install SDDM Desktop Manager"
		echo $SEC_BOT
		msg_text "System Configuration"
		echo "14) Set Up SSH Server"
		echo "15) Install Cups Printing"
		echo "16) Firewall / IPTables Setup"
		echo "17) CloudFlare DoH DNS Setup"
		echo "18) Manage Wireguard VPN Client"
		echo $SEC_BOT
		msg_text "Graphics & 3d Printing"
		echo "19) Install OpenShot"
		echo "20) Install Blender/Gimp/Inkscape"
		echo "21) Install Freecad"
		echo "22) Install OrcaSlicer"
		echo "23) Install Repetier Server"
		echo "24) Install RP-Imager"
		echo $SEC_BOT
		msg_text "System Maintenance"
		echo "25) Full Applications and System Update(s)"
		echo "26) Operating System Upgrade"
		echo $SEC_BOT
		msg_text "Backports PPA Repository"
		echo "27) Add Repository "
		echo "28) Remove Repository"
		echo "29) Add Firefox-ESR"
		echo "30) Install Thunderbird"
		echo $SEC_BOT
		echo -e "${RED}31) Exit${RESET}"
		echo ""
		read -rp "Please select an option [1-31]: " choice

		case $choice in
		1)
			install_apt_apps
			;;
		2)
			install_audio_studio
			;;
		3)
			sudo snap install btop
			;;
		4)
			install_etcher_portable
			;;
		5)
			install_deb_packages "https://launchpad.net/veracrypt/trunk/1.26.24/+download/veracrypt-1.26.24-Ubuntu-25.04-amd64.deb"
			;;
		6)
			menu_dev
			;;
		7)
			menu_java
			;;
		8)
			menu_nodejs
			;;
		9)
			menu_homebrew
			;;
		10)
			menu_flatpak
			;;
		11)
			install_kde_plasma_desktop
			;;
		12)
			kde_settings
			;;
		13)
			install_sddm
			;;
		14)
			setup_ssh
			;;
		15)
			install_cups
			;;
		16)
			iptables_secure
			;;
		17)
			menu_dns
			;;
		18)
			#menu_vpn "$1"
			menu_vpn
			;;
		19)
			install_openshot
			;;
		20)
			install_graphics
			;;
		21)
			sudo snap install freecad
			;;
		22)
			install_appimages "https://github.com/SoftFever/OrcaSlicer/releases/download/v2.3.1/OrcaSlicer_Linux_AppImage_Ubuntu2404_V2.3.1.AppImage"
			;;
		23)
			install_deb_packages "https://download1.repetier.com/files/server/debian-amd64/Repetier-Server-1.4.16-Linux.deb"
			;;
		24)
			sudo snap install rpi-imager
			;;
		25)
			update_upgrade
			;;
		26)
			update_system
			;;
		27)
			repository_add
			;;
		28)
			repository_remove
			;;
		29)
			firefox_add
			;;
		30)
			sudo snap install thunderbird
			;;
		31 | q)
			echo "Exiting."
			exit 0
			;;
		66)
			#lock current desktop session remotely
			lock_out
			;;
		qt)
			# 🕵🏻‍♂️ secret qt check
			qt5check
			;;
		libreoffice)
			sudo apt install libreoffice
			;;
		dbeaver)
			sudo snap install dbeaver-ce --classic
			;;
		ffremove)
			firefox_remove
			;;
		muse)
			install_musecore
			;;
		ollama)
			install_ollama
			;;
		ledger)
			install_ledger_live
			;;
		discord)
			install_discord
			;;
		brave)
			sudo apt install curl
			sudo curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg
			echo "deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg] https://brave-browser-apt-release.s3.brave.com/ stable main" | sudo tee /etc/apt/sources.list.d/brave-browser-release.list
			sudo apt update
			sudo apt install brave-browser
			;;
		iptablesreset)
			iptables_reset
			;;
		*)
			echo "Invalid option. Please try again."
			;;
		esac
		msg_pause
	done
}

menu_main
