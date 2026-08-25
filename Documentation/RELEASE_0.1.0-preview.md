# Blusher 0.1.0 Preview

Blusher detects the two-hand 👉🏻👈🏻 gesture using Apple Vision. Face landmarks track the user's cheeks, and the blush effect animates smoothly in and out. The preview includes physical-camera capture, a native macOS interface, and entirely local processing.

## Important limitations

- This preview does **not** provide the system-wide “Blusher Camera” virtual camera. Apple's Personal Team provisioning service rejects the required System Extension capability. A provisioning configuration that supports Apple's System Extension capability is required to build and activate the preserved Camera Extension target.
- This archive is Apple Development / Personal Team signed. It is not Developer ID signed or notarized for normal public Gatekeeper distribution. It is primarily a development and technical preview and may require additional macOS approval or manual handling after download. Do not disable macOS security features.
- Sparkle update checking is intentionally disabled because a securely signed production appcast and Ed25519 release key are not yet provisioned.

## Requirements

- Apple Silicon Mac
- macOS 15 or later
- Camera permission

Version: `0.1.0` (`CFBundleVersion` 2)
