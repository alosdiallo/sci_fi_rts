# Red Dust, Cold Iron

An early-stage Godot project for a classic 2D pixel-art science-fiction real-time strategy game set during a war for control of Mars. Its working title is **Red Dust, Cold Iron**, and its mechanical reference point is the approachable, deliberate style of late-1990s RTS games such as *Dune 2000*.

The repository is currently an early technical prototype. Its generic test scene validates core RTS interactions and a minimal deterministic combat foundation; it is not yet a playable match or content-complete game.

## Confirmed direction

- Single-player first.
- Two asymmetric playable factions.
- Base construction, resource gathering, unit production, and scripted campaign missions.
- Limited numbers of units on screen, simple deterministic combat, and minimal physics.
- Modular, data-driven definitions for units and buildings.
- Approximately 40 total units and buildings as a long-term ceiling, not a prototype target.
- No multiplayer, procedural campaign, advanced physics, or 3D graphics in the first version.

## Current status

Milestone 1 is complete. The current prototype includes a bounded test map, camera controls, selection, direct movement, data-driven generic units, health, explicit hostile targeting, cooldown-based instant-hit combat, death cleanup, attack approach, footprint-aware bounds, and basic friendly separation.

Milestone 2 is active. The current work is deterministic angular positioning for multiple friendly attackers sharing one target. Economy, buildings, production, navigation around obstacles, final faction units, campaign missions, final art, and audio are not implemented.

See [DEVELOPMENT_PLAN.md](DEVELOPMENT_PLAN.md) for current status, dependencies, approval gates, and next steps; [GAME_DESIGN.md](GAME_DESIGN.md) for design boundaries; and [HANDOFF.md](HANDOFF.md) for a concise session handoff.

## Setting status

All playable missions in the first version take place on Mars. The **Free Settlements Army** is the conventional home-territory military of the **Free Settlements of Mars**, while an expeditionary Marine force from the Earth–Moon system operates with fewer personnel and constrained logistics. The Army emphasizes established bases, local industry, combined arms, and specialized equipment; the Marines emphasize adaptability, mobility, modular equipment, drones, and multi-role platforms. Neither faction is intended as a simplistic weak swarm or universally superior elite force.

## Running the project

Open `project.godot` in Godot 4.7 and run the configured technical test scene. The scene is an interaction and combat laboratory, not yet a complete playable match.

## Documentation

- [GAME_DESIGN.md](GAME_DESIGN.md): confirmed design, provisional direction, and open questions.
- [ROADMAP.md](ROADMAP.md): milestones and explicit exclusions.
- [DEVELOPMENT_PLAN.md](DEVELOPMENT_PLAN.md): detailed implementation status, dependencies, approval gates, and sequencing.
- [HANDOFF.md](HANDOFF.md): compact context for a new ChatGPT or Codex session.
- [CHANGELOG.md](CHANGELOG.md): notable repository changes.
- [AGENTS.md](AGENTS.md): repository-wide instructions for coding agents.
