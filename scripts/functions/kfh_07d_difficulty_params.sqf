KFH_fnc_applyEnemyAccuracyPreset = {
    private _value = ["KFH_EnemyAccuracy", missionNamespace getVariable ["KFH_enemyAccuracyParamDefault", 1]] call BIS_fnc_getParamValue;
    private _names = missionNamespace getVariable ["KFH_enemyAccuracyNames", ["veryLow", "low", "normal", "high", "veryHigh"]];
    private _index = (_value max 0) min ((count _names) - 1);
    private _profile = switch (_index) do {
        case 0: { [0.02, 0.24, 0.10] };
        case 2: { [0.06, 0.14, 0.18] };
        case 3: { [0.09, 0.11, 0.22] };
        case 4: { [0.13, 0.08, 0.28] };
        default { [0.04, 0.18, 0.14] };
    };
    _profile params ["_accuracy", "_shake", "_speed"];

    missionNamespace setVariable ["KFH_enemyAccuracyPreset", _names select _index, true];
    missionNamespace setVariable ["KFH_enemyAimingAccuracy", _accuracy, true];
    missionNamespace setVariable ["KFH_enemyAimingShake", _shake, true];
    missionNamespace setVariable ["KFH_enemyAimingSpeed", _speed, true];
    [format ["Enemy fire accuracy preset applied: %1 accuracy=%2 shake=%3 speed=%4.", _names select _index, _accuracy, _shake, _speed]] call KFH_fnc_log;
};

KFH_fnc_applyEnvironmentParams = {
    private _hour = ["KFH_TimeOfDay", missionNamespace getVariable ["KFH_timeOfDayParamDefault", 6]] call BIS_fnc_getParamValue;
    private _timeMultiplier = ["KFH_TimeMultiplier", missionNamespace getVariable ["KFH_timeMultiplierParamDefault", 1]] call BIS_fnc_getParamValue;
    private _cloud = (["KFH_CloudCover", missionNamespace getVariable ["KFH_cloudCoverParamDefault", 18]] call BIS_fnc_getParamValue) / 100;
    private _fog = (["KFH_FogDensity", missionNamespace getVariable ["KFH_fogDensityParamDefault", 0]] call BIS_fnc_getParamValue) / 100;
    private _rain = (["KFH_RainDensity", missionNamespace getVariable ["KFH_rainDensityParamDefault", 0]] call BIS_fnc_getParamValue) / 100;
    private _wind = ["KFH_Wind", missionNamespace getVariable ["KFH_windParamDefault", 0]] call BIS_fnc_getParamValue;
    private _windVector = switch (_wind) do {
        case 1: { [1.5, 0.5, true] };
        case 2: { [4, 1.5, true] };
        case 3: { [7, 3, true] };
        default { [0, 0, true] };
    };
    private _overcast = if (_rain > 0) then { _cloud max 0.5 } else { _cloud };

    setDate [2035, 7, 16, _hour, 20];
    setTimeMultiplier _timeMultiplier;
    0 setFog _fog;
    0 setRain _rain;
    0 setOvercast _overcast;
    setWind _windVector;
    forceWeatherChange;
    [format ["Environment params applied: hour=%1 timeMultiplier=%2 cloud=%3 fog=%4 rain=%5 wind=%6.", _hour, _timeMultiplier, _overcast, _fog, _rain, _wind]] call KFH_fnc_log;
};

KFH_fnc_applyLocalVisibilityParams = {
    private _grass = ["KFH_GrassVisibility", missionNamespace getVariable ["KFH_grassVisibilityParamDefault", 2]] call BIS_fnc_getParamValue;
    private _terrainGrid = switch (_grass) do {
        case 0: { 50 };
        case 1: { 25 };
        case 3: { 6.25 };
        default { 12.5 };
    };

    setTerrainGrid _terrainGrid;
    [format ["Local visibility params applied: grass=%1 terrainGrid=%2.", _grass, _terrainGrid]] call KFH_fnc_log;
};

KFH_fnc_applyExtractionAndAreaParams = {
    private _extractionType = ["KFH_ExtractionType", missionNamespace getVariable ["KFH_extractionTypeParamDefault", 0]] call BIS_fnc_getParamValue;
    private _extractionDistance = ["KFH_ExtractionMaxDistance", missionNamespace getVariable ["KFH_extractionMaxDistanceParamDefault", 0]] call BIS_fnc_getParamValue;
    if (_extractionDistance <= 0) then {
        _extractionDistance = selectRandom [650, 950, 1250, 1600];
    };

    KFH_extractionHeliSpawnDistance = _extractionDistance;
    KFH_extractionHeliEvacDistance = (_extractionDistance + 250) max 900;
    KFH_extractionFinaleRushEnabled = _extractionType isEqualTo 0;
    missionNamespace setVariable ["KFH_extractionHeliSpawnDistance", KFH_extractionHeliSpawnDistance, true];
    missionNamespace setVariable ["KFH_extractionHeliEvacDistance", KFH_extractionHeliEvacDistance, true];
    missionNamespace setVariable ["KFH_extractionFinaleRushEnabled", KFH_extractionFinaleRushEnabled, true];

    KFH_startPatrolVehicleMax = ["KFH_StartPatrolVehicleMax", missionNamespace getVariable ["KFH_startPatrolVehicleMaxParamDefault", KFH_startPatrolVehicleMax]] call BIS_fnc_getParamValue;
    KFH_checkpointMobilityVehicleCount = ["KFH_CheckpointVehicleCount", missionNamespace getVariable ["KFH_checkpointVehicleCountParamDefault", KFH_checkpointMobilityVehicleCount]] call BIS_fnc_getParamValue;
    KFH_checkpointMobilityVehicleCountByScale = [];
    KFH_checkpointMobilityVehicleLateMax = KFH_checkpointMobilityVehicleCount;
    KFH_finalArsenalCooldownSeconds = ["KFH_FinalArsenalCooldown", missionNamespace getVariable ["KFH_finalArsenalCooldownParamDefault", KFH_finalArsenalCooldownSeconds]] call BIS_fnc_getParamValue;

    [format [
        "Extraction/area params applied: type=%1 extractDistance=%2 motorPool=%3 checkpointVehicles=%4 arsenalCooldown=%5.",
        _extractionType,
        _extractionDistance,
        KFH_startPatrolVehicleMax,
        KFH_checkpointMobilityVehicleCount,
        KFH_finalArsenalCooldownSeconds
    ]] call KFH_fnc_log;
};

KFH_fnc_applyTrafficAndSpawnParams = {
    private _civilianTrafficScale = (["KFH_CivilianTrafficFrequency", missionNamespace getVariable ["KFH_civilianTrafficFrequencyParamDefault", 100]] call BIS_fnc_getParamValue) / 100;
    private _enemyTrafficScale = (["KFH_EnemyTrafficFrequency", missionNamespace getVariable ["KFH_enemyTrafficFrequencyParamDefault", 100]] call BIS_fnc_getParamValue) / 100;
    private _roadblockScale = (["KFH_RoadblockCount", missionNamespace getVariable ["KFH_roadblockCountParamDefault", 100]] call BIS_fnc_getParamValue) / 100;
    private _spawnDistanceMode = ["KFH_EnemySpawnDistance", missionNamespace getVariable ["KFH_enemySpawnDistanceParamDefault", 0]] call BIS_fnc_getParamValue;
    private _villagePatrolScale = (["KFH_VillagePatrolSpawns", missionNamespace getVariable ["KFH_villagePatrolSpawnsParamDefault", 100]] call BIS_fnc_getParamValue) / 100;
    private _civilianSuicideBombChance = (["KFH_CivilianSuicideBombFrequency", missionNamespace getVariable ["KFH_civilianSuicideBombFrequencyParamDefault", 8]] call BIS_fnc_getParamValue) / 100;

    KFH_ambientTrafficEnabled = _civilianTrafficScale > 0;
    KFH_ambientTrafficChance = (KFH_ambientTrafficChance * _civilianTrafficScale) min 1;
    KFH_ambientTrafficVehiclesPerSegment = ceil (KFH_ambientTrafficVehiclesPerSegment * _civilianTrafficScale);
    missionNamespace setVariable ["KFH_envTrafficMaxCivilianGroups", ceil ((missionNamespace getVariable ["KFH_envTrafficMaxCivilianGroups", KFH_envTrafficMaxCivilianGroups]) * _civilianTrafficScale), true];
    missionNamespace setVariable ["KFH_envTrafficCivilianChance", ((missionNamespace getVariable ["KFH_envTrafficCivilianChance", KFH_envTrafficCivilianChance]) * _civilianTrafficScale) min 1, true];
    missionNamespace setVariable ["KFH_outbreakCivilianChance", ((missionNamespace getVariable ["KFH_outbreakCivilianChance", KFH_outbreakCivilianChance]) * _civilianTrafficScale) min 1, true];
    missionNamespace setVariable ["KFH_envSceneCivilianPedestrianMaxEarly", ceil ((missionNamespace getVariable ["KFH_envSceneCivilianPedestrianMaxEarly", KFH_envSceneCivilianPedestrianMaxEarly]) * _civilianTrafficScale), true];
    missionNamespace setVariable ["KFH_envSceneCivilianVehicleMaxEarly", ceil ((missionNamespace getVariable ["KFH_envSceneCivilianVehicleMaxEarly", KFH_envSceneCivilianVehicleMaxEarly]) * _civilianTrafficScale), true];

    missionNamespace setVariable ["KFH_envTrafficMaxMilitaryGroups", ceil ((missionNamespace getVariable ["KFH_envTrafficMaxMilitaryGroups", KFH_envTrafficMaxMilitaryGroups]) * _enemyTrafficScale), true];
    missionNamespace setVariable ["KFH_envTrafficMilitaryChance", ((missionNamespace getVariable ["KFH_envTrafficMilitaryChance", KFH_envTrafficMilitaryChance]) * _enemyTrafficScale) min 1, true];
    missionNamespace setVariable ["KFH_envTrafficMilitaryArmedChance", ((missionNamespace getVariable ["KFH_envTrafficMilitaryArmedChance", KFH_envTrafficMilitaryArmedChance]) * _enemyTrafficScale) min 1, true];
    missionNamespace setVariable ["KFH_envTrafficMilitaryArmorShare", ((missionNamespace getVariable ["KFH_envTrafficMilitaryArmorShare", KFH_envTrafficMilitaryArmorShare]) * _enemyTrafficScale) min 1, true];
    missionNamespace setVariable ["KFH_envTrafficMilitaryMortarShare", ((missionNamespace getVariable ["KFH_envTrafficMilitaryMortarShare", KFH_envTrafficMilitaryMortarShare]) * _enemyTrafficScale) min 1, true];

    if (_roadblockScale <= 0) then {
        KFH_routeRoadblockOffsets = [];
        KFH_checkpointDressingSets = [];
    } else {
        if (_roadblockScale < 1) then {
            KFH_routeRoadblockOffsets = KFH_routeRoadblockOffsets select [0, ceil ((count KFH_routeRoadblockOffsets) * _roadblockScale)];
            KFH_checkpointDressingSets = KFH_checkpointDressingSets select [0, ceil ((count KFH_checkpointDressingSets) * _roadblockScale)];
        };
    };

    switch (_spawnDistanceMode) do {
        case 1: {
            KFH_spawnMinDistance = 30;
            KFH_spawnMaxDistance = 50;
            KFH_spawnAheadMinDistance = 100;
            KFH_spawnAheadMaxDistance = 160;
        };
        case 2: {
            KFH_spawnMinDistance = 50;
            KFH_spawnMaxDistance = 80;
            KFH_spawnAheadMinDistance = 140;
            KFH_spawnAheadMaxDistance = 220;
        };
        default {};
    };

    missionNamespace setVariable ["KFH_envMilitaryFootPatrolChance", ((missionNamespace getVariable ["KFH_envMilitaryFootPatrolChance", KFH_envMilitaryFootPatrolChance]) * _villagePatrolScale) min 1, true];
    missionNamespace setVariable ["KFH_envMilitaryFootPatrolMax", ceil ((missionNamespace getVariable ["KFH_envMilitaryFootPatrolMax", KFH_envMilitaryFootPatrolMax]) * _villagePatrolScale), true];
    missionNamespace setVariable ["KFH_envSceneMilitaryMaxLate", ceil ((missionNamespace getVariable ["KFH_envSceneMilitaryMaxLate", KFH_envSceneMilitaryMaxLate]) * _villagePatrolScale), true];
    missionNamespace setVariable ["KFH_envSceneMilitaryPerTickLate", ceil ((missionNamespace getVariable ["KFH_envSceneMilitaryPerTickLate", KFH_envSceneMilitaryPerTickLate]) * _villagePatrolScale), true];
    missionNamespace setVariable ["KFH_civilianKillExplosionChance", _civilianSuicideBombChance, true];

    [format ["Traffic/spawn params applied: civilian=%1 enemyTraffic=%2 roadblocks=%3 spawnDistanceMode=%4 villagePatrols=%5 civilianBombChance=%6.", _civilianTrafficScale, _enemyTrafficScale, _roadblockScale, _spawnDistanceMode, _villagePatrolScale, _civilianSuicideBombChance]] call KFH_fnc_log;
};

KFH_fnc_applyDetailedDifficultyParams = {
    private _playerHealthMultiplier = (["KFH_PlayerHealthMultiplier", missionNamespace getVariable ["KFH_playerHealthMultiplierParamDefault", 100]] call BIS_fnc_getParamValue) / 100;
    private _enemySkillScale = (["KFH_EnemySkill", missionNamespace getVariable ["KFH_enemySkillParamDefault", 100]] call BIS_fnc_getParamValue) / 100;
    private _waveSizeScale = (["KFH_WaveSizeScale", missionNamespace getVariable ["KFH_waveSizeScaleParamDefault", 100]] call BIS_fnc_getParamValue) / 100;
    private _waveIntervalScale = (["KFH_WaveIntervalScale", missionNamespace getVariable ["KFH_waveIntervalScaleParamDefault", 100]] call BIS_fnc_getParamValue) / 100;
    KFH_holdSeconds = ["KFH_CheckpointCaptureSeconds", missionNamespace getVariable ["KFH_holdSecondsParamDefault", KFH_holdSeconds]] call BIS_fnc_getParamValue;
    KFH_holdSeconds = (KFH_holdSeconds max 15) min 180;
    private _specialThreatScale = (["KFH_SpecialThreatScale", missionNamespace getVariable ["KFH_specialThreatScaleParamDefault", 100]] call BIS_fnc_getParamValue) / 100;
    private _pressureScale = (["KFH_PressureScale", missionNamespace getVariable ["KFH_pressureScaleParamDefault", 100]] call BIS_fnc_getParamValue) / 100;
    private _hardCap = ["KFH_EnemyHardCap", missionNamespace getVariable ["KFH_enemyHardCapParamDefault", KFH_activeEnemyHardCap]] call BIS_fnc_getParamValue;
    private _armedScale = (["KFH_ArmedEnemyScale", missionNamespace getVariable ["KFH_armedEnemyScaleParamDefault", 100]] call BIS_fnc_getParamValue) / 100;
    _playerHealthMultiplier = _playerHealthMultiplier max 0.1;
    missionNamespace setVariable ["KFH_playerHealthMultiplier", _playerHealthMultiplier, true];
    missionNamespace setVariable ["KFH_playerDamageTakenScale", 1 / _playerHealthMultiplier, true];

    missionNamespace setVariable [
        "KFH_waveBaseCounts",
        (missionNamespace getVariable ["KFH_waveBaseCounts", KFH_waveBaseCounts]) apply { ceil (_x * _waveSizeScale) }
    ];
    missionNamespace setVariable ["KFH_waveCooldownNormalMinSeconds", round ((missionNamespace getVariable ["KFH_waveCooldownNormalMinSeconds", KFH_waveCooldownNormalMinSeconds]) * _waveIntervalScale)];
    missionNamespace setVariable ["KFH_waveCooldownNormalMaxSeconds", round ((missionNamespace getVariable ["KFH_waveCooldownNormalMaxSeconds", KFH_waveCooldownNormalMaxSeconds]) * _waveIntervalScale)];
    missionNamespace setVariable ["KFH_waveCooldownRushMinSeconds", round ((missionNamespace getVariable ["KFH_waveCooldownRushMinSeconds", KFH_waveCooldownRushMinSeconds]) * _waveIntervalScale)];
    missionNamespace setVariable ["KFH_waveCooldownRushMaxSeconds", round ((missionNamespace getVariable ["KFH_waveCooldownRushMaxSeconds", KFH_waveCooldownRushMaxSeconds]) * _waveIntervalScale)];

    KFH_checkpointSpecialChance = (KFH_checkpointSpecialChance * _specialThreatScale) min 0.98;
    KFH_checkpointSpecialMaxActive = ceil (KFH_checkpointSpecialMaxActive * _specialThreatScale);
    KFH_pressureTickValue = round (KFH_pressureTickValue * _pressureScale);
    KFH_reinforcePressure = round (KFH_reinforcePressure * _pressureScale);
    KFH_extractPressureTickValue = round (KFH_extractPressureTickValue * _pressureScale);
    KFH_extractReinforcePressure = round (KFH_extractReinforcePressure * _pressureScale);
    KFH_activeEnemyHardCap = _hardCap;
    KFH_standardGunnerChance = (KFH_standardGunnerChance * _armedScale) min 0.95;
    KFH_rushGunnerChance = (KFH_rushGunnerChance * _armedScale) min 0.95;
    KFH_standardHeavyChance = (KFH_standardHeavyChance * _armedScale) min 0.95;
    KFH_rushHeavyChance = (KFH_rushHeavyChance * _armedScale) min 0.95;
    missionNamespace setVariable ["KFH_enemyAimingAccuracy", ((missionNamespace getVariable ["KFH_enemyAimingAccuracy", 0.04]) * _enemySkillScale) min 0.95, true];
    missionNamespace setVariable ["KFH_enemyAimingShake", ((missionNamespace getVariable ["KFH_enemyAimingShake", 0.18]) / _enemySkillScale) max 0.02, true];
    missionNamespace setVariable ["KFH_enemyAimingSpeed", ((missionNamespace getVariable ["KFH_enemyAimingSpeed", 0.14]) * _enemySkillScale) min 0.95, true];
    missionNamespace setVariable ["KFH_envMilitarySkillBase", ((missionNamespace getVariable ["KFH_envMilitarySkillBase", KFH_envMilitarySkillBase]) * _enemySkillScale) min 0.95, true];
    missionNamespace setVariable ["KFH_envMilitarySkillRandom", ((missionNamespace getVariable ["KFH_envMilitarySkillRandom", KFH_envMilitarySkillRandom]) * _enemySkillScale) min 0.95, true];
    missionNamespace setVariable ["KFH_envMilitaryAimingAccuracy", ((missionNamespace getVariable ["KFH_envMilitaryAimingAccuracy", KFH_envMilitaryAimingAccuracy]) * _enemySkillScale) min 0.95, true];
    missionNamespace setVariable ["KFH_envMilitaryAimingShake", ((missionNamespace getVariable ["KFH_envMilitaryAimingShake", KFH_envMilitaryAimingShake]) / _enemySkillScale) max 0.02, true];
    missionNamespace setVariable ["KFH_envMilitaryAimingSpeed", ((missionNamespace getVariable ["KFH_envMilitaryAimingSpeed", KFH_envMilitaryAimingSpeed]) * _enemySkillScale) min 0.95, true];
    KFH_vehicleThreatEnabled = (["KFH_VehicleThreats", missionNamespace getVariable ["KFH_vehicleThreatParamDefault", 1]] call BIS_fnc_getParamValue) > 0;

    [format ["Detailed difficulty params applied: playerHealth=%1 damageTaken=%2 enemySkill=%3 waveSize=%4 interval=%5 captureHold=%6 special=%7 pressure=%8 hardCap=%9.", _playerHealthMultiplier, missionNamespace getVariable ["KFH_playerDamageTakenScale", 1], _enemySkillScale, _waveSizeScale, _waveIntervalScale, KFH_holdSeconds, _specialThreatScale, _pressureScale, KFH_activeEnemyHardCap]] call KFH_fnc_log;
    [format ["Detailed combat toggles applied: armed=%1 vehicleThreats=%2.", _armedScale, KFH_vehicleThreatEnabled]] call KFH_fnc_log;
};

KFH_fnc_applyServerRouteParams = {
    private _routeScale = ["KFH_RouteScale", missionNamespace getVariable ["KFH_routeScaleParamDefault", 100]] call BIS_fnc_getParamValue;
    private _checkpointCount = ["KFH_CheckpointCount", missionNamespace getVariable ["KFH_checkpointCountParamDefault", KFH_checkpointCount]] call BIS_fnc_getParamValue;
    _checkpointCount = (_checkpointCount max KFH_checkpointCountMin) min KFH_checkpointCountMax;

    missionNamespace setVariable ["KFH_checkpointCount", _checkpointCount, true];
    KFH_checkpointCount = _checkpointCount;

    switch (_routeScale) do {
        case 33: {
            missionNamespace setVariable ["KFH_debugShortRouteEnabled", true, true];
            missionNamespace setVariable ["KFH_debugShortRouteForce", true, true];
            missionNamespace setVariable ["KFH_debugShortRouteScale", 0.33, true];
            missionNamespace setVariable ["KFH_debugShortRouteMinSpacing", 280, true];
            missionNamespace setVariable ["KFH_debugShortRouteLengthRatio", 0.08, true];
            missionNamespace setVariable ["KFH_debugShortRouteTargetSegment", missionNamespace getVariable ["KFH_debugShortRouteTargetSegment", 480], true];
            missionNamespace setVariable ["KFH_debugShortRouteJitter", 140, true];
            missionNamespace setVariable ["KFH_debugShortRouteEdgeMargin", 450, true];
        };
        case 50: {
            missionNamespace setVariable ["KFH_debugShortRouteEnabled", true, true];
            missionNamespace setVariable ["KFH_debugShortRouteForce", true, true];
            missionNamespace setVariable ["KFH_debugShortRouteScale", 0.5, true];
            missionNamespace setVariable ["KFH_debugShortRouteMinSpacing", missionNamespace getVariable ["KFH_routeScaleHalfMinSpacing", 440], true];
            missionNamespace setVariable ["KFH_debugShortRouteLengthRatio", missionNamespace getVariable ["KFH_routeScaleHalfLengthRatio", 0.18], true];
            missionNamespace setVariable ["KFH_debugShortRouteTargetSegment", missionNamespace getVariable ["KFH_routeScaleHalfTargetSegment", 780], true];
            missionNamespace setVariable ["KFH_debugShortRouteJitter", missionNamespace getVariable ["KFH_routeScaleHalfJitter", 210], true];
            missionNamespace setVariable ["KFH_debugShortRouteEdgeMargin", missionNamespace getVariable ["KFH_routeScaleHalfEdgeMargin", 520], true];
        };
        default {
            missionNamespace setVariable ["KFH_debugShortRouteEnabled", false, true];
            missionNamespace setVariable ["KFH_debugShortRouteForce", false, true];
            missionNamespace setVariable ["KFH_debugShortRouteActive", false, true];
            missionNamespace setVariable ["KFH_debugShortRouteApplied", false, true];
        };
    };

    [format ["Server route params applied: scale=%1 checkpointCount=%2.", _routeScale, _checkpointCount]] call KFH_fnc_log;
};

KFH_fnc_applyThreatScaleParam = {
    private _percent = ["KFH_ThreatScale", missionNamespace getVariable ["KFH_threatScaleParamDefault", 100]] call BIS_fnc_getParamValue;
    private _multiplier = ((_percent max 50) min 250) / 100;
    missionNamespace setVariable ["KFH_threatScaleMultiplier", _multiplier, true];
    [format ["Threat density scale applied: %1%% multiplier=%2.", _percent, _multiplier]] call KFH_fnc_log;
};

KFH_fnc_applyDifficultyPreset = {
    private _difficulty = ["KFH_Difficulty", missionNamespace getVariable ["KFH_difficultyParamDefault", 1]] call BIS_fnc_getParamValue;
    private _names = missionNamespace getVariable ["KFH_difficultyNames", ["easy", "normal", "hard", "veryHard"]];
    private _index = (_difficulty max 0) min ((count _names) - 1);
    private _name = _names select _index;

    switch (_index) do {
        case 0: {
            KFH_pressureTickValue = 4;
            KFH_reinforcePressure = 7;
            KFH_standardGunnerChance = 0.08;
            KFH_standardHeavyChance = 0.035;
            KFH_rushHeavyChance = 0.08;
            KFH_checkpointSpecialChance = 0.25;
            KFH_checkpointSpecialMaxActive = 3;
            missionNamespace setVariable ["KFH_waveBaseCounts", (KFH_waveBaseCounts apply { ceil (_x * 0.78) })];
            missionNamespace setVariable ["KFH_waveCooldownNormalMinSeconds", 120];
            missionNamespace setVariable ["KFH_waveCooldownNormalMaxSeconds", 130];
            missionNamespace setVariable ["KFH_waveCooldownRushMinSeconds", 140];
            missionNamespace setVariable ["KFH_waveCooldownRushMaxSeconds", 260];
        };
        case 2: {
            KFH_pressureTickValue = 8;
            KFH_reinforcePressure = 13;
            KFH_standardGunnerChance = 0.16;
            KFH_standardHeavyChance = 0.09;
            KFH_rushHeavyChance = 0.16;
            KFH_checkpointSpecialChance = 0.6;
            KFH_checkpointSpecialMaxActive = 6;
            missionNamespace setVariable ["KFH_waveBaseCounts", (KFH_waveBaseCounts apply { ceil (_x * 1.18) })];
            missionNamespace setVariable ["KFH_waveCooldownNormalMinSeconds", 85];
            missionNamespace setVariable ["KFH_waveCooldownNormalMaxSeconds", 95];
            missionNamespace setVariable ["KFH_waveCooldownRushMinSeconds", 85];
            missionNamespace setVariable ["KFH_waveCooldownRushMaxSeconds", 210];
        };
        case 3: {
            KFH_pressureTickValue = 10;
            KFH_reinforcePressure = 16;
            KFH_standardGunnerChance = 0.2;
            KFH_standardHeavyChance = 0.12;
            KFH_rushHeavyChance = 0.2;
            KFH_checkpointSpecialChance = 0.67;
            KFH_checkpointSpecialMaxActive = 7;
            missionNamespace setVariable ["KFH_waveBaseCounts", (KFH_waveBaseCounts apply { ceil (_x * 1.35) })];
            missionNamespace setVariable ["KFH_waveCooldownNormalMinSeconds", 70];
            missionNamespace setVariable ["KFH_waveCooldownNormalMaxSeconds", 85];
            missionNamespace setVariable ["KFH_waveCooldownRushMinSeconds", 70];
            missionNamespace setVariable ["KFH_waveCooldownRushMaxSeconds", 180];
        };
        default {
            missionNamespace setVariable ["KFH_waveBaseCounts", +KFH_waveBaseCounts];
            missionNamespace setVariable ["KFH_waveCooldownNormalMinSeconds", KFH_waveCooldownNormalMinSeconds];
            missionNamespace setVariable ["KFH_waveCooldownNormalMaxSeconds", KFH_waveCooldownNormalMaxSeconds];
            missionNamespace setVariable ["KFH_waveCooldownRushMinSeconds", KFH_waveCooldownRushMinSeconds];
            missionNamespace setVariable ["KFH_waveCooldownRushMaxSeconds", KFH_waveCooldownRushMaxSeconds];
        };
    };

    missionNamespace setVariable ["KFH_difficulty", _name, true];
    missionNamespace setVariable ["KFH_difficultyIndex", _index, true];
    [format ["Difficulty preset applied: %1 (%2).", _name, _index]] call KFH_fnc_log;
};

