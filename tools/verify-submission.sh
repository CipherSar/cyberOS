#!/usr/bin/env bash
# verify-submission.sh <submission-dir>
#
# Run every automated gate over a submission. Used by CI and runnable locally
# before opening the pull request.
set -uo pipefail

HERE=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=lib/gates.sh
# shellcheck disable=SC1091
source "$HERE/lib/gates.sh"

DIR=${1:-}
[[ -d $DIR ]] || { printf 'usage: verify-submission.sh <submission-dir>\n' >&2; exit 2; }

STATIC_GATES=(gate_pkgbuild_lint gate_sources_pinned gate_licence gate_metainfo)
BUILD_GATES=(gate_clean_build)

failed=0
for g in "${STATIC_GATES[@]}"; do
  printf '=== %s\n' "$g"
  if "$g" "$DIR"; then printf '    pass\n'; else printf '    FAIL\n'; failed=1; fi
done

if (( failed )); then
  printf '\nStatic gates failed; not building. %s failure(s).\n' "${#GATE_FAILURES[@]}"
  exit 1
fi

OUTDIR=${OUTDIR:-$DIR/out}
for g in "${BUILD_GATES[@]}"; do
  printf '=== %s\n' "$g"
  if "$g" "$DIR" "$OUTDIR"; then printf '    pass\n'; else printf '    FAIL\n'; failed=1; fi
done

if (( failed == 0 )); then
  shopt -s nullglob
  for pkg in "$OUTDIR"/*.pkg.tar.zst; do
    for g in gate_package_lint gate_filesystem_policy gate_malware_scan; do
      printf '=== %s %s\n' "$g" "$(basename "$pkg")"
      if "$g" "$pkg" ${ALLOW_PRIVILEGED:+--allow-privileged}; then
        printf '    pass\n'
      else
        printf '    FAIL\n'; failed=1
      fi
    done
  done
fi

if (( failed )); then
  printf '\n%s gate(s) failed. A submission that fails a gate is not reviewed.\n' "${#GATE_FAILURES[@]}"
  exit 1
fi
printf '\nAll automated gates passed. Ready for two maintainer reviews.\n'
