# 05 — Conventions

## GDScript

- Follow the official GDScript style guide. Tabs for indentation (matches `.editorconfig`).
- **Static typing everywhere**: typed vars, params, returns, typed arrays/dictionaries. Treat untyped-declaration warnings as errors.
- `class_name` for anything used from another file. One class per file.
- File order: `class_name`/`extends`, signals, enums, constants, `@export`, public vars, private vars (`_name`), `@onready`, built-in callbacks, public methods, private methods, RPCs last.
- Use `StringName` literals (`&"log"`) for ids. Never compare ids as plain strings built at runtime.
- No `get_node("../../Something")` across system boundaries. Use contracts, groups, or exported node references.
- No logic in `_process` that can be a signal or a timer. Host-only simulation starts with `if not Net.is_host(): return`.
- Comments explain why, not what. Public methods get a one-line `##` doc comment.

## Naming

| Kind | Style | Example |
|------|-------|---------|
| Files, folders | `snake_case` | `build_manager.gd`, `wall_plank.tres` |
| Classes, nodes | `PascalCase` | `BuildManager` |
| Functions, vars | `snake_case` | `apply_hit` |
| Constants, enums values | `CONSTANT_CASE` | `MAX_WORKERS` |
| Signals | past tense | `piece_completed` |
| Client→host RPC | `request_*` | `request_plant` |
| Host→client RPC | `sync_*` | `sync_crop_stage` |
| Def files | `<id>.tres` in its type folder | `content/items/stone_axe.tres` |

## Scenes

- One root script per scene; the scene works when instanced on its own (no hidden dependency on siblings).
- One owner per `.tscn`. To use another system's scene, instance it; to change it, file a change request.
- Visual model is always a child node named `Model`, so art can be swapped without touching scripts.
- Collision shapes are simple primitives (box/capsule/convex). Trimesh only for terrain.

## Tunables

Gameplay numbers live in data (`.tres` defs) or in `@export` vars on the manager, never as literals buried in logic.
The numbers in these docs are starting values; change them in data and note the change in the system doc.

## Logging

`print` only in tests and tools. Use `push_warning` for rejected requests and recoverable problems, `push_error` for bugs.
Prefix with the system: `push_warning("[build] rejected place from peer %d: too far" % peer)`.

## Text

All player-facing strings go through `tr()` with English source text. No hard-coded UI strings in logic scripts.
