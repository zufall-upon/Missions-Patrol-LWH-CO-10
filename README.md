# Missions: Patrol LWH CO-10

1-10 player cooperative patrol survival mission for Arma 3 on Altis.

Move from checkpoint to checkpoint, hold against infected waves, recover supplies, keep the patrol vehicle alive, and extract before hive pressure overwhelms the team.

## Required Workshop Items

- WebKnight's Zombies and Creatures
- Improved Melee System

CBA_A3 is not directly required by this mission code at the moment. If any subscribed dependency requires it, Steam Workshop will normally pull it through that dependency.

## Optional Workshop Items

The mission can use RHS content for extra weapons, gear, and vehicle variety when it is loaded, but RHS is not a hard requirement. Without RHS, the mission falls back to base-game equipment and vehicles.

- RHSUSAF
- RHSAFRF
- RHSGREF
- RHSSAF

## DLC

No Arma 3 DLC is strictly required to load the mission. The mission is built on Altis and uses base-game mission metadata.

Some optional loot candidates may use DLC-class equipment when that content is available. These are not intended to be hard requirements.

## Features

- Dynamic checkpoint route generation
- Infected wave pressure and rush events
- Special infected encounters
- Reward crates and side caches
- Vehicle-focused patrol flow
- Downed/revive support
- Solo support AI
- Player-count scaling
- Extraction finale

## Source and Packaging Notes

This folder is the Eden mission source folder.

The public source repository is:

- `missions/KFH_Patrol_LWH_co10`

The packaged PBO is produced by:

- `tools/package_steam_workshop_mission.ps1`

The packaging script writes the Steam Workshop PBO to:

- `O:\__gamedev\__steamworkshop_publish\KFH_Patrol_LWH_co10\KFH_Patrol_LWH_co10.Altis.pbo`

When the public source repository exists, the same PBO is also copied into that repository root.

## License and Attribution

Missions: Patrol LWH CO-10 is a modified/derivative Arma 3 mission based on work and design lineage from co10_Escape / co10_Escape_SableVII.

This mission is distributed for non-commercial Arma use under the Arma Public License Share Alike (APL-SA):

https://www.bohemia.net/community/licenses/arma-public-license-share-alike

Upstream credits:

- Original Co10-Escape missions by CaptainPStar and ScruffyAT
- Original Arma 2 Escape mission by Engima of Ostgota Ops
- Arma 3 port by Vormulac and HyperZ
- co10_Escape_SableVII fork and tweaks by SableVII

This mission is not the original co10_Escape or co10_Escape_SableVII mission. It has been renamed, heavily modified, and published as Missions: Patrol LWH CO-10.

Third-party Workshop dependencies such as WebKnight's Zombies and Creatures, Improved Melee System, and optional RHS items are not bundled, repacked, or relicensed by this repository. Subscribe to those dependencies from their original Workshop pages.
