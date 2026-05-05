KFH_fnc_serverInit = {
    private _startMarker = "kfh_start";
    private _optionalProbe = missionNamespace getVariable ["KFH_optionalContentWeaponProbe", "rhs_weap_m4a1"];
    private _optionalAvailableOnServer = (missionNamespace getVariable ["KFH_cupOptionalEnabled", true]) &&
        {isClass (configFile >> "CfgWeapons" >> _optionalProbe)};
    missionNamespace setVariable ["KFH_optionalContentAvailableOnServer", _optionalAvailableOnServer, true];
    [format ["Optional content on server: %1.", _optionalAvailableOnServer]] call KFH_fnc_log;

    private _checkpointMarkers = [] call KFH_fnc_getCheckpointMarkers;
    private _checkpointLimit = missionNamespace getVariable ["KFH_checkpointCount", count _checkpointMarkers];
    if ((count _checkpointMarkers) > _checkpointLimit) then {
        _checkpointMarkers = _checkpointMarkers select [0, _checkpointLimit];
    };

    if !(_startMarker in allMapMarkers) exitWith {
        ["Missing marker: kfh_start"] call KFH_fnc_log;
    };

    private _extractMarker = if ("kfh_extract" in allMapMarkers) then {
        "kfh_extract"
    } else {
        _startMarker
    };
    private _extractionTestModeValue = ["KFH_ExtractionTestMode", missionNamespace getVariable ["KFH_extractionTestModeDefault", 0]] call BIS_fnc_getParamValue;
    private _extractionTestMode = _extractionTestModeValue > 0;
    private _extractionFinaleTestMode = _extractionTestModeValue isEqualTo 2;
    missionNamespace setVariable ["KFH_announcementLanguageIndex", ["KFH_AnnouncementLanguage", missionNamespace getVariable ["KFH_announcementLanguageDefault", 1]] call BIS_fnc_getParamValue];
    private _scalingTestAllies = ["KFH_ScalingTestAllies", missionNamespace getVariable ["KFH_scalingTestAlliesDefault", 0]] call BIS_fnc_getParamValue;
    private _routePoints = +(missionNamespace getVariable ["KFH_dynamicRoutePoints", []]);
    if (missionNamespace getVariable ["KFH_dynamicRouteBuilt", false]) then {
        ["Dynamic route checkpoint safe relocation skipped; generator already validated route spacing."] call KFH_fnc_log;
    } else {
        {
            private _markerName = _x;
            private _markerPos = getMarkerPos _markerName;
            if !([_markerPos, "checkpoint"] call KFH_fnc_isObjectiveAreaSafe) then {
                private _relocated = [_markerPos, "checkpoint", markerDir _markerName] call KFH_fnc_findNearbySafeObjectivePos;
                if !(_relocated isEqualTo _markerPos) then {
                    _markerName setMarkerPos _relocated;
                    if ((count _routePoints) > (_forEachIndex + 1)) then {
                        _routePoints set [_forEachIndex + 1, _relocated];
                    };
                    [format ["Checkpoint marker %1 relocated to safer ground at %2.", _markerName, mapGridPosition _relocated]] call KFH_fnc_log;
                };
            };
        } forEach _checkpointMarkers;
    };
    if (_extractionTestMode) then {
        private _startPos = getMarkerPos _startMarker;
        private _lzDir = markerDir _startMarker;
        private _lzDistance = missionNamespace getVariable ["KFH_extractionTestLzDistance", 140];
        private _candidateLz = _startPos getPos [_lzDistance, _lzDir + 35];
        private _lzPos = [_candidateLz, "extract", _lzDir + 35] call KFH_fnc_findNearbySafeObjectivePos;
        _extractMarker setMarkerPos _lzPos;
        _extractMarker setMarkerAlpha 1;
        [format ["Extraction test mode moved LZ near start: %1.", mapGridPosition _lzPos]] call KFH_fnc_log;
    } else {
        private _extractPos = getMarkerPos _extractMarker;
        private _safeExtract = [_extractPos, "extract", markerDir _extractMarker] call KFH_fnc_findNearbySafeObjectivePos;
        if !(_safeExtract isEqualTo _extractPos) then {
            _extractMarker setMarkerPos _safeExtract;
            [format ["Extraction marker relocated to safer LZ at %1.", mapGridPosition _safeExtract]] call KFH_fnc_log;
        };
    };
    if ((count _routePoints) > 0) then {
        _routePoints set [((count _routePoints) - 1), getMarkerPos _extractMarker];
        missionNamespace setVariable ["KFH_dynamicRoutePoints", _routePoints, true];
    };
    [_extractMarker] call KFH_fnc_refreshExtractSpawnMarkers;
    private _routeMarkers = [_startMarker] + _checkpointMarkers + [_extractMarker];

    if ((count _checkpointMarkers) isEqualTo 0) exitWith {
        ["At least one checkpoint marker named kfh_cp_1 is required."] call KFH_fnc_log;
    };

    [] call KFH_fnc_initRunTelemetry;
    [] call KFH_fnc_configurePvEvERelations;
    [] call KFH_fnc_applyDifficultyPreset;
    [] call KFH_fnc_applyThreatScaleParam;
    [] call KFH_fnc_applyEnemyAccuracyPreset;
    [] call KFH_fnc_applyEnvironmentParams;
    [] call KFH_fnc_applyExtractionAndAreaParams;
    [] call KFH_fnc_applyTrafficAndSpawnParams;
    [] call KFH_fnc_applyDetailedDifficultyParams;
    ["start"] call KFH_fnc_playStoryBeatOnce;
    private _targetPlayers = [] call KFH_fnc_getMissionMaxPlayers;
    missionNamespace setVariable ["KFH_targetPlayers", _targetPlayers, true];
    ["KFH_targetPlayers", _targetPlayers] call KFH_fnc_setState;
    missionNamespace setVariable ["KFH_scalingTestAllyCount", _scalingTestAllies, true];
    missionNamespace setVariable ["KFH_scalingTestAllies", [], true];
    missionNamespace setVariable ["KFH_scalingPlayerCountOverride", if (_scalingTestAllies > 0) then { 1 + _scalingTestAllies } else { -1 }, true];
    ["KFH_scalingPlayerCount", [] call KFH_fnc_getScalingPlayerCount] call KFH_fnc_setState;
    ["KFH_extractionTestMode", _extractionTestMode] call KFH_fnc_setState;
    ["KFH_phase", if (_extractionTestMode) then { "extract" } else { "assault" }] call KFH_fnc_setState;
    ["KFH_pressure", 0] call KFH_fnc_setState;
    ["KFH_currentWave", 0] call KFH_fnc_setState;
    ["KFH_rushActive", false] call KFH_fnc_setState;
    ["KFH_currentCheckpoint", if (_extractionTestMode) then { count _checkpointMarkers } else { 1 }] call KFH_fnc_setState;
    ["KFH_totalCheckpoints", count _checkpointMarkers] call KFH_fnc_setState;
    ["KFH_extractMarker", _extractMarker] call KFH_fnc_setState;
    ["KFH_objectiveMarker", if (_extractionTestMode) then { _extractMarker } else { _checkpointMarkers select 0 }] call KFH_fnc_setState;
    ["KFH_objectiveHostiles", 0] call KFH_fnc_setState;
    ["KFH_totalHostiles", 0] call KFH_fnc_setState;
    ["KFH_captureActive", false] call KFH_fnc_setState;
    ["KFH_captureProgress", 0] call KFH_fnc_setState;
    ["KFH_captureLabel", "MOVE"] call KFH_fnc_setState;
    ["KFH_nextWaveAt", time + KFH_reinforceSeconds] call KFH_fnc_setState;
    ["KFH_waveCooldownReason", "initial"] call KFH_fnc_setState;
    ["KFH_combatReadyFriendlies", 0] call KFH_fnc_setState;
    missionNamespace setVariable ["KFH_checkpointMarkers", _checkpointMarkers];
    missionNamespace setVariable ["KFH_routeMarkers", _routeMarkers, true];
    missionNamespace setVariable ["KFH_waveBaseCounts", missionNamespace getVariable ["KFH_waveBaseCounts", +KFH_waveBaseCounts]];
    missionNamespace setVariable ["KFH_enemyClasses", +KFH_enemyClasses];
    missionNamespace setVariable ["KFH_checkpointEventPlan", [_checkpointMarkers] call KFH_fnc_buildCheckpointEventPlan, true];
    missionNamespace setVariable ["KFH_checkpointSecuredStates", _checkpointMarkers apply { _extractionTestMode }, true];
    missionNamespace setVariable ["KFH_checkpointSupplyStates", _checkpointMarkers apply { _extractionTestMode }, true];
    missionNamespace setVariable ["KFH_activeEnemies", []];
    missionNamespace setVariable ["KFH_currentObjectiveEnemies", []];
    missionNamespace setVariable ["KFH_currentWaveCheckpoint", 0, true];
    missionNamespace setVariable ["KFH_envTrafficGroups", []];
    missionNamespace setVariable ["KFH_ambientTrafficVehicles", [], true];
    missionNamespace setVariable ["KFH_holdStart", -1];
    missionNamespace setVariable ["KFH_extractHoldStart", -1];
    missionNamespace setVariable ["KFH_extractPrepUntil", if (_extractionTestMode) then { time + (missionNamespace getVariable ["KFH_extractionTestPrepSeconds", 5]) } else { -1 }];
    missionNamespace setVariable ["KFH_extractPrepReleased", _extractionTestMode && {(missionNamespace getVariable ["KFH_extractionTestPrepSeconds", 5]) <= 0}];
    missionNamespace setVariable ["KFH_extractPrepAnnounced", []];
    missionNamespace setVariable ["KFH_extractFlareFired", _extractionTestMode, true];
    missionNamespace setVariable ["KFH_extractFlareFiredBy", "", true];
    missionNamespace setVariable ["KFH_extractFlareRequired", if (_extractionTestMode) then { false } else { KFH_extractFlareRequired }, true];
    missionNamespace setVariable ["KFH_extractFlareWarnedAt", -1];
    missionNamespace setVariable ["KFH_extractAutoDepartAt", -1, true];
    missionNamespace setVariable ["KFH_extractAutoDepartWarned", false, true];
    missionNamespace setVariable ["KFH_extractionHeliScheduledAt", -1, true];
    missionNamespace setVariable ["KFH_extractionFinaleRushActive", false, true];
    missionNamespace setVariable ["KFH_extractionFinaleSpecialQueue", [], true];
    missionNamespace setVariable ["KFH_extractionFinaleNextSpecialAt", -1, true];
    missionNamespace setVariable ["KFH_extractionHeli", objNull, true];
    missionNamespace setVariable ["KFH_extractionHelis", [], true];
    missionNamespace setVariable ["KFH_extractionHeliRetryCount", 0, true];
    missionNamespace setVariable ["KFH_extractionPassengersAtDeparture", -1, true];
    missionNamespace setVariable ["KFH_extractionAliveAtDeparture", -1, true];
    missionNamespace setVariable ["KFH_extractionCompleted", false, true];
    missionNamespace setVariable ["KFH_extractionHeliState", "idle", true];
    missionNamespace setVariable ["KFH_extractHelipad", objNull, true];
    missionNamespace setVariable ["KFH_extractHelipads", [], true];
    missionNamespace setVariable ["KFH_extractPressureTickCurrent", KFH_extractPressureTickSeconds];
    missionNamespace setVariable ["KFH_extractReinforceSecondsCurrent", KFH_extractReinforceSeconds];
    missionNamespace setVariable ["KFH_extractReinforcePressureCurrent", KFH_extractReinforcePressure];
    missionNamespace setVariable ["KFH_extractWaveBaseCount", KFH_extractBaseWaveCount];
    missionNamespace setVariable ["KFH_rushActive", false, true];
    missionNamespace setVariable ["KFH_rushCheckpoint", -1, true];
    missionNamespace setVariable ["KFH_rushWaveNumber", -1, true];
    missionNamespace setVariable ["KFH_wipeLocked", false, true];
    missionNamespace setVariable ["KFH_wipePendingSince", -1];
    missionNamespace setVariable ["KFH_initialCombatReleased", false, true];
    missionNamespace setVariable ["KFH_initialWaveSpawnStarted", false, true];
    missionNamespace setVariable ["KFH_initialWaveFirstHumanSeenAt", -1, true];
    missionNamespace setVariable ["KFH_nextPressureAt", time + KFH_pressureTickSeconds];
    missionNamespace setVariable ["KFH_nextPressureEmergencyAt", 0];
    missionNamespace setVariable ["KFH_nextReinforceAt", time + KFH_reinforceSeconds];
    missionNamespace setVariable ["KFH_nextWaveAt", time + KFH_reinforceSeconds, true];
    missionNamespace setVariable ["KFH_nextCheckpointStatusAt", time + 5];
    [_startMarker] call KFH_fnc_spawnSupportFob;
    [_startMarker] call KFH_fnc_spawnPatrolVehicles;
    {
        [_x, _forEachIndex + 1] call KFH_fnc_spawnCheckpointLandmarks;
    } forEach _checkpointMarkers;
    [_startMarker, _checkpointMarkers, _extractMarker] call KFH_fnc_spawnRouteDressing;
    [] call KFH_fnc_updateRouteMarkerVisibility;
    [] call KFH_fnc_refreshStrategicState;
    [getMarkerPos (if (_extractionTestMode) then { _extractMarker } else { _startMarker }), if (_extractionTestMode) then { "Extraction Test LZ" } else { "Start FOB" }] call KFH_fnc_updateRespawnAnchor;
    private _runStartText = if (([] call KFH_fnc_getAnnouncementLanguageIndex) isEqualTo 0) then {
        format ["Run 開始デス。checkpoint は %1 箇所、extract は %2 デス。", count _checkpointMarkers, _extractMarker]
    } else {
        format ["Run started with %1 checkpoint(s); extract is %2.", count _checkpointMarkers, _extractMarker]
    };
    [_runStartText, "RUN"] call KFH_fnc_appendRunEvent;
    if (_extractionTestMode) then {
        ["extract_test_active", [], "EXTRACT"] call KFH_fnc_appendRunEventKey;
        ["extract_test_lz_near", [_startMarker]] call KFH_fnc_notifyAllKey;
        [] call KFH_fnc_applyExtractDangerProfile;
        [_extractionFinaleTestMode] spawn {
            params ["_finaleTestMode"];
            sleep (missionNamespace getVariable ["KFH_extractionTestPrepSeconds", 5]);
            missionNamespace setVariable ["KFH_extractPrepReleased", true];
            missionNamespace setVariable ["KFH_extractFlareFired", true, true];
            missionNamespace setVariable ["KFH_extractFlareFiredBy", "Extraction Test", true];
            if (_finaleTestMode) then {
                private _heliDelay = missionNamespace getVariable ["KFH_extractionHeliCallDelaySeconds", 200];
                missionNamespace setVariable ["KFH_extractionHeliScheduledAt", time + _heliDelay, true];
                [] call KFH_fnc_startExtractionFinaleRush;
                [] call KFH_fnc_spawnExtractWave;
                [format ["Extraction finale test started. Angel One ETA %1 seconds.", round _heliDelay]] call KFH_fnc_log;
            } else {
                [] call KFH_fnc_spawnExtractionHeli;
            };
        };
    };

    ["KFH_Patrol_LWH_co10 server init complete."] call KFH_fnc_log;
    [] spawn KFH_fnc_vehicleThreatLoop;
    [] spawn KFH_fnc_envTrafficLoop;
    [] spawn KFH_fnc_meleeDirectorLoop;
    [] spawn KFH_fnc_debugTeammateLoop;
    [] spawn KFH_fnc_scalingTestAllyLoop;
    [] spawn KFH_fnc_debugTeammateReviveLoop;
    [] spawn KFH_fnc_wildSpecialLoop;
    if (!_extractionTestMode) then {
        [] spawn {
            [] call KFH_fnc_waitForInitialCombatReady;
        };
    } else {
        missionNamespace setVariable ["KFH_initialCombatReleased", true, true];
        missionNamespace setVariable ["KFH_initialWaveSpawnStarted", true, true];
    };

    while { true } do {
        private _phase = missionNamespace getVariable ["KFH_phase", "assault"];

        if (_phase in ["complete", "failed"]) exitWith {};

        private _pressure = missionNamespace getVariable ["KFH_pressure", 0];
        private _activeEnemies = [] call KFH_fnc_pruneActiveEnemies;
        private _combatReadyFriendlies = [] call KFH_fnc_getCombatReadyFriendlies;
        [] call KFH_fnc_trackPlayerReviveTransitions;
        ["KFH_combatReadyFriendlies", count _combatReadyFriendlies] call KFH_fnc_setState;
        if (!_extractionTestMode) then {
            [] call KFH_fnc_pollInitialWaveRelease;
        };
        private _currentPressureTickSeconds = if (_phase isEqualTo "extract") then {
            missionNamespace getVariable ["KFH_extractPressureTickCurrent", KFH_extractPressureTickSeconds]
        } else {
            KFH_pressureTickSeconds
        };
        private _currentPressureTickValue = if (_phase isEqualTo "extract") then { KFH_extractPressureTickValue } else { KFH_pressureTickValue };
        private _currentReinforceSecondsBase = if (_phase isEqualTo "extract") then {
            missionNamespace getVariable ["KFH_extractReinforceSecondsCurrent", KFH_extractReinforceSeconds]
        } else {
            KFH_reinforceSeconds
        };
        private _currentReinforceSeconds = [_currentReinforceSecondsBase] call KFH_fnc_getPressureReinforceSeconds;
        private _currentReinforcePressure = if (_phase isEqualTo "extract") then {
            missionNamespace getVariable ["KFH_extractReinforcePressureCurrent", KFH_extractReinforcePressure]
        } else {
            KFH_reinforcePressure
        };

        private _wipeCheckArmed = missionNamespace getVariable ["KFH_initialCombatReleased", false];
        if (_wipeCheckArmed && {(count _combatReadyFriendlies) isEqualTo 0}) then {
            private _aliveMonitoredFriendlies = [] call KFH_fnc_getAliveMonitoredFriendlies;
            private _aliveDebugTeammates = [] call KFH_fnc_getAliveDebugTeammates;
            private _hasReviveChance = [] call KFH_fnc_hasReviveChance;
            private _hasRecentDebugGrace = [] call KFH_fnc_hasRecentDebugTeammateGrace;
            private _hasRecentHumanCasualtyGrace = [] call KFH_fnc_hasRecentHumanCasualtyGrace;
            private _wipePendingSince = missionNamespace getVariable ["KFH_wipePendingSince", -1];

            if (_hasReviveChance && {(count _aliveDebugTeammates) > 0 || {_hasRecentDebugGrace} || {_hasRecentHumanCasualtyGrace}}) then {
                missionNamespace setVariable ["KFH_wipePendingSince", -1];
                if (time >= (missionNamespace getVariable ["KFH_nextDebugLastStandLogAt", 0])) then {
                    missionNamespace setVariable ["KFH_nextDebugLastStandLogAt", time + 20];
                    [format [
                        "Wipe blocked: rescue window active. Alive monitored=%1 rescuers=%2 aliveDebug=%3 downedPlayers=%4 recentEcho=%5 recentHumanCasualty=%6 reviveChance=%7.",
                        count _aliveMonitoredFriendlies,
                        count ([] call KFH_fnc_getPotentialRescuers),
                        count _aliveDebugTeammates,
                        count ([] call KFH_fnc_getIncapacitatedPlayers),
                        _hasRecentDebugGrace,
                        _hasRecentHumanCasualtyGrace,
                        _hasReviveChance
                    ]] call KFH_fnc_log;
                };
            } else {
                if (_hasReviveChance) then {
                    if (_wipePendingSince < 0) then {
                        missionNamespace setVariable ["KFH_wipePendingSince", time];
                        [format [
                            "Wipe grace started. Alive monitored=%1 rescuers=%2 aliveDebug=%3 downedPlayers=%4.",
                            count _aliveMonitoredFriendlies,
                            count ([] call KFH_fnc_getPotentialRescuers),
                            count _aliveDebugTeammates,
                            count ([] call KFH_fnc_getIncapacitatedPlayers)
                        ]] call KFH_fnc_log;
                    };

                    if ((time - (missionNamespace getVariable ["KFH_wipePendingSince", time])) >= KFH_wipeGraceSeconds) exitWith {
                        missionNamespace setVariable ["KFH_wipeLocked", true, true];
                        [format [
                            "Wipe detected after rescue grace. Alive monitored=%1 rescuers=%2 aliveDebug=%3 downedPlayers=%4.",
                            count _aliveMonitoredFriendlies,
                            count ([] call KFH_fnc_getPotentialRescuers),
                            count _aliveDebugTeammates,
                            count ([] call KFH_fnc_getIncapacitatedPlayers)
                        ]] call KFH_fnc_log;
                        [false, ["mission_failed_team_down"] call KFH_fnc_localizeAnnouncement] call KFH_fnc_completeMission;
                    };
                } else {
                    missionNamespace setVariable ["KFH_wipeLocked", true, true];
                    [format [
                        "Wipe detected. Monitored combat-ready=%1 aliveMonitored=%2 rescuers=%3 downedPlayers=%4.",
                        count _combatReadyFriendlies,
                        count _aliveMonitoredFriendlies,
                        count ([] call KFH_fnc_getPotentialRescuers),
                        count ([] call KFH_fnc_getIncapacitatedPlayers)
                    ]] call KFH_fnc_log;
                    [false, ["mission_failed_team_down"] call KFH_fnc_localizeAnnouncement] call KFH_fnc_completeMission;
                };
            };
        } else {
            missionNamespace setVariable ["KFH_wipePendingSince", -1];
        };

        if (time >= (missionNamespace getVariable ["KFH_nextPressureAt", 0])) then {
            _pressure = (_pressure + _currentPressureTickValue) min KFH_pressureMax;
            ["KFH_pressure", _pressure] call KFH_fnc_setState;
            missionNamespace setVariable ["KFH_nextPressureAt", time + _currentPressureTickSeconds];
        };

        if (_pressure >= KFH_pressureMax) then {
            if (KFH_pressureFailEnabled) exitWith {
                [false, ["mission_failed_pressure"] call KFH_fnc_localizeAnnouncement] call KFH_fnc_completeMission;
            };

            if (time >= (missionNamespace getVariable ["KFH_nextPressureEmergencyAt", 0])) then {
                missionNamespace setVariable ["KFH_nextPressureEmergencyAt", time + KFH_pressureEmergencyCooldown];
                _pressure = (KFH_pressureMax - KFH_pressureEmergencyRelief) max 0;
                ["KFH_pressure", _pressure] call KFH_fnc_setState;
                private _nextReinforceAt = missionNamespace getVariable ["KFH_nextReinforceAt", time + KFH_reinforceSeconds];
                missionNamespace setVariable ["KFH_nextReinforceAt", _nextReinforceAt min (time + ([_currentReinforceSecondsBase] call KFH_fnc_getPressureReinforceSeconds))];
                ["pressure_critical"] call KFH_fnc_notifyAllKey;
                ["Hive Pressure critical intensity vented into the next reinforcement cycle.", "PRESSURE"] call KFH_fnc_appendRunEvent;
            } else {
                _pressure = KFH_pressureMax - 1;
                ["KFH_pressure", _pressure] call KFH_fnc_setState;
            };
        };

        if (_phase isEqualTo "assault") then {
            private _checkpointIndex = missionNamespace getVariable ["KFH_currentCheckpoint", 1];
            private _checkpointMarker = _checkpointMarkers select (_checkpointIndex - 1);
            private _checkpointPos = getMarkerPos _checkpointMarker;
            private _objectiveEnemies = [] call KFH_fnc_getCurrentObjectiveEnemies;
            private _playersNear = ([] call KFH_fnc_getHumanReferenceUnits) select {
                alive _x && ((_x distance2D _checkpointPos) <= KFH_captureRadius)
            };
            private _objectiveThreats = [_objectiveEnemies, _checkpointPos] call KFH_fnc_getCheckpointBlockingThreats;
            private _rushActive = missionNamespace getVariable ["KFH_rushActive", false];
            private _rushCheckpoint = missionNamespace getVariable ["KFH_rushCheckpoint", -1];
            private _rushWaveNumber = missionNamespace getVariable ["KFH_rushWaveNumber", -1];
            ["KFH_objectiveHostiles", count _objectiveEnemies] call KFH_fnc_setState;

            private _captureActive = (count _playersNear) > 0;
            private _currentWaveHostileCount = missionNamespace getVariable ["KFH_currentWaveHostileCount", count _objectiveThreats];
            private _captureThreatBasis = _currentWaveHostileCount max 1;
            private _captureBaseline = missionNamespace getVariable ["KFH_captureThreatBaseline", -1];
            if (_captureActive) then {
                private _observedThreats = (_currentWaveHostileCount max (count _objectiveThreats)) max 1;
                if (_captureBaseline < _observedThreats) then {
                    _captureBaseline = _observedThreats;
                    missionNamespace setVariable ["KFH_captureThreatBaseline", _captureBaseline, true];
                };
                _captureThreatBasis = _captureBaseline max _observedThreats;
            } else {
                missionNamespace setVariable ["KFH_captureThreatBaseline", -1, true];
            };
            private _remainingObjectiveCount = count _objectiveEnemies;
            private _captureProgress = 0;
            private _captureLabel = if ((count _playersNear) > 0) then {
                if ((count _objectiveThreats) > 0) then {
                    format ["SECURING CP %1 | THREATS %2", _checkpointIndex, count _objectiveThreats]
                } else {
                    if (_remainingObjectiveCount > 0) then {
                        format ["SECURING CP %1 | INBOUND %2", _checkpointIndex, _remainingObjectiveCount]
                    } else {
                        format ["SECURING CHECKPOINT %1", _checkpointIndex]
                    }
                }
            } else {
                format ["MOVE TO CHECKPOINT %1", _checkpointIndex]
            };

            if ((count _playersNear) > 0) then {
                [_checkpointIndex, _checkpointMarker, count _objectiveThreats] call KFH_fnc_startCheckpointDefenseEvent;
            };

            if (
                ((count _playersNear) > 0) &&
                {(count _objectiveThreats) isEqualTo 0} &&
                {(missionNamespace getVariable ["KFH_currentWaveCheckpoint", 0]) isNotEqualTo _checkpointIndex}
            ) then {
                private _entrySeenKey = format ["KFH_checkpointEntrySeenAt_%1", _checkpointIndex];
                private _entrySeenAt = missionNamespace getVariable [_entrySeenKey, -1];
                if (_entrySeenAt < 0) then {
                    _entrySeenAt = time;
                    missionNamespace setVariable [_entrySeenKey, _entrySeenAt, true];
                };
                if ((time - _entrySeenAt) >= (missionNamespace getVariable ["KFH_checkpointEntryWaveGraceSeconds", 4])) then {
                    [format ["Checkpoint %1 entry wave guarantee triggered after empty objective contact.", _checkpointIndex]] call KFH_fnc_log;
                    [_checkpointIndex, 1, true] call KFH_fnc_spawnCheckpointWave;
                    missionNamespace setVariable ["KFH_nextReinforceAt", time + _currentReinforceSeconds];
                    missionNamespace setVariable ["KFH_nextWaveAt", time + _currentReinforceSeconds, true];
                    _objectiveEnemies = [] call KFH_fnc_getCurrentObjectiveEnemies;
                    _objectiveThreats = [_objectiveEnemies, _checkpointPos] call KFH_fnc_getCheckpointBlockingThreats;
                    _currentWaveHostileCount = missionNamespace getVariable ["KFH_currentWaveHostileCount", count _objectiveThreats];
                };
            } else {
                missionNamespace setVariable [format ["KFH_checkpointEntrySeenAt_%1", _checkpointIndex], -1, true];
            };

            if (
                (missionNamespace getVariable ["KFH_checkpointStallRescueEnabled", true]) &&
                {(count _playersNear) > 0} &&
                {(count _objectiveEnemies) > 0} &&
                {(count _objectiveThreats) isEqualTo 0}
            ) then {
                private _stallKey = format ["KFH_checkpointStallSince_%1", _checkpointIndex];
                private _stallSince = missionNamespace getVariable [_stallKey, -1];
                if (_stallSince < 0) then {
                    _stallSince = time;
                    missionNamespace setVariable [_stallKey, _stallSince, true];
                    ["checkpoint_contact_inbound", [count _objectiveEnemies]] call KFH_fnc_notifyAllKey;
                    [format [
                        "Checkpoint %1 stall watch started: objective=%2 blocking=%3 nearest=%4.",
                        _checkpointIndex,
                        count _objectiveEnemies,
                        count _objectiveThreats,
                        if ((count _objectiveEnemies) > 0) then { round ([getPosATL (_objectiveEnemies select 0)] call KFH_fnc_getNearestHumanDistance) } else { -1 }
                    ]] call KFH_fnc_log;
                };
                if ((time - _stallSince) >= (missionNamespace getVariable ["KFH_checkpointStallRescueSeconds", 35])) then {
                    private _nudged = [_objectiveEnemies, _checkpointPos] call KFH_fnc_nudgeObjectiveEnemiesTowardCheckpoint;
                    missionNamespace setVariable [_stallKey, time, true];
                    [format [
                        "Checkpoint %1 stall rescue nudged %2 objective hostiles toward checkpoint. objective=%3 blocking=%4.",
                        _checkpointIndex,
                        _nudged,
                        count _objectiveEnemies,
                        count _objectiveThreats
                    ]] call KFH_fnc_log;
                };
            } else {
                missionNamespace setVariable [format ["KFH_checkpointStallSince_%1", _checkpointIndex], -1, true];
            };

            if (
                _rushActive &&
                {_rushCheckpoint isEqualTo _checkpointIndex} &&
                {(count _objectiveThreats) isEqualTo 0}
            ) then {
                [_checkpointIndex, _rushWaveNumber] call KFH_fnc_grantRushReward;
            };

            private _currentWaveForCooldown = missionNamespace getVariable ["KFH_currentWave", 0];
            private _cooldownAppliedWave = missionNamespace getVariable ["KFH_objectiveClearCooldownAppliedWave", -1];
            if (
                (_currentWaveForCooldown > 0) &&
                {_cooldownAppliedWave isNotEqualTo _currentWaveForCooldown} &&
                {(count _objectiveEnemies) isEqualTo 0}
            ) then {
                private _isRushClear = _rushActive && {_rushCheckpoint isEqualTo _checkpointIndex};
                private _clearCooldown = [_isRushClear] call KFH_fnc_calculateWaveClearCooldown;
                [_clearCooldown, if (_isRushClear) then { "rush cleared" } else { "wave cleared" }] call KFH_fnc_applyWaveCooldown;
                missionNamespace setVariable ["KFH_objectiveClearCooldownAppliedWave", _currentWaveForCooldown, true];
            };

            if (
                time >= (missionNamespace getVariable ["KFH_nextReinforceAt", 0]) &&
                {(_phase isEqualTo "extract") || {missionNamespace getVariable ["KFH_initialCombatReleased", false]}} &&
                {((count ([] call KFH_fnc_getHumanReferenceUnits)) > 0) || {(count _combatReadyFriendlies) > 0}}
            ) then {
                [_checkpointIndex, 0.75 * ([] call KFH_fnc_getPressureSpawnMultiplier)] call KFH_fnc_spawnCheckpointWave;
                _pressure = ((_pressure + _currentReinforcePressure) min KFH_pressureMax);
                ["KFH_pressure", _pressure] call KFH_fnc_setState;
                missionNamespace setVariable ["KFH_nextReinforceAt", time + _currentReinforceSeconds];
                missionNamespace setVariable ["KFH_nextWaveAt", time + _currentReinforceSeconds, true];
                _objectiveEnemies = [] call KFH_fnc_getCurrentObjectiveEnemies;
                _objectiveThreats = [_objectiveEnemies, _checkpointPos] call KFH_fnc_getCheckpointBlockingThreats;
                _remainingObjectiveCount = count _objectiveEnemies;
                ["KFH_objectiveHostiles", _remainingObjectiveCount] call KFH_fnc_setState;
            };

            if (time >= (missionNamespace getVariable ["KFH_nextCheckpointStatusAt", 0])) then {
                private _nextWaveRemaining = round (((missionNamespace getVariable ["KFH_nextReinforceAt", 0]) - time) max 0);
                private _waitReason = switch (true) do {
                    case ((count _playersNear) isEqualTo 0): { "waiting_for_players" };
                    case (_captureActive): { format ["securing threats=%1 objective=%2 hold=%3", count _objectiveThreats, count _objectiveEnemies, KFH_holdSeconds] };
                    case (_nextWaveRemaining > 0): { format ["wave_cooldown=%1", _nextWaveRemaining] };
                    default { "ready" };
                };
                if (missionNamespace getVariable ["KFH_showCheckpointStatusChat", false]) then {
                    ["checkpoint_status_debug", [
                        _checkpointIndex,
                        count _playersNear,
                        count _objectiveThreats,
                        mapGridPosition _checkpointPos
                    ]] call KFH_fnc_notifyAllKey;
                } else {
                    private _statusLine = ["checkpoint_status_debug", [
                        _checkpointIndex,
                        count _playersNear,
                        count _objectiveThreats,
                        mapGridPosition _checkpointPos
                    ]] call KFH_fnc_localizeAnnouncement;
                    [format [
                        "%1 wait=%2 nextWave=%3 wave=%4 waveHostiles=%5 objectiveTotal=%6",
                        _statusLine,
                        _waitReason,
                        _nextWaveRemaining,
                        missionNamespace getVariable ["KFH_currentWave", 0],
                        missionNamespace getVariable ["KFH_currentWaveHostileCount", 0],
                        count _objectiveEnemies
                    ]] call KFH_fnc_log;
                };
                missionNamespace setVariable ["KFH_nextCheckpointStatusAt", time + KFH_checkpointStatusInterval];
            };

            if ((count _playersNear) > 0) then {
                private _holdStart = missionNamespace getVariable ["KFH_holdStart", -1];

                if (_holdStart < 0) then {
                    missionNamespace setVariable ["KFH_holdStart", time];
                    _holdStart = time;
                    if ((count _objectiveThreats) > 0 || {_remainingObjectiveCount > 0}) then {
                        ["checkpoint_secure_window_started_suppressed", [(count _objectiveThreats) max _remainingObjectiveCount]] call KFH_fnc_notifyAllKey;
                    } else {
                        ["checkpoint_secure_window_started_clear"] call KFH_fnc_notifyAllKey;
                    };
                };

                _captureProgress = (((time - _holdStart) / KFH_holdSeconds) max 0) min 1;

                if ((time - (missionNamespace getVariable ["KFH_holdStart", time])) >= KFH_holdSeconds) then {
                    [_checkpointIndex, _checkpointMarker, _pressure] call KFH_fnc_onCheckpointSecured;
                    missionNamespace setVariable ["KFH_holdStart", -1];
                    missionNamespace setVariable ["KFH_captureThreatBaseline", -1, true];

                    if (_checkpointIndex >= (count _checkpointMarkers)) then {
                        ["KFH_phase", "extract"] call KFH_fnc_setState;
                        [getMarkerPos _checkpointMarker, "Final Checkpoint"] call KFH_fnc_updateRespawnAnchor;
                        [] call KFH_fnc_updateRouteMarkerVisibility;
                        [] call KFH_fnc_applyExtractDangerProfile;
                        missionNamespace setVariable ["KFH_nextPressureAt", time + (missionNamespace getVariable ["KFH_extractPressureTickCurrent", KFH_extractPressureTickSeconds])];
                        missionNamespace setVariable ["KFH_nextReinforceAt", time + KFH_finalArsenalCooldownSeconds];
                        missionNamespace setVariable ["KFH_nextWaveAt", time + KFH_finalArsenalCooldownSeconds, true];
                        missionNamespace setVariable ["KFH_extractPrepUntil", time + KFH_finalPrepSeconds];
                        missionNamespace setVariable ["KFH_extractPrepReleased", false];
                        missionNamespace setVariable ["KFH_extractPrepAnnounced", []];
                        missionNamespace setVariable ["KFH_extractionHeliScheduledAt", -1, true];
                        missionNamespace setVariable ["KFH_extractionFinaleRushActive", false, true];
                        missionNamespace setVariable ["KFH_extractionFinaleSpecialQueue", [], true];
                        missionNamespace setVariable ["KFH_extractionFinaleNextSpecialAt", -1, true];
                        ["final_checkpoint_prep", [KFH_finalPrepSeconds, _extractMarker]] call KFH_fnc_notifyAllKey;
                        ["extractReleased", _checkpointIndex] call KFH_fnc_playStoryBeatOnce;
                    } else {
                        ["KFH_currentCheckpoint", _checkpointIndex + 1] call KFH_fnc_setState;
                        ["KFH_objectiveMarker", _checkpointMarkers select _checkpointIndex] call KFH_fnc_setState;
                        private _nextSecureCooldown = [_checkpointIndex] call KFH_fnc_getCheckpointSecureCooldown;
                        missionNamespace setVariable ["KFH_nextReinforceAt", time + _nextSecureCooldown];
                        missionNamespace setVariable ["KFH_nextWaveAt", time + _nextSecureCooldown, true];
                        missionNamespace setVariable ["KFH_nextCheckpointStatusAt", time + 5];
                        [] call KFH_fnc_updateRouteMarkerVisibility;
                        [] call KFH_fnc_refreshStrategicState;
                        ["advance_checkpoint", [_checkpointIndex + 1]] call KFH_fnc_notifyAllKey;
                    };
                };
            } else {
                missionNamespace setVariable ["KFH_holdStart", -1];
            };

            ["KFH_captureActive", _captureActive] call KFH_fnc_setState;
            ["KFH_captureProgress", _captureProgress] call KFH_fnc_setState;
            ["KFH_captureLabel", _captureLabel] call KFH_fnc_setState;
        };

        if (_phase isEqualTo "extract") then {
            private _extractPrepUntil = missionNamespace getVariable ["KFH_extractPrepUntil", -1];
            private _extractPrepActive = (_extractPrepUntil > 0) && {time < _extractPrepUntil};

            if (_extractPrepActive) then {
                private _remaining = round (_extractPrepUntil - time);
                private _announced = missionNamespace getVariable ["KFH_extractPrepAnnounced", []];

                if ((_remaining in [20, 10, 5]) && {!(_remaining in _announced)}) then {
                    _announced pushBack _remaining;
                    missionNamespace setVariable ["KFH_extractPrepAnnounced", _announced];
                    ["extract_prep_remaining", [_remaining]] call KFH_fnc_notifyAllKey;
                };
            } else {
                if (
                    (_extractPrepUntil > 0) &&
                    {!(missionNamespace getVariable ["KFH_extractPrepReleased", false])}
                ) then {
                    missionNamespace setVariable ["KFH_extractPrepReleased", true];
                    ["prep_window_over", [_extractMarker]] call KFH_fnc_notifyAllKey;
                };
            };

            private _extractPos = getMarkerPos _extractMarker;
            private _alivePlayers = ([] call KFH_fnc_getHumanPlayers) select { alive _x };
            private _playersInExtract = _alivePlayers select {
                (_x distance2D _extractPos) <= KFH_captureRadius
            };
            private _flareRequired = missionNamespace getVariable ["KFH_extractFlareRequired", KFH_extractFlareRequired];
            private _flareReady = missionNamespace getVariable ["KFH_extractFlareFired", false];
            private _helis = [] call KFH_fnc_getExtractionHelis;
            private _heli = if ((count _helis) > 0) then { _helis select 0 } else { objNull };
            private _heliScheduledAt = missionNamespace getVariable ["KFH_extractionHeliScheduledAt", -1];
            private _heliEta = if (_heliScheduledAt >= 0) then { (_heliScheduledAt - time) max 0 } else { -1 };
            private _extractCaptureActive = !_extractPrepActive && {(count _playersInExtract) > 0};
            private _extractCaptureProgress = 0;
            private _extractCaptureLabel = if (_extractPrepActive) then {
                format ["PREP %1s", round (_extractPrepUntil - time)]
            } else {
                if (_flareRequired && {!_flareReady}) then {
                    "FIRE FLARE AT LZ"
                } else {
                    if ((count _helis) isEqualTo 0) then {
                        if (_heliEta >= 0) then {
                            format ["HELI ETA %1s", ceil _heliEta]
                        } else {
                            "AWAITING HELI"
                        }
                    } else {
                        format ["BOARD HELI %1/%2", count ([_alivePlayers, _helis] call KFH_fnc_getExtractionBoardedPlayers), count _alivePlayers]
                    }
                }
            };

            if (!_extractPrepActive && {_flareRequired} && {!_flareReady}) then {
                private _warnedAt = missionNamespace getVariable ["KFH_extractFlareWarnedAt", -1];
                if ((time - _warnedAt) >= KFH_extractFlareReminderSeconds) then {
                    missionNamespace setVariable ["KFH_extractFlareWarnedAt", time];
                    if ([] call KFH_fnc_teamHasFlareCapability) then {
                        ["fire_flare_now"] call KFH_fnc_notifyAllKey;
                    } else {
                        ["no_flare_capability"] call KFH_fnc_notifyAllKey;
                    };
                };
                missionNamespace setVariable ["KFH_extractHoldStart", -1];
            } else {
                private _boardedPlayers = [_alivePlayers, _helis] call KFH_fnc_getExtractionBoardedPlayers;
                private _approachHelis = _helis select {
                    (_x getVariable ["KFH_extractionHeliState", "Init"]) in ["Init", "Approach", "ApproachActive", "Land"]
                };
                private _waitHelis = _helis select {
                    (_x getVariable ["KFH_extractionHeliState", "Init"]) isEqualTo "WaitForPlayers"
                };
                private _evacHelis = _helis select {
                    (_x getVariable ["KFH_extractionHeliState", "Init"]) in ["Evac", "EvacActive"]
                };
                private _autoDepartAt = missionNamespace getVariable ["KFH_extractAutoDepartAt", -1];
                private _autoDepartRemaining = if (_autoDepartAt >= 0) then {
                    ((_autoDepartAt - time) max 0)
                } else {
                    -1
                };

                _extractCaptureLabel = if (_extractPrepActive) then {
                    format ["PREP %1s", round (_extractPrepUntil - time)]
                } else {
                    if ((count _helis) isEqualTo 0 || {(count _approachHelis) > 0} || {((count _waitHelis) < (count _helis)) && {(count _evacHelis) isEqualTo 0}}) then {
                        if ((count _helis) isEqualTo 0 && {_heliEta >= 0}) then {
                            format ["HELI ETA %1s", ceil _heliEta]
                        } else {
                            "HELI INBOUND"
                        }
                    } else {
                        if ((count _evacHelis) > 0 && {(count _waitHelis) isEqualTo 0}) then {
                            "HELI DEPARTING"
                        } else {
                            if ((count _waitHelis) > 0 && {_autoDepartRemaining >= 0}) then {
                                format ["BOARD HELI %1/%2 | AUTO %3s", count _boardedPlayers, count _alivePlayers, ceil _autoDepartRemaining]
                            } else {
                                format ["BOARD HELI %1/%2", count _boardedPlayers, count _alivePlayers]
                            }
                        }
                    }
                };

                if (
                    ((count _helis) > 0) &&
                    {(count _waitHelis) isEqualTo (count _helis)} &&
                    {(count _alivePlayers) > 0} &&
                    {(count _boardedPlayers) isEqualTo (count _alivePlayers)}
                ) then {
                    private _extractHoldStart = missionNamespace getVariable ["KFH_extractHoldStart", -1];

                    if (_extractHoldStart < 0) then {
                        missionNamespace setVariable ["KFH_extractHoldStart", time];
                        _extractHoldStart = time;
                        ["angel_one_lift_moment"] call KFH_fnc_notifyAllKey;
                    };

                    _extractCaptureProgress = (((time - _extractHoldStart) / KFH_extractHoldSeconds) max 0) min 1;
                    _extractCaptureLabel = "LIFTING OFF";

                    if ((time - (missionNamespace getVariable ["KFH_extractHoldStart", time])) >= KFH_extractHoldSeconds) then {
                        [_helis, "all_boarded", count _boardedPlayers, count _alivePlayers] call KFH_fnc_triggerExtractionDeparture;
                    };
                } else {
                    missionNamespace setVariable ["KFH_extractHoldStart", -1];

                    if (
                        ((count _helis) > 0) &&
                        {(count _waitHelis) isEqualTo (count _helis)} &&
                        {_autoDepartAt >= 0}
                    ) then {
                        _extractCaptureProgress = if (KFH_extractBoardTimeoutSeconds > 0) then {
                            (((KFH_extractBoardTimeoutSeconds - _autoDepartRemaining) / KFH_extractBoardTimeoutSeconds) max 0) min 1
                        } else {
                            0
                        };

                        if (
                            _autoDepartRemaining <= KFH_extractBoardWarnSeconds &&
                            {!(missionNamespace getVariable ["KFH_extractAutoDepartWarned", false])}
                        ) then {
                            missionNamespace setVariable ["KFH_extractAutoDepartWarned", true, true];
                            ["angel_one_depart_warn", [ceil _autoDepartRemaining]] call KFH_fnc_notifyAllKey;
                        };

                        if (_autoDepartRemaining <= 0) then {
                            [_helis, "timeout", count _boardedPlayers, count _alivePlayers] call KFH_fnc_triggerExtractionDeparture;
                            _extractCaptureLabel = "HELI DEPARTING";
                            _extractCaptureProgress = 1;
                        };
                    };
                };
            };

            ["KFH_captureActive", _extractCaptureActive] call KFH_fnc_setState;
            ["KFH_captureProgress", _extractCaptureProgress] call KFH_fnc_setState;
            ["KFH_captureLabel", _extractCaptureLabel] call KFH_fnc_setState;

            if (!_extractPrepActive && {_flareReady}) then {
                [] call KFH_fnc_tickExtractionFinaleRush;
                if ((count _helis) isEqualTo 0 && {_heliScheduledAt >= 0} && {time >= _heliScheduledAt}) then {
                    missionNamespace setVariable ["KFH_extractionHeliScheduledAt", -1, true];
                    [] call KFH_fnc_spawnExtractionHeli;
                };
            };

            if (!_extractPrepActive && {time >= (missionNamespace getVariable ["KFH_nextReinforceAt", 0])}) then {
                [] call KFH_fnc_spawnExtractWave;
                _pressure = ((_pressure + _currentReinforcePressure) min KFH_pressureMax);
                ["KFH_pressure", _pressure] call KFH_fnc_setState;
                missionNamespace setVariable ["KFH_nextReinforceAt", time + _currentReinforceSeconds];
                missionNamespace setVariable ["KFH_nextWaveAt", time + _currentReinforceSeconds, true];
            };
        };

        sleep 1;
    };
};

