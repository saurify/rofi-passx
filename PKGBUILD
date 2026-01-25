pkgname=rofi-passx
gitname=rofi-passx
desc="Rofi based password manager based on pass"
pkgver=1.0.0
pkgrel=1
arch=('any')
url="https://github.com/saurify/rofi-passx"
license=('MIT')
depends=('bash' 'gnupg' 'pass' 'rofi' 'xclip' 'libnotify')
optdepends=('wl-clipboard: Wayland clipboard support')
install=rofi-passx.install
source=("git+https://github.com/saurify/rofi-passx.git")
sha256sums=('SKIP') 

package() {
    install -Dm755 bin/rofi-passx "$pkgdir/usr/bin/rofi-passx"
    install -d "$pkgdir/usr/share/rofi-passx"
    cp -r lib "$pkgdir/usr/share/rofi-passx/lib"

    install -Dm644 share/rofi-passx.desktop "$pkgdir/usr/share/applications/rofi-passx.desktop"
}