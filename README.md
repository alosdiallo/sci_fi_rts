# Red Dust, Cold Iron

An early-stage Godot project for a classic 2D pixel-art science-fiction real-time strategy game set during a war for control of Mars. Its working title is **Red Dust, Cold Iron**, and its mechanical reference point is the approachable, deliberate style of late-1990s RTS games such as *Dune 2000*.

The repository is currently in pre-production. The documents define direction and scope; they do not indicate that gameplay systems have been implemented.

## Confirmed direction

- Single-player first.
- Two asymmetric playable factions.
- Base construction, resource gathering, unit production, and scripted campaign missions.
- Limited numbers of units on screen, simple deterministic combat, and minimal physics.
- Modular, data-driven definitions for units and buildings.
- Approximately 40 total units and buildings as a long-term ceiling, not a prototype target.
- No multiplayer, procedural campaign, advanced physics, or 3D graphics in the first version.

## Current status

The repository contains a minimal Godot project scaffold and planning documentation. The first implementation milestone will cover only:

1. Camera movement.
2. A test map.
3. Unit selection.
4. Basic movement.

See [GAME_DESIGN.md](GAME_DESIGN.md) for the design boundaries, [ROADMAP.md](ROADMAP.md) for staged development, and [HANDOFF.md](HANDOFF.md) for a concise session handoff.

## Setting status

All playable missions in the first version take place on Mars. The **Free Settlements of Mars** is the confirmed Martian faction, built around entrenched local industry and mass production. Its opposing Earth–Lunar expeditionary faction is a smaller, elite force, but its finalized political or military name remains unresolved. Further names, plot details, exact faction mechanics, and other material identified as provisional or unresolved in the design document should not be invented without approval.

## Running the project

Open `project.godot` in a compatible Godot editor. No playable scene or gameplay loop is currently promised by this repository.

## Documentation

- [GAME_DESIGN.md](GAME_DESIGN.md): confirmed design, provisional direction, and open questions.
- [ROADMAP.md](ROADMAP.md): milestones and explicit exclusions.
- [HANDOFF.md](HANDOFF.md): compact context for a new ChatGPT or Codex session.
- [CHANGELOG.md](CHANGELOG.md): notable repository changes.
- [AGENTS.md](AGENTS.md): repository-wide instructions for coding agents.
