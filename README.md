# Blusher

Blusher is a native macOS camera experiment that recognizes the two-hand 👉🏻👈🏻 gesture and animates a blush over the user's tracked cheeks. Physical-camera capture, Apple Vision analysis, and Core Image rendering happen entirely on the Mac; frames are neither uploaded nor persisted.

## 0.1.0 preview limitation

**This preview does not expose “Blusher Camera” as a system-wide virtual camera.** Apple's provisioning service rejects the System Extension capability for the Personal Team used to sign this preview. The Camera Extension source and full target remain in the repository for development with a provisioning team that supports that capability, but the `BlusherLocal` preview application does not embed it.

The downloadable preview is Apple Development / Personal Team signed, not Developer ID signed or notarized. It is primarily a development and technical preview and may require additional macOS approval or manual handling after download. Do not disable macOS security features to run it.

## Included in the preview

- Physical AVFoundation camera capture with a mirrored selfie preview
- Vision face-landmark and cheek tracking
- Vision-based two-hand 👉🏻👈🏻 gesture detection
- Animated, face-relative cheek blush rendering
- Native SwiftUI macOS interface
- Local-only image processing

## Requirements and usage

- Apple Silicon Mac
- macOS 15 or later
- Camera permission for Blusher

Launch Blusher, select a physical camera, face the camera, and hold both index fingers toward one another in the 👉🏻👈🏻 pose. The status changes to “Blushing” and the effect animates over the tracked cheeks. Release the pose to fade the effect out.

Automatic updates are intentionally disabled in this preview because the Sparkle feed and Ed25519 release-signing setup are not yet provisioned.

See [Documentation/BUILDING.md](Documentation/BUILDING.md) and [Documentation/ARCHITECTURE.md](Documentation/ARCHITECTURE.md).
