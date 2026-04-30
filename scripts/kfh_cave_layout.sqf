/*
    KFH_Patrol_LWH_co10 cave layout bootstrap.
    Fixed layout v2 favors physical consistency over fancy branching:
    one wide RSPN-aligned main tunnel, three checkpoint chambers, and
    all gameplay markers snapped onto that route.
*/

if (isNil "KFH_caveLayoutEnabled") then { KFH_caveLayoutEnabled = false; };
if (isNil "KFH_caveLayoutMode") then { KFH_caveLayoutMode = "fixed"; };
if (isNil "KFH_caveLayoutOrigin") then { KFH_caveLayoutOrigin = [23250, 18350, 0]; };
if (isNil "KFH_caveLayoutDir") then { KFH_caveLayoutDir = 0; };
if (isNil "KFH_caveLayoutUseRSPN") then { KFH_caveLayoutUseRSPN = false; };
if (isNil "KFH_caveLayoutEntranceClass") then { KFH_caveLayoutEntranceClass = "CB_Entrance02"; };
if (isNil "KFH_caveLayoutMainClass") then { KFH_caveLayoutMainClass = "CB_Long"; };
if (isNil "KFH_caveLayoutCheckpointClass") then { KFH_caveLayoutCheckpointClass = "CB_Intersect02"; };
if (isNil "KFH_caveLayoutEndClass") then { KFH_caveLayoutEndClass = "CB_End02"; };
if (isNil "KFH_caveLayoutBranchClass") then { KFH_caveLayoutBranchClass = "CB_Intersect01"; };
if (isNil "KFH_caveLayoutCoverClass") then { KFH_caveLayoutCoverClass = "Cover_Bluntstone"; };
if (isNil "KFH_caveLayoutHeightOffset") then { KFH_caveLayoutHeightOffset = 0; };
if (isNil "KFH_caveLayoutRouteLength") then { KFH_caveLayoutRouteLength = 3150; };
if (isNil "KFH_caveLayoutSegmentSpacing") then { KFH_caveLayoutSegmentSpacing = 38; };
if (isNil "KFH_caveLayoutClearTerrain") then { KFH_caveLayoutClearTerrain = true; };
if (isNil "KFH_caveDebugVehiclesEnabled") then { KFH_caveDebugVehiclesEnabled = false; };
if (isNil "KFH_caveDebugVehicleClass") then { KFH_caveDebugVehicleClass = "B_Quadbike_01_F"; };

KFH_fnc_caveClassAvailable = {
    params ["_className"];

    isClass (configFile >> "CfgVehicles" >> _className)
};

KFH_fnc_caveLayoutBasePos = {
    private _origin = missionNamespace getVariable ["KFH_caveLayoutOrigin", [23250, 18350, 0]];

    [
        _origin select 0,
        _origin select 1,
        if ((count _origin) >= 3) then { _origin select 2 } else { 0 }
    ]
};

KFH_fnc_caveLayoutWorldPos = {
    params ["_offset"];

    private _basePos = [] call KFH_fnc_caveLayoutBasePos;
    private _dir = missionNamespace getVariable ["KFH_caveLayoutDir", 0];
    private _heightOffset = missionNamespace getVariable ["KFH_caveLayoutHeightOffset", 0];
    private _rotated = [_offset, _dir] call KFH_fnc_rotateOffset;

    [
        (_basePos select 0) + (_rotated select 0),
        (_basePos select 1) + (_rotated select 1),
        (_basePos select 2) + (_rotated select 2) + _heightOffset
    ]
};

KFH_fnc_caveDir = {
    params [["_dirOffset", 0]];

    (missionNamespace getVariable ["KFH_caveLayoutDir", 0]) + _dirOffset
};

KFH_fnc_setLayoutMarker = {
    params ["_markerName", "_offset", ["_dirOffset", 0], ["_alpha", 0.9]];

    if !(_markerName in allMapMarkers) exitWith {
        [format ["Cave layout marker missing: %1", _markerName]] call KFH_fnc_log;
    };

    _markerName setMarkerPos ([_offset] call KFH_fnc_caveLayoutWorldPos);
    _markerName setMarkerDir ([_dirOffset] call KFH_fnc_caveDir);
    _markerName setMarkerAlpha _alpha;
};

KFH_fnc_trackCaveObject = {
    params ["_object"];

    if (isNull _object) exitWith {};

    _object setVectorUp [0, 0, 1];
    _object setVariable ["KFH_caveLayoutObject", true, true];

    private _objects = missionNamespace getVariable ["KFH_caveObjects", []];
    _objects pushBack _object;
    missionNamespace setVariable ["KFH_caveObjects", _objects, true];
};

KFH_fnc_spawnCaveObject = {
    params ["_className", "_offset", ["_dirOffset", 0], ["_allowDamage", false], ["_disableSimulation", true]];

    if !([_className] call KFH_fnc_caveClassAvailable) exitWith { objNull };

    private _pos = [_offset] call KFH_fnc_caveLayoutWorldPos;
    private _object = createVehicle [_className, _pos, [], 0, "CAN_COLLIDE"];

    _object setDir ([_dirOffset] call KFH_fnc_caveDir);
    _object setPosATL _pos;
    _object allowDamage _allowDamage;

    if (_disableSimulation) then {
        _object enableSimulationGlobal false;
    };

    [_object] call KFH_fnc_trackCaveObject;
    _object
};

KFH_fnc_clearCaveFootprint = {
    params ["_offset", ["_radius", 90]];

    if !(missionNamespace getVariable ["KFH_caveLayoutClearTerrain", true]) exitWith {};

    private _pos = [_offset] call KFH_fnc_caveLayoutWorldPos;
    private _terrainObjects = nearestTerrainObjects [
        _pos,
        ["HOUSE", "BUILDING", "TREE", "SMALL TREE", "BUSH", "ROCK", "ROCKS", "WALL", "FENCE", "HIDE"],
        _radius,
        false,
        true
    ];

    {
        _x hideObjectGlobal true;
    } forEach _terrainObjects;
};

KFH_fnc_spawnCaveMainRoute = {
    private _mainClass = missionNamespace getVariable ["KFH_caveLayoutMainClass", "CB_Long"];
    private _checkpointClass = missionNamespace getVariable ["KFH_caveLayoutCheckpointClass", "CB_Intersect02"];
    private _entranceClass = missionNamespace getVariable ["KFH_caveLayoutEntranceClass", "CB_Entrance02"];
    private _endClass = missionNamespace getVariable ["KFH_caveLayoutEndClass", "CB_End02"];
    private _branchClass = missionNamespace getVariable ["KFH_caveLayoutBranchClass", "CB_Intersect01"];
    private _coverClass = missionNamespace getVariable ["KFH_caveLayoutCoverClass", "Cover_Bluntstone"];
    private _routeLength = missionNamespace getVariable ["KFH_caveLayoutRouteLength", 3150];
    private _spacing = missionNamespace getVariable ["KFH_caveLayoutSegmentSpacing", 38];
    private _checkpointXs = [800, 1700, 2800];

    [_entranceClass, [0, 0, 0], 0] call KFH_fnc_spawnCaveObject;
    [_endClass, [_routeLength + 80, 0, 0], 180] call KFH_fnc_spawnCaveObject;

    for "_xPos" from _spacing to _routeLength step _spacing do {
        private _nearCheckpoint = false;
        {
            if (abs (_xPos - _x) < (_spacing * 0.75)) exitWith {
                _nearCheckpoint = true;
            };
        } forEach _checkpointXs;

        if (!_nearCheckpoint) then {
            [_mainClass, [_xPos, 0, 0], 0] call KFH_fnc_spawnCaveObject;
        };
    };

    {
        [_checkpointClass, [_x, 0, 0], 0] call KFH_fnc_spawnCaveObject;
        [_branchClass, [_x, 62, 0], 90] call KFH_fnc_spawnCaveObject;
        [_coverClass, [_x - 42, -32, 0], 0] call KFH_fnc_spawnCaveObject;
        [_coverClass, [_x + 42, 32, 0], 180] call KFH_fnc_spawnCaveObject;
    } forEach _checkpointXs;
};

KFH_fnc_spawnCaveLightsAndLandmarks = {
    {
        _x params ["_xPos", "_label"];
        ["Land_PortableLight_double_F", [_xPos, -16, 0], 90, false, false] call KFH_fnc_spawnCaveObject;
        ["Land_Camping_Light_F", [_xPos, 18, 0], 270, false, false] call KFH_fnc_spawnCaveObject;

        if (_label != "") then {
            ["Land_MetalBarrel_F", [_xPos - 18, 24, 0], 0, false, false] call KFH_fnc_spawnCaveObject;
            ["Land_MetalBarrel_F", [_xPos + 18, -24, 0], 0, false, false] call KFH_fnc_spawnCaveObject;
        };
    } forEach [
        [80, "START"],
        [450, ""],
        [800, "CP1"],
        [1250, ""],
        [1700, "CP2"],
        [2250, ""],
        [2800, "CP3"],
        [3150, ""]
    ];

    ["MetalBarrel_burning_F", [-120, 0, 0], 0, false, false] call KFH_fnc_spawnCaveObject;
};

KFH_fnc_spawnCaveDebugVehicles = {
    if !(missionNamespace getVariable ["KFH_caveDebugVehiclesEnabled", true]) exitWith {};

    private _vehicleClass = missionNamespace getVariable ["KFH_caveDebugVehicleClass", "B_Quadbike_01_F"];
    if !([_vehicleClass] call KFH_fnc_caveClassAvailable) exitWith {
        [format ["Debug cave vehicle class missing: %1", _vehicleClass]] call KFH_fnc_log;
    };

    private _vehicles = missionNamespace getVariable ["KFH_debugCaveVehicles", []];
    {
        if (!isNull _x) then {
            deleteVehicle _x;
        };
    } forEach _vehicles;

    _vehicles = [];

    {
        _x params ["_offset", "_dirOffset"];
        private _vehicle = [_vehicleClass, _offset, _dirOffset, true, false] call KFH_fnc_spawnCaveObject;

        if (!isNull _vehicle) then {
            _vehicle setVariable ["KFH_debugCaveVehicle", true, true];
            _vehicle setVariable ["KFH_supportLabel", "Debug cave buggy", true];
            _vehicles pushBack _vehicle;
        };
    } forEach [
        [[115, -18, 0], 0],
        [[115, 18, 0], 0]
    ];

    missionNamespace setVariable ["KFH_debugCaveVehicles", _vehicles, true];
    [format ["Debug cave vehicles spawned: %1", count _vehicles]] call KFH_fnc_log;
};

KFH_fnc_relocateServerLocalFriendlies = {
    private _startPos = ["kfh_start", [0, 0, 0]] call KFH_fnc_worldFromMarkerOffset;
    private _startDir = markerDir "kfh_start";
    private _index = 0;

    {
        if (!isPlayer _x && {side _x isEqualTo west}) then {
            private _offset = [(_index mod 4) * 2, floor (_index / 4) * 2, 0];
            private _pos = [
                (_startPos select 0) + (_offset select 0),
                (_startPos select 1) + (_offset select 1),
                _startPos select 2
            ];

            _x setPosATL _pos;
            _x setDir _startDir;
            _index = _index + 1;
        };
    } forEach allUnits;
};

KFH_fnc_applyFixedCaveLayout = {
    if (!isServer) exitWith {};
    if !(missionNamespace getVariable ["KFH_caveLayoutEnabled", false]) exitWith {};
    if (missionNamespace getVariable ["KFH_caveLayoutBuilt", false]) exitWith {};

    missionNamespace setVariable ["KFH_caveObjects", [], true];

    private _markerLayout = [
        ["kfh_start", [80, 0, 0], 0],
        ["kfh_cp_1", [800, 0, 0], 0],
        ["kfh_cp_2", [1700, 0, 0], 0],
        ["kfh_cp_3", [2800, 0, 0], 0],
        ["kfh_extract", [-140, 0, 0], 180],
        ["kfh_spawn_1_1", [980, 0, 0], 180],
        ["kfh_spawn_1_2", [1120, 22, 0], 180],
        ["kfh_spawn_2_1", [1880, 0, 0], 180],
        ["kfh_spawn_2_2", [2020, -22, 0], 180],
        ["kfh_spawn_3_1", [2980, 0, 0], 180],
        ["kfh_spawn_3_2", [3120, 22, 0], 180],
        ["kfh_spawn_extract_1", [220, 0, 0], 180],
        ["kfh_spawn_extract_2", [360, -22, 0], 180]
    ];

    {
        _x params ["_markerName", "_offset", "_dirOffset"];
        [_markerName, _offset, _dirOffset] call KFH_fnc_setLayoutMarker;
    } forEach _markerLayout;

    for "_xPos" from -180 to 3250 step 220 do {
        [[_xPos, 0, 0], 120] call KFH_fnc_clearCaveFootprint;
    };

    private _useRSPN = missionNamespace getVariable ["KFH_caveLayoutUseRSPN", true];
    private _mainClass = missionNamespace getVariable ["KFH_caveLayoutMainClass", "CB_Long"];

    if (_useRSPN && {!([_mainClass] call KFH_fnc_caveClassAvailable)}) then {
        [format ["RSPN Cave Systems not loaded or class missing: %1. Cave meshes skipped; gameplay markers remain active.", _mainClass]] call KFH_fnc_log;
        ["RSPN cave parts were not found. Markers were moved, but cave meshes were skipped."] call KFH_fnc_notifyAll;
        _useRSPN = false;
    };

    if (_useRSPN) then {
        [] call KFH_fnc_spawnCaveMainRoute;
        [] call KFH_fnc_spawnCaveLightsAndLandmarks;
    };

    [] call KFH_fnc_spawnCaveDebugVehicles;
    [] call KFH_fnc_relocateServerLocalFriendlies;
    missionNamespace setVariable ["KFH_caveLayoutBuilt", true, true];

    [format [
        "Fixed cave layout v2 applied. origin=%1 route=%2m spacing=%3m rspn=%4",
        [] call KFH_fnc_caveLayoutBasePos,
        missionNamespace getVariable ["KFH_caveLayoutRouteLength", 3150],
        missionNamespace getVariable ["KFH_caveLayoutSegmentSpacing", 38],
        _useRSPN
    ]] call KFH_fnc_log;
};

KFH_fnc_applyCaveLayout = {
    private _mode = missionNamespace getVariable ["KFH_caveLayoutMode", "fixed"];

    switch (_mode) do {
        case "fixed": {
            [] call KFH_fnc_applyFixedCaveLayout;
        };
        default {
            [format ["Unknown cave layout mode '%1'; using fixed layout.", _mode]] call KFH_fnc_log;
            [] call KFH_fnc_applyFixedCaveLayout;
        };
    };
};

KFH_fnc_placePlayerAtCaveStartOnce = {
    if (!hasInterface) exitWith {};
    if (isNull player) exitWith {};
    if !(missionNamespace getVariable ["KFH_caveLayoutEnabled", false]) exitWith {};
    if (player getVariable ["KFH_caveStartPlaced", false]) exitWith {};

    private _timeoutAt = time + 45;
    waitUntil {
        sleep 0.1;
        (missionNamespace getVariable ["KFH_caveLayoutBuilt", false]) || {time > _timeoutAt}
    };

    if !(missionNamespace getVariable ["KFH_caveLayoutBuilt", false]) exitWith {};
    if !("kfh_start" in allMapMarkers) exitWith {};

    private _startPos = getMarkerPos "kfh_start";
    private _slot = (allPlayers find player) max 0;
    private _sideOffset = ((_slot mod 5) - 2) * 2.2;
    private _backOffset = floor (_slot / 5) * -2.2;
    private _dir = markerDir "kfh_start";
    private _offset = [[_backOffset, _sideOffset, 0], _dir] call KFH_fnc_rotateOffset;

    player setPosATL [
        (_startPos select 0) + (_offset select 0),
        (_startPos select 1) + (_offset select 1),
        _startPos select 2
    ];
    player setDir _dir;
    player setVariable ["KFH_caveStartPlaced", true];
};
