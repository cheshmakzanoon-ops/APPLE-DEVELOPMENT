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
| Fair use of one phone | Private handoffs, secret ballots, no vote visibility before results |
| Instant replay | Round history avoids immediate word repeats; persistent match scores |
| Function without internet | All game logic, cards, and results remain local |

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

### First ship

Offline core with four included packs and 9 prompt cards. Gather 20 play
sessions and record where players get confused, stall, or quit. A good game
isn't proven by a compile or a mockup.

### Paid expansion (later)

A clear, optional one-time **Big Mouth Pack** with additional themed word
pairs and pressure prompts. Use StoreKit 2 with real App Store Connect
products and restore-purchase behavior. Never block already-purchased content.

### Future original modes

- **Cross-examination:** a voted player gets 20 seconds to defend their clue.
- **Second thoughts:** one unanimous table veto per match, logged visibly.
- **Duet:** two opponents must respond to one jointly chosen pressure card.
- **House rules:** custom word packs shared by nearby-device transport if
  enabled explicitly; never upload contacts or player names by default.

## Ethical and App Store boundaries

- All 120 starter pairs are authored for this project. No third-party text scraping.
- Do not borrow competitor screenshots, branding, dialogue, or hidden assets.
- Avoid manipulative subscriptions, fake countdowns, or misleading paywalls.
- In-app player names are held only in session memory. There is no backend.
- New analytics, identifiers, ads, or SDKs will require re-reviewing privacy
  documentation and App Store declarations.
