## What is this?

<!-- One or two sentences. -->

## Checklist

- [ ] `./tools/verify-submission.sh apps/<pkgname>` passes locally
- [ ] The branch is rebased on `main`, not merged from it
- [ ] A charter for this branch exists in `docs/branches/`

## Privilege review

- [ ] This package installs **nothing** in `/etc/sudoers.d`, `/etc/polkit-1/rules.d`, or a
      systemd unit directory

If that box is unchecked, say exactly what it installs and why. Privileged submissions
need the same two approvals plus a note in the review from each approver confirming they
read the privileged file.
