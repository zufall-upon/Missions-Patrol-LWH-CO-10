KFH_fnc_configureRangedEnemy = {
    params ["_unit"];

    if (isNull _unit) exitWith {};

    removeAllWeapons _unit;
    removeAllItems _unit;
    removeAllAssignedItems _unit;
    removeHeadgear _unit;
    removeGoggles _unit;
    removeVest _unit;

    private _entry = [] call KFH_fnc_selectRangedEnemyLoadout;
    if ((count _entry) < 2) exitWith {};
    private _weapon = _entry select 0;
    private _mag = _entry select 1;
    private _attachments = if ((count _entry) > 2) then { _entry select 2 } else { [] };
    private _extraMags = if ((count _entry) > 3) then { _entry select 3 } else { 2 };

    _unit addVest "V_BandollierB_khk";
    [_unit, _weapon, _mag, _attachments, _extraMags] call KFH_fnc_givePrimaryWeaponLoadout;
    _unit setSkill (0.38 + random 0.18);
    [_unit] call KFH_fnc_applyEnemyFireAccuracy;
    _unit setVariable ["KFH_enemyRole", "ranged", true];
    _unit setVariable ["KFH_rushGunner", true, true];
    _unit enableFatigue false;
    _unit allowFleeing 0;
    _unit setAnimSpeedCoef 1;
    {
        _unit enableAI _x;
    } forEach ["AUTOCOMBAT", "COVER", "SUPPRESSION", "TARGET", "AUTOTARGET"];
    _unit setBehaviourStrong "AWARE";
    _unit setCombatMode "RED";
    _unit setSpeedMode "FULL";
    _unit setUnitPos "AUTO";
    _unit forceWalk false;
    _unit stop false;
    (group _unit) setFormation "WEDGE";
    (group _unit) setBehaviour "AWARE";
    (group _unit) setCombatMode "RED";
    (group _unit) setSpeedMode "FULL";
};

KFH_fnc_configureAgentEnemy = {
    params ["_unit"];

    if (isNull _unit) exitWith {};

    removeAllWeapons _unit;
    removeAllItems _unit;
    removeAllAssignedItems _unit;
    removeUniform _unit;
    removeVest _unit;
    removeHeadgear _unit;
    removeGoggles _unit;

    private _entry = [] call KFH_fnc_selectRangedEnemyLoadout;
    if ((count _entry) < 2) exitWith {};
    private _weapon = _entry select 0;
    private _mag = _entry select 1;
    private _attachments = if ((count _entry) > 2) then { _entry select 2 } else { [] };
    private _extraMags = if ((count _entry) > 3) then { _entry select 3 } else { 2 };

    _unit forceAddUniform (selectRandom KFH_agentUniforms);
    _unit addVest "V_TacVest_blk";
    _unit addHeadgear (selectRandom KFH_agentHeadgear);
    _unit addGoggles "G_Balaclava_blk";
    [_unit, _weapon, _mag, _attachments, _extraMags] call KFH_fnc_givePrimaryWeaponLoadout;
    _unit setVariable ["KFH_enemyRole", "agent", true];
    _unit setVariable ["KFH_agentEnemy", true, true];
    _unit setSkill (0.46 + random 0.16);
    [_unit] call KFH_fnc_applyEnemyFireAccuracy;
    _unit enableFatigue false;
    _unit allowFleeing 0;
    {
        _unit enableAI _x;
    } forEach ["AUTOCOMBAT", "COVER", "SUPPRESSION", "TARGET", "AUTOTARGET"];
    _unit setBehaviourStrong "AWARE";
    _unit setCombatMode "RED";
    _unit setSpeedMode "FULL";
    _unit setUnitPos "AUTO";
    _unit forceWalk false;
    _unit stop false;
    (group _unit) setFormation "WEDGE";
    (group _unit) setBehaviour "AWARE";
    (group _unit) setCombatMode "RED";
    (group _unit) setSpeedMode "FULL";
    [_unit, KFH_agentLootTable, "agent"] call KFH_fnc_addUnitLootTable;
};

KFH_fnc_configureHeavyInfected = {
    params ["_unit", ["_allowExternalZombie", true]];

    if (isNull _unit) exitWith {};

    [_unit, _allowExternalZombie] call KFH_fnc_configureMeleeEnemy;
    removeUniform _unit;
    removeVest _unit;
    removeHeadgear _unit;
    removeBackpack _unit;
    _unit forceAddUniform (selectRandom KFH_heavyInfectedUniforms);
    _unit addVest (selectRandom KFH_heavyInfectedVests);
    _unit addHeadgear (selectRandom KFH_heavyInfectedHeadgear);
    _unit addBackpack (selectRandom KFH_heavyInfectedBackpacks);
    private _isExternalZombie = (_unit getVariable ["KFH_enemyRole", ""]) isEqualTo "externalZombie";
    if (_isExternalZombie) then {
        _unit setVariable ["KFH_webKnightNativeRole", "heavyInfected", true];
    } else {
        _unit setVariable ["KFH_enemyRole", "heavyInfected", true];
    };
    _unit setVariable ["KFH_heavyInfected", true, true];
    if (!_isExternalZombie) then {
        _unit setAnimSpeedCoef KFH_heavyInfectedAnimSpeed;
    };
    [_unit, KFH_heavyInfectedLootTable, "heavyInfected"] call KFH_fnc_addUnitLootTable;
    if !(_unit getVariable ["KFH_heavyDamageHandlerInstalled", false]) then {
        _unit setVariable ["KFH_heavyDamageHandlerInstalled", true];
        _unit addEventHandler ["HandleDamage", {
            params ["_unit", "_selection", "_incomingDamage", "_source"];

            if !(_unit getVariable ["KFH_heavyInfected", false]) exitWith { _incomingDamage };
            private _scale = _unit getVariable ["KFH_heavyInfectedDamageScale", KFH_heavyInfectedDamageScale];
            _incomingDamage * _scale
        }];
    };
};

KFH_fnc_configureLeaperProxyInfected = {
    params ["_unit"];

    if (isNull _unit) exitWith {};

    [_unit, false] call KFH_fnc_configureHeavyInfected;
    _unit setVariable ["KFH_enemyRole", "leaper", true];
    _unit setVariable ["KFH_leaperProxy", true, true];
    _unit setVariable ["KFH_heavyInfectedDamageScale", missionNamespace getVariable ["KFH_leaperProxyDamageScale", 1.1], true];
    _unit enableFatigue false;
    _unit setAnimSpeedCoef (missionNamespace getVariable ["KFH_leaperProxyAnimSpeed", 1.12]);
    _unit setVariable ["KFH_nextLeaperPounceAt", time + 0.8 + random 1.2];
    _unit setSkill 0.7;
    _unit allowFleeing 0;
    {
        _unit disableAI _x;
    } forEach ["AUTOCOMBAT", "COVER", "SUPPRESSION"];
    {
        _unit enableAI _x;
    } forEach ["MOVE", "PATH", "TARGET", "AUTOTARGET", "FSM"];
    _unit setBehaviourStrong "COMBAT";
    _unit setCombatMode "RED";
    _unit setSpeedMode "FULL";
    if (missionNamespace getVariable ["KFH_leaperProxyCrawlEnabled", true]) then {
        _unit setUnitPos (missionNamespace getVariable ["KFH_leaperProxyUnitPos", "MIDDLE"]);
    } else {
        _unit setUnitPos "UP";
    };
    _unit forceWalk false;
    (group _unit) allowFleeing 0;
    (group _unit) setBehaviour "COMBAT";
    (group _unit) setCombatMode "RED";
    (group _unit) setSpeedMode "FULL";
    [format ["Leaper proxy configured with KFH melee chase AI at %1.", mapGridPosition _unit]] call KFH_fnc_log;
};

KFH_fnc_configureJuggernautInfected = {
    params ["_unit"];

    if (isNull _unit) exitWith {};

    [_unit] call KFH_fnc_configureHeavyInfected;
    _unit setVariable ["KFH_juggernaut", true, true];
    _unit setVariable ["KFH_heavyInfectedDamageScale", KFH_juggernautDamageScale, true];
    _unit setAnimSpeedCoef KFH_juggernautAnimSpeed;
    _unit setSkill 0.75;
    _unit allowFleeing 0;
    [_unit, KFH_heavyInfectedLootTable + [["RPG32_F", 0, 1, 0.35], ["NLAW_F", 0, 1, 0.25]], "juggernaut"] call KFH_fnc_addUnitLootTable;
    [format ["Juggernaut infected configured at %1.", mapGridPosition _unit]] call KFH_fnc_log;
};

KFH_fnc_selectExistingClass = {
    params [["_classes", []], ["_fallbackClass", ""]];

    private _pool = _classes select { isClass (configFile >> "CfgVehicles" >> _x) };
    if ((count _pool) > 0) exitWith { selectRandom _pool };
    _fallbackClass
};

KFH_fnc_findRelaxedSpecialSpawnPosition = {
    params ["_centerPos", ["_minDistance", 28], ["_maxDistance", 70]];

    private _attempts = 18;
    private _found = [];
    for "_i" from 1 to _attempts do {
        private _angle = random 360;
        private _dist = _minDistance + random ((_maxDistance - _minDistance) max 1);
        private _pos = [
            (_centerPos select 0) + (sin _angle) * _dist,
            (_centerPos select 1) + (cos _angle) * _dist,
            0
        ];
        if !(surfaceIsWater _pos) then {
            private _empty = _pos findEmptyPosition [0, 12, "C_man_1"];
            if !(_empty isEqualTo []) then {
                if (count (_empty isFlatEmpty [0.6, -1, 0.35, 2, 0, false, objNull]) > 0) exitWith {
                    _found = _empty;
                };
            };
        };
    };

    _found
};

KFH_fnc_selectCheckpointSpecialRole = {
    params [["_checkpointIndex", 1]];

    private _entries = missionNamespace getVariable ["KFH_checkpointSpecialRoles", []];
    private _checkpointCount = missionNamespace getVariable ["KFH_checkpointCount", KFH_checkpointCount];
    private _startProgress = missionNamespace getVariable ["KFH_checkpointJuggernautStartProgress", 0.85];
    private _startCheckpoint = ceil ((_checkpointCount max 1) * _startProgress);
    _startCheckpoint = (_startCheckpoint max 1) min (_checkpointCount max 1);
    private _allowJuggernaut =
        (_checkpointIndex >= _startCheckpoint) &&
        {(random 1) <= (missionNamespace getVariable ["KFH_checkpointJuggernautChance", 0.05])};

    if !(_allowJuggernaut) then {
        _entries = _entries select {
            !((_x param [0, ""]) in ["goliath", "smasher"])
        };
    };

    [_entries] call KFH_fnc_selectSpecialRoleFromEntries
};

KFH_fnc_isKnownBrokenSpecialClass = {
    params [["_className", ""]];

    !(_className isEqualTo "") &&
    {_className in (missionNamespace getVariable ["KFH_knownBrokenSpecialClasses", []])}
};

KFH_fnc_isBannedSpecialClass = {
    params [["_className", ""]];

    private _lowerName = toLower _className;
    ((missionNamespace getVariable ["KFH_bannedSpecialClassSubstrings", []]) findIf {
        (_lowerName find (toLower _x)) >= 0
    }) >= 0
};

KFH_fnc_selectSpecialRoleFromEntries = {
    params [["_entries", []]];

    if ((count _entries) isEqualTo 0) exitWith { ["screamer", missionNamespace getVariable ["KFH_branchRewardScreamerClass", ""]] };

    private _weighted = [];
    {
        _x params ["_role", ["_classes", []], ["_weight", 1]];
        private _filteredClasses = if (_role isEqualTo "leaper" && {missionNamespace getVariable ["KFH_leaperProxyEnabled", true]}) then {
            [""]
        } else {
            _classes select {
                !([_x] call KFH_fnc_isKnownBrokenSpecialClass) &&
                {!([_x] call KFH_fnc_isBannedSpecialClass)}
            }
        };
        private _allowFallbackClass = (_filteredClasses findIf { _x isEqualTo "" }) >= 0;
        private _className = [_filteredClasses, if ((count _filteredClasses) > 0) then { _filteredClasses select 0 } else { "" }] call KFH_fnc_selectExistingClass;
        if (_allowFallbackClass && {_className isEqualTo ""}) then {
            _className = "";
        };
        if (_allowFallbackClass || {!(_className isEqualTo "")}) then {
            for "_i" from 1 to (_weight max 1) do {
                _weighted pushBack [_role, _className];
            };
        };
    } forEach _entries;

    if ((count _weighted) isEqualTo 0) exitWith {
        private _bloaterClass = [["Zombie_Special_OPFOR_Boomer"], ""] call KFH_fnc_selectExistingClass;
        if !(_bloaterClass isEqualTo "") exitWith { ["bloater", _bloaterClass] };
        ["screamer", missionNamespace getVariable ["KFH_branchRewardScreamerClass", ""]]
    };
    selectRandom _weighted
};

KFH_fnc_configureSpecialJuggernautInfected = {
    params ["_unit"];

    if (isNull _unit) exitWith {};
    _unit setVariable ["KFH_juggernaut", true, true];
    _unit setVariable ["KFH_heavyInfected", true, true];
    _unit setVariable ["KFH_heavyInfectedDamageScale", KFH_juggernautDamageScale, true];
    _unit setAnimSpeedCoef KFH_juggernautAnimSpeed;
    _unit setSkill 0.75;
    _unit allowFleeing 0;
    if !(_unit getVariable ["KFH_heavyDamageHandlerInstalled", false]) then {
        _unit setVariable ["KFH_heavyDamageHandlerInstalled", true];
        _unit addEventHandler ["HandleDamage", {
            params ["_unit", "_selection", "_incomingDamage", "_source"];

            if !(_unit getVariable ["KFH_heavyInfected", false]) exitWith { _incomingDamage };
            private _scale = _unit getVariable ["KFH_heavyInfectedDamageScale", KFH_heavyInfectedDamageScale];
            _incomingDamage * _scale
        }];
    };
    [format ["Special juggernaut infected configured at %1.", mapGridPosition _unit]] call KFH_fnc_log;
};

KFH_fnc_isJuggernautEnemy = {
    params ["_unit"];

    if (isNull _unit) exitWith { false };
    (_unit getVariable ["KFH_juggernaut", false]) ||
    {(_unit getVariable ["KFH_enemyRole", ""]) in ["goliath", "smasher"]}
};

KFH_fnc_leaveBehindJuggernaut = {
    params ["_unit", ["_reason", "left behind"]];

    if (isNull _unit || {!alive _unit}) exitWith {};
    if (_unit getVariable ["KFH_juggernautLeftBehind", false]) exitWith {};

    _unit setVariable ["KFH_juggernautLeftBehind", true, true];
    _unit setVariable ["KFH_staleSince", -1];
    _unit setVariable ["KFH_staleRemoved", true, true];

    private _objectiveEnemies = missionNamespace getVariable ["KFH_currentObjectiveEnemies", []];
    _objectiveEnemies = _objectiveEnemies - [_unit];
    missionNamespace setVariable ["KFH_currentObjectiveEnemies", _objectiveEnemies];

    private _activeEnemies = missionNamespace getVariable ["KFH_activeEnemies", []];
    _activeEnemies = _activeEnemies - [_unit];
    missionNamespace setVariable ["KFH_activeEnemies", _activeEnemies];

    ["KFH_objectiveHostiles", count _objectiveEnemies] call KFH_fnc_setState;
    ["KFH_totalHostiles", count _activeEnemies] call KFH_fnc_setState;
    [format ["Juggernaut left behind without relocation: %1 at %2 (%3).", typeOf _unit, mapGridPosition _unit, _reason]] call KFH_fnc_log;
};

KFH_fnc_addRushDebt = {
    params [["_count", 0], ["_reason", "left behind"]];

    if !(missionNamespace getVariable ["KFH_rushDebtEnabled", true]) exitWith { 0 };
    _count = floor (_count max 0);
    if (_count <= 0) exitWith { missionNamespace getVariable ["KFH_rushDebtCount", 0] };

    private _debt = missionNamespace getVariable ["KFH_rushDebtCount", 0];
    private _maxDebt = missionNamespace getVariable ["KFH_rushDebtMax", 24];
    private _newDebt = (_debt + _count) min _maxDebt;
    missionNamespace setVariable ["KFH_rushDebtCount", _newDebt, true];
    [format ["Rush debt accrued: +%1 (%2), total=%3/%4.", _count, _reason, _newDebt, _maxDebt]] call KFH_fnc_log;
    _newDebt
};

KFH_fnc_applyBloaterBlastDamageLocal = {
    params ["_unit", ["_source", objNull], ["_incomingDamage", 0], ["_reason", "bloater blast"]];

    if (isNull _unit) exitWith {};
    if !(alive _unit) exitWith {};
    if !(local _unit) exitWith {};
    if (_unit getVariable ["KFH_forcedDowned", false]) exitWith {};

    private _safeDamage = missionNamespace getVariable ["KFH_forcedDownedDamage", 0.42];
    private _protectedUntil = _unit getVariable ["KFH_postReviveProtectedUntil", -1];
    if (_protectedUntil > time) exitWith {
        _unit setDamage ((damage _unit) min _safeDamage);
    };

    private _damageScale = if (isPlayer _unit) then {
        missionNamespace getVariable ["KFH_playerDamageTakenScale", 1]
    } else {
        1
    };
    private _damage = ((_incomingDamage max 0) * _damageScale) min 1;
    private _currentDamage = damage _unit;
    private _nextDamage = (_currentDamage + _damage) min 1;
    private _damageThreshold = missionNamespace getVariable ["KFH_downedInterceptDamageThreshold", 0.72];
    private _totalDamageThreshold = missionNamespace getVariable ["KFH_downedInterceptTotalDamageThreshold", 0.82];

    if (
        ((_damage >= _damageThreshold) || {_nextDamage >= _totalDamageThreshold}) &&
        {[_unit] call KFH_fnc_hasRescueCoverageFor}
    ) exitWith {
        [_unit, _source, _reason] call KFH_fnc_forceUnitDowned;
    };

    _unit setDamage _nextDamage;
};

KFH_fnc_applyBloaterBlastDamageBridge = {
    params ["_bloater", ["_blastPos", []]];

    if (!isServer) exitWith {};
    if !(missionNamespace getVariable ["KFH_bloaterBlastDamageBridgeEnabled", true]) exitWith {};
    if (_blastPos isEqualTo []) exitWith {};
    if (!isNull _bloater && {_bloater getVariable ["KFH_bloaterBlastDamageHandled", false]}) exitWith {};

    if (!isNull _bloater) then {
        _bloater setVariable ["KFH_bloaterBlastDamageHandled", true, true];
    };

    private _unitRadius = missionNamespace getVariable ["KFH_bloaterBlastDamageRadius", 9];
    private _vehicleRadius = missionNamespace getVariable ["KFH_bloaterBlastVehicleCrewRadius", 14];
    private _unitDamageMax = missionNamespace getVariable ["KFH_bloaterBlastDamageMax", 0.88];
    private _vehicleDamageMax = missionNamespace getVariable ["KFH_bloaterBlastVehicleCrewDamageMax", 0.96];
    private _damageMin = missionNamespace getVariable ["KFH_bloaterBlastDamageMin", 0.25];
    private _targets = [];

    {
        private _unit = _x;
        private _vehicle = vehicle _unit;
        private _unitDistance = _unit distance2D _blastPos;
        private _vehicleDistance = if (_vehicle isEqualTo _unit) then { 1000000 } else { _vehicle distance2D _blastPos };
        private _radius = _unitRadius;
        private _distance = _unitDistance;
        private _damageMax = _unitDamageMax;

        if (_vehicleDistance <= _vehicleRadius && {_vehicleDistance < _unitDistance}) then {
            _radius = _vehicleRadius;
            _distance = _vehicleDistance;
            _damageMax = _vehicleDamageMax;
        };

        if (_distance <= _radius) then {
            private _falloff = 1 - ((_distance max 0) / (_radius max 1));
            private _damage = _damageMin + ((_damageMax - _damageMin) * (_falloff max 0));
            _targets pushBackUnique [_unit, (_damage min _damageMax), _distance, _radius];
        };
    } forEach ([] call KFH_fnc_getAliveMonitoredFriendlies);

    private _affected = [];
    {
        _x params ["_unit", "_damage", "_distance", "_radius"];
        if (!([_unit] call KFH_fnc_isIncapacitated)) then {
            private _source = if (isNull _bloater) then { objNull } else { _bloater };
            if (local _unit) then {
                [_unit, _source, _damage, "bloater blast"] call KFH_fnc_applyBloaterBlastDamageLocal;
            } else {
                [_unit, _source, _damage, "bloater blast"] remoteExecCall ["KFH_fnc_applyBloaterBlastDamageLocal", _unit];
            };
            _affected pushBack (format ["%1 damage=%2 distance=%3/%4", name _unit, (_damage toFixed 2), (_distance toFixed 1), _radius]);
        };
    } forEach _targets;

    if ((count _affected) > 0) then {
        [format [
            "Bloater blast damage bridge applied at %1 affected=%2 unitRadius=%3 vehicleRadius=%4.",
            mapGridPosition _blastPos,
            _affected,
            _unitRadius,
            _vehicleRadius
        ]] call KFH_fnc_log;
    };
};

KFH_fnc_installBloaterBlastDamageBridge = {
    params ["_unit"];

    if (!isServer) exitWith {};
    if (isNull _unit) exitWith {};
    if ((_unit getVariable ["KFH_enemyRole", ""]) isNotEqualTo "bloater") exitWith {};
    if (_unit getVariable ["KFH_bloaterBlastDamageBridgeInstalled", false]) exitWith {};

    _unit setVariable ["KFH_bloaterBlastDamageBridgeInstalled", true, true];
    _unit addEventHandler ["Killed", {
        params ["_unit"];
        [_unit, getPosATL _unit] call KFH_fnc_applyBloaterBlastDamageBridge;
    }];

    [_unit] spawn {
        params ["_unit"];

        private _lastPos = getPosATL _unit;
        private _interval = missionNamespace getVariable ["KFH_bloaterBlastWatchInterval", 0.15];
        waitUntil {
            sleep _interval;
            if (!isNull _unit) then {
                _lastPos = getPosATL _unit;
            };
            (isNull _unit) ||
            {!alive _unit} ||
            {_unit getVariable ["KFH_bloaterBlastDamageHandled", false]}
        };

        if (!(_unit getVariable ["KFH_bloaterBlastDamageHandled", false])) then {
            [_unit, _lastPos] call KFH_fnc_applyBloaterBlastDamageBridge;
        };
    };
};

KFH_fnc_spawnSpecialInfected = {
    params [
        "_centerPos",
        "_className",
        ["_role", "special"],
        ["_minDistance", 28],
        ["_maxDistance", 70],
        ["_moveTarget", []],
        ["_ignoreActiveBudget", false],
        ["_relaxedSpawn", false],
        ["_addToObjective", false],
        ["_webKnightReplacementAttempt", 0]
    ];

    if (!_ignoreActiveBudget && {([1] call KFH_fnc_limitSpawnCountByActiveBudget) <= 0}) exitWith { objNull };

    private _enemyClasses = missionNamespace getVariable ["KFH_enemyClasses", KFH_enemyClasses];
    if ((count _enemyClasses) isEqualTo 0) exitWith { objNull };

    private _isLeaperProxy = (
        (_role isEqualTo "leaper") ||
        {((toLower _className) find "leaper") >= 0}
    ) && {missionNamespace getVariable ["KFH_leaperProxyEnabled", true]};
    private _useSpecialClass = !_isLeaperProxy && {isClass (configFile >> "CfgVehicles" >> _className)};
    private _spawnClass = if (_useSpecialClass) then { _className } else { selectRandom _enemyClasses };
    private _spawnPos = [_centerPos, _minDistance, _maxDistance] call KFH_fnc_findSafeDistantSpawnPosition;
    if (_relaxedSpawn && {(_spawnPos isEqualTo []) || {!([_spawnPos, objNull] call KFH_fnc_isSpawnCandidateOpen)}}) then {
        _spawnPos = [_centerPos, _minDistance, _maxDistance] call KFH_fnc_findRelaxedSpecialSpawnPosition;
    };

    if (
        (_spawnPos isEqualTo []) ||
        {!([_spawnPos, objNull] call KFH_fnc_isSpawnCandidateOpen)}
    ) exitWith {
        [format ["Skipped %1 special spawn near %2; no safe position.", _role, mapGridPosition _centerPos]] call KFH_fnc_log;
        objNull
    };

    private _groupRef = createGroup [east, true];
    _groupRef setFormation "FILE";
    _groupRef allowFleeing 0;
    _groupRef setBehaviourStrong "COMBAT";
    _groupRef setCombatMode "YELLOW";
    _groupRef setSpeedMode "FULL";

    private _unit = _groupRef createUnit [_spawnClass, _spawnPos, [], 0, "FORM"];
    _unit setDir ([_unit, _centerPos] call BIS_fnc_dirTo);
    _unit allowFleeing 0;
    _unit setSkill (0.56 + random 0.2);
    _unit setVariable ["KFH_enemyRole", _role, true];
    _unit setVariable ["KFH_specialInfected", true, true];
    _unit setVariable ["KFH_specialClassRequested", _className, true];
    _unit setVariable ["KFH_webKnightReplacementAttempt", _webKnightReplacementAttempt, true];
    if (_role isEqualTo "bloater") then {
        [_unit] call KFH_fnc_installBloaterBlastDamageBridge;
    };
    _groupRef selectLeader _unit;

    if (_useSpecialClass) then {
        _unit setVariable ["KFH_enemyRole", "externalZombie", true];
        _unit setVariable ["KFH_webKnightNativeRole", _role, true];
        _unit setVariable ["KFH_externalZombieInitPending", true, true];
        private _webKnightKnownPos = if ((count _moveTarget) >= 2) then { _moveTarget } else { _centerPos };
        [_unit, _role, _webKnightKnownPos] call KFH_fnc_tryStartWebKnightNativeSpecialAI;
        [format ["Special infected handed to WebKnight AI: role=%1 class=%2 grid=%3.", _role, _spawnClass, mapGridPosition _unit]] call KFH_fnc_log;
    } else {
        if (_isLeaperProxy) then {
            [_unit] call KFH_fnc_configureLeaperProxyInfected;
        } else {
            [_unit, true] call KFH_fnc_configureMeleeEnemy;
        };
        if (_role in ["goliath", "smasher"]) then {
            [_unit] call KFH_fnc_configureJuggernautInfected;
        };
        if (_isLeaperProxy) then {
            [format ["Leaper special uses heavy infected body proxy class=%1.", _spawnClass]] call KFH_fnc_log;
        } else {
            [format ["Special class %1 missing; spawned fallback melee for role=%2.", _className, _role]] call KFH_fnc_log;
        };
    };

    if ((_unit getVariable ["KFH_enemyRole", ""]) isEqualTo "externalZombie") then {
        private _webKnightKnownPos = if ((count _moveTarget) >= 2) then { _moveTarget } else { _centerPos };
        _unit setVariable ["WBK_AI_LastKnownLoc", _webKnightKnownPos, true];
    } else {
        if ((count _moveTarget) >= 2) then {
            _groupRef move _moveTarget;
            _unit doMove _moveTarget;
        } else {
            _groupRef move _centerPos;
            _unit doMove _centerPos;
        };
    };

    private _activeEnemies = missionNamespace getVariable ["KFH_activeEnemies", []];
    _activeEnemies pushBack _unit;
    missionNamespace setVariable ["KFH_activeEnemies", _activeEnemies];
    ["KFH_totalHostiles", count _activeEnemies] call KFH_fnc_setState;
    if (_addToObjective) then {
        private _objectiveEnemies = missionNamespace getVariable ["KFH_currentObjectiveEnemies", []];
        _objectiveEnemies pushBack _unit;
        missionNamespace setVariable ["KFH_currentObjectiveEnemies", _objectiveEnemies];
        ["KFH_objectiveHostiles", count _objectiveEnemies] call KFH_fnc_setState;
    };

    [format [
        "Special infected spawned: role=%1 class=%2 grid=%3.",
        _role,
        _spawnClass,
        mapGridPosition _unit
    ]] call KFH_fnc_log;

    _unit
};

KFH_fnc_spawnCheckpointSpecialInfected = {
    params ["_checkpointIndex", "_checkpointMarker", ["_isRushWave", false]];

    if !(missionNamespace getVariable ["KFH_checkpointSpecialEnabled", true]) exitWith { objNull };
    if (_checkpointIndex < (missionNamespace getVariable ["KFH_checkpointSpecialStartCheckpoint", 2])) exitWith { objNull };

    private _threatScale = [] call KFH_fnc_getThreatScale;
    private _activeSpecials = ({alive _x && {_x getVariable ["KFH_specialInfected", false]}} count (missionNamespace getVariable ["KFH_activeEnemies", []]));
    if (_activeSpecials >= ceil ((missionNamespace getVariable ["KFH_checkpointSpecialMaxActive", 4]) * _threatScale)) exitWith { objNull };

    private _chance = (missionNamespace getVariable ["KFH_checkpointSpecialChance", 0.35]) * _threatScale;
    if (_isRushWave) then {
        _chance = _chance + (missionNamespace getVariable ["KFH_checkpointSpecialRushChanceBonus", 0.2]);
    };
    if ((random 1) > (_chance min 0.98)) exitWith { objNull };

    private _roleClass = [_checkpointIndex] call KFH_fnc_selectCheckpointSpecialRole;
    _roleClass params ["_role", "_className"];
    private _centerPos = getMarkerPos _checkpointMarker;
    private _moveTarget = +_centerPos;
    if (_role isEqualTo "leaper" && {missionNamespace getVariable ["KFH_leaperProxyHumanAnchorEnabled", true]}) then {
        private _anchor = [_centerPos] call KFH_fnc_getNearestHumanReferenceUnit;
        if (!isNull _anchor && {(_anchor distance2D _centerPos) > (missionNamespace getVariable ["KFH_leaperProxyHumanAnchorCheckpointDistance", 260])}) then {
            _centerPos = getPosATL (vehicle _anchor);
            _moveTarget = +_centerPos;
            [format ["Leaper checkpoint special anchored near human at %1 instead of distant CP%2.", mapGridPosition _centerPos, _checkpointIndex]] call KFH_fnc_log;
        };
    };
    private _minDistance = if (_role isEqualTo "screamer") then {
        missionNamespace getVariable ["KFH_screamerSpawnDistanceMin", 150]
    } else {
        if (_role isEqualTo "leaper" && {!(_centerPos isEqualTo (getMarkerPos _checkpointMarker))}) then {
            missionNamespace getVariable ["KFH_leaperProxyHumanAnchorMinDistance", 65]
        } else {
            missionNamespace getVariable ["KFH_checkpointSpecialMinDistance", 42]
        }
    };
    private _maxDistance = if (_role isEqualTo "screamer") then {
        missionNamespace getVariable ["KFH_screamerSpawnDistanceMax", 260]
    } else {
        if (_role isEqualTo "leaper" && {!(_centerPos isEqualTo (getMarkerPos _checkpointMarker))}) then {
            missionNamespace getVariable ["KFH_leaperProxyHumanAnchorMaxDistance", 135]
        } else {
            missionNamespace getVariable ["KFH_checkpointSpecialMaxDistance", 110]
        }
    };
    [
        _centerPos,
        _className,
        _role,
        _minDistance,
        _maxDistance,
        _moveTarget,
        false,
        true,
        true
    ] call KFH_fnc_spawnSpecialInfected
};

KFH_fnc_getCheckpointSpecialRampFactor = {
    params [["_waveNumber", missionNamespace getVariable ["KFH_currentWave", 0]]];

    private _cycle = (missionNamespace getVariable ["KFH_checkpointSpecialWaveRampCycle", 10]) max 1;
    ((((_waveNumber max 1) - 1) mod _cycle) + 1) / _cycle
};

KFH_fnc_spawnCheckpointRampSpecialInfected = {
    params ["_checkpointIndex", "_checkpointMarker", "_waveNumber", ["_alreadySpawnedRoles", []]];

    private _maxExtra = missionNamespace getVariable ["KFH_checkpointSpecialRampExtraMax", 1];
    if (_maxExtra <= 0) exitWith { [] };

    private _factor = [_waveNumber] call KFH_fnc_getCheckpointSpecialRampFactor;
    private _chance = (_factor * (missionNamespace getVariable ["KFH_checkpointSpecialRampExtraChanceMax", 0.65])) min 0.95;
    if ((random 1) > _chance) exitWith { [] };

    private _threatScale = [] call KFH_fnc_getThreatScale;
    private _activeSpecials = ({alive _x && {_x getVariable ["KFH_specialInfected", false]}} count (missionNamespace getVariable ["KFH_activeEnemies", []]));
    private _maxActive = ceil ((missionNamespace getVariable ["KFH_checkpointSpecialMaxActive", 4]) * _threatScale);
    if (_activeSpecials >= _maxActive) exitWith { [] };

    private _entries = missionNamespace getVariable ["KFH_checkpointSpecialRampRoles", []];
    _entries = _entries select {
        private _role = _x param [0, ""];
        !(_role in _alreadySpawnedRoles) && {!(_role in ["goliath", "smasher"])}
    };
    if ((count _entries) isEqualTo 0) exitWith { [] };

    private _spawned = [];
    private _attempts = _maxExtra min (_maxActive - _activeSpecials);
    for "_i" from 1 to _attempts do {
        private _roleClass = [_entries] call KFH_fnc_selectSpecialRoleFromEntries;
        _roleClass params ["_role", "_className"];
        private _minDistance = if (_role isEqualTo "screamer") then {
            missionNamespace getVariable ["KFH_screamerSpawnDistanceMin", 150]
        } else {
            missionNamespace getVariable ["KFH_checkpointSpecialMinDistance", 42]
        };
        private _maxDistance = if (_role isEqualTo "screamer") then {
            missionNamespace getVariable ["KFH_screamerSpawnDistanceMax", 260]
        } else {
            missionNamespace getVariable ["KFH_checkpointSpecialMaxDistance", 110]
        };
        private _unit = [
            getMarkerPos _checkpointMarker,
            _className,
            _role,
            _minDistance,
            _maxDistance,
            getMarkerPos _checkpointMarker,
            false,
            true,
            true
        ] call KFH_fnc_spawnSpecialInfected;
        if !(isNull _unit) then {
            _spawned pushBack _unit;
            _alreadySpawnedRoles pushBackUnique _role;
            _entries = _entries select { !((_x param [0, ""]) in _alreadySpawnedRoles) };
        };
    };

    if ((count _spawned) > 0) then {
        [format ["Wave %1 ramp special spawned %2 extra non-juggernaut special(s).", _waveNumber, count _spawned]] call KFH_fnc_log;
    };
    _spawned
};

KFH_fnc_spawnCheckpointBloaterInfected = {
    params ["_checkpointIndex", "_checkpointMarker", ["_alreadySpawnedRole", ""]];

    if !(missionNamespace getVariable ["KFH_checkpointBloaterPerWaveEnabled", true]) exitWith { objNull };
    if (_alreadySpawnedRole isEqualTo "bloater") exitWith { objNull };
    if (_checkpointIndex < (missionNamespace getVariable ["KFH_checkpointSpecialStartCheckpoint", 1])) exitWith { objNull };
    if ((random 1) > (missionNamespace getVariable ["KFH_checkpointBloaterPerWaveChance", 1])) exitWith { objNull };

    private _bloaterClass = [["Zombie_Special_OPFOR_Boomer"], ""] call KFH_fnc_selectExistingClass;
    if (_bloaterClass isEqualTo "") exitWith { objNull };

    private _unit = [
        getMarkerPos _checkpointMarker,
        _bloaterClass,
        "bloater",
        missionNamespace getVariable ["KFH_checkpointSpecialMinDistance", 42],
        missionNamespace getVariable ["KFH_checkpointSpecialMaxDistance", 110],
        getMarkerPos _checkpointMarker,
        missionNamespace getVariable ["KFH_checkpointBloaterPerWaveIgnoreBudget", true],
        true,
        true
    ] call KFH_fnc_spawnSpecialInfected;

    if !(isNull _unit) then {
        [format ["Checkpoint wave guaranteed bloater spawned for CP%1 at %2.", _checkpointIndex, mapGridPosition _unit]] call KFH_fnc_log;
    };
    _unit
};

KFH_fnc_getWildSpecialAnchor = {
    private _minRoadDistance = missionNamespace getVariable ["KFH_wildSpecialMinRoadDistance", 95];
    private _candidates = ([] call KFH_fnc_getHumanReferenceUnits) select {
        private _refVehicle = vehicle _x;
        alive _x &&
        {(count ((getPosATL _refVehicle) nearRoads _minRoadDistance)) isEqualTo 0}
    };

    if ((count _candidates) isEqualTo 0 && {missionNamespace getVariable ["KFH_wildSpecialAllowRouteFallback", true]}) then {
        _candidates = ([] call KFH_fnc_getHumanReferenceUnits) select { alive _x };
    };
    if ((count _candidates) isEqualTo 0) exitWith { objNull };
    selectRandom _candidates
};

KFH_fnc_spawnWildSpecialInfected = {
    if !(missionNamespace getVariable ["KFH_wildSpecialEnabled", true]) exitWith { objNull };
    private _checkpointIndex = missionNamespace getVariable ["KFH_currentCheckpoint", 1];
    if (_checkpointIndex < (missionNamespace getVariable ["KFH_wildSpecialStartCheckpoint", 2])) exitWith { objNull };
    private _threatScale = [] call KFH_fnc_getThreatScale;
    if ((random 1) > (((missionNamespace getVariable ["KFH_wildSpecialChance", 0.35]) * _threatScale) min 0.98)) exitWith { objNull };

    private _activeWild = ({alive _x && {_x getVariable ["KFH_wildSpecialInfected", false]}} count (missionNamespace getVariable ["KFH_activeEnemies", []]));
    if (_activeWild >= ceil ((missionNamespace getVariable ["KFH_wildSpecialMaxActive", 3]) * _threatScale)) exitWith { objNull };

    private _anchor = [] call KFH_fnc_getWildSpecialAnchor;
    if (isNull _anchor) exitWith { objNull };

    private _roleClass = [
        missionNamespace getVariable ["KFH_wildSpecialRoles", missionNamespace getVariable ["KFH_checkpointSpecialRoles", []]]
    ] call KFH_fnc_selectSpecialRoleFromEntries;
    _roleClass params ["_role", "_className"];
    private _minDistance = if (_role isEqualTo "screamer") then {
        missionNamespace getVariable ["KFH_screamerSpawnDistanceMin", 150]
    } else {
        missionNamespace getVariable ["KFH_wildSpecialMinDistance", 130]
    };
    private _maxDistance = if (_role isEqualTo "screamer") then {
        missionNamespace getVariable ["KFH_screamerSpawnDistanceMax", 260]
    } else {
        missionNamespace getVariable ["KFH_wildSpecialMaxDistance", 280]
    };

    private _unit = [
        getPosATL _anchor,
        _className,
        _role,
        _minDistance,
        _maxDistance,
        getPosATL _anchor,
        false,
        true,
        false
    ] call KFH_fnc_spawnSpecialInfected;

    if (!isNull _unit) then {
        _unit setVariable ["KFH_wildSpecialInfected", true, true];
        [format [
            "Wild special infected spawned off-road: role=%1 grid=%2 anchor=%3.",
            _role,
            mapGridPosition _unit,
            name _anchor
        ]] call KFH_fnc_log;
    };

    _unit
};

KFH_fnc_wildSpecialLoop = {
    while { true } do {
        private _phase = missionNamespace getVariable ["KFH_phase", "boot"];
        if (_phase in ["complete", "failed"]) exitWith {};

        if (_phase in ["assault", "extract"]) then {
            [] call KFH_fnc_spawnWildSpecialInfected;
        };

        sleep (missionNamespace getVariable ["KFH_wildSpecialLoopSeconds", 18]);
    };
};

KFH_fnc_configureRushSupplyCarrier = {
    params ["_unit", ["_scale", 1]];

    if (isNull _unit) exitWith {};
    if ((_unit getVariable ["KFH_enemyRole", "melee"]) isNotEqualTo "melee") exitWith {};

    private _bagClass = selectRandom KFH_rushSupplyCarrierBackpacks;

    removeBackpack _unit;
    _unit addBackpack _bagClass;
    _unit setVariable ["KFH_rushSupplyCarrier", true, true];
    _unit setVariable ["KFH_supplyBagClass", _bagClass, true];

    private _bag = unitBackpack _unit;
    if !(isNull _bag) then {
        [_bag, _scale] call KFH_fnc_fillRushSupplyBackpack;
    };

    _unit addEventHandler ["Killed", {
        params ["_unit"];

        if (_unit getVariable ["KFH_supplyCarrierReported", false]) exitWith {};
        _unit setVariable ["KFH_supplyCarrierReported", true, true];
        ["rush_supply_carrier_down", [mapGridPosition _unit]] call KFH_fnc_notifyAllKey;
    }];
};

KFH_fnc_canUseWebKnightZombies = {
    KFH_useWebKnightZombies && {!isNil "WBK_LoadAIThroughEden"}
};

KFH_fnc_isWebKnightCommonZombieReady = {
    params [["_unit", objNull]];

    if (isNull _unit || {!alive _unit}) exitWith { false };

    !(isNil {_unit getVariable "WBK_AI_ISZombie"}) ||
    {!(isNil {_unit getVariable "WBK_AI_ZombieMoveSet"})} ||
    {!(isNil {_unit getVariable "WBK_SynthHP"})}
};

KFH_fnc_unregisterEnemyUnit = {
    params [["_unit", objNull]];

    if (isNull _unit) exitWith { [false, false] };

    private _objectiveEnemies = missionNamespace getVariable ["KFH_currentObjectiveEnemies", []];
    private _activeEnemies = missionNamespace getVariable ["KFH_activeEnemies", []];
    private _wasObjective = _unit in _objectiveEnemies;
    private _wasActive = _unit in _activeEnemies;

    _objectiveEnemies = _objectiveEnemies - [_unit];
    _activeEnemies = _activeEnemies - [_unit];
    missionNamespace setVariable ["KFH_currentObjectiveEnemies", _objectiveEnemies];
    missionNamespace setVariable ["KFH_activeEnemies", _activeEnemies];
    ["KFH_objectiveHostiles", count _objectiveEnemies] call KFH_fnc_setState;
    ["KFH_totalHostiles", count _activeEnemies] call KFH_fnc_setState;

    [_wasActive, _wasObjective]
};

KFH_fnc_deleteEnemyUnit = {
    params [["_unit", objNull]];

    if (isNull _unit) exitWith {};
    private _groupRef = group _unit;
    deleteVehicle _unit;
    if (!isNull _groupRef && {({alive _x} count units _groupRef) isEqualTo 0}) then {
        deleteGroup _groupRef;
    };
};

KFH_fnc_findWebKnightReplacementSpawnPosition = {
    params [["_oldUnit", objNull], ["_target", objNull], ["_objectivePos", []], ["_reason", "replace"]];

    private _targetPos = if (!isNull _target && {alive _target}) then { getPosATL _target } else { [] };
    private _anchorPos = if ((count _objectivePos) >= 2) then { +_objectivePos } else {
        if (!isNull _target && {alive _target}) then { getPosATL _target } else {
            if (!isNull _oldUnit) then { getPosATL _oldUnit } else { [0, 0, 0] }
        }
    };

    if (!isNull _target && {alive _target} && {(count _anchorPos) >= 2}) then {
        private _laneResult = [_target, _anchorPos, format ["webknight-replace-%1", _reason]] call KFH_fnc_findPlayerCheckpointLaneSpawnPosition;
        if ((count _laneResult) >= 2) exitWith { _laneResult select 0 };
    };

    private _minDistance = missionNamespace getVariable ["KFH_webKnightReplacementMinDistance", 34];
    private _maxDistance = missionNamespace getVariable ["KFH_webKnightReplacementMaxDistance", 75];
    private _spawnResult = [_anchorPos, if ((count _targetPos) >= 2) then {_targetPos} else {_anchorPos}] call KFH_fnc_findForcedSpawnFallback;
    if ((count _spawnResult) >= 2) exitWith { _spawnResult };

    _spawnResult = [_anchorPos, _minDistance, _maxDistance] call KFH_fnc_findSafeDistantSpawnPosition;
    if ((count _spawnResult) >= 2) exitWith { _spawnResult };

    if ((count _targetPos) >= 2) then {
        private _near = _targetPos getPos [_minDistance, random 360];
        _near set [2, 0];
        _near
    } else {
        +_anchorPos
    }
};

KFH_fnc_prepareWebKnightReplacementBody = {
    params [["_unit", objNull], ["_role", "melee"]];

    if (isNull _unit) exitWith {};

    removeAllWeapons _unit;
    removeAllItems _unit;
    removeAllAssignedItems _unit;
    removeHeadgear _unit;
    removeGoggles _unit;
    removeVest _unit;
    removeBackpack _unit;
    _unit enableFatigue false;
    _unit allowFleeing 0;

    if (_role isEqualTo "heavyInfected") then {
        _unit forceAddUniform (selectRandom KFH_heavyInfectedUniforms);
        _unit addVest (selectRandom KFH_heavyInfectedVests);
        _unit addHeadgear (selectRandom KFH_heavyInfectedHeadgear);
        _unit addBackpack (selectRandom KFH_heavyInfectedBackpacks);
        _unit setVariable ["KFH_heavyInfected", true, true];
        _unit setVariable ["KFH_heavyInfectedDamageScale", KFH_heavyInfectedDamageScale, true];
        [_unit, KFH_heavyInfectedLootTable, "heavyInfected"] call KFH_fnc_addUnitLootTable;
        if !(_unit getVariable ["KFH_heavyDamageHandlerInstalled", false]) then {
            _unit setVariable ["KFH_heavyDamageHandlerInstalled", true];
            _unit addEventHandler ["HandleDamage", {
                params ["_unit", "_selection", "_incomingDamage", "_source"];

                if !(_unit getVariable ["KFH_heavyInfected", false]) exitWith { _incomingDamage };
                private _scale = _unit getVariable ["KFH_heavyInfectedDamageScale", KFH_heavyInfectedDamageScale];
                _incomingDamage * _scale
            }];
        };
    } else {
        [_unit, KFH_meleeLootTable, "infected"] call KFH_fnc_addUnitLootTable;
    };
};

KFH_fnc_replaceWebKnightExternalZombie = {
    params [["_unit", objNull], ["_reason", "webknight failure"]];

    if (isNull _unit || {!alive _unit}) exitWith { objNull };
    if (_unit getVariable ["KFH_webKnightReplacementInProgress", false]) exitWith { objNull };
    _unit setVariable ["KFH_webKnightReplacementInProgress", true, true];

    private _attempt = _unit getVariable ["KFH_webKnightReplacementAttempt", 0];
    private _maxAttempts = missionNamespace getVariable ["KFH_webKnightReplacementMaxAttempts", 3];
    private _className = _unit getVariable ["KFH_specialClassRequested", typeOf _unit];
    private _spawnClass = typeOf _unit;
    private _role = _unit getVariable ["KFH_webKnightNativeRole", _unit getVariable ["KFH_enemyRole", "melee"]];
    private _zombieType = _unit getVariable ["KFH_webKnightZombieType", -1];
    private _isSpecial = _unit getVariable ["KFH_specialInfected", false];
    private _target = [_unit] call KFH_fnc_findClosestCombatPlayer;
    private _markerName = missionNamespace getVariable ["KFH_currentObjectiveMarker", ""];
    private _objectivePos = if (_markerName in allMapMarkers) then { getMarkerPos _markerName } else {
        if (!isNull _target && {alive _target}) then { getPosATL _target } else { getPosATL _unit }
    };
    private _moveTarget = if (!isNull _target && {alive _target}) then { getPosATL _target } else { +_objectivePos };
    private _state = [_unit] call KFH_fnc_unregisterEnemyUnit;
    private _wasObjective = _state select 1;

    if (_attempt >= _maxAttempts) exitWith {
        [format [
            "WebKnight external zombie replacement exhausted; removing unit: class=%1 role=%2 attempt=%3 reason=%4.",
            typeOf _unit,
            _role,
            _attempt,
            _reason
        ]] call KFH_fnc_log;
        if (_wasObjective) then {
            [1, format ["webknight replacement exhausted %1", _reason]] call KFH_fnc_addRushDebt;
        };
        [_unit] call KFH_fnc_deleteEnemyUnit;
        objNull
    };

    private _spawnPos = [_unit, _target, _objectivePos, _reason] call KFH_fnc_findWebKnightReplacementSpawnPosition;
    [_unit] call KFH_fnc_deleteEnemyUnit;

    private _replacement = objNull;
    if (_isSpecial) then {
        _replacement = [
            _spawnPos,
            _className,
            _role,
            missionNamespace getVariable ["KFH_webKnightReplacementMinDistance", 34],
            missionNamespace getVariable ["KFH_webKnightReplacementMaxDistance", 75],
            _moveTarget,
            true,
            true,
            _wasObjective,
            _attempt + 1
        ] call KFH_fnc_spawnSpecialInfected;
    } else {
        private _groupRef = createGroup [east, true];
        _groupRef setFormation "FILE";
        _groupRef allowFleeing 0;
        _groupRef setBehaviourStrong "COMBAT";
        _groupRef setCombatMode "YELLOW";
        _groupRef setSpeedMode "FULL";

        _replacement = _groupRef createUnit [_spawnClass, _spawnPos, [], 0, "FORM"];
        _replacement setDir (if ((count _moveTarget) >= 2) then { _spawnPos getDir _moveTarget } else { random 360 });
        _replacement setSkill (0.35 + random 0.25);
        [_replacement, _role] call KFH_fnc_prepareWebKnightReplacementBody;
        _replacement setVariable ["KFH_webKnightReplacementAttempt", _attempt + 1, true];
        _replacement setVariable ["KFH_webKnightNativeRole", _role, true];
        if ((count _moveTarget) >= 2) then {
            _replacement setVariable ["WBK_AI_LastKnownLoc", _moveTarget, true];
        };
        if ([_replacement, _attempt + 1, _zombieType] call KFH_fnc_tryConfigureWebKnightZombie) then {
            private _activeEnemies = missionNamespace getVariable ["KFH_activeEnemies", []];
            _activeEnemies pushBackUnique _replacement;
            missionNamespace setVariable ["KFH_activeEnemies", _activeEnemies];
            if (_wasObjective) then {
                private _objectiveEnemies = missionNamespace getVariable ["KFH_currentObjectiveEnemies", []];
                _objectiveEnemies pushBackUnique _replacement;
                missionNamespace setVariable ["KFH_currentObjectiveEnemies", _objectiveEnemies];
                ["KFH_objectiveHostiles", count _objectiveEnemies] call KFH_fnc_setState;
            };
            ["KFH_totalHostiles", count _activeEnemies] call KFH_fnc_setState;
        } else {
            if (_wasObjective) then {
                [1, format ["webknight replacement unavailable %1", _reason]] call KFH_fnc_addRushDebt;
            };
            [_replacement] call KFH_fnc_deleteEnemyUnit;
            _replacement = objNull;
        };
    };

    if (isNull _replacement && {_wasObjective}) then {
        [1, format ["webknight replacement failed %1", _reason]] call KFH_fnc_addRushDebt;
    };

    [format [
        "WebKnight external zombie replaced: oldClass=%1 newClass=%2 role=%3 attempt=%4 reason=%5 grid=%6 target=%7.",
        _spawnClass,
        if (isNull _replacement) then { "<null>" } else { typeOf _replacement },
        _role,
        _attempt + 1,
        _reason,
        if (isNull _replacement) then { "<none>" } else { mapGridPosition _replacement },
        if (isNull _target) then { "<none>" } else { name _target }
    ]] call KFH_fnc_log;

    _replacement
};

KFH_fnc_handleWebKnightCommonZombieInitFailure = {
    params [["_unit", objNull], ["_zombieType", -1]];

    if (isNull _unit || {!alive _unit}) exitWith {};
    _unit setVariable ["KFH_webKnightZombieType", _zombieType, true];
    [_unit, "common init failed"] call KFH_fnc_replaceWebKnightExternalZombie;
};

KFH_fnc_warnMissingWebKnightZombies = {
    if !(KFH_useWebKnightZombies) exitWith {};
    if (missionNamespace getVariable ["KFH_webKnightMissingNotified", false]) exitWith {};

    missionNamespace setVariable ["KFH_webKnightMissingNotified", true, true];
    [
        "WebKnight Zombies is enabled in KFH settings, but WBK_LoadAIThroughEden was not found. Zombie AI fallback is disabled."
    ] call KFH_fnc_log;
    ["melee_dependency_missing"] call KFH_fnc_notifyAllKey;
};

KFH_fnc_enemyDirectorShouldUseExternalZombie = {
    params [["_role", "melee"], ["_requested", true]];

    if (!_requested) exitWith { false };
    if !(KFH_useWebKnightZombies) exitWith { false };

    switch (_role) do {
        case "melee": { missionNamespace getVariable ["KFH_enemyDirectorUseWebKnightForCommon", true] };
        case "heavyInfected": { missionNamespace getVariable ["KFH_enemyDirectorUseWebKnightForHeavy", true] };
        default { true };
    };
};

KFH_fnc_getWebKnightNativeSpecialAIScript = {
    params [["_unit", objNull], ["_role", ""]];

    private _class = toLower (if (isNull _unit) then { "" } else { typeOf _unit });
    private _roleKey = toLower _role;

    if (_roleKey isEqualTo "screamer" || {(_class find "screamer") >= 0}) exitWith {
        "\WBK_Zombies\AI\WBK_AI_Stunden.sqf"
    };
    if (_roleKey isEqualTo "bloater" || {(_class find "boomer") >= 0} || {(_class find "bloater") >= 0}) exitWith {
        "\WBK_Zombies\AI\WBK_AI_ZombieExplosion.sqf"
    };
    if (_roleKey isEqualTo "goliath" || {(_class find "goliaph") >= 0}) exitWith {
        "\WBK_Zombies_Goliath\AI\WBK_Goliath_AI.sqf"
    };
    if (_roleKey isEqualTo "smasher" || {(_class find "smasher") >= 0}) exitWith {
        "\WBK_Zombies_Smasher\AI\WBK_AI_Smasher.sqf"
    };

    ""
};

KFH_fnc_isWebKnightNativeSpecialReady = {
    params [["_unit", objNull], ["_role", ""]];

    if (isNull _unit || {!alive _unit}) exitWith { false };

    private _class = toLower (typeOf _unit);
    private _roleKey = toLower _role;

    if (_roleKey isEqualTo "screamer" || {(_class find "screamer") >= 0}) exitWith {
        !(isNil {_unit getVariable "WBK_AI_ZombieMoveSet"}) &&
        {!(isNil {_unit getVariable "WBK_SynthHP"})}
    };
    if (_roleKey isEqualTo "bloater" || {(_class find "boomer") >= 0} || {(_class find "bloater") >= 0}) exitWith {
        !(isNil {_unit getVariable "WBK_AI_ZombieMoveSet"}) &&
        {!(isNil {_unit getVariable "WBK_SynthHP"})}
    };
    if (_roleKey isEqualTo "goliath" || {(_class find "goliaph") >= 0}) exitWith {
        !(isNil {_unit getVariable "WBK_SynthHP"}) ||
        {!(isNil {_unit getVariable "IMS_IsUnitInvicibleScripted"})}
    };
    if (_roleKey isEqualTo "smasher" || {(_class find "smasher") >= 0}) exitWith {
        !(isNil {_unit getVariable "WBK_AI_ZombieMoveSet"}) ||
        {!(isNil {_unit getVariable "WBK_SynthHP"})}
    };

    !(isNil {_unit getVariable "WBK_AI_ISZombie"})
};

KFH_fnc_runWebKnightNativeSpecialAIScript = {
    params [["_unit", objNull], ["_script", ""], ["_role", ""]];

    if (isNull _unit || {!alive _unit} || {_script isEqualTo ""}) exitWith {};

    private _class = toLower (typeOf _unit);
    private _roleKey = toLower _role;
    if (_roleKey isEqualTo "bloater" || {(_class find "boomer") >= 0} || {(_class find "bloater") >= 0}) then {
        [_unit] execVM _script;
    } else {
        _unit execVM _script;
    };
};

KFH_fnc_tryStartWebKnightNativeSpecialAI = {
    params ["_unit", ["_role", "special"], ["_targetPos", []]];

    if (isNull _unit || {!alive _unit}) exitWith { false };
    if !(KFH_useWebKnightZombies) exitWith { false };
    if (!local _unit) exitWith {
        [_unit, _role, _targetPos] remoteExecCall ["KFH_fnc_tryStartWebKnightNativeSpecialAI", owner _unit];
        true
    };

    if ((count _targetPos) >= 2) then {
        _unit setVariable ["WBK_AI_LastKnownLoc", _targetPos, true];
        private _target = [_unit] call KFH_fnc_findClosestCombatPlayer;
        if (!isNull _target) then {
            _unit reveal [_target, 4];
        };
    };

    [_unit, _role, _targetPos] spawn {
        params ["_trackedUnit", "_trackedRole", "_trackedTargetPos"];

        sleep (missionNamespace getVariable ["KFH_webKnightNativeSpecialInitDelay", 0.45]);
        if (isNull _trackedUnit || {!alive _trackedUnit} || {!local _trackedUnit}) exitWith {};
        private _timeoutAt = time + (missionNamespace getVariable ["KFH_webKnightNativeSpecialInitTimeout", 2]);
        waitUntil {
            sleep 0.2;
            isNull _trackedUnit ||
            {!alive _trackedUnit} ||
            {!local _trackedUnit} ||
            {[_trackedUnit, _trackedRole] call KFH_fnc_isWebKnightNativeSpecialReady} ||
            {time >= _timeoutAt}
        };
        if (isNull _trackedUnit || {!alive _trackedUnit} || {!local _trackedUnit}) exitWith {};
        if ([_trackedUnit, _trackedRole] call KFH_fnc_isWebKnightNativeSpecialReady) exitWith {
            _trackedUnit setVariable ["KFH_externalZombieInitPending", false, true];
        };

        private _script = [_trackedUnit, _trackedRole] call KFH_fnc_getWebKnightNativeSpecialAIScript;
        if (_script isEqualTo "") exitWith {
            _trackedUnit setVariable ["KFH_externalZombieInitPending", false, true];
        };

        if !(isNil {_trackedUnit getVariable "WBK_AI_ISZombie"}) then {
            _trackedUnit setVariable ["WBK_AI_ISZombie", nil, true];
        };
        [_trackedUnit, _script, _trackedRole] call KFH_fnc_runWebKnightNativeSpecialAIScript;
        _trackedUnit setVariable ["KFH_webKnightNativeSpecialInitForced", true, true];
        if ((count _trackedTargetPos) >= 2) then {
            _trackedUnit setVariable ["WBK_AI_LastKnownLoc", _trackedTargetPos, true];
        };
        private _forcedTimeoutAt = time + (missionNamespace getVariable ["KFH_webKnightNativeSpecialInitTimeout", 2]);
        waitUntil {
            sleep 0.2;
            isNull _trackedUnit ||
            {!alive _trackedUnit} ||
            {!local _trackedUnit} ||
            {[_trackedUnit, _trackedRole] call KFH_fnc_isWebKnightNativeSpecialReady} ||
            {time >= _forcedTimeoutAt}
        };
        if (isNull _trackedUnit || {!alive _trackedUnit} || {!local _trackedUnit}) exitWith {};
        if ([_trackedUnit, _trackedRole] call KFH_fnc_isWebKnightNativeSpecialReady) then {
            _trackedUnit setVariable ["KFH_externalZombieInitPending", false, true];
        } else {
            [_trackedUnit, format ["special init failed role=%1", _trackedRole]] call KFH_fnc_replaceWebKnightExternalZombie;
        };
    };

    true
};

KFH_fnc_tryConfigureWebKnightZombie = {
    params ["_unit", ["_replacementAttempt", 0], ["_forcedZombieType", -1]];

    if (isNull _unit) exitWith { false };
    if !(alive _unit) exitWith { false };
    if !(KFH_useWebKnightZombies) exitWith { false };

    if !([] call KFH_fnc_canUseWebKnightZombies) exitWith {
        [] call KFH_fnc_warnMissingWebKnightZombies;
        false
    };

    private _externalCount = count ((missionNamespace getVariable ["KFH_activeEnemies", []]) select {
        alive _x && {(_x getVariable ["KFH_enemyRole", ""]) isEqualTo "externalZombie"}
    });
    if (_externalCount >= KFH_webKnightZombieMaxActive) exitWith { false };

    private _type = if (_forcedZombieType >= 0) then { _forcedZombieType } else { selectRandom KFH_webKnightZombieTypes };
    _unit setVariable ["KFH_enemyRole", "externalZombie", true];
    _unit setVariable ["KFH_webKnightZombieType", _type, true];
    _unit setVariable ["KFH_webKnightReplacementAttempt", _replacementAttempt, true];
    _unit setVariable ["KFH_externalZombieInitPending", true, true];

    [_unit, _type] spawn {
        params ["_trackedUnit", "_zombieType"];

        sleep KFH_webKnightInitDelay;
        waitUntil {
            sleep 0.05;
            isNull _trackedUnit || {alive _trackedUnit && {simulationEnabled _trackedUnit}}
        };
        if (isNull _trackedUnit || {!alive _trackedUnit}) exitWith {};

        private _ready = false;
        private _attempt = 0;
        private _maxRetries = missionNamespace getVariable ["KFH_webKnightCommonInitRetries", 1];
        private _timeout = missionNamespace getVariable ["KFH_webKnightCommonInitTimeout", 2.5];
        while {
            !isNull _trackedUnit &&
            {alive _trackedUnit} &&
            {!_ready} &&
            {_attempt <= _maxRetries}
        } do {
            [_trackedUnit, _zombieType] call WBK_LoadAIThroughEden;
            private _target = [_trackedUnit] call KFH_fnc_findClosestCombatPlayer;
            if (!isNull _target) then {
                _trackedUnit reveal [_target, 4];
                _trackedUnit setVariable ["WBK_AI_LastKnownLoc", getPosATL _target, true];
            };

            private _timeoutAt = time + _timeout;
            waitUntil {
                sleep 0.2;
                isNull _trackedUnit ||
                {!alive _trackedUnit} ||
                {[_trackedUnit] call KFH_fnc_isWebKnightCommonZombieReady} ||
                {time >= _timeoutAt}
            };
            _ready = [_trackedUnit] call KFH_fnc_isWebKnightCommonZombieReady;
            _attempt = _attempt + 1;
        };

        if (isNull _trackedUnit || {!alive _trackedUnit}) exitWith {};
        if (_ready) then {
            _trackedUnit setVariable ["KFH_externalZombieInitPending", false, true];
            _trackedUnit setVariable ["KFH_enemyRole", "externalZombie", true];
        } else {
            [_trackedUnit, _zombieType] call KFH_fnc_handleWebKnightCommonZombieInitFailure;
        };
    };

    true
};

KFH_fnc_setupMeleeChaseState = {
    params ["_unit", ["_role", "melee"], ["_allowExternalZombie", false], ["_animSpeed", -1]];

    if (isNull _unit) exitWith {};

    private _externalZombieHandled = false;
    if ([_role, _allowExternalZombie] call KFH_fnc_enemyDirectorShouldUseExternalZombie) then {
        if ([_unit] call KFH_fnc_tryConfigureWebKnightZombie) then {
            _unit setVariable ["KFH_webKnightNativeRole", _role, true];
            _externalZombieHandled = true;
        };
        if (!_externalZombieHandled && {!(missionNamespace getVariable ["KFH_enemyDirectorFallbackMeleeEnabled", false])}) then {
            [format ["Removed zombie candidate because WebKnight init did not accept it and KFH zombie AI fallback is disabled: role=%1 class=%2.", _role, typeOf _unit]] call KFH_fnc_log;
            [_unit] call KFH_fnc_deleteEnemyUnit;
            _externalZombieHandled = true;
        };
    };
    if (_externalZombieHandled) exitWith {};

    _unit setVariable ["KFH_enemyRole", _role, true];
    _unit setVariable ["KFH_nextMeleeAttackAt", 0];
    _unit setVariable ["KFH_nextMoveUpdateAt", 0];
    _unit setVariable ["KFH_nextCommandMoveAt", 0];
    _unit setVariable ["KFH_nextForcedDestinationAt", 0];
    _unit setVariable ["KFH_lastMovePos", getPosATL _unit];
    _unit setVariable ["KFH_lastStuckCheckAt", time];
    _unit setVariable ["KFH_lastStuckCheckPos", getPosATL _unit];
    _unit setVariable ["KFH_nextGroanAt", time + random 2];
    _unit enableFatigue false;
    _unit allowFleeing 0;

    private _runAnimSpeed = if (_animSpeed > 0) then {
        _animSpeed
    } else {
        switch (_role) do {
            case "leaper": { missionNamespace getVariable ["KFH_leaperProxyAnimSpeed", 1.12] };
            case "heavyInfected": { KFH_heavyInfectedAnimSpeed };
            case "goliath": { KFH_juggernautAnimSpeed };
            case "smasher": { KFH_juggernautAnimSpeed };
            default { KFH_meleeRunAnimSpeed };
        }
    };
    _unit setAnimSpeedCoef _runAnimSpeed;

    {
        _unit disableAI _x;
    } forEach ["AUTOCOMBAT", "COVER", "SUPPRESSION"];
    {
        _unit enableAI _x;
    } forEach ["MOVE", "PATH", "TARGET", "AUTOTARGET", "FSM"];
    _unit setBehaviourStrong "COMBAT";
    _unit setCombatMode "RED";
    _unit setSpeedMode "FULL";
    _unit setUnitPos "UP";
    _unit forceWalk false;
    _unit setSpeaker "NoVoice";
    (group _unit) setFormation "FILE";
    (group _unit) allowFleeing 0;
    (group _unit) setCombatMode "RED";
    (group _unit) setSpeedMode "FULL";
    (group _unit) setBehaviour "COMBAT";
    _unit stop false;

    if (_allowExternalZombie) then {
        [_unit] call KFH_fnc_tryConfigureWebKnightZombie;
    };
};

KFH_fnc_configureMeleeEnemy = {
    params ["_unit", ["_allowExternalZombie", true]];

    if (isNull _unit) exitWith {};

    removeAllWeapons _unit;
    removeAllItems _unit;
    removeAllAssignedItems _unit;
    removeHeadgear _unit;
    removeGoggles _unit;
    removeVest _unit;
    removeBackpack _unit;

    [_unit, "melee", _allowExternalZombie, KFH_meleeRunAnimSpeed] call KFH_fnc_setupMeleeChaseState;
    [_unit, KFH_meleeLootTable, "infected"] call KFH_fnc_addUnitLootTable;
};

KFH_fnc_configureSpawnedEnemies = {
    params ["_units"];

    {
        [_x] call KFH_fnc_configureMeleeEnemy;
    } forEach _units;
};

KFH_fnc_findClosestCombatPlayer = {
    params ["_origin"];

    private _targets = [] call KFH_fnc_getCombatReadyHumans;
    if ((count _targets) isEqualTo 0) then {
        _targets = [] call KFH_fnc_getCombatReadyFriendlies;
    };

    if ((count _targets) isEqualTo 0) exitWith { objNull };

    private _closest = objNull;
    private _closestDistance = 1e10;

    {
        private _distance = _origin distance2D _x;
        if (_distance < _closestDistance) then {
            _closest = _x;
            _closestDistance = _distance;
        };
    } forEach _targets;

    _closest
};

KFH_fnc_updateMeleeEnemy = {
    params ["_unit"];

    if (isNull _unit) exitWith {};
    if !(alive _unit) exitWith {};
    private _role = _unit getVariable ["KFH_enemyRole", "melee"];
    private _meleeChaserRoles = ["melee", "leaper", "heavyInfected", "bloater", "screamer", "smasher", "goliath"];
    if (_role isEqualTo "externalZombie") exitWith {};
    if !(_role in _meleeChaserRoles) exitWith {};

    private _target = [_unit] call KFH_fnc_findClosestCombatPlayer;
    if (isNull _target) exitWith {};

    private _distance = _unit distance2D _target;
    private _nextAttackAt = _unit getVariable ["KFH_nextMeleeAttackAt", 0];
    private _targetDir = [_unit, _target] call BIS_fnc_dirTo;
    private _runAnimSpeed = switch (_role) do {
        case "leaper": { missionNamespace getVariable ["KFH_leaperProxyAnimSpeed", 1.12] };
        case "heavyInfected": { KFH_heavyInfectedAnimSpeed };
        case "goliath": { KFH_juggernautAnimSpeed };
        case "smasher": { KFH_juggernautAnimSpeed };
        default { KFH_meleeRunAnimSpeed };
    };

    if (time >= (_unit getVariable ["KFH_nextMoveUpdateAt", 0])) then {
        [_unit, _target, _distance] call KFH_fnc_updateMeleeDestination;
        _unit setVariable ["KFH_nextMoveUpdateAt", time + (if (_role isEqualTo "leaper") then { missionNamespace getVariable ["KFH_leaperProxyRetargetSeconds", 0.12] } else { KFH_meleeRetargetSeconds })];
    };

    if (time >= ((_unit getVariable ["KFH_lastStuckCheckAt", 0]) + KFH_meleeStuckCheckSeconds)) then {
        private _lastCheckPos = _unit getVariable ["KFH_lastStuckCheckPos", getPosATL _unit];
        private _moved = _unit distance2D _lastCheckPos;

        if (_distance > (KFH_meleeAttackRange + 1) && {_moved < KFH_meleeStuckDistance}) then {
            [_unit, _target, _distance] call KFH_fnc_updateMeleeDestination;
            _unit setVariable ["KFH_lastMovePos", [0, 0, 0]];
        };

        _unit setVariable ["KFH_lastStuckCheckAt", time];
        _unit setVariable ["KFH_lastStuckCheckPos", getPosATL _unit];
    };

    if (_role isEqualTo "leaper" && {missionNamespace getVariable ["KFH_leaperProxyCrawlEnabled", true]}) then {
        _unit setUnitPos (missionNamespace getVariable ["KFH_leaperProxyUnitPos", "MIDDLE"]);
    } else {
        _unit setUnitPos "UP";
    };
    _unit stop false;
    _unit allowFleeing 0;
    _unit setBehaviourStrong "COMBAT";
    _unit setCombatMode "RED";
    (group _unit) allowFleeing 0;
    (group _unit) setBehaviour "COMBAT";
    (group _unit) setCombatMode "RED";

    if (_role isEqualTo "leaper") then {
        private _targetPos = getPosATL _target;
        _unit enableAI "FSM";
        _unit setBehaviourStrong "COMBAT";
        _unit setCombatMode "RED";
        (group _unit) setBehaviour "COMBAT";
        (group _unit) setCombatMode "RED";
        _unit commandMove _targetPos;
        _unit doMove _targetPos;
        (group _unit) move _targetPos;
        _unit setDestination [_targetPos, "LEADER DIRECT", true];

        private _pounceMin = missionNamespace getVariable ["KFH_leaperProxyPounceMinDistance", 4.5];
        private _pounceMax = missionNamespace getVariable ["KFH_leaperProxyPounceMaxDistance", 16];
        if (
            _distance >= _pounceMin &&
            {_distance <= _pounceMax} &&
            {time >= (_unit getVariable ["KFH_nextLeaperPounceAt", 0])}
        ) then {
            private _pounceForward = missionNamespace getVariable ["KFH_leaperProxyPounceForwardVelocity", 3.2];
            if (_pounceForward > 0) then {
                _unit setVariable ["KFH_nextLeaperPounceAt", time + (missionNamespace getVariable ["KFH_leaperProxyPounceCooldown", 7.5]) + random 1.2];
                _unit setDir _targetDir;
                _unit setVelocityModelSpace [
                    0,
                    _pounceForward,
                    missionNamespace getVariable ["KFH_leaperProxyPounceUpVelocity", 0.25]
                ];
            };
        };
    };

    if (_distance <= KFH_meleeFaceDistance) then {
        _unit setDir _targetDir;
    };

    if (_distance <= KFH_meleeWalkDistance) then {
        if (_role isEqualTo "leaper") then {
            _unit forceWalk true;
            _unit setSpeedMode "LIMITED";
            _unit setAnimSpeedCoef _runAnimSpeed;
        } else {
            _unit forceWalk true;
            _unit setSpeedMode "LIMITED";
            _unit setAnimSpeedCoef KFH_meleeWalkAnimSpeed;
        };
    } else {
        _unit forceWalk false;
        _unit setSpeedMode "FULL";
        _unit setAnimSpeedCoef _runAnimSpeed;
    };

    if (
        _distance <= KFH_meleeCueDistance &&
        {time >= (_unit getVariable ["KFH_nextGroanAt", 0])}
    ) then {
        _unit setVariable ["KFH_nextGroanAt", time + KFH_meleeCueCooldown + random 1.5];
        [_unit] remoteExecCall ["KFH_fnc_playZombieCue", 0];
    };

    if (_distance <= KFH_meleeAttackRange && {time >= _nextAttackAt}) then {
        _unit setVariable ["KFH_nextMeleeAttackAt", time + KFH_meleeAttackCooldown];
        [_unit] remoteExecCall ["KFH_fnc_localEnemyAttackAnim", 0];
        if (_distance > 0.55) then {
            _unit setVelocityModelSpace [0, KFH_meleeAttackLunge, 0.02];
        };
        [_unit] call KFH_fnc_playZombieCue;
        _target setDamage ((damage _target) + KFH_meleeAttackDamage);
        if (isPlayer _target) then {
            [] remoteExecCall ["KFH_fnc_localMeleeHitFeedback", _target];
        };
        [format ["An infected rusher hit %1.", name _target]] call KFH_fnc_log;
    };
};

KFH_fnc_meleeDirectorLoop = {
    while { true } do {
        private _phase = missionNamespace getVariable ["KFH_phase", "boot"];

        if (_phase in ["complete", "failed"]) exitWith {};

        {
            [_x] call KFH_fnc_updateMeleeEnemy;
        } forEach ([] call KFH_fnc_pruneActiveEnemies);

        sleep KFH_meleeRetargetSeconds;
    };
};

