#!/usr/bin/env bats

@test "cyberos-store unit tests pass" {
  python3 "$BATS_TEST_DIRNAME/test_store.py"
}

@test "cyberos-store desktop file exists and is valid" {
  [ -f "$BATS_TEST_DIRNAME/../profile/airootfs/usr/share/applications/cyberos-store.desktop" ]
  grep -q 'Exec=cyberos-store --gui' "$BATS_TEST_DIRNAME/../profile/airootfs/usr/share/applications/cyberos-store.desktop"
}

@test "cyberos-store executable is tracked in profiledef.sh" {
  grep -q 'cyberos-store' "$BATS_TEST_DIRNAME/../profile/profiledef.sh"
}

@test "cyberos-store reports missing repository cleanly" {
  run python3 "$BATS_TEST_DIRNAME/../profile/airootfs/usr/local/bin/cyberos-store" --list
  [ "$status" -ne 0 ]
  [[ "$output" == *"cyberos-apps"* ]]
}
