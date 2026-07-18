# Session Handoff

## Project

Early-stage Godot project for a classic 2D pixel-art science-fiction RTS inspired mechanically by late-1990s RTS games such as *Dune 2000*. The repository currently contains a minimal engine scaffold and planning documents; do not describe gameplay as implemented.

## Confirmed

- Single-player first; two asymmetric playable factions.
- Long-term loop: construction, gathering, production, simple deterministic combat, and scripted campaign missions.
- Limited on-screen unit counts and minimal physics.
- Modular, data-driven unit and building definitions.
- Roughly 40 total units/buildings is a long-term ceiling, not prototype scope.
- First version excludes multiplayer, procedural campaign, advanced physics, and 3D graphics.
- Milestone 1 only: camera movement, test map, unit selection, basic movement.

## Creative boundary

Current provisional ingredients: planetary invasion, a dying/lightless world, fortified settlements, powerful invading walkers, and a hostile neutral biosphere. Do not invent canon, names, factions, plot, or relationships among these ideas without user approval.

## Next-session rules

Read `AGENTS.md`, `GAME_DESIGN.md`, and `ROADMAP.md` before changing code. Preserve the distinction between confirmed, provisional, and unresolved material. Do not edit `project.godot`, add dependencies, or begin gameplay code unless the user explicitly asks. Keep `CHANGELOG.md` current for meaningful changes.
