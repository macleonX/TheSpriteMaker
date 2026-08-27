# End Here

Use this at the end of a development session for The Sprite Maker.

## 1. Verify The App

```sh
cd /Users/macleon/Projects/Work/hub/TheSpriteMaker/app
dart format lib test
flutter analyze
flutter test
```

Run a build check when UI or platform code changed:

```sh
flutter build web
```

## 2. Update Progress Docs

Go back to the repo root:

```sh
cd /Users/macleon/Projects/Work/hub/TheSpriteMaker
```

Update the living tracker:

```sh
$EDITOR doc/development_WIP.md
```

Rules for the tracker:

- Update `Last updated` to today.
- Update `Current phase` when the active phase changes.
- Mark only working, tested behavior as `DONE`.
- Leave partially wired UI or untested behavior as `IN PROGRESS`.
- Add dated decisions to the decision log.

Update `README.md` if the public project status changed.

## 3. Review What Will Be Committed

```sh
git status --short
git diff -- README.md doc/development_WIP.md start.md end.md
git diff --stat
```

For new app files, inspect the file list:

```sh
git status --short app
```

Make sure no local secrets, temporary files, or unrelated work are included.

## 4. Commit All Intended Changes

```sh
git add -A
git status --short
git commit -m "Update Sprite Maker progress"
```

Use a more specific commit message when possible, for example:

```sh
git commit -m "Build Phase 1 sprite editor"
```

## 5. Push

```sh
git push
```

If the branch has no upstream yet:

```sh
git push -u origin main
```

## 6. Final Note

Record the final verification result and pushed commit hash in the handoff
message:

```sh
git rev-parse --short HEAD
```
