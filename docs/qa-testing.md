# QA & Testing

**Owner:** `qa` · **Code:** `res://tests/` · Every agent writes tests for its own system; `qa` owns the harness, integration tests, and milestone gates.

## Layers

| Layer | What | Who | When |
|-------|------|-----|------|
| Unit | Pure logic: `Inventory`, cost checks, growth maths, snap matching, save round-trips | system owner | with the feature |
| Scene | One system in a minimal scene, host-only (no network): place piece, hit node, grow crop | system owner | with the feature |
| Multiplayer | Two processes, scripted host + client | `qa` (+ owner) | before merge of networked features |
| Gate | The milestone script in [roadmap.md](roadmap.md), played by hand or by a driver script | `qa` | end of milestone |
| Soak | 4 clients (bots walking, building, trading) for 60 min; watch errors, memory, bandwidth | `qa` | M3 onward |

## Harness

- Test framework: **GUT** (Godot Unit Test) under `res://addons/gut/` — installed by `lead` in M0. Verify the release that supports Godot 4.7 before installing.
- Tests live in `res://tests/<system>/test_*.gd`.
- Headless run (set `GODOT` to the editor executable path):

```bash
"$GODOT" --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests -ginclude_subdirs -gexit
```

- Import/parse check, run before every hand-off: `"$GODOT" --headless --path . --import` then `"$GODOT" --headless --path . --quit` — must print no errors.

## Two-client recipe

The game accepts debug arguments (implemented by `net` in M1):

```bash
"$GODOT" --path . -- --host --world=test --port=24565 &
"$GODOT" --path . -- --join=127.0.0.1:24565 --name=Client1 &
```

- Add `--headless` for scripted runs; `--script-driver=res://tests/drivers/<name>.gd` runs a driver that performs actions and asserts, then exits with code 0/1.
- Simulate bad networks in every multiplayer test at least once: 100 ms latency, 2 % loss (debug options on the ENet peer wrapper in `net`).

## Standard multiplayer checklist (apply to every networked feature)

- [ ] Host performs the action → client sees it.
- [ ] Client performs the action → host and other client see it.
- [ ] Two peers perform conflicting actions at once → exactly one wins, no duplication.
- [ ] Client joins **after** the action → sees the correct state.
- [ ] Client leaves **during** the action → no stuck state on the host.
- [ ] Forged request (wrong distance / missing items / wrong owner) → rejected.
- [ ] Save → load → state identical.

## Bug reports

`docs/bugs.md` (create when needed), one entry per bug:
`- [ ] <id> <system> <severity> — steps, expected, actual, host/client, build commit`. `qa` never fixes production code; the owner does.

## Performance checks (from M3)

Use the built-in monitors and profiler: frame time, physics time, draw calls, node count, network bytes/s.
Stress scenes under `res://tests/stress/` spawn 5,000 pieces, 1,500 nodes, 8 workers, 20 animals. Budgets are in [02-architecture.md](02-architecture.md).
