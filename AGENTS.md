# Development rules for this template

## Goals

- Keep iOS, macOS, watchOS, tvOS, and visionOS independently buildable.
- Treat iPhone Duo as an adaptive iOS form factor, not a sixth SDK or standalone target.
- Build every platform through GitHub Actions; do not require contributors to own a Mac.
- Reuse `SharedCore` for Foundation-only logic, and `Apps/Shared` for UI that genuinely fits all five platforms.

## Workflow

1. Work from `main` unless a change specifically requires review in a short-lived PR.
2. When editing `project.yml`, also update the app/CI/docs as applicable.
3. Run `swift test --package-path Packages/SharedCore` for pure logic changes.
4. Run the `Apple platform CI` GitHub Actions workflow to validate native targets. Linux checks alone do not prove SwiftUI compatibility.
5. If a macOS runner build cannot be executed, report **not run** honestly; never claim it passed.

## Safety

- Never commit signing identities, API keys, certificates, private keys, provisioning profiles, or generated archives.
- Never allow signing secrets in a pull-request workflow.
- Do not enable automatic App Store releases on regular pushes. Release stays manually dispatched and protected.
- Do not change one platform in a way that silently removes another target's support.
- Do not claim iPhone Duo hinge/posture testing has passed based on width responsiveness alone.

## Architecture

Use Swift 6, native SwiftUI views, `SharedCore` for business logic, and small platform-specific UI modules. Keep new third-party dependencies minimal and justify them. Preserve a clean, re-generatable `project.yml` source of truth.

