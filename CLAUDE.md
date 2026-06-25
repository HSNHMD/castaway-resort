# Castaway Resort (Godot 4)

A low-poly 3D island resort tycoon. Start stranded with no money, forage to build
your first hut, draw in guests, and grow into a fly-in resort — while keeping power,
water, and staff ahead of demand or the reviews sink you.

## Architecture — the one rule
- scripts/sim/Simulation.gd is the game brain: pure GDScript, RefCounted, NO nodes,
  NO scene tree, NO rendering. All economy, capacity systems, satisfaction/rating,
  guests, reviews, and events live here.
- Scenes and UI only READ sim state and CALL sim methods. Never put game logic in a
  scene or in the HUD. This separation is load-bearing — keep it.

## Balance
- Tuned constants live at the top of Simulation.gd (see build kit §3). They're
  validated from prototypes; don't retune casually. Change in one place, note why.

## Style
- Godot 4.3+. GDScript, typed where it helps. Small scripts, one job each.
- Low-poly visual style (Islanders / Townscaper). Primitive placeholders until .glb
  assets are in assets/models/.
- Forward+ renderer on desktop, Mobile renderer for phone export.

## Build order
- P0: project scaffold (done)
- P1: Simulation.gd brain + headless test (done)
- P2: Island.tscn environment
- P3: CameraRig.tscn gimbal camera
- P4: tap-to-place + BuildingFactory
- P5: HUD bound to sim
- P6: real GLB assets
- P7: depth + persistence (storm repair, save/load)
- P8: polish + export

## Reference
- Full design in docs/GDD.md.
- Build kit: castaway-resort-GODOT-BUILD-KIT.md (in Downloads)
