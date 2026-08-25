# Architecture

The host captures a selected physical camera with AVFoundation, excluding devices named Blusher. Capture buffers remain unmirrored and upright in one canonical Core Image pixel space. Vision uses `.up` against that same buffer; `FrameCoordinateMapper` converts Vision-normalized rectangles and face-relative landmarks into canonical pixels without a Y inversion. Mirroring occurs once, at the final selfie-preview boundary.

Reused face-landmark and two-hand-pose requests run on a throttled cadence while capture and preview continue at camera rate. Eye, nose, and mouth landmarks define a scale- and rotation-aware facial basis; cheek anchors sit below and slightly outward from the eyes, are smoothed with time-based exponential interpolation, and fade on tracking loss. Two-hand joint geometry produces a normalized score, and temporal hysteresis controls a frame-rate-independent blush animation. Core Image composites rotated elliptical gradients in canonical coordinates. Debug Local builds expose an optional overlay for the face box, eye/nose/mouth landmarks, cheek anchors, and live FPS/Vision/render timing.

The Camera Extension has stable provider identity `com.nixboi42.Blusher.CameraExtension`, device UUID `6D9D7F5C-4994-4D57-8BC6-69086B57A111`, and paired sink/source streams. Frames submitted by the host to the sink are relayed to consumers through the source stream with monotonic host timestamps. Host-side CMIO sink discovery/submission remains required before end-to-end frame delivery is complete.

All image processing is local. No audio is requested, images are not persisted, and analytics are absent.
