# 00 — Vision

## One sentence

Friends land on a quiet, nearly flat island with a road through it, and turn it into a colony:
they gather, farm, build anything anywhere, trade with a roadside merchant, and hire workers.

## Pillars (use these to settle design arguments)

1. **Build anything, anywhere.** Free placement with optional snapping, like *The Forest*. No plots, no grid, no build zones.
2. **Cozy survival, not punishing survival.** Hunger and health exist to give the day a rhythm, not to kill players often.
3. **Together.** Every system must work with 2–4 players at once. If it only works solo, it is not done.
4. **A colony that works for you.** Hired NPCs fish, hunt, and carry. They never build — building stays the players' creative act.
5. **Simple and cute.** Low-poly, flat colours, chunky shapes. Readability beats detail.

## Fixed facts

| Topic | Decision |
|-------|----------|
| Engine | Godot 4.7, Forward+, Jolt Physics, GDScript |
| Players | 2–4 online co-op, one player hosts (host is the authoritative server) |
| Camera | Third-person, over-the-shoulder when building |
| World | One hand-authored island, about 400 × 400 m, near flat, one road crossing it |
| Session | Endless sandbox. No story, no win condition, no end |
| Platform | Windows desktop first, keyboard + mouse; controller later |

## Core loop

```
gather (wood, stone, fibre, food)
   -> craft tools -> gather faster / farm / fish / hunt
   -> build shelter, storage, farm plots
   -> sell surplus to merchant -> coins
   -> buy seeds, metal tools, hire workers
   -> workers supply food and haul materials -> bigger builds
```

## In scope (v1)

- Survival: health, hunger, death and respawn.
- Tools: axe, pickaxe, hammer, spear, hoe, fishing rod, watering can — stone tier (crafted) and iron tier (bought).
- Gathering: trees, rocks, bushes, fishing spots, wildlife (rabbit, deer, boar). Everything regrows/respawns.
- Farming: till soil anywhere on grass, plant, water, harvest.
- Building: ghost blueprints, haul materials to complete, snapping, dismantle; storage, bed, campfire, workbench.
- Merchant: buy/sell for coins, daily stock.
- Hired NPCs: follow, stay, carry/haul, fish, hunt.
- Day/night cycle. Host save/load with autosave.

## Out of scope (v1) — do not build, do not leave hooks for

- Story, quests, dialogue trees.
- Hostile raids, PvP, combat depth beyond hunting.
- Stamina, thirst, temperature, sanity, seasons, weather.
- Structural collapse / physics destruction of buildings.
- Procedural world generation, multiple islands, boats.
- Dedicated servers, matchmaking, accounts.
- NPC needs/moods, NPC building.
- Skill trees, XP.

Ideas outside this list go to "Open questions" in [decisions.md](decisions.md), not into code.

## Tone note

Players are settlers founding a colony on an uninhabited island. Friendly, storybook tone: the merchant
and workers are cheerful collaborators who are paid for their work.
