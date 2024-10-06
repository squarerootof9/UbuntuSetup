# UbuntuSetup

# **Ubuntu Setup and Hosts Updater Scripts**

This repository contains scripts to automate the setup of an Ubuntu system with preferred applications and configurations, and to enhance system security and privacy by updating the hosts file to block ads, phishing sites, and other malicious domains. The scripts are designed to work seamlessly on a fresh install and do not require any login credentials or accounts.

---

## **Table of Contents**

- [Overview](#overview)
- [Setup Script (`setup.sh`)](#setup-script-setupsh)
  - [Features](#features)
  - [Usage](#usage)
- [Hosts Updater Script (`hosts_updater.sh`)](#hosts-updater-script-hosts_updatersh)
  - [Purpose](#purpose)
  - [Usage](#usage-1)
  - [How It Works](#how-it-works)
  - [Compatibility](#compatibility)
- [Important Notes](#important-notes)
- [Description](#description)
- [License](#license)
- [Contributing](#contributing)
- [Acknowledgements](#acknowledgements)
- [Contact](#contact)

---

## **Overview**

This project aims to simplify the initial setup of an Ubuntu system by automating the installation of essential applications and configuring system preferences to your liking. Additionally, it enhances your system's security and privacy by updating the hosts file to block unwanted domains.

---

## **Setup Script (`setup.sh`)**

### **Features**

- **Automates Installation of Applications:**
  - Installs Homebrew (Linuxbrew) if not already installed.
  - Installs Java via Homebrew and configures environment variables.
  - Installs various packages and applications using `apt`, `snap`, and Homebrew.
  - Installs AppImage applications and creates desktop entries for them.
  - Provides options to install or remove the Kubuntu desktop environment.

- **Configurable and Modular:**
  - Features a menu system allowing you to choose between full setup or individual components.
  - Functions are modular and can be reused or modified as needed.

- **Designed for Fresh Installs:**
  - Ideal for setting up a new Ubuntu installation.
  - Does not require any login credentials or accounts to install software.

### **Usage**

1. **Clone the Repository:**

   ```bash
   git clone https://github.com/yourusername/yourrepository.git
   cd yourrepository
   ```

2. **Make the Script Executable:**

   ```bash
   chmod +x setup.sh
   ```

3. **Run the Script:**

   ```bash
   ./setup.sh
   ```

4. **Follow the On-Screen Menu:**

   The script presents a menu with options:

   ```
   --------------------------------------------
   Setup Script Menu
   --------------------------------------------
   1) Full setup (Homebrew, Java, Apps)
   2) Add/Remove Java
   3) Add Kubuntu Desktop
   4) Remove Kubuntu Desktop
   5) Exit
   --------------------------------------------
   Please select an option [1-5]:
   ```

   - **Option 1:** Performs the full setup, including installing Homebrew, Java, applications, and optionally the Kubuntu desktop environment.
   - **Option 2:** Allows you to install or remove Java.
   - **Option 3:** Installs the Kubuntu desktop environment.
   - **Option 4:** Removes the Kubuntu desktop environment.
   - **Option 5:** Exits the script.

5. **Reboot If Necessary:**

   - If you install or remove the Kubuntu desktop environment, the script will prompt you to reboot your system to apply the changes.

---

## **Hosts Updater Script (`hosts_updater.sh`)**

### **Purpose**

The `hosts_updater.sh` script updates your system's hosts file to block ads, phishing sites, malware domains, and other malicious websites. This enhances your privacy and security while browsing the internet.

### **Usage**

1. **Make the Script Executable:**

   ```bash
   chmod +x hosts_updater.sh
   ```

2. **Run the Script:**

   ```bash
   ./hosts_updater.sh
   ```

3. **Select an Option:**

   The script presents a menu with three options:

   ```
   --------------------------------------------
   Hosts File Updater Script
   --------------------------------------------
   1) Add/Update hosts entries
   2) Remove hosts entries
   3) Exit
   --------------------------------------------
   Please select an option [1-3]:
   ```

   - **Option 1:** Downloads the latest hosts file and updates your system's hosts file.
   - **Option 2:** Removes the entries added by this script.
   - **Option 3:** Exits the script.

### **How It Works**

- **Downloading Hosts File:**

  - The script downloads a hosts file from a trusted source: [MVPS Hosts](https://winhelp2002.mvps.org/hosts.htm).
  - The hosts file contains mappings of known malicious domains to `0.0.0.0`, effectively blocking them.

- **Updating the Hosts File:**

  - The script backs up your existing `/etc/hosts` file.
  - It removes any previous entries added by itself to avoid duplicates.
  - It appends the new entries, enclosed within identifiable comments for easy management.

- **Flushing DNS Cache:**

  - After updating the hosts file, the script flushes the DNS cache to ensure changes take effect immediately.
  - Works on both Ubuntu and macOS by detecting the operating system and using the appropriate commands.

### **Compatibility**

- **Cross-Platform Support:**

  - The script is designed to work on both **Ubuntu** and **macOS** systems.
  - It automatically detects the operating system and adjusts its operations accordingly.

- **No Dependencies on Logins or Accounts:**

  - The script does not require any login credentials or additional setup.
  - Ideal for fresh installations where minimal configuration has been done.

---

## **Important Notes**

- **Administrative Privileges:**

  - Both the `setup.sh` and `hosts_updater.sh` scripts may require `sudo` privileges to execute certain commands (e.g., modifying system files).

- **Backups:**

  - The `hosts_updater.sh` script creates backups of your hosts file before making any changes. Backup files are stored with a timestamp (e.g., `/etc/hosts.backup.YYYYMMDDHHMMSS`).

- **Customizations:**

  - You can customize the list of applications and packages in the `setup.sh` script to suit your needs.
  - The `snap_list.txt` file can be edited to include the snap packages you wish to install.

- **Testing:**

  - It is recommended to test the scripts in a controlled environment or virtual machine before running them on a production system.

- **No Login Required:**

  - All installations and configurations are performed without the need for any login credentials.
  - The scripts fetch applications and updates from open-source repositories and trusted sources.

---

## **Description**

This project is part of a group of three scripts designed to enable users to set up their systems across macOS, Linux, and Windows platforms. The aim is to facilitate sharing work and exploring creativity while utilizing free and open-source software whenever possible. By providing consistent setup processes and tools across different operating systems, these scripts help users maintain a unified and efficient workflow, making cross-platform collaboration and productivity seamless.

---

## **License**

This project is licensed under the MIT License.

```
MIT License

[Full MIT License Text]
```

---

## **Contributing**

Contributions are welcome! If you have suggestions, improvements, or fixes, feel free to open an issue or submit a pull request.

---

## **Acknowledgements**

- **Homebrew (Linuxbrew):** The missing package manager for Linux.
- **snap:** A software packaging and deployment system.
- **MVPS Hosts:** Provides a comprehensive hosts file to block unwanted domains.

---

## **Contact**

For questions or support, please open an issue on the repository or contact [Your Email].

---

**Note:** Always review scripts and understand their functions before running them, especially when they modify system files or require administrative privileges.

