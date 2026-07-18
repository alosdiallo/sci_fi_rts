# Roadmap

This roadmap describes sequencing, not completed work. A milestone is complete only when its acceptance criteria are implemented and verified.

## Milestone 1: Interaction prototype

Scope is intentionally limited to four features:

- Camera movement.
- A test map.
- Unit selection.
- Basic movement.

Acceptance criteria:

- The player can move the 2D camera across a bounded test map.
- At least one placeholder unit can be selected and visibly indicates selection.
- The player can issue a movement command to a selected unit.
- The unit moves predictably to the commanded location on the test map.
- No combat, economy, construction, production, faction, or campaign logic is required.

## Milestone 2: Core technical foundation

Provisional scope, to be refined after Milestone 1:

- Establish modular, data-driven unit and building definition formats.
- Separate definition data, runtime state, commands, and presentation.
- Define deterministic update and combat conventions.
- Add focused tests or reproducible test scenes for foundational systems.

## Milestone 3: Small playable loop

Provisional scope:

- One resource-gathering loop.
- Minimal base construction.
- Minimal unit production.
- Simple deterministic combat.
- A very small set of placeholder units and buildings sufficient to test the loop.

This milestone should not attempt the long-term content ceiling.

## Milestone 4: Faction and mission proof

Provisional scope:

- Prove one clear point of asymmetry for each playable faction.
- Add a small scripted mission slice with objectives, success, and failure states.
- Introduce a neutral biosphere interaction only if its rules have been approved.
- Validate pacing, readability, and on-screen population limits.

## Milestone 5: Vertical slice

Provisional scope:

- A polished representative mission.
- Representative pixel-art presentation and user interface.
- A coherent sample of construction, gathering, production, combat, faction identity, and mission scripting.
- Initial accessibility, save/load, audio, and settings requirements as approved.

## Later development

Only after the vertical slice is validated:

- Expand the scripted campaign.
- Grow the roster gradually toward, but not necessarily to, the ceiling of approximately 40 total units and buildings.
- Balance both factions and campaign encounters.
- Improve tooling, content pipelines, performance, accessibility, and presentation.

## Explicitly out of scope for the first version

- Multiplayer.
- Procedural campaign generation.
- Advanced physics.
- 3D graphics.
