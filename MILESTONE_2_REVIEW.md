# Milestone 2 Technical-Foundation Review

## Status and purpose

This review began after Approach and Spacing Slice 4 and now records the post-navigation Milestone 2 closeout. Navigation Slices 1–6 are committed; a representative manual interaction/navigation regression was completed on 2026-07-31.

The state-first boundary in `TEST_UNIT_DECOMPOSITION_PLAN.md` was approved. Slice 1 is implemented and verified in the working tree and awaits commit; Slice 2 remains separately gated and is not currently recommended.

This document does not authorize implementation. It does not redefine game design, final unit architecture, navigation, economy, or content.

## Executive findings

- The prototype has clear outer boundaries: authored values are in `UnitDefinition`, pointer commands are in focused controllers, map bounds have one authority, and per-unit runtime state and presentation are owned by `TestUnit`.
- Before extraction, `test_unit.gd` was a 1,409-line prototype script with more than 40 private runtime-state fields. Slice 1 moved 20 route/result/chokepoint/recovery fields and three recovery constants into `UnitNavigationState`; `TestUnit` now retains 26 direct private fields while continuing to coordinate live movement, combat, and presentation.
- The decision to defer extraction until navigation established real contracts was correct. Those contracts now exist, so a focused decomposition plan is justified before economy, production, or real unit categories expand the script further.
- Do not begin a broad component rewrite. The first proposed boundary should isolate navigation route execution and recovery behind a narrow typed contract while leaving `CharacterBody2D` motion ownership and existing behavior explicit until the plan proves otherwise.
- Cleanup Slices 1–2 and Navigation Slices 1–6 are committed. The active closeout change is the verified state-first navigation-state extraction; the earlier clearance defect and live grouped-routing regression are already committed.
- All current geometric visuals remain useful diagnostics. They should be explicitly treated as temporary, not removed or replaced with final presentation.
- `scenes/main/milestone_1.tscn` should remain the main scene until a second test composition has materially different fixtures or lifecycle needs.

## 1. Current architecture

### Responsibility map

| File | Current responsibility | Data/state category |
|---|---|---|
| `scripts/data/unit_definition.gd` | Declares `UnitDefinition`; stores identity, movement, health, and one simple attack profile; returns validation errors | Shared authored data and data validation |
| `data/units/test_unit_standard.tres` | Standard generic test values: speed 180, tolerance 4, health 100, damage 20, range 220, cooldown 1.0 | Shared authored test data |
| `data/units/test_unit_fast.tres` | Fast generic test values: speed 240, tolerance 4, health 80, damage 12, range 180, cooldown 0.6 | Shared authored test data |
| `scripts/units/test_unit.gd` | Executes per-unit movement, health, targeting, combat, approach, footprint clamping, separation, slots, death, and presentation updates | Per-instance runtime state, simulation behavior, and presentation bridge |
| `scenes/units/test_unit.tscn` | Defines the `CharacterBody2D`, 48 × 48 pointer/footprint shape, geometric body, selection outline, target line, hit outline, and health bar | Authored node composition and prototype presentation |
| `scripts/commands/unit_command_controller.gd` | Interprets right-clicks, performs unit hit tests, distinguishes hostile/friendly/ground context, supplies map bounds, and calls unit command APIs | Command input and orchestration |
| `scripts/selection/selection_controller.gd` | Interprets left-click and drag gestures, converts screen/world coordinates, queries selectable units, and applies exclusive collection-based selection | Selection input and orchestration |
| `scripts/camera/camera_controller.gd` | Reads camera input, applies frame-scaled movement, disables smoothing, and clamps the visible viewport | Camera behavior |
| `scripts/maps/test_map.gd` | Owns the authoritative 2048 × 2048 `MAP_BOUNDS` and draws the background, grid, and border | Prototype map dimensions and debug presentation |
| `scenes/maps/test_map.tscn` | Instantiates the focused map script on a `Node2D` | Map scene wrapper |
| `scenes/main/milestone_1.tscn` | Composes the map, camera, four unit instances, selection UI/controller, and contextual command controller | Prototype composition root and per-instance assignments |
| `scripts/maps/navigation_test_map.gd` | Owns the navigation grid, static fixtures, clearance queries, destination resolution, route simplification, combat-position search, group destinations, and chokepoint coordination | Navigation arena authority and deterministic routing |
| `scripts/commands/navigation_command_controller.gd` | Converts arena commands into per-unit ground or combat route requests and preserves rejected-command state | Navigation command orchestration |
| `scripts/navigation/navigation_path_result.gd` | Carries typed route success/failure status, accepted destination, and raw/simplified route data | Navigation result value object |
| `scripts/navigation/navigation_recovery_tracker.gd` | Measures progress windows and bounds local refresh/replan escalation | Per-route recovery policy |
| `scenes/main/navigation_test.tscn` | Composes the separate obstacle, destination, group, combat, and chokepoint arena | Navigation regression composition |
| `tests/run_validation.gd` | Runs repository-native deterministic and live-physics validation without third-party dependencies | Automated technical regression runner |

### Authored data

Reusable authored values live in `UnitDefinition` Resources. The two `.tres` files are read-only shared definitions; neither selection, destinations, health, targets, cooldown progress, nor slot caches are stored in them. The main scene assigns one definition and a prototype `team_id` to each unit instance and authors the four initial positions.

The unit scene authors the current 48 × 48 collision shape and all geometric visual dimensions and colors. The map script authors the fixed prototype map size and debug-grid appearance. Controller thresholds and camera speed remain local to their focused consumers.

### Per-instance runtime state

`TestUnit` owns selection, movement destination, current health, alive/initialized flags, attack target, approach activation, cached target and approach positions, cached slot membership, remembered map bounds, attack cooldown, hit-feedback timing, inherited velocity, and prototype team ownership.

### Command handling

`SelectionController` owns primary-pointer selection gestures. `UnitCommandController` is the sole right-click interpreter: hostile clicks assign targets, friendly clicks do nothing, and ground clicks issue movement that clears combat targeting. Neither controller simulates movement or combat.

### Presentation

The unit scene owns all unit visual nodes, while `TestUnit` updates their state. `TestMap` draws its own grid and boundary. The drag rectangle belongs to the screen-space selection layer. There is no final art or faction presentation.

## 2. `TestUnit` responsibility audit

### Current responsibilities

`test_unit.gd` currently contains:

- Assigned-definition validation and invalid-unit shutdown.
- Ground-movement destination state and direct `CharacterBody2D` movement.
- Movement replacement, arrival tolerance, clean stopping, and velocity control.
- Collision-shape footprint derivation and footprint-aware map clamping.
- Per-instance current health, damage validation and clamping, alive state, and one-shot death cleanup.
- Selected-state storage and selection-indicator presentation.
- Health-bar ratio and visibility.
- Temporary hit-feedback timing and presentation.
- Prototype integer team ownership and hostility checks.
- Explicit attack-target assignment, replacement, validity checks, and clearing.
- Temporary target-line presentation.
- Authored range checks, full first-hit cooldown, cooldown resets, instant-hit damage, and one-hit-per-physics-frame behavior.
- Attack-approach activation and the fixed eight-pixel firing margin.
- Cached moving-target positions and eight-pixel refresh threshold.
- Cached approach destinations and reached-but-obsolete fallback.
- Friendly-only local separation, stable coincident-position handling, and speed capping.
- Stable `NodePath` attacker discovery, ordering, angular slots, and slot-cache refresh.
- Ground-route metadata, raw and simplified waypoints, waypoint progression, and route completion.
- Combat-navigation requests, resolved firing positions, route refresh, and explicit failure state.
- Chokepoint command priority, holding, reservation, waiting, and yielding integration.
- Measured route progress, bounded local refresh and replanning, new-command reset, and terminal stuck failure.
- Temporary route, destination, chokepoint, and recovery diagnostics.

### Size and state

The script is 1,409 lines. It declares:

- More than 40 private runtime-state fields spanning interaction, combat, routing, congestion, and recovery.
- A substantially expanded public query/command surface for route results, chokepoint coordination, recovery diagnostics, combat navigation, selection, targeting, health, and movement.
- Six `@onready` presentation/shape references.
- Nine prototype tuning constants, including approach, separation, and recovery thresholds.

Most complexity remains organized into named helpers, and state names consistently distinguish cached values, active flags, and authored values. The public surface is no longer small, however: navigation and chokepoint coordination require outside consumers to query and mutate several route states. This is now enough evidence to plan a focused boundary.

### Coupling and understandability

The strongest coupling is intentional:

- Combat range determines whether approach or cooldown processing runs.
- Separation can alter actual range, which resets cooldown and resumes approach.
- Footprint data affects both destination and final-position clamping.
- Attacker-set membership changes angular slot destinations.
- Target invalidation must clear target, approach, slot, movement, feedback, and cooldown state safely.

These rules form one per-unit state machine even though it is represented by booleans and nullable state rather than an explicit enum. Extracting one portion requires a clear contract for velocity ownership, command cancellation, target validity, and physics-step order.

The script is still understandable for the current four-unit prototype, but it is near the practical limit for adding more cross-cutting behavior safely. Navigation would add path state, route failure, waypoint progression, repath policy, obstacle interaction, destination validity, and movement cancellation. Economy, squads, and distinct vehicle behavior would add consumers with different capabilities and footprints. Adding all of those directly to `TestUnit` would make state combinations and cleanup paths difficult to reason about.

This is now evidence that another major system should not be added directly to `TestUnit`. It still does not justify an unplanned broad component rewrite.

## 3. Refactor options

### Option A — Keep `TestUnit` intact through the navigation prototype

Benefits:

- Preserves a manually accepted behavior baseline.
- Avoids designing a movement interface before obstacle, route-failure, and footprint requirements are tested.
- Keeps physics-step ordering and command cancellation visible in one place.
- Has the lowest immediate regression risk.

Risks:

- Navigation temporarily increases an already large script.
- Additional state can make invalid combinations easier to introduce.
- A later extraction may touch more code.

Likely affected files and nodes:

- No structural change now.
- The future navigation slice would initially affect `test_unit.gd`, a navigation test map/fixture, and possibly the command API.

Justification and timing:

- Justified now if navigation is kept to a narrow test slice and no economy behavior is added concurrently.
- Reassess immediately after the first routing prototype establishes actual contracts.

### Option B — Extract presentation-only behavior

Possible scope:

- A focused child script/node controlling selection outline, health bar, target line, and hit outline.
- `TestUnit` would expose state changes to that presentation node through direct typed calls.

Benefits:

- Removes six node references, feedback timing, and visual update helpers from simulation code.
- Makes later replacement of temporary visuals localized.
- Has clearer ownership than extracting interdependent simulation behavior.

Risks:

- Changes the scene tree and creates synchronization calls without fixing the main movement/navigation coupling.
- Health, selection, target, and death regressions remain possible.
- A single generic scene does not yet demonstrate reusable presentation variation.

Likely affected files and nodes:

- `test_unit.gd`, `test_unit.tscn`, and one new presentation script.
- Existing indicator and health-bar nodes would likely move under a `Presentation` child.

Justification and timing:

- Reasonable after navigation or when a second real presentation/category exists.
- Not required merely to reduce line count before navigation.

### Option C — Extract combat and targeting behavior

Possible scope:

- A combat component holding health, cooldown, target, damage, and death-related state.

Benefits:

- Could isolate health/attack rules for future combat-capable units.
- Could make combat-specific automated checks easier.

Risks:

- Target range, approach, separation, death, movement cancellation, selection cleanup, and visual feedback cross the proposed boundary.
- Death owns node lifetime, so a component would still need strong coordination with the root.
- Current single-attack model and single unit category do not prove the correct reusable combat interface.

Likely affected files and nodes:

- `test_unit.gd`, `test_unit.tscn`, command controller, and one or more new scripts/nodes.

Justification and timing:

- Not justified now.
- Reconsider after a second real combatant category or a second weapon/attack model demonstrates common and varying behavior.

### Option D — Extract movement, approach, spacing, and footprint behavior

Possible scope:

- A movement component owning destination, bounds, footprint, separation, approach caches, slot caches, and velocity requests.

Benefits:

- Directly targets the area navigation will expand.
- Could provide a reusable movement contract for later unit categories.

Risks:

- Navigation requirements are precisely what is not yet known.
- Attack range and target validity currently drive movement state; `CharacterBody2D` owns velocity and `move_and_slide()`.
- Premature extraction may need immediate replacement once route following, unreachable destinations, and different footprints are tested.
- Highest near-term regression risk among focused extractions.

Likely affected files and nodes:

- `test_unit.gd`, `test_unit.tscn`, command controller, and a new movement script/node; navigation would then revise all of them again.

Justification and timing:

- Do not do this before the first navigation test cases.
- Reassess after navigation proves the route-request, cancellation, waypoint, and failure interfaces.

### Option E — Broad component-based unit refactor

Possible scope:

- Separate definition consumer, health, selection, combat, targeting, movement, and presentation components.

Benefits:

- Creates explicit boundaries if several real unit categories demonstrably share different subsets.
- Could support composition over inheritance later.

Risks:

- Large node/API expansion, difficult initialization order, extensive signal or direct-reference wiring, and broad regression surface.
- Risks recreating a manager-like architecture inside every unit.
- Current single generic unit scene cannot validate the abstractions.

Likely affected files and nodes:

- Almost every unit, command, selection, scene, and future test file.

Justification and timing:

- Not justified now.
- Consider only after navigation and a second real unit category expose repeated, stable responsibility boundaries.

### Recommendation after navigation

Option A was completed successfully through Navigation Slice 6. Cleanup also introduced `test_units`, footprint fallback diagnostics, and the native validation runner.

The next task should be **planning Option D as a focused extraction**, using the contracts navigation proved. The plan should identify route request/result ownership, waypoint progression, cancellation/replacement, chokepoint coordination, recovery escalation, failure reporting, physics movement ownership, and the smallest regression-preserving implementation slices. It must not authorize a broad combat/presentation/unit rewrite.

Consider Option B only when presentation begins to vary or temporary visuals are replaced. Do not begin Option C or E without a second concrete unit/attack requirement.

## 4. Temporary prototype visuals

| Visual | Decision | Reason |
|---|---|---|
| Yellow selection indicator | Retain, mark temporary | Essential for click/box-selection regression and selected-attacker identity |
| Conditional health bar | Retain, mark temporary | Makes damage, repeated hits, and health differences inspectable |
| Magenta target line | Retain, mark temporary | Exposes target assignment, replacement, invalidation, and multi-attacker state |
| White hit outline | Retain, mark temporary | Gives minimal instant-hit timing feedback without affecting simulation |
| Geometric placeholder body/inset | Retain, mark temporary | Keeps unit centers, overlap, speed, and footprint visually readable |
| Test-map grid and boundary | Retain, mark temporary | Supports camera, distance, approach, movement, and edge-clamp checks |

None should be simplified or removed during cleanup. Removal would reduce observability before replacement presentation exists. “Temporary” should be recorded in documentation and focused node/script comments where useful; it does not require adding labels, UI, faction colors, animation, particles, sound, or final art.

## 5. Naming and organization

### Concrete findings

- `scripts/commands/unit_command_controller.gd` and node `UnitCommandController` accurately describe contextual ground/target commands.
- `scripts/selection/selection_controller.gd`, `scripts/camera/camera_controller.gd`, `scripts/maps/test_map.gd`, and their class names are focused and consistent.
- `scripts/data/unit_definition.gd` and `data/units/*.tres` clearly separate schema from authored resources.
- `TestUnit`, `test_unit.tscn`, and the neutral resource names remain accurate because the entities are generic non-canon test content.
- Public methods use consistent verb/query forms. Private fields consistently use a leading underscore and state prefixes such as `_has_`, `_is_`, and `_cached_`.
- `selectable_units` is misleading when used for friendly-separation and attacker-slot discovery. Selection eligibility is not a durable simulation-wide unit registry. A separate neutral `test_units` group is the only naming/organization change recommended before new nonselectable entities exist.
- `scenes/main/milestone_1.tscn` is historically accurate but increasingly misleading as the Milestone 2 combat laboratory. Renaming it now would change the configured main scene and references without improving behavior. Defer the rename under the main-scene recommendation below.

No folder move, broad rename, base class, registry, manager, or hierarchy is justified.

## 6. Validation and error handling

### Current strengths

- `UnitDefinition.get_validation_errors()` reports blank IDs/names and nonfinite or out-of-range movement, health, and combat values in one pass.
- Missing or invalid definitions produce unit-identifying runtime errors, leave the unit visible/selectable for inspection, and disable physics behavior.
- `take_damage()` rejects nonfinite and non-positive amounts, clamps health to `[0, max_health]`, and does not mutate inactive health.
- `_die()` is guarded by alive state, clears selection/movement/target/feedback, disables hit testing, stops physics, removes group membership, and safely queues deletion.
- Target checks cover invalid/freed references, self, tree membership, alive state, and current hostility.
- Target caches and slot state clear through the central target-clear path.
- Coincident friendly centers use deterministic `NodePath` ordering rather than normalization or randomness.
- Preferred range, refresh thresholds, direct distance, and footprint calculations avoid random or render-frame-dependent simulation.

### Narrow cleanup recommendations

- Footprint fallback is intentionally safe but silent. If the collision shape is missing or changes to an unsupported shape, clamping becomes center-only and separation becomes inactive. Emit a single clear configuration/runtime diagnostic identifying the unit and fallback; do not invent a radius.
- Definition validation is centralized adequately. Do not add a validation framework or duplicate field checks in `TestUnit`.
- Target validity is necessarily checked at several transition points. Do not consolidate it into a global target service.
- `team_id` is a prototype integer and hostility is inequality. There is no current invalid integer value, so additional validation would invent team semantics.
- Death idempotence is correctly guarded. Do not add a death manager, corpse state, or lifecycle abstraction.
- Map bounds are supplied with commands and retained per unit. Navigation should later define how a unit receives authoritative movement context at initialization; do not redesign that contract during this cleanup.

## 7. Manual Milestone 2 regression checklist

### Recorded representative pass — 2026-07-31

The closeout pass exercised the running project through Godot rather than relying only on headless launch checks. It verified:

- Main-scene click and drag selection, empty-ground deselection, ground movement, destination replacement, camera-relative commands, friendly-command no-op, explicit hostile targeting, approach, damage, health feedback, death, and target cleanup.
- Navigation-arena static-obstacle detours, blocked-destination rejection with prior-state preservation, multi-attacker combat slots, group routing around the large obstacle, and lower-chokepoint traversal in both directions.
- Godot reported zero warning and error counts after the interaction pass.

The pass found one real defect: friendly separation could nudge a routed unit outside clearance-valid navigation space, producing an invalid-start rejection on its next route. The current closeout fix validates separated route segments, falls back to the command-only step, and adds a live four-unit regression. The runner now reports 120 passed and zero failed checks.

The exhaustive checklist below remains the reference for future releases and material input/windowing changes. Low/high render-cap comparison, window-resize coverage, every drag direction, and temporary editor mutation cases were not repeated during this representative closeout pass.

### A. Launch and diagnostics

- [ ] Open the project in Godot 4.7 and run the configured main scene.
- [ ] Confirm all four generic units and the complete map grid/boundary appear.
- [ ] Confirm Output and Debugger contain no parser, resource, configuration, runtime, or warning messages.
- [ ] Inspect both `.tres` definitions and confirm all identity, movement, health, and attack values load.

### B. Camera and coordinate conversion

- [ ] Pan with W/A/S/D and all four arrow keys.
- [ ] Verify opposing inputs cancel and diagonal movement is not faster.
- [ ] Verify the visible viewport clamps at all four map edges and after window resizing.
- [ ] Move the camera, then repeat unit click, drag selection, ground commands, and hostile target clicks to verify screen-to-world conversion.

### C. Selection

- [ ] Single-click each unit and verify exclusive selection and yellow outline.
- [ ] Click empty ground and verify all selection clears.
- [ ] Drag-select left-to-right, right-to-left, top-to-bottom, and bottom-to-top.
- [ ] Verify boxes containing zero, one, and several centers produce the expected collection.
- [ ] Verify a sub-eight-pixel gesture behaves as a click.

### D. Contextual commands and ground movement

- [ ] Right-click with no selected units and verify no response.
- [ ] Right-click a friendly unit and verify current movement/target state is unchanged.
- [ ] Right-click empty ground and verify only selected units move.
- [ ] Replace a ground destination while moving and verify immediate redirection.
- [ ] Compare standard and fast units over the same distance; verify 180 versus 240 pixels/second behavior.
- [ ] Verify clean arrival without overshoot or oscillation.
- [ ] Verify a ground command clears any attack target and magenta target line.

### E. Health, damage, hit feedback, and death

- [ ] Put an attacker in range and verify the victim health bar appears only after damage.
- [ ] Verify the white hit outline appears briefly for each hit and has no gameplay effect.
- [ ] Verify standard and fast maximum-health differences through predictable hit counts.
- [ ] Verify health never displays below zero.
- [ ] Verify lethal damage removes the unit once, hides its indicators, disables pointer interaction, and produces no freed-node errors.
- [ ] Verify selecting a victim before death does not leave stale selection presentation.

### F. Teams, targeting, and combat timing

- [ ] Verify team 1 units treat each other as friendly and team 2 units as hostile, and vice versa.
- [ ] Right-click a hostile and verify only selected units assign it and show target lines.
- [ ] Replace one hostile target with another and verify target state, line, approach, slot, and cooldown restart.
- [ ] Kill or remove a shared target and verify all attackers clear it safely.
- [ ] Verify self and friendly units never become attack targets.
- [ ] Keep a target outside range and verify no damage occurs.
- [ ] Enter range and verify the first hit occurs only after one full authored cooldown.
- [ ] Verify repeated hits match the authored cooldown and damage values.
- [ ] Move the target out of actual range during cooldown; verify progress resets and a new full cooldown is required after range is regained.
- [ ] Verify no attacker delivers more than one hit in a physics frame.

### G. Approach and moving targets

- [ ] Explicitly target a stationary hostile from out of range; verify direct approach and stopping near the assigned firing position.
- [ ] Verify the firing position uses the eight-pixel inside-range margin and actual attack eligibility still uses center distance.
- [ ] Issue a ground command during approach and verify immediate cancellation.
- [ ] Move a target less than eight pixels and verify no unnecessary cached-destination update is visible.
- [ ] Move it at least eight pixels and verify approach destination refresh.
- [ ] Let an attacker reach an obsolete cached destination while still too far away; verify the useful-destination fallback resumes approach.
- [ ] Move an in-range target out of range; verify approach resumes without prediction.

### H. Footprint boundaries and edge targets

- [ ] Ground-command units toward each map edge and corner; verify the 48 × 48 footprint remains inside the boundary.
- [ ] Approach targets near each edge and corner; verify destinations clamp without NaN values or visible boundary oscillation.
- [ ] Move along a boundary while separation is active and verify units remain inside.

### I. Friendly separation

- [ ] Send two, three, and four same-team units to one ground point; verify severe overlap is reduced.
- [ ] Cross friendly paths and verify command intent remains primary.
- [ ] Place two friendlies at coincident centers and verify deterministic opposite resolution without NaN values.
- [ ] Verify idle units do not drift after acceptable spacing is reached.
- [ ] Verify hostile units pass through and do not contribute separation.
- [ ] Verify separation does not exceed authored speed or clear target state.

### J. Angular attack slots and attacker-set changes

- [ ] Target one hostile with one attacker and verify a stable slot.
- [ ] Repeat with two attackers and verify opposite slots.
- [ ] Repeat with three attackers and verify approximately 120-degree distribution.
- [ ] Repeat with four same-team attackers in a temporary editor arrangement if needed and verify approximately 90-degree distribution; restore the committed scene afterward.
- [ ] Verify stable `NodePath` ordering while the participant set is unchanged.
- [ ] Mix standard and fast/ranged definitions and verify each uses its own preferred firing radius.
- [ ] Kill, retarget, ground-command, or change the team of one attacker in a temporary editor test; verify remaining indices/counts recompute stably.
- [ ] Move the shared target at least eight pixels and verify all participating caches refresh without visible jitter.
- [ ] Verify attackers may stop and attack when actually in range before reaching the exact slot.
- [ ] Verify friendly separation remains secondary and severe stacking is reduced.

### K. Final diagnostics

- [ ] Repeat a representative command sequence at low and high rendered frame-rate caps.
- [ ] Confirm behavior remains physics-step based and no visible oscillation or persistent drift appears.
- [ ] Recheck Output and Debugger for warnings, errors, orphan nodes, or invalid/freed-object access.

## 8. Automated checks

### Worth automating now

- `UnitDefinition` validation for every blank, nonfinite, zero, negative, and valid field case. This is pure, stable, and costly to recheck manually.
- Loading both committed `.tres` files and asserting that validation succeeds.
- Damage clamping and invalid-damage rejection on an instantiated `TestUnit`, provided the check does not depend on rendered visuals.
- Hostility rules for self, same-team, other-team, dead, and invalid units.
- Preferred firing distance (`max(attack_range - 8, 0)`), target-refresh threshold (squared eight-pixel boundary), slot angles for one through four participants, and rectangle/circle footprint half-extents if these calculations are first moved into small deterministic helper functions for a real consumer—not solely to satisfy a test.

Death idempotence is valuable but requires careful scene-tree advancement because the unit queues itself for deletion. It belongs after a minimal runner can process deferred cleanup and assert no duplicate effects or errors.

### Still requires manual interaction testing

- Pointer hit testing and screen-to-world conversion.
- Camera feel and viewport clamping.
- Drag-box behavior.
- Visual indicator timing and clarity.
- Separation jitter, overlap quality, edge behavior, and moving-target feel.
- End-to-end slot movement and attacker-set transitions.

### Recommended test mechanism

Use typed GDScript executed by Godot 4.7 headlessly. A small repository-native runner and focused scripts are sufficient; no third-party framework, addon, autoload, or permanent test manager is justified.

The smallest useful first slice is:

1. Load both unit-definition Resources.
2. Exercise `UnitDefinition.get_validation_errors()` with valid and invalid in-memory definitions.
3. Instantiate `test_unit.tscn` in a minimal `SceneTree`, assign a valid definition, and verify damage clamping plus same/different-team hostility.
4. Exit nonzero on assertion failure and print concise results.

Do not expose private gameplay methods merely to increase coverage. Add pure helpers only when cleanup or navigation already needs a stable boundary. Continue headless editor-load/runtime-launch checks independently.

## 9. Main-scene decision

### Keep the existing main scene

Benefits:

- No `project.godot` edit or reference churn.
- Preserves the accepted four-unit regression laboratory.
- Navigation can initially add temporary fixtures to a separate scene that is run directly.

Cost:

- The filename no longer describes all behavior it contains.

### Rename it now

Benefit:

- A name such as `technical_sandbox.tscn` would describe current use better.

Costs:

- Requires a main-scene configuration change and documentation/reference updates.
- Adds churn without changing composition or capability.

### Create a new technical sandbox later

Benefits:

- Preserves the Milestone 1/Milestone 2 regression baseline.
- Allows navigation fixtures or economy entities to have a distinct composition without overloading one scene.

Cost:

- Two scenes must be kept deliberately scoped.

### Recommendation

Keep `scenes/main/milestone_1.tscn` as the configured main scene through initial navigation planning and the smallest obstacle-routing proof. Run a separate navigation test scene directly only when static obstacles, narrow passages, or unreachable destinations require a materially different fixture.

Change the configured main scene only when the new sandbox becomes the regular integrated prototype, or when maintaining the old composition no longer provides a useful regression baseline. Do not rename merely to match the current milestone number.

## 10. Navigation outcome

The implemented navigation foundation supports testing:

- Static obstacle fixtures with known open and blocked routes.
- A clear boundary between global route planning and existing local friendly separation.
- Distinct provisional footprints for infantry squads and vehicles without prematurely defining final movement classes.
- Destination validation after map/footprint clamping.
- Narrow passages near one- and multiple-footprint widths.
- Unreachable destinations and an explicit non-oscillating failure state.
- Movement replacement and cancellation while a route is active.
- Explicit target approach around obstacles without automatic target acquisition.

### Cleanup completed before and during navigation

- A representative manual regression baseline now distinguishes navigation failures from existing interaction/combat behavior.
- `test_units` separates simulation discovery from selection eligibility.
- Missing/unsupported footprint shapes produce a clear one-time diagnostic.
- The approved 32-pixel clearance-aware `AStarGrid2D` arena covers static obstacles, narrow passages, invalid/unreachable destinations, cancellation/replacement, combat approach, group routes, congestion, and bounded recovery.

### Still intentionally deferred

- Extracting movement into a component.
- A final footprint or movement-class Resource schema.
- Squad, vehicle, building, or economy definitions.
- A manager, registry, service locator, autoload, event bus, factory, or inheritance hierarchy.
- Replacing direct movement, separation, or prototype visuals before a route consumer exists.

Dynamic topology, moving obstacles, terrain costs, attack-move, automatic acquisition, and large-crowd optimization remain outside the current foundation. Existing separation remains local overlap mitigation, not routing.

## 11. Final recommendation

### Findings

- Milestone 2 has a coherent, data-driven technical foundation, a useful interaction/combat laboratory, and a separate navigation regression arena.
- Deferring structural extraction until navigation was correct; route, cancellation, congestion, recovery, and failure contracts are now concrete.
- Slice 1 has reduced direct navigation state on `TestUnit` without changing its physics, command, combat, or presentation boundary.
- The 132-check native runner plus the recorded interactive passes provide a suitable safety net for the completed staged extraction.
- Temporary diagnostics remain valuable and should stay until replacement presentation exists.

### Recommended closeout scope

1. Keep the committed clearance-safe routed-separation fix and its live four-unit regression as the baseline.
2. Keep every current prototype visual and both technical scenes.
3. Commit and push the verified `UnitNavigationState` Slice 1 extraction.
4. Close the architecture gate after Slice 1; do not begin optional route-execution Slice 2 without evidence from a concrete future consumer.
5. Begin a focused plan for the smallest gather-return-deposit economy loop after the commit.

### Explicitly not worth changing

- Do not split presentation, combat, movement, or the entire unit into components without the focused plan and approval.
- Do not rename the main scene or reorganize folders.
- Do not add final visuals, navigation abstractions, footprint fields, movement classes, building data, or economy data.
- Do not add a framework, manager, registry, autoload, event bus, factory, service locator, or addon.
- Do not “clean up” deterministic constants that are intentionally local prototype conventions.

### Suggested next slices

These require separate authorization:

1. **Architecture plan only:** document the current `TestUnit` responsibility/state map and propose the smallest navigation/recovery extraction contract, affected files, migration order, regression gates, and rollback boundary.
2. **Extraction Slice 1:** move only pure route-progress/recovery policy or another equally narrow approved boundary; preserve behavior and public commands.
3. **Extraction Slice 2:** move route execution state only if Slice 1 demonstrates a clean interface and all validation/manual checks remain green.
4. **Milestone 3 planning:** define the first visible gather-return-deposit loop after the technical foundation is closed.

### Approval gates

The user must approve:

1. The focused decomposition plan and its first extraction boundary.
2. Whether `CharacterBody2D` physics movement remains on `TestUnit` during the first extraction.
3. Whether `milestone_1.tscn` remains configured as the main scene during Milestone 3.
4. The first Milestone 3 economy-planning scope after architecture closeout.

### Exit criteria for the review and cleanup phase

- The clearance-safe closeout fix is committed and pushed.
- The validation runner reports 132 passed and zero failed checks.
- The recorded representative manual pass remains warning/error free.
- Documentation matches the committed and pushed repository.
- The approved post-navigation decomposition Slice 1 is implemented and verified.
- No unapproved architecture, navigation, economy, content, or presentation work is included.
- The approved decomposition boundary is written clearly enough to implement one bounded, reversible slice.

### Precise next task

Commit and push the verified Slice 1 extraction. Then close Milestone 2 architecture work and create a focused plan for the smallest generic gather-return-deposit economy loop. Do not begin optional route-execution Slice 2 or economy implementation without a separate approved plan.
