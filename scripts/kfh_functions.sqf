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
        "Checkpoint secure window 開始デス。残り %1 体は抑え込めているデス。踏みとどまれば、確保完了時にダウン中の味方は自動復帰するデス。",
        "Checkpoint secure window started. The remaining %1 contact(s) are suppressed enough. Hold your ground; downed teammates will auto-revive when the checkpoint is secured.",
        "检查点确保窗口已开始。剩余 %1 名敌人已被压制。守住阵地；检查点确保后倒地队友会自动复活。"
    ]],
    ["checkpoint_secure_window_started_clear", [
        "Checkpoint secure window 開始デス。踏みとどまれば、確保完了時にダウン中の味方は自動復帰するデス。",
        "Checkpoint secure window started. Hold your ground; downed teammates will auto-revive when the checkpoint is secured.",
        "检查点确保窗口已开始。守住阵地；检查点确保后倒地队友会自动复活。"
    ]],
    ["checkpoint_cleared_reason", [
        "Checkpoint %1 確保",
        "Checkpoint %1 cleared",
        "检查点 %1 已确保"
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
    ]]
];

KFH_fnc_getAnnouncementLanguageIndex = {
    private _cached = missionNamespace getVariable ["KFH_announcementLanguageIndex", -1];
    if (_cached >= 0) exitWith { _cached };

    private _value = ["KFH_AnnouncementLanguage", missionNamespace getVariable ["KFH_announcementLanguageDefault", 0]] call BIS_fnc_getParamValue;
    missionNamespace setVariable ["KFH_announcementLanguageIndex", _value];
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
        _langIndex = 0;
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
            [format ["%1 が救助されて戦線に復帰したデス。", name _x], "REVIVE"] call KFH_fnc_appendRunEvent;
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
    private _resultLabel = if (_outcome isEqualTo "complete") then { "帰還成功" } else { "帰還失敗" };
    private _seed = missionNamespace getVariable ["KFH_routeSeed", -1];
    private _routePoints = missionNamespace getVariable ["KFH_dynamicRoutePoints", []];
    private _startGrid = if ((count _routePoints) > 0) then { mapGridPosition (_routePoints select 0) } else { "N/A" };
    private _extractGrid = if ((count _routePoints) > 1) then { mapGridPosition (_routePoints select ((count _routePoints) - 1)) } else { "N/A" };

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
};

KFH_fnc_renderRouteSummary = {
    private _routePoints = missionNamespace getVariable ["KFH_dynamicRoutePoints", []];

    if ((count _routePoints) isEqualTo 0) exitWith {
        "動的ルート記録なし"
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
        "イベント記録はまだ無いデス。"
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
        "RUN SUMMARY | 結果=%1 | seed=%2 | route=%3 | wave=%4 | checkpoint=%5/%6 | rescues=%7 | extracted=%8 | duration=%9",
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

KFH_fnc_getHumanPlayers = {
    allPlayers select {
        isPlayer _x &&
        !(_x isKindOf "HeadlessClient_F")
    }
};

KFH_fnc_getAliveHumanPlayers = {
    ([] call KFH_fnc_getHumanPlayers) select { alive _x }
};

KFH_fnc_getScalingPlayerCount = {
    private _humans = count ([] call KFH_fnc_getHumanPlayers);
    private _override = missionNamespace getVariable ["KFH_scalingPlayerCountOverride", -1];
    if (_override > 0) exitWith { _override };
    _humans max 1
};

KFH_fnc_localNotify = {
    params ["_message"];
    systemChat format ["[KFH] %1", _message];
};

KFH_fnc_handleCivilianKilled = {
    params ["_unit", ["_killer", objNull]];

    if (!isServer) exitWith {
        [_unit, _killer] remoteExecCall ["KFH_fnc_handleCivilianKilled", 2];
    };
    if (isNull _unit) exitWith {};
    if (_unit getVariable ["KFH_civilianPenaltyHandled", false]) exitWith {};

    private _effectiveSource = _killer;
    if (!isNull _killer && {!(_killer isKindOf "CAManBase")}) then {
        _effectiveSource = effectiveCommander _killer;
    };
    private _friendlyCaused = !isNull _effectiveSource && {
        isPlayer _effectiveSource || {(side group _effectiveSource) isEqualTo west}
    };
    if !(_friendlyCaused) exitWith {};

    _unit setVariable ["KFH_civilianPenaltyHandled", true, true];
    private _penalty = missionNamespace getVariable ["KFH_civilianKillPressurePenalty", 8];
    if (_penalty > 0) then {
        private _pressure = missionNamespace getVariable ["KFH_pressure", 0];
        ["KFH_pressure", (_pressure + _penalty) min KFH_pressureMax] call KFH_fnc_setState;
    };

    private _killerName = if (isNull _effectiveSource) then { "unknown" } else { name _effectiveSource };
    [format ["Civilian casualty caused by %1. Pressure penalty=%2.", _killerName, _penalty], "CIV"] call KFH_fnc_appendRunEvent;

    if ((random 1) <= (missionNamespace getVariable ["KFH_civilianKillExplosionChance", 0.08])) then {
        private _pos = getPosATL _unit;
        private _explosionClass = missionNamespace getVariable ["KFH_civilianKillExplosionClass", "Bo_Mk82"];
        createVehicle [_explosionClass, _pos, [], 0, "CAN_COLLIDE"];
        [format ["Civilian panic explosion triggered at %1.", mapGridPosition _pos], "CIV"] call KFH_fnc_appendRunEvent;
        ["A civilian vehicle/device cooked off nearby. Watch your fire around non-combatants."] call KFH_fnc_notifyAll;
    };
};

KFH_fnc_installCivilianPenaltyHandlers = {
    params ["_unit"];

    if (isNull _unit) exitWith {};
    if (_unit getVariable ["KFH_civilianPenaltyInstalled", false]) exitWith {};

    _unit setVariable ["KFH_civilianPenaltyInstalled", true, true];
    _unit addEventHandler ["Killed", {
        params ["_unit", "_killer"];
        [_unit, _killer] call KFH_fnc_handleCivilianKilled;
    }];
};

KFH_fnc_applyFriendlyFireMitigation = {
    params ["_unit"];

    if (isNull _unit) exitWith {};
    if (_unit getVariable ["KFH_ffMitigationInstalled", false]) exitWith {};

    _unit addEventHandler ["HandleDamage", {
        params ["_unit", "_selection", "_incomingDamage", "_source"];

        if (isNull _source) exitWith { _incomingDamage };
        if (_source isEqualTo _unit) exitWith { _incomingDamage };

        private _effectiveSource = if (_source isKindOf "CAManBase") then {
            _source
        } else {
            effectiveCommander _source
        };

        if (isNull _effectiveSource) exitWith { _incomingDamage };
        if !(alive _effectiveSource) exitWith { _incomingDamage };

        private _sourceIsEnvMilitary = (_effectiveSource getVariable ["KFH_envTrafficCrew", false]) || {
            _source getVariable ["KFH_ambientTraffic", false]
        };
        private _targetIsEnvMilitary = _unit getVariable ["KFH_envTrafficCrew", false];
        if (_sourceIsEnvMilitary && {_targetIsEnvMilitary}) exitWith { 0 };

        if ((side group _effectiveSource) isEqualTo (side group _unit)) then {
            _incomingDamage * KFH_friendlyFireScale
        } else {
            _incomingDamage
        };
    }];

    _unit setVariable ["KFH_ffMitigationInstalled", true];
};

KFH_fnc_playUiCue = {
    params [
        ["_soundPath", "A3\Sounds_F\sfx\blip1.wss"],
        ["_volume", 1],
        ["_pitch", 1]
    ];

    playSoundUI [_soundPath, _volume, _pitch, true];
};

KFH_fnc_playZombieCue = {
    params [
        ["_source", objNull]
    ];

    if (isNull _source) exitWith {};
    if !(alive _source) exitWith {};

    private _soundClass = selectRandom [
        "KFH_HoloGroanAlarm",
        "KFH_HoloGroanPulse"
    ];

    _source say3D _soundClass;
};

KFH_fnc_localEnemyAttackAnim = {
    params [
        ["_unit", objNull]
    ];

    if (isNull _unit) exitWith {};

    _unit playActionNow KFH_meleeAttackAction;
};

KFH_fnc_localMeleeHitFeedback = {
    addCamShake KFH_meleeHitShake;
    playSoundUI ["A3\Sounds_F\sfx\blip1.wss", 1.2, 0.74, true];
};

KFH_fnc_localHologramHitFeedback = KFH_fnc_localMeleeHitFeedback;

KFH_fnc_updateMeleeDestination = {
    params ["_unit", "_target", "_distance"];

    if (isNull _unit || {isNull _target}) exitWith {};

    private _targetPos = getPosATL _target;
    private _approachPos = _target modelToWorld [0, -KFH_meleeStuckRepathOffset, 0];

    if (_distance <= (KFH_meleeAttackRange + 0.4)) then {
        _approachPos = _targetPos;
    };

    _unit enableAI "MOVE";
    _unit enableAI "PATH";
    _unit enableAI "TARGET";
    _unit enableAI "AUTOTARGET";
    _unit allowFleeing 0;
    _unit reveal [_target, 4];
    (group _unit) reveal [_target, 4];
    _unit doWatch _target;
    _unit stop false;
    _unit doMove _approachPos;

    if (time >= (_unit getVariable ["KFH_nextForcedDestinationAt", 0])) then {
        _unit setDestination [_approachPos, "LEADER PLANNED", true];
        _unit setVariable ["KFH_nextForcedDestinationAt", time + KFH_meleeForcedDestinationSeconds];
    };

    _unit setVariable ["KFH_lastMovePos", _targetPos];
};

KFH_fnc_applyPrototypeCarryCapacity = {
    params ["_unit"];

    if (isNull _unit) exitWith {};

    _unit setUnitTrait ["loadCoef", KFH_playerLoadCoef];
    _unit setUnitTrait ["Medic", true];
    _unit setUnitTrait ["Engineer", true];
    _unit forceWalk false;
    _unit setFatigue 0;

    if (missionNamespace getVariable ["KFH_playerDisableFatigue", true]) then {
        _unit enableFatigue false;
    };

    if (missionNamespace getVariable ["KFH_playerDisableStamina", true]) then {
        _unit enableStamina false;
    };

    private _animSpeed = missionNamespace getVariable ["KFH_playerAnimSpeedCoef", 1];
    if (_animSpeed > 0) then {
        _unit setAnimSpeedCoef _animSpeed;
    };
};

KFH_fnc_clientStaminaAssistLoop = {
    while { true } do {
        if (!isNull player && {alive player}) then {
            [player] call KFH_fnc_applyPrototypeCarryCapacity;
            player setFatigue ((getFatigue player) * KFH_playerFatigueKeepRatio);
        };

        sleep KFH_playerFatigueAssistSeconds;
    };
};

KFH_fnc_rotateOffset = {
    params ["_offset", "_dirDegrees"];

    private _xOffset = _offset select 0;
    private _yOffset = _offset select 1;
    private _zOffset = _offset select 2;
    private _dir = _dirDegrees * 0.0174533;
    private _rx = (_xOffset * cos _dir) - (_yOffset * sin _dir);
    private _ry = (_xOffset * sin _dir) + (_yOffset * cos _dir);

    [_rx, _ry, _zOffset]
};

KFH_fnc_worldFromMarkerOffset = {
    params ["_markerName", "_offset"];

    private _basePos = getMarkerPos _markerName;
    private _dir = markerDir _markerName;
    private _rotated = [_offset, _dir] call KFH_fnc_rotateOffset;

    [
        (_basePos select 0) + (_rotated select 0),
        (_basePos select 1) + (_rotated select 1),
        (_basePos select 2) + (_rotated select 2)
    ]
};

KFH_fnc_getSpawnSafetyAnchors = {
    private _anchors = [];

    {
        if (alive _x) then {
            _anchors pushBack [getPosATL _x, KFH_spawnMinPlayerDistance, name _x];
        };
    } forEach ([] call KFH_fnc_getHumanPlayers);

    private _respawnAnchor = missionNamespace getVariable ["KFH_respawnAnchorPos", []];
    if ((count _respawnAnchor) >= 2) then {
        _anchors pushBack [_respawnAnchor, KFH_spawnMinRespawnDistance, "respawn anchor"];
    };

    _anchors
};

KFH_fnc_isSpawnFarFromFriendlies = {
    params ["_candidatePos"];

    private _isFarEnough = true;
    {
        private _anchorPos = _x select 0;
        private _minDistance = _x select 1;

        if ((_candidatePos distance2D _anchorPos) < _minDistance) exitWith {
            _isFarEnough = false;
        };
    } forEach ([] call KFH_fnc_getSpawnSafetyAnchors);

    _isFarEnough
};

KFH_fnc_findSafeDistantSpawnPosition = {
    params [
        "_centerPos",
        ["_minDistance", KFH_spawnAheadMinDistance],
        ["_maxDistance", KFH_spawnAheadMaxDistance]
    ];

    private _fallbackPos = [];
    private _attempt = 0;
    private _foundOpen = false;

    while { _attempt < KFH_spawnAheadAttempts && {!_foundOpen} } do {
        _attempt = _attempt + 1;
        private _seed = _centerPos getPos [_minDistance + random (_maxDistance - _minDistance), random 360];
        private _candidate = [_seed, 0, KFH_spawnAheadSafeRadius, 2, 0, 0.35, 0] call BIS_fnc_findSafePos;

        if ((count _candidate) < 3) then {
            _candidate set [2, 0];
        };

        if (
            !((_candidate select 0) isEqualTo 0 && {(_candidate select 1) isEqualTo 0}) &&
            {(_candidate distance2D _centerPos) >= _minDistance} &&
            {[_candidate, objNull] call KFH_fnc_isSpawnCandidateOpen}
        ) then {
            _fallbackPos = +_candidate;
            _foundOpen = true;
        };
    };

    _fallbackPos
};

KFH_fnc_isSpawnCandidateOpen = {
    params ["_candidatePos", "_target"];

    if ((count _candidatePos) < 2) exitWith { false };
    if (surfaceIsWater _candidatePos) exitWith { false };

    private _posATL = [
        _candidatePos select 0,
        _candidatePos select 1,
        if ((count _candidatePos) > 2) then { _candidatePos select 2 } else { 0 }
    ];
    if !([_posATL] call KFH_fnc_isSpawnFarFromFriendlies) exitWith { false };

    private _nearBlockers = nearestObjects [_posATL, ["House", "Building", "Wall", "Fence"], KFH_spawnAheadBlockerRadius];
    private _nearTerrainBlockers = nearestTerrainObjects [
        _posATL,
        ["BUILDING", "HOUSE", "ROCK", "BUNKER", "FORTRESS"],
        KFH_spawnAheadBlockerRadius,
        false,
        true
    ];

    if ((count _nearBlockers) > 0) exitWith { false };
    if ((count _nearTerrainBlockers) > 0) exitWith { false };
    if (isNull _target) exitWith { true };

    private _targetEye = eyePos _target;
    private _candidateEye = AGLToASL [
        _posATL select 0,
        _posATL select 1,
        (_posATL select 2) + 1.2
    ];
    private _intersections = lineIntersectsSurfaces [
        _targetEye,
        _candidateEye,
        _target,
        objNull,
        true,
        1,
        "GEOM",
        "NONE"
    ];

    (count _intersections) isEqualTo 0
};

KFH_fnc_findForwardSpawnPosition = {
    params ["_centerPos"];

    private _targets = [] call KFH_fnc_getCombatReadyHumans;
    if ((count _targets) isEqualTo 0) then {
        _targets = ([] call KFH_fnc_getHumanPlayers) select { alive _x };
    };

    if ((count _targets) isEqualTo 0) exitWith {
        [_centerPos, KFH_spawnAheadMinDistance, KFH_spawnAheadMaxDistance] call KFH_fnc_findSafeDistantSpawnPosition
    };

    private _target = selectRandom _targets;
    private _direction = if ((_target distance2D _centerPos) > 12) then {
        [_target, _centerPos] call BIS_fnc_dirTo
    } else {
        getDir _target
    };
    private _fallbackPos = [];

    private _attempt = 0;
    private _foundOpen = false;
    while { _attempt < KFH_spawnAheadAttempts && {!_foundOpen} } do {
        _attempt = _attempt + 1;
        private _distance = KFH_spawnAheadMinDistance + random (KFH_spawnAheadMaxDistance - KFH_spawnAheadMinDistance);
        private _coneOffset = (random (KFH_spawnAheadConeDegrees * 2)) - KFH_spawnAheadConeDegrees;
        private _candidateSeed = (getPosATL _target) getPos [_distance, _direction + _coneOffset];
        private _candidate = [_candidateSeed, 0, KFH_spawnAheadSafeRadius, 2, 0, 0.35, 0] call BIS_fnc_findSafePos;

        if ((count _candidate) < 3) then {
            _candidate set [2, 0];
        };

        if (
            !((_candidate select 0) isEqualTo 0 && {(_candidate select 1) isEqualTo 0}) &&
            {(_candidate distance2D _target) >= KFH_spawnAheadMinDistance}
        ) then {
            if ((count _fallbackPos) isEqualTo 0) then {
                _fallbackPos = +_candidate;
            };

            if ([_candidate, _target] call KFH_fnc_isSpawnCandidateOpen) then {
                _fallbackPos = +_candidate;
                _foundOpen = true;
            };
        };
    };

    if ((count _fallbackPos) > 0) exitWith { _fallbackPos };

    [format [
        "Forward spawn failed near %1. Falling back to objective safe position.",
        mapGridPosition _centerPos
    ]] call KFH_fnc_log;
    [_centerPos, KFH_spawnAheadMinDistance, KFH_spawnAheadMaxDistance + 45] call KFH_fnc_findSafeDistantSpawnPosition
};

KFH_fnc_notifyAll = {
    params ["_message"];
    [format ["[KFH] %1", _message]] remoteExecCall ["systemChat", 0];
    [format ["Broadcast: %1", _message]] call KFH_fnc_log;
};

KFH_fnc_buildCheckpointEventPlan = {
    params ["_checkpointMarkers"];

    private _plan = [];
    private _pool = +KFH_checkpointEventPool;

    if ((count _pool) isEqualTo 0) exitWith { [] };

    _pool = [_pool] call BIS_fnc_arrayShuffle;

    for "_i" from 0 to ((count _checkpointMarkers) - 1) do {
        if ((count _pool) isEqualTo 0) then {
            _pool = [+KFH_checkpointEventPool] call BIS_fnc_arrayShuffle;
        };

        _plan pushBack (_pool deleteAt 0);
    };

    _plan
};

KFH_fnc_getCheckpointEventId = {
    params ["_checkpointIndex"];

    private _plan = missionNamespace getVariable ["KFH_checkpointEventPlan", []];
    private _arrayIndex = (_checkpointIndex - 1) max 0;

    if (_arrayIndex >= (count _plan)) exitWith { "surge" };

    _plan select _arrayIndex
};

KFH_fnc_getCheckpointEventName = {
    params ["_checkpointIndex"];

    switch ([_checkpointIndex] call KFH_fnc_getCheckpointEventId) do {
        case "resupply": { "Forward Resupply" };
        case "hunter": { "Signal Hunt" };
        default { "Hive Surge" };
    }
};

KFH_fnc_getCheckpointEventSummary = {
    params ["_checkpointIndex"];

    switch ([_checkpointIndex] call KFH_fnc_getCheckpointEventId) do {
        case "resupply": { "補給隊が近いデス。secure 後の supply 到着が早いデス。" };
        case "hunter": { "強化 signal carrier が追加で出るデス。倒すと装備が伸びるデス。" };
        default { "巣が活性化してるデス。接触時に追加ラッシュが入りやすいデス。" };
    }
};

KFH_fnc_getCheckpointValue = {
    params ["_checkpointIndex"];

    switch ([_checkpointIndex] call KFH_fnc_getCheckpointEventId) do {
        case "resupply": { 3 };
        case "hunter": { 2 };
        default { 2 };
    }
};

KFH_fnc_getCheckpointValueLabel = {
    params ["_checkpointIndex"];

    switch ([_checkpointIndex] call KFH_fnc_getCheckpointValue) do {
        case 3: { "HIGH" };
        case 2: { "MED" };
        default { "LOW" };
    }
};

KFH_fnc_getCheckpointSupplyDelay = {
    params ["_checkpointIndex"];

    switch ([_checkpointIndex] call KFH_fnc_getCheckpointEventId) do {
        case "resupply": { KFH_checkpointEventResupplyDelay };
        case "hunter": { KFH_checkpointEventHunterDelay };
        default { KFH_checkpointEventSurgeDelay };
    }
};

KFH_fnc_getSupplyLineSummary = {
    private _checkpointMarkers = missionNamespace getVariable ["KFH_checkpointMarkers", []];
    private _securedStates = missionNamespace getVariable ["KFH_checkpointSecuredStates", []];
    private _supplyStates = missionNamespace getVariable ["KFH_checkpointSupplyStates", []];
    private _total = count _checkpointMarkers;
    private _secured = { _x } count _securedStates;
    private _supplied = { _x } count _supplyStates;
    private _danger = (_secured - _supplied) max 0;

    [_secured, _supplied, _total, _danger]
};

KFH_fnc_getReturnDangerLabel = {
    params ["_danger"];

    switch (true) do {
        case (_danger <= 0): { "LOW" };
        case (_danger isEqualTo 1): { "MED" };
        default { "HIGH" };
    }
};

KFH_fnc_refreshStrategicState = {
    private _phase = missionNamespace getVariable ["KFH_phase", "boot"];
    private _currentCheckpoint = missionNamespace getVariable ["KFH_currentCheckpoint", 0];
    private _summary = [] call KFH_fnc_getSupplyLineSummary;
    private _secured = _summary select 0;
    private _supplied = _summary select 1;
    private _total = _summary select 2;
    private _danger = _summary select 3;
    private _eventName = if (_phase isEqualTo "assault") then {
        [_currentCheckpoint] call KFH_fnc_getCheckpointEventName
    } else {
        "Return Run"
    };
    private _valueLabel = if (_phase isEqualTo "assault") then {
        [_currentCheckpoint] call KFH_fnc_getCheckpointValueLabel
    } else {
        "LOCKED"
    };

    ["KFH_supplyLineSecured", _secured] call KFH_fnc_setState;
    ["KFH_supplyLineOnline", _supplied] call KFH_fnc_setState;
    ["KFH_supplyLineTotal", _total] call KFH_fnc_setState;
    ["KFH_supplyLineStatus", format ["%1/%2 ONLINE", _supplied, _total]] call KFH_fnc_setState;
    ["KFH_currentCheckpointEvent", _eventName] call KFH_fnc_setState;
    ["KFH_currentCheckpointValue", _valueLabel] call KFH_fnc_setState;
    ["KFH_returnDanger", _danger] call KFH_fnc_setState;
    ["KFH_returnDangerLabel", [_danger] call KFH_fnc_getReturnDangerLabel] call KFH_fnc_setState;
};

KFH_fnc_applyExtractDangerProfile = {
    private _summary = [] call KFH_fnc_getSupplyLineSummary;
    private _danger = _summary select 3;
    private _tickSeconds = (KFH_extractPressureTickSeconds - (_danger * KFH_extractDangerTickPenalty)) max 16;
    private _reinforceSeconds = (KFH_extractReinforceSeconds - (_danger * KFH_extractDangerReinforcePenalty)) max 25;
    private _reinforcePressure = KFH_extractReinforcePressure + (_danger * KFH_extractDangerPressureBonus);
    private _waveBaseCount = KFH_extractBaseWaveCount + (_danger * KFH_extractDangerWaveStep);

    missionNamespace setVariable ["KFH_extractPressureTickCurrent", _tickSeconds];
    missionNamespace setVariable ["KFH_extractReinforceSecondsCurrent", _reinforceSeconds];
    missionNamespace setVariable ["KFH_extractReinforcePressureCurrent", _reinforcePressure];
    missionNamespace setVariable ["KFH_extractWaveBaseCount", _waveBaseCount];
    [] call KFH_fnc_refreshStrategicState;

    [format [
        "Return route profile locked. Supply line %1/%2 online. Return danger %3.",
        _summary select 1,
        _summary select 2,
        [_danger] call KFH_fnc_getReturnDangerLabel
    ]] call KFH_fnc_notifyAll;
};

KFH_fnc_appendSupportObject = {
    params ["_object"];

    if (isNull _object) exitWith {};

    private _supportObjects = missionNamespace getVariable ["KFH_supportObjects", []];
    _supportObjects pushBack _object;
    missionNamespace setVariable ["KFH_supportObjects", _supportObjects, true];
};

KFH_fnc_spawnSupportObject = {
    params ["_className", "_markerName", "_offset", ["_dirOffset", 0], ["_allowDamage", false]];

    private _spawnPos = [_markerName, _offset] call KFH_fnc_worldFromMarkerOffset;
    private _dir = markerDir _markerName + _dirOffset;
    private _object = createVehicle [_className, _spawnPos, [], 0, "CAN_COLLIDE"];

    _object setDir _dir;
    _object setPosATL _spawnPos;
    _object allowDamage _allowDamage;

    _object
};

KFH_fnc_setMissionDateStage = {
    params ["_dateValue", ["_label", ""]];

    if ((count _dateValue) < 5) exitWith {};

    setDate _dateValue;
    if !(_label isEqualTo "") then {
        [format ["Time shift: %1", _label], "TIME"] call KFH_fnc_appendRunEvent;
        [format ["Radio update: %1", _label]] call KFH_fnc_log;
    };
};

KFH_fnc_getCheckpointDateStage = {
    params ["_checkpointIndex"];

    private _stages = missionNamespace getVariable ["KFH_outbreakCheckpointDates", KFH_outbreakCheckpointDates];
    if ((count _stages) isEqualTo 0) exitWith { KFH_outbreakTwilightDate };

    private _stageIndex = ((_checkpointIndex - 1) max 0) min ((count _stages) - 1);
    _stages select _stageIndex
};

KFH_fnc_applyCheckpointTimeProgression = {
    params ["_checkpointIndex"];

    private _lastApplied = missionNamespace getVariable ["KFH_lastCheckpointTimeStage", 0];
    if (_checkpointIndex <= _lastApplied) exitWith {};

    missionNamespace setVariable ["KFH_lastCheckpointTimeStage", _checkpointIndex, true];

    private _dateStage = [_checkpointIndex] call KFH_fnc_getCheckpointDateStage;
    private _label = format [
        "Checkpoint %1 secured. The sun keeps dropping; lights and optics matter more now.",
        _checkpointIndex
    ];

    [_dateStage, _label] call KFH_fnc_setMissionDateStage;
};

KFH_fnc_setStoryObjective = {
    params ["_label"];

    ["KFH_storyObjective", _label] call KFH_fnc_setState;
};

KFH_fnc_updateRouteMarkerVisibility = {
    private _checkpointMarkers = missionNamespace getVariable ["KFH_checkpointMarkers", []];
    private _current = missionNamespace getVariable ["KFH_currentCheckpoint", 1];
    private _phase = missionNamespace getVariable ["KFH_phase", "boot"];
    private _hiddenAlpha = missionNamespace getVariable ["KFH_routeMarkerHiddenAlpha", 0];
    private _securedAlpha = missionNamespace getVariable ["KFH_routeMarkerSecuredAlpha", 0.45];
    private _currentAlpha = missionNamespace getVariable ["KFH_routeMarkerCurrentAlpha", 1];
    private _lookAhead = missionNamespace getVariable ["KFH_routeMarkerRevealLookAhead", 0];

    if ("kfh_start" in allMapMarkers) then {
        "kfh_start" setMarkerAlpha 1;
    };

    {
        private _index = _forEachIndex + 1;
        private _alpha = _hiddenAlpha;

        if (_index < _current) then {
            _alpha = _securedAlpha;
        };
        if (_index >= _current && {_index <= (_current + _lookAhead)}) then {
            _alpha = _currentAlpha;
        };
        if (_phase isEqualTo "extract") then {
            _alpha = _securedAlpha;
        };

        if (_x in allMapMarkers) then {
            _x setMarkerAlpha _alpha;
        };
    } forEach _checkpointMarkers;

    if ("kfh_extract" in allMapMarkers) then {
        private _extractAlpha = if (_phase isEqualTo "extract") then { 1 } else { _hiddenAlpha };
        "kfh_extract" setMarkerAlpha _extractAlpha;
    };

    private _optionalBaseMarker = missionNamespace getVariable ["KFH_optionalBaseActiveMarker", ""];
    if (!(_optionalBaseMarker isEqualTo "") && {_optionalBaseMarker in allMapMarkers}) then {
        _optionalBaseMarker setMarkerAlpha 1;
    };

    {
        _x setMarkerAlpha (if (missionNamespace getVariable ["KFH_routeShowSpawnMarkers", false]) then { 0.55 } else { _hiddenAlpha });
    } forEach (allMapMarkers select { (_x find "kfh_spawn_") isEqualTo 0 });
};

KFH_fnc_placePlayerAtDynamicStartOnce = {
    if !(missionNamespace getVariable ["KFH_dynamicRouteEnabled", false]) exitWith {};
    if (player getVariable ["KFH_dynamicStartPlaced", false]) exitWith {};
    if !("kfh_start" in allMapMarkers) exitWith {};

    private _startPos = getMarkerPos "kfh_start";
    if ((_startPos distance2D [0, 0, 0]) < 100) exitWith {};

    private _players = allPlayers select { isPlayer _x };
    private _index = (_players find player) max 0;
    private _angle = (markerDir "kfh_start") + 180 + ((_index mod 6) * 24);
    private _radius = 3 + (floor (_index / 6)) * 2;
    private _targetPos = [
        (_startPos select 0) + (sin _angle) * _radius,
        (_startPos select 1) + (cos _angle) * _radius,
        0
    ];

    player setDir (markerDir "kfh_start");
    player setPosATL _targetPos;
    player setVariable ["KFH_dynamicStartPlaced", true, true];
    [format ["Patrol start synced to dynamic route: %1", mapGridPosition _startPos]] call KFH_fnc_log;
};

KFH_fnc_spawnOutbreakObject = {
    params [
        "_className",
        "_markerName",
        "_offset",
        ["_dirOffset", 0],
        ["_damage", 0],
        ["_allowDamage", false]
    ];

    if !(isClass (configFile >> "CfgVehicles" >> _className)) exitWith {
        [format ["Skipped outbreak dressing object with missing class: %1", _className]] call KFH_fnc_log;
        objNull
    };

    private _object = [_className, _markerName, _offset, _dirOffset, _allowDamage] call KFH_fnc_spawnSupportObject;
    _object setDamage _damage;

    if (_object isKindOf "LandVehicle") then {
        private _fuelMin = missionNamespace getVariable ["KFH_outbreakAbandonedVehicleFuelMin", 0.01];
        private _fuelMax = missionNamespace getVariable ["KFH_outbreakAbandonedVehicleFuelMax", 0.09];
        _object setFuel (_fuelMin + random ((_fuelMax - _fuelMin) max 0.01));
        _object lock 0;
        _object setVariable ["KFH_supportLabel", "Abandoned Low-fuel Vehicle", true];
        [_object] call KFH_fnc_installVehicleThreatHandlers;
    };

    [_object] call KFH_fnc_appendSupportObject;

    _object
};

KFH_fnc_spawnOutbreakDressingSet = {
    params ["_markerName", "_entries"];

    private _spawned = [];
    {
        _x params ["_className", "_offset", ["_dirOffset", 0], ["_damage", 0], ["_allowDamage", false]];
        private _object = [_className, _markerName, _offset, _dirOffset, _damage, _allowDamage] call KFH_fnc_spawnOutbreakObject;
        if !(isNull _object) then {
            _spawned pushBack _object;
        };
    } forEach _entries;

    _spawned
};

KFH_fnc_spawnCheckpointMobilityVehicles = {
    params ["_markerName", "_checkpointIndex"];

    if !(missionNamespace getVariable ["KFH_checkpointMobilityVehiclesEnabled", true]) exitWith { [] };

    private _classes = [
        missionNamespace getVariable ["KFH_checkpointMobilityVehicleClasses", []],
        missionNamespace getVariable ["KFH_cupCheckpointMobilityVehicleClasses", []],
        missionNamespace getVariable ["KFH_cupVehiclePreferredChance", 0.9]
    ] call KFH_fnc_selectExistingWithOptionalPriority;
    if (_classes isEqualTo "") exitWith { [] };

    private _scale = ([] call KFH_fnc_getScalingPlayerCount) max 1;
    private _scaleCounts = missionNamespace getVariable ["KFH_checkpointMobilityVehicleCountByScale", []];
    private _count = if ((count _scaleCounts) > 0) then {
        _scaleCounts select ((_scale - 1) min ((count _scaleCounts) - 1))
    } else {
        missionNamespace getVariable ["KFH_checkpointMobilityVehicleCount", 2]
    };
    if (_checkpointIndex >= (missionNamespace getVariable ["KFH_envTrafficMilitaryStartCheckpoint", 3])) then {
        _count = _count min (missionNamespace getVariable ["KFH_checkpointMobilityVehicleLateMax", 1]);
    };
    private _offsets = missionNamespace getVariable ["KFH_checkpointMobilityVehicleOffsets", []];
    private _fuelMin = missionNamespace getVariable ["KFH_checkpointMobilityVehicleFuelMin", 0.18];
    private _fuelMax = missionNamespace getVariable ["KFH_checkpointMobilityVehicleFuelMax", 0.24];
    private _spawned = [];

    for "_i" from 0 to ((_count - 1) max 0) do {
        private _entry = if (_i < (count _offsets)) then {
            _offsets select _i
        } else {
            [(-10 + (_i * 10)), -8, 0, 0]
        };
        _entry params [["_rightOffset", 0], ["_forwardOffset", 0], ["_heightOffset", 0], ["_dirOffset", 0]];
        private _className = [
            missionNamespace getVariable ["KFH_checkpointMobilityVehicleClasses", []],
            missionNamespace getVariable ["KFH_cupCheckpointMobilityVehicleClasses", []],
            missionNamespace getVariable ["KFH_cupVehiclePreferredChance", 0.9]
        ] call KFH_fnc_selectExistingWithOptionalPriority;

        if !(_className isEqualTo "") then {
            private _object = [_className, _markerName, [_rightOffset, _forwardOffset, _heightOffset], _dirOffset, 0, true] call KFH_fnc_spawnOutbreakObject;
            if !(isNull _object) then {
                _object setFuel (_fuelMin + random ((_fuelMax - _fuelMin) max 0.01));
                _object setDamage 0;
                _object lock 0;
                _object setVariable ["KFH_supportLabel", format ["Checkpoint %1 Low-fuel Patrol Buggy", _checkpointIndex], true];
                _spawned pushBack _object;
            };
        };
    };

    if ((count _spawned) > 0) then {
        [format ["Checkpoint %1 mobility vehicles spawned: %2.", _checkpointIndex, count _spawned]] call KFH_fnc_log;
    };
    _spawned
};

KFH_fnc_spawnOutbreakCiviliansAtMarker = {
    params ["_markerName", ["_count", 1]];

    if !(missionNamespace getVariable ["KFH_outbreakCivilianEnabled", true]) exitWith { [] };
    if ((random 1) > (missionNamespace getVariable ["KFH_outbreakCivilianChance", 0.65])) exitWith { [] };

    private _classes = missionNamespace getVariable ["KFH_outbreakCivilianClasses", []];
    if ((count _classes) isEqualTo 0) exitWith { [] };

    private _moves = missionNamespace getVariable ["KFH_outbreakCivilianPanicMoves", []];
    private _maxCount = missionNamespace getVariable ["KFH_outbreakCivilianMaxPerNode", 3];
    private _actualCount = (_count max 1) min _maxCount;
    private _spawned = [];

    for "_i" from 1 to _actualCount do {
        private _groupRef = createGroup [civilian, true];
        private _className = selectRandom _classes;
        if (isClass (configFile >> "CfgVehicles" >> _className)) then {
            private _angle = markerDir _markerName + 90 + random 180;
            private _distance = 8 + random 18;
            private _basePos = getMarkerPos _markerName;
            private _pos = [
                (_basePos select 0) + (sin _angle) * _distance,
                (_basePos select 1) + (cos _angle) * _distance,
                0
            ];

            if (!surfaceIsWater _pos && {[_pos, objNull] call KFH_fnc_isSpawnCandidateOpen}) then {
                private _unit = _groupRef createUnit [_className, _pos, [], 0, "FORM"];
                _unit setDir (random 360);
                _unit allowFleeing 1;
                _unit setBehaviour "CARELESS";
                _unit setCombatMode "BLUE";
                _unit setSpeedMode "LIMITED";
                _unit disableAI "AUTOCOMBAT";
                _unit disableAI "TARGET";
                _unit disableAI "AUTOTARGET";
                _unit setVariable ["KFH_outbreakCivilian", true, true];
                [_unit] call KFH_fnc_installCivilianPenaltyHandlers;
                if ((count _moves) > 0) then {
                    _unit switchMove (selectRandom _moves);
                };
                _spawned pushBack _unit;
            } else {
                deleteGroup _groupRef;
            };
        } else {
            deleteGroup _groupRef;
        };
    };

    if ((count _spawned) > 0) then {
        private _all = missionNamespace getVariable ["KFH_outbreakCivilians", []];
        _all append _spawned;
        missionNamespace setVariable ["KFH_outbreakCivilians", _all, true];
    };

    _spawned
};

KFH_fnc_getHumanReferenceUnits = {
    private _humans = [] call KFH_fnc_getHumanPlayers;
    if ((count _humans) isEqualTo 0) then {
        _humans = allPlayers;
    };

    _humans select { alive _x }
};

KFH_fnc_getNearestHumanDistance = {
    params ["_origin"];

    private _humans = [] call KFH_fnc_getHumanReferenceUnits;
    if ((count _humans) isEqualTo 0) exitWith { 1e10 };

    private _nearest = 1e10;
    {
        private _distance = _origin distance2D _x;
        if (_distance < _nearest) then {
            _nearest = _distance;
        };
    } forEach _humans;

    _nearest
};

KFH_fnc_getRandomRoadSegmentAroundHumans = {
    params [
        ["_minDistance", 550],
        ["_maxDistance", 1250],
        ["_activeGroups", []]
    ];

    private _humans = [] call KFH_fnc_getHumanReferenceUnits;
    if ((count _humans) isEqualTo 0) exitWith { objNull };

    private _distanceRange = (_maxDistance - _minDistance) max 1;
    private _result = objNull;
    private _tries = 0;

    while { isNull _result && {_tries < 10} } do {
        _tries = _tries + 1;
        private _refUnit = vehicle (selectRandom _humans);
        private _refPos = getPosATL _refUnit;
        private _dir = random 360;
        private _probe = [
            (_refPos select 0) + (_minDistance + random _distanceRange) * sin _dir,
            (_refPos select 1) + (_minDistance + random _distanceRange) * cos _dir,
            0
        ];
        private _roads = _probe nearRoads _distanceRange;
        _roads = _roads select {
            private _roadSegment = _x;
            private _nearVehicles = _roadSegment nearEntities [["Car", "Motorcycle", "Tank"], 70];
            !surfaceIsWater (getPosATL _roadSegment) &&
            { (count (roadsConnectedTo _roadSegment)) > 0 } &&
            { ((count (_nearVehicles select { alive _x && {speed _x > 4} })) isEqualTo 0) }
        };

        if ((count _roads) > 0) then {
            private _candidate = selectRandom _roads;
            private _candidatePos = getPosATL _candidate;
            private _tooCloseToPlayers = false;
            private _tooFarFromAll = true;
            {
                private _distance = (vehicle _x) distance2D _candidatePos;
                if (_distance < _minDistance) then { _tooCloseToPlayers = true; };
                if (_distance <= _maxDistance) then { _tooFarFromAll = false; };
            } forEach _humans;

            private _tooCloseToTraffic = false;
            {
                private _leader = leader _x;
                if (!isNull _leader && {(_leader distance2D _candidatePos) < 120}) then {
                    _tooCloseToTraffic = true;
                };
            } forEach _activeGroups;

            if (!_tooCloseToPlayers && {!_tooFarFromAll} && {!_tooCloseToTraffic}) then {
                _result = _candidate;
            };
        };
    };

    _result
};

KFH_fnc_getRoadDestination = {
    params ["_fromPos", ["_distance", 2600], ["_mode", "random"]];

    private _roads = [];
    private _tries = 0;
    while { (count _roads) isEqualTo 0 && {_tries < 8} } do {
        _tries = _tries + 1;
        private _dir = random 360;
        if (_mode isEqualTo "approach") then {
            private _humans = [] call KFH_fnc_getHumanReferenceUnits;
            private _center = [0, 0, 0];
            if ((count _humans) > 0) then {
                {
                    private _pos = getPosATL (vehicle _x);
                    _center set [0, (_center select 0) + (_pos select 0)];
                    _center set [1, (_center select 1) + (_pos select 1)];
                } forEach _humans;
                _center set [0, (_center select 0) / (count _humans)];
                _center set [1, (_center select 1) / (count _humans)];
                _dir = (_fromPos getDir _center) + ((random ((missionNamespace getVariable ["KFH_envTrafficOncomingDirJitter", 32]) * 2)) - (missionNamespace getVariable ["KFH_envTrafficOncomingDirJitter", 32]));
            };
        };
        private _probe = [
            (_fromPos select 0) + _distance * sin _dir,
            (_fromPos select 1) + _distance * cos _dir,
            0
        ];
        _roads = (_probe nearRoads 650) select { !surfaceIsWater (getPosATL _x) };
    };

    if ((count _roads) isEqualTo 0) exitWith { _fromPos };
    getPosATL (selectRandom _roads)
};

KFH_fnc_assignEnvTrafficWaypoint = {
    params [
        "_groupRef",
        ["_speed", "NORMAL"],
        ["_behaviour", "CARELESS"],
        ["_distance", 1400],
        ["_mode", "random"]
    ];

    if (isNull _groupRef || {(count units _groupRef) isEqualTo 0}) exitWith {};

    private _leader = leader _groupRef;
    if (isNull _leader) exitWith {};

    private _destinationPos = [getPosATL _leader, _distance, _mode] call KFH_fnc_getRoadDestination;
    private _vehicle = vehicle _leader;
    if (_vehicle isNotEqualTo _leader) then {
        _vehicle setDir ((getPosATL _vehicle) getDir _destinationPos);
    };
    private _wp = _groupRef addWaypoint [_destinationPos, 0];
    _wp setWaypointType "MOVE";
    _wp setWaypointSpeed _speed;
    _wp setWaypointBehaviour _behaviour;
    _wp setWaypointCompletionRadius 35;
    _wp setWaypointStatements ["true", "[group this] spawn KFH_fnc_retaskEnvTrafficGroup;"];
};

KFH_fnc_retaskEnvTrafficGroup = {
    params ["_groupRef"];

    if (!isServer || {isNull _groupRef}) exitWith {};
    sleep (4 + random 8);
    if (isNull _groupRef || {(count units _groupRef) isEqualTo 0}) exitWith {};

    private _role = _groupRef getVariable ["KFH_envRole", "civilianTraffic"];
    private _speed = if (_role in ["militaryTraffic", "militaryScene", "militaryFootPatrol", "militaryCheckpoint"]) then { "NORMAL" } else { "LIMITED" };
    private _behaviour = if (_role in ["militaryTraffic", "militaryScene", "militaryFootPatrol", "militaryCheckpoint"]) then { "AWARE" } else { "CARELESS" };
    [_groupRef, _speed, _behaviour, missionNamespace getVariable ["KFH_envTrafficDestinationDistance", 1400], "random"] call KFH_fnc_assignEnvTrafficWaypoint;
};

KFH_fnc_getEnvGroupCounts = {
    private _groups = missionNamespace getVariable ["KFH_envTrafficGroups", []];
    private _civilianPedestrians = 0;
    private _civilianVehicles = 0;
    private _military = 0;

    {
        if (!isNull _x && {(count units _x) > 0}) then {
            private _role = _x getVariable ["KFH_envRole", ""];
            switch (_role) do {
                case "civilianPedestrian": { _civilianPedestrians = _civilianPedestrians + 1; };
                case "civilianTraffic": { _civilianVehicles = _civilianVehicles + 1; };
                case "civilianSceneVehicle": { _civilianVehicles = _civilianVehicles + 1; };
                case "militaryTraffic": { _military = _military + 1; };
                case "militaryScene": { _military = _military + 1; };
                case "militaryFootPatrol": { _military = _military + 1; };
                case "militaryCheckpoint": { _military = _military + 1; };
            };
        };
    } forEach _groups;

    [_civilianPedestrians, _civilianVehicles, _military]
};

KFH_fnc_registerEnvGroup = {
    params ["_groupRef", ["_role", "civilianTraffic"], ["_vehicles", []], ["_objects", []]];

    if (isNull _groupRef) exitWith {};
    _groupRef setVariable ["KFH_envRole", _role];
    _groupRef setVariable ["KFH_envObjects", _objects];
    {
        _x setVariable ["KFH_envTrafficCrew", true, true];
    } forEach units _groupRef;

    private _groups = missionNamespace getVariable ["KFH_envTrafficGroups", []];
    _groups pushBackUnique _groupRef;
    missionNamespace setVariable ["KFH_envTrafficGroups", _groups];

    if ((count _vehicles) > 0) then {
        private _traffic = missionNamespace getVariable ["KFH_ambientTrafficVehicles", []];
        {
            if (!isNull _x) then {
                _traffic pushBackUnique _x;
            };
        } forEach _vehicles;
        missionNamespace setVariable ["KFH_ambientTrafficVehicles", _traffic, true];
    };
};

KFH_fnc_addCivilianTrafficCargo = {
    params ["_vehicle"];

    if (isNull _vehicle) exitWith {};
    clearItemCargoGlobal _vehicle;
    clearWeaponCargoGlobal _vehicle;
    clearMagazineCargoGlobal _vehicle;

    if ((random 1) > (missionNamespace getVariable ["KFH_envTrafficCivilianCargoChance", 0.45])) exitWith {};

    private _items = missionNamespace getVariable ["KFH_envTrafficCivilianCargoItems", []];
    {
        _x params ["_className", ["_kind", "item"], ["_count", 1]];
        if (_kind isEqualTo "magazine") then {
            _vehicle addMagazineCargoGlobal [_className, _count];
        } else {
            _vehicle addItemCargoGlobal [_className, _count];
        };
    } forEach _items;
};

KFH_fnc_isOptionalContentClass = {
    params [["_className", ""]];

    private _lowerClass = toLowerANSI _className;
    private _prefixes = missionNamespace getVariable [
        "KFH_optionalContentClassPrefixes",
        ["rhs_", "rhsusf_", "rhsgref_", "rhssaf_", "gm_", "cis_"]
    ];

    (_prefixes findIf { (_lowerClass find (toLowerANSI _x)) isEqualTo 0 }) >= 0
};

KFH_fnc_filterExistingVehicleClasses = {
    params [["_classes", []], ["_optionalClasses", []]];

    private _pool = _classes select { isClass (configFile >> "CfgVehicles" >> _x) };
    private _optional = [];
    if (missionNamespace getVariable ["KFH_cupOptionalEnabled", true]) then {
        _optional = _optionalClasses select { isClass (configFile >> "CfgVehicles" >> _x) };
        if ((missionNamespace getVariable ["KFH_cupBanVanillaWhenAvailable", true]) && {(count _optional) > 0}) exitWith {
            _optional
        };
        _pool append _optional;
    };

    if ((count _pool) isEqualTo 0) exitWith { _classes select { isClass (configFile >> "CfgVehicles" >> _x) } };
    _pool
};

KFH_fnc_filterExistingWeaponBundles = {
    params [["_bundles", []]];

    _bundles select {
        (count _x) >= 2 &&
        {isClass (configFile >> "CfgWeapons" >> (_x select 0))} &&
        {isClass (configFile >> "CfgMagazines" >> (_x select 1))}
    }
};

KFH_fnc_selectExistingWithOptionalPriority = {
    params [["_vanillaClasses", []], ["_optionalClasses", []], ["_optionalChance", 0.75]];

    private _vanilla = _vanillaClasses select { isClass (configFile >> "CfgVehicles" >> _x) };
    private _optional = if (missionNamespace getVariable ["KFH_cupOptionalEnabled", true]) then {
        _optionalClasses select { isClass (configFile >> "CfgVehicles" >> _x) }
    } else {
        []
    };

    if ((missionNamespace getVariable ["KFH_cupBanVanillaWhenAvailable", true]) && {(count _optional) > 0}) exitWith {
        selectRandom _optional
    };
    if ((count _optional) > 0 && {((count _vanilla) isEqualTo 0) || {(random 1) < _optionalChance}}) exitWith {
        selectRandom _optional
    };
    if ((count _vanilla) > 0) exitWith { selectRandom _vanilla };
    if ((count _optional) > 0) exitWith { selectRandom _optional };
    ""
};

KFH_fnc_selectMilitaryVehicleClass = {
    private _armedChance = missionNamespace getVariable ["KFH_envTrafficMilitaryArmedChance", 0.7];
    private _armorShare = missionNamespace getVariable ["KFH_envTrafficMilitaryArmorShare", 0.4];
    private _mortarShare = missionNamespace getVariable ["KFH_envTrafficMilitaryMortarShare", 0.16];
    private _cupChance = missionNamespace getVariable ["KFH_cupVehiclePreferredChance", 0.78];
    private _cupArmorChance = missionNamespace getVariable ["KFH_cupArmorVehiclePreferredChance", _cupChance];
    private _roll = random 1;
    private _category = if (_roll < _armedChance) then {
        if ((random 1) < _armorShare) then {
            if ((random 1) < _mortarShare) then { "mortar" } else { "armor" }
        } else {
            "armedLight"
        }
    } else {
        "transport"
    };

    private _selected = switch (_category) do {
        case "mortar": {
            [
                missionNamespace getVariable ["KFH_envTrafficMilitaryMortarVehicleClasses", []],
                missionNamespace getVariable ["KFH_cupEnvTrafficMilitaryMortarVehicleClasses", []],
                _cupArmorChance
            ] call KFH_fnc_selectExistingWithOptionalPriority
        };
        case "armor": {
            [
                missionNamespace getVariable ["KFH_envTrafficMilitaryArmorVehicleClasses", []],
                missionNamespace getVariable ["KFH_cupEnvTrafficMilitaryArmorVehicleClasses", []],
                _cupArmorChance
            ] call KFH_fnc_selectExistingWithOptionalPriority
        };
        case "armedLight": {
            [
                missionNamespace getVariable ["KFH_envTrafficMilitaryArmedLightVehicleClasses", []],
                missionNamespace getVariable ["KFH_cupEnvTrafficMilitaryArmedLightVehicleClasses", []],
                _cupChance
            ] call KFH_fnc_selectExistingWithOptionalPriority
        };
        default {
            [
                missionNamespace getVariable ["KFH_envTrafficMilitaryTransportVehicleClasses", []],
                missionNamespace getVariable ["KFH_cupEnvTrafficMilitaryTransportVehicleClasses", []],
                _cupChance
            ] call KFH_fnc_selectExistingWithOptionalPriority
        };
    };

    if !(_selected isEqualTo "") exitWith { _selected };

    [
        missionNamespace getVariable ["KFH_envTrafficMilitaryVehicleClasses", []],
        missionNamespace getVariable ["KFH_cupEnvTrafficMilitaryVehicleClasses", []],
        _cupChance
    ] call KFH_fnc_selectExistingWithOptionalPriority
};

KFH_fnc_configurePvEvERelations = {
    west setFriend [west, 1];
    east setFriend [east, 1];
    resistance setFriend [resistance, 1];
    west setFriend [resistance, 0];
    resistance setFriend [west, 0];
    east setFriend [resistance, 0];
    resistance setFriend [east, 0];
    civilian setFriend [east, 0];
    east setFriend [civilian, 0];
};

KFH_fnc_applyEnemyFireAccuracy = {
    params ["_unit"];

    if (isNull _unit) exitWith {};
    _unit setSkill ["aimingAccuracy", missionNamespace getVariable ["KFH_enemyAimingAccuracy", 0.04]];
    _unit setSkill ["aimingShake", missionNamespace getVariable ["KFH_enemyAimingShake", 0.16]];
    _unit setSkill ["aimingSpeed", missionNamespace getVariable ["KFH_enemyAimingSpeed", 0.16]];
};

KFH_fnc_protectEnvMilitaryRating = {
    params ["_unit"];

    if (isNull _unit) exitWith {};
    if !(missionNamespace getVariable ["KFH_envMilitaryProtectRating", true]) exitWith {};

    _unit setVariable ["KFH_envMilitaryRatingProtected", true, true];
    _unit addRating (100000 - (rating _unit));
    if !(_unit getVariable ["KFH_envMilitaryRatingHandlerInstalled", false]) then {
        _unit setVariable ["KFH_envMilitaryRatingHandlerInstalled", true];
        _unit addEventHandler ["HandleRating", {
            params ["_unit", "_rating"];
            if (_unit getVariable ["KFH_envMilitaryRatingProtected", false]) then {
                0
            } else {
                _rating
            }
        }];
    };
};

KFH_fnc_getThreatScale = {
    missionNamespace getVariable ["KFH_threatScaleMultiplier", 1]
};

KFH_fnc_applyEnvMilitarySpawnDiscipline = {
    params ["_groupRef"];

    if (isNull _groupRef) exitWith {};

    private _grace = missionNamespace getVariable ["KFH_envMilitarySpawnTargetGraceSeconds", 0];
    if (_grace <= 0) exitWith {};

    _groupRef setCombatMode "BLUE";
    {
        if (!isNull _x && {alive _x}) then {
            _x setBehaviour "SAFE";
            _x disableAI "TARGET";
            _x disableAI "AUTOTARGET";
        };
    } forEach (units _groupRef);

    [_groupRef, _grace] spawn {
        params ["_groupRef", "_grace"];
        sleep _grace;
        if (isNull _groupRef) exitWith {};
        {
            if (!isNull _x && {alive _x}) then {
                _x enableAI "TARGET";
                _x enableAI "AUTOTARGET";
                _x setBehaviour "AWARE";
            };
        } forEach (units _groupRef);
        _groupRef setCombatMode "RED";
    };
};

KFH_fnc_configureEnvMilitaryCrew = {
    params ["_unit"];

    if (isNull _unit) exitWith {};
    [_unit] call KFH_fnc_protectEnvMilitaryRating;
    if ((random 1) < (missionNamespace getVariable ["KFH_envMilitaryLoadoutCupPreferredChance", 0.68])) then {
        [_unit, true] call KFH_fnc_configureMilitaryInfantryLoadout;
    } else {
        [_unit, false] call KFH_fnc_configureMilitaryInfantryLoadout;
    };
    if ((random 1) < (missionNamespace getVariable ["KFH_envMilitaryATChance", 0.72])) then {
        [_unit] call KFH_fnc_giveMilitaryATLauncher;
    };
    _unit setSkill ((missionNamespace getVariable ["KFH_envMilitarySkillBase", 0.24]) + random (missionNamespace getVariable ["KFH_envMilitarySkillRandom", 0.16]));
    _unit setSkill ["aimingAccuracy", missionNamespace getVariable ["KFH_envMilitaryAimingAccuracy", 0.08]];
    _unit setSkill ["aimingShake", missionNamespace getVariable ["KFH_envMilitaryAimingShake", 0.12]];
    _unit setSkill ["aimingSpeed", missionNamespace getVariable ["KFH_envMilitaryAimingSpeed", 0.18]];
    _unit setSkill ["spotDistance", missionNamespace getVariable ["KFH_envMilitarySpotDistance", 0.34]];
    _unit setSkill ["spotTime", missionNamespace getVariable ["KFH_envMilitarySpotTime", 0.28]];
    _unit setSkill ["courage", missionNamespace getVariable ["KFH_envMilitaryCourage", 0.42]];
    _unit setSkill ["commanding", missionNamespace getVariable ["KFH_envMilitaryCommanding", 0.32]];
    _unit setSkill ["general", missionNamespace getVariable ["KFH_envMilitaryGeneral", 0.32]];
    [_unit] call KFH_fnc_applyEnemyFireAccuracy;
    _unit setBehaviour "AWARE";
    _unit setCombatMode "RED";
    _unit allowFleeing 0.15;
    _unit setVariable ["KFH_envTrafficCrew", true, true];
    _unit setVariable ["KFH_enemyRole", "military", true];
    [_unit] call KFH_fnc_applyFriendlyFireMitigation;
    [_unit] call KFH_fnc_protectEnvMilitaryRating;
};

KFH_fnc_configureMilitaryInfantryLoadout = {
    params ["_unit", ["_preferCup", true]];

    if (isNull _unit) exitWith {};

    private _vanilla = missionNamespace getVariable ["KFH_rangedEnemyLoadouts", []];
    private _optional = missionNamespace getVariable ["KFH_cupRangedEnemyLoadouts", []];
    private _cupChance = if (_preferCup) then { missionNamespace getVariable ["KFH_cupRangedEnemyPreferredChance", 0.72] } else { 0.15 };
    private _entry = [_vanilla, _optional, _cupChance] call KFH_fnc_selectAvailableWeaponBundle;
    if ((count _entry) < 2) exitWith {};

    removeAllWeapons _unit;
    removeAllItems _unit;
    removeAllAssignedItems _unit;
    removeVest _unit;
    _unit addVest "V_BandollierB_khk";

    private _weapon = _entry select 0;
    private _mag = _entry select 1;
    private _attachments = if ((count _entry) > 2) then { _entry select 2 } else { [] };
    private _extraMags = if ((count _entry) > 3) then { _entry select 3 } else { 3 };
    [_unit, _weapon, _mag, _attachments, _extraMags] call KFH_fnc_givePrimaryWeaponLoadout;
};

KFH_fnc_giveMilitaryATLauncher = {
    params ["_unit"];

    if (isNull _unit) exitWith { false };
    private _bundles = [
        missionNamespace getVariable ["KFH_simpleLauncherBundles", []],
        missionNamespace getVariable ["KFH_cupLauncherBundles", []],
        missionNamespace getVariable ["KFH_cupRewardPreferredChance", 0.85]
    ] call KFH_fnc_selectAvailableWeaponBundle;
    if ((count _bundles) < 2) exitWith { false };

    private _launcher = _bundles select 0;
    private _mag = _bundles select 1;
    private _magCount = if ((count _bundles) > 2) then { _bundles select 2 } else { 1 };
    if !(isClass (configFile >> "CfgWeapons" >> _launcher)) exitWith { false };
    if !(isClass (configFile >> "CfgMagazines" >> _mag)) exitWith { false };

    _unit addMagazine _mag;
    _unit addWeapon _launcher;
    [_unit, _mag, (_magCount - 1) max 0] call KFH_fnc_addInventoryItems;
    _unit setVariable ["KFH_envMilitaryAT", true, true];
    [_unit] spawn KFH_fnc_watchMilitaryATTargets;
    true
};

KFH_fnc_watchMilitaryATTargets = {
    params ["_unit"];

    private _radius = missionNamespace getVariable ["KFH_envMilitaryATVehicleScanRadius", 420];
    while { !isNull _unit && {alive _unit} && {_unit getVariable ["KFH_envMilitaryAT", false]} } do {
        private _vehicles = vehicles select {
            alive _x &&
            {canMove _x} &&
            {(_x distance2D _unit) < _radius} &&
            {({alive _x && {isPlayer _x}} count crew _x) > 0}
        };
        if ((count _vehicles) > 0) then {
            private _target = selectRandom _vehicles;
            _unit reveal [_target, 4];
            _unit doTarget _target;
            _unit doFire _target;
        };
        sleep 6;
    };
};

KFH_fnc_getActiveMilitaryEnvPositions = {
    private _positions = [];
    {
        if (!isNull _x && {(_x getVariable ["KFH_envRole", ""]) in ["militaryTraffic", "militaryScene", "militaryFootPatrol", "militaryCheckpoint"]}) then {
            private _leader = leader _x;
            if (!isNull _leader && {alive _leader}) then {
                _positions pushBack (getPosATL _leader);
            };
        };
    } forEach (missionNamespace getVariable ["KFH_envTrafficGroups", []]);

    _positions
};

KFH_fnc_isFarFromMilitaryEnv = {
    params ["_pos", ["_minDistance", missionNamespace getVariable ["KFH_envMilitarySeparationFromZombies", 120]]];

    private _ok = true;
    {
        if ((_pos distance2D _x) < _minDistance) exitWith { _ok = false; };
    } forEach ([] call KFH_fnc_getActiveMilitaryEnvPositions);

    _ok
};

KFH_fnc_isFarFromActiveZombies = {
    params ["_pos", ["_minDistance", missionNamespace getVariable ["KFH_envMilitarySeparationFromZombies", 120]]];

    private _ok = true;
    {
        if (
            alive _x &&
            {(_x getVariable ["KFH_enemyRole", ""]) isNotEqualTo "agent"} &&
            {(_pos distance2D _x) < _minDistance}
        ) exitWith {
            _ok = false;
        };
    } forEach (missionNamespace getVariable ["KFH_activeEnemies", []]);

    _ok
};

KFH_fnc_spawnAmbientTrafficBetweenMarkers = {
    params ["_fromMarker", "_toMarker", ["_segmentIndex", 1]];

    if !(missionNamespace getVariable ["KFH_ambientTrafficEnabled", true]) exitWith { objNull };
    if (_segmentIndex > (missionNamespace getVariable ["KFH_ambientTrafficMaxSegment", 4])) exitWith { objNull };
    if ((random 1) > (missionNamespace getVariable ["KFH_ambientTrafficChance", 0.9])) exitWith { objNull };
    if !(_fromMarker in allMapMarkers) exitWith { objNull };
    if !(_toMarker in allMapMarkers) exitWith { objNull };

    private _fromPos = getMarkerPos _fromMarker;
    private _toPos = getMarkerPos _toMarker;
    if (surfaceIsWater _fromPos) exitWith { objNull };

    private _classes = [
        missionNamespace getVariable ["KFH_ambientTrafficClasses", ["C_Hatchback_01_F"]],
        missionNamespace getVariable ["KFH_cupAmbientTrafficClasses", []]
    ] call KFH_fnc_filterExistingVehicleClasses;
    private _drivers = missionNamespace getVariable ["KFH_ambientTrafficDriverClasses", ["C_man_1"]];
    if ((count _classes) isEqualTo 0 || {(count _drivers) isEqualTo 0}) exitWith { objNull };

    private _activeGroups = missionNamespace getVariable ["KFH_envTrafficGroups", []];
    private _road = [
        missionNamespace getVariable ["KFH_envTrafficMinSpawnDistance", 550],
        missionNamespace getVariable ["KFH_envTrafficMaxSpawnDistance", 1250],
        _activeGroups
    ] call KFH_fnc_getRandomRoadSegmentAroundHumans;
    if (isNull _road) exitWith { objNull };

    private _spawnPos = getPosATL _road;
    private _connected = roadsConnectedTo _road;
    private _dir = if ((count _connected) > 0) then {
        _spawnPos getDir (getPosATL (selectRandom _connected))
    } else {
        _fromPos getDir _toPos
    };
    if (surfaceIsWater _spawnPos) exitWith { objNull };

    private _vehicleClass = selectRandom _classes;

    private _vehicle = createVehicle [_vehicleClass, _spawnPos, [], 0, "NONE"];
    _vehicle setDir _dir;
    _vehicle setPosATL _spawnPos;
    _vehicle setDamage 0;

    private _fuelMin = missionNamespace getVariable ["KFH_ambientTrafficFuelMin", 0.25];
    private _fuelMax = missionNamespace getVariable ["KFH_ambientTrafficFuelMax", 0.55];
    _vehicle setFuel (_fuelMin + random ((_fuelMax - _fuelMin) max 0.01));
    _vehicle lock 0;
    _vehicle setVariable ["KFH_supportLabel", "Panicked Civilian Traffic", true];
    _vehicle setVariable ["KFH_ambientTraffic", true, true];
    [_vehicle] call KFH_fnc_installVehicleThreatHandlers;
    [_vehicle] call KFH_fnc_addCivilianTrafficCargo;

    private _groupRef = createGroup [civilian, true];
    private _driverClass = selectRandom _drivers;
    if (isClass (configFile >> "CfgVehicles" >> _driverClass)) then {
        private _driver = _groupRef createUnit [_driverClass, _spawnPos, [], 0, "FORM"];
        _driver moveInDriver _vehicle;
        _driver allowFleeing 1;
        _driver setBehaviour "CARELESS";
        _driver setCombatMode "BLUE";
        _driver setSpeedMode "NORMAL";
        _driver setVariable ["KFH_outbreakCivilian", true, true];
        [_driver] call KFH_fnc_installCivilianPenaltyHandlers;
        private _trafficMode = if ((random 1) <= (missionNamespace getVariable ["KFH_envTrafficOncomingChance", 0.55])) then { "approach" } else { "random" };
        [_groupRef, "LIMITED", "CARELESS", missionNamespace getVariable ["KFH_envTrafficDestinationDistance", 1400], _trafficMode] call KFH_fnc_assignEnvTrafficWaypoint;
    } else {
        deleteGroup _groupRef;
    };

    [_groupRef, "civilianTraffic", [_vehicle]] call KFH_fnc_registerEnvGroup;

    _vehicle
};

KFH_fnc_spawnRouteAmbientTraffic = {
    params ["_routeMarkers"];

    if !(missionNamespace getVariable ["KFH_ambientTrafficEnabled", true]) exitWith { [] };

    private _spawned = [];
    private _perSegment = (missionNamespace getVariable ["KFH_ambientTrafficVehiclesPerSegment", 1]) max 0;
    private _maxSegment = (missionNamespace getVariable ["KFH_ambientTrafficMaxSegment", 4]) min ((count _routeMarkers) - 1);

    for "_segmentIndex" from 1 to _maxSegment do {
        private _fromMarker = _routeMarkers select (_segmentIndex - 1);
        private _toMarker = _routeMarkers select _segmentIndex;
        for "_i" from 1 to _perSegment do {
            private _vehicle = [_fromMarker, _toMarker, _segmentIndex] call KFH_fnc_spawnAmbientTrafficBetweenMarkers;
            if !(isNull _vehicle) then {
                _spawned pushBack _vehicle;
            };
        };
    };

    if ((count _spawned) > 0) then {
        [format ["Ambient civilian traffic spawned: %1 vehicle(s) across early route.", count _spawned]] call KFH_fnc_log;
    };

    _spawned
};

KFH_fnc_cleanupEnvTrafficGroups = {
    private _groups = missionNamespace getVariable ["KFH_envTrafficGroups", []];
    private _removalDistance = missionNamespace getVariable ["KFH_envTrafficRemovalDistance", 1800];
    private _keptGroups = [];
    private _keptVehicles = [];

    {
        private _groupRef = _x;
        if (!isNull _groupRef && {(count units _groupRef) > 0}) then {
            private _leader = leader _groupRef;
            private _nearest = if (isNull _leader) then { 1e10 } else { [getPosATL _leader] call KFH_fnc_getNearestHumanDistance };

            if (_nearest > _removalDistance) then {
                private _vehicles = [];
                {
                    private _vehicle = vehicle _x;
                    if (_vehicle != _x) then {
                        _vehicles pushBackUnique _vehicle;
                    };
                    deleteVehicle _x;
                } forEach units _groupRef;
                { deleteVehicle _x } forEach _vehicles;
                { if (!isNull _x) then { deleteVehicle _x; }; } forEach (_groupRef getVariable ["KFH_envObjects", []]);
                deleteGroup _groupRef;
            } else {
                _keptGroups pushBack _groupRef;
                {
                    private _vehicle = vehicle _x;
                    if (_vehicle != _x && {alive _vehicle}) then {
                        _keptVehicles pushBackUnique _vehicle;
                    };
                } forEach units _groupRef;
            };
        } else {
            if (!isNull _groupRef) then {
                deleteGroup _groupRef;
            };
        };
    } forEach _groups;

    missionNamespace setVariable ["KFH_envTrafficGroups", _keptGroups];
    missionNamespace setVariable ["KFH_ambientTrafficVehicles", _keptVehicles, true];
    _keptGroups
};

KFH_fnc_spawnEnvMilitaryTraffic = {
    [] call KFH_fnc_configurePvEvERelations;
    private _crewClasses = [
        missionNamespace getVariable ["KFH_envTrafficMilitaryCrewClasses", []],
        missionNamespace getVariable ["KFH_cupEnvTrafficMilitaryCrewClasses", []]
    ] call KFH_fnc_filterExistingVehicleClasses;
    private _vehicleClass = [] call KFH_fnc_selectMilitaryVehicleClass;
    if (_vehicleClass isEqualTo "" || {(count _crewClasses) isEqualTo 0}) exitWith { grpNull };

    private _groups = missionNamespace getVariable ["KFH_envTrafficGroups", []];
    private _road = [
        missionNamespace getVariable ["KFH_envTrafficMinSpawnDistance", 550],
        missionNamespace getVariable ["KFH_envTrafficMaxSpawnDistance", 1250],
        _groups
    ] call KFH_fnc_getRandomRoadSegmentAroundHumans;
    if (isNull _road) exitWith { grpNull };

    private _spawnPos = getPosATL _road;
    private _connected = roadsConnectedTo _road;
    private _dir = if ((count _connected) > 0) then {
        _spawnPos getDir (getPosATL (selectRandom _connected))
    } else {
        random 360
    };

    private _result = [_spawnPos, _dir, _vehicleClass, resistance] call BIS_fnc_spawnVehicle;
    private _vehicle = _result select 0;
    private _crew = _result select 1;
    private _groupRef = _result select 2;
    _vehicle setDamage (random 0.08);
    _vehicle setFuel (0.22 + random 0.38);
    _vehicle lock 0;
    _vehicle setVariable ["KFH_supportLabel", "Hostile Military Patrol", true];
    _vehicle setVariable ["KFH_ambientTraffic", true, true];
    [_vehicle] call KFH_fnc_installVehicleThreatHandlers;

    {
        [_x] call KFH_fnc_configureEnvMilitaryCrew;
    } forEach _crew;

    [_groupRef] call KFH_fnc_applyEnvMilitarySpawnDiscipline;
    [_groupRef, "NORMAL", "AWARE", missionNamespace getVariable ["KFH_envTrafficDestinationDistance", 1400], "approach"] call KFH_fnc_assignEnvTrafficWaypoint;
    [_groupRef, "militaryTraffic", [_vehicle]] call KFH_fnc_registerEnvGroup;

    _groupRef
};

KFH_fnc_spawnEnvCivilianPedestrian = {
    private _classes = missionNamespace getVariable ["KFH_outbreakCivilianClasses", []];
    if ((count _classes) isEqualTo 0) exitWith { grpNull };

    private _road = [
        missionNamespace getVariable ["KFH_envSceneSpawnRadiusMin", 85],
        missionNamespace getVariable ["KFH_envSceneSpawnRadiusMax", 340],
        missionNamespace getVariable ["KFH_envTrafficGroups", []]
    ] call KFH_fnc_getRandomRoadSegmentAroundHumans;
    if (isNull _road) exitWith { grpNull };

    private _basePos = getPosATL _road;
    private _spawnAngle = random 360;
    private _spawnDistance = 6 + random 18;
    private _spawnPos = [
        (_basePos select 0) + (sin _spawnAngle) * _spawnDistance,
        (_basePos select 1) + (cos _spawnAngle) * _spawnDistance,
        0
    ];
    if (surfaceIsWater _spawnPos) exitWith { grpNull };

    private _className = selectRandom _classes;
    if !(isClass (configFile >> "CfgVehicles" >> _className)) exitWith { grpNull };

    private _groupRef = createGroup [civilian, true];
    private _unit = _groupRef createUnit [_className, _spawnPos, [], 0, "FORM"];
    _unit setDir (random 360);
    _unit allowFleeing 1;
    _unit setBehaviour "CARELESS";
    _unit setCombatMode "BLUE";
    _unit setSpeedMode "LIMITED";
    _unit disableAI "AUTOCOMBAT";
    _unit disableAI "TARGET";
    _unit disableAI "AUTOTARGET";
    _unit setVariable ["KFH_outbreakCivilian", true, true];
    [_unit] call KFH_fnc_installCivilianPenaltyHandlers;

    private _moves = missionNamespace getVariable ["KFH_outbreakCivilianPanicMoves", []];
    if ((count _moves) > 0 && {(random 1) < 0.45}) then {
        _unit switchMove (selectRandom _moves);
    } else {
        private _moveAngle = random 360;
        private _moveDistance = 30 + random 70;
        private _movePos = [
            (_basePos select 0) + (sin _moveAngle) * _moveDistance,
            (_basePos select 1) + (cos _moveAngle) * _moveDistance,
            0
        ];
        private _wp = _groupRef addWaypoint [_movePos, 0];
        _wp setWaypointType "MOVE";
        _wp setWaypointSpeed "LIMITED";
        _wp setWaypointBehaviour "CARELESS";
        _wp setWaypointCompletionRadius 8;
    };

    [_groupRef, "civilianPedestrian", []] call KFH_fnc_registerEnvGroup;
    _groupRef
};

KFH_fnc_spawnEnvCivilianSceneVehicle = {
    private _classes = [
        missionNamespace getVariable ["KFH_ambientTrafficClasses", ["C_Hatchback_01_F"]],
        missionNamespace getVariable ["KFH_cupAmbientTrafficClasses", []]
    ] call KFH_fnc_filterExistingVehicleClasses;
    private _drivers = missionNamespace getVariable ["KFH_ambientTrafficDriverClasses", ["C_man_1"]];
    if ((count _classes) isEqualTo 0 || {(count _drivers) isEqualTo 0}) exitWith { grpNull };

    private _road = [
        missionNamespace getVariable ["KFH_envSceneSpawnRadiusMin", 85],
        missionNamespace getVariable ["KFH_envSceneSpawnRadiusMax", 340],
        missionNamespace getVariable ["KFH_envTrafficGroups", []]
    ] call KFH_fnc_getRandomRoadSegmentAroundHumans;
    if (isNull _road) exitWith { grpNull };

    private _spawnPos = getPosATL _road;
    private _connected = roadsConnectedTo _road;
    private _dir = if ((count _connected) > 0) then {
        _spawnPos getDir (getPosATL (selectRandom _connected))
    } else {
        random 360
    };

    private _vehicleClass = selectRandom _classes;
    private _driverClass = selectRandom _drivers;
    if !(isClass (configFile >> "CfgVehicles" >> _driverClass)) exitWith { grpNull };

    private _vehicle = createVehicle [_vehicleClass, _spawnPos, [], 0, "NONE"];
    _vehicle setDir _dir;
    _vehicle setPosATL _spawnPos;
    _vehicle setDamage (random 0.08);
    _vehicle setFuel ((missionNamespace getVariable ["KFH_ambientTrafficFuelMin", 0.25]) + random (((missionNamespace getVariable ["KFH_ambientTrafficFuelMax", 0.55]) - (missionNamespace getVariable ["KFH_ambientTrafficFuelMin", 0.25])) max 0.01));
    _vehicle lock 0;
    _vehicle setVariable ["KFH_supportLabel", "Panicked Civilian Traffic", true];
    _vehicle setVariable ["KFH_ambientTraffic", true, true];
    [_vehicle] call KFH_fnc_installVehicleThreatHandlers;
    [_vehicle] call KFH_fnc_addCivilianTrafficCargo;

    private _groupRef = createGroup [civilian, true];
    private _driver = _groupRef createUnit [_driverClass, _spawnPos, [], 0, "FORM"];
    _driver moveInDriver _vehicle;
    _driver allowFleeing 1;
    _driver setBehaviour "CARELESS";
    _driver setCombatMode "BLUE";
    _driver setSpeedMode "LIMITED";
    _driver setVariable ["KFH_outbreakCivilian", true, true];
    [_driver] call KFH_fnc_installCivilianPenaltyHandlers;

    private _trafficMode = if ((random 1) <= (missionNamespace getVariable ["KFH_envTrafficOncomingChance", 0.55])) then { "approach" } else { "random" };
    [_groupRef, "LIMITED", "CARELESS", missionNamespace getVariable ["KFH_envTrafficDestinationDistance", 1400], _trafficMode] call KFH_fnc_assignEnvTrafficWaypoint;
    [_groupRef, "civilianSceneVehicle", [_vehicle]] call KFH_fnc_registerEnvGroup;
    _groupRef
};

KFH_fnc_spawnEnvMilitaryScene = {
    [] call KFH_fnc_configurePvEvERelations;
    private _vehicleClass = [] call KFH_fnc_selectMilitaryVehicleClass;
    if (_vehicleClass isEqualTo "") exitWith { grpNull };

    private _road = [
        missionNamespace getVariable ["KFH_envSceneSpawnRadiusMin", 85],
        missionNamespace getVariable ["KFH_envSceneSpawnRadiusMax", 340],
        missionNamespace getVariable ["KFH_envTrafficGroups", []]
    ] call KFH_fnc_getRandomRoadSegmentAroundHumans;
    if (isNull _road) exitWith { grpNull };

    private _spawnPos = getPosATL _road;
    private _connected = roadsConnectedTo _road;
    private _dir = if ((count _connected) > 0) then {
        _spawnPos getDir (getPosATL (selectRandom _connected))
    } else {
        random 360
    };

    private _result = [_spawnPos, _dir, _vehicleClass, resistance] call BIS_fnc_spawnVehicle;
    private _vehicle = _result select 0;
    private _crew = _result select 1;
    private _groupRef = _result select 2;
    _vehicle setDamage (random 0.06);
    _vehicle setFuel (0.28 + random 0.42);
    _vehicle lock 0;
    _vehicle setVariable ["KFH_supportLabel", "Hostile Military Patrol", true];
    _vehicle setVariable ["KFH_ambientTraffic", true, true];
    [_vehicle] call KFH_fnc_installVehicleThreatHandlers;

    {
        [_x] call KFH_fnc_configureEnvMilitaryCrew;
    } forEach _crew;

    [_groupRef] call KFH_fnc_applyEnvMilitarySpawnDiscipline;
    [_groupRef, "NORMAL", "AWARE", missionNamespace getVariable ["KFH_envTrafficDestinationDistance", 1400], "approach"] call KFH_fnc_assignEnvTrafficWaypoint;
    [_groupRef, "militaryScene", [_vehicle]] call KFH_fnc_registerEnvGroup;
    _groupRef
};

KFH_fnc_spawnEnvMilitaryFootPatrol = {
    if !(missionNamespace getVariable ["KFH_envMilitaryFootPatrolEnabled", true]) exitWith { grpNull };
    [] call KFH_fnc_configurePvEvERelations;

    private _crewClasses = [
        missionNamespace getVariable ["KFH_envTrafficMilitaryCrewClasses", []],
        missionNamespace getVariable ["KFH_cupEnvTrafficMilitaryCrewClasses", []]
    ] call KFH_fnc_filterExistingVehicleClasses;
    if ((count _crewClasses) isEqualTo 0) exitWith { grpNull };

    private _road = [
        missionNamespace getVariable ["KFH_envSceneSpawnRadiusMin", 85],
        missionNamespace getVariable ["KFH_envSceneSpawnRadiusMax", 340],
        missionNamespace getVariable ["KFH_envTrafficGroups", []]
    ] call KFH_fnc_getRandomRoadSegmentAroundHumans;
    if (isNull _road) exitWith { grpNull };

    private _spawnPos = getPosATL _road;
    if !([_spawnPos, missionNamespace getVariable ["KFH_envMilitaryRespawnSeparationFromZombies", 260]] call KFH_fnc_isFarFromActiveZombies) exitWith { grpNull };

    private _groupRef = createGroup [resistance, true];
    private _minSize = missionNamespace getVariable ["KFH_envMilitaryFootPatrolSizeMin", 2];
    private _maxSize = missionNamespace getVariable ["KFH_envMilitaryFootPatrolSizeMax", 4];
    private _threatScale = [] call KFH_fnc_getThreatScale;
    private _count = ceil ((_minSize + floor (random (((_maxSize - _minSize) max 0) + 1))) * _threatScale);
    for "_i" from 1 to _count do {
        private _pos = _spawnPos getPos [2 + random 6, random 360];
        private _unit = _groupRef createUnit [selectRandom _crewClasses, _pos, [], 0, "FORM"];
        [_unit] call KFH_fnc_configureEnvMilitaryCrew;
    };

    _groupRef setFormation "WEDGE";
    [_groupRef] call KFH_fnc_applyEnvMilitarySpawnDiscipline;
    [_groupRef, "LIMITED", "AWARE", 260, "random"] call KFH_fnc_assignEnvTrafficWaypoint;
    [_groupRef, "militaryFootPatrol", []] call KFH_fnc_registerEnvGroup;
    [format ["Military foot patrol spawned at %1 (%2 units).", mapGridPosition _spawnPos, _count]] call KFH_fnc_log;

    _groupRef
};

KFH_fnc_spawnEnvMilitaryCheckpoint = {
    if !(missionNamespace getVariable ["KFH_envMilitaryCheckpointEnabled", true]) exitWith { grpNull };
    [] call KFH_fnc_configurePvEvERelations;

    private _crewClasses = [
        missionNamespace getVariable ["KFH_envTrafficMilitaryCrewClasses", []],
        missionNamespace getVariable ["KFH_cupEnvTrafficMilitaryCrewClasses", []]
    ] call KFH_fnc_filterExistingVehicleClasses;
    if ((count _crewClasses) isEqualTo 0) exitWith { grpNull };

    private _road = [
        missionNamespace getVariable ["KFH_envSceneSpawnRadiusMin", 85],
        missionNamespace getVariable ["KFH_envSceneSpawnRadiusMax", 340],
        missionNamespace getVariable ["KFH_envTrafficGroups", []]
    ] call KFH_fnc_getRandomRoadSegmentAroundHumans;
    if (isNull _road) exitWith { grpNull };

    private _spawnPos = getPosATL _road;
    if !([_spawnPos, missionNamespace getVariable ["KFH_envMilitaryRespawnSeparationFromZombies", 260]] call KFH_fnc_isFarFromActiveZombies) exitWith { grpNull };

    private _connected = roadsConnectedTo _road;
    private _dir = if ((count _connected) > 0) then { _spawnPos getDir (getPosATL (selectRandom _connected)) } else { random 360 };
    private _objects = [];
    {
        _x params ["_className", ["_offset", [0, 0, 0]], ["_dirOffset", 0]];
        if (isClass (configFile >> "CfgVehicles" >> _className)) then {
            private _rightOffset = _offset select 0;
            private _forwardOffset = _offset select 1;
            private _objectPos = [
                (_spawnPos select 0) + (sin (_dir + 90)) * _rightOffset + (sin _dir) * _forwardOffset,
                (_spawnPos select 1) + (cos (_dir + 90)) * _rightOffset + (cos _dir) * _forwardOffset,
                0
            ];
            _objectPos set [2, if ((count _offset) > 2) then { _offset select 2 } else { 0 }];
            private _object = createVehicle [_className, _objectPos, [], 0, "CAN_COLLIDE"];
            _object setDir (_dir + _dirOffset);
            _object setPosATL _objectPos;
            _objects pushBack _object;
        };
    } forEach (missionNamespace getVariable ["KFH_envMilitaryCheckpointObjects", []]);

    private _groupRef = createGroup [resistance, true];
    private _minGuards = missionNamespace getVariable ["KFH_envMilitaryCheckpointGuardMin", 2];
    private _maxGuards = missionNamespace getVariable ["KFH_envMilitaryCheckpointGuardMax", 4];
    private _threatScale = [] call KFH_fnc_getThreatScale;
    private _count = ceil ((_minGuards + floor (random (((_maxGuards - _minGuards) max 0) + 1))) * _threatScale);
    for "_i" from 1 to _count do {
        private _pos = _spawnPos getPos [6 + random 12, random 360];
        private _unit = _groupRef createUnit [selectRandom _crewClasses, _pos, [], 0, "FORM"];
        [_unit] call KFH_fnc_configureEnvMilitaryCrew;
        _unit doWatch (_spawnPos getPos [60, _dir]);
    };

    _groupRef setFormation "LINE";
    [_groupRef] call KFH_fnc_applyEnvMilitarySpawnDiscipline;
    [_groupRef, "militaryCheckpoint", [], _objects] call KFH_fnc_registerEnvGroup;
    [format ["Military checkpoint spawned at %1 (%2 guards, %3 objects).", mapGridPosition _spawnPos, _count, count _objects]] call KFH_fnc_log;

    _groupRef
};

KFH_fnc_spawnEnvSceneTick = {
    if !(missionNamespace getVariable ["KFH_envSceneEnabled", true]) exitWith {};

    private _currentCheckpoint = missionNamespace getVariable ["KFH_currentCheckpoint", 1];
    private _earlyUntil = missionNamespace getVariable ["KFH_envSceneEarlyUntilCheckpoint", 2];
    private _isEarly = _currentCheckpoint <= _earlyUntil;
    private _counts = [] call KFH_fnc_getEnvGroupCounts;
    _counts params ["_pedestrians", "_civilianVehicles", "_military"];

    private _pedMax = if (_isEarly) then {
        missionNamespace getVariable ["KFH_envSceneCivilianPedestrianMaxEarly", 18]
    } else {
        missionNamespace getVariable ["KFH_envSceneCivilianPedestrianMaxLate", 6]
    };
    private _civVehicleMax = if (_isEarly) then {
        missionNamespace getVariable ["KFH_envSceneCivilianVehicleMaxEarly", 8]
    } else {
        missionNamespace getVariable ["KFH_envSceneCivilianVehicleMaxLate", 3]
    };
    private _milMax = if (_isEarly) then {
        missionNamespace getVariable ["KFH_envSceneMilitaryMaxEarly", 1]
    } else {
        missionNamespace getVariable ["KFH_envSceneMilitaryMaxLate", 5]
    };

    private _spawnedPeds = 0;
    private _spawnedCivVehicles = 0;
    private _spawnedMilitary = 0;

    private _pedPerTick = if (_isEarly) then {
        missionNamespace getVariable ["KFH_envSceneCivilianPedestriansPerTickEarly", 4]
    } else {
        missionNamespace getVariable ["KFH_envSceneCivilianPedestriansPerTickLate", 1]
    };
    for "_i" from 1 to ((_pedMax - _pedestrians) min _pedPerTick) do {
        if !(isNull ([] call KFH_fnc_spawnEnvCivilianPedestrian)) then { _spawnedPeds = _spawnedPeds + 1; };
    };

    private _civVehiclePerTick = if (_isEarly) then {
        missionNamespace getVariable ["KFH_envSceneCivilianVehiclesPerTickEarly", 2]
    } else {
        missionNamespace getVariable ["KFH_envSceneCivilianVehiclesPerTickLate", 1]
    };
    for "_i" from 1 to ((_civVehicleMax - _civilianVehicles) min _civVehiclePerTick) do {
        if !(isNull ([] call KFH_fnc_spawnEnvCivilianSceneVehicle)) then { _spawnedCivVehicles = _spawnedCivVehicles + 1; };
    };

    if (_currentCheckpoint >= (missionNamespace getVariable ["KFH_envTrafficMilitaryStartCheckpoint", 3]) && {time >= (missionNamespace getVariable ["KFH_envTrafficMilitaryDelaySeconds", 55])}) then {
        private _milPerTick = if (_isEarly) then {
            missionNamespace getVariable ["KFH_envSceneMilitaryPerTickEarly", 0]
        } else {
            missionNamespace getVariable ["KFH_envSceneMilitaryPerTickLate", 1]
        };
        for "_i" from 1 to ((_milMax - _military) min _milPerTick) do {
            if ((random 1) <= (missionNamespace getVariable ["KFH_envSceneMilitaryVehicleChance", 0.2])) then {
                if !(isNull ([] call KFH_fnc_spawnEnvMilitaryScene)) then { _spawnedMilitary = _spawnedMilitary + 1; };
            };
        };

        private _envGroups = missionNamespace getVariable ["KFH_envTrafficGroups", []];
        private _footPatrols = {
            !isNull _x && {(_x getVariable ["KFH_envRole", ""]) isEqualTo "militaryFootPatrol"}
        } count _envGroups;
        if (
            _footPatrols < (ceil ((missionNamespace getVariable ["KFH_envMilitaryFootPatrolMax", 4]) * ([] call KFH_fnc_getThreatScale))) &&
            {(random 1) <= (missionNamespace getVariable ["KFH_envMilitaryFootPatrolChance", 0.5])}
        ) then {
            if !(isNull ([] call KFH_fnc_spawnEnvMilitaryFootPatrol)) then { _spawnedMilitary = _spawnedMilitary + 1; };
        };

        private _checkpoints = {
            !isNull _x && {(_x getVariable ["KFH_envRole", ""]) isEqualTo "militaryCheckpoint"}
        } count (missionNamespace getVariable ["KFH_envTrafficGroups", []]);
        if (
            _checkpoints < (ceil ((missionNamespace getVariable ["KFH_envMilitaryCheckpointMax", 3]) * ([] call KFH_fnc_getThreatScale))) &&
            {(random 1) <= (missionNamespace getVariable ["KFH_envMilitaryCheckpointChance", 0.35])}
        ) then {
            if !(isNull ([] call KFH_fnc_spawnEnvMilitaryCheckpoint)) then { _spawnedMilitary = _spawnedMilitary + 1; };
        };
    };

    if ((_spawnedPeds + _spawnedCivVehicles + _spawnedMilitary) > 0 && {time >= (missionNamespace getVariable ["KFH_nextEnvSceneLogAt", 0])}) then {
        missionNamespace setVariable ["KFH_nextEnvSceneLogAt", time + 45];
        [format [
            "Env scene tick CP%1: +%2 civilians, +%3 civilian vehicles, +%4 military groups.",
            _currentCheckpoint,
            _spawnedPeds,
            _spawnedCivVehicles,
            _spawnedMilitary
        ]] call KFH_fnc_log;
    };
};

KFH_fnc_envTrafficLoop = {
    while { true } do {
        private _phase = missionNamespace getVariable ["KFH_phase", "boot"];
        if (_phase in ["complete", "failed"]) exitWith {};

        if (missionNamespace getVariable ["KFH_envTrafficLoopEnabled", true]) then {
            private _currentCheckpoint = missionNamespace getVariable ["KFH_currentCheckpoint", 1];
            private _maxCheckpoint = missionNamespace getVariable ["KFH_envTrafficSpawnUntilCheckpoint", 4];

            if (_currentCheckpoint <= _maxCheckpoint) then {
                private _groups = [] call KFH_fnc_cleanupEnvTrafficGroups;
                private _civilianGroups = _groups select { side _x isEqualTo civilian };
                private _militaryGroups = _groups select { (side _x) in [west, resistance] };

                [] call KFH_fnc_spawnEnvSceneTick;

                if ((count _civilianGroups) < (missionNamespace getVariable ["KFH_envTrafficMaxCivilianGroups", 4])) then {
                private _civilianTrafficChance = if (_currentCheckpoint >= (missionNamespace getVariable ["KFH_envTrafficMilitaryStartCheckpoint", 3])) then {
                    missionNamespace getVariable ["KFH_envTrafficCivilianChanceLate", 0.28]
                } else {
                    missionNamespace getVariable ["KFH_envTrafficCivilianChance", 0.75]
                };
                if ((random 1) <= _civilianTrafficChance) then {
                        private _routeMarkers = missionNamespace getVariable ["KFH_routeMarkers", []];
                        if ((count _routeMarkers) >= 2) then {
                            private _segmentIndex = (_currentCheckpoint max 1) min ((count _routeMarkers) - 1);
                            [_routeMarkers select ((_segmentIndex - 1) max 0), _routeMarkers select _segmentIndex, _segmentIndex] call KFH_fnc_spawnAmbientTrafficBetweenMarkers;
                        };
                    };
                };

                if (
                    time >= (missionNamespace getVariable ["KFH_envTrafficMilitaryDelaySeconds", 90]) &&
                    {_currentCheckpoint >= (missionNamespace getVariable ["KFH_envTrafficMilitaryStartCheckpoint", 3])} &&
                    {(count _militaryGroups) < (missionNamespace getVariable ["KFH_envTrafficMaxMilitaryGroups", 2])} &&
                    {(random 1) <= (missionNamespace getVariable ["KFH_envTrafficMilitaryChance", 0.45])}
                ) then {
                    [] call KFH_fnc_spawnEnvMilitaryTraffic;
                };
            };
        };

        sleep (missionNamespace getVariable ["KFH_envTrafficLoopSeconds", 35]);
    };
};

KFH_fnc_getVehicleThreatTier = {
    params ["_vehicle"];

    if (isNull _vehicle) exitWith { "medium" };

    private _existing = _vehicle getVariable ["KFH_vehicleThreatTier", ""];
    if !(_existing isEqualTo "") exitWith { _existing };

    private _tier = "medium";
    if (_vehicle isKindOf "Tank") then {
        _tier = "combat";
    } else {
        if (_vehicle isKindOf "Wheeled_APC_F") then {
            _tier = "armor";
        } else {
            if (_vehicle isKindOf "Truck_F") then {
                _tier = "heavy";
            } else {
                if (_vehicle isKindOf "Car") then {
                    _tier = "medium";
                };
            };
        };
    };

    if ((typeOf _vehicle) in ["C_Quadbike_01_F", "B_Quadbike_01_F", "I_Quadbike_01_F", "O_Quadbike_01_F"]) then {
        _tier = "light";
    };

    _vehicle setVariable ["KFH_vehicleThreatTier", _tier, true];
    _tier
};

KFH_fnc_getVehicleThreatPressure = {
    params ["_tier"];

    private _table = missionNamespace getVariable ["KFH_vehicleThreatPressureByTier", KFH_vehicleThreatPressureByTier];
    private _entry = _table select { (_x select 0) isEqualTo _tier };

    if ((count _entry) > 0) exitWith { (_entry select 0) select 1 };

    2
};

KFH_fnc_getVehicleThreatLabel = {
    params ["_tier"];

    switch (_tier) do {
        case "light": { "low noise / low hive pressure" };
        case "heavy": { "loud / high hive pressure" };
        case "armor": { "armored / severe hive pressure" };
        case "combat": { "combat vehicle / extreme hive pressure" };
        default { "vehicle noise / medium hive pressure" };
    }
};

KFH_fnc_installVehicleThreatHandlers = {
    params ["_vehicle"];

    if (isNull _vehicle) exitWith {};
    if (_vehicle getVariable ["KFH_vehicleThreatHandlersInstalled", false]) exitWith {};

    private _tier = [_vehicle] call KFH_fnc_getVehicleThreatTier;
    _vehicle setVariable ["KFH_vehicleThreatHandlersInstalled", true, true];
    _vehicle addEventHandler ["GetIn", {
        params ["_vehicle", "_role", "_unit"];

        if !(isPlayer _unit) exitWith {};

        private _tier = [_vehicle] call KFH_fnc_getVehicleThreatTier;
        private _entryMessage = format [
            "Vehicle entered: fuel=%1%% tier=%2 note=%3.",
            round ((fuel _vehicle) * 100),
            _tier,
            [_tier] call KFH_fnc_getVehicleThreatLabel
        ];
        [_entryMessage] call KFH_fnc_log;
        if (missionNamespace getVariable ["KFH_showVehicleEntryChat", false]) then {
            [format [
                "[KFH] Vehicle fuel %1%%. %2. Bigger vehicles escalate Hive Pressure faster.",
                round ((fuel _vehicle) * 100),
                [_tier] call KFH_fnc_getVehicleThreatLabel
            ]] remoteExecCall ["systemChat", _unit];
        };
    }];

    [format ["Vehicle threat handler installed: %1 tier=%2", typeOf _vehicle, _tier]] call KFH_fnc_log;
};

KFH_fnc_isVehicleFlipped = {
    params ["_vehicle"];

    if (isNull _vehicle) exitWith { false };
    alive _vehicle &&
    {_vehicle isKindOf "LandVehicle"} &&
    {abs (speed _vehicle) <= (missionNamespace getVariable ["KFH_vehicleFlipMaxSpeed", 2])} &&
    {((vectorUp _vehicle) select 2) < (missionNamespace getVariable ["KFH_vehicleFlipVectorUpZ", 0.45])}
};

KFH_fnc_getNearbyFlippableVehicle = {
    params [["_unit", objNull]];

    if (isNull _unit) exitWith { objNull };
    if !(missionNamespace getVariable ["KFH_vehicleFlipEnabled", true]) exitWith { objNull };

    private _distance = missionNamespace getVariable ["KFH_vehicleFlipDistance", 7];
    private _vehicles = nearestObjects [_unit, ["LandVehicle"], _distance] select {
        [_x] call KFH_fnc_isVehicleFlipped
    };
    if ((count _vehicles) isEqualTo 0) exitWith { objNull };

    ([_vehicles, [], {_unit distance2D _x}, "ASCEND"] call BIS_fnc_sortBy) select 0
};

KFH_fnc_flipVehicleServer = {
    params ["_vehicle", ["_caller", objNull]];

    if (!isServer) exitWith {
        [_vehicle, _caller] remoteExecCall ["KFH_fnc_flipVehicleServer", 2];
    };
    if (isNull _vehicle) exitWith {};
    if !([_vehicle] call KFH_fnc_isVehicleFlipped) exitWith {};

    if (!isNull _caller) then {
        private _maxDistance = (missionNamespace getVariable ["KFH_vehicleFlipDistance", 7]) + 3;
        if ((_caller distance2D _vehicle) > _maxDistance) exitWith {};
    };

    private _pos = getPosATL _vehicle;
    private _surface = surfaceNormal _pos;
    _vehicle setVelocity [0, 0, 0];
    _vehicle setVectorUp _surface;
    _vehicle setPosATL [(_pos select 0), (_pos select 1), ((_pos select 2) max 0) + 0.35];
    [format ["Vehicle flipped upright: %1 at %2.", typeOf _vehicle, mapGridPosition _vehicle]] call KFH_fnc_log;
};

KFH_fnc_vehicleThreatLoop = {
    if (!isServer) exitWith {};
    if !(missionNamespace getVariable ["KFH_vehicleThreatEnabled", true]) exitWith {};

    while { !((missionNamespace getVariable ["KFH_phase", "boot"]) in ["complete", "failed"]) } do {
        private _supportObjects = missionNamespace getVariable ["KFH_supportObjects", []];
        private _occupiedVehicles = _supportObjects select {
            !isNull _x &&
            {alive _x} &&
            {_x isKindOf "LandVehicle"} &&
            {fuel _x > 0} &&
            {count (crew _x select { alive _x }) > 0}
        };

        private _pressureAdd = 0;
        {
            private _tier = [_x] call KFH_fnc_getVehicleThreatTier;
            _pressureAdd = _pressureAdd + ([_tier] call KFH_fnc_getVehicleThreatPressure);
        } forEach _occupiedVehicles;

        if (_pressureAdd > 0) then {
            private _pressure = missionNamespace getVariable ["KFH_pressure", 0];
            ["KFH_pressure", (_pressure + _pressureAdd) min KFH_pressureMax] call KFH_fnc_setState;
            if (missionNamespace getVariable ["KFH_vehicleThreatDebugLog", false]) then {
                [format [
                "Vehicle noise raised Hive Pressure by %1 from %2 active vehicle(s).",
                _pressureAdd,
                count _occupiedVehicles
                ]] call KFH_fnc_log;
            };
        };

        sleep (missionNamespace getVariable ["KFH_vehicleThreatLoopSeconds", 12]);
    };
};

KFH_fnc_startPatrolVehicleBoost = {
    params ["_vehicle"];

    if (isNull _vehicle) exitWith {};
    if (_vehicle getVariable ["KFH_patrolVehicleBoostInstalled", false]) exitWith {};

    private _boost = missionNamespace getVariable ["KFH_startPatrolVehicleSpeedBoost", 1];
    if (_boost <= 1) exitWith {};

    _vehicle setVariable ["KFH_patrolVehicleBoostInstalled", true, true];
    [_vehicle, _boost, missionNamespace getVariable ["KFH_startPatrolVehicleBoostMaxKmh", 95]] spawn {
        params ["_vehicle", "_boost", "_maxKmh"];

        while { alive _vehicle } do {
            sleep 0.45;

            private _driver = driver _vehicle;
            private _speedKmh = speed _vehicle;
            if (!(isNull _driver)) then {
                if (alive _driver) then {
                    if (isEngineOn _vehicle) then {
                        if ((_speedKmh > 8) && {_speedKmh < _maxKmh}) then {
                            private _currentVelocity = velocity _vehicle;
                            private _forward = vectorDir _vehicle;
                            private _currentMs = _speedKmh / 3.6;
                            private _targetMs = ((_currentMs * _boost) min (_maxKmh / 3.6));
                            private _addMs = ((_targetMs - _currentMs) max 0) min 2.2;
                            _vehicle setVelocity [
                                (_currentVelocity select 0) + ((_forward select 0) * _addMs),
                                (_currentVelocity select 1) + ((_forward select 1) * _addMs),
                                _currentVelocity select 2
                            ];
                        };
                    };
                };
            };
        };
    };
};

KFH_fnc_spawnPatrolVehicles = {
    params ["_markerName"];

    private _players = (missionNamespace getVariable ["KFH_targetPlayers", KFH_targetPlayers]) max 1;
    private _perPlayers = (missionNamespace getVariable ["KFH_startPatrolVehiclePerPlayers", 2]) max 1;
    private _maxVehicles = missionNamespace getVariable ["KFH_startPatrolVehicleMax", 5];
    private _vehicleCount = (ceil (_players / _perPlayers)) min _maxVehicles;
    private _vehicleClass = missionNamespace getVariable ["KFH_startPatrolVehicleClass", "C_Quadbike_01_F"];
    private _fuelMin = missionNamespace getVariable ["KFH_startPatrolVehicleFuelMin", 0.04];
    private _fuelMax = missionNamespace getVariable ["KFH_startPatrolVehicleFuelMax", 0.1];
    private _spawned = [];

    for "_i" from 0 to (_vehicleCount - 1) do {
        private _side = if ((_i mod 2) isEqualTo 0) then { 1 } else { -1 };
        private _row = floor (_i / 2);
        private _offset = [(-7 * _side) - (_row * 2 * _side), -10 - (_row * 5), 0];
        private _vehicle = [_vehicleClass, _markerName, _offset, 180 + (12 * _side), false] call KFH_fnc_spawnSupportObject;
        _vehicle setFuel (_fuelMin + random ((_fuelMax - _fuelMin) max 0.01));
        _vehicle setDamage 0;
        _vehicle setVelocity [0, 0, 0];
        _vehicle lock 0;
        _vehicle setVariable ["KFH_vehicleThreatTier", "light", true];
        _vehicle setVariable ["KFH_supportLabel", "Patrol Buggy", true];
        [_vehicle] call KFH_fnc_installVehicleThreatHandlers;
        [_vehicle] call KFH_fnc_startPatrolVehicleBoost;
        [_vehicle] call KFH_fnc_appendSupportObject;
        _spawned pushBack _vehicle;
        [_vehicle, missionNamespace getVariable ["KFH_startPatrolVehicleGraceSeconds", 8]] spawn {
            params ["_vehicle", "_graceSeconds"];
            sleep _graceSeconds;
            if (alive _vehicle) then {
                _vehicle allowDamage true;
            };
        };
    };

    [format ["Patrol started with %1 fueled buggy vehicle(s). Civilian traffic and scavenged fuel still matter.", count _spawned]] call KFH_fnc_log;
    _spawned
};

KFH_fnc_spawnRouteDressing = {
    params ["_startMarker", "_checkpointMarkers", "_extractMarker"];

    if !(missionNamespace getVariable ["KFH_outbreakRouteDressingEnabled", true]) exitWith {};

    private _allMarkers = [_startMarker] + _checkpointMarkers + [_extractMarker];
    missionNamespace setVariable ["KFH_routeMarkers", _allMarkers, true];
    private _spawned = [];

    _spawned append ([_startMarker, KFH_routeRoadblockOffsets] call KFH_fnc_spawnOutbreakDressingSet);
    [_startMarker, 1] call KFH_fnc_spawnOutbreakCiviliansAtMarker;
    {
        private _dressingSets = missionNamespace getVariable ["KFH_checkpointDressingSets", [KFH_routeRoadblockOffsets]];
        private _set = if ((count _dressingSets) > 0) then { selectRandom _dressingSets } else { KFH_routeRoadblockOffsets };
        _spawned append ([_x, _set] call KFH_fnc_spawnOutbreakDressingSet);
        [_x, 1 + floor (random 3)] call KFH_fnc_spawnOutbreakCiviliansAtMarker;
    } forEach _checkpointMarkers;
    _spawned append ([_extractMarker, KFH_routeRoadblockOffsets] call KFH_fnc_spawnOutbreakDressingSet);
    [_extractMarker, 1] call KFH_fnc_spawnOutbreakCiviliansAtMarker;
    _spawned append ([_allMarkers] call KFH_fnc_spawnRouteAmbientTraffic);

    missionNamespace setVariable ["KFH_routeDressingObjects", _spawned, true];
    [format ["Outbreak dressing placed along %1 route nodes.", count _allMarkers]] call KFH_fnc_log;
};

KFH_fnc_playStoryBeat = {
    params ["_beatId", ["_checkpointIndex", 0]];

    switch (_beatId) do {
        case "start": {
            ["RETURN TO BASE"] call KFH_fnc_setStoryObjective;
            [KFH_outbreakStartDate, "軽装パトロール中。周辺通信が乱れ始めたデス。"] call KFH_fnc_setMissionDateStage;
            ["Patrol cut off by a sudden outbreak. Move checkpoint to checkpoint, scavenge fuel and supplies, then reach extraction.", "STORY"] call KFH_fnc_appendRunEvent;
            ["HQ: Patrol team, comms are degraded. Marked checkpoints are your best route back. Patrol buggies have fuel, but abandoned vehicles will be scarce."] call KFH_fnc_log;
        };
        case "firstCheckpoint": {
            ["HQ: Civilian traffic has collapsed. Expect roadblocks, abandoned vehicles, and infected contacts ahead."] call KFH_fnc_notifyAll;
        };
        case "baseLost": {
            ["BASE LOST"] call KFH_fnc_setStoryObjective;
            ["HQ: Bad news. Your original base is gone. Repeat, base is overrun. Arsenal may still be there, but it is not safe.", "STORY"] call KFH_fnc_appendRunEvent;
            ["HQ: 帰投予定基地は壊滅済みデス。装備庫だけは生きている可能性あり。行くか、脱出優先か判断して。"] call KFH_fnc_notifyAll;
            ["A3\Sounds_F\sfx\alarm_independent.wss", 2.4, 0.75] remoteExecCall ["KFH_fnc_playUiCue", 0];
        };
        case "finalCheckpoint": {
            ["ARSENAL OPTIONAL"] call KFH_fnc_setStoryObjective;
            ["HQ: Arsenal signal is live, but heavy contacts are converging. Prepare for extraction and do not forget flare capability.", "STORY"] call KFH_fnc_appendRunEvent;
            ["HQ: 装備庫オンライン。ただし重装感染体が寄ってきています。帰還準備を急いで。"] call KFH_fnc_notifyAll;
        };
        case "extractReleased": {
            ["REACH LZ"] call KFH_fnc_setStoryObjective;
            ["HQ: New LZ transmitted. Original base is lost; helicopter pickup is the only clean exit now.", "STORY"] call KFH_fnc_appendRunEvent;
            ["HQ: 別座標のヘリ LZ を送信。チームをまとめて脱出地点へ移動して。"] call KFH_fnc_notifyAll;
        };
        default {
            [format ["Story beat %1 at checkpoint %2", _beatId, _checkpointIndex], "STORY"] call KFH_fnc_appendRunEvent;
        };
    };
};

KFH_fnc_playStoryBeatOnce = {
    params ["_beatId", ["_checkpointIndex", 0]];

    private _key = format ["KFH_storyBeat_%1", _beatId];
    if (missionNamespace getVariable [_key, false]) exitWith {};

    missionNamespace setVariable [_key, true, true];
    [_beatId, _checkpointIndex] call KFH_fnc_playStoryBeat;
};

KFH_fnc_getSafeArsenalConfigClasses = {
    params ["_kind"];

    private _cacheKey = format ["KFH_safeArsenalClasses_%1", _kind];
    private _cached = missionNamespace getVariable [_cacheKey, []];
    if ((count _cached) > 0) exitWith { _cached };

    private _classes = [];
    private _skipNames = ["", "%ALL", "Throw", "Put"];

    switch (_kind) do {
        case "weapons": {
            private _root = configFile >> "CfgWeapons";
            for "_i" from 0 to ((count _root) - 1) do {
                private _cfg = _root select _i;
                if (isClass _cfg) then {
                    private _className = configName _cfg;
                    private _type = getNumber (_cfg >> "type");

                    if (
                        !(_className in _skipNames) &&
                        {getNumber (_cfg >> "scope") >= 2} &&
                        {!(getText (_cfg >> "displayName") isEqualTo "")} &&
                        {_type in [1, 2, 4]}
                    ) then {
                        _classes pushBackUnique _className;
                    };
                };
            };
        };
        case "items": {
            private _root = configFile >> "CfgWeapons";
            for "_i" from 0 to ((count _root) - 1) do {
                private _cfg = _root select _i;
                if (isClass _cfg) then {
                    private _className = configName _cfg;
                    private _type = getNumber (_cfg >> "type");

                    if (
                        !(_className in _skipNames) &&
                        {getNumber (_cfg >> "scope") >= 2} &&
                        {!(getText (_cfg >> "displayName") isEqualTo "")} &&
                        {!(_type in [0, 1, 2, 4])}
                    ) then {
                        _classes pushBackUnique _className;
                    };
                };
            };
        };
        case "magazines": {
            private _root = configFile >> "CfgMagazines";
            for "_i" from 0 to ((count _root) - 1) do {
                private _cfg = _root select _i;
                if (isClass _cfg) then {
                    private _className = configName _cfg;

                    if (
                        !(_className in _skipNames) &&
                        {getNumber (_cfg >> "scope") >= 2} &&
                        {!(getText (_cfg >> "displayName") isEqualTo "")}
                    ) then {
                        _classes pushBackUnique _className;
                    };
                };
            };
        };
        case "backpacks": {
            private _root = configFile >> "CfgVehicles";
            for "_i" from 0 to ((count _root) - 1) do {
                private _cfg = _root select _i;
                if (isClass _cfg) then {
                    private _className = configName _cfg;
                    private _parents = [_cfg, true] call BIS_fnc_returnParents;

                    if (
                        !(_className in _skipNames) &&
                        {getNumber (_cfg >> "scope") >= 2} &&
                        {!(getText (_cfg >> "displayName") isEqualTo "")} &&
                        {"Bag_Base" in _parents}
                    ) then {
                        _classes pushBackUnique _className;
                    };
                };
            };
        };
        default {};
    };

    missionNamespace setVariable [_cacheKey, _classes];
    _classes
};

KFH_fnc_setupSafeAllArsenal = {
    params ["_arsenal"];

    if (isNull _arsenal) exitWith {};

    clearWeaponCargoGlobal _arsenal;
    clearMagazineCargoGlobal _arsenal;
    clearItemCargoGlobal _arsenal;
    clearBackpackCargoGlobal _arsenal;

    ["AmmoboxInit", [_arsenal, false, { _this distance _target < 8 }]] call BIS_fnc_arsenal;

    private _weapons = ["weapons"] call KFH_fnc_getSafeArsenalConfigClasses;
    private _magazines = ["magazines"] call KFH_fnc_getSafeArsenalConfigClasses;
    private _items = ["items"] call KFH_fnc_getSafeArsenalConfigClasses;
    private _backpacks = ["backpacks"] call KFH_fnc_getSafeArsenalConfigClasses;

    [_arsenal, _weapons, true] call BIS_fnc_addVirtualWeaponCargo;
    [_arsenal, _magazines, true] call BIS_fnc_addVirtualMagazineCargo;
    [_arsenal, _items, true] call BIS_fnc_addVirtualItemCargo;
    [_arsenal, _backpacks, true] call BIS_fnc_addVirtualBackpackCargo;

    [format [
        "Safe ALL arsenal initialized: weapons=%1 magazines=%2 items=%3 backpacks=%4.",
        count _weapons,
        count _magazines,
        count _items,
        count _backpacks
    ]] call KFH_fnc_log;
};

KFH_fnc_fillCheckpointSupplyCargo = {
    params ["_ammo", "_medical", "_checkpointIndex"];

    private _players = [] call KFH_fnc_getRewardPlayerCount;
    private _tier = [_checkpointIndex] call KFH_fnc_getCheckpointRewardTier;
    private _cupOnly = (missionNamespace getVariable ["KFH_cupBanVanillaWhenAvailable", true]) &&
        {missionNamespace getVariable ["KFH_cupOptionalEnabled", true]} &&
        {isClass (configFile >> "CfgWeapons" >> (missionNamespace getVariable ["KFH_optionalContentWeaponProbe", "rhs_weap_m4a1"]))};

    if !(isNull _ammo) then {
        clearWeaponCargoGlobal _ammo;
        clearMagazineCargoGlobal _ammo;
        clearItemCargoGlobal _ammo;
        clearBackpackCargoGlobal _ammo;

        if (!_cupOnly) then {
            _ammo addMagazineCargoGlobal ["30Rnd_9x21_Mag", 12 + (_players * 2)];
            _ammo addMagazineCargoGlobal ["30Rnd_45ACP_Mag_SMG_01", 8 + _players];
            _ammo addMagazineCargoGlobal ["30Rnd_556x45_Stanag", 8 + _players];
            [_ammo, "acc_flashlight", 2] call KFH_fnc_addOptionalItemCargo;
            [_ammo, "optic_Aco", 1] call KFH_fnc_addOptionalItemCargo;
            [_ammo, "optic_ACO_grn_smg", 1] call KFH_fnc_addOptionalItemCargo;
        };
        _ammo addMagazineCargoGlobal ["HandGrenade", 2 + floor (_players / 3)];
        _ammo addMagazineCargoGlobal ["SmokeShell", 3 + ceil (_players / 4)];
        _ammo addItemCargoGlobal ["FirstAidKit", 4 + _players];

        if (missionNamespace getVariable ["KFH_cupOptionalEnabled", true]) then {
            [_ammo, "rhs_weap_m4a1", 1] call KFH_fnc_addOptionalWeaponCargo;
            [_ammo, "rhs_mag_30Rnd_556x45_M855A1_Stanag", 8 + _players] call KFH_fnc_addOptionalMagazineCargo;
            [_ammo, "optic_Arco", 1] call KFH_fnc_addOptionalItemCargo;
            [_ammo, "rhs_weap_ak74m", 1] call KFH_fnc_addOptionalWeaponCargo;
            [_ammo, "rhs_30Rnd_545x39_7N10_AK", 8 + _players] call KFH_fnc_addOptionalMagazineCargo;
            [_ammo, "rhs_acc_ekp1", 1] call KFH_fnc_addOptionalItemCargo;
            if (_tier >= 2) then {
                [_ammo, "rhs_weap_M136", 1] call KFH_fnc_addOptionalWeaponCargo;
                [_ammo, "rhs_m136_mag", 1] call KFH_fnc_addOptionalMagazineCargo;
            };
        };
    };

    if !(isNull _medical) then {
        clearWeaponCargoGlobal _medical;
        clearMagazineCargoGlobal _medical;
        clearItemCargoGlobal _medical;
        clearBackpackCargoGlobal _medical;

        _medical addItemCargoGlobal ["FirstAidKit", 8 + _players];
        if ((random 1) < (missionNamespace getVariable ["KFH_rewardMedikitChanceTier3", 0.18])) then {
            _medical addItemCargoGlobal ["Medikit", 1];
        };
        _medical addItemCargoGlobal ["ToolKit", 1 + floor (_players / 6)];
        _medical addBackpackCargoGlobal ["B_AssaultPack_rgr", 1 + floor (_players / 4)];
        _medical addMagazineCargoGlobal ["SmokeShell", 2 + ceil (_players / 4)];
        [_medical, "NVGoggles", 1] call KFH_fnc_addOptionalItemCargo;
    };

    [format ["Checkpoint %1 supply cargo filled for %2-player scale.", _checkpointIndex, _players]] call KFH_fnc_log;
};

KFH_fnc_spawnSupportFob = {
    params ["_markerName"];

    private _supportObjects = [];

    private _ammo = ["Box_NATO_Ammo_F", _markerName, KFH_supportAmmoOffset, 180] call KFH_fnc_spawnSupportObject;
    _ammo setVariable ["KFH_supportType", "ammo", true];
    _ammo setVariable ["KFH_supportLabel", "Ammo Cache", true];
    clearWeaponCargoGlobal _ammo;
    clearMagazineCargoGlobal _ammo;
    clearItemCargoGlobal _ammo;
    clearBackpackCargoGlobal _ammo;
    _supportObjects pushBack _ammo;

    private _medical = ["Box_NATO_Equip_F", _markerName, KFH_supportMedicalOffset, 180] call KFH_fnc_spawnSupportObject;
    _medical setVariable ["KFH_supportType", "medical", true];
    _medical setVariable ["KFH_supportLabel", "Medical Station", true];
    clearWeaponCargoGlobal _medical;
    clearMagazineCargoGlobal _medical;
    clearItemCargoGlobal _medical;
    clearBackpackCargoGlobal _medical;
    _supportObjects pushBack _medical;

    private _repair = [KFH_repairStationClass, _markerName, KFH_supportRepairOffset, 270] call KFH_fnc_spawnSupportObject;
    _repair setDamage 0;
    _repair setVariable ["KFH_supportType", "repair", true];
    _repair setVariable ["KFH_supportLabel", "Field Maintenance", true];
    _supportObjects pushBack _repair;

    if (
        is3DENPreview &&
        {missionNamespace getVariable ["KFH_debugEdenStartArsenalEnabled", true]}
    ) then {
        private _arsenal = [
            "B_supplyCrate_F",
            _markerName,
            missionNamespace getVariable ["KFH_debugEdenStartArsenalOffset", [-5, -6, 0]],
            180
        ] call KFH_fnc_spawnSupportObject;
        _arsenal allowDamage false;
        _arsenal setVariable ["KFH_supportType", "arsenal", true];
        _arsenal setVariable ["KFH_supportLabel", "Debug Arsenal", true];
        [_arsenal] call KFH_fnc_setupSafeAllArsenal;
        _supportObjects pushBack _arsenal;
    };

    {
        _x params ["_className", "_offset", "_dirOffset"];
        private _decor = [_className, _markerName, _offset, _dirOffset] call KFH_fnc_spawnSupportObject;
        _supportObjects pushBack _decor;
    } forEach KFH_supportDecor;

    missionNamespace setVariable ["KFH_supportObjects", _supportObjects, true];
    _supportObjects
};

KFH_fnc_spawnCheckpointSupport = {
    params ["_markerName", "_checkpointIndex"];

    private _ammo = ["Box_NATO_Wps_F", _markerName, KFH_checkpointAmmoOffset, 180] call KFH_fnc_spawnSupportObject;
    _ammo setVariable ["KFH_supportType", "ammo", true];
    _ammo setVariable ["KFH_supportLabel", format ["Checkpoint %1 Resupply", _checkpointIndex], true];
    clearWeaponCargoGlobal _ammo;
    clearMagazineCargoGlobal _ammo;
    clearItemCargoGlobal _ammo;
    clearBackpackCargoGlobal _ammo;
    [_ammo] call KFH_fnc_appendSupportObject;

    private _medical = ["Box_NATO_Equip_F", _markerName, KFH_checkpointMedicalOffset, 180] call KFH_fnc_spawnSupportObject;
    _medical setVariable ["KFH_supportType", "medical", true];
    _medical setVariable ["KFH_supportLabel", format ["Checkpoint %1 Aid Station", _checkpointIndex], true];
    clearWeaponCargoGlobal _medical;
    clearMagazineCargoGlobal _medical;
    clearItemCargoGlobal _medical;
    clearBackpackCargoGlobal _medical;
    [_ammo, _medical, _checkpointIndex] call KFH_fnc_fillCheckpointSupplyCargo;
    [_medical] call KFH_fnc_appendSupportObject;

    private _landmarkKey = format ["KFH_checkpointLandmarks_%1", _checkpointIndex];
    private _landmarks = missionNamespace getVariable [_landmarkKey, []];

    {
        private _beacon = ["MetalBarrel_burning_F", _markerName, _x, 0] call KFH_fnc_spawnSupportObject;
        _beacon setVariable ["KFH_supportLabel", format ["Checkpoint %1 Beacon", _checkpointIndex], true];
        _beacon allowDamage false;
        _landmarks pushBack _beacon;
        [_beacon] call KFH_fnc_appendSupportObject;
    } forEach KFH_checkpointBeaconOffsets;
    missionNamespace setVariable [_landmarkKey, _landmarks];

    [_ammo, _medical]
};

KFH_fnc_spawnCheckpointLandmarks = {
    params ["_markerName", "_checkpointIndex"];

    private _landmarkKey = format ["KFH_checkpointLandmarks_%1", _checkpointIndex];
    private _landmarks = [];
    private _sets = missionNamespace getVariable ["KFH_checkpointDressingSets", [KFH_checkpointDressingOffsets]];
    private _setNames = missionNamespace getVariable ["KFH_checkpointDressingSetNames", ["Outbreak Site"]];
    private _setIndex = ((_checkpointIndex - 1) max 0) mod ((count _sets) max 1);
    private _entries = _sets select _setIndex;
    private _setName = _setNames select (_setIndex min ((count _setNames) - 1));

    {
        _x params ["_className", "_offset", ["_dirOffset", 0], ["_damage", 0], ["_allowDamage", false]];
        private _object = [_className, _markerName, _offset, _dirOffset, _damage, _allowDamage] call KFH_fnc_spawnOutbreakObject;
        if !(isNull _object) then {
            _object setVariable ["KFH_supportLabel", format ["Checkpoint %1 %2", _checkpointIndex, _setName], true];
            _landmarks pushBack _object;
        };
    } forEach _entries;

    _landmarks append ([_markerName, _checkpointIndex] call KFH_fnc_spawnCheckpointMobilityVehicles);
    [_markerName, 1 + floor (random 2)] call KFH_fnc_spawnOutbreakCiviliansAtMarker;

    missionNamespace setVariable [_landmarkKey, _landmarks];
    [format ["Checkpoint %1 dressing spawned: %2 (%3 objects).", _checkpointIndex, _setName, count _landmarks]] call KFH_fnc_log;
    _landmarks
};

KFH_fnc_startCheckpointDefenseEvent = {
    params ["_checkpointIndex", "_checkpointMarker", ["_hostileCount", 0]];

    private _stateKey = format ["KFH_checkpointDefenseStarted_%1", _checkpointIndex];
    if (missionNamespace getVariable [_stateKey, false]) exitWith {};

    missionNamespace setVariable [_stateKey, true, true];
    [format [
        "Checkpoint %1 defensive event started. %3 Hostiles: %2.",
        _checkpointIndex,
        _hostileCount,
        [_checkpointIndex] call KFH_fnc_getCheckpointEventSummary
    ]] call KFH_fnc_notifyAll;
    ["A3\Sounds_F\sfx\blip1.wss", 1.9, 0.78] remoteExecCall ["KFH_fnc_playUiCue", 0];

    switch ([_checkpointIndex] call KFH_fnc_getCheckpointEventId) do {
        case "surge": {
            [_checkpointIndex, 0.45] call KFH_fnc_spawnCheckpointWave;
            [format ["Checkpoint %1 event: Hive Surge triggered an extra contact wave.", _checkpointIndex]] call KFH_fnc_notifyAll;
        };
        case "hunter": {
            [_checkpointIndex, _checkpointMarker] call KFH_fnc_spawnSpecialCarrierEncounter;
        };
        default {};
    };

    if (
        (_checkpointIndex <= (missionNamespace getVariable ["KFH_checkpointSecureCooldownEarlyUntil", 4])) &&
        {_hostileCount <= 0}
    ) then {
        [_checkpointIndex, 0.35] call KFH_fnc_spawnCheckpointWave;
        [format ["Checkpoint %1 noise drew a blocking contact. Clear it before securing.", _checkpointIndex]] call KFH_fnc_notifyAll;
    };
};

KFH_fnc_scheduleCheckpointSupplyArrival = {
    params ["_checkpointIndex", "_checkpointMarker"];

    private _scheduledKey = format ["KFH_checkpointSupplyScheduled_%1", _checkpointIndex];
    private _arrivedKey = format ["KFH_checkpointSupplyArrived_%1", _checkpointIndex];

    if (missionNamespace getVariable [_scheduledKey, false]) exitWith {};
    if (missionNamespace getVariable [_arrivedKey, false]) exitWith {};

    missionNamespace setVariable [_scheduledKey, true, true];
    [format [
        "HQ: CP%1 secure. Supply team may reach this position in about %2 seconds. Holding here could pay off.",
        _checkpointIndex,
        [_checkpointIndex] call KFH_fnc_getCheckpointSupplyDelay
    ]] call KFH_fnc_notifyAll;

    [_checkpointIndex, _checkpointMarker, _scheduledKey, _arrivedKey] spawn {
        params ["_checkpointIndex", "_checkpointMarker", "_scheduledKey", "_arrivedKey"];

        sleep ([_checkpointIndex] call KFH_fnc_getCheckpointSupplyDelay);

        if ((missionNamespace getVariable ["KFH_phase", "boot"]) in ["complete", "failed"]) exitWith {};
        if (missionNamespace getVariable [_arrivedKey, false]) exitWith {};

        private _supportObjects = [_checkpointMarker, _checkpointIndex] call KFH_fnc_spawnCheckpointSupport;
        {
            if !(isNull _x) then {
                _x setDamage 0;
            };
        } forEach _supportObjects;

        missionNamespace setVariable [_arrivedKey, true, true];
        private _supplyStates = missionNamespace getVariable ["KFH_checkpointSupplyStates", []];
        if ((_checkpointIndex - 1) < (count _supplyStates)) then {
            _supplyStates set [_checkpointIndex - 1, true];
            missionNamespace setVariable ["KFH_checkpointSupplyStates", _supplyStates, true];
        };
        [] call KFH_fnc_refreshStrategicState;
        [format [
            "Supply team reached CP%1. Ammo, medical kit, and repair kit support are now online.",
            _checkpointIndex
        ]] call KFH_fnc_notifyAll;
        ["A3\Sounds_F\sfx\blip1.wss", 2.2, 0.6] remoteExecCall ["KFH_fnc_playUiCue", 0];
    };
};

KFH_fnc_doAmmoSupport = {
    params ["_caller"];

    private _damage = damage _caller;
    private _loadout = _caller getVariable ["KFH_savedLoadout", getUnitLoadout _caller];

    _caller setUnitLoadout _loadout;
    _caller setDamage _damage;
    _caller setFatigue 0;
    [_caller] call KFH_fnc_updateSavedLoadout;

    ["Loadout restored from ammo cache."] call KFH_fnc_localNotify;
};

KFH_fnc_doMedicalSupport = {
    params ["_caller"];

    _caller setVariable ["KFH_forcedDowned", false, true];
    _caller setVariable ["KFH_forcedDownedAt", -1, true];
    _caller allowDamage true;
    _caller setCaptive false;
    _caller setUnconscious false;
    _caller enableSimulation true;
    _caller switchMove "";
    _caller setDamage 0;
    _caller setFatigue 0;
    [_caller] call KFH_fnc_applyPrototypeCarryCapacity;

    if (local _caller) then {
        [] call KFH_fnc_scheduleLocalReviveCleanup;
    };

    ["Medical station patched you up."] call KFH_fnc_localNotify;
};

KFH_fnc_doRepairSupport = {
    params ["_target", "_caller"];

    private _nearVehicles = nearestObjects [_target, ["LandVehicle", "Air", "Ship"], 20];

    {
        _x setDamage 0;
        _x setFuel 1;
        _x setVehicleAmmo 1;
    } forEach _nearVehicles;

    _caller setFatigue 0;
    [_caller] call KFH_fnc_applyPrototypeCarryCapacity;

    if ((count _nearVehicles) > 0) then {
        [format ["Field maintenance serviced %1 vehicle(s).", count _nearVehicles]] call KFH_fnc_localNotify;
    } else {
        ["Field maintenance reset your stamina. No vehicles nearby."] call KFH_fnc_localNotify;
    };
};

KFH_fnc_saveLoadoutSnapshot = {
    params ["_unit", ["_loadout", []], ["_reason", "snapshot"]];

    if (isNull _unit) exitWith {};
    if ((count _loadout) isEqualTo 0) then {
        _loadout = getUnitLoadout _unit;
    };

    _unit setVariable ["KFH_savedLoadout", _loadout, true];

    if (isPlayer _unit) then {
        private _uid = getPlayerUID _unit;
        if !(_uid isEqualTo "") then {
            missionNamespace setVariable [format ["KFH_savedLoadout_%1", _uid], _loadout, true];
        };
    };

    [format ["Loadout snapshot saved for %1 reason=%2.", name _unit, _reason]] call KFH_fnc_log;
};

KFH_fnc_updateSavedLoadout = {
    params ["_unit", ["_reason", "update"]];

    if (isNull _unit) exitWith {};
    if !(alive _unit) exitWith {};

    [_unit, [], _reason] call KFH_fnc_saveLoadoutSnapshot;
};

KFH_fnc_ensureNavigationItems = {
    params ["_unit"];

    if (isNull _unit) exitWith {};

    {
        if !(_x in assignedItems _unit) then {
            _unit linkItem _x;
        };
    } forEach ["ItemMap", "ItemCompass", "ItemWatch", "ItemRadio", "ItemGPS"];
};

KFH_fnc_getSavedLoadout = {
    params ["_unit", ["_corpse", objNull]];

    private _loadout = [];
    if (!isNull _corpse) then {
        _loadout = _corpse getVariable ["KFH_savedLoadout", []];
    };
    if (((count _loadout) isEqualTo 0) && {!isNull _unit}) then {
        _loadout = _unit getVariable ["KFH_savedLoadout", []];
    };
    if (((count _loadout) isEqualTo 0) && {!isNull _unit} && {isPlayer _unit}) then {
        private _uid = getPlayerUID _unit;
        if !(_uid isEqualTo "") then {
            _loadout = missionNamespace getVariable [format ["KFH_savedLoadout_%1", _uid], []];
        };
    };

    _loadout
};

KFH_fnc_installLoadoutSnapshotHandlers = {
    params ["_unit"];

    if (isNull _unit) exitWith {};
    if (_unit getVariable ["KFH_loadoutSnapshotHandlersInstalled", false]) exitWith {};

    _unit setVariable ["KFH_loadoutSnapshotHandlersInstalled", true];
    _unit addEventHandler ["InventoryClosed", {
        params ["_unit"];
        [_unit, "inventory closed"] call KFH_fnc_updateSavedLoadout;
    }];
    _unit addEventHandler ["Take", {
        params ["_unit"];
        [_unit, "item taken"] call KFH_fnc_updateSavedLoadout;
    }];
    _unit addEventHandler ["Put", {
        params ["_unit"];
        [_unit, "item put"] call KFH_fnc_updateSavedLoadout;
    }];
    _unit addEventHandler ["Killed", {
        params ["_unit"];
        if (isPlayer _unit) then {
            missionNamespace setVariable ["KFH_lastHumanCasualtyAt", time, true];
        };
        [_unit, [], "killed"] call KFH_fnc_saveLoadoutSnapshot;
    }];
};

KFH_fnc_installArsenalLoadoutTracker = {
    if !(hasInterface) exitWith {};
    if (missionNamespace getVariable ["KFH_arsenalLoadoutTrackerInstalled", false]) exitWith {};

    missionNamespace setVariable ["KFH_arsenalLoadoutTrackerInstalled", true];
    [missionNamespace, "arsenalClosed", {
        if (!isNull player && {alive player}) then {
            [player, "arsenal closed"] call KFH_fnc_updateSavedLoadout;
        };
    }] call BIS_fnc_addScriptedEventHandler;
};

KFH_fnc_installFlareSignalHandler = {
    params ["_unit"];

    if (isNull _unit) exitWith {};
    if (_unit getVariable ["KFH_flareSignalHandlerInstalled", false]) exitWith {};

    _unit setVariable ["KFH_flareSignalHandlerInstalled", true];
    _unit addEventHandler ["FiredMan", {
        params ["_unit", "_weapon", "_muzzle", "_mode", "_ammo", "_magazine", "_projectile"];

        if ((missionNamespace getVariable ["KFH_phase", "boot"]) isNotEqualTo "extract") exitWith {};
        if !([_weapon, _ammo] call KFH_fnc_isFlareShot) exitWith {};

        [_unit, getPosATL _unit, _weapon, _ammo] remoteExecCall ["KFH_fnc_reportFlareLaunch", 2];
    }];
};

KFH_fnc_isIncapacitated = {
    params ["_unit"];

    if (isNull _unit) exitWith { false };
    if !(alive _unit) exitWith { false };

    (_unit getVariable ["KFH_forcedDowned", false]) ||
    {((lifeState _unit) isEqualTo "INCAPACITATED") || {!((incapacitatedState _unit) isEqualTo "")}}
};

KFH_fnc_getIncapacitatedPlayers = {
    ([] call KFH_fnc_getHumanPlayers) select {
        [_x] call KFH_fnc_isIncapacitated
    }
};

KFH_fnc_getHumanRescuersFor = {
    params ["_unit"];

    ([] call KFH_fnc_getHumanPlayers) select {
        _x != _unit &&
        {alive _x} &&
        {!([_x] call KFH_fnc_isIncapacitated)}
    }
};

KFH_fnc_getDebugTeammates = {
    private _debugTeammates = allUnits select {
        (_x getVariable ["KFH_debugTeammate", false]) ||
        {_x getVariable ["KFH_soloWingman", false]} ||
        {_x getVariable ["KFH_scalingTestAlly", false]}
    };
    private _stored = missionNamespace getVariable ["KFH_debugTeammate", objNull];
    if (!isNull _stored) then {
        _debugTeammates pushBackUnique _stored;
    };

    _debugTeammates
};

KFH_fnc_getMonitoredFriendlies = {
    private _friendlies = +([] call KFH_fnc_getHumanPlayers);
    private _debugTeammates = [] call KFH_fnc_getDebugTeammates;
    private _debugTeammate = missionNamespace getVariable ["KFH_debugTeammate", objNull];

    {
        _friendlies pushBackUnique _x;
    } forEach _debugTeammates;

    if (!isNull _debugTeammate) then {
        _friendlies pushBackUnique _debugTeammate;
    };

    _friendlies
};

KFH_fnc_getAliveMonitoredFriendlies = {
    ([] call KFH_fnc_getMonitoredFriendlies) select {
        alive _x
    }
};

KFH_fnc_getCombatReadyHumans = {
    ([] call KFH_fnc_getHumanPlayers) select {
        alive _x && !([_x] call KFH_fnc_isIncapacitated)
    }
};

KFH_fnc_getCombatReadyFriendlies = {
    ([] call KFH_fnc_getMonitoredFriendlies) select {
        alive _x && !([_x] call KFH_fnc_isIncapacitated)
    }
};

KFH_fnc_getPotentialRescuers = {
    ([] call KFH_fnc_getDebugTeammates) select {
        alive _x &&
        canMove _x &&
        !([_x] call KFH_fnc_isIncapacitated)
    }
};

KFH_fnc_hasRescueCoverageFor = {
    params ["_unit"];

    private _rescuers = [] call KFH_fnc_getPotentialRescuers;
    _rescuers append ([_unit] call KFH_fnc_getHumanRescuersFor);
    (count _rescuers) > 0
};

KFH_fnc_clearReviveVisualEffectsLocal = {
    if (!hasInterface) exitWith {};

    {
        _x ppEffectEnable false;
        _x ppEffectCommit 0;
    } forEach [
        "dynamicBlur",
        "DynamicBlur",
        "radialBlur",
        "RadialBlur",
        "ColorCorrections",
        "colorCorrections"
    ];

    if !(isNil "ace_medical_effectUnconsciousCC") then {
        ace_medical_effectUnconsciousCC ppEffectEnable false;
    };
    if !(isNil "ace_medical_effectUnconsciousRB") then {
        ace_medical_effectUnconsciousRB ppEffectEnable false;
    };
    if !(isNil "ace_medical_effectBlind") then {
        ace_medical_effectBlind = false;
    };
    if !(isNil "ace_common_fnc_setDisableUserInputStatus") then {
        ["unconscious", false] call ace_common_fnc_setDisableUserInputStatus;
    };

    disableUserInput false;
    resetCamShake;
    showCommandingMenu "";
    showCinemaBorder false;
    if !(isNil "KFH_fnc_stopDownedSpectator") then {
        [] call KFH_fnc_stopDownedSpectator;
    };
    missionNamespace setVariable ["KFH_postReviveBlurUntil", -1];
};

KFH_fnc_restoreLocalPlayerControl = {
    if (!hasInterface) exitWith {};
    if (isNull player) exitWith {};

    player setVariable ["KFH_forcedDowned", false, true];
    player setVariable ["KFH_forcedDownedAt", -1, true];
    player setVariable ["BIS_revive_incapacitated", false, true];
    player setVariable ["BIS_revive_isIncapacitated", false, true];
    player setVariable ["BIS_revive_unconscious", false, true];
    player allowDamage true;
    player setCaptive false;
    player setUnconscious false;
    player enableSimulation true;
    player switchMove "";
    [player] call KFH_fnc_applyPrototypeCarryCapacity;
    [] call KFH_fnc_clearReviveVisualEffectsLocal;
};

KFH_fnc_scheduleLocalReviveCleanup = {
    if (!hasInterface) exitWith {};

    private _cleanupSeconds = missionNamespace getVariable ["KFH_reviveCleanupSeconds", 1.2];
    private _animationBuffer = if (missionNamespace getVariable ["KFH_reviveGetUpAnimationEnabled", true]) then {
        (missionNamespace getVariable ["KFH_reviveGetUpAnimationSeconds", 3.6]) + 0.45
    } else {
        0
    };
    private _startAt = time + (_cleanupSeconds max _animationBuffer);
    missionNamespace setVariable ["KFH_reviveCleanupUntil", _startAt];
    [] spawn {
        private _until = missionNamespace getVariable ["KFH_reviveCleanupUntil", time + 1.2];
        waitUntil { time >= _until };
        private _endAt = time + 0.8;
        while { time <= _endAt } do {
            if (!isNull player && {alive player} && {!(player getVariable ["KFH_forcedDowned", false])}) then {
                [] call KFH_fnc_restoreLocalPlayerControl;
            };
            sleep 0.25;
        };
        missionNamespace setVariable ["KFH_reviveCleanupUntil", -1];
    };
};

KFH_fnc_startPostReviveBlurLocal = {
    if (!hasInterface) exitWith {};

    private _duration = missionNamespace getVariable ["KFH_postReviveBlurSeconds", 30];
    if (_duration <= 0) exitWith {
        [] call KFH_fnc_clearReviveVisualEffectsLocal;
    };

    "dynamicBlur" ppEffectEnable true;
    "dynamicBlur" ppEffectAdjust [1.15];
    "dynamicBlur" ppEffectCommit 0;
    "dynamicBlur" ppEffectAdjust [0.28];
    "dynamicBlur" ppEffectCommit 1.2;
    missionNamespace setVariable ["KFH_postReviveBlurUntil", time + _duration];
};

KFH_fnc_applyPostReviveSafetyGrace = {
    params ["_unit", ["_seconds", -1]];

    if (isNull _unit) exitWith {};
    if (!local _unit) exitWith {
        [_unit, _seconds] remoteExecCall ["KFH_fnc_applyPostReviveSafetyGrace", _unit];
    };

    if (_seconds < 0) then {
        _seconds = missionNamespace getVariable ["KFH_postReviveInvulnerabilitySeconds", 5];
    };
    if (_seconds <= 0) exitWith {};

    private _until = time + _seconds;
    _unit setVariable ["KFH_postReviveProtectedUntil", _until, true];
    _unit allowDamage false;

    [_unit, _until] spawn {
        params ["_trackedUnit", "_until"];
        sleep ((_until - time) max 0);
        if (
            !isNull _trackedUnit &&
            {alive _trackedUnit} &&
            {!(_trackedUnit getVariable ["KFH_forcedDowned", false])} &&
            {(_trackedUnit getVariable ["KFH_postReviveProtectedUntil", -1]) <= _until}
        ) then {
            _trackedUnit allowDamage true;
            _trackedUnit setVariable ["KFH_postReviveProtectedUntil", -1, true];
        };
    };
};

KFH_fnc_playReviveGetUpAnimation = {
    params ["_unit"];

    if (isNull _unit) exitWith {};
    if (!local _unit) exitWith {
        [_unit] remoteExecCall ["KFH_fnc_playReviveGetUpAnimation", _unit];
    };
    if !(missionNamespace getVariable ["KFH_reviveGetUpAnimationEnabled", true]) exitWith {
        _unit switchMove "";
    };

    private _hasPrimary = (primaryWeapon _unit) isNotEqualTo "";
    private _proneAnim = if (_hasPrimary) then {
        missionNamespace getVariable ["KFH_reviveGetUpAnimationProne", "AmovPpneMstpSrasWrflDnon"]
    } else {
        missionNamespace getVariable ["KFH_reviveGetUpAnimationProneUnarmed", "AmovPpneMstpSnonWnonDnon"]
    };
    private _getUpAnim = if (_hasPrimary) then {
        missionNamespace getVariable ["KFH_reviveGetUpAnimation", "AmovPpneMstpSrasWrflDnon_AmovPercMstpSrasWrflDnon"]
    } else {
        missionNamespace getVariable ["KFH_reviveGetUpAnimationUnarmed", "AmovPpneMstpSnonWnonDnon_AmovPercMstpSnonWnonDnon"]
    };
    private _seconds = missionNamespace getVariable ["KFH_reviveGetUpAnimationSeconds", 3.6];
    private _speedCoef = missionNamespace getVariable ["KFH_reviveGetUpAnimationSpeedCoef", 0.55];
    private _restoreSpeed = missionNamespace getVariable ["KFH_playerAnimSpeedCoef", 1];
    _unit setVariable ["KFH_reviveGetUpAnimatingUntil", time + _seconds, true];

    _unit switchMove _proneAnim;
    _unit setUnitPos "DOWN";
    _unit setAnimSpeedCoef _speedCoef;

    [_unit, _getUpAnim, time + _seconds, _restoreSpeed] spawn {
        params ["_trackedUnit", "_anim", "_until", "_restoreSpeed"];
        sleep 0.2;
        if (
            !isNull _trackedUnit &&
            {alive _trackedUnit} &&
            {!(_trackedUnit getVariable ["KFH_forcedDowned", false])}
        ) then {
            _trackedUnit switchMove "";
            _trackedUnit playMoveNow _anim;
        };
        sleep ((_until - time) max 0);
        if (
            !isNull _trackedUnit &&
            {alive _trackedUnit} &&
            {!(_trackedUnit getVariable ["KFH_forcedDowned", false])}
        ) then {
            _trackedUnit setUnitPos "AUTO";
            _trackedUnit setAnimSpeedCoef _restoreSpeed;
            _trackedUnit setVariable ["KFH_reviveGetUpAnimatingUntil", -1, true];
        };
    };
};

KFH_fnc_findVehicleCasualtySafePosition = {
    params ["_vehicle", ["_rescuer", objNull]];

    if (isNull _vehicle) exitWith { [] };

    private _origin = getPosATL _vehicle;
    private _safeDistance = missionNamespace getVariable ["KFH_vehicleCasualtyPullSafeDistance", 12];
    private _maxDistance = missionNamespace getVariable ["KFH_vehicleCasualtyPullMaxDistance", 55];
    private _maxObjectiveDistance = missionNamespace getVariable ["KFH_vehicleCasualtyPullMaxObjectiveDistance", 520];
    private _objectiveFallbackDistance = missionNamespace getVariable ["KFH_vehicleCasualtyPullObjectiveFallbackDistance", 85];
    private _invalidMargin = missionNamespace getVariable ["KFH_vehicleCasualtyInvalidWorldMargin", 25];
    private _objectivePos = [];
    private _currentCheckpoint = missionNamespace getVariable ["KFH_currentCheckpoint", 0];
    private _checkpointMarkers = missionNamespace getVariable ["KFH_checkpointMarkers", []];
    if (_currentCheckpoint > 0 && {_currentCheckpoint <= (count _checkpointMarkers)}) then {
        _objectivePos = getMarkerPos (_checkpointMarkers select (_currentCheckpoint - 1));
    };
    private _hasObjective = (count _objectivePos) >= 2;
    private _worldSize = worldSize max 1000;
    private _originInvalid =
        ((count _origin) < 2) ||
        {(_origin select 0) < _invalidMargin} ||
        {(_origin select 1) < _invalidMargin} ||
        {(_origin select 0) > (_worldSize - _invalidMargin)} ||
        {(_origin select 1) > (_worldSize - _invalidMargin)};
    if (_originInvalid && {_hasObjective}) then {
        _origin = _objectivePos getPos [_objectiveFallbackDistance, random 360];
        _origin set [2, 0];
        [format ["Vehicle casualty pull used objective fallback because vehicle position was invalid: %1.", _origin]] call KFH_fnc_log;
    };

    private _directions = [];

    if !(isNull _rescuer) then {
        _directions pushBack (_origin getDir (getPosATL _rescuer));
    };

    _directions append [
        (getDir _vehicle) + 90,
        (getDir _vehicle) - 90,
        (getDir _vehicle) + 180,
        random 360
    ];

    private _result = [];
    {
        if (_result isEqualTo []) then {
            for "_step" from 0 to 3 do {
                if (_result isEqualTo []) then {
                    private _distance = _safeDistance + (_step * 4);
                    private _seed = _origin getPos [_distance, _x + ((random 28) - 14)];
                    private _candidate = [_seed, 0, 5, 1, 0, 0.45, 0] call BIS_fnc_findSafePos;
                    if ((count _candidate) < 3) then {
                        _candidate set [2, 0];
                    };

                    if (
                        !surfaceIsWater _candidate &&
                        {(_candidate distance2D _origin) >= (_safeDistance - 2)} &&
                        {(_candidate distance2D _origin) <= _maxDistance} &&
                        {!_originInvalid || {!_hasObjective} || {(_candidate distance2D _objectivePos) <= _maxObjectiveDistance}}
                    ) then {
                        _result = +_candidate;
                    };
                };
            };
        };
    } forEach _directions;

    if (_result isEqualTo []) then {
        _result = if (_originInvalid && {_hasObjective}) then {
            _objectivePos getPos [_objectiveFallbackDistance, random 360]
        } else {
            _origin getPos [_safeDistance, random 360]
        };
        _result set [2, 0];
    };

    _result
};

KFH_fnc_extractCasualtyFromVehicle = {
    params ["_casualty", ["_rescuer", objNull], ["_reason", "pull injured"]];

    if !(missionNamespace getVariable ["KFH_vehicleCasualtyPullEnabled", true]) exitWith { false };
    if (isNull _casualty || {!alive _casualty}) exitWith { false };

    if (!local _casualty) exitWith {
        [_casualty, _rescuer, _reason] remoteExecCall ["KFH_fnc_extractCasualtyFromVehicle", _casualty];
        true
    };

    private _vehicle = vehicle _casualty;
    if (_vehicle isEqualTo _casualty) exitWith { false };

    private _safePos = [_vehicle, _rescuer] call KFH_fnc_findVehicleCasualtySafePosition;

    unassignVehicle _casualty;
    moveOut _casualty;
    _casualty setPosATL _safePos;
    _casualty setVelocity [0, 0, 0];
    _casualty setDir (_safePos getDir (getPosATL _vehicle));
    _casualty setVariable ["KFH_lastVehicleExtractedAt", time, true];

    private _immunitySeconds = missionNamespace getVariable ["KFH_vehicleCasualtyPullImmunitySeconds", 6];
    _casualty allowDamage false;
    [_casualty, time + _immunitySeconds] spawn {
        params ["_trackedUnit", "_until"];
        sleep ((_until - time) max 0);
        private _postReviveUntil = _trackedUnit getVariable ["KFH_postReviveProtectedUntil", -1];
        if (
            !isNull _trackedUnit &&
            {alive _trackedUnit} &&
            {!(_trackedUnit getVariable ["KFH_forcedDowned", false])} &&
            {_postReviveUntil <= time}
        ) then {
            _trackedUnit allowDamage true;
        };
    };

    [format [
        "Vehicle casualty extracted: %1 from %2 reason=%3.",
        name _casualty,
        typeOf _vehicle,
        _reason
    ]] call KFH_fnc_log;

    true
};

KFH_fnc_forceUnitDowned = {
    params ["_unit", ["_source", objNull], ["_reason", "fatal damage"]];

    if (isNull _unit) exitWith {};
    if !(alive _unit) exitWith {};

    _unit setVariable ["KFH_forcedDowned", true, true];
    _unit setVariable ["KFH_forcedDownedAt", time, true];
    if ((vehicle _unit) isNotEqualTo _unit) then {
        _unit setVariable ["KFH_downedInsideVehicle", vehicle _unit, true];
        _unit setVariable ["KFH_needsVehiclePull", true, true];
    } else {
        _unit setVariable ["KFH_downedInsideVehicle", objNull, true];
        _unit setVariable ["KFH_needsVehiclePull", false, true];
    };
    _unit setCaptive true;
    _unit setDamage (missionNamespace getVariable ["KFH_forcedDownedDamage", 0.86]);
    _unit allowDamage false;
    _unit switchMove "AinjPpneMstpSnonWrflDnon";

    if (isPlayer _unit) then {
        missionNamespace setVariable ["KFH_lastHumanCasualtyAt", time, true];
        if (local _unit) then {
            missionNamespace setVariable ["KFH_reviveCleanupUntil", -1];
            ["Downed. Hold on for revive support."] call KFH_fnc_localNotify;
        };
    };

    [format [
        "Forced downed state armed for %1 reason=%2 source=%3 rescuers=%4.",
        name _unit,
        _reason,
        if (isNull _source) then { "unknown" } else { typeOf _source },
        count ([] call KFH_fnc_getPotentialRescuers)
    ]] call KFH_fnc_log;
};

KFH_fnc_reviveUnitFromDowned = {
    params ["_casualty", ["_healDamage", missionNamespace getVariable ["KFH_revivedDamage", 0.35]]];

    if (isNull _casualty) exitWith {};

    if (!local _casualty) exitWith {
        [_casualty, _healDamage] remoteExecCall ["KFH_fnc_reviveUnitFromDowned", _casualty];
    };

    private _vehicleAtDowned = _casualty getVariable ["KFH_downedInsideVehicle", objNull];
    private _wasVehicleCasualty =
        ((vehicle _casualty) isNotEqualTo _casualty) ||
        {!isNull _vehicleAtDowned} ||
        {_casualty getVariable ["KFH_needsVehiclePull", false]};
    private _graceSeconds = if (_wasVehicleCasualty) then {
        missionNamespace getVariable ["KFH_vehicleCasualtyPostReviveGraceSeconds", 8]
    } else {
        missionNamespace getVariable ["KFH_postReviveInvulnerabilitySeconds", 5]
    };
    if (_graceSeconds > 0) then {
        [_casualty, _graceSeconds] call KFH_fnc_applyPostReviveSafetyGrace;
    } else {
        _casualty allowDamage true;
    };

    if (_casualty getVariable ["KFH_forcedDowned", false]) then {
        _casualty setVariable ["KFH_forcedDowned", false, true];
        _casualty setVariable ["KFH_forcedDownedAt", -1, true];
        _casualty setVariable ["KFH_needsVehiclePull", false, true];
        _casualty setVariable ["KFH_downedInsideVehicle", objNull, true];
        _casualty setCaptive false;
        _casualty setUnconscious false;
        _casualty enableSimulation true;
        _casualty setDamage (_healDamage max 0);
        [_casualty] call KFH_fnc_applyPrototypeCarryCapacity;
        [_casualty] call KFH_fnc_playReviveGetUpAnimation;
        if (isPlayer _casualty) then {
            [] remoteExecCall ["KFH_fnc_scheduleLocalReviveCleanup", _casualty];
        };
    } else {
        _casualty setVariable ["KFH_forcedDowned", false, true];
        _casualty setVariable ["KFH_forcedDownedAt", -1, true];
        _casualty setVariable ["KFH_needsVehiclePull", false, true];
        _casualty setVariable ["KFH_downedInsideVehicle", objNull, true];
        _casualty setCaptive false;
        _casualty setUnconscious false;
        _casualty enableSimulation true;
        _casualty setDamage 0;
        [_casualty] call KFH_fnc_applyPrototypeCarryCapacity;
        [objNull, 1, _casualty] remoteExecCall ["BIS_fnc_reviveOnState", 0];
        [_casualty] call KFH_fnc_playReviveGetUpAnimation;
        if (isPlayer _casualty) then {
            [] remoteExecCall ["KFH_fnc_scheduleLocalReviveCleanup", _casualty];
        };
    };
};

KFH_fnc_installPlayerDownedProtection = {
    params ["_unit"];

    if (isNull _unit) exitWith {};
    if (_unit getVariable ["KFH_downedProtectionInstalled", false]) exitWith {};
    if !(missionNamespace getVariable ["KFH_playerDownedProtectionEnabled", true]) exitWith {};

    _unit setVariable ["KFH_downedProtectionInstalled", true];
    _unit addEventHandler ["HandleDamage", {
        params ["_unit", "_selection", "_incomingDamage", "_source"];

        if (isNull _unit) exitWith { _incomingDamage };
        if !(local _unit) exitWith { _incomingDamage };
        if !(missionNamespace getVariable ["KFH_playerDownedProtectionEnabled", true]) exitWith { _incomingDamage };

        private _safeDamage = missionNamespace getVariable ["KFH_forcedDownedDamage", 0.42];
        private _protectedUntil = _unit getVariable ["KFH_postReviveProtectedUntil", -1];
        if (_protectedUntil > time) exitWith { (damage _unit) min _safeDamage };

        private _damageThreshold = missionNamespace getVariable ["KFH_downedInterceptDamageThreshold", 0.72];
        private _totalDamageThreshold = missionNamespace getVariable ["KFH_downedInterceptTotalDamageThreshold", 0.82];
        private _currentDamage = damage _unit;
        if (_unit getVariable ["KFH_forcedDowned", false]) exitWith { _safeDamage };
        if (
            (_incomingDamage < _damageThreshold) &&
            {((_currentDamage max 0) + (_incomingDamage max 0)) < _totalDamageThreshold}
        ) exitWith { _incomingDamage };
        if !([_unit] call KFH_fnc_hasRescueCoverageFor) exitWith { _incomingDamage };

        [_unit, _source, "fatal damage intercepted"] call KFH_fnc_forceUnitDowned;
        _safeDamage
    }];

    _unit addEventHandler ["Killed", {
        params ["_unit", "_killer"];

        if (isNull _unit) exitWith {};
        if !(local _unit) exitWith {};
        if !(isPlayer _unit) exitWith {};
        if !(missionNamespace getVariable ["KFH_respawnFallbackDownedEnabled", true]) exitWith {};
        if !([_unit] call KFH_fnc_hasRescueCoverageFor) exitWith {};

        private _vehicle = vehicle _unit;
        private _wasInVehicle = !(_vehicle isEqualTo _unit);
        private _downedPos = if (_wasInVehicle && {!isNull _vehicle}) then { getPosATL _vehicle } else { getPosATL _unit };
        missionNamespace setVariable ["KFH_respawnAsDownedPending", true];
        missionNamespace setVariable ["KFH_respawnAsDownedPos", _downedPos];
        missionNamespace setVariable ["KFH_respawnAsDownedDir", if (_wasInVehicle && {!isNull _vehicle}) then { getDir _vehicle } else { getDir _unit }];
        missionNamespace setVariable ["KFH_respawnAsDownedVehicle", if (_wasInVehicle) then { _vehicle } else { objNull }];
        missionNamespace setVariable ["KFH_respawnAsDownedWasVehicle", _wasInVehicle];
        missionNamespace setVariable ["KFH_lastHumanCasualtyAt", time, true];
        [format [
            "Respawn fallback armed for %1. Killer=%2 vehicle=%3.",
            name _unit,
            if (isNull _killer) then { "unknown" } else { typeOf _killer },
            if (_wasInVehicle) then { typeOf _vehicle } else { "none" }
        ]] call KFH_fnc_log;
    }];
};

KFH_fnc_getPressureRatio = {
    private _pressure = missionNamespace getVariable ["KFH_pressure", 0];
    ((_pressure max 0) min KFH_pressureMax) / KFH_pressureMax
};

KFH_fnc_getPressureReinforceSeconds = {
    params ["_baseSeconds"];

    private _ratio = [] call KFH_fnc_getPressureRatio;
    private _scaled = _baseSeconds * (1 - (_ratio * KFH_pressureReinforceIntervalScale));

    _scaled max KFH_pressureReinforceIntervalFloor
};

KFH_fnc_getPressureSpawnMultiplier = {
    private _ratio = [] call KFH_fnc_getPressureRatio;
    private _multiplier = 1 + (_ratio * KFH_pressureReinforceMultiplierStep * 10);

    _multiplier min KFH_pressureReinforceMultiplierMax
};

KFH_fnc_applyWaveCooldown = {
    params [
        ["_seconds", KFH_waveCooldownMinSeconds],
        ["_reason", "wave cooldown"]
    ];

    private _cooldown = round (_seconds max 0);
    private _targetTime = time + _cooldown;
    private _currentNext = missionNamespace getVariable ["KFH_nextReinforceAt", 0];
    private _newNext = _currentNext max _targetTime;

    missionNamespace setVariable ["KFH_nextReinforceAt", _newNext];
    missionNamespace setVariable ["KFH_nextWaveAt", _newNext, true];
    missionNamespace setVariable ["KFH_waveCooldownReason", _reason, true];
    [format ["Wave cooldown applied: %1s reason=%2 next=%3", _cooldown, _reason, round (_newNext - time)]] call KFH_fnc_log;

    _cooldown
};

KFH_fnc_calculateWaveClearCooldown = {
    params [["_isRush", false]];

    private _minSeconds = if (_isRush) then {
        missionNamespace getVariable ["KFH_waveCooldownRushMinSeconds", 160]
    } else {
        missionNamespace getVariable ["KFH_waveCooldownNormalMinSeconds", 60]
    };
    private _maxSeconds = if (_isRush) then {
        missionNamespace getVariable ["KFH_waveCooldownRushMaxSeconds", 300]
    } else {
        missionNamespace getVariable ["KFH_waveCooldownNormalMaxSeconds", 90]
    };

    private _range = (_maxSeconds - _minSeconds) max 0;
    private _cooldown = _minSeconds + random _range;

    round _cooldown
};

KFH_fnc_getCheckpointSecureCooldown = {
    params [["_checkpointIndex", 1]];

    if (_checkpointIndex <= (missionNamespace getVariable ["KFH_checkpointSecureCooldownEarlyUntil", 4])) exitWith {
        missionNamespace getVariable ["KFH_checkpointSecureCooldownEarlySeconds", 60]
    };

    missionNamespace getVariable ["KFH_checkpointSecureCooldownSeconds", KFH_checkpointSecureCooldownSeconds]
};

KFH_fnc_reducePressure = {
    params ["_amount", ["_reason", "Pressure relief"]];

    private _oldPressure = missionNamespace getVariable ["KFH_pressure", 0];
    private _newPressure = (_oldPressure - _amount) max 0;
    ["KFH_pressure", _newPressure] call KFH_fnc_setState;
    [format ["%1: Hive Pressure %2 -> %3.", _reason, round _oldPressure, round _newPressure], "PRESSURE"] call KFH_fnc_appendRunEvent;

    _newPressure
};

KFH_fnc_getAliveDebugTeammates = {
    ([] call KFH_fnc_getDebugTeammates) select {
        alive _x
    }
};

KFH_fnc_hasRecentDebugTeammateGrace = {
    private _lastAliveAt = missionNamespace getVariable ["KFH_lastAliveDebugTeammateAt", -1];
    _lastAliveAt >= 0 &&
    {(time - _lastAliveAt) <= (missionNamespace getVariable ["KFH_debugTeammateWipeGraceSeconds", 35])}
};

KFH_fnc_hasRecentHumanCasualtyGrace = {
    private _lastCasualtyAt = missionNamespace getVariable ["KFH_lastHumanCasualtyAt", -1];
    _lastCasualtyAt >= 0 &&
    {(time - _lastCasualtyAt) <= (missionNamespace getVariable ["KFH_playerDeathWipeGraceSeconds", 55])}
};

KFH_fnc_hasReviveChance = {
    ((count ([] call KFH_fnc_getIncapacitatedPlayers)) > 0) &&
    ((count ([] call KFH_fnc_getPotentialRescuers)) > 0)
};

KFH_fnc_autoRevivePlayers = {
    params [["_reasonKey", "checkpoint_cleared_reason"], ["_reasonArgs", []]];

    private _targets = [] call KFH_fnc_getIncapacitatedPlayers;

    if ((count _targets) isEqualTo 0) exitWith {};

    {
        [_x, 0] call KFH_fnc_reviveUnitFromDowned;
    } forEach _targets;

    [_reasonKey, _reasonArgs, count _targets] remoteExecCall ["KFH_fnc_receiveAutoReviveAnnouncement", 0];
    [format ["AutoReviveKey: %1 %2 count=%3", _reasonKey, _reasonArgs, count _targets]] call KFH_fnc_log;
};

KFH_fnc_applyDebugTeammateCombatProfile = {
    params ["_unit"];

    if (isNull _unit) exitWith {};

    _unit allowFleeing 0;
    _unit enableFatigue false;
    _unit enableAI "TARGET";
    _unit enableAI "AUTOTARGET";
    _unit enableAI "AUTOCOMBAT";
    _unit enableAI "WEAPONAIM";
    _unit setCombatMode "RED";
    _unit setBehaviourStrong "COMBAT";
    _unit setSpeedMode "FULL";
    _unit setUnitPos "AUTO";
    _unit doFollow leader (group _unit);
    (group _unit) setCombatMode "RED";
    (group _unit) setBehaviourStrong "COMBAT";
    (group _unit) setSpeedMode "FULL";

    _unit setSkill KFH_debugTeammateSkill;
    _unit setSkill ["aimingAccuracy", KFH_debugTeammateAimingAccuracy];
    _unit setSkill ["aimingShake", 0.45];
    _unit setSkill ["aimingSpeed", 0.72];
    _unit setSkill ["spotDistance", 0.85];
    _unit setSkill ["spotTime", 0.78];
    _unit setSkill ["courage", 1];
    _unit setSkill ["commanding", 0.82];
    _unit setSkill ["general", KFH_debugTeammateSkill];

    if !(_unit getVariable ["KFH_debugCombatDamageInstalled", false]) then {
        _unit addEventHandler ["HandleDamage", {
            params ["_unit", "_selection", "_incomingDamage", "_source"];

            if (_unit getVariable ["KFH_aiReviveBusy", false]) exitWith {
                _incomingDamage * ((KFH_debugTeammateDamageScale * 0.5) max 0.05)
            };

            _incomingDamage * KFH_debugTeammateDamageScale
        }];
        _unit setVariable ["KFH_debugCombatDamageInstalled", true];
    };
};

KFH_fnc_applyDebugTeammateWeaponProfile = {
    params ["_unit"];

    if (isNull _unit) exitWith {};

    private _weapon = missionNamespace getVariable ["KFH_debugTeammatePrimaryWeapon", ""];
    private _magazine = missionNamespace getVariable ["KFH_debugTeammatePrimaryMagazine", ""];
    if (_weapon isEqualTo "" || {_magazine isEqualTo ""}) exitWith {};
    if !(isClass (configFile >> "CfgWeapons" >> _weapon)) exitWith {};
    if !(isClass (configFile >> "CfgMagazines" >> _magazine)) exitWith {};

    private _backpack = missionNamespace getVariable ["KFH_debugTeammateBackpack", ""];
    if ((backpack _unit) isEqualTo "" && {!(_backpack isEqualTo "")} && {isClass (configFile >> "CfgVehicles" >> _backpack)}) then {
        _unit addBackpack _backpack;
    };

    if ((primaryWeapon _unit) isEqualTo "") then {
        [
            _unit,
            _weapon,
            _magazine,
            missionNamespace getVariable ["KFH_debugTeammatePrimaryAttachments", []],
            ((missionNamespace getVariable ["KFH_debugTeammatePrimaryMagCount", 12]) - 1) max 0
        ] call KFH_fnc_givePrimaryWeaponLoadout;
    };
};

KFH_fnc_addInventoryItem = {
    params ["_unit", "_itemClass"];

    if (isNull _unit) exitWith { false };
    if (isClass (configFile >> "CfgMagazines" >> _itemClass)) exitWith {
        if !(_unit canAdd _itemClass) exitWith { false };
        _unit addMagazine _itemClass;
        true
    };
    if !(isClass (configFile >> "CfgWeapons" >> _itemClass)) exitWith { false };

    if (_unit canAddItemToUniform _itemClass) exitWith {
        _unit addItemToUniform _itemClass;
        true
    };

    if ((vest _unit) isNotEqualTo "" && {_unit canAddItemToVest _itemClass}) exitWith {
        _unit addItemToVest _itemClass;
        true
    };

    if ((backpack _unit) isNotEqualTo "" && {_unit canAddItemToBackpack _itemClass}) exitWith {
        _unit addItemToBackpack _itemClass;
        true
    };

    if (_unit canAdd _itemClass) exitWith {
        _unit addItem _itemClass;
        true
    };

    false
};

KFH_fnc_addInventoryItems = {
    params ["_unit", "_itemClass", ["_count", 1]];

    private _added = 0;
    for "_i" from 1 to _count do {
        if ([_unit, _itemClass] call KFH_fnc_addInventoryItem) then {
            _added = _added + 1;
        };
    };

    if (_added < _count) then {
        [format [
            "Inventory full while adding %1 to %2 (%3/%4).",
            _itemClass,
            name _unit,
            _added,
            _count
        ]] call KFH_fnc_log;
    };

    _added
};

KFH_fnc_addUnitLootClass = {
    params ["_unit", "_className"];

    if (isNull _unit) exitWith { false };
    if (isClass (configFile >> "CfgMagazines" >> _className)) exitWith {
        if !(_unit canAdd _className) exitWith { false };
        _unit addMagazine _className;
        true
    };

    if (isClass (configFile >> "CfgWeapons" >> _className)) exitWith {
        [_unit, _className] call KFH_fnc_addInventoryItem
    };

    false
};

KFH_fnc_addRecentRewardWeaponLoot = {
    params ["_unit"];

    if (isNull _unit) exitWith { 0 };
    if !(missionNamespace getVariable ["KFH_enemyLootUseRecentRewardBundles", true]) exitWith { 0 };
    if ((random 1) > (missionNamespace getVariable ["KFH_enemyLootRecentBundleChance", 0.75])) exitWith { 0 };

    private _bundles = (missionNamespace getVariable ["KFH_recentRewardWeaponBundles", []]) select {
        (count _x) >= 2 && {isClass (configFile >> "CfgMagazines" >> (_x select 1))}
    };
    if ((count _bundles) isEqualTo 0) exitWith { 0 };

    private _bundle = selectRandom _bundles;
    private _weaponClass = _bundle select 0;
    private _magazineClass = _bundle select 1;
    private _maxMags = missionNamespace getVariable ["KFH_enemyLootRecentBundleMaxMags", 2];
    private _magCount = 1 + floor (random (_maxMags max 1));
    private _added = 0;

    for "_i" from 1 to _magCount do {
        if ([_unit, _magazineClass] call KFH_fnc_addUnitLootClass) then {
            _added = _added + 1;
        };
    };

    if ((random 1) <= (missionNamespace getVariable ["KFH_enemyLootRecentBundleAttachmentChance", 0.12])) then {
        private _attachments = if ((count _bundle) > 3) then { _bundle select 3 } else { [] };
        private _compatible = [_weaponClass, _attachments] call KFH_fnc_filterCompatibleWeaponAttachments;
        if ((count _compatible) > 0) then {
            if ([_unit, selectRandom _compatible] call KFH_fnc_addUnitLootClass) then {
                _added = _added + 1;
            };
        };
    };

    _added
};

KFH_fnc_addUnitLootTable = {
    params ["_unit", "_lootTable", ["_roleLabel", "loot"]];

    if (isNull _unit) exitWith {};
    if !(missionNamespace getVariable ["KFH_meleeLootEnabled", true]) exitWith {};

    private _added = 0;
    _added = _added + ([_unit] call KFH_fnc_addRecentRewardWeaponLoot);
    {
        _x params ["_className", ["_minCount", 0], ["_maxCount", 1], ["_chance", 1]];

        if ((random 1) <= _chance) then {
            private _rollMax = (_maxCount - _minCount) max 0;
            private _count = _minCount + floor (random (_rollMax + 1));

            for "_i" from 1 to _count do {
                if ([_unit, _className] call KFH_fnc_addUnitLootClass) then {
                    _added = _added + 1;
                };
            };
        };
    } forEach _lootTable;

    if (_added <= 0 && {(random 1) <= (missionNamespace getVariable ["KFH_meleeLootFallbackChance", 0])}) then {
        private _fallbackItems = missionNamespace getVariable ["KFH_meleeLootFallbackItems", []];
        if ((count _fallbackItems) > 0) then {
            if ([_unit, selectRandom _fallbackItems] call KFH_fnc_addUnitLootClass) then {
                _added = _added + 1;
            };
        };
    };

    if (_added > 0) then {
        _unit setVariable ["KFH_lootRole", _roleLabel, true];
        _unit setVariable ["KFH_lootItemsAdded", _added, true];
    };
};

KFH_fnc_giveHandgunLoadout = {
    params ["_unit", "_weaponClass", "_magClass", ["_attachmentClass", ""], ["_extraMagCount", 0]];

    _unit addMagazine _magClass;
    _unit addWeapon _weaponClass;

    if !(_attachmentClass isEqualTo "") then {
        _unit addHandgunItem _attachmentClass;
    };

    [_unit, _magClass, _extraMagCount] call KFH_fnc_addInventoryItems;
};

KFH_fnc_filterCompatibleWeaponAttachments = {
    params ["_weaponClass", ["_attachments", []]];

    private _weaponCfg = configFile >> "CfgWeapons" >> _weaponClass;
    if !(isClass _weaponCfg) exitWith { [] };

    private _allowed = [];
    private _slotsCfg = _weaponCfg >> "WeaponSlotsInfo";
    if (isClass _slotsCfg) then {
        {
            _allowed append (getArray (_x >> "compatibleItems"));
        } forEach (configProperties [_slotsCfg, "isClass _x", true]);
    };

    _attachments select {
        !(_x isEqualTo "") &&
        {isClass (configFile >> "CfgWeapons" >> _x)} &&
        {_x in _allowed}
    }
};

KFH_fnc_givePrimaryWeaponLoadout = {
    params ["_unit", "_weaponClass", "_magClass", ["_attachments", []], ["_extraMagCount", 0]];

    _unit addMagazine _magClass;
    _unit addWeapon _weaponClass;

    {
        if !(_x isEqualTo "") then {
            _unit addPrimaryWeaponItem _x;
        };
    } forEach ([_weaponClass, _attachments] call KFH_fnc_filterCompatibleWeaponAttachments);

    [_unit, _magClass, _extraMagCount] call KFH_fnc_addInventoryItems;
};

KFH_fnc_applyStarterLoadout = {
    params ["_unit"];

    if (isNull _unit) exitWith {};

    private _cupChance = missionNamespace getVariable ["KFH_cupStarterPreferredChance", 0.9];
    private _uniform = [
        "CfgWeapons",
        missionNamespace getVariable ["KFH_starterUniforms", []],
        missionNamespace getVariable ["KFH_cupStarterUniforms", []],
        _cupChance
    ] call KFH_fnc_selectAvailableConfigClass;
    private _vest = [
        "CfgWeapons",
        missionNamespace getVariable ["KFH_starterVests", []],
        missionNamespace getVariable ["KFH_cupStarterVests", []],
        _cupChance
    ] call KFH_fnc_selectAvailableConfigClass;
    private _headgear = [
        "CfgWeapons",
        missionNamespace getVariable ["KFH_starterHeadgear", []],
        missionNamespace getVariable ["KFH_cupStarterHeadgear", []],
        _cupChance,
        true
    ] call KFH_fnc_selectAvailableConfigClass;
    private _sidearmEntry = [
        missionNamespace getVariable ["KFH_starterSidearms", []],
        missionNamespace getVariable ["KFH_cupStarterSidearms", []],
        _cupChance
    ] call KFH_fnc_selectAvailableWeaponBundle;
    if ((count _sidearmEntry) < 2) then {
        _sidearmEntry = selectRandom KFH_starterSidearms;
    };
    private _sidearm = _sidearmEntry select 0;
    private _sidearmMag = _sidearmEntry select 1;
    private _sidearmAttachment = if ((count _sidearmEntry) > 2) then { _sidearmEntry select 2 } else { "" };

    if (
        (missionNamespace getVariable ["KFH_cupStarterMissingWarning", true]) &&
        {_cupChance >= 1} &&
        {!([_sidearm] call KFH_fnc_isOptionalContentClass)} &&
        {!(missionNamespace getVariable ["KFH_cupStarterMissingWarned", false])}
    ) then {
        missionNamespace setVariable ["KFH_cupStarterMissingWarned", true, true];
        [format [
            "%1 starter loadout requested, but optional gear classes are not available. Check the Arma modset, or vanilla fallback will be used.",
            missionNamespace getVariable ["KFH_optionalContentLabel", "Optional"]
        ]] call KFH_fnc_log;
    };

    removeAllWeapons _unit;
    removeAllItems _unit;
    removeAllAssignedItems _unit;
    removeUniform _unit;
    removeVest _unit;
    removeBackpack _unit;
    removeHeadgear _unit;
    removeGoggles _unit;

    if (_uniform isEqualTo "") then {
        _uniform = selectRandom KFH_starterUniforms;
    };
    _unit forceAddUniform _uniform;
    if !(_vest isEqualTo "") then {
        _unit addVest _vest;
    };

    if !(_headgear isEqualTo "") then {
        _unit addHeadgear _headgear;
    };

    [_unit] call KFH_fnc_applyPrototypeCarryCapacity;

    for "_i" from 1 to KFH_starterFirstAidCount do {
        [_unit, "FirstAidKit"] call KFH_fnc_addInventoryItem;
    };

    [_unit, _sidearm, _sidearmMag, _sidearmAttachment, (KFH_starterMagCount - 1) max 0] call KFH_fnc_giveHandgunLoadout;

    [_unit, "SmokeShell"] call KFH_fnc_addInventoryItem;
    [_unit] call KFH_fnc_ensureNavigationItems;

    _unit setVariable ["KFH_starterIssued", true];
    [_unit] call KFH_fnc_updateSavedLoadout;
    [format ["Starter loadout applied to %1 with %2.", name _unit, _sidearm]] call KFH_fnc_log;
};

KFH_fnc_spawnDebugTeammate = {
    params ["_leader"];

    if (isNull _leader) exitWith { objNull };

    private _existing = missionNamespace getVariable ["KFH_debugTeammate", objNull];
    if (!isNull _existing && {alive _existing}) exitWith { _existing };

    private _spawnPos = _leader modelToWorld [1.8, -1.6, 0];
    if (surfaceIsWater _spawnPos) then {
        _spawnPos = getMarkerPos "kfh_start";
    };

    private _groupRef = group _leader;
    private _unit = _groupRef createUnit [KFH_debugTeammateClass, _spawnPos, [], 0, "FORM"];

    [_unit] joinSilent _groupRef;
    _groupRef selectLeader _leader;
    _unit setName KFH_debugTeammateName;
    _unit setSpeaker "NoVoice";
    _unit setVariable ["KFH_debugTeammate", true, true];
    _unit setVariable ["KFH_soloWingman", true, true];
    _unit setVariable ["KFH_canRevivePlayers", true, true];
    _unit allowFleeing 0;
    _unit enableFatigue false;
    _unit setUnitTrait ["Medic", true];
    _unit setFormation "WEDGE";

    private _leaderLoadout = getUnitLoadout _leader;
    if ((count _leaderLoadout) > 0) then {
        _unit setUnitLoadout _leaderLoadout;
    } else {
        [_unit] call KFH_fnc_applyStarterLoadout;
    };

    if !(missionNamespace getVariable ["KFH_debugTeammateMirrorPlayerLoadout", true]) then {
        [_unit] call KFH_fnc_applyDebugTeammateWeaponProfile;
    };
    [_unit] call KFH_fnc_applyDebugTeammateCombatProfile;
    [_unit] call KFH_fnc_applyPrototypeCarryCapacity;
    [_unit, "Medikit"] call KFH_fnc_addInventoryItem;
    [_unit] call KFH_fnc_applyFriendlyFireMitigation;
    [_unit] call KFH_fnc_updateSavedLoadout;
    missionNamespace setVariable ["KFH_debugTeammate", _unit, true];
    missionNamespace setVariable ["KFH_lastAliveDebugTeammateAt", time, true];

    [format ["Wingman %1 joined the patrol.", KFH_debugTeammateName]] call KFH_fnc_log;

    _unit
};

KFH_fnc_spawnScalingTestAlly = {
    params ["_leader", "_index"];

    if (isNull _leader) exitWith { objNull };

    private _existing = (missionNamespace getVariable ["KFH_scalingTestAllies", []]) select {
        !isNull _x && {alive _x} && {(_x getVariable ["KFH_scalingTestAllyIndex", -1]) isEqualTo _index}
    };
    if ((count _existing) > 0) exitWith { _existing select 0 };

    private _names = missionNamespace getVariable ["KFH_scalingTestAllyNames", ["Delta", "Mika", "Rook"]];
    private _name = if (_index < (count _names)) then { _names select _index } else { format ["Scale-%1", _index + 1] };
    private _spawnPos = _leader modelToWorld [2.2 + (_index * 0.8), -2.2 - (_index * 0.4), 0];
    if (surfaceIsWater _spawnPos) then {
        _spawnPos = getMarkerPos "kfh_start";
    };

    private _groupRef = group _leader;
    private _unit = _groupRef createUnit [missionNamespace getVariable ["KFH_scalingTestAllyClass", KFH_debugTeammateClass], _spawnPos, [], 0, "FORM"];
    [_unit] joinSilent _groupRef;
    _groupRef selectLeader _leader;
    _unit setName _name;
    _unit setSpeaker "NoVoice";
    _unit setVariable ["KFH_debugTeammate", true, true];
    _unit setVariable ["KFH_soloWingman", true, true];
    _unit setVariable ["KFH_scalingTestAlly", true, true];
    _unit setVariable ["KFH_scalingTestAllyIndex", _index, true];
    _unit setVariable ["KFH_canRevivePlayers", true, true];
    _unit allowFleeing 0;
    _unit enableFatigue false;
    _unit setUnitTrait ["Medic", true];
    _unit setFormation "WEDGE";

    private _leaderLoadout = getUnitLoadout _leader;
    if ((count _leaderLoadout) > 0) then {
        _unit setUnitLoadout _leaderLoadout;
    } else {
        [_unit] call KFH_fnc_applyStarterLoadout;
    };

    [_unit] call KFH_fnc_applyDebugTeammateCombatProfile;
    [_unit] call KFH_fnc_applyPrototypeCarryCapacity;
    [_unit, "Medikit"] call KFH_fnc_addInventoryItem;
    [_unit] call KFH_fnc_applyFriendlyFireMitigation;
    [_unit] call KFH_fnc_updateSavedLoadout;

    private _allies = missionNamespace getVariable ["KFH_scalingTestAllies", []];
    _allies pushBackUnique _unit;
    missionNamespace setVariable ["KFH_scalingTestAllies", _allies, true];
    [format ["Scaling test ally %1 joined the patrol.", _name]] call KFH_fnc_log;

    _unit
};

KFH_fnc_forceInitialStarterLoadout = {
    params ["_unit"];

    if (isNull _unit) exitWith {};
    if !((vehicle _unit) isEqualTo _unit) exitWith {};

    [_unit] call KFH_fnc_applyStarterLoadout;

    [_unit] spawn {
        params ["_trackedUnit"];
        private _deadline = time + KFH_starterEnforceWindow;

        while {time <= _deadline} do {
            sleep KFH_starterRecheckDelay;

            if (isNull _trackedUnit) exitWith {};
            if !(alive _trackedUnit) exitWith {};

            if ((primaryWeapon _trackedUnit) isEqualTo "" && {!((handgunWeapon _trackedUnit) isEqualTo "")}) exitWith {
                [_trackedUnit] call KFH_fnc_updateSavedLoadout;
                ["Starter loadout lock-in confirmed."] call KFH_fnc_log;
            };

            [_trackedUnit] call KFH_fnc_applyStarterLoadout;
            ["Starter loadout reapplied after override."] call KFH_fnc_log;
        };
    };
};

KFH_fnc_debugTeammateLoop = {
    missionNamespace setVariable ["KFH_nextDebugTeammateSpawnAt", 0];

    while { true } do {
        private _phase = missionNamespace getVariable ["KFH_phase", "boot"];

        if (_phase in ["complete", "failed"]) exitWith {};

        if (KFH_debugTeammateEnabled) then {
            private _players = [] call KFH_fnc_getHumanPlayers;
            private _combatReadyHumans = [] call KFH_fnc_getCombatReadyHumans;

            if (
                !(missionNamespace getVariable ["KFH_wipeLocked", false]) &&
                ((count _players) > 0) &&
                {(count _players) <= KFH_debugTeammateHumanThreshold} &&
                {(count _combatReadyHumans) > 0}
            ) then {
                private _leader = _players select 0;
                private _current = missionNamespace getVariable ["KFH_debugTeammate", objNull];

                if (isNull _current || {!alive _current}) then {
                    if (time >= (missionNamespace getVariable ["KFH_nextDebugTeammateSpawnAt", 0])) then {
                        [_leader] call KFH_fnc_spawnDebugTeammate;
                        missionNamespace setVariable ["KFH_nextDebugTeammateSpawnAt", time + KFH_debugTeammateRespawnDelay];
                    };
                } else {
                    _current setVariable ["KFH_debugTeammate", true, true];
                    _current setVariable ["KFH_soloWingman", true, true];
                    _current setVariable ["KFH_canRevivePlayers", true, true];
                    missionNamespace setVariable ["KFH_lastAliveDebugTeammateAt", time, true];
                    if ((group _current) != (group _leader)) then {
                        [_current] joinSilent (group _leader);
                    };
                    if (KFH_debugTeammatePassiveCombat) then {
                        _current disableAI "TARGET";
                        _current disableAI "AUTOTARGET";
                        _current setCombatMode "BLUE";
                    } else {
                        [_current] call KFH_fnc_applyDebugTeammateCombatProfile;

                        if !(_current getVariable ["KFH_aiReviveBusy", false]) then {
                            private _nearEnemies = ([] call KFH_fnc_pruneActiveEnemies) select {
                                alive _x && {(_x distance2D _current) <= KFH_debugTeammateEngageRadius}
                            };
                            if ((count _nearEnemies) > 0) then {
                                private _target = [_nearEnemies, [], {_x distance2D _current}, "ASCEND"] call BIS_fnc_sortBy;
                                _target = _target select 0;
                                _current reveal [_target, 4];
                                _current doTarget _target;
                                _current doFire _target;
                            };
                        };
                    };

                    if (
                        (missionNamespace getVariable ["KFH_debugTeammateMirrorPlayerLoadout", true]) &&
                        {!(_current getVariable ["KFH_aiReviveBusy", false])} &&
                        {!([_leader] call KFH_fnc_isIncapacitated)} &&
                        {time >= (_current getVariable ["KFH_nextLoadoutMirrorAt", 0])}
                    ) then {
                        private _leaderLoadout = getUnitLoadout _leader;
                        if ((count _leaderLoadout) > 0) then {
                            _current setUnitLoadout _leaderLoadout;
                            [_current] call KFH_fnc_applyPrototypeCarryCapacity;
                            [_current, "Medikit"] call KFH_fnc_addInventoryItem;
                            [_current] call KFH_fnc_updateSavedLoadout;
                        };
                        _current setVariable [
                            "KFH_nextLoadoutMirrorAt",
                            time + (missionNamespace getVariable ["KFH_debugTeammateMirrorInterval", 18])
                        ];
                    };

                    if ((_current distance2D _leader) > 60 && {!([_current] call KFH_fnc_isIncapacitated)}) then {
                        _current setPosATL (_leader modelToWorld [1.2, -1.4, 0]);
                    };
                };
            };
        };

        sleep 5;
    };
};

KFH_fnc_pickClosestIncapacitatedAlly = {
    params ["_unit"];

    if (isNull _unit) exitWith { objNull };

    private _targets = (([] call KFH_fnc_getHumanPlayers) + (units group _unit)) arrayIntersect (([] call KFH_fnc_getHumanPlayers) + (units group _unit));
    _targets = _targets select {
        _x != _unit &&
        alive _x &&
        [_x] call KFH_fnc_isIncapacitated
    };

    if ((count _targets) isEqualTo 0) exitWith { objNull };

    private _closest = objNull;
    private _closestDistance = 1e10;

    {
        private _distance = _unit distance2D _x;
        if (_distance < _closestDistance) then {
            _closest = _x;
            _closestDistance = _distance;
        };
    } forEach _targets;

    _closest
};

KFH_fnc_runDebugTeammateRevive = {
    params ["_medic", "_casualty"];

    if (isNull _medic || {isNull _casualty}) exitWith {};
    if (!local _medic) exitWith {};
    if !([_casualty] call KFH_fnc_isIncapacitated) exitWith {};

    _medic setVariable ["KFH_aiReviveBusy", true, true];
    _medic disableAI "AUTOCOMBAT";
    _medic disableAI "TARGET";
    _medic disableAI "AUTOTARGET";
    _medic doMove (getPosATL _casualty);

    private _rescueStartAt = time;
    private _didTeleport = false;
    private _timeoutAt = time + KFH_debugTeammateReviveTimeout;
    waitUntil {
        sleep 0.25;

        if (
            !_didTeleport &&
            {!(isNull _medic)} &&
            {!(isNull _casualty)} &&
            {alive _medic} &&
            {alive _casualty} &&
            {[_casualty] call KFH_fnc_isIncapacitated} &&
            {time >= (_rescueStartAt + KFH_debugTeammateRescueTeleportDelay)} &&
            {(_medic distance2D _casualty) > (KFH_debugTeammateReviveRange + 1.2)}
        ) then {
            _medic setPosATL (_casualty modelToWorld [1.1, -0.9, 0]);
            _didTeleport = true;
        };

        isNull _medic ||
        {isNull _casualty} ||
        {!alive _medic} ||
        {!alive _casualty} ||
        {!([_casualty] call KFH_fnc_isIncapacitated)} ||
        {(_medic distance2D _casualty) <= KFH_debugTeammateReviveRange} ||
        {time >= _timeoutAt}
    };

    if (
        !isNull _medic &&
        !isNull _casualty &&
        {alive _medic} &&
        {alive _casualty} &&
        {[_casualty] call KFH_fnc_isIncapacitated}
    ) then {
        if (
            ((vehicle _casualty) isNotEqualTo _casualty) &&
            {!(missionNamespace getVariable ["KFH_debugTeammateAutoPullVehicleCasualties", false])}
        ) exitWith {
            _medic allowDamage true;
            _medic enableAI "AUTOCOMBAT";
            _medic enableAI "TARGET";
            _medic enableAI "AUTOTARGET";
            _medic setVariable ["KFH_aiReviveBusy", false, true];
            _medic doMove (getPosATL (vehicle _casualty));
            [format ["Echo revive paused for %1 inside vehicle; waiting for manual Pull injured.", name _casualty]] call KFH_fnc_log;
        };
        if ((_medic distance2D _casualty) > KFH_debugTeammateReviveRange) then {
            _medic setPosATL (_casualty modelToWorld [1.1, -1.0, 0]);
        };

        _medic allowDamage false;
        if ((vehicle _casualty) isNotEqualTo _casualty) then {
            [_casualty, _medic, "Echo pull before revive"] call KFH_fnc_extractCasualtyFromVehicle;
            sleep 0.35;
            _medic doMove (getPosATL _casualty);
            if ((_medic distance2D _casualty) > KFH_debugTeammateReviveRange) then {
                _medic setPosATL (_casualty modelToWorld [1.1, -1.0, 0]);
            };
        };
        _medic doWatch _casualty;
        _medic playActionNow "MedicOther";
        sleep KFH_debugTeammateReviveDuration;

        if (alive _casualty && {[_casualty] call KFH_fnc_isIncapacitated}) then {
            [_casualty] call KFH_fnc_reviveUnitFromDowned;
            [format ["%1 revived %2.", name _medic, name _casualty]] call KFH_fnc_notifyAll;
        };
        _medic allowDamage true;
    };

    if (!isNull _medic) then {
        _medic allowDamage true;
        _medic enableAI "AUTOCOMBAT";
        _medic enableAI "TARGET";
        _medic enableAI "AUTOTARGET";
        _medic setVariable ["KFH_aiReviveBusy", false, true];
        if (!KFH_debugTeammatePassiveCombat) then {
            [_medic] call KFH_fnc_applyDebugTeammateCombatProfile;
        };
        _medic doFollow leader (group _medic);
    };
};

KFH_fnc_scalingTestAllyLoop = {
    missionNamespace setVariable ["KFH_nextScalingTestAllySpawnAt", 0];

    while { true } do {
        private _phase = missionNamespace getVariable ["KFH_phase", "boot"];
        if (_phase in ["complete", "failed"]) exitWith {};

        private _count = missionNamespace getVariable ["KFH_scalingTestAllyCount", 0];
        if (_count > 0) then {
            private _players = [] call KFH_fnc_getHumanPlayers;
            private _combatReadyHumans = [] call KFH_fnc_getCombatReadyHumans;
            if (
                !(missionNamespace getVariable ["KFH_wipeLocked", false]) &&
                {(count _players) > 0} &&
                {(count _combatReadyHumans) > 0}
            ) then {
                private _leader = _players select 0;
                private _allies = missionNamespace getVariable ["KFH_scalingTestAllies", []];
                _allies = _allies select { !isNull _x && {alive _x} };
                missionNamespace setVariable ["KFH_scalingTestAllies", _allies, true];

                for "_i" from 0 to ((_count min 9) - 1) do {
                    private _ally = objNull;
                    private _matches = _allies select { (_x getVariable ["KFH_scalingTestAllyIndex", -1]) isEqualTo _i };
                    if ((count _matches) > 0) then {
                        _ally = _matches select 0;
                    };

                    if (isNull _ally || {!alive _ally}) then {
                        [_leader, _i] call KFH_fnc_spawnScalingTestAlly;
                    } else {
                        if ((group _ally) != (group _leader)) then {
                            [_ally] joinSilent (group _leader);
                        };
                        [_ally] call KFH_fnc_applyDebugTeammateCombatProfile;
                        if (
                            !(_ally getVariable ["KFH_aiReviveBusy", false]) &&
                            {!([_leader] call KFH_fnc_isIncapacitated)} &&
                            {time >= (_ally getVariable ["KFH_nextLoadoutMirrorAt", 0])}
                        ) then {
                            private _leaderLoadout = getUnitLoadout _leader;
                            if ((count _leaderLoadout) > 0) then {
                                _ally setUnitLoadout _leaderLoadout;
                                [_ally] call KFH_fnc_applyPrototypeCarryCapacity;
                                [_ally, "Medikit"] call KFH_fnc_addInventoryItem;
                                [_ally] call KFH_fnc_updateSavedLoadout;
                            };
                            _ally setVariable [
                                "KFH_nextLoadoutMirrorAt",
                                time + (missionNamespace getVariable ["KFH_scalingTestAllyMirrorInterval", 18])
                            ];
                        };
                        if ((_ally distance2D _leader) > 70 && {!([_ally] call KFH_fnc_isIncapacitated)}) then {
                            _ally setPosATL (_leader modelToWorld [2 + (_i * 0.8), -2 - (_i * 0.5), 0]);
                        };
                    };
                };
            };
        };

        sleep 2.5;
    };
};

KFH_fnc_debugTeammateReviveLoop = {
    while { true } do {
        private _phase = missionNamespace getVariable ["KFH_phase", "boot"];

        if (_phase in ["complete", "failed"]) exitWith {};

        private _medic = missionNamespace getVariable ["KFH_debugTeammate", objNull];

        if (
            !isNull _medic &&
            {alive _medic} &&
            {!([_medic] call KFH_fnc_isIncapacitated)} &&
            {local _medic} &&
            {!(_medic getVariable ["KFH_aiReviveBusy", false])}
        ) then {
            private _casualty = [_medic] call KFH_fnc_pickClosestIncapacitatedAlly;

            if !(isNull _casualty) then {
                [_medic, _casualty] spawn KFH_fnc_runDebugTeammateRevive;
            };
        };

        sleep 1.2;
    };
};

KFH_fnc_getCheckpointRewardTier = {
    params ["_checkpointIndex"];

    private _markers = missionNamespace getVariable ["KFH_checkpointMarkers", []];
    private _total = missionNamespace getVariable ["KFH_totalCheckpoints", count _markers];
    if (_total <= 0) exitWith { ((_checkpointIndex max 1) min 3) };

    ((ceil (((_checkpointIndex max 1) / (_total max 1)) * 3)) max 1) min 3
};

KFH_fnc_getCheckpointRewardTierName = {
    params ["_checkpointIndex"];

    switch ([_checkpointIndex] call KFH_fnc_getCheckpointRewardTier) do {
        case 1: { "Breacher Tier" };
        case 2: { "Rifle Tier" };
        default { "Holdout Tier" };
    };
};

KFH_fnc_addOptionalWeaponCargo = {
    params ["_cache", "_className", ["_count", 1]];

    if (isClass (configFile >> "CfgWeapons" >> _className)) then {
        _cache addWeaponCargoGlobal [_className, _count];
        true
    } else {
        false
    }
};

KFH_fnc_addOptionalItemCargo = {
    params ["_cache", "_className", ["_count", 1]];

    if (isClass (configFile >> "CfgWeapons" >> _className)) then {
        _cache addItemCargoGlobal [_className, _count];
        true
    } else {
        false
    }
};

KFH_fnc_addOptionalMagazineCargo = {
    params ["_cache", "_className", ["_count", 1]];

    if (isClass (configFile >> "CfgMagazines" >> _className)) then {
        _cache addMagazineCargoGlobal [_className, _count];
        true
    } else {
        false
    }
};

KFH_fnc_selectAvailableConfigClass = {
    params [
        ["_configRoot", "CfgWeapons"],
        ["_vanillaClasses", []],
        ["_optionalClasses", []],
        ["_optionalChance", missionNamespace getVariable ["KFH_cupRewardPreferredChance", 0.85]],
        ["_allowEmpty", false]
    ];

    private _vanilla = _vanillaClasses select {
        (_allowEmpty && {_x isEqualTo ""}) || {isClass (configFile >> _configRoot >> _x)}
    };
    private _optional = if (missionNamespace getVariable ["KFH_cupOptionalEnabled", true]) then {
        _optionalClasses select { isClass (configFile >> _configRoot >> _x) }
    } else {
        []
    };

    if ((missionNamespace getVariable ["KFH_cupBanVanillaWhenAvailable", true]) && {(count _optional) > 0}) exitWith {
        selectRandom _optional
    };
    if ((count _optional) > 0 && {((count _vanilla) isEqualTo 0) || {(random 1) < _optionalChance}}) exitWith {
        selectRandom _optional
    };
    if ((count _vanilla) > 0) exitWith { selectRandom _vanilla };
    if ((count _optional) > 0) exitWith { selectRandom _optional };
    ""
};

KFH_fnc_isWeaponBundleAvailable = {
    params ["_bundle"];

    if ((count _bundle) < 2) exitWith { false };
    private _weaponClass = _bundle select 0;
    private _magazineClass = _bundle select 1;

    (isClass (configFile >> "CfgWeapons" >> _weaponClass)) &&
    {isClass (configFile >> "CfgMagazines" >> _magazineClass)}
};

KFH_fnc_stringContainsAny = {
    params [["_text", ""], ["_tokens", []]];

    private _lower = toLower _text;
    (_tokens findIf { (_lower find (toLower _x)) >= 0 }) >= 0
};

KFH_fnc_getDynamicRhsRewardCategory = {
    params ["_className", "_displayName"];

    private _haystack = format ["%1 %2", _className, _displayName];
    if ([_haystack, missionNamespace getVariable ["KFH_dynamicRhsRewardExcludedTokens", []]] call KFH_fnc_stringContainsAny) exitWith { [] };

    if ([_haystack, missionNamespace getVariable ["KFH_dynamicRhsRewardShotgunTokens", []]] call KFH_fnc_stringContainsAny) exitWith {
        ["shotgun", 1, 8, missionNamespace getVariable ["KFH_dynamicRhsRewardShotgunAttachments", []]]
    };
    if ([_haystack, missionNamespace getVariable ["KFH_dynamicRhsRewardMachinegunTokens", []]] call KFH_fnc_stringContainsAny) exitWith {
        ["machinegun", 3, 3, missionNamespace getVariable ["KFH_dynamicRhsRewardMachinegunAttachments", []]]
    };
    if ([_haystack, missionNamespace getVariable ["KFH_dynamicRhsRewardBattleRifleTokens", []]] call KFH_fnc_stringContainsAny) exitWith {
        ["battleRifle", 2, 8, missionNamespace getVariable ["KFH_dynamicRhsRewardBattleRifleAttachments", []]]
    };

    []
};

KFH_fnc_selectDynamicRhsMagazine = {
    params ["_weaponCfg"];

    private _magazines = getArray (_weaponCfg >> "magazines");
    private _usable = _magazines select {
        isClass (configFile >> "CfgMagazines" >> _x) &&
        {!([_x, ["grenade", "flare", "signal", "smoke"]] call KFH_fnc_stringContainsAny)}
    };

    if ((count _usable) > 0) exitWith { _usable select 0 };
    ""
};

KFH_fnc_buildDynamicRhsRewardBundles = {
    if !(missionNamespace getVariable ["KFH_dynamicRhsRewardWeaponsEnabled", true]) exitWith {
        missionNamespace setVariable ["KFH_dynamicRhsRewardBundlesCache", [[], [], []]];
        [[], [], []]
    };

    private _cached = missionNamespace getVariable ["KFH_dynamicRhsRewardBundlesCache", objNull];
    if !(_cached isEqualType objNull) exitWith { _cached };

    private _tier1 = [];
    private _tier2 = [];
    private _tier3 = [];
    private _seenBaseWeapons = [];
    private _shotguns = 0;
    private _machineguns = 0;
    private _battleRifles = 0;
    private _maxPerCategory = missionNamespace getVariable ["KFH_dynamicRhsRewardMaxPerCategory", 8];

    {
        private _className = configName _x;
        private _lowerClass = toLower _className;
        if (
            ((_lowerClass find "rhs_weap_") isEqualTo 0) ||
            {(_lowerClass find "rhsusf_weap_") isEqualTo 0} ||
            {(_lowerClass find "rhsgref_weap_") isEqualTo 0}
        ) then {
            private _scope = getNumber (_x >> "scope");
            private _displayName = getText (_x >> "displayName");
            private _category = [_className, _displayName] call KFH_fnc_getDynamicRhsRewardCategory;
            if (_scope >= 2 && {!(_displayName isEqualTo "")} && {(count _category) > 0}) then {
                _category params ["_categoryName", "_minTier", "_magazineCount", "_attachments"];
                private _canAdd = switch (_categoryName) do {
                    case "shotgun": {
                        if (_shotguns < _maxPerCategory) then { _shotguns = _shotguns + 1; true } else { false }
                    };
                    case "machinegun": {
                        if (_machineguns < _maxPerCategory) then { _machineguns = _machineguns + 1; true } else { false }
                    };
                    default {
                        if (_battleRifles < _maxPerCategory) then { _battleRifles = _battleRifles + 1; true } else { false }
                    };
                };
                if (_canAdd) then {
                    private _baseWeapon = getText (_x >> "baseWeapon");
                    if (_baseWeapon isEqualTo "") then { _baseWeapon = _className; };
                    if !(_baseWeapon in _seenBaseWeapons) then {
                        private _magazine = [_x] call KFH_fnc_selectDynamicRhsMagazine;
                        if !(_magazine isEqualTo "") then {
                            _seenBaseWeapons pushBack _baseWeapon;
                            private _bundle = [_className, _magazine, _magazineCount, _attachments, "dynamicRhs", _categoryName];
                            if (_minTier <= 1) then { _tier1 pushBack _bundle; };
                            if (_minTier <= 2) then { _tier2 pushBack _bundle; };
                            _tier3 pushBack _bundle;
                        };
                    };
                };
            };
        };
    } forEach (configProperties [configFile >> "CfgWeapons", "isClass _x", true]);

    private _result = [_tier1, _tier2, _tier3];
    missionNamespace setVariable ["KFH_dynamicRhsRewardBundlesCache", _result];
    [format ["Dynamic RHS reward bundles: tier1=%1 tier2=%2 tier3=%3.", count _tier1, count _tier2, count _tier3]] call KFH_fnc_log;
    _result
};

KFH_fnc_getDynamicRhsRewardBundles = {
    params [["_tier", 1]];

    private _bundles = [] call KFH_fnc_buildDynamicRhsRewardBundles;
    _bundles select (((_tier max 1) min 3) - 1)
};

KFH_fnc_getAvailableWeaponBundles = {
    params [["_vanillaBundles", []], ["_optionalBundles", []]];

    private _pool = _vanillaBundles select { [_x] call KFH_fnc_isWeaponBundleAvailable };

    if (missionNamespace getVariable ["KFH_cupOptionalEnabled", true]) then {
        _pool append (_optionalBundles select { [_x] call KFH_fnc_isWeaponBundleAvailable });
    };

    if ((count _pool) isEqualTo 0) then {
        _pool = +_vanillaBundles;
    };

    _pool
};

KFH_fnc_selectAvailableWeaponBundle = {
    params [["_vanillaBundles", []], ["_optionalBundles", []], ["_optionalChance", missionNamespace getVariable ["KFH_cupRewardPreferredChance", 0.85]]];

    private _vanilla = _vanillaBundles select { [_x] call KFH_fnc_isWeaponBundleAvailable };
    private _optional = if (missionNamespace getVariable ["KFH_cupOptionalEnabled", true]) then {
        _optionalBundles select { [_x] call KFH_fnc_isWeaponBundleAvailable }
    } else {
        []
    };

    if ((missionNamespace getVariable ["KFH_cupBanVanillaWhenAvailable", true]) && {(count _optional) > 0}) exitWith {
        selectRandom _optional
    };
    if ((count _optional) > 0 && {((count _vanilla) isEqualTo 0) || {(random 1) < _optionalChance}}) exitWith {
        selectRandom _optional
    };
    if ((count _vanilla) > 0) exitWith { selectRandom _vanilla };
    if ((count _optional) > 0) exitWith { selectRandom _optional };
    []
};

KFH_fnc_getRangedEnemyLoadoutPool = {
    [
        missionNamespace getVariable ["KFH_rangedEnemyLoadouts", []],
        missionNamespace getVariable ["KFH_cupRangedEnemyLoadouts", []]
    ] call KFH_fnc_getAvailableWeaponBundles
};

KFH_fnc_selectRangedEnemyLoadout = {
    [
        missionNamespace getVariable ["KFH_rangedEnemyLoadouts", []],
        missionNamespace getVariable ["KFH_cupRangedEnemyLoadouts", []],
        missionNamespace getVariable ["KFH_cupRangedEnemyPreferredChance", 0.72]
    ] call KFH_fnc_selectAvailableWeaponBundle
};

KFH_fnc_addOptionalLauncherBundle = {
    params ["_cache", ["_count", 1], ["_bundles", missionNamespace getVariable ["KFH_cupLauncherBundles", []]], ["_optionalChance", missionNamespace getVariable ["KFH_cupRewardPreferredChance", 0.85]]];

    private _available = [_bundles] call KFH_fnc_filterExistingWeaponBundles;

    if ((count _available) isEqualTo 0) exitWith { false };

    private _cupAvailable = _available select { [(_x select 0)] call KFH_fnc_isOptionalContentClass };
    private _vanillaAvailable = _available select { !([(_x select 0)] call KFH_fnc_isOptionalContentClass) };
    if ((missionNamespace getVariable ["KFH_cupBanVanillaWhenAvailable", true]) && {(count _cupAvailable) > 0}) then {
        _vanillaAvailable = [];
    };
    private _bundle = if ((count _cupAvailable) > 0 && {((count _vanillaAvailable) isEqualTo 0) || {(random 1) < _optionalChance}}) then {
        selectRandom _cupAvailable
    } else {
        selectRandom _vanillaAvailable
    };
    private _weaponClass = _bundle select 0;
    private _magazineClass = _bundle select 1;
    private _magazineCount = if ((count _bundle) > 2) then { _bundle select 2 } else { 1 };

    [_cache, _weaponClass, _count] call KFH_fnc_addOptionalWeaponCargo;
    [_cache, _magazineClass, _magazineCount * _count] call KFH_fnc_addOptionalMagazineCargo;
    true
};

KFH_fnc_addLauncherBundlesCargo = {
    params ["_cache", ["_count", 1], ["_bundles", missionNamespace getVariable ["KFH_simpleLauncherBundles", []]]];

    private _added = 0;
    for "_i" from 1 to (_count max 1) do {
        if ([_cache, 1, _bundles] call KFH_fnc_addOptionalLauncherBundle) then {
            _added = _added + 1;
        };
    };
    _added
};

KFH_fnc_addSideCacheATCargo = {
    params ["_cache", ["_checkpointIndex", 1]];

    private _bundles = missionNamespace getVariable ["KFH_sideCacheAtLauncherBundles", []];
    private _added = [_cache, 2, _bundles] call KFH_fnc_addLauncherBundlesCargo;
    [_cache, "DemoCharge_Remote_Mag", 1] call KFH_fnc_addOptionalMagazineCargo;
    [_cache, "APERSTripMine_Wire_Mag", 2] call KFH_fnc_addOptionalMagazineCargo;
    [_cache] call KFH_fnc_addSideCacheBonusCargo;
    [format ["Side cache AT bonus added for checkpoint %1 (%2 launchers).", _checkpointIndex, _added]] call KFH_fnc_log;
};

KFH_fnc_getRewardPlayerCount = {
    private _scalingPlayers = [] call KFH_fnc_getScalingPlayerCount;
    (_scalingPlayers max 1) min 10
};

KFH_fnc_addRewardHelmets = {
    params ["_cache", ["_count", 1]];

    private _vanilla = missionNamespace getVariable ["KFH_rewardHelmetPool", []];
    private _optional = missionNamespace getVariable ["KFH_cupRewardHelmetPool", []];

    for "_i" from 1 to (_count max 1) do {
        private _helmet = [
            "CfgWeapons",
            _vanilla,
            _optional,
            missionNamespace getVariable ["KFH_cupRewardPreferredChance", 0.85]
        ] call KFH_fnc_selectAvailableConfigClass;
        if !(_helmet isEqualTo "") then {
            [_cache, _helmet, 1] call KFH_fnc_addOptionalItemCargo;
        };
    };
};

KFH_fnc_addRewardVests = {
    params ["_cache", ["_tier", 2], ["_count", 1]];

    private _vanillaKey = if (_tier >= 3) then { "KFH_rewardVestPoolTier3" } else { "KFH_rewardVestPoolTier2" };
    private _optionalKey = if (_tier >= 3) then { "KFH_cupRewardVestPoolTier3" } else { "KFH_cupRewardVestPoolTier2" };
    private _vanilla = missionNamespace getVariable [_vanillaKey, []];
    private _optional = missionNamespace getVariable [_optionalKey, []];

    for "_i" from 1 to (_count max 1) do {
        private _vest = [
            "CfgWeapons",
            _vanilla,
            _optional,
            missionNamespace getVariable ["KFH_cupRewardPreferredChance", 0.85]
        ] call KFH_fnc_selectAvailableConfigClass;
        if !(_vest isEqualTo "") then {
            [_cache, _vest, 1] call KFH_fnc_addOptionalItemCargo;
        };
    };
};

KFH_fnc_addRewardBackpacks = {
    params ["_cache", ["_tier", 1], ["_count", 1]];

    private _vanilla = switch (_tier) do {
        case 1: { ["B_AssaultPack_rgr", "B_FieldPack_khk"] };
        case 2: { ["B_Kitbag_rgr", "B_Kitbag_cbr"] };
        default { ["B_Carryall_mcamo"] };
    };
    private _optionalKey = switch (_tier) do {
        case 1: { "KFH_cupRewardBackpackPoolTier1" };
        case 2: { "KFH_cupRewardBackpackPoolTier2" };
        default { "KFH_cupRewardBackpackPoolTier3" };
    };
    private _backpack = [
        "CfgVehicles",
        _vanilla,
        missionNamespace getVariable [_optionalKey, []],
        missionNamespace getVariable ["KFH_cupRewardPreferredChance", 1]
    ] call KFH_fnc_selectAvailableConfigClass;

    if !(_backpack isEqualTo "") then {
        _cache addBackpackCargoGlobal [_backpack, _count max 1];
    };
};

KFH_fnc_addRewardWeaponBundle = {
    params ["_cache", "_bundle", ["_weaponCount", 1]];

    _bundle params [
        "_weaponClass",
        "_magazineClass",
        ["_magazineCount", 6],
        ["_attachments", []]
    ];

    _weaponCount = (_weaponCount max 1);
    if !([_cache, _weaponClass, _weaponCount] call KFH_fnc_addOptionalWeaponCargo) exitWith { false };

    private _rewardPlayers = [] call KFH_fnc_getRewardPlayerCount;
    private _bonusInterval = missionNamespace getVariable ["KFH_rewardWeaponMagazinePlayerBonusInterval", 2];
    private _playerBonusMags = if (_bonusInterval > 0) then { floor ((_rewardPlayers max 1) / _bonusInterval) } else { 0 };
    [_cache, _magazineClass, (_magazineCount * _weaponCount) + _playerBonusMags] call KFH_fnc_addOptionalMagazineCargo;
    {
        [_cache, _x, _weaponCount] call KFH_fnc_addOptionalItemCargo;
    } forEach ([_weaponClass, _attachments] call KFH_fnc_filterCompatibleWeaponAttachments);

    true
};

KFH_fnc_addRewardWeaponBundlePool = {
    params [
        "_cache",
        ["_vanillaBundles", []],
        ["_optionalBundles", []],
        ["_weaponCount", 1],
        ["_optionalChance", missionNamespace getVariable ["KFH_cupRewardPreferredChance", 0.85]]
    ];

    private _vanilla = _vanillaBundles select { [_x] call KFH_fnc_isWeaponBundleAvailable };
    private _optional = if (missionNamespace getVariable ["KFH_cupOptionalEnabled", true]) then {
        _optionalBundles select { [_x] call KFH_fnc_isWeaponBundleAvailable }
    } else {
        []
    };
    if ((missionNamespace getVariable ["KFH_cupBanVanillaWhenAvailable", true]) && {(count _optional) > 0}) then {
        _vanilla = [];
    };
    private _dynamicOptional = _optional select { (count _x) > 4 && {(_x select 4) isEqualTo "dynamicRhs"} };
    private _dynamicChance = missionNamespace getVariable ["KFH_dynamicRhsRewardPreferredChance", 0.75];

    private _added = 0;
    private _usedWeapons = [];
    private _addedBundles = [];
    for "_i" from 1 to (_weaponCount max 1) do {
        private _pool = [];
        if ((count _dynamicOptional) > 0 && {(random 1) < _dynamicChance}) then {
            _pool = +_dynamicOptional;
        } else {
        if ((count _optional) > 0 && {((count _vanilla) isEqualTo 0) || {(random 1) < _optionalChance}}) then {
            _pool = +_optional;
        } else {
            _pool = +_vanilla;
        };
        };
        if ((count _pool) isEqualTo 0) then { _pool = +_optional; };
        if ((count _pool) isEqualTo 0) then { _pool = +_vanilla; };

        if ((count _pool) > 0) then {
            private _eligible = _pool select { !((_x select 0) in _usedWeapons) };
            if ((count _eligible) isEqualTo 0) then {
                _eligible = _pool;
                _usedWeapons = [];
            };
            private _bundle = selectRandom _eligible;
            _usedWeapons pushBackUnique (_bundle select 0);
            if ([_cache, _bundle, 1] call KFH_fnc_addRewardWeaponBundle) then {
                _added = _added + 1;
                _addedBundles pushBack _bundle;
            };
        };
    };

    if ((count _addedBundles) > 0) then {
        missionNamespace setVariable ["KFH_recentRewardWeaponBundles", _addedBundles, true];
    };

    _added
};

KFH_fnc_addConfiguredItemCargo = {
    params ["_cache", ["_entries", []]];

    {
        _x params ["_className", ["_count", 1]];
        [_cache, _className, _count] call KFH_fnc_addOptionalItemCargo;
    } forEach _entries;
};

KFH_fnc_addConfiguredMagazineCargo = {
    params ["_cache", ["_entries", []]];

    {
        _x params ["_className", ["_count", 1]];
        [_cache, _className, _count] call KFH_fnc_addOptionalMagazineCargo;
    } forEach _entries;
};

KFH_fnc_addRewardAttachmentCargo = {
    params ["_cache", ["_tier", 1]];

    private _key = switch (_tier) do {
        case 1: { "KFH_rewardAttachmentCargoTier1" };
        case 2: { "KFH_rewardAttachmentCargoTier2" };
        default { "KFH_rewardAttachmentCargoTier3" };
    };

    [_cache, missionNamespace getVariable [_key, []]] call KFH_fnc_addConfiguredItemCargo;
};

KFH_fnc_getWeaponMagazineWellMagazines = {
    params ["_weaponCfg"];

    private _result = [];
    {
        private _wellCfg = configFile >> "CfgMagazineWells" >> _x;
        if (isClass _wellCfg) then {
            {
                _result append (getArray (_x >> "magazines"));
            } forEach (configProperties [_wellCfg, "isClass _x", true]);
        };
    } forEach (getArray (_weaponCfg >> "magazineWell"));

    _result
};

KFH_fnc_isMagazineCompatibleWithWeapon = {
    params ["_weaponClass", "_magazineClass"];

    private _weaponCfg = configFile >> "CfgWeapons" >> _weaponClass;
    if !(isClass _weaponCfg) exitWith { false };
    if !(isClass (configFile >> "CfgMagazines" >> _magazineClass)) exitWith { false };

    private _magazines = getArray (_weaponCfg >> "magazines");
    if (_magazineClass in _magazines) exitWith { true };

    _magazineClass in ([_weaponCfg] call KFH_fnc_getWeaponMagazineWellMagazines)
};

KFH_fnc_isMagazineCompatibleWithAnyWeapon = {
    params ["_weaponClasses", "_magazineClass"];

    (_weaponClasses findIf { [_x, _magazineClass] call KFH_fnc_isMagazineCompatibleWithWeapon }) >= 0
};

KFH_fnc_addSideCacheM4LargeMagazineCargo = {
    params ["_cache"];

    private _weaponClasses = (missionNamespace getVariable ["KFH_sideCacheM4LargeMagazineWeapons", []]) select {
        isClass (configFile >> "CfgWeapons" >> _x)
    };
    if ((count _weaponClasses) isEqualTo 0) exitWith { 0 };

    private _tokens = missionNamespace getVariable ["KFH_sideCacheM4LargeMagazineTokens", []];
    private _excludeTokens = missionNamespace getVariable ["KFH_sideCacheM4LargeMagazineExcludeTokens", []];
    private _minAmmo = missionNamespace getVariable ["KFH_sideCacheM4LargeMagazineMinAmmo", 40];
    private _maxTypes = missionNamespace getVariable ["KFH_sideCacheM4LargeMagazineMaxTypes", 4];
    private _countPerType = missionNamespace getVariable ["KFH_sideCacheM4LargeMagazineCount", 6];
    private _addedTypes = 0;
    private _addedClasses = [];

    {
        _x params ["_className", ["_count", _countPerType]];
        if (
            (_addedTypes < _maxTypes) &&
            {[_weaponClasses, _className] call KFH_fnc_isMagazineCompatibleWithAnyWeapon} &&
            {[_cache, _className, _count] call KFH_fnc_addOptionalMagazineCargo}
        ) then {
            _addedClasses pushBackUnique _className;
            _addedTypes = _addedTypes + 1;
        };
    } forEach (missionNamespace getVariable ["KFH_sideCacheM4LargeMagazineExplicitCargo", []]);

    {
        private _className = configName _x;
        private _displayName = getText (_x >> "displayName");
        private _haystack = format ["%1 %2", _className, _displayName];
        if (
            (_addedTypes < _maxTypes) &&
            {!(_className in _addedClasses)} &&
            {getNumber (_x >> "scope") >= 1} &&
            {(getNumber (_x >> "count")) >= _minAmmo} &&
            {[_haystack, _tokens] call KFH_fnc_stringContainsAny} &&
            {!([_haystack, _excludeTokens] call KFH_fnc_stringContainsAny)} &&
            {[_weaponClasses, _className] call KFH_fnc_isMagazineCompatibleWithAnyWeapon}
        ) then {
            [_cache, _className, _countPerType] call KFH_fnc_addOptionalMagazineCargo;
            _addedTypes = _addedTypes + 1;
        };
    } forEach (configProperties [configFile >> "CfgMagazines", "isClass _x", true]);

    if (_addedTypes > 0) then {
        [format ["Side cache added %1 M4/M16-compatible large magazine types.", _addedTypes]] call KFH_fnc_log;
    } else {
        ["Side cache found no M4/M16-compatible large RHS magazines; skipped SAW soft-pouch belts."] call KFH_fnc_log;
    };

    _addedTypes
};

KFH_fnc_addSideCacheBonusCargo = {
    params ["_cache"];

    [_cache, missionNamespace getVariable ["KFH_sideCacheBonusMagazineCargo", []]] call KFH_fnc_addConfiguredMagazineCargo;
    [_cache] call KFH_fnc_addSideCacheM4LargeMagazineCargo;
    [_cache, missionNamespace getVariable ["KFH_sideCacheBonusItemCargo", []]] call KFH_fnc_addConfiguredItemCargo;
};

KFH_fnc_addOptionalFlareKit = {
    params ["_cache"];

    private _added = [_cache, "hgun_Pistol_Signal_F", 1] call KFH_fnc_addOptionalWeaponCargo;
    if (_added) then {
        [_cache, "6Rnd_RedSignal_F", 2] call KFH_fnc_addOptionalMagazineCargo;
        [_cache, "6Rnd_GreenSignal_F", 2] call KFH_fnc_addOptionalMagazineCargo;
    } else {
        [_cache, "UGL_FlareWhite_F", 4] call KFH_fnc_addOptionalMagazineCargo;
        [_cache, "UGL_FlareRed_F", 2] call KFH_fnc_addOptionalMagazineCargo;
    };
};

KFH_fnc_unitHasFlareCapability = {
    params ["_unit"];

    if (isNull _unit) exitWith { false };
    if !(alive _unit) exitWith { false };

    private _weapons = weapons _unit;
    private _magazines = magazines _unit;

    (_weapons findIf { _x isEqualTo "hgun_Pistol_Signal_F" }) >= 0 ||
    {(_magazines findIf { (_x find "Signal") >= 0 || {(_x find "Flare") >= 0} }) >= 0}
};

KFH_fnc_teamHasFlareCapability = {
    (([] call KFH_fnc_getHumanPlayers) findIf {
        [_x] call KFH_fnc_unitHasFlareCapability
    }) >= 0
};

KFH_fnc_isFlareShot = {
    params ["_weaponClass", "_ammoClass"];

    if (_weaponClass isEqualTo "hgun_Pistol_Signal_F") exitWith { true };
    private _parents = [(configFile >> "CfgAmmo" >> _ammoClass), true] call BIS_fnc_returnParents;
    if ("FlareBase" in _parents) exitWith { true };
    if ((_ammoClass find "Signal") >= 0) exitWith { true };
    if ((_ammoClass find "Flare") >= 0) exitWith { true };

    false
};

KFH_fnc_getExtractionHelis = {
    (missionNamespace getVariable ["KFH_extractionHelis", []]) select {
        !isNull _x && {alive _x}
    }
};

KFH_fnc_getExtractionHeli = {
    private _helis = [] call KFH_fnc_getExtractionHelis;
    if ((count _helis) > 0) exitWith { _helis select 0 };
    missionNamespace getVariable ["KFH_extractionHeli", objNull]
};

KFH_fnc_getExtractionHeliCount = {
    private _baseCount = missionNamespace getVariable ["KFH_extractionHeliBaseCount", 2];
    private _seatEstimate = (missionNamespace getVariable ["KFH_extractionHeliSeatEstimate", 8]) max 1;
    private _scaledPlayers = ([] call KFH_fnc_getScalingPlayerCount) max 1;
    (_baseCount max (ceil (_scaledPlayers / _seatEstimate))) max 1
};

KFH_fnc_getExtractionBoardedPlayers = {
    params [["_alivePlayers", []], ["_helis", []]];

    if ((count _alivePlayers) isEqualTo 0) then {
        _alivePlayers = [] call KFH_fnc_getAliveHumanPlayers;
    };
    if ((count _helis) isEqualTo 0) then {
        _helis = [] call KFH_fnc_getExtractionHelis;
    };
    if ((count _helis) isEqualTo 0) exitWith { [] };

    _alivePlayers select { (vehicle _x) in _helis }
};

KFH_fnc_areAllExtractionHelisReadyForBoarding = {
    private _helis = [] call KFH_fnc_getExtractionHelis;
    if ((count _helis) isEqualTo 0) exitWith { false };

    ({ (_x getVariable ["KFH_extractionHeliState", "Init"]) isEqualTo "WaitForPlayers" } count _helis) isEqualTo (count _helis)
};

KFH_fnc_isObjectiveAreaSafe = {
    params ["_pos", ["_mode", "checkpoint"]];

    if (surfaceIsWater _pos) exitWith { false };
    if ((getTerrainHeightASL _pos) < -0.5) exitWith { false };

    private _isExtract = _mode isEqualTo "extract";
    private _sampleDistance = if (_isExtract) then { 12 } else { 9 };
    private _maxDiff = if (_isExtract) then { 2.4 } else { 3.1 };
    private _dirs = [0, 45, 90, 135, 180, 225, 270, 315];
    private _h0 = getTerrainHeightASL _pos;
    if !(_dirs isEqualTo []) then {
        private _failedSlope = _dirs findIf {
            private _samplePos = _pos getPos [_sampleDistance, _x];
            (abs (_h0 - (getTerrainHeightASL _samplePos))) > _maxDiff
        };
        if (_failedSlope >= 0) exitWith { false };
    };

    private _buildingRadius = missionNamespace getVariable [if (_isExtract) then { "KFH_extractSafeBuildingRadius" } else { "KFH_objectiveSafeBuildingRadius" }, if (_isExtract) then { 42 } else { 24 }];
    private _terrainRadius = missionNamespace getVariable [if (_isExtract) then { "KFH_extractSafeTerrainRadius" } else { "KFH_objectiveSafeTerrainRadius" }, if (_isExtract) then { 28 } else { 18 }];
    private _nearObjects = nearestObjects [_pos, ["House", "Building", "Wall", "Fence"], _buildingRadius];
    if ((count _nearObjects) > 0) exitWith { false };

    private _terrainTypes = if (_isExtract) then {
        ["HOUSE", "BUILDING", "WALL", "FENCE", "TREE", "SMALL TREE", "BUSH", "ROCK"]
    } else {
        ["HOUSE", "BUILDING", "WALL", "FENCE"]
    };
    private _terrainBlockers = nearestTerrainObjects [_pos, _terrainTypes, _terrainRadius, false, true];
    if ((count _terrainBlockers) > 0) exitWith { false };

    private _roadRadius = missionNamespace getVariable [if (_isExtract) then { "KFH_extractSafeRoadClearRadius" } else { "KFH_objectiveRoadSearchRadius" }, if (_isExtract) then { 16 } else { 55 }];
    private _roads = _pos nearRoads _roadRadius;
    if (_isExtract) then {
        if ((count _roads) > 0) exitWith { false };
    } else {
        if ((count _roads) isEqualTo 0) exitWith { false };
    };

    true
};

KFH_fnc_findNearbySafeObjectivePos = {
    params ["_origin", ["_mode", "checkpoint"], ["_preferredDir", -1]];

    if ([_origin, _mode] call KFH_fnc_isObjectiveAreaSafe) exitWith { +_origin };

    private _distances = if (_mode isEqualTo "extract") then {
        +(missionNamespace getVariable ["KFH_extractSafeSearchDistances", [0, 70, 110, 150, 200, 260, 320]])
    } else {
        [0, 35, 55, 80, 110, 150, 200]
    };
    private _dirs = if (_preferredDir >= 0) then {
        [_preferredDir, _preferredDir + 30, _preferredDir - 30, _preferredDir + 60, _preferredDir - 60, _preferredDir + 90, _preferredDir - 90, _preferredDir + 135, _preferredDir - 135, _preferredDir + 180]
    } else {
        [0, 45, 90, 135, 180, 225, 270, 315]
    };

    private _best = [];
    private _bestDistance = 1e9;

    {
        private _distance = _x;
        {
            private _candidate = if (_distance <= 0) then { +_origin } else { _origin getPos [_distance, _x] };
            if ([_candidate, _mode] call KFH_fnc_isObjectiveAreaSafe) then {
                private _candidateDistance = _origin distance2D _candidate;
                if (_candidateDistance < _bestDistance) then {
                    _best = [_candidate select 0, _candidate select 1, 0];
                    _bestDistance = _candidateDistance;
                };
            };
        } forEach _dirs;
    } forEach _distances;

    if ((count _best) isEqualTo 0) exitWith { +_origin };
    _best
};

KFH_fnc_refreshExtractSpawnMarkers = {
    params ["_extractMarker"];

    if !(_extractMarker in allMapMarkers) exitWith {};

    private _routePoints = missionNamespace getVariable ["KFH_dynamicRoutePoints", []];
    private _extractPos = getMarkerPos _extractMarker;
    private _referencePos = if ((count _routePoints) >= 2) then {
        _routePoints select ((count _routePoints) - 2)
    } else {
        _extractPos vectorAdd [-120, -40, 0]
    };
    private _extractDir = [_referencePos, _extractPos] call BIS_fnc_dirTo;
    private _extractFront = [_extractPos, 160, _extractDir + 180] call KFH_fnc_dynamicRouteRelPos;
    private _spawnOffsets = [
        ["kfh_spawn_extract_1", -75],
        ["kfh_spawn_extract_2", 75]
    ];

    {
        private _markerName = _x select 0;
        private _offset = _x select 1;
        if (_markerName in allMapMarkers) then {
            _markerName setMarkerPos ([_extractFront, 75, _extractDir + _offset] call KFH_fnc_dynamicRouteRelPos);
            _markerName setMarkerDir _extractDir;
        };
    } forEach _spawnOffsets;
};

KFH_fnc_protectExtractionHeli = {
    params ["_heli"];

    if (isNull _heli) exitWith {};
    if !(missionNamespace getVariable ["KFH_extractionHeliInvulnerable", true]) exitWith {};

    _heli allowDamage false;
    _heli setDamage 0;
    _heli setFuel 1;
    _heli setVehicleAmmo 1;

    {
        _x allowDamage false;
        _x setDamage 0;
        _x disableAI "AUTOCOMBAT";
        _x allowFleeing 0;
    } forEach crew _heli;
};

KFH_fnc_getExtractionFlightVectors = {
    params [["_extractPosOverride", []]];

    private _extractPos = if ((count _extractPosOverride) >= 2) then {
        +_extractPosOverride
    } else {
        getMarkerPos (missionNamespace getVariable ["KFH_extractMarker", "kfh_extract"])
    };
    private _routePoints = missionNamespace getVariable ["KFH_dynamicRoutePoints", []];
    private _approachOrigin = if ((count _routePoints) >= 2) then {
        _routePoints select ((count _routePoints) - 2)
    } else {
        _extractPos vectorAdd [-400, -200, 0]
    };
    private _dir = [_approachOrigin, _extractPos] call BIS_fnc_dirTo;
    private _spawnPos = [
        (_extractPos select 0) - ((sin _dir) * KFH_extractionHeliSpawnDistance),
        (_extractPos select 1) - ((cos _dir) * KFH_extractionHeliSpawnDistance),
        KFH_extractionHeliApproachHeight
    ];
    private _evacVec = [
        (sin _dir) * KFH_extractionHeliEvacDistance,
        (cos _dir) * KFH_extractionHeliEvacDistance,
        220
    ];

    [_spawnPos, _dir, _evacVec]
};

KFH_fnc_getExtractionLzSlots = {
    private _extractPos = getMarkerPos (missionNamespace getVariable ["KFH_extractMarker", "kfh_extract"]);
    private _flight = [_extractPos] call KFH_fnc_getExtractionFlightVectors;
    _flight params ["_baseSpawnPos", "_dir"];

    private _count = [] call KFH_fnc_getExtractionHeliCount;
    private _spacing = missionNamespace getVariable ["KFH_extractionHeliSpacing", 26];
    private _minSeparation = missionNamespace getVariable ["KFH_extractionHeliMinSlotSeparation", 70];
    private _slotDir = _dir + 90;
    private _slots = [];

    for "_i" from 0 to (_count - 1) do {
        private _offset = (_i - ((_count - 1) / 2)) * _spacing;
        private _slotPos = [
            (_extractPos select 0) + ((sin _slotDir) * _offset),
            (_extractPos select 1) + ((cos _slotDir) * _offset),
            0
        ];
        private _safeSlotPos = [_slotPos, "extract", _dir] call KFH_fnc_findNearbySafeObjectivePos;
        private _tooClose = (_slots findIf { (_x distance2D _safeSlotPos) < _minSeparation }) >= 0;
        if (_tooClose) then {
            private _side = if (_offset < 0) then { -1 } else { 1 };
            private _baseOffset = abs _offset;
            private _replacement = [];

            for "_step" from 1 to 6 do {
                private _candidateOffset = _side * (_baseOffset + (_spacing * _step));
                private _candidate = [
                    (_extractPos select 0) + ((sin _slotDir) * _candidateOffset),
                    (_extractPos select 1) + ((cos _slotDir) * _candidateOffset),
                    0
                ];
                if (
                    ((_slots findIf { (_x distance2D _candidate) < _minSeparation }) < 0) &&
                    {[_candidate, "extract"] call KFH_fnc_isObjectiveAreaSafe}
                ) exitWith {
                    _replacement = +_candidate;
                };
            };

            if ((count _replacement) > 0) then {
                _safeSlotPos = _replacement;
            } else {
                private _forcedOffset = _side * (_baseOffset + (_spacing * 7));
                _safeSlotPos = [
                    (_extractPos select 0) + ((sin _slotDir) * _forcedOffset),
                    (_extractPos select 1) + ((cos _slotDir) * _forcedOffset),
                    0
                ];
                [format ["Extraction LZ slot %1 forced apart to avoid overlap at %2.", _i + 1, mapGridPosition _safeSlotPos]] call KFH_fnc_log;
            };
        };
        _slots pushBack _safeSlotPos;
    };

    _slots
};

KFH_fnc_spawnSingleExtractionHeli = {
    params ["_extractPos", ["_slotIndex", 0]];

    private _flight = [_extractPos] call KFH_fnc_getExtractionFlightVectors;
    _flight params ["_spawnPos", "_dir", "_evacVec"];
    private _result = [_spawnPos, _dir, KFH_extractionHeliClass, west] call BIS_fnc_spawnVehicle;
    private _heli = _result select 0;
    private _group = _result select 2;

    _heli setPosATL _spawnPos;
    _heli setDir _dir;
    _heli flyInHeight KFH_extractionHeliApproachHeight;
    _heli setUnloadInCombat [false, false];
    _heli setVariable ["KFH_extractionHeliState", "Init", true];
    _heli setVariable ["KFH_extractionPos", _extractPos, true];
    _heli setVariable ["KFH_extractionEvacVec", _evacVec, true];
    _heli setVariable ["KFH_extractionSpawnPos", _spawnPos, true];
    _heli setVariable ["KFH_extractionSlotIndex", _slotIndex, true];
    _heli lockCargo false;
    _heli allowDamage !(missionNamespace getVariable ["KFH_extractionHeliInvulnerable", true]);
    _group setGroupIdGlobal [format ["Angel %1", _slotIndex + 1]];
    _group setBehaviour "CARELESS";
    _group setCombatMode "BLUE";
    _group setSpeedMode "FULL";
    {
        _x disableAI "AUTOCOMBAT";
        _x allowFleeing 0;
    } forEach units _group;
    [_heli] call KFH_fnc_protectExtractionHeli;
    [_heli] spawn KFH_fnc_extractionHeliLoop;

    _heli
};

KFH_fnc_tryCompleteExtractionFromFormation = {
    if (!isServer) exitWith { false };
    if (missionNamespace getVariable ["KFH_extractionCompleted", false]) exitWith { true };

    private _trackedHelis = (missionNamespace getVariable ["KFH_extractionHelis", []]) select { !isNull _x };
    if ((count _trackedHelis) isEqualTo 0) exitWith { false };

    private _boardedAtDeparture = missionNamespace getVariable ["KFH_extractionPassengersAtDeparture", -1];
    private _aliveAtDeparture = missionNamespace getVariable ["KFH_extractionAliveAtDeparture", _boardedAtDeparture max 0];
    if (_boardedAtDeparture < 0) exitWith { false };

    private _passengerHelis = _trackedHelis select {
        (_x getVariable ["KFH_extractionPassengersAtDeparture", 0]) > 0
    };
    if ((count _passengerHelis) isEqualTo 0) then {
        _passengerHelis = _trackedHelis select { alive _x };
    };

    private _pendingPassengerHelis = _passengerHelis select {
        alive _x && {!(_x getVariable ["KFH_extractionFarEnoughReached", false])}
    };
    if ((count _pendingPassengerHelis) > 0) then {
        private _departureStartedAt = missionNamespace getVariable ["KFH_extractionDepartureStartedAt", -1];
        private _forceAfter = missionNamespace getVariable ["KFH_extractionCompletionForceSeconds", 105];
        if (_departureStartedAt >= 0 && {(time - _departureStartedAt) >= _forceAfter}) then {
            {
                _x setVariable ["KFH_extractionFarEnoughReached", true, true];
            } forEach _pendingPassengerHelis;
            [format ["Extraction completion safety timeout fired after %1s.", round (time - _departureStartedAt)], "EXTRACT"] call KFH_fnc_appendRunEvent;
            _pendingPassengerHelis = [];
        };
    };
    if ((count _pendingPassengerHelis) > 0) exitWith { false };

    missionNamespace setVariable ["KFH_extractionCompleted", true, true];
    if (_boardedAtDeparture > 0) then {
        private _message = if (_boardedAtDeparture < _aliveAtDeparture) then {
            format ["Angel flight escaped with %1 of %2 surviving operators aboard.", _boardedAtDeparture, _aliveAtDeparture]
        } else {
            "Angel flight lifted the team out. Extraction successful."
        };
        [true, _message] call KFH_fnc_completeMission;
    } else {
        [false, "Angel flight lifted empty. No survivors made it aboard."] call KFH_fnc_completeMission;
    };
    true
};

KFH_fnc_spawnExtractionHeli = {
    if (!isServer) exitWith { objNull };

    private _existing = [] call KFH_fnc_getExtractionHelis;
    if ((count _existing) > 0) exitWith { _existing select 0 };

    private _slots = [] call KFH_fnc_getExtractionLzSlots;
    private _helipads = [];
    private _spawnedHelis = [];
    {
        private _pad = "Land_HelipadEmpty_F" createVehicle _x;
        _pad setPosATL _x;
        _helipads pushBack _pad;

        private _heli = [_x, _forEachIndex] call KFH_fnc_spawnSingleExtractionHeli;
        if (!isNull _heli && {alive _heli}) then {
            _spawnedHelis pushBack _heli;
        };
    } forEach _slots;

    missionNamespace setVariable ["KFH_extractHelipads", _helipads, true];
    missionNamespace setVariable ["KFH_extractHelipad", if ((count _helipads) > 0) then { _helipads select 0 } else { objNull }, true];
    missionNamespace setVariable ["KFH_extractionHelis", _spawnedHelis, true];
    missionNamespace setVariable ["KFH_extractionHeli", if ((count _spawnedHelis) > 0) then { _spawnedHelis select 0 } else { objNull }, true];
    missionNamespace setVariable ["KFH_extractionHeliState", "Approach", true];

    ["angel_one_inbound_log", [], "EXTRACT"] call KFH_fnc_appendRunEventKey;
    ["angel_one_inbound_chat"] call KFH_fnc_notifyAllKey;

    missionNamespace getVariable ["KFH_extractionHeli", objNull]
};

KFH_fnc_triggerExtractionDeparture = {
    params ["_heliRef", ["_reason", "timeout"], ["_boardedCount", -1], ["_aliveCount", -1]];

    if (!isServer) exitWith { false };

    private _helis = if ((typeName _heliRef) isEqualTo "ARRAY") then {
        _heliRef select { !isNull _x && {alive _x} }
    } else {
        if (isNull _heliRef) then { [] } else { [_heliRef] }
    };
    if ((count _helis) isEqualTo 0) then {
        _helis = [] call KFH_fnc_getExtractionHelis;
    };
    if ((count _helis) isEqualTo 0) exitWith { false };

    private _eligibleHelis = _helis select {
        !((_x getVariable ["KFH_extractionHeliState", "Init"]) in ["Evac", "EvacActive"])
    };
    if ((count _eligibleHelis) isEqualTo 0) exitWith { false };

    private _alivePlayers = [] call KFH_fnc_getAliveHumanPlayers;
    if (_aliveCount < 0) then {
        _aliveCount = count _alivePlayers;
    };
    if (_boardedCount < 0) then {
        _boardedCount = count ([_alivePlayers, _helis] call KFH_fnc_getExtractionBoardedPlayers);
    };
    private _boardedPlayers = [_alivePlayers, _helis] call KFH_fnc_getExtractionBoardedPlayers;

    {
        private _heli = _x;
        private _boardedOnHeli = { (vehicle _x) isEqualTo _heli } count _boardedPlayers;
        _heli setVariable ["KFH_extractionPassengersAtDeparture", _boardedOnHeli, true];
        _x setVariable ["KFH_extractionAliveAtDeparture", _aliveCount, true];
        _x setVariable ["KFH_extractionDepartureReason", _reason, true];
        _x setVariable ["KFH_extractionFarEnoughReached", false, true];
        _x setVariable ["KFH_extractionHeliState", "Evac", true];
    } forEach _eligibleHelis;
    missionNamespace setVariable ["KFH_extractionPassengersAtDeparture", _boardedCount, true];
    missionNamespace setVariable ["KFH_extractionAliveAtDeparture", _aliveCount, true];
    missionNamespace setVariable ["KFH_extractionDepartureStartedAt", time, true];
    missionNamespace setVariable ["KFH_extractionHeliState", "Evac", true];
    missionNamespace setVariable ["KFH_extractHoldStart", -1];
    missionNamespace setVariable ["KFH_extractAutoDepartAt", -1, true];
    missionNamespace setVariable ["KFH_extractAutoDepartWarned", false, true];

    switch (_reason) do {
        case "all_boarded": {
            ["angel_one_all_aboard_log", [], "EXTRACT"] call KFH_fnc_appendRunEventKey;
            ["angel_one_all_aboard_chat"] call KFH_fnc_notifyAllKey;
        };
        case "timeout": {
            ["angel_one_timeout_log", [], "EXTRACT"] call KFH_fnc_appendRunEventKey;
            ["angel_one_timeout_chat", [_boardedCount]] call KFH_fnc_notifyAllKey;
        };
        default {
            ["Angel One departing extraction zone.", "EXTRACT"] call KFH_fnc_appendRunEvent;
        };
    };

    true
};

KFH_fnc_extractionHeliLoop = {
    params ["_heli"];

    if (isNull _heli) exitWith {};

    private _extractPos = _heli getVariable ["KFH_extractionPos", getPosATL _heli];
    private _evacVec = _heli getVariable ["KFH_extractionEvacVec", [0, 0, 220]];

    while {alive _heli} do {
        if (missionNamespace getVariable ["KFH_extractionHeliInvulnerable", true]) then {
            [_heli] call KFH_fnc_protectExtractionHeli;
        };
        private _state = _heli getVariable ["KFH_extractionHeliState", "Init"];

        switch (_state) do {
            case "Init": {
                _heli setVariable ["KFH_extractionHeliState", "Approach", true];
            };
            case "Approach": {
                {
                    deleteWaypoint _x;
                } forEach waypoints (group _heli);
                private _waypoint = (group _heli) addWaypoint [_extractPos, 30];
                _waypoint setWaypointSpeed "FULL";
                _waypoint setWaypointBehaviour "CARELESS";
                _waypoint setWaypointType "MOVE";
                _waypoint setWaypointStatements ["true", "(vehicle this) setVariable [""KFH_extractionHeliState"",""Land"",true]; missionNamespace setVariable [""KFH_extractionHeliState"",""Land"",true];"];
                _heli setVariable ["KFH_extractionHeliState", "ApproachActive", true];
                missionNamespace setVariable ["KFH_extractionHeliState", "Approach", true];
                _heli setVariable ["KFH_extractionApproachStartedAt", time, true];
                [format ["Angel One approach started at %1.", mapGridPosition _extractPos], "EXTRACT"] call KFH_fnc_appendRunEvent;
            };
            case "ApproachActive": {
                private _distance2D = _heli distance2D _extractPos;
                if (_distance2D < 300) then {
                    _heli setSpeedMode "NORMAL";
                    _heli flyInHeight 30;
                };
                if (_distance2D < (missionNamespace getVariable ["KFH_extractionHeliLandCommandDistance", 220])) then {
                    _heli setSpeedMode "LIMITED";
                    _heli flyInHeight 0;
                    _heli land "LAND";
                };
                if (_distance2D < 80) then {
                    _heli setVariable ["KFH_extractionHeliState", "Land", true];
                    missionNamespace setVariable ["KFH_extractionHeliState", "Land", true];
                    _heli setVariable ["KFH_extractionLandingStartedAt", time, true];
                };
            };
            case "Land": {
                if ((_heli getVariable ["KFH_extractionLandingStartedAt", -1]) < 0) then {
                    _heli setVariable ["KFH_extractionLandingStartedAt", time, true];
                    [format ["Angel One landing run started. dist=%1 alt=%2", round (_heli distance2D _extractPos), round ((getPosATL _heli) select 2)], "EXTRACT"] call KFH_fnc_appendRunEvent;
                };
                _heli setSpeedMode "LIMITED";
                _heli flyInHeight 0;
                _heli land "LAND";
                private _landStarted = _heli getVariable ["KFH_extractionLandingStartedAt", time];
                private _timeout = missionNamespace getVariable ["KFH_extractionHeliLandingTimeoutSeconds", 75];
                private _settled = isTouchingGround _heli || {((getPosATL _heli) select 2) <= 1.8};
                if (!_settled && {(time - _landStarted) >= _timeout}) then {
                    private _fallbackLz = [_extractPos, "extract", [_heli, _extractPos] call BIS_fnc_dirTo] call KFH_fnc_findNearbySafeObjectivePos;
                    _extractPos = +_fallbackLz;
                    _heli setVariable ["KFH_extractionPos", _extractPos, true];
                    missionNamespace setVariable ["KFH_extractMarkerPosFallback", _extractPos];
                    _heli setVelocity [0, 0, 0];
                    _heli setDir ([_heli, _extractPos] call BIS_fnc_dirTo);
                    _heli setPosATL [_extractPos select 0, _extractPos select 1, 1.1];
                    _heli land "LAND";
                    _settled = true;
                    [format ["Angel One landing watchdog settled heli at LZ after %1s.", round (time - _landStarted)], "EXTRACT"] call KFH_fnc_appendRunEvent;
                };
                if (_settled && {(_heli getVariable ["KFH_extractionHeliState", "Land"]) isNotEqualTo "Evac"}) then {
                    _heli setVariable ["KFH_extractionHeliState", "WaitForPlayers", true];
                    if ([] call KFH_fnc_areAllExtractionHelisReadyForBoarding) then {
                        missionNamespace setVariable ["KFH_extractionHeliState", "WaitForPlayers", true];
                        if ((missionNamespace getVariable ["KFH_extractAutoDepartAt", -1]) < 0) then {
                            missionNamespace setVariable ["KFH_extractAutoDepartAt", time + KFH_extractBoardTimeoutSeconds, true];
                            missionNamespace setVariable ["KFH_extractAutoDepartWarned", false, true];
                            ["angel_one_landed_log", [], "EXTRACT"] call KFH_fnc_appendRunEventKey;
                            ["angel_one_landed_chat", [KFH_extractBoardTimeoutSeconds]] call KFH_fnc_notifyAllKey;
                            ["angel_one_manual_ready", [], "EXTRACT"] call KFH_fnc_appendRunEventKey;
                        };
                    } else {
                        missionNamespace setVariable ["KFH_extractionHeliState", "Land", true];
                    };
                };
            };
            case "WaitForPlayers": {
                if !(isTouchingGround _heli || {((getPosATL _heli) select 2) <= 2}) then {
                    _heli setVariable ["KFH_extractionHeliState", "Land", true];
                    missionNamespace setVariable ["KFH_extractionHeliState", "Land", true];
                    missionNamespace setVariable ["KFH_extractAutoDepartAt", -1, true];
                    missionNamespace setVariable ["KFH_extractAutoDepartWarned", false, true];
                };
            };
            case "Evac": {
                private _evacTarget = _extractPos vectorAdd _evacVec;
                _heli land "NONE";
                _heli engineOn true;
                _heli setSpeedMode "FULL";
                _heli flyInHeight (KFH_extractionHeliApproachHeight + 40);
                _heli doMove _evacTarget;
                if (!isNull (driver _heli)) then {
                    (driver _heli) doMove _evacTarget;
                    (driver _heli) commandMove _evacTarget;
                };
                {
                    deleteWaypoint _x;
                } forEach waypoints (group _heli);
                private _waypoint = (group _heli) addWaypoint [_evacTarget, 0];
                _waypoint setWaypointSpeed "FULL";
                _waypoint setWaypointBehaviour "CARELESS";
                _waypoint setWaypointType "MOVE";
                _waypoint setWaypointCompletionRadius 80;
                missionNamespace setVariable ["KFH_extractionHeliState", "EvacActive", true];
                _heli setVariable ["KFH_extractionHeliState", "EvacActive", true];
                _heli setVariable ["KFH_extractionEvacStartedAt", time, true];
                _heli setVariable ["KFH_extractionNextEvacNudgeAt", time + (missionNamespace getVariable ["KFH_extractionHeliEvacNudgeSeconds", 12]), true];
                ["Angel One received evac waypoint and is lifting from the LZ.", "EXTRACT"] call KFH_fnc_appendRunEvent;
            };
            case "EvacActive": {
                private _evacTarget = _extractPos vectorAdd _evacVec;
                private _nextNudge = _heli getVariable ["KFH_extractionNextEvacNudgeAt", -1];
                if (_nextNudge >= 0 && {time >= _nextNudge}) then {
                    private _alt = (getPosATL _heli) select 2;
                    if ((_heli distance2D _extractPos) < 180 || {_alt < 15}) then {
                        _heli land "NONE";
                        _heli engineOn true;
                        _heli flyInHeight (KFH_extractionHeliApproachHeight + 60);
                        _heli doMove _evacTarget;
                        if (!isNull (driver _heli)) then {
                            (driver _heli) doMove _evacTarget;
                            (driver _heli) commandMove _evacTarget;
                        };
                        [format ["Angel One evac nudge issued. dist=%1 alt=%2", round (_heli distance2D _extractPos), round _alt], "EXTRACT"] call KFH_fnc_appendRunEvent;
                    };
                    _heli setVariable ["KFH_extractionNextEvacNudgeAt", time + (missionNamespace getVariable ["KFH_extractionHeliEvacNudgeSeconds", 12]), true];
                };
                if ((_heli distance2D _extractPos) >= KFH_extractionHeliFarEnoughDistance) exitWith {
                    _heli setVariable ["KFH_extractionFarEnoughReached", true, true];
                    [] call KFH_fnc_tryCompleteExtractionFromFormation;
                };
            };
            default {};
        };

        sleep 2;
    };

    if ((missionNamespace getVariable ["KFH_phase", "boot"]) isEqualTo "extract") then {
        private _remainingHelis = (missionNamespace getVariable ["KFH_extractionHelis", []]) select {
            !isNull _x && {alive _x} && {!(_x isEqualTo _heli)}
        };
        missionNamespace setVariable ["KFH_extractionHelis", _remainingHelis, true];
        missionNamespace setVariable ["KFH_extractionHeli", if ((count _remainingHelis) > 0) then { _remainingHelis select 0 } else { objNull }, true];
        if ((count _remainingHelis) > 0) exitWith {};

        private _retries = (missionNamespace getVariable ["KFH_extractionHeliRetryCount", 0]) + 1;
        private _retryLimit = missionNamespace getVariable ["KFH_extractionHeliBackupRetryLimit", 2];
        missionNamespace setVariable ["KFH_extractionHeli", objNull, true];
        missionNamespace setVariable ["KFH_extractionHelis", [], true];
        missionNamespace setVariable ["KFH_extractionHeliState", "idle", true];
        if (_retries <= _retryLimit) then {
            missionNamespace setVariable ["KFH_extractionHeliRetryCount", _retries, true];
            ["backup_pickup"] call KFH_fnc_notifyAllKey;
            [] spawn {
                sleep (missionNamespace getVariable ["KFH_extractionHeliBackupRetryDelaySeconds", 4]);
                [] call KFH_fnc_spawnExtractionHeli;
            };
        } else {
            [false, "Extraction helicopter was lost before the team got out."] call KFH_fnc_completeMission;
        };
    };
};

KFH_fnc_buildExtractionFinaleSpecialQueue = {
    private _queue = [];
    private _roles = missionNamespace getVariable ["KFH_extractionFinaleSpecialRoles", []];

    {
        private _roleClass = [[_x]] call KFH_fnc_selectSpecialRoleFromEntries;
        if ((count _roleClass) >= 2) then {
            _queue pushBack _roleClass;
        };
    } forEach _roles;

    private _juggernautRoles = missionNamespace getVariable ["KFH_extractionFinaleJuggernautRoles", []];
    if ((count _juggernautRoles) > 0) then {
        private _juggernaut = [_juggernautRoles] call KFH_fnc_selectSpecialRoleFromEntries;
        if ((count _juggernaut) >= 2 && {(_juggernaut select 0) in ["goliath", "smasher"]} && {!((_juggernaut select 1) isEqualTo "")}) then {
            _queue pushBack _juggernaut;
        };
    };

    private _shuffled = [];
    while {(count _queue) > 0} do {
        _shuffled pushBack (_queue deleteAt (floor (random (count _queue))));
    };
    _shuffled
};

KFH_fnc_startExtractionFinaleRush = {
    if !(missionNamespace getVariable ["KFH_extractionFinaleRushEnabled", true]) exitWith {};
    if (missionNamespace getVariable ["KFH_extractionFinaleRushActive", false]) exitWith {};

    private _queue = [] call KFH_fnc_buildExtractionFinaleSpecialQueue;
    missionNamespace setVariable ["KFH_extractionFinaleRushActive", true, true];
    missionNamespace setVariable ["KFH_extractionFinaleSpecialQueue", _queue, true];
    missionNamespace setVariable ["KFH_extractionFinaleNextSpecialAt", time + 3, true];
    [format ["Extraction finale rush armed with %1 special contacts.", count _queue]] call KFH_fnc_log;
};

KFH_fnc_tickExtractionFinaleRush = {
    if !(missionNamespace getVariable ["KFH_extractionFinaleRushActive", false]) exitWith {};

    private _nextAt = missionNamespace getVariable ["KFH_extractionFinaleNextSpecialAt", -1];
    if (_nextAt < 0 || {time < _nextAt}) exitWith {};

    private _queue = missionNamespace getVariable ["KFH_extractionFinaleSpecialQueue", []];
    if ((count _queue) isEqualTo 0) exitWith {
        missionNamespace setVariable ["KFH_extractionFinaleRushActive", false, true];
        missionNamespace setVariable ["KFH_extractionFinaleNextSpecialAt", -1, true];
    };

    private _extractMarker = missionNamespace getVariable ["KFH_extractMarker", "kfh_extract"];
    private _extractPos = getMarkerPos _extractMarker;
    private _spawnCount = 1;
    if ((count _queue) > 1 && {(random 1) < (missionNamespace getVariable ["KFH_extractionFinaleSpecialPairChance", 0.35])}) then {
        _spawnCount = 2;
    };

    private _spawned = 0;
    for "_i" from 1 to _spawnCount do {
        if ((count _queue) > 0) then {
            private _roleClass = _queue deleteAt 0;
            _roleClass params ["_role", "_className"];
            private _isJuggernaut = _role in ["goliath", "smasher"];
            private _minDistance = if (_isJuggernaut) then {
                missionNamespace getVariable ["KFH_extractionFinaleJuggernautMinDistance", 230]
            } else {
                if (_role isEqualTo "screamer") then {
                    missionNamespace getVariable ["KFH_extractionFinaleScreamerMinDistance", 170]
                } else {
                    missionNamespace getVariable ["KFH_extractionFinaleSpecialMinDistance", 90]
                }
            };
            private _maxDistance = if (_isJuggernaut) then {
                missionNamespace getVariable ["KFH_extractionFinaleJuggernautMaxDistance", 360]
            } else {
                if (_role isEqualTo "screamer") then {
                    missionNamespace getVariable ["KFH_extractionFinaleScreamerMaxDistance", 300]
                } else {
                    missionNamespace getVariable ["KFH_extractionFinaleSpecialMaxDistance", 185]
                }
            };
            private _unit = [
                _extractPos,
                _className,
                _role,
                _minDistance,
                _maxDistance,
                _extractPos,
                true,
                true,
                false
            ] call KFH_fnc_spawnSpecialInfected;
            if !(isNull _unit) then {
                _spawned = _spawned + 1;
            };
        };
    };

    missionNamespace setVariable ["KFH_extractionFinaleSpecialQueue", _queue, true];
    missionNamespace setVariable [
        "KFH_extractionFinaleNextSpecialAt",
        time + (missionNamespace getVariable ["KFH_extractionFinaleSpecialIntervalSeconds", 30]),
        true
    ];
    if (_spawned > 0) then {
        [format ["Extraction finale special wave deployed (%1 contact(s), %2 queued).", _spawned, count _queue]] call KFH_fnc_log;
    };
};

KFH_fnc_reportFlareLaunch = {
    params ["_unit", "_origin", "_weaponClass", "_ammoClass"];

    if (!isServer) exitWith {};
    if ((missionNamespace getVariable ["KFH_phase", "boot"]) isNotEqualTo "extract") exitWith {};
    if !(missionNamespace getVariable ["KFH_extractFlareRequired", true]) exitWith {};
    if (missionNamespace getVariable ["KFH_extractFlareFired", false]) exitWith {};
    if ((missionNamespace getVariable ["KFH_extractPrepUntil", -1]) > time) exitWith {
        [format ["Flare ignored: prep window still active for %1s.", round ((missionNamespace getVariable ["KFH_extractPrepUntil", time]) - time)]] call KFH_fnc_log;
    };
    if !([_weaponClass, _ammoClass] call KFH_fnc_isFlareShot) exitWith {};

    private _extractPos = getMarkerPos (missionNamespace getVariable ["KFH_extractMarker", "kfh_extract"]);
    if ((_origin distance2D _extractPos) > KFH_extractFlareRadius) exitWith {
        [format ["Flare ignored: not close enough to LZ (%1m).", round (_origin distance2D _extractPos)]] call KFH_fnc_log;
    };

    missionNamespace setVariable ["KFH_extractFlareFired", true, true];
    missionNamespace setVariable ["KFH_extractFlareFiredBy", name _unit, true];
    missionNamespace setVariable ["KFH_extractFlareWarnedAt", -1];
    ["flare_received_log", [], "EXTRACT"] call KFH_fnc_appendRunEventKey;
    ["flare_received_chat", [name _unit]] call KFH_fnc_notifyAllKey;
    private _heliDelay = missionNamespace getVariable ["KFH_extractionHeliCallDelaySeconds", 200];
    if (_heliDelay > 0) then {
        missionNamespace setVariable ["KFH_extractionHeliScheduledAt", time + _heliDelay, true];
        [format ["Angel One scheduled in %1 seconds.", round _heliDelay]] call KFH_fnc_log;
    } else {
        missionNamespace setVariable ["KFH_extractionHeliScheduledAt", -1, true];
        [] call KFH_fnc_spawnExtractionHeli;
    };
    [] call KFH_fnc_startExtractionFinaleRush;
    [] call KFH_fnc_spawnExtractWave;
};

KFH_fnc_fillRewardCache = {
    params ["_cache", "_checkpointIndex"];

    clearWeaponCargoGlobal _cache;
    clearMagazineCargoGlobal _cache;
    clearItemCargoGlobal _cache;
    clearBackpackCargoGlobal _cache;

    private _tier = [_checkpointIndex] call KFH_fnc_getCheckpointRewardTier;
    private _tierName = [_checkpointIndex] call KFH_fnc_getCheckpointRewardTierName;
    private _rewardPlayers = [] call KFH_fnc_getRewardPlayerCount;
    private _weaponCount = (ceil (_rewardPlayers * (missionNamespace getVariable ["KFH_rewardWeaponCoverageRatio", 0.75]))) max 2;
    private _backpackCount = (ceil (_rewardPlayers * (missionNamespace getVariable ["KFH_rewardBackpackCoverageRatio", 0.35]))) max 1;
    missionNamespace setVariable ["KFH_recentRewardWeaponBundles", [], true];

    switch (_tier) do {
        case 1: {
            private _vanillaBundles = [
                ["SMG_01_F", "30Rnd_45ACP_Mag_SMG_01", 8, ["optic_Aco_smg", "acc_flashlight"]],
                ["SMG_02_F", "30Rnd_9x21_Mag_SMG_02", 8, ["optic_ACO_grn_smg", "acc_flashlight"]],
                ["hgun_PDW2000_F", "30Rnd_9x21_Mag", 8, ["optic_ACO_grn_smg", "acc_flashlight"]]
            ];
            private _optionalBundles = (missionNamespace getVariable ["KFH_cupRewardWeaponBundlesTier1", []]) + ([1] call KFH_fnc_getDynamicRhsRewardBundles);

            [_cache, 1, _backpackCount] call KFH_fnc_addRewardBackpacks;
            [_cache, _vanillaBundles, _optionalBundles, _weaponCount] call KFH_fnc_addRewardWeaponBundlePool;
            [_cache, _rewardPlayers] call KFH_fnc_addRewardHelmets;
            _cache addItemCargoGlobal ["FirstAidKit", 3 + ceil (_rewardPlayers / 2)];
            [_cache, "SmokeShell", 2 + ceil (_rewardPlayers / 4)] call KFH_fnc_addOptionalMagazineCargo;
            if ((random 1) < 0.45) then {
                [_cache, "ToolKit", 1] call KFH_fnc_addOptionalItemCargo;
            };
            if ((random 1) < 0.35) then {
                [_cache, "NVGoggles", 1] call KFH_fnc_addOptionalItemCargo;
            };
            if ((random 1) < 0.25) then {
                [_cache] call KFH_fnc_addOptionalFlareKit;
            };
        };
        case 2: {
            private _vanillaBundles = [
                ["arifle_TRG21_F", "30Rnd_556x45_Stanag", 10, ["optic_Aco", "acc_flashlight"]],
                ["arifle_Mk20C_F", "30Rnd_556x45_Stanag", 10, ["optic_ACO_grn", "acc_pointer_IR"]],
                ["arifle_Katiba_C_F", "30Rnd_65x39_caseless_green", 8, ["optic_ACO_grn", "acc_pointer_IR"]],
                ["arifle_MX_GL_F", "30Rnd_65x39_caseless_mag", 8, ["optic_Holosight", "acc_pointer_IR"]]
            ];
            private _optionalBundles = (missionNamespace getVariable ["KFH_cupRewardWeaponBundlesTier2", []]) + ([2] call KFH_fnc_getDynamicRhsRewardBundles);

            [_cache, 2, _backpackCount] call KFH_fnc_addRewardBackpacks;
            [_cache, _vanillaBundles, _optionalBundles, _weaponCount] call KFH_fnc_addRewardWeaponBundlePool;
            [_cache, 2, ceil (_rewardPlayers / 3)] call KFH_fnc_addRewardVests;
            [_cache, _rewardPlayers] call KFH_fnc_addRewardHelmets;
            [_cache, "HandGrenade", 2 + floor (_rewardPlayers / 4)] call KFH_fnc_addOptionalMagazineCargo;
            [_cache, "MiniGrenade", 2 + floor (_rewardPlayers / 4)] call KFH_fnc_addOptionalMagazineCargo;
            _cache addItemCargoGlobal ["FirstAidKit", 4 + ceil (_rewardPlayers / 2)];
            [_cache, "ToolKit", 1] call KFH_fnc_addOptionalItemCargo;
            [_cache, 1 + floor (random 2), missionNamespace getVariable ["KFH_simpleLauncherBundles", []]] call KFH_fnc_addLauncherBundlesCargo;
            [_cache] call KFH_fnc_addOptionalFlareKit;
        };
        default {
            private _vanillaBundles = [
                ["LMG_Mk200_F", "200Rnd_65x39_cased_Box", 3, ["optic_Hamr", "acc_pointer_IR"]],
                ["arifle_MX_SW_F", "100Rnd_65x39_caseless_mag", 4, ["optic_Hamr", "acc_pointer_IR"]],
                ["arifle_Katiba_F", "30Rnd_65x39_caseless_green", 12, ["optic_Hamr", "acc_pointer_IR"]],
                ["srifle_EBR_F", "20Rnd_762x51_Mag", 10, ["optic_DMS", "bipod_01_F_blk"]],
                ["arifle_MX_GL_F", "30Rnd_65x39_caseless_mag", 10, ["optic_Hamr", "acc_pointer_IR"]]
            ];
            private _optionalBundles = (missionNamespace getVariable ["KFH_cupRewardWeaponBundlesTier3", []]) + ([3] call KFH_fnc_getDynamicRhsRewardBundles);

            [_cache, 3, _backpackCount] call KFH_fnc_addRewardBackpacks;
            [_cache, _vanillaBundles, _optionalBundles, _weaponCount] call KFH_fnc_addRewardWeaponBundlePool;
            [_cache, 3, ceil (_rewardPlayers / 3)] call KFH_fnc_addRewardVests;
            [_cache, _rewardPlayers] call KFH_fnc_addRewardHelmets;
            if ((random 1) < (missionNamespace getVariable ["KFH_rewardMedikitChanceTier3", 0.18])) then {
                [_cache, "Medikit", 1] call KFH_fnc_addOptionalItemCargo;
            };
            _cache addItemCargoGlobal ["FirstAidKit", 6 + ceil (_rewardPlayers / 2)];
            [_cache, 1 + floor (random 2), missionNamespace getVariable ["KFH_simpleLauncherBundles", []]] call KFH_fnc_addLauncherBundlesCargo;
            [_cache, "HandGrenade", 3 + floor (_rewardPlayers / 3)] call KFH_fnc_addOptionalMagazineCargo;
            [_cache, "MiniGrenade", 3 + floor (_rewardPlayers / 3)] call KFH_fnc_addOptionalMagazineCargo;
            [_cache, "ToolKit", 1] call KFH_fnc_addOptionalItemCargo;
            [_cache, "NVGoggles", 2] call KFH_fnc_addOptionalItemCargo;
            [_cache] call KFH_fnc_addOptionalFlareKit;
        };
    };

    [format ["Reward cache filled for checkpoint %1 (%2).", _checkpointIndex, _tierName]] call KFH_fnc_log;
};

KFH_fnc_fillRushSupplyBackpack = {
    params ["_container", ["_scale", 1]];

    if (isNull _container) exitWith {};

    private _bonus = ceil (_scale max 1);

    clearWeaponCargoGlobal _container;
    clearMagazineCargoGlobal _container;
    clearItemCargoGlobal _container;
    clearBackpackCargoGlobal _container;

    _container addItemCargoGlobal ["FirstAidKit", 3 + _bonus];
    _container addMagazineCargoGlobal ["16Rnd_9x21_Mag", 4 + _bonus];
    _container addMagazineCargoGlobal ["30Rnd_45ACP_Mag_SMG_01", 2 + _bonus];
    _container addMagazineCargoGlobal ["30Rnd_9x21_Mag_SMG_02", 2 + _bonus];
    _container addMagazineCargoGlobal ["30Rnd_556x45_Stanag", 1 + _bonus];
    _container addMagazineCargoGlobal ["30Rnd_65x39_caseless_mag", 1 + (floor (_bonus / 2))];
    [_container, "SmokeShell", 1] call KFH_fnc_addOptionalMagazineCargo;
    if ((random 1) < 0.25) then {
        [_container, "HandGrenade", 1] call KFH_fnc_addOptionalMagazineCargo;
    };
    if ((random 1) < 0.18) then {
        [_container, "ToolKit", 1] call KFH_fnc_addOptionalItemCargo;
    };
};

KFH_fnc_spawnRewardCache = {
    params ["_markerName", "_checkpointIndex"];

    private _cache = ["Box_NATO_WpsSpecial_F", _markerName, KFH_rewardCacheOffset, 180] call KFH_fnc_spawnSupportObject;
    _cache allowDamage false;
    _cache setVariable ["KFH_supportLabel", format ["Checkpoint %1 Loot Cache", _checkpointIndex], true];
    [_cache, _checkpointIndex] call KFH_fnc_fillRewardCache;
    [_cache] call KFH_fnc_appendSupportObject;

    _cache
};

KFH_fnc_spawnBranchRewardCache = {
    params ["_checkpointIndex"];

    if !(missionNamespace getVariable ["KFH_branchRewardEnabled", true]) exitWith { objNull };

    private _markerName = format ["kfh_branch_reward_%1", _checkpointIndex];
    if !(_markerName in allMapMarkers) exitWith { objNull };

    private _spawnedKey = format ["KFH_branchRewardSpawned_%1", _checkpointIndex];
    if (missionNamespace getVariable [_spawnedKey, false]) exitWith { objNull };
    missionNamespace setVariable [_spawnedKey, true, true];

    _markerName setMarkerAlpha (missionNamespace getVariable ["KFH_branchRewardMarkerAlpha", 0.85]);

    private _cacheClass = missionNamespace getVariable ["KFH_branchRewardCacheClass", "Box_NATO_WpsSpecial_F"];
    private _cache = [_cacheClass, _markerName, [0, 0, 0], 180] call KFH_fnc_spawnSupportObject;
    _cache allowDamage false;
    _cache setVariable ["KFH_supportType", "branch_reward", true];
    _cache setVariable ["KFH_supportLabel", format ["Checkpoint %1 Side Cache", _checkpointIndex], true];
    clearWeaponCargoGlobal _cache;
    clearMagazineCargoGlobal _cache;
    clearItemCargoGlobal _cache;
    clearBackpackCargoGlobal _cache;
    [_cache, _checkpointIndex + 1] call KFH_fnc_fillRewardCache;
    [_cache, _checkpointIndex] call KFH_fnc_addSideCacheATCargo;
    [_cache] call KFH_fnc_appendSupportObject;

    [format ["Optional side cache marked near checkpoint %1. Detour if the team can afford it.", _checkpointIndex]] call KFH_fnc_notifyAll;
    [format ["Checkpoint %1 side cache revealed at %2.", _checkpointIndex, mapGridPosition (getMarkerPos _markerName)], "LOOT"] call KFH_fnc_appendRunEvent;
    [_markerName, _checkpointIndex] spawn KFH_fnc_watchBranchRewardPressure;
    [_markerName, _checkpointIndex] call KFH_fnc_spawnBranchRewardSpecials;

    _cache
};

KFH_fnc_spawnBranchRewardSpecials = {
    params ["_markerName", "_checkpointIndex"];

    if !(missionNamespace getVariable ["KFH_branchRewardScreamerEnabled", true]) exitWith { [] };
    if !(_markerName in allMapMarkers) exitWith { [] };

    private _cachePos = getMarkerPos _markerName;
    private _spawned = [];
    private _screamerClass = [
        missionNamespace getVariable ["KFH_branchRewardScreamerClassCandidates", []],
        missionNamespace getVariable ["KFH_branchRewardScreamerClass", ""]
    ] call KFH_fnc_selectExistingClass;
    private _screamer = [
        _cachePos,
        _screamerClass,
        "screamer",
        missionNamespace getVariable ["KFH_branchRewardScreamerDistanceMin", 42],
        missionNamespace getVariable ["KFH_branchRewardScreamerDistanceMax", 72],
        _cachePos,
        true,
        true,
        false
    ] call KFH_fnc_spawnSpecialInfected;

    if !(isNull _screamer) then {
        _spawned pushBack _screamer;
    };

    private _guardCount = missionNamespace getVariable ["KFH_branchRewardGuardCount", 2];
    if (_guardCount > 0) then {
        private _guards = [
            _cachePos,
            [],
            _guardCount,
            0,
            0,
            0
        ] call KFH_fnc_spawnGroupWave;

        private _activeEnemies = missionNamespace getVariable ["KFH_activeEnemies", []];
        _activeEnemies append _guards;
        missionNamespace setVariable ["KFH_activeEnemies", _activeEnemies];
        ["KFH_totalHostiles", count _activeEnemies] call KFH_fnc_setState;
        _spawned append _guards;
    };

    if ((count _spawned) > 0) then {
        [format [
            "Side cache %1 guarded by special infected (%2 spawned) at %3.",
            _checkpointIndex,
            count _spawned,
            mapGridPosition _cachePos
        ]] call KFH_fnc_log;
    };

    _spawned
};

KFH_fnc_watchBranchRewardPressure = {
    params ["_markerName", "_checkpointIndex"];

    private _radius = missionNamespace getVariable ["KFH_branchRewardNoiseRadius", 38];
    waitUntil {
        sleep 1.5;
        ((missionNamespace getVariable ["KFH_phase", "boot"]) in ["complete", "failed"]) ||
        {
            (([] call KFH_fnc_getHumanPlayers) findIf {
                alive _x && {(_x distance2D (getMarkerPos _markerName)) <= _radius}
            }) >= 0
        }
    };

    if ((missionNamespace getVariable ["KFH_phase", "boot"]) in ["complete", "failed"]) exitWith {};

    private _pressureCost = missionNamespace getVariable ["KFH_branchRewardPressureCost", 7];
    private _pressure = missionNamespace getVariable ["KFH_pressure", 0];
    ["KFH_pressure", (_pressure + _pressureCost) min KFH_pressureMax] call KFH_fnc_setState;
    [format ["Side cache noise raised pressure by %1 near checkpoint %2.", _pressureCost, _checkpointIndex], "PRESSURE"] call KFH_fnc_appendRunEvent;
    [format ["HQ: Side cache contact near checkpoint %1. Good loot, but the noise is drawing infected.", _checkpointIndex]] call KFH_fnc_notifyAll;
};

KFH_fnc_spawnFinalFlareCache = {
    params ["_markerName"];

    private _cache = ["Box_NATO_Ammo_F", _markerName, KFH_finalFlareCacheOffset, 180] call KFH_fnc_spawnSupportObject;
    _cache allowDamage false;
    _cache setVariable ["KFH_supportLabel", "Emergency Flare Cache", true];
    clearWeaponCargoGlobal _cache;
    clearMagazineCargoGlobal _cache;
    clearItemCargoGlobal _cache;
    clearBackpackCargoGlobal _cache;
    [_cache] call KFH_fnc_addOptionalFlareKit;
    _cache addItemCargoGlobal ["FirstAidKit", 2];
    [_cache] call KFH_fnc_appendSupportObject;
    ["Emergency flare cache deployed. Someone must carry flare capability before moving to the LZ.", "EXTRACT"] call KFH_fnc_appendRunEvent;
    ["HQ: Emergency flare cache marked. Assign one survivor to carry the flare gun before moving to the LZ."] call KFH_fnc_notifyAll;

    _cache
};

KFH_fnc_spawnFinalBaseComposition = {
    params ["_markerName"];

    private _stateKey = format ["KFH_finalBaseComposition_%1", _markerName];
    private _existing = missionNamespace getVariable [_stateKey, []];
    if ((count _existing) > 0) exitWith { _existing };

    private _spawned = [_markerName, KFH_finalBaseCompositionOffsets] call KFH_fnc_spawnOutbreakDressingSet;
    {
        _x setVariable ["KFH_supportLabel", "Ruined Forward Armory", true];
    } forEach _spawned;

    missionNamespace setVariable [_stateKey, _spawned];
    _spawned
};

KFH_fnc_fillFinalBaseSupply = {
    params ["_crate", "_role"];

    if (isNull _crate) exitWith {};

    clearWeaponCargoGlobal _crate;
    clearMagazineCargoGlobal _crate;
    clearItemCargoGlobal _crate;
    clearBackpackCargoGlobal _crate;

    switch (_role) do {
        case "launchers": {
            [_crate, 2, missionNamespace getVariable ["KFH_sideCacheAtLauncherBundles", []]] call KFH_fnc_addLauncherBundlesCargo;
            [_crate, "HandGrenade", 4] call KFH_fnc_addOptionalMagazineCargo;
            [_crate, "MiniGrenade", 2] call KFH_fnc_addOptionalMagazineCargo;
            _crate setVariable ["KFH_supportLabel", "Fallback Launcher Crate", true];
        };
        case "equipment": {
            _crate addItemCargoGlobal ["ToolKit", 1];
            _crate addItemCargoGlobal ["NVGoggles", 2];
            _crate addItemCargoGlobal ["FirstAidKit", 10];
            if ((random 1) < (missionNamespace getVariable ["KFH_rewardMedikitChanceTier3", 0.18])) then {
                _crate addItemCargoGlobal ["Medikit", 1];
            };
            _crate addBackpackCargoGlobal ["B_Carryall_mcamo", 1];
            _crate addBackpackCargoGlobal ["B_Kitbag_rgr", 1];
            _crate setVariable ["KFH_supportLabel", "Recovery Equipment Locker", true];
        };
        default {
            [_crate, "200Rnd_65x39_cased_Box", 2] call KFH_fnc_addOptionalMagazineCargo;
            _crate addMagazineCargoGlobal ["30Rnd_65x39_caseless_green", 8];
            _crate addMagazineCargoGlobal ["30Rnd_556x45_Stanag", 8];
            [_crate, "SmokeShell", 4] call KFH_fnc_addOptionalMagazineCargo;
            [_crate, "Chemlight_green", 6] call KFH_fnc_addOptionalMagazineCargo;
            _crate setVariable ["KFH_supportLabel", "Emergency Ammo Reserve", true];
        };
    };
};

KFH_fnc_spawnOptionalBaseVehicles = {
    params ["_markerName"];

    private _count = missionNamespace getVariable ["KFH_optionalBaseVehicleCount", 3];
    if (_count <= 0) exitWith { [] };

    private _offsets = missionNamespace getVariable ["KFH_optionalBaseVehicleOffsets", []];
    private _fuelMin = missionNamespace getVariable ["KFH_optionalBaseVehicleFuelMin", 0.22];
    private _fuelMax = missionNamespace getVariable ["KFH_optionalBaseVehicleFuelMax", 0.45];
    private _invulnerableUntilEntered = missionNamespace getVariable ["KFH_optionalBaseVehicleInvulnerableUntilEntered", true];
    private _spawned = [];

    for "_i" from 0 to ((_count - 1) max 0) do {
        private _className = [
            missionNamespace getVariable ["KFH_optionalBaseVehicleClasses", []],
            missionNamespace getVariable ["KFH_cupOptionalBaseVehicleClasses", []],
            missionNamespace getVariable ["KFH_cupVehiclePreferredChance", 0.9]
        ] call KFH_fnc_selectExistingWithOptionalPriority;

        if !(_className isEqualTo "") then {
            private _offset = if (_i < (count _offsets)) then {
                _offsets select _i
            } else {
                [120 + (_i * 28), -90 + (_i * 80), 0, random 70]
            };
            _offset params [["_rightOffset", 0], ["_forwardOffset", 0], ["_heightOffset", 0], ["_dirOffset", 0]];
            private _vehicle = [_className, _markerName, [_rightOffset, _forwardOffset, _heightOffset], _dirOffset, 0, true] call KFH_fnc_spawnOutbreakObject;
            if !(isNull _vehicle) then {
                _vehicle setFuel (_fuelMin + random ((_fuelMax - _fuelMin) max 0.01));
                _vehicle setDamage 0;
                _vehicle lock 0;
                _vehicle setVariable ["KFH_supportLabel", "Ruined Base Armor Reserve", true];
                _vehicle setVariable ["KFH_optionalBaseVehicle", true, true];
                if (_invulnerableUntilEntered) then {
                    _vehicle allowDamage false;
                    _vehicle addEventHandler ["GetIn", {
                        params ["_vehicle"];
                        _vehicle allowDamage true;
                        _vehicle removeEventHandler ["GetIn", _thisEventHandler];
                    }];
                };
                _spawned pushBack _vehicle;
            };
        };
    };

    [format ["Ruined arsenal base vehicles spawned: %1.", count _spawned]] call KFH_fnc_log;
    _spawned
};

KFH_fnc_findOptionalBasePosition = {
    params ["_checkpointMarker"];

    private _offsets = [
        [KFH_optionalBaseForwardOffset, KFH_optionalBaseOffsetDistance, 0],
        [KFH_optionalBaseForwardOffset, -KFH_optionalBaseOffsetDistance, 0],
        [KFH_optionalBaseForwardOffset * 1.7, KFH_optionalBaseOffsetDistance * 0.7, 0],
        [KFH_optionalBaseForwardOffset * 1.7, -KFH_optionalBaseOffsetDistance * 0.7, 0]
    ];

    private _best = [];
    {
        private _candidate = [_checkpointMarker, _x] call KFH_fnc_worldFromMarkerOffset;
        if (!isNil "KFH_fnc_dynamicRouteFindLandRoadPos") then {
            private _roadPos = [_candidate] call KFH_fnc_dynamicRouteFindLandRoadPos;
            if ((count _roadPos) > 0) then {
                _candidate = _roadPos;
            };
        };

        private _safe = !(_candidate isEqualTo []) &&
            {!surfaceIsWater _candidate} &&
            {[_candidate, objNull] call KFH_fnc_isSpawnCandidateOpen};

        if (_safe && {(count _best) isEqualTo 0}) then {
            _best = +_candidate;
        };
    } forEach _offsets;

    if ((count _best) > 0) exitWith { _best };

    getMarkerPos _checkpointMarker
};

KFH_fnc_prepareOptionalBaseMarker = {
    params ["_checkpointMarker"];

    private _markerName = missionNamespace getVariable ["KFH_optionalBaseActiveMarker", KFH_optionalBaseMarker];
    private _basePos = [_checkpointMarker] call KFH_fnc_findOptionalBasePosition;

    if (_markerName in allMapMarkers) then {
        deleteMarker _markerName;
    };

    private _marker = createMarker [_markerName, _basePos];
    _marker setMarkerType "mil_objective";
    _marker setMarkerColor "ColorOrange";
    _marker setMarkerText "Ruined Arsenal Base";
    _marker setMarkerAlpha 1;
    _marker setMarkerDir (markerDir _checkpointMarker);

    missionNamespace setVariable ["KFH_optionalBaseActiveMarker", _markerName, true];
    missionNamespace setVariable ["KFH_optionalBasePos", _basePos, true];

    _markerName
};

KFH_fnc_spawnOptionalBaseDefenders = {
    params ["_markerName"];

    if !(KFH_optionalBaseEnabled) exitWith { [] };
    if (missionNamespace getVariable ["KFH_optionalBaseDefendersSpawned", false]) exitWith { [] };

    private _basePos = getMarkerPos _markerName;
    private _bossClass = [
        missionNamespace getVariable ["KFH_optionalBaseSpecialClassCandidates", []],
        missionNamespace getVariable ["KFH_optionalBaseSpecialClass", "WBK_Goliaph_1"]
    ] call KFH_fnc_selectExistingClass;
    private _goliath = [
        _basePos,
        _bossClass,
        "goliath",
        missionNamespace getVariable ["KFH_optionalBaseSpecialMinDistance", 34],
        missionNamespace getVariable ["KFH_optionalBaseSpecialMaxDistance", 70],
        _basePos
    ] call KFH_fnc_spawnSpecialInfected;
    private _unitCount = [KFH_optionalBaseThreatBaseCount] call KFH_fnc_scaledEnemyCount;

    if !(isNull _goliath) then {
        _unitCount = (
            _unitCount - (missionNamespace getVariable ["KFH_optionalBaseJuggernautHordeReduction", 3])
        ) max (missionNamespace getVariable ["KFH_optionalBaseMinDefenders", 2]);
    };

    _unitCount = [
        _unitCount,
        if (isNull _goliath) then { missionNamespace getVariable ["KFH_optionalBaseSpecialReserveSlots", 1] } else { 0 }
    ] call KFH_fnc_limitSpawnCountByActiveBudget;

    private _spawnedUnits = [
        _basePos,
        [],
        _unitCount,
        KFH_optionalBaseGunnerChance,
        KFH_optionalBaseSupplyCarrierChance,
        KFH_optionalBaseHeavyChance
    ] call KFH_fnc_spawnGroupWave;

    if (isNull _goliath && {(count _spawnedUnits) > 0}) then {
        private _juggernaut = selectRandom _spawnedUnits;
        [_juggernaut] call KFH_fnc_configureJuggernautInfected;
    };

    private _activeEnemies = missionNamespace getVariable ["KFH_activeEnemies", []];
    _activeEnemies append _spawnedUnits;
    missionNamespace setVariable ["KFH_activeEnemies", _activeEnemies];
    ["KFH_totalHostiles", count _activeEnemies] call KFH_fnc_setState;
    missionNamespace setVariable ["KFH_optionalBaseDefendersSpawned", true, true];

    [format [
        "Ruined arsenal base defenders spawned at %1 (%2 escorts, special=%3).",
        mapGridPosition _basePos,
        count _spawnedUnits,
        if (isNull _goliath) then { "fallback" } else { typeOf _goliath }
    ]] call KFH_fnc_log;
    _spawnedUnits
};

KFH_fnc_spawnOptionalArsenalBase = {
    params ["_checkpointMarker"];

    if !(KFH_optionalBaseEnabled) exitWith {
        [_checkpointMarker] call KFH_fnc_spawnFinalArsenal;
        [_checkpointMarker] call KFH_fnc_spawnFinalFlareCache;
        _checkpointMarker
    };

    if (missionNamespace getVariable ["KFH_optionalBaseSpawned", false]) exitWith {
        missionNamespace getVariable ["KFH_optionalBaseActiveMarker", _checkpointMarker]
    };

    private _baseMarker = [_checkpointMarker] call KFH_fnc_prepareOptionalBaseMarker;
    [_baseMarker] call KFH_fnc_spawnFinalArsenal;
    [_baseMarker] call KFH_fnc_spawnFinalFlareCache;
    [_baseMarker] call KFH_fnc_spawnOptionalBaseVehicles;
    [_baseMarker] call KFH_fnc_spawnOptionalBaseDefenders;
    missionNamespace setVariable ["KFH_optionalBaseSpawned", true, true];
    [] call KFH_fnc_updateRouteMarkerVisibility;

    ["HQ: Arsenal signal found off the safe route. The base is overrun by a juggernaut; detour only if the team can afford it.", "STORY"] call KFH_fnc_appendRunEvent;
    ["HQ: Arsenal is off-route at a ruined base. Expect a juggernaut. You can skip it and push extraction if battered."] call KFH_fnc_notifyAll;

    _baseMarker
};

KFH_fnc_spawnFinalArsenal = {
    params ["_markerName"];

    [_markerName] call KFH_fnc_spawnFinalBaseComposition;

    private _arsenal = ["B_supplyCrate_F", _markerName, KFH_finalArsenalOffset, 180] call KFH_fnc_spawnSupportObject;
    _arsenal allowDamage false;
    _arsenal setVariable ["KFH_supportLabel", "Final Arsenal", true];
    [_arsenal] call KFH_fnc_setupSafeAllArsenal;
    [_arsenal] call KFH_fnc_appendSupportObject;

    {
        _x params ["_className", "_offset", ["_dirOffset", 0]];
        private _crate = [_className, _markerName, _offset, _dirOffset] call KFH_fnc_spawnSupportObject;
        _crate allowDamage false;
        [_crate, ["launchers", "ammo", "equipment"] select _forEachIndex] call KFH_fnc_fillFinalBaseSupply;
        [_crate] call KFH_fnc_appendSupportObject;
    } forEach KFH_finalBaseSupplyOffsets;

    _arsenal
};

KFH_fnc_promoteObjectiveCarrier = {
    params ["_spawnedUnits", "_checkpointIndex"];

    if ((count _spawnedUnits) isEqualTo 0) exitWith {};

    private _elite = selectRandom _spawnedUnits;

    removeAllWeapons _elite;
    removeAllItems _elite;
    removeAllAssignedItems _elite;
    removeBackpack _elite;

    switch ([_checkpointIndex] call KFH_fnc_getCheckpointRewardTier) do {
        case 1: {
            _elite addBackpack "B_AssaultPack_ocamo";
            [_elite, "SMG_01_F", "30Rnd_45ACP_Mag_SMG_01", ["optic_Aco_smg", "acc_flashlight"], 4] call KFH_fnc_givePrimaryWeaponLoadout;
        };
        case 2: {
            _elite addBackpack "B_Kitbag_cbr";
            [_elite, "arifle_Katiba_C_F", "30Rnd_65x39_caseless_green", ["optic_ACO_grn", "acc_pointer_IR"], 5] call KFH_fnc_givePrimaryWeaponLoadout;
        };
        default {
            _elite addBackpack "B_Carryall_ocamo";
            [_elite, "LMG_Zafir_F", "150Rnd_762x54_Box", ["optic_Hamr", "acc_pointer_IR"], 2] call KFH_fnc_givePrimaryWeaponLoadout;
        };
    };

    _elite setSkill 0.6;
    _elite setVariable ["KFH_rewardCarrier", true, true];
    _elite setVariable ["KFH_enemyRole", "ranged", true];
    (group _elite) setFormation "WEDGE";
    (group _elite) setBehaviour "AWARE";
    (group _elite) setCombatMode "RED";
    (group _elite) setSpeedMode "FULL";
    {
        _elite enableAI _x;
    } forEach ["AUTOCOMBAT", "COVER", "SUPPRESSION", "TARGET", "AUTOTARGET"];
    _elite setUnitPos "AUTO";
    _elite forceSpeed -1;
    _elite setBehaviourStrong "AWARE";
    _elite setCombatMode "RED";
    _elite setSpeedMode "FULL";
    [format [
        "Checkpoint %1 signal carrier spawned. Body carries %2 gear.",
        _checkpointIndex,
        [_checkpointIndex] call KFH_fnc_getCheckpointRewardTierName
    ]] call KFH_fnc_log;
};

KFH_fnc_spawnSpecialCarrierEncounter = {
    params ["_checkpointIndex", "_checkpointMarker"];

    private _spawnMarkers = [format ["kfh_spawn_%1", _checkpointIndex]] call KFH_fnc_getSpawnMarkers;
    private _spawnedUnits = [getMarkerPos _checkpointMarker, _spawnMarkers, 2] call KFH_fnc_spawnGroupWave;
    private _activeEnemies = missionNamespace getVariable ["KFH_activeEnemies", []];
    private _objectiveEnemies = missionNamespace getVariable ["KFH_currentObjectiveEnemies", []];

    _activeEnemies append _spawnedUnits;
    _objectiveEnemies append _spawnedUnits;
    missionNamespace setVariable ["KFH_activeEnemies", _activeEnemies];
    missionNamespace setVariable ["KFH_currentObjectiveEnemies", _objectiveEnemies];
    [_spawnedUnits, _checkpointIndex] call KFH_fnc_promoteObjectiveCarrier;
    ["KFH_totalHostiles", count _activeEnemies] call KFH_fnc_setState;
    ["KFH_objectiveHostiles", count _objectiveEnemies] call KFH_fnc_setState;
    [format ["Checkpoint %1 event: Signal Hunt added a bonus carrier team.", _checkpointIndex]] call KFH_fnc_notifyAll;
};

KFH_fnc_configureRangedEnemy = {
    params ["_unit"];

    if (isNull _unit) exitWith {};

    removeAllWeapons _unit;
    removeAllItems _unit;
    removeAllAssignedItems _unit;
    removeHeadgear _unit;
    removeGoggles _unit;
    removeVest _unit;

    private _entry = [] call KFH_fnc_selectRangedEnemyLoadout;
    if ((count _entry) < 2) exitWith {};
    private _weapon = _entry select 0;
    private _mag = _entry select 1;
    private _attachments = if ((count _entry) > 2) then { _entry select 2 } else { [] };
    private _extraMags = if ((count _entry) > 3) then { _entry select 3 } else { 2 };

    _unit addVest "V_BandollierB_khk";
    [_unit, _weapon, _mag, _attachments, _extraMags] call KFH_fnc_givePrimaryWeaponLoadout;
    _unit setSkill (0.38 + random 0.18);
    [_unit] call KFH_fnc_applyEnemyFireAccuracy;
    _unit setVariable ["KFH_enemyRole", "ranged", true];
    _unit setVariable ["KFH_rushGunner", true, true];
    _unit enableFatigue false;
    _unit allowFleeing 0;
    _unit setAnimSpeedCoef 1;
    {
        _unit enableAI _x;
    } forEach ["AUTOCOMBAT", "COVER", "SUPPRESSION", "TARGET", "AUTOTARGET"];
    _unit setBehaviourStrong "AWARE";
    _unit setCombatMode "RED";
    _unit setSpeedMode "FULL";
    _unit setUnitPos "AUTO";
    _unit forceWalk false;
    _unit stop false;
    (group _unit) setFormation "WEDGE";
    (group _unit) setBehaviour "AWARE";
    (group _unit) setCombatMode "RED";
    (group _unit) setSpeedMode "FULL";
};

KFH_fnc_configureAgentEnemy = {
    params ["_unit"];

    if (isNull _unit) exitWith {};

    removeAllWeapons _unit;
    removeAllItems _unit;
    removeAllAssignedItems _unit;
    removeUniform _unit;
    removeVest _unit;
    removeHeadgear _unit;
    removeGoggles _unit;

    private _entry = [] call KFH_fnc_selectRangedEnemyLoadout;
    if ((count _entry) < 2) exitWith {};
    private _weapon = _entry select 0;
    private _mag = _entry select 1;
    private _attachments = if ((count _entry) > 2) then { _entry select 2 } else { [] };
    private _extraMags = if ((count _entry) > 3) then { _entry select 3 } else { 2 };

    _unit forceAddUniform (selectRandom KFH_agentUniforms);
    _unit addVest "V_TacVest_blk";
    _unit addHeadgear (selectRandom KFH_agentHeadgear);
    _unit addGoggles "G_Balaclava_blk";
    [_unit, _weapon, _mag, _attachments, _extraMags] call KFH_fnc_givePrimaryWeaponLoadout;
    _unit setVariable ["KFH_enemyRole", "agent", true];
    _unit setVariable ["KFH_agentEnemy", true, true];
    _unit setSkill (0.46 + random 0.16);
    [_unit] call KFH_fnc_applyEnemyFireAccuracy;
    _unit enableFatigue false;
    _unit allowFleeing 0;
    {
        _unit enableAI _x;
    } forEach ["AUTOCOMBAT", "COVER", "SUPPRESSION", "TARGET", "AUTOTARGET"];
    _unit setBehaviourStrong "AWARE";
    _unit setCombatMode "RED";
    _unit setSpeedMode "FULL";
    _unit setUnitPos "AUTO";
    _unit forceWalk false;
    _unit stop false;
    (group _unit) setFormation "WEDGE";
    (group _unit) setBehaviour "AWARE";
    (group _unit) setCombatMode "RED";
    (group _unit) setSpeedMode "FULL";
    [_unit, KFH_agentLootTable, "agent"] call KFH_fnc_addUnitLootTable;
};

KFH_fnc_configureHeavyInfected = {
    params ["_unit", ["_allowExternalZombie", true]];

    if (isNull _unit) exitWith {};

    [_unit, _allowExternalZombie] call KFH_fnc_configureMeleeEnemy;
    removeUniform _unit;
    removeVest _unit;
    removeHeadgear _unit;
    removeBackpack _unit;
    _unit forceAddUniform (selectRandom KFH_heavyInfectedUniforms);
    _unit addVest (selectRandom KFH_heavyInfectedVests);
    _unit addHeadgear (selectRandom KFH_heavyInfectedHeadgear);
    _unit addBackpack (selectRandom KFH_heavyInfectedBackpacks);
    _unit setVariable ["KFH_enemyRole", "heavyInfected", true];
    _unit setVariable ["KFH_heavyInfected", true, true];
    _unit setAnimSpeedCoef KFH_heavyInfectedAnimSpeed;
    [_unit, KFH_heavyInfectedLootTable, "heavyInfected"] call KFH_fnc_addUnitLootTable;
    if !(_unit getVariable ["KFH_heavyDamageHandlerInstalled", false]) then {
        _unit setVariable ["KFH_heavyDamageHandlerInstalled", true];
        _unit addEventHandler ["HandleDamage", {
            params ["_unit", "_selection", "_incomingDamage", "_source"];

            if !(_unit getVariable ["KFH_heavyInfected", false]) exitWith { _incomingDamage };
            private _scale = _unit getVariable ["KFH_heavyInfectedDamageScale", KFH_heavyInfectedDamageScale];
            _incomingDamage * _scale
        }];
    };
};

KFH_fnc_configureLeaperProxyInfected = {
    params ["_unit"];

    if (isNull _unit) exitWith {};

    [_unit, false] call KFH_fnc_configureHeavyInfected;
    _unit setVariable ["KFH_enemyRole", "leaper", true];
    _unit setVariable ["KFH_leaperProxy", true, true];
    _unit setAnimSpeedCoef (missionNamespace getVariable ["KFH_leaperProxyAnimSpeed", 1.12]);
    _unit setSkill 0.7;
    _unit allowFleeing 0;
    {
        _unit disableAI _x;
    } forEach ["AUTOCOMBAT", "COVER", "SUPPRESSION", "FSM"];
    {
        _unit enableAI _x;
    } forEach ["MOVE", "PATH", "TARGET", "AUTOTARGET"];
    _unit setBehaviourStrong "AWARE";
    _unit setCombatMode "RED";
    _unit setSpeedMode "FULL";
    _unit setUnitPos "UP";
    _unit forceWalk false;
    (group _unit) allowFleeing 0;
    (group _unit) setBehaviour "AWARE";
    (group _unit) setCombatMode "RED";
    (group _unit) setSpeedMode "FULL";
    [format ["Leaper proxy configured with KFH heavy melee AI at %1.", mapGridPosition _unit]] call KFH_fnc_log;
};

KFH_fnc_configureJuggernautInfected = {
    params ["_unit"];

    if (isNull _unit) exitWith {};

    [_unit] call KFH_fnc_configureHeavyInfected;
    _unit setVariable ["KFH_juggernaut", true, true];
    _unit setVariable ["KFH_heavyInfectedDamageScale", KFH_juggernautDamageScale, true];
    _unit setAnimSpeedCoef KFH_juggernautAnimSpeed;
    _unit setSkill 0.75;
    _unit allowFleeing 0;
    [_unit, KFH_heavyInfectedLootTable + [["RPG32_F", 0, 1, 0.35], ["NLAW_F", 0, 1, 0.25]], "juggernaut"] call KFH_fnc_addUnitLootTable;
    [format ["Juggernaut infected configured at %1.", mapGridPosition _unit]] call KFH_fnc_log;
};

KFH_fnc_selectExistingClass = {
    params [["_classes", []], ["_fallbackClass", ""]];

    private _pool = _classes select { isClass (configFile >> "CfgVehicles" >> _x) };
    if ((count _pool) > 0) exitWith { selectRandom _pool };
    _fallbackClass
};

KFH_fnc_findRelaxedSpecialSpawnPosition = {
    params ["_centerPos", ["_minDistance", 28], ["_maxDistance", 70]];

    private _attempts = 18;
    private _found = [];
    for "_i" from 1 to _attempts do {
        private _angle = random 360;
        private _dist = _minDistance + random ((_maxDistance - _minDistance) max 1);
        private _pos = [
            (_centerPos select 0) + (sin _angle) * _dist,
            (_centerPos select 1) + (cos _angle) * _dist,
            0
        ];
        if !(surfaceIsWater _pos) then {
            private _empty = _pos findEmptyPosition [0, 12, "C_man_1"];
            if !(_empty isEqualTo []) then {
                if (count (_empty isFlatEmpty [0.6, -1, 0.35, 2, 0, false, objNull]) > 0) exitWith {
                    _found = _empty;
                };
            };
        };
    };

    _found
};

KFH_fnc_selectCheckpointSpecialRole = {
    private _entries = missionNamespace getVariable ["KFH_checkpointSpecialRoles", []];
    [_entries] call KFH_fnc_selectSpecialRoleFromEntries
};

KFH_fnc_isKnownBrokenSpecialClass = {
    params [["_className", ""]];

    !(_className isEqualTo "") &&
    {_className in (missionNamespace getVariable ["KFH_knownBrokenSpecialClasses", []])}
};

KFH_fnc_selectSpecialRoleFromEntries = {
    params [["_entries", []]];

    if ((count _entries) isEqualTo 0) exitWith { ["screamer", missionNamespace getVariable ["KFH_branchRewardScreamerClass", ""]] };

    private _weighted = [];
    {
        _x params ["_role", ["_classes", []], ["_weight", 1]];
        private _filteredClasses = if (_role isEqualTo "leaper" && {missionNamespace getVariable ["KFH_leaperProxyEnabled", true]}) then {
            [""]
        } else {
            _classes select { !([_x] call KFH_fnc_isKnownBrokenSpecialClass) }
        };
        private _allowFallbackClass = (_filteredClasses findIf { _x isEqualTo "" }) >= 0;
        private _className = [_filteredClasses, if ((count _filteredClasses) > 0) then { _filteredClasses select 0 } else { "" }] call KFH_fnc_selectExistingClass;
        if (_allowFallbackClass && {_className isEqualTo ""}) then {
            _className = "";
        };
        if (_allowFallbackClass || {!(_className isEqualTo "")}) then {
            for "_i" from 1 to (_weight max 1) do {
                _weighted pushBack [_role, _className];
            };
        };
    } forEach _entries;

    if ((count _weighted) isEqualTo 0) exitWith {
        private _bloaterClass = [["Zombie_Special_OPFOR_Boomer"], ""] call KFH_fnc_selectExistingClass;
        if !(_bloaterClass isEqualTo "") exitWith { ["bloater", _bloaterClass] };
        ["screamer", missionNamespace getVariable ["KFH_branchRewardScreamerClass", ""]]
    };
    selectRandom _weighted
};

KFH_fnc_configureSpecialJuggernautInfected = {
    params ["_unit"];

    if (isNull _unit) exitWith {};
    _unit setVariable ["KFH_juggernaut", true, true];
    _unit setVariable ["KFH_heavyInfected", true, true];
    _unit setVariable ["KFH_heavyInfectedDamageScale", KFH_juggernautDamageScale, true];
    _unit setAnimSpeedCoef KFH_juggernautAnimSpeed;
    _unit setSkill 0.75;
    _unit allowFleeing 0;
    if !(_unit getVariable ["KFH_heavyDamageHandlerInstalled", false]) then {
        _unit setVariable ["KFH_heavyDamageHandlerInstalled", true];
        _unit addEventHandler ["HandleDamage", {
            params ["_unit", "_selection", "_incomingDamage", "_source"];

            if !(_unit getVariable ["KFH_heavyInfected", false]) exitWith { _incomingDamage };
            private _scale = _unit getVariable ["KFH_heavyInfectedDamageScale", KFH_heavyInfectedDamageScale];
            _incomingDamage * _scale
        }];
    };
    [format ["Special juggernaut infected configured at %1.", mapGridPosition _unit]] call KFH_fnc_log;
};

KFH_fnc_isJuggernautEnemy = {
    params ["_unit"];

    if (isNull _unit) exitWith { false };
    (_unit getVariable ["KFH_juggernaut", false]) ||
    {(_unit getVariable ["KFH_enemyRole", ""]) in ["goliath", "smasher"]}
};

KFH_fnc_leaveBehindJuggernaut = {
    params ["_unit", ["_reason", "left behind"]];

    if (isNull _unit || {!alive _unit}) exitWith {};
    if (_unit getVariable ["KFH_juggernautLeftBehind", false]) exitWith {};

    _unit setVariable ["KFH_juggernautLeftBehind", true, true];
    _unit setVariable ["KFH_staleSince", -1];
    _unit setVariable ["KFH_staleRemoved", true, true];

    private _objectiveEnemies = missionNamespace getVariable ["KFH_currentObjectiveEnemies", []];
    _objectiveEnemies = _objectiveEnemies - [_unit];
    missionNamespace setVariable ["KFH_currentObjectiveEnemies", _objectiveEnemies];

    private _activeEnemies = missionNamespace getVariable ["KFH_activeEnemies", []];
    _activeEnemies = _activeEnemies - [_unit];
    missionNamespace setVariable ["KFH_activeEnemies", _activeEnemies];

    ["KFH_objectiveHostiles", count _objectiveEnemies] call KFH_fnc_setState;
    ["KFH_totalHostiles", count _activeEnemies] call KFH_fnc_setState;
    [format ["Juggernaut left behind without relocation: %1 at %2 (%3).", typeOf _unit, mapGridPosition _unit, _reason]] call KFH_fnc_log;
};

KFH_fnc_spawnSpecialInfected = {
    params [
        "_centerPos",
        "_className",
        ["_role", "special"],
        ["_minDistance", 28],
        ["_maxDistance", 70],
        ["_moveTarget", []],
        ["_ignoreActiveBudget", false],
        ["_relaxedSpawn", false],
        ["_addToObjective", false]
    ];

    if (!_ignoreActiveBudget && {([1] call KFH_fnc_limitSpawnCountByActiveBudget) <= 0}) exitWith { objNull };

    private _enemyClasses = missionNamespace getVariable ["KFH_enemyClasses", KFH_enemyClasses];
    if ((count _enemyClasses) isEqualTo 0) exitWith { objNull };

    private _isLeaperProxy = (
        (_role isEqualTo "leaper") ||
        {((toLower _className) find "leaper") >= 0}
    ) && {missionNamespace getVariable ["KFH_leaperProxyEnabled", true]};
    private _useSpecialClass = !_isLeaperProxy && {isClass (configFile >> "CfgVehicles" >> _className)};
    private _spawnClass = if (_useSpecialClass) then { _className } else { selectRandom _enemyClasses };
    private _spawnPos = [_centerPos, _minDistance, _maxDistance] call KFH_fnc_findSafeDistantSpawnPosition;
    if (_relaxedSpawn && {(_spawnPos isEqualTo []) || {!([_spawnPos, objNull] call KFH_fnc_isSpawnCandidateOpen)}}) then {
        _spawnPos = [_centerPos, _minDistance, _maxDistance] call KFH_fnc_findRelaxedSpecialSpawnPosition;
    };

    if (
        (_spawnPos isEqualTo []) ||
        {!([_spawnPos, objNull] call KFH_fnc_isSpawnCandidateOpen)}
    ) exitWith {
        [format ["Skipped %1 special spawn near %2; no safe position.", _role, mapGridPosition _centerPos]] call KFH_fnc_log;
        objNull
    };

    private _groupRef = createGroup [east, true];
    _groupRef setFormation "FILE";
    _groupRef allowFleeing 0;
    _groupRef setBehaviourStrong "COMBAT";
    _groupRef setCombatMode "YELLOW";
    _groupRef setSpeedMode "FULL";

    private _unit = _groupRef createUnit [_spawnClass, _spawnPos, [], 0, "FORM"];
    _unit setDir ([_unit, _centerPos] call BIS_fnc_dirTo);
    _unit allowFleeing 0;
    _unit setSkill (0.56 + random 0.2);
    _unit setVariable ["KFH_enemyRole", _role, true];
    _unit setVariable ["KFH_specialInfected", true, true];
    _unit setVariable ["KFH_specialClassRequested", _className, true];
    _groupRef selectLeader _unit;

    if (_useSpecialClass) then {
        _unit enableFatigue false;
        _unit setUnitPos "UP";
        _unit setBehaviourStrong "COMBAT";
        _unit setCombatMode "YELLOW";
        _unit setSpeedMode "FULL";
        if (_role in ["goliath", "smasher"]) then {
            [_unit] call KFH_fnc_configureSpecialJuggernautInfected;
        };
    } else {
        if (_isLeaperProxy) then {
            [_unit] call KFH_fnc_configureLeaperProxyInfected;
        } else {
            [_unit, true] call KFH_fnc_configureMeleeEnemy;
        };
        if (_role in ["goliath", "smasher"]) then {
            [_unit] call KFH_fnc_configureJuggernautInfected;
        };
        if (_isLeaperProxy) then {
            [format ["Leaper special uses heavy infected body proxy class=%1.", _spawnClass]] call KFH_fnc_log;
        } else {
            [format ["Special class %1 missing; spawned fallback melee for role=%2.", _className, _role]] call KFH_fnc_log;
        };
    };

    if ((count _moveTarget) >= 2) then {
        _groupRef move _moveTarget;
        _unit doMove _moveTarget;
    } else {
        _groupRef move _centerPos;
        _unit doMove _centerPos;
    };

    private _activeEnemies = missionNamespace getVariable ["KFH_activeEnemies", []];
    _activeEnemies pushBack _unit;
    missionNamespace setVariable ["KFH_activeEnemies", _activeEnemies];
    ["KFH_totalHostiles", count _activeEnemies] call KFH_fnc_setState;
    if (_addToObjective) then {
        private _objectiveEnemies = missionNamespace getVariable ["KFH_currentObjectiveEnemies", []];
        _objectiveEnemies pushBack _unit;
        missionNamespace setVariable ["KFH_currentObjectiveEnemies", _objectiveEnemies];
        ["KFH_objectiveHostiles", count _objectiveEnemies] call KFH_fnc_setState;
    };

    [format [
        "Special infected spawned: role=%1 class=%2 grid=%3.",
        _role,
        _spawnClass,
        mapGridPosition _unit
    ]] call KFH_fnc_log;

    _unit
};

KFH_fnc_spawnCheckpointSpecialInfected = {
    params ["_checkpointIndex", "_checkpointMarker", ["_isRushWave", false]];

    if !(missionNamespace getVariable ["KFH_checkpointSpecialEnabled", true]) exitWith { objNull };
    if (_checkpointIndex < (missionNamespace getVariable ["KFH_checkpointSpecialStartCheckpoint", 2])) exitWith { objNull };

    private _threatScale = [] call KFH_fnc_getThreatScale;
    private _activeSpecials = ({alive _x && {_x getVariable ["KFH_specialInfected", false]}} count (missionNamespace getVariable ["KFH_activeEnemies", []]));
    if (_activeSpecials >= ceil ((missionNamespace getVariable ["KFH_checkpointSpecialMaxActive", 4]) * _threatScale)) exitWith { objNull };

    private _chance = (missionNamespace getVariable ["KFH_checkpointSpecialChance", 0.35]) * _threatScale;
    if (_isRushWave) then {
        _chance = _chance + (missionNamespace getVariable ["KFH_checkpointSpecialRushChanceBonus", 0.2]);
    };
    if ((random 1) > (_chance min 0.98)) exitWith { objNull };

    private _roleClass = [] call KFH_fnc_selectCheckpointSpecialRole;
    _roleClass params ["_role", "_className"];
    private _minDistance = if (_role isEqualTo "screamer") then {
        missionNamespace getVariable ["KFH_screamerSpawnDistanceMin", 150]
    } else {
        missionNamespace getVariable ["KFH_checkpointSpecialMinDistance", 42]
    };
    private _maxDistance = if (_role isEqualTo "screamer") then {
        missionNamespace getVariable ["KFH_screamerSpawnDistanceMax", 260]
    } else {
        missionNamespace getVariable ["KFH_checkpointSpecialMaxDistance", 110]
    };
    [
        getMarkerPos _checkpointMarker,
        _className,
        _role,
        _minDistance,
        _maxDistance,
        getMarkerPos _checkpointMarker,
        false,
        true,
        true
    ] call KFH_fnc_spawnSpecialInfected
};

KFH_fnc_getCheckpointSpecialRampFactor = {
    params [["_waveNumber", missionNamespace getVariable ["KFH_currentWave", 0]]];

    private _cycle = (missionNamespace getVariable ["KFH_checkpointSpecialWaveRampCycle", 10]) max 1;
    ((((_waveNumber max 1) - 1) mod _cycle) + 1) / _cycle
};

KFH_fnc_spawnCheckpointRampSpecialInfected = {
    params ["_checkpointIndex", "_checkpointMarker", "_waveNumber", ["_alreadySpawnedRoles", []]];

    private _maxExtra = missionNamespace getVariable ["KFH_checkpointSpecialRampExtraMax", 1];
    if (_maxExtra <= 0) exitWith { [] };

    private _factor = [_waveNumber] call KFH_fnc_getCheckpointSpecialRampFactor;
    private _chance = (_factor * (missionNamespace getVariable ["KFH_checkpointSpecialRampExtraChanceMax", 0.65])) min 0.95;
    if ((random 1) > _chance) exitWith { [] };

    private _threatScale = [] call KFH_fnc_getThreatScale;
    private _activeSpecials = ({alive _x && {_x getVariable ["KFH_specialInfected", false]}} count (missionNamespace getVariable ["KFH_activeEnemies", []]));
    private _maxActive = ceil ((missionNamespace getVariable ["KFH_checkpointSpecialMaxActive", 4]) * _threatScale);
    if (_activeSpecials >= _maxActive) exitWith { [] };

    private _entries = missionNamespace getVariable ["KFH_checkpointSpecialRampRoles", []];
    _entries = _entries select {
        private _role = _x param [0, ""];
        !(_role in _alreadySpawnedRoles) && {!(_role in ["goliath", "smasher"])}
    };
    if ((count _entries) isEqualTo 0) exitWith { [] };

    private _spawned = [];
    private _attempts = _maxExtra min (_maxActive - _activeSpecials);
    for "_i" from 1 to _attempts do {
        private _roleClass = [_entries] call KFH_fnc_selectSpecialRoleFromEntries;
        _roleClass params ["_role", "_className"];
        private _minDistance = if (_role isEqualTo "screamer") then {
            missionNamespace getVariable ["KFH_screamerSpawnDistanceMin", 150]
        } else {
            missionNamespace getVariable ["KFH_checkpointSpecialMinDistance", 42]
        };
        private _maxDistance = if (_role isEqualTo "screamer") then {
            missionNamespace getVariable ["KFH_screamerSpawnDistanceMax", 260]
        } else {
            missionNamespace getVariable ["KFH_checkpointSpecialMaxDistance", 110]
        };
        private _unit = [
            getMarkerPos _checkpointMarker,
            _className,
            _role,
            _minDistance,
            _maxDistance,
            getMarkerPos _checkpointMarker,
            false,
            true,
            true
        ] call KFH_fnc_spawnSpecialInfected;
        if !(isNull _unit) then {
            _spawned pushBack _unit;
            _alreadySpawnedRoles pushBackUnique _role;
            _entries = _entries select { !((_x param [0, ""]) in _alreadySpawnedRoles) };
        };
    };

    if ((count _spawned) > 0) then {
        [format ["Wave %1 ramp special spawned %2 extra non-juggernaut special(s).", _waveNumber, count _spawned]] call KFH_fnc_log;
    };
    _spawned
};

KFH_fnc_spawnCheckpointBloaterInfected = {
    params ["_checkpointIndex", "_checkpointMarker", ["_alreadySpawnedRole", ""]];

    if !(missionNamespace getVariable ["KFH_checkpointBloaterPerWaveEnabled", true]) exitWith { objNull };
    if (_alreadySpawnedRole isEqualTo "bloater") exitWith { objNull };
    if (_checkpointIndex < (missionNamespace getVariable ["KFH_checkpointSpecialStartCheckpoint", 1])) exitWith { objNull };

    private _bloaterClass = [["Zombie_Special_OPFOR_Boomer"], ""] call KFH_fnc_selectExistingClass;
    if (_bloaterClass isEqualTo "") exitWith { objNull };

    private _unit = [
        getMarkerPos _checkpointMarker,
        _bloaterClass,
        "bloater",
        missionNamespace getVariable ["KFH_checkpointSpecialMinDistance", 42],
        missionNamespace getVariable ["KFH_checkpointSpecialMaxDistance", 110],
        getMarkerPos _checkpointMarker,
        missionNamespace getVariable ["KFH_checkpointBloaterPerWaveIgnoreBudget", true],
        true,
        true
    ] call KFH_fnc_spawnSpecialInfected;

    if !(isNull _unit) then {
        [format ["Checkpoint wave guaranteed bloater spawned for CP%1 at %2.", _checkpointIndex, mapGridPosition _unit]] call KFH_fnc_log;
    };
    _unit
};

KFH_fnc_getWildSpecialAnchor = {
    private _minRoadDistance = missionNamespace getVariable ["KFH_wildSpecialMinRoadDistance", 95];
    private _candidates = ([] call KFH_fnc_getHumanReferenceUnits) select {
        private _refVehicle = vehicle _x;
        alive _x &&
        {(count ((getPosATL _refVehicle) nearRoads _minRoadDistance)) isEqualTo 0}
    };

    if ((count _candidates) isEqualTo 0 && {missionNamespace getVariable ["KFH_wildSpecialAllowRouteFallback", true]}) then {
        _candidates = ([] call KFH_fnc_getHumanReferenceUnits) select { alive _x };
    };
    if ((count _candidates) isEqualTo 0) exitWith { objNull };
    selectRandom _candidates
};

KFH_fnc_spawnWildSpecialInfected = {
    if !(missionNamespace getVariable ["KFH_wildSpecialEnabled", true]) exitWith { objNull };
    private _checkpointIndex = missionNamespace getVariable ["KFH_currentCheckpoint", 1];
    if (_checkpointIndex < (missionNamespace getVariable ["KFH_wildSpecialStartCheckpoint", 2])) exitWith { objNull };
    private _threatScale = [] call KFH_fnc_getThreatScale;
    if ((random 1) > (((missionNamespace getVariable ["KFH_wildSpecialChance", 0.35]) * _threatScale) min 0.98)) exitWith { objNull };

    private _activeWild = ({alive _x && {_x getVariable ["KFH_wildSpecialInfected", false]}} count (missionNamespace getVariable ["KFH_activeEnemies", []]));
    if (_activeWild >= ceil ((missionNamespace getVariable ["KFH_wildSpecialMaxActive", 3]) * _threatScale)) exitWith { objNull };

    private _anchor = [] call KFH_fnc_getWildSpecialAnchor;
    if (isNull _anchor) exitWith { objNull };

    private _roleClass = [
        missionNamespace getVariable ["KFH_wildSpecialRoles", missionNamespace getVariable ["KFH_checkpointSpecialRoles", []]]
    ] call KFH_fnc_selectSpecialRoleFromEntries;
    _roleClass params ["_role", "_className"];
    private _minDistance = if (_role isEqualTo "screamer") then {
        missionNamespace getVariable ["KFH_screamerSpawnDistanceMin", 150]
    } else {
        missionNamespace getVariable ["KFH_wildSpecialMinDistance", 130]
    };
    private _maxDistance = if (_role isEqualTo "screamer") then {
        missionNamespace getVariable ["KFH_screamerSpawnDistanceMax", 260]
    } else {
        missionNamespace getVariable ["KFH_wildSpecialMaxDistance", 280]
    };

    private _unit = [
        getPosATL _anchor,
        _className,
        _role,
        _minDistance,
        _maxDistance,
        getPosATL _anchor,
        false,
        true,
        false
    ] call KFH_fnc_spawnSpecialInfected;

    if (!isNull _unit) then {
        _unit setVariable ["KFH_wildSpecialInfected", true, true];
        [format [
            "Wild special infected spawned off-road: role=%1 grid=%2 anchor=%3.",
            _role,
            mapGridPosition _unit,
            name _anchor
        ]] call KFH_fnc_log;
    };

    _unit
};

KFH_fnc_wildSpecialLoop = {
    while { true } do {
        private _phase = missionNamespace getVariable ["KFH_phase", "boot"];
        if (_phase in ["complete", "failed"]) exitWith {};

        if (_phase in ["assault", "extract"]) then {
            [] call KFH_fnc_spawnWildSpecialInfected;
        };

        sleep (missionNamespace getVariable ["KFH_wildSpecialLoopSeconds", 18]);
    };
};

KFH_fnc_configureRushSupplyCarrier = {
    params ["_unit", ["_scale", 1]];

    if (isNull _unit) exitWith {};
    if ((_unit getVariable ["KFH_enemyRole", "melee"]) isNotEqualTo "melee") exitWith {};

    private _bagClass = selectRandom KFH_rushSupplyCarrierBackpacks;

    removeBackpack _unit;
    _unit addBackpack _bagClass;
    _unit setVariable ["KFH_rushSupplyCarrier", true, true];
    _unit setVariable ["KFH_supplyBagClass", _bagClass, true];

    private _bag = unitBackpack _unit;
    if !(isNull _bag) then {
        [_bag, _scale] call KFH_fnc_fillRushSupplyBackpack;
    };

    _unit addEventHandler ["Killed", {
        params ["_unit"];

        if (_unit getVariable ["KFH_supplyCarrierReported", false]) exitWith {};
        _unit setVariable ["KFH_supplyCarrierReported", true, true];
        [format [
            "Rush supply carrier down at %1. Loot the backpack for bandages and magazines.",
            mapGridPosition _unit
        ]] call KFH_fnc_notifyAll;
    }];
};

KFH_fnc_canUseWebKnightZombies = {
    KFH_useWebKnightZombies && {!isNil "WBK_LoadAIThroughEden"}
};

KFH_fnc_warnMissingWebKnightZombies = {
    if !(KFH_useWebKnightZombies) exitWith {};
    if (missionNamespace getVariable ["KFH_webKnightMissingNotified", false]) exitWith {};

    missionNamespace setVariable ["KFH_webKnightMissingNotified", true, true];
    [
        "WebKnight Zombies is enabled in KFH settings, but WBK_LoadAIThroughEden was not found. Falling back to prototype melee AI."
    ] call KFH_fnc_log;
    [
        "WebKnight Zombies/Improved Melee System not loaded. Prototype melee fallback is active."
    ] call KFH_fnc_notifyAll;
};

KFH_fnc_tryConfigureWebKnightZombie = {
    params ["_unit"];

    if (isNull _unit) exitWith { false };
    if !(alive _unit) exitWith { false };
    if !(KFH_useWebKnightZombies) exitWith { false };

    if !([] call KFH_fnc_canUseWebKnightZombies) exitWith {
        [] call KFH_fnc_warnMissingWebKnightZombies;
        false
    };

    private _externalCount = count ((missionNamespace getVariable ["KFH_activeEnemies", []]) select {
        alive _x && {(_x getVariable ["KFH_enemyRole", ""]) isEqualTo "externalZombie"}
    });
    if (_externalCount >= KFH_webKnightZombieMaxActive) exitWith { false };

    private _type = selectRandom KFH_webKnightZombieTypes;
    _unit setVariable ["KFH_enemyRole", "externalZombie", true];
    _unit setVariable ["KFH_webKnightZombieType", _type, true];
    _unit setVariable ["KFH_externalZombieInitPending", true, true];

    [_unit, _type] spawn {
        params ["_trackedUnit", "_zombieType"];

        sleep KFH_webKnightInitDelay;
        waitUntil {
            sleep 0.05;
            isNull _trackedUnit || {alive _trackedUnit && {simulationEnabled _trackedUnit}}
        };
        if (isNull _trackedUnit || {!alive _trackedUnit}) exitWith {};

        [_trackedUnit, _zombieType] call WBK_LoadAIThroughEden;
        _trackedUnit setVariable ["KFH_externalZombieInitPending", false, true];
        _trackedUnit setVariable ["KFH_enemyRole", "externalZombie", true];
    };

    true
};

KFH_fnc_configureMeleeEnemy = {
    params ["_unit", ["_allowExternalZombie", true]];

    if (isNull _unit) exitWith {};

    removeAllWeapons _unit;
    removeAllItems _unit;
    removeAllAssignedItems _unit;
    removeHeadgear _unit;
    removeGoggles _unit;
    removeVest _unit;
    removeBackpack _unit;

    _unit setVariable ["KFH_enemyRole", "melee", true];
    _unit setVariable ["KFH_nextMeleeAttackAt", 0];
    _unit setVariable ["KFH_nextMoveUpdateAt", 0];
    _unit setVariable ["KFH_nextCommandMoveAt", 0];
    _unit setVariable ["KFH_nextForcedDestinationAt", 0];
    _unit setVariable ["KFH_lastMovePos", getPosATL _unit];
    _unit setVariable ["KFH_lastStuckCheckAt", time];
    _unit setVariable ["KFH_lastStuckCheckPos", getPosATL _unit];
    _unit setVariable ["KFH_nextGroanAt", time + random 2];
    _unit enableFatigue false;
    _unit allowFleeing 0;
    _unit setAnimSpeedCoef KFH_meleeRunAnimSpeed;
    {
        _unit disableAI _x;
    } forEach ["AUTOCOMBAT", "COVER", "SUPPRESSION"];
    {
        _unit enableAI _x;
    } forEach ["MOVE", "PATH", "TARGET", "AUTOTARGET"];
    _unit setBehaviourStrong "COMBAT";
    _unit setCombatMode "YELLOW";
    _unit setSpeedMode "FULL";
    _unit setUnitPos "UP";
    _unit forceWalk false;
    _unit setSpeaker "NoVoice";
    (group _unit) setFormation "FILE";
    (group _unit) allowFleeing 0;
    (group _unit) setCombatMode "YELLOW";
    (group _unit) setSpeedMode "FULL";
    (group _unit) setBehaviour "COMBAT";
    _unit stop false;

    if (_allowExternalZombie) then {
        [_unit] call KFH_fnc_tryConfigureWebKnightZombie;
    };

    [_unit, KFH_meleeLootTable, "infected"] call KFH_fnc_addUnitLootTable;
};

KFH_fnc_configureSpawnedEnemies = {
    params ["_units"];

    {
        [_x] call KFH_fnc_configureMeleeEnemy;
    } forEach _units;
};

KFH_fnc_findClosestCombatPlayer = {
    params ["_origin"];

    private _targets = [] call KFH_fnc_getCombatReadyHumans;
    if ((count _targets) isEqualTo 0) then {
        _targets = [] call KFH_fnc_getCombatReadyFriendlies;
    };

    if ((count _targets) isEqualTo 0) exitWith { objNull };

    private _closest = objNull;
    private _closestDistance = 1e10;

    {
        private _distance = _origin distance2D _x;
        if (_distance < _closestDistance) then {
            _closest = _x;
            _closestDistance = _distance;
        };
    } forEach _targets;

    _closest
};

KFH_fnc_updateMeleeEnemy = {
    params ["_unit"];

    if (isNull _unit) exitWith {};
    if !(alive _unit) exitWith {};
    private _role = _unit getVariable ["KFH_enemyRole", "melee"];
    if !(_role in ["melee", "leaper", "heavyInfected"]) exitWith {};

    private _target = [_unit] call KFH_fnc_findClosestCombatPlayer;
    if (isNull _target) exitWith {};

    private _distance = _unit distance2D _target;
    private _nextAttackAt = _unit getVariable ["KFH_nextMeleeAttackAt", 0];
    private _targetDir = [_unit, _target] call BIS_fnc_dirTo;
    private _runAnimSpeed = switch (_role) do {
        case "leaper": { missionNamespace getVariable ["KFH_leaperProxyAnimSpeed", 1.12] };
        case "heavyInfected": { KFH_heavyInfectedAnimSpeed };
        default { KFH_meleeRunAnimSpeed };
    };

    if (time >= (_unit getVariable ["KFH_nextMoveUpdateAt", 0])) then {
        [_unit, _target, _distance] call KFH_fnc_updateMeleeDestination;
        _unit setVariable ["KFH_nextMoveUpdateAt", time + (if (_role isEqualTo "leaper") then { 0.2 } else { KFH_meleeRetargetSeconds })];
    };

    if (time >= ((_unit getVariable ["KFH_lastStuckCheckAt", 0]) + KFH_meleeStuckCheckSeconds)) then {
        private _lastCheckPos = _unit getVariable ["KFH_lastStuckCheckPos", getPosATL _unit];
        private _moved = _unit distance2D _lastCheckPos;

        if (_distance > (KFH_meleeAttackRange + 1) && {_moved < KFH_meleeStuckDistance}) then {
            [_unit, _target, _distance] call KFH_fnc_updateMeleeDestination;
            _unit setVariable ["KFH_lastMovePos", [0, 0, 0]];
        };

        _unit setVariable ["KFH_lastStuckCheckAt", time];
        _unit setVariable ["KFH_lastStuckCheckPos", getPosATL _unit];
    };

    _unit setUnitPos "UP";
    _unit stop false;
    _unit allowFleeing 0;
    _unit setBehaviourStrong "COMBAT";
    _unit setCombatMode "YELLOW";
    (group _unit) allowFleeing 0;
    (group _unit) setBehaviour "COMBAT";
    (group _unit) setCombatMode "YELLOW";

    if (_role isEqualTo "leaper") then {
        private _targetPos = getPosATL _target;
        _unit disableAI "FSM";
        _unit setBehaviourStrong "AWARE";
        _unit setCombatMode "RED";
        (group _unit) setBehaviour "AWARE";
        (group _unit) setCombatMode "RED";
        _unit commandMove _targetPos;
        _unit doMove _targetPos;
        (group _unit) move _targetPos;
        _unit setDestination [_targetPos, "LEADER DIRECT", true];
    };

    if (_distance <= KFH_meleeFaceDistance) then {
        _unit setDir _targetDir;
    };

    if (_distance <= KFH_meleeWalkDistance) then {
        _unit forceWalk true;
        _unit setSpeedMode "LIMITED";
        _unit setAnimSpeedCoef KFH_meleeWalkAnimSpeed;
    } else {
        _unit forceWalk false;
        _unit setSpeedMode "FULL";
        _unit setAnimSpeedCoef _runAnimSpeed;
    };

    if (
        _distance <= KFH_meleeCueDistance &&
        {time >= (_unit getVariable ["KFH_nextGroanAt", 0])}
    ) then {
        _unit setVariable ["KFH_nextGroanAt", time + KFH_meleeCueCooldown + random 1.5];
        [_unit] remoteExecCall ["KFH_fnc_playZombieCue", 0];
    };

    if (_distance <= KFH_meleeAttackRange && {time >= _nextAttackAt}) then {
        _unit setVariable ["KFH_nextMeleeAttackAt", time + KFH_meleeAttackCooldown];
        [_unit] remoteExecCall ["KFH_fnc_localEnemyAttackAnim", 0];
        if (_distance > 0.55) then {
            _unit setVelocityModelSpace [0, KFH_meleeAttackLunge, 0.02];
        };
        [_unit] call KFH_fnc_playZombieCue;
        _target setDamage ((damage _target) + KFH_meleeAttackDamage);
        if (isPlayer _target) then {
            [] remoteExecCall ["KFH_fnc_localMeleeHitFeedback", _target];
        };
        [format ["An infected rusher hit %1.", name _target]] call KFH_fnc_log;
    };
};

KFH_fnc_playerQuickStrike = {
    private _unit = player;

    if (isNull _unit) exitWith {};
    if !(alive _unit) exitWith {};
    if ([_unit] call KFH_fnc_isIncapacitated) exitWith {};
    if (time < (_unit getVariable ["KFH_nextQuickStrikeAt", 0])) exitWith {};

    private _targets = (nearestObjects [_unit, ["CAManBase"], KFH_quickStrikeRange]) select {
        _x != _unit &&
        alive _x &&
        side _x isEqualTo east &&
        ((_x getVariable ["KFH_enemyRole", ""]) isNotEqualTo "")
    };

    if ((count _targets) isEqualTo 0) exitWith {
        ["No target in striking range."] call KFH_fnc_localNotify;
    };

    private _target = _targets select 0;
    _unit setVariable ["KFH_nextQuickStrikeAt", time + KFH_quickStrikeCooldown];
    _unit playMoveNow "AmovPercMstpSrasWpstDnon_AinvPercMstpSrasWpstDnon";
    addCamShake [1.8, 0.16, 8];
    _target setDamage ((damage _target) + KFH_quickStrikeDamage);
    [format ["%1 used Quick Strike on %2.", name _unit, typeOf _target]] call KFH_fnc_log;
};

KFH_fnc_meleeDirectorLoop = {
    while { true } do {
        private _phase = missionNamespace getVariable ["KFH_phase", "boot"];

        if (_phase in ["complete", "failed"]) exitWith {};

        {
            [_x] call KFH_fnc_updateMeleeEnemy;
        } forEach ([] call KFH_fnc_pruneActiveEnemies);

        sleep KFH_meleeRetargetSeconds;
    };
};

KFH_fnc_supportActionHandler = {
    params ["_target", "_caller"];

    private _supportType = _target getVariable ["KFH_supportType", ""];

    switch (_supportType) do {
        case "ammo": {
            [_caller] call KFH_fnc_doAmmoSupport;
        };
        case "medical": {
            [_caller] call KFH_fnc_doMedicalSupport;
        };
        case "repair": {
            [_target, _caller] call KFH_fnc_doRepairSupport;
        };
        default {
            ["Unknown support point."] call KFH_fnc_localNotify;
        };
    };
};

KFH_fnc_setupSupportActions = {
    waitUntil {
        !isNull player &&
        ((count (missionNamespace getVariable ["KFH_supportObjects", []])) > 0)
    };

    while { true } do {
        private _supportObjects = missionNamespace getVariable ["KFH_supportObjects", []];

        {
            if !(isNull _x) then {
                private _supportType = _x getVariable ["KFH_supportType", ""];

                if (
                    !(_supportType isEqualTo "") &&
                    !(_x getVariable ["KFH_actionsAdded", false])
                ) then {
                    private _label = _x getVariable ["KFH_supportLabel", "Support"];
                    private _title = switch (_supportType) do {
                        case "ammo": { format ["Resupply at %1", _label] };
                        case "medical": { format ["Use %1", _label] };
                        case "repair": { format ["Use %1", _label] };
                        default { format ["Use %1", _label] };
                    };

                    _x addAction [
                        _title,
                        {
                            params ["_target", "_caller"];
                            [_target, _caller] call KFH_fnc_supportActionHandler;
                        },
                        nil,
                        1.5,
                        true,
                        true,
                        "",
                        format ["alive _this && (_this distance _target) < %1", KFH_supportUseDistance]
                    ];

                    _x setVariable ["KFH_actionsAdded", true];
                };
            };
        } forEach _supportObjects;

        if ((missionNamespace getVariable ["KFH_phase", "boot"]) in ["complete", "failed"]) exitWith {};

        sleep 3;
    };
};

KFH_fnc_updateRespawnAnchor = {
    params ["_position", "_label"];

    private _existing = missionNamespace getVariable ["KFH_dynamicRespawn", []];

    if ((count _existing) > 0) then {
        _existing call BIS_fnc_removeRespawnPosition;
    };

    private _respawnData = [west, _position, _label] call BIS_fnc_addRespawnPosition;
    missionNamespace setVariable ["KFH_dynamicRespawn", _respawnData];
    missionNamespace setVariable ["KFH_respawnAnchorPos", +_position, true];

    if ("respawn_west" in allMapMarkers) then {
        "respawn_west" setMarkerPos _position;
        "respawn_west" setMarkerText _label;
        "respawn_west" setMarkerAlpha 0;
    };

    [format ["Respawn anchor moved to %1.", _label]] call KFH_fnc_log;
};

KFH_fnc_getCheckpointMarkers = {
    private _markers = [];
    private _index = 1;

    while { true } do {
        private _markerName = format ["kfh_cp_%1", _index];

        if !(_markerName in allMapMarkers) exitWith {};

        _markers pushBack _markerName;
        _index = _index + 1;
    };

    _markers
};

KFH_fnc_getSpawnMarkers = {
    params ["_prefix"];

    private _markers = [];
    private _index = 1;

    while { true } do {
        private _markerName = format ["%1_%2", _prefix, _index];

        if !(_markerName in allMapMarkers) exitWith {};

        _markers pushBack _markerName;
        _index = _index + 1;
    };

    _markers
};

KFH_fnc_pruneAliveUnits = {
    params ["_units"];

    _units select { alive _x }
};

KFH_fnc_scaledEnemyCount = {
    params ["_baseCount"];

    private _players = [] call KFH_fnc_getScalingPlayerCount;
    private _targetPlayers = missionNamespace getVariable ["KFH_targetPlayers", 10];
    private _factor = (((_players max 1) / _targetPlayers) max 0.4) min 1.0;
    private _threatScale = [] call KFH_fnc_getThreatScale;

    ceil (_baseCount * _factor * _threatScale)
};

KFH_fnc_getWavesUntilRush = {
    private _currentWave = missionNamespace getVariable ["KFH_currentWave", 0];
    private _remainder = _currentWave mod KFH_rushEveryWaves;

    if (_remainder isEqualTo 0) exitWith { KFH_rushEveryWaves };

    KFH_rushEveryWaves - _remainder
};

KFH_fnc_restoreSavedLoadout = {
    params ["_unit"];

    if (isNull _unit) exitWith {};
    if !(alive _unit) exitWith {};

    private _damage = damage _unit;
    private _loadout = [_unit] call KFH_fnc_getSavedLoadout;
    if ((count _loadout) isEqualTo 0) exitWith {};

    _unit setUnitLoadout _loadout;
    _unit setDamage _damage;
    _unit setFatigue 0;
    [_unit, [], "restored saved loadout"] call KFH_fnc_saveLoadoutSnapshot;
    [format ["Saved loadout restored for %1.", name _unit]] call KFH_fnc_log;
};

KFH_fnc_grantRushReward = {
    params ["_checkpointIndex", "_waveNumber"];

    if !(missionNamespace getVariable ["KFH_rushActive", false]) exitWith {};

    missionNamespace setVariable ["KFH_rushActive", false, true];
    missionNamespace setVariable ["KFH_rushCheckpoint", -1, true];
    missionNamespace setVariable ["KFH_rushWaveNumber", -1, true];
    ["KFH_rushActive", false] call KFH_fnc_setState;

    {
        [_x] call KFH_fnc_restoreSavedLoadout;
        [_x] call KFH_fnc_updateSavedLoadout;
    } forEach ([] call KFH_fnc_getHumanPlayers);

    ["rush_wave_cleared_reason", [_waveNumber, _checkpointIndex]] call KFH_fnc_autoRevivePlayers;

    [KFH_rushPressureRelief, format ["Rush wave %1 broken", _waveNumber]] call KFH_fnc_reducePressure;

    [format [
        "Rush wave %1 broken. Team revived and pressure reduced. Loot supply carriers for extra bandages and magazines.",
        _waveNumber
    ]] call KFH_fnc_notifyAll;
    ["A3\Sounds_F\sfx\blip1.wss", 2.3, 0.56] remoteExecCall ["KFH_fnc_playUiCue", 0];
};

KFH_fnc_pruneActiveEnemies = {
    private _activeEnemies = missionNamespace getVariable ["KFH_activeEnemies", []];

    _activeEnemies = _activeEnemies select { alive _x };
    missionNamespace setVariable ["KFH_activeEnemies", _activeEnemies];
    ["KFH_totalHostiles", count _activeEnemies] call KFH_fnc_setState;

    _activeEnemies
};

KFH_fnc_unregisterStaleEnemy = {
    params ["_unit", ["_reason", "stale"]];

    if (isNull _unit) exitWith {};
    if (_unit getVariable ["KFH_staleRemoved", false]) exitWith {};

    _unit setVariable ["KFH_staleRemoved", true, true];

    private _objectiveEnemies = missionNamespace getVariable ["KFH_currentObjectiveEnemies", []];
    _objectiveEnemies = _objectiveEnemies - [_unit];
    missionNamespace setVariable ["KFH_currentObjectiveEnemies", _objectiveEnemies];

    private _activeEnemies = missionNamespace getVariable ["KFH_activeEnemies", []];
    _activeEnemies = _activeEnemies - [_unit];
    missionNamespace setVariable ["KFH_activeEnemies", _activeEnemies];
    ["KFH_objectiveHostiles", count _objectiveEnemies] call KFH_fnc_setState;
    ["KFH_totalHostiles", count _activeEnemies] call KFH_fnc_setState;

    private _pressurePenalty = missionNamespace getVariable ["KFH_staleEnemyPressurePenalty", 1];
    if (_pressurePenalty > 0) then {
        private _pressure = missionNamespace getVariable ["KFH_pressure", 0];
        ["KFH_pressure", (_pressure + _pressurePenalty) min KFH_pressureMax] call KFH_fnc_setState;
    };

    if (missionNamespace getVariable ["KFH_rushDebtEnabled", true]) then {
        private _debt = missionNamespace getVariable ["KFH_rushDebtCount", 0];
        private _maxDebt = missionNamespace getVariable ["KFH_rushDebtMax", 24];
        missionNamespace setVariable ["KFH_rushDebtCount", (_debt + 1) min _maxDebt, true];
    };

    [format ["Objective hostile removed from count: %1 (%2).", typeOf _unit, _reason]] call KFH_fnc_log;

    if (([getPosATL _unit] call KFH_fnc_getNearestHumanDistance) > ((missionNamespace getVariable ["KFH_staleEnemyMinDistance", 520]) + 180)) then {
        private _groupRef = group _unit;
        deleteVehicle _unit;
        if (!isNull _groupRef && {({alive _x} count units _groupRef) isEqualTo 0}) then {
            deleteGroup _groupRef;
        };
    };
};

KFH_fnc_recycleOffscreenObjectiveEnemies = {
    params ["_checkpointMarker"];

    if !(missionNamespace getVariable ["KFH_waveRecycleOffscreenEnabled", true]) exitWith { 0 };
    if !(_checkpointMarker in allMapMarkers) exitWith { 0 };

    private _markerPos = getMarkerPos _checkpointMarker;
    private _objectiveEnemies = missionNamespace getVariable ["KFH_currentObjectiveEnemies", []];
    private _activeEnemies = missionNamespace getVariable ["KFH_activeEnemies", []];
    private _objectiveDistance = missionNamespace getVariable ["KFH_waveRecycleObjectiveDistance", 240];
    private _humanDistance = missionNamespace getVariable ["KFH_waveRecycleHumanDistance", 260];
    private _kept = [];
    private _removed = 0;

    {
        if (alive _x) then {
            private _farFromObjective = (_x distance2D _markerPos) > _objectiveDistance;
            private _offscreen = ([getPosATL _x] call KFH_fnc_getNearestHumanDistance) > _humanDistance;
            if (_farFromObjective && {_offscreen} && {!([_x] call KFH_fnc_isUnitVisibleToHumans)}) then {
                if ([_x] call KFH_fnc_isJuggernautEnemy) then {
                    [_x, "offscreen recycle skipped"] call KFH_fnc_leaveBehindJuggernaut;
                    _activeEnemies = _activeEnemies - [_x];
                } else {
                    private _groupRef = group _x;
                    _activeEnemies = _activeEnemies - [_x];
                    deleteVehicle _x;
                    if (!isNull _groupRef && {({alive _x} count units _groupRef) isEqualTo 0}) then {
                        deleteGroup _groupRef;
                    };
                };
                _removed = _removed + 1;
            } else {
                _kept pushBack _x;
            };
        };
    } forEach _objectiveEnemies;

    missionNamespace setVariable ["KFH_currentObjectiveEnemies", _kept];
    missionNamespace setVariable ["KFH_activeEnemies", _activeEnemies];
    ["KFH_objectiveHostiles", count _kept] call KFH_fnc_setState;
    ["KFH_totalHostiles", count _activeEnemies] call KFH_fnc_setState;

    if (_removed > 0) then {
        [format ["Recycled %1 offscreen objective hostiles into the next wave.", _removed]] call KFH_fnc_log;
    };
    _removed
};

KFH_fnc_isUnitVisibleToHumans = {
    params ["_unit"];

    if (isNull _unit || {!alive _unit}) exitWith { false };

    private _visible = false;
    private _threshold = missionNamespace getVariable ["KFH_staleEnemyVisibleThreshold", 0.25];
    {
        if (!_visible && {alive _x}) then {
            private _distance = _x distance2D _unit;
            if (_distance < ((missionNamespace getVariable ["KFH_staleEnemyMinDistance", 520]) + 420)) then {
                private _visibility = [objNull, "VIEW"] checkVisibility [eyePos _x, eyePos _unit];
                if (_visibility > _threshold) then {
                    _visible = true;
                };
            };
        };
    } forEach ([] call KFH_fnc_getHumanReferenceUnits);

    _visible
};

KFH_fnc_relocateStaleEnemyToObjective = {
    params ["_unit"];

    if !(missionNamespace getVariable ["KFH_staleEnemyRelocateEnabled", true]) exitWith { false };
    if (isNull _unit || {!alive _unit}) exitWith { false };
    if ([_unit] call KFH_fnc_isJuggernautEnemy) exitWith { false };
    if ([_unit] call KFH_fnc_isUnitVisibleToHumans) exitWith { false };

    private _markerName = missionNamespace getVariable ["KFH_currentObjectiveMarker", ""];
    if !(_markerName in allMapMarkers) exitWith { false };

    private _markerPos = getMarkerPos _markerName;
    private _spawnPos = [_markerPos] call KFH_fnc_findCoveredObjectiveRelocationPosition;
    if ((count _spawnPos) < 2) then {
        _spawnPos = [
            _markerPos,
            missionNamespace getVariable ["KFH_staleEnemyRelocateMinDistance", 90],
            missionNamespace getVariable ["KFH_staleEnemyRelocateMaxDistance", 190]
        ] call KFH_fnc_findSafeDistantSpawnPosition;
    };
    if ((count _spawnPos) < 2) exitWith { false };

    private _groupRef = group _unit;
    {
        deleteWaypoint _x;
    } forEach (waypoints _groupRef);

    _unit setPosATL _spawnPos;
    _unit setDir (_spawnPos getDir _markerPos);
    _unit setVariable ["KFH_staleSince", -1];
    _unit setVariable ["KFH_staleRemoved", false, true];
    _unit setVariable ["KFH_nextCommandMoveAt", 0];
    _unit setVariable ["KFH_nextForcedDestinationAt", 0];
    _unit enableAI "MOVE";
    _unit enableAI "PATH";
    _unit enableAI "TARGET";
    _unit enableAI "AUTOTARGET";
    _unit setUnitPos "UP";
    _unit setSpeedMode "FULL";
    _unit stop false;
    _unit doMove _markerPos;
    _groupRef move _markerPos;
    private _wp = _groupRef addWaypoint [_markerPos, 0];
    _wp setWaypointType "MOVE";
    _wp setWaypointSpeed "FULL";
    _wp setWaypointBehaviour "COMBAT";
    _wp setWaypointCompletionRadius KFH_captureRadius;

    [format ["Objective hostile relocated ahead: %1 -> %2.", typeOf _unit, mapGridPosition _spawnPos]] call KFH_fnc_log;
    true
};

KFH_fnc_isRelocationCandidateUsable = {
    params ["_candidatePos"];

    if ((count _candidatePos) < 2) exitWith { false };

    private _posATL = [
        _candidatePos select 0,
        _candidatePos select 1,
        if ((count _candidatePos) > 2) then { _candidatePos select 2 } else { 0 }
    ];

    if (surfaceIsWater _posATL) exitWith { false };
    if !([_posATL] call KFH_fnc_isSpawnFarFromFriendlies) exitWith { false };
    if !([_posATL] call KFH_fnc_isFarFromMilitaryEnv) exitWith { false };

    private _hardBlockers = nearestObjects [_posATL, ["House", "Building"], 2.5];
    if ((count _hardBlockers) > 0) exitWith { false };

    true
};

KFH_fnc_findCoveredObjectiveRelocationPosition = {
    params ["_objectivePos"];

    private _minDistance = missionNamespace getVariable ["KFH_staleEnemyRelocateMinDistance", 90];
    private _maxDistance = missionNamespace getVariable ["KFH_staleEnemyRelocateMaxDistance", 190];
    private _coverRadius = missionNamespace getVariable ["KFH_staleEnemyRelocateCoverRadius", 95];
    private _coverTypes = missionNamespace getVariable [
        "KFH_staleEnemyRelocateCoverTypes",
        ["TREE", "SMALL TREE", "BUSH", "ROCK", "ROCKS", "HOUSE", "BUILDING", "WALL", "FENCE", "HIDE"]
    ];
    private _offsetMin = missionNamespace getVariable ["KFH_staleEnemyRelocateCoverOffsetMin", 4];
    private _offsetMax = missionNamespace getVariable ["KFH_staleEnemyRelocateCoverOffsetMax", 9];
    private _result = [];
    private _tries = 0;

    private _covers = nearestTerrainObjects [
        _objectivePos,
        _coverTypes,
        _maxDistance + _coverRadius,
        false,
        true
    ];
    _covers = _covers call BIS_fnc_arrayShuffle;

    {
        if (_tries < 36 && {_result isEqualTo []} && {_x isEqualType objNull} && {!isNull _x}) then {
            _tries = _tries + 1;
            private _coverPos = getPosATL _x;
            private _distanceFromObjective = _coverPos distance2D _objectivePos;

            if (_distanceFromObjective >= _minDistance && {_distanceFromObjective <= (_maxDistance + _coverRadius)}) then {
                private _nearestHuman = objNull;
                private _nearestDistance = 1e10;

                {
                    private _distanceToHuman = _coverPos distance2D _x;
                    if (_distanceToHuman < _nearestDistance) then {
                        _nearestDistance = _distanceToHuman;
                        _nearestHuman = _x;
                    };
                } forEach ([] call KFH_fnc_getHumanReferenceUnits);

                private _coverDir = if (isNull _nearestHuman) then {
                    random 360
                } else {
                    [_nearestHuman, _x] call BIS_fnc_dirTo
                };
                private _offset = _offsetMin + random ((_offsetMax - _offsetMin) max 1);
                private _candidateSeed = _coverPos getPos [_offset, _coverDir + ((random 50) - 25)];
                private _candidate = [_candidateSeed, 0, 6, 1, 0, 0.45, 0] call BIS_fnc_findSafePos;
                if ((count _candidate) < 3) then {
                    _candidate set [2, 0];
                };

                if ([_candidate] call KFH_fnc_isRelocationCandidateUsable) then {
                    _result = +_candidate;
                };
            };
        };
    } forEach _covers;

    _result
};

KFH_fnc_pruneStaleObjectiveEnemies = {
    params ["_objectiveEnemies"];

    if !(missionNamespace getVariable ["KFH_staleEnemyCleanupEnabled", true]) exitWith {
        [_objectiveEnemies] call KFH_fnc_pruneAliveUnits
    };

    private _markerName = missionNamespace getVariable ["KFH_currentObjectiveMarker", ""];
    private _markerPos = if (_markerName in allMapMarkers) then { getMarkerPos _markerName } else { [0, 0, 0] };
    private _minDistance = missionNamespace getVariable ["KFH_staleEnemyMinDistance", 520];
    private _forgetSeconds = missionNamespace getVariable ["KFH_staleEnemyForgetSeconds", 40];
    private _cpGraceDistance = KFH_captureRadius + 220;
    private _kept = [];

    {
        if (alive _x) then {
            private _nearestHuman = [getPosATL _x] call KFH_fnc_getNearestHumanDistance;
            private _farFromObjective = if (_markerName in allMapMarkers) then {
                (_x distance2D _markerPos) > _cpGraceDistance
            } else {
                true
            };
            private _staleCandidate = (_nearestHuman > _minDistance) && {_farFromObjective};

            if (_staleCandidate) then {
                if ([_x] call KFH_fnc_isJuggernautEnemy) then {
                    [_x, "stale relocation skipped"] call KFH_fnc_leaveBehindJuggernaut;
                } else {
                private _staleSince = _x getVariable ["KFH_staleSince", -1];
                if (_staleSince < 0) then {
                    _x setVariable ["KFH_staleSince", time];
                    _kept pushBack _x;
                } else {
                    if ((time - _staleSince) >= _forgetSeconds) then {
                        if ([_x] call KFH_fnc_relocateStaleEnemyToObjective) then {
                            _kept pushBack _x;
                        } else {
                            if ([_x] call KFH_fnc_isUnitVisibleToHumans) then {
                                _x setVariable ["KFH_staleSince", time];
                                _kept pushBack _x;
                            } else {
                                [_x, "left behind"] call KFH_fnc_unregisterStaleEnemy;
                            };
                        };
                    } else {
                        _kept pushBack _x;
                    };
                };
                };
            } else {
                _x setVariable ["KFH_staleSince", -1];
                _kept pushBack _x;
            };
        };
    } forEach _objectiveEnemies;

    _kept
};

KFH_fnc_limitSpawnCountByActiveBudget = {
    params ["_requestedCount", ["_reserveSlots", 0]];

    private _activeEnemies = [] call KFH_fnc_pruneActiveEnemies;
    private _hardCap = missionNamespace getVariable ["KFH_activeEnemyHardCap", KFH_activeEnemyHardCap];
    private _available = (_hardCap - (count _activeEnemies) - _reserveSlots) max 0;
    private _allowed = (_requestedCount max 0) min _available;

    if (_allowed < _requestedCount) then {
        if (time >= (missionNamespace getVariable ["KFH_nextSpawnCapWarningAt", 0])) then {
            missionNamespace setVariable [
                "KFH_nextSpawnCapWarningAt",
                time + (missionNamespace getVariable ["KFH_spawnCapWarningCooldown", KFH_spawnCapWarningCooldown])
            ];
            [format [
                "Spawn budget limited: requested=%1 allowed=%2 active=%3 cap=%4 reserve=%5.",
                _requestedCount,
                _allowed,
                count _activeEnemies,
                _hardCap,
                _reserveSlots
            ]] call KFH_fnc_log;
        };
    };

    _allowed
};

KFH_fnc_rollRoleCount = {
    params ["_unitCount", "_chance", ["_maxCount", 999]];

    if (_chance <= 0 || {_unitCount <= 0}) exitWith { 0 };

    private _rawCount = _unitCount * _chance;
    private _count = floor _rawCount;
    private _fraction = _rawCount - _count;

    if ((random 1) < _fraction) then {
        _count = _count + 1;
    };

    (_count min _unitCount) min _maxCount
};

KFH_fnc_getCurrentObjectiveEnemies = {
    private _objectiveEnemies = missionNamespace getVariable ["KFH_currentObjectiveEnemies", []];
    _objectiveEnemies = [_objectiveEnemies] call KFH_fnc_pruneStaleObjectiveEnemies;
    missionNamespace setVariable ["KFH_currentObjectiveEnemies", _objectiveEnemies];

    _objectiveEnemies
};

KFH_fnc_spawnGroupWave = {
    params [
        "_centerPos",
        "_spawnMarkers",
        "_unitCount",
        ["_gunnerChance", 0],
        ["_supplyCarrierChance", 0],
        ["_heavyChance", 0]
    ];

    private _enemyClasses = missionNamespace getVariable ["KFH_enemyClasses", KFH_enemyClasses];
    private _spawnedUnits = [];
    _unitCount = [_unitCount] call KFH_fnc_limitSpawnCountByActiveBudget;

    if ((count _enemyClasses) isEqualTo 0) exitWith { [] };
    if (_unitCount <= 0) exitWith { [] };

    for "_i" from 0 to (_unitCount - 1) do {
        private _groupRef = createGroup [east, true];
        _groupRef setFormation "FILE";
        _groupRef allowFleeing 0;
        _groupRef setBehaviourStrong "COMBAT";
        _groupRef setCombatMode "YELLOW";
        _groupRef setSpeedMode "FULL";
        private _spawnPos = [0, 0, 0];

        if (KFH_useManualSpawnMarkers && ((count _spawnMarkers) > 0)) then {
            _spawnPos = getMarkerPos (selectRandom _spawnMarkers);
        } else {
            _spawnPos = [_centerPos] call KFH_fnc_findForwardSpawnPosition;
        };

        if (
            (_spawnPos isEqualTo []) ||
            {(_spawnPos distance2D _centerPos) < 3} ||
            {surfaceIsWater _spawnPos} ||
            {!([_spawnPos, objNull] call KFH_fnc_isSpawnCandidateOpen)}
        ) then {
            _spawnPos = [_centerPos, KFH_spawnAheadMinDistance, KFH_spawnAheadMaxDistance + 45] call KFH_fnc_findSafeDistantSpawnPosition;
        };

        if (
            (_spawnPos isEqualTo []) ||
            {!([_spawnPos, objNull] call KFH_fnc_isSpawnCandidateOpen)}
        ) then {
            [format ["Skipped unsafe hostile spawn near %1.", mapGridPosition _centerPos]] call KFH_fnc_log;
            deleteGroup _groupRef;
        } else {
            private _unit = _groupRef createUnit [selectRandom _enemyClasses, _spawnPos, [], 0, "FORM"];
            _unit setSkill (0.35 + random 0.25);
            _unit setDir ([_unit, _centerPos] call BIS_fnc_dirTo);
            _groupRef selectLeader _unit;
            _spawnedUnits pushBack _unit;
            _groupRef move _centerPos;
        };
    };

    private _availableForRoles = +_spawnedUnits;
    private _gunnerCount = if (_gunnerChance > 0 && {(count _availableForRoles) > 0}) then {
        [_unitCount, _gunnerChance, count _availableForRoles] call KFH_fnc_rollRoleCount
    } else {
        0
    };

    for "_i" from 1 to _gunnerCount do {
        private _picked = selectRandom _availableForRoles;
        _availableForRoles deleteAt (_availableForRoles find _picked);
        [_picked] call KFH_fnc_configureAgentEnemy;
        _picked doMove _centerPos;
    };

    private _heavyCount = if (_heavyChance > 0 && {(count _availableForRoles) > 0}) then {
        [_unitCount, _heavyChance, count _availableForRoles] call KFH_fnc_rollRoleCount
    } else {
        0
    };

    for "_i" from 1 to _heavyCount do {
        private _picked = selectRandom _availableForRoles;
        _availableForRoles deleteAt (_availableForRoles find _picked);
        [_picked] call KFH_fnc_configureHeavyInfected;
    };

    private _carrierCount = if (_supplyCarrierChance > 0 && {(count _availableForRoles) > 0}) then {
        [_unitCount, _supplyCarrierChance, KFH_rushSupplyCarrierMax min (count _availableForRoles)] call KFH_fnc_rollRoleCount
    } else {
        0
    };

    for "_i" from 1 to _carrierCount do {
        private _picked = selectRandom _availableForRoles;
        _availableForRoles deleteAt (_availableForRoles find _picked);
        [_picked, true] call KFH_fnc_configureMeleeEnemy;
        [_picked, _unitCount / 10] call KFH_fnc_configureRushSupplyCarrier;
    };

    {
        [_x, true] call KFH_fnc_configureMeleeEnemy;
    } forEach _availableForRoles;

    _spawnedUnits
};

KFH_fnc_spawnCheckpointWave = {
    params ["_checkpointIndex", ["_multiplier", 1], ["_setAsCurrentObjective", false]];

    private _checkpointMarkers = missionNamespace getVariable ["KFH_checkpointMarkers", []];

    if (_checkpointIndex > count _checkpointMarkers) exitWith { [] };

    private _checkpointMarker = _checkpointMarkers select (_checkpointIndex - 1);
    private _recycledCount = [_checkpointMarker] call KFH_fnc_recycleOffscreenObjectiveEnemies;
    private _baseCounts = missionNamespace getVariable ["KFH_waveBaseCounts", KFH_waveBaseCounts];
    private _baseIndex = ((_checkpointIndex - 1) min ((count _baseCounts) - 1)) max 0;
    private _baseCount = _baseCounts select _baseIndex;
    private _waveNumber = missionNamespace getVariable ["KFH_currentWave", 0];
    private _newWaveNumber = _waveNumber + 1;
    private _phase = missionNamespace getVariable ["KFH_phase", "assault"];
    private _isRushWave =
        (_phase isEqualTo "assault") &&
        {_newWaveNumber > 0} &&
        {(_newWaveNumber mod KFH_rushEveryWaves) isEqualTo 0};
    private _effectiveMultiplier = if (_isRushWave) then {
        _multiplier * KFH_rushWaveMultiplier
    } else {
        _multiplier
    };
    private _unitCount = [ceil (_baseCount * _effectiveMultiplier)] call KFH_fnc_scaledEnemyCount;
    private _rushDebt = if (_isRushWave) then { missionNamespace getVariable ["KFH_rushDebtCount", 0] } else { 0 };
    if (_isRushWave && {_rushDebt > 0}) then {
        missionNamespace setVariable ["KFH_rushDebtCount", 0, true];
        [format ["Rush debt paid: %1 left-behind hostiles added to wave %2.", _rushDebt, _newWaveNumber]] call KFH_fnc_log;
    };
    _unitCount = _unitCount + _recycledCount + _rushDebt;
    private _spawnMarkers = [format ["kfh_spawn_%1", _checkpointIndex]] call KFH_fnc_getSpawnMarkers;
    private _gunnerChance = if (_isRushWave) then { KFH_rushGunnerChance } else { KFH_standardGunnerChance };
    private _supplyCarrierChance = if (_isRushWave) then { KFH_rushSupplyCarrierChance } else { 0 };
    private _heavyChance = if (_isRushWave) then { KFH_rushHeavyChance } else { KFH_standardHeavyChance };
    private _spawnedUnits = [
        getMarkerPos _checkpointMarker,
        _spawnMarkers,
        _unitCount,
        _gunnerChance,
        _supplyCarrierChance,
        _heavyChance
    ] call KFH_fnc_spawnGroupWave;
    private _activeEnemies = missionNamespace getVariable ["KFH_activeEnemies", []];

    _activeEnemies append _spawnedUnits;
    missionNamespace setVariable ["KFH_activeEnemies", _activeEnemies];

    if (_setAsCurrentObjective) then {
        missionNamespace setVariable ["KFH_currentObjectiveEnemies", _spawnedUnits];
        missionNamespace setVariable ["KFH_currentObjectiveMarker", _checkpointMarker, true];
        missionNamespace setVariable ["KFH_currentWaveHostileCount", count _spawnedUnits, true];
        [_spawnedUnits, _checkpointIndex] call KFH_fnc_promoteObjectiveCarrier;
    } else {
        if (_checkpointIndex isEqualTo (missionNamespace getVariable ["KFH_currentCheckpoint", 1])) then {
            private _objectiveEnemies = missionNamespace getVariable ["KFH_currentObjectiveEnemies", []];
            _objectiveEnemies append _spawnedUnits;
            missionNamespace setVariable ["KFH_currentObjectiveEnemies", _objectiveEnemies];
            missionNamespace setVariable ["KFH_currentWaveHostileCount", count _objectiveEnemies, true];
        };
    };

    private _special = [_checkpointIndex, _checkpointMarker, _isRushWave] call KFH_fnc_spawnCheckpointSpecialInfected;
    private _specialRole = "";
    if !(isNull _special) then {
        _specialRole = _special getVariable ["KFH_enemyRole", ""];
        _spawnedUnits pushBack _special;
        _activeEnemies = missionNamespace getVariable ["KFH_activeEnemies", []];
        private _objectiveEnemies = missionNamespace getVariable ["KFH_currentObjectiveEnemies", []];
        missionNamespace setVariable ["KFH_currentWaveHostileCount", count _objectiveEnemies, true];
    };

    private _bloater = [_checkpointIndex, _checkpointMarker, _specialRole] call KFH_fnc_spawnCheckpointBloaterInfected;
    if !(isNull _bloater) then {
        _spawnedUnits pushBack _bloater;
        _activeEnemies = missionNamespace getVariable ["KFH_activeEnemies", []];
        private _objectiveEnemies = missionNamespace getVariable ["KFH_currentObjectiveEnemies", []];
        missionNamespace setVariable ["KFH_currentWaveHostileCount", count _objectiveEnemies, true];
    };

    private _alreadySpecialRoles = [];
    if !(_specialRole isEqualTo "") then { _alreadySpecialRoles pushBackUnique _specialRole; };
    if !(isNull _bloater) then { _alreadySpecialRoles pushBackUnique "bloater"; };
    private _rampSpecials = [_checkpointIndex, _checkpointMarker, _newWaveNumber, _alreadySpecialRoles] call KFH_fnc_spawnCheckpointRampSpecialInfected;
    if ((count _rampSpecials) > 0) then {
        _spawnedUnits append _rampSpecials;
        _activeEnemies = missionNamespace getVariable ["KFH_activeEnemies", []];
        private _objectiveEnemies = missionNamespace getVariable ["KFH_currentObjectiveEnemies", []];
        missionNamespace setVariable ["KFH_currentWaveHostileCount", count _objectiveEnemies, true];
    };

    if (_isRushWave) then {
        missionNamespace setVariable ["KFH_rushActive", true, true];
        missionNamespace setVariable ["KFH_rushCheckpoint", _checkpointIndex, true];
        missionNamespace setVariable ["KFH_rushWaveNumber", _newWaveNumber, true];
        ["KFH_rushActive", true] call KFH_fnc_setState;
    };

    ["KFH_currentWave", _newWaveNumber] call KFH_fnc_setState;
    missionNamespace setVariable ["KFH_currentWaveStartedAt", time, true];
    if !(missionNamespace getVariable ["KFH_currentWaveHostileCount", -1] > 0) then {
        missionNamespace setVariable ["KFH_currentWaveHostileCount", count _spawnedUnits, true];
    };
    missionNamespace setVariable ["KFH_objectiveClearCooldownAppliedWave", -1, true];
    ["KFH_objectiveHostiles", count _spawnedUnits] call KFH_fnc_setState;
    ["KFH_totalHostiles", count _activeEnemies] call KFH_fnc_setState;
    if (_isRushWave) then {
        private _expectedGunners = ((round (_unitCount * KFH_rushGunnerChance)) max 1);
        [format ["Rush wave %1 deployed at checkpoint %2 (%3 hostiles, about %4 gunners).", _newWaveNumber, _checkpointIndex, count _spawnedUnits, _expectedGunners]] call KFH_fnc_notifyAll;
        ["A3\Sounds_F\sfx\alarm_independent.wss", 2.6, 0.86] remoteExecCall ["KFH_fnc_playUiCue", 0];
    } else {
        [format ["Wave %1 deployed at checkpoint %2 (%3 hostiles).", _newWaveNumber, _checkpointIndex, count _spawnedUnits]] call KFH_fnc_log;
    };
    [format ["Wave %1 が checkpoint %2 に到達、敵 %3 体デス。", _newWaveNumber, _checkpointIndex, count _spawnedUnits], "WAVE"] call KFH_fnc_appendRunEvent;
    [format ["Spawned hostiles near checkpoint %1 at %2.", _checkpointIndex, mapGridPosition (getMarkerPos _checkpointMarker)]] call KFH_fnc_log;

    _spawnedUnits
};

KFH_fnc_spawnExtractWave = {
    private _extractMarker = missionNamespace getVariable ["KFH_extractMarker", ""];

    if (_extractMarker isEqualTo "") exitWith { [] };

    private _spawnMarkers = ["kfh_spawn_extract"] call KFH_fnc_getSpawnMarkers;
    private _extractBaseCount = missionNamespace getVariable ["KFH_extractWaveBaseCount", KFH_extractBaseWaveCount];
    private _unitCount = [ceil (_extractBaseCount * ([] call KFH_fnc_getPressureSpawnMultiplier))] call KFH_fnc_scaledEnemyCount;
    private _spawnedUnits = [
        getMarkerPos _extractMarker,
        _spawnMarkers,
        _unitCount,
        KFH_extractGunnerChance,
        KFH_extractSupplyCarrierChance,
        KFH_extractHeavyChance
    ] call KFH_fnc_spawnGroupWave;
    private _activeEnemies = missionNamespace getVariable ["KFH_activeEnemies", []];
    private _waveNumber = missionNamespace getVariable ["KFH_currentWave", 0];

    _activeEnemies append _spawnedUnits;
    missionNamespace setVariable ["KFH_activeEnemies", _activeEnemies];
    ["KFH_currentWave", _waveNumber + 1] call KFH_fnc_setState;
    missionNamespace setVariable ["KFH_currentWaveStartedAt", time, true];
    missionNamespace setVariable ["KFH_currentWaveHostileCount", count _spawnedUnits, true];
    missionNamespace setVariable ["KFH_objectiveClearCooldownAppliedWave", -1, true];
    ["KFH_totalHostiles", count _activeEnemies] call KFH_fnc_setState;
    ["Retreat wave deployed near extraction."] call KFH_fnc_notifyAll;
    [format ["帰還 wave %1 が extraction 付近に出現、敵 %2 体デス。", _waveNumber + 1, count _spawnedUnits], "WAVE"] call KFH_fnc_appendRunEvent;

    _spawnedUnits
};

KFH_fnc_onCheckpointSecured = {
    params ["_checkpointIndex", "_checkpointMarker", "_pressure"];

    private _checkpointPos = getMarkerPos _checkpointMarker;
    private _totalCheckpoints = missionNamespace getVariable ["KFH_totalCheckpoints", _checkpointIndex];
    private _securedStates = missionNamespace getVariable ["KFH_checkpointSecuredStates", []];

    {
        [_x] call KFH_fnc_updateSavedLoadout;
    } forEach ([] call KFH_fnc_getHumanPlayers);

    if ((_checkpointIndex - 1) < (count _securedStates)) then {
        _securedStates set [_checkpointIndex - 1, true];
        missionNamespace setVariable ["KFH_checkpointSecuredStates", _securedStates, true];
    };
    missionNamespace setVariable ["KFH_runLastSecuredCheckpoint", _checkpointIndex, true];
    [_checkpointIndex] call KFH_fnc_applyCheckpointTimeProgression;
    [format [
        "Checkpoint %1 を確保したデス。イベント: %2。",
        _checkpointIndex,
        [_checkpointIndex] call KFH_fnc_getCheckpointEventName
    ], "CHECKPOINT"] call KFH_fnc_appendRunEvent;
    if (_checkpointIndex isEqualTo 1) then {
        ["firstCheckpoint", _checkpointIndex] call KFH_fnc_playStoryBeatOnce;
    };
    if (_checkpointIndex >= (ceil (_totalCheckpoints * 0.6))) then {
        ["baseLost", _checkpointIndex] call KFH_fnc_playStoryBeatOnce;
    };

    ["checkpoint_cleared_reason", [_checkpointIndex]] call KFH_fnc_autoRevivePlayers;
    [_checkpointPos, format ["Checkpoint %1", _checkpointIndex]] call KFH_fnc_updateRespawnAnchor;
    ["TaskSucceeded", [format ["Checkpoint %1 secured", _checkpointIndex], "Route stabilized. Resupply incoming."]] remoteExecCall ["BIS_fnc_showNotification", 0];
    ["A3\Sounds_F\sfx\blip1.wss", 2.1, 0.62] remoteExecCall ["KFH_fnc_playUiCue", 0];

    [KFH_pressureCheckpointRelief, format ["Checkpoint %1 secured", _checkpointIndex]] call KFH_fnc_reducePressure;
    private _secureCooldown = [_checkpointIndex] call KFH_fnc_getCheckpointSecureCooldown;
    [_secureCooldown, format ["checkpoint %1 secured", _checkpointIndex]] call KFH_fnc_applyWaveCooldown;
    missionNamespace setVariable ["KFH_currentObjectiveEnemies", []];
    ["KFH_objectiveHostiles", 0] call KFH_fnc_setState;
    ["KFH_totalHostiles", count ([] call KFH_fnc_pruneActiveEnemies)] call KFH_fnc_setState;
    [] call KFH_fnc_refreshStrategicState;

    if (_checkpointIndex < _totalCheckpoints) then {
        [_checkpointIndex, _checkpointMarker] call KFH_fnc_scheduleCheckpointSupplyArrival;
        [_checkpointMarker, _checkpointIndex] call KFH_fnc_spawnRewardCache;
        [_checkpointIndex] call KFH_fnc_spawnBranchRewardCache;
        if ((random 1) < KFH_pressureReliefEventChance) then {
            [KFH_pressureReliefEventAmount, format ["Checkpoint %1 side relief event", _checkpointIndex]] call KFH_fnc_reducePressure;
            [format ["Checkpoint %1 side event disrupted hive pressure.", _checkpointIndex]] call KFH_fnc_notifyAll;
        };
        [format [
            "Checkpoint %1 secured. %2 cache dropped with a backpack upgrade and stronger gear.",
            _checkpointIndex,
            [_checkpointIndex] call KFH_fnc_getCheckpointRewardTierName
        ]] call KFH_fnc_notifyAll;
    } else {
        private _supportObjects = [_checkpointMarker, _checkpointIndex] call KFH_fnc_spawnCheckpointSupport;
        {
            if !(isNull _x) then {
                _x setDamage 0;
            };
        } forEach _supportObjects;
        [_checkpointMarker] call KFH_fnc_spawnOptionalArsenalBase;
        [KFH_finalArsenalCooldownSeconds, "arsenal secured"] call KFH_fnc_applyWaveCooldown;
        ["finalCheckpoint", _checkpointIndex] call KFH_fnc_playStoryBeatOnce;
        ["Final checkpoint secured. Optional arsenal base marked off-route for the return trip."] call KFH_fnc_notifyAll;
    };
};

KFH_fnc_completeMission = {
    params ["_success", "_message"];

    if (missionNamespace getVariable ["KFH_missionEnding", false]) exitWith {};
    missionNamespace setVariable ["KFH_missionEnding", true, true];

    private _phase = if (_success) then { "complete" } else { "failed" };
    ["KFH_phase", _phase] call KFH_fnc_setState;
    [_message] call KFH_fnc_notifyAll;
    [format ["ミッション終了: %1", _message], "END"] call KFH_fnc_appendRunEvent;
    [] call KFH_fnc_publishRunSummary;

    [_success] spawn {
        params ["_success"];
        sleep KFH_missionEndSyncDelay;

        if (_success) then {
            ["end1", true, 5] remoteExecCall ["BIS_fnc_endMission", 0];
        } else {
            ["loser", true, 5] remoteExecCall ["BIS_fnc_endMission", 0];
        };
    };
};

KFH_fnc_waitForInitialCombatReady = {
    private _deadline = time + KFH_initialWaveReadyTimeout;
    private _ready = false;
    private _hasHumans = false;

    waitUntil {
        sleep 0.5;
        private _humans = [] call KFH_fnc_getHumanPlayers;
        _hasHumans = (count _humans) > 0;
        _ready = (count (_humans select {
            alive _x && {_x getVariable ["KFH_clientReadyForInitialWave", false]}
        })) > 0;

        _ready || {time >= _deadline && {_hasHumans}}
    };

    sleep KFH_initialWaveReadyBuffer;

    if (_ready) then {
        ["Initial wave released after player starter loadout readiness."] call KFH_fnc_log;
    } else {
        ["Initial wave readiness timed out; releasing wave after safety buffer."] call KFH_fnc_log;
    };

    missionNamespace setVariable ["KFH_initialCombatReleased", true, true];
};

KFH_fnc_applyEnemyAccuracyPreset = {
    private _value = ["KFH_EnemyAccuracy", missionNamespace getVariable ["KFH_enemyAccuracyParamDefault", 1]] call BIS_fnc_getParamValue;
    private _names = missionNamespace getVariable ["KFH_enemyAccuracyNames", ["veryLow", "low", "normal", "high", "veryHigh"]];
    private _index = (_value max 0) min ((count _names) - 1);
    private _profile = switch (_index) do {
        case 0: { [0.02, 0.24, 0.10] };
        case 2: { [0.06, 0.14, 0.18] };
        case 3: { [0.09, 0.11, 0.22] };
        case 4: { [0.13, 0.08, 0.28] };
        default { [0.04, 0.18, 0.14] };
    };
    _profile params ["_accuracy", "_shake", "_speed"];

    missionNamespace setVariable ["KFH_enemyAccuracyPreset", _names select _index, true];
    missionNamespace setVariable ["KFH_enemyAimingAccuracy", _accuracy, true];
    missionNamespace setVariable ["KFH_enemyAimingShake", _shake, true];
    missionNamespace setVariable ["KFH_enemyAimingSpeed", _speed, true];
    [format ["Enemy fire accuracy preset applied: %1 accuracy=%2 shake=%3 speed=%4.", _names select _index, _accuracy, _shake, _speed]] call KFH_fnc_log;
};

KFH_fnc_applyServerRouteParams = {
    private _routeScale = ["KFH_RouteScale", missionNamespace getVariable ["KFH_routeScaleParamDefault", 100]] call BIS_fnc_getParamValue;
    private _checkpointCount = ["KFH_CheckpointCount", missionNamespace getVariable ["KFH_checkpointCountParamDefault", KFH_checkpointCount]] call BIS_fnc_getParamValue;
    _checkpointCount = (_checkpointCount max KFH_checkpointCountMin) min KFH_checkpointCountMax;

    missionNamespace setVariable ["KFH_checkpointCount", _checkpointCount, true];
    KFH_checkpointCount = _checkpointCount;

    switch (_routeScale) do {
        case 33: {
            missionNamespace setVariable ["KFH_debugShortRouteEnabled", true, true];
            missionNamespace setVariable ["KFH_debugShortRouteForce", true, true];
            missionNamespace setVariable ["KFH_debugShortRouteScale", 0.33, true];
            missionNamespace setVariable ["KFH_debugShortRouteMinSpacing", 280, true];
            missionNamespace setVariable ["KFH_debugShortRouteLengthRatio", 0.08, true];
            missionNamespace setVariable ["KFH_debugShortRouteTargetSegment", missionNamespace getVariable ["KFH_debugShortRouteTargetSegment", 480], true];
            missionNamespace setVariable ["KFH_debugShortRouteJitter", 140, true];
            missionNamespace setVariable ["KFH_debugShortRouteEdgeMargin", 450, true];
        };
        case 50: {
            missionNamespace setVariable ["KFH_debugShortRouteEnabled", true, true];
            missionNamespace setVariable ["KFH_debugShortRouteForce", true, true];
            missionNamespace setVariable ["KFH_debugShortRouteScale", 0.5, true];
            missionNamespace setVariable ["KFH_debugShortRouteMinSpacing", missionNamespace getVariable ["KFH_routeScaleHalfMinSpacing", 440], true];
            missionNamespace setVariable ["KFH_debugShortRouteLengthRatio", missionNamespace getVariable ["KFH_routeScaleHalfLengthRatio", 0.18], true];
            missionNamespace setVariable ["KFH_debugShortRouteTargetSegment", missionNamespace getVariable ["KFH_routeScaleHalfTargetSegment", 780], true];
            missionNamespace setVariable ["KFH_debugShortRouteJitter", missionNamespace getVariable ["KFH_routeScaleHalfJitter", 210], true];
            missionNamespace setVariable ["KFH_debugShortRouteEdgeMargin", missionNamespace getVariable ["KFH_routeScaleHalfEdgeMargin", 520], true];
        };
        default {
            missionNamespace setVariable ["KFH_debugShortRouteEnabled", false, true];
            missionNamespace setVariable ["KFH_debugShortRouteForce", false, true];
            missionNamespace setVariable ["KFH_debugShortRouteActive", false, true];
            missionNamespace setVariable ["KFH_debugShortRouteApplied", false, true];
        };
    };

    [format ["Server route params applied: scale=%1 checkpointCount=%2.", _routeScale, _checkpointCount]] call KFH_fnc_log;
};

KFH_fnc_applyThreatScaleParam = {
    private _percent = ["KFH_ThreatScale", missionNamespace getVariable ["KFH_threatScaleParamDefault", 100]] call BIS_fnc_getParamValue;
    private _multiplier = ((_percent max 50) min 250) / 100;
    missionNamespace setVariable ["KFH_threatScaleMultiplier", _multiplier, true];
    [format ["Threat density scale applied: %1%% multiplier=%2.", _percent, _multiplier]] call KFH_fnc_log;
};

KFH_fnc_applyDifficultyPreset = {
    private _difficulty = ["KFH_Difficulty", missionNamespace getVariable ["KFH_difficultyParamDefault", 1]] call BIS_fnc_getParamValue;
    private _names = missionNamespace getVariable ["KFH_difficultyNames", ["easy", "normal", "hard", "veryHard"]];
    private _index = (_difficulty max 0) min ((count _names) - 1);
    private _name = _names select _index;

    switch (_index) do {
        case 0: {
            KFH_pressureTickValue = 4;
            KFH_reinforcePressure = 7;
            KFH_standardGunnerChance = 0.08;
            KFH_standardHeavyChance = 0.035;
            KFH_rushHeavyChance = 0.08;
            KFH_checkpointSpecialChance = 0.25;
            KFH_checkpointSpecialMaxActive = 3;
            missionNamespace setVariable ["KFH_waveBaseCounts", (KFH_waveBaseCounts apply { ceil (_x * 0.78) })];
            missionNamespace setVariable ["KFH_waveCooldownNormalMinSeconds", 120];
            missionNamespace setVariable ["KFH_waveCooldownNormalMaxSeconds", 130];
            missionNamespace setVariable ["KFH_waveCooldownRushMinSeconds", 140];
            missionNamespace setVariable ["KFH_waveCooldownRushMaxSeconds", 260];
        };
        case 2: {
            KFH_pressureTickValue = 8;
            KFH_reinforcePressure = 13;
            KFH_standardGunnerChance = 0.16;
            KFH_standardHeavyChance = 0.09;
            KFH_rushHeavyChance = 0.16;
            KFH_checkpointSpecialChance = 0.6;
            KFH_checkpointSpecialMaxActive = 6;
            missionNamespace setVariable ["KFH_waveBaseCounts", (KFH_waveBaseCounts apply { ceil (_x * 1.18) })];
            missionNamespace setVariable ["KFH_waveCooldownNormalMinSeconds", 85];
            missionNamespace setVariable ["KFH_waveCooldownNormalMaxSeconds", 95];
            missionNamespace setVariable ["KFH_waveCooldownRushMinSeconds", 85];
            missionNamespace setVariable ["KFH_waveCooldownRushMaxSeconds", 210];
        };
        case 3: {
            KFH_pressureTickValue = 10;
            KFH_reinforcePressure = 16;
            KFH_standardGunnerChance = 0.2;
            KFH_standardHeavyChance = 0.12;
            KFH_rushHeavyChance = 0.2;
            KFH_checkpointSpecialChance = 0.67;
            KFH_checkpointSpecialMaxActive = 7;
            missionNamespace setVariable ["KFH_waveBaseCounts", (KFH_waveBaseCounts apply { ceil (_x * 1.35) })];
            missionNamespace setVariable ["KFH_waveCooldownNormalMinSeconds", 70];
            missionNamespace setVariable ["KFH_waveCooldownNormalMaxSeconds", 85];
            missionNamespace setVariable ["KFH_waveCooldownRushMinSeconds", 70];
            missionNamespace setVariable ["KFH_waveCooldownRushMaxSeconds", 180];
        };
        default {
            missionNamespace setVariable ["KFH_waveBaseCounts", +KFH_waveBaseCounts];
            missionNamespace setVariable ["KFH_waveCooldownNormalMinSeconds", KFH_waveCooldownNormalMinSeconds];
            missionNamespace setVariable ["KFH_waveCooldownNormalMaxSeconds", KFH_waveCooldownNormalMaxSeconds];
            missionNamespace setVariable ["KFH_waveCooldownRushMinSeconds", KFH_waveCooldownRushMinSeconds];
            missionNamespace setVariable ["KFH_waveCooldownRushMaxSeconds", KFH_waveCooldownRushMaxSeconds];
        };
    };

    missionNamespace setVariable ["KFH_difficulty", _name, true];
    [format ["Difficulty preset applied: %1 (%2).", _name, _index]] call KFH_fnc_log;
};

KFH_fnc_serverInit = {
    private _startMarker = "kfh_start";
    private _checkpointMarkers = [] call KFH_fnc_getCheckpointMarkers;
    private _checkpointLimit = missionNamespace getVariable ["KFH_checkpointCount", count _checkpointMarkers];
    if ((count _checkpointMarkers) > _checkpointLimit) then {
        _checkpointMarkers = _checkpointMarkers select [0, _checkpointLimit];
    };

    if !(_startMarker in allMapMarkers) exitWith {
        ["Missing marker: kfh_start"] call KFH_fnc_log;
    };

    private _extractMarker = if ("kfh_extract" in allMapMarkers) then {
        "kfh_extract"
    } else {
        _startMarker
    };
    private _extractionTestModeValue = ["KFH_ExtractionTestMode", missionNamespace getVariable ["KFH_extractionTestModeDefault", 0]] call BIS_fnc_getParamValue;
    private _extractionTestMode = _extractionTestModeValue > 0;
    private _extractionFinaleTestMode = _extractionTestModeValue isEqualTo 2;
    missionNamespace setVariable ["KFH_announcementLanguageIndex", ["KFH_AnnouncementLanguage", missionNamespace getVariable ["KFH_announcementLanguageDefault", 0]] call BIS_fnc_getParamValue];
    private _scalingTestAllies = ["KFH_ScalingTestAllies", missionNamespace getVariable ["KFH_scalingTestAlliesDefault", 0]] call BIS_fnc_getParamValue;
    private _routePoints = +(missionNamespace getVariable ["KFH_dynamicRoutePoints", []]);
    if (missionNamespace getVariable ["KFH_dynamicRouteBuilt", false]) then {
        ["Dynamic route checkpoint safe relocation skipped; generator already validated route spacing."] call KFH_fnc_log;
    } else {
        {
            private _markerName = _x;
            private _markerPos = getMarkerPos _markerName;
            if !([_markerPos, "checkpoint"] call KFH_fnc_isObjectiveAreaSafe) then {
                private _relocated = [_markerPos, "checkpoint", markerDir _markerName] call KFH_fnc_findNearbySafeObjectivePos;
                if !(_relocated isEqualTo _markerPos) then {
                    _markerName setMarkerPos _relocated;
                    if ((count _routePoints) > (_forEachIndex + 1)) then {
                        _routePoints set [_forEachIndex + 1, _relocated];
                    };
                    [format ["Checkpoint marker %1 relocated to safer ground at %2.", _markerName, mapGridPosition _relocated]] call KFH_fnc_log;
                };
            };
        } forEach _checkpointMarkers;
    };
    if (_extractionTestMode) then {
        private _startPos = getMarkerPos _startMarker;
        private _lzDir = markerDir _startMarker;
        private _lzDistance = missionNamespace getVariable ["KFH_extractionTestLzDistance", 140];
        private _candidateLz = _startPos getPos [_lzDistance, _lzDir + 35];
        private _lzPos = [_candidateLz, "extract", _lzDir + 35] call KFH_fnc_findNearbySafeObjectivePos;
        _extractMarker setMarkerPos _lzPos;
        _extractMarker setMarkerAlpha 1;
        [format ["Extraction test mode moved LZ near start: %1.", mapGridPosition _lzPos]] call KFH_fnc_log;
    } else {
        private _extractPos = getMarkerPos _extractMarker;
        private _safeExtract = [_extractPos, "extract", markerDir _extractMarker] call KFH_fnc_findNearbySafeObjectivePos;
        if !(_safeExtract isEqualTo _extractPos) then {
            _extractMarker setMarkerPos _safeExtract;
            [format ["Extraction marker relocated to safer LZ at %1.", mapGridPosition _safeExtract]] call KFH_fnc_log;
        };
    };
    if ((count _routePoints) > 0) then {
        _routePoints set [((count _routePoints) - 1), getMarkerPos _extractMarker];
        missionNamespace setVariable ["KFH_dynamicRoutePoints", _routePoints, true];
    };
    [_extractMarker] call KFH_fnc_refreshExtractSpawnMarkers;
    private _routeMarkers = [_startMarker] + _checkpointMarkers + [_extractMarker];

    if ((count _checkpointMarkers) isEqualTo 0) exitWith {
        ["At least one checkpoint marker named kfh_cp_1 is required."] call KFH_fnc_log;
    };

    [] call KFH_fnc_initRunTelemetry;
    [] call KFH_fnc_configurePvEvERelations;
    [] call KFH_fnc_applyDifficultyPreset;
    [] call KFH_fnc_applyThreatScaleParam;
    [] call KFH_fnc_applyEnemyAccuracyPreset;
    ["start"] call KFH_fnc_playStoryBeatOnce;
    ["KFH_targetPlayers", missionNamespace getVariable ["KFH_targetPlayers", KFH_targetPlayers]] call KFH_fnc_setState;
    missionNamespace setVariable ["KFH_scalingTestAllyCount", _scalingTestAllies, true];
    missionNamespace setVariable ["KFH_scalingTestAllies", [], true];
    missionNamespace setVariable ["KFH_scalingPlayerCountOverride", if (_scalingTestAllies > 0) then { 1 + _scalingTestAllies } else { -1 }, true];
    ["KFH_scalingPlayerCount", [] call KFH_fnc_getScalingPlayerCount] call KFH_fnc_setState;
    ["KFH_extractionTestMode", _extractionTestMode] call KFH_fnc_setState;
    ["KFH_phase", if (_extractionTestMode) then { "extract" } else { "assault" }] call KFH_fnc_setState;
    ["KFH_pressure", 0] call KFH_fnc_setState;
    ["KFH_currentWave", 0] call KFH_fnc_setState;
    ["KFH_rushActive", false] call KFH_fnc_setState;
    ["KFH_currentCheckpoint", if (_extractionTestMode) then { count _checkpointMarkers } else { 1 }] call KFH_fnc_setState;
    ["KFH_totalCheckpoints", count _checkpointMarkers] call KFH_fnc_setState;
    ["KFH_extractMarker", _extractMarker] call KFH_fnc_setState;
    ["KFH_objectiveMarker", if (_extractionTestMode) then { _extractMarker } else { _checkpointMarkers select 0 }] call KFH_fnc_setState;
    ["KFH_objectiveHostiles", 0] call KFH_fnc_setState;
    ["KFH_totalHostiles", 0] call KFH_fnc_setState;
    ["KFH_captureActive", false] call KFH_fnc_setState;
    ["KFH_captureProgress", 0] call KFH_fnc_setState;
    ["KFH_captureLabel", "MOVE"] call KFH_fnc_setState;
    ["KFH_nextWaveAt", time + KFH_reinforceSeconds] call KFH_fnc_setState;
    ["KFH_waveCooldownReason", "initial"] call KFH_fnc_setState;
    ["KFH_combatReadyFriendlies", 0] call KFH_fnc_setState;
    missionNamespace setVariable ["KFH_checkpointMarkers", _checkpointMarkers];
    missionNamespace setVariable ["KFH_routeMarkers", _routeMarkers, true];
    missionNamespace setVariable ["KFH_waveBaseCounts", missionNamespace getVariable ["KFH_waveBaseCounts", +KFH_waveBaseCounts]];
    missionNamespace setVariable ["KFH_enemyClasses", +KFH_enemyClasses];
    missionNamespace setVariable ["KFH_checkpointEventPlan", [_checkpointMarkers] call KFH_fnc_buildCheckpointEventPlan, true];
    missionNamespace setVariable ["KFH_checkpointSecuredStates", _checkpointMarkers apply { _extractionTestMode }, true];
    missionNamespace setVariable ["KFH_checkpointSupplyStates", _checkpointMarkers apply { _extractionTestMode }, true];
    missionNamespace setVariable ["KFH_activeEnemies", []];
    missionNamespace setVariable ["KFH_currentObjectiveEnemies", []];
    missionNamespace setVariable ["KFH_envTrafficGroups", []];
    missionNamespace setVariable ["KFH_ambientTrafficVehicles", [], true];
    missionNamespace setVariable ["KFH_holdStart", -1];
    missionNamespace setVariable ["KFH_extractHoldStart", -1];
    missionNamespace setVariable ["KFH_extractPrepUntil", if (_extractionTestMode) then { time + (missionNamespace getVariable ["KFH_extractionTestPrepSeconds", 5]) } else { -1 }];
    missionNamespace setVariable ["KFH_extractPrepReleased", _extractionTestMode && {(missionNamespace getVariable ["KFH_extractionTestPrepSeconds", 5]) <= 0}];
    missionNamespace setVariable ["KFH_extractPrepAnnounced", []];
    missionNamespace setVariable ["KFH_extractFlareFired", _extractionTestMode, true];
    missionNamespace setVariable ["KFH_extractFlareFiredBy", "", true];
    missionNamespace setVariable ["KFH_extractFlareRequired", if (_extractionTestMode) then { false } else { KFH_extractFlareRequired }, true];
    missionNamespace setVariable ["KFH_extractFlareWarnedAt", -1];
    missionNamespace setVariable ["KFH_extractAutoDepartAt", -1, true];
    missionNamespace setVariable ["KFH_extractAutoDepartWarned", false, true];
    missionNamespace setVariable ["KFH_extractionHeliScheduledAt", -1, true];
    missionNamespace setVariable ["KFH_extractionFinaleRushActive", false, true];
    missionNamespace setVariable ["KFH_extractionFinaleSpecialQueue", [], true];
    missionNamespace setVariable ["KFH_extractionFinaleNextSpecialAt", -1, true];
    missionNamespace setVariable ["KFH_extractionHeli", objNull, true];
    missionNamespace setVariable ["KFH_extractionHelis", [], true];
    missionNamespace setVariable ["KFH_extractionHeliRetryCount", 0, true];
    missionNamespace setVariable ["KFH_extractionPassengersAtDeparture", -1, true];
    missionNamespace setVariable ["KFH_extractionAliveAtDeparture", -1, true];
    missionNamespace setVariable ["KFH_extractionCompleted", false, true];
    missionNamespace setVariable ["KFH_extractionHeliState", "idle", true];
    missionNamespace setVariable ["KFH_extractHelipad", objNull, true];
    missionNamespace setVariable ["KFH_extractHelipads", [], true];
    missionNamespace setVariable ["KFH_extractPressureTickCurrent", KFH_extractPressureTickSeconds];
    missionNamespace setVariable ["KFH_extractReinforceSecondsCurrent", KFH_extractReinforceSeconds];
    missionNamespace setVariable ["KFH_extractReinforcePressureCurrent", KFH_extractReinforcePressure];
    missionNamespace setVariable ["KFH_extractWaveBaseCount", KFH_extractBaseWaveCount];
    missionNamespace setVariable ["KFH_rushActive", false, true];
    missionNamespace setVariable ["KFH_rushCheckpoint", -1, true];
    missionNamespace setVariable ["KFH_rushWaveNumber", -1, true];
    missionNamespace setVariable ["KFH_wipeLocked", false, true];
    missionNamespace setVariable ["KFH_wipePendingSince", -1];
    missionNamespace setVariable ["KFH_initialCombatReleased", false, true];
    missionNamespace setVariable ["KFH_nextPressureAt", time + KFH_pressureTickSeconds];
    missionNamespace setVariable ["KFH_nextPressureEmergencyAt", 0];
    missionNamespace setVariable ["KFH_nextReinforceAt", time + KFH_reinforceSeconds];
    missionNamespace setVariable ["KFH_nextWaveAt", time + KFH_reinforceSeconds, true];
    missionNamespace setVariable ["KFH_nextCheckpointStatusAt", time + 5];
    [_startMarker] call KFH_fnc_spawnSupportFob;
    [_startMarker] call KFH_fnc_spawnPatrolVehicles;
    {
        [_x, _forEachIndex + 1] call KFH_fnc_spawnCheckpointLandmarks;
    } forEach _checkpointMarkers;
    [_startMarker, _checkpointMarkers, _extractMarker] call KFH_fnc_spawnRouteDressing;
    [] call KFH_fnc_updateRouteMarkerVisibility;
    [] call KFH_fnc_refreshStrategicState;
    [getMarkerPos (if (_extractionTestMode) then { _extractMarker } else { _startMarker }), if (_extractionTestMode) then { "Extraction Test LZ" } else { "Start FOB" }] call KFH_fnc_updateRespawnAnchor;
    [format ["Run 開始デス。checkpoint は %1 箇所、extract は %2 デス。", count _checkpointMarkers, _extractMarker], "RUN"] call KFH_fnc_appendRunEvent;
    if (_extractionTestMode) then {
        ["extract_test_active", [], "EXTRACT"] call KFH_fnc_appendRunEventKey;
        ["extract_test_lz_near", [_startMarker]] call KFH_fnc_notifyAllKey;
        [] call KFH_fnc_applyExtractDangerProfile;
        [_extractionFinaleTestMode] spawn {
            params ["_finaleTestMode"];
            sleep (missionNamespace getVariable ["KFH_extractionTestPrepSeconds", 5]);
            missionNamespace setVariable ["KFH_extractPrepReleased", true];
            missionNamespace setVariable ["KFH_extractFlareFired", true, true];
            missionNamespace setVariable ["KFH_extractFlareFiredBy", "Extraction Test", true];
            if (_finaleTestMode) then {
                private _heliDelay = missionNamespace getVariable ["KFH_extractionHeliCallDelaySeconds", 200];
                missionNamespace setVariable ["KFH_extractionHeliScheduledAt", time + _heliDelay, true];
                [] call KFH_fnc_startExtractionFinaleRush;
                [] call KFH_fnc_spawnExtractWave;
                [format ["Extraction finale test started. Angel One ETA %1 seconds.", round _heliDelay]] call KFH_fnc_log;
            } else {
                [] call KFH_fnc_spawnExtractionHeli;
            };
        };
    };

    ["KFH_Patrol_LWH_co10 server init complete."] call KFH_fnc_log;
    [] spawn KFH_fnc_vehicleThreatLoop;
    [] spawn KFH_fnc_envTrafficLoop;
    [] spawn KFH_fnc_meleeDirectorLoop;
    [] spawn KFH_fnc_debugTeammateLoop;
    [] spawn KFH_fnc_scalingTestAllyLoop;
    [] spawn KFH_fnc_debugTeammateReviveLoop;
    [] spawn KFH_fnc_wildSpecialLoop;
    if (!_extractionTestMode) then {
        [] spawn {
            [] call KFH_fnc_waitForInitialCombatReady;
            [1, 1, true] call KFH_fnc_spawnCheckpointWave;
        };
    } else {
        missionNamespace setVariable ["KFH_initialCombatReleased", true, true];
    };

    while { true } do {
        private _phase = missionNamespace getVariable ["KFH_phase", "assault"];

        if (_phase in ["complete", "failed"]) exitWith {};

        private _pressure = missionNamespace getVariable ["KFH_pressure", 0];
        private _activeEnemies = [] call KFH_fnc_pruneActiveEnemies;
        private _combatReadyFriendlies = [] call KFH_fnc_getCombatReadyFriendlies;
        [] call KFH_fnc_trackPlayerReviveTransitions;
        ["KFH_combatReadyFriendlies", count _combatReadyFriendlies] call KFH_fnc_setState;
        private _currentPressureTickSeconds = if (_phase isEqualTo "extract") then {
            missionNamespace getVariable ["KFH_extractPressureTickCurrent", KFH_extractPressureTickSeconds]
        } else {
            KFH_pressureTickSeconds
        };
        private _currentPressureTickValue = if (_phase isEqualTo "extract") then { KFH_extractPressureTickValue } else { KFH_pressureTickValue };
        private _currentReinforceSecondsBase = if (_phase isEqualTo "extract") then {
            missionNamespace getVariable ["KFH_extractReinforceSecondsCurrent", KFH_extractReinforceSeconds]
        } else {
            KFH_reinforceSeconds
        };
        private _currentReinforceSeconds = [_currentReinforceSecondsBase] call KFH_fnc_getPressureReinforceSeconds;
        private _currentReinforcePressure = if (_phase isEqualTo "extract") then {
            missionNamespace getVariable ["KFH_extractReinforcePressureCurrent", KFH_extractReinforcePressure]
        } else {
            KFH_reinforcePressure
        };

        private _wipeCheckArmed = missionNamespace getVariable ["KFH_initialCombatReleased", false];
        if (_wipeCheckArmed && {(count _combatReadyFriendlies) isEqualTo 0}) then {
            private _aliveMonitoredFriendlies = [] call KFH_fnc_getAliveMonitoredFriendlies;
            private _aliveDebugTeammates = [] call KFH_fnc_getAliveDebugTeammates;
            private _hasReviveChance = [] call KFH_fnc_hasReviveChance;
            private _hasRecentDebugGrace = [] call KFH_fnc_hasRecentDebugTeammateGrace;
            private _hasRecentHumanCasualtyGrace = [] call KFH_fnc_hasRecentHumanCasualtyGrace;
            private _wipePendingSince = missionNamespace getVariable ["KFH_wipePendingSince", -1];

            if (_hasReviveChance && {(count _aliveDebugTeammates) > 0 || {_hasRecentDebugGrace} || {_hasRecentHumanCasualtyGrace}}) then {
                missionNamespace setVariable ["KFH_wipePendingSince", -1];
                if (time >= (missionNamespace getVariable ["KFH_nextDebugLastStandLogAt", 0])) then {
                    missionNamespace setVariable ["KFH_nextDebugLastStandLogAt", time + 20];
                    [format [
                        "Wipe blocked: rescue window active. Alive monitored=%1 rescuers=%2 aliveDebug=%3 downedPlayers=%4 recentEcho=%5 recentHumanCasualty=%6 reviveChance=%7.",
                        count _aliveMonitoredFriendlies,
                        count ([] call KFH_fnc_getPotentialRescuers),
                        count _aliveDebugTeammates,
                        count ([] call KFH_fnc_getIncapacitatedPlayers),
                        _hasRecentDebugGrace,
                        _hasRecentHumanCasualtyGrace,
                        _hasReviveChance
                    ]] call KFH_fnc_log;
                };
            } else {
                if (_hasReviveChance) then {
                    if (_wipePendingSince < 0) then {
                        missionNamespace setVariable ["KFH_wipePendingSince", time];
                        [format [
                            "Wipe grace started. Alive monitored=%1 rescuers=%2 aliveDebug=%3 downedPlayers=%4.",
                            count _aliveMonitoredFriendlies,
                            count ([] call KFH_fnc_getPotentialRescuers),
                            count _aliveDebugTeammates,
                            count ([] call KFH_fnc_getIncapacitatedPlayers)
                        ]] call KFH_fnc_log;
                    };

                    if ((time - (missionNamespace getVariable ["KFH_wipePendingSince", time])) >= KFH_wipeGraceSeconds) exitWith {
                        missionNamespace setVariable ["KFH_wipeLocked", true, true];
                        [format [
                            "Wipe detected after rescue grace. Alive monitored=%1 rescuers=%2 aliveDebug=%3 downedPlayers=%4.",
                            count _aliveMonitoredFriendlies,
                            count ([] call KFH_fnc_getPotentialRescuers),
                            count _aliveDebugTeammates,
                            count ([] call KFH_fnc_getIncapacitatedPlayers)
                        ]] call KFH_fnc_log;
                        [false, "The whole team went down. Operation lost."] call KFH_fnc_completeMission;
                    };
                } else {
                    missionNamespace setVariable ["KFH_wipeLocked", true, true];
                    [format [
                        "Wipe detected. Monitored combat-ready=%1 aliveMonitored=%2 rescuers=%3 downedPlayers=%4.",
                        count _combatReadyFriendlies,
                        count _aliveMonitoredFriendlies,
                        count ([] call KFH_fnc_getPotentialRescuers),
                        count ([] call KFH_fnc_getIncapacitatedPlayers)
                    ]] call KFH_fnc_log;
                    [false, "The whole team went down. Operation lost."] call KFH_fnc_completeMission;
                };
            };
        } else {
            missionNamespace setVariable ["KFH_wipePendingSince", -1];
        };

        if (time >= (missionNamespace getVariable ["KFH_nextPressureAt", 0])) then {
            _pressure = (_pressure + _currentPressureTickValue) min KFH_pressureMax;
            ["KFH_pressure", _pressure] call KFH_fnc_setState;
            missionNamespace setVariable ["KFH_nextPressureAt", time + _currentPressureTickSeconds];
        };

        if (_pressure >= KFH_pressureMax) then {
            if (KFH_pressureFailEnabled) exitWith {
                [false, "Hive pressure collapsed the operation."] call KFH_fnc_completeMission;
            };

            if (time >= (missionNamespace getVariable ["KFH_nextPressureEmergencyAt", 0])) then {
                missionNamespace setVariable ["KFH_nextPressureEmergencyAt", time + KFH_pressureEmergencyCooldown];
                _pressure = (KFH_pressureMax - KFH_pressureEmergencyRelief) max 0;
                ["KFH_pressure", _pressure] call KFH_fnc_setState;
                private _nextReinforceAt = missionNamespace getVariable ["KFH_nextReinforceAt", time + KFH_reinforceSeconds];
                missionNamespace setVariable ["KFH_nextReinforceAt", _nextReinforceAt min (time + ([_currentReinforceSecondsBase] call KFH_fnc_getPressureReinforceSeconds))];
                ["Hive Pressure is critical. Rush density is rising, but there is no time-limit fail state."] call KFH_fnc_notifyAll;
                ["Hive Pressure critical intensity vented into the next reinforcement cycle.", "PRESSURE"] call KFH_fnc_appendRunEvent;
            } else {
                _pressure = KFH_pressureMax - 1;
                ["KFH_pressure", _pressure] call KFH_fnc_setState;
            };
        };

        if (_phase isEqualTo "assault") then {
            private _checkpointIndex = missionNamespace getVariable ["KFH_currentCheckpoint", 1];
            private _checkpointMarker = _checkpointMarkers select (_checkpointIndex - 1);
            private _checkpointPos = getMarkerPos _checkpointMarker;
            private _objectiveEnemies = [] call KFH_fnc_getCurrentObjectiveEnemies;
            private _playersNear = ([] call KFH_fnc_getHumanPlayers) select {
                alive _x && ((_x distance2D _checkpointPos) <= KFH_captureRadius)
            };
            private _objectiveThreats = +_objectiveEnemies;
            private _rushActive = missionNamespace getVariable ["KFH_rushActive", false];
            private _rushCheckpoint = missionNamespace getVariable ["KFH_rushCheckpoint", -1];
            private _rushWaveNumber = missionNamespace getVariable ["KFH_rushWaveNumber", -1];
            ["KFH_objectiveHostiles", count _objectiveThreats] call KFH_fnc_setState;

            private _captureActive = (count _playersNear) > 0;
            private _currentWaveHostileCount = missionNamespace getVariable ["KFH_currentWaveHostileCount", count _objectiveThreats];
            private _captureThreatBasis = _currentWaveHostileCount max 1;
            private _captureBaseline = missionNamespace getVariable ["KFH_captureThreatBaseline", -1];
            if (_captureActive) then {
                private _observedThreats = (_currentWaveHostileCount max (count _objectiveThreats)) max 1;
                if (_captureBaseline < _observedThreats) then {
                    _captureBaseline = _observedThreats;
                    missionNamespace setVariable ["KFH_captureThreatBaseline", _captureBaseline, true];
                };
                _captureThreatBasis = _captureBaseline max _observedThreats;
            } else {
                missionNamespace setVariable ["KFH_captureThreatBaseline", -1, true];
            };
            private _captureAllowedRemaining = if (missionNamespace getVariable ["KFH_captureAllowPartialClear", true]) then {
                ceil ((_captureThreatBasis max 1) * (missionNamespace getVariable ["KFH_captureClearRemainingRatio", 0.34]))
            } else {
                0
            };
            private _captureClearEnough = (count _objectiveThreats) <= _captureAllowedRemaining;
            private _captureProgress = 0;
            private _captureLabel = if ((count _playersNear) > 0) then {
                if !(_captureClearEnough) then {
                    format ["CLEAR %1 HOSTILES", count _objectiveThreats]
                } else {
                    format ["SECURING CHECKPOINT %1", _checkpointIndex]
                }
            } else {
                format ["MOVE TO CHECKPOINT %1", _checkpointIndex]
            };

            if ((count _playersNear) > 0) then {
                [_checkpointIndex, _checkpointMarker, count _objectiveThreats] call KFH_fnc_startCheckpointDefenseEvent;
            };

            if (
                _rushActive &&
                {_rushCheckpoint isEqualTo _checkpointIndex} &&
                {(count _objectiveThreats) isEqualTo 0}
            ) then {
                [_checkpointIndex, _rushWaveNumber] call KFH_fnc_grantRushReward;
            };

            private _currentWaveForCooldown = missionNamespace getVariable ["KFH_currentWave", 0];
            private _cooldownAppliedWave = missionNamespace getVariable ["KFH_objectiveClearCooldownAppliedWave", -1];
            if (
                (_currentWaveForCooldown > 0) &&
                {_cooldownAppliedWave isNotEqualTo _currentWaveForCooldown} &&
                {(count _objectiveThreats) isEqualTo 0}
            ) then {
                private _isRushClear = _rushActive && {_rushCheckpoint isEqualTo _checkpointIndex};
                private _clearCooldown = [_isRushClear] call KFH_fnc_calculateWaveClearCooldown;
                [_clearCooldown, if (_isRushClear) then { "rush cleared" } else { "wave cleared" }] call KFH_fnc_applyWaveCooldown;
                missionNamespace setVariable ["KFH_objectiveClearCooldownAppliedWave", _currentWaveForCooldown, true];
            };

            if (
                _captureActive &&
                {_captureClearEnough} &&
                {time >= (missionNamespace getVariable ["KFH_nextReinforceAt", 0])}
            ) then {
                private _pauseUntil = time + (missionNamespace getVariable ["KFH_captureWavePauseSeconds", 35]);
                missionNamespace setVariable ["KFH_nextReinforceAt", _pauseUntil];
                missionNamespace setVariable ["KFH_nextWaveAt", _pauseUntil, true];
            };

            if (
                time >= (missionNamespace getVariable ["KFH_nextReinforceAt", 0]) &&
                {!(_captureActive && {_captureClearEnough})}
            ) then {
                [_checkpointIndex, 0.75 * ([] call KFH_fnc_getPressureSpawnMultiplier)] call KFH_fnc_spawnCheckpointWave;
                _pressure = ((_pressure + _currentReinforcePressure) min KFH_pressureMax);
                ["KFH_pressure", _pressure] call KFH_fnc_setState;
                missionNamespace setVariable ["KFH_nextReinforceAt", time + _currentReinforceSeconds];
                missionNamespace setVariable ["KFH_nextWaveAt", time + _currentReinforceSeconds, true];
            };

            if (time >= (missionNamespace getVariable ["KFH_nextCheckpointStatusAt", 0])) then {
                private _statusLine = format [
                    "Checkpoint %1 status: players=%2 hostiles=%3 grid=%4",
                    _checkpointIndex,
                    count _playersNear,
                    count _objectiveThreats,
                    mapGridPosition _checkpointPos
                ];
                if (missionNamespace getVariable ["KFH_showCheckpointStatusChat", false]) then {
                    [_statusLine] call KFH_fnc_notifyAll;
                } else {
                    [_statusLine] call KFH_fnc_log;
                };
                missionNamespace setVariable ["KFH_nextCheckpointStatusAt", time + KFH_checkpointStatusInterval];
            };

            if ((count _playersNear) > 0 && {_captureClearEnough}) then {
                private _holdStart = missionNamespace getVariable ["KFH_holdStart", -1];

                if (_holdStart < 0) then {
                    missionNamespace setVariable ["KFH_holdStart", time];
                    _holdStart = time;
                    if ((count _objectiveThreats) > 0) then {
                        ["checkpoint_secure_window_started_suppressed", [count _objectiveThreats]] call KFH_fnc_notifyAllKey;
                    } else {
                        ["checkpoint_secure_window_started_clear"] call KFH_fnc_notifyAllKey;
                    };
                };

                _captureProgress = (((time - _holdStart) / KFH_holdSeconds) max 0) min 1;

                if ((time - (missionNamespace getVariable ["KFH_holdStart", time])) >= KFH_holdSeconds) then {
                    [_checkpointIndex, _checkpointMarker, _pressure] call KFH_fnc_onCheckpointSecured;
                    missionNamespace setVariable ["KFH_holdStart", -1];
                    missionNamespace setVariable ["KFH_captureThreatBaseline", -1, true];

                    if (_checkpointIndex >= (count _checkpointMarkers)) then {
                        ["KFH_phase", "extract"] call KFH_fnc_setState;
                        [getMarkerPos _checkpointMarker, "Final Checkpoint"] call KFH_fnc_updateRespawnAnchor;
                        [] call KFH_fnc_updateRouteMarkerVisibility;
                        [] call KFH_fnc_applyExtractDangerProfile;
                        missionNamespace setVariable ["KFH_nextPressureAt", time + (missionNamespace getVariable ["KFH_extractPressureTickCurrent", KFH_extractPressureTickSeconds])];
                        missionNamespace setVariable ["KFH_nextReinforceAt", time + KFH_finalArsenalCooldownSeconds];
                        missionNamespace setVariable ["KFH_nextWaveAt", time + KFH_finalArsenalCooldownSeconds, true];
                        missionNamespace setVariable ["KFH_extractPrepUntil", time + KFH_finalPrepSeconds];
                        missionNamespace setVariable ["KFH_extractPrepReleased", false];
                        missionNamespace setVariable ["KFH_extractPrepAnnounced", []];
                        missionNamespace setVariable ["KFH_extractionHeliScheduledAt", -1, true];
                        missionNamespace setVariable ["KFH_extractionFinaleRushActive", false, true];
                        missionNamespace setVariable ["KFH_extractionFinaleSpecialQueue", [], true];
                        missionNamespace setVariable ["KFH_extractionFinaleNextSpecialAt", -1, true];
                        [format [
                            "Final checkpoint secure. Arsenal online. You have %1 seconds to prepare before falling back to %2.",
                            KFH_finalPrepSeconds,
                            _extractMarker
                        ]] call KFH_fnc_notifyAll;
                        ["extractReleased", _checkpointIndex] call KFH_fnc_playStoryBeatOnce;
                    } else {
                        ["KFH_currentCheckpoint", _checkpointIndex + 1] call KFH_fnc_setState;
                        ["KFH_objectiveMarker", _checkpointMarkers select _checkpointIndex] call KFH_fnc_setState;
                        private _nextSecureCooldown = [_checkpointIndex] call KFH_fnc_getCheckpointSecureCooldown;
                        missionNamespace setVariable ["KFH_nextReinforceAt", time + _nextSecureCooldown];
                        missionNamespace setVariable ["KFH_nextWaveAt", time + _nextSecureCooldown, true];
                        missionNamespace setVariable ["KFH_nextCheckpointStatusAt", time + 5];
                        [] call KFH_fnc_updateRouteMarkerVisibility;
                        [] call KFH_fnc_refreshStrategicState;
                        [format ["Advance to checkpoint %1.", _checkpointIndex + 1]] call KFH_fnc_notifyAll;
                    };
                };
            } else {
                missionNamespace setVariable ["KFH_holdStart", -1];
            };

            ["KFH_captureActive", _captureActive] call KFH_fnc_setState;
            ["KFH_captureProgress", _captureProgress] call KFH_fnc_setState;
            ["KFH_captureLabel", _captureLabel] call KFH_fnc_setState;
        };

        if (_phase isEqualTo "extract") then {
            private _extractPrepUntil = missionNamespace getVariable ["KFH_extractPrepUntil", -1];
            private _extractPrepActive = (_extractPrepUntil > 0) && {time < _extractPrepUntil};

            if (_extractPrepActive) then {
                private _remaining = round (_extractPrepUntil - time);
                private _announced = missionNamespace getVariable ["KFH_extractPrepAnnounced", []];

                if ((_remaining in [20, 10, 5]) && {!(_remaining in _announced)}) then {
                    _announced pushBack _remaining;
                    missionNamespace setVariable ["KFH_extractPrepAnnounced", _announced];
                    ["extract_prep_remaining", [_remaining]] call KFH_fnc_notifyAllKey;
                };
            } else {
                if (
                    (_extractPrepUntil > 0) &&
                    {!(missionNamespace getVariable ["KFH_extractPrepReleased", false])}
                ) then {
                    missionNamespace setVariable ["KFH_extractPrepReleased", true];
                    ["prep_window_over", [_extractMarker]] call KFH_fnc_notifyAllKey;
                };
            };

            private _extractPos = getMarkerPos _extractMarker;
            private _alivePlayers = ([] call KFH_fnc_getHumanPlayers) select { alive _x };
            private _playersInExtract = _alivePlayers select {
                (_x distance2D _extractPos) <= KFH_captureRadius
            };
            private _flareRequired = missionNamespace getVariable ["KFH_extractFlareRequired", KFH_extractFlareRequired];
            private _flareReady = missionNamespace getVariable ["KFH_extractFlareFired", false];
            private _helis = [] call KFH_fnc_getExtractionHelis;
            private _heli = if ((count _helis) > 0) then { _helis select 0 } else { objNull };
            private _heliScheduledAt = missionNamespace getVariable ["KFH_extractionHeliScheduledAt", -1];
            private _heliEta = if (_heliScheduledAt >= 0) then { (_heliScheduledAt - time) max 0 } else { -1 };
            private _extractCaptureActive = !_extractPrepActive && {(count _playersInExtract) > 0};
            private _extractCaptureProgress = 0;
            private _extractCaptureLabel = if (_extractPrepActive) then {
                format ["PREP %1s", round (_extractPrepUntil - time)]
            } else {
                if (_flareRequired && {!_flareReady}) then {
                    "FIRE FLARE AT LZ"
                } else {
                    if ((count _helis) isEqualTo 0) then {
                        if (_heliEta >= 0) then {
                            format ["HELI ETA %1s", ceil _heliEta]
                        } else {
                            "AWAITING HELI"
                        }
                    } else {
                        format ["BOARD HELI %1/%2", count ([_alivePlayers, _helis] call KFH_fnc_getExtractionBoardedPlayers), count _alivePlayers]
                    }
                }
            };

            if (!_extractPrepActive && {_flareRequired} && {!_flareReady}) then {
                private _warnedAt = missionNamespace getVariable ["KFH_extractFlareWarnedAt", -1];
                if ((time - _warnedAt) >= KFH_extractFlareReminderSeconds) then {
                    missionNamespace setVariable ["KFH_extractFlareWarnedAt", time];
                    if ([] call KFH_fnc_teamHasFlareCapability) then {
                        ["fire_flare_now"] call KFH_fnc_notifyAllKey;
                    } else {
                        ["no_flare_capability"] call KFH_fnc_notifyAllKey;
                    };
                };
                missionNamespace setVariable ["KFH_extractHoldStart", -1];
            } else {
                private _boardedPlayers = [_alivePlayers, _helis] call KFH_fnc_getExtractionBoardedPlayers;
                private _approachHelis = _helis select {
                    (_x getVariable ["KFH_extractionHeliState", "Init"]) in ["Init", "Approach", "ApproachActive", "Land"]
                };
                private _waitHelis = _helis select {
                    (_x getVariable ["KFH_extractionHeliState", "Init"]) isEqualTo "WaitForPlayers"
                };
                private _evacHelis = _helis select {
                    (_x getVariable ["KFH_extractionHeliState", "Init"]) in ["Evac", "EvacActive"]
                };
                private _autoDepartAt = missionNamespace getVariable ["KFH_extractAutoDepartAt", -1];
                private _autoDepartRemaining = if (_autoDepartAt >= 0) then {
                    ((_autoDepartAt - time) max 0)
                } else {
                    -1
                };

                _extractCaptureLabel = if (_extractPrepActive) then {
                    format ["PREP %1s", round (_extractPrepUntil - time)]
                } else {
                    if ((count _helis) isEqualTo 0 || {(count _approachHelis) > 0} || {((count _waitHelis) < (count _helis)) && {(count _evacHelis) isEqualTo 0}}) then {
                        if ((count _helis) isEqualTo 0 && {_heliEta >= 0}) then {
                            format ["HELI ETA %1s", ceil _heliEta]
                        } else {
                            "HELI INBOUND"
                        }
                    } else {
                        if ((count _evacHelis) > 0 && {(count _waitHelis) isEqualTo 0}) then {
                            "HELI DEPARTING"
                        } else {
                            if ((count _waitHelis) > 0 && {_autoDepartRemaining >= 0}) then {
                                format ["BOARD HELI %1/%2 | AUTO %3s", count _boardedPlayers, count _alivePlayers, ceil _autoDepartRemaining]
                            } else {
                                format ["BOARD HELI %1/%2", count _boardedPlayers, count _alivePlayers]
                            }
                        }
                    }
                };

                if (
                    ((count _helis) > 0) &&
                    {(count _waitHelis) isEqualTo (count _helis)} &&
                    {(count _alivePlayers) > 0} &&
                    {(count _boardedPlayers) isEqualTo (count _alivePlayers)}
                ) then {
                    private _extractHoldStart = missionNamespace getVariable ["KFH_extractHoldStart", -1];

                    if (_extractHoldStart < 0) then {
                        missionNamespace setVariable ["KFH_extractHoldStart", time];
                        _extractHoldStart = time;
                        ["angel_one_lift_moment"] call KFH_fnc_notifyAllKey;
                    };

                    _extractCaptureProgress = (((time - _extractHoldStart) / KFH_extractHoldSeconds) max 0) min 1;
                    _extractCaptureLabel = "LIFTING OFF";

                    if ((time - (missionNamespace getVariable ["KFH_extractHoldStart", time])) >= KFH_extractHoldSeconds) then {
                        [_helis, "all_boarded", count _boardedPlayers, count _alivePlayers] call KFH_fnc_triggerExtractionDeparture;
                    };
                } else {
                    missionNamespace setVariable ["KFH_extractHoldStart", -1];

                    if (
                        ((count _helis) > 0) &&
                        {(count _waitHelis) isEqualTo (count _helis)} &&
                        {_autoDepartAt >= 0}
                    ) then {
                        _extractCaptureProgress = if (KFH_extractBoardTimeoutSeconds > 0) then {
                            (((KFH_extractBoardTimeoutSeconds - _autoDepartRemaining) / KFH_extractBoardTimeoutSeconds) max 0) min 1
                        } else {
                            0
                        };

                        if (
                            _autoDepartRemaining <= KFH_extractBoardWarnSeconds &&
                            {!(missionNamespace getVariable ["KFH_extractAutoDepartWarned", false])}
                        ) then {
                            missionNamespace setVariable ["KFH_extractAutoDepartWarned", true, true];
                            ["angel_one_depart_warn", [ceil _autoDepartRemaining]] call KFH_fnc_notifyAllKey;
                        };

                        if (_autoDepartRemaining <= 0) then {
                            [_helis, "timeout", count _boardedPlayers, count _alivePlayers] call KFH_fnc_triggerExtractionDeparture;
                            _extractCaptureLabel = "HELI DEPARTING";
                            _extractCaptureProgress = 1;
                        };
                    };
                };
            };

            ["KFH_captureActive", _extractCaptureActive] call KFH_fnc_setState;
            ["KFH_captureProgress", _extractCaptureProgress] call KFH_fnc_setState;
            ["KFH_captureLabel", _extractCaptureLabel] call KFH_fnc_setState;

            if (!_extractPrepActive && {_flareReady}) then {
                [] call KFH_fnc_tickExtractionFinaleRush;
                if ((count _helis) isEqualTo 0 && {_heliScheduledAt >= 0} && {time >= _heliScheduledAt}) then {
                    missionNamespace setVariable ["KFH_extractionHeliScheduledAt", -1, true];
                    [] call KFH_fnc_spawnExtractionHeli;
                };
            };

            if (!_extractPrepActive && {time >= (missionNamespace getVariable ["KFH_nextReinforceAt", 0])}) then {
                [] call KFH_fnc_spawnExtractWave;
                _pressure = ((_pressure + _currentReinforcePressure) min KFH_pressureMax);
                ["KFH_pressure", _pressure] call KFH_fnc_setState;
                missionNamespace setVariable ["KFH_nextReinforceAt", time + _currentReinforceSeconds];
                missionNamespace setVariable ["KFH_nextWaveAt", time + _currentReinforceSeconds, true];
            };
        };

        sleep 1;
    };
};

KFH_fnc_buildTextBar = {
    params [
        ["_ratio", 0],
        ["_segments", 22]
    ];

    private _clamped = (_ratio max 0) min 1;
    private _filled = round (_clamped * _segments);
    private _empty = _segments - _filled;
    private _bar = "";

    for "_i" from 1 to _filled do {
        _bar = _bar + "#";
    };

    for "_i" from 1 to _empty do {
        _bar = _bar + "-";
    };

    _bar
};

KFH_fnc_ensureTopHudControls = {
    private _display = findDisplay 46;
    if (isNull _display) exitWith { false };

    private _panel = uiNamespace getVariable ["KFH_topHudPanel", controlNull];
    private _text = uiNamespace getVariable ["KFH_topHudText", controlNull];
    private _barBack = uiNamespace getVariable ["KFH_topHudBarBack", controlNull];
    private _barFill = uiNamespace getVariable ["KFH_topHudBarFill", controlNull];

    if (isNull _panel) then {
        _panel = _display ctrlCreate ["RscText", -1];
        uiNamespace setVariable ["KFH_topHudPanel", _panel];
    };
    if !(isNull _panel) then {
        _panel ctrlSetBackgroundColor [0, 0, 0, 0.58];
        _panel ctrlSetPosition [
            safeZoneX + safeZoneW * 0.365,
            safeZoneY + safeZoneH * 0.024,
            safeZoneW * 0.27,
            safeZoneH * 0.067
        ];
        _panel ctrlCommit 0;
    };

    if (isNull _text) then {
        _text = _display ctrlCreate ["RscStructuredText", -1];
        uiNamespace setVariable ["KFH_topHudText", _text];
    };
    if !(isNull _text) then {
        _text ctrlSetBackgroundColor [0, 0, 0, 0];
        _text ctrlSetPosition [
            safeZoneX + safeZoneW * 0.37,
            safeZoneY + safeZoneH * 0.029,
            safeZoneW * 0.26,
            safeZoneH * 0.05
        ];
        _text ctrlCommit 0;
    };

    if (isNull _barBack) then {
        _barBack = _display ctrlCreate ["RscText", -1];
        uiNamespace setVariable ["KFH_topHudBarBack", _barBack];
    };

    if (isNull _barFill) then {
        _barFill = _display ctrlCreate ["RscText", -1];
        uiNamespace setVariable ["KFH_topHudBarFill", _barFill];
    };

    true
};

KFH_fnc_clientTopHudLoop = {
    waitUntil { !isNull findDisplay 46 };

    while { true } do {
        if ([] call KFH_fnc_ensureTopHudControls) then {
            private _phase = missionNamespace getVariable ["KFH_phase", "boot"];
            private _wave = missionNamespace getVariable ["KFH_currentWave", 0];
            private _objectiveHostiles = missionNamespace getVariable ["KFH_objectiveHostiles", 0];
            private _totalHostiles = missionNamespace getVariable ["KFH_totalHostiles", 0];
            private _rushActive = missionNamespace getVariable ["KFH_rushActive", false];
            private _wavesUntilRush = [] call KFH_fnc_getWavesUntilRush;
            private _captureProgress = missionNamespace getVariable ["KFH_captureProgress", 0];
            private _captureLabel = missionNamespace getVariable ["KFH_captureLabel", ""];
            private _captureActive = missionNamespace getVariable ["KFH_captureActive", false];
            private _storyObjective = missionNamespace getVariable ["KFH_storyObjective", "RETURN TO BASE"];
            private _pressure = missionNamespace getVariable ["KFH_pressure", 0];
            private _checkpoint = missionNamespace getVariable ["KFH_currentCheckpoint", 0];
            private _totalCheckpoints = missionNamespace getVariable ["KFH_totalCheckpoints", 0];
            private _checkpointValue = missionNamespace getVariable ["KFH_currentCheckpointValue", "LOW"];
            private _returnDangerLabel = missionNamespace getVariable ["KFH_returnDangerLabel", "LOW"];
            private _nextWaveAt = missionNamespace getVariable ["KFH_nextWaveAt", time];
            private _nextWaveRemaining = ceil ((_nextWaveAt - time) max 0);
            private _rushLabel = if (_rushActive) then {
                "<t color='#ffb347'>RUSH ACTIVE</t>"
            } else {
                if (_wavesUntilRush <= 1) then {
                    "<t color='#ff6f61'>RUSH SOON</t>"
                } else {
                    format ["Rush in %1", _wavesUntilRush]
                }
            };
            private _showCaptureBar = _captureActive && {_captureProgress > 0.001};
            private _barColor = if (_showCaptureBar) then { [0.86, 0.58, 0.12, 0.96] } else { [0.25, 0.25, 0.25, 0.65] };
            private _text = uiNamespace getVariable ["KFH_topHudText", controlNull];
            private _barBack = uiNamespace getVariable ["KFH_topHudBarBack", controlNull];
            private _barFill = uiNamespace getVariable ["KFH_topHudBarFill", controlNull];
            private _barWidth = safeZoneW * 0.24 * ((_captureProgress max 0) min 1);

            private _hudText = parseText format [
                "<t align='center' size='0.92' font='PuristaBold'>WAVE %1 | NEXT %9s | %8</t><br/><t align='center' size='0.62'>CP %10/%11 %12 | Hostiles %3/%4 | Pressure %5/%6 | %2</t><br/><t align='center' size='0.58' color='#ffd166'>%7</t>",
                _wave,
                _rushLabel,
                _objectiveHostiles,
                _totalHostiles,
                _pressure,
                KFH_pressureMax,
                _captureLabel,
                _storyObjective,
                _nextWaveRemaining,
                _checkpoint,
                _totalCheckpoints,
                _checkpointValue,
                _returnDangerLabel
            ];
            _text ctrlSetStructuredText _hudText;

            if (_showCaptureBar) then {
                _barBack ctrlShow true;
                _barFill ctrlShow true;
                _barBack ctrlSetBackgroundColor [0.15, 0.15, 0.15, 0.78];
                _barBack ctrlSetPosition [
                    safeZoneX + safeZoneW * 0.38,
                    safeZoneY + safeZoneH * 0.082,
                    safeZoneW * 0.24,
                    safeZoneH * 0.006
                ];
                _barBack ctrlCommit 0;

                _barFill ctrlSetBackgroundColor _barColor;
                _barFill ctrlSetPosition [
                    safeZoneX + safeZoneW * 0.38,
                    safeZoneY + safeZoneH * 0.082,
                    _barWidth,
                    safeZoneH * 0.006
                ];
                _barFill ctrlCommit 0;
            } else {
                _barBack ctrlShow false;
                _barFill ctrlShow false;
                _barBack ctrlSetBackgroundColor [0, 0, 0, 0];
                _barBack ctrlCommit 0;
                _barFill ctrlSetBackgroundColor [0, 0, 0, 0];
                _barFill ctrlSetPosition [
                    safeZoneX + safeZoneW * 0.38,
                    safeZoneY + safeZoneH * 0.082,
                    0,
                    safeZoneH * 0.006
                ];
                _barFill ctrlCommit 0;
            };
        };

        if ((missionNamespace getVariable ["KFH_phase", "boot"]) in ["complete", "failed"]) exitWith {};

        sleep KFH_topHudUpdateSeconds;
    };
};

KFH_fnc_clientHudLoop = {
    while { true } do {
        private _phase = missionNamespace getVariable ["KFH_phase", "boot"];
        private _checkpoint = missionNamespace getVariable ["KFH_currentCheckpoint", 0];
        private _total = missionNamespace getVariable ["KFH_totalCheckpoints", 0];
        private _pressure = missionNamespace getVariable ["KFH_pressure", 0];
        private _checkpointEvent = missionNamespace getVariable ["KFH_currentCheckpointEvent", "NONE"];
        private _checkpointValue = missionNamespace getVariable ["KFH_currentCheckpointValue", "LOW"];
        private _storyObjective = missionNamespace getVariable ["KFH_storyObjective", "RETURN TO BASE"];
        private _supplyLineStatus = missionNamespace getVariable ["KFH_supplyLineStatus", "0/0 ONLINE"];
        private _returnDangerLabel = missionNamespace getVariable ["KFH_returnDangerLabel", "LOW"];
        private _targetPlayers = missionNamespace getVariable ["KFH_targetPlayers", 10];
        private _alive = count (([] call KFH_fnc_getHumanPlayers) select { alive _x });
        private _downed = count ([] call KFH_fnc_getIncapacitatedPlayers);
        private _phaseLabel = toUpper _phase;
        private _pressureColor = if (_pressure >= 75) then {
            "#ff6b4a"
        } else {
            if (_pressure >= 45) then { "#ffd166" } else { "#86f7a7" }
        };
        private _dangerColor = switch (_returnDangerLabel) do {
            case "HIGH": { "#ff6b4a" };
            case "MED": { "#ffd166" };
            default { "#86f7a7" };
        };
        private _objectiveColor = switch (_storyObjective) do {
            case "BASE LOST": { "#ff6b4a" };
            case "ARSENAL OPTIONAL": { "#ffd166" };
            case "REACH LZ": { "#7bdff2" };
            default { "#ffffff" };
        };

        private _hudText = format [
            "<t font='PuristaBold' size='1.18' color='#f2f2f2'>KFH_Patrol_LWH_co10</t><br/>" +
            "<t size='0.78' color='#9fb3c8'>%1</t><br/>" +
            "<t size='0.96' color='%14'>%2</t><br/><br/>" +
            "<t size='0.84' color='#9fb3c8'>ROUTE</t> <t size='0.9' color='#ffffff'>CP %3/%4</t><br/>" +
            "<t size='0.84' color='#9fb3c8'>EVENT</t> <t size='0.9' color='#ffffff'>%5</t> <t color='#9fb3c8'>(%6)</t><br/>" +
            "<t size='0.84' color='#9fb3c8'>SUPPLY</t> <t size='0.9' color='#ffffff'>%7</t><br/>" +
            "<t size='0.84' color='#9fb3c8'>RETURN</t> <t size='0.9' color='%13'>%8</t><br/>" +
            "<t size='0.84' color='#9fb3c8'>HIVE</t> <t size='0.9' color='%12'>%9/%10</t><br/><br/>" +
            "<t size='0.84' color='#9fb3c8'>TEAM</t> <t size='0.9' color='#ffffff'>%11/%15 alive</t> <t color='#ff9f9f'>%16 down</t>",
            _phaseLabel,
            _storyObjective,
            _checkpoint,
            _total,
            _checkpointEvent,
            _checkpointValue,
            _supplyLineStatus,
            _returnDangerLabel,
            _pressure,
            KFH_pressureMax,
            _alive,
            _pressureColor,
            _dangerColor,
            _objectiveColor,
            _targetPlayers,
            _downed
        ];
        hintSilent parseText _hudText;

        if (_phase in ["complete", "failed"]) exitWith {};

        sleep (missionNamespace getVariable ["KFH_rightHudUpdateSeconds", 0.5]);
    };
};

KFH_fnc_clientLoadoutTracker = {
    while { true } do {
        if (!isNull player && alive player && !([player] call KFH_fnc_isIncapacitated)) then {
            [player] call KFH_fnc_updateSavedLoadout;

            private _cleanupUntil = missionNamespace getVariable ["KFH_reviveCleanupUntil", -1];
            if (_cleanupUntil > 0) then {
                if (time <= _cleanupUntil) then {
                    [] call KFH_fnc_restoreLocalPlayerControl;
                } else {
                    missionNamespace setVariable ["KFH_reviveCleanupUntil", -1];
                };
            };

            private _blurUntil = missionNamespace getVariable ["KFH_postReviveBlurUntil", -1];
            if (_blurUntil > 0) then {
                private _clearDamage = missionNamespace getVariable ["KFH_postReviveBlurClearDamage", 0.25];
                if (time >= _blurUntil || {(damage player) <= _clearDamage}) then {
                    [] call KFH_fnc_clearReviveVisualEffectsLocal;
                };
            };
        };

        if ((missionNamespace getVariable ["KFH_phase", "boot"]) in ["complete", "failed"]) exitWith {};

        sleep KFH_loadoutTrackSeconds;
    };
};

KFH_fnc_getSpectatorTargets = {
    private _targets = (([] call KFH_fnc_getHumanPlayers) + (units group player)) arrayIntersect (([] call KFH_fnc_getHumanPlayers) + (units group player));

    _targets select {
        _x != player &&
        alive _x &&
        !([_x] call KFH_fnc_isIncapacitated)
    }
};

KFH_fnc_pickSpectatorTarget = {
    private _targets = [] call KFH_fnc_getSpectatorTargets;

    if ((count _targets) isEqualTo 0) exitWith { objNull };

    private _current = missionNamespace getVariable ["KFH_spectatorTarget", objNull];
    if (!isNull _current && {_current in _targets}) exitWith { _current };

    private _closest = objNull;
    private _closestDistance = 1e10;

    {
        private _distance = player distance2D _x;
        if (_distance < _closestDistance) then {
            _closest = _x;
            _closestDistance = _distance;
        };
    } forEach _targets;

    _closest
};

KFH_fnc_cycleSpectatorTarget = {
    params [["_direction", 1]];

    private _targets = [] call KFH_fnc_getSpectatorTargets;
    if ((count _targets) isEqualTo 0) exitWith { objNull };

    private _current = missionNamespace getVariable ["KFH_spectatorTarget", objNull];
    private _index = _targets find _current;
    if (_index < 0) then {
        _index = if (_direction >= 0) then { -1 } else { 0 };
    };

    _index = (_index + _direction + (count _targets)) mod (count _targets);
    private _target = _targets select _index;
    missionNamespace setVariable ["KFH_spectatorTarget", _target];
    [format ["Spectating %1", name _target]] call KFH_fnc_localNotify;
    _target
};

KFH_fnc_installDownedSpectatorInput = {
    if (!hasInterface) exitWith {};
    if ((missionNamespace getVariable ["KFH_spectatorMouseEh", -1]) >= 0) exitWith {};

    private _display = findDisplay 46;
    if (isNull _display) exitWith {};

    private _handler = _display displayAddEventHandler ["MouseButtonDown", {
        params ["_display", "_button"];
        if !(missionNamespace getVariable ["KFH_spectatorActive", false]) exitWith { false };
        if (_button isEqualTo 0) exitWith {
            [1] call KFH_fnc_cycleSpectatorTarget;
            true
        };
        if (_button isEqualTo 1) exitWith {
            [-1] call KFH_fnc_cycleSpectatorTarget;
            true
        };
        false
    }];
    missionNamespace setVariable ["KFH_spectatorMouseEh", _handler];
};

KFH_fnc_removeDownedSpectatorInput = {
    private _handler = missionNamespace getVariable ["KFH_spectatorMouseEh", -1];
    if (_handler < 0) exitWith {};
    private _display = findDisplay 46;
    if !(isNull _display) then {
        _display displayRemoveEventHandler ["MouseButtonDown", _handler];
    };
    missionNamespace setVariable ["KFH_spectatorMouseEh", -1];
};

KFH_fnc_startDownedSpectator = {
    if (missionNamespace getVariable ["KFH_spectatorActive", false]) exitWith {};

    private _camera = "camera" camCreate (getPosATL player);
    _camera cameraEffect ["INTERNAL", "BACK"];
    showCinemaBorder false;
    missionNamespace setVariable ["KFH_spectatorCamera", _camera];
    missionNamespace setVariable ["KFH_spectatorActive", true];
    [] call KFH_fnc_installDownedSpectatorInput;
    ["Downed spectator active. Camera will follow a living ally."] call KFH_fnc_localNotify;
};

KFH_fnc_stopDownedSpectator = {
    if !(missionNamespace getVariable ["KFH_spectatorActive", false]) exitWith {};

    private _camera = missionNamespace getVariable ["KFH_spectatorCamera", objNull];

    if !(isNull _camera) then {
        _camera cameraEffect ["TERMINATE", "BACK"];
        camDestroy _camera;
    };

    missionNamespace setVariable ["KFH_spectatorCamera", objNull];
    missionNamespace setVariable ["KFH_spectatorTarget", objNull];
    missionNamespace setVariable ["KFH_spectatorActive", false];
    [] call KFH_fnc_removeDownedSpectatorInput;
};

KFH_fnc_updateDownedSpectator = {
    private _camera = missionNamespace getVariable ["KFH_spectatorCamera", objNull];
    if (isNull _camera) exitWith {};

    private _target = [] call KFH_fnc_pickSpectatorTarget;
    if (isNull _target) exitWith {};

    missionNamespace setVariable ["KFH_spectatorTarget", _target];

    _camera camSetTarget _target;
    _camera camSetPos (_target modelToWorldVisual [0, -4.2, 2.0]);
    _camera camCommit 0;
};

KFH_fnc_downedSpectatorLoop = {
    while { true } do {
        waitUntil { !isNull player };

        if ([player] call KFH_fnc_isIncapacitated) then {
            [] call KFH_fnc_startDownedSpectator;
            [] call KFH_fnc_updateDownedSpectator;
        } else {
            [] call KFH_fnc_stopDownedSpectator;
        };

        if ((missionNamespace getVariable ["KFH_phase", "boot"]) in ["complete", "failed"]) exitWith {
            [] call KFH_fnc_stopDownedSpectator;
        };

        sleep 0.2;
    };
};

KFH_fnc_clientPlayerPositionMarkerLoop = {
    waitUntil { !isNull player };

    private _markerName = format ["KFH_local_player_pos_%1", floor random 1000000];
    private _marker = createMarkerLocal [_markerName, getPosATL player];
    _marker setMarkerTypeLocal "mil_arrow2";
    _marker setMarkerColorLocal "ColorBLUFOR";
    _marker setMarkerTextLocal "YOU";
    _marker setMarkerSizeLocal [0.75, 0.75];

    while { true } do {
        if ((missionNamespace getVariable ["KFH_phase", "boot"]) in ["complete", "failed"]) exitWith {};

        private _hasNavigation = ("ItemGPS" in assignedItems player) || {"ItemMap" in assignedItems player};
        if ((missionNamespace getVariable ["KFH_playerPositionMarkerEnabled", true]) && {_hasNavigation} && {alive player}) then {
            _marker setMarkerPosLocal (getPosATL player);
            _marker setMarkerDirLocal (getDirVisual player);
            _marker setMarkerAlphaLocal 1;
        } else {
            _marker setMarkerAlphaLocal 0;
        };

        sleep 0.35;
    };

    deleteMarkerLocal _marker;
};

KFH_fnc_showTacticalPingLocal = {
    params ["_pos", ["_senderName", "Team"], ["_pingId", floor random 1000000]];

    if ((count _pos) < 2) exitWith {};

    private _markerName = format ["KFH_ping_%1", _pingId];
    private _marker = createMarkerLocal [_markerName, _pos];
    _marker setMarkerTypeLocal "mil_warning";
    _marker setMarkerColorLocal (missionNamespace getVariable ["KFH_tacticalPingMarkerColor", "ColorOrange"]);
    _marker setMarkerTextLocal format ["PING %1", _senderName];
    _marker setMarkerSizeLocal [0.95, 0.95];
    [format ["%1 pinged %2.", _senderName, mapGridPosition _pos]] call KFH_fnc_localNotify;

    [_markerName] spawn {
        params ["_markerName"];
        sleep (missionNamespace getVariable ["KFH_tacticalPingLifetime", 45]);
        deleteMarkerLocal _markerName;
    };
};

KFH_fnc_broadcastTacticalPing = {
    params ["_pos", ["_senderName", "Team"]];

    if (!isServer) exitWith {
        [_pos, _senderName] remoteExecCall ["KFH_fnc_broadcastTacticalPing", 2];
    };

    private _pingId = (missionNamespace getVariable ["KFH_nextTacticalPingId", 0]) + 1;
    missionNamespace setVariable ["KFH_nextTacticalPingId", _pingId, true];
    [_pos, _senderName, _pingId] remoteExecCall ["KFH_fnc_showTacticalPingLocal", 0];
};

KFH_fnc_placeTacticalPingLocal = {
    params ["_pos"];

    if ((count _pos) < 2) exitWith {};
    [_pos, name player] remoteExecCall ["KFH_fnc_broadcastTacticalPing", 2];
};

KFH_fnc_installTacticalPingControls = {
    waitUntil { !isNull player };
    if (missionNamespace getVariable ["KFH_tacticalPingControlsStarted", false]) exitWith {};
    missionNamespace setVariable ["KFH_tacticalPingControlsStarted", true];

    [] spawn {
        private _lastDisplay = displayNull;
        while { true } do {
            waitUntil {
                sleep 0.25;
                !isNull findDisplay 12 || {(missionNamespace getVariable ["KFH_phase", "boot"]) in ["complete", "failed"]}
            };
            if ((missionNamespace getVariable ["KFH_phase", "boot"]) in ["complete", "failed"]) exitWith {};

            private _display = findDisplay 12;
            if (!isNull _display && {_display isNotEqualTo _lastDisplay}) then {
                _lastDisplay = _display;
                private _map = _display displayCtrl 51;
                if (!isNull _map) then {
                    _map ctrlAddEventHandler ["MouseButtonDblClick", {
                        params ["_control", "_button", "_x", "_y"];
                        if (_button isEqualTo 0) then {
                            private _pos = _control ctrlMapScreenToWorld [_x, _y];
                            [_pos] call KFH_fnc_placeTacticalPingLocal;
                        };
                    }];
                    _map ctrlAddEventHandler ["MouseButtonDown", {
                        params ["_control", "_button", "_x", "_y", "_shift", "_ctrl"];
                        if (_button isEqualTo 0 && {_ctrl}) then {
                            private _pos = _control ctrlMapScreenToWorld [_x, _y];
                            [_pos] call KFH_fnc_placeTacticalPingLocal;
                        };
                    }];
                };
            };

            waitUntil {
                sleep 0.25;
                isNull findDisplay 12 || {(missionNamespace getVariable ["KFH_phase", "boot"]) in ["complete", "failed"]}
            };
        };
    };
};

KFH_fnc_togglePerspective = {
    private _subject = vehicle player;

    if (cameraView isEqualTo "EXTERNAL") then {
        _subject switchCamera "INTERNAL";
    } else {
        _subject switchCamera "EXTERNAL";
    };
};

KFH_fnc_installPerspectiveControls = {
    waitUntil { !isNull player };

    if !(isNil { player getVariable "KFH_perspectiveActionId" }) then {
        player removeAction (player getVariable ["KFH_perspectiveActionId", -1]);
        player setVariable ["KFH_perspectiveActionId", nil];
    };

    [] spawn {
        waitUntil { !isNull findDisplay 46 };
        private _display = findDisplay 46;

        _display displayAddEventHandler ["KeyDown", {
            params ["", "_key"];
            private _personViewKeys = actionKeys "personView";

            if (_key in _personViewKeys) then {
                [] call KFH_fnc_togglePerspective;
                true
            } else {
                false
            };
        }];
    };
};

KFH_fnc_isFriendlyDragTarget = {
    params ["_candidate", "_caller"];

    if (isNull _candidate || {isNull _caller}) exitWith { false };
    if (_candidate isEqualTo _caller) exitWith { false };
    if !(_candidate isKindOf "CAManBase") exitWith { false };
    if (_candidate getVariable ["KFH_draggedBodyBusy", false]) exitWith { false };

    private _needsHelp = (!alive _candidate) || {[_candidate] call KFH_fnc_isIncapacitated};
    if !(_needsHelp) exitWith { false };

    ((side group _candidate) isEqualTo (side group _caller)) ||
    {_candidate getVariable ["KFH_debugTeammate", false]} ||
    {_candidate getVariable ["KFH_soloWingman", false]}
};

KFH_fnc_getNearbyDraggableAllyBody = {
    params ["_caller"];

    if (isNull _caller) exitWith { objNull };

    private _range = missionNamespace getVariable ["KFH_bodyDragDistance", 3.2];
    private _near = nearestObjects [_caller, ["CAManBase"], _range];
    {
        if ((_x distance2D _caller) <= _range) then {
            _near pushBackUnique _x;
        };
    } forEach allDeadMen;

    private _candidates = _near select { [_x, _caller] call KFH_fnc_isFriendlyDragTarget };
    if ((count _candidates) isEqualTo 0) exitWith { objNull };

    ([_candidates, [], {_x distance2D _caller}, "ASCEND"] call BIS_fnc_sortBy) select 0
};

KFH_fnc_getNearbyVehicleInjuredAlly = {
    params ["_caller"];

    if (isNull _caller) exitWith { objNull };

    private _range = missionNamespace getVariable ["KFH_vehicleCasualtyPullActionDistance", 8];
    private _vehicles = nearestObjects [_caller, ["LandVehicle", "Air", "Ship"], _range];
    private _candidates = [];

    {
        private _vehicle = _x;
        {
            if (
                !isNull _x &&
                {_x isNotEqualTo _caller} &&
                {_x isKindOf "CAManBase"} &&
                {[_x, _caller] call KFH_fnc_isFriendlyDragTarget} &&
                {vehicle _x isEqualTo _vehicle}
            ) then {
                _candidates pushBackUnique _x;
            };
        } forEach (crew _vehicle);
    } forEach _vehicles;

    if ((count _candidates) isEqualTo 0) exitWith { objNull };

    ([_candidates, [], {_caller distance2D (vehicle _x)}, "ASCEND"] call BIS_fnc_sortBy) select 0
};

KFH_fnc_pullNearbyVehicleInjuredLocal = {
    params [["_caller", player]];

    private _casualty = [_caller] call KFH_fnc_getNearbyVehicleInjuredAlly;
    if (isNull _casualty) exitWith {
        ["No injured ally inside a nearby vehicle."] call KFH_fnc_localNotify;
    };

    [_casualty, _caller, "manual pull injured"] call KFH_fnc_extractCasualtyFromVehicle;
    ["Injured ally pulled clear. Drag or revive once safe."] call KFH_fnc_localNotify;
};

KFH_fnc_dropDraggedBodyLocal = {
    params [["_caller", player]];

    private _body = _caller getVariable ["KFH_draggedBody", objNull];
    if (isNull _body) exitWith {};

    detach _body;
    _body setPosATL (_caller modelToWorld [0, 1.25, 0]);
    _body setVariable ["KFH_draggedBodyBusy", false, true];
    _caller setVariable ["KFH_draggedBody", objNull];

    if (alive _body) then {
        _body enableAI "MOVE";
    };

    ["Body dropped."] call KFH_fnc_localNotify;
};

KFH_fnc_startDraggingBodyLocal = {
    params [["_caller", player]];

    if !(missionNamespace getVariable ["KFH_bodyDragEnabled", true]) exitWith {};
    if !(isNull (_caller getVariable ["KFH_draggedBody", objNull])) exitWith {};

    private _body = [_caller] call KFH_fnc_getNearbyDraggableAllyBody;
    if (isNull _body) exitWith {
        ["No downed ally or body close enough to drag."] call KFH_fnc_localNotify;
    };

    _body setVariable ["KFH_draggedBodyBusy", true, true];
    _caller setVariable ["KFH_draggedBody", _body];

    if (alive _body) then {
        _body disableAI "MOVE";
    };

    _body attachTo [_caller, missionNamespace getVariable ["KFH_bodyDragAttachOffset", [0, 1.15, 0.05]]];
    _body setDir 180;
    ["Dragging ally body. Use Drop body when safe."] call KFH_fnc_localNotify;
};

KFH_fnc_installPlayerCombatActions = {
    waitUntil { !isNull player };

    if (isNil { player getVariable "KFH_vehicleFlipActionId" }) then {
        private _flipActionId = player addAction [
            "Flip nearby vehicle",
            {
                params ["_target", "_caller"];
                private _vehicle = [_caller] call KFH_fnc_getNearbyFlippableVehicle;
                if (isNull _vehicle) exitWith {
                    ["No overturned vehicle close enough."] call KFH_fnc_localNotify;
                };
                [_vehicle, _caller] remoteExecCall ["KFH_fnc_flipVehicleServer", 2];
            },
            nil,
            1.8,
            true,
            true,
            "",
            "missionNamespace getVariable ['KFH_vehicleFlipEnabled', true] && {!isNull ([_this] call KFH_fnc_getNearbyFlippableVehicle)}"
        ];

        player setVariable ["KFH_vehicleFlipActionId", _flipActionId];
    };

    if (isNil { player getVariable "KFH_quickStrikeActionId" }) then {
        private _actionId = player addAction [
            "Quick Strike",
            {
                [] call KFH_fnc_playerQuickStrike;
            },
            nil,
            1.6,
            false,
            true,
            "",
            "alive _this && (_this distance _target) < 1.5"
        ];

        player setVariable ["KFH_quickStrikeActionId", _actionId];
    };

    if (isNil { player getVariable "KFH_pullVehicleInjuredActionId" }) then {
        private _pullActionId = player addAction [
            "Pull injured from vehicle",
            {
                params ["_target", "_caller"];
                [_caller] call KFH_fnc_pullNearbyVehicleInjuredLocal;
            },
            nil,
            1.85,
            false,
            true,
            "",
            "missionNamespace getVariable ['KFH_vehicleCasualtyPullEnabled', true] && {alive _this} && {!isNull ([_this] call KFH_fnc_getNearbyVehicleInjuredAlly)}"
        ];

        player setVariable ["KFH_pullVehicleInjuredActionId", _pullActionId];
    };

    if (isNil { player getVariable "KFH_dragBodyActionId" }) then {
        private _dragActionId = player addAction [
            "Drag ally body",
            {
                params ["_target", "_caller"];
                [_caller] call KFH_fnc_startDraggingBodyLocal;
            },
            nil,
            1.7,
            false,
            true,
            "",
            "missionNamespace getVariable ['KFH_bodyDragEnabled', true] && {alive _this} && {isNull (_this getVariable ['KFH_draggedBody', objNull])} && {!isNull ([_this] call KFH_fnc_getNearbyDraggableAllyBody)}"
        ];

        player setVariable ["KFH_dragBodyActionId", _dragActionId];
    };

    if (isNil { player getVariable "KFH_dropBodyActionId" }) then {
        private _dropActionId = player addAction [
            "Drop body",
            {
                params ["_target", "_caller"];
                [_caller] call KFH_fnc_dropDraggedBodyLocal;
            },
            nil,
            1.75,
            false,
            true,
            "",
            "alive _this && {!isNull (_this getVariable ['KFH_draggedBody', objNull])}"
        ];

        player setVariable ["KFH_dropBodyActionId", _dropActionId];
    };
};
