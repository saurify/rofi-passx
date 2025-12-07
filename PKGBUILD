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
    make install DESTDIR="$pkgdir" PREFIX=/usr
} 