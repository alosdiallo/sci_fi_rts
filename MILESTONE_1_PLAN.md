# Milestone 1 Proposed Implementation Plan

## Status

This document is a proposal only. It does not authorize implementation, changes to `project.godot`, or creation of scripts, scenes, or assets.

The repository remains in pre-production. Milestone 1 is limited to camera movement, a bounded test map, unit selection, and basic movement.

Items labeled **Requires user approval** are architectural or project-configuration choices that must be approved before implementation.

## Detected Godot version

`project.godot` declares `config_version=5` and the feature tag `"4.7"`. The proposed target is therefore **Godot 4.7**.

## Proposed directory and file structure

```text
assets/
  placeholder/
    unit_placeholder.svg
scenes/
  milestone_1/
    milestone_1.tscn
    test_map.tscn
    test_unit.tscn
scripts/
  milestone_1/
    camera_controller.gd
    selection_controller.gd
    test_unit.gd
```

The files above would remain narrowly scoped to the interaction prototype. Reusable authored unit definitions are deferred until Milestone 2 because Milestone 1 needs only a placeholder unit and should not prematurely establish the roster-data format.

**Requires user approval:** directory names, whether the placeholder should be an SVG file or editor-authored primitive, and whether the prototype should live under `milestone_1/` or use feature-oriented directories intended to persist.

## Proposed scene tree

```text
Milestone1 (Node2D)
├── TestMap (Node2D)
│   ├── Ground (Polygon2D or Sprite2D)
│   └── BoundaryVisuals (Node2D)
├── Units (Node2D)
│   └── TestUnit (CharacterBody2D)
│       ├── PlaceholderVisual (Sprite2D or Polygon2D)
│       └── SelectionIndicator (Polygon2D or Line2D)
├── CameraRig (Node2D)
│   └── Camera2D
└── Interface (CanvasLayer)
    └── SelectionBox (Control)
```

Responsibilities would remain separated:

- `camera_controller.gd` handles camera input and map-bound clamping.
- `selection_controller.gd` handles pointer gestures, hit testing, and selection state.
- `test_unit.gd` owns the placeholder unit's selected state, destination, and deterministic movement.
- The root scene connects these pieces without becoming a general game manager.

**Requires user approval:** use of `CharacterBody2D` for the test unit, the exact selection-controller node placement, and whether the selection rectangle is drawn with a `Control`, `_draw()` on a dedicated node, or another code-native method.

## Camera behavior

Proposed behavior:

- Move with keyboard input in four directions.
- Optionally pan when the pointer reaches the viewport edge.
- Scale movement by elapsed time so camera speed is frame-rate independent.
- Clamp the camera view to the test-map bounds so empty space outside the map cannot be exposed.
- Do not add zoom, rotation, smoothing, minimap navigation, or camera bookmarks in Milestone 1.

**Requires user approval:** whether edge scrolling is included, the initial camera speed, input keys, viewport assumptions, and whether camera smoothing is explicitly disabled or merely deferred.

## Test-map approach

Use one fixed, editor-authored rectangular map with clearly visible edges and enough open space to test camera panning, selection, and movement. The map would contain no terrain gameplay, obstacles, pathfinding requirements, hazards, resources, or final Mars art.

The map bounds should be stored once and shared with camera clamping and movement-command validation rather than duplicated as unrelated constants.

**Requires user approval:** map dimensions, the source of the shared bounds (for example, an exported `Rect2` on the map root), and whether movement destinations outside the bounds are clamped or rejected.

## Selection behavior

### Single click

- Primary-button press and release with movement below a small drag threshold counts as a click.
- Clicking a selectable unit selects it and clears any previous selection.
- Clicking empty ground clears the current selection.
- A selected unit displays a simple, clearly visible selection indicator.

### Drag box

- Pressing and dragging the primary button beyond the threshold displays a screen-space selection rectangle.
- On release, selectable units whose selection point lies within the rectangle become selected.
- Dragging in any direction is supported by normalizing the rectangle.
- With the initial one-unit test, box selection still uses a collection-based selection API so it does not require replacement when more placeholders are added for verification.

Modifier-key additive and subtractive selection, control groups, double-click selection, selection filters, and prioritization rules are excluded.

**Requires user approval:** drag threshold, unit inclusion rule (center point versus visual/collision overlap), and whether Milestone 1 verification should include multiple instances of the same placeholder unit.

## Basic movement-command behavior

- Secondary click on valid map ground issues a destination to all currently selected placeholder units.
- A unit moves directly toward its destination at a fixed speed using a frame-rate-independent update.
- The unit stops within a small arrival tolerance and does not oscillate around the destination.
- Destinations remain inside the bounded map.
- Reissuing a command replaces the previous destination.
- No pathfinding, collision avoidance, formations, facing system, acceleration, animation, command queue, or network synchronization is included.

For more than one selected placeholder, all units may receive the same destination for interaction testing; formation offsets and overlap resolution are deferred.

**Requires user approval:** direct kinematic movement versus a navigation-based approach. Direct movement is proposed for the obstacle-free Milestone 1 map because navigation and avoidance are outside the milestone. Movement speed, arrival tolerance, and the treatment of multiple selected units also require approval.

## Required input actions

Proposed actions:

| Action | Proposed default |
|---|---|
| `camera_left` | `A` and Left Arrow |
| `camera_right` | `D` and Right Arrow |
| `camera_up` | `W` and Up Arrow |
| `camera_down` | `S` and Down Arrow |
| `select_primary` | Left Mouse Button |
| `command_move` | Right Mouse Button |

Implementation would require adding these actions to the `[input]` section of `project.godot`, preferably through the Godot editor. If the milestone scene is to run on project launch, `[application] run/main_scene` would also need to reference the approved root scene.

No `project.godot` changes are made by this plan.

**Requires user approval:** action names, bindings, whether mouse buttons should be represented as input actions or handled as pointer events, and authorization for the eventual `project.godot` edit and main-scene assignment.

## Placeholder-art strategy

Use flat code-native or simple repository-authored geometric shapes with high contrast:

- A solid shape for the unit.
- A contrasting outline or ring for selection.
- A flat ground color plus a visible border or lightweight grid for the map.
- A translucent rectangle for drag selection.

No generated art, third-party assets, faction-specific visual canon, final palette, animation, or setting detail should enter Milestone 1.

**Requires user approval:** code-native shapes versus a small authored SVG placeholder. No asset should be created until that choice is approved.

## Acceptance criteria

- The project opens in the detected Godot version without parser errors or warnings introduced by Milestone 1.
- The approved Milestone 1 scene runs.
- The player can move the 2D camera across a bounded test map and cannot expose space beyond its limits.
- A placeholder unit can be selected with a single click and visibly indicates selection.
- Clicking empty ground clears selection.
- Dragging a selection box in any direction can select the placeholder unit.
- A secondary click issues a movement command to selected units.
- A commanded unit moves predictably to the valid destination and stops without visible oscillation.
- Camera and unit movement behave consistently at differing frame rates.
- No systems outside the Milestone 1 boundary are introduced.
- Documentation and `CHANGELOG.md` reflect the implemented result when implementation is complete.

## Manual verification checklist

- Open the project in Godot 4.7 and confirm there are no import, parser, or configuration errors.
- Run the approved Milestone 1 scene.
- Pan to every map edge with each approved camera input and confirm clamping.
- Confirm opposite camera inputs cancel cleanly and diagonal movement is not unintentionally faster.
- Single-click the placeholder and confirm the selection indicator appears.
- Click empty map space and confirm selection clears.
- Drag selection boxes left-to-right, right-to-left, top-to-bottom, and bottom-to-top.
- Start a drag below the threshold and confirm it behaves as a click.
- Command the selected unit to several valid points, including near each map edge.
- Replace an in-progress movement command and confirm the unit changes destination.
- Confirm an unselected unit does not respond to a movement command.
- Test at low and high frame-rate caps and compare camera speed, unit speed, and stopping behavior.
- Confirm no combat, economy, construction, production, faction, campaign, hazard, or final-art behavior is present.
- Review `git diff` to confirm only approved files and configuration changed.

## Explicit exclusions

- Combat, enemies, damage, weapons, armor, and targeting.
- Resources, economy, power, gathering, or supply lines.
- Construction, production, buildings, or technology trees.
- Final faction mechanics or faction-specific units.
- Campaign scripting, missions, objectives, briefings, victory, or defeat.
- Environmental hazards or terrain effects.
- Pathfinding, obstacle avoidance, formations, collision resolution, or group movement polish.
- Fog of war, sensors, minimap, user-interface panels, or command queues.
- Final pixel art, animation, audio, visual effects, or lore-bearing assets.
- Data-driven roster resources, save/load, settings menus, accessibility systems, or localization.
- Multiplayer, networking, procedural content, advanced physics, or 3D graphics.
- Third-party dependencies or addons.
