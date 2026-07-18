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

### Changed

- Replaced the temporary README placeholder with useful project documentation.
- Approved **Red Dust, Cold Iron** as the working title.
- Confirmed that all version-one playable missions take place on Mars.
- Confirmed the **Free Settlements of Mars** as the Martian faction and the central contrast of entrenched local mass production against a smaller, elite Earth–Lunar expeditionary force; the expeditionary faction's finalized name remains unresolved.
- Set `scenes/main/milestone_1.tscn` as the main scene and added WASD and arrow-key camera input actions.
- Replaced placeholder-unit movement constants with validated, per-instance definition assignments while preserving Milestone 1 behavior.
