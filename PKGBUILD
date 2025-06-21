pkgname=rofi-passx
gitname=rofi-passx
desc="Rofi-integrated password backup and fetch tool for pass"
pkgver=1.0.0
pkgrel=1
arch=('any')
url="https://github.com/example/rofi-passx"
license=('MIT')
depends=('bash' 'gnupg' 'pass' 'rofi' 'xclip' 'xdg-utils' 'coreutils' 'libnotify')
optdepends=('wl-clipboard: Wayland clipboard support')
install=rofi-passx.install
source=(
    "rofi-passx"
    "rofi-passx-setup"
    "utils/clipboard.sh"
    "utils/config.sh"
    "utils/gpg.sh"
    "utils/notify.sh"
    "utils/pass.sh"
    "utils/startup.sh"
    "menu/confirm_action_menu.sh"
    "menu/add_entry_menu.sh"
    "menu/update_entry_menu.sh"
    "menu/delete_entry_menu.sh"
    "menu/edit_passwords_menu.sh"
    "menu/site_menu.sh"
    "rofi-passx.desktop"
)
sha256sums=('SKIP' 'SKIP' 'SKIP' 'SKIP' 'SKIP' 'SKIP' 'SKIP' 'SKIP' 'SKIP')

package() {
    # Install main executable
    install -Dm755 "$srcdir/rofi-passx" "$pkgdir/usr/bin/rofi-passx"
    
    # Install setup script
    install -Dm755 "$srcdir/rofi-passx-setup" "$pkgdir/usr/bin/rofi-passx-setup"
    
    # Install utils directory
    install -dm755 "$pkgdir/usr/lib/rofi-passx/utils"
    install -Dm644 "$srcdir/utils/"*.sh "$pkgdir/usr/lib/rofi-passx/utils/"
    
    # Install menu directory
    install -dm755 "$pkgdir/usr/lib/rofi-passx/menu"
    install -Dm644 "$srcdir/menu/"*.sh "$pkgdir/usr/lib/rofi-passx/menu/"
    
    # Install desktop file
    install -Dm644 "$srcdir/rofi-passx.desktop" "$pkgdir/usr/share/applications/rofi-passx.desktop"
} 