# From empty GitHub repository to Apple builds

This setup deliberately **does not require your personal Mac**. A GitHub-hosted macOS runner compiles with Apple's SDKs, and App Store Connect is accessible in the browser.

## 1. Create the GitHub repository

Choose your intended GitHub account and create an empty repository, for example `apple-platform-template`, with default branch `main`.

From the directory containing this template's files (not a new nested directory):

```bash
git init -b main
git add .
git commit -m "Initialize multi-platform Apple development template"
git remote add origin https://github.com/YOUR-ACCOUNT/apple-platform-template.git
git push -u origin main
```

In the repository settings, you may enable **Template repository** so future apps can be created from it instead of copied by hand.

## 2. Let the unsigned CI run

Open **Actions → Apple platform CI**. The workflow checks out the code on a hosted Apple-silicon Mac, selects Xcode 27.1, installs XcodeGen, generates the native project, runs Swift package tests, and compiles five unsigned application targets. Do **not** add developer credentials for this stage.

If a platform build fails because of an SDK or XcodeGen incompatibility, read the associated build log artifact. We should fix it before considering the template CI-ready.

The `xcode-27` GitHub Actions image is in preview as of October 2026. Monitor [GitHub's runner image manifest](https://github.com/actions/runner-images/blob/main/images/macos/xcode-27-arm64-Readme.md) for changes, including the move from Xcode 27.1 RC to stable. This workflow intentionally fails if no Xcode 27.1 installation is present.

## 3. Customize each target

Before distribution:

1. Set each `PRODUCT_BUNDLE_IDENTIFIER` in `project.yml` to a unique, account-controlled reverse-DNS ID. All five currently use **unusable placeholders** (`dev.example...`).
2. Update the app names, marketing versions, deployment targets, and `Apps/*` SwiftUI views.
3. Add production app icons and required privacy usage descriptions/entitlements. Review the Mac App Sandbox and any platform-specific capabilities.
4. Register the matching identifiers and create the relevant app records in [App Store Connect](https://appstoreconnect.apple.com/). Universal purchase is optional; independent apps might be more suitable for different product types.
5. Accept current developer agreements, including paid-app agreements and banking/tax forms if selling apps or subscriptions.

**WatchOS:** The starter creates a standalone watchOS app target. If your eventual app is an iPhone companion, redesign the pairing/embedding configuration rather than treating this target as already paired.

**iPhone Duo:** The same `iOSApp` runs on the folding iPhone. Xcode 27.1 Device Hub is needed to evaluate folded, unfolded, and rotating states; the starter only adjusts layout based on window width.

## 4. Prepare the protected release environment

Open **Settings → Environments → New environment**, call it `app-store`, and limit deployments to `main`. Configure required reviewers where your GitHub plan supports them. The template's release workflow refers to this exact environment name.

Create an **App Store Connect API key** with the privileges needed for signing and uploading builds. In [App Store Connect](https://appstoreconnect.apple.com/), open **Users and Access → Integrations → App Store Connect API** (the UI may evolve). Retain its Key ID, Issuer ID, and `.p8` private key securely. Use the least permissions that work; initially, Apple may require an Admin/Account Holder operation to set up signing resources.

Set these **environment secrets** (never repository variables, committed files, or chat messages):

| Secret name | Value |
| --- | --- |
| `APPLE_TEAM_ID` | Your Apple Developer Team ID |
| `APP_STORE_CONNECT_KEY_ID` | Key ID assigned to the API key |
| `APP_STORE_CONNECT_ISSUER_ID` | Issuer ID shown for your API key |
| `APP_STORE_CONNECT_PRIVATE_KEY_BASE64` | Base64 encoding of the entire downloaded `.p8` private key |

On Windows PowerShell, encode your **local** `.p8` file with `[Convert]::ToBase64String([IO.File]::ReadAllBytes('C:\\path\\AuthKey_XXXXXX.p8'))`. Paste that value **only into GitHub's secret editor**. Never print or send private key content to this chat.

Xcode supports API-key authentication and cloud-managed signing, but some App IDs/capabilities can require additional account provisioning. Apple may reject an automated archive until the account is correctly configured.

## 5. Upload a release candidate

1. Confirm the ordinary **Apple platform CI** workflow passes.
2. Go to **Actions → Upload Apple build to App Store Connect → Run workflow** on the `main` branch.
3. Pick one platform: `ios`, `macos`, `watchos`, `tvos`, or `visionos`.
4. Approve the protected environment if configured.
5. Wait for processing in App Store Connect and choose TestFlight or prepare the App Review submission in the browser.

The workflow uses `xcodebuild archive` plus `-exportArchive` with `destination=upload`. It **does not** automatically publish an app to customers, alter prices, or submit a version for App Review.

## 6. Reality checks

| Capability | GitHub Actions alone? | Additional validation |
| --- | --- | --- |
| Compile five native app targets | Yes, with macOS image and suitable SDKs | CI logs, warnings, archives |
| Shared logic unit tests | Yes | Swift Package tests |
| Basic simulator tests | Possible, with available runtimes | Simulator setup and reliability work |
| Visual interaction debugging | Limited | Device Hub or remote interactive Mac access |
| iPhone Duo folded layouts | Compile yes | Xcode 27.1 Device Hub and hardware |
| Watch sensors/fitness | Build yes | Physical Watch |
| Vision Pro hand/eye interactions | Build yes | Vision Pro hardware recommended |
| TV remote/focus experience | Build yes | Apple TV hardware recommended |
| TestFlight upload | Yes, after authorization | Signing assets, App Store record, tester setup |

## 7. Troubleshooting

- **Xcode 27.1 unavailable:** inspect the [runner image manifest](https://github.com/actions/runner-images), then update `scripts/select-xcode.sh` and the runner label deliberately.
- **Destination or SDK unavailable:** an individual platform runtime may be missing; install it with `xcodebuild -downloadPlatform ...` on the runner if supported. Be mindful of macOS runner disk and job time limits.
- **`xcodegen` error:** pin a known-good XcodeGen release and adjust `project.yml` to its current spec. Keep the generated `.xcodeproj` out of source control.
- **No provisioning profile/certificate:** verify the Apple program membership is active, App IDs exist, the API key can manage signing, and the requested capability is enabled.
- **Missing icon/privacy metadata:** add required assets and descriptions before attempting release.
- **High GitHub bill:** keep the single-runner serial build, avoid simulator-heavy tests on every commit, cache only when beneficial, and set a GitHub Actions spending budget.

## Official references

- [GitHub-hosted runners](https://docs.github.com/en/actions/reference/runners/github-hosted-runners)
- [Xcode 27 runner image](https://github.com/actions/runner-images/blob/main/images/macos/xcode-27-arm64-Readme.md)
- [XcodeGen project specification](https://github.com/yonaskolb/XcodeGen/blob/master/Docs/ProjectSpec.md)
- [Apple cloud signing](https://developer.apple.com/videos/play/wwdc2021/10204/)
- [Apple's App Store Connect upload documentation](https://developer.apple.com/help/app-store-connect/manage-builds/upload-builds/)
- [iPhone Duo preparation](https://developer.apple.com/news/?id=kkphp5qo)



## Project 01 — Oddmouth

To build the new iOS party-game scheme, use the ordinary Apple platform CI;
it now includes Oddmouth alongside the original five platform targets.
For a future protected App Store upload, choose the **oddmouth** release option.

Confirm ownership/registration of **com.cheshmakzanoon.oddmouth** in your Apple
team before using the sample bundle ID. The original five starter targets still
have distinct placeholder IDs. Oddmouth also needs a production icon,
screenshots, real-device/TestFlight verification, and the other launch work
in [Projects/01-Oddmouth/RELEASE_CHECKLIST.md](../Projects/01-Oddmouth/RELEASE_CHECKLIST.md).
