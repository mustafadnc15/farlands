# Content — Art Style & Asset Pipeline

**Rules owner:** `lead` · **Followed by:** `art-characters`, `art-environment`, `art-props`, `ui`

## The look

Simple, cute, low-poly. Think toy diorama: chunky shapes, soft colours, no realism.

| Rule | Detail |
|------|--------|
| Shapes | Chunky and slightly exaggerated. Thick handles, big heads, fat tree crowns. Bevel big edges; no thin slivers. |
| Shading | Flat-shaded faces (hard normals) or very soft smooth shading on round things. Pick per asset, not per face. |
| Colour | **One shared palette texture** (`assets/palette.png`, 16 × 16 swatches). Meshes UV-map faces onto swatches. No painted textures, no normal maps. |
| Materials | One shared `StandardMaterial3D` (`assets/mat_palette.tres`): roughness 0.9, metallic 0, no specular highlights. Separate materials only for water, foliage sway, glass, emissive. |
| Detail | Detail comes from silhouette and colour blocks, never from texture noise. |
| Outline | None. |
| Light | Warm sun, soft blue shadows, gentle ambient. Light fog toward the horizon. Nights are blue and readable. |

Palette families: grass greens (4), leaf greens (3), wood browns (4), stone greys (3), sand/dirt (3), water blues (3),
skin tones (5), cloth accents (red, mustard, teal, cream, plum), metal (2), UI paper/ink.

## Budgets

| Asset | Triangles | Notes |
|-------|-----------|-------|
| Player / worker | ≤ 3,000 | shared skeleton |
| Animal | ≤ 1,500 | |
| Tool / held item | ≤ 400 | |
| Small prop / drop | ≤ 300 | |
| Build piece | ≤ 400 (logs ≤ 150) | thousands on screen |
| Tree | ≤ 800 | plus stump variant |
| Rock | ≤ 300 | |

## Technical rules

- Format **glTF binary (`.glb`)**, +Y up, 1 unit = 1 m, transforms applied, origin at the base centre (tools: at the grip).
- Characters face −Z after import. Held items: grip along +Y, working end toward −Z.
- Names: `snake_case`, matching the def id where there is one (`stone_axe.glb`, `wall_plank.glb`).
- Each asset ships as a wrapper scene `<id>.tscn` whose root is the node gameplay scenes instance as `Model`. Collision is **not** in the art scene; system owners add it.
- Build pieces must respect module sizes and snap positions listed in [systems/building.md](../systems/building.md); deliver a dimension sheet with each piece.
- LODs are not needed at these budgets; use visibility range fade for small props beyond 80 m.

## Pipeline

```
1. Brief        system owner lists needed assets with id, size, purpose (from the catalogues)
2. Concept      Higgsfield generate_image: one sheet per asset family on a plain background, palette-locked
                -> saved to docs/art/concepts/, approved by the human for each *family* (not each asset)
3. Model        route A: Higgsfield generate_3d from the approved concept -> GLB
                route B: hand/procedural modelling (Blender via MCP or script) for anything modular or snapping
                route C: freely licensed kit asset (CC0 preferred, decision D18) restyled to the palette
4. Cleanup      decimate to budget, flat-shade, remap to palette, fix scale/origin/orientation  (needs Blender)
5. Import       .glb + wrapper .tscn into res://assets/..., check in the style test scene
6. Swap         replace the placeholder Model in the gameplay scene (change request to the owner if not yours)
```

Honest caveats for step 3A: image-to-3D output is usually dense, textured, and not rigged. It is fine for
organic one-offs (rocks, animals, trees, props) after cleanup. It is a poor fit for **modular build pieces**
(need exact dimensions) and **characters** (need a clean rig) — use route B/C for those.

## Concept prompt base (prepend to every Higgsfield image prompt)

> cute low-poly 3D game asset, chunky toy-like proportions, flat shaded, solid pastel colours, no textures,
> soft studio light, plain light-grey background, three-quarter view, single object centred

Add the asset description and the palette family. Keep one seed/reference image per family for consistency.

## Style test scene

`res://assets/style_test.tscn` (owned by `art-environment`): the standard lighting rig, a player model, a tree, a rock,
a wall piece, and a ground patch. Every new asset is screenshotted here next to the references before it is accepted.

## Acceptance for any asset

- [ ] Within triangle budget, palette material only, correct scale/origin/orientation.
- [ ] Reads clearly at gameplay camera distance (5–15 m) in the style test scene, day and night.
- [ ] Sits visually with existing assets (same chunkiness, same saturation).
- [ ] Source prompt/reference and licence recorded in `assets/CREDITS.md`.
