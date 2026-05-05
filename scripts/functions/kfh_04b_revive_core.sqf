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

    private _rescuers = ([] call KFH_fnc_getPotentialRescuers) select { _x != _unit };
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

KFH_fnc_applyDownedWaitPoseLocal = {
    params ["_unit"];

    if (isNull _unit) exitWith {};
    if (_unit getVariable ["KFH_debugTeammate", false]) then {
        _unit setVariable ["KFH_lastEchoCasualtyAt", time, true];
    };
    if !(alive _unit) exitWith {};
    if !(_unit getVariable ["KFH_forcedDowned", false]) exitWith {};
    if ((vehicle _unit) isNotEqualTo _unit) exitWith {};

    private _anim = missionNamespace getVariable ["KFH_downedWaitAnimation", "AinjPpneMstpSnonWrflDnon"];
    _unit setUnitPos "DOWN";
    _unit switchMove _anim;
};

KFH_fnc_startDownedPoseRefresh = {
    params ["_unit"];

    if (isNull _unit) exitWith {};
    if (_unit getVariable ["KFH_downedPoseRefreshActive", false]) exitWith {};

    _unit setVariable ["KFH_downedPoseRefreshActive", true, true];
    [_unit] spawn {
        params ["_trackedUnit"];

        private _interval = missionNamespace getVariable ["KFH_downedPoseRefreshSeconds", 1.2];
        while {
            !isNull _trackedUnit &&
            {alive _trackedUnit} &&
            {_trackedUnit getVariable ["KFH_forcedDowned", false]}
        } do {
            [_trackedUnit] remoteExecCall ["KFH_fnc_applyDownedWaitPoseLocal", 0];
            sleep _interval;
        };

        if (!isNull _trackedUnit) then {
            _trackedUnit setVariable ["KFH_downedPoseRefreshActive", false, true];
            _trackedUnit setUnitPos "AUTO";
        };
    };
};

KFH_fnc_findVehicleCasualtySafePosition = {
    params ["_vehicle", ["_rescuer", objNull]];

    if (isNull _vehicle) exitWith { [] };

    private _origin = getPosATL _vehicle;
    private _safeDistance = missionNamespace getVariable ["KFH_vehicleCasualtyPullSafeDistance", 12];
    private _hullClearance = missionNamespace getVariable ["KFH_vehicleCasualtyPullHullClearance", 0.85];
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

    private _nearPullResult = [];
    if !(_originInvalid) then {
        private _bounds = boundingBoxReal _vehicle;
        private _min = _bounds select 0;
        private _max = _bounds select 1;
        private _clamp = {
            params ["_value", "_low", "_high"];
            (_value max _low) min _high
        };
        private _candidateLocals = [];

        if !(isNull _rescuer) then {
            private _rel = _vehicle worldToModel (getPosATL _rescuer);
            private _relX = _rel select 0;
            private _relY = _rel select 1;
            private _x = [_relX, _min select 0, _max select 0] call _clamp;
            private _y = [_relY, _min select 1, _max select 1] call _clamp;
            if ((abs _relX) > (abs _relY)) then {
                _x = if (_relX >= 0) then {(_max select 0) + _hullClearance} else {(_min select 0) - _hullClearance};
            } else {
                _y = if (_relY >= 0) then {(_max select 1) + _hullClearance} else {(_min select 1) - _hullClearance};
            };
            _candidateLocals pushBack [_x, _y, 0];
        };

        _candidateLocals append [
            [(_max select 0) + _hullClearance, 0, 0],
            [(_min select 0) - _hullClearance, 0, 0],
            [0, (_max select 1) + _hullClearance, 0],
            [0, (_min select 1) - _hullClearance, 0]
        ];

        private _nearResult = [];
        {
            if (_nearResult isEqualTo []) then {
                private _candidate = _vehicle modelToWorld _x;
                _candidate set [2, 0];
                if (!surfaceIsWater _candidate) then {
                    _nearResult = +_candidate;
                };
            };
        } forEach _candidateLocals;

        if !(_nearResult isEqualTo []) then {
            _nearPullResult = +_nearResult;
        };
    };

    if !(_nearPullResult isEqualTo []) exitWith { _nearPullResult };

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

KFH_fnc_announcePlayerDowned = {
    params ["_unit", ["_reason", "downed"]];

    if (!isServer) exitWith {
        [_unit, _reason] remoteExecCall ["KFH_fnc_announcePlayerDowned", 2];
    };
    if (isNull _unit) exitWith {};
    if !(isPlayer _unit) exitWith {};

    private _lastAnnouncedAt = _unit getVariable ["KFH_lastDownedAnnouncementAt", -1];
    private _minInterval = missionNamespace getVariable ["KFH_playerDownedAnnouncementMinInterval", 8];
    if (_lastAnnouncedAt >= 0 && {(time - _lastAnnouncedAt) < _minInterval}) exitWith {};

    _unit setVariable ["KFH_lastDownedAnnouncementAt", time, true];
    ["player_downed_announcement", [name _unit]] call KFH_fnc_notifyAllKey;
    [format ["Player downed announcement: %1 reason=%2.", name _unit, _reason]] call KFH_fnc_log;
};

KFH_fnc_getSuppressedDownedDamage = {
    params ["_unit"];

    private _safeDamage = missionNamespace getVariable ["KFH_forcedDownedDamage", 0.42];
    if (isNull _unit) exitWith { _safeDamage };

    (damage _unit) min _safeDamage
};

KFH_fnc_clearDownedState = {
    params ["_unit", ["_allowDamage", true]];

    if (isNull _unit) exitWith {};

    private _dragCarrier = _unit getVariable ["KFH_draggedBy", objNull];
    if !(isNull _dragCarrier) then {
        detach _unit;
        _dragCarrier setVariable ["KFH_draggedBody", objNull];
        _dragCarrier forceWalk false;
        _dragCarrier setAnimSpeedCoef (missionNamespace getVariable ["KFH_playerAnimSpeedCoef", 1]);
    };

    _unit setVariable ["KFH_forcedDowned", false, true];
    _unit setVariable ["KFH_forcedDownedAt", -1, true];
    _unit setVariable ["KFH_needsVehiclePull", false, true];
    _unit setVariable ["KFH_downedInsideVehicle", objNull, true];
    _unit setVariable ["KFH_downedPoseRefreshActive", false, true];
    _unit setVariable ["KFH_draggedBodyBusy", false, true];
    _unit setVariable ["KFH_draggedBy", objNull, true];
    _unit setVariable ["KFH_dragPoseRefreshActive", false, true];
    _unit setVariable ["KFH_manualReviveTargetBusy", false, true];
    _unit setVariable ["KFH_manualReviveTargetMedic", objNull, true];
    _unit setVariable ["KFH_aiReviveTargetBusy", false, true];
    _unit setVariable ["KFH_aiReviveTargetMedic", objNull, true];
    _unit setVariable ["KFH_aiReviveTargetBusyAt", -1, true];
    _unit setVariable ["KFH_aiReviveReadyAt", 0, true];
    _unit setVariable ["BIS_revive_incapacitated", false, true];
    _unit setVariable ["BIS_revive_isIncapacitated", false, true];
    _unit setVariable ["BIS_revive_unconscious", false, true];
    _unit setCaptive false;
    _unit setUnconscious false;
    _unit enableSimulation true;
    _unit allowDamage _allowDamage;
};

KFH_fnc_armDownedState = {
    params ["_unit", ["_source", objNull], ["_reason", "fatal damage"]];

    if (isNull _unit) exitWith {};
    if !(alive _unit) exitWith {};

    _unit setVariable ["KFH_forcedDowned", true, true];
    _unit setVariable ["KFH_forcedDownedAt", time, true];
    _unit setVariable ["KFH_aiReviveReadyAt", time + (missionNamespace getVariable ["KFH_debugTeammateReviveStartDelay", 2.5]), true];
    _unit setVariable ["KFH_aiReviveTargetBusy", false, true];
    _unit setVariable ["KFH_aiReviveTargetMedic", objNull, true];
    _unit setVariable ["KFH_aiReviveTargetBusyAt", -1, true];
    _unit setVariable ["KFH_downedReason", _reason, true];
    if ((vehicle _unit) isNotEqualTo _unit) then {
        _unit setVariable ["KFH_downedInsideVehicle", vehicle _unit, true];
        _unit setVariable ["KFH_needsVehiclePull", true, true];
    } else {
        _unit setVariable ["KFH_downedInsideVehicle", objNull, true];
        _unit setVariable ["KFH_needsVehiclePull", false, true];
    };
    _unit setCaptive true;
    _unit setUnconscious true;
    _unit setDamage (missionNamespace getVariable ["KFH_forcedDownedDamage", 0.42]);
    _unit allowDamage false;
    [_unit] call KFH_fnc_startDownedPoseRefresh;
    [_unit] remoteExecCall ["KFH_fnc_applyDownedWaitPoseLocal", 0];
};

KFH_fnc_forceUnitDowned = {
    params ["_unit", ["_source", objNull], ["_reason", "fatal damage"]];

    if (isNull _unit) exitWith {};
    if !(alive _unit) exitWith {};

    if (!isServer && {isPlayer _unit}) then {
        private _sourceType = if (isNull _source) then { "unknown" } else { typeOf _source };
        [_unit, _sourceType, _reason] remoteExecCall ["KFH_fnc_registerForcedDownedOnServer", 2];
    };

    [_unit, _source, _reason] call KFH_fnc_armDownedState;

        if (isPlayer _unit) then {
            missionNamespace setVariable ["KFH_lastHumanCasualtyAt", time, true];
            if (isServer) then {
                [_unit, _reason] call KFH_fnc_announcePlayerDowned;
            };
            if (local _unit) then {
                missionNamespace setVariable ["KFH_reviveCleanupUntil", -1];
                ["local_downed_notice"] call KFH_fnc_localNotifyKey;
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
    private _dragCarrier = _casualty getVariable ["KFH_draggedBy", objNull];
    if (!isNull _dragCarrier || {_casualty getVariable ["KFH_draggedBodyBusy", false]}) then {
        if (!isNull _dragCarrier) then {
            [_dragCarrier, _casualty, "revive"] remoteExecCall ["KFH_fnc_cleanupDraggingBodyLocal", _dragCarrier];
        };
        [objNull, _casualty, "revive-casualty-local"] call KFH_fnc_cleanupDraggingBodyLocal;
        [format [
            "Revive drag cleanup casualty=%1 carrier=%2 vehicleCasualty=%3",
            name _casualty,
            if (isNull _dragCarrier) then {"<none>"} else {name _dragCarrier},
            _wasVehicleCasualty
        ]] call KFH_fnc_log;
    };
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

    private _wasForcedDowned = _casualty getVariable ["KFH_forcedDowned", false];
    [_casualty, _graceSeconds <= 0] call KFH_fnc_clearDownedState;
    [format [
        "Revive completed casualty=%1 forced=%2 vehicleCasualty=%3 damage=%4",
        name _casualty,
        _wasForcedDowned,
        _wasVehicleCasualty,
        _healDamage
    ]] call KFH_fnc_log;

    if (_wasForcedDowned) then {
        _casualty setDamage (_healDamage max 0);
        [_casualty] call KFH_fnc_applyPrototypeCarryCapacity;
        [_casualty] call KFH_fnc_playReviveGetUpAnimation;
        if (isPlayer _casualty) then {
            [] remoteExecCall ["KFH_fnc_scheduleLocalReviveCleanup", _casualty];
        };
    } else {
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
        _incomingDamage = [_unit, _incomingDamage, _source] call KFH_fnc_getFriendlyFireScaledDamage;
        private _damageScale = missionNamespace getVariable ["KFH_playerDamageTakenScale", 1];
        private _scaledDamage = _currentDamage + (((_incomingDamage - _currentDamage) max 0) * _damageScale);
        _scaledDamage = (_scaledDamage max 0) min 1;
        if (_unit getVariable ["KFH_forcedDowned", false]) exitWith { [_unit] call KFH_fnc_getSuppressedDownedDamage };
        if (
            (_scaledDamage < _damageThreshold) &&
            {_scaledDamage < _totalDamageThreshold}
        ) exitWith { _scaledDamage };
        if !([_unit] call KFH_fnc_hasRescueCoverageFor) exitWith { _scaledDamage };

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
        [_unit, "killed fallback"] call KFH_fnc_announcePlayerDowned;
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

KFH_fnc_registerForcedDownedOnServer = {
    params ["_unit", ["_sourceType", "unknown"], ["_reason", "fatal damage"]];

    if (!isServer) exitWith {};
    if (isNull _unit) exitWith {};
    if !(alive _unit) exitWith {};

    _unit setVariable ["KFH_forcedDowned", true, true];
    _unit setVariable ["KFH_forcedDownedAt", time, true];
    missionNamespace setVariable ["KFH_lastHumanCasualtyAt", time, true];
    [_unit, _reason] call KFH_fnc_announcePlayerDowned;

    [format [
        "Forced downed server sync for %1 reason=%2 source=%3 rescuers=%4.",
        name _unit,
        _reason,
        _sourceType,
        count ([] call KFH_fnc_getPotentialRescuers)
    ]] call KFH_fnc_log;
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
        alive _x &&
        {!([_x] call KFH_fnc_isIncapacitated)}
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
    if ((count ([] call KFH_fnc_getIncapacitatedPlayers)) isEqualTo 0) exitWith { false };
    if ((count ([] call KFH_fnc_getPotentialRescuers)) > 0) exitWith { true };

    KFH_debugTeammateEnabled &&
    {((count ([] call KFH_fnc_getHumanPlayers)) > 0)} &&
    {((count ([] call KFH_fnc_getHumanPlayers)) <= KFH_debugTeammateHumanThreshold)}
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

