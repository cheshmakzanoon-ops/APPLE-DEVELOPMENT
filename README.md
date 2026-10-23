# Apple Platform Template

A macOS-runner-first SwiftUI starter for **iOS/iPadOS, macOS, watchOS, tvOS, and visionOS**. The iOS target also includes a width-adaptive starting point for **iPhone Duo**. No personal Mac is required to author code or trigger CI.

> Status: starter scaffold. Code-signing credentials, App Store records, icons, and real-device validation are required before release. The CI builds use `CODE_SIGNING_ALLOWED=NO` and do not access Apple credentials.

## Project map

| Path | Purpose |
| --- | --- |
| `project.yml` | Reproducible Xcode project definition (XcodeGen) |
| `Packages/SharedCore` | Foundation-only shared behavior and unit tests |
| `Apps/Shared` | Shared SwiftUI welcome screen |
| `Apps/iOS` | iPhone, iPad, and iPhone Duo adaptive UI |
| `Apps/macOS` | Native macOS entry point |
| `Apps/watchOS` | Standalone watchOS entry point |
| `Apps/tvOS` | Native Apple TV entry point |
| `Apps/visionOS` | Native Vision Pro entry point |
| `.github/workflows/ci.yml` | All-platform unsigned builds and shared-core tests |
| `.github/workflows/release.yml` | Guarded, manually dispatched App Store Connect upload |
| `scripts/` | Xcode selection, platform builds, and release helper |
| `docs/SETUP.md` | Instructions for your GitHub account and Apple credentials |

## Development workflow

1. Edit Swift sources from any operating system, including Windows, Chromebook, or Linux.
2. Push to GitHub. GitHub Actions uses an Apple-silicon `xcode-27` hosted runner with Xcode 27.1 for iPhone Duo readiness.
3. The CI workflow regenerates the Xcode project, tests `SharedCore`, and compiles six native app targets (the five platform templates plus Oddmouth) **without code signing**.
4. When ready to distribute, configure Apple signing/API credentials and an App Store Connect app record, then run the protected manual release workflow for **one** platform at a time.

The template contains no third-party runtime dependencies. It uses XcodeGen only to produce `.xcodeproj` on macOS; that generated directory is intentionally not committed.

## Local macOS commands (optional)

```bash
brew install xcodegen
xcodegen generate --spec project.yml
swift test --package-path Packages/SharedCore
xcodebuild -project ApplePlatformTemplate.xcodeproj -scheme iOSApp -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build
```

## Before releasing

Read [docs/SETUP.md](docs/SETUP.md). At minimum, replace placeholder bundle IDs, confirm account enrollment and API-key permissions, create corresponding app records, add production app icons, enable the necessary entitlements, and test on real devices.

### iPhone Duo

`iPhone Duo` is not a sixth OS; it runs iOS. The `iOSApp` example changes its layout at a width breakpoint using `AdaptiveLayout`. It does **not** claim hinge/posture API coverage. Validate unfolded/folded poses and transitions using Xcode 27.1 Device Hub and, eventually, real hardware.

### Why the platforms are separate

Each platform has a distinct native `@main` app target, while pure Swift logic and simple UI are shared. This avoids forced UI parity where a remote, watch crown, spatial controls, or Mac menus demand different interaction models.

## Security defaults

- CI cannot sign or release.
- Release is manually dispatched behind GitHub's `app-store` environment; configure required reviewers in your repository settings.
- API private keys live in GitHub environment secrets, never in source control or build artifacts.
- Job permissions are read-only; no untrusted pull-request code can access signing secrets.
- CI won't silently pass on missing Xcode 27.1 or absent platform SDKs.

## Known verification limits

This repository must be run on GitHub's hosted macOS environment before it can be marked build-verified; a Linux checkout cannot compile SwiftUI or boot Apple simulators. The release workflow also requires real Apple account authorization and an App Store Connect app record.


## Project 01: Oddmouth

**[Oddmouth](Projects/01-Oddmouth/README.md)** is the repository's first iOS/iPadOS commercial-app project: a fully offline, one-phone social bluffing game, with original ink-and-paper styling and a native SwiftUI app.

The version on main includes:

- 3–12 player matches, 120 original word pairs across four built-in packs, and 9 clue constraints.
- **The Hot Seat:** secret nominations, one of 12 timed challenges, and a wholly new final ballot. Players can reverse their vote; only anonymous totals and vote-switch counts are revealed.
- **House decks:** author, edit, save, delete, and select custom decks with 3–120 word pairs. Share an encoded deck through iOS ShareLink or import a validated code entirely offline.
- **Privacy and resilience:** concealed private roles during handoffs, protected ballot transitions, automatic hide on background, configurable timers, and saved/resumable matches.
- A Foundation-only Swift game engine with deterministic unit tests and no third-party runtime dependencies.

**Source:** [iOS SwiftUI app](Projects/01-Oddmouth/iOS/) · [game engine](Packages/SharedCore/Sources/SharedCore/OddmouthGame.swift) · [house-deck transfer](Packages/SharedCore/Sources/SharedCore/OddmouthHouseTransfer.swift) · [test suite](Packages/SharedCore/Tests/SharedCoreTests/OddmouthGameTests.swift)

**Build:** The `Oddmouth` XcodeGen scheme compiles unsigned in the same GitHub Actions workflow as the five existing platform apps; the manual protected release workflow includes an `oddmouth` selection.

An unsigned simulator build is a development milestone, not an App Store launch: signing, app icon, bundle registration, device testing, name clearance, and TestFlight are still pending. See the [release checklist](Projects/01-Oddmouth/RELEASE_CHECKLIST.md).
