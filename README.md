# Missions: Patrol LWH CO-10

1-10 player cooperative patrol survival mission for Arma 3 on Altis.

Move from checkpoint to checkpoint, hold against infected waves, recover supplies, keep the patrol vehicle alive, and extract before hive pressure overwhelms the team.

[English](#english) | [日本語](#japanese) | [简体中文](#zh-cn)

## At a Glance

- Game: Arma 3
- Terrain: Altis
- Mode: Co-op multiplayer
- Players: 1-10
- Status: playable, still actively tuned through live play
- Distribution: Steam Workshop is recommended for players; this repository includes source files and packaged PBO variants

## Required Workshop Items

Players should load the required Steam Workshop items before starting the mission.

- WebKnight's Zombies and Creatures
- WebKnight / WBK melee dependency used by the zombie AI
- RHSUSAF
- RHSAFRF
- RHSGREF
- RHSSAF

CBA_A3 is not directly required by this mission code at the moment. If any subscribed dependency requires it, Steam Workshop will normally pull it through that dependency.

## DLC

No Arma 3 DLC is strictly required to load the mission. The mission is built on Altis and uses base-game mission metadata.

Some optional loot candidates may use DLC-class equipment when that content is available. These are not intended to be hard requirements.

## Packaged PBO Variants

The latest packaged mission PBOs are included in the repository root:

- `KFH_Patrol_LWH_co10.Altis.pbo`
- `KFH_Patrol_LWH_co10.Stratis.pbo`
- `KFH_Patrol_LWH_co10.Tanoa.pbo`
- `KFH_Patrol_LWH_co10.Malden.pbo`

Server admins can use these files directly, while mission authors can inspect or modify the unpacked source files in this repository.

<a id="english"></a>
## English

Missions: Patrol LWH CO-10 is a checkpoint-to-checkpoint patrol survival mission.

The team starts from a small forward position, pushes through a dynamic route, secures checkpoints under pressure, collects reward crates and side caches, and then fights through the extraction phase. The mission supports solo play with a support AI and scales pressure for larger co-op testing.

### Features

- Dynamic checkpoint route generation
- Infected wave pressure and rush events
- Special infected encounters
- Reward crates and side caches
- Vehicle-focused patrol flow
- Downed/revive support
- Solo support AI
- Player-count scaling
- Extraction finale

### Current Status

This mission is around 90 percent complete. It is ready for real multiplayer playtests, but balance, loot tables, route generation, and special infected behavior may still change.

Please report issues with RPT logs when possible.

<a id="japanese"></a>
## 日本語

Missions: Patrol LWH CO-10 は、Altis を舞台にしたチェックポイント巡回型の協力サバイバルミッションです。

プレイヤーは小規模な前進拠点から出発し、動的に生成されるルートを進み、感染者の圧力を受けながらチェックポイントを確保し、報酬クレートやサイドキャッシュを回収して、最終的な脱出を目指します。ソロプレイ用の支援 AI と、人数に応じたスケーリングにも対応しています。

### 主な特徴

- 動的チェックポイントルート生成
- 感染者 Wave と Rush イベント
- 特殊感染者の出現
- 報酬クレートとサイドキャッシュ
- 車両を中心にしたパトロール進行
- ダウン/蘇生サポート
- ソロ支援 AI
- プレイヤー人数スケーリング
- 脱出フィナーレ

### 現在の状態

完成度はおよそ 90% です。実際のマルチプレイで遊べる段階ですが、バランス、クレート内容、ルート生成、特殊感染者の挙動は今後も調整される可能性があります。

不具合報告時は、可能であれば RPT ログを添えてください。

<a id="zh-cn"></a>
## 简体中文

Missions: Patrol LWH CO-10 是一张以 Altis 为舞台的合作巡逻生存任务。

玩家从小型前线据点出发，沿动态生成的路线前往各个检查点，在感染者压力下守住阵地，回收奖励补给箱和支线补给点，最后完成撤离。任务支持单人辅助 AI，并会根据玩家人数调整压力。

### 主要特色

- 动态检查点路线生成
- 感染者 Wave 与 Rush 事件
- 特殊感染者遭遇
- 奖励补给箱与支线补给点
- 以载具巡逻为核心的任务流程
- 倒地/复活支援
- 单人辅助 AI
- 根据玩家人数进行缩放
- 撤离阶段决战

### 当前状态

当前完成度约为 90%。任务已经可以进行实际多人游玩测试，但平衡性、补给内容、路线生成和特殊感染者行为之后仍可能继续调整。

报告问题时，如有可能请附上 RPT 日志。

## Developer Setup

This repository contains the unpacked mission source.

To test locally:

1. Place or symlink this folder as an Arma 3 mission folder.
2. Load the required Workshop mods.
3. Open the mission in Eden Editor on Altis.
4. Export to multiplayer or run hosted/dedicated tests.

Important mission files:

- `description.ext`: mission metadata, params, respawn settings
- `mission.sqm`: Eden mission layout
- `init.sqf`: shared script bootstrap
- `initServer.sqf`: server-side mission startup
- `initPlayerLocal.sqf`: client-side HUD and revive handling
- `scripts/kfh_settings.sqf`: balance and content settings
- `scripts/kfh_functions.sqf`: mission progression, AI, loot, revive, extraction logic
- `scripts/kfh_dynamic_route.sqf`: dynamic route generation
- `LAYOUT.md`: older layout notes retained for reference

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

Third-party Workshop dependencies such as WebKnight's Zombies and Creatures, WBK melee dependencies, and RHS are not bundled, repacked, or relicensed by this repository. Subscribe to those dependencies from their original Workshop pages.
