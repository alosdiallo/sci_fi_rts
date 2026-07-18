# Approach and Spacing Proposed Implementation Plan

## Status and boundary

This document proposes a minimal staged design for explicit attack approach and basic unit spacing. It does not authorize implementation or changes to scripts, scenes, Resources, assets, or `project.godot`.

The goal is limited to letting explicitly commanded generic test units enter firing range without severe stacking. It is not a pathfinding, formation, navigation, crowd, or general steering architecture.

Items labeled **Requires user approval** must be decided before the applicable implementation slice.

## Current behavior

### Map and camera

`scripts/maps/test_map.gd` owns the authoritative `Rect2(0, 0, 2048, 2048)` map bounds. The camera and command controller request those bounds rather than duplicating the dimensions.

`CameraController` moves its `Camera2D` from keyboard input and clamps the visible viewport to the map. Camera behavior is independent of unit movement and should remain unchanged.

### Movement state and execution

Each `TestUnit` currently stores:

- `_movement_target: Vector2`
- `_has_movement_target: bool`
- inherited `CharacterBody2D.velocity`

`set_movement_target()` clears the attack target, replaces the destination, and enables direct movement. In `_physics_process(delta)`, the unit:

1. Calculates the offset and distance to the destination.
2. Snaps to the exact destination if it is within `arrival_tolerance` or the next speed-scaled physics step would reach it.
3. Otherwise sets velocity directly toward the destination using `definition.movement_speed`.
4. Calls `move_and_slide()`.

This is frame-rate independent for a given physics-step sequence and stops without overshoot or oscillation. There is no acceleration, facing, route planning, or command queue.

### Explicit attack targets and combat

`UnitCommandController` interprets right-clicks:

- A hostile clicked unit is assigned as the attack target of each selected hostile-to-target unit.
- A friendly clicked unit causes no command.
- Empty ground produces one map-clamped destination for every selected unit.

`TestUnit.set_attack_target()` clears movement state, stops velocity, assigns the target, and starts a fresh full cooldown. The target remains per-instance runtime state and must be alive, valid, inside the tree, not self, and hostile.

Every physics step, the unit checks direct center-to-center squared distance against `definition.attack_range`. In range, it counts down the authored cooldown and applies deterministic instant-hit damage through `take_damage()`. Out of range, it resets the cooldown to its full duration and does nothing else.

Out-of-range attackers therefore remain stationary by design: assigning an attack target explicitly clears `_has_movement_target`, and combat code has no approach state or destination.

### Collision and overlap

The generic unit is a `CharacterBody2D` with a 48 × 48 `RectangleShape2D`. The shape currently serves physics point queries for click and contextual-command hit testing.

The unit remains on Godot's default collision layer, but `collision_mask = 0`. Consequently, `move_and_slide()` supplies direct CharacterBody movement without responding to other units. Physics queries can still find the bodies, while units can pass through and occupy the same position.

Ground commands send the same destination to every selected unit. With no collision response, offsets, or separation, multiple units stack exactly at that destination. Attack commands do not currently add overlap because out-of-range units do not move, but naïvely approaching every attacker toward the target center would produce the same convergence problem.

Selection remains separate: `SelectionController` performs pointer queries or center-point drag-box tests, and each unit owns its selected-state presentation.

## Desired prototype behavior

For an explicitly assigned hostile target:

- An in-range attacker remains stationary and uses the existing cooldown and instant-hit attack behavior.
- An out-of-range attacker approaches a suitable firing position.
- The attacker stops slightly inside its firing range rather than moving to the target center.
- If the target moves enough to invalidate the current firing position, the approach destination updates.
- A stationary attacker resumes approach if the target moves out of range.
- Leaving range continues to reset the full attack cooldown.
- Target death, invalidity, removal from the tree, or a change that makes it friendly clears both target and approach state.
- A new explicit hostile-target command replaces the previous target and approach state.
- A ground command clears the attack target and all approach state, then preserves ordinary map-clamped movement.
- No target is acquired without an explicit contextual right-click.

Approach is a consequence of the existing explicit attack command, not a new autonomous behavior or command type.

## Recommended responsibility boundary

Keep the current focused ownership:

| Concern | Owner |
|---|---|
| Contextual right-click and selected-unit ordering | `UnitCommandController` |
| Per-attacker target and approach state | Individual `TestUnit` |
| Movement, range checks, cooldown, and attack execution | Individual `TestUnit` physics update |
| Authoritative playable bounds | `TestMap` |
| Unit footprint source | Generic unit scene's collision shape initially |
| Selection and its presentation | Existing selection controller and unit scene |

The command controller may calculate deterministic target-slot assignments for a multi-unit command. It should pass only the small slot value needed by each unit; it should not update movement every frame or become a combat manager.

The unit should continue to own its actual destination, velocity, cooldown, and target validity. No manager, autoload, registry, event bus, navigation agent, or general steering component is justified for four generic units.

## Approach state representation

Recommended private runtime state on `TestUnit`:

- Whether the current movement is an ordinary ground command or target approach.
- A stable approach-slot angle or normalized radial direction assigned for the current attack command.
- The last target position used to calculate the approach destination.
- The current approach destination.

The existing `_attack_target` remains authoritative. Do not encode approach as a second target type or write it into `UnitDefinition`.

The narrow public target API can be extended so the command controller may assign an optional deterministic slot direction with the target. Ground movement must clear the slot and approach destination through the existing command-replacement boundary.

An enum with only `IDLE`, `GROUND_MOVE`, and `ATTACK_TARGET` is clearer than several potentially contradictory booleans if implementation shows that `_has_movement_target` can no longer express the states safely. A larger command hierarchy, command objects, queues, state-machine framework, or separate approach controller is not recommended.

**Requires user approval:** use the three-value private command state as recommended, or minimally extend the current booleans. The enum is preferred because movement and explicit attack approach are mutually exclusive player commands even though attack approach internally uses direct movement.

## Preferred firing distance

### Exact attack range

Stopping exactly at `attack_range` maximizes distance, but it places the unit directly on the range boundary. Small target movements or floating-point differences can alternate the unit between in-range and out-of-range states. Because leaving range resets the cooldown, this can repeatedly prevent attacks.

### Slightly inside range

Stopping inside range provides deterministic hysteresis without changing the authored weapon range. The approach distance from the target should be:

```text
preferred_firing_distance = max(0, attack_range - firing_margin)
```

The unit still uses the full authored `attack_range` for the actual permission-to-hit check. The margin affects only its desired stopping position.

### Recommended initial margin

Use a fixed private prototype constant of **8 world pixels**.

This is recommended over deriving it from `arrival_tolerance` because arrival tolerance describes destination snapping, not combat-range hysteresis. Coupling the two would make a movement tuning value silently change tactical distance. It is recommended over a new `UnitDefinition` field because all current units can validate the behavior with one margin and no demonstrated unit-specific need exists.

Eight pixels is small relative to the current 180–220 pixel ranges and large enough to exceed the current 4-pixel arrival tolerance. It is prototype tuning, not final balance.

If later unit or weapon behavior demonstrates different needs, an authored field can be proposed then. It should not be added speculatively now.

**Requires user approval:** fixed 8-pixel firing margin, derived margin, or a new authored field. The fixed private constant is recommended for the first two slices.

## Unit footprints

### Existing collision shape

The current 48 × 48 `RectangleShape2D` is the only authored spatial footprint. A conservative circular radius can be derived from its half extents:

```text
radius = length(rectangle_size / 2)
```

This approximately 33.9-pixel radius encloses the rectangle. Using half the smaller dimension, 24 pixels, would permit corner overlap; using the conservative radius favors visibly separated placeholders.

Advantages:

- No new Resource field or duplicated scene value.
- The value matches the current geometric body used by pointer hit tests.
- It is sufficient to prove local spacing with identical placeholders.

Limitations:

- A pointer hitbox and a logical movement footprint may eventually have different meanings.
- Shape inspection needs a clear error for a missing or unsupported shape.
- A rectangle reduced to a radius is deliberately approximate.

### Authored radius field

Adding `collision_radius` or `unit_radius` to `UnitDefinition` would be easy to consume but would prematurely conflate selection collision, physical collision, movement occupancy, and visual size. A future field should have a precise name such as `movement_radius` only when heterogeneous unit sizes require authored occupancy behavior.

### Recommendation

Derive one conservative spacing radius from the scene's existing `CollisionShape2D` for this prototype. Keep it runtime-read-only and validate that the current rectangle shape exists. Do not mutate the collision shape or add a Resource field.

Later infantry squads, buggies, and drones may require distinct logical movement footprints even when their selection shapes differ. Buildings will likely need static occupancy shapes and route blocking rather than local unit separation. Those requirements justify a future explicit footprint schema, but this plan does not design it.

**Requires user approval:** derive the prototype radius from the current scene as recommended, or add an authored `movement_radius`. Approval for derivation does not establish the final footprint model.

## Basic separation

### Physics collision through `move_and_slide()`

Enabling unit collision masks would prevent direct overlap with recognized bodies, but it would also introduce sliding, order-dependent blocking, units pinning each other, and hostile-body interactions. Without navigation, a blocked unit may never reach its direct destination. Using the same shape for pointer queries and movement collision would also commit to a meaning it does not yet have.

Physics collision alone is therefore not recommended for this prototype.

### Destination offsets

Distinct destinations are deterministic and inexpensive. They prevent intentional convergence at commanded ground points and around one attack target, but they do not resolve units whose paths cross or units that begin overlapped.

Target slots are recommended for multi-attacker approach. Equivalent small offsets for multi-unit ground commands may be considered in the spacing slice, but they must not become a persistent formation system.

### Lightweight local separation

A local separation term can inspect nearby living friendly `TestUnit` nodes and add a bounded velocity correction away from neighbors that are closer than the sum of their derived radii.

Recommended rules:

- Evaluate only living units with the same `team_id`.
- Iterate neighbors in a stable order, sorted by a stable scene identifier such as `NodePath` for the current fixed scene.
- Use squared distances where practical.
- Apply no force outside the combined radii.
- Use a capped linear correction rather than inverse-square force.
- Resolve exact coincident centers with a stable direction derived from the two units' stable ordering, never randomness.
- Blend the correction with the intended direct velocity, then cap final speed at `definition.movement_speed`.
- Apply it only while a unit is executing ground movement or approach; do not make untouched idle units drift.
- Suppress very small corrections with a dead zone.
- Preserve destination snapping when the intended destination is reached and no significant overlap remains.

This reduces severe stacking but does not promise collision-free motion.

### Recommended prototype combination

Use:

1. Deterministic target slots to avoid commanding attackers to the same firing point.
2. A small capped friendly-only separation correction for remaining overlap.
3. No physical unit collision-mask response.

Destination slots solve the largest intentional convergence problem; separation handles incidental overlap. Neither alone is sufficient for both cases.

To limit jitter and oscillation:

- Compute separation only in `_physics_process()`.
- Scale displacement through the physics step.
- Cap final velocity.
- Use a minimum penetration/dead-zone threshold.
- Do not preserve momentum; recompute from explicit state each step.
- Let the firing-margin and arrival-tolerance rules dominate stopping.
- Do not use random tie-breaking.

This is deterministic for the same scene ordering, commands, and Godot physics-step sequence. It is not a claim of cross-platform lockstep determinism.

### Friendly and hostile collision

Only friendly units should contribute to local separation in this prototype. Hostile units remain non-blocking and do not repel one another. Attackers stop at firing slots outside the hostile target's footprint, but units may still pass through hostile units if commanded along intersecting direct paths.

This is intentionally limited. Adding hostile blocking without pathfinding could create unavoidable deadlocks and would require decisions about melee contact, body blocking, and route selection.

**Requires user approval:** the target-slot plus friendly-separation combination, leaving collision masks unchanged, and keeping hostile units non-blocking. Any physical collision-layer or collision-mask change requires separate approval before implementation.

## Multiple attackers

Several selected attackers should not approach the target center or share one radial point.

Recommended command-time assignment:

1. Collect selected living units through the existing group.
2. Sort them by stable `NodePath` for the current fixed scene.
3. Assign evenly spaced angular slots around the clicked target:

```text
slot_angle = base_angle + TAU * slot_index / attacker_count
```

4. Choose `base_angle` from the direction between the target and the average attacker position. This favors the side from which the group was commanded without adding tactical encirclement logic.
5. Store only each attacker's assigned slot direction for that explicit target command.
6. Place each desired center at the unit's preferred firing distance from the target, then clamp it to the map bounds adjusted by the derived unit radius.

For one attacker, its slot lies on the approach side. For several attackers, even angular distribution supplies distinct positions. The slot count and angles are recalculated only when the player issues a new hostile-target command; this avoids units exchanging slots as they move or die.

If one attacker dies, survivors retain their slots until a new command. Empty slots are acceptable. Persistent formations, dynamic encirclement, optimal assignment, path crossing prevention, and squad layouts are excluded.

`NodePath` is suitable for the fixed prototype because the four authored unit names are stable and readable. A later spawning system will need an explicit stable simulation/entity identifier before relying on deterministic ordering for runtime-created units. `get_instance_id()` is not recommended as a long-term deterministic key.

**Requires user approval:** even angular slots, average-approach base angle, command-time stable `NodePath` ordering, and retaining slots until a new command.

## Moving targets

The attacker should check range and target validity every physics step, as it does now. It does not need to rewrite its approach destination for every subpixel target movement.

Recommended update rule:

- Store the target position used for the last approach calculation.
- Recalculate the slot destination when the target has moved at least **8 world pixels** from that stored position.
- Recalculate immediately when approach begins or resumes after the target leaves range.
- Continue checking the actual center-to-center attack range every physics step.
- Clamp every recalculated slot destination to map bounds adjusted for the attacker's footprint.

The fixed 8-pixel movement threshold matches the proposed prototype firing margin, is larger than tiny transform noise, and does not require a timer or authored field. It is not a final target-tracking cadence.

An attacker that is in range remains stopped. If the target moves out of range, the existing combat rule resets the cooldown, the attacker immediately resumes approach, and a fresh full cooldown must elapse after it regains range. Partial cooldown progress is not preserved.

If threshold-based updates visibly lag behind the current movement speeds, a later approved revision may use a fixed physics-tick cadence. Recalculating a simple destination is cheap, but thresholding makes state changes easier to inspect and prevents needless tiny corrections.

**Requires user approval:** the 8-pixel target-position threshold and immediate recalculation on approach start/resume. No authored tracking field is recommended.

## Collision and navigation boundary

This prototype may solve:

- Direct unobstructed approach to an explicitly commanded target.
- Stable firing positions slightly inside range.
- Simple command-time distribution around one target.
- Reduction of severe friendly overlap.
- Direct destination updates for moving targets.
- Existing authoritative map-bound clamping.

It will not solve:

- Navigation around obstacles, buildings, terrain, cliffs, or other units.
- Guaranteed collision-free travel.
- Narrow passages, congestion, traffic priority, or deadlock resolution.
- Globally shortest or tactically safe routes.
- Persistent formations or squad layouts.
- Polished flocking, crowd motion, or large-army performance.
- Hostile body blocking or melee contact.

Do not add `NavigationAgent2D`, `NavigationServer`, AStar, flow fields, terrain costs, obstacle avoidance, building avoidance, or crowd simulation in these slices.

Proper pathfinding should be introduced only when an approved map contains route-blocking terrain or buildings and direct movement demonstrably fails. At that point, choose a navigation model using actual map topology, unit footprint classes, dynamic-obstacle requirements, expected unit counts, and deterministic-performance targets. Local separation may complement later navigation, but it must not be mistaken for route finding.

## Staged implementation

### Slice 1: One attacker approaches one stationary target

1. Add the minimal explicit command/approach state to `TestUnit`.
2. Preserve contextual right-click target assignment.
3. When a target is out of range, calculate a direct position on the current attacker-to-target line.
4. Stop at the approved preferred firing distance.
5. Use the existing direct movement, map bounds, range checks, cooldown, and instant-hit damage.
6. Clear approach on invalidity, death, friendliness change, ground command, or replacement target.
7. Do not add spacing, slots, collision changes, or moving-target thresholding yet.

Acceptance focus: one unit can approach a stationary explicitly commanded hostile, stop inside range, wait one full cooldown, and attack without pursuit machinery or automatic acquisition.

Approval gate:

- Approach-state representation.
- Fixed firing margin.
- Whether approach movement lives entirely in `TestUnit`.
- Whether the command API changes only enough to distinguish attack approach.

### Slice 2: Stable margin and moving-target updates

1. Recalculate the direct approach destination only after the approved target-movement threshold.
2. Resume approach immediately when a previously in-range target becomes out of range.
3. Preserve full cooldown reset whenever range is lost.
4. Clamp the unit center to map bounds adjusted by its approved derived footprint.
5. Verify repeated target motion does not cause boundary toggling or visible destination jitter.

Approval gate:

- Footprint derivation.
- Target-position update threshold.
- Footprint-adjusted versus center-only map clamping.
- Continued cooldown-reset rule.

### Slice 3: Basic friendly separation

1. Add a local friendly-neighbor query without a manager or registry.
2. Add only the approved capped linear separation correction.
3. Define stable coincident-center tie-breaking.
4. Keep collision layers and masks unchanged unless separately approved.
5. Keep hostile units non-blocking.
6. Exercise crossing paths, shared ground destinations, and initially overlapping units.

Approval gate:

- Separation radius and strength rules.
- Neighbor source and stable ordering.
- Whether separation applies only while moving as recommended.
- Friendly versus hostile interaction.
- Any collision-layer or collision-mask changes.

### Slice 4: Multiple-attacker target slots and regression

1. Sort selected attackers by the approved stable key at command time.
2. Assign stable angular slots around the explicit target.
3. Retain slots until command replacement even if an attacker dies.
4. Combine slots with the approved separation behavior.
5. Run full interaction, combat, and movement regression checks.
6. Update documentation only with verified implementation.

Approval gate:

- Slot geometry, base angle, and stable ordering.
- Behavior when slots fall outside map bounds.
- Whether multi-unit ground commands also receive simple destination offsets.
- Whether a narrowly scoped automated movement validation is worthwhile.

Each slice must be implemented and verified separately. Approval of one slice does not authorize later slices.

## Verification

### Acceptance criteria

- Only explicitly assigned hostile targets cause approach.
- A ground command clears target and approach state and retains existing map-clamped movement.
- Friendly-unit right-click remains a no-op.
- An out-of-range attacker moves directly toward its assigned firing position.
- An in-range attacker does not approach or drift.
- The attacker stops slightly inside range and begins damage only after the existing full cooldown.
- Losing range resets cooldown progress.
- A moving target causes bounded, thresholded destination updates.
- Target death, invalidity, removal, friendliness change, or command replacement stops approach safely.
- Multiple attackers receive stable distinct firing positions without randomness.
- Friendly separation reduces severe overlap without promising obstacle avoidance.
- Units do not exceed their authored movement speed.
- Physics-step behavior does not depend on rendered frame rate.
- Map-bound clamping uses the authoritative `TestMap` bounds and accounts for the approved footprint rule.
- Camera, selection, health, death, target feedback, hit feedback, and definition validation remain functional.
- No excluded system or infrastructure is introduced.

### Headless checks Codex can run

- `git diff --check`.
- Godot 4.7 headless editor load for parsing, class registration, Resource validation, and scene resolution.
- Godot 4.7 headless runtime launch for startup and physics-processing errors.
- Final working-tree and diff review for unrelated or generated changes.
- If separately approved, one repository-native validation scene or script that instantiates the generic units and checks approach, stopping distance, cooldown reset, and overlap reduction without adding a test framework.

Headless startup alone cannot prove pointer feel, visual jitter, acceptable spacing, or practical multi-unit motion.

### Manual Godot tests

- Select one unit and right-click an out-of-range hostile; verify direct approach, clean stop inside range, full cooldown delay, damage, and no pursuit past the firing position.
- Issue a ground command during approach; verify the target line and approach state clear immediately.
- Replace one hostile target with another; verify the previous approach and cooldown are replaced.
- Right-click a friendly unit; verify existing state remains unchanged.
- Kill, free, or invalidate a target during approach; verify the attacker stops and clears feedback safely.
- Move a target in small increments below the threshold; verify no visible jitter.
- Move it beyond the threshold; verify the destination updates.
- Move an in-range target out of range; verify approach resumes and cooldown resets.
- Move a target near every map edge; verify firing destinations remain inside footprint-adjusted bounds.
- Command two and then three selected attackers at one hostile; verify stable distinct slots and no severe stacking.
- Repeat the same command from different approach directions.
- Kill one attacker or the shared target; verify remaining state clears safely and slots do not shuffle unexpectedly.
- Send friendly units through crossing paths and to a shared ground destination; verify overlap is reduced without persistent oscillation.
- Send opposing units through one another; verify the approved non-blocking hostile behavior.
- Repeat movement at low and high rendered frame-rate caps.

### Regression checklist

- Pan with WASD and arrow keys; verify normalized camera movement and boundary clamping.
- Single-click, drag-box select in all directions, and empty-ground deselect.
- Repeat pointer commands after moving the camera.
- Verify unselected units receive no movement or attack commands.
- Verify ground destination replacement and authoritative map clamping.
- Verify standard and fast definitions retain their movement speeds.
- Verify health bars, exact damage values, hit feedback, death-once cleanup, and removal from selection queries.
- Verify team IDs and hostility checks.
- Verify target lines appear only for selected attackers with valid targets.
- Verify first hit occurs only after one full cooldown in range.
- Verify no unit deals multiple hits in one physics frame.
- Verify invalid definitions remain visible/selectable but neither move nor attack.

### Stress tests with the current four units

- Command all four generic units as each selectable team permits and verify only selected hostile-to-target attackers respond.
- Repeatedly alternate shared ground destinations at opposite sides of the group.
- Repeatedly replace a shared hostile target while units are moving.
- Place two friendly units at the same center and verify deterministic separation without random direction changes.
- Approach one target with two attackers of different movement speeds and ranges.
- Move the target repeatedly across each attacker's range boundary.
- Kill the target while multiple attackers are approaching or cooling down.
- Repeat the same initial arrangement and command sequence several times and compare stopping positions and attack order.

### Explicit exclusions

- Automatic target acquisition, attack-move, patrol, guard, follow, or autonomous combat movement.
- Navigation agents, navigation servers, AStar, flow fields, terrain costs, obstacle routing, building avoidance, or path smoothing.
- Persistent formations, squad layouts, tactical encirclement, destination optimization, or assignment solvers.
- Guaranteed collision avoidance, hostile body blocking, melee contact, congestion management, or crowd simulation.
- Acceleration, deceleration, facing, turret rotation, movement animation, or attack animation.
- Projectiles, multiple weapons, armor, accuracy, critical hits, suppression, cover, healing, status effects, or combat AI.
- New faction units, final balance, lore, economy, buildings, production, art, or audio.
- Managers, autoloads, registries, event buses, service locators, addons, dependencies, or testing frameworks.
- Changes to `project.godot`.

## Consolidated approval decisions

Before implementation, approve or revise:

1. **Approach state:** private `IDLE` / `GROUND_MOVE` / `ATTACK_TARGET` state versus extending existing booleans.
2. **Firing margin:** fixed 8 world pixels as recommended versus derivation or authored data.
3. **Footprint source:** conservative radius derived from the current rectangle shape versus an authored movement radius.
4. **Map clamping:** clamp unit centers using footprint-adjusted bounds during approach.
5. **Collision configuration:** retain the current layer and zero mask; make no physics collision changes.
6. **Separation:** stable, capped, linear friendly-only correction combined with destination slots.
7. **Separation activation:** apply only to units executing ground movement or attack approach.
8. **Hostile interaction:** hostile units remain non-blocking and do not contribute separation.
9. **Multiple attackers:** command-time even angular slots using average approach direction and stable `NodePath` ordering.
10. **Slot lifetime:** retain assigned slots until command replacement; do not reshuffle after death.
11. **Moving targets:** recalculate after 8 pixels of target movement and immediately when approach begins or resumes.
12. **Cooldown:** preserve full reset whenever the attacker is out of range.
13. **Ground groups:** whether multi-unit ground destinations also receive simple deterministic offsets in Slice 4.
14. **Automated validation:** whether one narrow repository-native validation script or scene is worthwhile; no framework is recommended.

Approval of this plan or an early slice must not be interpreted as approval for later slices, final footprint data, pathfinding, formations, hostile collision, or other excluded systems.
