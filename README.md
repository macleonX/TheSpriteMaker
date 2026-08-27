# The Sprite Maker (Sprite Forge)

A cross-platform pixel-art sprite and animation editor with a built-in generator
that turns a text prompt into a starting sprite. Built with Flutter to compile
from one codebase to Windows, macOS, and mobile.

## Documents

- [source/spriteforgedevplan.md](source/spriteforgedevplan.md) — the development
  plan / spec to build from.
- [doc/ecosystem.md](doc/ecosystem.md) — framework choice, package dependencies,
  platform targets, and external services.
- [doc/development_WIP.md](doc/development_WIP.md) — living build-status tracker
  and decision log.

## Status

Phase 2 — Flutter scaffold is in `app/`; Phase 1 pixel canvas, drawing tools,
palette, grid sizing, mirror toggles, and starter generator are in place.

## Generator modes

- **Procedural generator** (default) — fully local, offline, no API key, no cost.
- **Real-AI image mode** (optional, off by default) — uses the Google Gemini
  image API with the user's own key; usable on Gemini's free tier.
