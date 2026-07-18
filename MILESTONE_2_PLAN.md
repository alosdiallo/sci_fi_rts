# Milestone 2 Proposed Implementation Plan

## Status and boundary

This document is a proposal only. It does not authorize implementation or changes to existing scripts, scenes, resources, or `project.godot`.

Milestone 2 should establish the smallest useful data-driven foundation while preserving the completed Milestone 1 prototype. It should not introduce systems merely because they may be useful later.

Items labeled **Requires user approval** must be decided before implementation.

## Current architecture

### Scene composition

`scenes/main/milestone_1.tscn` is the current main scene. It composes:

- One instanced `TestMap`.
- One `Camera2D` with `CameraController`.
- A `Units` container with four instances of the same `TestUnit` scene.
- A screen-space `SelectionInterface` with `SelectionController` and a translucent selection rectangle.
- A separate `MoveCommandController`.

This is a suitably small composition root. It does not contain a global manager, autoload, registry, factory, or event bus.

### Map

`scripts/maps/test_map.gd` owns the authoritative `Rect2(0, 0, 2048, 2048)` map bounds and draws the geometric background, grid, and border. Both camera clamping and movement-command destination clamping request these bounds from the map. Map dimensions are therefore not duplicated in the camera or command code.

The map script currently mixes authored prototype dimensions and visual presentation, but this is acceptable for the single fixed test map. Moving map data into a Resource is not necessary for the first Milestone 2 slice.

### Camera

`scripts/camera/camera_controller.gd` is attached directly to `Camera2D`. It reads keyboard actions, moves at an exported default of 600 pixels per second, disables smoothing, and clamps the visible viewport to the test-map bounds.

Camera behavior is independent of unit definitions and should remain unchanged.

### Selection

`scripts/selection/selection_controller.gd` handles primary-button input through `_unhandled_input()`. It:

- Distinguishes clicks from drags with an 8-screen-pixel threshold.
- Uses a physics point query for click selection.
- Queries the narrowly named `selectable_units` group as a collection.
- Converts screen-space drag rectangles into world space.
- Selects units by global center point.
- Clears the previous selection before applying a click or box result.

The controller orchestrates selection. Each unit owns its selected-state flag and indicator visibility. This boundary should be preserved.

### Commands

`scripts/commands/move_command_controller.gd` handles secondary-button input through `_unhandled_input()`. It:

- Converts the pointer from screen space to world space using the viewport canvas transform.
- Clamps the destination through the authoritative `TestMap` bounds.
- Queries selected `TestUnit` nodes through the existing group and selected-state API.
- Sends the same destination to every selected unit.

The controller issues commands but does not move units. This separation should be preserved.

### Placeholder unit

`scenes/units/test_unit.tscn` uses a `CharacterBody2D` root with:

- A 48 × 48 `CollisionShape2D` for click hit testing.
- Two geometric `Polygon2D` nodes for its placeholder body.
- A geometric `Line2D` selection indicator.
- Membership in `selectable_units`.
- A zero collision mask so multiple units may overlap at their shared destination.

`scripts/units/test_unit.gd` currently contains three kinds of responsibility:

| Category | Current contents |
|---|---|
| Authored data | Exported `movement_speed = 180.0` and `arrival_tolerance = 4.0` |
| Runtime state | Selected flag, movement target, whether a target is active, and inherited velocity |
| Behavior/presentation bridge | Direct movement, stopping logic, and selection-indicator visibility |

Additional values are authored directly in the scene:

- The 48 × 48 collision/selection footprint.
- Body geometry and colors.
- Selection-indicator geometry, width, and color.

The four initial positions are authored in the main scene. Selection threshold, camera speed, map dimensions, and placeholder visual constants are also hard-coded or exported in their own narrowly scoped systems; they are not unit-definition data.

The immediate architectural issue is not that `TestUnit` has behavior and state. It is that reusable authored movement values live on each unit node instead of in a shareable definition.

## Proposed data-driven unit definition

### Persistent structure

```text
scripts/
  definitions/
    unit_definition.gd
data/
  units/
    test_unit_standard.tres
    test_unit_fast.tres
```

Proposed class:

```gdscript
class_name UnitDefinition
extends Resource
```

Native `.tres` resources are recommended because they are editor-inspectable, version-control friendly, typed through the custom Resource class, and require no parser, importer, addon, or external dependency.

The resource filenames are generic test labels only. They must not represent factions, named vehicles, setting canon, or a committed roster.

**Requires user approval:** the `scripts/definitions/` and `data/units/` paths, `UnitDefinition` class name, filenames, and whether the proof uses one shared definition or two deliberately different generic definitions. Two definitions are recommended because they prove that scene behavior is actually driven by assigned data rather than a relocated constant.

### Initial fields

Proposed fields:

| Field | Type | Purpose |
|---|---|---|
| `unit_id` | `StringName` | Stable, non-display identifier for the generic definition |
| `display_name` | `String` | Human-readable editor/debug label |
| `movement_speed` | `float` | Movement rate in pixels per second |
| `arrival_tolerance` | `float` | Distance in pixels at which movement snaps cleanly to its target |

Only `movement_speed` and `arrival_tolerance` affect current gameplay. `unit_id` supplies stable identity for validation, diagnostics, and later references without relying on filenames. `display_name` makes assigned resources understandable in the inspector and diagnostics.

The initial Resource should not include health, weapons, armor, damage, cost, production time, faction, technology, sensors, audio, sprites, animations, or other speculative fields.

### Footprints

The current 48 × 48 collision shape serves click hit testing and placeholder physical representation. Because all four instances share one scene and movement has no pathfinding, avoidance, or footprint-sensitive rules, a footprint field is not justified in the first slice.

If future approved unit scenes need definition-driven sizes, add a narrowly named field only after deciding what it means:

- `selection_footprint` if it controls pointer selection only.
- `movement_footprint` if movement or occupancy rules consume it.

Those concepts should not be conflated preemptively.

### Extension policy

`UnitDefinition` can gain fields through small, approved additions when an implemented system has a concrete consumer. Existing `.tres` files can then receive explicit values or carefully reviewed defaults. This permits gradual evolution without committing to a complete roster schema now.

Do not introduce inheritance hierarchies, nested stat Resources, registries, factories, or schema-version machinery until actual variation demonstrates a need.

## Separation of responsibilities

### Authored definition data

`UnitDefinition` and its `.tres` instances should contain reusable authored values only. Runtime code should treat assigned definitions as read-only shared data. A unit must not write destination, selection, velocity, cooldown, or other per-instance state into its Resource.

### Runtime unit state

`TestUnit` should continue to own:

- Whether this instance is selected.
- Its current destination.
- Whether it has an active destination.
- Its `CharacterBody2D` velocity.

These values differ per scene instance and do not belong in a shared definition.

### Scene presentation

`test_unit.tscn` should continue to own the current geometric body, collision shape, and selection-indicator nodes. `TestUnit` may continue toggling its own indicator because that is a small presentation bridge for its selected state.

The definition should not contain colors, polygons, or node paths in the first slice. Visual data can be reconsidered when more than one approved presentation actually exists.

### Commands and selection

`SelectionController` should continue to decide which units are selected. `MoveCommandController` should continue to translate pointer input into bounded movement targets. Neither controller should read `movement_speed` or `arrival_tolerance`; those values matter only while the unit executes its assigned command.

### How `TestUnit` consumes a definition

Proposed node property:

```gdscript
@export var definition: UnitDefinition
```

`_physics_process()` should read the validated definition's `movement_speed` and `arrival_tolerance` instead of node-local exported duplicates. The existing public APIs should remain narrow:

- `set_selected(is_selected: bool)`
- `is_selected() -> bool`
- `set_movement_target(target: Vector2)`

The script should not become a roster loader, resource cache, definition registry, command router, presentation factory, or universal unit base. It remains the behavior script for the current generic prototype unit.

## Validation and failure behavior

### Missing definition

A `TestUnit` without an assigned definition should:

- Produce a clear editor configuration warning identifying the missing `UnitDefinition`.
- Produce a clear runtime error if the scene is run anyway.
- Disable its movement processing rather than silently using old constants or invented fallback values.
- Remain visible for diagnosis; the implementation should not silently delete it.

Selection behavior may remain available for diagnosis, but movement commands must not result in undefined or fallback movement.

### Invalid definition values

Proposed validation rules:

- `unit_id`: must not be empty after converting to text and trimming whitespace.
- `display_name`: should not be blank because it is the human-readable diagnostic label.
- `movement_speed`: must be finite and greater than zero.
- `arrival_tolerance`: must be finite and greater than or equal to zero.

The Resource should expose one typed validation method that returns all problems, for example `get_validation_errors() -> PackedStringArray`. `TestUnit._get_configuration_warnings()` can surface those errors in the editor, while `_ready()` can report them at runtime and disable movement processing.

Validation should report every detected problem in one pass. It must not silently clamp, substitute defaults, or mutate the Resource to make invalid data appear valid.

**Requires user approval:** whether invalid definitions disable only movement processing as recommended or fail more aggressively during development, and whether blank `display_name` is an error or only an editor warning.

## Staged implementation

### Stage 1: Prove definition-driven movement

This is the recommended first implementation slice:

1. Add `scripts/definitions/unit_definition.gd` with the four approved typed fields and validation method.
2. Add one or two generic `.tres` definitions under `data/units/`.
3. Replace `TestUnit`'s exported `movement_speed` and `arrival_tolerance` with an exported typed `definition`.
4. Preserve all runtime selection and destination state in `TestUnit`.
5. Make movement and stopping read their values from the validated definition.
6. Assign definitions to all four existing placeholder instances, either on their shared scene or as main-scene instance overrides.
7. Preserve current camera, map, selection, right-click command, overlap, and movement behavior.

Recommended proof arrangement: assign `test_unit_standard.tres` to two placeholders and `test_unit_fast.tres` to two placeholders. Keep both resources generic and use small, obvious speed differences only to prove data flow. This is prototype verification, not faction asymmetry or balance.

If identical behavior across all four units is more important than visually proving variation, use one definition for every instance and verify shared assignment through the inspector and headless resource loading.

**Requires user approval:** one versus two definitions, their exact neutral IDs/display names and values, and whether definitions are assigned on the shared `test_unit.tscn` or overridden per instance in `milestone_1.tscn`. Instance overrides are recommended only if two definitions are approved.

### Stage 2: Validate failure paths

After Stage 1 works:

- Confirm missing definitions produce editor and runtime diagnostics.
- Confirm each invalid field is reported.
- Confirm invalid units do not move through fallback values.
- Confirm fixing or reassigning a valid definition restores normal behavior.

This stage should not create a general validation framework. The Resource and its consumer can provide the required checks directly.

### Stage 3: Record simulation conventions

Document the proven movement conventions near the relevant code or in an approved technical document. Add focused automated checks only if a small repository-native Godot test scene or script can verify behavior without introducing a testing addon or framework.

Do not expand this stage into combat conventions, replay architecture, networking, or a custom simulation scheduler.

## Deterministic simulation conventions

### Needed now

- Execute unit movement in `_physics_process()` rather than render-frame `_process()`.
- Express movement speed in pixels per second.
- Use the physics-step `delta` for frame-rate-independent displacement.
- Compute movement from current state and the current target without randomness.
- Replace the active target explicitly when a new command arrives.
- Snap to the exact target when within arrival tolerance or when the next step would reach or pass it.
- Set velocity to zero and clear the active-target flag on arrival.
- Keep map-bound clamping in command issuance so every unit receives the same valid target.
- Treat Resource definitions as read-only during play.

These conventions preserve current behavior and make outcomes reproducible for the same initial state, inputs, and physics-step sequence.

### May be considered later

If an approved system requires stronger guarantees, later work may define:

- Stable processing order for interactions between multiple entities.
- Explicit rules for controlled randomness and seeds.
- Numeric precision and rounding conventions.
- Simulation snapshots or command recording.
- A project-wide fixed tick policy beyond Godot's existing physics tick.

None of those are required by the current obstacle-free movement prototype. Milestone 2's first slice should not add a fixed-timestep framework, replay system, networking model, deterministic random-number service, or custom scheduler. Godot physics-step movement alone should not be claimed as cross-platform lockstep determinism.

## Future building definitions

Building data can eventually follow the same pattern:

```text
scripts/
  definitions/
    building_definition.gd
data/
  buildings/
    ...
```

A future `BuildingDefinition` should be a separate typed Resource whose fields are justified by an implemented building slice. It should not inherit from `UnitDefinition`, because movement fields do not apply to buildings.

If both definitions later acquire genuinely identical identity or presentation fields, a small shared base Resource may be evaluated then. Do not introduce that abstraction before duplication and shared behavior are proven.

The first Milestone 2 slice should not create `BuildingDefinition`, building `.tres` files, building scenes, construction data, production data, costs, power requirements, or placement rules.

## Verification

### Acceptance criteria for the first implementation slice

- Godot 4.7 loads the project, custom Resource script, `.tres` files, and scenes without parser or resource errors.
- Every existing placeholder has an explicitly assigned valid `UnitDefinition`.
- `TestUnit` no longer declares duplicate node-local movement speed or arrival tolerance values.
- Movement speed and stopping tolerance are read from the assigned definition.
- Missing or invalid definitions produce clear diagnostics and do not trigger silent fallback movement.
- All Milestone 1 camera, map, selection, deselection, command replacement, destination clamping, movement, overlap, and stopping behavior remains functional.
- Generic test definitions do not introduce faction identity, lore, final unit names, or roster commitments.
- No manager, autoload, registry, factory, addon, or unrelated system is introduced.
- Documentation and changelog accurately describe only what was implemented.

### Headless checks Codex can run

- `git diff --check`.
- Godot 4.7 headless editor load to parse scripts, register `UnitDefinition`, import `.tres` resources, and resolve scene assignments.
- Godot 4.7 headless runtime launch for several physics frames to detect startup and runtime validation errors.
- A narrowly scoped repository-native validation script or test scene only if separately approved; no third-party test framework.
- Final `git diff` and working-tree review for scope and unintended generated files.

### Manual Godot editor tests

- Open each generic `.tres` definition and confirm its typed inspector fields.
- Inspect all four unit instances and confirm the intended definitions are assigned.
- Temporarily remove a definition in the editor and confirm a clear configuration warning; restore it before committing.
- Temporarily enter each invalid value and confirm diagnostics; restore valid values before committing.
- Run the prototype and confirm no unexpected warnings or errors.
- If two definitions are used, verify their approved movement difference while their controls and presentation remain identical.

### Milestone 1 regression checklist

- Pan the camera with WASD and arrow keys; verify normalized diagonal speed and boundary clamping.
- Single-click each unit and verify exclusive selection.
- Click empty ground and verify deselection.
- Drag-select in all four directions and verify zero-, single-, and multi-unit results.
- Move the camera, then repeat click and drag selection to verify coordinate conversion.
- Right-click with no selection and verify no unit moves.
- Command one selected unit and verify unselected units remain still.
- Command multiple units and verify all receive the same destination and may overlap.
- Reissue a command during movement and verify destination replacement.
- Command near all map edges and verify bound clamping.
- Compare movement at low and high frame-rate caps.
- Verify units stop exactly and do not overshoot or oscillate.

## Explicit exclusions

- Combat, enemies, targeting, weapons, damage, armor, health, or status effects.
- Faction identity, ownership, asymmetry, lore, or final unit names.
- Resources, economy, costs, construction, buildings, production, or technology.
- Full unit or building roster schemas.
- Pathfinding, navigation, obstacles, avoidance, separation, formations, or movement classes.
- Facing, acceleration, animation, command queues, or additional commands.
- Final art, audio, effects, user-interface panels, or localization.
- Save/load, replay, networking, multiplayer, lockstep simulation, or custom fixed-timestep frameworks.
- Random-number infrastructure.
- Managers, autoloads, singletons, registries, factories, event buses, addons, dependencies, or external data pipelines.
- Changes to `project.godot` unless separately proposed and explicitly approved.

## Approval gates

Before Stage 1 implementation, obtain explicit approval for:

1. The `UnitDefinition` class name and persistent directory structure.
2. The initial four fields and the decision to defer footprint data.
3. One generic definition versus two, including exact neutral IDs, display names, speeds, and tolerances.
4. Shared-scene assignment versus per-instance overrides.
5. Missing/invalid definition behavior and whether blank display names are errors.
6. Whether any automated validation script or scene is warranted without a testing dependency.

No implementation should infer approval for building schemas, broader unit fields, content identities, project settings, or new infrastructure from approval of the first Resource slice.
