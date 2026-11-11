#!/usr/bin/env bats

setup() {
  source "$BATS_TEST_DIRNAME/../tools/lib/gates.sh"
  DIR="$BATS_TEST_TMPDIR/app"
  mkdir -p "$DIR"
  cat >"$DIR/PKGBUILD" <<'PKG'
pkgname=demo
pkgver=1.0
pkgrel=1
pkgdesc="Demo"
arch=('x86_64')
url="https://example.org/demo"
license=('MIT')
source=("https://example.org/demo-1.0.tar.gz")
sha256sums=('0000000000000000000000000000000000000000000000000000000000000000')
PKG
}

@test "G2 accepts an https source with a real checksum" {
  run gate_sources_pinned "$DIR"
  [ "$status" -eq 0 ]
}

@test "G2 rejects a plain http source" {
  sed -i 's@https://example.org/demo-1.0.tar.gz@http://example.org/demo-1.0.tar.gz@' "$DIR/PKGBUILD"
  run gate_sources_pinned "$DIR"
  [ "$status" -ne 0 ]
  [[ "$output" == *"http"* ]]
}

@test "G2 rejects SKIP on a non-VCS source" {
  sed -i "s@sha256sums=('0*')@sha256sums=('SKIP')@" "$DIR/PKGBUILD"
  run gate_sources_pinned "$DIR"
  [ "$status" -ne 0 ]
  [[ "$output" == *"SKIP"* ]]
}

@test "G2 rejects a git source with no pinned commit" {
  sed -i 's@source=(.*)@source=("git+https://example.org/demo.git")@' "$DIR/PKGBUILD"
  sed -i "s@sha256sums=('0*')@sha256sums=('SKIP')@" "$DIR/PKGBUILD"
  run gate_sources_pinned "$DIR"
  [ "$status" -ne 0 ]
  [[ "$output" == *"commit"* ]]
}

@test "G2 accepts a git source pinned to a commit" {
  sed -i 's@source=(.*)@source=("git+https://example.org/demo.git#commit=abc123")@' "$DIR/PKGBUILD"
  sed -i "s@sha256sums=('0*')@sha256sums=('SKIP')@" "$DIR/PKGBUILD"
  run gate_sources_pinned "$DIR"
  [ "$status" -eq 0 ]
}

@test "G9 requires a licence" {
  run gate_licence "$DIR"
  [ "$status" -eq 0 ]
  sed -i "s@license=('MIT')@license=('unknown')@" "$DIR/PKGBUILD"
  run gate_licence "$DIR"
  [ "$status" -ne 0 ]
}

@test "G8 fails when there is no metainfo file at all" {
  run gate_metainfo "$DIR"
  [ "$status" -ne 0 ]
  [[ "$output" == *"metainfo"* ]]
}

@test "G4 flags a build() that curls at build time" {
  cat >>"$DIR/PKGBUILD" <<'PKG'
build() {
  curl -sL https://example.org/setup.sh | sh
}
PKG
  run build_uses_network "$DIR"
  [ "$status" -eq 0 ]
  [[ "$output" == *"curl"* ]]
}

@test "G4 flags wget, git and pip in build()" {
  for tool in wget git pip; do
    cp "$DIR/PKGBUILD" "$DIR/PKGBUILD.bak"
    printf 'build() {\n  %s install thing\n}\n' "$tool" >>"$DIR/PKGBUILD"
    run build_uses_network "$DIR"
    [ "$status" -eq 0 ]
    mv "$DIR/PKGBUILD.bak" "$DIR/PKGBUILD"
  done
}

@test "G4 passes a build() that only compiles" {
  cat >>"$DIR/PKGBUILD" <<'PKG'
build() {
  cd "$pkgname-$pkgver"
  make
}
PKG
  run build_uses_network "$DIR"
  [ "$status" -ne 0 ]
}

@test "G4 ignores network tools mentioned outside build functions" {
  sed -i '1i # upstream is fetched with curl by the maintainer' "$DIR/PKGBUILD"
  cat >>"$DIR/PKGBUILD" <<'PKG'
build() {
  make
}
PKG
  run build_uses_network "$DIR"
  [ "$status" -ne 0 ]
}

mkpkg() {   # build a minimal .pkg.tar.zst containing the given paths
  local out=$1; shift
  local root="$BATS_TEST_TMPDIR/pkgroot.$$"
  rm -rf "$root"; mkdir -p "$root"
  printf 'pkgname = demo\npkgver = 1.0-1\narch = x86_64\n' >"$root/.PKGINFO"
  local p
  for p in "$@"; do
    mkdir -p "$root/$(dirname "$p")"
    printf 'x' >"$root/$p"
  done
  ( cd "$root" && bsdtar --zstd -cf "$out" .PKGINFO "${@}" )
}

@test "G6 accepts a package that stays in /usr" {
  mkpkg "$BATS_TEST_TMPDIR/ok.pkg.tar.zst" usr/bin/demo usr/share/metainfo/demo.xml
  run gate_filesystem_policy "$BATS_TEST_TMPDIR/ok.pkg.tar.zst"
  [ "$status" -eq 0 ]
}

@test "G6 rejects a file outside /usr, /opt and /etc" {
  mkpkg "$BATS_TEST_TMPDIR/bad.pkg.tar.zst" usr/bin/demo var/lib/demo/state
  run gate_filesystem_policy "$BATS_TEST_TMPDIR/bad.pkg.tar.zst"
  [ "$status" -ne 0 ]
  [[ "$output" == *"var/lib"* ]]
}

@test "G6 rejects a sudoers drop-in without the privileged flag" {
  mkpkg "$BATS_TEST_TMPDIR/sudo.pkg.tar.zst" usr/bin/demo etc/sudoers.d/demo
  run gate_filesystem_policy "$BATS_TEST_TMPDIR/sudo.pkg.tar.zst"
  [ "$status" -ne 0 ]
  [[ "$output" == *"sudoers"* ]]
}

@test "G6 allows a sudoers drop-in when the PR is flagged for privilege review" {
  mkpkg "$BATS_TEST_TMPDIR/sudo.pkg.tar.zst" usr/bin/demo etc/sudoers.d/demo
  run gate_filesystem_policy "$BATS_TEST_TMPDIR/sudo.pkg.tar.zst" --allow-privileged
  [ "$status" -eq 0 ]
}

@test "G6 rejects a setuid binary even when privileged review is allowed" {
  local root="$BATS_TEST_TMPDIR/suid"; mkdir -p "$root/usr/bin"
  printf 'pkgname = demo\n' >"$root/.PKGINFO"
  printf 'x' >"$root/usr/bin/demo"; chmod 4755 "$root/usr/bin/demo"
  ( cd "$root" && bsdtar --zstd -cf "$BATS_TEST_TMPDIR/suid.pkg.tar.zst" .PKGINFO usr )
  run gate_filesystem_policy "$BATS_TEST_TMPDIR/suid.pkg.tar.zst" --allow-privileged
  [ "$status" -ne 0 ]
  [[ "$output" == *"setuid"* ]]
}
