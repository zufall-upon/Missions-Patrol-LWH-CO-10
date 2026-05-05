KFH_fnc_getHumanReferenceUnits = {
    private _humans = [] call KFH_fnc_getHumanPlayers;
    if ((count _humans) isEqualTo 0) then {
        _humans = allPlayers;
    };
    if ((count _humans) isEqualTo 0) then {
        private _anchors = missionNamespace getVariable ["KFH_recentPlayerPresenceAnchors", []];
        _anchors = _anchors select { time - (_x select 2) <= 12 };
        missionNamespace setVariable ["KFH_recentPlayerPresenceAnchors", _anchors, true];
        _humans = _anchors apply { _x select 0 };
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
    private _progressScale = [] call KFH_fnc_getEnvMilitaryProgressScale;
    private _armedChance = ((missionNamespace getVariable ["KFH_envTrafficMilitaryArmedChance", 0.7]) * _progressScale) min 1;
    private _armorShare = ((missionNamespace getVariable ["KFH_envTrafficMilitaryArmorShare", 0.4]) * _progressScale) min 1;
    private _mortarShare = ((missionNamespace getVariable ["KFH_envTrafficMilitaryMortarShare", 0.16]) * _progressScale) min 1;
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

KFH_fnc_getEnvMilitaryProgressScale = {
    if !(missionNamespace getVariable ["KFH_envTrafficMilitaryProgressEnabled", true]) exitWith { 1 };

    private _currentCheckpoint = missionNamespace getVariable ["KFH_currentCheckpoint", 1];
    private _startCheckpoint = missionNamespace getVariable ["KFH_envTrafficMilitaryStartCheckpoint", 3];
    if (_currentCheckpoint < _startCheckpoint) exitWith { 0 };

    private _fullCheckpoint = missionNamespace getVariable ["KFH_envTrafficMilitaryFullCheckpoint", missionNamespace getVariable ["KFH_envTrafficSpawnUntilCheckpoint", 6]];
    private _initialScale = missionNamespace getVariable ["KFH_envTrafficMilitaryInitialScale", 0.25];
    if (_fullCheckpoint <= _startCheckpoint) exitWith { 1 };

    private _progress = (((_currentCheckpoint - _startCheckpoint) / ((_fullCheckpoint - _startCheckpoint) max 1)) max 0) min 1;
    ((_initialScale + ((1 - _initialScale) * _progress)) max 0) min 1
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
    private _atChance = ((missionNamespace getVariable ["KFH_envMilitaryATChance", 0.72]) * ([] call KFH_fnc_getEnvMilitaryProgressScale)) min 1;
    if ((random 1) < _atChance) then {
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
    private _progressScale = [] call KFH_fnc_getEnvMilitaryProgressScale;
    private _count = (ceil ((_minSize + floor (random (((_maxSize - _minSize) max 0) + 1))) * _threatScale * _progressScale)) max 1;
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
    private _progressScale = [] call KFH_fnc_getEnvMilitaryProgressScale;
    private _count = (ceil ((_minGuards + floor (random (((_maxGuards - _minGuards) max 0) + 1))) * _threatScale * _progressScale)) max 1;
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
        private _progressScale = [] call KFH_fnc_getEnvMilitaryProgressScale;
        _milMax = ceil (_milMax * _progressScale);
        private _milPerTick = if (_isEarly) then {
            missionNamespace getVariable ["KFH_envSceneMilitaryPerTickEarly", 0]
        } else {
            missionNamespace getVariable ["KFH_envSceneMilitaryPerTickLate", 1]
        };
        _milPerTick = ceil (_milPerTick * _progressScale);
        for "_i" from 1 to ((_milMax - _military) min _milPerTick) do {
            if ((random 1) <= ((missionNamespace getVariable ["KFH_envSceneMilitaryVehicleChance", 0.2]) * _progressScale)) then {
                if !(isNull ([] call KFH_fnc_spawnEnvMilitaryScene)) then { _spawnedMilitary = _spawnedMilitary + 1; };
            };
        };

        private _envGroups = missionNamespace getVariable ["KFH_envTrafficGroups", []];
        private _footPatrols = {
            !isNull _x && {(_x getVariable ["KFH_envRole", ""]) isEqualTo "militaryFootPatrol"}
        } count _envGroups;
        if (
            _footPatrols < (ceil ((missionNamespace getVariable ["KFH_envMilitaryFootPatrolMax", 4]) * ([] call KFH_fnc_getThreatScale) * _progressScale)) &&
            {(random 1) <= ((missionNamespace getVariable ["KFH_envMilitaryFootPatrolChance", 0.5]) * _progressScale)}
        ) then {
            if !(isNull ([] call KFH_fnc_spawnEnvMilitaryFootPatrol)) then { _spawnedMilitary = _spawnedMilitary + 1; };
        };

        private _checkpoints = {
            !isNull _x && {(_x getVariable ["KFH_envRole", ""]) isEqualTo "militaryCheckpoint"}
        } count (missionNamespace getVariable ["KFH_envTrafficGroups", []]);
        if (
            _checkpoints < (ceil ((missionNamespace getVariable ["KFH_envMilitaryCheckpointMax", 3]) * ([] call KFH_fnc_getThreatScale) * _progressScale)) &&
            {(random 1) <= ((missionNamespace getVariable ["KFH_envMilitaryCheckpointChance", 0.35]) * _progressScale)}
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

                private _progressScale = [] call KFH_fnc_getEnvMilitaryProgressScale;
                if (
                    time >= (missionNamespace getVariable ["KFH_envTrafficMilitaryDelaySeconds", 90]) &&
                    {_currentCheckpoint >= (missionNamespace getVariable ["KFH_envTrafficMilitaryStartCheckpoint", 3])} &&
                    {(count _militaryGroups) < (ceil ((missionNamespace getVariable ["KFH_envTrafficMaxMilitaryGroups", 2]) * _progressScale))} &&
                    {(random 1) <= ((missionNamespace getVariable ["KFH_envTrafficMilitaryChance", 0.45]) * _progressScale)}
                ) then {
                    [] call KFH_fnc_spawnEnvMilitaryTraffic;
                };
            };
        };

        sleep (missionNamespace getVariable ["KFH_envTrafficLoopSeconds", 35]);
    };
};

