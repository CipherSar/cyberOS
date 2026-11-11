# Branch: `store/app-market`

**State:** in progress (Tasks 1–4, 6 implemented and tested; Task 5 publishing awaits D1/D2) · **Owner:** store owner · **Spec:** `docs/SPEC.md` §5
**Plan:** `docs/superpowers/plans/2026-08-30-app-store.md`

## Charter

A department app store and plugin market where **every** published artifact was built in a
clean chroot, linted, scanned, and approved by two maintainers before a student can install
it. This is the reason CyberOS does not simply enable the AUR: AUR PKGBUILDs are
unreviewed shell scripts that run as your user.

## One mechanism, two catalogues

Apps and plugins are both pacman packages in `[cyberos-apps]`. Plugins are named
`cyberos-plugin-<name>` and declare AppStream component type `addon`; apps declare
`desktop-application`. There is no second packaging system, no second thing to secure.

A plugin is a waybar module, an nvim colourscheme, a rofi menu, a lab exercise pack — the
small things students and staff actually want to share.

## Scope

| Path | Role |
|---|---|
| `apps/<pkgname>/PKGBUILD` | submission |
| `apps/<pkgname>/<pkgname>.metainfo.xml` | AppStream catalogue entry |
| `apps/<pkgname>/SUBMISSION.md` | what it is, who wrote it, why |
| `tools/verify-submission.sh` | gates G1–G9, runs in CI and locally |
| `.github/workflows/verify-submission.yml` | CI entry point |
| `profile/airootfs/usr/local/bin/cyberos-store` | CLI + GTK4 client |

## The gates

Automated gates run first; **a PR that fails any of them is not reviewed by a human.**

| | Gate |
|---|---|
| G1 | `namcap PKGBUILD` |
| G2 | sources pinned and authenticated — no bare `http://`, no `SKIP` on a non-VCS source |
| G3 | builds in a clean chroot (`extra-x86_64-build`) |
| G4 | no network access during build, after sources are fetched |
| G5 | `namcap` on the built package |
| G6 | filesystem policy — no setuid/setgid; nothing outside `/usr`, `/opt`, `/etc`; anything in `sudoers.d`, `polkit-1/rules.d` or `systemd/system` needs an explicit privilege review |
| G7 | `clamscan` over the payload |
| G8 | `appstreamcli validate --explain` |
| G9 | licence present |
| G10 | **two** maintainer approvals |

## The rules that define this branch

- **`cyberos-store` implements no download or install logic.** pacman does that, with
  signature verification. The store is a browser over a repository.
- **Publication follows the OS channels.** Approved packages land in `testing` and promote
  to `stable` on the monthly cadence, not on merge.
- Reuse the installer's GTK4/libadwaita stack. Those packages are already in
  `packages.x86_64`; do not add a second toolkit.

## Depends on

`channels/release-engineering` for the promotion mechanism, and on decisions D1 and D2
(repo hosting, signing key custody) in `docs/SPEC.md` §9.
