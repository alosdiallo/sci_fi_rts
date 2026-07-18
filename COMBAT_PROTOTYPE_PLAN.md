# Combat Prototype Proposed Implementation Plan

## Status and boundary

This document proposes the smallest staged combat prototype that can validate health, deterministic damage, targeting, attack timing, death, and cleanup. It does not authorize implementation or changes to existing scripts, scenes, Resources, assets, or `project.godot`.

The prototype must remain generic and non-canon. It is not a final Army or Marine roster, balance model, weapon system, or combat architecture.

Items labeled **Requires user approval** must be decided before the applicable implementation slice begins.

## Current architecture

### Authored unit data

`scripts/data/unit_definition.gd` defines the typed `UnitDefinition` Resource. It currently contains only:

- `unit_id: StringName`
- `display_name: String`
- `movement_speed: float`
- `arrival_tolerance: float`

The Resource validates identity and movement values. Two neutral `.tres` instances provide standard and fast test movement data. They are assigned per unit instance in `scenes/main/milestone_1.tscn`.

This is the correct location for reusable authored values shared by multiple unit instances. Resources must remain read-only during play.

### Placeholder unit

`scenes/units/test_unit.tscn` is a generic `CharacterBody2D` with:

- Code-native geometric body presentation.
- A `CollisionShape2D` used for pointer hit testing.
- A visible selection indicator.
- Membership in `selectable_units`.
- No collision response between units.

`scripts/units/test_unit.gd` consumes its assigned `UnitDefinition`. It owns per-instance selection, movement target, active-target state, velocity, movement execution, and selection-indicator visibility.

The unit script is currently small. Combat work should add only state and behavior that inherently belong to an individual combatant; it must not become a global combat coordinator.

### Selection and command handling

`SelectionController` owns click and drag-box selection orchestration. It queries the `selectable_units` group, while each unit owns its selected-state presentation.

`MoveCommandController` handles right-click input, converts screen coordinates to world coordinates, clamps destinations through the authoritative `TestMap`, queries selected units, and assigns movement targets.

Combat targeting should extend this command boundary rather than being embedded in selection logic. Only one controller should interpret a given right-click; two competing `_unhandled_input()` handlers would risk issuing both movement and attack commands.

### Proposed responsibility boundaries

| Concern | Proposed owner |
|---|---|
| Authored health and attack values | `UnitDefinition` |
| Current health | Individual `TestUnit` runtime state |
| Current attack target | Individual `TestUnit` runtime state |
| Cooldown remaining | Individual `TestUnit` runtime state |
| Range and attack timing | Individual `TestUnit` behavior |
| Selection indicator and minimal combat feedback | Unit scene presentation |
| Pointer hit testing and contextual command choice | One unit-command controller |
| Team identifier for the test encounter | Per unit scene instance, not `UnitDefinition` |
| Death and node cleanup | The damaged `TestUnit` |

No global combat manager, autoload, registry, service locator, factory, or event bus is needed.

## Minimal authored combat fields

### Proposed fields

Add only these fields as their implementation slices require them:

| Field | Type | Unit | Validation |
|---|---|---|---|
| `max_health` | `float` | Health points | Finite and greater than zero |
| `attack_damage` | `float` | Health points per hit | Finite and greater than zero |
| `attack_range` | `float` | World pixels, center to center | Finite and greater than zero |
| `attack_cooldown` | `float` | Seconds between hits | Finite and greater than zero |

These fields are sufficient to validate health, fixed damage, center-distance range checks, and timed repeated attacks.

Do not add armor classes, accuracy, critical hits, random variance, status effects, suppression, cover, abilities, ammunition, damage types, targeting priorities, costs, production data, visual references, or audio references.

### UnitDefinition versus WeaponDefinition

For this prototype, the four fields should live directly in `UnitDefinition`.

The current unit has exactly one undifferentiated attack. A separate `WeaponDefinition` would introduce another Resource type, reference, validation path, and ownership question without proving reuse, multiple weapons, weapon swapping, or independent weapon identity. Keeping one attack profile on the unit is the smallest architecture and does not create obvious debt if field names remain explicit.

If an approved later slice requires reusable weapons, multiple attacks per unit, turret-specific behavior, or weapon swapping, the attack fields can then move into a typed `WeaponDefinition`. That extraction should follow a demonstrated need rather than being prebuilt now.

**Requires user approval:** adding the four fields directly to `UnitDefinition`, their types and units, and whether schema growth happens incrementally by slice or all four fields are added together before attack behavior exists. Incremental addition is recommended so every field has an immediate consumer.

## Runtime combat state

### Health

Each `TestUnit` should initialize a private `_current_health: float` from `definition.max_health` when it enters the running scene. Current health must never be written back to the shared Resource.

Proposed narrow API:

- `take_damage(amount: float) -> void`
- `get_current_health() -> float`
- `is_alive() -> bool`

`take_damage()` should reject non-finite or non-positive damage with a clear development error, subtract valid damage once, clamp health to zero, and invoke death exactly once.

### Target

Each attacker should hold at most one current target. A typed `TestUnit` reference is sufficient for the prototype. Every physics step must verify `is_instance_valid(target)` and `target.is_alive()` before using it.

Assigning a new attack target replaces the old target. A movement command should clear the attack target, preserving the existing destination-replacement model and preventing a unit from simultaneously following incompatible commands.

No target list, threat table, target priority, blackboard, or shared registry is needed.

### Cooldown

Each unit should store a private `_attack_cooldown_remaining: float`, initialized to zero. It should be reduced in `_physics_process(delta)` and clamped to zero.

Recommended first-hit convention: a valid in-range explicit attack command may attack immediately when cooldown is ready, then sets the remaining cooldown to `definition.attack_cooldown`. No random timing or render-frame timers should influence damage.

The first prototype should not attempt to catch up multiple missed attacks within one physics step. One attack at most per physics step is simple and predictable.

### Death and cleanup

On reaching zero health, a unit should:

1. Guard against processing death more than once.
2. Mark itself no longer alive.
3. Clear movement and attack state.
4. Set velocity to zero and disable further physics processing.
5. Clear its selected state so its indicator is hidden.
6. Disable its collision shape immediately so it cannot receive new pointer commands.
7. Call `queue_free()` for end-of-frame cleanup.

Selection currently queries the scene group rather than storing a persistent selection collection, so freeing the node naturally removes it from later selection and command queries. Other attackers must clear invalid freed targets on their next physics step.

The first prototype should not leave wreckage, corpses, salvage, death animation, delayed cleanup, respawning, or destruction effects.

**Requires user approval:** immediate `queue_free()` as recommended versus a short diagnostic delay, and whether death should print a concise debug message during the prototype.

## Targeting and commands

### Recommended staged model

Use explicit contextual right-click attack commands, added after health/damage support:

- Right-click a hostile test unit: assign it as the attack target for every selected unit that is on a different test team.
- Right-click ground or a non-hostile unit: preserve the current map-clamped movement command.
- A newly issued movement command clears the attack target.
- A newly issued attack command replaces the previous movement destination and attack target.

This preserves familiar movement behavior while proving intentional target selection. Automatic acquisition is deferred because it introduces search radius, scan frequency, target priority, player-control conflicts, and idle-unit behavior that are not required to validate the core combat loop.

To avoid two handlers interpreting the same right-click, evolve the current command controller into one contextual unit-command controller. Renaming `MoveCommandController` and its file is architecturally clearer, but extending the existing controller with a carefully updated name later is also possible.

**Requires user approval:** contextual explicit attacks versus automatic acquisition, and whether to rename the existing controller to `UnitCommandController` when attack commands are introduced. Contextual explicit attacks and a rename are recommended.

### Range behavior

The smallest prototype should not chase targets. An explicit target remains assigned, but the unit attacks only while center-to-center distance is less than or equal to `attack_range`.

Players can use the existing movement command to place units in range before issuing an attack. If a target moves out of range, attacks pause; if it re-enters range while still targeted, attacks resume.

This deliberately isolates and validates range checks without adding pursuit, pathfinding, stopping-distance logic, attack-move, or movement/attack arbitration.

**Requires user approval:** persistent out-of-range targets without chasing as recommended, or clearing the target immediately when it is out of range.

### Minimal team representation

Add a per-instance integer such as:

```gdscript
@export var test_team_id: int = 0
```

Two units are hostile when their IDs differ. The ID belongs to the runtime scene instance, not `UnitDefinition`, because the same generic definition should be usable by either side.

The test IDs have no faction meaning. They should be described only as team `0` and team `1`, with validation requiring non-negative values. Do not add faction Resources, ownership managers, diplomacy tables, player objects, Army/Marine assignments, or lore-bearing identifiers.

For prototype control, units from both test teams may remain selectable. This lets the user command either side manually, verify damage in both directions, and select a future victim before it dies to verify cleanup. Player-ownership filtering can be designed later.

**Requires user approval:** integer per-instance team IDs, two-team hostility by inequality, and allowing both teams to remain selectable as a test-harness convention.

## Attack model

### Instant-hit

An instant-hit attack applies damage directly when:

- The target is valid, alive, and hostile.
- Center-to-center distance is within the authored range.
- Cooldown is ready.

Advantages:

- Deterministic timing and damage are easy to inspect.
- No projectile travel time or collision ambiguity.
- No projectile scene, lifetime, ownership, impact, or missed-target rules.
- It directly validates the intended health, damage, range, and cooldown rules.

Limitation:

- Without minimal presentation, a hit can be hard to see.

### Simple projectile

A projectile would improve spatial feedback and could make range visually intuitive, but it immediately requires decisions about speed, travel time, collision masks, moving targets, hit detection, target death during flight, lifetime, map bounds, and cleanup. Projectile ordering and collision can also make deterministic reasoning more complex.

### Recommendation

Use instant-hit attacks for the first prototype and do not implement a projectile alongside them. Pair instant damage with one approved code-native feedback method, preferably a small health bar. A brief color flash is another option but requires timing and restoration behavior.

**Requires user approval:** instant-hit versus projectile, plus health bar, brief hit flash, both, or no feedback. Instant-hit with a health bar only is recommended.

## Test encounter

### Recommended setup

Use four visually generic, non-canon test units on the existing bounded map:

- Two units assigned `test_team_id = 0`.
- Two units assigned `test_team_id = 1`.
- Keep the existing generic geometric unit scene.
- Reuse neutral test definitions or add neutral combat-test `.tres` resources only after their exact values are approved.
- Place opposing pairs initially outside attack range but close enough that existing movement can put them in range quickly.

Four units are enough to verify:

- Selecting and commanding either test team.
- Right-click target identification.
- Friendly versus hostile contextual commands.
- Single and multiple attacker behavior.
- In-range and out-of-range checks.
- Repeated attacks at the authored cooldown.
- Fixed damage and health reduction.
- Death after a predictable number of hits.
- A selected victim clearing selection presentation and leaving the selectable group on death.
- Multiple attackers clearing a dead shared target.

No unit should be named, presented, or documented as an Army or Marine roster unit. Team IDs and combat values are test data, not faction balance.

**Requires user approval:** four-unit 2-versus-2 setup, exact positions, exact neutral Resource assignments, and exact prototype health/damage/range/cooldown values.

## Deterministic conventions

### Required now

- Update movement, cooldowns, range checks, and attacks in `_physics_process()`.
- Express cooldown in seconds and range in world pixels.
- Use physics-step `delta` only for countdowns and movement.
- Use fixed authored damage with no random hit, damage, or critical calculations.
- Use explicit current health, target, cooldown, alive, and command state.
- Compare center-to-center squared distance against squared range where practical.
- Apply at most one attack per attacker per physics step.
- Use a documented immediate-first-hit convention.
- Resolve lethal damage and mark the target dead synchronously before another attacker evaluates it later in the same physics step.
- Validate target existence and alive state before every attack.

Godot's scene-tree processing order will affect which simultaneous attacker resolves first. That is acceptable for this isolated prototype if outcomes remain explainable. Do not claim cross-platform lockstep determinism.

### Deferred

Do not add:

- A custom fixed-step simulation framework beyond Godot's existing physics tick.
- Stable global combat ordering infrastructure.
- Replay or command recording.
- Lockstep networking.
- Seeded random-number systems.
- Rollback, snapshots, or prediction.

If later gameplay depends on genuinely simultaneous resolution or network synchronization, processing order and numeric conventions can be revisited with concrete requirements.

## Staged implementation

### Slice 1: Health and damageable state

Smallest recommended first slice:

1. Add only `max_health` to `UnitDefinition` and its validation.
2. Add approved neutral `max_health` values to the existing test Resources.
3. Initialize per-instance current health in `TestUnit`.
4. Add the narrow damageable API and one-shot death cleanup.
5. Add only the approved health/death presentation.
6. Preserve all camera, selection, movement, command, and definition behavior.

Because there is not yet an attack source, this slice needs an approved way to verify damage. Options are:

- A temporary repository-native headless validation script or scene that calls the public damage API.
- Manual calls through the running editor's remote scene/debug facilities.
- Delaying behavioral damage verification until Slice 3.

A narrowly scoped headless validation script is the most repeatable option, but it must be separately approved and must not become a testing framework.

Approval gate before Slice 1:

- `max_health` schema and exact test values.
- Damageable API.
- Validation and missing-data behavior.
- Health/death presentation.
- Immediate death cleanup behavior.
- Verification method.

### Slice 2: Test teams and contextual commands

1. Add per-instance non-negative test team IDs.
2. Add a typed hostility query to the unit.
3. Extend or rename the command controller so it performs one physics point query on right-click.
4. Issue an attack-target command for a hostile body.
5. Preserve movement commands for ground and non-hostile clicks.
6. Make movement and attack commands explicitly replace incompatible command state.

No attacks or automatic acquisition are required in this slice. It proves target identification and command state.

Approval gate before Slice 2:

- Team representation and selectability.
- Controller rename.
- Contextual click rules.
- Target replacement and out-of-range persistence.

### Slice 3: Instant-hit attack timing

1. Add `attack_damage`, `attack_range`, and `attack_cooldown` to `UnitDefinition`.
2. Add approved neutral values to the test Resources.
3. Validate all new authored values.
4. Execute range checks, cooldown countdown, and one instant hit at a time in `_physics_process()`.
5. Clear dead or invalid targets.
6. Add the approved minimal hit feedback, if any.
7. Configure the approved 2-versus-2 test encounter.

Approval gate before Slice 3:

- Exact attack values.
- Instant-hit confirmation.
- Immediate-first-hit timing.
- Range behavior without chasing.
- Feedback choice.
- Test-unit placement and definition assignments.

### Slice 4: Focused regression and documentation

1. Run headless load and runtime checks.
2. Exercise any approved repository-native validation script.
3. Perform the full manual combat and Milestone 1 regression checklists.
4. Update handoff and changelog with only verified implementation.

Do not use this slice to add automatic targeting, projectiles, pursuit, AI, or additional combat features.

Approval gate before Slice 4:

- Whether a validation script remains useful in the repository or should be removed after the prototype is proven.

## Verification

### Acceptance criteria

- All combat fields are typed, validated authored data; no combat values are silently hard-coded in runtime control code.
- Every combat-capable test unit has a valid definition and non-negative test team ID.
- Current health, cooldown remaining, active target, and alive state are per-instance runtime values.
- Only hostile units can become attack targets.
- Ground right-click retains map-clamped movement behavior.
- A new move or attack command replaces incompatible previous command state.
- Out-of-range units do not deal damage.
- In-range units deal exactly `attack_damage` no more frequently than the authored cooldown.
- Damage and cooldown behavior are independent of rendered frame rate.
- Units die exactly once at zero health and are removed cleanly.
- Selected dead units hide their indicator and no longer appear in selection or command queries.
- Attackers clear dead or freed targets without errors.
- The encounter uses generic test data and introduces no faction or roster canon.
- No excluded infrastructure or systems are introduced.

### Headless checks Codex can run

- `git diff --check`.
- Godot 4.7 headless editor load to parse scripts, validate classes, load Resources, and resolve scenes.
- Godot 4.7 headless runtime launch for startup/runtime errors.
- If separately approved, a small repository-native Godot validation script or scene that instantiates generic units, applies known damage, advances physics, and checks health/death results.
- Final working-tree and diff review for unrelated changes or generated files.

Headless startup alone cannot prove pointer targeting, visible feedback, or real-time cooldown feel.

### Manual combat tests

- Select units from each test team and confirm existing selection behavior.
- Right-click ground and verify normal movement still works.
- Right-click a friendly unit and verify the approved non-hostile behavior.
- Right-click a hostile unit and verify it becomes the target without also issuing ground movement.
- Command a target while out of range and confirm no damage occurs.
- Move into range, reissue the attack command if needed, and confirm the first-hit convention.
- Observe several attacks and compare intervals to the authored cooldown.
- Confirm each hit subtracts exactly the authored damage.
- Reissue an attack command and verify target replacement.
- Move a targeted unit out of range and verify attacks pause.
- Kill a unit and verify it disappears once without errors.
- Select a unit before it dies and verify its indicator and selection membership are cleaned up.
- Have multiple attackers share one target and verify all clear it after death.
- Repeat at low and high rendered frame-rate caps.

### Milestone 1 and unit-definition regression tests

- Pan with WASD and arrow keys; verify camera speed, diagonal normalization, and boundary clamping.
- Single-click, empty-ground deselect, and drag-box select in all directions.
- Repeat selection after moving the camera.
- Right-click movement after moving the camera; verify screen-to-world conversion.
- Reissue movement commands and verify destination replacement.
- Command map edges and verify destination clamping.
- Verify standard and fast generic definitions retain their respective movement speeds.
- Verify units stop cleanly without overshoot or oscillation.
- Verify missing or invalid definitions still produce clear errors and disable movement.

## Explicit exclusions

- Automatic target acquisition, attack-move, pursuit, patrol, guard, follow, or stop commands.
- Projectiles if instant-hit is approved.
- Multiple weapons, weapon swapping, turrets, or a `WeaponDefinition` in the first prototype.
- Armor, damage classes, accuracy, evasion, random damage, critical hits, cover, suppression, status effects, abilities, ammunition, or area damage.
- Healing, repair, regeneration, resurrection, wreckage, salvage, corpses, respawning, or veterancy.
- Facing, attack animation, death animation, final effects, final art, sound, or music.
- Final Army or Marine units, faction balance, roster names, ownership systems, diplomacy, or AI.
- Pathfinding, pursuit navigation, collision avoidance, formations, or separation.
- Economy, resources, costs, construction, buildings, production, or technology.
- Fog of war, sensors, line of sight, targeting priorities, or threat systems.
- Replay, networking, lockstep, rollback, seeded RNG, or custom simulation frameworks.
- Managers, autoloads, registries, factories, event buses, service locators, addons, dependencies, or third-party test frameworks.
- Changes to `project.godot` unless separately proposed and explicitly approved.

## Consolidated approval gates

Before implementation, obtain explicit decisions for:

1. Adding `max_health`, `attack_damage`, `attack_range`, and `attack_cooldown` directly to `UnitDefinition`, including incremental versus all-at-once schema changes.
2. Instant-hit attacks versus a simple projectile.
3. Per-instance integer test team IDs and hostility-by-inequality.
4. Contextual explicit right-click attack commands versus automatic targeting.
5. Renaming the movement controller to a broader unit-command controller.
6. No-chase range behavior and whether out-of-range targets persist.
7. Health bar, hit flash, both, or no combat feedback.
8. Immediate `queue_free()` death versus delayed diagnostic cleanup.
9. Four-unit 2-versus-2 encounter, exact positions, Resource assignments, and all prototype combat values.
10. Immediate-first-hit cooldown behavior.
11. Whether a narrowly scoped automated validation script or scene is worthwhile and whether it should remain after validation.

Approval of the combat prototype must not be interpreted as approval for final faction units, a complete combat schema, projectiles, AI, production, economy, or any explicitly excluded system.
