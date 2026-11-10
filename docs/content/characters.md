# Content — Characters

**Owner:** `art-characters` · **Output:** `res://assets/characters/` · **Follows:** [art-style.md](art-style.md) · **Milestone:** placeholder M1, final M6

## Cast

| Character | Variants | Notes |
|-----------|----------|-------|
| Settler (players + workers) | 1 body, 4 skin tones, 6 hair styles, 6 outfits, 4 hats | Players pick a look in the menu; workers get a random one |
| Merchant | 1 unique | Round, friendly, big hat, apron, backpack of wares. Must read as "trader" from 30 m |
| Rabbit, Deer, Boar | 1 each | Simple rigs, big heads, small legs |

## Proportions

About 3 heads tall, large head and hands, short legs, no fingers (mitten hands), dot eyes, no mouth animation.
Height 1.7 m to match the gameplay capsule (the merchant may be wider, not taller).

## Rig

- **One shared humanoid skeleton** for settlers and merchant so every animation works on every variant.
  Bones: root, hips, spine, chest, neck, head, shoulder/upper_arm/lower_arm/hand (L/R), upper_leg/lower_leg/foot (L/R). No finger or face bones.
- Bone attachments required: `hand_r` (tools), `hand_l` (rod support), `shoulder_r` (carried logs), `back` (stowed tool), `head_top` (hats).
- Variants are separate mesh parts skinned to the same skeleton (body, hair, outfit, hat), toggled by a `CharacterLook` script from `{skin, hair, outfit, hat}` indices — replicated by `player`/`npc`.
- Use Godot's skeleton retargeting (`SkeletonProfileHumanoid`) on import so externally sourced animations fit.

## Animation list (names are a contract with `player` and `npc`)

Settler: `idle`, `walk`, `run`, `jump`, `fall`, `land`, `swing_axe`, `swing_pick`, `swing_hammer`, `swing_hoe`,
`spear_thrust`, `spear_aim`, `spear_throw`, `rod_cast`, `rod_idle`, `rod_reel`, `water`, `carry_idle`, `carry_walk`,
`pickup`, `eat`, `sit`, `sleep`, `hurt`, `die`, `wave`, `talk`.

Animals: `idle`, `graze`, `walk`, `run`, `alert`, `hurt`, `die`; boar adds `charge`.

Rules: loops are seamless; action clips are ≤ 0.8 s with the impact frame marked by a method-call track `anim_hit()`
(gameplay timing and audio hang off it); snappy, bouncy timing with a little squash rather than realistic motion.

## Delivery

`settler.tscn` (root `Model`, contains skeleton, mesh parts, `AnimationPlayer`, `CharacterLook`), `merchant.tscn`, `rabbit.tscn`, `deer.tscn`, `boar.tscn`.
Until these exist, everyone uses `core/placeholders/capsule_character.tscn`, which exposes the same animation names as empty clips.

## Acceptance

- [ ] All listed animations exist with exact names and play on every variant without mesh tearing.
- [ ] Tools sit correctly in `hand_r` for every swing; logs sit on `shoulder_r` in carry clips.
- [ ] 4 players + 8 workers on screen stay within triangle and skinning budget.
- [ ] Swapping placeholder → final model requires no script changes.

## Sourcing note

A clean rig and ~27 animations are the most expensive art in the project. Start from a CC0 rigged low-poly base
(e.g. KayKit / Quaternius style kits) and restyle to our palette, rather than rigging an AI-generated mesh.
Approved by the human (decision D18 in [decisions.md](../decisions.md)); record source and licence in `assets/CREDITS.md`.
