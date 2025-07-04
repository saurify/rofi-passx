# rofi-passx

**A modern, extensible, and user-friendly password manager interface for [pass](https://www.passwordstore.org/) using [rofi](https://github.com/davatorium/rofi).**

---

## Overview

`rofi-passx` is a shell-based menu system that provides a seamless graphical interface for managing your password store via `rofi`. Building on the foundation of the original [rofi-pass](https://github.com/carnager/rofi-pass), `rofi-passx` introduces a more modular, maintainable, and extensible codebase, with improved navigation and user experience.

If you are looking for a natural successor to `rofi-pass`, with a focus on scriptability, maintainability, and a modern UX, `rofi-passx` is designed for you.

---

## Features

- **Full integration with `pass`**: All password management is done via the standard [pass](https://www.passwordstore.org/) utility.
- **Rofi-powered UI**: Fast, keyboard-driven menu navigation for all password operations.
- **Multi-level navigation**: Easily browse sites, users, and credentials with a stack-based menu system.
- **Add, edit, update, and delete entries**: Manage your credentials with ease.
- **CSV import**: Quickly migrate credentials from other password managers.
- **GPG key management**: Initialize and switch GPG keys for your password store.
- **Notifications**: Get instant feedback on actions via desktop notifications.
- **Extensible and modular**: Each menu and utility is a separate script for easy customization and extension.

---

## Prerequisites

- **Linux** (tested on modern distributions)
- **[pass](https://www.passwordstore.org/)** (the standard Unix password manager)
- **[rofi](https://github.com/davatorium/rofi)** (for the graphical menu)
- **gpg** (for encryption)
- **bash** (or compatible shell)

---

## Installation

1. **Clone the repository:**
   ```sh
   git clone https://github.com/saurify/rofi-passx.git
   cd rofi-passx
   ```

2. **(Optional) Install dependencies:**
   - Ensure `pass`, `rofi`, and `gpg` are installed via your package manager:
     ```sh
     sudo pacman -S pass rofi gnupg   # Arch Linux
     sudo apt install pass rofi gnupg # Debian/Ubuntu
     ```

3. **Make scripts executable:**
   ```sh
   chmod +x rofi-passx rofi-passx-setup *.sh
   ```

4. **(Optional) Add to your PATH:**
   ```sh
   sudo cp rofi-passx /usr/local/bin/
   ```

---

## Getting Started

### 1. Initialize your password store

If you haven’t already, initialize your password store with your GPG key:
```sh
pass init "YOUR-GPG-ID"
```
Or use the setup script:
```sh
./rofi-passx-setup
```

### 2. Launch the menu

Simply run:
```sh
./rofi-passx
```
or, if installed to your PATH:
```sh
rofi-passx
```

### 3. Navigate

- Use the keyboard to select sites, users, and actions.
- Add, edit, or delete credentials as needed.
- Use the back navigation to return to previous menus.

---

## Usage

- **Add Entry**: Add a new credential for a site and user.
- **Edit Entry**: Edit an existing credential.
- **Delete Entry**: Remove a credential or an entire site.
- **Import CSV**: Import credentials from a CSV file (with columns: domain, username, password).
- **Switch GPG Key**: Change the GPG key used for encryption.
- **Notifications**: Desktop notifications inform you of successful or failed actions.

All actions are performed securely using `pass` and GPG.

---

## How is `rofi-passx` different from [rofi-pass](https://github.com/carnager/rofi-pass)?

- **Modular Design**: Each menu and utility is a separate script, making it easier to maintain and extend.
- **Stack-based Navigation**: Improved user experience with a robust navigation stack, allowing for intuitive back-and-forth movement between menus.
- **CSV Import**: Built-in support for importing credentials from CSV files.
- **Extensibility**: Designed for easy customization and addition of new features.
- **Cleaner Codebase**: Adheres to modern shell scripting practices and coding guidelines.

**If you liked `rofi-pass`, you’ll find `rofi-passx` a natural, modern successor with a focus on maintainability and user experience.**

---

## Contributing

Contributions are welcome! Please see `CODING_GUIDELINES.md` for best practices.

---

## License

This project is licensed under the MIT License.

---

## Acknowledgements

- Inspired by [rofi-pass](https://github.com/carnager/rofi-pass) and the Unix philosophy of modular, scriptable tools.
- Thanks to all contributors and users of the original `rofi-pass` project.

---

For more details, see the in-script documentation and comments, or open an issue if you have questions.

---

Let me know if you want to further tailor this README for a specific audience or add more technical details!