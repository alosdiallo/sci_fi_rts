# Game Design

## Document purpose

This document separates approved constraints from ideas that still require design work. It is a direction-setting brief, not evidence that any listed system has been implemented.

## Confirmed decisions

### Product and presentation

- The game is a classic 2D pixel-art science-fiction RTS built with Godot.
- Late-1990s RTS games, especially *Dune 2000*, are mechanical references. This is inspiration, not a commitment to copy their setting, content, interface, or exact rules.
- Development is single-player first.
- The first version excludes multiplayer, a procedural campaign, advanced physics, and 3D graphics.

### Core game structure

- There will be two asymmetric playable factions.
- The intended full loop includes base construction, resource gathering, unit production, and combat.
- Campaign content will use scripted missions.
- Unit counts on screen should remain limited.
- Combat should be simple and deterministic.
- Physics should be minimal and used only where it serves clear gameplay needs.
- Approximately 40 total units and buildings is a long-term ceiling across the project, not the scope of the first prototype.

### Technical direction

- Unit and building definitions should be modular and data-driven.
- Runtime behavior, presentation, and authored balance data should be separated where practical.
- Early work should favor small, testable systems over broad content production.

## Provisional ideas

These ideas describe the current creative direction but are not settled canon or finalized mechanics:

- A planetary invasion provides the large-scale conflict.
- The world is dying, lightless, or both.
- Fortified settlements act as important population centers or defensive anchors.
- Invaders field powerful walkers.
- A hostile neutral biosphere threatens or complicates both playable sides.
- Faction asymmetry may emerge through different relationships to fortification, mobility, walkers, resources, or the biosphere.

Do not infer names, histories, motives, visual identities, technologies, mission plots, or exact faction roles from these ideas.

## Design principles

- **Readable over crowded:** a limited battlefield population should make units, threats, and commands easy to understand.
- **Deterministic over simulation-heavy:** outcomes should be explainable and reproducible from game state.
- **Asymmetry with clarity:** factions may solve problems differently, but their rules must remain legible to the player.
- **Data over duplication:** shared code should consume authored unit and building definitions rather than embedding per-entity balance values.
- **Prototype before breadth:** validate interaction and control fundamentals before expanding factions, economies, combat, or content.

## Initial milestone boundary

The first milestone contains only:

- Camera movement.
- A test map.
- Unit selection.
- Basic movement.

It does not include combat, enemies, resources, construction, production, faction asymmetry, campaign scripting, final art, or a complete user interface.

## Unresolved questions

### Setting and narrative

- What is the world, and why is it dying or lightless?
- Who is invading, who is defending, and are those roles identical to the two playable factions?
- What are the fortified settlements protecting?
- What is the neutral biosphere, and why is it hostile?
- How do the confirmed setting ingredients relate without becoming derivative of existing fiction?

### Systems

- What resource model supports the desired pacing?
- How are buildings placed and construction authorized?
- What are the factions' central mechanical differences?
- What population or production limits keep battlefield counts controlled?
- How do neutral hazards interact with units, buildings, and mission objectives?
- What deterministic rules govern targeting, damage, range, movement conflicts, and pathfinding?

### Presentation and campaign

- What pixel resolution, tile scale, camera limits, and target display sizes should be used?
- What input platforms are in scope beyond keyboard and mouse, if any?
- What is the campaign structure, mission count, and progression model?
- What accessibility and difficulty options are required?

Resolve these questions explicitly before treating their answers as project requirements.
