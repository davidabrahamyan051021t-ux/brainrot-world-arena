# Brainrot World — Main Forest (open-world visual upgrade)

Harvest shouting Brainrot entities in a large stylized forest, earn Coins and XP, buy perks, unlock a
laser, and fight a periodic Gigantic Brainrot.

Gameplay is unchanged: server-authoritative damage, Coins, XP, leveling, the shop, the Laser unlock,
the Gigantic Brainrot boss, the Sonic Wave reward, respawn timers and DataStore saving all still work
exactly as before. This pass rebuilds the **world, the trees and the environment**.

## World scale

| | |
|---|---|
| Playable basin | ~2,200 × 2,200 studs, ringed by an invisible boundary at r = 1,040 |
| Terrain shelf + mountains | ~3,000 studs across (mountains 1,060–1,500 studs from the centre) |
| Spawn glade ↔ central plaza | ~700 studs of road |
| Sub-biomes | 7 + a wilds fill layer |
| Harvest clusters | 11 across the map (33 Small, 11 Elite, 7 Rare = 51 entities) |

2,200 studs of *playable* ground was chosen over a literal 3,000 × 3,000 square: at 16 studs/s walk
speed a 3 km square is mostly empty walking, and every extra stud of terrain costs terrain memory and
prop budget. The visible world still reaches ~3,000 studs, so the map reads as huge without becoming
padding. Widening `WorldPlan.PLAY_RADIUS`/biome radii is a one-file change if you want more.

## Where things are

- **Greatbrain Glade** (spawn, z ≈ 800) — cobbled terrace, the Greatbrain Ancient, shop stall, signposts.
- **Hollowheart Plaza** (0, 0) — boss arena, sigil, 8 pillars, floating beacon, four roads + four trails.
- **Whisperwood** (east) — dense broadleaf forest, the Colossus Ruins.
- **Tanglevine Thicket** (west) — corkscrew candy trees, the Mushroom Ring.
- **Crystal Hollow** (north) — glass trees, Starfall Spire, obsidian ground.
- **Brute Basin** (south-east) — pines, Training Camp, Elite farming.
- **Mirefen** (south-west) — willows, lake, stream, Sunken Arch.
- **Highland Crags** (north-east) — pines and rock, Skyfall Grotto waterfall.
- **Old Watchtower** (mid-map) — three storeys of walkable stairs.

## Brainrot trees

Seven families, each with its own silhouette, bark and canopy language — not one model recoloured:

| Family | Look | Where |
|---|---|---|
| Whisperoak | tapering trunk, buttress roots, 3 branch arms, layered 5-blob canopy with leaf blades and vines | everywhere |
| Gigglepod | squat trunk with a permanent grin (googly eyes, brows, buck teeth), afro canopy, candy pods | dense in Tanglevine |
| Twistpop | corkscrew trunk of 6 offset segments, spiral candy crown, hanging pods | Tanglevine edges |
| Crystalbloom | pale marble trunk, glass collar, shard branches, glowing shard crown + neon fruit | Crystal Hollow (rare) |
| Mirewillow | pale bent trunk, drooping fronds, moss curtains, glowing spore pods | Mirefen |
| Emberpine | stacked conifer tiers, ember tips with sparks | Crags, Brute Basin |
| Greatbrain Ancient | 80-stud braided trunk, 8 buttress roots, carved face, 6 gnarled branches, 9-canopy crown, hanging lanterns, glowing runes | spawn glade |

Trees are built from parts and ellipsoids (no custom meshes exist in this repo), use
`Wood`/`LeafyGrass`/`Grass`/`Marble`/`Glass`/`Neon` materials, and are placed by a seeded jittered
grid so the forest is dense but never a repeatable row. Background trees use a 5–13 part "simple"
build; trees near trails use the full build.

## Mapping the code

```
src/shared/Config.lua          gameplay numbers, rarity identity, boss spawn, STYLE_VERSION
src/shared/Theme.lua           UI design tokens
src/server/WorldBuilder.lua    orchestrator: lighting, roads, forest scatter, harvest spawns, spawn pad
src/server/World/WorldPlan.lua authored layout data (biomes, trails, clearings, water, landmarks, zones)
src/server/World/Placement.lua seeded RNG, Catmull-Rom path sampling, analytic terrain height, spatial hash
src/server/World/Build.lua     part/ellipsoid/cylinder/particle primitives
src/server/World/TerrainBuilder.lua terrain fills, lakes/stream, mountain backdrop, world boundary
src/server/World/TreeFactory.lua     the seven tree families
src/server/World/PropFactory.lua     rocks, undergrowth, crystals, woodwork, ruins, signage
src/server/World/Landmarks.lua       glade, plaza and the eight discoveries
src/server/EntityFactory.lua   Brainrot creature models + name plates
src/client/EntityFX.lua        idle motion, label culling, damage numbers, hit bursts
src/client/HUD.lua             stats panel, boss bar, shop
```

World generation is deterministic (fixed seed in `WorldPlan`), runs once, and is stamped with
`Config.STYLE_VERSION` on the `MainWorldBase` folder. Bump `STYLE_VERSION` to force a rebuild; nothing
player-facing is stored in the world, so a rebuild never touches DataStore progress.

## Sync it with Rojo and test

1. Stop Play mode in Studio.
2. In this folder run:

   ```bash
   rojo serve
   ```

3. In Studio open your existing place → Rojo plugin → **Connect** → wait for "Sync complete".
4. **Enable streaming (recommended, one time):** select `Workspace` → Properties → tick
   **StreamingEnabled** (and optionally set `StreamingTargetRadius` ≈ 700). The world is ~10,300
   anchored parts; streaming keeps only nearby parts loaded. The project does not force this property
   because `default.project.json` deliberately does not manage the Workspace service.
5. Press **Play**. `STYLE_VERSION` is now `4`, so the first server start clears the old arena, terrain
   and entities and builds the new forest (expect a few seconds for terrain; watch the output for
   `[Brainrot World] Built Main Forest: …`).

### What to check

1. You spawn in the Greatbrain Glade facing the plaza; the Greatbrain Ancient stands ahead-left with a
   lit carved face, glowing runes and hanging lanterns.
2. Walk the Glade Road (~700 studs) — curbs, lanterns and a signposted junction; no floating or buried
   road tiles, no trees growing through the road.
3. Plaza: sigil under the boss spawn, 8 pillars, 4 braziers, beacon overhead; the boss still spawns at
   the centre after 45 s (boss bar, shockwave, damage numbers).
4. Walk each trail. Trees, rocks, ferns, flowers, mushrooms and logs sit on the hills (they are sunk
   ~1 stud on purpose); nothing hovers in the air.
5. Harvest: each cluster is an open glade with 3–8 entities, plates readable, coins/XP awarded,
   respawn works. Entities are never in water and never inside the boss arena.
6. Lake/stream in Mirefen: swim into the water, then check the shoreline sand and reeds.
7. Landmarks: climb the watchtower stairs, stand on the grotto deck, walk into Colossus Ruins.
8. Shop (**B**), perk purchases, Laser unlock (level 3 + 150 coins), tool equipping — unchanged.

## Limitations

- **No Studio pass was possible here.** The checks below are the maximum this environment allows;
  lighting, silhouettes and collisions still need your eyes in Studio.
- No custom meshes, textures or audio are shipped, so trees and props are carefully assembled parts,
  Roblox primitives and built-in particle textures. Genuinely "AAA" trees would need imported foliage
  meshes (e.g. a modeller-authored LOD set) — that asset workflow does not exist in this repo.
- The other modes in `Info.txt` (PvP arena, zombie co-op, boss raids) are **not implemented** in this
  project, and there are no portal objects to preserve. The forest is self-contained; adding those
  worlds later means a new module per world plus a travel remote, not a change to this one.
- Trees are decorative. Harvesting still targets the Brainrot creatures (tag `Harvestable`), which are
  visually distinct: they glow, bob and carry a rarity name plate. No economy values were changed.
- Terrain smoothing is voxel-based, so hills have ~2-stud surface softness; props are placed from the
  analytic height minus ~1 stud to guarantee they never float.
- 2,200 studs of world with ~10.4k anchored parts, 339 particle emitters and 130 point lights: fine on
  desktop with StreamingEnabled, heavier without it.

## Verification run

- Luau 0.744 parse check: all 23 `src` files compile.
- Headless execution: the whole world build was run against a mock Roblox API (terrain, part, CFrame,
  CollectionService). 337 trees (4,378 parts), 374 props (2,063 parts), 51 harvestables, 8,013 parts in
  `MainWorldBase`, ~10,400 parts in total with 339 particle emitters and 130 point lights; all part
  transforms finite with positive sizes; no harvestable in water, none inside the boss arena, none
  overlapping another; largest single terrain fill 3.27 M voxels (limit ≈ 4.19 M).
- `rojo build default.project.json` succeeds; the sourcemap shows every module in the right place.

## Controls

- Click / activate the equipped tool to hit a Brainrot in range
- **B** opens the shop (Move Speed, Crit Chance, Max Health, Laser unlock)
- Gigantic Brainrot spawns after 45 s, then every 3 minutes, and lasts 90 s
