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
    cp $srcdir/rofi-passx/bin "$pkgdir/usr/bin/rofi-passx/bin"
    cp $srcdir/rofi-passx/lib "$pkgdir/usr/bin/rofi-passx/lib"
    cp $srcdir/rofi-passx/share "$pkgdir/usr/bin/rofi-passx/share"
}