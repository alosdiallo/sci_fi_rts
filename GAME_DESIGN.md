# Game Design

## Document purpose

This document is the current design source of truth for the project.

It separates:

- Confirmed decisions that should guide development.
- Provisional ideas that remain subject to revision.
- Unresolved questions that require explicit decisions.

Planned systems must not be described as implemented unless they exist in the repository and have been verified.

---

# Project Summary

## Working title

**Red Dust, Cold Iron**

The title is provisional and may change.

## High-level concept

A classic 2D pixel-art real-time strategy game set during a war for control of Mars.

By the twenty-third century, the Martian colonies have developed into permanent settlements with their own industries, institutions, and political identity. After decades of supplying water, fuel, and industrial resources to the inner solar system, the colonies declare independence as **The Free Settlements of Mars**.

Earth and its lunar industrial authorities refuse to recognize the declaration. An elite expeditionary force is deployed from the Earth–Moon system to restore control over Martian extraction infrastructure and interplanetary supply routes.

The Free Settlements defend Mars through entrenched local industry, mass-produced autonomous vehicles, artillery, and extensive knowledge of the terrain. The expeditionary force relies on orbital deployment, advanced sensors, precision weapons, and a small number of powerful armored walkers.

All playable missions in the first version take place on Mars.

---

# Confirmed Decisions

## Product and presentation

- The game is a classic 2D pixel-art science-fiction RTS.
- Godot is the game engine.
- Late-1990s RTS games, particularly *Dune 2000*, are mechanical and presentation references.
- The game will be designed primarily for keyboard and mouse.
- Development is single-player first.
- The first version will include two asymmetric playable factions.
- Battlefield populations will remain deliberately limited.
- Combat will favor clear, deterministic rules over complex physical simulation.
- Physics will be minimal and used only where it clearly improves gameplay.
- Approximately 40 total units and buildings is a long-term ceiling, not an initial target.

## Version-one location

- All playable missions take place on Mars.
- Earth, the Moon, orbital shipyards, and interplanetary infrastructure may appear in lore, communications, briefings, and strategic context.
- The first version will not contain playable Earth, Moon, space, or orbital-combat maps.
- The game will not include an interplanetary strategy layer in its first version.

## Political setting

- Mars contains mature, permanent human settlements rather than temporary scientific outposts.
- The Martian colonies have declared independence from Earth-aligned authorities.
- The independent Martian political coalition is called **The Free Settlements of Mars**.
- The Free Settlements originated as separate colonies and retain a decentralized or confederated political identity.
- Earth and the Moon remain important to the conflict as centers of population, industry, shipbuilding, and military logistics.
- The war is fought partly over Martian water, fuel production, industrial resources, and control of interplanetary supply routes.

## Intended core game loop

The intended mature game loop includes:

1. Establishing and expanding a base.
2. Locating and securing strategic resources.
3. Producing units and constructing defenses.
4. Contesting territory and infrastructure.
5. Managing power, extraction, and production.
6. Fighting enemy forces through faction-specific doctrines.
7. Completing scripted campaign objectives.

These systems are planned and should not be described as implemented until they exist.

## Technical direction

- Unit and building definitions should be modular and data-driven.
- Authored balance data should remain separate from runtime behavior where practical.
- Shared behaviors should be reused rather than duplicated for individual units.
- Runtime state, simulation rules, presentation, and authored content should remain separated where practical.
- Early development should favor small, testable systems.
- Frame-rate-dependent gameplay outcomes should be avoided.
- The project should not add unnecessary third-party dependencies.

---

# Setting

## Mars in the twenty-third century

Mars is no longer a distant frontier. Its buried settlements, industrial districts, water-extraction fields, and regolith foundries support a large population born away from Earth.

Martian civilization depends on local resource utilization. Water ice supports human survival, oxygen generation, agriculture, industrial processes, and propellant production. Regolith and trace minerals provide feedstock for construction and manufacturing.

The same infrastructure that makes settlement possible also makes Mars strategically indispensable.

## The independence crisis

The Free Settlements formed after growing conflict over extraction mandates, political representation, resource ownership, and control of Martian infrastructure.

The precise sequence of events leading to war remains unresolved, but the conflict should involve a credible escalation such as:

1. Increasing Earth-directed extraction requirements.
2. Martian resistance or export restrictions.
3. A declaration of sovereignty.
4. Economic sanctions or an orbital blockade.
5. Seizure of strategically important installations.
6. Deployment of an Earth–Lunar expeditionary force.
7. Open planetary warfare.

The conflict should not initially present either faction as unambiguously heroic or villainous.

## Strategic resources

Water is central to the setting because it supports:

- Life support.
- Agriculture.
- Oxygen production.
- Hydrogen production.
- Methane-based propellant.
- Industrial cooling and processing.
- Control of interplanetary transportation.

Regolith and mineral deposits support:

- Additive manufacturing.
- Fortification construction.
- Vehicle replacement.
- Ammunition production.
- Repair and maintenance.

The exact in-game resource system remains unresolved.

---

# Playable Factions

## The Free Settlements of Mars

### Identity

The Free Settlements are a confederation of established Martian communities defending their independence, infrastructure, and continued survival.

They possess local manufacturing capacity, established settlements, detailed terrain knowledge, and equipment designed specifically for Martian conditions.

Their forces should communicate the idea:

> We live here. We can outlast you.

### Current mechanical direction

The Free Settlements are provisionally envisioned as the more industrial and territorially entrenched faction.

Possible characteristics include:

- Rugged, inexpensive autonomous vehicles.
- Large numbers of replaceable ground units.
- Strong artillery.
- Durable fortifications.
- Distributed production facilities.
- Efficient repair and reconstruction.
- Strong performance during prolonged environmental disruption.
- Dependence on territorial control and industrial momentum.

They should not merely be the faction with weaker units. Their advantages should come from production, redundancy, range, fortification, and their ability to sustain prolonged warfare.

### Political character

The Free Settlements should not necessarily behave as a perfectly unified state.

Possible internal tensions include:

- Settlement autonomy versus central military authority.
- Older Earth-founded colonies versus newer Martian communities.
- Civilian leadership versus military command.
- Moderate independence advocates versus uncompromising separatists.
- Resource-rich settlements versus vulnerable dependent settlements.

These tensions are provisional and require narrative development.

---

## Earth–Lunar Expeditionary Force

### Naming status

The opposing faction does not yet have a finalized political or military name.

**Artemis Expeditionary Command** is a provisional working name for its deployed military force.

### Identity

The expeditionary force is deployed from the Earth–Moon system to regain control of Martian infrastructure and restore access to strategically important resources and supply routes.

Its forces are technologically advanced but expensive to transport, maintain, and replace.

Their doctrine should communicate the idea:

> We cannot match your numbers, so every unit must dominate its battlefield role.

### Current mechanical direction

The expeditionary faction is provisionally envisioned as the smaller, more mobile, technologically advanced force.

Possible characteristics include:

- Heavily armored walkers.
- Orbital deployment or reinforcement.
- Superior sensors and battlefield awareness.
- Precision weapons.
- Area-denial and anti-swarm systems.
- Mobile or relocatable infrastructure.
- Modular unit configurations.
- High individual unit value.
- Greater dependence on limited landing zones, supply windows, or specialized support.

Its weaknesses may include:

- High replacement costs.
- Long production or reinforcement times.
- Limited battlefield population.
- Dependence on specialized units.
- Vulnerability when isolated from support infrastructure.

The faction should not simply possess universally superior units. Its power should be balanced by scarcity, logistical dependence, and the consequences of losing expensive assets.

---

# Faction Asymmetry

The central faction contrast is currently:

| Free Settlements of Mars | Earth–Lunar Expeditionary Force |
|---|---|
| Local and established | Distant and expeditionary |
| Industrial volume | Concentrated technological superiority |
| Entrenched territorial control | Mobility and rapid deployment |
| Replaceable autonomous units | Expensive specialized units |
| Artillery and fortification | Walkers and precision weapons |
| Distributed production | Limited high-value infrastructure |
| Wins through endurance | Wins through maneuver and force concentration |

This is an approved direction, but exact faction mechanics remain provisional until tested.

Both factions should use compatible underlying RTS systems where practical. Their presentation and strategic behavior may differ substantially without requiring two entirely separate game engines.

---

# The Martian Environment

Mars functions as a hostile neutral force but not as a conventional playable faction.

## Environmental threats

Potential environmental systems include:

- Dust storms that reduce vision or sensor range.
- Temporary disruption of solar power.
- Extreme cold affecting exposed or damaged infrastructure.
- Radiation zones.
- Unstable terrain.
- Deep canyons and crater walls that constrain movement.
- Limited safe construction areas.
- Vulnerable infrastructure connecting distant extraction sites.
- Reduced visibility across dust-heavy terrain.

Environmental mechanics should remain readable and predictable enough for strategic planning.

Random events should not arbitrarily decide battles.

## Map environments

Potential Martian map types include:

- Polar ice fields.
- Exposed glacial deposits.
- Crater settlements.
- Open regolith plains.
- Canyon systems.
- Buried industrial complexes.
- Water-extraction fields.
- Solar and reactor installations.
- Abandoned colonies.
- Orbital landing zones.
- Fuel-processing facilities.
- Damaged transportation corridors.

All environments should reuse a coherent Martian asset library rather than requiring unrelated visual pipelines.

---

# Resources and Economy

The economy is not yet finalized.

## Confirmed principles

- Resource control should force players to expand beyond their initial base.
- Valuable extraction infrastructure should create exposed and contested territory.
- Economy mechanics should reinforce the setting rather than use unexplained generic resources.
- The resource system should remain understandable and manageable.
- The first playable prototype will not implement the full economy.

## Provisional resource model

A possible economy could use two principal resource categories:

### Water and volatiles

Used for:

- Power or fuel production.
- Advanced units.
- Reinforcements.
- Life-support-related infrastructure.
- Strategic progression.

### Regolith and industrial feedstock

Used for:

- Buildings.
- Fortifications.
- Basic vehicles.
- Repairs.
- Ammunition or replacement components.

A simpler single-resource model may be preferable if two resources do not meaningfully improve gameplay.

---

# Combat

## Confirmed principles

- Combat should be deterministic and explainable.
- Unit roles should be visually and mechanically readable.
- Damage should not depend on advanced rigid-body physics.
- Limited battlefield populations should make positioning and target selection meaningful.
- Units should not require excessive micromanagement to perform basic roles.

## Provisional systems

Potential combat systems include:

- Armor and damage classes.
- Clearly defined range.
- Deterministic accuracy or fixed-hit weapons.
- Area-of-effect weapons.
- Suppression or temporary disabling effects.
- Line-of-sight and sensor range.
- Terrain-based firing advantages.
- Artillery minimum ranges.
- Specialized anti-infantry, anti-vehicle, and anti-structure weapons.

Exact targeting, damage, accuracy, and armor rules remain unresolved.

---

# Units and Buildings

## Content ceiling

Approximately 40 total units and buildings across both factions is a long-term ceiling.

This figure includes both units and structures and should not be interpreted as:

- A minimum target.
- A Milestone 1 requirement.
- A vertical-slice requirement.
- Forty units per faction.

The final game may contain fewer entities if a smaller roster produces clearer and more distinctive gameplay.

## Development principle

New units should primarily be defined through reusable data and shared behaviors, including:

- Health.
- Movement speed.
- Movement class.
- Armor type.
- Weapon type.
- Damage.
- Range.
- Reload time.
- Cost.
- Production time.
- Technology requirements.
- Sensor range.
- Sprite and audio references.
- Approved special behaviors.

Unique code should be reserved for genuinely unique mechanics.

---

# Campaign

## Confirmed direction

- The game will be single-player first.
- Campaign missions will be scripted.
- All version-one missions will take place on Mars.
- Off-world events may be communicated through briefings, dialogue, reports, or transmissions.
- The narrative may present perspectives from both playable factions.

## Provisional structure

A possible campaign progression is:

### Act I: The Crisis

- Resource disputes escalate.
- Martian settlements organize their defense.
- Earth–Lunar forces establish their first landing zones.
- Both factions treat the conflict as limited and temporary.

### Act II: The Planetary War

- Infrastructure becomes a primary target.
- Neutral settlements are forced to choose sides.
- The conflict expands across major extraction and industrial regions.
- Both factions adapt their doctrines to sustained warfare.

### Act III: Fracture

- Internal political divisions become more visible.
- The true economic or political motives behind the intervention emerge.
- Both factions face consequences from prolonged resource extraction and environmental damage.

### Act IV: Decision

- The player confronts the strategic and political consequences of the war.
- The resolution determines the future status of Mars and its relationship with Earth.

The campaign structure, mission count, protagonist characters, and ending remain unresolved.

---

# Narrative Principles

- Neither playable faction should be entirely heroic or villainous.
- Martian independence should have legitimate political and survival-based motivations.
- Earth–Lunar dependence on Martian resources should also have credible consequences.
- Characters should have motives beyond faction loyalty.
- The conflict should involve civilians, infrastructure, logistics, and political pressure—not only military conquest.
- Present-day national identities may influence the historical background, but the twenty-third-century factions should have developed identities of their own.
- The story should avoid relying on contemporary geopolitical stereotypes.
- Scientific and logistical details should support the story without overwhelming it.

---

# Visual Direction

## Confirmed direction

- 2D pixel art.
- A top-down or slightly angled RTS battlefield presentation.
- Clear silhouettes and readable unit roles.
- Limited visual clutter.
- Mars should have a coherent environmental identity across the campaign.

## Provisional visual contrast

### Free Settlements

Possible visual qualities:

- Rugged.
- Modular.
- Industrial.
- Repaired and adapted.
- Low-profile vehicles.
- Buried or reinforced structures.
- Exposed conduits, fabrication systems, and local materials.

### Expeditionary force

Possible visual qualities:

- Tall silhouettes.
- Armored walkers.
- Standardized military design.
- Advanced sensors.
- Precision construction.
- Orbital or aerospace influence.
- More compact but higher-value infrastructure.

Faction colors, palettes, sprite dimensions, tile scale, animation frame counts, and camera resolution remain unresolved.

---

# Version-One Scope

## Included direction

The intended first version may eventually contain:

- Two playable factions.
- A scripted single-player campaign.
- Base construction.
- Resource gathering.
- Unit production.
- Deterministic combat.
- Limited battlefield populations.
- Martian environmental hazards.
- A restrained roster of units and structures.
- Mission briefings and narrative communications.

## Explicitly excluded

The first version will not include:

- Multiplayer.
- Procedural campaign generation.
- Playable Earth maps.
- Playable Moon maps.
- Space combat.
- Orbital combat maps.
- An interplanetary grand-strategy layer.
- Multiple playable planets.
- Zero-gravity gameplay.
- Advanced physics simulation.
- Fully destructible terrain.
- 3D graphics.
- Console releases.
- Mobile releases.
- A large public modding framework.

These exclusions may be reconsidered only after the first version is complete.

---

# Initial Milestone Boundary

Milestone 1 contains only:

- Camera movement.
- A bounded test map.
- Unit selection.
- Basic unit movement.

Milestone 1 does not include:

- Combat.
- Enemies.
- Resources.
- Construction.
- Production.
- Final faction mechanics.
- Campaign scripting.
- Environmental hazards.
- Final artwork.
- A complete interface.

---

# Unresolved Questions

## World and politics

- What exact event triggers the Martian declaration of independence?
- Who governs the Earth–Moon system?
- What is the finalized name of the expeditionary faction?
- Are all Martian settlements members of the Free Settlements?
- Are any settlements neutral or loyal to Earth?
- How centralized is the Free Settlements government?
- What political event turns the crisis into open war?
- How dependent is Earth on Martian resources?

## Economy

- Will the game use one resource or multiple resources?
- Is water collected directly, processed, or transported?
- How is regolith converted into usable construction material?
- Is electrical power a strategic system?
- Are supply lines simulated directly or represented abstractly?
- How vulnerable should remote extraction sites be?

## Factions

- What is each faction's defining mechanic?
- How are expeditionary reinforcements produced or delivered?
- How does Free Settlements manufacturing differ from conventional production?
- What population limits apply to each faction?
- How replaceable should expeditionary walkers be?
- How should artillery be balanced against mobility?

## Combat and movement

- What movement grid or navigation system will be used?
- How will groups move around buildings and narrow terrain?
- Will attacks use fixed accuracy, deterministic hit rules, or controlled variance?
- What armor and damage classes are needed?
- How should area-of-effect attacks avoid becoming overwhelming?
- Will units use directional sprites, turret rotation, or both?

## Campaign

- Will the player complete one campaign per faction or one combined narrative?
- How many missions are realistic for the first version?
- Will missions use named commanders or a less personalized strategic perspective?
- Will the ending branch?
- How much political choice should the player have?
- What role do civilian settlements play?

## Presentation

- What internal pixel resolution will be used?
- What tile dimensions will be used?
- Will the battlefield be orthographic top-down or use an isometric-like angle?
- How many directional frames are needed for vehicles and walkers?
- What interface layout best supports the intended battlefield population?
- What accessibility options are required?

Answers to these questions must be approved before they become binding project requirements.
