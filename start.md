# Start Here

Use this at the beginning of a new development session for The Sprite Maker.

## 1. Go To The Repo

```sh
cd /Users/macleon/Projects/Work/hub/TheSpriteMaker
```

## 2. Check Local Changes

```sh
git status --short
```

If there are uncommitted changes, inspect them before pulling:

```sh
git diff -- README.md doc/development_WIP.md
git status --short app
```

Do not overwrite local work unless that is the explicit goal.

## 3. Get Latest From Git

```sh
git fetch origin
git pull --ff-only
```

If `git pull --ff-only` fails because local work exists, pause and decide whether
to commit, stash, or merge manually.

## 4. Read Latest Progress

Start with the living tracker:

```sh
sed -n '1,180p' doc/development_WIP.md
```

Then check the reference docs when needed:

```sh
sed -n '1,220p' README.md
sed -n '1,260p' source/spriteforgedevplan.md
sed -n '1,220p' doc/ecosystem.md
```

Current expected progress as of 2026-08-27:

- Phase 0 is complete.
- Phase 1 pixel canvas/tools/palette is complete.
- Next planned work is Phase 2: layers.

## 5. Verify The App

```sh
cd app
flutter analyze
flutter test
```

For a browser dev run:

```sh
flutter run -d web-server --web-hostname 127.0.0.1 --web-port 5173
```

Open:

```text
http://127.0.0.1:5173
```

For macOS desktop:

```sh
flutter run -d macos
```

## 6. Continue From The Tracker

Update `doc/development_WIP.md` as work lands. Keep statuses honest: mark only
working, tested behavior as `DONE`.
