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

install_development() {

	echo ""
	echo "📦 Installing Build Essentials"
	echo ""

	#libtool-bin # Different from libtool?

	#flex bison ant	ragel lua5.4

	sudo apt install --no-install-recommends \
		make cmake ninja-build automake autoconf autopoint libtool g++ pkg-config swig \
		doxygen graphviz libltdl-dev libcurl4-openssl-dev gettext intltool \
		python3-setuptools python3-pip python3-wheel \
		subversion git curl ccache dpkg-dev libc6-dev \
		libncurses-dev \
		protobuf-compiler patch

	echo ""
	echo "✅ Build Essentials Installed"
	echo ""
}

# Function to install Homebrew
install_homebrew() {
	if ! $HOMEBREW_INSTALLED; then
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
				} >>"$HOME/.bashrc"
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

################################################################################
######                          Node.JS®
################################################################################

install_nodejs() {

	local options="${1:-}"

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
		echo " - Removing ~/.nvm"
		rm -rf "$HOME/.nvm"
	else
		echo " - ~/.nvm already removed"
	fi

	# 2) Remove npm cache
	if [ -d "$HOME/.npm" ]; then
		echo " - Removing ~/.npm cache"
		rm -rf "$HOME/.npm"
	else
		echo " - ~/.npm cache already removed"
	fi

	# 3) Remove NVM-related lines from ~/.bashrc
	echo " - Cleaning up ~/.bashrc entries"

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
		aha clinfo edid-decode libdisplay-info-bin libpulsedsp mesa-utils mesa-utils-bin pulseaudio-utils vulkan-tools wayland-utils
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

		# Widgets, calendar, engine add-ons
		plasma-calendar-addons
		plasma-dataengines-addons
		plasma-runners-addons
		plasma-widgets-addons

		# Appearance (themes, visuals)
		plasma-theme-oxygen
		#plasma-workspace-wallpapers (185M)
		plasma-wallpapers-addons

		#add this only after it's updated to qt6
		#plasma-wallpaper-dynamic

		kdegraphics-thumbnailers
		ffmpegthumbs
		kimageformat6-plugins
		plymouth-theme-breeze
		plymouth-theme-kubuntu-logo
		plymouth-theme-kubuntu-text
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
		ksystemlog
		khelpcenter
		kdf
		kpartx
		partitionmanager
		plasma-browser-integration
		plasma-discover-notifier
		plasma-disks
		kcalc
		kcharselect
		kamera
		krecorder
		print-manager
	)

	ankonadi=(
		akonadi-server
		akonadi-backend-mysql
	)

	# don't forget someday
	#sudo apt install libreoffice

	#sudo apt install --no-install-recommends kmail accountwizard kleopatra #kaddressbook

	kde_pim=(
		#Core apps:
		kalarm
		#Core framework:
		kdepim
		kdepim-runtime
		#Extra features:
		kdepim-addons
		accountwizard
		libkdepim-plugins
		kdepim-themeeditors

		#Merkuro Suite:
		merkuro
		qml6-module-org-kde-kirigamiaddons-settings
		qml6-module-qtlocation
	)

	kde_pim_old=(
		#Core apps:
		kontact
		kmail
		korganizer
		kaddressbook
		kalarm
		klevernotes
		#Core framework:
		kdepim
		kdepim-runtime
		#Extra features:
		kdepim-addons
		accountwizard
		libkdepim-plugins
		kdepim-themeeditors
	)

	#sudo apt install -y kaccounts-integration kaccounts-providers kio-gdrive nextcloud-desktop owncloud-client telepathy-mission-control-5 plasma-vault
	#kdenetwork-filesharing

	all_packages=(
		"${base_desktop[@]}"
		"${kde_kio_modules[@]}"
		"${bluetooth_libs[@]}"
		"${essential_kde_utilities[@]}"
	)

	install_apps "${all_packages[@]}"

}

install_sddm() {

	# Prompt for sddm
	#read -p "Do you want to install sddm? [y/N]: " INSTALL_SDDM
	#if [[ "$INSTALL_SDDM" =~ ^[Yy]$ ]]; then

	sddm=(
		sddm
		xserver-xorg-input-libinput
		sddm-theme-breeze
		#qt6-virtualkeyboard-plugin
		#sddm-conf
		#qt6-qtwayland
	)

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

	packages=(
		"${sddm[@]}"
	)

	install_apps "${packages[@]}"

	#else
	#echo "Skipping sddm installation."
	#fi

}

kde_settings() {

	################################
	# Configure Plasma/Dolphin/KDE #
	################################

	# Single-click opens items
	kwriteconfig6 --file kdeglobals --group "KDE" --key "SingleClick" true

	# Dolphin startup location and behavior
	kwriteconfig6 --file dolphinrc --group "General" --key "HomeUrl" "file:///home/$USER"
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
		flatpak update -y
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
	)
	### 💾 File System & Disk Tools
	fs_disk_tools=(
		exfatprogs jfsutils reiserfsprogs xfsprogs udftools libparted-dev
	)
	### 🔐 Security & Auth
	security_tools=(
		opensc pcscd fido2-tools yubico-piv-tool libpam-pkcs11 xca wireguard
	)

	#mplayer-skin-blue breaks mplayer-skins install
	sudo tee /etc/apt/preferences.d/blacklist-mplayer-skin-blue >/dev/null <<EOF
Package: mplayer-skin-blue
Pin: release *
Pin-Priority: -1
EOF

	### 🖥️ Multimedia / GUI / OBS
	gui_apps=(
		obs-studio
		audacity
		mpv
		mplayer mplayer-gui mencoder mplayer-skins #<-mplayer-skin-blue breaks install
		ffmpeg
		#vlc #qt5 🤔 apt rdepends --installed libqt5core5t64
		#smplayer #qt5 🤔
	)
	### 📱 Mobile / Flash / Embedded
	embedded_tools=(
		adb binwalk esptool
	)
	### 🌍 Web & Remote Tools
	remote_tools=(
		curl wget elinks
	)

	### 🌐 Network Utilities
	network_tools=(
		net-tools
		traceroute
		dnsutils
		netcat-openbsd
	)

	### 🛰️ Nmap & Companion Tools
	nmap_tools=(
		nmap
		ncat
		ndiff
		zenmap
	)

	### 🛠 Miscellaneous / Special Purpose
	misc_tools=(
		python-is-python3
		#synaptic
		#dotnet-sdk-9.0
	)

	all_packages=(
		"${system_utils[@]}"
		"${fs_disk_tools[@]}"
		"${security_tools[@]}"
		"${gui_apps[@]}"
		"${embedded_tools[@]}"
		"${remote_tools[@]}"
		"${network_tools[@]}"
		"${nmap_tools[@]}"
		"${misc_tools[@]}"
	)

	install_apps "${all_packages[@]}"

}

install_snap_apps() {

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

	# Install snaps with classic confinement
	echo "Installing snap packages with classic confinement..."

	sudo snap install blender --classic

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
	mkdir -p ~/.local/share/applications
	cat <<EOF >~/.local/share/applications/balena-etcher.desktop
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

	WAN_IF=$(ip route | awk '/^default/{print $5; exit}') # auto-detect WAN if

	# Ask user whether to expose it
	echo ""
	read -rp "Would you like to expose SSH (port 22) to the network on interface $WAN_IF? [y/N]: " reply
	case "$reply" in
	[yY] | [yY][eE][sS])
		echo "🔓 Opening port 22 on interface $WAN_IF..."

		sudo iptables -C INPUT -i "$WAN_IF" -p tcp --dport 22 -j ACCEPT 2>/dev/null ||
			sudo iptables -A INPUT -i "$WAN_IF" -p tcp --dport 22 -j ACCEPT

		sudo ip6tables -C INPUT -i "$WAN_IF" -p tcp --dport 22 -j ACCEPT 2>/dev/null ||
			sudo ip6tables -A INPUT -i "$WAN_IF" -p tcp --dport 22 -j ACCEPT

		echo "✅ SSH port exposed on "$WAN_IF"."

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
	WAN_IF=$(ip route | awk '/^default/{print $5; exit}') # auto-detect WAN if
	# ------------------------------

	# --- OpenSSH detection & optional exposure ---

	# Check if openssh-server is installed
	if dpkg -l | awk '$2 == "openssh-server" && $1 == "ii" {found=1} END {exit !found}'; then
		echo "✅ OpenSSH Server detected on this system."

		# Ask user whether to expose it
		read -rp "Would you like to expose SSH (port 22) to the network on interface $WAN_IF? [y/N]: " reply_ssh
		case "$reply_ssh" in
		[yY] | [yY][eE][sS])
			echo "🔓 Opening port 22 on interface $WAN_IF..."

			sudo iptables -C INPUT -i "$WAN_IF" -p tcp --dport 22 -j ACCEPT 2>/dev/null ||
				sudo iptables -A INPUT -i "$WAN_IF" -p tcp --dport 22 -j ACCEPT

			sudo ip6tables -C INPUT -i "$WAN_IF" -p tcp --dport 22 -j ACCEPT 2>/dev/null ||
				sudo ip6tables -A INPUT -i "$WAN_IF" -p tcp --dport 22 -j ACCEPT

			echo "✅ SSH port exposed on "$WAN_IF"."
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
	read -rp "Would you like to expose mDNS (port 5353) to the network on interface $WAN_IF? [y/N]: " reply_mDNS
	case "$reply_mDNS" in
	[yY] | [yY][eE][sS])
		echo "🔓 Opening port 5353 on interface $WAN_IF..."

		sudo iptables -C INPUT -i "$WAN_IF" -p udp --dport 5353 -j ACCEPT 2>/dev/null ||
			sudo iptables -A INPUT -i "$WAN_IF" -p udp --dport 5353 -j ACCEPT

		sudo ip6tables -C INPUT -i "$WAN_IF" -p udp --dport 5353 -j ACCEPT 2>/dev/null ||
			sudo ip6tables -A INPUT -i "$WAN_IF" -p udp --dport 5353 -j ACCEPT

		echo "✅ mDNS port exposed on "$WAN_IF"."
		;;
	*)
		echo "❌ mDNS exposure canceled."
		;;
	esac

	############
	#   PING   #
	############

	# Ask user whether to expose
	read -rp "Would you like to be able to ping this machine from the network on interface $WAN_IF? [y/N]: " reply_ping
	case "$reply_ping" in
	[yY] | [yY][eE][sS])
		echo "🔓 Opening ping on interface $WAN_IF..."

		# limit to 10 pings/sec burst 20
		# iptables -R INPUT $(sudo iptables -L INPUT --line-numbers | awk '/icmp/ {print $1; exit}') -p icmp --icmp-type echo-request -m limit --limit 10/second --limit-burst 20 -j ACCEPT
		# ip6tables -R INPUT $(sudo ip6tables -L INPUT --line-numbers | awk '/ipv6-icmp/ {print $1; exit}') -p ipv6-icmp --icmpv6-type echo-request -m limit --limit 10/second --limit-burst 20 -j ACCEPT

		# OR: only allow ping on the WG iface and remove the global one

		sudo iptables -C INPUT -i "$WAN_IF" -p icmp --icmp-type echo-request -j ACCEPT 2>/dev/null ||
			sudo iptables -A INPUT -i "$WAN_IF" -p icmp --icmp-type echo-request -j ACCEPT

		sudo ip6tables -C INPUT -i "$WAN_IF" -p ipv6-icmp --icmpv6-type echo-request -j ACCEPT 2>/dev/null ||
			sudo ip6tables -A INPUT -i "$WAN_IF" -p ipv6-icmp --icmpv6-type echo-request -j ACCEPT

		# iptables -D INPUT <line-number-of-global-icmp-rule>
		# ip6tables -D INPUT <line-number-of-global-icmp-rule>

		echo "✅ ping exposed on "$WAN_IF"."
		;;
	*)
		echo "❌ ping exposure canceled."
		;;
	esac

	iptables_save

}

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

confirm() {
	# Usage: confirm "message" || return 1
	echo -en "${CYAN}$1${RESET} ${YELLOW}[Y/n]${RESET}: "
	read -r ans
	case "${ans,,}" in
	y | yes | "") return 0 ;;
	*)
		echo -e "${RED}✗ Operation cancelled.${RESET}\n"
		return 1
		;;
	esac
}

repository_add() {
	echo ""
	confirm "Add the Kubuntu Backports PPA?" || return 1

	echo -e "\n${CYAN}➜ Adding Kubuntu Backports PPA…${RESET}"
	echo -e "${YELLOW}  (Official Kubuntu repo providing newer KDE Plasma packages)${RESET}\n"

	sudo add-apt-repository -y ppa:kubuntu-ppa/backports
	sudo apt update

	echo -e "\n${GREEN}✓ Kubuntu Backports PPA added successfully.${RESET}\n"
}

repository_remove() {
	echo ""
	confirm "Remove the Kubuntu Backports PPA?" || return 1

	echo -e "\n${CYAN}➜ Removing Kubuntu Backports PPA…${RESET}"
	echo -e "${YELLOW}  (Returning to standard Ubuntu KDE packages)${RESET}\n"

	sudo add-apt-repository -y --remove ppa:kubuntu-ppa/backports
	sudo apt update

	echo -e "\n${GREEN}✓ Kubuntu Backports PPA removed successfully.${RESET}\n"
}

visualstudio_add() {

	# Install dependencies
	sudo apt install -y curl

	echo -e "\n${CYAN}➜ Adding Microsoft VS Code repository…${RESET}"

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

	echo -e "\n${GREEN}✓ VS Code installed successfully.${RESET}\n"

	visualstudio_stealth
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

visualstudio_remove() {

	echo -e "\n${CYAN}➜ Removing Microsoft VS Code and repository…${RESET}"

	sudo apt purge -y code
	sudo apt autoremove -y

	sudo rm -f /usr/share/keyrings/microsoft.gpg
	sudo rm -f /etc/apt/sources.list.d/vscode.*
	sudo apt update

	echo -e "\n${GREEN}✓ VS Code and repository removed.${RESET}\n"
}

firefox_add() {

	echo "Firefox"

	read -p "Do you want to upgrade to Firefox ESR? [y/N]: " UPGRADE_FIREFOX
	if [[ "$UPGRADE_FIREFOX" =~ ^[Yy]$ ]]; then

		echo -e "\n${CYAN}➜ Removing Previous Mozilla Firefox…${RESET}"

		sudo snap remove firefox
		sudo apt purge -y firefox
		sudo apt autoremove -y

		echo -e "\n${CYAN}➜ Adding Mozilla Firefox ESR repository…${RESET}"

		sudo add-apt-repository -y ppa:mozillateam/ppa

		# Prevent Snap Firefox from stealing priority
		echo -e "${YELLOW}➜ Setting APT priority to prefer deb over snap…${RESET}"
		sudo tee /etc/apt/preferences.d/mozillateam.pref >/dev/null <<'EOF'
Package: firefox*
Pin: release o=LP-PPA-mozillateam
Pin-Priority: 1001
EOF
		echo -e "\n${CYAN}➜ Updating apt…${RESET}"
		sudo apt update

		echo -e "\n${CYAN}➜ Installing firefox-esr…${RESET}"
		sudo apt install -y firefox-esr

		echo -e "\n${GREEN}✓ Firefox ESR installed successfully.${RESET}\n"

	fi

}

firefox_remove() {
	echo -e "\n${CYAN}➜ Removing Firefox ESR and Mozilla repository…${RESET}"

	sudo apt purge -y firefox-esr
	sudo apt autoremove -y

	sudo rm -f /etc/apt/preferences.d/mozillateam.pref
	sudo add-apt-repository -y --remove ppa:mozillateam/ppa

	sudo apt update

	echo -e "\n${GREEN}✓ Firefox ESR and repository removed.${RESET}\n"
}

openshot_add() {

	#flatpak install flathub org.openshot.OpenShot

	echo -e "\n${CYAN}➜ Adding OpenShot Video Editor PPA and installing…${RESET}"

	sudo add-apt-repository -y ppa:openshot.developers/ppa
	sudo apt update
	sudo apt install -y openshot-qt python3-openshot

	echo -e "\n${GREEN}✓ OpenShot Video Editor installed successfully.${RESET}\n"
}

openshot_remove() {
	echo -e "\n${CYAN}➜ Removing OpenShot Video Editor and its PPA…${RESET}"

	sudo apt purge -y openshot-qt python3-openshot
	sudo apt autoremove -y

	sudo add-apt-repository -y --remove ppa:openshot.developers/ppa
	sudo apt update

	echo -e "\n${GREEN}✓ OpenShot Video Editor and PPA removed.${RESET}\n"
}

androidstudio_add() {
	echo -e "\n${CYAN}➜ Adding Android Studio PPA and installing…${RESET}"

	sudo add-apt-repository -y ppa:maarten-fonville/android-studio
	sudo apt update
	sudo apt install -y android-studio

	echo -e "\n${GREEN}✓ Android Studio installed successfully.${RESET}\n"
}

androidstudio_remove() {
	echo -e "\n${CYAN}➜ Removing Android Studio and its PPA…${RESET}"

	sudo apt purge -y android-studio
	sudo apt autoremove -y

	sudo add-apt-repository -y --remove ppa:maarten-fonville/android-studio
	sudo apt update

	echo -e "\n${GREEN}✓ Android Studio and PPA removed.${RESET}\n"
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

manage_java() {

	while true; do

		clear

		echo "╭──────────────────────────────────────────╮"
		echo -e "│             ${BOLD}${CYAN}Java Management${RESET}              │"
		echo "╰──────────────────────────────────────────╯"
		echo -e "${YELLOW}Select the Java version to install:${RESET}"
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
			main_menu
			;;
		*)
			echo "Invalid option. Please try again."
			;;
		esac
		pause
	done
}

nodejs_menu() {

	while true; do

		clear

		echo "╭──────────────────────────────────────────╮"
		echo -e "│               ${BOLD}${CYAN}Node.JS® Menu${RESET}              │"
		echo "╰──────────────────────────────────────────╯"
		echo -e "${YELLOW}Node.JS® Setup${RESET}"
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
			main_menu
			;;
		*)
			echo "Invalid option. Please try again."
			;;
		esac
		pause
	done

}

hb_menu() {

	while true; do

		clear

		echo "╭──────────────────────────────────────────╮"
		echo -e "│               ${BOLD}${CYAN}Homebrew Menu${RESET}              │"
		echo "╰──────────────────────────────────────────╯"
		echo -e "${YELLOW}Homebrew Setup${RESET}"
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
			main_menu
			;;
		*)
			echo "Invalid option. Please try again."
			;;
		esac
		pause
	done

}

flatpak_menu() {

	while true; do

		clear

		echo "╭──────────────────────────────────────────╮"
		echo -e "│               ${BOLD}${CYAN}Flatpak Menu${RESET}               │"
		echo "╰──────────────────────────────────────────╯"
		echo -e "${YELLOW}Flatpak Setup${RESET}"
		echo "1) Install Flatpak"
		echo "2) Remove Flatpak"
		echo "3) 🔙 Back to Main Menu"
		echo ""
		read -rp "Please select an option [1-3]: " choice

		case $choice in
		1)
			echo -e "${CYAN}➜ Installing Flatpak…${RESET}"
			sudo apt install flatpak
			echo -e "${CYAN}➜ Adding Flathub remote repository…${RESET}"
			flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

			;;
		2)
			echo -e "${CYAN}➜ Removing Flatpak…${RESET}"
			sudo apt remove flatpak
			sudo apt autoremove
			;;
		3)
			main_menu
			;;
		*)
			echo "Invalid option. Please try again."
			;;
		esac
		pause
	done

}

dev_menu() {

	while true; do

		clear

		echo "╭──────────────────────────────────────────╮"
		echo -e "│         ${BOLD}${CYAN}Development Utilities Menu${RESET}       │"
		echo "╰──────────────────────────────────────────╯"
		echo -e "${YELLOW}Core Application Setup${RESET}"
		echo "1) Development Utilities (make, etc...)"
		echo "2) Android Studio"
		echo "3) Visual Studio"
		echo "4) IntelliJ IDEA"
		echo "5) 🔙 Back to Main Menu"
		echo ""
		read -rp "Please select an option [1-5]: " choice

		case $choice in
		1)
			install_development
			;;
		2)
			androidstudio_add
			;;
		3)
			visualstudio_add
			#sudo snap install codium --classic
			;;
		4)
			sudo snap install intellij-idea-ultimate --classic
			;;
		5)
			main_menu
			;;
		*)
			echo "Invalid option. Please try again."
			;;
		esac
		pause
	done

}
# Main Menu
main_menu() {

	while true; do

		clear

		SEC_TOP=""
		#SEC_TOP="--------------------------------------------"

		SEC_BOT=""
		#SEC_BOT="--------------------------------------------"

		echo "╭──────────────────────────────────────────╮"
		echo -e "│             ${BOLD}${CYAN}Ubuntu Setup Menu${RESET}            │"
		echo "╰──────────────────────────────────────────╯"
		echo -e "${YELLOW}Core Application Setup${RESET}"
		echo "1) System Applications"
		echo "2) Snap Applications"
		echo "3) Install Balena-Etcher"
		echo "4) Install Veracypt"
		echo $SEC_BOT
		echo -e "${YELLOW}Development Tools${RESET}"
		echo "5) Development Applications"
		echo "6) Add/Remove Java"
		echo "7) Add/Remove Node.js®"
		echo "8) Add/Remove Homebrew"
		echo "9) Add/Remove Flatpak"
		echo $SEC_BOT
		echo -e "${YELLOW}Desktop Environment${RESET}"
		echo "10) Install Plasma/KDE Desktop"
		echo "11) Add Plasma/KDE Settings"
		echo "12) Install SDDM Desktop Manager"
		echo $SEC_BOT
		echo -e "${YELLOW}System Configuration${RESET}"
		echo "13) Set Up SSH Server"
		echo "14) Install Cups Printing"
		echo "15) Firewall / IPTables Setup"
		echo $SEC_BOT
		echo -e "${YELLOW}3d Printing${RESET}"
		echo "16) Install OrcaSlicer"
		echo "17) Install Repetier Server"
		echo $SEC_BOT
		echo -e "${YELLOW}System Maintenance${RESET}"
		echo "18) Full Applications and System Update(s)"
		echo "19) Operating System Upgrade"
		echo $SEC_BOT
		echo -e "${YELLOW}Backports PPA Repository${RESET}"
		echo "20) Add Repository "
		echo "21) Remove Repository"
		echo "22) Add Firefox-ESR"
		echo $SEC_BOT
		echo -e "${RED}23) Exit${RESET}"
		echo ""
		read -rp "Please select an option [1-23]: " choice

		case $choice in
		1)
			install_apt_apps
			;;
		2)
			install_snap_apps
			;;
		3)
			install_etcher_portable
			;;
		4)
			install_deb_packages "https://launchpad.net/veracrypt/trunk/1.26.14/+download/veracrypt-1.26.14-Ubuntu-24.04-amd64.deb"
			;;
		5)
			dev_menu
			;;
		6)
			manage_java
			;;
		7)
			nodejs_menu
			;;
		8)
			hb_menu
			;;
		9)
			flatpak_menu
			;;
		10)
			install_kde_plasma_desktop
			;;
		11)
			# Add Kubuntu Desktop
			#install_kde_desktop
			kde_settings
			;;
		12)
			# Remove Kubuntu Desktop
			#remove_kde_desktop
			install_sddm
			;;
		13)
			# Set Up SSH
			setup_ssh
			;;
		14)
			install_cups
			;;
		15)
			iptables_secure
			;;
		16)
			install_appimages "https://github.com/SoftFever/OrcaSlicer/releases/download/v2.3.1/OrcaSlicer_Linux_AppImage_Ubuntu2404_V2.3.1.AppImage"
			;;
		17)
			install_deb_packages "https://download1.repetier.com/files/server/debian-amd64/Repetier-Server-1.4.16-Linux.deb"
			;;
		18)
			# Helper function for updating and upgrading the system
			update_upgrade
			;;
		19)
			update_system
			;;
		20)
			repository_add
			;;
		21)
			repository_remove
			;;
		22)
			firefox_add
			;;
		23)
			echo "Exiting."
			exit 0
			;;
		66)
			#lock current desktop session remotely
			lock_out
			;;
		qt)
			#secret qt check
			qt5check
			;;
		ffremove)
			firefox_remove
			;;
		*)
			echo "Invalid option. Please try again."
			;;
		esac
		pause
	done
}

main_menu
