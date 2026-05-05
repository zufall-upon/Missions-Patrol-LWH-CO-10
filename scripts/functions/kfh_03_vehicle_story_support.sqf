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

    private _key = switch (_tier) do {
        case "light": { "vehicle_threat_label_light" };
        case "heavy": { "vehicle_threat_label_heavy" };
        case "armor": { "vehicle_threat_label_armor" };
        case "combat": { "vehicle_threat_label_combat" };
        default { "vehicle_threat_label_medium" };
    };

    [_key] call KFH_fnc_localizeAnnouncement
};

KFH_fnc_getVehicleThreatLogLabel = {
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
            [_tier] call KFH_fnc_getVehicleThreatLogLabel
        ];
        [_entryMessage] call KFH_fnc_log;
        if (missionNamespace getVariable ["KFH_showVehicleEntryChat", false]) then {
            ["vehicle_entry_notice", [
                round ((fuel _vehicle) * 100),
                [_tier] call KFH_fnc_getVehicleThreatLabel
            ]] remoteExecCall ["KFH_fnc_receiveAnnouncementKey", _unit];
        };
    }];

    [format ["Vehicle threat handler installed: %1 tier=%2", typeOf _vehicle, _tier]] call KFH_fnc_log;
};

KFH_fnc_installPatrolVehicleDurability = {
    params ["_vehicle"];

    if (isNull _vehicle) exitWith {};
    if (_vehicle getVariable ["KFH_patrolVehicleDurabilityInstalled", false]) exitWith {};

    _vehicle setVariable ["KFH_patrolVehicleDurabilityInstalled", true, true];
    _vehicle addEventHandler ["HandleDamage", {
        params ["_vehicle", "_selection", "_incomingDamage", "_source"];

        if (isNull _vehicle) exitWith { _incomingDamage };
        private _currentDamage = damage _vehicle;
        private _isHitPoint = !(_selection isEqualTo "");
        private _scale = if (_isHitPoint) then {
            missionNamespace getVariable ["KFH_startPatrolVehicleHitPointDamageScale", 0.05]
        } else {
            missionNamespace getVariable ["KFH_startPatrolVehicleDamageScale", 0.08]
        };
        private _softCap = if (_isHitPoint) then {
            missionNamespace getVariable ["KFH_startPatrolVehicleHitPointSoftCap", 0.18]
        } else {
            missionNamespace getVariable ["KFH_startPatrolVehicleDamageSoftCap", 0.22]
        };
        private _scaledDamage = _currentDamage + (((_incomingDamage - _currentDamage) max 0) * _scale);
        (_scaledDamage min _softCap) max 0
    }];
    [_vehicle] spawn {
        params ["_vehicle"];

        while { alive _vehicle && {_vehicle getVariable ["KFH_patrolVehicleDurabilityInstalled", false]} } do {
            sleep (missionNamespace getVariable ["KFH_startPatrolVehicleAutoRepairSeconds", 2.5]);
            if (alive _vehicle) then {
                private _maxDamage = missionNamespace getVariable ["KFH_startPatrolVehicleAutoRepairMaxDamage", 0.28];
                if ((damage _vehicle) > _maxDamage) then {
                    _vehicle setDamage _maxDamage;
                };
                private _hitCap = missionNamespace getVariable ["KFH_startPatrolVehicleAutoRepairHitPointCap", 0.12];
                {
                    if ((_vehicle getHitPointDamage _x) > _hitCap) then {
                        _vehicle setHitPointDamage [_x, _hitCap];
                    };
                } forEach ["HitEngine", "HitFuel", "HitLFWheel", "HitLF2Wheel", "HitRFWheel", "HitRF2Wheel", "HitLMWheel", "HitRMWheel", "HitLBWheel", "HitRBWheel"];
            };
        };
    };
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

    private _players = ([] call KFH_fnc_getTargetPlayers) max 1;
    private _perPlayers = (missionNamespace getVariable ["KFH_startPatrolVehiclePerPlayers", 2]) max 1;
    private _maxVehicles = missionNamespace getVariable ["KFH_startPatrolVehicleMax", 5];
    private _vehicleCount = (ceil (_players / _perPlayers)) min _maxVehicles;
    private _vehicleClass = missionNamespace getVariable ["KFH_startPatrolVehicleClass", "C_Quadbike_01_F"];
    private _fuelMin = missionNamespace getVariable ["KFH_startPatrolVehicleFuelMin", 0.04];
    private _fuelMax = missionNamespace getVariable ["KFH_startPatrolVehicleFuelMax", 0.1];
    private _assetDirCorrection = missionNamespace getVariable ["KFH_startAssetDirCorrection", 180];
    private _spawned = [];

    for "_i" from 0 to (_vehicleCount - 1) do {
        private _side = if ((_i mod 2) isEqualTo 0) then { 1 } else { -1 };
        private _row = floor (_i / 2);
        private _offset = [(-7 * _side) - (_row * 2 * _side), -10 - (_row * 5), 0];
        private _vehicle = [_vehicleClass, _markerName, _offset, 180 + (12 * _side), false, _assetDirCorrection] call KFH_fnc_spawnSupportObject;
        _vehicle setFuel (_fuelMin + random ((_fuelMax - _fuelMin) max 0.01));
        _vehicle setDamage 0;
        _vehicle setVelocity [0, 0, 0];
        _vehicle lock 0;
        _vehicle setVariable ["KFH_vehicleThreatTier", "light", true];
        _vehicle setVariable ["KFH_supportLabel", "Patrol Buggy", true];
        [_vehicle] call KFH_fnc_installVehicleThreatHandlers;
        [_vehicle] call KFH_fnc_installPatrolVehicleDurability;
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
            private _stageText = if (([] call KFH_fnc_getAnnouncementLanguageIndex) isEqualTo 0) then {
                "軽装パトロール中。周辺通信が乱れ始めたデス。"
            } else {
                "Light patrol in progress. Local comms are starting to degrade."
            };
            [KFH_outbreakStartDate, _stageText] call KFH_fnc_setMissionDateStage;
            ["Patrol cut off by a sudden outbreak. Move checkpoint to checkpoint, scavenge fuel and supplies, then reach extraction.", "STORY"] call KFH_fnc_appendRunEvent;
            ["HQ: Patrol team, comms are degraded. Marked checkpoints are your best route back. Patrol buggies have fuel, but abandoned vehicles will be scarce."] call KFH_fnc_log;
        };
        case "firstCheckpoint": {
            ["story_civilian_traffic_collapsed"] call KFH_fnc_notifyAllKey;
        };
        case "baseLost": {
            ["BASE LOST"] call KFH_fnc_setStoryObjective;
            ["HQ: Bad news. Your original base is gone. Repeat, base is overrun. Arsenal may still be there, but it is not safe.", "STORY"] call KFH_fnc_appendRunEvent;
            ["story_base_lost"] call KFH_fnc_notifyAllKey;
            [] remoteExecCall ["KFH_fnc_playBaseLostWarning", 0];
        };
        case "finalCheckpoint": {
            ["ARSENAL OPTIONAL"] call KFH_fnc_setStoryObjective;
            ["HQ: Arsenal signal is live, but heavy contacts are converging. Prepare for extraction and do not forget flare capability.", "STORY"] call KFH_fnc_appendRunEvent;
            ["story_arsenal_online"] call KFH_fnc_notifyAllKey;
        };
        case "extractReleased": {
            ["REACH LZ"] call KFH_fnc_setStoryObjective;
            ["HQ: New LZ transmitted. Original base is lost; helicopter pickup is the only clean exit now.", "STORY"] call KFH_fnc_appendRunEvent;
            ["story_alt_lz_sent"] call KFH_fnc_notifyAllKey;
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
    params ["_ammo", "_medical", "_checkpointIndex", ["_includeReward", false]];

    private _players = [] call KFH_fnc_getRewardPlayerCount;
    private _tier = [_checkpointIndex] call KFH_fnc_getCheckpointRewardTier;
    private _sameCache = !(isNull _ammo) && {!(isNull _medical)} && {_ammo isEqualTo _medical};
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
            _ammo addMagazineCargoGlobal ["30Rnd_9x21_Mag_SMG_02", 8 + _players];
            _ammo addMagazineCargoGlobal ["30Rnd_556x45_Stanag", 8 + _players];
            [_ammo, "acc_flashlight", 2] call KFH_fnc_addOptionalItemCargo;
            [_ammo, "optic_Aco", 1] call KFH_fnc_addOptionalItemCargo;
            [_ammo, "optic_ACO_grn_smg", 1] call KFH_fnc_addOptionalItemCargo;
        };
        _ammo addMagazineCargoGlobal ["HandGrenade", 2 + floor (_players / 3)];
        _ammo addMagazineCargoGlobal ["SmokeShell", 3 + ceil (_players / 4)];
        _ammo addItemCargoGlobal ["FirstAidKit", 4 + _players];

        if (_includeReward) then {
            private _supplyVanillaBundles = switch (_tier) do {
                case 1: {
                    [
                        ["SMG_02_F", "30Rnd_9x21_Mag_SMG_02", 8, ["optic_ACO_grn_smg", "acc_flashlight"]],
                        ["hgun_PDW2000_F", "30Rnd_9x21_Mag", 8, ["optic_ACO_grn_smg", "acc_flashlight"]]
                    ]
                };
                case 2: {
                    [
                        ["arifle_TRG21_F", "30Rnd_556x45_Stanag", 10, ["optic_Aco", "acc_flashlight"]],
                        ["arifle_Mk20C_F", "30Rnd_556x45_Stanag", 10, ["optic_ACO_grn", "acc_pointer_IR"]]
                    ]
                };
                default {
                    [
                        ["LMG_Mk200_F", "200Rnd_65x39_cased_Box", 3, ["optic_Hamr", "acc_pointer_IR"]],
                        ["arifle_MX_SW_F", "100Rnd_65x39_caseless_mag", 4, ["optic_Hamr", "acc_pointer_IR"]]
                    ]
                };
            };
            private _supplyOptionalBundles = (missionNamespace getVariable [format ["KFH_cupRewardWeaponBundlesTier%1", _tier], []]) + ([_tier] call KFH_fnc_getDynamicRhsRewardBundles);
            [_ammo, _supplyVanillaBundles, _supplyOptionalBundles, 1 + floor (_players / 6)] call KFH_fnc_addRewardWeaponBundlePool;
            [_ammo, 1, true] call KFH_fnc_addRecentRewardBundleCargo;

            if ([_checkpointIndex] call KFH_fnc_isPrePatrolRewardCheckpoint) then {
                private _atCount = missionNamespace getVariable ["KFH_rewardPrePatrolATLauncherCount", 2];
                [_ammo, _atCount, missionNamespace getVariable ["KFH_rewardPrePatrolATLauncherBundles", []]] call KFH_fnc_addLauncherBundlesCargo;
                [
                    _ammo,
                    missionNamespace getVariable ["KFH_rewardPrePatrolATBackpacks", []],
                    missionNamespace getVariable ["KFH_rewardPrePatrolATBackpackCoverageRatio", 0.25],
                    missionNamespace getVariable ["KFH_rewardPrePatrolATBackpackMin", 2]
                ] call KFH_fnc_addScaledBackpackCargo;
                [format ["Checkpoint %1 supply received guaranteed pre-patrol AT (%2 launcher(s)).", _checkpointIndex, _atCount]] call KFH_fnc_log;
            };
        };
    };

    if !(isNull _medical) then {
        if (!_sameCache) then {
            clearWeaponCargoGlobal _medical;
            clearMagazineCargoGlobal _medical;
            clearItemCargoGlobal _medical;
            clearBackpackCargoGlobal _medical;
        };

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

KFH_fnc_fillStartSupportCargo = {
    params ["_ammo", "_medical"];

    private _players = [] call KFH_fnc_getRewardPlayerCount;
    private _difficultyIndex = missionNamespace getVariable ["KFH_difficultyIndex", (missionNamespace getVariable ["KFH_difficultyParamDefault", 1])];
    private _sidearmCoverageByDifficulty = missionNamespace getVariable ["KFH_startSidearmCacheCoverageByDifficulty", []];
    private _sidearmCoverage = missionNamespace getVariable ["KFH_startSidearmCacheCoverageRatio", 1];
    if (_difficultyIndex < (count _sidearmCoverageByDifficulty)) then {
        _sidearmCoverage = _sidearmCoverageByDifficulty select _difficultyIndex;
    };
    private _toolKitCountsByDifficulty = missionNamespace getVariable ["KFH_startToolKitCountsByDifficulty", [1, 1, 1, 0]];
    private _toolKitCount = if (_difficultyIndex < (count _toolKitCountsByDifficulty)) then {
        _toolKitCountsByDifficulty select _difficultyIndex
    } else {
        0
    };

    if !(isNull _ammo) then {
        private _weaponCount = ceil (_players * (_sidearmCoverage max 0));
        if (_weaponCount > 0) then {
            private _bundles = [missionNamespace getVariable ["KFH_startSidearmCacheBundles", []]] call KFH_fnc_filterExistingWeaponBundles;
            if ((count _bundles) > 0) then {
                [_ammo, selectRandom _bundles, _weaponCount] call KFH_fnc_addRewardWeaponBundle;
            };
        };
        [_ammo, "SmokeShell", 3 + ceil (_players / 3)] call KFH_fnc_addOptionalMagazineCargo;
        [_ammo, "Chemlight_green", 4 + ceil (_players / 3)] call KFH_fnc_addOptionalMagazineCargo;
        _ammo addItemCargoGlobal ["FirstAidKit", 2 + ceil (_players / 2)];
    };

    if !(isNull _medical) then {
        _medical addItemCargoGlobal ["FirstAidKit", 6 + _players];
        if (_toolKitCount > 0) then {
            _medical addItemCargoGlobal ["ToolKit", _toolKitCount];
        };
        _medical addMagazineCargoGlobal ["SmokeShell", 2 + ceil (_players / 4)];
    };

    [format ["Start support cargo filled: difficulty=%1 sidearmCoverage=%2 toolkit=%3.", _difficultyIndex, _sidearmCoverage, _toolKitCount]] call KFH_fnc_log;
};

KFH_fnc_spawnSupportFob = {
    params ["_markerName"];

    private _supportObjects = [];
    private _assetDirCorrection = missionNamespace getVariable ["KFH_startAssetDirCorrection", 180];

    private _ammo = ["Box_NATO_Ammo_F", _markerName, KFH_supportAmmoOffset, 180, false, _assetDirCorrection] call KFH_fnc_spawnSupportObject;
    _ammo setVariable ["KFH_supportType", "ammo", true];
    _ammo setVariable ["KFH_supportLabel", "Ammo Cache", true];
    clearWeaponCargoGlobal _ammo;
    clearMagazineCargoGlobal _ammo;
    clearItemCargoGlobal _ammo;
    clearBackpackCargoGlobal _ammo;
    _supportObjects pushBack _ammo;

    private _medical = ["Box_NATO_Equip_F", _markerName, KFH_supportMedicalOffset, 180, false, _assetDirCorrection] call KFH_fnc_spawnSupportObject;
    _medical setVariable ["KFH_supportType", "medical", true];
    _medical setVariable ["KFH_supportLabel", "Medical Station", true];
    clearWeaponCargoGlobal _medical;
    clearMagazineCargoGlobal _medical;
    clearItemCargoGlobal _medical;
    clearBackpackCargoGlobal _medical;
    _supportObjects pushBack _medical;

    [_ammo, _medical] call KFH_fnc_fillStartSupportCargo;

    private _repair = [KFH_repairStationClass, _markerName, KFH_supportRepairOffset, 270, false, _assetDirCorrection] call KFH_fnc_spawnSupportObject;
    _repair setDamage 0;
    _repair setVariable ["KFH_supportType", "repair", true];
    _repair setVariable ["KFH_supportLabel", "Field Maintenance", true];
    clearWeaponCargoGlobal _repair;
    clearMagazineCargoGlobal _repair;
    clearItemCargoGlobal _repair;
    clearBackpackCargoGlobal _repair;
    _supportObjects pushBack _repair;

    if (
        is3DENPreview &&
        {missionNamespace getVariable ["KFH_debugEdenStartArsenalEnabled", true]}
    ) then {
        private _arsenal = [
            "B_supplyCrate_F",
            _markerName,
            missionNamespace getVariable ["KFH_debugEdenStartArsenalOffset", [-5, -6, 0]],
            180,
            false,
            _assetDirCorrection
        ] call KFH_fnc_spawnSupportObject;
        _arsenal allowDamage false;
        _arsenal setVariable ["KFH_supportType", "arsenal", true];
        _arsenal setVariable ["KFH_supportLabel", "Debug Arsenal", true];
        [_arsenal] call KFH_fnc_setupSafeAllArsenal;
        _supportObjects pushBack _arsenal;
    };

    {
        _x params ["_className", "_offset", "_dirOffset"];
        private _decor = [_className, _markerName, _offset, _dirOffset, false, _assetDirCorrection] call KFH_fnc_spawnSupportObject;
        _supportObjects pushBack _decor;
    } forEach KFH_supportDecor;

    missionNamespace setVariable ["KFH_supportObjects", _supportObjects, true];
    _supportObjects
};

KFH_fnc_spawnCheckpointSupport = {
    params ["_markerName", "_checkpointIndex"];

    private _supplyKey = format ["KFH_checkpointSupplyObject_%1", _checkpointIndex];
    private _existingSupply = missionNamespace getVariable [_supplyKey, objNull];
    if (!isNull _existingSupply && {alive _existingSupply}) exitWith { [_existingSupply] };

    private _assetDirCorrection = missionNamespace getVariable ["KFH_checkpointAssetDirCorrection", 90];
    private _supplyClass = missionNamespace getVariable ["KFH_checkpointSupplyCrateClass", "Box_NATO_AmmoVeh_F"];
    private _supply = [_supplyClass, _markerName, KFH_checkpointAmmoOffset, 180, false, _assetDirCorrection] call KFH_fnc_spawnSupportObject;
    _supply allowDamage false;
    _supply setVariable ["KFH_supportType", "resupply", true];
    _supply setVariable ["KFH_supportLabel", format ["Checkpoint %1 Resupply Cache", _checkpointIndex], true];
    _supply setVariable ["KFH_checkpointIndex", _checkpointIndex, true];
    clearWeaponCargoGlobal _supply;
    clearMagazineCargoGlobal _supply;
    clearItemCargoGlobal _supply;
    clearBackpackCargoGlobal _supply;
    [_supply, _supply, _checkpointIndex, false] call KFH_fnc_fillCheckpointSupplyCargo;
    [_supply] call KFH_fnc_appendSupportObject;
    missionNamespace setVariable [_supplyKey, _supply, true];

    private _landmarkKey = format ["KFH_checkpointLandmarks_%1", _checkpointIndex];
    private _landmarks = missionNamespace getVariable [_landmarkKey, []];

    {
        private _beacon = ["MetalBarrel_burning_F", _markerName, _x, 0, false, _assetDirCorrection] call KFH_fnc_spawnSupportObject;
        _beacon setVariable ["KFH_supportLabel", format ["Checkpoint %1 Beacon", _checkpointIndex], true];
        _beacon allowDamage false;
        _landmarks pushBack _beacon;
        [_beacon] call KFH_fnc_appendSupportObject;
    } forEach KFH_checkpointBeaconOffsets;
    missionNamespace setVariable [_landmarkKey, _landmarks];

    [_supply]
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
    private _assetDirCorrection = missionNamespace getVariable ["KFH_checkpointAssetDirCorrection", 90];

    {
        _x params ["_className", "_offset", ["_dirOffset", 0], ["_damage", 0], ["_allowDamage", false]];
        private _object = [_className, _markerName, _offset, _dirOffset, _damage, _allowDamage, _assetDirCorrection] call KFH_fnc_spawnOutbreakObject;
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
    [_checkpointMarker, _checkpointIndex] call KFH_fnc_spawnCheckpointSupport;
    ["checkpoint_defense_started", [
        _checkpointIndex,
        _hostileCount,
        [_checkpointIndex] call KFH_fnc_getCheckpointEventSummary
    ]] call KFH_fnc_notifyAllKey;
    ["A3\Sounds_F\sfx\blip1.wss", 1.9, 0.78] remoteExecCall ["KFH_fnc_playUiCue", 0];

    switch ([_checkpointIndex] call KFH_fnc_getCheckpointEventId) do {
        case "surge": {
            [_checkpointIndex, 0.45] call KFH_fnc_spawnCheckpointWave;
            ["checkpoint_hive_surge", [_checkpointIndex]] call KFH_fnc_notifyAllKey;
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
        ["checkpoint_blocking_contact", [_checkpointIndex]] call KFH_fnc_notifyAllKey;
    };
};

KFH_fnc_scheduleCheckpointSupplyArrival = {
    params ["_checkpointIndex", "_checkpointMarker"];

    private _scheduledKey = format ["KFH_checkpointSupplyScheduled_%1", _checkpointIndex];
    private _arrivedKey = format ["KFH_checkpointSupplyArrived_%1", _checkpointIndex];

    if (missionNamespace getVariable [_scheduledKey, false]) exitWith {};
    if (missionNamespace getVariable [_arrivedKey, false]) exitWith {};

    missionNamespace setVariable [_scheduledKey, true, true];
    ["checkpoint_supply_enroute", [
        _checkpointIndex,
        [_checkpointIndex] call KFH_fnc_getCheckpointSupplyDelay
    ]] call KFH_fnc_notifyAllKey;

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
        ["checkpoint_supply_arrived", [_checkpointIndex]] call KFH_fnc_notifyAllKey;
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

    ["support_loadout_restored"] call KFH_fnc_localNotifyKey;
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

    ["support_medical_patched"] call KFH_fnc_localNotifyKey;
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
        ["support_repair_serviced", [count _nearVehicles]] call KFH_fnc_localNotifyKey;
    } else {
        ["support_repair_stamina"] call KFH_fnc_localNotifyKey;
    };
};

