# 01 — Agent Workflow

How many agents build one game without breaking each other's work.

## The seven rules

1. **Own your folder.** Edit only the paths listed for your agent id in [INDEX.md](INDEX.md).
2. **Talk through contracts.** Systems interact only through what [03-contracts.md](03-contracts.md) defines
   (component APIs, `Events` signals, `Registry` data, manager APIs). Never reach into another system's nodes or private state.
3. **Contracts are frozen.** Only `lead` edits `03-contracts.md`, `res://core/`, and `project.godot`.
   Need a change? File a change request (below). Do not work around a contract.
4. **Content is data.** New items, recipes, pieces, crops, animals are `.tres` resources, not code. Adding content must not require code edits.
5. **Server decides.** Every gameplay mutation happens on the host. Clients request. See [04-networking.md](04-networking.md).
6. **Placeholders first.** Never wait for art. Use the grey-box placeholders from `res://core/placeholders/`; art agents swap models later without touching code.
7. **Prove it with two clients.** A feature is not done until it works with host + one joined client (see [qa-testing.md](qa-testing.md)).

## Why these rules

Agents do not share memory. The only things they share are these docs and the repo. So:
interfaces are written down before code, each file has exactly one writer, and the hot-spot files
(`project.godot`, autoloads, the main scene) have a single owner to avoid merge conflicts.

## Git workflow

- `main` is always runnable. `lead` is the only one who merges into it.
- Each task = one branch `agent/<agent-id>/<short-task>` in its own git worktree.
- Small merges (a day of work at most). Rebase on `main` before handing off.
- `.tscn` and `.tres` are text but merge badly: one owner per scene file, no exceptions.
- Commit `.import` files and `*.uid` files; never commit `.godot/`.

## Task brief template

`lead` dispatches every task with this brief. An agent that receives less should ask for the missing parts.

```
AGENT: <agent-id>
TASK: <one sentence outcome>
MILESTONE: <M0..M6>
READ FIRST: docs/INDEX.md core docs, docs/systems/<yours>.md, <dependency docs>
YOU OWN: <paths>
DO NOT TOUCH: everything else (file change requests instead)
DEPENDS ON: <contracts / systems already merged>  |  STUB IF MISSING: <what to fake>
ACCEPTANCE: <checklist copied from the system doc>
VERIFY: <commands / test scenes to run>
REPORT BACK: files changed, how verified (with output), open issues, change requests
```

## Change requests

When you need something outside your folder:

1. Do not edit it. Add an entry to `docs/change-requests.md` (create if missing):
   `- [ ] <date> <from-agent> -> <owner>: <what and why>, blocking: yes/no`
2. Keep working behind a local stub or adapter inside your own folder.
3. `lead` resolves it: updates the contract, or asks the owner to change, then ticks the entry.

## Definition of done

- [ ] Matches the system doc's acceptance list.
- [ ] Runs with no errors or new warnings in the Godot output.
- [ ] Works as host **and** as joined client; late-joining client sees correct state.
- [ ] Survives save → quit → load (if the system holds state).
- [ ] No edits outside owned paths; no new autoloads, input actions, or layers without `lead`.
- [ ] Tests added under `res://tests/<system>/` for logic that can be unit tested.
- [ ] System doc updated if behaviour differs from what it says.
- [ ] Report states what was verified and what was not.

## Reporting honestly

Say exactly what you ran and what happened. "Not tested with two clients" is an acceptable report;
claiming it works without running it is not.

## Verifying engine facts

These docs target Godot **4.7**. API details drift between versions. Before using an engine API you are
not certain of, check the 4.7 documentation (the `context7` MCP or docs.godotengine.org) rather than memory.
