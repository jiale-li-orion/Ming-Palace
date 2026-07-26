# Content Schema — Ming Palace Demo

## experience.json

Top-level structure:

```json
{
  "schemaVersion": 1,
  "contentVersion": "0.1.0",
  "experienceId": "ming-palace-zhu-yunwen",
  "title": "朱允炆：建文四年不是空白",
  "routes": {
    "normal": {"initialState": "INTRO"},
    "fallback": {"initialState": "INTRO"}
  },
  "scenes": {
    "<STATE_ID>": { ... }
  }
}
```

### Scene definition

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `id` | string | yes | 必须与外层 `<STATE_ID>` 完全一致，使用大写蛇形命名 |
| `renderer` | string | yes | Renderer type: `instruction`, `narrative`, `layered_reconstruction`, `question`, `survey`, `safety`, `completed` |
| `background` | string? | no | Asset path for background image |
| `audio` | string? | no | Asset path for audio file |
| `minimumDurationMs` | int | yes | Minimum time before auto-advance (0 = disabled) |
| `autoAdvance` | bool | yes | Whether timer auto-advances |
| `visualSequence` | array | yes | List of VisualLayer objects |
| `allowedActions` | array | yes | List of action names the user can trigger |
| `next` | array | yes | 允许的后继状态 ID；实际转换由 Experience Engine 校验 |
| `operatorActions` | array | yes | 当前状态允许呈现的操作员动作 |
| `safetyMode` | string | yes | `stationary`, `walking`, `ascending`, `descending` |

### VisualLayer

| Field | Type | Description |
|-------|------|-------------|
| `asset` | string | Asset path for the layer image |
| `startMs` | int | Delay before this layer appears (ms from scene start) |
| `fadeInMs` | int | Duration of fade-in animation (ms) |

### Scene IDs (state machine)

```
READY, INTRO, FENGTIAN_NORTH, WALK_TO_WUMEN, WUMEN_NORTH,
WAIT_FOR_ROUTE_DECISION, NORMAL_ASCEND, NORMAL_PLATFORM_OBSERVE,
NORMAL_PLATFORM_NARRATION, QUESTION, QUESTION_BRANCH_FEUDAL,
QUESTION_BRANCH_CLASSICS, QUESTION_MERGE, NORMAL_DESCEND,
WALK_THROUGH_WUMEN, FALLBACK_GROUND_OBSERVE, FALLBACK_GROUND_NARRATION,
WUMEN_SOUTH_ENDING, ENDING_AMBIENCE, SURVEY, COMPLETED
```

### Renderer types and their requirements

| Renderer | Background | Audio | Visual Layers | Allowed Actions |
|----------|-----------|-------|---------------|-----------------|
| `instruction` | optional | no | empty | start_test, submit_survey |
| `narrative` | optional | yes | empty | continue, pause, resume, replay, arrived |
| `layered_reconstruction` | required | optional | required | continue, pause, resume, replay |
| `question` | optional | yes | empty | choose_feudal, choose_classics |
| `survey` | optional | no | empty | submit_survey |
| `safety` | prohibited | prohibited | prohibited | arrived |
| `completed` | optional | no | empty | export, restart |

### Allowed actions reference

| Action | Description | Renderers |
|--------|-------------|-----------|
| `start_test` | Begin the experience | instruction |
| `continue` | Advance to next scene | narrative, layered_reconstruction |
| `pause` | Pause audio | narrative, layered_reconstruction |
| `resume` | Resume audio | narrative, layered_reconstruction |
| `replay` | Replay current audio | narrative, layered_reconstruction |
| `arrived` | User confirms arrival at location | narrative (walking) |
| `choose_feudal` | Select "why did you hurry to reduce the feudal princes?" | question |
| `choose_classics` | Select "why did you value classics and texts so much?" | question |
| `submit_survey` | Submit completed survey | survey |
| `export` | Export session data | completed |
| `restart` | Start a new session | completed |

## Version compatibility

`schemaVersion: 1` — the only supported version. If the version changes, the app must show a clear error and refuse to start until the content package is updated.
