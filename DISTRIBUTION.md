# Local Stitch Distribution Guide

This guide covers the admin and release steps for distributing Local Stitch as a free macOS app through GitHub DMG releases and, separately, through the Mac App Store.

## Current Project State

- Product name: `Local Stitch`
- Bundle identifier: `com.moeed.local-stitch`
- Category: Utilities
- Version: `1.0`
- Build: `1`
- Sandbox: enabled
- User-selected files: read/write
- Incoming network connections: disabled
- Outgoing network connections: disabled
- Universal architectures: Apple Silicon and Intel

The app currently builds successfully in Release configuration.

## Distribution Paths

Local Stitch has two different distribution paths:

1. **GitHub DMG release**
   - Build a Developer ID signed app.
   - Package it in a DMG.
   - Submit the DMG to Apple notarization.
   - Staple the notarization ticket.
   - Upload the final DMG to GitHub Releases.

2. **Mac App Store release**
   - Create an app record in App Store Connect.
   - Archive in Xcode.
   - Distribute through App Store Connect.
   - Complete App Store metadata and review.

The DMG path and App Store path use different distribution signing identities. A Developer ID signed DMG is for distribution outside the Mac App Store. The Mac App Store upload uses Apple distribution signing managed by Xcode/App Store Connect.

## Apple Developer Account Setup

### 1. Enroll Or Confirm Enrollment

You need an active Apple Developer Program membership for:

- Developer ID certificates.
- Notarization.
- Mac App Store submission.
- App Store Connect access.

If publishing under a company, confirm that the Apple Developer account is enrolled as the correct organization.

### 2. Add The Apple Account To Xcode

In Xcode:

1. Open Xcode.
2. Go to **Xcode > Settings > Accounts**.
3. Add the Apple Account tied to the developer membership.
4. Select the team.
5. Download or create signing certificates if prompted.

### 3. Select The Team In The Project

In Xcode:

1. Open `Local Stitch.xcodeproj`.
2. Select the `Local Stitch` project.
3. Select the `Local Stitch` target.
4. Open **Signing & Capabilities**.
5. Select the correct Team.
6. Keep **Automatically manage signing** enabled unless there is a specific reason not to.

Do not change the bundle identifier, sandbox, network entitlements, or release configuration without treating that as a deliberate release decision.

## Certificates Needed

For GitHub DMG distribution:

- **Developer ID Application** certificate.
  - Used to sign the `.app`.

For installer package distribution, which Local Stitch does not currently need:

- **Developer ID Installer** certificate.
  - Used for signed `.pkg` installers.

For App Store distribution:

- Xcode can usually manage Apple distribution signing automatically once the account and team are configured.

## Notarization Credentials

For command-line notarization, store credentials once in Keychain:

```sh
xcrun notarytool store-credentials "LocalStitchNotaryProfile" \
  --apple-id "APPLE_ID_EMAIL" \
  --team-id "TEAM_ID" \
  --password "APP_SPECIFIC_PASSWORD"
```

Use an app-specific password for the Apple Account. Do not commit passwords, API keys, or credential files to the repository.

## GitHub DMG Release Process

### 1. Confirm Signing Identity

After Xcode account setup, this should show a Developer ID Application identity:

```sh
security find-identity -v -p codesigning
```

Look for a line similar to:

```text
Developer ID Application: Your Name or Organization (TEAMID)
```

### 2. Clean And Archive

```sh
xcodebuild clean \
  -project "Local Stitch.xcodeproj" \
  -scheme "Local Stitch" \
  -configuration Release

xcodebuild archive \
  -project "Local Stitch.xcodeproj" \
  -scheme "Local Stitch" \
  -configuration Release \
  -destination "generic/platform=macOS" \
  -archivePath "build/Local Stitch.xcarchive"
```

### 3. Export Developer ID App

Create an export options file named `build/ExportOptions-DeveloperID.plist`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>method</key>
  <string>developer-id</string>
  <key>signingStyle</key>
  <string>automatic</string>
  <key>stripSwiftSymbols</key>
  <true/>
</dict>
</plist>
```

Then export:

```sh
xcodebuild -exportArchive \
  -archivePath "build/Local Stitch.xcarchive" \
  -exportPath "build/export" \
  -exportOptionsPlist "build/ExportOptions-DeveloperID.plist"
```

### 4. Verify App Signature

```sh
codesign --verify --deep --strict --verbose=2 "build/export/Local Stitch.app"
spctl --assess --type execute --verbose=4 "build/export/Local Stitch.app"
```

Before notarization, `spctl` may not fully accept the app for distribution. After notarization and stapling, it should.

### 5. Create A DMG

Create a staging folder:

```sh
rm -rf "build/dmg-root"
mkdir -p "build/dmg-root"
cp -R "build/export/Local Stitch.app" "build/dmg-root/"
ln -s /Applications "build/dmg-root/Applications"
```

Create the compressed DMG:

```sh
hdiutil create \
  -volname "Local Stitch" \
  -srcfolder "build/dmg-root" \
  -ov \
  -format UDZO \
  "build/Local-Stitch-1.0.dmg"
```

### 6. Notarize The DMG

```sh
xcrun notarytool submit "build/Local-Stitch-1.0.dmg" \
  --keychain-profile "LocalStitchNotaryProfile" \
  --wait
```

If notarization fails, inspect the log:

```sh
xcrun notarytool log SUBMISSION_ID \
  --keychain-profile "LocalStitchNotaryProfile"
```

### 7. Staple The Notarization Ticket

```sh
xcrun stapler staple "build/Local-Stitch-1.0.dmg"
xcrun stapler validate "build/Local-Stitch-1.0.dmg"
```

### 8. Final Gatekeeper Verification

```sh
spctl --assess --type open --verbose=4 "build/Local-Stitch-1.0.dmg"
```

You can also mount the DMG, copy the app to `/Applications`, and launch it on a clean test Mac or fresh user account.

## Mac App Store Process

### 1. Create App Record

In App Store Connect:

1. Go to **Apps**.
2. Create a new macOS app record.
3. Use the bundle identifier `com.moeed.local-stitch`.
4. Set price to free.
5. Add category, screenshots, support URL, privacy details, and review notes.

### 2. Archive In Xcode

In Xcode:

1. Select **Any Mac** as the run destination.
2. Choose **Product > Archive**.
3. Open Organizer.
4. Select the archive.
5. Click **Distribute App**.
6. Choose App Store Connect distribution.

### 3. App Store Metadata

Recommended positioning:

- Free private PDF stitching for Mac.
- Merge PDFs locally.
- Prepare PDFs for AI-assisted review.
- No account.
- No cloud upload.
- No subscription.

Avoid implying legal advice or guaranteed legal compliance.

### 4. Privacy Nutrition Label

Based on the current app behavior, the App Store privacy answers should reflect:

- No account creation.
- No tracking.
- No third-party analytics.
- No data collection.
- No network upload of documents.

Review the actual binary and any future dependencies before submitting; the privacy answers must match the shipped app.

## Release Checklist

- [ ] Confirm `MARKETING_VERSION` and `CURRENT_PROJECT_VERSION`.
- [ ] Confirm bundle identifier is correct.
- [ ] Confirm Team is selected in Xcode.
- [ ] Confirm Developer ID Application certificate is installed.
- [ ] Confirm sandbox remains enabled.
- [ ] Confirm incoming and outgoing network entitlements remain disabled.
- [ ] Build Release configuration.
- [ ] Archive for Developer ID.
- [ ] Export signed app.
- [ ] Verify code signature.
- [ ] Create DMG.
- [ ] Submit DMG for notarization.
- [ ] Staple notarization ticket.
- [ ] Verify DMG with Gatekeeper.
- [ ] Smoke test on another Mac or clean macOS user account.
- [ ] Upload DMG to GitHub Releases.
- [ ] Keep release notes simple and user-facing.

## Current Blockers Before A Real Public DMG

- No valid local code-signing identities are currently available in Keychain.
- Xcode currently needs the Apple Developer team connected before Developer ID signing can work.
- Notarization credentials need to be stored locally before command-line notarization can run.
