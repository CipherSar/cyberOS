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
