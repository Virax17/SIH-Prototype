# iTantra

Offline, push-to-talk voice translator for Android — built for **SIH 2026, Problem Statement 26173** (ISRO / Department of Space).

Two phones communicate by voice over Bluetooth/WiFi Direct with no internet, no SIM, and no cell signal. Each side runs on-device speech-to-text and text-to-speech, so speech is transmitted as compact text (under ~200 bytes/sentence) and re-synthesized as speech at the receiver — a voice channel that works on links too narrow for any audio codec.

## Status

This repository currently contains the **UI prototype**: all app screens, matching the visual design, wired to a simulated state machine (same interaction behavior as the design mockup — fake transcripts, fake incoming replies, fake device list). Real on-device STT/TTS inference and Bluetooth transport are not wired in yet.

## Screens

- **Home** — paired-device status, language pair selector, live transcript, push-to-talk button (hold to record, release to send), replay and emergency-alert buttons
- **Device pairing** — Bluetooth scan/connect flow with connected / available / out-of-range states
- **Settings** — paired device, default language pair, playback volume, emergency-override toggle, light/dark theme, about
- **Confirm alert** — cancelable 3-second countdown before broadcasting a priority alert
- **Emergency takeover** — full-screen, non-dismissible priority alert playback
- **Language picker** — English / Hindi / Tamil, offline voice models

Trigger the emergency flow either by holding the push-to-talk button for 3 seconds, or by triple-tapping anywhere on screen (panic gesture).

## Tech stack

- **Flutter** (Dart) — UI and app shell
- **provider** — app state management
- Bundled **Barlow**, **IBM Plex Mono**, **Noto Sans Devanagari**, **Noto Sans Tamil** fonts (no runtime font fetching, consistent with the fully-offline goal)

Planned for real functionality (not yet integrated):
- **Vosk** or a quantized **ONNX** Conformer/Whisper model for offline STT
- **flutter_tts** or a quantized on-device neural TTS (e.g. AI4Bharat Indic-TTS) for offline speech synthesis
- **flutter_bluetooth_serial** (Bluetooth Classic RFCOMM) for the two-device transport, with WiFi Direct as a later addition

## Project structure

```
lib/
  main.dart                     # App entry, theme, root screen switcher
  app_state.dart                # State machine (screen/mode/messages), simulated PTT + reply behavior
  models.dart                   # Message, LangOption, DeviceInfo
  theme.dart                    # Color tokens and fonts
  screens/
    home_screen.dart
    pairing_screen.dart
    settings_screen.dart
  widgets/
    language_sheet.dart
    confirm_alert_overlay.dart
    emergency_screen.dart
    wave_bars.dart
assets/fonts/                   # Bundled offline font files
```

## Running it

Requires the Flutter SDK and Android SDK set up (`flutter doctor` should be clean).

```bash
flutter pub get
flutter run
```

Or build a debug APK directly:

```bash
flutter build apk --debug
```

**Note:** on some Android GPU drivers, Flutter's Impeller/Vulkan renderer can misbehave. This project disables Impeller in `android/app/src/main/AndroidManifest.xml` for broader device compatibility.
