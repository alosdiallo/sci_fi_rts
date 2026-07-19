# Development and Implementation Plan

## Purpose

This document is the operational source of truth for development status and sequencing.

- `GAME_DESIGN.md` defines the approved and provisional game direction.
- `ROADMAP.md` summarizes the major milestones.
- The focused plan documents define technical decisions for individual systems.
- `HANDOFF.md` provides the shortest current-session snapshot.
- This file shows what is complete, active, next, blocked by dependencies, awaiting approval, and intentionally deferred.

A feature is **complete** only after it is implemented, verified, committed, and pushed. Work that exists only in the working tree remains **active**.

## Status legend

| Status | Meaning |
|---|---|
| Complete | Implemented, manually verified where applicable, committed, and pushed |
| Active | Currently being implemented or reviewed; not yet a clean committed checkpoint |
| Planned | Approved direction, but implementation has not started |
| Approval required | A user decision is required before implementation |
| Deferred | Intentionally outside the current development sequence |

## Current project status

The project has moved beyond pre-production into an early technical-prototype phase.

- **Current milestone:** Milestone 2 — Core Technical Foundation
- **Active work:** Navigation Slice 1 — one-unit static obstacle routing
- **Last committed checkpoint:** Approach and Spacing Slice 4 — deterministic angular attack slots
- **Current playable state:** one bounded technical test map with camera controls, four generic units, selection, movement, data-driven unit values, prototype teams, explicit targeting, direct approach, health, cooldown-based instant-hit combat, death cleanup, footprint-aware bounds, moving-target tracking, friendly separation, and deterministic angular attack slots
- **Current content state:** generic geometric placeholders only; no final Army or Marine units, buildings, economy, campaign missions, or final art

## Milestone status

| Milestone | Status | Outcome |
|---|---|---|
| Milestone 1 — Interaction prototype | Complete | Bounded map, camera movement, click and box selection, and direct unit movement |
| Milestone 2 — Core technical foundation | Active | Data-driven units and a minimal combat/movement foundation |
| Milestone 3 — Small playable loop | Planned | Resource gathering, construction, production, and a small repeatable combat loop |
| Milestone 4 — Faction and mission proof | Planned | One clear faction distinction and one scripted mission slice |
| Milestone 5 — Vertical slice | Planned | One polished representative mission with coherent presentation and supporting systems |

## Completed implementation

### Milestone 1 — Interaction prototype

Status: **Complete**

- 2048 × 2048 bounded geometric test map.
- Keyboard camera movement using WASD and arrow keys.
- Viewport-aware camera clamping.
- Four generic selectable placeholder units.
- Single-click and drag-box selection.
- Empty-ground deselection.
- Contextual right-click ground movement.
- Frame-rate-independent direct movement with clean stopping.
- Map-bound movement destinations.

Acceptance criteria were manually exercised in Godot and the milestone was committed in small slices.

### Milestone 2A — Data-driven unit foundation

Status: **Complete**

- Typed `UnitDefinition` Godot Resource.
- Native `.tres` unit definitions.
- Authored identity, movement, health, and minimal prototype combat values separated from per-instance runtime state.
- Clear validation for missing or invalid definitions.
- Two neutral definitions proving different behavior through shared unit code and scenes.

### Milestone 2B — Minimal combat prototype

Status: **Complete**

- Per-instance current health and safe death cleanup.
- Conditional health bars and temporary hit feedback.
- Prototype integer team IDs.
- Contextual right-click hostile targeting.
- Friendly-unit right-click no-op.
- Explicit target state and safe invalid-target cleanup.
- Authored attack damage, range, and cooldown.
- Deterministic instant-hit attacks.
- No automatic acquisition, random damage, projectiles, or pursuit outside explicit commands.

### Milestone 2C — Approach and spacing

Status: **Complete**

- Slice 1: direct approach to explicit hostile targets.
- Slice 2: thresholded moving-target tracking and footprint-aware map clamping.
- Slice 3: capped, deterministic, friendly-only local separation.
- Slice 4: stable angular firing slots for same-team attackers sharing one explicit target.

Slice 4 was manually accepted, committed, and pushed. Milestone 2C is complete.

## Active work: Milestone 2 Cleanup Slice 2

The technical-foundation audit is recorded in `MILESTONE_2_REVIEW.md`. It reviews current responsibilities, refactor timing, temporary visuals, validation, regression coverage, automated checks, main-scene continuity, and navigation readiness.

Cleanup Slice 1 separated simulation-wide unit discovery from selection eligibility with a neutral `test_units` group and added one-time missing/unsupported-footprint diagnostics while preserving center-only fallback behavior.

Cleanup Slice 2 is active in the working tree. It adds a repository-native GDScript runner for deterministic definition, health, hostility, targeting, footprint, firing-distance, target-refresh, and angular-slot checks:

```bash
godot --headless --path . --script res://tests/run_validation.gd
```

The cleanup phase remains active until the full manual interaction regression passes, the final diff is reviewed, and the changes are committed and pushed.

## Active planning: Navigation architecture

`NAVIGATION_ARCHITECTURE_PLAN.md` is the active planning document for obstacle routing, destination validity, group movement, congestion, stuck recovery, replanning, combat approach, test fixtures, and quality metrics. It does not authorize navigation implementation.

Approved principle: the game will deliberately use modest on-screen unit counts so navigation, group movement, recovery, and tactical AI can prioritize quality over maximum throughput. Higher CPU cost is acceptable when it produces meaningfully better behavior; optimization must not prematurely weaken route quality, reliability, or recovery.

Navigation priorities are correctness and reliability, route quality, congestion/deadlock handling, responsive replanning, and only then performance optimization.

## Active implementation: Navigation Slice 1

Navigation Slice 1 is active in the working tree. It adds a separately run geometric arena at `scenes/main/navigation_test.tscn`, a map-owned clearance-aware 32-pixel `AStarGrid2D`, one-unit ground-route commands, per-unit waypoint following, and temporary path/grid diagnostics.

Combat approach remains direct and the configured project main scene is unchanged. Group navigation, smoothing, recovery, replanning, and dynamic obstacles remain deferred.

Manual launch:

```bash
godot --path . --editor scenes/main/navigation_test.tscn
```

Headless scene check:

```bash
godot --headless --path . --scene res://scenes/main/navigation_test.tscn --quit-after 10
```

## Next implementation sequence

The next phase should consolidate the technical prototype before adding broad content.

### 1. Milestone 2 review and cleanup

Status: **Active**

Dependencies:

- Approach and Spacing Slice 4 complete.

Work:

- Complete and verify Cleanup Slice 2.
- Run the full manual regression checklist.
- Review warnings, node ownership, naming, and temporary debug visuals.
- Remove or explicitly retain temporary prototype-only feedback.
- Confirm documentation matches the committed repository.
- Decide whether the current `TestUnit` has become too broad and needs focused components before additional systems are added.

Approval gates:

- Whether to refactor `TestUnit` now or defer until a second unit category exists.
- Whether to add narrow repository-native automated checks for definition validation, damage/death, and movement state.
- Whether the technical test scene remains the main scene during Milestone 3.

Exit criteria:

- Milestone 2 foundation is stable, documented, warning-free, and easy to extend.

### 2. Spatial scale and navigation requirements

Status: **Active — Slice 1 implementation**

Dependencies:

- Milestone 2 review complete.

Work:

- Review and approve or revise `NAVIGATION_ARCHITECTURE_PLAN.md`.
- Define provisional world scale for infantry squads, buggies, rovers, drones, buildings, weapon ranges, and camera framing.
- Build a repeatable combat/navigation test arena with open ground and simple obstacles.
- Document required movement behavior around static obstacles and narrow spaces.
- Choose the smallest appropriate pathfinding approach only after the test cases are defined.

Approval gates:

- Top-down versus slightly angled battlefield presentation.
- Provisional unit and building footprints.
- Navigation grid/cell scale.
- Whether infantry squads and vehicles share one movement layer initially.
- Pathfinding technology and the boundary between global routing and local separation.

Exit criteria:

- Units can reach valid destinations around representative static obstacles without severe deadlocks or overlap.

### 3. Economy prototype plan

Status: **Planned**

Dependencies:

- Stable movement/navigation foundation.
- Approval of the provisional economy shape.

Approved direction to preserve:

- Two spendable resources plus constructed command capacity.
- Regolith/feedstock as the common construction and manufacturing resource.
- Water ice/volatiles as the concentrated strategic resource.
- Visible, physical gathering that forces expansion into exposed territory.

Work:

- Plan one generic resource loop before faction-specific economic units.
- Define deposit, gatherer, processor/drop-off, storage, and command-capacity responsibilities.
- Add only the data fields required by the implemented loop.
- Use generic non-canon test entities first.

Approval gates:

- One shared generic gatherer versus separate gatherer types in the first prototype.
- Collection/return loop versus deployable extraction.
- Whether resource amounts deplete.
- Initial role of power, if any.
- Command-capacity behavior.

Exit criteria:

- A player can gather one resource through a visible repeatable loop and spend it on one approved output.

### 4. Construction and production prototype

Status: **Planned**

Dependencies:

- One functioning resource loop.
- Building footprint and navigation rules.

Work:

- Minimal building definition pattern.
- Placement validation.
- One construction method.
- One production structure and queue.
- One generic produced unit.
- Command-capacity enforcement.

Approval gates:

- Construction model.
- Placement grid and footprint rules.
- Queue behavior.
- Build-time and cancellation behavior.

Exit criteria:

- The player can gather, construct, produce, and command a replacement unit.

### 5. Small playable loop

Status: **Planned**

Dependencies:

- Resource, construction, production, navigation, and combat foundations.

Work:

- Small repeatable match using generic placeholders.
- One player base, one opposing force, resource pressure, production, and a clear victory/defeat condition.
- Minimal opponent behavior sufficient to test the loop.

Approval gates:

- AI behavior boundary.
- Win/loss conditions.
- Match duration target.
- Population limit.

Exit criteria:

- A complete short match can be played from start to victory or defeat.

### 6. First faction proof

Status: **Planned**

Dependencies:

- The generic small playable loop is stable.

Work:

- Replace a minimal subset of generic content with provisional Free Settlements Army and expeditionary Marine units.
- Start with straightforward infantry squads, buggies/rovers, drones, and logistics roles.
- Prove one clear mechanical distinction per faction.
- Keep names and balance provisional until playtesting supports them.

Approval gates:

- Exact first units.
- Squad representation.
- Faction resource and production differences.
- Visual scale and placeholder-art direction.

Exit criteria:

- Each faction solves one shared battlefield problem differently without requiring separate core engines.

### 7. Scripted mission proof

Status: **Planned**

Dependencies:

- First faction proof.
- Stable playable loop.

Work:

- One Mars test mission with objectives, success, failure, and briefing text.
- Minimal trigger and objective architecture.
- No final campaign length commitment.

Approval gates:

- Mission premise.
- Objective types.
- Trigger representation.
- Narrative presentation.

Exit criteria:

- One complete scripted mission demonstrates the campaign workflow.

### 8. Vertical slice

Status: **Planned**

Dependencies:

- Stable faction and mission proof.

Work:

- One representative polished mission.
- Representative pixel art, interface, audio, settings, save/load needs, accessibility, and balance.
- Production estimates for the remaining campaign and roster.

Exit criteria:

- The project demonstrates its intended player experience and provides enough evidence to approve broader content production.

## Dependency chain

```text
Angular attack slots
  -> Milestone 2 review
  -> Spatial scale and navigation
  -> Economy gathering loop
  -> Construction and production
  -> Generic small playable match
  -> First faction proof
  -> Scripted mission proof
  -> Vertical slice
  -> Campaign and roster expansion
```

Art direction, story writing, and unit/economy design can continue in parallel as planning work, but implementation-dependent decisions should not be locked before the systems they affect can be tested.

## Approval gates summary

The user should approve these decisions before implementation:

1. Milestone 2 cleanup and any refactor of `TestUnit`.
2. Spatial scale, footprints, and pathfinding approach.
3. First economy loop and command-capacity behavior.
4. Construction, placement, and production model.
5. Generic match win/loss conditions and AI boundary.
6. First provisional faction units and their defining asymmetry.
7. First mission premise and trigger architecture.
8. Any dependency, addon, `project.godot` expansion, final art pipeline, or scope increase.

## Deferred scope

Deferred until after the vertical slice unless explicitly reconsidered:

- Multiplayer and networking.
- Procedural campaigns.
- Playable Earth, Moon, orbital, or space maps.
- Interplanetary strategy.
- Advanced physics.
- Fully destructible terrain.
- 3D graphics.
- Console and mobile releases.
- Large public modding framework.
- Final campaign-scale roster.
- Advanced AI, cover, suppression, complex projectile simulation, and tactical formations.
- Navigation optimizations for large armies before representative unit counts exist.

## Status maintenance

After every meaningful implementation slice:

1. Verify behavior in proportion to the change.
2. Update the active-work and completed-work sections here.
3. Update `HANDOFF.md` with the immediate state and next task.
4. Add a concise `CHANGELOG.md` entry.
5. Commit and push only after manual verification where interaction matters.
6. Keep `README.md` high-level; do not use it as the detailed project tracker.
