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
source=("rofi-passx-1.0.0.tar.gz")
sha256sums=('SKIP')

package() {
    cd "$srcdir/rofi-passx"
    install -Dm755 rofi-passx "$pkgdir/usr/bin/rofi-passx"
    install -Dm755 rofi-passx-setup "$pkgdir/usr/bin/rofi-passx-setup"
    for f in util_*.sh menu_*.sh; do
        install -Dm644 "$f" "$pkgdir/usr/lib/rofi-passx/$f"
    done
    install -Dm644 rofi-passx.desktop "$pkgdir/usr/share/applications/rofi-passx.desktop"
} 