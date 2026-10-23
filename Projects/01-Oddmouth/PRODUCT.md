# Oddmouth — product direction

## The pitch

A beautiful little social game that makes *how you say a clue* just as important
as *what you know*. One phone, three or more people, no accounts, no awkward setup.

**Tone:** sly, human, playful, a little mischievous. Think an old gig poster
and a scandalous note passed across a restaurant table. Avoid glossy gradients,
purple neon, stock spy imagery, and AI-generated detective clichés.

**Name:** Oddmouth (working title). Short, strange in a good way, and directly
connected to the one person whose clue sounds subtly wrong. Perform an
independent trademark and App Store-title check before registration/release.

## Why this is more than a lookalike

| Player need | Project 01 answer |
| --- | --- |
| Party energy without rules lectures | All roles revealed through a private pass-and-hide flow |
| Rounds don't all sound the same | 9 pressure prompts change the clue-giving constraint |
| Entertaining players who don't know each other | Four authored packs with accessible, conversational words |
| Fair use of one phone | Private reveal, protected ballot handoffs, no individual-voter visibility |
| Instant replay | Immediate-repeat prevention, persistent match and score recovery |
| Function without internet | All game logic, cards, results, and house decks remain local |

## Initial art direction

- **Paper:** warm ivory (#F7F2E3).
- **Ink:** nearly black (#212421).
- **Accent:** vermilion (#FA4F3D).
- **Secondary:** acidic chartreuse (#D6F25E), dusty blue (#6199E6).
- **Typography:** large, dense rounded grotesk headlines; compact monospace
  kicker labels; deliberately asymmetric but readable hierarchy.
- **Signature mark:** a crooked red mouth, one misplaced tooth.
- **Motion goal:** energetic card snaps, tiny paper shifts, controlled haptics;
  honor Reduce Motion and VoiceOver.
- **Sound goal:** optional short percussive UI punctuation; allow silent play.

## Launch tiers

### Current development milestone

Playable offline core now includes four authored packs, 9 clue-pressure cards,
12 cross-examination challenges, independent secret nomination/final ballots,
local house-deck editor, offline exchangeable deck codes, flexible clue timer,
and resumable matches. No backend.
Still gather 20 group play sessions, tune confusion/stall points, and test
VoiceOver, private-card handoffs, timer pacing and the hot seat on real devices.
A successful compile is not evidence of an enjoyable party.

### Paid expansion (later)

A clear, optional one-time **Big Mouth Pack** with additional themed word
pairs and pressure prompts. Use StoreKit 2 with real App Store Connect
products and restore-purchase behavior. Never block already-purchased content.

### Future original modes

- **Hot Seat (implemented):** a privately nominated player gets 30 seconds to defend, followed by independent final ballots.
- **Second thoughts:** one unanimous table veto per match, logged visibly.
- **Duet:** two opponents must respond to one jointly chosen pressure card.
- **House rules (editor implemented):** editable local custom packs; codes can be shared explicitly through the system share sheet;
  nearby-device live game synchronization remains future work.

## Ethical and App Store boundaries

- All 120 starter pairs are authored for this project. No third-party text scraping.
- Do not borrow competitor screenshots, branding, dialogue, or hidden assets.
- Avoid manipulative subscriptions, fake countdowns, or misleading paywalls.
- Resumable games now store player names, private role assignments and progress
  on-device in app preferences. No backend, analytics or remote sharing; review
  local data retention, device backups, and app-switcher privacy during QA.
- New analytics, identifiers, ads, or SDKs will require re-reviewing privacy
  documentation and App Store declarations.
