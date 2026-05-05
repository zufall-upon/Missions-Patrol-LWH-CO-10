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
            ["mission_success_partial", [_boardedAtDeparture, _aliveAtDeparture]] call KFH_fnc_localizeAnnouncement
        } else {
            ["mission_success_full"] call KFH_fnc_localizeAnnouncement
        };
        [true, _message] call KFH_fnc_completeMission;
    } else {
        [false, ["mission_failed_empty_lift"] call KFH_fnc_localizeAnnouncement] call KFH_fnc_completeMission;
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
            [false, ["mission_failed_heli_lost"] call KFH_fnc_localizeAnnouncement] call KFH_fnc_completeMission;
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
        private _juggernautCount = missionNamespace getVariable ["KFH_extractionFinaleJuggernautCount", 1];
        for "_i" from 1 to (_juggernautCount max 1) do {
            private _juggernaut = [_juggernautRoles] call KFH_fnc_selectSpecialRoleFromEntries;
            if ((count _juggernaut) >= 2 && {(_juggernaut select 0) in ["goliath", "smasher"]} && {!((_juggernaut select 1) isEqualTo "")}) then {
                _queue pushBack _juggernaut;
            };
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
                true
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

