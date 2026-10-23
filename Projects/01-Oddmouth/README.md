# Project 01 — Oddmouth

**Oddmouth** is an original one-phone, offline bluffing party game for iPhone and iPad.
One person sees a closely related but different word; optionally another sees no word.
Everyone speaks under the same eccentric **pressure prompt**, then secretly votes on
who sounded wrong.

It shares no branding, wording, assets, code, or word lists with Undercover.
"Oddmouth" is a working brand name pending App Store and trademark clearance.

## Current playable flow

1. Add 3–12 players (blank card available at 5+); choose any of four original word packs.
2. Pass the phone around to view **private** word cards; hide each card before handing off.
3. Give clues in order while obeying the shared pressure prompt and watching a 90-second clock.
4. Pass the phone for **secret, one-vote-per-player** ballots; no self-voting.
5. Reveal every role and word, score the round, and play again with scores retained.
6. Avoid immediate repeats of the last word pair.

Four themed word packs contain **120** original pairs, plus nine pressure prompts.
No user accounts, online multiplayer, analytics, advertising, or paid backend are needed.

### Rules and scoring

- Most players get the **common** word.
- One player gets a **nearby** word without being explicitly labeled the impostor during reveal.
- With five or more players, the optional **blank** player receives no word.
- The person receiving the most votes is eliminated; ties eliminate no one.
- Every voter who selected an oddmouth or blank player receives **2 points**.
- Every oddmouth or blank player not eliminated receives **3 points**.
- Scores accumulate over rounds. All votes remain hidden until results.

A core differentiator is the *pressure card* applied to every speaker:
"Exactly three words", "Give the clue as a question", "Sell it badly", etc.
It varies the conversation even when a group knows the format.

## Architecture

| Path | Purpose |
| --- | --- |
| Projects/01-Oddmouth/iOS/OddmouthApp.swift | Separate native iOS app entry point |
| Projects/01-Oddmouth/iOS/OddmouthRootView.swift | Setup, handoff, clues, secret voting, reveal, scoreboard |
| Projects/01-Oddmouth/iOS/OddmouthStyle.swift | Original paper-and-ink SwiftUI identity |
| Projects/01-Oddmouth/iOS/PrivacyInfo.xcprivacy | Current no-tracking/no-collected-data manifest |
| Packages/SharedCore/Sources/SharedCore/OddmouthGame.swift | Foundation-only, deterministic, testable game rules |
| Packages/SharedCore/Sources/SharedCore/OddmouthDeck.swift | Offline original word pairs |
| Packages/SharedCore/Tests/SharedCoreTests/OddmouthGameTests.swift | Validation, secrecy, voting, scoring, repeat prevention |

The XcodeGen target is **Oddmouth**, distinct from the five platform-template targets.
The existing five remain independently buildable.

## Build and test without a personal Mac

Push to the main branch. The **Apple platform CI** GitHub Action uses a hosted
Apple-silicon macOS runner and invokes:

    brew install xcodegen
    xcodegen generate --spec project.yml
    swift test --package-path Packages/SharedCore
    xcodebuild -project ApplePlatformTemplate.xcodeproj -scheme Oddmouth -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build

You can also execute the same commands on a local Mac if available. The generated
Xcode project is ignored intentionally; edit the YAML and Swift files in GitHub.

### Release workflow

The protected **Upload Apple build to App Store Connect** workflow includes
a manually selected **oddmouth** option, but release still requires:

- An Apple Developer account, signed agreements, App Store Connect record,
  and the registered bundle identifier **com.cheshmakzanoon.oddmouth** (change
  the ID in project.yml if you don't control it).
- A production 1024px app icon asset catalog, complete metadata, accessibility
  and device verification, and App Privacy answers reflecting the shipped app.
- GitHub environment **app-store** with protected signing secrets as documented
  in the repository's docs/SETUP.md.

**Important:** Native SwiftUI UI builds and real-device behavior must be validated
by GitHub Actions and testing. No claim of successful native build is made just
by adding these source files.

## Next milestone

The initial project focuses on a complete offline game. Planned improvements:
editable round duration, localized packs, richer animations/haptics, family-
friendly and adults-only content partitioning, additional accessibility audit,
a professional app icon, TestFlight playtesting, and StoreKit 2 word-pack purchases
with server-verified entitlements where needed. **There is no paid button or
pretend purchase flow in this build.** See [PRODUCT.md](PRODUCT.md) and
[RELEASE_CHECKLIST.md](RELEASE_CHECKLIST.md).
