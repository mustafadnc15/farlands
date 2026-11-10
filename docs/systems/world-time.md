# System — World Clock (day/night)

**Owner:** `world` · **Code:** `res://world/clock/` (autoload `WorldClock`) · **Depends on:** net · **Milestone:** M2

## Purpose

One shared clock that drives lighting and every "per day" rule (crop growth, respawns, wages, merchant stock).

## Behaviour

- One in-game day = **20 real minutes** (export). `time_of_day` 0–1: 0.25 sunrise, 0.5 noon, 0.75 sunset; night is 0.8–0.2.
- `day` starts at 1 and only increases. `day_started(day)` fires at 0.25 on host and clients.
- Lighting: rotate the `DirectionalLight3D`, blend sky colours and ambient energy along a gradient resource. Nights stay readable (blue, moonlit, never black).
- Night skip: `WorldClock.skip_to_morning()` (host only), called by `survival` when everyone sleeps.
- The clock pauses when the host pauses with no clients connected; never otherwise.

## Rules for consumers

- Per-day logic runs **on the host** in response to `day_started`. Do not poll `time_of_day` for gameplay.
- Durations in data are in days (`grow_days`, `respawn_days`). Store absolute target days (`ready_on_day`) in records, not countdowns.

## Networking

Host owns the clock. Clients receive `day` and `time_of_day` on join and a correction every 5 s; they advance locally in between.

## Save

`{day, time_of_day}`.

## Acceptance

- [ ] Clients stay within 0.5 s of host time after 30 minutes.
- [ ] `day_started` fires exactly once per day on every peer, including after night skip.
- [ ] Late joiner gets the right lighting immediately.

## Out of scope

Weather, seasons, calendar, moon phases.
