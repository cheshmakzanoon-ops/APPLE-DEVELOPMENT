# Oddmouth — release readiness

## Engineering

- [x] GitHub Actions SharedCore tests pass on the macOS runner. ([CI run 39904296644](https://github.com/cheshmakzanoon-ops/APPLE-DEVELOPMENT/actions/runs/39904296644))
- [x] Unsigned Oddmouth iOS Simulator build succeeds. ([CI run 39904296644](https://github.com/cheshmakzanoon-ops/APPLE-DEVELOPMENT/actions/runs/39904296644))
- [ ] Physically smoke-test 3, 5, 8, and 12 players across consecutive rounds.
- [ ] Test oddmouth-only and optional blank-card sessions.
- [ ] Confirm no private words remain displayed during phone handoff.
- [ ] Test ties, correct detection, all players voting, and scores.
- [ ] Check Dynamic Type, Reduce Motion, VoiceOver, and minimum touch sizes.
- [ ] On a physical device, test interruption/background/foreground, rotation, and iPad width.
- [ ] On a physical device, test Hot Seat nominations, defense timing, changed votes, and ballot privacy.
- [ ] On a physical device, share a deck through the system sheet, import it, and verify saved edits.
- [ ] On a physical device, terminate/relaunch mid-round and verify concealed private words and accurate recovery.
- [ ] Test fold/unfold transitions on iPhone Duo hardware or Device Hub.
- [ ] Conduct at least 20 sessions with real groups and fix confusing steps.

## Store assets and policy

- [ ] Finalize brand clearance and App Store name availability (Oddmouth is provisional).
- [ ] Create an original 1024×1024 App Store icon and complete asset catalog.
- [ ] Confirm the final bundle ID in project.yml and register it to your team.
- [ ] Create an App Store Connect record and complete app age rating.
- [ ] Capture honest device screenshots and optional preview video.
- [ ] Publish support URL, privacy policy, and marketing copy.
- [ ] Recheck privacy manifest if collecting anything or integrating third-party SDKs.
- [ ] Complete Apple paid-app contracts/tax/banking if monetizing.
- [ ] Do not advertise subscriptions or IAP until StoreKit products work.

## Distribution

- [ ] Set up the protected GitHub environment and signing API credentials.
- [ ] Run the manually dispatched Oddmouth archive/upload workflow.
- [ ] Inspect TestFlight processing warnings and install on a real iPhone.
- [ ] Invite testers and resolve crashes and onboarding issues.
- [ ] Submit explicitly for App Review when release candidate is ready.

Checked items above have the linked CI evidence. Simulator compilation and unit tests do not prove device UX or App Store readiness.
