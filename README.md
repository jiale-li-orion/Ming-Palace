# 明故宫 · 在场叙事体验 Ming Palace On-Site Narrative Demo

> 朱允炆：建文四年不是空白 — First-person historical narrative at Nanjing Ming Palace Ruins

An Android app that guides users through the Ming Palace Ruins (明故宫遗址, Nanjing) with first-person narration from Zhu Yunwen (建文帝). Pre-shot photos overlaid with painting-style historical reconstruction layers replace the vanished palace architecture.

## Quick start

### Prerequisites

- Flutter SDK (≥ 3.10.0, Dart ≥ 3.0.0)
- Android phone or emulator (Android 8.0+ / API 26+)
- USB cable for deployment or APK

### Build & install

```bash
# Clone
git clone https://github.com/jiale-li-orion/Ming-Palace.git
cd Ming-Palace

# Get dependencies
flutter pub get

# Run on connected device
flutter run

# Build release APK
flutter build apk --release
```

### Run tests

```bash
# Unit tests (domain model, state machine, repositories)
flutter test

# Integration tests (full user flow)
flutter test integration_test/
```

## Routes

### Normal route (6–8 minutes)

Walk from 奉天门北 → 午门 → ascend the 午门 city gate → observe the layered reconstruction northward → hear Zhu Yunwen's narration → answer one question → descend → walk out through 午门 → ending.

### Fallback route (alternative)

Same start, but when 午门 is closed or conditions prevent climbing → ground-level observation → shorter reconstruction → same question → ending.

Triggered by operator panel "切换替代路线" button. Must be selected at `WAIT_FOR_ROUTE_DECISION` state.

## Project structure

```
lib/
├── main.dart                          # Entry point
├── app/
│   ├── app.dart                       # MaterialApp root widget
│   ├── router.dart                    # State-driven routing (doc only)
│   └── theme.dart                     # Dark theme, Chinese red accent
├── application/
│   ├── experience_controller.dart     # Central state machine engine
│   ├── audio_controller.dart          # Audio playback (just_audio)
│   └── operator_controller.dart       # Hidden operator panel logic
├── domain/
│   ├── experience_state.dart          # 21-state enum
│   ├── experience_event.dart          # Event types + action enums
│   ├── scene_definition.dart          # Scene + visual layer models
│   ├── route_definition.dart          # Normal + fallback transition tables
│   └── session_summary.dart           # Test session data model
├── infrastructure/
│   ├── local_content_repository.dart   # Load experience.json
│   ├── local_telemetry_repository.dart # JSONL event logging
│   ├── local_session_repository.dart   # Session + state persistence
│   └── export_service.dart            # Data export + share
├── presentation/
│   ├── screens/
│   │   ├── experience_screen.dart     # Main screen wiring
│   │   └── error_screen.dart          # Load failure UI
│   ├── renderers/
│   │   ├── scene_renderer.dart        # Renderer interface
│   │   ├── instruction_renderer.dart   # Welcome + route decision
│   │   ├── narrative_renderer.dart     # Walking + stationary narrative
│   │   ├── layered_reconstruction_renderer.dart  # Historical overlay
│   │   ├── question_renderer.dart      # 2-choice interaction
│   │   ├── survey_renderer.dart        # Post-experience survey
│   │   ├── safety_renderer.dart        # Ascend/descend safety
│   │   └── completed_renderer.dart     # End screen + export
│   ├── widgets/
│   │   └── audio_controls.dart        # Reusable audio bar
│   └── operator/
│       └── operator_panel.dart        # Hidden operator panel
└── shared/
    ├── result.dart                    # Result<T, E> type
    └── app_error.dart                 # Error codes
```

## Content management

Content is fully offline, loaded from `assets/content/experience.json` at startup.

### Replacing assets

| Directory | Contents |
|-----------|----------|
| `assets/audio/` | MP3 narration files, named per experience.json |
| `assets/images/fengtian_north/` | 奉天门北 scene background |
| `assets/images/platform_north/` | 午门城台北望 — background + 5 overlay layers |
| `assets/images/ground_fallback/` | Fallback route background + 2 overlay layers |
| `assets/images/wumen_south/` | 午门南 ending background |
| `assets/content/experience.json` | Scene definitions, transitions, asset mapping |

### Asset specs

| Parameter | Requirement |
|-----------|-------------|
| Format | WebP or PNG |
| Resolution | 1080 × 1920 (full-screen mobile portrait) |
| Color space | sRGB |
| Max file size | ≤ 2 MB per image |
| Clearance | 12% top, 12% bottom (system bars / subtitles / UI) |

See `docs/asset-guide.md` for the full asset inventory.

### Modifying the script

Edit `assets/content/experience.json` scene configurations. Audio files must match the `audio` field paths. The state machine flow is defined in `lib/domain/route_definition.dart`.

## State machine

21 states, normal and fallback routes, all transitions defined in pure Dart. See `docs/content-schema.md`.

## Telemetry

All events logged to `telemetry.jsonl` in the app's documents directory. Export via the operator panel or the end screen. Full schema in `docs/telemetry-schema.md`.

## Tests

| Test file | Coverage |
|-----------|----------|
| `test/domain/state_machine_test.dart` | State transitions, route logic, model parsing |
| `test/infrastructure/repository_test.dart` | JSONL telemetry, session persistence |
| `test/presentation/` | Widget tests (when Flutter SDK available) |
| `integration_test/experience_test.dart` | Full user flow end-to-end |

## Operator panel

Revealed by tapping the title "明故宫 · 朱允炆" 7 times. Provides:

- Session control: create, reset, navigate states
- Route switching: normal ↔ fallback
- Debug: replay audio, view/export logs, clear data
- Mark user "needs help"

All operator actions are logged to telemetry.

## Known limitations

- **Flutter SDK installation**: The current development network is unable to download Flutter SDK (Google CDN, Gitee mirror, and snap all time out at ~20 KB/s). All code is written to spec; verify and run tests once Flutter is available (try a VPN, different network, or `sudo snap install flutter --classic`).
- **Production assets**: All image slots currently have 1-pixel PNG placeholders. Replace with real production assets before field testing.
- **Audio files**: No MP3 files yet. Placeholder READMEs in `assets/audio/`. The app handles missing audio gracefully (shows error, logs event, allows skip).
- **Single device target**: Android only. Not tested on iOS.
- **No GPS or AR**: Manual progression only.

## What this project does NOT do

Per `Project.md` §14, this version explicitly does NOT implement:
- Login, accounts, payments, registration
- Cloud database, CMS, real-time upload
- GPS auto-triggering or map display
- Real-time camera overlay
- AR or 3D models
- Free-text conversation, LLM, RAG
- Voice recognition or TTS
- Multi-character or multi-route stories
- iOS support
- App store deployment
- Remote content updates

## Architecture decisions

- **State machine**: Pure Dart `ChangeNotifier` (no Riverpod/Bloc/GetX)
- **Audio**: `just_audio` — plays MP3 from assets, handles lifecycle
- **Content**: Static `experience.json` asset (no network)
- **Telemetry**: JSONL file, appended per event
- **UI**: Single-screen, state-driven renderer switching

## Docs

- `docs/content-schema.md` — Scene configuration format
- `docs/telemetry-schema.md` — Event log format
- `docs/asset-guide.md` — Asset production specs

## License

Internal development prototype. Not for distribution.
