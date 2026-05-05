KFH_fnc_supportActionHandler = {
    params ["_target", "_caller"];

    private _supportType = _target getVariable ["KFH_supportType", ""];

    switch (_supportType) do {
        case "ammo": {
            [_caller] call KFH_fnc_doAmmoSupport;
        };
        case "medical": {
            [_caller] call KFH_fnc_doMedicalSupport;
        };
        case "resupply": {
            [_caller] call KFH_fnc_doAmmoSupport;
            [_caller] call KFH_fnc_doMedicalSupport;
        };
        case "repair": {
            [_target, _caller] call KFH_fnc_doRepairSupport;
        };
        default {
            ["support_unknown_point"] call KFH_fnc_localNotifyKey;
        };
    };
};

KFH_fnc_setupSupportActions = {
    waitUntil {
        !isNull player &&
        ((count (missionNamespace getVariable ["KFH_supportObjects", []])) > 0)
    };

    while { true } do {
        private _supportObjects = missionNamespace getVariable ["KFH_supportObjects", []];

        {
            if !(isNull _x) then {
                private _supportType = _x getVariable ["KFH_supportType", ""];

                if (
                    !(_supportType isEqualTo "") &&
                    !(_x getVariable ["KFH_actionsAdded", false])
                ) then {
                    private _label = _x getVariable ["KFH_supportLabel", "Support"];
                    private _title = switch (_supportType) do {
                        case "ammo": { ["action_support_resupply", [_label]] call KFH_fnc_localizeAnnouncement };
                        case "medical": { ["action_support_use", [_label]] call KFH_fnc_localizeAnnouncement };
                        case "resupply": { ["action_support_resupply", [_label]] call KFH_fnc_localizeAnnouncement };
                        case "repair": { ["action_support_use", [_label]] call KFH_fnc_localizeAnnouncement };
                        default { ["action_support_use", [_label]] call KFH_fnc_localizeAnnouncement };
                    };

                    _x addAction [
                        _title,
                        {
                            params ["_target", "_caller"];
                            [_target, _caller] call KFH_fnc_supportActionHandler;
                        },
                        nil,
                        1.5,
                        true,
                        true,
                        "",
                        format ["alive _this && (_this distance _target) < %1", KFH_supportUseDistance]
                    ];

                    _x setVariable ["KFH_actionsAdded", true];
                };
            };
        } forEach _supportObjects;

        if ((missionNamespace getVariable ["KFH_phase", "boot"]) in ["complete", "failed"]) exitWith {};

        sleep 3;
    };
};

KFH_fnc_updateRespawnAnchor = {
    params ["_position", "_label"];

    private _existing = missionNamespace getVariable ["KFH_dynamicRespawn", []];

    if ((count _existing) > 0) then {
        _existing call BIS_fnc_removeRespawnPosition;
    };

    private _respawnData = [west, _position, _label] call BIS_fnc_addRespawnPosition;
    missionNamespace setVariable ["KFH_dynamicRespawn", _respawnData];
    missionNamespace setVariable ["KFH_respawnAnchorPos", +_position, true];

    if ("respawn_west" in allMapMarkers) then {
        "respawn_west" setMarkerPos _position;
        "respawn_west" setMarkerText _label;
        "respawn_west" setMarkerAlpha 0;
    };

    [format ["Respawn anchor moved to %1.", _label]] call KFH_fnc_log;
};

KFH_fnc_getCheckpointMarkers = {
    private _markers = [];
    private _index = 1;

    while { true } do {
        private _markerName = format ["kfh_cp_%1", _index];

        if !(_markerName in allMapMarkers) exitWith {};

        _markers pushBack _markerName;
        _index = _index + 1;
    };

    _markers
};

KFH_fnc_getSpawnMarkers = {
    params ["_prefix"];

    private _markers = [];
    private _index = 1;

    while { true } do {
        private _markerName = format ["%1_%2", _prefix, _index];

        if !(_markerName in allMapMarkers) exitWith {};

        _markers pushBack _markerName;
        _index = _index + 1;
    };

    _markers
};

KFH_fnc_pruneAliveUnits = {
    params ["_units"];

    _units select { alive _x }
};

KFH_fnc_scaledEnemyCount = {
    params ["_baseCount"];

    private _players = [] call KFH_fnc_getScalingPlayerCount;
    private _targetPlayers = [] call KFH_fnc_getTargetPlayers;
    private _factor = (((_players max 1) / _targetPlayers) max 0.4) min 1.0;
    private _threatScale = [] call KFH_fnc_getThreatScale;

    ceil (_baseCount * _factor * _threatScale)
};

KFH_fnc_getWavesUntilRush = {
    private _currentWave = missionNamespace getVariable ["KFH_currentWave", 0];
    private _remainder = _currentWave mod KFH_rushEveryWaves;

    if (_remainder isEqualTo 0) exitWith { KFH_rushEveryWaves };

    KFH_rushEveryWaves - _remainder
};

KFH_fnc_restoreSavedLoadout = {
    params ["_unit"];

    if (isNull _unit) exitWith {};
    if !(alive _unit) exitWith {};

    private _damage = damage _unit;
    private _loadout = [_unit] call KFH_fnc_getSavedLoadout;
    if ((count _loadout) isEqualTo 0) exitWith {};

    _unit setUnitLoadout _loadout;
    _unit setDamage _damage;
    _unit setFatigue 0;
    [_unit, [], "restored saved loadout"] call KFH_fnc_saveLoadoutSnapshot;
    [format ["Saved loadout restored for %1.", name _unit]] call KFH_fnc_log;
};

KFH_fnc_grantRushReward = {
    params ["_checkpointIndex", "_waveNumber"];

    if !(missionNamespace getVariable ["KFH_rushActive", false]) exitWith {};

    missionNamespace setVariable ["KFH_rushActive", false, true];
    missionNamespace setVariable ["KFH_rushCheckpoint", -1, true];
    missionNamespace setVariable ["KFH_rushWaveNumber", -1, true];
    ["KFH_rushActive", false] call KFH_fnc_setState;

    {
        [_x] call KFH_fnc_restoreSavedLoadout;
        [_x] call KFH_fnc_updateSavedLoadout;
    } forEach ([] call KFH_fnc_getHumanPlayers);

    ["rush_wave_cleared_reason", [_waveNumber, _checkpointIndex]] call KFH_fnc_autoRevivePlayers;

    [KFH_rushPressureRelief, format ["Rush wave %1 broken", _waveNumber]] call KFH_fnc_reducePressure;

    ["rush_wave_broken", [_waveNumber]] call KFH_fnc_notifyAllKey;
    ["A3\Sounds_F\sfx\blip1.wss", 2.3, 0.56] remoteExecCall ["KFH_fnc_playUiCue", 0];
};

