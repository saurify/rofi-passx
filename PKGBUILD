pkgname=cred-sync
gitname=cred-sync
desc="Rofi-integrated password backup and fetch tool for pass"
pkgver=1.0.0
pkgrel=1
arch=('any')
url="https://github.com/example/cred-sync"
license=('MIT')
depends=('bash' 'gnupg' 'pass' 'rofi' 'xclip' 'xdg-utils' 'coreutils' 'libnotify')
install=cred-sync.install
source=(
    "cred-sync"
    "onboard.sh"
    "import.sh"
    "launch.sh"
    "vault.sh"
    "cred-sync.desktop"
)
sha256sums=('SKIP' 'SKIP' 'SKIP' 'SKIP' 'SKIP' 'SKIP')

package() {
    install -Dm755 "$srcdir/cred-sync" "$pkgdir/usr/bin/cred-sync"
    install -Dm755 "$srcdir/onboard.sh" "$pkgdir/usr/bin/cred-sync-onboard"
    install -Dm755 "$srcdir/import.sh" "$pkgdir/usr/bin/cred-sync-import"
    install -Dm755 "$srcdir/launch.sh" "$pkgdir/usr/bin/cred-sync-launch"
    install -Dm755 "$srcdir/vault.sh" "$pkgdir/usr/lib/cred-sync-vault.sh"
    install -Dm644 "$srcdir/cred-sync.desktop" "$pkgdir/usr/share/applications/cred-sync.desktop"
} 