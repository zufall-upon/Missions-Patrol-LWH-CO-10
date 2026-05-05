KFH_fnc_applyDebugTeammateCombatProfile = {
    params ["_unit"];

    if (isNull _unit) exitWith {};

    _unit allowFleeing 0;
    _unit enableFatigue false;
    _unit enableAI "TARGET";
    _unit enableAI "AUTOTARGET";
    _unit enableAI "AUTOCOMBAT";
    _unit enableAI "WEAPONAIM";
    _unit setCombatMode "RED";
    _unit setBehaviourStrong "COMBAT";
    _unit setSpeedMode "FULL";
    _unit setUnitPos "AUTO";
    _unit doFollow leader (group _unit);
    (group _unit) setCombatMode "RED";
    (group _unit) setBehaviourStrong "COMBAT";
    (group _unit) setSpeedMode "FULL";

    _unit setSkill KFH_debugTeammateSkill;
    _unit setSkill ["aimingAccuracy", KFH_debugTeammateAimingAccuracy];
    _unit setSkill ["aimingShake", 0.45];
    _unit setSkill ["aimingSpeed", 0.72];
    _unit setSkill ["spotDistance", 0.85];
    _unit setSkill ["spotTime", 0.78];
    _unit setSkill ["courage", 1];
    _unit setSkill ["commanding", 0.82];
    _unit setSkill ["general", KFH_debugTeammateSkill];

    if !(_unit getVariable ["KFH_debugCombatDamageInstalled", false]) then {
        _unit addEventHandler ["HandleDamage", {
            params ["_unit", "_selection", "_incomingDamage", "_source"];

            if (isNull _unit) exitWith { _incomingDamage };
            if !(local _unit) exitWith { _incomingDamage };

            private _safeDamage = missionNamespace getVariable ["KFH_forcedDownedDamage", 0.42];
            if (_unit getVariable ["KFH_forcedDowned", false]) exitWith { [_unit] call KFH_fnc_getSuppressedDownedDamage };

            private _protectedUntil = _unit getVariable ["KFH_postReviveProtectedUntil", -1];
            if (_protectedUntil > time) exitWith { (damage _unit) min _safeDamage };

            private _currentDamage = damage _unit;
            private _damageScale = KFH_debugTeammateDamageScale;
            private _scaledDamage = _currentDamage + (((_incomingDamage - _currentDamage) max 0) * _damageScale);
            _scaledDamage = (_scaledDamage max 0) min 1;
            if (_unit getVariable ["KFH_aiReviveBusy", false]) exitWith {
                private _busyScale = (_damageScale * 0.5) max 0.05;
                private _busyDamage = _currentDamage + (((_incomingDamage - _currentDamage) max 0) * _busyScale);
                (_busyDamage max 0) min 1
            };

            if (missionNamespace getVariable ["KFH_debugTeammateDownedProtectionEnabled", true]) then {
                private _damageThreshold = missionNamespace getVariable ["KFH_downedInterceptDamageThreshold", 0.72];
                private _totalDamageThreshold = missionNamespace getVariable ["KFH_downedInterceptTotalDamageThreshold", 0.82];
                if (
                    (_scaledDamage >= _damageThreshold || {_scaledDamage >= _totalDamageThreshold}) &&
                    {[_unit] call KFH_fnc_hasRescueCoverageFor}
                ) exitWith {
                    [_unit, _source, "Echo fatal damage intercepted"] call KFH_fnc_forceUnitDowned;
                    _safeDamage
                };
            };

            _scaledDamage
        }];
        _unit setVariable ["KFH_debugCombatDamageInstalled", true];
    };
};

KFH_fnc_applyDebugTeammateWeaponProfile = {
    params ["_unit"];

    if (isNull _unit) exitWith {};

    private _weapon = missionNamespace getVariable ["KFH_debugTeammatePrimaryWeapon", ""];
    private _magazine = missionNamespace getVariable ["KFH_debugTeammatePrimaryMagazine", ""];
    if (_weapon isEqualTo "" || {_magazine isEqualTo ""}) exitWith {};
    if !(isClass (configFile >> "CfgWeapons" >> _weapon)) exitWith {};
    if !(isClass (configFile >> "CfgMagazines" >> _magazine)) exitWith {};

    private _backpack = missionNamespace getVariable ["KFH_debugTeammateBackpack", ""];
    if ((backpack _unit) isEqualTo "" && {!(_backpack isEqualTo "")} && {isClass (configFile >> "CfgVehicles" >> _backpack)}) then {
        _unit addBackpack _backpack;
    };

    if ((primaryWeapon _unit) isEqualTo "") then {
        [
            _unit,
            _weapon,
            _magazine,
            missionNamespace getVariable ["KFH_debugTeammatePrimaryAttachments", []],
            ((missionNamespace getVariable ["KFH_debugTeammatePrimaryMagCount", 12]) - 1) max 0
        ] call KFH_fnc_givePrimaryWeaponLoadout;
    };
};

KFH_fnc_addInventoryItem = {
    params ["_unit", "_itemClass"];

    if (isNull _unit) exitWith { false };
    if (isClass (configFile >> "CfgMagazines" >> _itemClass)) exitWith {
        if !(_unit canAdd _itemClass) exitWith { false };
        _unit addMagazine _itemClass;
        true
    };
    if !(isClass (configFile >> "CfgWeapons" >> _itemClass)) exitWith { false };

    if (_unit canAddItemToUniform _itemClass) exitWith {
        _unit addItemToUniform _itemClass;
        true
    };

    if ((vest _unit) isNotEqualTo "" && {_unit canAddItemToVest _itemClass}) exitWith {
        _unit addItemToVest _itemClass;
        true
    };

    if ((backpack _unit) isNotEqualTo "" && {_unit canAddItemToBackpack _itemClass}) exitWith {
        _unit addItemToBackpack _itemClass;
        true
    };

    if (_unit canAdd _itemClass) exitWith {
        _unit addItem _itemClass;
        true
    };

    false
};

KFH_fnc_addInventoryItems = {
    params ["_unit", "_itemClass", ["_count", 1]];

    private _added = 0;
    for "_i" from 1 to _count do {
        if ([_unit, _itemClass] call KFH_fnc_addInventoryItem) then {
            _added = _added + 1;
        };
    };

    if (_added < _count) then {
        [format [
            "Inventory full while adding %1 to %2 (%3/%4).",
            _itemClass,
            name _unit,
            _added,
            _count
        ]] call KFH_fnc_log;
    };

    _added
};

KFH_fnc_addUnitLootClass = {
    params ["_unit", "_className"];

    if (isNull _unit) exitWith { false };
    if (isClass (configFile >> "CfgMagazines" >> _className)) exitWith {
        if !(_unit canAdd _className) exitWith { false };
        _unit addMagazine _className;
        true
    };

    if (isClass (configFile >> "CfgWeapons" >> _className)) exitWith {
        [_unit, _className] call KFH_fnc_addInventoryItem
    };

    false
};

KFH_fnc_addRecentRewardWeaponLoot = {
    params ["_unit"];

    if (isNull _unit) exitWith { 0 };
    if !(missionNamespace getVariable ["KFH_enemyLootUseRecentRewardBundles", true]) exitWith { 0 };
    if ((random 1) > (missionNamespace getVariable ["KFH_enemyLootRecentBundleChance", 0.75])) exitWith { 0 };

    private _bundles = (missionNamespace getVariable ["KFH_recentRewardWeaponBundles", []]) select {
        (count _x) >= 2 && {isClass (configFile >> "CfgMagazines" >> (_x select 1))}
    };
    if ((count _bundles) isEqualTo 0) exitWith { 0 };

    private _bundle = selectRandom _bundles;
    private _weaponClass = _bundle select 0;
    private _magazineClass = _bundle select 1;
    private _maxMags = missionNamespace getVariable ["KFH_enemyLootRecentBundleMaxMags", 2];
    private _magCount = 1 + floor (random (_maxMags max 1));
    private _added = 0;

    for "_i" from 1 to _magCount do {
        if ([_unit, _magazineClass] call KFH_fnc_addUnitLootClass) then {
            _added = _added + 1;
        };
    };

    if ((random 1) <= (missionNamespace getVariable ["KFH_enemyLootRecentBundleAttachmentChance", 0.12])) then {
        private _attachments = if ((count _bundle) > 3) then { _bundle select 3 } else { [] };
        private _compatible = [_weaponClass, _attachments] call KFH_fnc_filterCompatibleWeaponAttachments;
        if ((count _compatible) > 0) then {
            if ([_unit, selectRandom _compatible] call KFH_fnc_addUnitLootClass) then {
                _added = _added + 1;
            };
        };
    };

    _added
};

KFH_fnc_addUnitLootTable = {
    params ["_unit", "_lootTable", ["_roleLabel", "loot"]];

    if (isNull _unit) exitWith {};
    if !(missionNamespace getVariable ["KFH_meleeLootEnabled", true]) exitWith {};

    private _added = 0;
    _added = _added + ([_unit] call KFH_fnc_addRecentRewardWeaponLoot);
    {
        _x params ["_className", ["_minCount", 0], ["_maxCount", 1], ["_chance", 1]];

        if ((random 1) <= _chance) then {
            private _rollMax = (_maxCount - _minCount) max 0;
            private _count = _minCount + floor (random (_rollMax + 1));

            for "_i" from 1 to _count do {
                if ([_unit, _className] call KFH_fnc_addUnitLootClass) then {
                    _added = _added + 1;
                };
            };
        };
    } forEach _lootTable;

    if (_added <= 0 && {(random 1) <= (missionNamespace getVariable ["KFH_meleeLootFallbackChance", 0])}) then {
        private _fallbackItems = missionNamespace getVariable ["KFH_meleeLootFallbackItems", []];
        if ((count _fallbackItems) > 0) then {
            if ([_unit, selectRandom _fallbackItems] call KFH_fnc_addUnitLootClass) then {
                _added = _added + 1;
            };
        };
    };

    if (_added > 0) then {
        _unit setVariable ["KFH_lootRole", _roleLabel, true];
        _unit setVariable ["KFH_lootItemsAdded", _added, true];
    };
};

KFH_fnc_giveHandgunLoadout = {
    params ["_unit", "_weaponClass", "_magClass", ["_attachmentClass", ""], ["_extraMagCount", 0]];

    _unit addMagazine _magClass;
    _unit addWeapon _weaponClass;

    if !(_attachmentClass isEqualTo "") then {
        _unit addHandgunItem _attachmentClass;
    };

    [_unit, _magClass, _extraMagCount] call KFH_fnc_addInventoryItems;
};

KFH_fnc_filterCompatibleWeaponAttachments = {
    params ["_weaponClass", ["_attachments", []]];

    private _weaponCfg = configFile >> "CfgWeapons" >> _weaponClass;
    if !(isClass _weaponCfg) exitWith { [] };

    private _allowed = [];
    private _slotsCfg = _weaponCfg >> "WeaponSlotsInfo";
    if (isClass _slotsCfg) then {
        {
            _allowed append (getArray (_x >> "compatibleItems"));
        } forEach (configProperties [_slotsCfg, "isClass _x", true]);
    };

    _attachments select {
        !(_x isEqualTo "") &&
        {isClass (configFile >> "CfgWeapons" >> _x)} &&
        {_x in _allowed}
    }
};

KFH_fnc_givePrimaryWeaponLoadout = {
    params ["_unit", "_weaponClass", "_magClass", ["_attachments", []], ["_extraMagCount", 0]];

    _unit addMagazine _magClass;
    _unit addWeapon _weaponClass;

    {
        if !(_x isEqualTo "") then {
            _unit addPrimaryWeaponItem _x;
        };
    } forEach ([_weaponClass, _attachments] call KFH_fnc_filterCompatibleWeaponAttachments);

    [_unit, _magClass, _extraMagCount] call KFH_fnc_addInventoryItems;
};

KFH_fnc_applyStarterLoadout = {
    params ["_unit"];

    if (isNull _unit) exitWith {};

    private _starterOptionalAllowed = isServer || {
        missionNamespace getVariable ["KFH_optionalContentAvailableOnServer", false]
    };
    private _cupChance = missionNamespace getVariable ["KFH_cupStarterPreferredChance", 0.9];
    private _optionalUniforms = if (_starterOptionalAllowed) then { missionNamespace getVariable ["KFH_cupStarterUniforms", []] } else { [] };
    private _optionalVests = if (_starterOptionalAllowed) then { missionNamespace getVariable ["KFH_cupStarterVests", []] } else { [] };
    private _optionalHeadgear = if (_starterOptionalAllowed) then { missionNamespace getVariable ["KFH_cupStarterHeadgear", []] } else { [] };
    private _optionalSidearms = if (_starterOptionalAllowed) then { missionNamespace getVariable ["KFH_cupStarterSidearms", []] } else { [] };
    private _uniform = [
        "CfgWeapons",
        missionNamespace getVariable ["KFH_starterUniforms", []],
        _optionalUniforms,
        _cupChance
    ] call KFH_fnc_selectAvailableConfigClass;
    private _vest = [
        "CfgWeapons",
        missionNamespace getVariable ["KFH_starterVests", []],
        _optionalVests,
        _cupChance
    ] call KFH_fnc_selectAvailableConfigClass;
    private _headgear = [
        "CfgWeapons",
        missionNamespace getVariable ["KFH_starterHeadgear", []],
        _optionalHeadgear,
        _cupChance,
        true
    ] call KFH_fnc_selectAvailableConfigClass;
    private _sidearmEntry = [
        missionNamespace getVariable ["KFH_starterSidearms", []],
        _optionalSidearms,
        _cupChance
    ] call KFH_fnc_selectAvailableWeaponBundle;
    if ((count _sidearmEntry) < 2) then {
        _sidearmEntry = selectRandom KFH_starterSidearms;
    };
    private _sidearm = _sidearmEntry select 0;
    private _sidearmMag = _sidearmEntry select 1;
    private _sidearmAttachment = if ((count _sidearmEntry) > 2) then { _sidearmEntry select 2 } else { "" };

    if (
        (missionNamespace getVariable ["KFH_cupStarterMissingWarning", true]) &&
        {_cupChance >= 1} &&
        {!([_sidearm] call KFH_fnc_isOptionalContentClass)} &&
        {!(missionNamespace getVariable ["KFH_cupStarterMissingWarned", false])}
    ) then {
        missionNamespace setVariable ["KFH_cupStarterMissingWarned", true, true];
        [format [
            "%1 starter loadout requested, but optional gear classes are not available. Check the Arma modset, or vanilla fallback will be used.",
            missionNamespace getVariable ["KFH_optionalContentLabel", "Optional"]
        ]] call KFH_fnc_log;
    };

    removeAllWeapons _unit;
    removeAllItems _unit;
    removeAllAssignedItems _unit;
    removeUniform _unit;
    removeVest _unit;
    removeBackpack _unit;
    removeHeadgear _unit;
    removeGoggles _unit;

    if (_uniform isEqualTo "") then {
        _uniform = selectRandom KFH_starterUniforms;
    };
    _unit forceAddUniform _uniform;
    if !(_vest isEqualTo "") then {
        _unit addVest _vest;
    };

    if !(_headgear isEqualTo "") then {
        _unit addHeadgear _headgear;
    };

    [_unit] call KFH_fnc_applyPrototypeCarryCapacity;

    for "_i" from 1 to KFH_starterFirstAidCount do {
        [_unit, "FirstAidKit"] call KFH_fnc_addInventoryItem;
    };

    [_unit, _sidearm, _sidearmMag, _sidearmAttachment, (KFH_starterMagCount - 1) max 0] call KFH_fnc_giveHandgunLoadout;

    [_unit, "SmokeShell"] call KFH_fnc_addInventoryItem;
    [_unit] call KFH_fnc_ensureNavigationItems;

    _unit setVariable ["KFH_starterIssued", true];
    [_unit] call KFH_fnc_updateSavedLoadout;
    [format ["Starter loadout applied to %1 with %2.", name _unit, _sidearm]] call KFH_fnc_log;
};

KFH_fnc_spawnDebugTeammate = {
    params ["_leader"];

    if (isNull _leader) exitWith { objNull };

    private _existing = missionNamespace getVariable ["KFH_debugTeammate", objNull];
    if (!isNull _existing && {alive _existing}) exitWith { _existing };

    private _spawnPos = _leader modelToWorld [1.8, -1.6, 0];
    if (surfaceIsWater _spawnPos) then {
        _spawnPos = getMarkerPos "kfh_start";
    };

    private _groupRef = group _leader;
    private _unit = _groupRef createUnit [KFH_debugTeammateClass, _spawnPos, [], 0, "FORM"];

    [_unit] joinSilent _groupRef;
    _groupRef selectLeader _leader;
    _unit setName KFH_debugTeammateName;
    _unit setSpeaker "NoVoice";
    _unit setVariable ["KFH_debugTeammate", true, true];
    _unit setVariable ["KFH_soloWingman", true, true];
    _unit setVariable ["KFH_canRevivePlayers", true, true];
    _unit allowFleeing 0;
    _unit enableFatigue false;
    _unit setUnitTrait ["Medic", true];
    _unit setFormation "WEDGE";

    private _leaderLoadout = getUnitLoadout _leader;
    if ((count _leaderLoadout) > 0) then {
        _unit setUnitLoadout _leaderLoadout;
    } else {
        [_unit] call KFH_fnc_applyStarterLoadout;
    };

    if !(missionNamespace getVariable ["KFH_debugTeammateMirrorPlayerLoadout", true]) then {
        [_unit] call KFH_fnc_applyDebugTeammateWeaponProfile;
    };
    [_unit] call KFH_fnc_applyDebugTeammateCombatProfile;
    _unit setVariable [
        "KFH_nextCombatProfileRefreshAt",
        time + (missionNamespace getVariable ["KFH_debugTeammateCombatProfileRefreshSeconds", 25])
    ];
    [_unit] call KFH_fnc_applyPrototypeCarryCapacity;
    [_unit, "Medikit"] call KFH_fnc_addInventoryItem;
    [_unit] call KFH_fnc_applyFriendlyFireMitigation;
    [_unit] call KFH_fnc_updateSavedLoadout;
    missionNamespace setVariable ["KFH_debugTeammate", _unit, true];
    missionNamespace setVariable ["KFH_lastAliveDebugTeammateAt", time, true];

    [format ["Wingman %1 joined the patrol.", KFH_debugTeammateName]] call KFH_fnc_log;

    _unit
};

KFH_fnc_spawnScalingTestAlly = {
    params ["_leader", "_index"];

    if (isNull _leader) exitWith { objNull };

    private _existing = (missionNamespace getVariable ["KFH_scalingTestAllies", []]) select {
        !isNull _x && {alive _x} && {(_x getVariable ["KFH_scalingTestAllyIndex", -1]) isEqualTo _index}
    };
    if ((count _existing) > 0) exitWith { _existing select 0 };

    private _names = missionNamespace getVariable ["KFH_scalingTestAllyNames", ["Delta", "Mika", "Rook"]];
    private _name = if (_index < (count _names)) then { _names select _index } else { format ["Scale-%1", _index + 1] };
    private _spawnPos = _leader modelToWorld [2.2 + (_index * 0.8), -2.2 - (_index * 0.4), 0];
    if (surfaceIsWater _spawnPos) then {
        _spawnPos = getMarkerPos "kfh_start";
    };

    private _groupRef = group _leader;
    private _unit = _groupRef createUnit [missionNamespace getVariable ["KFH_scalingTestAllyClass", KFH_debugTeammateClass], _spawnPos, [], 0, "FORM"];
    [_unit] joinSilent _groupRef;
    _groupRef selectLeader _leader;
    _unit setName _name;
    _unit setSpeaker "NoVoice";
    _unit setVariable ["KFH_debugTeammate", true, true];
    _unit setVariable ["KFH_soloWingman", true, true];
    _unit setVariable ["KFH_scalingTestAlly", true, true];
    _unit setVariable ["KFH_scalingTestAllyIndex", _index, true];
    _unit setVariable ["KFH_canRevivePlayers", true, true];
    _unit allowFleeing 0;
    _unit enableFatigue false;
    _unit setUnitTrait ["Medic", true];
    _unit setFormation "WEDGE";

    private _leaderLoadout = getUnitLoadout _leader;
    if ((count _leaderLoadout) > 0) then {
        _unit setUnitLoadout _leaderLoadout;
    } else {
        [_unit] call KFH_fnc_applyStarterLoadout;
    };

    [_unit] call KFH_fnc_applyDebugTeammateCombatProfile;
    [_unit] call KFH_fnc_applyPrototypeCarryCapacity;
    [_unit, "Medikit"] call KFH_fnc_addInventoryItem;
    [_unit] call KFH_fnc_applyFriendlyFireMitigation;
    [_unit] call KFH_fnc_updateSavedLoadout;

    private _allies = missionNamespace getVariable ["KFH_scalingTestAllies", []];
    _allies pushBackUnique _unit;
    missionNamespace setVariable ["KFH_scalingTestAllies", _allies, true];
    [format ["Scaling test ally %1 joined the patrol.", _name]] call KFH_fnc_log;

    _unit
};

KFH_fnc_forceInitialStarterLoadout = {
    params ["_unit"];

    if (isNull _unit) exitWith {};
    if !((vehicle _unit) isEqualTo _unit) exitWith {};

    [_unit] call KFH_fnc_applyStarterLoadout;

    [_unit] spawn {
        params ["_trackedUnit"];
        private _deadline = time + KFH_starterEnforceWindow;

        while {time <= _deadline} do {
            sleep KFH_starterRecheckDelay;

            if (isNull _trackedUnit) exitWith {};
            if !(alive _trackedUnit) exitWith {};

            if ((primaryWeapon _trackedUnit) isEqualTo "" && {!((handgunWeapon _trackedUnit) isEqualTo "")}) exitWith {
                [_trackedUnit] call KFH_fnc_updateSavedLoadout;
                ["Starter loadout lock-in confirmed."] call KFH_fnc_log;
            };

            [_trackedUnit] call KFH_fnc_applyStarterLoadout;
            ["Starter loadout reapplied after override."] call KFH_fnc_log;
        };
    };
};

KFH_fnc_retireDebugTeammateIfUnneeded = {
    params [["_reason", "human backup joined"]];

    private _current = missionNamespace getVariable ["KFH_debugTeammate", objNull];
    if (isNull _current) exitWith { false };
    if !(alive _current) exitWith {
        missionNamespace setVariable ["KFH_debugTeammate", objNull, true];
        true
    };
    if (_current getVariable ["KFH_aiReviveBusy", false]) exitWith { false };
    if ((count ([] call KFH_fnc_getIncapacitatedPlayers)) > 0) exitWith { false };

    private _groupRef = group _current;
    [format ["Wingman %1 retired: %2.", name _current, _reason]] call KFH_fnc_log;
    deleteVehicle _current;
    missionNamespace setVariable ["KFH_debugTeammate", objNull, true];
    if (!isNull _groupRef && {({alive _x} count units _groupRef) isEqualTo 0}) then {
        deleteGroup _groupRef;
    };

    true
};

KFH_fnc_debugTeammateLoop = {
    missionNamespace setVariable ["KFH_nextDebugTeammateSpawnAt", 0];

    while { true } do {
        private _phase = missionNamespace getVariable ["KFH_phase", "boot"];

        if (_phase in ["complete", "failed"]) exitWith {};

        if (KFH_debugTeammateEnabled) then {
            private _players = [] call KFH_fnc_getHumanPlayers;
            private _combatReadyHumans = [] call KFH_fnc_getCombatReadyHumans;
            private _downedHumans = [] call KFH_fnc_getIncapacitatedPlayers;

            if ((count _players) > KFH_debugTeammateHumanThreshold) then {
                ["human player count above solo threshold"] call KFH_fnc_retireDebugTeammateIfUnneeded;
            };

            if (
                !(missionNamespace getVariable ["KFH_wipeLocked", false]) &&
                ((count _players) > 0) &&
                {(count _players) <= KFH_debugTeammateHumanThreshold} &&
                {((count _combatReadyHumans) > 0) || {(count _downedHumans) > 0}}
            ) then {
                private _leader = _players select 0;
                private _current = missionNamespace getVariable ["KFH_debugTeammate", objNull];

                if (isNull _current || {!alive _current}) then {
                    if ((count _downedHumans) > 0) then {
                        private _rescueDelay = missionNamespace getVariable ["KFH_debugTeammateRescueRespawnDelay", 3];
                        private _nextSpawnAt = missionNamespace getVariable ["KFH_nextDebugTeammateSpawnAt", 0];
                        missionNamespace setVariable ["KFH_nextDebugTeammateSpawnAt", _nextSpawnAt min (time + _rescueDelay)];
                    };
                    if (time >= (missionNamespace getVariable ["KFH_nextDebugTeammateSpawnAt", 0])) then {
                        [_leader] call KFH_fnc_spawnDebugTeammate;
                        missionNamespace setVariable ["KFH_nextDebugTeammateSpawnAt", time + KFH_debugTeammateRespawnDelay];
                    };
                } else {
                    _current setVariable ["KFH_debugTeammate", true, true];
                    _current setVariable ["KFH_soloWingman", true, true];
                    _current setVariable ["KFH_canRevivePlayers", true, true];
                    if !([_current] call KFH_fnc_isIncapacitated) then {
                    missionNamespace setVariable ["KFH_lastAliveDebugTeammateAt", time, true];
                    if ((group _current) != (group _leader)) then {
                        [_current] joinSilent (group _leader);
                    };
                    if (KFH_debugTeammatePassiveCombat) then {
                        _current disableAI "TARGET";
                        _current disableAI "AUTOTARGET";
                        _current setCombatMode "BLUE";
                    } else {
                        if (time >= (_current getVariable ["KFH_nextCombatProfileRefreshAt", 0])) then {
                            [_current] call KFH_fnc_applyDebugTeammateCombatProfile;
                            _current setVariable [
                                "KFH_nextCombatProfileRefreshAt",
                                time + (missionNamespace getVariable ["KFH_debugTeammateCombatProfileRefreshSeconds", 25])
                            ];
                        };

                        if !(_current getVariable ["KFH_aiReviveBusy", false]) then {
                            private _nearEnemies = ([] call KFH_fnc_pruneActiveEnemies) select {
                                alive _x && {(_x distance2D _current) <= KFH_debugTeammateEngageRadius}
                            };
                            if ((count _nearEnemies) > 0) then {
                                private _target = [_nearEnemies, [], {_x distance2D _current}, "ASCEND"] call BIS_fnc_sortBy;
                                _target = _target select 0;
                                _current reveal [_target, 4];
                                _current doTarget _target;
                                _current doFire _target;
                            };
                        };
                    };

                    if (
                        (missionNamespace getVariable ["KFH_debugTeammateMirrorPlayerLoadout", true]) &&
                        {!(_current getVariable ["KFH_aiReviveBusy", false])} &&
                        {!([_leader] call KFH_fnc_isIncapacitated)} &&
                        {time >= (_current getVariable ["KFH_nextLoadoutMirrorAt", 0])}
                    ) then {
                        private _leaderLoadout = getUnitLoadout _leader;
                        if ((count _leaderLoadout) > 0) then {
                            _current setUnitLoadout _leaderLoadout;
                            [_current] call KFH_fnc_applyPrototypeCarryCapacity;
                            [_current, "Medikit"] call KFH_fnc_addInventoryItem;
                            [_current] call KFH_fnc_updateSavedLoadout;
                        };
                        _current setVariable [
                            "KFH_nextLoadoutMirrorAt",
                            time + (missionNamespace getVariable ["KFH_debugTeammateMirrorInterval", 18])
                        ];
                    };

                    private _distanceToLeader = _current distance2D _leader;
                    if (_distanceToLeader > (missionNamespace getVariable ["KFH_debugTeammateFollowCommandDistance", 35])) then {
                        _current doFollow _leader;
                        _current doMove (getPosATL _leader);
                    };
                    if (_distanceToLeader > (missionNamespace getVariable ["KFH_debugTeammateFollowTeleportDistance", 160])) then {
                        _current setPosATL (_leader modelToWorld [1.2, -1.4, 0]);
                    };
                    };
                };
            };
        };

        sleep 5;
    };
};

KFH_fnc_pickClosestIncapacitatedAlly = {
    params ["_unit"];

    if (isNull _unit) exitWith { objNull };
    private _busyTimeout = missionNamespace getVariable ["KFH_aiReviveTargetBusyTimeout", 8];

    private _targets = (([] call KFH_fnc_getHumanPlayers) + (units group _unit)) arrayIntersect (([] call KFH_fnc_getHumanPlayers) + (units group _unit));
    _targets = _targets select {
        private _busy = _x getVariable ["KFH_aiReviveTargetBusy", false];
        private _busyMedic = _x getVariable ["KFH_aiReviveTargetMedic", objNull];
        private _busyAt = _x getVariable ["KFH_aiReviveTargetBusyAt", -1];
        private _staleBusy = _busy && {
            isNull _busyMedic ||
            {!alive _busyMedic} ||
            {!(_busyMedic getVariable ["KFH_aiReviveBusy", false]) && {_busyAt >= 0} && {(time - _busyAt) > _busyTimeout}}
        };
        if (_staleBusy) then {
            _x setVariable ["KFH_aiReviveTargetBusy", false, true];
            _x setVariable ["KFH_aiReviveTargetMedic", objNull, true];
            _x setVariable ["KFH_aiReviveTargetBusyAt", -1, true];
            _busy = false;
        };
        _x != _unit &&
        alive _x &&
        {!_busy} &&
        {time >= (_x getVariable ["KFH_aiReviveReadyAt", 0])} &&
        [_x] call KFH_fnc_isIncapacitated
    };

    if ((count _targets) isEqualTo 0) exitWith { objNull };

    private _closest = objNull;
    private _closestDistance = 1e10;

    {
        private _distance = _unit distance2D _x;
        if (_distance < _closestDistance) then {
            _closest = _x;
            _closestDistance = _distance;
        };
    } forEach _targets;

    _closest
};

KFH_fnc_runDebugTeammateRevive = {
    params ["_medic", "_casualty"];

    if (isNull _medic || {isNull _casualty}) exitWith {};
    if (!local _medic) exitWith {
        _casualty setVariable ["KFH_aiReviveTargetBusy", false, true];
        _casualty setVariable ["KFH_aiReviveTargetMedic", objNull, true];
        _casualty setVariable ["KFH_aiReviveTargetBusyAt", -1, true];
    };
    if !([_casualty] call KFH_fnc_isIncapacitated) exitWith {
        _casualty setVariable ["KFH_aiReviveTargetBusy", false, true];
        _casualty setVariable ["KFH_aiReviveTargetMedic", objNull, true];
        _casualty setVariable ["KFH_aiReviveTargetBusyAt", -1, true];
    };

    _medic setVariable ["KFH_aiReviveBusy", true, true];
    _casualty setVariable ["KFH_aiReviveTargetBusy", true, true];
    _casualty setVariable ["KFH_aiReviveTargetMedic", _medic, true];
    _casualty setVariable ["KFH_aiReviveTargetBusyAt", time, true];
    _medic disableAI "AUTOCOMBAT";
    _medic disableAI "TARGET";
    _medic disableAI "AUTOTARGET";
    _medic doMove (getPosATL _casualty);
    [format ["%1 moving to revive %2.", name _medic, name _casualty]] call KFH_fnc_log;

    private _rescueStartAt = time;
    private _didTeleport = false;
    private _timeoutAt = time + KFH_debugTeammateReviveTimeout;
    waitUntil {
        sleep 0.25;

        if (
            !_didTeleport &&
            {!(isNull _medic)} &&
            {!(isNull _casualty)} &&
            {alive _medic} &&
            {alive _casualty} &&
            {[_casualty] call KFH_fnc_isIncapacitated} &&
            {missionNamespace getVariable ["KFH_debugTeammateRescueTeleportEnabled", true]} &&
            {time >= (_rescueStartAt + KFH_debugTeammateRescueTeleportDelay)} &&
            {(_medic distance2D _casualty) > (KFH_debugTeammateReviveRange + 1.2)}
        ) then {
            _medic setPosATL (_casualty modelToWorld [1.1, -0.9, 0]);
            _didTeleport = true;
        };

        isNull _medic ||
        {isNull _casualty} ||
        {!alive _medic} ||
        {!alive _casualty} ||
        {!([_casualty] call KFH_fnc_isIncapacitated)} ||
        {(_medic distance2D _casualty) <= KFH_debugTeammateReviveRange} ||
        {time >= _timeoutAt}
    };

    if (
        !isNull _medic &&
        !isNull _casualty &&
        {alive _medic} &&
        {alive _casualty} &&
        {[_casualty] call KFH_fnc_isIncapacitated}
    ) then {
        if (
            ((vehicle _casualty) isNotEqualTo _casualty) &&
            {!(missionNamespace getVariable ["KFH_debugTeammateAutoPullVehicleCasualties", false])}
        ) exitWith {
            _medic allowDamage true;
            _medic enableAI "AUTOCOMBAT";
            _medic enableAI "TARGET";
            _medic enableAI "AUTOTARGET";
            _medic setVariable ["KFH_aiReviveBusy", false, true];
            _casualty setVariable ["KFH_aiReviveTargetBusy", false, true];
            _casualty setVariable ["KFH_aiReviveTargetMedic", objNull, true];
            _casualty setVariable ["KFH_aiReviveTargetBusyAt", -1, true];
            _medic doMove (getPosATL (vehicle _casualty));
            [format ["%1 revive paused for %2 inside vehicle; waiting for manual Pull injured.", name _medic, name _casualty]] call KFH_fnc_log;
        };
        if (
            (missionNamespace getVariable ["KFH_debugTeammateRescueTeleportEnabled", true]) &&
            {(_medic distance2D _casualty) > KFH_debugTeammateReviveRange}
        ) then {
            _medic setPosATL (_casualty modelToWorld [1.1, -1.0, 0]);
        };

        if ((vehicle _casualty) isNotEqualTo _casualty) then {
            [_casualty, _medic, "Echo pull before revive"] call KFH_fnc_extractCasualtyFromVehicle;
            sleep 0.35;
            _medic doMove (getPosATL _casualty);
            if (
                (missionNamespace getVariable ["KFH_debugTeammateRescueTeleportEnabled", true]) &&
                {(_medic distance2D _casualty) > KFH_debugTeammateReviveRange}
            ) then {
                _medic setPosATL (_casualty modelToWorld [1.1, -1.0, 0]);
            };
        };
        _medic doWatch _casualty;
        _medic playActionNow "MedicOther";
        sleep KFH_debugTeammateReviveDuration;

        if (alive _casualty && {[_casualty] call KFH_fnc_isIncapacitated}) then {
            [_casualty] call KFH_fnc_reviveUnitFromDowned;
            ["ai_revived_player", [name _medic, name _casualty]] call KFH_fnc_notifyAllKey;
        };
        _medic allowDamage true;
    };

    if (!isNull _medic) then {
        _medic allowDamage true;
        _medic enableAI "AUTOCOMBAT";
        _medic enableAI "TARGET";
        _medic enableAI "AUTOTARGET";
        _medic setVariable ["KFH_aiReviveBusy", false, true];
        if (!KFH_debugTeammatePassiveCombat) then {
            [_medic] call KFH_fnc_applyDebugTeammateCombatProfile;
        };
        _medic doFollow leader (group _medic);
    };
    if (!isNull _casualty) then {
        _casualty setVariable ["KFH_aiReviveTargetBusy", false, true];
        _casualty setVariable ["KFH_aiReviveTargetMedic", objNull, true];
        _casualty setVariable ["KFH_aiReviveTargetBusyAt", -1, true];
    };
};

KFH_fnc_scalingTestAllyLoop = {
    missionNamespace setVariable ["KFH_nextScalingTestAllySpawnAt", 0];

    while { true } do {
        private _phase = missionNamespace getVariable ["KFH_phase", "boot"];
        if (_phase in ["complete", "failed"]) exitWith {};

        private _count = missionNamespace getVariable ["KFH_scalingTestAllyCount", 0];
        if (_count > 0) then {
            private _players = [] call KFH_fnc_getHumanPlayers;
            private _combatReadyHumans = [] call KFH_fnc_getCombatReadyHumans;
            if (
                !(missionNamespace getVariable ["KFH_wipeLocked", false]) &&
                {(count _players) > 0} &&
                {(count _combatReadyHumans) > 0}
            ) then {
                private _leader = _players select 0;
                private _allies = missionNamespace getVariable ["KFH_scalingTestAllies", []];
                _allies = _allies select { !isNull _x && {alive _x} };
                missionNamespace setVariable ["KFH_scalingTestAllies", _allies, true];

                for "_i" from 0 to ((_count min 9) - 1) do {
                    private _ally = objNull;
                    private _matches = _allies select { (_x getVariable ["KFH_scalingTestAllyIndex", -1]) isEqualTo _i };
                    if ((count _matches) > 0) then {
                        _ally = _matches select 0;
                    };

                    if (isNull _ally || {!alive _ally}) then {
                        [_leader, _i] call KFH_fnc_spawnScalingTestAlly;
                    } else {
                        if ((group _ally) != (group _leader)) then {
                            [_ally] joinSilent (group _leader);
                        };
                        [_ally] call KFH_fnc_applyDebugTeammateCombatProfile;
                        if (
                            !(_ally getVariable ["KFH_aiReviveBusy", false]) &&
                            {!([_leader] call KFH_fnc_isIncapacitated)} &&
                            {time >= (_ally getVariable ["KFH_nextLoadoutMirrorAt", 0])}
                        ) then {
                            private _leaderLoadout = getUnitLoadout _leader;
                            if ((count _leaderLoadout) > 0) then {
                                _ally setUnitLoadout _leaderLoadout;
                                [_ally] call KFH_fnc_applyPrototypeCarryCapacity;
                                [_ally, "Medikit"] call KFH_fnc_addInventoryItem;
                                [_ally] call KFH_fnc_updateSavedLoadout;
                            };
                            _ally setVariable [
                                "KFH_nextLoadoutMirrorAt",
                                time + (missionNamespace getVariable ["KFH_scalingTestAllyMirrorInterval", 18])
                            ];
                        };
                        if ((_ally distance2D _leader) > 70 && {!([_ally] call KFH_fnc_isIncapacitated)}) then {
                            _ally setPosATL (_leader modelToWorld [2 + (_i * 0.8), -2 - (_i * 0.5), 0]);
                        };
                    };
                };
            };
        };

        sleep 2.5;
    };
};

KFH_fnc_debugTeammateReviveLoop = {
    while { true } do {
        private _phase = missionNamespace getVariable ["KFH_phase", "boot"];

        if (_phase in ["complete", "failed"]) exitWith {};

        private _medics = [] call KFH_fnc_getPotentialRescuers;
        {
            private _medic = _x;
            if !(_medic getVariable ["KFH_aiReviveBusy", false]) then {

            private _casualty = [_medic] call KFH_fnc_pickClosestIncapacitatedAlly;

            if !(isNull _casualty) then {
                _casualty setVariable ["KFH_aiReviveTargetBusy", true, true];
                _casualty setVariable ["KFH_aiReviveTargetMedic", _medic, true];
                _casualty setVariable ["KFH_aiReviveTargetBusyAt", time, true];
                if (local _medic) then {
                    [_medic, _casualty] spawn KFH_fnc_runDebugTeammateRevive;
                } else {
                    if (time >= (_medic getVariable ["KFH_aiReviveDispatchAt", 0])) then {
                        _medic setVariable ["KFH_aiReviveDispatchAt", time + 1.5, true];
                        [format [
                            "Dispatching AI revive to owner: medic=%1 casualty=%2 owner=%3.",
                            name _medic,
                            name _casualty,
                            owner _medic
                        ]] call KFH_fnc_log;
                        [_medic, _casualty] remoteExec ["KFH_fnc_runDebugTeammateRevive", owner _medic];
                    } else {
                        _casualty setVariable ["KFH_aiReviveTargetBusy", false, true];
                        _casualty setVariable ["KFH_aiReviveTargetMedic", objNull, true];
                        _casualty setVariable ["KFH_aiReviveTargetBusyAt", -1, true];
                    };
                };
            };
            };
        } forEach _medics;

        sleep 1.2;
    };
};

