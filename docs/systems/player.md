# System — Player

**Owner:** `player` · **Code:** `res://player/` · **Depends on:** net, contracts · **Milestone:** M1

## Purpose

The controllable character: movement, third-person camera, targeting, and turning input into requests
(interact, use tool). It hosts the components other systems fill in (inventory, health, hunger).

## Behaviour

- `CharacterBody3D`, capsule 1.7 × 0.35 m. Walk 4 m/s, sprint 6.5 m/s, jump 1.1 m, gravity 20 m/s². Carrying a bulky item: no sprint.
- **Camera:** spring-arm orbit, mouse look, 3.5 m default distance, scroll to zoom 2–6 m, collides with terrain and pieces.
  In build mode and while aiming the spear it shifts to over-the-shoulder (1.8 m, offset right) with a centre reticle.
- **Targeting:** one ray from the camera through screen centre, clipped to `reach` from the character (default 3 m, tools override).
  Result is published locally as `current_target` (entity_id, kind, hit position, normal) for UI and other systems.
- **Interact (`interact`):** if the target has an `Interactable`, send `request_interact(entity_id)`.
- **Use tool (`use_tool`):** play swing locally at once, send `request_use_tool(target_entity_id, hit_pos)`; host routes by tool type and target layer:
  node → `NodeManager.apply_hit`, animal → damage, soil → farming, blueprint/piece with hammer → building. Routing table lives in `player/tool_router.gd` and calls only contract APIs.
- **Hotbar:** `hotbar_1..6` selects a slot of `inventory`; the equipped item's `Model` attaches to the right-hand bone attachment.
- **Animation states:** idle, walk, run, jump/fall, swing (axe/pick/hammer/hoe), thrust (spear), cast/reel (rod), carry (bulky), eat, sit/sleep, die. The `Model` child supplies an `AnimationPlayer` with these names (see [content/characters.md](../content/characters.md)).

## Networking

- Movement authority is the **owning client**; position, yaw, velocity, anim state synchronised at ~20 Hz; remote copies interpolate.
- Host sanity check: reject positions implying > 12 m/s sustained and snap the player back.
- Everything else (inventory, health, equip) is host-authoritative; the client only sends requests.
- Player scene is spawned by `net` under `World/Players`, named by peer id.

## Public surface (see contracts §8)

`inventory`, `carry`, `health`, `peer_id`, `player_id`, `get_equipped()`, `current_target`, signal `equipped_changed(item_id)`.

## Acceptance

- [ ] Two players see each other move, jump and animate smoothly (no visible jitter at 100 ms simulated latency).
- [ ] Camera never clips through terrain or buildings.
- [ ] Interact prompt appears for interactables in reach and triggers `interacted` on the host.
- [ ] Tool use reaches the right system through the router for each tool type.
- [ ] Equipped item is visible in hand to all peers.
- [ ] Works with placeholder capsule model and with the final character model without code changes.

## Out of scope

Stamina, crouch, swimming (water deeper than 1 m pushes the player back to shore), mounts, emotes, first-person.
