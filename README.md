# rofi-passx

A modular, keyboard-driven interface for [pass](https://www.passwordstore.org/) using [rofi](https://github.com/davatorium/rofi).

## Prerequisites

Before installing, ensure you have the following installed on your system:

*   **pass**: The standard unix password manager.
*   **rofi**: The menu interface.
*   **gnupg**: For encryption/decryption.
*   **Clipboard Utility**:
    *   `xclip` or `xsel` (for X11)
    *   `wl-clipboard` (for Wayland)

## Installation

### Option 1: Manual Installation (Universal)

1.  **Clone the repository:**
    ```bash
    git clone https://github.com/saurify/rofi-passx.git
    cd rofi-passx
    ```

2.  **Install:**
    ```bash
    sudo make install
    ```

### Option 2: Arch Linux (PKGBUILD)

If you are on Arch Linux, you can build and install the package using `makepkg`:

```bash
git clone https://github.com/saurify/rofi-passx.git
cd rofi-passx
makepkg -si
```

## Setup

If you haven't initialized `pass` yet, you can use the included setup script will assist you to generate a GPG key and initialize the password store:

```bash
rofi-passx-setup
```

## Usage

Launch the menu from your terminal or bind it to a hotkey in your window manager and it will show up in rofi dmenu as well:

```bash
rofi-passx
```

### Features

#### Browsing & Searching
Navigate through your password hierarchy using the keyboard. Type to filter entries.

#### Copying Credentials
Select an entry to view options for copying the password or username to your clipboard. The clipboard is automatically cleared after a set timeout.

#### Managing Entries
You can add, edit, or delete entries directly from the menu.
*   **Add**: Create new entries with generated or manual passwords.
*   **Edit**: Modify existing entries.
*   **Delete**: Remove entries (requires confirmation).


#### Import
Import credentials from CSV files (You can import passwords from browser generated csv files).
