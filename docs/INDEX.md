# New Lands — Documentation Index

**New Lands** is an online co-op (2–4 players) 3D farming/building/colony game in Godot 4.7.
This folder is the single source of truth. If code and docs disagree, fix one of them in the same change.

Every agent reads the **Core** docs first, then its own system doc, then the docs its system depends on.

## Core (everyone reads, in this order)

| # | Doc | What it answers |
|---|-----|-----------------|
| 1 | [00-vision.md](00-vision.md) | What the game is, pillars, scope, non-goals |
| 2 | [01-agent-workflow.md](01-agent-workflow.md) | How agents work in parallel without colliding; task brief template; definition of done |
| 3 | [02-architecture.md](02-architecture.md) | Folder layout, autoloads, scene tree, data-driven content |
| 4 | [03-contracts.md](03-contracts.md) | **Frozen shared interfaces**: IDs, layers, input actions, component APIs, signals |
| 5 | [04-networking.md](04-networking.md) | Host-authoritative model, RPC rules, replication, late join |
| 6 | [05-conventions.md](05-conventions.md) | GDScript style, naming, units, scene rules |

## Systems (one owner each)

| Doc | Owner | Code folder | Depends on |
|-----|-------|-------------|------------|
| [systems/player.md](systems/player.md) | `player` | `res://player/` | net, contracts |
| [systems/survival.md](systems/survival.md) | `survival` | `res://survival/` | player, items |
| [systems/items-inventory.md](systems/items-inventory.md) | `items` | `res://items/` | net, contracts |
| [systems/gathering.md](systems/gathering.md) | `world` | `res://world/` | items, world-time |
| [systems/world-time.md](systems/world-time.md) | `world` | `res://world/` | net |
| [systems/farming.md](systems/farming.md) | `farming` | `res://farming/` | items, world-time |
| [systems/building.md](systems/building.md) | `building` | `res://building/` | items, net |
| [systems/npc-workers.md](systems/npc-workers.md) | `npc` | `res://npc/` | items, building, gathering, economy |
| [systems/economy-merchant.md](systems/economy-merchant.md) | `economy` | `res://economy/` | items, world-time |
| [systems/ui-hud.md](systems/ui-hud.md) | `ui` | `res://ui/` | all gameplay systems (read-only) |
| [systems/save-load.md](systems/save-load.md) | `save` | `res://save/` | all gameplay systems |
| [systems/audio.md](systems/audio.md) | `audio` | `res://audio/` | contracts (Events) |

## Content & art

| Doc | Owner | Output folder |
|-----|-------|---------------|
| [content/art-style.md](content/art-style.md) | `lead` (rules) | — style guide + asset pipeline, all art agents follow it |
| [content/characters.md](content/characters.md) | `art-characters` | `res://assets/characters/` |
| [content/level-island.md](content/level-island.md) | `world` + `art-environment` | `res://levels/`, `res://assets/environment/` |
| [content/item-catalog.md](content/item-catalog.md) | `items` (data), `art-props` (models) | `res://content/`, `res://assets/props/` |

## Process

| Doc | Purpose |
|-----|---------|
| [roadmap.md](roadmap.md) | Milestones M0–M6, what is playable at each, which agents work in parallel |
| [qa-testing.md](qa-testing.md) | Test harness, multiplayer test recipe, per-milestone acceptance |
| [decisions.md](decisions.md) | Decision log (why things are the way they are) + open questions for the human |

## Agent roster

| Agent id | Owns (may edit) | Never edits |
|----------|-----------------|-------------|
| `lead` | `docs/`, `project.godot`, `res://core/`, `res://main/`, merges | — |
| `net` | `res://net/` | gameplay folders |
| `player` | `res://player/` | |
| `survival` | `res://survival/` | |
| `items` | `res://items/`, `res://content/items/`, `res://content/recipes/` | |
| `world` | `res://world/`, `res://levels/`, `res://content/nodes/`, `res://content/animals/` | |
| `farming` | `res://farming/`, `res://content/crops/` | |
| `building` | `res://building/`, `res://content/pieces/` | |
| `npc` | `res://npc/`, `res://content/jobs/` | |
| `economy` | `res://economy/`, `res://content/trades/` | |
| `ui` | `res://ui/` | |
| `save` | `res://save/` | |
| `audio` | `res://audio/`, `res://assets/audio/` | |
| `art-characters` | `res://assets/characters/` | any `.gd` |
| `art-environment` | `res://assets/environment/` | any `.gd` |
| `art-props` | `res://assets/props/` | any `.gd` |
| `qa` | `res://tests/` | production code (files bugs instead) |

Rule of thumb: **you edit only what you own.** Anything else is a change request to its owner
(see [01-agent-workflow.md](01-agent-workflow.md)).

## Status board

Updated by `lead` when a milestone gate passes. See [roadmap.md](roadmap.md).

| Milestone | State |
|-----------|-------|
| M0 Foundation | not started |
| M1 Walk together | not started |
| M2 Survive & gather | not started |
| M3 Build | not started |
| M4 Farm & trade | not started |
| M5 Colony | not started |
| M6 Look & feel | not started |
