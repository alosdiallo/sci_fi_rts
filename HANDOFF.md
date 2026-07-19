# Session Handoff

## Project

**Red Dust, Cold Iron** is the working title of an early technical-prototype Godot project for a classic 2D pixel-art science-fiction RTS inspired mechanically by late-1990s RTS games such as *Dune 2000*. Milestone 1 is complete. Milestone 2 cleanup still awaits full manual regression, while navigation architecture planning is now active.

## Confirmed

- Single-player first; two asymmetric playable factions.
- All playable missions in version one take place on Mars.
- The **Free Settlements of Mars** is the confirmed Martian faction.
- Its military is the **Free Settlements Army**, a conventional home-territory force with established bases, local industry, combined arms, specialized equipment, and sustained territorial warfare.
- The opposing force is an expeditionary Marine force from the Earth–Moon system; its more specific organizational name and sponsoring political authority remain unresolved.
- The Marines operate with fewer personnel and constrained logistics, emphasizing adaptability, mobility, ingenuity, modular equipment, drones, and multi-role platforms.
- Neither faction is a simplistic weak swarm or universally superior elite force.
- The initial roster direction emphasizes selectable infantry squads, Mars-capable buggies and rovers, reconnaissance and support drones, and engineering and logistics units.
- Walkers are removed from the version-one direction; conventional atmospheric hovercraft are not currently approved.
- Long-term loop: construction, gathering, production, simple deterministic combat, and scripted campaign missions.
- Limited on-screen unit counts and minimal physics.
- Modular, data-driven unit and building definitions.
- Roughly 40 total units/buildings is a long-term ceiling, not prototype scope.
- First version excludes multiplayer, procedural campaign, advanced physics, and 3D graphics.
- Milestone 1 only: camera movement, a bounded test map, unit selection, and basic movement.

## Implemented

- A 2048 × 2048 pixel geometric test map with visible grid and boundary.
- Keyboard camera movement using WASD or arrow keys at an exported default speed of 600 pixels per second.
- Normalized diagonal camera input and clamping of the visible viewport to the map bounds.
- Four selectable geometric placeholder units with collision-based click hit testing.
- Single-click and normalized drag-box selection with visible selected-state indicators.
- Empty-ground clicks clear the current selection.
- Right-click movement commands for selected units, with map-bound destination clamping and command replacement.
- Direct frame-rate-independent movement reads speed and arrival tolerance from each unit's assigned definition and retains clean destination snapping.
- A typed `UnitDefinition` Resource containing generic identity, movement, health, and minimal prototype attack values.
- Two neutral `.tres` test definitions assigned across the four placeholder instances; their 180 and 240 pixel-per-second speeds validate definition-driven behavior and are not final balance or canon.
- Clear missing/invalid-definition errors that disable only the affected unit's movement while leaving it visible and selectable.
- Combat Prototype Slice 1 adds authored maximum health, per-instance current health, damage reception, health bars shown only after damage, and one-shot unit death cleanup.
- Combat Prototype Slice 2 assigns prototype-only integer teams and adds contextual hostile-target commands with selected-attacker target lines; it does not add attacks or damage dealing.
- Combat Prototype Slice 3 adds validated damage, range, and cooldown data plus no-pursuit deterministic instant-hit attacks and brief temporary hit outlines.
- Approach and Spacing Slice 1 lets explicitly commanded units directly approach stationary hostile targets and stop 8 pixels inside their authored range before attacking.
- Approach and Spacing Slice 2 caches moving-target approach destinations, refreshes them after 8 pixels of target movement, and keeps unit collision footprints inside the authoritative map bounds.
- Approach and Spacing Slice 3 adds capped deterministic friendly-only separation during ground movement, attack approach, and severe idle overlap without changing physical collision behavior.
- Approach and Spacing Slice 4 adds stable `NodePath`-ordered angular firing slots for living same-team attackers sharing an explicit hostile target.
- Milestone 2 Cleanup Slice 1 separates simulation discovery into a neutral `test_units` group and adds one-time footprint-fallback diagnostics without invalidating affected units.
- Milestone 2 Cleanup Slice 2 adds a native headless GDScript runner covering definition validation, health and damage, hostility and targeting, footprint calculations, firing distance, target refresh, and angular slot angles.
- Navigation Slice 1 adds a separately run geometric arena with a map-owned clearance-aware 32-pixel `AStarGrid2D`, static obstacle detours, bounded destination projection, one-unit waypoint following, and temporary route/grid diagnostics.
- Navigation Slice 2 adds explicit typed navigation results, reachability-aware bounded projection, deterministic command rejection that preserves prior state, expanded destination fixtures, and reason-specific temporary feedback.
- Navigation Slice 3 adds deterministic line-of-sight waypoint reduction, conservative supercover-style segment validation, smoother intermediate-waypoint transitions, raw-versus-simplified path drawing, and per-command route metrics.
- Navigation Slice 4 routes explicitly targeted hostiles in the navigation arena to reachable deterministic firing positions, refreshes on material target or slot changes, and reports unreachable combat positions without direct-movement fallback.
- `scenes/main/milestone_1.tscn` as the project main scene.

Milestone 1 remains technically complete. Milestone 2C — Approach and Spacing is complete. Slice 4 was manually accepted, committed, and pushed.

## Active work

Navigation Slice 4 is active in the working tree. Open `scenes/main/navigation_test.tscn` to test in-range attacks, open and obstacle-detour combat routes, blocked preferred slots, enclosed unreachable targets, eight-pixel target refresh, and two-attacker slot changes. The configured main scene remains unchanged and retains legacy direct combat approach.

Approved principle: modest on-screen unit counts permit navigation, group movement, recovery, and tactical AI to prioritize correctness and behavior quality over maximum throughput. Optimize only after route reliability, quality, congestion/deadlock handling, and replanning are sound.

The native validation runner now also covers preferred and alternate firing positions, range and clearance validity, deterministic candidate choice, enclosed-target failure, invalid targets, slot refresh, mutually exclusive route state, ground-command replacement, and death cleanup. Run it through `/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/run_validation.gd`. Manual navigation interaction and full Milestone 2 regression remain required.

See `DEVELOPMENT_PLAN.md` for the full development status, dependencies, approval gates, deferred scope, and implementation sequence.

## Creative boundary

The Mars setting, Mars-only version-one mission scope, Free Settlements and Army names, Marine identity, central faction contrast, and broad initial unit categories are confirmed. The two-spendable-resource-plus-command-capacity economy is provisional and unimplemented. Exact faction mechanics, Marine organizational and political names, rosters, unit names, balance, economic values, campaign details, and other unresolved material still require user approval.

## Next-session rules

Read `AGENTS.md`, `README.md`, `GAME_DESIGN.md`, `ROADMAP.md`, `DEVELOPMENT_PLAN.md`, `HANDOFF.md`, and `CHANGELOG.md` before changing the project. Preserve the distinction between confirmed, provisional, and unresolved material. Treat review recommendations as approval gates, not implementation authorization. Do not edit `project.godot`, add dependencies, or expand beyond the approved technical slice unless the user explicitly asks. Keep planning status and `CHANGELOG.md` current for meaningful changes.
