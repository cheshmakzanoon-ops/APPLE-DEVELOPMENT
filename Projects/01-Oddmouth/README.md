# Project 01 — Oddmouth

**Oddmouth** is an original one-phone, offline bluffing party game for iPhone and iPad.
One person sees a closely related but different word; optionally another sees no word.
Everyone speaks under the same eccentric **pressure prompt**. In the original Hot Seat
mode, the room privately nominates a suspect, hears a timed defense, and secretly
votes again. The nominations can be completely overturned.

It shares no branding, wording, assets, code, or word lists with Undercover.
"Oddmouth" is a working brand name pending App Store and trademark clearance.

## The playable game now

1. Create a table of 3–12 players, choose an included deck or one of your own house decks.
2. Choose the optional blank role, Hot Seat on/off, and a 90–240 second clue timer.
3. Pass one phone around; each person reveals and re-hides only their own card.
4. Each player gives a clue under the round's shared pressure prompt.
5. **Hot Seat mode:** everybody secretly nominates one other player. The leading
   nominee faces one of 12 new interrogation challenges for 30 seconds. Nomination
   ties are broken by the rotating speaker order to keep the round moving.
6. Everyone privately casts a new final ballot; a player may change their mind.
   With Hot Seat disabled, proceed directly from clues to final voting.
7. Reveal the two words, every role, only the *aggregated* nomination and vote
   totals, how many people switched, and the running scoreboard.
8. Play another round without immediately repeating the last word pair.

### The house-deck editor

Write any 3–120 pairs in the form *common word | nearby alternate*. Name the
deck, save it, select it for your game, edit it later, or delete it with a
confirmation. Validation catches missing separators, duplicate or identical
words, and oversized inputs. House decks stay in local device storage.

### Rules and scoring

- Most players get a **common** word. One gets a **nearby** word. At five or
  more players, an optional **blank** player gets no word.
- Nominations *only* select the Hot Seat. They do not score points. The final
  ballot is entirely independent and remains secret until every vote is cast.
- Final ballots eliminate the one player with the most votes; ties eliminate nobody.
- Every voter who selected an oddmouth or blank player receives **2 points**.
- Each oddmouth or blank player not eliminated receives **3 points**.
- Scores continue over rounds. Hot Seat reveals only aggregate ballots and
  how many people changed their minds—not individual voting histories.

Four original built-in packs contain **120** word pairs, with **9** different
clue pressures and **12** interrogation challenges. Any group can add unlimited
house decks locally. The app works fully offline without any backend.

### An interrupted match stays playable

Match state (including hidden role assignments, scores, timing, and progress)
is saved on the device after each action. Reopening the app offers an explicit
**Resume the table** action. Private cards and ballot choices hide when the app
goes into the background; the clock pauses. No account or cloud sync is required.

## Architecture

| Path | Purpose |
| --- | --- |
| Projects/01-Oddmouth/iOS/OddmouthApp.swift | Separate native iOS app entry point |
| Projects/01-Oddmouth/iOS/OddmouthRootView.swift | Setup, house-deck editor, private handoffs, dual ballots, hot seat, results |
| Projects/01-Oddmouth/iOS/OddmouthStyle.swift | Original paper-and-ink SwiftUI identity
| Projects/01-Oddmouth/iOS/OddmouthSessionStore.swift | On-device match recovery |
| Projects/01-Oddmouth/iOS/PrivacyInfo.xcprivacy | Current no-tracking/no-collected-data manifest |
| Packages/SharedCore/Sources/SharedCore/OddmouthGame.swift | Foundation-only, deterministic, testable game rules |
| Packages/SharedCore/Sources/SharedCore/OddmouthDeck.swift | Offline original word pairs
| Packages/SharedCore/Sources/SharedCore/OddmouthHousePack.swift | House-deck validation and local persistence
| Packages/SharedCore/Sources/SharedCore/OddmouthHouseTransfer.swift | Offline export/import codec with revalidation and size limits |
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

## Next release work

Native iOS CI tests game rules and compiles the SwiftUI target. These checks
do **not** replace a physical iPhone/iPad playtest. The next gates are a
professionally exported production icon, VoiceOver and dynamic-type review,
20 real group sessions to tune rules and onboarding, App Store/trademark name
clearance, and manual signing/TestFlight/App Store review. StoreKit 2 is **not**
wired up yet; the game does not display a pretend paywall.
