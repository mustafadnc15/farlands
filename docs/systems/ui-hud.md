# System — UI & HUD

**Owner:** `ui` · **Code:** `res://ui/` · **Depends on:** reads all gameplay systems through contracts · **Milestone:** M1 (menu), then grows each milestone

## Purpose

Every screen and overlay. UI **reads** replicated state and **sends requests** through the owning system's request functions; it holds no game state.

## Screens

| Screen | Opens with | Contents | Milestone |
|--------|-----------|----------|-----------|
| Main menu | boot | New world, Load world, Join (IP:port), Settings, Quit | M1 |
| HUD | always in game | health + hunger bars, hotbar (6), carry indicator, target prompt ("E — Open"), required-tool hint, clock/day, coins, toasts | M2 |
| Inventory | `inventory` | 24 slots, carry slot, crafting list (hand recipes; station recipes when near one), drag & drop, split with RMB | M2 |
| Storage | interact chest | chest grid beside player grid | M3 |
| Build menu | `build_menu` | categories, piece icons, cost, key hints for rotate/snap | M3 |
| Blueprint tooltip | aim at blueprint | missing materials list | M3 |
| Trade | interact merchant | Buy / Sell / Hire tabs | M4 |
| Worker radial | interact worker | commands from [npc-workers.md](npc-workers.md), tool slot | M5 |
| Pause | `pause` | Resume, Settings, Save (host), Invite info (host IP/port), Quit to menu | M1 |
| Player list / chat | `chat`, Tab-hold | names, ping, text chat | M1 |

## Rules

- All UI under one `CanvasLayer`; one `UIManager` decides which screen is open and whether gameplay input is captured. Other systems never toggle mouse mode themselves.
- Bind to signals (`Inventory.changed`, `HealthComponent.changed`, `Events.*`); no polling in `_process` except the target prompt.
- A screen that depends on a system not yet merged must hide itself gracefully.
- Scales from 1280×720 to 4K using the project's `canvas_items` stretch; anchors and containers only, no absolute pixel layouts.
- Keyboard + mouse first; keep focus navigation working so a controller can be added later.

## Visual style

Rounded panels, thick outlines, warm paper/wood tones, big readable icons — details and palette in [content/art-style.md](../content/art-style.md).
One shared `Theme` resource (`ui/theme/new_lands_theme.tres`); no per-control style overrides.
Item/piece icons are rendered from the 3D models by a tool script (`ui/tools/icon_baker.gd`) so they always match.

## Acceptance

- [ ] Each screen works for host and client and reflects changes made by other players live.
- [ ] No screen can be used to send a request the host would reject without the UI showing why (greyed out or toast).
- [ ] Opening any screen never leaves the mouse or input in a stuck state.
- [ ] Readable at 1280×720.

## Out of scope

Map/minimap, quest log, tutorial sequence (a one-page "how to play" panel is enough), localisation beyond English strings wrapped in `tr()`.
