# UbuntuSetup

## Ubuntu Setup and Hosts Updater Scripts

This project provides two Bash scripts that streamline the configuration and maintenance of an Ubuntu system:

* `setup.sh`: Automates software installation, desktop environment setup, Java management, and system updating.
* `hosts_updater.sh`: Updates your system's hosts file to block ads, trackers, and malicious domains.

These scripts are designed for fresh installs, require no online accounts, and are modular for repeatable and customizable use.

---

## Table of Contents

* [Overview](#overview)
* [Setup Script (`setup.sh`)](#setup-script-setupsh)

  * [Features](#features)
  * [Usage](#usage)
* [Hosts Updater Script (`hosts_updater.sh`)](#hosts-updater-script-hosts_updatersh)

  * [Purpose](#purpose)
  * [Usage](#usage-1)
  * [How It Works](#how-it-works)
  * [Compatibility](#compatibility)
* [Important Notes](#important-notes)
* [License](#license)
* [Contributing](#contributing)
* [Acknowledgements](#acknowledgements)
* [Contact](#contact)

---

## Overview

These scripts simplify system setup and maintenance for Ubuntu users. Whether you're configuring a workstation from scratch or managing multiple devices, this toolset offers modular, clear, and automated options for:

* Desktop environment management
* AppImage/Snap/Flatpak setup
* System updating (APT/Snap/Flatpak)
* Java version control
* Privacy-focused hosts file configuration

---

## Setup Script (`setup.sh`)

### Features

* Desktop environment management
* AppImage/Snap/Flatpak setup
* System updating (APT/Snap/Flatpak)
* Java version control
* Privacy-focused hosts file configuration

---

## Setup Script (`setup.sh`)

### Features

* **Java Version Management**:

  * Install or remove OpenJDK versions 8 through 24 (excluding experimental CRaC builds).
  * Optional Homebrew-based Java installation and environment configuration.

* **Multi-source Package Management**:

  * Install applications via `apt`, `snap`, `flatpak`, or `brew`.
  * Supports AppImage deployment with desktop entry generation.

* **Desktop Environment Control**:

  * Install or remove the Kubuntu desktop environment.

* **Java Version Selection**:

  * Choose from OpenJDK versions 8 through 24 (excluding experimental CRaC builds).
  * Optionally install Homebrew-managed Java.

* **Full System Updates**:

  * Runs `apt update/upgrade/full-upgrade`, `snap refresh`, and `flatpak update`.

* **Modular, Menu-Driven Flow**:

  * Designed for both full setup and individual tasks.

### Usage

1. **Clone the Repository**:

```bash
git clone https://github.com/squarerootof9/UbuntuSetup
cd UbuntuSetup
```

2. **Make the Script Executable**:

```bash
chmod +x setup.sh
```

3. **Run the Script**:

```bash
./setup.sh
```

4. **Interact With the Menu**:

```
╭──────────────────────────────────────────╮
│             Ubuntu Setup Menu            │
╰──────────────────────────────────────────╯
Core Application Setup
1) System Applications
2) Snap Applications
3) Install Balena-Etcher
4) Install Veracypt

Development Tools
5) Development Utilities (make, etc...)
6) Add/Remove Java
7) Add Node.js®
8) Install Homebrew

Desktop Environment
9) Install Plasma/KDE Desktop
10) Add Plasma/KDE Settings
11) Install SDDM Desktop Manager

System Configuration
12) Set Up SSH Server
13) Install Cups Printing
14) Firewall / IPTables Setup

3d Printing
15) Install OrcaSlicer
16) Install Repetier Server

System Maintenance
17) Full Applications and System Update(s)
18) Operating System Upgrade

Backports PPA Repository
19) Add Repository
20) Remove Repository

21) Exit

Please select an option [1-21]:
```

You can run the script multiple times to change or add components.

---

## Hosts Updater Script (`hosts_updater.sh`)

### Purpose

This script blocks unwanted web domains by updating `/etc/hosts`. It helps:

* Stop ads and trackers
* Block malicious domains
* Improve page load speeds

### Usage

1. **Make Executable**:

```bash
chmod +x hosts_updater.sh
```

2. **Run the Script**:

```bash
./hosts_updater.sh
```

3. **Choose an Option**:

```
--------------------------------------------
Hosts File Updater Script
--------------------------------------------
1) Add/Update hosts entries
2) Remove hosts entries
3) Exit
--------------------------------------------
```

* **Option 1**: Installs or updates the blocklist.
* **Option 2**: Reverts changes and restores backup.
* **Option 3**: Exits.

### How It Works

* Downloads a curated blocklist from [MVPS Hosts](https://winhelp2002.mvps.org/hosts.htm)
* Backs up your existing `/etc/hosts`
* Inserts or removes managed entries
* Flushes DNS cache as needed

### Compatibility

* Supports **Ubuntu** and **macOS**
* Detects OS automatically and uses proper tools
* Does not require user accounts or logins

---

## Important Notes

* **Sudo Required**: Some options require administrative access.
* **Safe Defaults**: The scripts back up files before modifying them.
* **Customizable**: Edit the script to add or remove packages, paths, or versions.
* **Modular Workflow**: Re-run safely to install new components later.

---

## License

This project is licensed under the MIT License.

---

## Contributing

Pull requests and suggestions are welcome. Contributions should follow a modular design philosophy and strive for clean, auditable Bash code.

---

## Acknowledgements

* [Homebrew (Linuxbrew)](https://docs.brew.sh/Homebrew-on-Linux)
* Snap, Flatpak, and AppImage maintainers
* [MVPS Hosts Project](https://winhelp2002.mvps.org/hosts.htm)

---

## Contact

Submit issues or questions via GitHub.

---

**Note**: Always review scripts before running them. These scripts modify system files and install software packages.
