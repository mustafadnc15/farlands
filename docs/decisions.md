# Decisions & Open Questions

Append-only log. Newest at the bottom. Only `lead` edits; anyone may propose through a change request.

## Decided

| # | Date | Decision | Why |
|---|------|----------|-----|
| D1 | 2026-11-10 | Godot 4.7, GDScript, Forward+, Jolt | Set by the project; GDScript keeps every agent in one language |
| D2 | 2026-11-10 | Player-hosted, host-authoritative, 2–4 players | Chosen by the human. No server costs; same code can go headless later |
| D3 | 2026-11-10 | Third-person camera, over-the-shoulder in build mode | Chosen by the human. Shows the characters; shoulder view gives placement precision |
| D4 | 2026-11-10 | Free placement with optional snapping; ghost blueprints completed by hauling | Chosen by the human. Matches "The Forest" freedom while keeping tidy builds possible |
| D5 | 2026-11-10 | Movement is client-authoritative with host sanity checks; everything else host-authoritative | Friends-only co-op: responsiveness matters more than anti-cheat; avoids prediction/reconciliation code |
| D6 | 2026-11-10 | Mass objects (pieces, nodes, crops, drops) replicate as manager record tables, not per-node synchronizers | Thousands of objects; keeps bandwidth, join time and saves manageable |
| D7 | 2026-11-10 | Content is `.tres` data loaded by `Registry` | Content agents add items/pieces without touching code or each other |
| D8 | 2026-11-10 | One owner per folder; `project.godot`, `core/`, contracts owned by `lead` only | Parallel agents with no shared memory need single-writer files |
| D9 | 2026-11-10 | Bulky materials use a carry slot instead of the backpack | Makes hauling physical like The Forest and gives hired carriers a real job |
| D10 | 2026-11-10 | Shared colony wallet | Simplest co-op economy; wages have one source |
| D11 | 2026-11-10 | No structural integrity, no terrain editing | Biggest complexity/risk for least fun in v1; keeps "build anywhere" reliable |
| D12 | 2026-11-10 | Hand-authored single island; resources regrow | Endless play without procedural generation |
| D13 | 2026-11-10 | Health + hunger only | Requested "survival basics"; cozy tone |
| D14 | 2026-11-10 | Workers: follow, stay, carry, haul, fish, hunt. Never build | As specified by the human |
| D15 | 2026-11-10 | JSON saves, host only | Debuggable by agents; clients get state from snapshots |
| D16 | 2026-11-10 | Modular build pieces and characters are modelled by hand/script or from kits, not image-to-3D | They need exact dimensions / clean rigs that image-to-3D does not give |
| D17 | 2026-11-10 | Direct IP / LAN only (ENet). No Steam, no relay for now | Chosen by the human. Transport stays behind `Net` so a relay can be added later |
| D18 | 2026-11-10 | No assets are supplied by the human. Agents may source freely licensed assets (CC0 preferred: KayKit, Quaternius, Kenney) or generate them (Higgsfield), for placeholders and for final art | Chosen by the human. Every sourced file must have its source and licence in `assets/CREDITS.md`; no asset with unclear or non-commercial licence |

## Open questions for the human

| # | Question | Default if unanswered | Needed by |
|---|----------|-----------------------|-----------|
| Q3 | Should a worker be able to farm or chop wood later? | No in v1 (fish, hunt, carry only) | after M5 |
| Q4 | Day length 20 real minutes — right pace? | 20 min | M2 |
| Q5 | Should death drop the inventory (current) or keep it (cozier)? | Drop as a lootable bag | M2 |
| Q6 | Is there any threat besides hunger and boars (e.g. night creatures)? | No | after M5 |
| Q7 | Player character customisation at start (skin/hair/outfit picker)? | Yes, simple picker | M6 |

## Tooling requests (things that would help the agents)

| Need | For | Status |
|------|-----|--------|
| Godot 4.7 executable path on PATH or in a `GODOT` env var | headless import checks, tests, two-client runs | **needed for M0** |
| A Godot MCP (run project, read errors, capture screenshots, edit scenes) | agents verifying their own work visually | strongly recommended |
| Blender + Blender MCP | mesh cleanup, palette remap, modular pieces, rigging | **needed for final art** |
| Higgsfield MCP | concept sheets, image-to-3D for organic props | available |
| ElevenLabs MCP | sound effects | available |
| context7 MCP | up-to-date Godot 4.7 API docs | available (needs sign-in) |
| Git repository (+ GitHub remote if wanted) | branches/worktrees per agent | not initialised yet; GitHub MCP currently fails to connect |
