# 04 — Networking

Owner: `net`. Every gameplay agent must follow the rules in this doc.

## Model

- **Player-hosted, host-authoritative.** One player hosts; their game instance is the server (peer id `1`) and also a player. Up to 3 clients join.
- Godot high-level multiplayer: `MultiplayerAPI`, `@rpc`, `MultiplayerSpawner`, `MultiplayerSynchronizer`.
- Transport sits behind `Net` so it can be swapped. M1 ships **ENet** (LAN / direct IP, default port `24565`).
  Direct IP / LAN is the only supported way to connect for now (decision D17). Playing over the internet therefore needs the host to forward the port or use a VPN-style LAN tool; a relay is not planned yet.
- The same code must be able to run headless later, so never assume "host has a screen" inside simulation code.

## The five rules

1. **Clients request, host decides.** A client never changes shared state. It calls `request_*` on the host; the host validates and applies.
2. **Validate every request.** Check sender identity, distance, ownership, resources, cooldown. Reject silently (log a warning).
3. **State flows host → clients.** Via synchronizers (continuous) or `sync_*` RPCs (events/deltas).
4. **Late join must work.** Every manager can produce a full snapshot and apply it on a fresh client.
5. **Cosmetics are local.** Animations, particles, sounds, UI never need authority — trigger them from replicated state or `Events`.

## RPC conventions

```gdscript
# Client -> host. Name starts with request_.
@rpc("any_peer", "call_remote", "reliable")
func request_place_piece(piece_id: StringName, xform: Transform3D) -> void:
    if not Net.is_host(): return
    var peer := Net.sender_id()
    ...validate, then apply...

# Host -> everyone. Name starts with sync_.
@rpc("authority", "call_remote", "reliable")
func sync_piece_added(record: Dictionary) -> void: ...
```

Calling pattern from gameplay code (works for host-player and clients alike):

```gdscript
if Net.is_host(): request_place_piece(id, xf)      # direct local call; Net.sender_id() returns 1
else: request_place_piece.rpc_id(1, id, xf)
```

- `reliable` for anything that changes state; `unreliable_ordered` only for high-rate cosmetic streams.
- RPC arguments are primitives, `StringName` ids, `entity_id`s, and small dictionaries. Never nodes or resources.
- Keep RPCs on the manager or the entity root so node paths match on all peers.

## What replicates how

| Thing | Authority | Mechanism |
|-------|-----------|-----------|
| Player movement | **owning client** (trusted co-op), host sanity-checks speed/teleports | `MultiplayerSynchronizer`, ~20 Hz, interpolated on remotes |
| Player inventory, health, hunger | host | synchronizer visible to owner (and to others only for health/equipped item) |
| NPCs, wildlife | host | `MultiplayerSpawner` + synchronizer (position, state, anim), ~10 Hz |
| Build pieces, crops, resource nodes | host | **record tables in managers**, replicated by `sync_*` deltas; no per-object synchronizer |
| Item drops | host | DropManager records + deltas |
| Clock, coins | host | small synchronizer / RPC on change |
| Chat | any → host → all | reliable RPC |

Why record tables: thousands of pieces as individual synchronized nodes would exhaust bandwidth and CPU.
A manager holds `Dictionary[int, Dictionary]` (entity_id → record), sends only changes, and each peer builds the visuals locally from records.

## Join flow

1. Client connects; sends `{game_version, player_id, display_name}`.
2. Host checks version and player count (max 4); rejects with a reason or accepts.
3. Host sends snapshot: clock, coins, then each manager's `get_snapshot()` (chunked reliable RPCs, ≤ 32 KB each).
4. Client applies snapshots, reports ready. Host spawns the player (saved position/inventory if `player_id` is known, else spawn point with starter kit).
5. `Net.player_joined` fires on all peers.

Each replicated manager therefore implements, besides the save contract:

```gdscript
func get_snapshot() -> Dictionary            # host
func apply_snapshot(d: Dictionary) -> void   # client; must fully replace local state
```

`get_snapshot()` may reuse `save_state()` when the shapes match.

## Leave / host quit

- Client leaves: host saves that player's data, despawns them, their carried bulky items drop on the ground.
- Host quits: host autosaves, then all clients return to the menu with "Host ended the session". No host migration in v1.
- Connection lost: same as above after a 10 s timeout.

## Testing

Run two instances from the editor (Debug → Customize Run Instances) or with the CLI recipe in [qa-testing.md](qa-testing.md).
Always test: host acts, client acts, client joins late, client leaves mid-action.
