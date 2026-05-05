KFH_fnc_getCheckpointRewardTier = {
    params ["_checkpointIndex"];

    private _markers = missionNamespace getVariable ["KFH_checkpointMarkers", []];
    private _total = missionNamespace getVariable ["KFH_totalCheckpoints", count _markers];
    if (_total <= 0) exitWith { ((_checkpointIndex max 1) min 3) };

    ((ceil (((_checkpointIndex max 1) / (_total max 1)) * 3)) max 1) min 3
};

KFH_fnc_getCheckpointRewardTierName = {
    params ["_checkpointIndex"];

    private _lang = [] call KFH_fnc_getAnnouncementLanguageIndex;
    switch ([_checkpointIndex] call KFH_fnc_getCheckpointRewardTier) do {
        case 1: { if (_lang isEqualTo 0) then { "突破装備" } else { "Breacher Tier" } };
        case 2: { if (_lang isEqualTo 0) then { "ライフル装備" } else { "Rifle Tier" } };
        default { if (_lang isEqualTo 0) then { "持久戦装備" } else { "Holdout Tier" } };
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

    private _magazines = (getArray (_weaponCfg >> "magazines")) + ([_weaponCfg] call KFH_fnc_getWeaponMagazineWellMagazines);
    private _usable = _magazines select {
        isClass (configFile >> "CfgMagazines" >> _x) &&
        {!([_x, ["grenade", "flare", "signal", "smoke"]] call KFH_fnc_stringContainsAny)}
    };

    if ((count _usable) > 0) exitWith {
        private _best = _usable select 0;
        private _bestCount = getNumber (configFile >> "CfgMagazines" >> _best >> "count");
        {
            private _count = getNumber (configFile >> "CfgMagazines" >> _x >> "count");
            if (_count > _bestCount) then {
                _best = _x;
                _bestCount = _count;
            };
        } forEach _usable;
        _best
    };
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
    private _priorityTokens = missionNamespace getVariable ["KFH_dynamicRhsRewardPriorityTokens", []];
    private _weaponConfigs = configProperties [configFile >> "CfgWeapons", "isClass _x", true];

    private _addCandidate = {
        params ["_cfg"];

        private _className = configName _cfg;
        private _lowerClass = toLower _className;
        if (
            ((_lowerClass find "rhs_weap_") isEqualTo 0) ||
            {(_lowerClass find "rhsusf_weap_") isEqualTo 0} ||
            {(_lowerClass find "rhsgref_weap_") isEqualTo 0}
        ) then {
            private _scope = getNumber (_cfg >> "scope");
            private _displayName = getText (_cfg >> "displayName");
            private _category = [_className, _displayName] call KFH_fnc_getDynamicRhsRewardCategory;
            if (_scope >= 2 && {!(_displayName isEqualTo "")} && {(count _category) > 0}) then {
                _category params ["_categoryName", "_minTier", "_magazineCount", "_attachments"];
                private _categoryCount = switch (_categoryName) do {
                    case "shotgun": { _shotguns };
                    case "machinegun": { _machineguns };
                    default { _battleRifles };
                };
                private _canAdd = _categoryCount < _maxPerCategory;
                if (_canAdd) then {
                    private _baseWeapon = getText (_cfg >> "baseWeapon");
                    if (_baseWeapon isEqualTo "") then { _baseWeapon = _className; };
                    if !(_baseWeapon in _seenBaseWeapons) then {
                        private _magazine = [_cfg] call KFH_fnc_selectDynamicRhsMagazine;
                        if !(_magazine isEqualTo "") then {
                            _seenBaseWeapons pushBack _baseWeapon;
                            private _bundle = [_className, _magazine, _magazineCount, _attachments, "dynamicRhs", _categoryName];
                            if (_minTier <= 1) then { _tier1 pushBack _bundle; };
                            if (_minTier <= 2) then { _tier2 pushBack _bundle; };
                            _tier3 pushBack _bundle;
                            switch (_categoryName) do {
                                case "shotgun": { _shotguns = _shotguns + 1; };
                                case "machinegun": { _machineguns = _machineguns + 1; };
                                default { _battleRifles = _battleRifles + 1; };
                            };
                        };
                    };
                };
            };
        };
    };

    {
        private _className = configName _x;
        private _displayName = getText (_x >> "displayName");
        if ([format ["%1 %2", _className, _displayName], _priorityTokens] call KFH_fnc_stringContainsAny) then {
            [_x] call _addCandidate;
        };
    } forEach _weaponConfigs;

    {
        [_x] call _addCandidate;
    } forEach _weaponConfigs;

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
    private _dynamicOptional = _optional select { (count _x) > 4 && {(_x select 4) isEqualTo "dynamicRhs"} };
    private _dynamicChance = missionNamespace getVariable ["KFH_dynamicRhsRewardPreferredChance", 0.75];

    if ((count _dynamicOptional) > 0 && {(random 1) < _dynamicChance}) exitWith {
        selectRandom _dynamicOptional
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
    [
        _cache,
        missionNamespace getVariable ["KFH_sideCacheLargeBackpacks", []],
        missionNamespace getVariable ["KFH_sideCacheLargeBackpackCoverageRatio", 0.25],
        missionNamespace getVariable ["KFH_sideCacheLargeBackpackMin", 2]
    ] call KFH_fnc_addScaledBackpackCargo;
    [_cache, "DemoCharge_Remote_Mag", 1] call KFH_fnc_addOptionalMagazineCargo;
    [_cache, "APERSTripMine_Wire_Mag", 2] call KFH_fnc_addOptionalMagazineCargo;
    [_cache] call KFH_fnc_addSideCacheBonusCargo;
    [format ["Side cache AT bonus added for checkpoint %1 (%2 launchers).", _checkpointIndex, _added]] call KFH_fnc_log;
};

KFH_fnc_getRewardPlayerCount = {
    private _scalingPlayers = [] call KFH_fnc_getScalingPlayerCount;
    (_scalingPlayers max 1) min ([] call KFH_fnc_getTargetPlayers)
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

KFH_fnc_addScaledBackpackCargo = {
    params ["_cache", ["_backpacks", []], ["_coverageRatio", 0.25], ["_minCount", 1]];

    private _available = _backpacks select { isClass (configFile >> "CfgVehicles" >> _x) };
    if ((count _available) isEqualTo 0) exitWith { 0 };

    private _players = [] call KFH_fnc_getRewardPlayerCount;
    private _count = ((ceil (_players * (_coverageRatio max 0))) max _minCount) max 1;
    for "_i" from 1 to _count do {
        _cache addBackpackCargoGlobal [selectRandom _available, 1];
    };
    _count
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

KFH_fnc_addRecentRewardBundleCargo = {
    params ["_cache", ["_magMultiplier", 1], ["_includeAttachments", true]];

    private _added = 0;
    {
        if ((count _x) >= 2) then {
            private _weaponClass = _x select 0;
            private _magazineClass = _x select 1;
            private _magazineCount = if ((count _x) > 2) then { _x select 2 } else { 4 };
            if ([_cache, _magazineClass, ceil (_magazineCount * (_magMultiplier max 1))] call KFH_fnc_addOptionalMagazineCargo) then {
                _added = _added + 1;
            };
            if (_includeAttachments) then {
                private _attachments = if ((count _x) > 3) then { _x select 3 } else { [] };
                {
                    [_cache, _x, 1] call KFH_fnc_addOptionalItemCargo;
                } forEach ([_weaponClass, _attachments] call KFH_fnc_filterCompatibleWeaponAttachments);
            };
        };
    } forEach (missionNamespace getVariable ["KFH_recentRewardWeaponBundles", []]);

    _added
};

KFH_fnc_isPrePatrolRewardCheckpoint = {
    params ["_checkpointIndex"];

    if !(missionNamespace getVariable ["KFH_rewardPrePatrolATEnabled", true]) exitWith { false };
    private _startCheckpoint = missionNamespace getVariable ["KFH_envTrafficMilitaryStartCheckpoint", 3];
    _checkpointIndex isEqualTo ((_startCheckpoint - 1) max 1)
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

