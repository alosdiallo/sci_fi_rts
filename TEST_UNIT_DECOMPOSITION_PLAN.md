# TestUnit Decomposition Plan

## Status and purpose

Status: **Planning only — implementation requires approval**

`scripts/units/test_unit.gd` is currently 1,409 lines and owns interaction, direct movement, navigation, separation, targeting, combat, health, death, and temporary presentation. Navigation Slices 1–6 deliberately remained in this script until route, cancellation, congestion, recovery, and failure requirements were proven.

Those contracts now exist. This plan defines the smallest reversible extraction before economy, production, or real unit categories add more responsibilities.

This document does not authorize code, scene, Resource, or project-setting changes.

## Goals

- Centralize ground-route, chokepoint, navigation-result, and recovery state.
- Reduce the number of navigation state combinations managed directly by `TestUnit`.
- Preserve every existing command, movement, combat, recovery, debug, and failure behavior.
- Keep `CharacterBody2D` velocity and `move_and_slide()` ownership explicit.
- Preserve the current controller, map, scene, and test boundaries during the first extraction.
- Make the first implementation slice independently testable and easy to revert.

## Non-goals

- No broad entity-component system.
- No navigation manager, registry, autoload, service locator, event bus, or addon.
- No scene-tree component or signal network in the first slice.
- No combat, health, selection, presentation, footprint, separation, or authored-data refactor.
- No navigation behavior changes, tuning changes, optimizations, or new features.
- No economy, harvesting, buildings, production, final units, art, or audio.
- No rename of `TestUnit`, either technical scene, or the configured main scene.
- No `project.godot` edit.

## 1. Current responsibility map

### Responsibilities that should remain on `TestUnit`

- `CharacterBody2D` lifecycle, `velocity`, and `move_and_slide()`.
- Definition validation and access to movement/combat values.
- Selection state and temporary presentation updates.
- Direct ground movement used by the configured interaction scene.
- Map-bound clamping and collision-shape footprint calculation.
- Friendly separation and clearance-safe endpoint choice.
- Attack-target validity, angular attack slots, cooldowns, damage, health, and death.
- Direct non-navigation attack approach.
- Deciding whether a combat target needs a navigation route.
- Requesting a new ground or combat path from `NavigationTestMap`.
- Applying actual position changes and deciding when a waypoint has been reached.
- Temporary route/debug drawing until a later presentation change is justified.

### Navigation state currently stored directly on `TestUnit`

- Raw and simplified ground waypoints.
- Route start and current waypoint index.
- Active-route and combat-route flags.
- Last navigation status, requested destination, accepted destination, and projection flag.
- Active `NavigationTestMap` reference.
- Command sequence and stable priority.
- Chokepoint ID, holding point, entry side, waiting state, and entry grant.
- `NavigationRecoveryTracker` and terminal recovery-failure state.

### Combat-navigation state to keep on `TestUnit` initially

- Combat-navigation map selection.
- Whether a combat route has been requested.
- Combat-navigation failure status.
- Desired and resolved firing positions.
- Alternate-firing-position flag.
- Cached target position and attack-slot state.

These values remain coupled to attack-target validity, authored attack range, cooldown reset, and combat feedback. Moving them in the first slice would combine two refactors and obscure the boundary being tested.

## 2. Options considered

### Option A — Keep extending `TestUnit`

Benefit:

- No immediate structural change.

Reason not recommended:

- Navigation has already grown the script beyond 1,400 lines and more than 40 private state fields.
- Economy and production would add unrelated state to the same lifecycle.
- Route cleanup, recovery reset, command replacement, and death cleanup are increasingly difficult to audit as independent invariants.

### Option B — Extract a state-first `UnitNavigationState` — Recommended

Create one typed `RefCounted` class:

```text
scripts/navigation/unit_navigation_state.gd
```

```gdscript
class_name UnitNavigationState
extends RefCounted
```

It owns navigation route/result/chokepoint/recovery state and deterministic state transitions. It does not move a node, request a path, query the scene tree, draw, print, or own combat.

Benefits:

- Removes the largest coherent set of private fields without changing the scene tree.
- Preserves `TestUnit` as the physics and gameplay coordinator.
- Makes route reset/replacement and recovery-budget invariants directly testable.
- Can be introduced behind the current public `TestUnit` APIs.
- Is reversible because it has no serialized scene or Resource state.

Costs:

- `TestUnit` still contains waypoint-following behavior in the first slice.
- Some delegation methods remain temporarily verbose.
- A later extraction may revise the boundary after real unit categories exist.

### Option C — Extract a route-execution component immediately

Possible scope:

- State from Option B plus waypoint advancement, chokepoint queries, movement requests, and recovery actions.

Reason to defer:

- Physical movement combines authored speed, arrival tolerance, separation, map clamping, clearance validation, and `CharacterBody2D` velocity.
- Moving that behavior now would require callbacks, signals, or an owner reference before the state-only boundary is verified.
- It has a larger regression and rollback surface.

### Option D — Broad unit-component rewrite

Possible scope:

- Separate movement, combat, health, selection, targeting, and presentation nodes.

Reason rejected:

- One generic unit category does not prove reusable interfaces.
- It would change scene composition, initialization order, and many state-cleanup paths at once.
- It is not required for the first economy loop.

## 3. Recommended first boundary

### New owner: `UnitNavigationState`

Move these fields from `TestUnit`:

```text
ground_waypoints
raw_ground_waypoints
ground_route_start
ground_waypoint_index
is_following_ground_route
is_combat_navigation_route
last_navigation_result
last_navigation_requested_destination
accepted_navigation_destination
last_navigation_was_projected
navigation_map
command_sequence
priority
chokepoint_id
chokepoint_holding_point
chokepoint_entry_side
is_waiting_at_chokepoint
chokepoint_entry_granted
recovery_tracker
recovery_failed
```

Names inside the new class do not need leading `ground_` or `navigation_` where the class context already makes their meaning clear.

Move the three recovery tuning constants with their sole consumer:

```text
progress window: 1.5 seconds
minimum progress: 4 pixels
maximum replans: 2
```

They remain prototype constants and are not added to `UnitDefinition`.

### Owner retained: `TestUnit`

Keep:

- `_movement_target` and `_has_movement_target` for legacy direct movement.
- `_map_bounds` and `_has_map_bounds`.
- All attack-target and combat-navigation state.
- `velocity`, position, definition, footprint, and separation.
- Calls to `NavigationTestMap.request_navigation()` and `request_firing_position()`.
- Chokepoint map queries that require the live unit node and position.
- Debug printing and drawing.

## 4. Proposed state API

Exact names require approval, but the first implementation should remain close to this surface:

```gdscript
func assign_route(
    waypoints: PackedVector2Array,
    raw_waypoints: PackedVector2Array,
    route_start: Vector2,
    is_combat_route: bool,
    navigation_map: NavigationTestMap,
    command_sequence: int,
    priority: int,
    chokepoint_id: int,
    chokepoint_holding_point: Vector2,
    chokepoint_entry_side: int,
    preserve_recovery_state: bool = false
) -> void

func clear_route(reset_recovery_state: bool = true) -> void
func record_success(
    status: NavigationPathResult.Status,
    requested_destination: Vector2,
    accepted_destination: Vector2
) -> void
func record_failure(
    status: NavigationPathResult.Status,
    requested_destination: Vector2
) -> void

func has_active_route() -> bool
func is_ground_route() -> bool
func is_combat_route() -> bool
func has_current_waypoint() -> bool
func get_current_waypoint() -> Vector2
func advance_waypoint() -> void
func is_route_complete() -> bool

func set_waiting_at_chokepoint(waiting: bool) -> void
func grant_chokepoint_entry() -> void
func pause_recovery(position: Vector2, distance_to_waypoint: float) -> void
func restart_recovery_observation(position: Vector2, distance_to_waypoint: float) -> void
func observe_recovery(
    delta: float,
    position: Vector2,
    distance_to_waypoint: float
) -> NavigationRecoveryTracker.Action
func mark_recovery_failed() -> void
```

Read-only getters may expose raw/simplified paths, result metadata, map reference, command ordering, chokepoint metadata, and recovery diagnostics where current map/controller/debug consumers require them.

### API constraints

- Do not expose public mutable arrays or public writable state.
- Duplicate assigned path arrays so callers cannot mutate active routes accidentally.
- Keep `NavigationRecoveryTracker` private to `UnitNavigationState`.
- Do not pass `TestUnit` into the state object.
- Do not let the state object access `SceneTree`, node paths, velocity, position, or presentation.
- Do not emit signals in the first slice.

## 5. Compatibility boundary

During the first extraction, preserve these existing `TestUnit` methods and their behavior:

```text
set_movement_route
complete_navigation_command
record_navigation_failure
get_last_navigation_result
get_accepted_navigation_destination
was_last_navigation_destination_projected
is_ground_route_active
is_combat_route_active
get_navigation_command_sequence
get_navigation_priority
is_waiting_for_navigation_chokepoint
holds_navigation_chokepoint_reservation
get_navigation_recovery_events
get_navigation_replan_attempts
get_navigation_recovery_action
has_navigation_recovery_failure
set_navigation_attack_target
```

`NavigationCommandController`, `NavigationTestMap`, scenes, and external callers should not need to know that state moved. `TestUnit` delegates these calls to `UnitNavigationState` while continuing to coordinate live-node behavior.

This compatibility layer keeps the first slice bounded. Removing or redesigning these methods is a separate approval gate after the extraction is proven.

## 6. Required lifecycle invariants

The extraction is acceptable only if these rules remain true:

1. A new direct-ground command clears attack and navigation route state.
2. A new navigation command replaces the prior route and resets the recovery budget.
3. A recovery replan replaces route geometry without resetting the current recovery budget.
4. A rejected navigation command preserves the currently active route or combat target.
5. Route completion snaps to the accepted destination, clears active-route and chokepoint state, and preserves last-result metadata.
6. Intentional chokepoint waiting pauses recovery observation and cannot spend the stuck budget.
7. Clearing a combat route does not accidentally clear a still-valid attack target unless the existing caller requests that transition.
8. Target replacement and ground-command replacement clear stale combat-route state.
9. Death clears active route, chokepoint, recovery, target, movement, and presentation state once.
10. Recovery failure stops velocity, clears the active route without erasing the exhausted budget, records terminal failure, and preserves visible diagnostics.
11. Local separation can never move a routed unit through clearance-invalid space.
12. Direct movement in `milestone_1.tscn` remains independent of navigation state.

## 7. Proposed implementation slices

### Slice 1 — State container and compatibility delegation

Scope:

- Add `UnitNavigationState` as one `RefCounted` script.
- Move only the approved navigation fields, recovery constants, and deterministic state transitions.
- Instantiate it directly in `TestUnit`.
- Keep all current public `TestUnit` navigation APIs as delegates.
- Keep physics movement, route requests, chokepoint map queries, drawing, and logging in `TestUnit`.
- Update the native runner with direct state-transition checks.

Expected files:

```text
scripts/navigation/unit_navigation_state.gd
scripts/navigation/unit_navigation_state.gd.uid
scripts/units/test_unit.gd
tests/run_validation.gd
HANDOFF.md
CHANGELOG.md
DEVELOPMENT_PLAN.md
```

No scene, Resource, map, controller, or project-setting change should be required.

Approval gate after Slice 1:

- Confirm behavior and diagnostics are identical.
- Review whether the state object reduced invalid combinations and made cleanup easier to audit.
- Measure the resulting `TestUnit` responsibility/field reduction without treating line count as the primary success criterion.
- Decide whether any second extraction is justified before economy planning.

### Slice 2 — Route execution policy — Deferred and optional

Possible later scope:

- Move waypoint-advancement and recovery-action selection behind a typed step result.
- Keep actual `CharacterBody2D` movement on `TestUnit`.

Do not approve this automatically with Slice 1. It should proceed only if Slice 1 exposes a stable input/output contract without adding owner callbacks or a signal network.

### Slice 3 — Broader unit composition — Deferred

Reconsider combat, health, or presentation components only after a second real unit category or attack model proves a reusable boundary.

## 8. Verification

### Automated requirements

- `git diff --check` passes.
- Godot 4.7 headless editor load passes without warnings or errors.
- The main interaction scene launches headlessly.
- The navigation arena launches headlessly.
- The existing native runner remains at least 120 passing checks with zero failures.
- New direct `UnitNavigationState` checks cover:
  - fresh inactive state;
  - route assignment and duplicated arrays;
  - ground versus combat route flags;
  - waypoint advancement and completion;
  - successful and rejected result metadata;
  - new-command recovery reset;
  - preserved recovery state during replan;
  - chokepoint wait/grant reset;
  - terminal recovery failure and explicit clear semantics.

### Manual requirements

Repeat the highest-risk representative checks:

- Ground-route replacement while moving.
- Rejected destination preserving the current route.
- Explicit combat routing and target death cleanup.
- Multi-unit obstacle routing with local separation.
- Bidirectional one-cell chokepoint traversal.
- Forced stuck recovery through local refresh, bounded replans, and terminal failure.
- Main-scene direct movement and combat regression.
- Output and Debugger remain warning/error free.

### Diff review requirements

- No behavior or tuning changes are mixed into the extraction.
- No scene, `.tres`, `project.godot`, or input-map changes.
- No new manager, node component, signal network, dependency, or addon.
- Documentation distinguishes planned, implemented, committed, and deferred work accurately.

## 9. Rollback boundary

Slice 1 should be one isolated commit after verification.

Because `UnitNavigationState` is a non-serialized `RefCounted` object and existing public `TestUnit` APIs remain, rollback consists of reverting that single extraction commit. No scene migration, Resource conversion, save compatibility, or project-setting repair should be necessary.

If the extraction requires changes to scenes, controllers, maps, or `project.godot`, stop and revise the plan before proceeding.

## 10. Approval gates

The user should approve or revise:

1. **Boundary:** move navigation route/result/chokepoint/recovery state only.
2. **Representation:** use one typed `RefCounted` `UnitNavigationState`, not a Node.
3. **Physics ownership:** keep velocity and `move_and_slide()` on `TestUnit`.
4. **Combat boundary:** keep target and combat-navigation state on `TestUnit` in Slice 1.
5. **Compatibility:** preserve existing public `TestUnit` navigation APIs as delegates.
6. **Scene boundary:** make no scene or configured-main-scene changes.
7. **Staging:** authorize Slice 1 independently; keep Slice 2 optional and separately gated.
8. **Milestone transition:** after the approved extraction (or an explicit decision to defer it), close Milestone 2 and begin a plan for the smallest gather-return-deposit economy loop.

## Recommendation

Approve Slice 1 as written.

It addresses the proven source of architectural growth while preserving the working gameplay boundary: `TestUnit` remains the live unit and physics coordinator, while `UnitNavigationState` becomes the single owner of route lifecycle and recovery state. It is narrow, testable, and reversible, and it avoids designing a generalized unit architecture before real content exists.
