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
    "onboard.sh"
    "import.sh"
    "launch.sh"
    "vault.sh"
    "rofi-passx.desktop"
)
sha256sums=('SKIP' 'SKIP' 'SKIP' 'SKIP' 'SKIP' 'SKIP')

package() {
    install -Dm755 "$srcdir/rofi-passx" "$pkgdir/usr/bin/rofi-passx"
    install -Dm755 "$srcdir/onboard.sh" "$pkgdir/usr/bin/rofi-passx-onboard"
    install -Dm755 "$srcdir/import.sh" "$pkgdir/usr/bin/rofi-passx-import"
    install -Dm755 "$srcdir/launch.sh" "$pkgdir/usr/bin/rofi-passx-launch"
    install -Dm755 "$srcdir/vault.sh" "$pkgdir/usr/lib/rofi-passx-vault.sh"
    install -Dm644 "$srcdir/rofi-passx.desktop" "$pkgdir/usr/share/applications/rofi-passx.desktop"
} 