KFH_fnc_spawnGroupWave = {
    params [
        "_centerPos",
        "_spawnMarkers",
        "_unitCount",
        ["_gunnerChance", 0],
        ["_supplyCarrierChance", 0],
        ["_heavyChance", 0],
        ["_moveTargetPos", []],
        ["_context", "wave"],
        ["_checkpointPos", []],
        ["_moveTargetUnit", objNull],
        ["_ignoreActiveCap", false]
    ];

    private _enemyClasses = missionNamespace getVariable ["KFH_enemyClasses", KFH_enemyClasses];
    private _spawnedUnits = [];
    if ((count _moveTargetPos) < 2) then { _moveTargetPos = +_centerPos; };
    private _requestedUnitCount = _unitCount max 0;
    _unitCount = if (_ignoreActiveCap) then { _requestedUnitCount } else { [_unitCount] call KFH_fnc_limitSpawnCountByActiveBudget };
    private _deferredUnitCount = (_requestedUnitCount - _unitCount) max 0;
    if (!_ignoreActiveCap && {_deferredUnitCount > 0}) then {
        [_deferredUnitCount, "spawn cap deferred from wave request"] call KFH_fnc_addRushDebt;
    };

    if ((count _enemyClasses) isEqualTo 0) exitWith { [] };
    if (_unitCount <= 0) exitWith {
        [format [
            "Wave spawn skipped by budget context=%1 requested=%2 allowed=%3 active=%4.",
            _context,
            _requestedUnitCount,
            _unitCount,
            count (missionNamespace getVariable ["KFH_activeEnemies", []])
        ]] call KFH_fnc_log;
        []
    };

    private _stageCounts = [];
    private _clusterEnabled = (missionNamespace getVariable ["KFH_waveSpawnClusterEnabled", true]) && {!KFH_useManualSpawnMarkers};
    private _clusterSize = (missionNamespace getVariable ["KFH_waveSpawnClusterSize", 4]) max 1;
    private _maxClusters = (missionNamespace getVariable ["KFH_waveSpawnMaxClusters", 3]) max 1;
    private _clusterRadius = missionNamespace getVariable ["KFH_waveSpawnClusterRadius", 7];
    private _clusterSafeRadius = missionNamespace getVariable ["KFH_waveSpawnClusterSafeRadius", 5];
    private _clusterBases = [];

    for "_i" from 0 to (_unitCount - 1) do {
        private _groupRef = createGroup [east, true];
        _groupRef setFormation "FILE";
        _groupRef allowFleeing 0;
        _groupRef setBehaviourStrong "COMBAT";
        _groupRef setCombatMode "YELLOW";
        _groupRef setSpeedMode "FULL";
        private _spawnPos = [0, 0, 0];

        if (KFH_useManualSpawnMarkers && ((count _spawnMarkers) > 0)) then {
            _spawnPos = getMarkerPos (selectRandom _spawnMarkers);
        } else {
            private _spawnResult = [];
            if (_clusterEnabled) then {
                private _clusterIndex = floor (_i / _clusterSize);
                while { _clusterIndex >= _maxClusters } do {
                    _clusterIndex = _clusterIndex - _maxClusters;
                };
                while { (count _clusterBases) <= _clusterIndex } do {
                    private _newIndex = count _clusterBases;
                    private _baseResult = [
                        _centerPos,
                        _moveTargetPos,
                        format ["%1-cluster%2", _context, _newIndex + 1],
                        _checkpointPos,
                        _moveTargetUnit
                    ] call KFH_fnc_findWaveSpawnPosition;
                    _clusterBases pushBack _baseResult;
                };
                _spawnResult = _clusterBases select _clusterIndex;
            } else {
                _spawnResult = [_centerPos, _moveTargetPos, _context, _checkpointPos, _moveTargetUnit] call KFH_fnc_findWaveSpawnPosition;
            };
            _spawnPos = _spawnResult select 0;
            private _stage = _spawnResult select 1;
            private _stageIndex = _stageCounts findIf { (_x select 0) isEqualTo _stage };
            if (_stageIndex < 0) then {
                _stageCounts pushBack [_stage, 1];
            } else {
                (_stageCounts select _stageIndex) set [1, ((_stageCounts select _stageIndex) select 1) + 1];
            };
            if (_clusterEnabled && {(count _spawnPos) >= 2} && {_clusterRadius > 0}) then {
                private _clusterSeed = _spawnPos getPos [random _clusterRadius, random 360];
                private _clusterCandidate = [_clusterSeed, 0, _clusterSafeRadius, 1, 0, 0.45, 0] call BIS_fnc_findSafePos;
                if ((count _clusterCandidate) < 3) then {
                    _clusterCandidate set [2, 0];
                };
                if (
                    !((_clusterCandidate select 0) isEqualTo 0 && {(_clusterCandidate select 1) isEqualTo 0}) &&
                    {!surfaceIsWater _clusterCandidate} &&
                    {[_clusterCandidate, objNull, missionNamespace getVariable ["KFH_spawnForcedMinPlayerDistance", 35], missionNamespace getVariable ["KFH_spawnForcedMinRespawnDistance", 30], 0, false] call KFH_fnc_isSpawnCandidateOpen}
                ) then {
                    _spawnPos = +_clusterCandidate;
                };
            };
        };

        if (
            (_spawnPos isEqualTo []) ||
            {(_spawnPos distance2D _centerPos) < 3} ||
            {surfaceIsWater _spawnPos} ||
            {!([_spawnPos, objNull, missionNamespace getVariable ["KFH_spawnForcedMinPlayerDistance", 35], missionNamespace getVariable ["KFH_spawnForcedMinRespawnDistance", 30], 0, false] call KFH_fnc_isSpawnCandidateOpen)}
        ) then {
            private _spawnResult = [_centerPos, _moveTargetPos, format ["%1-final", _context], _checkpointPos, _moveTargetUnit] call KFH_fnc_findWaveSpawnPosition;
            _spawnPos = _spawnResult select 0;
        };

        if (
            (_spawnPos isEqualTo []) ||
            {surfaceIsWater _spawnPos}
        ) then {
            [format ["Skipped unsafe hostile spawn context=%1 anchor=%2 moveTarget=%3 candidate=%4.", _context, mapGridPosition _centerPos, mapGridPosition _moveTargetPos, _spawnPos]] call KFH_fnc_log;
            deleteGroup _groupRef;
        } else {
            private _unit = _groupRef createUnit [selectRandom _enemyClasses, _spawnPos, [], 0, "FORM"];
            _unit setSkill (0.35 + random 0.25);
            _unit setDir ([_unit, _moveTargetPos] call BIS_fnc_dirTo);
            _groupRef selectLeader _unit;
            _spawnedUnits pushBack _unit;
            _groupRef move _moveTargetPos;
        };
    };

    if ((count _spawnedUnits) < _requestedUnitCount) then {
        [format [
            "Wave spawn shortfall context=%1 requested=%2 allowed=%3 spawned=%4 stages=%5 anchor=%6 moveTarget=%7.",
            _context,
            _requestedUnitCount,
            _unitCount,
            count _spawnedUnits,
            _stageCounts,
            mapGridPosition _centerPos,
            mapGridPosition _moveTargetPos
        ]] call KFH_fnc_log;
    };

    private _availableForRoles = +_spawnedUnits;
    private _gunnerCount = if (_gunnerChance > 0 && {(count _availableForRoles) > 0}) then {
        [_unitCount, _gunnerChance, count _availableForRoles] call KFH_fnc_rollRoleCount
    } else {
        0
    };

    for "_i" from 1 to _gunnerCount do {
        private _picked = selectRandom _availableForRoles;
        _availableForRoles deleteAt (_availableForRoles find _picked);
        [_picked] call KFH_fnc_configureAgentEnemy;
        _picked doMove _moveTargetPos;
    };

    private _heavyCount = if (_heavyChance > 0 && {(count _availableForRoles) > 0}) then {
        [_unitCount, _heavyChance, count _availableForRoles] call KFH_fnc_rollRoleCount
    } else {
        0
    };

    for "_i" from 1 to _heavyCount do {
        private _picked = selectRandom _availableForRoles;
        _availableForRoles deleteAt (_availableForRoles find _picked);
        [_picked] call KFH_fnc_configureHeavyInfected;
    };

    private _carrierCount = if (_supplyCarrierChance > 0 && {(count _availableForRoles) > 0}) then {
        [_unitCount, _supplyCarrierChance, KFH_rushSupplyCarrierMax min (count _availableForRoles)] call KFH_fnc_rollRoleCount
    } else {
        0
    };

    for "_i" from 1 to _carrierCount do {
        private _picked = selectRandom _availableForRoles;
        _availableForRoles deleteAt (_availableForRoles find _picked);
        [_picked, true] call KFH_fnc_configureMeleeEnemy;
        [_picked, _unitCount / 10] call KFH_fnc_configureRushSupplyCarrier;
    };

    {
        [_x, true] call KFH_fnc_configureMeleeEnemy;
    } forEach _availableForRoles;

    _spawnedUnits = _spawnedUnits select { alive _x };

    {
        [_x, _moveTargetUnit, _moveTargetPos] call KFH_fnc_driveEnemyTowardTarget;
    } forEach _spawnedUnits;

    if ((count _spawnedUnits) > 0) then {
        [format [
            "Wave spawn placement context=%1 spawned=%2 stages=%3 clusters=%4 target=%5.",
            _context,
            count _spawnedUnits,
            _stageCounts,
            count _clusterBases,
            if (isNull _moveTargetUnit) then { mapGridPosition _moveTargetPos } else { name _moveTargetUnit }
        ]] call KFH_fnc_log;
    };

    _spawnedUnits
};

KFH_fnc_spawnCheckpointWave = {
    params ["_checkpointIndex", ["_multiplier", 1], ["_setAsCurrentObjective", false]];

    private _checkpointMarkers = missionNamespace getVariable ["KFH_checkpointMarkers", []];

    if (_checkpointIndex > count _checkpointMarkers) exitWith { [] };

    private _checkpointMarker = _checkpointMarkers select (_checkpointIndex - 1);
    private _recycledCount = [_checkpointMarker] call KFH_fnc_recycleOffscreenObjectiveEnemies;
    private _baseCounts = missionNamespace getVariable ["KFH_waveBaseCounts", KFH_waveBaseCounts];
    private _baseIndex = ((_checkpointIndex - 1) min ((count _baseCounts) - 1)) max 0;
    private _baseCount = _baseCounts select _baseIndex;
    private _waveNumber = missionNamespace getVariable ["KFH_currentWave", 0];
    private _newWaveNumber = _waveNumber + 1;
    private _phase = missionNamespace getVariable ["KFH_phase", "assault"];
    private _isRushWave =
        (_phase isEqualTo "assault") &&
        {_newWaveNumber > 0} &&
        {(_newWaveNumber mod KFH_rushEveryWaves) isEqualTo 0};
    private _effectiveMultiplier = if (_isRushWave) then {
        _multiplier * KFH_rushWaveMultiplier
    } else {
        _multiplier
    };
    private _unitCount = [ceil (_baseCount * _effectiveMultiplier)] call KFH_fnc_scaledEnemyCount;
    private _rushDebt = missionNamespace getVariable ["KFH_rushDebtCount", 0];
    if (_isRushWave && {_rushDebt > 0}) then {
        missionNamespace setVariable ["KFH_rushDebtCount", 0, true];
        [format ["Rush debt paid: %1 left-behind hostiles added to wave %2.", _rushDebt, _newWaveNumber]] call KFH_fnc_log;
    };
    private _rushDebtInterest = 0;
    if (!_isRushWave && {_rushDebt > 0} && {missionNamespace getVariable ["KFH_rushDebtInterestEnabled", true]}) then {
        private _interestRatio = missionNamespace getVariable ["KFH_rushDebtInterestRatio", 0.25];
        private _interestMin = missionNamespace getVariable ["KFH_rushDebtInterestMin", 1];
        private _interestMax = missionNamespace getVariable ["KFH_rushDebtInterestMax", 4];
        _rushDebtInterest = ((ceil (_rushDebt * _interestRatio)) max _interestMin) min _interestMax;
        [format ["Rush debt interest charged: %1 extra hostiles on wave %2, principal remains %3.", _rushDebtInterest, _newWaveNumber, _rushDebt]] call KFH_fnc_log;
    };
    _unitCount = _unitCount + _recycledCount + (if (_isRushWave) then { _rushDebt } else { _rushDebtInterest });
    private _spawnMarkers = [format ["kfh_spawn_%1", _checkpointIndex]] call KFH_fnc_getSpawnMarkers;
    private _gunnerChance = if (_isRushWave) then { KFH_rushGunnerChance } else { KFH_standardGunnerChance };
    private _supplyCarrierChance = if (_isRushWave) then { KFH_rushSupplyCarrierChance } else { 0 };
    private _heavyChance = if (_isRushWave) then { KFH_rushHeavyChance } else { KFH_standardHeavyChance };
    private _checkpointPos = getMarkerPos _checkpointMarker;
    private _playerAnchor = [_checkpointPos] call KFH_fnc_getWavePlayerAnchor;
    private _spawnAnchorPos = if (isNull _playerAnchor) then { _checkpointPos } else { getPosATL _playerAnchor };
    private _moveTargetPos = if (!isNull _playerAnchor) then {
        getPosATL _playerAnchor
    } else {
        _checkpointPos
    };
    private _spawnContext = format [
        "cp%1-wave%2-%3",
        _checkpointIndex,
        _newWaveNumber,
        if (_isRushWave) then { "rush" } else { "normal" }
    ];
    private _spawnedUnits = [
        _spawnAnchorPos,
        _spawnMarkers,
        _unitCount,
        _gunnerChance,
        _supplyCarrierChance,
        _heavyChance,
        _moveTargetPos,
        _spawnContext,
        _checkpointPos,
        _playerAnchor
    ] call KFH_fnc_spawnGroupWave;
    [format [
        "Checkpoint wave spawn context=%1 checkpoint=%2 requested=%3 spawned=%4 recycled=%5 playerAnchor=%6 spawnAnchor=%7 moveTarget=%8.",
        _spawnContext,
        _checkpointIndex,
        _unitCount,
        count _spawnedUnits,
        _recycledCount,
        if (isNull _playerAnchor) then {"<none>"} else {name _playerAnchor},
        mapGridPosition _spawnAnchorPos,
        mapGridPosition _moveTargetPos
    ]] call KFH_fnc_log;
    private _activeEnemies = missionNamespace getVariable ["KFH_activeEnemies", []];

    _activeEnemies append _spawnedUnits;
    missionNamespace setVariable ["KFH_activeEnemies", _activeEnemies];

    if (_setAsCurrentObjective) then {
        missionNamespace setVariable ["KFH_currentObjectiveEnemies", _spawnedUnits];
        missionNamespace setVariable ["KFH_currentObjectiveMarker", _checkpointMarker, true];
        missionNamespace setVariable ["KFH_currentWaveHostileCount", count _spawnedUnits, true];
        [_spawnedUnits, _checkpointIndex] call KFH_fnc_promoteObjectiveCarrier;
    } else {
        if (_checkpointIndex isEqualTo (missionNamespace getVariable ["KFH_currentCheckpoint", 1])) then {
            private _objectiveEnemies = missionNamespace getVariable ["KFH_currentObjectiveEnemies", []];
            _objectiveEnemies append _spawnedUnits;
            missionNamespace setVariable ["KFH_currentObjectiveEnemies", _objectiveEnemies];
            missionNamespace setVariable ["KFH_currentWaveHostileCount", count _objectiveEnemies, true];
        };
    };

    private _special = [_checkpointIndex, _checkpointMarker, _isRushWave] call KFH_fnc_spawnCheckpointSpecialInfected;
    private _specialRole = "";
    if !(isNull _special) then {
        _specialRole = _special getVariable ["KFH_enemyRole", ""];
        _spawnedUnits pushBack _special;
        _activeEnemies = missionNamespace getVariable ["KFH_activeEnemies", []];
        private _objectiveEnemies = missionNamespace getVariable ["KFH_currentObjectiveEnemies", []];
        missionNamespace setVariable ["KFH_currentWaveHostileCount", count _objectiveEnemies, true];
    };

    private _bloater = [_checkpointIndex, _checkpointMarker, _specialRole] call KFH_fnc_spawnCheckpointBloaterInfected;
    if !(isNull _bloater) then {
        _spawnedUnits pushBack _bloater;
        _activeEnemies = missionNamespace getVariable ["KFH_activeEnemies", []];
        private _objectiveEnemies = missionNamespace getVariable ["KFH_currentObjectiveEnemies", []];
        missionNamespace setVariable ["KFH_currentWaveHostileCount", count _objectiveEnemies, true];
    };

    private _alreadySpecialRoles = [];
    if !(_specialRole isEqualTo "") then { _alreadySpecialRoles pushBackUnique _specialRole; };
    if !(isNull _bloater) then { _alreadySpecialRoles pushBackUnique "bloater"; };
    private _rampSpecials = [_checkpointIndex, _checkpointMarker, _newWaveNumber, _alreadySpecialRoles] call KFH_fnc_spawnCheckpointRampSpecialInfected;
    if ((count _rampSpecials) > 0) then {
        _spawnedUnits append _rampSpecials;
        _activeEnemies = missionNamespace getVariable ["KFH_activeEnemies", []];
        private _objectiveEnemies = missionNamespace getVariable ["KFH_currentObjectiveEnemies", []];
        missionNamespace setVariable ["KFH_currentWaveHostileCount", count _objectiveEnemies, true];
    };

    if (_isRushWave) then {
        missionNamespace setVariable ["KFH_rushActive", true, true];
        missionNamespace setVariable ["KFH_rushCheckpoint", _checkpointIndex, true];
        missionNamespace setVariable ["KFH_rushWaveNumber", _newWaveNumber, true];
        ["KFH_rushActive", true] call KFH_fnc_setState;
    };

    ["KFH_currentWave", _newWaveNumber] call KFH_fnc_setState;
    missionNamespace setVariable ["KFH_currentWaveStartedAt", time, true];
    missionNamespace setVariable ["KFH_currentWaveCheckpoint", _checkpointIndex, true];
    if !(missionNamespace getVariable ["KFH_currentWaveHostileCount", -1] > 0) then {
        missionNamespace setVariable ["KFH_currentWaveHostileCount", count _spawnedUnits, true];
    };
    missionNamespace setVariable ["KFH_objectiveClearCooldownAppliedWave", -1, true];
    ["KFH_objectiveHostiles", count _spawnedUnits] call KFH_fnc_setState;
    ["KFH_totalHostiles", count _activeEnemies] call KFH_fnc_setState;
    if (_isRushWave) then {
        private _expectedGunners = ((round (_unitCount * KFH_rushGunnerChance)) max 1);
        ["rush_wave_deployed", [_newWaveNumber, _checkpointIndex, count _spawnedUnits, _expectedGunners]] call KFH_fnc_notifyAllKey;
        [] remoteExecCall ["KFH_fnc_playFinaleRushWarning", 0];
    } else {
        [format ["Wave %1 deployed at checkpoint %2 (%3 hostiles).", _newWaveNumber, _checkpointIndex, count _spawnedUnits]] call KFH_fnc_log;
        [] remoteExecCall ["KFH_fnc_playWaveStartWarning", 0];
    };
    private _waveEventText = if (([] call KFH_fnc_getAnnouncementLanguageIndex) isEqualTo 0) then {
        format ["Wave %1 が checkpoint %2 に到達、敵 %3 体デス。", _newWaveNumber, _checkpointIndex, count _spawnedUnits]
    } else {
        format ["Wave %1 reached checkpoint %2 with %3 hostile(s).", _newWaveNumber, _checkpointIndex, count _spawnedUnits]
    };
    [_waveEventText, "WAVE"] call KFH_fnc_appendRunEvent;
    [format ["Spawned hostiles near checkpoint %1 at %2.", _checkpointIndex, mapGridPosition (getMarkerPos _checkpointMarker)]] call KFH_fnc_log;

    _spawnedUnits
};

KFH_fnc_spawnExtractWave = {
    private _extractMarker = missionNamespace getVariable ["KFH_extractMarker", ""];

    if (_extractMarker isEqualTo "") exitWith { [] };

    private _extractPos = getMarkerPos _extractMarker;
    private _checkpointMarkers = missionNamespace getVariable ["KFH_checkpointMarkers", []];
    private _spawnCenter = _extractPos;
    private _spawnMarkers = ["kfh_spawn_extract"] call KFH_fnc_getSpawnMarkers;
    private _spawnAtLz = missionNamespace getVariable ["KFH_extractWaveSpawnAtLz", true];
    if (
        !_spawnAtLz &&
        missionNamespace getVariable ["KFH_extractSpawnFromFinalCheckpoint", true] &&
        {(count _checkpointMarkers) > 0}
    ) then {
        _spawnCenter = getMarkerPos (_checkpointMarkers select ((count _checkpointMarkers) - 1));
        _spawnMarkers = [];
    };

    private _extractBaseCount = missionNamespace getVariable ["KFH_extractWaveBaseCount", KFH_extractBaseWaveCount];
    private _unitCount = [ceil (_extractBaseCount * ([] call KFH_fnc_getPressureSpawnMultiplier))] call KFH_fnc_scaledEnemyCount;
    private _rushDebt = missionNamespace getVariable ["KFH_rushDebtCount", 0];
    if (_rushDebt > 0) then {
        missionNamespace setVariable ["KFH_rushDebtCount", 0, true];
        [format ["Rush debt paid: %1 left-behind hostiles added to extraction finale wave.", _rushDebt]] call KFH_fnc_log;
    };
    _unitCount = _unitCount + _rushDebt;
    private _spawnedUnits = [
        _spawnCenter,
        _spawnMarkers,
        _unitCount,
        KFH_extractGunnerChance,
        KFH_extractSupplyCarrierChance,
        KFH_extractHeavyChance,
        _extractPos,
        "extract-wave",
        _extractPos,
        objNull,
        missionNamespace getVariable ["KFH_extractWaveIgnoreActiveCap", true]
    ] call KFH_fnc_spawnGroupWave;
    private _activeEnemies = missionNamespace getVariable ["KFH_activeEnemies", []];
    private _waveNumber = missionNamespace getVariable ["KFH_currentWave", 0];

    _activeEnemies append _spawnedUnits;
    missionNamespace setVariable ["KFH_activeEnemies", _activeEnemies];
    private _objectiveEnemies = missionNamespace getVariable ["KFH_currentObjectiveEnemies", []];
    _objectiveEnemies append _spawnedUnits;
    missionNamespace setVariable ["KFH_currentObjectiveEnemies", _objectiveEnemies];
    missionNamespace setVariable ["KFH_currentObjectiveMarker", _extractMarker, true];
    {
        if (alive _x) then {
            (group _x) move _extractPos;
            _x doMove _extractPos;
            _x setVariable ["KFH_nextCommandMoveAt", 0];
            _x setVariable ["KFH_nextForcedDestinationAt", 0];
        };
    } forEach _spawnedUnits;

    ["KFH_currentWave", _waveNumber + 1] call KFH_fnc_setState;
    missionNamespace setVariable ["KFH_currentWaveStartedAt", time, true];
    missionNamespace setVariable ["KFH_currentWaveHostileCount", count _objectiveEnemies, true];
    missionNamespace setVariable ["KFH_objectiveClearCooldownAppliedWave", -1, true];
    ["KFH_objectiveHostiles", count _objectiveEnemies] call KFH_fnc_setState;
    ["KFH_totalHostiles", count _activeEnemies] call KFH_fnc_setState;
    ["retreat_wave_deployed", [count _spawnedUnits]] call KFH_fnc_notifyAllKey;
    [] remoteExecCall ["KFH_fnc_playFinaleRushWarning", 0];
    private _extractWaveEventText = if (([] call KFH_fnc_getAnnouncementLanguageIndex) isEqualTo 0) then {
        format ["帰還 wave %1 が final checkpoint 方向から LZ へ再投入、敵 %2 体デス。", _waveNumber + 1, count _spawnedUnits]
    } else {
        format ["Return wave %1 redeployed from the final checkpoint toward the LZ with %2 hostile(s).", _waveNumber + 1, count _spawnedUnits]
    };
    [_extractWaveEventText, "WAVE"] call KFH_fnc_appendRunEvent;
    [format ["Extraction retreat wave spawned at %1 and ordered to LZ %2 (%3 hostiles).", mapGridPosition _spawnCenter, mapGridPosition _extractPos, count _spawnedUnits]] call KFH_fnc_log;

    _spawnedUnits
};

KFH_fnc_onCheckpointSecured = {
    params ["_checkpointIndex", "_checkpointMarker", "_pressure"];

    private _checkpointPos = getMarkerPos _checkpointMarker;
    private _totalCheckpoints = missionNamespace getVariable ["KFH_totalCheckpoints", _checkpointIndex];
    private _securedStates = missionNamespace getVariable ["KFH_checkpointSecuredStates", []];

    {
        [_x] call KFH_fnc_updateSavedLoadout;
    } forEach ([] call KFH_fnc_getHumanPlayers);

    if ((_checkpointIndex - 1) < (count _securedStates)) then {
        _securedStates set [_checkpointIndex - 1, true];
        missionNamespace setVariable ["KFH_checkpointSecuredStates", _securedStates, true];
    };
    missionNamespace setVariable ["KFH_runLastSecuredCheckpoint", _checkpointIndex, true];
    [_checkpointIndex] call KFH_fnc_applyCheckpointTimeProgression;
    private _secureEventText = if (([] call KFH_fnc_getAnnouncementLanguageIndex) isEqualTo 0) then {
        format [
            "Checkpoint %1 を確保したデス。イベント: %2。",
            _checkpointIndex,
            [_checkpointIndex] call KFH_fnc_getCheckpointEventName
        ]
    } else {
        format [
            "Checkpoint %1 secured. Event: %2.",
            _checkpointIndex,
            [_checkpointIndex] call KFH_fnc_getCheckpointEventName
        ]
    };
    [_secureEventText, "CHECKPOINT"] call KFH_fnc_appendRunEvent;

    private _skippedObjectiveEnemies = (missionNamespace getVariable ["KFH_currentObjectiveEnemies", []]) select {
        alive _x && {!([_x] call KFH_fnc_isJuggernautEnemy)}
    };
    if ((count _skippedObjectiveEnemies) > 0) then {
        private _keepAliveDistance = missionNamespace getVariable ["KFH_checkpointSecureKeepAliveDistance", 320];
        private _keptInWorld = _skippedObjectiveEnemies select {
            ([_x] call KFH_fnc_isUnitVisibleToHumans) ||
            {([getPosATL _x] call KFH_fnc_getNearestHumanDistance) <= _keepAliveDistance}
        };
        private _debtEnemies = _skippedObjectiveEnemies - _keptInWorld;

        [count _debtEnemies, format ["checkpoint %1 secured with offscreen hostiles bypassed", _checkpointIndex]] call KFH_fnc_addRushDebt;
        if ((count _debtEnemies) > 0) then {
            ["wave_debt_accrued_warning", [count _debtEnemies]] call KFH_fnc_notifyAllKey;
        };

        private _activeEnemies = missionNamespace getVariable ["KFH_activeEnemies", []];
        _activeEnemies = _activeEnemies - _debtEnemies;
        missionNamespace setVariable ["KFH_activeEnemies", _activeEnemies];
        ["KFH_totalHostiles", count _activeEnemies] call KFH_fnc_setState;

        {
            private _groupRef = group _x;
            deleteVehicle _x;
            if (!isNull _groupRef && {({alive _x} count units _groupRef) isEqualTo 0}) then {
                deleteGroup _groupRef;
            };
        } forEach _debtEnemies;

        {
            _x setVariable ["KFH_leftBehindAfterCheckpoint", true, true];
            _x setVariable ["KFH_staleSince", -1];
            _x setVariable ["KFH_recyclePendingLogged", false];
            private _target = [getPosATL _x] call KFH_fnc_findClosestCombatPlayer;
            [_x, _target, if (isNull _target) then { _checkpointPos } else { getPosATL _target }] call KFH_fnc_driveEnemyTowardTarget;
        } forEach _keptInWorld;
        [format ["Checkpoint %1 secured with %2 visible/near hostiles kept alive and %3 offscreen hostiles converted to rush debt.", _checkpointIndex, count _keptInWorld, count _debtEnemies]] call KFH_fnc_log;
    };

    if (_checkpointIndex isEqualTo 1) then {
        ["firstCheckpoint", _checkpointIndex] call KFH_fnc_playStoryBeatOnce;
    };
    if (_checkpointIndex >= (ceil (_totalCheckpoints * 0.6))) then {
        ["baseLost", _checkpointIndex] call KFH_fnc_playStoryBeatOnce;
    };

    ["checkpoint_cleared_reason", [_checkpointIndex]] call KFH_fnc_autoRevivePlayers;
    [_checkpointPos, format ["Checkpoint %1", _checkpointIndex]] call KFH_fnc_updateRespawnAnchor;
    ["TaskSucceeded", [format ["Checkpoint %1 secured", _checkpointIndex], "Route stabilized. Resupply incoming."]] remoteExecCall ["BIS_fnc_showNotification", 0];
    ["A3\Sounds_F\sfx\blip1.wss", 2.1, 0.62] remoteExecCall ["KFH_fnc_playUiCue", 0];

    [KFH_pressureCheckpointRelief, format ["Checkpoint %1 secured", _checkpointIndex]] call KFH_fnc_reducePressure;
    private _secureCooldown = [_checkpointIndex] call KFH_fnc_getCheckpointSecureCooldown;
    [_secureCooldown, format ["checkpoint %1 secured", _checkpointIndex]] call KFH_fnc_applyWaveCooldown;
    missionNamespace setVariable ["KFH_currentObjectiveEnemies", []];
    ["KFH_objectiveHostiles", 0] call KFH_fnc_setState;
    ["KFH_totalHostiles", count ([] call KFH_fnc_pruneActiveEnemies)] call KFH_fnc_setState;
    [] call KFH_fnc_refreshStrategicState;

    if (_checkpointIndex < _totalCheckpoints) then {
        [_checkpointMarker, _checkpointIndex] call KFH_fnc_upgradeCheckpointSupplyReward;
        private _supplyStates = missionNamespace getVariable ["KFH_checkpointSupplyStates", []];
        if ((_checkpointIndex - 1) < (count _supplyStates)) then {
            _supplyStates set [_checkpointIndex - 1, true];
            missionNamespace setVariable ["KFH_checkpointSupplyStates", _supplyStates, true];
        };
        [] call KFH_fnc_refreshStrategicState;
        [_checkpointIndex] call KFH_fnc_spawnBranchRewardCache;
        if ((random 1) < KFH_pressureReliefEventChance) then {
            [KFH_pressureReliefEventAmount, format ["Checkpoint %1 side relief event", _checkpointIndex]] call KFH_fnc_reducePressure;
            ["checkpoint_side_relief", [_checkpointIndex]] call KFH_fnc_notifyAllKey;
        };
        ["checkpoint_reward_cache", [
            _checkpointIndex,
            [_checkpointIndex] call KFH_fnc_getCheckpointRewardTierName
        ]] call KFH_fnc_notifyAllKey;
    } else {
        private _supportObjects = [_checkpointMarker, _checkpointIndex] call KFH_fnc_spawnCheckpointSupport;
        {
            if !(isNull _x) then {
                _x setDamage 0;
            };
        } forEach _supportObjects;
        [_checkpointMarker] call KFH_fnc_spawnOptionalArsenalBase;
        [KFH_finalArsenalCooldownSeconds, "arsenal secured"] call KFH_fnc_applyWaveCooldown;
        ["finalCheckpoint", _checkpointIndex] call KFH_fnc_playStoryBeatOnce;
        ["final_checkpoint_arsenal_marked"] call KFH_fnc_notifyAllKey;
    };
};

KFH_fnc_completeMission = {
    params ["_success", "_message"];

    if (missionNamespace getVariable ["KFH_missionEnding", false]) exitWith {};
    missionNamespace setVariable ["KFH_missionEnding", true, true];

    private _phase = if (_success) then { "complete" } else { "failed" };
    ["KFH_phase", _phase] call KFH_fnc_setState;
    [_message] call KFH_fnc_notifyAll;
    private _endEventText = if (([] call KFH_fnc_getAnnouncementLanguageIndex) isEqualTo 0) then {
        format ["ミッション終了: %1", _message]
    } else {
        format ["Mission ended: %1", _message]
    };
    [_endEventText, "END"] call KFH_fnc_appendRunEvent;
    [] call KFH_fnc_publishRunSummary;

    [_success] spawn {
        params ["_success"];
        sleep KFH_missionEndSyncDelay;

        if (_success) then {
            ["end1", true, 5] remoteExecCall ["BIS_fnc_endMission", 0];
        } else {
            ["loser", true, 5] remoteExecCall ["BIS_fnc_endMission", 0];
        };
    };
};

KFH_fnc_waitForInitialCombatReady = {
    private _deadline = -1;
    private _ready = false;
    private _hasHumans = false;
    private _humanCount = 0;
    private _readyCount = 0;

    waitUntil {
        sleep 0.5;
        if (
            (missionNamespace getVariable ["KFH_initialWaveSpawnStarted", false]) ||
            {(missionNamespace getVariable ["KFH_currentWave", 0]) > 0}
        ) exitWith {
            _ready = false;
            true
        };

        private _humans = [] call KFH_fnc_getHumanReferenceUnits;
        _humanCount = count _humans;
        _hasHumans = _humanCount > 0;
        _readyCount = count (_humans select {
            alive _x && {_x getVariable ["KFH_clientReadyForInitialWave", false]}
        });
        _ready = _readyCount > 0;

        if (_hasHumans && {_deadline < 0}) then {
            _deadline = diag_tickTime + KFH_initialWaveReadyTimeout;
            missionNamespace setVariable ["KFH_initialWaveFirstHumanSeenAt", diag_tickTime, true];
            [format ["Initial wave wait detected players; timeout window started (%1 humans).", _humanCount]] call KFH_fnc_log;
        };

        _ready || {_deadline >= 0 && {diag_tickTime >= _deadline}}
    };

    sleep KFH_initialWaveReadyBuffer;

    if (
        (missionNamespace getVariable ["KFH_initialWaveSpawnStarted", false]) ||
        {(missionNamespace getVariable ["KFH_currentWave", 0]) > 0}
    ) exitWith {};

    if (_ready) exitWith {
        ["ready wait thread", _readyCount, _humanCount] call KFH_fnc_releaseInitialWave;
    };

    ["real-time timeout wait thread", _readyCount, _humanCount] call KFH_fnc_releaseInitialWave;
};

KFH_fnc_releaseInitialWave = {
    params [["_reason", "unknown"], ["_readyCount", 0], ["_humanCount", 0]];

    if (!isServer) exitWith { false };
    if (missionNamespace getVariable ["KFH_initialWaveSpawnStarted", false]) exitWith { false };
    if ((missionNamespace getVariable ["KFH_currentWave", 0]) > 0) exitWith { false };

    missionNamespace setVariable ["KFH_initialWaveSpawnStarted", true, true];
    missionNamespace setVariable ["KFH_initialCombatReleased", true, true];

    if ((_reason find "ready") >= 0) then {
        [format ["Initial wave released after player starter loadout readiness (%1/%2 ready, reason=%3).", _readyCount, _humanCount, _reason]] call KFH_fnc_log;
    } else {
        [format ["Initial wave readiness timed out in real time; releasing wave after safety buffer (%1/%2 ready, reason=%3).", _readyCount, _humanCount, _reason]] call KFH_fnc_log;
    };

    if !(missionNamespace getVariable ["KFH_waveCleanupWarningAnnounced", false]) then {
        missionNamespace setVariable ["KFH_waveCleanupWarningAnnounced", true, true];
        ["wave_cleanup_warning", [], "RUN"] call KFH_fnc_appendRunEventKey;
        ["wave_cleanup_warning"] call KFH_fnc_notifyAllKey;
        ["melee_controls_tip", [], "RUN"] call KFH_fnc_appendRunEventKey;
        ["melee_controls_tip"] call KFH_fnc_notifyAllKey;
    };

    [1, 1, true] call KFH_fnc_spawnCheckpointWave;
    true
};

KFH_fnc_pollInitialWaveRelease = {
    if (!isServer) exitWith {};
    if (missionNamespace getVariable ["KFH_initialWaveSpawnStarted", false]) exitWith {};
    if ((missionNamespace getVariable ["KFH_currentWave", 0]) > 0) exitWith {};
    if ((missionNamespace getVariable ["KFH_phase", "boot"]) isNotEqualTo "assault") exitWith {};

    private _humans = [] call KFH_fnc_getHumanReferenceUnits;
    private _humanCount = count _humans;
    if (_humanCount <= 0) exitWith {};

    private _readyCount = count (_humans select {
        alive _x && {_x getVariable ["KFH_clientReadyForInitialWave", false]}
    });

    if (_readyCount > 0) exitWith {
        ["ready watchdog", _readyCount, _humanCount] call KFH_fnc_releaseInitialWave;
    };

    private _firstSeen = missionNamespace getVariable ["KFH_initialWaveFirstHumanSeenAt", -1];
    if (_firstSeen < 0) then {
        _firstSeen = diag_tickTime;
        missionNamespace setVariable ["KFH_initialWaveFirstHumanSeenAt", _firstSeen, true];
        [format ["Initial wave watchdog detected players; timeout window started (%1 humans).", _humanCount]] call KFH_fnc_log;
    };

    if ((diag_tickTime - _firstSeen) >= KFH_initialWaveReadyTimeout) then {
        ["real-time timeout watchdog", _readyCount, _humanCount] call KFH_fnc_releaseInitialWave;
    };
};

