# rofi-passx

A modular, user-friendly password manager interface for [pass](https://www.passwordstore.org/) using [rofi](https://github.com/davatorium/rofi).

---

## Overview

`rofi-passx` provides a graphical menu system for managing your password store via `rofi`. It is designed to be modular, maintainable, and extensible, allowing users to manage credentials efficiently from a keyboard-driven interface.

---

## Features

- **Integration with `pass`**: All password management is performed using the standard [pass](https://www.passwordstore.org/) utility.
- **Rofi-based UI**: Keyboard-driven menu navigation for all password operations.
- **Multi-level navigation**: Browse sites, users, and credentials with a stack-based menu system.
- **Credential management**: Add, edit, update, and delete entries.
- **CSV import**: Import credentials from CSV files.
- **Desktop notifications**: Receive feedback on actions via notifications.
- **Clipboard integration**: Copy passwords or usernames to your clipboard securely.
- **Modular structure**: Each menu and utility is a separate script for easy customization and extension.

---

## Prerequisites

To ensure all features work as intended, you should have the following tools installed:

- **[pass](https://www.passwordstore.org/):** The standard Unix password manager.
- **[rofi](https://github.com/davatorium/rofi):** For the graphical menu interface.
- **gpg:** For encryption and decryption of passwords.
- **bash:** Or a compatible POSIX shell.
- **Clipboard utility:**
  - Recommended: `xclip` (for X11)
  - Alternative: `xsel` (for X11)
  - For Wayland-native clipboard support, you may also want `wl-clipboard`, but see the note below.
- **Notification utility:**
  - Recommended: `notify-send` (provided by `libnotify`)

You can install these dependencies using your system's package manager. For example, on Arch Linux:
```sh
sudo pacman -S pass rofi gnupg xclip libnotify
```
Or on Debian/Ubuntu:
```sh
sudo apt install pass rofi gnupg xclip libnotify-bin
```

> **Note:**
> - **Rofi is an X11 application.** On Wayland compositors, Rofi runs via XWayland (an X11 compatibility layer). This works on most setups, but is not native Wayland. If you encounter issues, check that XWayland is enabled in your compositor.
> - **Clipboard integration** in this project uses X11 tools (`xclip` or `xsel`). These work with Rofi under XWayland. If you use Wayland-native applications, you may also want `wl-clipboard`, but copying from Rofi menus will still use the X11 clipboard.
> - **Notifications** via `notify-send` should work on both X11 and Wayland, provided a notification daemon is running.

---

## Installation
 
 1. **Clone the repository:**
    ```sh
    git clone https://github.com/saurify/rofi-passx.git
    cd rofi-passx
    ```
 
 2. **Install dependencies:**
    - **Arch Linux:**
      ```sh
      sudo pacman -S rofi pass gnupg xclip libnotify
      ```
    - **Debian/Ubuntu:**
      ```sh
      sudo apt install rofi pass gpg xclip libnotify-bin
      ```
    - **Fedora:**
      ```sh
      sudo dnf install rofi pass gnupg xclip libnotify
      ```
 
 3. **Install:**
    ```sh
    sudo make install
    ```
    This installs `rofi-passx` to `/usr/bin/` and supporting scripts to `/usr/lib/rofi-passx/`.
 
 4. **(Optional) Uninstall:**
    ```sh
    sudo make uninstall
    ```
 
 **Alternative: Install via PKGBUILD (Arch Linux/Manjaro):**
 ```sh
 makepkg -si
 ```

---

## Getting Started

### 1. Initialize your password store

If you haven't already, initialize your password store with your GPG key:
```sh
pass init "YOUR-GPG-ID"
```
Or use the setup script:
```sh
./rofi-passx-setup
```

### 2. Launch the menu

Run:
```sh
./rofi-passx
```
or, if installed to your PATH:
```sh
rofi-passx
```

### 3. Navigation

- Use the keyboard to select sites, users, and actions.
- Add, edit, or delete credentials as needed.
- Use the back navigation to return to previous menus.

---

## Usage

- **Add Entry**: Add a new credential for a site and user.
- **Edit Entry**: Edit an existing credential.
- **Delete Entry**: Remove a credential or an entire site.
- **Import CSV**: Import credentials from a CSV file (with columns: domain, username, password).
- **Notifications**: Desktop notifications inform you of successful or failed actions.
- **Clipboard**: Copy passwords or usernames to your clipboard for easy pasting.
- **Settings**: Open the configuration file to customize behavior.

All actions are performed using `pass` and GPG.

---

## Configuration

`rofi-passx` uses a configuration file located at `~/.config/rofi-passx/config`.
This file is automatically created with default settings upon first run or when accessing the Settings menu.

You can configure:
- **Password Store Directory**: Custom location for your password store.
- **Import Directory**: Custom location for CSV files to import.
- **Notifications**: Enable/disable global or per-action notifications.
- **Clipboard**: Preferred clipboard utilities.

To edit the configuration, select "⚙️ Settings" from the main menu or manually edit the file.

---

## Contributing

Contributions are welcome. Please see any included guidelines or open an issue for questions.

---

## License

This project is licensed under the MIT License.