# System — Economy & Merchant

**Owner:** `economy` · **Code:** `res://economy/`, data in `res://content/trades/` · **Depends on:** items, world-time · **Milestone:** M4

## Purpose

Coins, the roadside merchant's buy/sell lists, and the hiring transaction. The merchant is the colony's link to the outside world.

## Behaviour

- **Currency:** coins, an integer held in one **shared colony wallet** (`Economy.coins()`), not per player. Simple for co-op, and wages come from one place.
- **Merchant stall:** fixed spot on the road (see [content/level-island.md](../content/level-island.md)). Open from sunrise to sunset.
- **Trading:** `interact` with the merchant opens the trade UI.
  - *Sell:* any item with `base_value > 0`. Price = `TradeDef.sell_price` if defined, else `floor(base_value × 0.5)`.
  - *Buy:* only items with a `TradeDef`. Stock per item resets on `day_started` (`daily_stock`, −1 unlimited).
  - Requests: `request_buy(trade_id, count)`, `request_sell(slot, count)`; host validates distance (≤ 4 m), stock, coins, inventory space.
- **Hiring:** a "Hire" tab lists up to 3 candidates per day (name, look, job aptitude is cosmetic in v1). Hire fee 50 coins, wage 10 coins/day (exports).
  `request_hire(candidate_index)` → `Economy.spend(fee)` → `NpcManager.hire(...)`. Respect the 8-worker cap.
- **Starter state:** new world starts with 20 coins.

What the merchant sells (data; see catalogue for prices): seeds, iron tools, iron ingots, nails, rope, watering can, bread.
What he never sells: logs, stone, raw food — the island provides those.

## Balance intent

Early game: sell berries, fish, wheat for seeds and a first iron tool. Mid game: a hunter and fisher pay for themselves
(one worker should net roughly 15–25 coins/day after wage if supplied with tools). Keep all numbers in data.

## Networking

Wallet and daily stock are host state, replicated on change (`Events.coins_changed`). The trade UI is local and reads replicated stock.

## Save

`{coins, stock: {trade_id: remaining}, candidates: [...], last_stock_day}`.

## Acceptance

- [ ] Buy/sell update wallet, stock, and inventory atomically; spam-clicking cannot duplicate items or coins.
- [ ] Two players trading at once see consistent stock.
- [ ] Stock and candidates reset once per day.
- [ ] Hiring fails cleanly at cap or without coins.
- [ ] New trade good = one `TradeDef`, no code.

## Out of scope

Dynamic prices, haggling, multiple merchants, caravans, player-to-player trading UI (players can just drop items), taxes.
