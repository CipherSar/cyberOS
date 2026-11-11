# CyberOS branches

Every branch in this repository has a charter file here. If you are about to create a
branch, add its charter in the same commit as the first piece of work.

## Rules

1. `main` is protected. It is always releasable and only receives merges via pull request.
2. Branch names are `<area>/<topic>`. The area matches a `CODEOWNERS` section so the right
   reviewer is requested automatically.
3. A branch owns **one** area of `profile/`. If your change spans two areas, that is two
   branches and two pull requests.
4. Branches are short-lived. Merge or close within a term; a branch older than that is
   rebased or abandoned, not left to rot.
5. Rebase onto `main` before opening the PR. Do not merge `main` into your branch.

## Current branches

| Branch | State | Charter |
|---|---|---|
| `main` | protected, releasable | [main.md](main.md) |
| `installer/gui` | merged (PR #2) | [installer-gui.md](installer-gui.md) |
| `theme/macos-palette` | merged (PR #3) | [theme-macos-palette.md](theme-macos-palette.md) |
| `docs/spec` | merged (PR #4) | [docs-spec.md](docs-spec.md) |
| `theme/foot-portal` | merged (PR #5) | see the "Follow-up work" note in [theme-macos-palette.md](theme-macos-palette.md) — no separate charter was opened for this one |
| `security/hardening` | merged (PR #6) | [security-hardening.md](security-hardening.md) |
| `hardware/enablement` | merged (PR #7) | [hardware-enablement.md](hardware-enablement.md) |
| `theme/lua-config` | merged (PR #8) | see the "Follow-up work" note in [theme-macos-palette.md](theme-macos-palette.md) — no separate charter was opened for this one |
| `shell/quickshell` | merged (PR #9) | [shell-quickshell.md](shell-quickshell.md) |
| `packages/repo-publishing` | open, PR #1 closed unmerged | [packages-repo-publishing.md](packages-repo-publishing.md) |
| `docs/contributor-guidance` | merged into `main` | [docs-contributor-guidance.md](docs-contributor-guidance.md) |
| `channels/release-engineering` | open, in progress | [channels-release-engineering.md](channels-release-engineering.md) |
| `store/app-market` | open, in progress | [store-app-market.md](store-app-market.md) |

## Planned branches

These implement `docs/SPEC.md` and do not exist yet.

| Branch | Charter | Plan |
|---|---|---|
| `docs/handbook` | [docs-handbook.md](docs-handbook.md) | — |

## Naming reference

| Area | Owns | Reviewer |
|---|---|---|
| `installer/` | `usr/local/bin/cyberos-install*` | installer owner |
| `theme/` | `etc/skel/.config/`, `usr/share/sddm/`, `usr/share/backgrounds/`, `assets/` | theme owner |
| `packages/` | `profile/packages.x86_64`, `aur/`, `packages/` | packages owner |
| `channels/` | `tools/`, channel client, pacman configuration | release engineer |
| `store/` | `cyberos-store`, submission CI, AppStream catalogue | store owner |
| `hardware/` | kernel set, boot entries, drivers, firmware | hardware owner |
| `security/` | `sshd_config.d/`, `ufw`, signing, audit | security owner |
| `docs/` | `README.md`, `docs/` | docs owner |
