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

GATES=(gate_pkgbuild_lint gate_sources_pinned gate_licence gate_metainfo)

failed=0
for g in "${GATES[@]}"; do
  printf '=== %s\n' "$g"
  if "$g" "$DIR"; then
    printf '    pass\n'
  else
    printf '    FAIL\n'
    failed=1
  fi
done

if (( failed )); then
  printf '\n%s gate(s) failed. A submission that fails a gate is not reviewed.\n' "${#GATE_FAILURES[@]}"
  exit 1
fi
printf '\nAll automated gates passed. Ready for two maintainer reviews.\n'
