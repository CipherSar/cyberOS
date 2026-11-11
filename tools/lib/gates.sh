#!/usr/bin/env bash
# CyberOS submission gates.
#
# Each gate takes a submission directory, returns 0 to pass, and prints why it
# failed. A submission that fails ANY gate is not reviewed by a human -- the
# point is that reviewer attention is spent on judgement, not on catching things
# a script catches.

GATE_FAILURES=()

_fail() { printf '%s\n' "$*"; GATE_FAILURES+=("$*"); return 1; }

# G1 -- lint the PKGBUILD itself.
gate_pkgbuild_lint() {
  local dir=$1
  [[ -f $dir/PKGBUILD ]] || { _fail "G1: no PKGBUILD in $dir"; return 1; }
  command -v namcap >/dev/null || { _fail "G1: namcap is not installed"; return 1; }
  local out
  out=$(namcap "$dir/PKGBUILD" 2>&1) || true
  if grep -qE '\(E\)|ERROR' <<<"$out"; then
    _fail "G1: namcap errors on PKGBUILD:"$'\n'"$out"
    return 1
  fi
  return 0
}

# G2 -- every source must be authenticated: https with a checksum, or a git URL
# pinned to a commit. This is the gate that stops an upstream tarball being
# swapped out under us.
gate_sources_pinned() {
  local dir=$1 srcline sumline
  [[ -f $dir/PKGBUILD ]] || { _fail "G2: no PKGBUILD in $dir"; return 1; }
  srcline=$(grep -E '^[[:space:]]*source=' "$dir/PKGBUILD" || true)
  [[ -n $srcline ]] || return 0    # no sources is fine (meta packages)

  if grep -qE "(^|['\"( ])http://" <<<"$srcline"; then
    _fail "G2: source uses plain http; use https"
    return 1
  fi

  sumline=$(grep -E '^[[:space:]]*(sha256sums|b2sums)=' "$dir/PKGBUILD" || true)
  if grep -qE 'git\+' <<<"$srcline"; then
    if ! grep -qE '#(commit|tag)=' <<<"$srcline"; then
      _fail "G2: git source is not pinned to a commit or tag"
      return 1
    fi
    return 0
  fi

  [[ -n $sumline ]] || { _fail "G2: no sha256sums or b2sums"; return 1; }
  if grep -q "SKIP" <<<"$sumline"; then
    _fail "G2: SKIP checksum on a non-VCS source"
    return 1
  fi
  return 0
}

# G9 -- a package with no licence cannot be redistributed by the department.
gate_licence() {
  local dir=$1 line
  line=$(grep -E '^[[:space:]]*license=' "$dir/PKGBUILD" || true)
  [[ -n $line ]] || { _fail "G9: no license= in PKGBUILD"; return 1; }
  if grep -qiE "\('?(unknown|custom)'?\)" <<<"$line"; then
    _fail "G9: license is 'unknown' or bare 'custom'; name it, or use custom:<name> and ship the text"
    return 1
  fi
  return 0
}

# G8 -- the catalogue entry the store will render.
gate_metainfo() {
  local dir=$1 file
  file=$(find "$dir" -maxdepth 1 -name '*.metainfo.xml' | head -1)
  [[ -n $file ]] || { _fail "G8: no *.metainfo.xml in $dir"; return 1; }
  command -v appstreamcli >/dev/null || { _fail "G8: appstreamcli is not installed"; return 1; }
  local out
  if ! out=$(appstreamcli validate --explain "$file" 2>&1); then
    _fail "G8: appstreamcli rejected the metainfo:"$'\n'"$out"
    return 1
  fi
  return 0
}

# build_uses_network <dir> -- exit 0 if build() or package() reference a network
# tool. Curl-to-shell at build time is the classic supply-chain vector, and a
# reviewer reading a 400-line PKGBUILD will miss it.
build_uses_network() {
  local dir=$1 body tool
  # Extract only the bodies of build() and package(), so a comment or a source=
  # URL elsewhere does not trip the check.
  body=$(awk '
    /^[[:space:]]*(build|package|prepare)[[:space:]]*\(\)[[:space:]]*\{/ { depth=1; next }
    depth > 0 {
      depth += gsub(/\{/, "{") - gsub(/\}/, "}")
      if (depth <= 0) { depth = 0; next }
      sub(/#.*/, "")
      print
    }
  ' "$dir/PKGBUILD")

  for tool in curl wget git svn hg pip npm "cargo fetch" "go get"; do
    if grep -qE "(^|[;&|[:space:]])${tool}([[:space:]]|$)" <<<"$body"; then
      printf 'G4: build functions call %s -- the build must not touch the network\n' "$tool"
      return 0
    fi
  done
  return 1
}

# G3 + G4 -- build in a clean chroot with networking off after sources are
# fetched. If it does not build here, it does not build on a student machine.
gate_clean_build() {
  local dir=$1
  local outdir=${2:-$dir/out}
  if build_uses_network "$dir"; then
    _fail "G4: the build reaches the network"
    return 1
  fi
  command -v extra-x86_64-build >/dev/null \
    || { _fail "G3: devtools is not installed (need extra-x86_64-build)"; return 1; }

  mkdir -p "$outdir"
  local log="$outdir/build.log"
  if ! ( cd "$dir" && PKGDEST="$(cd "$outdir" && pwd)" \
           extra-x86_64-build -- -- --nocheck ) >"$log" 2>&1; then
    _fail "G3: clean-chroot build failed, see $log"$'\n'"$(tail -30 "$log")"
    return 1
  fi
  return 0
}

# G5 -- lint the built package, which catches what linting the recipe cannot:
# missing runtime deps, world-writable files, insecure RPATH.
gate_package_lint() {
  local pkgfile=$1 out
  [[ -f $pkgfile ]] || { _fail "G5: no package file at $pkgfile"; return 1; }
  out=$(namcap "$pkgfile" 2>&1) || true
  if grep -qE '\(E\)|ERROR' <<<"$out"; then
    _fail "G5: namcap errors on the built package:"$'\n'"$out"
    return 1
  fi
  return 0
}
