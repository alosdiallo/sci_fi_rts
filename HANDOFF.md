# Session Handoff

## Project

**Red Dust, Cold Iron** is the working title of an early-stage Godot project for a classic 2D pixel-art science-fiction RTS inspired mechanically by late-1990s RTS games such as *Dune 2000*. The project remains in pre-production. Milestone 1 is implemented: the repository contains a bounded geometric test map, keyboard-controlled boundary-clamped camera, placeholder unit selection, and direct right-click unit movement.

## Confirmed

- Single-player first; two asymmetric playable factions.
- All playable missions in version one take place on Mars.
- The **Free Settlements of Mars** is the confirmed Martian faction.
- The opposing Earth–Lunar expeditionary faction does not yet have a finalized political or military name.
- The central faction direction is entrenched local industry and mass production versus a smaller, elite expeditionary force.
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
- Direct frame-rate-independent movement at an exported default speed of 180 pixels per second, with a 4-pixel default arrival tolerance and clean destination snapping.
- `scenes/main/milestone_1.tscn` as the project main scene.

Milestone 1 is technically complete, pending manual interaction verification in the Godot editor.

## Creative boundary

The Mars setting, Mars-only version-one mission scope, Free Settlements name, and central faction contrast are confirmed. The expeditionary faction's finalized name, exact faction mechanics, campaign details, and other items marked provisional or unresolved in `GAME_DESIGN.md` still require user approval. Do not turn provisional material into canon or invent additional lore, names, or plot.

## Next-session rules

Read `AGENTS.md`, `README.md`, `GAME_DESIGN.md`, `ROADMAP.md`, `HANDOFF.md`, `CHANGELOG.md`, and `MILESTONE_1_PLAN.md` before changing the project. Preserve the distinction between confirmed, provisional, and unresolved material. Do not edit `project.godot`, add dependencies, or expand beyond the approved technical slice unless the user explicitly asks. Keep `CHANGELOG.md` current for meaningful changes.
