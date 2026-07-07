# Design Follow-up Decisions

## Decibel Detail Navigation

The decibel detail page keeps the top-right history entry instead of replacing it with an info button. This is a product decision: measurement history is the primary follow-up action after recording, and the bottom History tab remains the general entry point.

## Flashlight Brightness

The flashlight UI keeps brightness disabled for steady and SOS modes. The current CameraKit torch API used by `TorchController` exposes torch on/off control and does not provide a brightness-strength setter in this project, so showing an enabled brightness slider would be misleading.

## Settings Scope

Settings keeps the extra items for time weighting, screen calibration, clearing local history, and privacy policy. These map to real product capabilities or store compliance requirements; visual density should continue to follow the existing settings section rhythm.

## Compass Accuracy

The compass status keeps real sensor accuracy feedback instead of always showing the static design-copy pair. High accuracy shows `精度 ±2°`, medium accuracy shows `精度 ±5°`, low/unreliable states ask for calibration, and inactive sensor state never claims calibration.
