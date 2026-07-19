# Repository Instructions for Coding Agents

These instructions apply to the entire repository unless a more specific `AGENTS.md` exists in a subdirectory.

## Start here

Before making changes, read:

1. `README.md`
2. `GAME_DESIGN.md`
3. `ROADMAP.md`
4. `DEVELOPMENT_PLAN.md`
5. `HANDOFF.md`
6. `CHANGELOG.md`

Inspect the repository and current working tree before editing. Existing user changes must be preserved.

## Project boundaries

- This is a Godot project for a classic 2D pixel-art science-fiction RTS.
- Treat only material labeled confirmed as decided.
- Treat provisional ideas as candidates, not requirements or canon.
- Do not silently answer unresolved questions or invent setting details, faction identities, lore, plot, names, or visual canon.
- Do not claim planned or partially built features are implemented.
- Keep the first implementation milestone limited to camera movement, a test map, unit selection, and basic movement unless the user expands its scope.
- The approximately 40-unit/building figure is a long-term ceiling, never an initial content target.
- Multiplayer, procedural campaigns, advanced physics, and 3D graphics are outside the first-version scope.

## Architecture expectations

- Use modular, data-driven definitions for units and buildings.
- Keep authored definition data separate from runtime state and scene presentation where practical.
- Prefer composition and small focused systems over deep inheritance or monolithic managers.
- Keep simulation rules simple, explicit, and deterministic. Avoid frame-rate-dependent gameplay outcomes.
- Use minimal physics; do not introduce physics-heavy solutions where direct game logic is sufficient.
- Avoid premature systems and abstractions that are not required by the current milestone.

## Change discipline

- Match work to the active milestone and the user's request.
- Keep `DEVELOPMENT_PLAN.md` accurate when milestone status, dependencies, approval gates, or implementation sequencing changes.
- Before making unrelated or scope-expanding changes, show the proposed changes and obtain approval.
- Do not add third-party dependencies, addons, or generated assets without explicit approval.
- Do not edit `project.godot` unless the user explicitly authorizes it.
- Do not overwrite user-authored assets or unrelated working-tree changes.
- Keep scenes, scripts, resources, and data files narrowly scoped and clearly named.
- Update documentation when an approved decision, milestone, workflow, or architecture changes.
- Add a concise entry to `CHANGELOG.md` for meaningful repository changes.

## Godot practices

- Favor typed GDScript when gameplay coding begins.
- Avoid hard-coded absolute paths and machine-specific settings.
- Treat warnings and parser errors as issues to resolve, not expected output.
- Keep reusable gameplay data in Godot resources or another approved declarative format; do not hard-code complete rosters in control scripts.
- Document input actions and project-setting changes before requesting authorization to modify `project.godot`.

## Verification and handoff

- Verify changes in proportion to their scope. For code, run the smallest relevant Godot checks or tests available in the repository.
- Report what changed, what was verified, and what remains unimplemented.
- Clearly call out any assumption made because a requirement was unresolved.
- Leave the repository in a state that a new agent can understand from the root documentation.
