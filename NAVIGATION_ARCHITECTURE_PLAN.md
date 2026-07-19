# Navigation Architecture Plan

## Status and boundary

This document proposes the navigation foundation for the next technical phase. It does not authorize implementation, changes to gameplay code, scenes, Resources, tests, or `project.godot`.

The current prototype has no obstacle routing. Every navigation choice and implementation slice below remains approval-gated.

## Approved project principle

> The game will deliberately use modest on-screen unit counts so navigation, group movement, recovery behavior, and tactical AI can prioritize quality over maximum simulation throughput. Higher CPU cost is acceptable when it produces meaningfully better in-game behavior. Performance optimization must not prematurely weaken route quality, reliability, or recovery.

Navigation priorities, in order:

1. Correctness and reliability.
2. Route quality.
3. Congestion and deadlock handling.
4. Responsive replanning.
5. Performance optimization.

Optimization is valid only after representative behavior meets the first four priorities. A faster system that produces avoidable deadlocks, implausible detours, unstable replans, or silent failures is not an improvement.

## 1. Quality goals

“Intelligent movement” means more than eventually reaching a point:

- Every reachable command completes within a reasonable, observable time.
- A commanded unit never remains permanently stuck without recovery or failure feedback.
- Routes avoid obviously poor detours when a materially shorter valid route exists.
- Units respond when a route, waypoint, or destination becomes blocked.
- Route validity accounts for the moving unit's footprint.
- Groups traverse chokepoints without permanent mutual deadlock.
- Units spread across usable route width where practical instead of forming needless single-file lines.
- Explicit combat targets behind obstacles are approached through valid routes to valid firing positions.
- Unreachable commands fail predictably, visibly, and without stale movement state.
- New commands replace old intent promptly.
- Replans are stable enough that units do not oscillate between similar routes.
- Movement remains legible: the player can understand the destination, current route, delay, recovery, and failure.

Quality must be evaluated against known reasonable routes, congestion scenarios, and recovery cases—not only a single unit moving around one box.

## 2. Expected scale

Use provisional technical test tiers:

| Tier | Active moving units | Purpose |
|---|---:|---|
| Small | 1–8 | Correctness, route quality, combat approach, and edge cases |
| Typical | Approximately 10–30 | Normal group movement, crossing traffic, chokepoints, and replanning |
| Stress | Approximately 40–60 | Performance trend, recovery load, and degraded-but-correct behavior |

These are test ranges, not final population limits or balance commitments.

At these scales, individual or small-batch path queries, clearance-aware routing, deterministic recovery, and better route comparisons are affordable candidates. The architecture may spend more CPU to avoid poor routes or recover a blocked group, provided it measures that cost and avoids waste such as full path recalculation every frame.

No final unit cap should be inferred. Revisit the tiers when representative infantry squads, vehicles, buildings, maps, and command patterns exist.

## 3. Current movement foundation

### Implemented behavior

The prototype currently provides:

- Direct `CharacterBody2D` movement in `_physics_process()`.
- Definition-driven movement speeds of 180 and 240 pixels per second.
- Replaceable ground destinations.
- Explicit hostile-target approach.
- A preferred firing distance eight pixels inside authored attack range.
- Moving-target destination refresh after eight pixels of displacement.
- Collision-shape-derived footprint half-extents.
- Footprint-aware map clamping with diagnostic center-only fallback.
- Friendly-only deterministic local separation.
- Stable `NodePath` ordering for coincident separation and angular attack slots.
- Distinct angular approach destinations for same-team attackers sharing a target.
- Contextual right-click ground and hostile-target commands.
- Deterministic cooldown and instant-hit combat.
- `selectable_units` for selection/commands and `test_units` for simulation discovery.
- A native headless validation runner for stable definition, health, targeting, footprint, and approach calculations.

It intentionally has:

- No obstacle representation or route query.
- No waypoint path state.
- No route failure or stuck state.
- No physical hostile blocking.
- No global navigation system, manager, autoload, registry, or event bus.

### What can be reused

- `CharacterBody2D` remains the unit motion body.
- Definition-driven speed and physics-step execution remain unchanged.
- Existing ground and explicit-target commands remain the source of player intent.
- Map and footprint clamping remain final safety boundaries.
- Friendly separation remains local overlap mitigation.
- Angular firing slots remain candidate combat destinations.
- Current target validity, death, cooldown, and command-replacement rules remain authoritative.
- Pure calculations and the native headless runner can gain narrow deterministic navigation checks.

### What navigation supplements or replaces

- Direct destination direction becomes direction toward the next valid route waypoint.
- A combat slot is no longer automatically reachable; it becomes a candidate goal that must be projected to valid navigation space and routed to.
- Center-only map validity becomes navigation-space and footprint-clearance validity.
- Existing separation remains secondary; it must not steer through blocked cells or permanently away from the route corridor.
- Movement state must gain explicit route status, progress, replan reason, and failure/cancellation transitions.

## 4. Navigation technology comparison

### Comparison

| Option | Strengths | Weaknesses | Fit |
|---|---|---|---|
| `NavigationServer2D` and navigation maps | Direct low-level queries, multiple maps, path metadata/post-processing, no required agent node | Mesh construction/synchronization complexity; footprint sizes require separately prepared maps | Strong mesh alternative, but not recommended first |
| `NavigationRegion2D` | Editor-visible traversable polygons and straightforward map composition | Runtime building changes and multiple footprint bakes add lifecycle complexity | Useful for authored terrain if mesh approach is later chosen |
| `NavigationAgent2D` | Path following support, debug path, optional RVO avoidance, target/waypoint thresholds | Experimental; must be updated each physics frame; avoidance radius does not change route clearance; RVO is not reliable as a narrow-space constraint | Do not make it the initial architecture |
| `AStarGrid2D` | Native shortest-path grid, explicit solid cells, heuristics, diagonal policies, simple headless tests | Clearance, costs, smoothing, dynamic updates, and metadata need project code around it | Best initial global router |
| Custom grid A* | Full control over clearance, costs, tie-breaking, alternate routes, and diagnostics | Highest maintenance and correctness burden; duplicates a native search prematurely | Defer until `AStarGrid2D` proves insufficient |
| Global path plus current separation | Separates obstacle correctness from friendly overlap; preserves proven local behavior | Needs corridor constraints and stuck recovery so separation cannot invalidate the route | Recommended hybrid |
| Flow fields/shared paths | Efficient for many units sharing a goal; can distribute traffic with suitable costs | More infrastructure, dynamic-update complexity, footprint variants, and poor justification at current counts | Later measured optimization only |

### Relevant Godot 4.7 capability notes

- `AStarGrid2D` supplies shortest-path queries on a partial 2D grid, solid cells, selectable heuristics, and controlled diagonal movement.
- `NavigationAgent2D.radius` affects avoidance, not normal pathfinding. Different actor sizes require navigation polygons baked with different agent radii and separate navigation maps.
- Godot's polygon path queries support corridor-funnel post-processing and optional simplification, but path quality still depends on navigation-polygon layout.
- Dynamic avoidance obstacles are soft avoidance influences and are not reliable constraints in crowded or narrow spaces.

Official references:

- [AStarGrid2D](https://docs.godotengine.org/en/4.7/classes/class_astargrid2d.html)
- [NavigationAgent2D](https://docs.godotengine.org/en/4.7/classes/class_navigationagent2d.html)
- [Different navigation actor types](https://docs.godotengine.org/en/4.7/tutorials/navigation/navigation_different_actor_types.html)
- [Navigation path-query post-processing](https://docs.godotengine.org/en/4.7/tutorials/navigation/navigation_using_navigationpathqueryobjects.html)
- [Navigation obstacles](https://docs.godotengine.org/en/4.7/tutorials/navigation/navigation_using_navigationobstacles.html)

### Recommendation

Start with a **clearance-aware uniform navigation grid backed by `AStarGrid2D`, plus explicit waypoint following and the existing friendly separation as bounded local steering**.

Use one map-owned navigation model, not an autoload. It should:

- Convert world positions to/from cells.
- Track static blocked cells.
- Produce a clearance value or footprint-specific traversability view.
- Validate/project destinations.
- Query deterministic paths with a corner-safe diagonal policy.
- Simplify waypoints only after verifying footprint-clear line of sight.
- Expose route results and failure reasons to the unit-level movement consumer.

Begin with one approved provisional footprint class while preserving a path to a small number of clearance views. Do not add final movement classes now.

Why this is the best initial fit:

- Grid occupancy and clearance are explicit and inspectable.
- Static buildings map naturally to blocked cells and update regions.
- Unreachable, enclosed, narrow-passage, and footprint-fit cases are deterministic and headless-testable.
- Route cost and alternate-route behavior are controllable.
- It integrates with current direct `CharacterBody2D` waypoint movement and separation.
- It avoids depending on RVO for correctness in chokepoints.
- Modest unit counts permit quality-oriented individual queries before shared-path optimization.

## 5. Global routing and local movement boundary

### Global routing owns

- Static terrain and constructed-structure occupancy.
- Start and destination projection to valid navigation space.
- Connectivity and destination reachability.
- Footprint clearance.
- Alternate-route search.
- Narrow-passage validity.
- Path cost and global route length.
- Waypoint corridor generation and safe simplification.
- Route invalidation after topology changes.

### Local movement owns

- Following the current waypoint without exceeding authored speed.
- Friendly separation and immediate overlap correction.
- Short-range queueing/yield behavior.
- Distinct group and combat-slot destinations.
- Detecting lack of progress.
- Reporting local blockage as a replan reason.
- Maintaining selected command intent until completion, replacement, or explicit failure.

### Boundary rules

- Local steering may adjust velocity only within a bounded influence.
- The adjusted short step must remain in navigable/clear space for the unit footprint.
- Separation must never create a shortcut across blocked cells or skip an obstacle corner.
- Waypoints may be advanced only after a footprint-safe corridor/line check or arrival threshold.
- Persistent local deviation beyond a route-corridor tolerance triggers recovery or replan rather than stronger steering.
- The global router does not solve momentary friendly overlap; local movement does not decide global detours.

## 6. Navigation representation

### Polygon navigation meshes

Benefits:

- Natural continuous-space routes.
- Funnel processing can produce short corner-following paths.
- Good for irregular geometry.

Costs:

- Separate bakes/maps are required for different radii.
- Runtime building updates and synchronization require care.
- Polygon layout can produce unexpected corridor choices or detours.
- Grid-like building placement and clearance testing are less direct.

### Uniform grid

Benefits:

- Exact blocked/clear state, deterministic connectivity, straightforward building updates, and easy overlays/tests.
- Natural fit for future placement cells and map-authored terrain costs.

Costs:

- Cell resolution trades memory/query cost against geometric fidelity.
- Raw cell paths look stair-stepped and need safe simplification.
- Coarse cells can reject valid narrow routes or permit corner clipping if configured poorly.

### Clearance-aware grid

Recommended extension:

- Keep one base occupancy grid.
- Derive distance-to-obstacle/clearance information.
- A route cell is traversable when its clearance meets the unit's approved conservative radius.
- Initially test one clearance requirement; later use a small number of approved footprint classes or query thresholds.

This avoids copying full occupancy state for every unit while allowing infantry squads, buggies/rovers, and possibly drones to differ later. Buildings are obstacles, not moving actors. Flying/terrain-ignoring drones may eventually require a separate navigation layer, but that is unresolved.

### Multiple navigation maps

If polygon navigation is later adopted, different actor sizes require separately baked maps. In the recommended grid architecture, equivalent behavior can use clearance thresholds or a small number of derived traversability grids.

### Smoothing

Use grid A* for correctness, then greedily simplify consecutive waypoints only when a footprint-inflated line/sweep between them remains valid. Do not use visual smoothing that clips obstacle corners. More advanced string-pulling may be considered after the grid corridor representation is proven.

### Decisions required before implementation

- Provisional world and cell scale.
- Whether movement is top-down orthogonal or slightly angled only in presentation.
- One initial conservative footprint and how it maps to clearance.
- Diagonal policy and corner-cutting rule.
- Whether the first arena has one terrain-access layer.
- Whether building footprints align to the navigation grid.

## 7. Route quality

### Criteria

For each known arena route, measure:

- Total path length and estimated travel time.
- Ratio to a known reasonable or reference shortest route.
- Turn count and severity.
- Needless departure from a direct corridor.
- Use of narrow versus broad alternatives.
- Expected congestion cost for group commands.
- Stability when replanning from nearby positions.
- Visual plausibility after safe simplification.

### Initial policy

- Use an admissible octile-style heuristic if eight-direction movement is approved.
- Disallow diagonal corner cutting where the footprint cannot clear both adjacent blocked cells.
- Prefer shorter travel time; with equal/near-equal costs, prefer fewer meaningful turns and stable continuation.
- Do not initially add dynamic unit density to global cost. First prove static route quality.
- For group routes, a wider path may receive a small approved preference only after chokepoint evidence shows value; it must not create absurd detours.

### Post-processing

- Safe waypoint simplification is appropriate in the first foundation because raw grid paths are visually poor.
- Funnel algorithms are native to polygon corridors, not automatically applicable to a plain grid path.
- A grid line-of-sight/string-pulling pass is appropriate if it checks the full footprint corridor.
- Cost weighting may later represent terrain or congestion, but no terrain costs are approved now.

## 8. Group movement

### Command intent

A shared ground click represents one group destination region, not an instruction for every center to occupy one pixel.

### Recommended staged strategy

1. Generate deterministic distinct final destinations near the clicked point, validated for footprint and reachability.
2. Query individual routes initially so differing starts, speeds, footprints, and obstructions remain correct.
3. Detect equivalent route corridors and allow later sharing/caching only after behavior is proven.
4. Preserve current local separation as a secondary stabilizer.
5. At chokepoints, use explicit queue/yield rules rather than increasing repulsion until units deadlock.

### Comparison

| Strategy | Use now? | Reason |
|---|---|---|
| Individual A* query per unit | Yes, initially | Best correctness/debug baseline at modest counts |
| Shared path copied to all units | No | Different starts/footprints and exact corridor entry can invalidate it |
| Shared route corridor with individual lane/entry decisions | Later | Promising once individual correctness exists |
| Flow field per destination | Later optimization | Useful only when measurements show many equivalent queries |

### Chokepoints and yielding

- Units approaching the same narrow passage should establish deterministic priority from command sequence plus stable unit ordering.
- A unit already inside a passage should normally retain priority.
- Waiting units stop at valid holding points instead of crowding the entrance.
- Faster units must not continuously push slower units off the route.
- If a queue makes no progress, stuck recovery escalates to replan or alternate-route evaluation.
- If space permits, units should use different valid cells/corridors rather than converge onto one centerline.

This is not a formation system. It is destination distribution, corridor use, and passage recovery.

## 9. Stuck detection and recovery

Stuck recovery is mandatory.

### Measurable signals

Track per active route:

- Displacement over a fixed observation window.
- Reduction in distance to the next waypoint.
- Reduction in remaining route cost or distance.
- Repeated sign/direction reversal in local steering.
- Time spent outside the expected route corridor.
- Repeated failure to reach/advance a waypoint.
- Navigation topology revision since the route was created.

A unit is potentially stuck only while it has active command intent and expected movement. Intentional waiting at a chokepoint must be represented separately so it is not immediately mistaken for failure.

### Recommended staged recovery

1. **Refresh local state:** clear insignificant steering residue, recompute immediate separation/yield choice, and re-evaluate waypoint arrival.
2. **Repair waypoint progress:** skip an obsolete waypoint only if a footprint-safe connection to a later waypoint exists; otherwise replace the local waypoint.
3. **Recalculate global route:** query from the current valid cell using the original command destination and current topology.
4. **Try a nearby valid destination:** search a bounded, deterministic ring around the intended destination, preserving command meaning and footprint clearance.
5. **Fail visibly:** clear active movement/route state, retain an explicit failure reason briefly, and show temporary invalid/unreachable feedback.

Rules:

- No teleportation.
- No random nudge or random alternate destination.
- No silent cancellation.
- No indefinite oscillation.
- Recovery attempts and reasons must be counted and visible in debug mode.
- Repeated identical failures should escalate rather than restart forever.

Exact observation windows, attempt counts, and time budgets require arena measurement and approval.

## 10. Replanning

### Required triggers

- A new ground or target command.
- Material destination change.
- A combat target moves enough to invalidate the current firing route/goal.
- A building or static obstacle changes cells intersecting or threatening the route.
- The next segment fails clearance validation.
- The unit meets the approved stuck condition.
- A chokepoint queue exceeds its progress threshold and an alternate route may be better.

### Optional trigger

A low-frequency safety refresh may be tested only if missed topology events prove possible. Event/revision-driven invalidation is preferable.

### Deliberate computation

- Never query a complete route every physics frame.
- Keep the current eight-pixel combat-target threshold as an initial candidate for goal reconsideration, but route recalculation may need a larger threshold or destination-cell change to avoid churn.
- Stagger nonurgent replans deterministically across physics ticks if typical/stress tiers show spikes.
- Urgent player commands and invalid routes take priority over cosmetic route improvement.
- Reuse paths only when start corridor, goal region, footprint class, topology revision, and cost policy are compatible.

## 11. Dynamic obstacles

| Category | Global navigation | Local movement |
|---|---|---|
| Static terrain | Always blocked/costed globally | Boundary safety only |
| Constructed building | Update blocked cells and topology revision | Avoid pending update and nearby footprint |
| Destroyed building | Clear cells and increment revision | Resume/replan if route improves or was blocked |
| Moving friendly unit | Normally not a global obstacle | Separation, queueing, yielding, stuck evidence |
| Moving hostile unit | Not initially a global obstacle | Initially nonblocking, preserving current rule |
| Temporary congestion | Avoid global hard-blocking initially | Local queue/recovery; optional temporary cost later |
| Temporarily blocked goal | Keep original intent plus bounded alternate goal | Wait/retry under explicit policy |

Buildings should update a bounded occupancy region on placement, construction-state change if relevant, and destruction. A topology revision identifies stale routes. Rebuilding the entire grid for one building should not be the default.

Do not use dynamic avoidance obstacles as the sole guarantee that a narrow route is passable; official Godot guidance describes them as soft avoidance and not reliable constraints in crowded or narrow spaces.

## 12. Unreachable destinations

### Cases and policy

- **Click outside navigable space:** project to the nearest valid point within an approved maximum radius; otherwise fail immediately.
- **Point inside an obstacle:** choose the nearest deterministic valid point that preserves approach direction where possible; show the adjusted destination in debug mode.
- **Enclosed goal:** report unreachable after connectivity/path query failure; do not select a point outside the enclosure and imply success.
- **Footprint too large:** fail for that unit even if a smaller unit can pass; group results may be partial but must be visibly reported.
- **Unreachable combat target:** search approved firing positions around the target for a reachable candidate; if none exists, retain target only under an approved retry policy, otherwise clear combat movement and report failure.
- **Route becomes impossible:** replan once topology is synchronized, then use bounded alternate-destination recovery, then fail visibly.

### Nearest-valid behavior

Nearest-valid projection must have:

- A bounded search radius.
- Deterministic cell ordering and tie-breaking.
- Footprint clearance.
- Connectivity to the start where required.
- A maximum displacement beyond which the command fails rather than being silently reinterpreted.

### Cleanup

Failure clears velocity, waypoints, approach cache, and active movement state. Target cleanup follows the approved combat retry policy. A temporary marker/reason remains for debugging and player feedback; no final UI is designed here.

## 13. Combat movement

### Explicit target flow

1. Validate the hostile target under existing rules.
2. Generate deterministic angular firing-slot candidates using each attacker's preferred firing distance.
3. Project each candidate to a footprint-valid navigable point.
4. Test line/route reachability; if blocked or invalid, search nearby angular/radial candidates deterministically.
5. Route to the chosen firing position.
6. Stop and attack as soon as actual current center distance is within authored range and the attack line/rules permit it.

Initially, obstacle-aware movement does not imply line-of-fire obstruction unless separately approved. The route must still avoid movement obstacles.

### Moving targets

- Continue actual range checks every physics step.
- Refresh candidate goals when the target crosses the approved movement/cell threshold or makes the route obsolete.
- Reuse a valid route while the goal remains within its accepted destination region.
- Reset cooldown when actual range is lost, preserving current behavior.
- Do not predict or intercept target motion.

### State transitions

- Target death/invalidity clears route and target state.
- Retargeting replaces the route and starts a fresh cooldown.
- A ground command clears target route/state.
- No automatic target acquisition is introduced.
- Units never direct-move through obstacles toward a target center when route generation fails.

## 14. Navigation test arena

Create a separate geometric technical arena when implementation is approved. Preserve the current scene as the Milestone 2 regression baseline.

### Proposed layout

- **Detour block:** one large rectangle between start and goal.
- **Route comparison:** one short route and one visibly longer alternate around paired obstacles.
- **Narrow passage:** just wide enough for the approved initial footprint.
- **Wide passage:** a longer or similar alternate capable of multiple units abreast.
- **Dead end:** a corridor requiring reversal/replan.
- **Enclosed pocket:** valid-looking goal space with no connected entrance.
- **Combat wall:** hostile target behind an obstacle with reachable firing positions around it.
- **Map-edge lane:** destination and corner path near map bounds.
- **Chokepoint:** holding areas on both sides for group traversal.
- **Crossing intersection:** two group streams with conflicting paths.
- **Temporary blocker fixture:** a toggleable geometric obstacle/occupancy region.
- **Clearance gallery:** passages sized around provisional small/medium footprint thresholds.

All fixtures use editor-authored or code-native geometry, labeled only for technical debugging. No final art, buildings, faction identity, terrain effects, or lore.

## 15. Acceptance metrics

Provisional metrics must be calibrated in Slice 1; thresholds require approval after baseline measurements.

| Concern | Metric |
|---|---|
| Reachability | 100% completion for every known reachable single-unit arena case |
| False success | 0 units clipping obstacles or accepting disconnected goals |
| Failure detection | Every known unreachable case reaches explicit failure within an approved time/recovery budget |
| Route quality | Path length/travel-time ratio remains within an approved margin of the known reasonable route |
| Recovery | Stuck fixtures recover or fail explicitly within an approved bounded time |
| Replan response | Invalidated routes begin urgent replan within an approved number of physics ticks |
| Chokepoint | All units in small/typical groups clear the passage without permanent deadlock |
| Deadlock | Zero permanent deadlocks in the deterministic arena command suite |
| Oscillation | No persistent waypoint/replan switching after route and topology stabilize |
| Stability | Small start/goal changes do not cause needless large route flips without cost benefit |
| Responsiveness | New commands replace route intent immediately; usable route begins within approved latency |
| Small tier | Full quality and debug instrumentation enabled |
| Typical tier | Same correctness/recovery; stable frame time and bounded query spikes |
| Stress tier | No correctness loss or permanent deadlock; measured slowdown may be accepted before optimization |

Record route length, compute time, replans, recoveries, completion/failure time, and reason. A slice does not pass because one unit routes around one obstacle.

## 16. Debugging tools

Recommended temporary, code-native tools:

- Global path polyline.
- Current waypoint and waypoint index.
- Requested destination and resolved valid destination.
- Route corridor or visited cells when explicitly enabled.
- Navigation state: idle, querying, following, waiting, recovering, failed.
- Stuck progress window/timer.
- Replan count and last reason.
- Topology revision used by the route.
- Invalid/unreachable destination marker.
- Grid, blocked-cell, and clearance overlay.
- Per-unit footprint circle/box.
- Chokepoint priority/holding-point marker when that slice begins.

Defaults should avoid clutter. Show per-unit details for selected units and allow a global grid overlay. Colors must remain non-canon and distinct from selection, health, target, and hit indicators.

Do not design final UI, minimaps, animation, particles, sound, or faction colors.

## 17. Automated and manual testing

### Native headless checks

Extend the existing runner in small approved increments for:

- Path exists/does not exist on fixed occupancy fixtures.
- Start and end cell validity/projection.
- Known route-cost comparison.
- Diagonal corner-cut prevention.
- Footprint-clearance acceptance/rejection.
- Deterministic nearest-valid destination selection.
- Footprint-safe waypoint simplification.
- Stuck-state threshold transitions using explicit progress samples.
- Replan-trigger decisions and reason priority.
- Topology revision invalidation.
- Alternate-destination ordering.

Avoid real-time physics waits for pure routing/state checks.

### Manual Godot observation

Still required:

- Visual route quality and obstacle clearance.
- Local separation inside route corridors.
- Group congestion, queueing, and yielding.
- Narrow/wide chokepoint choice.
- Jitter and oscillation.
- Crossing traffic.
- Moving-target combat approach.
- Command responsiveness and failure feedback.
- Small, typical, and stress-tier frame behavior.

## 18. Implementation staging

Every slice is separately approval-gated.

### Slice 1 — Arena and one-unit static routing

Scope:

- Geometric arena containing the static single-unit fixtures.
- One approved grid scale and one provisional footprint.
- Map-owned `AStarGrid2D` route query.
- One unit follows static waypoints to a ground destination.
- Selected-unit path/destination debug drawing.

Exclusions:

- Groups, combat approach, dynamic buildings, local avoidance changes, stuck recovery, economy.

Acceptance:

- All known reachable single-unit routes complete without clipping.
- Short versus long routes choose the expected reasonable route.
- Narrow route accepts/rejects the approved footprint correctly.

Automated:

- Connectivity, cost, corner cutting, footprint clearance, deterministic path.

Manual:

- Path appearance, waypoint following, turns, stopping, command replacement.

Approval gate:

- Technology, grid/cell scale, diagonal rule, first footprint, arena layout, debug visuals.

### Slice 2 — Destination validity and unreachable handling

Scope:

- World/cell validity, bounded nearest-valid projection, disconnected-goal failure, explicit route status.

Exclusions:

- Combat, group queues, dynamic construction.

Acceptance:

- Outside, blocked, enclosed, and too-narrow destinations resolve or fail by documented rules without stale movement.

Automated:

- Projection ordering/radius, connectivity, failure reasons, cleanup transitions.

Manual:

- Adjusted-goal and failure markers; command responsiveness.

Approval gate:

- Projection radius, partial group failure presentation, retry/failure policy.

### Slice 3 — Waypoint quality and safe simplification

Scope:

- Footprint-safe waypoint simplification, route-stability comparison, corridor deviation bounds.

Exclusions:

- Congestion costs, formations, flow fields.

Acceptance:

- Fewer needless turns without obstacle clipping or materially worse routes.

Automated:

- Simplification fixtures, route length, footprint sweep, deterministic output.

Manual:

- Visual plausibility, corner clearance, replan stability.

Approval gate:

- Simplification algorithm and route-quality tolerances.

### Slice 4 — Combat approach through navigation

Scope:

- Route explicit attackers to reachable firing-slot candidates around static obstacles.
- Preserve target replacement, death, cooldown, and moving-target thresholds.

Exclusions:

- Automatic targeting, predictive interception, line-of-fire combat obstacles.

Acceptance:

- Target behind a wall is approached through a valid route; unreachable targets fail predictably; no direct obstacle crossing.

Automated:

- Candidate validity/order, reachable slot choice, target-state route cleanup.

Manual:

- Moving targets, range entry/loss, cooldown reset, multi-radius slots.

Approval gate:

- Firing candidate search, unreachable-target policy, route refresh threshold.

### Slice 5 — Group destinations and chokepoints

Scope:

- Deterministic distinct final destinations.
- Individual routes.
- Chokepoint holding points, priority, queueing, and yielding.

Exclusions:

- Persistent formations, tactical encirclement, flow fields.

Acceptance:

- Small and typical groups complete narrow/wide passages without permanent deadlock or complete stacking.

Automated:

- Destination assignment, deterministic priority, holding-point validity.

Manual:

- Mixed speeds, crossing traffic, route-width use, chokepoint completion.

Approval gate:

- Destination pattern, priority/yield rule, narrow-versus-wide route cost.

### Slice 6 — Stuck detection and recovery

Scope:

- Progress measurements, recovery escalation, bounded attempts, visible failure reason.

Exclusions:

- Teleportation, random nudges, global tactical AI.

Acceptance:

- Every stuck fixture recovers or fails explicitly within the approved budget; no indefinite oscillation.

Automated:

- Progress windows, state transitions, escalation order, attempt limits.

Manual:

- Temporary congestion, dead ends, route changes, player readability.

Approval gate:

- Time/progress thresholds, retry counts, alternate-goal radius, final failure behavior.

### Slice 7 — Dynamic building/topology updates

Scope:

- Bounded occupancy updates, topology revisions, route invalidation after placement/destruction fixtures.

Exclusions:

- Actual construction/economy, arbitrary moving hard obstacles.

Acceptance:

- Affected routes replan; unaffected routes remain stable; destroyed blockers reopen routes.

Automated:

- Cell updates, revision tracking, impacted-route detection.

Manual:

- Mid-route blocking/reopening and recovery.

Approval gate:

- Building-grid alignment, update timing, synchronization and route invalidation policy.

### Slice 8 — Representative-count quality and performance review

Scope:

- Small, typical, and stress tiers; query/replan instrumentation; measured optimization candidates.

Exclusions:

- Quality-reducing shortcuts, premature flow fields, final population cap.

Acceptance:

- Correctness/recovery metrics remain satisfied; performance data identifies real bottlenecks; any optimization preserves route quality.

Automated:

- Repeatable query batches and deterministic results.

Manual:

- Group behavior and responsiveness at all tiers.

Approval gate:

- Test arrangements, acceptable latency/frame budgets, and any proposed caching/shared-path/flow-field optimization.

## 19. Approval decisions

Before Slice 1:

1. `AStarGrid2D` clearance-aware grid versus a Godot navigation-mesh architecture.
2. Provisional spatial and navigation-cell scale.
3. Square/eight-direction representation and diagonal corner rule.
4. First conservative unit footprint and clearance interpretation.
5. One initial clearance class versus more than one.
6. Arena size, fixtures, and whether it is a separate directly run scene.
7. Selected-path, waypoint, destination, state, and grid debug visuals.
8. Small/typical/stress technical test tiers.

Before later slices:

9. Global static/building obstacles versus local unit-congestion responsibilities.
10. Destination projection radius and unreachable-command behavior.
11. Waypoint simplification and route-quality thresholds.
12. Combat firing-position candidate search and target retry policy.
13. Group final-destination distribution.
14. Chokepoint priority, queueing, and yielding.
15. Replan triggers, priority, and optional safety refresh.
16. Stuck thresholds, recovery attempts, alternate-goal policy, and failure feedback.
17. Building placement/destruction update timing.
18. Whether measured performance justifies path caching, shared corridors, or flow fields.

Approval of the architecture does not approve final movement classes, unit caps, buildings, economy, combat line-of-fire rules, formations, AI, or optimization infrastructure.

## 20. Final recommendation

### Recommended architecture

Use a map-owned, clearance-aware uniform grid backed initially by `AStarGrid2D` for global path queries. Units follow deterministic waypoints with existing definition-driven `CharacterBody2D` movement. Existing friendly separation remains bounded local steering. Add explicit route status, progress, replan reasons, recovery escalation, and debug visualization slice by slice.

### Why it supports high-quality behavior

- Modest counts allow individual, footprint-aware routes and bounded recovery work.
- Explicit cells and clearance make failures reproducible and debuggable.
- Buildings and narrow passages have predictable occupancy semantics.
- Global correctness remains separate from local congestion handling.
- Deterministic route and recovery fixtures fit the native headless runner.
- Optimization can later reuse paths or corridors without replacing the correctness baseline.

### Immediate risks

- A poor cell scale can harm clearance or route appearance.
- Raw grid paths need safe simplification.
- Local separation can conflict with narrow corridors unless bounded.
- `TestUnit` must not absorb all routing, recovery, debug, and topology responsibilities.
- Group queueing is a separate behavior problem even after routes are valid.
- Static route correctness does not guarantee dynamic congestion quality.

### Do not build yet

- Custom A* before native limitations are measured.
- Flow fields, shared-path caches, or hierarchical routing.
- Full formations or tactical encirclement.
- Navigation-driven combat AI or automatic acquisition.
- Final movement/terrain classes.
- Dynamic building production or economy.
- RVO as the correctness mechanism.
- Managers, autoloads, registries, service locators, event buses, addons, or dependencies.

### Exact first implementation slice

Implement **Navigation Slice 1 only** after its approvals:

- Create a separate geometric navigation arena.
- Add one map-owned `AStarGrid2D` representation using one approved cell scale and footprint.
- Mark static fixture cells and prevent diagonal corner cutting.
- Query a route for one selected generic unit on a ground command.
- Follow waypoints with existing speed, physics step, stopping, and map clamping.
- Draw the selected unit's path, current waypoint, and resolved destination.
- Add headless connectivity, path-cost, clearance, and corner-rule checks.
- Do not add groups, combat routing, dynamic obstacles, stuck recovery, economy, or navigation optimization.

### Navigation-foundation exit criteria

The foundation is ready for economy work only when:

- Known reachable destinations succeed and known unreachable destinations fail explicitly.
- Approved footprint classes never clip static obstacles.
- Routes meet approved quality bounds.
- Combat targets behind obstacles use reachable firing routes.
- Small and typical groups complete chokepoints without permanent deadlock.
- Stuck units recover or fail within bounded policy.
- Building topology fixtures invalidate/reopen routes correctly.
- Debug information explains route and failure state.
- Native deterministic checks and the full manual regression suite pass.
- Stress-tier measurements identify no correctness failures; optimization remains evidence-driven.
