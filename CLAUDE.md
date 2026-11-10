# New Lands

Online co-op (2–4 players) 3D farming/building/colony game. Godot 4.7, GDScript, Jolt, Forward+.

**Start here: [docs/INDEX.md](docs/INDEX.md).** It is the single source of truth and tells you what to read for your role.

Non-negotiables (details in `docs/01-agent-workflow.md`):

1. Edit only the folders your agent id owns (roster in `docs/INDEX.md`). Anything else is a change request.
2. Code against `docs/03-contracts.md`. Only `lead` changes contracts, `res://core/`, or `project.godot`.
3. Host is authoritative: clients send `request_*`, host validates and replicates (`docs/04-networking.md`).
4. Content is `.tres` data under `res://content/`, not code.
5. Done means verified with host + one joined client, and reported honestly.
6. Stay inside v1 scope (`docs/00-vision.md`). New ideas go to `docs/decisions.md`.
