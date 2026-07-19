# Roadmap

This roadmap describes sequencing, not completed work. A milestone is complete only when its acceptance criteria are implemented and verified.

For detailed status, dependencies, approval gates, and implementation sequencing, see [DEVELOPMENT_PLAN.md](DEVELOPMENT_PLAN.md).

## Milestone 1: Interaction prototype — Complete

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

## Milestone 2: Core technical foundation — Active

Current scope:

- Establish modular, data-driven unit definitions.
- Separate definition data, runtime state, commands, and presentation.
- Define deterministic update and combat conventions.
- Validate health, targeting, combat, approach, bounds, and basic spacing with generic units.
- Review the foundation before expanding into navigation, economy, or buildings.

Implemented and committed:

- Typed unit definitions and neutral `.tres` test data.
- Health, damage, death, team IDs, explicit targeting, range, cooldowns, and deterministic instant-hit attacks.
- Direct attack approach, moving-target tracking, footprint-aware map clamping, and basic friendly separation.

Active:

- Deterministic angular attack slots for multiple friendly attackers sharing one target.

Still required to complete the milestone:

- Manual regression verification and commit of the active slice.
- Technical-foundation review and cleanup.
- Approval of whether focused automated validation is warranted.

## Milestone 3: Small playable loop — Planned

Provisional scope:

- One resource-gathering loop.
- Minimal base construction.
- Minimal unit production.
- Simple deterministic combat.
- A very small set of placeholder units and buildings sufficient to test the loop.

This milestone should not attempt the long-term content ceiling.

## Milestone 4: Faction and mission proof — Planned

Provisional scope:

- Prove one clear point of asymmetry for each playable faction.
- Add a small scripted mission slice with objectives, success, and failure states.
- Introduce a neutral biosphere interaction only if its rules have been approved.
- Validate pacing, readability, and on-screen population limits.

## Milestone 5: Vertical slice — Planned

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
