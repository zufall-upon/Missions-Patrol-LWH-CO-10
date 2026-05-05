KFH_fnc_buildTextBar = {
    params [
        ["_ratio", 0],
        ["_segments", 22]
    ];

    private _clamped = (_ratio max 0) min 1;
    private _filled = round (_clamped * _segments);
    private _empty = _segments - _filled;
    private _bar = "";

    for "_i" from 1 to _filled do {
        _bar = _bar + "#";
    };

    for "_i" from 1 to _empty do {
        _bar = _bar + "-";
    };

    _bar
};

KFH_fnc_ensureTopHudControls = {
    private _display = findDisplay 46;
    if (isNull _display) exitWith { false };

    private _panel = uiNamespace getVariable ["KFH_topHudPanel", controlNull];
    private _text = uiNamespace getVariable ["KFH_topHudText", controlNull];
    private _barBack = uiNamespace getVariable ["KFH_topHudBarBack", controlNull];
    private _barFill = uiNamespace getVariable ["KFH_topHudBarFill", controlNull];

    if (isNull _panel) then {
        _panel = _display ctrlCreate ["RscText", -1];
        uiNamespace setVariable ["KFH_topHudPanel", _panel];
    };
    if !(isNull _panel) then {
        _panel ctrlSetBackgroundColor [0, 0, 0, 0.58];
        _panel ctrlSetPosition [
            safeZoneX + safeZoneW * 0.365,
            safeZoneY + safeZoneH * 0.024,
            safeZoneW * 0.27,
            safeZoneH * 0.067
        ];
        _panel ctrlCommit 0;
    };

    if (isNull _text) then {
        _text = _display ctrlCreate ["RscStructuredText", -1];
        uiNamespace setVariable ["KFH_topHudText", _text];
    };
    if !(isNull _text) then {
        _text ctrlSetBackgroundColor [0, 0, 0, 0];
        _text ctrlSetPosition [
            safeZoneX + safeZoneW * 0.37,
            safeZoneY + safeZoneH * 0.029,
            safeZoneW * 0.26,
            safeZoneH * 0.05
        ];
        _text ctrlCommit 0;
    };

    if (isNull _barBack) then {
        _barBack = _display ctrlCreate ["RscText", -1];
        uiNamespace setVariable ["KFH_topHudBarBack", _barBack];
    };

    if (isNull _barFill) then {
        _barFill = _display ctrlCreate ["RscText", -1];
        uiNamespace setVariable ["KFH_topHudBarFill", _barFill];
    };

    true
};

KFH_fnc_clientTopHudLoop = {
    waitUntil { !isNull findDisplay 46 };

    while { true } do {
        if ([] call KFH_fnc_ensureTopHudControls) then {
            private _phase = missionNamespace getVariable ["KFH_phase", "boot"];
            private _wave = missionNamespace getVariable ["KFH_currentWave", 0];
            private _objectiveHostiles = missionNamespace getVariable ["KFH_objectiveHostiles", 0];
            private _totalHostiles = missionNamespace getVariable ["KFH_totalHostiles", 0];
            private _pendingHostiles = missionNamespace getVariable ["KFH_rushDebtCount", 0];
            private _displayTotalHostiles = _totalHostiles + _pendingHostiles;
            private _rushActive = missionNamespace getVariable ["KFH_rushActive", false];
            private _wavesUntilRush = [] call KFH_fnc_getWavesUntilRush;
            private _captureProgress = missionNamespace getVariable ["KFH_captureProgress", 0];
            private _captureLabel = missionNamespace getVariable ["KFH_captureLabel", ""];
            private _captureActive = missionNamespace getVariable ["KFH_captureActive", false];
            private _storyObjective = missionNamespace getVariable ["KFH_storyObjective", "RETURN TO BASE"];
            private _pressure = missionNamespace getVariable ["KFH_pressure", 0];
            private _checkpoint = missionNamespace getVariable ["KFH_currentCheckpoint", 0];
            private _totalCheckpoints = missionNamespace getVariable ["KFH_totalCheckpoints", 0];
            private _checkpointValue = missionNamespace getVariable ["KFH_currentCheckpointValue", "LOW"];
            private _returnDangerLabel = missionNamespace getVariable ["KFH_returnDangerLabel", "LOW"];
            private _nextWaveAt = missionNamespace getVariable ["KFH_nextWaveAt", time];
            private _nextWaveRemaining = ceil ((_nextWaveAt - time) max 0);
            private _rushLabel = if (_rushActive) then {
                "<t color='#ffb347'>RUSH ACTIVE</t>"
            } else {
                if (_wavesUntilRush <= 1) then {
                    "<t color='#ff6f61'>RUSH SOON</t>"
                } else {
                    format ["Rush in %1", _wavesUntilRush]
                }
            };
            private _showCaptureBar = _captureActive && {_captureProgress > 0.001};
            private _barColor = if (_showCaptureBar) then { [0.86, 0.58, 0.12, 0.96] } else { [0.25, 0.25, 0.25, 0.65] };
            private _text = uiNamespace getVariable ["KFH_topHudText", controlNull];
            private _barBack = uiNamespace getVariable ["KFH_topHudBarBack", controlNull];
            private _barFill = uiNamespace getVariable ["KFH_topHudBarFill", controlNull];
            private _barWidth = safeZoneW * 0.24 * ((_captureProgress max 0) min 1);

            private _hudText = parseText format [
                "<t align='center' size='0.92' font='PuristaBold'>WAVE %1 | NEXT %9s | %8</t><br/><t align='center' size='0.62'>CP %10/%11 %12 | Hostiles %3/%4 | Pressure %5/%6 | %2</t><br/><t align='center' size='0.58' color='#ffd166'>%7</t>",
                _wave,
                _rushLabel,
                _objectiveHostiles,
                _displayTotalHostiles,
                _pressure,
                KFH_pressureMax,
                _captureLabel,
                _storyObjective,
                _nextWaveRemaining,
                _checkpoint,
                _totalCheckpoints,
                _checkpointValue,
                _returnDangerLabel
            ];
            _text ctrlSetStructuredText _hudText;

            if (_showCaptureBar) then {
                _barBack ctrlShow true;
                _barFill ctrlShow true;
                _barBack ctrlSetBackgroundColor [0.15, 0.15, 0.15, 0.78];
                _barBack ctrlSetPosition [
                    safeZoneX + safeZoneW * 0.38,
                    safeZoneY + safeZoneH * 0.082,
                    safeZoneW * 0.24,
                    safeZoneH * 0.006
                ];
                _barBack ctrlCommit 0;

                _barFill ctrlSetBackgroundColor _barColor;
                _barFill ctrlSetPosition [
                    safeZoneX + safeZoneW * 0.38,
                    safeZoneY + safeZoneH * 0.082,
                    _barWidth,
                    safeZoneH * 0.006
                ];
                _barFill ctrlCommit 0;
            } else {
                _barBack ctrlShow false;
                _barFill ctrlShow false;
                _barBack ctrlSetBackgroundColor [0, 0, 0, 0];
                _barBack ctrlCommit 0;
                _barFill ctrlSetBackgroundColor [0, 0, 0, 0];
                _barFill ctrlSetPosition [
                    safeZoneX + safeZoneW * 0.38,
                    safeZoneY + safeZoneH * 0.082,
                    0,
                    safeZoneH * 0.006
                ];
                _barFill ctrlCommit 0;
            };
        };

        if ((missionNamespace getVariable ["KFH_phase", "boot"]) in ["complete", "failed"]) exitWith {};

        sleep KFH_topHudUpdateSeconds;
    };
};

KFH_fnc_clientHudLoop = {
    while { true } do {
        private _phase = missionNamespace getVariable ["KFH_phase", "boot"];
        private _checkpoint = missionNamespace getVariable ["KFH_currentCheckpoint", 0];
        private _total = missionNamespace getVariable ["KFH_totalCheckpoints", 0];
        private _pressure = missionNamespace getVariable ["KFH_pressure", 0];
        private _checkpointEvent = missionNamespace getVariable ["KFH_currentCheckpointEvent", "NONE"];
        private _checkpointValue = missionNamespace getVariable ["KFH_currentCheckpointValue", "LOW"];
        private _storyObjective = missionNamespace getVariable ["KFH_storyObjective", "RETURN TO BASE"];
        private _supplyLineStatus = missionNamespace getVariable ["KFH_supplyLineStatus", "0/0 ONLINE"];
        private _returnDangerLabel = missionNamespace getVariable ["KFH_returnDangerLabel", "LOW"];
        private _targetPlayers = [] call KFH_fnc_getTargetPlayers;
        private _alive = count (([] call KFH_fnc_getHumanPlayers) select { alive _x });
        private _downed = count ([] call KFH_fnc_getIncapacitatedPlayers);
        private _phaseLabel = toUpper _phase;
        private _pressureColor = if (_pressure >= 75) then {
            "#ff6b4a"
        } else {
            if (_pressure >= 45) then { "#ffd166" } else { "#86f7a7" }
        };
        private _dangerColor = switch (_returnDangerLabel) do {
            case "HIGH": { "#ff6b4a" };
            case "MED": { "#ffd166" };
            default { "#86f7a7" };
        };
        private _objectiveColor = switch (_storyObjective) do {
            case "BASE LOST": { "#ff6b4a" };
            case "ARSENAL OPTIONAL": { "#ffd166" };
            case "REACH LZ": { "#7bdff2" };
            default { "#ffffff" };
        };

        private _hudText = format [
            "<t font='PuristaBold' size='1.18' color='#f2f2f2'>KFH_Patrol_LWH_co10</t><br/>" +
            "<t size='0.78' color='#9fb3c8'>%1</t><br/>" +
            "<t size='0.96' color='%14'>%2</t><br/><br/>" +
            "<t size='0.84' color='#9fb3c8'>ROUTE</t> <t size='0.9' color='#ffffff'>CP %3/%4</t><br/>" +
            "<t size='0.84' color='#9fb3c8'>EVENT</t> <t size='0.9' color='#ffffff'>%5</t> <t color='#9fb3c8'>(%6)</t><br/>" +
            "<t size='0.84' color='#9fb3c8'>SUPPLY</t> <t size='0.9' color='#ffffff'>%7</t><br/>" +
            "<t size='0.84' color='#9fb3c8'>RETURN</t> <t size='0.9' color='%13'>%8</t><br/>" +
            "<t size='0.84' color='#9fb3c8'>HIVE</t> <t size='0.9' color='%12'>%9/%10</t><br/><br/>" +
            "<t size='0.84' color='#9fb3c8'>TEAM</t> <t size='0.9' color='#ffffff'>%11/%15 alive</t> <t color='#ff9f9f'>%16 down</t>",
            _phaseLabel,
            _storyObjective,
            _checkpoint,
            _total,
            _checkpointEvent,
            _checkpointValue,
            _supplyLineStatus,
            _returnDangerLabel,
            _pressure,
            KFH_pressureMax,
            _alive,
            _pressureColor,
            _dangerColor,
            _objectiveColor,
            _targetPlayers,
            _downed
        ];
        hintSilent parseText _hudText;

        if (_phase in ["complete", "failed"]) exitWith {};

        sleep (missionNamespace getVariable ["KFH_rightHudUpdateSeconds", 0.5]);
    };
};

KFH_fnc_clientLoadoutTracker = {
    while { true } do {
        if (!isNull player && alive player && !([player] call KFH_fnc_isIncapacitated)) then {
            [player] call KFH_fnc_updateSavedLoadout;

            private _cleanupUntil = missionNamespace getVariable ["KFH_reviveCleanupUntil", -1];
            if (_cleanupUntil > 0) then {
                if (time <= _cleanupUntil) then {
                    [] call KFH_fnc_restoreLocalPlayerControl;
                } else {
                    missionNamespace setVariable ["KFH_reviveCleanupUntil", -1];
                };
            };

            private _blurUntil = missionNamespace getVariable ["KFH_postReviveBlurUntil", -1];
            if (_blurUntil > 0) then {
                private _clearDamage = missionNamespace getVariable ["KFH_postReviveBlurClearDamage", 0.25];
                if (time >= _blurUntil || {(damage player) <= _clearDamage}) then {
                    [] call KFH_fnc_clearReviveVisualEffectsLocal;
                };
            };
        };

        if ((missionNamespace getVariable ["KFH_phase", "boot"]) in ["complete", "failed"]) exitWith {};

        sleep KFH_loadoutTrackSeconds;
    };
};

KFH_fnc_getSpectatorTargets = {
    private _source = ([] call KFH_fnc_getHumanPlayers) + (units group player);
    private _targets = _source arrayIntersect _source;

    _targets select {
        alive _x
    }
};

KFH_fnc_pickSpectatorTarget = {
    private _targets = [] call KFH_fnc_getSpectatorTargets;

    if ((count _targets) isEqualTo 0) exitWith { objNull };

    private _current = missionNamespace getVariable ["KFH_spectatorTarget", objNull];
    if (!isNull _current && {_current in _targets}) exitWith { _current };

    private _closest = objNull;
    private _closestDistance = 1e10;

    {
        private _distance = player distance2D _x;
        if (_distance < _closestDistance) then {
            _closest = _x;
            _closestDistance = _distance;
        };
    } forEach _targets;

    _closest
};

KFH_fnc_cycleSpectatorTarget = {
    params [["_direction", 1]];

    private _targets = [] call KFH_fnc_getSpectatorTargets;
    if ((count _targets) isEqualTo 0) exitWith { objNull };

    private _current = missionNamespace getVariable ["KFH_spectatorTarget", objNull];
    private _index = _targets find _current;
    if (_index < 0) then {
        _index = if (_direction >= 0) then { -1 } else { 0 };
    };

    _index = (_index + _direction + (count _targets)) mod (count _targets);
    private _target = _targets select _index;
    missionNamespace setVariable ["KFH_spectatorTarget", _target];
    ["spectating_target", [name _target]] call KFH_fnc_localNotifyKey;
    _target
};

KFH_fnc_installDownedSpectatorInput = {
    if (!hasInterface) exitWith {};
    if ((missionNamespace getVariable ["KFH_spectatorMouseEh", -1]) >= 0) exitWith {};

    private _display = findDisplay 46;
    if (isNull _display) exitWith {};

    private _handler = _display displayAddEventHandler ["MouseButtonDown", {
        params ["_display", "_button"];
        if !(missionNamespace getVariable ["KFH_spectatorActive", false]) exitWith { false };
        if (_button isEqualTo 0) exitWith {
            [1] call KFH_fnc_cycleSpectatorTarget;
            true
        };
        if (_button isEqualTo 1) exitWith {
            [-1] call KFH_fnc_cycleSpectatorTarget;
            true
        };
        false
    }];
    missionNamespace setVariable ["KFH_spectatorMouseEh", _handler];

    private _moveHandler = _display displayAddEventHandler ["MouseMoving", {
        params ["_display", "_x", "_y"];
        if !(missionNamespace getVariable ["KFH_spectatorActive", false]) exitWith { false };

        private _sensitivity = missionNamespace getVariable ["KFH_downedSpectatorMouseSensitivity", 7];
        private _pitchScale = missionNamespace getVariable ["KFH_downedSpectatorMousePitchScale", 0.65];
        private _deltaMax = missionNamespace getVariable ["KFH_downedSpectatorMouseDeltaMax", 0.025];
        private _deadzone = missionNamespace getVariable ["KFH_downedSpectatorMouseDeadzone", 0.00035];
        private _centerMode = missionNamespace getVariable ["KFH_downedSpectatorMouseCenterMode", true];
        private _center = missionNamespace getVariable ["KFH_downedSpectatorMouseCenter", [0.5, 0.5]];
        private _dx = _x;
        private _dy = _y;

        _dx = (_dx max -_deltaMax) min _deltaMax;
        _dy = (_dy max -_deltaMax) min _deltaMax;
        if ((abs _dx) < _deadzone) then { _dx = 0; };
        if ((abs _dy) < _deadzone) then { _dy = 0; };
        private _yaw = (missionNamespace getVariable ["KFH_spectatorYaw", getDirVisual player]) - (_dx * _sensitivity);
        private _pitch = ((missionNamespace getVariable ["KFH_spectatorPitch", 12]) + (_dy * _sensitivity * _pitchScale)) max -35 min 50;

        missionNamespace setVariable ["KFH_spectatorYaw", _yaw];
        missionNamespace setVariable ["KFH_spectatorPitch", _pitch];
        missionNamespace setVariable ["KFH_spectatorMouseLast", [_x, _y]];
        if (_centerMode && {(count _center) >= 2} && {((abs _dx) + (abs _dy)) > 0}) then {
            setMousePosition _center;
        };
        false
    }];
    missionNamespace setVariable ["KFH_spectatorMouseMoveEh", _moveHandler];

    private _wheelHandler = _display displayAddEventHandler ["MouseZChanged", {
        params ["_display", "_scroll"];
        if !(missionNamespace getVariable ["KFH_spectatorActive", false]) exitWith { false };

        private _distance = missionNamespace getVariable [
            "KFH_spectatorDistance",
            missionNamespace getVariable ["KFH_downedSpectatorDistance", 4.6]
        ];
        private _step = missionNamespace getVariable ["KFH_downedSpectatorZoomStep", 0.75];
        private _min = missionNamespace getVariable ["KFH_downedSpectatorDistanceMin", 2.2];
        private _max = missionNamespace getVariable ["KFH_downedSpectatorDistanceMax", 10];
        _distance = (_distance - (_scroll * _step)) max _min min _max;
        missionNamespace setVariable ["KFH_spectatorDistance", _distance];
        true
    }];
    missionNamespace setVariable ["KFH_spectatorMouseWheelEh", _wheelHandler];
};

KFH_fnc_removeDownedSpectatorInput = {
    private _handler = missionNamespace getVariable ["KFH_spectatorMouseEh", -1];
    private _display = findDisplay 46;
    if !(isNull _display) then {
        if (_handler >= 0) then {
            _display displayRemoveEventHandler ["MouseButtonDown", _handler];
        };
        private _moveHandler = missionNamespace getVariable ["KFH_spectatorMouseMoveEh", -1];
        if (_moveHandler >= 0) then {
            _display displayRemoveEventHandler ["MouseMoving", _moveHandler];
        };
        private _wheelHandler = missionNamespace getVariable ["KFH_spectatorMouseWheelEh", -1];
        if (_wheelHandler >= 0) then {
            _display displayRemoveEventHandler ["MouseZChanged", _wheelHandler];
        };
    };
    missionNamespace setVariable ["KFH_spectatorMouseEh", -1];
    missionNamespace setVariable ["KFH_spectatorMouseMoveEh", -1];
    missionNamespace setVariable ["KFH_spectatorMouseWheelEh", -1];
    missionNamespace setVariable ["KFH_spectatorMouseLast", []];
};

KFH_fnc_ensureDownedSpectatorInfoControls = {
    if (!hasInterface) exitWith {};

    private _display = findDisplay 46;
    if (isNull _display) exitWith {};

    private _text = uiNamespace getVariable ["KFH_spectatorInfoTextCtrl", controlNull];
    if !(isNull _text) exitWith {};

    private _bg = _display ctrlCreate ["RscText", -1];
    _text = _display ctrlCreate ["RscStructuredText", -1];
    _bg ctrlSetBackgroundColor [0, 0, 0, 0.48];
    _bg ctrlSetPosition [
        safeZoneX + safeZoneW * 0.31,
        safeZoneY + safeZoneH * 0.72,
        safeZoneW * 0.38,
        safeZoneH * 0.072
    ];
    _text ctrlSetPosition [
        safeZoneX + safeZoneW * 0.315,
        safeZoneY + safeZoneH * 0.727,
        safeZoneW * 0.37,
        safeZoneH * 0.055
    ];
    _bg ctrlCommit 0;
    _text ctrlCommit 0;

    uiNamespace setVariable ["KFH_spectatorInfoBgCtrl", _bg];
    uiNamespace setVariable ["KFH_spectatorInfoTextCtrl", _text];
};

KFH_fnc_removeDownedSpectatorInfoControls = {
    private _bg = uiNamespace getVariable ["KFH_spectatorInfoBgCtrl", controlNull];
    private _text = uiNamespace getVariable ["KFH_spectatorInfoTextCtrl", controlNull];

    if !(isNull _bg) then { ctrlDelete _bg; };
    if !(isNull _text) then { ctrlDelete _text; };

    uiNamespace setVariable ["KFH_spectatorInfoBgCtrl", controlNull];
    uiNamespace setVariable ["KFH_spectatorInfoTextCtrl", controlNull];
};

KFH_fnc_updateDownedSpectatorInfo = {
    params [["_target", objNull]];

    if (!hasInterface || {isNull player}) exitWith {};
    [] call KFH_fnc_ensureDownedSpectatorInfoControls;

    private _text = uiNamespace getVariable ["KFH_spectatorInfoTextCtrl", controlNull];
    if (isNull _text) exitWith {};

    private _rescuers = (([] call KFH_fnc_getPotentialRescuers) + ([player] call KFH_fnc_getHumanRescuersFor)) arrayIntersect (([] call KFH_fnc_getPotentialRescuers) + ([player] call KFH_fnc_getHumanRescuersFor));
    _rescuers = _rescuers select {
        !isNull _x &&
        {alive _x} &&
        {!([_x] call KFH_fnc_isIncapacitated)}
    };
    private _nearestText = "-";
    if ((count _rescuers) > 0) then {
        private _sorted = [_rescuers, [], {_x distance2D player}, "ASCEND"] call BIS_fnc_sortBy;
        private _nearest = _sorted select 0;
        _nearestText = format ["%1 %2m", name _nearest, round (_nearest distance2D player)];
    };
    private _targetText = if (isNull _target) then { "-" } else { name _target };
    private _info = ["downed_rescue_info", [_nearestText, _targetText]] call KFH_fnc_localizeAnnouncement;
    _text ctrlSetStructuredText parseText format [
        "<t align='center' font='RobotoCondensedBold' size='0.82' color='#ffdddd'>%1</t>",
        _info
    ];
    _text ctrlCommit 0;
};

KFH_fnc_startDownedSpectator = {
    if (missionNamespace getVariable ["KFH_spectatorActive", false]) exitWith {};

    private _camera = "camera" camCreate (getPosATL player);
    _camera cameraEffect ["INTERNAL", "BACK"];
    showCinemaBorder false;
    missionNamespace setVariable ["KFH_spectatorCamera", _camera];
    missionNamespace setVariable ["KFH_spectatorActive", true];
    missionNamespace setVariable ["KFH_spectatorYaw", getDirVisual player];
    missionNamespace setVariable ["KFH_spectatorPitch", 35];
    missionNamespace setVariable ["KFH_spectatorDistance", missionNamespace getVariable ["KFH_downedSpectatorDistance", 4.6]];
    missionNamespace setVariable ["KFH_spectatorMouseLast", []];
    if (missionNamespace getVariable ["KFH_downedSpectatorMouseCenterMode", true]) then {
        setMousePosition (missionNamespace getVariable ["KFH_downedSpectatorMouseCenter", [0.5, 0.5]]);
    };
    [] call KFH_fnc_installDownedSpectatorInput;
    [] call KFH_fnc_ensureDownedSpectatorInfoControls;
    ["downed_spectator_started"] call KFH_fnc_localNotifyKey;
};

KFH_fnc_stopDownedSpectator = {
    if !(missionNamespace getVariable ["KFH_spectatorActive", false]) exitWith {};

    private _camera = missionNamespace getVariable ["KFH_spectatorCamera", objNull];

    if !(isNull _camera) then {
        _camera cameraEffect ["TERMINATE", "BACK"];
        camDestroy _camera;
    };

    missionNamespace setVariable ["KFH_spectatorCamera", objNull];
    missionNamespace setVariable ["KFH_spectatorTarget", objNull];
    missionNamespace setVariable ["KFH_spectatorActive", false];
    missionNamespace setVariable ["KFH_spectatorMouseLast", []];
    [] call KFH_fnc_removeDownedSpectatorInput;
    [] call KFH_fnc_removeDownedSpectatorInfoControls;
};

KFH_fnc_getDownedSpectatorFocus = {
    params ["_target"];

    if (isNull _target) exitWith { [[0, 0, 0], objNull] };

    private _focusTarget = if ((vehicle _target) isEqualTo _target) then { _target } else { vehicle _target };
    private _height = if (_focusTarget isEqualTo _target) then {
        missionNamespace getVariable ["KFH_downedSpectatorHeight", 1.35]
    } else {
        missionNamespace getVariable ["KFH_teammateWorldMarkerVehicleHeight", 2.7]
    };

    [_focusTarget modelToWorldVisual [0, 0, _height], _focusTarget]
};

KFH_fnc_updateDownedSpectator = {
    private _camera = missionNamespace getVariable ["KFH_spectatorCamera", objNull];
    if (isNull _camera) exitWith {};

    private _target = [] call KFH_fnc_pickSpectatorTarget;
    if (isNull _target) exitWith {};

    missionNamespace setVariable ["KFH_spectatorTarget", _target];

    private _yaw = missionNamespace getVariable ["KFH_spectatorYaw", getDirVisual _target];
    private _pitch = missionNamespace getVariable ["KFH_spectatorPitch", 35];
    _pitch = (_pitch max (missionNamespace getVariable ["KFH_downedSpectatorPitchMin", 5])) min (missionNamespace getVariable ["KFH_downedSpectatorPitchMax", 85]);
    private _distance = missionNamespace getVariable [
        "KFH_spectatorDistance",
        missionNamespace getVariable ["KFH_downedSpectatorDistance", 4.6]
    ];
    private _focusData = [_target] call KFH_fnc_getDownedSpectatorFocus;
    private _focus = _focusData select 0;
    private _focusTarget = _focusData select 1;
    private _horizontal = _distance * cos _pitch;
    private _cameraPos = [
        (_focus select 0) + (sin _yaw) * _horizontal,
        (_focus select 1) + (cos _yaw) * _horizontal,
        (_focus select 2) + (sin _pitch) * _distance
    ];

    _camera camSetPos _cameraPos;
    private _lookDir = vectorNormalized (_focus vectorDiff _cameraPos);
    private _right = _lookDir vectorCrossProduct [0, 0, 1];
    if ((vectorMagnitude _right) < 0.001) then {
        _right = [1, 0, 0];
    } else {
        _right = vectorNormalized _right;
    };
    private _up = vectorNormalized (_right vectorCrossProduct _lookDir);
    _camera setVectorDirAndUp [_lookDir, _up];
    private _commit = if (!isNull _focusTarget && {_focusTarget isNotEqualTo _target}) then {
        0.05
    } else {
        missionNamespace getVariable ["KFH_downedSpectatorSmoothCommit", 0.08]
    };
    _camera camCommit _commit;
    [_target] call KFH_fnc_updateDownedSpectatorInfo;
};

KFH_fnc_downedSpectatorLoop = {
    while { true } do {
        waitUntil { !isNull player };

        if ([player] call KFH_fnc_isIncapacitated) then {
            [] call KFH_fnc_startDownedSpectator;
            [] call KFH_fnc_updateDownedSpectator;
        } else {
            [] call KFH_fnc_stopDownedSpectator;
        };

        if ((missionNamespace getVariable ["KFH_phase", "boot"]) in ["complete", "failed"]) exitWith {
            [] call KFH_fnc_stopDownedSpectator;
        };

        sleep (missionNamespace getVariable ["KFH_downedSpectatorUpdateSeconds", 0.05]);
    };
};

KFH_fnc_getTeammateMarkerUnitsLocal = {
    private _humans = [] call KFH_fnc_getHumanPlayers;
    private _debugTeammates = [] call KFH_fnc_getDebugTeammates;
    private _units = (_humans + _debugTeammates) arrayIntersect (_humans + _debugTeammates);
    _units select { !isNull _x && {alive _x} }
};

KFH_fnc_getTeammateWorldMarkerPositionLocal = {
    params ["_unit"];

    if (isNull _unit) exitWith { [0, 0, 0] };

    private _vehicle = vehicle _unit;
    if (_vehicle isEqualTo _unit) exitWith {
        private _pos = ASLToAGL (eyePos _unit);
        _pos set [2, (_pos select 2) + (missionNamespace getVariable ["KFH_teammateWorldMarkerHeight", 0.35])];
        _pos
    };

    _vehicle modelToWorldVisual [0, 0, missionNamespace getVariable ["KFH_teammateWorldMarkerVehicleHeight", 2.7]]
};

KFH_fnc_drawTeammateWorldMarkersLocal = {
    if (!hasInterface) exitWith {};
    if (isNull player) exitWith {};
    if !(missionNamespace getVariable ["KFH_teammateWorldMarkerEnabled", true]) exitWith {};

    private _phase = missionNamespace getVariable ["KFH_phase", "boot"];
    if (_phase in ["complete", "failed"]) exitWith {};

    private _maxDistance = missionNamespace getVariable ["KFH_teammateWorldMarkerMaxDistance", 900];
    private _icon = missionNamespace getVariable ["KFH_teammateWorldMarkerIcon", "\A3\ui_f\data\map\markers\military\dot_CA.paa"];
    private _size = missionNamespace getVariable ["KFH_teammateWorldMarkerSize", 0.55];
    private _textSize = missionNamespace getVariable ["KFH_teammateWorldMarkerTextSize", 0.033];
    private _normalColor = missionNamespace getVariable ["KFH_teammateWorldMarkerColor", [0.25, 0.65, 1, 0.78]];
    private _downedColor = missionNamespace getVariable ["KFH_teammateWorldMarkerDownedColor", [1, 0.18, 0.12, 1]];

    {
        private _unit = _x;
        if (!isNull _unit && {_unit isNotEqualTo player} && {alive _unit}) then {
            private _vehicle = vehicle _unit;
            private _distance = player distance2D _vehicle;
            if (_distance <= _maxDistance) then {
                private _downed = [_unit] call KFH_fnc_isIncapacitated;
                private _pos = [_unit] call KFH_fnc_getTeammateWorldMarkerPositionLocal;
                private _label = if (_downed) then {
                    if (([] call KFH_fnc_getAnnouncementLanguageIndex) isEqualTo 0) then {
                        format ["救助待ち %1 %2m", name _unit, round _distance]
                    } else {
                        format ["REVIVE %1 %2m", name _unit, round _distance]
                    }
                } else {
                    format ["%1 %2m", name _unit, round _distance]
                };
                if !((worldToScreen _pos) isEqualTo []) then {
                    drawIcon3D [
                        _icon,
                        if (_downed) then { _downedColor } else { _normalColor },
                        _pos,
                        if (_downed) then { _size * 1.35 } else { _size },
                        if (_downed) then { _size * 1.35 } else { _size },
                        45,
                        _label,
                        2,
                        if (_downed) then { _textSize * 1.18 } else { _textSize },
                        "RobotoCondensedBold",
                        "center",
                        false
                    ];
                };
            };
        };
    } forEach ([] call KFH_fnc_getTeammateMarkerUnitsLocal);
};

KFH_fnc_installTeammateWorldMarkersLocal = {
    if (!hasInterface) exitWith {};
    if (missionNamespace getVariable ["KFH_teammateWorldMarkerDrawEhInstalled", false]) exitWith {};

    missionNamespace setVariable ["KFH_teammateWorldMarkerDrawEhInstalled", true];
    missionNamespace setVariable [
        "KFH_teammateWorldMarkerDrawEh",
        addMissionEventHandler ["Draw3D", {
            [] call KFH_fnc_drawTeammateWorldMarkersLocal;
        }]
    ];
};

KFH_fnc_clientPlayerPositionMarkerLoop = {
    waitUntil { !isNull player };

    private _markers = [];

    while { true } do {
        if ((missionNamespace getVariable ["KFH_phase", "boot"]) in ["complete", "failed"]) exitWith {};

        private _hasNavigation = ("ItemGPS" in assignedItems player) || {"ItemMap" in assignedItems player};
        private _markerUnits = [] call KFH_fnc_getTeammateMarkerUnitsLocal;

        {
            _x params ["_unit", "_markerName"];
            if (!(_unit in _markerUnits)) then {
                deleteMarkerLocal _markerName;
                _markers set [_forEachIndex, objNull];
            };
        } forEach _markers;
        _markers = _markers select { !(_x isEqualTo objNull) };

        {
            private _unit = _x;
            private _entryIndex = _markers findIf { (_x select 0) isEqualTo _unit };
            private _markerName = "";
            if (_entryIndex < 0) then {
                _markerName = format ["KFH_local_player_pos_%1_%2", owner _unit, floor random 1000000];
                private _marker = createMarkerLocal [_markerName, getPosATL _unit];
                _marker setMarkerTypeLocal "mil_arrow2";
                _marker setMarkerSizeLocal [0.75, 0.75];
                _markers pushBack [_unit, _markerName];
            } else {
                _markerName = (_markers select _entryIndex) select 1;
            };

            private _isSelf = _unit isEqualTo player;
            private _isDowned = [_unit] call KFH_fnc_isIncapacitated;
            _markerName setMarkerColorLocal (if (_isDowned) then { "ColorRed" } else { if (_isSelf) then { "ColorBLUFOR" } else { "ColorWEST" } });
            _markerName setMarkerTextLocal (if (_isSelf) then { "YOU" } else { if (_isDowned) then { if (([] call KFH_fnc_getAnnouncementLanguageIndex) isEqualTo 0) then { format ["救助待ち %1", name _unit] } else { format ["REVIVE %1", name _unit] } } else { name _unit } });
            _markerName setMarkerTypeLocal (if (_isDowned) then { "mil_warning" } else { "mil_arrow2" });
            _markerName setMarkerSizeLocal (if (_isDowned) then { [0.95, 0.95] } else { [0.75, 0.75] });

            if (
                (missionNamespace getVariable ["KFH_playerPositionMarkerEnabled", true]) &&
                {_hasNavigation} &&
                {alive _unit}
            ) then {
                _markerName setMarkerPosLocal (getPosATL (vehicle _unit));
                _markerName setMarkerDirLocal (getDirVisual (vehicle _unit));
                _markerName setMarkerAlphaLocal 1;
            } else {
                _markerName setMarkerAlphaLocal 0;
            };
        } forEach _markerUnits;

        if !(_hasNavigation) then {
            {
                (_x select 1) setMarkerAlphaLocal 0;
            } forEach _markers;
        };

        sleep 0.35;
    };

    {
        deleteMarkerLocal (_x select 1);
    } forEach _markers;
};

KFH_fnc_showTacticalPingLocal = {
    params ["_pos", ["_senderName", "Team"], ["_pingId", floor random 1000000]];

    if ((count _pos) < 2) exitWith {};

    private _markerName = format ["KFH_ping_%1", _pingId];
    private _marker = createMarkerLocal [_markerName, _pos];
    _marker setMarkerTypeLocal "mil_warning";
    _marker setMarkerColorLocal (missionNamespace getVariable ["KFH_tacticalPingMarkerColor", "ColorOrange"]);
    _marker setMarkerTextLocal format ["PING %1", _senderName];
    _marker setMarkerSizeLocal [0.95, 0.95];
    ["map_pinged", [_senderName, mapGridPosition _pos]] call KFH_fnc_localNotifyKey;

    [_markerName] spawn {
        params ["_markerName"];
        sleep (missionNamespace getVariable ["KFH_tacticalPingLifetime", 45]);
        deleteMarkerLocal _markerName;
    };
};

KFH_fnc_broadcastTacticalPing = {
    params ["_pos", ["_senderName", "Team"]];

    if (!isServer) exitWith {
        [_pos, _senderName] remoteExecCall ["KFH_fnc_broadcastTacticalPing", 2];
    };

    private _pingId = (missionNamespace getVariable ["KFH_nextTacticalPingId", 0]) + 1;
    missionNamespace setVariable ["KFH_nextTacticalPingId", _pingId, true];
    [_pos, _senderName, _pingId] remoteExecCall ["KFH_fnc_showTacticalPingLocal", 0];
};

KFH_fnc_placeTacticalPingLocal = {
    params ["_pos"];

    if ((count _pos) < 2) exitWith {};
    [_pos, name player] remoteExecCall ["KFH_fnc_broadcastTacticalPing", 2];
};

KFH_fnc_installTacticalPingControls = {
    waitUntil { !isNull player };
    if (missionNamespace getVariable ["KFH_tacticalPingControlsStarted", false]) exitWith {};
    missionNamespace setVariable ["KFH_tacticalPingControlsStarted", true];

    [] spawn {
        private _lastDisplay = displayNull;
        while { true } do {
            waitUntil {
                sleep 0.25;
                !isNull findDisplay 12 || {(missionNamespace getVariable ["KFH_phase", "boot"]) in ["complete", "failed"]}
            };
            if ((missionNamespace getVariable ["KFH_phase", "boot"]) in ["complete", "failed"]) exitWith {};

            private _display = findDisplay 12;
            if (!isNull _display && {_display isNotEqualTo _lastDisplay}) then {
                _lastDisplay = _display;
                private _map = _display displayCtrl 51;
                if (!isNull _map) then {
                    _map ctrlAddEventHandler ["MouseButtonDblClick", {
                        params ["_control", "_button", "_x", "_y"];
                        if (_button isEqualTo 0) then {
                            private _pos = _control ctrlMapScreenToWorld [_x, _y];
                            [_pos] call KFH_fnc_placeTacticalPingLocal;
                        };
                    }];
                    _map ctrlAddEventHandler ["MouseButtonDown", {
                        params ["_control", "_button", "_x", "_y", "_shift", "_ctrl"];
                        if (_button isEqualTo 0 && {_ctrl}) then {
                            private _pos = _control ctrlMapScreenToWorld [_x, _y];
                            [_pos] call KFH_fnc_placeTacticalPingLocal;
                        };
                    }];
                };
            };

            waitUntil {
                sleep 0.25;
                isNull findDisplay 12 || {(missionNamespace getVariable ["KFH_phase", "boot"]) in ["complete", "failed"]}
            };
        };
    };
};

KFH_fnc_togglePerspective = {
    private _subject = vehicle player;

    if (cameraView isEqualTo "EXTERNAL") then {
        _subject switchCamera "INTERNAL";
    } else {
        _subject switchCamera "EXTERNAL";
    };
};

KFH_fnc_installPerspectiveControls = {
    waitUntil { !isNull player };

    if !(isNil { player getVariable "KFH_perspectiveActionId" }) then {
        player removeAction (player getVariable ["KFH_perspectiveActionId", -1]);
        player setVariable ["KFH_perspectiveActionId", nil];
    };

    [] spawn {
        waitUntil { !isNull findDisplay 46 };
        private _display = findDisplay 46;

        _display displayAddEventHandler ["KeyDown", {
            params ["", "_key"];
            private _personViewKeys = actionKeys "personView";

            if (_key in _personViewKeys) then {
                [] call KFH_fnc_togglePerspective;
                true
            } else {
                false
            };
        }];
    };
};

