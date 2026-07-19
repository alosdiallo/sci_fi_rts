# Changelog

Notable changes to this project will be documented here. Dates use `YYYY-MM-DD`.

## Unreleased

### Added

- Project overview and accurate pre-production status in `README.md`.
- Game design brief separating confirmed decisions, provisional ideas, and unresolved questions.
- Staged roadmap beginning with the camera, test map, selection, and movement prototype.
- Concise session handoff and repository-wide agent instructions.
- Proposed Milestone 1 implementation plan, including approval gates and verification criteria.
- First Milestone 1 technical slice: a bounded 2048 × 2048 test map and keyboard-controlled, boundary-clamped camera.
- Second Milestone 1 technical slice: four geometric placeholder units with click selection, drag-box selection, selection indicators, and empty-ground deselection.
- Final Milestone 1 technical slice: right-click commands, map-clamped destinations, command replacement, and direct frame-rate-independent placeholder-unit movement.
- First Milestone 2 technical slice: a typed `UnitDefinition` Resource and two neutral `.tres` definitions driving placeholder movement values.
- Combat Prototype Slice 1: authored maximum health, per-instance damageable state, conditional health bars, and safe unit death cleanup.
- Combat Prototype Slice 2: prototype team IDs, contextual hostile-target commands, per-unit target state, and temporary geometric target feedback.
- Combat Prototype Slice 3: validated attack damage, range, and cooldown data with deterministic no-pursuit instant-hit attacks and temporary hit outlines.
- Approach and Spacing Slice 1: direct approach toward explicitly targeted stationary hostiles, stopping at an 8-pixel firing-range margin before existing cooldown-based attacks.
- Approach and Spacing Slice 2: thresholded moving-target destination refresh and collision-footprint-aware map clamping for ground and approach movement.
- Approach and Spacing Slice 3: capped deterministic friendly-unit separation during commanded movement, attack approach, and severe idle overlap.

### Changed

- Replaced the temporary README placeholder with useful project documentation.
- Approved **Red Dust, Cold Iron** as the working title.
- Confirmed that all version-one playable missions take place on Mars.
- Confirmed the **Free Settlements of Mars** as the Martian political coalition and the Earth–Moon expeditionary opposition.
- Set `scenes/main/milestone_1.tscn` as the main scene and added WASD and arrow-key camera input actions.
- Replaced placeholder-unit movement constants with validated, per-instance definition assignments while preserving Milestone 1 behavior.
- Confirmed the Free Settlements Army and opposing Earth–Moon expeditionary Marines, including their home-territory versus adaptable expeditionary doctrines.
- Established the initial straightforward unit direction around infantry squads, Mars-capable buggies and rovers, drones, engineering, and logistics; removed walkers from version-one direction and left atmospheric hovercraft unapproved.
- Added the provisional economy direction of regolith/feedstock and water ice/volatiles as spendable resources, constructed command capacity as an army-size limit, and visible physical gathering.
- Added validated `max_health` unit data and a temporary debugger-callable damage hook for health and death verification without attack controls.
- Renamed the movement controller as a contextual unit-command controller while preserving ground movement and adding non-attacking hostile-target assignment.
- Removed the temporary manual-damage hook after explicit target commands became capable of exercising health and death.
