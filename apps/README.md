# Submitting to the CyberOS app store

Everything students install comes through here, and everything here was reviewed. This is
why CyberOS does not simply enable the AUR: AUR PKGBUILDs are unreviewed shell scripts
that run as your user.

## What you submit

A pull request adding one directory:

    apps/<pkgname>/
    ├── PKGBUILD
    ├── <pkgname>.metainfo.xml
    └── SUBMISSION.md

Copy `apps/template/` to start.

## Apps and plugins

Both are pacman packages in the same repository. They differ in two things:

|          | App                   | Plugin                        |
|----------|-----------------------|-------------------------------|
| Name     | the upstream name     | `cyberos-plugin-<name>`       |
| AppStream `type` | `desktop-application` | `addon`               |

A plugin is a waybar module, an nvim colourscheme, a rofi menu, a lab exercise pack.

## Check it before you open the pull request

    ./tools/verify-submission.sh apps/<pkgname>

Every gate must pass. CI runs the same script, and a pull request that fails a gate is not
reviewed by a human — reviewer attention is for judgement, not for catching what a script
catches.

## The gates

| | Checks |
|---|---|
| G1 | `namcap` on the PKGBUILD |
| G2 | sources are https with a checksum, or git pinned to a commit |
| G3 | it builds in a clean chroot |
| G4 | the build does not touch the network after fetching sources |
| G5 | `namcap` on the built package |
| G6 | no setuid/setgid; nothing outside `/usr`, `/opt`, `/etc` |
| G7 | `clamscan` over the payload |
| G8 | `appstreamcli validate` |
| G9 | a real licence |
| G10 | two maintainer approvals |

## After it is approved

Your package publishes to the **testing** channel first and promotes to **stable** on the
monthly cadence, alongside the OS. It does not go live on merge.
