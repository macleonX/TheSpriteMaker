# Sprite Forge — Development WIP

Living status tracker for the build. Derived from the "Suggested build order" in
[spriteforgedevplan.md](../source/spriteforgedevplan.md). Update the status
columns and notes as work lands; keep this file honest about what actually works
versus what is stubbed.

**Last updated:** 2026-08-31
**Current phase:** 3 — frames, preview, and editor shell polish

Status legend: `TODO` · `IN PROGRESS` · `BLOCKED` · `DONE`

---

## Phase 0 — Scaffold (prerequisite)

| Item | Status | Notes |
| --- | --- | --- |
| Flutter SDK installed, `flutter doctor` green for first targets | DONE | `flutter doctor -v` reports no issues |
| VS Code Flutter + Dart extensions | DONE | Flutter and Dart extensions installed |
| Desktop targets enabled (`flutter config --enable-*-desktop`) | DONE | macOS desktop is enabled and detected |
| `flutter create sprite_forge` | DONE | Scaffolded in `app/` as `the_sprite_maker` |
| Device selectable in VS Code device dropdown | DONE | `flutter devices` detects macOS and Chrome |
| `flutter pub add riverpod flutter_riverpod sqflite path_provider image file_picker share_plus` | DONE | Added initial dependencies |
| Project structure stubbed per plan (`lib/` tree) | DONE | Created the planned top-level `lib/` folders |
| `app.dart` MaterialApp shell with light + dark theme | DONE | Added `SpriteMakerApp` and shell smoke test |

---

## Phase 1 — Pixel canvas + tools + palette

Single frame, single implicit layer, no persistence. Get drawing feeling right —
everything else builds on this.

| Item | Status | Notes |
| --- | --- | --- |
| `models/sprite.dart`, `models/palette.dart` initial classes | DONE | Frame = single flat pixel list at this stage |
| `state/editor_providers.dart` — active sprite, tool, palette | DONE | Riverpod `EditorController` owns editor state |
| `editor/pixel_canvas.dart` — `CustomPainter` grid + gestures | DONE | Draws transparent grid and palette pixels |
| Pencil tool | DONE | |
| Eraser tool | DONE | |
| Flood fill | DONE | |
| Eyedropper | DONE | |
| Line tool | DONE | Bresenham line commit on drag end |
| Rectangle tool | DONE | Outline rectangle commit on drag end |
| Mirror-X / Mirror-Y toggles (symmetric write on every stroke) | DONE | Symmetric write covered by tests |
| `editor/tool_panel.dart` | DONE | Icon toolbar with selected tool state |
| `editor/palette_panel.dart` (15-slot palette) | DONE | Selectable PICO-8-style palette |
| Grid sizes 8 / 16 / 24 / 32 | DONE | Segmented control resizes while preserving overlapping pixels |
| `test/pixel_canvas_test.dart` | DONE | Covered in `test/editor_controller_test.dart` and shell widget test |

---

## Phase 2 — Layers

Extend the frame model to `List<Layer>` now, while there is only one frame to
migrate — before frames/animation exist.

| Item | Status | Notes |
| --- | --- | --- |
| `Layer` class: `name`, `visible`, `opacity` (0.0–1.0), `pixels` | DONE | `SpriteLayer` stores layer-scoped pixels and serializes compact hex/null strings |
| Frame becomes `List<Layer>` | DONE | `SpriteFrame` now owns the layer stack; document tracks active frame/layer |
| Canvas composites layers bottom-to-top every render | DONE | Hidden/zero-opacity layers are skipped; partial alpha blending is still represented as visibility/composite precedence for indexed pixels |
| Drawing tools write to the **active layer only** | DONE | Pencil, eraser, fill, line, rectangle, generator write to active layer |
| `editor/layers_panel.dart` — list top-to-bottom | DONE | Built into `editor_screen.dart` for now; can split to its own file as UI grows |
| Visibility toggle | DONE | |
| Opacity slider | DONE | |
| Add / delete / duplicate layer | DONE | |
| Reorder (drag or up/down) | DONE | Up/down controls move the active layer within the stack |
| Merge down | DONE | Flattens active visible pixels into the layer beneath |

---

## Phase 3 — Frames, undo/redo, onion skin, playback

| Item | Status | Notes |
| --- | --- | --- |
| `editor/frame_strip.dart` — thumbnails (flattened composite) | DONE | Built into `editor_screen.dart` for now; thumbnails render flattened frame composites |
| Add / duplicate / delete frame | DONE | Duplicating a frame duplicates its whole layer stack; deleting keeps at least one editable frame |
| Undo/redo: stack of pre-stroke layer-string snapshots | TODO | Keyed to the layer active at stroke start; cap ~60 entries |
| Onion skin — previous frame's flattened composite at ~28% opacity | TODO | Frame-level, not layer-level |
| `editor/playback_preview.dart` — `Timer.periodic` at adjustable FPS | DONE | Preview play/stop cycles flattened frame composites at selected FPS without changing the editable active frame |

---

## Phase 4 — Procedural generator (default AI mode)

Port the prototype's algorithm directly — validated already, just JS → Dart.
Most algorithm-heavy piece; test determinism before wiring to UI.

| Item | Status | Notes |
| --- | --- | --- |
| `generator/procedural_generator.dart` | DONE | Extracted generator service returns editable layer stacks |
| Keyword → themed palette subset (fire/water/toxic/magic/metal/shadow/royal/nature) | DONE | Fire/water/toxic/shadow/royal/magic/metal/nature families mapped to palette roles |
| Keyword → body-type profile (humanoid/vehicle/icon/creature) | DONE | Humanoid, creature, vehicle, icon, weapon archetypes implemented |
| Seeded PRNG builds width-per-row silhouette from type profile curve | IN PROGRESS | Deterministic archetype generation is seeded; further organic silhouette variation still planned |
| Colorize pass: outline ring, top/bottom shading bands, eye placement | DONE | Generator emits outline/base/shading/accent layers |
| "Reroll" — keep prompt, new seed | TODO | |
| "Generate idle animation" — bob lower half across 4 frames | DONE | Idle mode creates four generated frames with lower-body shift |
| `generator/generator_panel.dart` — prompt, type selector, seed, mode toggle | DONE | Prompt, type, mood, single/idle mode, outline toggle, reroll, generate, and image-reference import are wired |
| Result writes onto a fresh single layer | DONE | Updated behavior: result writes a fresh editable layer stack (outline/base/shading/accent) |
| `test/procedural_generator_test.dart` — same prompt + seed → identical output | DONE | Covered in controller tests for deterministic generated layer stacks |

### Generator-adjacent additions

| Item | Status | Notes |
| --- | --- | --- |
| Optional image reference import | DONE | Pick an image, crop/resize to grid, quantize to the active palette, and write into the active layer |

---

## Phase 5 — `.sprf` native format + library

Wire New / Save / Save As / Open before export, so there is a real save loop to
test export against.

| Item | Status | Notes |
| --- | --- | --- |
| `io/project_file.dart` — `Project.fromJson` / `toJson` | DONE | `ProjectFileCodec` serializes v1 `.sprf` JSON for the active layered sprite |
| File read/write via temp-file-then-rename | DONE | Direct native Save writes through temp + rename; Save As uses `file_picker` bytes API |
| `formatVersion` = 1; migration hook keyed on old version at load | DONE | v1 enforced; unsupported versions throw until a v2 migration exists |
| New / Save / Save As / Open (via `file_picker`) | DONE | App bar actions wired; dirty marker and save/open feedback included |
| `io/recent_files_repository.dart` — sqflite/hive index | TODO | path, name, thumbnail, last-opened timestamp only |
| `library/library_screen.dart` — browse index, open `.sprf` on tap | TODO | |

---

## Phase 6 — PNG export

| Item | Status | Notes |
| --- | --- | --- |
| `export/png_exporter.dart` via `image` package | DONE | Always from flattened layer composite |
| Single-frame export | DONE | Export button emits active-frame PNG when the project has one frame |
| Sprite-sheet export | DONE | Export button emits horizontal sprite sheet when multiple frames exist |
| Nearest-neighbor upscale 1x / 4x / 8x / 16x | IN PROGRESS | Exporter supports nearest-neighbor scale; UI currently uses default 8x |
| Desktop: `file_picker` save dialog | DONE | Reuses project storage bytes save flow |
| Mobile: `share_plus` share sheet | TODO | |

---

## Phase 7 — Package first two platforms

| Item | Status | Notes |
| --- | --- | --- |
| Build target A (e.g. macOS) | TODO | |
| Build target B (e.g. Android) | TODO | |
| Fix platform-specific gesture issues | TODO | |
| Fix platform-specific file-path issues | TODO | |

---

## Phase 8 — Optional real-AI-image mode (Gemini API)

Additive, gated behind a settings toggle, **off by default**, last. Must not
block a usable offline app everywhere first. Provider is settled: **Google
Gemini API** (image generation), chosen for its free tier and plain-HTTPS shape.
Browser automation of the Gemini/ChatGPT web apps was considered and rejected
(ToS, fragility, can't bundle, doesn't escape rate limits).

| Item | Status | Notes |
| --- | --- | --- |
| `pub add dio`/`http`, `flutter_secure_storage` | TODO | |
| On-device Gemini API key storage | TODO | |
| `generator/ai_generator.dart` — calls Gemini image endpoint, same interface as procedural | TODO | Target Gemini directly, no multi-provider abstraction |
| Post-process: downscale → quantize to 15-slot palette → outline pass | TODO | Same outline pass as procedural generator |
| Settings toggle (default off) + clear "sends prompt to Gemini; free tier then paid" warning | TODO | |

---

## Open questions (settle before / during Phase 1)

- ~~Which desktop/mobile targets first?~~ **Settled for first pass** — macOS
  desktop first, with Chrome/web available for quick UI iteration.
- ~~Which AI image provider for the optional real-API mode?~~ **Settled** — see
  decision log.

## Decision log

_Record dated decisions here as they are made (target platforms, provider choice,
any deviations from the dev plan)._

| Date | Decision | Rationale |
| --- | --- | --- |
| 2026-08-27 | Scaffold Flutter inside the existing `app/` directory as `the_sprite_maker`. | Keeps the repo layout simple and matches the user-provided development path. |
| 2026-08-27 | First development targets are **macOS desktop** and **Chrome/web**. | Both are already available on this Mac and keep the initial feedback loop fast. |
| 2026-08-27 | Real-AI-image mode uses the **Google Gemini API**, as an opt-in toggle that is **off by default**. `ai_generator.dart` targets Gemini directly (no multi-provider abstraction). | Gemini has a real free tier, so users can enable the mode without necessarily paying; plain HTTPS REST fits the no-backend pattern. Procedural generator stays the always-available default. |
| 2026-08-27 | **Rejected** browser automation (Selenium/Chromium driving a logged-in Gemini/ChatGPT web session) as a way to avoid API usage. | Violates those services' ToS; fragile against bot detection and UI changes; cannot be bundled into a mobile app; does not actually escape rate limits. |
