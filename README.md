# iTantra

Offline, push-to-talk voice translator for Android — built for **SIH 2026, Problem Statement 26173** (ISRO / Department of Space).

Two phones communicate by voice over Bluetooth with no internet, no SIM, and no cell signal. Each side runs on-device speech-to-text and text-to-speech, so speech is transmitted as compact text and re-synthesized as speech at the receiver — a voice channel that works on links too narrow for any audio codec.

## Screenshots

| Conversation | Recording | Government alert |
|---|---|---|
| ![Home conversation](docs/screenshots/home_conversation.png) | ![Recording](docs/screenshots/home_recording.png) | ![Emergency alert](docs/screenshots/emergency_alert.png) |

| Language picker | Devices — Find new | Settings |
|---|---|---|
| ![Language picker](docs/screenshots/language_sheet.png) | ![Devices](docs/screenshots/devices_findnew.png) | ![Settings](docs/screenshots/settings.png) |

| Alert history | Playing a reply | Devices — History |
|---|---|---|
| ![Alert history](docs/screenshots/alert_history.png) | ![Playing message](docs/screenshots/home_playing_message.png) | ![Devices history](docs/screenshots/devices_history.png) |

## Status

The full offline voice pipeline is wired end to end: push-to-talk captures real speech, transcribes it on-device (Vosk), translates it (a quantized OPUS-MT/Marian ONNX model, English↔Hindi), sends the translated text to the paired phone over the existing Bluetooth Classic connection, and the receiving phone speaks it (on-device TTS). English and Hindi are supported for the real pipeline; Tamil still falls back to text-only (no bundled STT/MT model for it yet — see "Model assets").

## Features

**Home**
- Push-to-talk: hold the mic button to record, release to send
- Volume-up + volume-down held together works as a hardware PTT combo (native Android key interception) — while the app is open, physical volume buttons are dedicated to this instead of adjusting media volume
- A text input bar to type a message instead of speaking — feeds the same send/reply pipeline
- Live transcript with sent/received bubbles; tap the play icon on any received message to replay it individually, not just the latest one
- Language pair selector (English / Hindi / Tamil) and a script-mode toggle (native script / Latin transliteration / both)
- **Emergency Broadcast** — any user can send one; it's presented as an official **government alert** (full-screen takeover, non-dismissible, max volume), matching real disaster-broadcast conventions
- A badge icon for quick access to the alert log, without going through Settings

**Devices**
- **Find new** — paired and nearby-scanned Bluetooth devices, with a "Phones only" filter that hides common accessories (earbuds, speakers, wearables) by name — a heuristic, since the Bluetooth Classic plugin doesn't expose Android's real device-class field
- **History** — devices you've successfully connected to before, persisted locally, for one-tap reconnecting

**Settings**
- Paired device, default language pair, playback volume, emergency-alert toggle, transcript text mode
- **Alert history** — every broadcast sent or received is logged permanently to local storage (never auto-deleted)

## Tech stack

- **Flutter** (Dart), **provider** for state management
- **flutter_classic_bluetooth** — permissions, adapter state, discovery, pairing, RFCOMM connect/server; `BluetoothManager.sendText`/`incomingText` carry the translated text of each message over the connection
- **vosk_flutter** — offline speech-to-text (English/Hindi small models), including its own on-Android microphone capture
- **onnxruntime** + **dart_sentencepiece_tokenizer** — offline English↔Hindi translation: quantized ONNX exports of Helsinki-NLP's OPUS-MT (Marian) models, tokenized with the models' own `.spm`/`vocab.json` files, greedy-decoded on-device
- **flutter_tts** — offline text-to-speech via the OS's own TTS engine
- **shared_preferences** — persisted connection history and alert log
- Native Android (`MainActivity.kt`) — volume-key combo interception via `dispatchKeyEvent`, forwarded to Flutter over a `MethodChannel`
- Bundled **Barlow**, **Noto Sans Devanagari**, **Noto Sans Tamil** fonts (no runtime font fetching, consistent with the fully-offline goal)

## Model assets

The STT and translation models (~300MB total) aren't committed to git — fetch them once with:

```bash
scripts/download_models.sh     # macOS/Linux/Git Bash
scripts/download_models.ps1    # Windows PowerShell
```

This downloads, into `assets/models/` (gitignored):
- `vosk-model-en-us-0.22-lgraph.zip` (~125MB, mid-tier — noticeably more accurate than Vosk's small tier) / `vosk-model-small-hi-0.22.zip` (~40MB — Hindi has no mid-tier option, only small-42MB or full-1.5GB) — Vosk STT models
- `mt-en-hi/` / `mt-hi-en/` — quantized ONNX OPUS-MT translation models plus their tokenizer files (~110MB each direction)

`flutter run`/`flutter build` will fail on missing assets until this has been run once. Tamil has no bundled STT/MT model, so typed text is the only input for that language pair for now.

## Project structure

```
lib/
  main.dart                       # App entry, theme, root tab shell, volume-key PTT wiring
  app_state.dart                  # Message/reply/emergency state machine (simulated STT/TTS)
  models.dart                     # Message, LangCode, Phrase, EmergencyAlertRecord
  theme.dart                      # Color tokens and fonts
  services/
    bluetooth_manager.dart        # Real Bluetooth Classic connectivity + connection history
    volume_ptt_service.dart       # MethodChannel bridge for the volume-key PTT combo
  screens/
    home_screen.dart
    devices_screen.dart
    settings_screen.dart
    alert_history_screen.dart
  widgets/
    language_sheet.dart
    emergency_screen.dart
    wave_bars.dart
android/app/src/main/kotlin/.../MainActivity.kt   # Volume-key combo interception
assets/fonts/                     # Bundled offline font files
docs/screenshots/                 # Screenshots used in this README
```

## Running it

Requires the Flutter SDK and Android SDK set up (`flutter doctor` should be clean).

```bash
flutter pub get
flutter run
```

Or build an APK directly:

```bash
flutter build apk --debug     # larger, unoptimized, for testing
flutter build apk --release   # smaller, for sharing/installing
```

**Notes:**
- On some Android GPU drivers, Flutter's Impeller/Vulkan renderer can misbehave (solid black screen). This project disables Impeller in `android/app/src/main/AndroidManifest.xml` for broader device compatibility.
- Testing the two-phone Bluetooth link requires installing the app on two devices — one device's background server accepts the other's outgoing connection, so either side can initiate.
