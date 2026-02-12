# Maintainer: mitanjan
pkgname=hack-do
pkgver=1.0.0
pkgrel=1
pkgdesc="A Matrix-themed task manager built with Flutter"
arch=('x86_64')
url=""
license=('MIT')
depends=('gtk3' 'glib2')
makedepends=('flutter-bin')
source=()

build() {
  cd "$startdir"
  flutter clean
  flutter pub get
  flutter build linux --release
}

package() {
  cd "$startdir"

  # Install the entire bundle to /opt/hack-do
  install -dm755 "$pkgdir/opt/hack-do"
  cp -r build/linux/x64/release/bundle/* "$pkgdir/opt/hack-do/"

  # Symlink binary to /usr/bin
  install -dm755 "$pkgdir/usr/bin"
  ln -s /opt/hack-do/hack_do "$pkgdir/usr/bin/hack-do"

  # Install desktop entry
  install -Dm644 hack-do.desktop "$pkgdir/usr/share/applications/hack-do.desktop"

  # Install license
  install -Dm644 LICENSE "$pkgdir/usr/share/licenses/$pkgname/LICENSE"
}
