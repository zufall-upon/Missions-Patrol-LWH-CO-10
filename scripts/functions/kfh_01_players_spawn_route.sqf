KFH_fnc_getHumanPlayers = {
    allPlayers select {
        isPlayer _x &&
        !(_x isKindOf "HeadlessClient_F")
    }
};

KFH_fnc_reportPlayerPresenceToServer = {
    params ["_unit", ["_pos", []], ["_combatReady", false]];

    if (!isServer) exitWith {
        [_unit, _pos, _combatReady] remoteExecCall ["KFH_fnc_reportPlayerPresenceToServer", 2];
    };
    if (isNull _unit) exitWith {};
    if !(isPlayer _unit) exitWith {};

    private _anchors = missionNamespace getVariable ["KFH_recentPlayerPresenceAnchors", []];
    _anchors = _anchors select {
        (_x select 0) isNotEqualTo _unit &&
        {time - (_x select 2) <= 12}
    };
    _anchors pushBack [_unit, _pos, time, _combatReady];
    missionNamespace setVariable ["KFH_recentPlayerPresenceAnchors", _anchors, true];
};

KFH_fnc_clientPlayerPresenceLoop = {
    if (!hasInterface) exitWith {};
    waitUntil { !isNull player };

    while { true } do {
        if ((missionNamespace getVariable ["KFH_phase", "boot"]) in ["complete", "failed"]) exitWith {};
        [player, getPosATL player, alive player && {!([player] call KFH_fnc_isIncapacitated)}] remoteExecCall ["KFH_fnc_reportPlayerPresenceToServer", 2];
        sleep 1.5;
    };
};

KFH_fnc_getAliveHumanPlayers = {
    ([] call KFH_fnc_getHumanPlayers) select { alive _x }
};

KFH_fnc_getMissionMaxPlayers = {
    private _configured = getNumber (missionConfigFile >> "Header" >> "maxPlayers");
    if (_configured <= 0) then {
        _configured = missionNamespace getVariable ["KFH_targetPlayers", KFH_targetPlayers];
    };

    (_configured max 1)
};

KFH_fnc_getTargetPlayers = {
    missionNamespace getVariable ["KFH_targetPlayers", [] call KFH_fnc_getMissionMaxPlayers]
};

KFH_fnc_getNearestHumanReferenceUnit = {
    params ["_origin"];

    private _nearest = objNull;
    private _nearestDistance = 1e10;
    {
        if (alive _x) then {
            private _distance = _origin distance2D _x;
            if (_distance < _nearestDistance) then {
                _nearest = _x;
                _nearestDistance = _distance;
            };
        };
    } forEach ([] call KFH_fnc_getHumanReferenceUnits);

    _nearest
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

KFH_fnc_localNotifyKey = {
    params ["_key", ["_args", []]];
    [[_key, _args] call KFH_fnc_localizeAnnouncement] call KFH_fnc_localNotify;
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
            ["civilian_panic_explosion"] call KFH_fnc_notifyAllKey;
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
        private _effectiveSource = if (_source isKindOf "CAManBase") then { _source } else { effectiveCommander _source };
        if (isNull _effectiveSource) exitWith { _incomingDamage };

        private _sourceIsEnvMilitary = (_effectiveSource getVariable ["KFH_envTrafficCrew", false]) || {
            _source getVariable ["KFH_ambientTraffic", false]
        };
        private _targetIsEnvMilitary = _unit getVariable ["KFH_envTrafficCrew", false];
        if (_sourceIsEnvMilitary && {_targetIsEnvMilitary}) exitWith { 0 };

        [_unit, _incomingDamage, _source] call KFH_fnc_getFriendlyFireScaledDamage
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

KFH_fnc_getFriendlyFireScaledDamage = {
    params ["_unit", "_incomingDamage", "_source"];

    if (isNull _unit) exitWith { _incomingDamage };
    if (isNull _source) exitWith { _incomingDamage };
    if (_source isEqualTo _unit) exitWith { _incomingDamage };

    private _effectiveSource = if (_source isKindOf "CAManBase") then {
        _source
    } else {
        effectiveCommander _source
    };
    if (isNull _effectiveSource) exitWith { _incomingDamage };
    if !(alive _effectiveSource) exitWith { _incomingDamage };
    if !((side group _effectiveSource) isEqualTo (side group _unit)) exitWith { _incomingDamage };

    private _currentDamage = damage _unit;
    private _scale = missionNamespace getVariable ["KFH_friendlyFireScale", KFH_friendlyFireScale];
    (_currentDamage + (((_incomingDamage - _currentDamage) max 0) * _scale)) max 0 min 1
};

KFH_fnc_playWaveStartWarning = {
    [] spawn {
        private _roars = [
            "corrupted_idle_1",
            "corrupted_idle_2",
            "corrupted_idle_3",
            "corrupted_idle_4",
            "corrupted_head_idle_1",
            "corrupted_head_idle_2"
        ];
        private _available = _roars select { isClass (configFile >> "CfgSounds" >> _x) };
        if ((count _available) isEqualTo 0) exitWith {};

        private _sound = selectRandom _available;
        playSound [_sound, true];
        sleep (0.22 + random 0.18);
        if ((count _available) > 1 && { random 1 < 0.55 }) then {
            _sound = selectRandom _available;
            playSound [_sound, true];
        };
    };
};

KFH_fnc_playFinaleRushWarning = {
    [] spawn {
        private _roars = [
            "Goliath_V_Roar_Dist_1",
            "Goliath_V_Roar_Dist_2",
            "Goliath_V_Roar_1",
            "Goliath_V_Roar_2"
        ];
        private _available = _roars select { isClass (configFile >> "CfgSounds" >> _x) };
        if ((count _available) isEqualTo 0) exitWith {};

        private _sound = selectRandom _available;
        playSound [_sound, true];
        sleep (0.3 + random 0.2);
        if ((count _available) > 1) then {
            _sound = selectRandom _available;
            playSound [_sound, true];
        };
    };
};

KFH_fnc_playBaseLostWarning = {
    [] spawn {
        playSoundUI ["A3\Sounds_F\sfx\blip1.wss", 2.6, 0.42, true];
        sleep 0.34;
        playSoundUI ["A3\Sounds_F\sfx\blip1.wss", 2.2, 0.34, true];
        sleep 0.42;
        playSoundUI ["A3\Sounds_F\sfx\blip1.wss", 1.9, 0.28, true];
    };
};

KFH_fnc_playZombieCue = {
    params [
        ["_source", objNull]
    ];

    if !(missionNamespace getVariable ["KFH_zombieCueEnabled", false]) exitWith {};
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
    _unit commandMove _approachPos;
    _unit doMove _approachPos;
    (group _unit) move _approachPos;

    if (time >= (_unit getVariable ["KFH_nextForcedDestinationAt", 0])) then {
        _unit setDestination [_approachPos, "LEADER DIRECT", true];
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

KFH_fnc_worldFromMarkerOffsetWithCorrection = {
    params ["_markerName", "_offset", ["_dirCorrection", 0]];

    private _basePos = getMarkerPos _markerName;
    private _dir = markerDir _markerName + _dirCorrection;
    private _rotated = [_offset, _dir] call KFH_fnc_rotateOffset;

    [
        (_basePos select 0) + (_rotated select 0),
        (_basePos select 1) + (_rotated select 1),
        (_basePos select 2) + (_rotated select 2)
    ]
};

KFH_fnc_getSpawnSafetyAnchors = {
    params [
        ["_playerDistance", KFH_spawnMinPlayerDistance],
        ["_respawnDistance", KFH_spawnMinRespawnDistance]
    ];

    private _anchors = [];

    {
        if (alive _x) then {
            _anchors pushBack [getPosATL _x, _playerDistance, name _x];
        };
    } forEach ([] call KFH_fnc_getHumanPlayers);

    private _respawnAnchor = missionNamespace getVariable ["KFH_respawnAnchorPos", []];
    if ((count _respawnAnchor) >= 2) then {
        _anchors pushBack [_respawnAnchor, _respawnDistance, "respawn anchor"];
    };

    _anchors
};

KFH_fnc_isSpawnFarFromFriendlies = {
    params [
        "_candidatePos",
        ["_playerDistance", KFH_spawnMinPlayerDistance],
        ["_respawnDistance", KFH_spawnMinRespawnDistance]
    ];

    private _isFarEnough = true;
    {
        private _anchorPos = _x select 0;
        private _minDistance = _x select 1;

        if ((_candidatePos distance2D _anchorPos) < _minDistance) exitWith {
            _isFarEnough = false;
        };
    } forEach ([_playerDistance, _respawnDistance] call KFH_fnc_getSpawnSafetyAnchors);

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
    params [
        "_candidatePos",
        "_target",
        ["_playerDistance", KFH_spawnMinPlayerDistance],
        ["_respawnDistance", KFH_spawnMinRespawnDistance],
        ["_blockerRadius", KFH_spawnAheadBlockerRadius],
        ["_requireTargetView", true]
    ];

    if ((count _candidatePos) < 2) exitWith { false };
    if (surfaceIsWater _candidatePos) exitWith { false };

    private _posATL = [
        _candidatePos select 0,
        _candidatePos select 1,
        if ((count _candidatePos) > 2) then { _candidatePos select 2 } else { 0 }
    ];
    if !([_posATL, _playerDistance, _respawnDistance] call KFH_fnc_isSpawnFarFromFriendlies) exitWith { false };

    private _nearBlockers = nearestObjects [_posATL, ["House", "Building", "Wall", "Fence"], _blockerRadius];
    private _nearTerrainBlockers = nearestTerrainObjects [
        _posATL,
        ["BUILDING", "HOUSE", "ROCK", "BUNKER", "FORTRESS"],
        _blockerRadius,
        false,
        true
    ];

    if ((count _nearBlockers) > 0) exitWith { false };
    if ((count _nearTerrainBlockers) > 0) exitWith { false };
    if (isNull _target) exitWith { true };
    if (!_requireTargetView) exitWith { true };

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

KFH_fnc_isSpawnCandidateHiddenFromHumans = {
    params ["_candidatePos"];

    if !(missionNamespace getVariable ["KFH_waveSpawnPreferHidden", true]) exitWith { true };
    if ((count _candidatePos) < 2) exitWith { false };

    private _posATL = [
        _candidatePos select 0,
        _candidatePos select 1,
        if ((count _candidatePos) > 2) then { _candidatePos select 2 } else { 0 }
    ];
    private _rejectDistance = missionNamespace getVariable ["KFH_waveSpawnVisibleRejectDistance", 145];
    private _rejectCone = missionNamespace getVariable ["KFH_waveSpawnVisibleRejectConeDegrees", 58];
    private _hidden = true;

    {
        if (alive _x && {(_posATL distance2D _x) <= _rejectDistance}) then {
            private _dirToCandidate = [_x, _posATL] call BIS_fnc_dirTo;
            private _delta = abs (_dirToCandidate - (getDir _x));
            if (_delta > 180) then { _delta = 360 - _delta; };
            if (_delta <= _rejectCone) then {
                private _candidateEye = AGLToASL [
                    _posATL select 0,
                    _posATL select 1,
                    (_posATL select 2) + 1.2
                ];
                private _intersections = lineIntersectsSurfaces [
                    eyePos _x,
                    _candidateEye,
                    _x,
                    objNull,
                    true,
                    1,
                    "GEOM",
                    "NONE"
                ];
                if ((count _intersections) isEqualTo 0) exitWith {
                    _hidden = false;
                };
            };
        };
    } forEach ([] call KFH_fnc_getHumanReferenceUnits);

    _hidden
};

KFH_fnc_findPlayerCheckpointLaneSpawnPosition = {
    params ["_player", "_checkpointPos", ["_context", "wave-lane"]];

    if !(missionNamespace getVariable ["KFH_waveSpawnLaneEnabled", true]) exitWith { [] };
    if (isNull _player || {!alive _player}) exitWith { [] };
    if ((count _checkpointPos) < 2) exitWith { [] };

    private _playerPos = getPosATL _player;
    private _minDistance = missionNamespace getVariable ["KFH_waveSpawnLaneMinDistance", 58];
    private _maxDistance = missionNamespace getVariable ["KFH_waveSpawnLaneMaxDistance", 105];
    private _closeMinDistance = missionNamespace getVariable ["KFH_waveSpawnLaneCloseMinDistance", 42];
    private _padding = missionNamespace getVariable ["KFH_waveSpawnLaneCheckpointPadding", 24];
    private _cpDistance = _playerPos distance2D _checkpointPos;
    private _direction = if (_cpDistance > _padding) then {
        [_playerPos, _checkpointPos] call BIS_fnc_dirTo
    } else {
        getDir _player
    };
    private _cone = missionNamespace getVariable ["KFH_waveSpawnLaneConeDegrees", 22];
    private _attempts = missionNamespace getVariable ["KFH_waveSpawnLaneAttempts", 18];
    private _minPlayerDistance = missionNamespace getVariable ["KFH_waveSpawnLaneMinPlayerDistance", 50];
    private _result = [];
    private _fallback = [];

    if (_cpDistance > (_padding + 8)) then {
        private _laneMaxDistance = (_cpDistance - _padding) max _closeMinDistance;
        _maxDistance = _maxDistance min _laneMaxDistance;
        _minDistance = _minDistance min _maxDistance;
    };
    _maxDistance = _maxDistance max _minDistance;

    for "_attempt" from 1 to _attempts do {
        if ((count _result) isEqualTo 0) then {
            private _distance = _minDistance + random ((_maxDistance - _minDistance) max 1);
            private _candidateSeed = _playerPos getPos [_distance, _direction + ((random (_cone * 2)) - _cone)];
            private _candidate = [
                _candidateSeed,
                0,
                missionNamespace getVariable ["KFH_spawnAheadSafeRadius", 14],
                2,
                0,
                0.35,
                0
            ] call BIS_fnc_findSafePos;
            if ((count _candidate) < 3) then {
                _candidate set [2, 0];
            };

            if (
                !((_candidate select 0) isEqualTo 0 && {(_candidate select 1) isEqualTo 0}) &&
                {!surfaceIsWater _candidate} &&
                {[_candidate, objNull, _minPlayerDistance, missionNamespace getVariable ["KFH_spawnRelaxedMinRespawnDistance", 45], missionNamespace getVariable ["KFH_spawnRelaxedBlockerRadius", 2], false] call KFH_fnc_isSpawnCandidateOpen}
            ) then {
                if ((count _fallback) isEqualTo 0) then {
                    _fallback = +_candidate;
                };
                if ([_candidate] call KFH_fnc_isSpawnCandidateHiddenFromHumans) then {
                    _result = +_candidate;
                };
            };
        };
    };

    if ((count _result) > 0) exitWith { [_result, "lane-hidden"] };
    if ((count _fallback) > 0) exitWith { [_fallback, "lane-open"] };

    [format [
        "Wave lane spawn failed context=%1 player=%2 checkpoint=%3 distance=%4.",
        _context,
        name _player,
        mapGridPosition _checkpointPos,
        round _cpDistance
    ]] call KFH_fnc_log;
    []
};

KFH_fnc_findForwardSpawnPosition = {
    params ["_centerPos"];

    private _targets = [] call KFH_fnc_getCombatReadyHumans;
    if ((count _targets) isEqualTo 0) then {
        _targets = ([] call KFH_fnc_getHumanPlayers) select { alive _x };
    };
    if ((count _targets) isEqualTo 0) then {
        _targets = ([] call KFH_fnc_getHumanReferenceUnits) select { alive _x && {!([_x] call KFH_fnc_isIncapacitated)} };
    };
    if ((count _targets) isEqualTo 0) then {
        _targets = [] call KFH_fnc_getCombatReadyFriendlies;
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

KFH_fnc_getWavePlayerAnchor = {
    params ["_checkpointPos"];

    private _range = missionNamespace getVariable ["KFH_wavePlayerEngagementDistance", 180];
    private _humans = ([] call KFH_fnc_getCombatReadyHumans) select { (_x distance2D _checkpointPos) <= _range };
    if ((count _humans) isEqualTo 0) then {
        _humans = ([] call KFH_fnc_getHumanPlayers) select { alive _x && {(_x distance2D _checkpointPos) <= _range} };
    };
    if ((count _humans) isEqualTo 0) then {
        _humans = ([] call KFH_fnc_getHumanReferenceUnits) select { alive _x && {!([_x] call KFH_fnc_isIncapacitated)} && {(_x distance2D _checkpointPos) <= _range} };
    };
    if ((count _humans) isEqualTo 0) then {
        _humans = ([] call KFH_fnc_getCombatReadyFriendlies) select { (_x distance2D _checkpointPos) <= _range };
    };
    if ((count _humans) isEqualTo 0) then {
        private _fallbackRange = missionNamespace getVariable ["KFH_wavePlayerFallbackEngagementDistance", 1000];
        _humans = ([] call KFH_fnc_getCombatReadyHumans) select { (_x distance2D _checkpointPos) <= _fallbackRange };
        if ((count _humans) isEqualTo 0) then {
            _humans = ([] call KFH_fnc_getHumanPlayers) select { alive _x && {(_x distance2D _checkpointPos) <= _fallbackRange} };
        };
        if ((count _humans) isEqualTo 0) then {
            _humans = ([] call KFH_fnc_getHumanReferenceUnits) select { alive _x && {!([_x] call KFH_fnc_isIncapacitated)} && {(_x distance2D _checkpointPos) <= _fallbackRange} };
        };
        if ((count _humans) isEqualTo 0) then {
            _humans = ([] call KFH_fnc_getCombatReadyFriendlies) select { (_x distance2D _checkpointPos) <= _fallbackRange };
        };
    };
    if ((count _humans) isEqualTo 0) then {
        _humans = ([] call KFH_fnc_getHumanReferenceUnits) select { alive _x && {!([_x] call KFH_fnc_isIncapacitated)} };
    };
    if ((count _humans) isEqualTo 0) exitWith { objNull };

    ([_humans, [], {_x distance2D _checkpointPos}, "ASCEND"] call BIS_fnc_sortBy) select 0
};

KFH_fnc_findRoadSpawnFallback = {
    params ["_anchorPos", "_moveTargetPos"];

    private _searchRadius = missionNamespace getVariable ["KFH_spawnFallbackRoadSearchRadius", 180];
    private _minPlayerDistance = missionNamespace getVariable ["KFH_spawnFallbackRoadMinDistance", 55];
    private _roads = _anchorPos nearRoads _searchRadius;
    private _result = [];

    {
        private _candidate = getPosATL _x;
        if (
            (count _result) isEqualTo 0 &&
            {!surfaceIsWater _candidate} &&
            {[_candidate, objNull, _minPlayerDistance, missionNamespace getVariable ["KFH_spawnRelaxedMinRespawnDistance", 45], missionNamespace getVariable ["KFH_spawnRelaxedBlockerRadius", 2], false] call KFH_fnc_isSpawnCandidateOpen}
        ) then {
            _result = +_candidate;
        };
    } forEach ([_roads, [], {_x distance2D _moveTargetPos}, "ASCEND"] call BIS_fnc_sortBy);

    _result
};

KFH_fnc_findPerimeterSpawnFallback = {
    params ["_anchorPos", "_moveTargetPos"];

    private _minDistance = missionNamespace getVariable ["KFH_spawnFallbackPerimeterMinDistance", 70];
    private _maxDistance = missionNamespace getVariable ["KFH_spawnFallbackPerimeterMaxDistance", 135];
    private _minPlayerDistance = missionNamespace getVariable ["KFH_spawnRelaxedMinPlayerDistance", 55];
    private _minRespawnDistance = missionNamespace getVariable ["KFH_spawnRelaxedMinRespawnDistance", 45];
    private _blockerRadius = missionNamespace getVariable ["KFH_spawnRelaxedBlockerRadius", 2];
    private _result = [];

    for "_i" from 1 to 20 do {
        if ((count _result) isEqualTo 0) then {
            private _seed = _moveTargetPos getPos [_minDistance + random ((_maxDistance - _minDistance) max 1), random 360];
            private _candidate = [_seed, 0, 8, 1, 0, 0.45, 0] call BIS_fnc_findSafePos;
            if ((count _candidate) < 3) then { _candidate set [2, 0]; };
            if (
                !((_candidate select 0) isEqualTo 0 && {(_candidate select 1) isEqualTo 0}) &&
                {!surfaceIsWater _candidate} &&
                {[_candidate, objNull, _minPlayerDistance, _minRespawnDistance, _blockerRadius, false] call KFH_fnc_isSpawnCandidateOpen}
            ) then {
                _result = +_candidate;
            };
        };
    };

    _result
};

KFH_fnc_findForcedSpawnFallback = {
    params ["_anchorPos", "_moveTargetPos"];

    private _minDistance = missionNamespace getVariable ["KFH_spawnFallbackNearMinDistance", 50];
    private _maxDistance = missionNamespace getVariable ["KFH_spawnFallbackNearMaxDistance", 95];
    private _minPlayerDistance = missionNamespace getVariable ["KFH_spawnForcedMinPlayerDistance", 35];
    private _minRespawnDistance = missionNamespace getVariable ["KFH_spawnForcedMinRespawnDistance", 30];
    private _result = [];

    for "_i" from 1 to 24 do {
        if ((count _result) isEqualTo 0) then {
            private _candidate = _anchorPos getPos [_minDistance + random ((_maxDistance - _minDistance) max 1), random 360];
            _candidate set [2, 0];
            if (
                !surfaceIsWater _candidate &&
                {[_candidate, _minPlayerDistance, _minRespawnDistance] call KFH_fnc_isSpawnFarFromFriendlies}
            ) then {
                _result = +_candidate;
            };
        };
    };

    if ((count _result) isEqualTo 0) then {
        _result = _anchorPos getPos [_minPlayerDistance, random 360];
        _result set [2, 0];
    };

    _result
};

KFH_fnc_findWaveSpawnPosition = {
    params [
        "_anchorPos",
        "_moveTargetPos",
        ["_context", "wave"],
        ["_checkpointPos", []],
        ["_playerAnchor", objNull]
    ];

    if (!isNull _playerAnchor && {(count _checkpointPos) >= 2}) then {
        private _laneResult = [_playerAnchor, _checkpointPos, _context] call KFH_fnc_findPlayerCheckpointLaneSpawnPosition;
        if ((count _laneResult) >= 2) exitWith { _laneResult };
    };

    private _spawnPos = [_anchorPos] call KFH_fnc_findForwardSpawnPosition;
    if (
        (count _spawnPos) >= 2 &&
        {[_spawnPos, objNull] call KFH_fnc_isSpawnCandidateOpen}
    ) exitWith { [_spawnPos, "strict"] };

    [format ["Wave spawn strict stage failed context=%1 anchor=%2 moveTarget=%3 candidate=%4.", _context, mapGridPosition _anchorPos, mapGridPosition _moveTargetPos, _spawnPos]] call KFH_fnc_log;

    _spawnPos = [
        _anchorPos,
        missionNamespace getVariable ["KFH_spawnFallbackNearMinDistance", 50],
        missionNamespace getVariable ["KFH_spawnFallbackNearMaxDistance", 95]
    ] call KFH_fnc_findSafeDistantSpawnPosition;
    if (
        (count _spawnPos) >= 2 &&
        {[_spawnPos, objNull, missionNamespace getVariable ["KFH_spawnRelaxedMinPlayerDistance", 55], missionNamespace getVariable ["KFH_spawnRelaxedMinRespawnDistance", 45], missionNamespace getVariable ["KFH_spawnRelaxedBlockerRadius", 2], false] call KFH_fnc_isSpawnCandidateOpen}
    ) exitWith { [_spawnPos, "relaxed-near"] };

    _spawnPos = [_anchorPos, _moveTargetPos] call KFH_fnc_findRoadSpawnFallback;
    if ((count _spawnPos) >= 2) exitWith { [_spawnPos, "road"] };

    _spawnPos = [_anchorPos, _moveTargetPos] call KFH_fnc_findPerimeterSpawnFallback;
    if ((count _spawnPos) >= 2) exitWith { [_spawnPos, "perimeter"] };

    _spawnPos = [_anchorPos, _moveTargetPos] call KFH_fnc_findForcedSpawnFallback;
    [format ["Wave spawn forced fallback context=%1 anchor=%2 moveTarget=%3 forced=%4.", _context, mapGridPosition _anchorPos, mapGridPosition _moveTargetPos, _spawnPos]] call KFH_fnc_log;
    [_spawnPos, "forced"]
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

    private _lang = [] call KFH_fnc_getAnnouncementLanguageIndex;
    switch ([_checkpointIndex] call KFH_fnc_getCheckpointEventId) do {
        case "resupply": {
            if (_lang isEqualTo 0) then { "補給隊が近いデス。secure 後の supply 到着が早いデス。" } else { "Supply team is nearby. Support arrives sooner after secure." }
        };
        case "hunter": {
            if (_lang isEqualTo 0) then { "強化 signal carrier が追加で出るデス。倒すと装備が伸びるデス。" } else { "A stronger signal carrier will appear. Drop it for better gear." }
        };
        default {
            if (_lang isEqualTo 0) then { "巣が活性化してるデス。接触時に追加ラッシュが入りやすいデス。" } else { "The hive is active. Contact can trigger extra rush pressure." }
        };
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

    ["return_route_profile", [
        _summary select 1,
        _summary select 2,
        [_danger] call KFH_fnc_getReturnDangerLabel
    ]] call KFH_fnc_notifyAllKey;
};

KFH_fnc_appendSupportObject = {
    params ["_object"];

    if (isNull _object) exitWith {};

    private _supportObjects = missionNamespace getVariable ["KFH_supportObjects", []];
    _supportObjects pushBack _object;
    missionNamespace setVariable ["KFH_supportObjects", _supportObjects, true];
};

KFH_fnc_spawnSupportObject = {
    params ["_className", "_markerName", "_offset", ["_dirOffset", 0], ["_allowDamage", false], ["_dirCorrection", 0]];

    private _spawnPos = [_markerName, _offset, _dirCorrection] call KFH_fnc_worldFromMarkerOffsetWithCorrection;
    private _dir = markerDir _markerName + _dirCorrection + _dirOffset;
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
    private _label = ["checkpoint_time_shift", [_checkpointIndex]] call KFH_fnc_localizeAnnouncement;

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

KFH_fnc_placeJipPlayerNearLeaderOnce = {
    if (player getVariable ["KFH_jipJoinPlaced", false]) exitWith {};

    private _candidates = ([] call KFH_fnc_getHumanPlayers) select {
        _x isNotEqualTo player &&
        {alive _x} &&
        {!([_x] call KFH_fnc_isIncapacitated)}
    };
    private _anchor = if ((count _candidates) > 0) then {
        ([_candidates, [], {_x distance2D player}, "ASCEND"] call BIS_fnc_sortBy) select 0
    } else {
        objNull
    };
    private _anchorPos = if (!isNull _anchor) then {
        getPosATL _anchor
    } else {
        missionNamespace getVariable ["KFH_respawnAnchorPos", getMarkerPos "kfh_start"]
    };
    private _dir = if (!isNull _anchor) then { getDir _anchor } else { markerDir "kfh_start" };
    private _angle = _dir + 180 + random 80 - 40;
    private _radius = 3 + random 3;
    private _targetPos = [
        (_anchorPos select 0) + (sin _angle) * _radius,
        (_anchorPos select 1) + (cos _angle) * _radius,
        0
    ];

    player setDir _dir;
    player setPosATL _targetPos;
    player setVariable ["KFH_jipJoinPlaced", true, true];
    [format [
        "JIP player %1 joined near %2 at %3.",
        name player,
        if (!isNull _anchor) then { name _anchor } else { "respawn anchor" },
        mapGridPosition _targetPos
    ]] call KFH_fnc_log;
};

KFH_fnc_spawnOutbreakObject = {
    params [
        "_className",
        "_markerName",
        "_offset",
        ["_dirOffset", 0],
        ["_damage", 0],
        ["_allowDamage", false],
        ["_dirCorrection", 0]
    ];

    if !(isClass (configFile >> "CfgVehicles" >> _className)) exitWith {
        [format ["Skipped outbreak dressing object with missing class: %1", _className]] call KFH_fnc_log;
        objNull
    };

    private _object = [_className, _markerName, _offset, _dirOffset, _allowDamage, _dirCorrection] call KFH_fnc_spawnSupportObject;
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
    private _assetDirCorrection = missionNamespace getVariable ["KFH_checkpointAssetDirCorrection", 90];
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
            private _object = [_className, _markerName, [_rightOffset, _forwardOffset, _heightOffset], _dirOffset, 0, true, _assetDirCorrection] call KFH_fnc_spawnOutbreakObject;
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

