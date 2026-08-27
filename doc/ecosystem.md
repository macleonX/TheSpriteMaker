# Sprite Forge — Ecosystem

The landscape Sprite Forge is built on: the framework choice, the package
dependencies and what each one is responsible for, the platform targets, and the
external services the app can optionally talk to. This is the "what depends on
what" companion to [spriteforgedevplan.md](../source/spriteforgedevplan.md).

## Framework

**Flutter (stable channel), Dart 3.x.** One Dart codebase compiles to Windows,
macOS, Linux, iOS, Android, and web with a single toolchain and widget set. This
was chosen over React because React only targets the web natively — desktop and
mobile would require bolting on Electron and React Native, which become two
near-separate apps with their own build pipelines and native modules.

Flutter also fits this app specifically:

- `CustomPainter` + `Canvas.drawRect` give pixel-level canvas control, a natural
  fit for a grid-based sprite editor — no external canvas library needed.
- Desktop file-system and native-share APIs make local project persistence and
  PNG export straightforward with no backend.

The trade-off is Dart itself: if the team or hiring pool is React-only, that is a
real cost. For a solo or small cross-platform build, Flutter is the more direct
path.

## Package dependencies

| Package | Role | Notes |
| --- | --- | --- |
| `flutter_riverpod` / `riverpod` | State management | Holds editor state (palette, active sprite, frames, undo stack) outside the widget tree so it stays testable |
| `CustomPainter` (SDK) | Canvas rendering | Pixel grid via `Canvas.drawRect`; no third-party canvas lib |
| `dart:io` (SDK) | Native `.sprf` file read/write | Plain file I/O for the JSON project format; no package needed |
| `sqflite` *or* `hive` | Recent-files index | Stores only paths / thumbnails / timestamps pointing at real `.sprf` files — never the sprites themselves |
| `path_provider` | Locate app documents / config directory | Used with the recent-files index and mobile file access |
| `image` | PNG encode/decode, nearest-neighbor scaling | Dart-native; avoids platform channels for basic export |
| `file_picker` | "Save as" / "Open" dialogs on desktop | |
| `share_plus` | Mobile share sheet | Export path on iOS/Android |
| `dio` *or* `http` | Gemini image API calls | Optional mode only |
| `flutter_secure_storage` | On-device storage of the user's own Gemini API key | Optional mode only |

Initial install (from the plan):

```
flutter pub add riverpod flutter_riverpod sqflite path_provider image file_picker share_plus
```

`dio`/`http` and `flutter_secure_storage` are added later, only when the optional
real-AI mode is built.

## Storage formats

Two distinct formats, deliberately kept separate:

- **`.sprf` — native project file.** UTF-8 JSON with a top-level `formatVersion`
  integer for migrations. The canonical source of truth: keeps all sprites,
  frames, and layers intact. Owned by `io/project_file.dart`
  (`Project.fromJson` / `toJson`). Written via temp-file-then-rename so a crash
  mid-save cannot corrupt the existing file. This is the standard desktop-app
  pattern (Aseprite's `.aseprite`, Photoshop's `.psd`).
- **PNG export.** One-way, lossy-to-layers output for use outside the app (a game
  engine, a README). Single frame or full sprite sheet, rendered from each
  frame's flattened layer composite, nearest-neighbor upscaled at 1x/4x/8x/16x.

The SQLite/Hive table is **not** canonical storage — it is only a recent-files
index (path, name, thumbnail, last-opened timestamp) so the library screen can
render without parsing every project file.

## Platform targets

| Platform | Build command | Build host required | SDK |
| --- | --- | --- | --- |
| Windows | `flutter build windows` | Windows only | Visual Studio Build Tools |
| macOS | `flutter build macos` | macOS only | Xcode |
| iOS | `flutter build ios` | macOS only | Xcode |
| Android | `flutter build apk` / `appbundle` | any | Android SDK |

You cannot build a Windows `.exe` from macOS or vice versa without a CI runner
for that platform. Desktop targets are opt-in per machine:
`flutter config --enable-windows-desktop`, `flutter config --enable-macos-desktop`.

Recommendation from the plan: enable one or two targets first (e.g. macOS +
Android). Setting up all four at once multiplies `flutter doctor` pain for no
early benefit.

## External services (optional real-AI mode)

**Provider: Google Gemini API (image generation).** Off by default and fully
opt-in. When enabled, the Dart client calls the Gemini image endpoint directly
over HTTPS using the user's own API key held on-device in
`flutter_secure_storage` — no backend.

Gemini was chosen over OpenAI / Stability / Replicate because it has a real free
tier: a user can turn this mode on and use it without necessarily paying per
call. `ai_generator.dart` targets Gemini directly rather than abstracting over
multiple providers.

**Why not browser automation.** Driving the Gemini/ChatGPT *web apps* with
Selenium/Chromium to dodge API usage was considered and rejected — it violates
those services' terms, breaks against bot detection and frequent UI changes,
can't be bundled into a mobile app, and doesn't actually escape rate limits.

Returned images run through a post-process pipeline before hitting the canvas:
downscale to the active grid size → color-quantize every pixel to the nearest of
the 15 palette slots → run the same outline pass the procedural generator uses,
so the result stays hand-editable with the normal tools.

The UI must flag clearly that this mode sends the prompt to a third-party API and,
past the free-tier limits, costs money per call. The procedural generator remains
the always-available default, so the app is fully usable with zero API access.
Client-side key storage is acceptable for a single-user desktop/mobile app; it
would **not** be an appropriate pattern for a shared multi-user product.

## Toolchain / editor

- Flutter SDK; run `flutter doctor` until every check passes for the chosen
  targets.
- VS Code with the **Flutter** and **Dart** extensions (Flutter pulls in Dart).
- Confirm a target device is selectable in VS Code's device dropdown before
  writing app code.

## Working reference

A browser prototype covers the pixel editor, mirrored drawing, multi-frame
animation, the procedural generator, and PNG export, tested end-to-end:
https://claude.ai/code/artifact/bef3cc11-4b13-4b6e-9592-26a8d76b6dcf

Where the spec is ambiguous, the prototype's behavior is the tiebreaker. It is a
reference only — the app does not depend on it to run.
