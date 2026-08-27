# Sprite Forge — Development WIP

Living status tracker for the build. Derived from the "Suggested build order" in
[spriteforgedevplan.md](../source/spriteforgedevplan.md). Update the status
columns and notes as work lands; keep this file honest about what actually works
versus what is stubbed.

**Last updated:** 2026-08-27
**Current phase:** 2 — layers

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
| `Layer` class: `name`, `visible`, `opacity` (0.0–1.0), `pixels` | TODO | `pixels` = `size*size` hex string, scoped to the layer |
| Frame becomes `List<Layer>` | TODO | |
| Canvas composites layers bottom-to-top every render | TODO | Skip hidden; blend by opacity |
| Drawing tools write to the **active layer only** | TODO | |
| `editor/layers_panel.dart` — list top-to-bottom | TODO | |
| Visibility toggle | TODO | |
| Opacity slider | TODO | |
| Add / delete / duplicate layer | TODO | |
| Reorder (drag or up/down) | TODO | |
| Merge down | TODO | Flatten layer into the one beneath |

---

## Phase 3 — Frames, undo/redo, onion skin, playback

| Item | Status | Notes |
| --- | --- | --- |
| `editor/frame_strip.dart` — thumbnails (flattened composite) | TODO | |
| Add / duplicate / delete frame | TODO | Duplicating a frame duplicates its whole layer stack |
| Undo/redo: stack of pre-stroke layer-string snapshots | TODO | Keyed to the layer active at stroke start; cap ~60 entries |
| Onion skin — previous frame's flattened composite at ~28% opacity | TODO | Frame-level, not layer-level |
| `editor/playback_preview.dart` — `Timer.periodic` at adjustable FPS | TODO | Always renders flattened composite |

---

## Phase 4 — Procedural generator (default AI mode)

Port the prototype's algorithm directly — validated already, just JS → Dart.
Most algorithm-heavy piece; test determinism before wiring to UI.

| Item | Status | Notes |
| --- | --- | --- |
| `generator/procedural_generator.dart` | TODO | |
| Keyword → themed palette subset (fire/water/toxic/magic/metal/shadow/royal/nature) | TODO | |
| Keyword → body-type profile (humanoid/vehicle/icon/creature) | TODO | |
| Seeded PRNG builds width-per-row silhouette from type profile curve | TODO | `Random(seed)` is fine — determinism only needs to be stable within the app |
| Colorize pass: outline ring, top/bottom shading bands, eye placement | TODO | Eyes for creature/humanoid |
| "Reroll" — keep prompt, new seed | TODO | |
| "Generate idle animation" — bob lower half across 4 frames | TODO | |
| `generator/generator_panel.dart` — prompt, type selector, seed, mode toggle | TODO | |
| Result writes onto a fresh single layer | TODO | |
| `test/procedural_generator_test.dart` — same prompt + seed → identical output | TODO | Write before UI wiring |

---

## Phase 5 — `.sprf` native format + library

Wire New / Save / Save As / Open before export, so there is a real save loop to
test export against.

| Item | Status | Notes |
| --- | --- | --- |
| `io/project_file.dart` — `Project.fromJson` / `toJson` | TODO | |
| File read/write via temp-file-then-rename | TODO | Crash mid-save must not corrupt existing file |
| `formatVersion` = 1; migration hook keyed on old version at load | TODO | |
| New / Save / Save As / Open (via `file_picker`) | TODO | |
| `io/recent_files_repository.dart` — sqflite/hive index | TODO | path, name, thumbnail, last-opened timestamp only |
| `library/library_screen.dart` — browse index, open `.sprf` on tap | TODO | |

---

## Phase 6 — PNG export

| Item | Status | Notes |
| --- | --- | --- |
| `export/png_exporter.dart` via `image` package | TODO | Always from flattened layer composite |
| Single-frame export | TODO | |
| Sprite-sheet export | TODO | |
| Nearest-neighbor upscale 1x / 4x / 8x / 16x | TODO | |
| Desktop: `file_picker` save dialog | TODO | |
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
