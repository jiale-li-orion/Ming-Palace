# Asset Guide — Ming Palace Demo

## Production asset requirements

### Image assets

| Parameter | Requirement |
|-----------|-------------|
| Format | WebP or PNG |
| Resolution | 1080 × 1920 (portrait, full-screen mobile) |
| Color space | sRGB |
| Max size | ≤ 2 MB per image |
| Clearance | 12% top, 12% bottom (for system bars, subtitles, UI) |
| Naming | `visual_<node>_<purpose>_v<version>_<date>.webp` |

### Audio assets

| Parameter | Requirement |
|-----------|-------------|
| Format | MP3 |
| Bitrate | 128-192 kbps |
| Channels | Mono (single narrator voice) |
| Language | Chinese (Mandarin) |
| Character | Zhu Yunwen (朱允炆) — first person |

### Outdoor visibility

All visual assets MUST be tested outdoors on the target Android phone at maximum brightness under direct sunlight. If the user must block sunlight to see the screen, the design has failed.

## Asset inventory

### fengtian_north/ (奉天门北侧)

| File | Description | Status |
|------|-------------|--------|
| `background.webp` | Fixed-viewpoint photo of current ruins from 奉天门北侧 | PLACEHOLDER |

### platform_north/ (午门城台北望)

| File | Description | Status |
|------|-------------|--------|
| `background.webp` | Fixed-viewpoint photo from 午门城台 looking north | PLACEHOLDER |
| `central_axis.webp` | Transparent overlay: central axis line / palace layout | PLACEHOLDER |
| `fengtian_gate.webp` | Transparent overlay: 奉天门 reconstruction | PLACEHOLDER |
| `fengtian_hall.webp` | Transparent overlay: 奉天殿 reconstruction | PLACEHOLDER |
| `civil_tower.webp` | Transparent overlay: 文楼 reconstruction | PLACEHOLDER |
| `military_tower.webp` | Transparent overlay: 武楼 reconstruction | PLACEHOLDER |
| `fade_mask.webp` | Transparent overlay: fade-out mask for ending | PLACEHOLDER |

### ground_fallback/ (地面替代路线)

| File | Description | Status |
|------|-------------|--------|
| `background.webp` | Fixed-viewpoint photo from ground level | PLACEHOLDER |
| `central_axis.webp` | Transparent overlay: central axis | PLACEHOLDER |
| `fengtian_gate.webp` | Transparent overlay: 奉天门 (simplified) | PLACEHOLDER |

### wumen_south/ (午门南侧回望)

| File | Description | Status |
|------|-------------|--------|
| `background.webp` | Fixed-viewpoint photo from 午门南侧 looking back | PLACEHOLDER |

### Audio files

| File | Duration (est.) | Description | Status |
|------|-----------------|-------------|--------|
| `01_fengtian_north.mp3` | ~60s | 奉天门北侧 intro narration | PLACEHOLDER |
| `02_walk_to_wumen.mp3` | ~30s | Walking guidance to 午门 | PLACEHOLDER |
| `03_wumen_north.mp3` | ~45s | 午门北侧 approach narration | PLACEHOLDER |
| `04_platform_narration.mp3` | ~90s | Main platform narration with visual reveal | PLACEHOLDER |
| `05_question_prompt.mp3` | ~15s | Question prompt introduction | PLACEHOLDER |
| `06_branch_feudal.mp3` | ~60s | Answer: "why reduce feudal princes?" | PLACEHOLDER |
| `07_branch_classics.mp3` | ~60s | Answer: "why value classics and texts?" | PLACEHOLDER |
| `08_question_merge.mp3` | ~30s | Branch merge transition | PLACEHOLDER |
| `09_ground_fallback.mp3` | ~60s | Ground-level alternative narration | PLACEHOLDER |
| `10_wumen_south_ending.mp3` | ~45s | Ending narration at 午门南侧 | PLACEHOLDER |

## Script reference

The full script with evidence layers [A], [B], [C] is at:
`assets/content/script/script-review-v0.5.md`

Evidence index: `assets/content/evidence/evidence-index.json`

## Placeholder policy

Until production assets arrive:
- Each image slot has a 1-pixel colored PNG placeholder
- Audio slots have no files (app shows error for missing audio)
- All placeholders are visually distinct and labeled
- Missing assets show asset name + "[PLACEHOLDER]" in app, never crash
