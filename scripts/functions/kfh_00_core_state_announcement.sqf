KFH_fnc_log = {
    params ["_message"];
    diag_log format ["[KFH] %1", _message];
};

KFH_fnc_setState = {
    params ["_key", "_value"];
    missionNamespace setVariable [_key, _value, true];
};

KFH_fnc_formatRunClock = {
    params [["_seconds", 0]];

    private _wholeSeconds = floor (_seconds max 0);
    private _minutes = floor (_wholeSeconds / 60);
    private _secondsPart = _wholeSeconds mod 60;
    private _minuteText = if (_minutes < 10) then { format ["0%1", _minutes] } else { str _minutes };
    private _secondText = if (_secondsPart < 10) then { format ["0%1", _secondsPart] } else { str _secondsPart };

    format ["%1:%2", _minuteText, _secondText]
};

KFH_fnc_initRunTelemetry = {
    missionNamespace setVariable ["KFH_runStartedAt", time, true];
    missionNamespace setVariable ["KFH_runEndedAt", -1, true];
    missionNamespace setVariable ["KFH_runEventLog", [], true];
    missionNamespace setVariable ["KFH_runRescueCount", 0, true];
    missionNamespace setVariable ["KFH_runLastSecuredCheckpoint", 0, true];
    missionNamespace setVariable ["KFH_debriefStats", "", true];
    missionNamespace setVariable ["KFH_debriefTimeline", "", true];

    ["Run telemetry initialized."] call KFH_fnc_log;
};

KFH_fnc_appendRunEvent = {
    params ["_message", ["_tag", "EVENT"]];

    private _startedAt = missionNamespace getVariable ["KFH_runStartedAt", time];
    private _timestamp = [time - _startedAt] call KFH_fnc_formatRunClock;
    private _entry = format ["[%1] %2: %3", _timestamp, _tag, _message];
    private _events = missionNamespace getVariable ["KFH_runEventLog", []];

    _events pushBack _entry;
    while { (count _events) > KFH_runEventLogLimit } do {
        _events deleteAt 0;
    };

    missionNamespace setVariable ["KFH_runEventLog", _events, true];
    [format ["RUN %1", _entry]] call KFH_fnc_log;
};

KFH_announcementTextTable = [
    ["extract_test_active", [
        "Extraction test mode 有効デス。全チェックポイントを制圧済み扱いにして、Angel One を自動要請するデス。",
        "Extraction test mode active. All checkpoints are treated as secured and Angel One will be called automatically.",
        "撤离测试模式已启用。所有检查点都视为已完成，Angel One 将自动呼叫。"
    ]],
    ["extract_test_lz_near", [
        "Extraction test: LZ は %1 付近デス。短い準備後に Angel One が到着するデス。",
        "Extraction test: the LZ is near %1. Angel One will arrive after the short prep.",
        "撤离测试：LZ 位于 %1 附近。短暂准备后 Angel One 将会抵达。"
    ]],
    ["angel_one_inbound_log", [
        "HQ: Angel One inbound. LZ を維持して搭乗準備デス。",
        "HQ: Angel One inbound. Keep the LZ hot and be ready to board.",
        "HQ：Angel One 正在接近。守住 LZ，准备登机。"
    ]],
    ["angel_one_inbound_chat", [
        "HQ: Angel One が接近中デス。LZ を確保して搭乗準備をするデス。",
        "HQ: Angel One inbound. Keep the LZ clear and prepare to board.",
        "HQ：Angel One 正在接近。清理 LZ 并准备登机。"
    ]],
    ["angel_one_landed_log", [
        "Angel One が着陸したデス。搭乗ウィンドウが閉じる前に乗るデス。",
        "Angel One is on the ground. Board now before the landing window closes.",
        "Angel One 已经着陆。请在着陆窗口关闭前立刻登机。"
    ]],
    ["angel_one_landed_chat", [
        "HQ: Angel One 着陸デス。今すぐ搭乗デス。自動離脱まで %1 秒デス。",
        "HQ: Angel One landed. Board now. Auto departure in %1 seconds.",
        "HQ：Angel One 已着陆。立即登机。%1 秒后自动离场。"
    ]],
    ["angel_one_manual_ready", [
        "Angel One は手動搭乗待ちデス。",
        "Angel One is ready for manual boarding.",
        "Angel One 已准备好手动登机。"
    ]],
    ["angel_one_all_aboard_log", [
        "生存者全員が搭乗したデス。Angel One が離陸するデス。",
        "All surviving players aboard. Angel One lifting now.",
        "所有幸存者都已登机。Angel One 立即起飞。"
    ]],
    ["angel_one_all_aboard_chat", [
        "HQ: 生存者全員搭乗デス。Angel One 離陸するデス！",
        "HQ: All survivors aboard. Angel One lifting off!",
        "HQ：所有幸存者已登机。Angel One 正在起飞！"
    ]],
    ["angel_one_timeout_log", [
        "搭乗猶予終了デス。Angel One は搭乗済みの生存者だけを乗せて離脱するデス。",
        "Angel One timeout reached. The pilot is lifting with whoever made it aboard.",
        "Angel One 的等待时间已到。飞行员将带着已登机的幸存者离开。"
    ]],
    ["angel_one_timeout_chat", [
        "HQ: Angel One はこれ以上待てないデス。搭乗済み %1 名で離脱するデス。",
        "HQ: Angel One cannot stay longer. Lifting with %1 boarded survivor(s).",
        "HQ：Angel One 无法继续等待。将带着 %1 名已登机幸存者起飞。"
    ]],
    ["flare_received_log", [
        "HQ: フレア確認デス。Angel One はピックアップ進入に入ったデス。",
        "HQ: Flare received. Angel One is committing to the pickup run.",
        "HQ：已确认信号弹。Angel One 正在执行接应航线。"
    ]],
    ["flare_received_chat", [
        "HQ: %1 からフレア確認デス。Angel One が向かうデス！",
        "HQ: Flare received from %1. Angel One is on the way!",
        "HQ：已收到 %1 发射的信号弹。Angel One 正在赶来！"
    ]],
    ["prep_window_over", [
        "準備時間終了デス。%1 に後退してフレアを撃ち、Angel One 搭乗準備をするデス。",
        "Prep window over. Fall back to %1, fire a flare at the LZ, and prepare to board Angel One.",
        "准备时间结束。撤回到 %1，在 LZ 发射信号弹，并准备登上 Angel One。"
    ]],
    ["extract_prep_remaining", [
        "Extraction 準備あと %1 秒デス。",
        "Extraction prep: %1 seconds remaining.",
        "撤离准备还剩 %1 秒。"
    ]],
    ["fire_flare_now", [
        "HQ: LZ にフレアを撃って Angel One を呼ぶデス。",
        "HQ: Fire a flare at the LZ to bring Angel One in.",
        "HQ：向 LZ 发射信号弹，把 Angel One 引导进来。"
    ]],
    ["no_flare_capability", [
        "HQ: チームにフレア携行者がいないデス。最終キャッシュかアーセナルを確認するデス。",
        "HQ: Nobody in the team is carrying a flare. Check the final cache or arsenal before pushing the LZ.",
        "HQ：队伍里没人携带信号弹。推进 LZ 前请检查最终补给箱或军械库。"
    ]],
    ["angel_one_depart_warn", [
        "HQ: Angel One はあと %1 秒で離脱デス。今すぐ搭乗しないと置いていくデス！",
        "HQ: Angel One departs in %1 seconds. Board now or be left behind!",
        "HQ：Angel One 将在 %1 秒后离开。立即登机，否则会被抛下！"
    ]],
    ["angel_one_lift_moment", [
        "生存者全員が搭乗したデス。Angel One はまもなく離陸するデス。",
        "All surviving players aboard. Angel One is lifting in a moment.",
        "所有幸存者都已登机。Angel One 即将起飞。"
    ]],
    ["backup_pickup", [
        "HQ: Angel One に機体トラブル発生デス。バックアップ機を向かわせるデス。",
        "HQ: Angel One suffered a flight fault. Dispatching a backup pickup now.",
        "HQ：Angel One 出现飞行故障。正在派遣备用接应机。"
    ]],
    ["checkpoint_secure_window_started_suppressed", [
        "確保ウィンドウ開始デス。残り %1 体は抑え込めているデス。踏みとどまれば、確保完了時にダウン中の味方は自動復帰するデス。",
        "Checkpoint secure window started. The remaining %1 contact(s) are suppressed enough. Hold your ground; downed teammates will auto-revive when the checkpoint is secured.",
        "检查点确保窗口已开始。剩余 %1 名敌人已被压制。守住阵地；检查点确保后倒地队友会自动复活。"
    ]],
    ["checkpoint_secure_window_started_clear", [
        "確保ウィンドウ開始デス。踏みとどまれば、確保完了時にダウン中の味方は自動復帰するデス。",
        "Checkpoint secure window started. Hold your ground; downed teammates will auto-revive when the checkpoint is secured.",
        "检查点确保窗口已开始。守住阵地；检查点确保后倒地队友会自动复活。"
    ]],
    ["checkpoint_cleared_reason", [
        "Checkpoint %1 確保",
        "Checkpoint %1 cleared",
        "检查点 %1 已确保"
    ]],
    ["checkpoint_contact_inbound", [
        "残敵 %1 体が接近中デス。確保前に接敵して掃討して。",
        "%1 remaining hostile(s) are moving in. Make contact and clear them before securing.",
        "剩余 %1 名敌人正在接近。确保前请接敌并清除。"
    ]],
    ["rush_wave_cleared_reason", [
        "Rush wave %1 を checkpoint %2 で撃破",
        "Rush wave %1 cleared at checkpoint %2",
        "突袭波次 %1 已在检查点 %2 清除"
    ]],
    ["auto_revive_players", [
        "%1。ダウン中の味方 %2 名が戦線復帰したデス。",
        "%1. %2 downed teammate(s) are back in the fight.",
        "%1。%2 名倒地队友已返回战斗。"
    ]],
    ["wave_cleanup_warning", [
        "HQ: 各Waveはできるだけ掃討してから進むデス。残した敵はHive Pressureに拾われて、後続Waveで利息つきで戻るデス。",
        "HQ: Clear each wave before moving on when you can. Left-behind hostiles feed Hive Pressure and return in later waves with interest.",
        "HQ：尽量在推进前清理每一波。被留下的敌人会增强蜂巢压力，并在后续波次中带着利息回来。"
    ]],
    ["melee_controls_tip", [
        "HQ: 近接攻撃のデフォルトは Ctrl+9、ドッジは Space デス。キー確認は 操作設定 > キーボード > アドオン: WebKnight's Melee デス。",
        "HQ: Default melee attack is Ctrl+9, and dodge is Space. Check Controls > Keyboard > Addon: WebKnight's Melee for keybinds.",
        "HQ：默认近战攻击为 Ctrl+9，闪避为空格键。按键请在 控制 > 键盘 > 插件: WebKnight's Melee 中确认。"
    ]],
    ["wave_debt_accrued_warning", [
        "HQ: %1 体を残してCPを確保したデス。残敵は後続Waveに回るデス。次は掃討優先が安全デス。",
        "HQ: Checkpoint secured with %1 hostile(s) left behind. They will return in later waves. Clearing the wave first is safer.",
        "HQ：检查点已确保，但留下了 %1 名敌人。它们会在后续波次中回来。优先清理波次会更安全。"
    ]],
    ["player_downed_announcement", [
        "HQ: %1 がダウンしたデス。安全を確保してReviveして。",
        "HQ: %1 is down. Secure the area and revive them.",
        "HQ：%1 已倒地。请先确保安全，然后进行复活。"
    ]],
    ["civilian_panic_explosion", [
        "民間人周辺で爆発が発生したデス。非戦闘員への誤射に注意して。",
        "A civilian vehicle/device cooked off nearby. Watch your fire around non-combatants.",
        "附近的民用车辆或装置发生爆炸。请注意不要误伤非战斗人员。"
    ]],
    ["story_civilian_traffic_collapsed", [
        "HQ: 民間交通は崩壊済みデス。道路封鎖、放置車両、感染体との接触を警戒して。",
        "HQ: Civilian traffic has collapsed. Expect roadblocks, abandoned vehicles, and infected contacts ahead.",
        "HQ：民用交通已经崩溃。前方可能有路障、废弃车辆和感染者接触。"
    ]],
    ["story_base_lost", [
        "HQ: 帰投予定基地は壊滅済みデス。装備庫だけは生きている可能性あり。行くか、脱出優先か判断して。",
        "HQ: The planned return base is lost. The arsenal may still be usable. Decide whether to risk it or prioritize extraction.",
        "HQ：预定返回基地已经失守。军械库可能还能使用。请判断是冒险前往，还是优先撤离。"
    ]],
    ["story_arsenal_online", [
        "HQ: 装備庫オンライン。ただし重装感染体が寄ってきています。帰還準備を急いで。",
        "HQ: Arsenal online. Heavy infected are closing in, so finish preparations quickly.",
        "HQ：军械库已上线。但重型感染者正在靠近，请尽快完成准备。"
    ]],
    ["story_alt_lz_sent", [
        "HQ: 別座標のヘリ LZ を送信。チームをまとめて脱出地点へ移動して。",
        "HQ: Alternate helicopter LZ transmitted. Regroup and move to extraction.",
        "HQ：已发送备用直升机 LZ 坐标。集合队伍并前往撤离点。"
    ]],
    ["checkpoint_defense_started", [
        "Checkpoint %1 防衛イベント開始デス。%3 敵数: %2。",
        "Checkpoint %1 defensive event started. %3 Hostiles: %2.",
        "检查点 %1 防御事件开始。%3 敌人：%2。"
    ]],
    ["checkpoint_hive_surge", [
        "Checkpoint %1 event: Hive Surge で追加接触Waveが発生したデス。",
        "Checkpoint %1 event: Hive Surge triggered an extra contact wave.",
        "检查点 %1 事件：蜂巢涌动触发了额外接触波次。"
    ]],
    ["checkpoint_blocking_contact", [
        "Checkpoint %1 の騒音で封鎖接触が発生。確保前に掃討して。",
        "Checkpoint %1 noise drew a blocking contact. Clear it before securing.",
        "检查点 %1 的噪音引来了阻挡敌群。确保前请先清理。"
    ]],
    ["checkpoint_supply_enroute", [
        "HQ: CP%1 確保デス。補給隊は約 %2 秒で到着予定デス。ここを維持すれば見返りがあるデス。",
        "HQ: CP%1 secure. Supply team may reach this position in about %2 seconds. Holding here could pay off.",
        "HQ：CP%1 已确保。补给队可能在约 %2 秒后抵达。守住这里会有回报。"
    ]],
    ["checkpoint_supply_arrived", [
        "補給隊が CP%1 に到着。弾薬、医療、修理支援が利用可能デス。",
        "Supply team reached CP%1. Ammo, medical kit, and repair kit support are now online.",
        "补给队已抵达 CP%1。弹药、医疗和修理支援现已可用。"
    ]],
    ["support_loadout_restored", [
        "弾薬キャッシュから装備を復元したデス。",
        "Loadout restored from ammo cache.",
        "已从弹药箱恢复装备。"
    ]],
    ["support_medical_patched", [
        "医療ステーションで回復したデス。",
        "Medical station patched you up.",
        "医疗站已为你完成治疗。"
    ]],
    ["support_repair_serviced", [
        "フィールド整備で車両 %1 台を修理・補給したデス。",
        "Field maintenance serviced %1 vehicle(s).",
        "野战维修已维护 %1 辆载具。"
    ]],
    ["support_repair_stamina", [
        "周辺に車両なし。フィールド整備でスタミナだけ回復したデス。",
        "Field maintenance reset your stamina. No vehicles nearby.",
        "附近没有载具。野战维修仅重置了你的体力。"
    ]],
    ["support_unknown_point", [
        "不明な支援ポイントデス。",
        "Unknown support point.",
        "未知支援点。"
    ]],
    ["ai_revived_player", [
        "%1 が %2 をReviveしたデス。",
        "%1 revived %2.",
        "%1 复活了 %2。"
    ]],
    ["local_downed_notice", [
        "ダウン中デス。Revive支援まで耐えて。",
        "Downed. Hold on for revive support.",
        "你已倒地。坚持等待复活支援。"
    ]],
    ["side_cache_marked", [
        "Checkpoint %1 付近に任意サイドキャッシュをマークしたデス。余裕があれば寄り道して。",
        "Optional side cache marked near checkpoint %1. Detour if the team can afford it.",
        "已在检查点 %1 附近标记可选侧边补给箱。队伍有余力时可以绕路获取。"
    ]],
    ["side_cache_contact", [
        "HQ: Checkpoint %1 付近でサイドキャッシュ反応デス。良い物資あり。ただし騒音で感染体が寄るデス。",
        "HQ: Side cache contact near checkpoint %1. Good loot, but the noise is drawing infected.",
        "HQ：检查点 %1 附近发现侧边补给箱。物资不错，但噪音会吸引感染者。"
    ]],
    ["final_flare_cache_marked", [
        "HQ: 緊急フレアキャッシュをマークしたデス。LZへ進む前に、誰か1人がフレアガンを持って。",
        "HQ: Emergency flare cache marked. Assign one survivor to carry the flare gun before moving to the LZ.",
        "HQ：已标记紧急信号弹补给箱。前往 LZ 前请安排一名幸存者携带信号枪。"
    ]],
    ["optional_arsenal_marked", [
        "HQ: アーセナルはルート外の廃基地デス。Juggernaut警戒。消耗が激しいなら無視して脱出優先でいいデス。",
        "HQ: Arsenal is off-route at a ruined base. Expect a juggernaut. You can skip it and push extraction if battered.",
        "HQ：军械库位于路线外的废弃基地。预计有巨型感染者。如果队伍损耗严重，可以跳过并优先撤离。"
    ]],
    ["signal_hunt_bonus_team", [
        "Checkpoint %1 event: Signal Hunt でボーナスキャリア部隊が追加されたデス。",
        "Checkpoint %1 event: Signal Hunt added a bonus carrier team.",
        "检查点 %1 事件：信号猎捕追加了一支奖励携行队。"
    ]],
    ["rush_supply_carrier_down", [
        "Rush補給キャリアを %1 で撃破。バックパックから包帯と弾薬を回収して。",
        "Rush supply carrier down at %1. Loot the backpack for bandages and magazines.",
        "突袭补给携行者已在 %1 被击倒。搜刮背包获取绷带和弹匣。"
    ]],
    ["melee_dependency_missing", [
        "WebKnight Zombies / Improved Melee System が未ロードです。ゾンビAIフォールバックは無効デス。",
        "WebKnight Zombies/Improved Melee System not loaded. Zombie AI fallback is disabled.",
        "未加载 WebKnight Zombies / Improved Melee System。僵尸 AI 备用方案已禁用。"
    ]],
    ["rush_wave_broken", [
        "Rush wave %1 を撃破。チームは復帰、Hive Pressureも低下したデス。補給キャリアの物資も確認して。",
        "Rush wave %1 broken. Team revived and pressure reduced. Loot supply carriers for extra bandages and magazines.",
        "突袭波次 %1 已击破。队伍已复活，压力已降低。请搜刮补给携行者获取额外绷带和弹匣。"
    ]],
    ["rush_wave_deployed", [
        "Rush wave %1 が checkpoint %2 に展開。敵 %3 体、射撃役およそ %4 体デス。",
        "Rush wave %1 deployed at checkpoint %2 (%3 hostiles, about %4 gunners).",
        "突袭波次 %1 已部署到检查点 %2（%3 名敌人，约 %4 名射手）。"
    ]],
    ["retreat_wave_deployed", [
        "帰還Waveが最終checkpoint方面からLZへ再展開。敵 %1 体デス。",
        "Retreat wave redeployed from final checkpoint toward extraction (%1 hostiles).",
        "撤退波次已从最终检查点方向重新部署到撤离点（%1 名敌人）。"
    ]],
    ["checkpoint_side_relief", [
        "Checkpoint %1 のサイドイベントがHive Pressureを乱したデス。",
        "Checkpoint %1 side event disrupted hive pressure.",
        "检查点 %1 的侧边事件扰乱了蜂巢压力。"
    ]],
    ["checkpoint_reward_cache", [
        "Checkpoint %1 確保。現地補給箱に %2 報酬を追加したデス。バックパック強化と上位装備を確認して。",
        "Checkpoint %1 secured. %2 rewards were added to the local resupply cache.",
        "检查点 %1 已确保。%2 奖励已加入现场补给箱。"
    ]],
    ["checkpoint_time_shift", [
        "Checkpoint %1 確保。日が傾いてきたデス。ライトと光学照準を意識して。",
        "Checkpoint %1 secured. The sun keeps dropping; lights and optics matter more now.",
        "检查点 %1 已确保。太阳继续下沉，灯光和光学装备更重要。"
    ]],
    ["vehicle_threat_label_light", [
        "低騒音 / Hive Pressure低め",
        "low noise / low hive pressure",
        "低噪音 / 蜂巢压力较低"
    ]],
    ["vehicle_threat_label_medium", [
        "車両騒音 / Hive Pressure中程度",
        "vehicle noise / medium hive pressure",
        "车辆噪音 / 蜂巢压力中等"
    ]],
    ["vehicle_threat_label_heavy", [
        "大きな騒音 / Hive Pressure高め",
        "loud / high hive pressure",
        "高噪音 / 蜂巢压力较高"
    ]],
    ["vehicle_threat_label_armor", [
        "装甲車両 / Hive Pressureかなり高い",
        "armored / severe hive pressure",
        "装甲车辆 / 蜂巢压力很高"
    ]],
    ["vehicle_threat_label_combat", [
        "戦闘車両 / Hive Pressure極大",
        "combat vehicle / extreme hive pressure",
        "战斗车辆 / 蜂巢压力极高"
    ]],
    ["vehicle_entry_notice", [
        "車両燃料 %1%%。%2。大型車ほどHive Pressureが上がりやすいデス。",
        "Vehicle fuel %1%%. %2. Bigger vehicles escalate Hive Pressure faster.",
        "车辆燃料 %1%%。%2。车辆越大，蜂巢压力上升越快。"
    ]],
    ["final_checkpoint_arsenal_marked", [
        "最終checkpoint確保。帰投ルート外に任意アーセナル基地をマークしたデス。",
        "Final checkpoint secured. Optional arsenal base marked off-route for the return trip.",
        "最终检查点已确保。已在返程路线外标记可选军械库基地。"
    ]],
    ["final_checkpoint_prep", [
        "最終checkpoint確保。アーセナルオンライン。%1 秒準備してから %2 へ後退して。",
        "Final checkpoint secure. Arsenal online. You have %1 seconds to prepare before falling back to %2.",
        "最终检查点已确保。军械库已上线。你有 %1 秒准备，然后撤回到 %2。"
    ]],
    ["advance_checkpoint", [
        "Checkpoint %1 へ前進して。",
        "Advance to checkpoint %1.",
        "前进到检查点 %1。"
    ]],
    ["spectating_target", [
        "%1 を観戦中デス。",
        "Spectating %1",
        "正在观看 %1"
    ]],
    ["downed_spectator_started", [
        "死亡時カメラ起動デス。マウスで視点、ホイールでズーム、クリックで対象切替デス。",
        "Downed spectator active. Move mouse to look around; wheel zooms; click switches target.",
        "倒地观察相机已启用。移动鼠标观察，滚轮缩放，点击切换目标。"
    ]],
    ["downed_rescue_info", [
        "最寄り: %1 / 観戦: %2",
        "Nearest: %1 / Camera: %2",
        "最近: %1 / 观察: %2"
    ]],
    ["map_pinged", [
        "%1 が %2 にPingしたデス。",
        "%1 pinged %2.",
        "%1 标记了 %2。"
    ]],
    ["revive_no_ally", [
        "Revive可能なダウン味方が近くにいないデス。",
        "No downed ally close enough to revive.",
        "附近没有可复活的倒地队友。"
    ]],
    ["revive_pull_vehicle_first", [
        "先に車両から負傷者をPullして。",
        "Pull injured from vehicle first.",
        "请先把伤员从载具中拉出来。"
    ]],
    ["manual_revived_player", [
        "%1 が %2 をReviveしたデス。",
        "%1 revived %2.",
        "%1 复活了 %2。"
    ]],
    ["revive_interrupted", [
        "Reviveが中断されたデス。",
        "Revive interrupted.",
        "复活被中断。"
    ]],
    ["pull_no_vehicle_injured", [
        "近くの車両内にPull可能な負傷者はいないデス。",
        "No injured ally inside a nearby vehicle.",
        "附近载具内没有可拉出的受伤队友。"
    ]],
    ["pull_vehicle_injured_clear", [
        "負傷者を車両外へPullしたデス。安全ならDragかReviveして。",
        "Injured ally pulled clear. Drag or revive once safe.",
        "已将受伤队友拉离载具。安全后请拖拽或复活。"
    ]],
    ["drag_body_dropped", [
        "Bodyを離したデス。",
        "Body dropped.",
        "已放下身体。"
    ]],
    ["drag_no_body", [
        "Drag可能なダウン味方またはBodyが近くにないデス。",
        "No downed ally or body close enough to drag.",
        "附近没有可拖拽的倒地队友或身体。"
    ]],
    ["drag_started", [
        "味方BodyをDrag中デス。安全な場所でDrop bodyして。",
        "Dragging ally body. Use Drop body when safe.",
        "正在拖拽队友身体。安全后使用 Drop body。"
    ]],
    ["flip_no_vehicle", [
        "近くに起こせる横転車両がないデス。",
        "No overturned vehicle close enough.",
        "附近没有可扶正的翻倒载具。"
    ]],
    ["action_flip_vehicle", [
        "近くの車両を起こす",
        "Flip nearby vehicle",
        "扶正附近载具"
    ]],
    ["action_revive_ally", [
        "<t color='#ff4444'>味方をRevive</t>",
        "<t color='#ff4444'>Revive ally</t>",
        "<t color='#ff4444'>复活队友</t>"
    ]],
    ["action_pull_vehicle_injured", [
        "<t color='#ff4444'>車両から負傷者をPull</t>",
        "<t color='#ff4444'>Pull injured from vehicle</t>",
        "<t color='#ff4444'>从载具中拉出伤员</t>"
    ]],
    ["action_drag_body", [
        "味方BodyをDrag",
        "Drag ally body",
        "拖拽队友身体"
    ]],
    ["action_drop_body", [
        "BodyをDrop",
        "Drop body",
        "放下身体"
    ]],
    ["return_route_profile", [
        "帰還ルート確定デス。補給線 %1/%2 online、帰還危険度 %3 デス。",
        "Return route profile locked. Supply line %1/%2 online. Return danger %3.",
        "返回路线配置已锁定。补给线 %1/%2 在线，返回危险度 %3。"
    ]],
    ["pressure_critical", [
        "Hive Pressure が危険域デス。Rush密度は上がるけど、時間切れ失敗はないデス。",
        "Hive Pressure is critical. Rush density is rising, but there is no time-limit fail state.",
        "蜂巢压力已达危险水平。突袭密度正在上升，但没有时间限制失败状态。"
    ]],
    ["checkpoint_status_debug", [
        "Checkpoint %1 status: players=%2 hostiles=%3 grid=%4",
        "Checkpoint %1 status: players=%2 hostiles=%3 grid=%4",
        "检查点 %1 状态：玩家=%2 敌人=%3 坐标=%4"
    ]],
    ["action_support_resupply", [
        "%1 で補給",
        "Resupply at %1",
        "在 %1 补给"
    ]],
    ["action_support_use", [
        "%1 を使う",
        "Use %1",
        "使用 %1"
    ]],
    ["mission_success_full", [
        "Angel flight がチームを回収したデス。Extraction successful.",
        "Angel flight lifted the team out. Extraction successful.",
        "Angel 航班已将队伍撤出。撤离成功。"
    ]],
    ["mission_success_partial", [
        "Angel flight は生存オペレーター %1/%2 名を乗せて離脱したデス。",
        "Angel flight escaped with %1 of %2 surviving operators aboard.",
        "Angel 航班已带着 %1/%2 名幸存干员撤离。"
    ]],
    ["mission_failed_empty_lift", [
        "Angel flight は空で離脱。生存者は搭乗できなかったデス。",
        "Angel flight lifted empty. No survivors made it aboard.",
        "Angel 航班空机离开。没有幸存者成功登机。"
    ]],
    ["mission_failed_heli_lost", [
        "チーム脱出前にExtraction helicopterを喪失したデス。",
        "Extraction helicopter was lost before the team got out.",
        "队伍撤出前，撤离直升机已损失。"
    ]],
    ["mission_failed_team_down", [
        "チーム全員がダウン。Operation lost.",
        "The whole team went down. Operation lost.",
        "全队倒地。行动失败。"
    ]],
    ["mission_failed_pressure", [
        "Hive Pressure が作戦を崩壊させたデス。",
        "Hive pressure collapsed the operation.",
        "蜂巢压力使行动崩溃。"
    ]]
];

KFH_fnc_getAnnouncementLanguageIndex = {
    private _cached = missionNamespace getVariable ["KFH_announcementLanguageIndex", -1];
    if (_cached >= 0 && {!hasInterface}) exitWith { _cached };

    private _value = ["KFH_AnnouncementLanguage", missionNamespace getVariable ["KFH_announcementLanguageDefault", 1]] call BIS_fnc_getParamValue;
    if (!hasInterface) then {
        missionNamespace setVariable ["KFH_announcementLanguageIndex", _value];
    };
    _value
};

KFH_fnc_localizeAnnouncement = {
    params ["_key", ["_args", []]];

    private _entryIndex = KFH_announcementTextTable findIf { (_x select 0) isEqualTo _key };
    if (_entryIndex < 0) exitWith {
        if ((count _args) > 0) then {
            format ([_key] + _args)
        } else {
            _key
        }
    };

    private _entry = KFH_announcementTextTable select _entryIndex;
    private _variants = _entry select 1;
    private _langIndex = ([] call KFH_fnc_getAnnouncementLanguageIndex) max 0;
    if (_langIndex >= count _variants) then {
        _langIndex = if ((count _variants) > 1) then { 1 } else { 0 };
    };

    private _text = _variants select _langIndex;
    if ((count _args) > 0) then {
        format ([_text] + _args)
    } else {
        _text
    }
};

KFH_fnc_appendRunEventKey = {
    params ["_key", ["_args", []], ["_tag", "EVENT"]];
    [[_key, _args] call KFH_fnc_localizeAnnouncement, _tag] call KFH_fnc_appendRunEvent;
};

KFH_fnc_receiveAnnouncementKey = {
    params ["_key", ["_args", []]];
    systemChat format ["[KFH] %1", [_key, _args] call KFH_fnc_localizeAnnouncement];
};

KFH_fnc_notifyAllKey = {
    params ["_key", ["_args", []]];
    [_key, _args] remoteExecCall ["KFH_fnc_receiveAnnouncementKey", 0];
    [format ["BroadcastKey: %1 %2", _key, _args]] call KFH_fnc_log;
};

KFH_fnc_receiveAutoReviveAnnouncement = {
    params ["_reasonKey", ["_reasonArgs", []], ["_count", 0]];

    private _reason = [_reasonKey, _reasonArgs] call KFH_fnc_localizeAnnouncement;
    systemChat format ["[KFH] %1", ["auto_revive_players", [_reason, _count]] call KFH_fnc_localizeAnnouncement];
};

KFH_fnc_trackPlayerReviveTransitions = {
    {
        private _currentState = if !(alive _x) then {
            "dead"
        } else {
            if ([_x] call KFH_fnc_isIncapacitated) then { "downed" } else { "combat" };
        };
        private _previousState = _x getVariable ["KFH_lastTelemetryState", "unknown"];

        if ((_previousState isEqualTo "downed") && (_currentState isEqualTo "combat")) then {
            private _rescues = (missionNamespace getVariable ["KFH_runRescueCount", 0]) + 1;
            missionNamespace setVariable ["KFH_runRescueCount", _rescues, true];
            private _message = if (([] call KFH_fnc_getAnnouncementLanguageIndex) isEqualTo 0) then {
                format ["%1 が救助されて戦線に復帰したデス。", name _x]
            } else {
                format ["%1 was rescued and returned to the fight.", name _x]
            };
            [_message, "REVIVE"] call KFH_fnc_appendRunEvent;
        };

        if (!(_previousState in ["unknown", "dead"]) && {_currentState isEqualTo "dead"}) then {
            missionNamespace setVariable ["KFH_lastHumanCasualtyAt", time, true];
            [format ["Human casualty grace armed for %1. Previous state=%2.", name _x, _previousState]] call KFH_fnc_log;
        };

        _x setVariable ["KFH_lastTelemetryState", _currentState];
    } forEach ([] call KFH_fnc_getHumanPlayers);
};

KFH_fnc_renderRunSummary = {
    private _outcome = missionNamespace getVariable ["KFH_phase", "boot"];
    private _wave = missionNamespace getVariable ["KFH_currentWave", 0];
    private _checkpoint = missionNamespace getVariable ["KFH_runLastSecuredCheckpoint", 0];
    private _checkpointTotal = missionNamespace getVariable ["KFH_totalCheckpoints", 0];
    private _rescues = missionNamespace getVariable ["KFH_runRescueCount", 0];
    private _extracted = if (_outcome isEqualTo "complete") then {
        count (([] call KFH_fnc_getHumanPlayers) select { alive _x })
    } else {
        0
    };
    private _startedAt = missionNamespace getVariable ["KFH_runStartedAt", 0];
    private _endedAt = missionNamespace getVariable ["KFH_runEndedAt", time];
    private _duration = [_endedAt - _startedAt] call KFH_fnc_formatRunClock;
    private _lang = [] call KFH_fnc_getAnnouncementLanguageIndex;
    private _resultLabel = if (_lang isEqualTo 0) then {
        if (_outcome isEqualTo "complete") then { "帰還成功" } else { "帰還失敗" }
    } else {
        if (_outcome isEqualTo "complete") then { "Extraction success" } else { "Extraction failed" }
    };
    private _seed = missionNamespace getVariable ["KFH_routeSeed", -1];
    private _routePoints = missionNamespace getVariable ["KFH_dynamicRoutePoints", []];
    private _startGrid = if ((count _routePoints) > 0) then { mapGridPosition (_routePoints select 0) } else { "N/A" };
    private _extractGrid = if ((count _routePoints) > 1) then { mapGridPosition (_routePoints select ((count _routePoints) - 1)) } else { "N/A" };

    if (_lang isEqualTo 0) then {
        format [
            "結果: %1<br/>Seed: %2<br/>Start: %3 / LZ: %4<br/>到達 Wave: %5<br/>到達 Checkpoint: %6/%7<br/>救助数: %8<br/>帰還人数: %9<br/>プレイ時間: %10",
            _resultLabel,
            _seed,
            _startGrid,
            _extractGrid,
            _wave,
            _checkpoint,
            _checkpointTotal,
            _rescues,
            _extracted,
            _duration
        ]
    } else {
        format [
            "Result: %1<br/>Seed: %2<br/>Start: %3 / LZ: %4<br/>Wave reached: %5<br/>Checkpoint reached: %6/%7<br/>Rescues: %8<br/>Extracted: %9<br/>Duration: %10",
            _resultLabel,
            _seed,
            _startGrid,
            _extractGrid,
            _wave,
            _checkpoint,
            _checkpointTotal,
            _rescues,
            _extracted,
            _duration
        ]
    }
};

KFH_fnc_renderRouteSummary = {
    private _routePoints = missionNamespace getVariable ["KFH_dynamicRoutePoints", []];

    if ((count _routePoints) isEqualTo 0) exitWith {
        if (([] call KFH_fnc_getAnnouncementLanguageIndex) isEqualTo 0) then { "動的ルート記録なし" } else { "No dynamic route record" }
    };

    private _segments = [];
    {
        private _label = if (_forEachIndex isEqualTo 0) then {
            "START"
        } else {
            if (_forEachIndex isEqualTo ((count _routePoints) - 1)) then {
                "LZ"
            } else {
                format ["CP%1", _forEachIndex]
            }
        };
        _segments pushBack (format ["%1=%2", _label, mapGridPosition _x]);
    } forEach _routePoints;

    _segments joinString " / "
};

KFH_fnc_renderRunTimeline = {
    private _events = missionNamespace getVariable ["KFH_runEventLog", []];

        if ((count _events) isEqualTo 0) exitWith {
        if (([] call KFH_fnc_getAnnouncementLanguageIndex) isEqualTo 0) then { "イベント記録はまだ無いデス。" } else { "No event log yet." }
    };

    private _text = "";
    {
        if (_forEachIndex > 0) then {
            _text = _text + "<br/>";
        };

        _text = _text + format ["- %1", _x];
    } forEach _events;

    _text
};

KFH_fnc_publishRunSummary = {
    missionNamespace setVariable ["KFH_runEndedAt", time, true];

    private _summaryText = [] call KFH_fnc_renderRunSummary;
    private _timelineText = [] call KFH_fnc_renderRunTimeline;
    private _outcome = missionNamespace getVariable ["KFH_phase", "boot"];
    private _wave = missionNamespace getVariable ["KFH_currentWave", 0];
    private _checkpoint = missionNamespace getVariable ["KFH_runLastSecuredCheckpoint", 0];
    private _checkpointTotal = missionNamespace getVariable ["KFH_totalCheckpoints", 0];
    private _rescues = missionNamespace getVariable ["KFH_runRescueCount", 0];
    private _seed = missionNamespace getVariable ["KFH_routeSeed", -1];
    private _routeSummary = [] call KFH_fnc_renderRouteSummary;
    private _extracted = if (_outcome isEqualTo "complete") then {
        count (([] call KFH_fnc_getHumanPlayers) select { alive _x })
    } else {
        0
    };
    private _duration = [
        (missionNamespace getVariable ["KFH_runEndedAt", time]) - (missionNamespace getVariable ["KFH_runStartedAt", 0])
    ] call KFH_fnc_formatRunClock;

    missionNamespace setVariable ["KFH_debriefStats", _summaryText, true];
    missionNamespace setVariable ["KFH_debriefTimeline", _timelineText, true];

    [format [
        "RUN SUMMARY | result=%1 | seed=%2 | route=%3 | wave=%4 | checkpoint=%5/%6 | rescues=%7 | extracted=%8 | duration=%9",
        _outcome,
        _seed,
        _routeSummary,
        _wave,
        _checkpoint,
        _checkpointTotal,
        _rescues,
        _extracted,
        _duration
    ]] call KFH_fnc_log;

    {
        [format ["RUN TIMELINE | %1", _x]] call KFH_fnc_log;
    } forEach (missionNamespace getVariable ["KFH_runEventLog", []]);
};

