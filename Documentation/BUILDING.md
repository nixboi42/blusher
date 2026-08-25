# Building and release

Requirements: Apple Silicon Mac, macOS 15 or later, Xcode 16 or later, and XcodeGen. Building the full virtual-camera target additionally requires an Apple Developer team whose App ID enables System Extension and Camera Extension capabilities.

1. For a future production updater, add the public key emitted by Sparkle's `generate_keys` and the signed feed URL to the production Info.plist. Keep the private key in Keychain. Sparkle is intentionally disabled and omitted from `BlusherLocal` preview builds.
2. Set the development team in Xcode or pass `DEVELOPMENT_TEAM=…`.
3. Run `./Scripts/build.sh`. Install the resulting app in `/Applications` before requesting extension activation.

Camera Extensions require a properly provisioned signature and user approval in Login Items & Extensions. Ad-hoc signatures cannot activate one. Public releases additionally require Developer ID Application credentials, notarization credentials, and the matching entitlements/provisioning profile.

On 2026-08-26, Apple's automatic provisioning service rejected Team `J6UMA79JLS` with: “Personal development teams … do not support the System Extension capability.” `BlusherLocal` is therefore a separately provisioned preview that retains camera capture, Vision, rendering, and preview but does not embed or request activation of the Camera Extension. The full `Blusher` target and Camera Extension source remain intact for a team that authorizes System Extensions.

Before enabling updates in a future production release, generate an appcast with Sparkle's `generate_appcast` and sign every archive with the Keychain-held Ed25519 key. Never commit private keys. CI needs the Developer ID certificate/key, notarization keychain profile, and Sparkle private signing material as encrypted secrets.
