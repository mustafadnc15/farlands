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

- Test framework: **GUT v9.7.1**, vendored under `res://addons/gut/` (installed by `lead` in M0; do not upgrade without a change request).
- Tests live in `res://tests/<system>/test_*.gd`.
- Run the whole suite with `tools/run_tests.sh`. It needs the `GODOT` environment variable set to the Godot 4.7 **console** executable (for example `export GODOT=<path to Godot_v4.7.2-stable_win64_console.exe>`), re-imports the project, then runs GUT headless with `-gexit`. Extra GUT arguments are passed through, e.g. a single script: `tools/run_tests.sh -gtest=res://tests/core/test_inventory.gd`.
- Pass means exit code 0 **and** the summary shows the expected script and test counts with every test passing. GUT exits 0 even when a test script fails to parse (the script is silently skipped), so also check the "Scripts" count in the run summary and that the output has no parse errors or warnings. Expected-error lines marked `[ExpectedError]` come from tests that assert on `push_error`/`push_warning` and are fine.
- Import/boot check, run before every hand-off: `"$GODOT" --headless --path . --import`, then `timeout 90 "$GODOT" --headless --path . --quit-after 2`. Prefer `--quit-after <frames>` over plain `--quit`, which has been seen to hang. It must print no errors or warnings.
- Session smoke run (starts the game scene without clicking the menu): `timeout 120 "$GODOT" --headless --path . --quit-after 120 -- --autostart` must exit 0 with no errors.

## Two-client recipe

Debug arguments. `--autostart` (skip the menu and start a session) is implemented. `--host`, `--join`, `--world`, `--port`, `--name` and `--script-driver` are **planned**: the `net` agent implements them in M1.

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
