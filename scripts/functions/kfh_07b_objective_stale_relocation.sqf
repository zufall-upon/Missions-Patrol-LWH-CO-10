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

    [1, _reason] call KFH_fnc_addRushDebt;

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
    private _forceObjectiveDistance = missionNamespace getVariable ["KFH_waveRecycleForceObjectiveDistance", _objectiveDistance + 180];
    private _humanDistance = missionNamespace getVariable ["KFH_waveRecycleHumanDistance", 260];
    private _kept = [];
    private _removed = 0;

    {
        if (alive _x) then {
            private _farFromObjective = (_x distance2D _markerPos) > _objectiveDistance;
            private _veryFarFromObjective = (_x distance2D _markerPos) > _forceObjectiveDistance;
            private _offscreen = ([getPosATL _x] call KFH_fnc_getNearestHumanDistance) > _humanDistance;
            private _canRecycle = _farFromObjective && {_offscreen} && {_veryFarFromObjective || {!([_x] call KFH_fnc_isUnitVisibleToHumans)}};
            if (_canRecycle) then {
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
    private _targetHuman = [_markerPos] call KFH_fnc_getWavePlayerAnchor;
    private _targetPos = if (!isNull _targetHuman) then { getPosATL _targetHuman } else { +_markerPos };
    private _spawnStage = "objective-cover";
    private _spawnPos = [];
    if (!isNull _targetHuman) then {
        private _laneResult = [_targetHuman, _markerPos, format ["relocate-%1", typeOf _unit]] call KFH_fnc_findPlayerCheckpointLaneSpawnPosition;
        if ((count _laneResult) >= 2) then {
            _spawnPos = _laneResult select 0;
            _spawnStage = _laneResult select 1;
        };
    };
    if ((count _spawnPos) < 2) then {
        _spawnPos = [_markerPos] call KFH_fnc_findCoveredObjectiveRelocationPosition;
    };
    if ((count _spawnPos) < 2) then {
        _spawnPos = [
            _markerPos,
            missionNamespace getVariable ["KFH_staleEnemyRelocateMinDistance", 90],
            missionNamespace getVariable ["KFH_staleEnemyRelocateMaxDistance", 190]
        ] call KFH_fnc_findSafeDistantSpawnPosition;
    };
    if ((count _spawnPos) < 2) exitWith { false };

    private _maxObjectiveDistance = missionNamespace getVariable [
        "KFH_staleEnemyRelocateMaxObjectiveDistance",
        (missionNamespace getVariable ["KFH_staleEnemyRelocateMaxDistance", 190]) + (missionNamespace getVariable ["KFH_staleEnemyRelocateCoverRadius", 95])
    ];
    if (!(_spawnStage in ["lane-hidden", "lane-open"]) && {(_spawnPos distance2D _markerPos) > _maxObjectiveDistance}) exitWith { false };

    private _isExternalZombie = (_unit getVariable ["KFH_enemyRole", ""]) isEqualTo "externalZombie";
    private _groupRef = group _unit;
    if (!_isExternalZombie) then {
        {
            deleteWaypoint _x;
        } forEach (waypoints _groupRef);
    };

    _unit setPosATL _spawnPos;
    _unit setDir (_spawnPos getDir _targetPos);
    _unit setVariable ["KFH_staleSince", -1];
    _unit setVariable ["KFH_staleRemoved", false, true];
    _unit setVariable ["KFH_nextCommandMoveAt", 0];
    _unit setVariable ["KFH_nextForcedDestinationAt", 0];
    if (_isExternalZombie) then {
        _unit setVariable ["WBK_AI_LastKnownLoc", _targetPos, true];
    } else {
        _unit enableAI "MOVE";
        _unit enableAI "PATH";
        _unit enableAI "TARGET";
        _unit enableAI "AUTOTARGET";
        _unit setUnitPos "UP";
        _unit setSpeedMode "FULL";
        _unit stop false;
        [_unit, _targetHuman, _targetPos] call KFH_fnc_driveEnemyTowardTarget;
    };

    [format [
        "Objective hostile relocated into player lane: %1 -> %2 stage=%3 target=%4.",
        typeOf _unit,
        mapGridPosition _spawnPos,
        _spawnStage,
        if (isNull _targetHuman) then { "checkpoint" } else { name _targetHuman }
    ]] call KFH_fnc_log;
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
    private _cpGraceDistance = missionNamespace getVariable ["KFH_staleEnemyObjectiveGraceDistance", KFH_captureRadius + 220];
    private _recycleDistance = missionNamespace getVariable ["KFH_waveRecycleObjectiveDistance", 240];
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
                            _x setVariable ["KFH_recyclePendingLogged", false];
                            _kept pushBack _x;
                        } else {
                            if ([_x] call KFH_fnc_isUnitVisibleToHumans) then {
                                _x setVariable ["KFH_staleSince", time];
                                _kept pushBack _x;
                            } else {
                                if (
                                    (missionNamespace getVariable ["KFH_waveRecycleOffscreenEnabled", true]) &&
                                    {_markerName in allMapMarkers} &&
                                    {(_x distance2D _markerPos) > _recycleDistance}
                                ) then {
                                    _x setVariable ["KFH_staleSince", time];
                                    if !(_x getVariable ["KFH_recyclePendingLogged", false]) then {
                                        _x setVariable ["KFH_recyclePendingLogged", true];
                                        [format ["Objective hostile queued for next-wave recycle: %1 at %2.", typeOf _x, mapGridPosition (getPosATL _x)]] call KFH_fnc_log;
                                    };
                                    _kept pushBack _x;
                                } else {
                                    [_x, "left behind"] call KFH_fnc_unregisterStaleEnemy;
                                };
                            };
                        };
                    } else {
                        _kept pushBack _x;
                    };
                };
                };
            } else {
                _x setVariable ["KFH_staleSince", -1];
                _x setVariable ["KFH_recyclePendingLogged", false];
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

KFH_fnc_getCheckpointBlockingThreats = {
    params ["_objectiveEnemies", "_checkpointPos"];

    private _threatRadius = missionNamespace getVariable ["KFH_objectiveThreatRadius", KFH_objectiveThreatRadius];
    private _stallFarDistance = missionNamespace getVariable ["KFH_checkpointStallFarDistance", 140];
    private _invisibleDistance = missionNamespace getVariable ["KFH_checkpointStallInvisibleDistance", 95];

    _objectiveEnemies select {
        alive _x &&
        {
            ((_x distance2D _checkpointPos) <= _threatRadius) ||
            {
                (([getPosATL _x] call KFH_fnc_getNearestHumanDistance) <= _invisibleDistance) &&
                {[_x] call KFH_fnc_isUnitVisibleToHumans}
            } ||
            {
                ((_x distance2D _checkpointPos) <= _stallFarDistance) &&
                {[_x] call KFH_fnc_isUnitVisibleToHumans}
            }
        }
    }
};

KFH_fnc_nudgeObjectiveEnemiesTowardCheckpoint = {
    params ["_objectiveEnemies", "_checkpointPos"];

    private _nudged = 0;
    {
        if (alive _x && {!([_x] call KFH_fnc_isJuggernautEnemy)}) then {
            if (
                ((_x getVariable ["KFH_enemyRole", ""]) isEqualTo "externalZombie") &&
                {missionNamespace getVariable ["KFH_webKnightReplaceExternalOnStall", true]}
            ) then {
                [_x, "checkpoint stall"] call KFH_fnc_replaceWebKnightExternalZombie;
            } else {
                private _nearestHuman = [getPosATL _x] call KFH_fnc_getNearestHumanReferenceUnit;
                private _targetPos = if (
                    !isNull _nearestHuman &&
                    {(_nearestHuman distance2D _x) <= (missionNamespace getVariable ["KFH_checkpointNudgeHumanTargetDistance", 260])}
                ) then {
                    getPosATL _nearestHuman
                } else {
                    _checkpointPos
                };
                [_x, _nearestHuman, _targetPos] call KFH_fnc_driveEnemyTowardTarget;
            };
            _nudged = _nudged + 1;
        };
    } forEach _objectiveEnemies;

    _nudged
};

KFH_fnc_driveEnemyTowardTarget = {
    params ["_unit", ["_target", objNull], ["_fallbackPos", []]];

    if (isNull _unit || {!alive _unit}) exitWith {};

    private _targetPos = if (!isNull _target && {alive _target}) then {
        getPosATL _target
    } else {
        +_fallbackPos
    };
    if ((count _targetPos) < 2) exitWith {};

    if ((_unit getVariable ["KFH_enemyRole", ""]) isEqualTo "externalZombie") exitWith {
        _unit setVariable ["WBK_AI_LastKnownLoc", _targetPos, true];
    };

    private _groupRef = group _unit;
    if (!isNull _groupRef) then {
        {
            deleteWaypoint _x;
        } forEach (waypoints _groupRef);
        _groupRef allowFleeing 0;
        _groupRef setFormation "FILE";
        _groupRef setBehaviour "COMBAT";
        _groupRef setCombatMode "RED";
        _groupRef setSpeedMode "FULL";
        _groupRef move _targetPos;
        private _wp = _groupRef addWaypoint [_targetPos, 0];
        _wp setWaypointType "MOVE";
        _wp setWaypointSpeed "FULL";
        _wp setWaypointBehaviour "COMBAT";
        _wp setWaypointCombatMode "RED";
        _wp setWaypointCompletionRadius 4;
    };

    {
        _unit enableAI _x;
    } forEach ["MOVE", "PATH", "TARGET", "AUTOTARGET", "FSM"];
    _unit allowFleeing 0;
    _unit stop false;
    _unit forceWalk false;
    _unit setSpeedMode "FULL";
    _unit setBehaviourStrong "COMBAT";
    _unit setCombatMode "RED";

    if (!isNull _target && {alive _target}) then {
        _unit reveal [_target, 4];
        if (!isNull _groupRef) then {
            _groupRef reveal [_target, 4];
        };
        _unit doWatch _target;
        if ((_unit getVariable ["KFH_enemyRole", "melee"]) in ["agent", "ranged", "military"]) then {
            _unit doTarget _target;
        };
    };

    _unit commandMove _targetPos;
    _unit doMove _targetPos;
    _unit setDestination [_targetPos, "LEADER DIRECT", true];
    _unit setVariable ["KFH_nextMoveUpdateAt", 0];
    _unit setVariable ["KFH_nextForcedDestinationAt", 0];
};

