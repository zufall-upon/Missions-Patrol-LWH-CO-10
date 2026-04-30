KFH_fnc_dynamicRouteLog = {
    params ["_message"];
    diag_log format ["[KFH][Route] %1", _message];
};

KFH_fnc_dynamicRouteRandom = {
    params [["_max", 1]];

    private _seed = missionNamespace getVariable ["KFH_dynamicRouteSeed", 0];
    private _counter = missionNamespace getVariable ["KFH_dynamicRouteRandomCounter", 0];
    missionNamespace setVariable ["KFH_dynamicRouteRandomCounter", _counter + 1];

    (_seed + _counter) random _max
};

KFH_fnc_dynamicRouteSelectRandom = {
    params ["_items"];

    if ((count _items) isEqualTo 0) exitWith { objNull };

    private _roll = [count _items] call KFH_fnc_dynamicRouteRandom;
    _items select ((floor _roll) min ((count _items) - 1))
};

KFH_fnc_isDebugShortRouteActive = {
    private _enabled = missionNamespace getVariable ["KFH_debugShortRouteEnabled", false];
    private _force = missionNamespace getVariable ["KFH_debugShortRouteForce", false];
    private _autoInEden = missionNamespace getVariable ["KFH_debugShortRouteAutoInEden", true];

    _enabled && {
        _force || {_autoInEden && {is3DENPreview}}
    }
};

KFH_fnc_applyDebugShortRouteSettings = {
    if !([] call KFH_fnc_isDebugShortRouteActive) exitWith { false };
    if (missionNamespace getVariable ["KFH_debugShortRouteApplied", false]) exitWith { true };

    private _scale = missionNamespace getVariable ["KFH_debugShortRouteScale", 0.33];
    private _baseSpacing = missionNamespace getVariable ["KFH_dynamicRouteMinSpacing", 850];
    private _baseRatio = missionNamespace getVariable ["KFH_dynamicRouteLengthRatio", 0.58];
    private _baseJitter = missionNamespace getVariable ["KFH_dynamicRouteJitter", 420];
    private _baseMargin = missionNamespace getVariable ["KFH_dynamicRouteEdgeMargin", 850];

    missionNamespace setVariable ["KFH_dynamicRouteMinSpacing", (round (_baseSpacing * _scale)) max (missionNamespace getVariable ["KFH_debugShortRouteMinSpacing", 280])];
    missionNamespace setVariable ["KFH_dynamicRouteLengthRatio", missionNamespace getVariable ["KFH_debugShortRouteLengthRatio", (_baseRatio * _scale)]];
    missionNamespace setVariable ["KFH_dynamicRouteJitter", (round (_baseJitter * _scale)) max (missionNamespace getVariable ["KFH_debugShortRouteJitter", 140])];
    missionNamespace setVariable ["KFH_dynamicRouteEdgeMargin", (_baseMargin min (missionNamespace getVariable ["KFH_debugShortRouteEdgeMargin", 450])) max 250];
    missionNamespace setVariable ["KFH_debugShortRouteActive", true, true];
    missionNamespace setVariable ["KFH_debugShortRouteApplied", true, true];

    [format [
        "debug short route enabled: spacing=%1 ratio=%2 jitter=%3 margin=%4.",
        missionNamespace getVariable ["KFH_dynamicRouteMinSpacing", 850],
        missionNamespace getVariable ["KFH_dynamicRouteLengthRatio", 0.58],
        missionNamespace getVariable ["KFH_dynamicRouteJitter", 420],
        missionNamespace getVariable ["KFH_dynamicRouteEdgeMargin", 850]
    ]] call KFH_fnc_dynamicRouteLog;

    true
};

KFH_fnc_dynamicRouteIsAcceptable = {
    params [["_points", []]];

    if ((count _points) < 3) exitWith { false };
    private _start = _points select 0;
    private _extract = _points select ((count _points) - 1);
    private _checkpointCount = ((count _points) - 2) max 1;
    private _spacing = missionNamespace getVariable ["KFH_dynamicRouteMinSpacing", 850];
    private _minimum = if (missionNamespace getVariable ["KFH_debugShortRouteActive", false]) then {
        missionNamespace getVariable ["KFH_debugShortRouteMinTotalDistance", 1900]
    } else {
        _spacing * (_checkpointCount + 1) * 0.72
    };

    (_start distance2D _extract) >= _minimum
};

KFH_fnc_dynamicRouteHasNodeSpacing = {
    params [["_points", []]];

    if ((count _points) < 3) exitWith { false };
    private _spacing = missionNamespace getVariable ["KFH_dynamicRouteMinSpacing", 850];
    private _factor = missionNamespace getVariable ["KFH_dynamicRouteMinNodeSpacingFactor", 0.62];
    private _targetSegment = missionNamespace getVariable ["KFH_debugShortRouteTargetSegment", _spacing];
    private _minSegment = if (missionNamespace getVariable ["KFH_debugShortRouteActive", false]) then {
        (_targetSegment * _factor) max 220
    } else {
        (_spacing * _factor) max 320
    };

    private _ok = true;
    for "_i" from 0 to ((count _points) - 2) do {
        if (((_points select _i) distance2D (_points select (_i + 1))) < _minSegment) exitWith {
            _ok = false;
        };
    };

    _ok
};

KFH_fnc_dynamicRouteCandidateIsUsable = {
    params [["_points", []]];

    ([_points] call KFH_fnc_dynamicRouteIsAcceptable) &&
    {[_points] call KFH_fnc_dynamicRouteHasNodeSpacing} &&
    {(_points findIf { !([_x] call KFH_fnc_dynamicRouteIsSafePos) }) < 0}
};

KFH_fnc_dynamicRouteRetryRelaxed = {
    if !(missionNamespace getVariable ["KFH_debugShortRouteActive", false]) exitWith { [[], 0] };

    missionNamespace setVariable ["KFH_dynamicRouteMinSpacing", (missionNamespace getVariable ["KFH_dynamicRouteMinSpacing", 420]) max 520];
    missionNamespace setVariable ["KFH_dynamicRouteLengthRatio", (missionNamespace getVariable ["KFH_dynamicRouteLengthRatio", 0.14]) max 0.16];
    missionNamespace setVariable ["KFH_dynamicRouteJitter", (missionNamespace getVariable ["KFH_dynamicRouteJitter", 180]) max 220];
    missionNamespace setVariable ["KFH_debugShortRouteTargetSegment", (missionNamespace getVariable ["KFH_debugShortRouteTargetSegment", 680]) max 760];
    missionNamespace setVariable ["KFH_dynamicRouteRoadSearchRadius", (missionNamespace getVariable ["KFH_dynamicRouteRoadSearchRadius", 360]) max 520];
    [format [
        "debug short route retry: spacing=%1 ratio=%2 targetSegment=%3.",
        missionNamespace getVariable ["KFH_dynamicRouteMinSpacing", 520],
        missionNamespace getVariable ["KFH_dynamicRouteLengthRatio", 0.16],
        missionNamespace getVariable ["KFH_debugShortRouteTargetSegment", 760]
    ]] call KFH_fnc_dynamicRouteLog;

    [] call KFH_fnc_dynamicRouteBuildPoints
};

KFH_fnc_dynamicRouteClampPos = {
    private _pos = _this;
    if (
        (_pos isEqualType []) &&
        {(count _pos) isEqualTo 1} &&
        {(_pos select 0) isEqualType []}
    ) then {
        _pos = _pos select 0;
    };

    private _world = worldSize;
    private _margin = (missionNamespace getVariable ["KFH_dynamicRouteEdgeMargin", 850]) min (_world * 0.25);
    private _x = ((_pos select 0) max _margin) min (_world - _margin);
    private _y = ((_pos select 1) max _margin) min (_world - _margin);

    [_x, _y, 0]
};

KFH_fnc_dynamicRouteIsSafePos = {
    params ["_pos"];

    if (surfaceIsWater _pos) exitWith { false };
    if ((getTerrainHeightASL _pos) < -0.5) exitWith { false };

    private _sample = missionNamespace getVariable ["KFH_dynamicRouteSlopeSampleDistance", 9];
    private _maxDiff = missionNamespace getVariable ["KFH_dynamicRouteMaxSlopeHeightDiff", 3.8];
    private _h0 = getTerrainHeightASL _pos;
    private _hX = getTerrainHeightASL [(_pos select 0) + _sample, _pos select 1, 0];
    private _hY = getTerrainHeightASL [_pos select 0, (_pos select 1) + _sample, 0];

    if ((abs (_h0 - _hX)) > _maxDiff) exitWith { false };
    if ((abs (_h0 - _hY)) > _maxDiff) exitWith { false };

    private _clearance = missionNamespace getVariable ["KFH_dynamicRouteSafeObjectRadius", 32];
    private _blockingObjects = nearestObjects [_pos, ["House", "Building", "Wall", "Fence"], _clearance];
    if ((count _blockingObjects) > 0) exitWith { false };
    private _terrainClearance = missionNamespace getVariable ["KFH_dynamicRouteSafeTerrainRadius", 24];
    private _terrainObjects = nearestTerrainObjects [_pos, ["HOUSE", "BUILDING", "WALL", "FENCE"], _terrainClearance, false, true];
    if ((count _terrainObjects) > 0) exitWith { false };
    if ((count (_pos nearRoads 50)) isEqualTo 0) exitWith { false };

    true
};

KFH_fnc_dynamicRouteSegmentIsLand = {
    params ["_from", "_to"];

    private _distance = _from distance2D _to;
    private _step = missionNamespace getVariable ["KFH_dynamicRouteSegmentSampleDistance", 220];
    private _samples = (ceil (_distance / (_step max 50))) max 2;
    private _ok = true;

    for "_i" from 0 to _samples do {
        private _t = _i / _samples;
        private _pos = [
            (_from select 0) + ((_to select 0) - (_from select 0)) * _t,
            (_from select 1) + ((_to select 1) - (_from select 1)) * _t,
            0
        ];

        if (surfaceIsWater _pos || {(getTerrainHeightASL _pos) < -0.5}) exitWith {
            _ok = false;
        };
    };

    _ok
};

KFH_fnc_dynamicRouteFindLandRoadPos = {
    params ["_rawPos"];

    private _radius = missionNamespace getVariable ["KFH_dynamicRouteRoadSearchRadius", 360];
    private _attempts = missionNamespace getVariable ["KFH_dynamicRouteRoadAttempts", 80];
    private _requireRoads = missionNamespace getVariable ["KFH_dynamicRouteRequireRoads", true];
    private _best = [];

    for "_i" from 0 to (_attempts - 1) do {
        private _candidate = if (_i isEqualTo 0) then {
            _rawPos
        } else {
            [
                (_rawPos select 0) + (([2] call KFH_fnc_dynamicRouteRandom) - 1) * _radius,
                (_rawPos select 1) + (([2] call KFH_fnc_dynamicRouteRandom) - 1) * _radius,
                0
            ] call KFH_fnc_dynamicRouteClampPos
        };

        if !(surfaceIsWater _candidate) then {
            private _roads = _candidate nearRoads _radius;
            if ((count _roads) > 0) then {
                private _validRoads = _roads select { !isNull _x };
                if ((count _validRoads) > 0) then {
                    private _roadPos = getPosATL ([_validRoads] call KFH_fnc_dynamicRouteSelectRandom);
                    if ([_roadPos] call KFH_fnc_dynamicRouteIsSafePos) then {
                        _best = [_roadPos select 0, _roadPos select 1, 0];
                    };
                };
            } else {
                if (!_requireRoads && {[_candidate] call KFH_fnc_dynamicRouteIsSafePos}) then {
                    _best = [_candidate select 0, _candidate select 1, 0];
                };
            };
        };

        if ((count _best) > 0) exitWith {};
    };

    _best
};

KFH_fnc_dynamicRouteCollectFallbackRoads = {
    private _cached = missionNamespace getVariable ["KFH_dynamicRouteFallbackRoads", []];
    if ((count _cached) > 0) exitWith { _cached };

    private _world = worldSize;
    private _margin = (missionNamespace getVariable ["KFH_dynamicRouteEdgeMargin", 850]) min (_world * 0.25);
    private _step = missionNamespace getVariable ["KFH_dynamicRouteFallbackGridStep", 900];
    private _radius = missionNamespace getVariable ["KFH_dynamicRouteRoadSearchRadius", 360];
    private _roadsFound = [];

    for "_x" from _margin to (_world - _margin) step _step do {
        for "_y" from _margin to (_world - _margin) step _step do {
            private _probe = [_x, _y, 0];
            if !(surfaceIsWater _probe) then {
                private _roads = _probe nearRoads _radius;
                if ((count _roads) > 0) then {
                    private _road = _roads select 0;
                    private _roadPos = getPosATL _road;
                    private _safe = [_roadPos select 0, _roadPos select 1, 0];
                    if ([_safe] call KFH_fnc_dynamicRouteIsSafePos) then {
                        if ((_roadsFound findIf { (_x distance2D _safe) < (_step * 0.35) }) < 0) then {
                            _roadsFound pushBack _safe;
                        };
                    };
                };
            };
        };
    };

    missionNamespace setVariable ["KFH_dynamicRouteFallbackRoads", _roadsFound];
    [format ["fallback road scan found %1 safe road nodes", count _roadsFound]] call KFH_fnc_dynamicRouteLog;
    _roadsFound
};

KFH_fnc_dynamicRouteFindBestFallbackEnd = {
    params [
        "_start",
        "_minDistance",
        ["_targetDistance", -1],
        ["_maxDistance", -1],
        ["_preferredDir", -1],
        ["_maxTurnDegrees", missionNamespace getVariable ["KFH_dynamicRouteMaxTurnDegrees", 110]]
    ];

    private _candidates = [] call KFH_fnc_dynamicRouteCollectFallbackRoads;
    private _best = [];
    private _bestDistance = -1;
    private _bestScore = 1e12;
    private _preferTarget = _targetDistance > 0;

    {
        private _distance = _start distance2D _x;
        private _turnOk = true;
        private _turnPenalty = 0;
        if (_preferredDir >= 0) then {
            private _dirTo = _start getDir _x;
            _turnPenalty = [_preferredDir, _dirTo] call KFH_fnc_dynamicRouteAngleDelta;
            _turnOk = _turnPenalty <= _maxTurnDegrees;
        };
        if (
            (_distance > _bestDistance || {_preferTarget}) &&
            {_distance >= _minDistance} &&
            {(_maxDistance < 0) || {_distance <= _maxDistance}} &&
            {_turnOk} &&
            {[_start, _x] call KFH_fnc_dynamicRouteSegmentIsLand}
        ) then {
            private _score = if (_preferTarget) then { abs (_distance - _targetDistance) + (_turnPenalty * 2) } else { -_distance + (_turnPenalty * 2) };
            if (_score < _bestScore) then {
                _best = _x;
                _bestDistance = _distance;
                _bestScore = _score;
            };
        };
    } forEach _candidates;

    if ((count _best) isEqualTo 0) then {
        {
            private _distance = _start distance2D _x;
            private _turnOk = true;
            if (_preferredDir >= 0) then {
                _turnOk = ([_preferredDir, _start getDir _x] call KFH_fnc_dynamicRouteAngleDelta) <= (_maxTurnDegrees + 25);
            };
            if (
                (_distance > _bestDistance) &&
                {_distance >= _minDistance} &&
                {(_maxDistance < 0) || {_distance <= _maxDistance}} &&
                {_turnOk} &&
                {[_start, _x] call KFH_fnc_dynamicRouteSegmentIsLand}
            ) then {
                _best = _x;
                _bestDistance = _distance;
            };
        } forEach _candidates;
    };

    _best
};

KFH_fnc_dynamicRouteBuildEmergencyFallback = {
    [] call KFH_fnc_applyDebugShortRouteSettings;

    private _countMin = missionNamespace getVariable ["KFH_checkpointCountMin", 6];
    private _countMax = missionNamespace getVariable ["KFH_checkpointCountMax", 10];
    private _count = ((missionNamespace getVariable ["KFH_checkpointCount", 6]) max _countMin) min _countMax;
    private _roads = [] call KFH_fnc_dynamicRouteCollectFallbackRoads;
    if ((count _roads) < (_count + 2)) exitWith {
        ["Emergency route failed: not enough safe fallback road nodes."] call KFH_fnc_dynamicRouteLog;
        [[], 0]
    };

    private _spacing = missionNamespace getVariable ["KFH_dynamicRouteMinSpacing", 850];
    private _targetSegment = missionNamespace getVariable ["KFH_debugShortRouteTargetSegment", _spacing];
    if (!(missionNamespace getVariable ["KFH_debugShortRouteActive", false]) || {_targetSegment <= 0}) then {
        _targetSegment = _spacing * 1.15;
    };
    private _minTotal = if (missionNamespace getVariable ["KFH_debugShortRouteActive", false]) then {
        missionNamespace getVariable ["KFH_debugShortRouteMinTotalDistance", 1900]
    } else {
        _spacing * (_count + 1) * 0.72
    };
    private _targetDistance = (_targetSegment * (_count + 1)) max _minTotal;
    private _maxDistance = _targetDistance * 1.55;

    private _start = [];
    private _end = [];
    private _dir = 0;
    private _bestScore = 1e12;
    {
        private _candidateStart = _x;
        {
            private _candidateEnd = _x;
            private _distance = _candidateStart distance2D _candidateEnd;
            if (
                _distance >= _minTotal &&
                {_distance <= _maxDistance} &&
                {[_candidateStart, _candidateEnd] call KFH_fnc_dynamicRouteSegmentIsLand}
            ) then {
                private _score = abs (_distance - _targetDistance);
                if (_score < _bestScore) then {
                    _bestScore = _score;
                    _start = _candidateStart;
                    _end = _candidateEnd;
                };
            };
        } forEach _roads;
    } forEach _roads;

    if ((count _start) isEqualTo 0 || {(count _end) isEqualTo 0}) exitWith {
        ["Emergency route failed: no acceptable start/end pair."] call KFH_fnc_dynamicRouteLog;
        [[], 0]
    };

    _dir = [_start, _end] call BIS_fnc_dirTo;
    private _totalDistance = _start distance2D _end;
    private _segmentTarget = _totalDistance / ((_count + 1) max 1);
    private _minSegment = (_spacing * (missionNamespace getVariable ["KFH_dynamicRouteMinSegmentFactor", 0.58])) max (_segmentTarget * 0.45);
    private _maxSegment = (_spacing * (missionNamespace getVariable ["KFH_dynamicRouteMaxSegmentFactor", 1.75])) max (_segmentTarget * 1.65);
    private _minProgress = _minSegment * (missionNamespace getVariable ["KFH_dynamicRouteMinForwardProgressFactor", 0.42]);
    private _points = [_start];
    private _failed = false;

    for "_i" from 1 to _count do {
        if (!_failed) then {
            private _targetProgress = _segmentTarget * _i;
            private _base = [
                (_start select 0) + ((_end select 0) - (_start select 0)) * (_i / (_count + 1)),
                (_start select 1) + ((_end select 1) - (_start select 1)) * (_i / (_count + 1)),
                0
            ];
            private _previous = _points select ((count _points) - 1);
            private _best = [];
            private _bestCpScore = 1e12;
            {
                private _candidate = _x;
                private _progress = [_start, _candidate, _dir] call KFH_fnc_dynamicRouteForwardProgress;
                private _segmentDistance = _previous distance2D _candidate;
                private _turn = [_dir, _previous getDir _candidate] call KFH_fnc_dynamicRouteAngleDelta;
                private _duplicate = (_points findIf { (_x distance2D _candidate) < (_minSegment * 0.5) }) >= 0;
                if (
                    !_duplicate &&
                    {_progress > (_targetProgress - (_segmentTarget * 0.75))} &&
                    {_progress < (_targetProgress + (_segmentTarget * 0.75))} &&
                    {_segmentDistance >= _minSegment} &&
                    {_segmentDistance <= _maxSegment} &&
                    {([_previous, _candidate, _dir] call KFH_fnc_dynamicRouteForwardProgress) >= _minProgress} &&
                    {_turn <= ((missionNamespace getVariable ["KFH_dynamicRouteMaxTurnDegrees", 95]) + 25)} &&
                    {[_previous, _candidate] call KFH_fnc_dynamicRouteSegmentIsLand}
                ) then {
                    private _score = (abs (_progress - _targetProgress)) + ((_candidate distance2D _base) * 0.7) + (_turn * 4);
                    if (_score < _bestCpScore) then {
                        _bestCpScore = _score;
                        _best = _candidate;
                    };
                };
            } forEach _roads;

            if ((count _best) isEqualTo 0) then {
                _best = [_previous, _minSegment, _segmentTarget, _maxSegment, _dir, (missionNamespace getVariable ["KFH_dynamicRouteMaxTurnDegrees", 95]) + 25] call KFH_fnc_dynamicRouteFindBestFallbackEnd;
            };

            if ((count _best) isEqualTo 0) then {
                _failed = true;
                _points = [];
            } else {
                _points pushBack _best;
            };
        };
    };

    if ((count _points) isEqualTo 0) then {
        ["Emergency route strict interpolation failed; using linear road fallback."] call KFH_fnc_dynamicRouteLog;
        _points = [_start];
        private _oldSearch = missionNamespace getVariable ["KFH_dynamicRouteRoadSearchRadius", 360];
        missionNamespace setVariable ["KFH_dynamicRouteRoadSearchRadius", _oldSearch max 700];
        for "_i" from 1 to _count do {
            private _base = [
                (_start select 0) + ((_end select 0) - (_start select 0)) * (_i / (_count + 1)),
                (_start select 1) + ((_end select 1) - (_start select 1)) * (_i / (_count + 1)),
                0
            ];
            private _checkpoint = [_base] call KFH_fnc_dynamicRouteFindLandRoadPos;
            if ((count _checkpoint) isEqualTo 0) then {
                _checkpoint = _base;
            };
            _points pushBack _checkpoint;
        };
        missionNamespace setVariable ["KFH_dynamicRouteRoadSearchRadius", _oldSearch];
    };

    if (((_points select ((count _points) - 1)) distance2D _end) < (_minSegment * 0.55)) then {
        ["Emergency route final leg is short; keeping route so extraction marker is still rebuilt."] call KFH_fnc_dynamicRouteLog;
    };

    _points pushBack _end;
    [format ["Emergency route selected: checkpoints=%1 start=%2 extract=%3 distance=%4m", _count, mapGridPosition _start, mapGridPosition _end, round _totalDistance]] call KFH_fnc_dynamicRouteLog;
    [_points, _dir]
};

KFH_fnc_dynamicRouteBuildForcedMarkerFallback = {
    [] call KFH_fnc_applyDebugShortRouteSettings;

    private _countMin = missionNamespace getVariable ["KFH_checkpointCountMin", 6];
    private _countMax = missionNamespace getVariable ["KFH_checkpointCountMax", 10];
    private _count = ((missionNamespace getVariable ["KFH_checkpointCount", 6]) max _countMin) min _countMax;
    private _spacing = missionNamespace getVariable ["KFH_dynamicRouteMinSpacing", 850];
    private _targetSegment = missionNamespace getVariable ["KFH_debugShortRouteTargetSegment", _spacing];
    if (!(missionNamespace getVariable ["KFH_debugShortRouteActive", false]) || {_targetSegment <= 0}) then {
        _targetSegment = _spacing * 1.15;
    };
    private _minTotal = if (missionNamespace getVariable ["KFH_debugShortRouteActive", false]) then {
        missionNamespace getVariable ["KFH_debugShortRouteMinTotalDistance", 1900]
    } else {
        _spacing * (_count + 1) * 0.72
    };
    private _targetDistance = (_targetSegment * (_count + 1)) max _minTotal;
    private _world = worldSize;
    private _start = if ("kfh_start" in allMapMarkers) then { getMarkerPos "kfh_start" } else { [_world * 0.5, _world * 0.5, 0] };
    private _center = [_world * 0.5, _world * 0.5, 0];
    private _baseDir = _center getDir _start;
    private _dirs = [_baseDir, _baseDir + 45, _baseDir - 45, _baseDir + 90, _baseDir - 90, _baseDir + 135, _baseDir - 135, _baseDir + 180];
    private _end = [];
    private _dir = _baseDir;
    private _oldSearch = missionNamespace getVariable ["KFH_dynamicRouteRoadSearchRadius", 360];
    missionNamespace setVariable ["KFH_dynamicRouteRoadSearchRadius", _oldSearch max 700];

    {
        if ((count _end) isEqualTo 0) then {
            private _candidate = [_start, _targetDistance, _x] call KFH_fnc_dynamicRouteRelPos;
            private _road = [_candidate] call KFH_fnc_dynamicRouteFindLandRoadPos;
            if (
                (count _road) > 0 &&
                {(_start distance2D _road) >= _minTotal} &&
                {[_start, _road] call KFH_fnc_dynamicRouteSegmentIsLand}
            ) then {
                _end = _road;
                _dir = [_start, _end] call BIS_fnc_dirTo;
            };
        };
    } forEach _dirs;

    if ((count _end) isEqualTo 0) then {
        _dir = _baseDir;
        _end = [_start, _targetDistance, _dir] call KFH_fnc_dynamicRouteRelPos;
    };

    private _points = [_start];
    for "_i" from 1 to _count do {
        private _base = [
            (_start select 0) + ((_end select 0) - (_start select 0)) * (_i / (_count + 1)),
            (_start select 1) + ((_end select 1) - (_start select 1)) * (_i / (_count + 1)),
            0
        ];
        private _checkpoint = [_base] call KFH_fnc_dynamicRouteFindLandRoadPos;
        if ((count _checkpoint) isEqualTo 0) then {
            _checkpoint = _base;
        };
        _points pushBack _checkpoint;
    };
    missionNamespace setVariable ["KFH_dynamicRouteRoadSearchRadius", _oldSearch];

    _points pushBack _end;
    [format ["Forced route fallback placed markers from editor start to rebuilt LZ: checkpoints=%1 start=%2 extract=%3 distance=%4m", _count, mapGridPosition _start, mapGridPosition _end, round (_start distance2D _end)]] call KFH_fnc_dynamicRouteLog;
    [_points, _dir]
};

KFH_fnc_dynamicRouteCollectAnchors = {
    private _world = worldSize;
    private _margin = (missionNamespace getVariable ["KFH_dynamicRouteEdgeMargin", 850]) min (_world * 0.25);
    private _anchors = [];

    if (missionNamespace getVariable ["KFH_dynamicRouteUseLocationAnchors", true]) then {
        private _types = missionNamespace getVariable ["KFH_dynamicRouteLocationTypes", []];
        private _locations = nearestLocations [[_world * 0.5, _world * 0.5, 0], _types, _world];

        {
            private _raw = locationPosition _x;
            if (
                (_raw distance2D [0, 0, 0]) > 100 &&
                {(_raw select 0) > _margin} &&
                {(_raw select 0) < (_world - _margin)} &&
                {(_raw select 1) > _margin} &&
                {(_raw select 1) < (_world - _margin)}
            ) then {
                private _anchor = [_raw] call KFH_fnc_dynamicRouteFindLandRoadPos;
                if ((count _anchor) > 0 && {[_anchor] call KFH_fnc_dynamicRouteIsSafePos}) then {
                    _anchors pushBack _anchor;
                };
            };
        } forEach _locations;
    };

    private _attempts = missionNamespace getVariable ["KFH_dynamicRouteAnchorAttempts", 48];
    for "_i" from 1 to _attempts do {
        private _candidate = [
            _margin + ([((_world - (_margin * 2)) max 1)] call KFH_fnc_dynamicRouteRandom),
            _margin + ([((_world - (_margin * 2)) max 1)] call KFH_fnc_dynamicRouteRandom),
            0
        ];
        private _anchor = [_candidate] call KFH_fnc_dynamicRouteFindLandRoadPos;
        if ((count _anchor) > 0 && {[_anchor] call KFH_fnc_dynamicRouteIsSafePos}) then {
            _anchors pushBack _anchor;
        };
    };

    _anchors
};

KFH_fnc_dynamicRouteSetMarker = {
    params [
        "_name",
        "_pos",
        "_type",
        "_color",
        "_text",
        ["_dir", 0],
        ["_size", [1, 1]]
    ];

    private _marker = if (_name in allMapMarkers) then {
        _name
    } else {
        createMarker [_name, _pos]
    };

    _marker setMarkerPos _pos;
    _marker setMarkerType _type;
    _marker setMarkerColor _color;
    _marker setMarkerText _text;
    _marker setMarkerDir _dir;
    _marker setMarkerSize _size;
    _marker
};

KFH_fnc_dynamicRouteRelPos = {
    params ["_pos", "_distance", "_dir"];

    [
        (_pos select 0) + (sin _dir) * _distance,
        (_pos select 1) + (cos _dir) * _distance,
        0
    ] call KFH_fnc_dynamicRouteClampPos
};

KFH_fnc_dynamicRouteAngleDelta = {
    params ["_a", "_b"];

    abs (((_a - _b + 540) mod 360) - 180)
};

KFH_fnc_dynamicRouteForwardProgress = {
    params ["_from", "_to", "_dir"];

    (((_to select 0) - (_from select 0)) * (sin _dir)) + (((_to select 1) - (_from select 1)) * (cos _dir))
};

KFH_fnc_dynamicRouteBuildPoints = {
    [] call KFH_fnc_applyDebugShortRouteSettings;

    private _countMin = missionNamespace getVariable ["KFH_checkpointCountMin", 6];
    private _countMax = missionNamespace getVariable ["KFH_checkpointCountMax", 10];
    private _count = ((missionNamespace getVariable ["KFH_checkpointCount", 6]) max _countMin) min _countMax;
    private _world = worldSize;
    private _margin = (missionNamespace getVariable ["KFH_dynamicRouteEdgeMargin", 850]) min (_world * 0.25);
    private _spacing = missionNamespace getVariable ["KFH_dynamicRouteMinSpacing", 850];
    private _ratio = missionNamespace getVariable ["KFH_dynamicRouteLengthRatio", 0.58];
    private _jitter = missionNamespace getVariable ["KFH_dynamicRouteJitter", 420];
    private _maxLength = (_world - (_margin * 2)) max (_spacing * (_count + 1));
    private _length = ((_world * _ratio) max (_spacing * (_count + 1))) min _maxLength;
    private _debugTargetSegment = missionNamespace getVariable ["KFH_debugShortRouteTargetSegment", -1];
    if ((missionNamespace getVariable ["KFH_debugShortRouteActive", false]) && {_debugTargetSegment > 0}) then {
        _length = ((_debugTargetSegment * (_count + 1)) max (_spacing * (_count + 1))) min _maxLength;
    };
    private _start = [];
    private _dir = [360] call KFH_fnc_dynamicRouteRandom;
    private _end = [];
    private _anchors = [] call KFH_fnc_dynamicRouteCollectAnchors;
    private _preferTargetDistance = missionNamespace getVariable ["KFH_dynamicRoutePreferTargetDistance", true];

    if ((count _anchors) >= 2) then {
        _start = [_anchors] call KFH_fnc_dynamicRouteSelectRandom;
        private _bestDistance = -1;
        private _bestScore = 1e12;
        {
            private _distance = _start distance2D _x;
            if (
                (_distance > _bestDistance || {_preferTargetDistance}) &&
                {_distance >= (_spacing * (_count + 1) * 0.72)} &&
                {[_start, _x] call KFH_fnc_dynamicRouteSegmentIsLand}
            ) then {
                private _score = if (_preferTargetDistance) then { abs (_distance - _length) } else { -_distance };
                if (_score < _bestScore) then {
                    _bestDistance = _distance;
                    _bestScore = _score;
                    _end = _x;
                };
            };
        } forEach _anchors;

        if ((count _end) isEqualTo 0) then {
            {
                private _distance = _start distance2D _x;
                if ((_distance > _bestDistance) && {[_start, _x] call KFH_fnc_dynamicRouteSegmentIsLand}) then {
                    _bestDistance = _distance;
                    _end = _x;
                };
            } forEach _anchors;
        };

        if (_bestDistance > 0) then {
            _dir = [_start, _end] call BIS_fnc_dirTo;
            _length = _bestDistance;
            [format ["anchor route selected: candidates=%1 distance=%2m", count _anchors, round _bestDistance]] call KFH_fnc_dynamicRouteLog;
        } else {
            _start = [];
            _end = [];
        };
    };

    if ((count _start) isEqualTo 0 || {(count _end) isEqualTo 0}) then {
        for "_attempt" from 1 to 80 do {
            _dir = [360] call KFH_fnc_dynamicRouteRandom;
            private _candidateStart = [
                _margin + ([((_world - (_margin * 2)) max 1)] call KFH_fnc_dynamicRouteRandom),
                _margin + ([((_world - (_margin * 2)) max 1)] call KFH_fnc_dynamicRouteRandom),
                0
            ];
            private _candidateEnd = [_candidateStart, _length, _dir] call KFH_fnc_dynamicRouteRelPos;
            private _candidateStartRoad = [_candidateStart] call KFH_fnc_dynamicRouteFindLandRoadPos;
            private _candidateEndRoad = [_candidateEnd] call KFH_fnc_dynamicRouteFindLandRoadPos;
            private _endInside =
                ((count _candidateStartRoad) > 0) &&
                {((count _candidateEndRoad) > 0)} &&
                {(_candidateEndRoad select 0) > _margin} &&
                {(_candidateEndRoad select 0) < (_world - _margin)} &&
                {(_candidateEndRoad select 1) > _margin} &&
                {(_candidateEndRoad select 1) < (_world - _margin)} &&
                {[_candidateStartRoad] call KFH_fnc_dynamicRouteIsSafePos} &&
                {[_candidateEndRoad] call KFH_fnc_dynamicRouteIsSafePos} &&
                {[_candidateStartRoad, _candidateEndRoad] call KFH_fnc_dynamicRouteSegmentIsLand};

            if (_endInside) exitWith {
                _start = _candidateStartRoad;
                _end = _candidateEndRoad;
            };
        };
    };

    if ((count _start) isEqualTo 0) then {
        private _fallbackRoads = [] call KFH_fnc_dynamicRouteCollectFallbackRoads;
        if ((count _fallbackRoads) < 2) exitWith {
            ["No safe land road nodes found for dynamic route fallback."] call KFH_fnc_dynamicRouteLog;
            [[], _dir]
        };

        _start = [_fallbackRoads] call KFH_fnc_dynamicRouteSelectRandom;
        _end = [_start, _spacing * (_count + 1) * 0.55, _length, _length * 1.2, _dir] call KFH_fnc_dynamicRouteFindBestFallbackEnd;

        if ((count _end) isEqualTo 0) exitWith {
            ["No land-only fallback route could be built."] call KFH_fnc_dynamicRouteLog;
            [[], _dir]
        };

        _dir = [_start, _end] call BIS_fnc_dirTo;
        [format ["fallback route selected: start=%1 end=%2 distance=%3m", mapGridPosition _start, mapGridPosition _end, round (_start distance2D _end)]] call KFH_fnc_dynamicRouteLog;
    } else {
        _dir = [_start, _end] call BIS_fnc_dirTo;
    };

    private _targetSegment = (_start distance2D _end) / ((_count + 1) max 1);
    private _minSegment = (_spacing * (missionNamespace getVariable ["KFH_dynamicRouteMinSegmentFactor", 0.58])) max (_targetSegment * 0.45);
    private _maxSegment = (_spacing * (missionNamespace getVariable ["KFH_dynamicRouteMaxSegmentFactor", 1.75])) max (_targetSegment * 1.55);
    private _startCheckpointMinDistance = (missionNamespace getVariable ["KFH_dynamicRouteStartCheckpointMinDistance", 360]) max _minSegment;

    private _points = [_start];
    private _routeFailed = false;
    for "_i" from 1 to _count do {
        if (!_routeFailed) then {
            private _t = _i / (_count + 1);
            private _base = [
                (_start select 0) + ((_end select 0) - (_start select 0)) * _t,
                (_start select 1) + ((_end select 1) - (_start select 1)) * _t,
                0
            ];
            private _offsetA = [_base, (([2] call KFH_fnc_dynamicRouteRandom) - 1) * _jitter, _dir + 90] call KFH_fnc_dynamicRouteRelPos;
            private _offsetB = [_offsetA, (([2] call KFH_fnc_dynamicRouteRandom) - 1) * (_jitter * 0.45), _dir] call KFH_fnc_dynamicRouteRelPos;
            private _checkpoint = [_offsetB] call KFH_fnc_dynamicRouteFindLandRoadPos;
            if ((count _checkpoint) isEqualTo 0) then {
                _checkpoint = [_base] call KFH_fnc_dynamicRouteFindLandRoadPos;
            };
            private _previous = _points select ((count _points) - 1);
            private _segmentDistance = if ((count _checkpoint) > 0) then { _previous distance2D _checkpoint } else { 0 };
            private _segmentMin = if (_i isEqualTo 1) then { _startCheckpointMinDistance } else { _minSegment };
            private _segmentProgress = if ((count _checkpoint) > 0) then { [_previous, _checkpoint, _dir] call KFH_fnc_dynamicRouteForwardProgress } else { -1 };
            private _segmentMaxTurn = missionNamespace getVariable ["KFH_dynamicRouteMaxTurnDegrees", 95];
            private _segmentTurn = if ((count _checkpoint) > 0) then { [_dir, _previous getDir _checkpoint] call KFH_fnc_dynamicRouteAngleDelta } else { 999 };
            private _minForwardProgress = _segmentMin * (missionNamespace getVariable ["KFH_dynamicRouteMinForwardProgressFactor", 0.42]);
            if (
                ((count _checkpoint) isEqualTo 0) ||
                {!([_checkpoint] call KFH_fnc_dynamicRouteIsSafePos)} ||
                {_segmentDistance < _segmentMin} ||
                {_segmentDistance > _maxSegment} ||
                {_segmentProgress < _minForwardProgress} ||
                {_segmentTurn > _segmentMaxTurn}
            ) then {
                _checkpoint = [_previous, _segmentMin, _targetSegment, _maxSegment, _dir, _segmentMaxTurn] call KFH_fnc_dynamicRouteFindBestFallbackEnd;
                if ((count _checkpoint) > 0) then {
                    [format ["checkpoint %1 fallback adjusted segment to %2m.", _i, round (_previous distance2D _checkpoint)]] call KFH_fnc_dynamicRouteLog;
                };
            };
            if ((count _checkpoint) isEqualTo 0) then {
                private _projected = [_previous, _spacing, _dir] call KFH_fnc_dynamicRouteRelPos;
                _checkpoint = [_projected] call KFH_fnc_dynamicRouteFindLandRoadPos;
            };
            if (
                (count _checkpoint) > 0 &&
                {
                    ((_previous distance2D _checkpoint) < _segmentMin) ||
                    {([_previous, _checkpoint, _dir] call KFH_fnc_dynamicRouteForwardProgress) < _minForwardProgress} ||
                    {([_dir, _previous getDir _checkpoint] call KFH_fnc_dynamicRouteAngleDelta) > (_segmentMaxTurn + 25)}
                }
            ) then {
                [format ["checkpoint %1 rejected: segment too short after fallback (%2m).", _i, round (_previous distance2D _checkpoint)]] call KFH_fnc_dynamicRouteLog;
                _checkpoint = [];
            };
            if ((count _checkpoint) isEqualTo 0) then {
                [format ["checkpoint %1 could not find a valid segment; route build aborted.", _i]] call KFH_fnc_dynamicRouteLog;
                _points = [];
                _routeFailed = true;
            } else {
                _points pushBack _checkpoint;
            };
        };
    };
    if ((count _points) isEqualTo 0) exitWith { [[], _dir] };
    _points pushBack _end;

    [_points, _dir]
};

KFH_fnc_applyDynamicRoute = {
    if (!isServer) exitWith {};
    if !(missionNamespace getVariable ["KFH_dynamicRouteEnabled", false]) exitWith {};

    private _baseSeed = missionNamespace getVariable ["KFH_routeSeed", -1];
    if (_baseSeed < 0) then {
        _baseSeed = floor (random 1000000);
    };

    private _attempts = missionNamespace getVariable ["KFH_dynamicRouteBuildAttempts", 10];
    private _acceptedBuilt = [[], 0];
    private _acceptedSeed = _baseSeed;
    private _lastBuilt = [[], 0];

    for "_attempt" from 1 to (_attempts max 1) do {
        if (((_acceptedBuilt select 0) isEqualTo [])) then {
            private _seed = _baseSeed + ((_attempt - 1) * 7919);
            missionNamespace setVariable ["KFH_routeSeed", _seed, true];
            missionNamespace setVariable ["KFH_dynamicRouteSeed", _seed, true];
            missionNamespace setVariable ["KFH_dynamicRouteRandomCounter", 0];

            private _built = [] call KFH_fnc_dynamicRouteBuildPoints;
            _built params ["_points", "_dir"];
            _lastBuilt = _built;

            if (!([_points] call KFH_fnc_dynamicRouteCandidateIsUsable)) then {
                _built = [] call KFH_fnc_dynamicRouteRetryRelaxed;
                _built params ["_points", "_dir"];
                if (!(_points isEqualTo [])) then {
                    _lastBuilt = _built;
                };
            };

            if (!([_points] call KFH_fnc_dynamicRouteCandidateIsUsable)) then {
                _built = [] call KFH_fnc_dynamicRouteBuildEmergencyFallback;
                _built params ["_points", "_dir"];
                if (!(_points isEqualTo [])) then {
                    _lastBuilt = _built;
                };
            };

            if ([_points] call KFH_fnc_dynamicRouteCandidateIsUsable) then {
                _acceptedBuilt = _built;
                _acceptedSeed = _seed;
                if (_attempt > 1) then {
                    [format ["Dynamic route accepted after retry %1/%2 seed=%3.", _attempt, _attempts, _seed]] call KFH_fnc_dynamicRouteLog;
                };
            } else {
                private _unsafeIndex = _points findIf { !([_x] call KFH_fnc_dynamicRouteIsSafePos) };
                [format [
                    "Dynamic route attempt %1/%2 rejected: acceptable=%3 spacing=%4 unsafeIndex=%5.",
                    _attempt,
                    _attempts,
                    [_points] call KFH_fnc_dynamicRouteIsAcceptable,
                    [_points] call KFH_fnc_dynamicRouteHasNodeSpacing,
                    _unsafeIndex
                ]] call KFH_fnc_dynamicRouteLog;
            };
        };
    };

    if ((_acceptedBuilt select 0) isEqualTo []) then {
        ["Dynamic route retries exhausted; trying forced marker fallback once as last resort."] call KFH_fnc_dynamicRouteLog;
        private _forced = [] call KFH_fnc_dynamicRouteBuildForcedMarkerFallback;
        if ([_forced select 0] call KFH_fnc_dynamicRouteCandidateIsUsable) then {
            _acceptedBuilt = _forced;
            _acceptedSeed = missionNamespace getVariable ["KFH_dynamicRouteSeed", _baseSeed];
        } else {
            ["Dynamic route forced marker fallback rejected; keeping editor markers unchanged rather than accepting unsafe clustered placement."] call KFH_fnc_dynamicRouteLog;
        };
    };

    if ((_acceptedBuilt select 0) isEqualTo []) exitWith {
        ["Dynamic route failed all retries; editor markers left unchanged to avoid clustered fallback placement."] call KFH_fnc_dynamicRouteLog;
    };

    _acceptedBuilt params ["_points", "_dir"];
    private _seed = _acceptedSeed;
    missionNamespace setVariable ["KFH_routeSeed", _seed, true];
    missionNamespace setVariable ["KFH_dynamicRouteSeed", _seed, true];

    private _checkpointCount = ((count _points) - 2) max 1;
    private _startPos = _points select 0;
    private _extractPos = _points select ((count _points) - 1);

    ["kfh_start", _startPos, "mil_start", "ColorBLUFOR", "Patrol Start", _dir] call KFH_fnc_dynamicRouteSetMarker;
    ["kfh_extract", _extractPos, "mil_end", "ColorGreen", "Extraction LZ", _dir] call KFH_fnc_dynamicRouteSetMarker;

    for "_i" from 1 to _checkpointCount do {
        private _cpPos = _points select _i;
        private _cpDir = if (_i < _checkpointCount) then {
            [_cpPos, _points select (_i + 1)] call BIS_fnc_dirTo
        } else {
            [_cpPos, _extractPos] call BIS_fnc_dirTo
        };
        private _cpMarker = format ["kfh_cp_%1", _i];
        [_cpMarker, _cpPos, "mil_objective", "ColorYellow", format ["CP %1", _i], _cpDir] call KFH_fnc_dynamicRouteSetMarker;

        private _front = [_cpPos, 130, _cpDir] call KFH_fnc_dynamicRouteRelPos;
        private _spawnA = [_front, 65, _cpDir - 65] call KFH_fnc_dynamicRouteRelPos;
        private _spawnB = [_front, 65, _cpDir + 65] call KFH_fnc_dynamicRouteRelPos;
        [format ["kfh_spawn_%1_1", _i], _spawnA, "mil_warning", "ColorOPFOR", format ["CP%1 Spawn A", _i], _cpDir] call KFH_fnc_dynamicRouteSetMarker;
        [format ["kfh_spawn_%1_2", _i], _spawnB, "mil_warning", "ColorOPFOR", format ["CP%1 Spawn B", _i], _cpDir] call KFH_fnc_dynamicRouteSetMarker;

        if (
            (missionNamespace getVariable ["KFH_branchRewardEnabled", true]) &&
            {([1] call KFH_fnc_dynamicRouteRandom) < (missionNamespace getVariable ["KFH_branchRewardChance", 0.55])}
        ) then {
            private _side = if (([1] call KFH_fnc_dynamicRouteRandom) < 0.5) then { -1 } else { 1 };
            private _branchDistance = missionNamespace getVariable ["KFH_branchRewardOffsetDistance", 360];
            private _branchMinDetour = missionNamespace getVariable ["KFH_branchRewardMinDetourDistance", 260];
            private _branchSearch = missionNamespace getVariable ["KFH_branchRewardRoadSearchRadius", 260];
            private _branchCandidate = [_cpPos, _branchDistance, _cpDir + (90 * _side)] call KFH_fnc_dynamicRouteRelPos;
            private _oldSearch = missionNamespace getVariable ["KFH_dynamicRouteRoadSearchRadius", 360];
            missionNamespace setVariable ["KFH_dynamicRouteRoadSearchRadius", _branchSearch];
            private _branchPos = [_branchCandidate] call KFH_fnc_dynamicRouteFindLandRoadPos;
            missionNamespace setVariable ["KFH_dynamicRouteRoadSearchRadius", _oldSearch];
            if (((count _branchPos) isEqualTo 0) || {(_branchPos distance2D _cpPos) < _branchMinDetour}) then {
                _branchPos = _branchCandidate;
            };
            if ((_branchPos distance2D _cpPos) < _branchMinDetour) then {
                _branchPos = [_cpPos, _branchMinDetour, _cpDir + (90 * _side)] call KFH_fnc_dynamicRouteRelPos;
            };
            if ([_branchPos] call KFH_fnc_dynamicRouteIsSafePos) then {
                private _branchMarker = [
                    format ["kfh_branch_reward_%1", _i],
                    _branchPos,
                    "mil_box",
                    "ColorOrange",
                    format ["Side Cache %1", _i],
                    _cpDir
                ] call KFH_fnc_dynamicRouteSetMarker;
                _branchMarker setMarkerAlpha (missionNamespace getVariable ["KFH_branchRewardHiddenAlpha", 0]);
            };
        };
    };

    for "_i" from (_checkpointCount + 1) to (missionNamespace getVariable ["KFH_checkpointCountMax", 10]) do {
        {
            if (_x in allMapMarkers) then {
                deleteMarker _x;
            };
        } forEach [
            format ["kfh_cp_%1", _i],
            format ["kfh_spawn_%1_1", _i],
            format ["kfh_spawn_%1_2", _i],
            format ["kfh_branch_reward_%1", _i]
        ];
    };

    private _extractDir = [_points select (_checkpointCount max 1), _extractPos] call BIS_fnc_dirTo;
    private _extractFront = [_extractPos, 160, _extractDir + 180] call KFH_fnc_dynamicRouteRelPos;
    [format ["kfh_spawn_extract_%1", 1], [_extractFront, 75, _extractDir - 75] call KFH_fnc_dynamicRouteRelPos, "mil_warning", "ColorOPFOR", "Extract Spawn A", _extractDir] call KFH_fnc_dynamicRouteSetMarker;
    [format ["kfh_spawn_extract_%1", 2], [_extractFront, 75, _extractDir + 75] call KFH_fnc_dynamicRouteRelPos, "mil_warning", "ColorOPFOR", "Extract Spawn B", _extractDir] call KFH_fnc_dynamicRouteSetMarker;

    {
        if (_x in allMapMarkers) then {
            _x setMarkerAlpha (missionNamespace getVariable ["KFH_routeMarkerHiddenAlpha", 0]);
        };
    } forEach (allMapMarkers select { (_x find "kfh_spawn_") isEqualTo 0 });

    missionNamespace setVariable ["KFH_dynamicRoutePoints", _points, true];
    missionNamespace setVariable ["KFH_dynamicRouteBuilt", true, true];

    [format ["seed=%1 checkpoints=%2 start=%3 extract=%4", _seed, _checkpointCount, mapGridPosition _startPos, mapGridPosition _extractPos]] call KFH_fnc_dynamicRouteLog;
};
