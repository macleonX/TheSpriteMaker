# Sprite Forge — Development Plan

A pixel-art sprite and animation editor with a built-in generator that turns a text prompt into a starting sprite, built to compile from one codebase to Windows, macOS, and mobile. This document is the spec to build from in VS Code — it does not require anything from the browser prototype below to run, but that prototype is worth keeping open as a working reference for exact tool behavior.

Working reference: https://claude.ai/code/artifact/bef3cc11-4b13-4b6e-9592-26a8d76b6dcf — a browser prototype covering the pixel editor, mirrored drawing, multi-frame animation, the procedural generator, and PNG export. Every interaction in it was tested end-to-end, so where this spec is ambiguous, that prototype's behavior is the tiebreaker.

## Why Flutter over React here

You asked for React or Flutter with Windows/macOS/mobile builds from one project. React itself only targets the web — reaching desktop and mobile from a React codebase means bolting on Electron for desktop and React Native (or Capacitor) for mobile, which in practice become two more-or-less separate apps with their own build pipelines, native modules, and platform quirks, sharing components at best. Flutter compiles the same Dart codebase to Windows, macOS, Linux, iOS, Android, and web with one toolchain and one set of widgets, which matches "compile to Windows/macOS or even mobile" much more directly. It also has a real advantage for this specific app: `CustomPainter` gives pixel-level canvas control that's a natural fit for a grid-based sprite editor, and Flutter's desktop file-system and native-share APIs make local project persistence and PNG export straightforward without a backend. The trade-off is Dart itself — if your team's existing skills or hiring pool is React-only, that's a real cost worth weighing, but for a solo or small cross-platform build, Flutter is the more direct path.

## Tech stack

- **Framework:** Flutter (stable channel), Dart 3.x
- **State management:** Riverpod (`flutter_riverpod`) — keeps the editor state (palette, active sprite, frames, undo stack) testable and out of widget trees
- **Canvas rendering:** `CustomPainter` + `Canvas.drawRect` for the pixel grid; no external canvas library needed
- **Native project file:** plain `dart:io` file read/write for the `.sprf` JSON format (own format, see below) — no extra package needed
- **Recent-files index:** `sqflite` (desktop+mobile SQLite) or `hive`, storing only paths/thumbnails/timestamps that point at real `.sprf` files, not the sprites themselves; `path_provider` to locate the app's documents/config directory
- **Image export:** the `image` package (Dart-native PNG encode/decode, nearest-neighbor scaling) — avoids needing platform channels for basic export
- **File save/share:** `file_picker` for "save as" dialogs on desktop, `share_plus` for the mobile share sheet
- **Real AI image mode (optional):** `dio` or `http` for the Gemini API call, plus `flutter_secure_storage` to hold the user's own API key on-device
- **Packaging:** `flutter build windows` / `flutter build macos` for desktop installers; standard `flutter build ios` / `flutter build apk` (or `appbundle`) for mobile — no extra tooling required beyond platform SDKs (Xcode for macOS/iOS, Visual Studio Build Tools for Windows)

## VS Code setup

1. Install the Flutter SDK and run `flutter doctor` until every check passes for the platforms you're targeting first (start with just desktop or just mobile — doing all four at once multiplies setup pain for no benefit).
2. Install the **Flutter** and **Dart** VS Code extensions (the Flutter extension pulls in Dart automatically).
3. Enable the desktop targets you want: `flutter config --enable-windows-desktop`, `flutter config --enable-macos-desktop` (each only builds on its own OS — you cannot build a Windows .exe from macOS or vice versa without a CI runner for that platform).
4. `flutter create sprite_forge`, open the folder in VS Code, and confirm a target device is selectable in VS Code's device dropdown (bottom right) before writing any app code.
5. Add the packages above to `pubspec.yaml` with `flutter pub add riverpod flutter_riverpod sqflite path_provider image file_picker share_plus`.

## Project structure

```
sprite_forge/
  lib/
    main.dart
    app.dart                    # MaterialApp/theme (light + dark) shell
    models/
      sprite.dart                # Sprite, Frame, Project data classes
      palette.dart
    state/
      editor_providers.dart      # Riverpod providers: active sprite, tool, undo stack
      library_providers.dart     # saved-sprite library state
    editor/
      pixel_canvas.dart          # CustomPainter grid + gesture handling, composites active frame's layers
      tool_panel.dart            # pencil/eraser/fill/eyedropper/line/rect + mirror toggles
      palette_panel.dart
      layers_panel.dart          # per-frame layer list: visibility, opacity, reorder, merge
      frame_strip.dart           # frame thumbnails (flattened), add/duplicate/delete
      playback_preview.dart      # animated preview at configurable FPS
    generator/
      procedural_generator.dart  # keyword → palette/type/silhouette pipeline (default mode)
      ai_generator.dart          # optional real-API mode, isolated behind the same interface
      generator_panel.dart       # prompt field, type selector, seed field, mode toggle
    export/
      png_exporter.dart          # flattened frame + sprite-sheet PNG at 1x/4x/8x/16x
    io/
      project_file.dart          # .sprf read/write, formatVersion migrations
      recent_files_repository.dart # sqflite/hive index of recently opened .sprf paths
    library/
      library_screen.dart        # browses the recent-files index, opens a .sprf on tap
    widgets/
      toast.dart
      confirm_dialog.dart
  test/
    procedural_generator_test.dart
    pixel_canvas_test.dart
  pubspec.yaml
```

## Data model

Keep the compact pixel encoding from the prototype — it keeps sprites small in storage and trivial to diff for undo/redo. The one structural change from the prototype is that each frame is no longer a single flat string but a **stack of layers**: a frame is `List<Layer>`, and a `Layer` holds `name`, `visible`, `opacity` (0.0–1.0), and `pixels` — the same `size*size` hex-character string as before, now scoped to one layer instead of the whole frame. The canvas composites layers bottom-to-top (skipping hidden ones, blending by `opacity`) to produce what's drawn and what gets exported; drawing tools always write to the *active* layer only. A `Sprite` holds `id`, `name`, `size` (8/16/24/32), `List<Frame> frames` (each a `List<Layer>`), `fps`, and `paletteOverride` (nullable — falls back to the project's shared palette). A `Project` is a `List<Sprite>` plus the shared default palette and a format-version number (see the file format section below) — this is the struct that gets serialized whole when saving.

Onion skinning stays a frame-level feature, not a layer-level one: it composites the *previous frame's fully-flattened layers* at ~28% opacity beneath the active frame's own layers, exactly as in the prototype, so it stays meaningful regardless of how many layers a frame has.

## Feature breakdown

**Pixel editor.** Pencil, eraser, flood fill, eyedropper, line, and rectangle tools, all working on the active layer's character array. Mirror-X and Mirror-Y toggles write to the reflected cell(s) on every stroke, the same symmetric-write logic as the prototype. Undo/redo is a stack of pre-stroke layer-string snapshots (keyed to whichever layer was active when the stroke started), pushed on gesture-start and capped (around 60 entries) to bound memory.

**Layers.** Each frame carries its own independent layer stack — useful for keeping outlines, base color, and shading/effects separable, or for building a body on one layer and swappable equipment/accessories on another. `layers_panel.dart` lists the active frame's layers top-to-bottom with a visibility toggle, an opacity slider, add/delete/duplicate, reorder (drag or up/down buttons), and a "merge down" action that flattens a layer into the one beneath it. Because layers live per-frame, duplicating a frame duplicates its whole layer stack; the frame thumbnail in the strip always shows the flattened composite, not any single layer.

**Frames and animation.** A horizontal frame strip with add/duplicate/delete, a frame-level onion-skin overlay (the previous frame's flattened composite painted at ~28% opacity beneath the active frame), and a playback preview that cycles frames at an adjustable FPS using a `Timer.periodic`, always rendering each frame's flattened composite.

**Procedural generator (default AI mode).** Port the prototype's algorithm directly — it's already validated and doesn't need redesigning, just translating from JS to Dart: keyword matching picks a themed subset of palette indices (fire/water/toxic/magic/metal/shadow/royal/nature), a second keyword pass picks a body-type profile (humanoid/vehicle/icon/creature), a seeded PRNG (`mulberry32`-equivalent, or Dart's own `Random(seed)` since determinism only needs to be stable within the app, not cross-language) builds a width-per-row silhouette from a type-specific profile curve, and a colorize pass adds an outline ring, top/bottom shading bands, and eye placement for creature/humanoid types. A "reroll" button keeps the prompt and draws a new seed; a "generate idle animation" button bobs the lower half of the silhouette left/right across 4 frames for a quick starter animation. This mode needs no network access and no API key, so it should stay the default and always available offline.

**Real AI image mode (optional, behind a toggle).** Since this now runs as a compiled app rather than a sandboxed web page, a genuine text-to-image call becomes possible. The provider is the **Google Gemini API** (image generation) — chosen because it has a real free tier, so a user can enable this mode without necessarily paying anything, and it is a plain HTTPS REST endpoint that fits the no-backend pattern. Browser automation of the Gemini/ChatGPT web apps (Selenium/Chromium driving a logged-in session) was considered and rejected: it violates those services' terms, is fragile against bot detection and UI changes, cannot be bundled into a mobile app, and does not actually escape rate limits. The pattern that avoids standing up a backend for what's likely a personal tool: store the user's own Gemini API key locally via `flutter_secure_storage`, call the Gemini image endpoint directly from the Dart client over plain HTTPS, then run the returned image through a post-process pipeline before it lands on the canvas — downscale to the active grid size with a color-quantization pass that snaps every pixel to the nearest color in the current 15-slot palette (so the result is still hand-editable with the same tools), then run the same outline pass the procedural generator uses. Flag clearly in the UI that this mode sends the prompt to a third-party API and, past the free-tier limits, costs money per call; keep it entirely opt-in and off by default — the procedural generator above stays the always-available default so the app is fully usable with zero API access. The client-side key storage is fine for a single-user desktop/mobile app but would not be an appropriate pattern if this ever became a shared multi-user product.

**Export.** PNG export (single frame or full sprite sheet) via the `image` package, always rendered from each frame's flattened layer composite, nearest-neighbor upscaled at 1x/4x/8x/16x to keep pixels crisp, written through `file_picker`'s save dialog on desktop or `share_plus` on mobile. This is a one-way, lossy-to-layers export for use outside the app (a game engine, a README) — it's separate from the native project file below, which is the only format that keeps layers intact.

**Native project file (`.sprf`) and library.** Give the app its own save format rather than leaning on a generic database as the source of truth — this is the standard desktop-app pattern (Aseprite's `.aseprite`, Photoshop's `.psd`): "New", "Save", "Save As...", and "Open" work against a single project file the user places wherever they like, and the app remembers a most-recently-used list for quick access. See the format spec below for what's actually inside a `.sprf` file. A lightweight SQLite (or Hive) table still earns its keep here, but only as a *recent-files index* (path, name, thumbnail, last-opened timestamp) pointing at real `.sprf` files on disk — not as the canonical storage — so the library screen stays fast to browse without needing to fully parse every project file just to show a thumbnail.

### The `.sprf` file format

Keep v1 simple: a `.sprf` file is UTF-8 JSON (human-readable, diffable in git, trivial to hand-edit or migrate later) with a top-level `formatVersion` integer so future changes can migrate old files instead of breaking them. Shape:

```json
{
  "formatVersion": 1,
  "projectName": "goblin-pack",
  "palette": ["1a1c2c", "5d275d", "b13e53", "..."],
  "sprites": [
    {
      "id": "s1a2b3c4",
      "name": "goblin-idle",
      "size": 16,
      "fps": 6,
      "frames": [
        {
          "layers": [
            { "name": "outline", "visible": true, "opacity": 1.0, "pixels": "0000111100000000..." },
            { "name": "base",    "visible": true, "opacity": 1.0, "pixels": "0000022200000000..." }
          ]
        }
      ]
    }
  ]
}
```

`io/project_file.dart` owns `Project.fromJson` / `toJson` and the actual file read/write (via `dart:io File` on desktop, `path_provider` + `File` on mobile). Writes should go through a temp-file-then-rename step so a crash mid-save can't corrupt the file the user already had on disk. Because it's plain JSON, a v2 migration (say, adding per-sprite tags) is just: bump `formatVersion`, add a migration function keyed on the old version number, and run it on load before handing the parsed project to the rest of the app.

## Suggested build order

1. Pixel canvas + tool panel + palette, single frame with a single implicit layer, no persistence — get drawing feeling right first, since every other feature builds on it.
2. Layers: extend the frame model to `List<Layer>`, build `layers_panel.dart`, update the canvas to composite on every render. Doing this right after step 1 (before frames/animation exist) keeps the data-model change small — you're only ever migrating one frame's shape, not retrofitting an animation system.
3. Frame strip, undo/redo (now per-layer), onion skin (frame-level, using flattened composites), playback preview.
4. Procedural generator and its panel — this is the most algorithm-heavy piece and worth its own test file (`procedural_generator_test.dart`) asserting determinism (same prompt + seed → identical output) before wiring it to the UI. It writes its result onto a fresh single layer.
5. The `.sprf` native format: `project_file.dart` read/write plus the recent-files index and library screen. Wire up New/Save/Save As/Open before export, so there's a real save loop to test PNG export against.
6. PNG export (flattened composite, single frame and sprite sheet).
7. Package for your first two target platforms (e.g., macOS + Android) and fix any platform-specific gesture or file-path issues before adding more targets.
8. Optional real-AI-image mode (Gemini API), gated behind a settings toggle and off by default, last — it's additive and shouldn't block getting a usable offline app running everywhere first.

## Open questions to settle before or during Phase 1

Which desktop/mobile targets matter most first (building and testing all four simultaneously multiplies setup time for little early benefit). The AI image provider is settled: Google Gemini API, for its free tier and plain-HTTPS shape — `ai_generator.dart` targets it directly rather than abstracting over multiple providers.
