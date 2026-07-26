# Telemetry Schema — Ming Palace Demo

## Format

JSONL (JSON Lines): one JSON object per line, append-only. File: `telemetry.jsonl` in app documents directory.

## Event envelope

Every event has these required fields:

```json
{
  "schemaVersion": 1,
  "sessionId": "550e8400-e29b-41d4-a716-446655440000",
  "timestamp": "2026-07-26T12:00:00.000Z",
  "event": "state_entered",
  "state": "NORMAL_PLATFORM_OBSERVE",
  "payload": {}
}
```

| Field | Type | Description |
|-------|------|-------------|
| `schemaVersion` | int | Always `1` |
| `sessionId` | string | UUID v4 identifying the test session |
| `timestamp` | string | ISO 8601 UTC timestamp |
| `event` | string | Event type (see below) |
| `state` | string? | Current experience state (null for session-level events) |
| `payload` | object | Event-specific data |

## Event types

### Session lifecycle

| Event | Payload | Description |
|-------|---------|-------------|
| `session_created` | `{}` | New test session started |
| `session_completed` | `{route, durationSeconds}` | Session reached COMPLETED state |
| `session_aborted` | `{route, reason}` | Session terminated prematurely |

### State transitions

| Event | Payload | Description |
|-------|---------|-------------|
| `state_entered` | `{route, contentVersion}` | Entered a new state |
| `state_exited` | `{route, durationMs}` | Exited current state |

### User actions

| Event | Payload | Description |
|-------|---------|-------------|
| `user_action` | `{action: string}` | User tapped a button (continue, pause, resume, replay, arrived, choose_feudal, choose_classics, submit_survey, start_test, export, restart) |

### Operator actions

| Event | Payload | Description |
|-------|---------|-------------|
| `operator_action` | `{action: string, extra?: {}}` | Operator triggered action from panel |

### Audio events

| Event | Payload | Description |
|-------|---------|-------------|
| `audio_started` | `{asset: string}` | Audio playback started |
| `audio_paused` | `{asset: string, positionMs: int}` | Audio was paused |
| `audio_resumed` | `{asset: string, positionMs: int}` | Audio resumed from pause |
| `audio_completed` | `{asset: string}` | Audio reached end |

### Interaction events

| Event | Payload | Description |
|-------|---------|-------------|
| `question_choice` | `{choice: string}` | User chose a branch: `feudal_princes` or `classics` |
| `fallback_route_used` | `{reason?: string}` | Fallback route was activated |
| `help_requested` | `{state: string, helpCount: int}` | User or operator marked "needs help" |

### Error events

| Event | Payload | Description |
|-------|---------|-------------|
| `app_error` | `{error: string, state: string?}` | Non-fatal application error |
| `content_load_failed` | `{error: string}` | Failed to load content config |
| `asset_missing` | `{asset: string, type: string}` | Missing audio or image asset |

### Survey

| Event | Payload | Description |
|-------|---------|-------------|
| `survey_submitted` | `{experienceDescription, mostEngagingMoment, confusingMoment, wantsLongerExperience, wantsNextTest}` | Survey answers |

## Session summary

Computed from telemetry events:

```json
{
  "sessionId": "uuid",
  "startedAt": "2026-07-26T12:00:00.000Z",
  "endedAt": "2026-07-26T12:07:18.000Z",
  "completed": true,
  "route": "normal",
  "durationSeconds": 438,
  "questionChoice": "feudal_princes",
  "helpCount": 1,
  "interrupted": false,
  "survey": {
    "experienceDescription": "...",
    "mostEngagingMoment": "...",
    "confusingMoment": "...",
    "wantsLongerExperience": true,
    "wantsNextTest": true
  }
}
```

## Data retention

- All data stored locally in app documents directory
- No network upload, no cloud sync
- User can export data via Share button
- User can clear all data via operator panel
- `schemaVersion` allows future format migration
