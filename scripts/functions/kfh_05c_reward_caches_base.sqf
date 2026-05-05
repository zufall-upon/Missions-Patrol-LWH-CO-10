KFH_fnc_fillRewardCache = {
    params ["_cache", "_checkpointIndex", ["_clearFirst", true]];

    if (isNull _cache) exitWith {};

    if (_clearFirst) then {
        clearWeaponCargoGlobal _cache;
        clearMagazineCargoGlobal _cache;
        clearItemCargoGlobal _cache;
        clearBackpackCargoGlobal _cache;
    };

    private _tier = [_checkpointIndex] call KFH_fnc_getCheckpointRewardTier;
    private _tierName = [_checkpointIndex] call KFH_fnc_getCheckpointRewardTierName;
    private _rewardPlayers = [] call KFH_fnc_getRewardPlayerCount;
    private _weaponCount = (ceil (_rewardPlayers * (missionNamespace getVariable ["KFH_rewardWeaponCoverageRatio", 0.75]))) max 2;
    private _backpackCount = (ceil (_rewardPlayers * (missionNamespace getVariable ["KFH_rewardBackpackCoverageRatio", 0.35]))) max 1;
    missionNamespace setVariable ["KFH_recentRewardWeaponBundles", [], true];

    switch (_tier) do {
        case 1: {
            private _vanillaBundles = [
                ["SMG_02_F", "30Rnd_9x21_Mag_SMG_02", 8, ["optic_ACO_grn_smg", "acc_flashlight"]],
                ["hgun_PDW2000_F", "30Rnd_9x21_Mag", 10, ["optic_ACO_grn_smg", "acc_flashlight"]],
                ["arifle_TRG20_F", "30Rnd_556x45_Stanag", 8, ["optic_Aco", "acc_flashlight"]]
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

    if ([_checkpointIndex] call KFH_fnc_isPrePatrolRewardCheckpoint) then {
        private _atCount = missionNamespace getVariable ["KFH_rewardPrePatrolATLauncherCount", 2];
        private _addedAt = [_cache, _atCount, missionNamespace getVariable ["KFH_rewardPrePatrolATLauncherBundles", []]] call KFH_fnc_addLauncherBundlesCargo;
        [
            _cache,
            missionNamespace getVariable ["KFH_rewardPrePatrolATBackpacks", []],
            missionNamespace getVariable ["KFH_rewardPrePatrolATBackpackCoverageRatio", 0.25],
            missionNamespace getVariable ["KFH_rewardPrePatrolATBackpackMin", 2]
        ] call KFH_fnc_addScaledBackpackCargo;
        [format ["Checkpoint %1 reward cache guaranteed pre-patrol AT: %2 launcher(s).", _checkpointIndex, _addedAt]] call KFH_fnc_log;
    };

    [format ["Reward cache filled for checkpoint %1 (%2).", _checkpointIndex, _tierName]] call KFH_fnc_log;
};

KFH_fnc_upgradeCheckpointSupplyReward = {
    params ["_checkpointMarker", "_checkpointIndex"];

    private _upgradedKey = format ["KFH_checkpointSupplyRewardUpgraded_%1", _checkpointIndex];
    if (missionNamespace getVariable [_upgradedKey, false]) exitWith {
        missionNamespace getVariable [format ["KFH_checkpointSupplyObject_%1", _checkpointIndex], objNull]
    };

    private _supplyKey = format ["KFH_checkpointSupplyObject_%1", _checkpointIndex];
    private _supply = missionNamespace getVariable [_supplyKey, objNull];
    if (isNull _supply || {!alive _supply}) then {
        private _supportObjects = [_checkpointMarker, _checkpointIndex] call KFH_fnc_spawnCheckpointSupport;
        if ((count _supportObjects) > 0) then {
            _supply = _supportObjects select 0;
        };
    };
    if (isNull _supply) exitWith { objNull };

    [_supply, _checkpointIndex, false] call KFH_fnc_fillRewardCache;
    _supply setVariable ["KFH_supportLabel", format ["Checkpoint %1 Resupply Cache+", _checkpointIndex], true];
    _supply setVariable ["KFH_rewardUpgraded", true, true];
    missionNamespace setVariable [_upgradedKey, true, true];
    [format ["Checkpoint %1 resupply cache upgraded with secure reward cargo.", _checkpointIndex]] call KFH_fnc_log;

    _supply
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
    if (([_container, 0.5, true] call KFH_fnc_addRecentRewardBundleCargo) isEqualTo 0) then {
        _container addMagazineCargoGlobal ["30Rnd_9x21_Mag_SMG_02", 2 + _bonus];
        _container addMagazineCargoGlobal ["30Rnd_556x45_Stanag", 1 + _bonus];
        _container addMagazineCargoGlobal ["30Rnd_65x39_caseless_mag", 1 + (floor (_bonus / 2))];
    };
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

    ["side_cache_marked", [_checkpointIndex]] call KFH_fnc_notifyAllKey;
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
    ["side_cache_contact", [_checkpointIndex]] call KFH_fnc_notifyAllKey;
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
    ["final_flare_cache_marked"] call KFH_fnc_notifyAllKey;

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
            private _vanillaBundles = [
                ["LMG_Mk200_F", "200Rnd_65x39_cased_Box", 3, ["optic_Hamr", "acc_pointer_IR"]],
                ["arifle_MX_SW_F", "100Rnd_65x39_caseless_mag", 4, ["optic_Hamr", "acc_pointer_IR"]]
            ];
            private _optionalBundles = (missionNamespace getVariable ["KFH_cupRewardWeaponBundlesTier3", []]) + ([3] call KFH_fnc_getDynamicRhsRewardBundles);
            [_crate, _vanillaBundles, _optionalBundles, 3] call KFH_fnc_addRewardWeaponBundlePool;
            [_crate, 1, true] call KFH_fnc_addRecentRewardBundleCargo;
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
    ["optional_arsenal_marked"] call KFH_fnc_notifyAllKey;

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

    private _tier = [_checkpointIndex] call KFH_fnc_getCheckpointRewardTier;
    switch (_tier) do {
        case 1: { _elite addBackpack "B_AssaultPack_ocamo"; };
        case 2: { _elite addBackpack "B_Kitbag_cbr"; };
        default { _elite addBackpack "B_Carryall_ocamo"; };
    };
    private _vanillaBundles = switch (_tier) do {
        case 1: {
            [
                ["SMG_02_F", "30Rnd_9x21_Mag_SMG_02", 4, ["optic_ACO_grn_smg", "acc_flashlight"]],
                ["hgun_PDW2000_F", "30Rnd_9x21_Mag", 5, ["optic_ACO_grn_smg", "acc_flashlight"]]
            ]
        };
        case 2: {
            [
                ["arifle_TRG21_F", "30Rnd_556x45_Stanag", 5, ["optic_Aco", "acc_flashlight"]],
                ["arifle_Katiba_C_F", "30Rnd_65x39_caseless_green", 5, ["optic_ACO_grn", "acc_pointer_IR"]]
            ]
        };
        default {
            [
                ["LMG_Mk200_F", "200Rnd_65x39_cased_Box", 2, ["optic_Hamr", "acc_pointer_IR"]],
                ["arifle_MX_SW_F", "100Rnd_65x39_caseless_mag", 3, ["optic_Hamr", "acc_pointer_IR"]]
            ]
        };
    };
    private _optionalBundles = (missionNamespace getVariable [format ["KFH_cupRewardWeaponBundlesTier%1", _tier], []]) + ([_tier] call KFH_fnc_getDynamicRhsRewardBundles);
    private _entry = [_vanillaBundles, _optionalBundles, missionNamespace getVariable ["KFH_cupRewardPreferredChance", 1]] call KFH_fnc_selectAvailableWeaponBundle;
    if ((count _entry) >= 2) then {
        private _weapon = _entry select 0;
        private _mag = _entry select 1;
        private _magCount = if ((count _entry) > 2) then { (_entry select 2) min 6 } else { 4 };
        private _attachments = if ((count _entry) > 3) then { _entry select 3 } else { [] };
        [_elite, _weapon, _mag, _attachments, _magCount] call KFH_fnc_givePrimaryWeaponLoadout;
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
        ["signal_hunt_bonus_team", [_checkpointIndex]] call KFH_fnc_notifyAllKey;
};

