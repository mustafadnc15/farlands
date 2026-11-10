# Content — Item Catalogue

**Data owner:** `items` (`res://content/items/`, `recipes/`) · **Trades:** `economy` (`res://content/trades/`) · **Models:** `art-props` (`res://assets/props/`)

All numbers are starting values and live in `.tres` data. `value` = `base_value` in coins; default sell price is half of it.

## Materials

| id | Stack | Bulky | Value | Source |
|----|-------|-------|-------|--------|
| `stick` | 20 | no | 1 | trees, loose |
| `fibre` | 20 | no | 1 | fibre grass |
| `stone` | 20 | no | 2 | rocks, loose |
| `log` | 3 | **yes** | 4 | trees |
| `plank` | 6 | **yes** | 3 | craft from log |
| `stone_block` | 2 | **yes** | 6 | craft from stone |
| `thatch` | 10 | no | 2 | craft from fibre |
| `rope` | 10 | no | 6 | craft from fibre / buy |
| `hide` | 10 | no | 8 | animals |
| `iron_ore` | 10 | no | 10 | ore rocks |
| `iron_ingot` | 10 | no | 30 | buy (smelting is out of scope v1; ore is a trade good) |
| `nails` | 50 | no | 1 | buy |

## Food

| id | Stack | Hunger | Health | Value | Source |
|----|-------|--------|--------|-------|--------|
| `berries` | 20 | 6 | 0 | 2 | bushes |
| `carrot` | 20 | 10 | 0 | 4 | farm |
| `potato` | 20 | 8 | 0 | 4 | farm |
| `tomato` | 20 | 10 | 2 | 5 | farm |
| `wheat` | 20 | 2 | 0 | 3 | farm |
| `raw_meat` | 10 | 8 | −5 | 5 | butcher carcass |
| `fish_small` / `fish_large` | 10 | 6 / 10 | −3 | 6 / 12 | fishing |
| `cooked_meat` | 10 | 35 | 5 | 12 | campfire |
| `cooked_fish` / `cooked_fish_large` | 10 | 25 / 40 | 5 | 12 / 22 | campfire |
| `dough` | 10 | 4 | 0 | 6 | workbench (wheat ×3) |
| `baked_potato` | 10 | 22 | 2 | 8 | campfire |
| `bread` | 10 | 30 | 2 | 10 | workbench→campfire, or buy |
| `stew` | 5 | 60 | 15 | 30 | campfire |

Carcasses (`carcass_rabbit`, `carcass_deer`, `carcass_boar`): bulky, stack 1, value 10 / 30 / 40. Butcher at a campfire or workbench into meat + hide, or sell whole.

## Tools

| id | Type | Power | Durability | Reach | Obtained |
|----|------|-------|------------|-------|----------|
| `stone_axe` / `iron_axe` | axe | 10 / 20 | 60 / 200 | 2.5 | craft / buy 60 |
| `stone_pickaxe` / `iron_pickaxe` | pickaxe | 10 / 20 | 60 / 200 | 2.5 | craft / buy 60 (iron needed for ore) |
| `wooden_hammer` / `iron_hammer` | hammer | — | 150 / 500 | 4 | craft / buy 40 (iron: dismantle refunds 75 %) |
| `wooden_spear` / `iron_spear` | spear | 15 / 30 | 40 / 150 | 3 (throw 20) | craft / buy 50 |
| `stone_hoe` / `iron_hoe` | hoe | — | 80 / 250 | 2.5 | craft / buy 40 (iron tills 2 patches wide) |
| `fishing_rod` | rod | — | 50 | 12 (cast) | craft |
| `watering_can` | can | — | ∞ (10 charges) | 2.5 | buy 25 |

Starter kit for a new player: `stone_axe`, `berries ×5`.

## Seeds

`wheat_seeds` 2, `carrot_seeds` 3, `potato_seeds` 4, `tomato_seeds` 6 coins each at the merchant (stack 20).

## Recipes

| Output | Inputs | Station |
|--------|--------|---------|
| `stone_axe` | stick 2, stone 2, fibre 2 | hand |
| `stone_pickaxe` | stick 2, stone 3, fibre 2 | hand |
| `wooden_hammer` | stick 1, log 1 | hand |
| `wooden_spear` | stick 3, stone 1 | hand |
| `stone_hoe` | stick 2, stone 1, fibre 2 | hand |
| `thatch ×2` | fibre 4 | hand |
| `rope` | fibre 6 | hand |
| `fishing_rod` | stick 3, rope 1 | workbench |
| `plank ×2` | log 1 | workbench |
| `stone_block` | stone 4 | workbench |
| `dough` → `bread` | wheat 3 → dough 1 | workbench → campfire |
| `cooked_meat`, `cooked_fish`, `cooked_fish_large`, `baked_potato` | 1 raw each | campfire |
| `stew` | cooked_meat 1, potato 1, carrot 1 | campfire |
| butcher `carcass_*` | carcass 1 → meat + hide per animal table | campfire or workbench |

## Merchant list (`TradeDef`s)

Buys from players: everything with a value (default half). Better-than-default sell prices: `hide` 6, `iron_ore` 8, `stew` 20.
Sells: seeds (stock 20 each/day), iron tools (1 each/day), `watering_can` (1), `iron_ingot` 30 (5), `nails` 1 (100), `rope` 6 (10), `bread` 10 (5).

## Build piece costs (owned by `building`, listed here for balance in one place)

| Piece | Cost |
|-------|------|
| `log_single`, `pillar_log`, `beam_log` | log 1 |
| `wall_log`, `foundation_log` | log 4 |
| `floor_plank`, `wall_plank` | plank 4, nails 4 |
| `wall_window`, `doorway` | plank 3, nails 4 |
| `door`, `gate` | plank 2, rope 1 |
| `stairs_plank` | plank 4, log 1 |
| `roof_thatch_slope`, `roof_thatch_ridge` | stick 4, thatch 4 |
| `fence_post` / `fence_rail` | stick 2 / stick 2 |
| `stone_block` (piece) | stone_block 1 |
| `campfire` | stone 6, stick 4 |
| `workbench` | log 2, plank 2 |
| `storage_chest` | plank 4, nails 6 |
| `bed` | log 2, thatch 6, hide 1 |
| `torch_post` | stick 2, fibre 2 |
| `sign`, `bench`, `table`, `planter`, `ladder`, `platform_small` | plank 1–4 |

## Adding content

1. Add the row here. 2. Create the `.tres` def(s). 3. Request the model from `art-props` (use a placeholder meanwhile). 4. No code changes — if you need one, the system is missing a feature: file a change request.
