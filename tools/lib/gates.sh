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
