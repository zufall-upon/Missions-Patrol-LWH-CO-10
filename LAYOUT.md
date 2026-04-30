# KFH_Patrol_LWH_co10 Layout

This is the concrete Eden layout plan for `KFH_Patrol_LWH_co10`.

Assumptions:

- 10-player PvE target
- Vanilla-first assets
- `@CBA_A3` is an allowed required dependency
- Altis is used as the first practical staging map

## Intent

The route should feel like a push into a contaminated industrial cut or quarry approach, not an open-field patrol.

What we want to test:

- whether 10 players can move as one stack without the route becoming trivial
- whether 3-4 player split pushes are occasionally useful
- whether reinforcement pressure makes turtling feel dangerous
- whether returning to extraction feels earned instead of like cleanup

## Route Shape

Use a bent lane, not a straight line.

Top-down intent:

```text
Extract / Start FOB
    |
    |  safe fallback lane
    |
CP1 --- first pinch / first defendable pocket
    \
     \ flank approach / split temptation
      \
      CP2 --- wider basin / strongest split opportunity
         \
          \
          CP3 --- final hardpoint / last secure point
```

## Concrete Marker Layout

The included `mission.sqm` draft uses this rough coordinate set on Altis:

- `respawn_west`: `14518, 16672`
- `kfh_start`: `14525, 16695`
- `kfh_cp_1`: `14595, 16820`
- `kfh_cp_2`: `14685, 16965`
- `kfh_cp_3`: `14800, 17120`
- `kfh_extract`: `14508, 16640`

Recommended spawn flank markers:

- `kfh_spawn_1_1`: left of CP1, 35-45 m offset
- `kfh_spawn_1_2`: right of CP1, 35-45 m offset
- `kfh_spawn_2_1`: left high angle on CP2, 40-60 m offset
- `kfh_spawn_2_2`: right long angle on CP2, 45-65 m offset
- `kfh_spawn_3_1`: forward-left on CP3, 35-50 m offset
- `kfh_spawn_3_2`: forward-right on CP3, 35-50 m offset
- `kfh_spawn_extract_1`: rear pursuit lane, 60-80 m from extract
- `kfh_spawn_extract_2`: side pursuit lane, 60-80 m from extract

## Recommended Eden Composition

### Start / Extract FOB

Place:

- 10 BLUFOR playable slots in 2 nearby groups of 5
- 1 ammo source
- 1 medical source
- 1 repair or toolkit point
- waist-high cover in a shallow arc facing CP1

Vanilla object direction:

- H-barrier segments
- cargo pallets / crates
- a watchtower or raised firing point
- one obvious retreat corridor back into the extract zone

Do not overbuild this area. It should feel exposed enough that lingering here forever is a bad idea.

### CP1: Tutorial Choke

Purpose:

- teach the first hold
- establish that stopping costs time
- let the team test one short flank

Place:

- one narrow front entrance
- one partial side lane usable by 3-4 players
- modest chest-high cover
- one elevated enemy perch that punishes full-team tunnel vision

### CP2: Split Decision Arena

Purpose:

- create the strongest “split or stack” decision in the slice
- reward communication, not raw aim only

Place:

- one wider central basin
- two side approaches with unequal safety
- one defensible center object cluster
- one exposed lane that lets overwatch matter

This is the key checkpoint for your concept. If the team never even considers splitting here, the layout is too flat.

### CP3: Final Secure Point

Purpose:

- feel closer and more claustrophobic
- reward fast breach and fast consolidation
- immediately prime the retreat phase

Place:

- shorter sightlines
- denser cover
- fewer flank options than CP2
- one obvious fallback line toward extraction

## Ten-Player Role Intention

The current draft slot split is:

- Alpha: squad lead, medic, AR, grenadier, rifleman
- Bravo: fireteam lead, engineer, marksman, AT, rifleman

That is not sacred, but it gives you:

- one command nucleus
- one sustain role
- one breach/utility role
- one anti-armor placeholder for future variants
- enough bodies to test 6/4 or 5/5 splitting

## CBA Use

For now, CBA is a declared prerequisite so the mod pack baseline is stable.

The next sensible CBA uses are:

- expose pressure and wave values as CBA settings
- add cleaner debug toggles
- standardize future event-driven hooks

This slice does not force CBA-heavy logic yet.

## Practical Note

The `mission.sqm` draft is intentionally conservative.

Open it in Eden, confirm it loads, then move the entire marker/object cluster together to the exact Altis POI you like. The scripts only care about marker names and relative route quality.
