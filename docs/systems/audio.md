# System — Audio

**Owner:** `audio` · **Code:** `res://audio/` (autoload `AudioDirector`), assets in `res://assets/audio/` · **Depends on:** `Events` · **Milestone:** M6 (hooks from M2)

## Purpose

Sound effects, ambience and music — added without any gameplay system needing to know about audio.

## How it works

- `AudioDirector` subscribes to `Events` signals and plays the mapped sound at the entity's position. Mapping is data: `audio/sound_map.tres` (`event name [+ tool_type / def id]` → `AudioStream` list with random pitch ±5 %).
- Gameplay code **never** calls audio directly. Need a sound for something with no event? Request a new `Events` signal from `lead`.
- Footsteps and animation-timed sounds are triggered by animation tracks calling a method on the character's `Model` scene, which forwards to `AudioDirector`.
- Buses: `Master` → `Music`, `SFX`, `Ambience`, `UI`. Volume sliders in settings.
- 3D sounds use `AudioStreamPlayer3D` from a pool (max 24 voices), attenuation 25 m.

## Content list (v1)

- **Tools:** axe chop (wood), pick hit (stone), hammer knock, hoe dig, spear thrust/throw/hit, rod cast/bite/reel, watering.
- **World:** tree fall, rock crumble, bush rustle, item pickup, drop, piece placed, piece completed, dismantle, door, chest open/close.
- **Characters:** footsteps (grass, dirt road, wood), jump/land, eat, hurt, death, worker acknowledgement blips (non-verbal).
- **Animals:** rabbit, deer, boar idle/alert/hurt.
- **UI:** click, open/close, craft done, coins, error.
- **Ambience:** day birds/wind, night crickets, shore waves, campfire crackle.
- **Music:** 2–3 calm looping tracks by day, 1 by night, low volume, long gaps.

Style: soft, rounded, slightly toy-like to match the visuals. No harsh or realistic gore sounds.

## Sourcing

Generated (ElevenLabs sound effects / Higgsfield audio via MCP) or CC0 libraries. Record source and licence for every file in `assets/audio/CREDITS.md`.
Format: `.ogg` for music/ambience loops, `.wav` for short SFX; mono for 3D sounds.

## Acceptance

- [ ] Every item in the content list plays at the right moment on all peers.
- [ ] No sound plays twice for one event on the host-player.
- [ ] Removing `AudioDirector` from autoloads leaves the game fully functional (proves the decoupling).

## Out of scope

Voice acting, voice chat, dynamic/adaptive music.
