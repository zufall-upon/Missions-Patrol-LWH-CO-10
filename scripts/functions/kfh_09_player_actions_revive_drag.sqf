KFH_fnc_isFriendlyDragTarget = {
    params ["_candidate", "_caller"];

    if (isNull _candidate || {isNull _caller}) exitWith { false };
    if (_candidate isEqualTo _caller) exitWith { false };
    if !(_candidate isKindOf "CAManBase") exitWith { false };

    private _needsHelp = (!alive _candidate) || {[_candidate] call KFH_fnc_isIncapacitated};
    if !(_needsHelp) exitWith { false };

    ((side group _candidate) isEqualTo (side group _caller)) ||
    {_candidate getVariable ["KFH_debugTeammate", false]} ||
    {_candidate getVariable ["KFH_soloWingman", false]}
};

KFH_fnc_getReviveActionBlockReason = {
    params ["_candidate", "_caller", ["_range", missionNamespace getVariable ["KFH_playerReviveActionDistance", 4]]];

    if (isNull _caller) exitWith { "caller_null" };
    if !(alive _caller) exitWith { "caller_dead" };
    if ([_caller] call KFH_fnc_isIncapacitated) exitWith { "caller_incapacitated" };
    if (_caller getVariable ["KFH_manualReviveBusy", false]) exitWith { "caller_busy" };
    if (isNull _candidate) exitWith { "target_null" };
    if (_candidate isEqualTo _caller) exitWith { "target_is_caller" };
    if !(_candidate isKindOf "CAManBase") exitWith { format ["target_not_man:%1", typeOf _candidate] };
    if !(alive _candidate) exitWith { "target_dead" };
    if !([_candidate] call KFH_fnc_isIncapacitated) exitWith {
        format [
            "target_not_downed forced=%1 life=%2 incap=%3",
            _candidate getVariable ["KFH_forcedDowned", false],
            lifeState _candidate,
            incapacitatedState _candidate
        ]
    };
    if ((vehicle _candidate) isNotEqualTo _candidate) exitWith { format ["needs_vehicle_pull vehicle=%1", typeOf (vehicle _candidate)] };
    if ((_candidate distance2D _caller) > _range) exitWith { format ["distance=%1 range=%2", round (_candidate distance2D _caller), _range] };
    if (_candidate getVariable ["KFH_manualReviveTargetBusy", false]) exitWith { format ["target_manual_busy medic=%1", name (_candidate getVariable ["KFH_manualReviveTargetMedic", objNull])] };
    if (_candidate getVariable ["KFH_aiReviveTargetBusy", false]) exitWith { format ["target_ai_busy medic=%1", name (_candidate getVariable ["KFH_aiReviveTargetMedic", objNull])] };
    if (_candidate getVariable ["KFH_draggedBodyBusy", false]) exitWith { format ["target_dragged_by=%1", name (_candidate getVariable ["KFH_draggedBy", objNull])] };
    if !(((side group _candidate) isEqualTo (side group _caller)) || {_candidate getVariable ["KFH_debugTeammate", false]} || {_candidate getVariable ["KFH_soloWingman", false]}) exitWith {
        format ["side_mismatch caller=%1 target=%2", side group _caller, side group _candidate]
    };

    "ok"
};

KFH_fnc_logReviveActionDiag = {
    params ["_caller", ["_context", "scan"]];

    if !(missionNamespace getVariable ["KFH_reviveActionDiagEnabled", true]) exitWith {};
    if (isNull _caller) exitWith {};

    private _now = diag_tickTime;
    private _nextAt = _caller getVariable ["KFH_nextReviveActionDiagAt", 0];
    if (_now < _nextAt) exitWith {};
    _caller setVariable ["KFH_nextReviveActionDiagAt", _now + (missionNamespace getVariable ["KFH_reviveActionDiagInterval", 6])];

    private _range = missionNamespace getVariable ["KFH_playerReviveActionDistance", 4];
    private _scanRange = _range max (missionNamespace getVariable ["KFH_bodyDragDistance", 3.2]) max (missionNamespace getVariable ["KFH_vehicleCasualtyPullActionDistance", 8]);
    private _candidates = nearestObjects [_caller, ["CAManBase"], _scanRange];
    {
        if ((_x distance2D _caller) <= _scanRange) then {
            _candidates pushBackUnique _x;
        };
    } forEach allDeadMen;
    private _cursor = cursorTarget;
    if (!isNull _cursor) then { _candidates pushBackUnique _cursor; };
    _candidates = _candidates select { _x isNotEqualTo _caller };

    private _entries = [];
    {
        private _reason = [_x, _caller, _range] call KFH_fnc_getReviveActionBlockReason;
        if (!(_reason isEqualTo "target_null")) then {
            _entries pushBack format [
                "%1 dist=%2 alive=%3 forced=%4 life=%5 incap=%6 vehicle=%7 reason=%8",
                name _x,
                round (_x distance2D _caller),
                alive _x,
                _x getVariable ["KFH_forcedDowned", false],
                lifeState _x,
                incapacitatedState _x,
                typeOf (vehicle _x),
                _reason
            ];
        };
    } forEach (_candidates select [0, 8]);

    if ((count _entries) > 0) then {
        [format ["Revive action diag (%1) caller=%2: %3", _context, name _caller, _entries joinString " | "]] call KFH_fnc_log;
    } else {
        [format ["Revive action diag (%1) caller=%2: no nearby candidates range=%3", _context, name _caller, _scanRange]] call KFH_fnc_log;
    };
};

KFH_fnc_findBodyDragGroundPosition = {
    params ["_anchor", ["_desiredPos", [0, 0, 0]]];

    private _radius = missionNamespace getVariable ["KFH_bodyDragGroundSearchRadius", 4];
    private _step = missionNamespace getVariable ["KFH_bodyDragGroundSearchStep", 0.8];
    private _zOffset = missionNamespace getVariable ["KFH_bodyDragGroundZOffset", 0.05];
    private _base = if (_desiredPos isEqualTo [0, 0, 0] && {!isNull _anchor}) then { getPosATL _anchor } else { _desiredPos };
    private _candidates = [_base];

    for "_r" from _step to _radius step _step do {
        for "_a" from 0 to 315 step 45 do {
            _candidates pushBack [
                (_base select 0) + ((sin _a) * _r),
                (_base select 1) + ((cos _a) * _r),
                0
            ];
        };
    };

    private _best = _base;
    {
        private _candidate = [_x select 0, _x select 1, 0];
        if !(surfaceIsWater _candidate) exitWith {
            _best = _candidate;
        };
    } forEach _candidates;

    _best set [2, _zOffset];
    _best
};

KFH_fnc_isFriendlyReviveTarget = {
    params ["_candidate", "_caller"];

    if !([_candidate, _caller] call KFH_fnc_isFriendlyDragTarget) exitWith { false };
    if !(alive _candidate) exitWith { false };
    if !([_candidate] call KFH_fnc_isIncapacitated) exitWith { false };
    if (_candidate getVariable ["KFH_manualReviveTargetBusy", false]) exitWith { false };
    if (_candidate getVariable ["KFH_draggedBodyBusy", false]) exitWith { false };

    true
};

KFH_fnc_isFriendlyBodyDragTarget = {
    params ["_candidate", "_caller"];

    if !([_candidate, _caller] call KFH_fnc_isFriendlyDragTarget) exitWith { false };
    if (_candidate getVariable ["KFH_draggedBodyBusy", false]) exitWith { false };

    true
};

KFH_fnc_getCursorOrNearbyAllyTarget = {
    params ["_caller", "_range", "_predicate"];

    if (isNull _caller) exitWith { objNull };

    private _cursor = cursorTarget;
    if (
        !isNull _cursor &&
        {(_cursor distance2D _caller) <= _range} &&
        {[_cursor, _caller] call _predicate}
    ) exitWith { _cursor };

    private _near = nearestObjects [_caller, ["CAManBase"], _range];
    {
        if ((_x distance2D _caller) <= _range) then {
            _near pushBackUnique _x;
        };
    } forEach allDeadMen;

    private _candidates = _near select { [_x, _caller] call _predicate };
    if ((count _candidates) isEqualTo 0) exitWith { objNull };

    ([_candidates, [], {_x distance2D _caller}, "ASCEND"] call BIS_fnc_sortBy) select 0
};

KFH_fnc_getNearbyDraggableAllyBody = {
    params ["_caller"];

    if (isNull _caller) exitWith { objNull };

    private _range = missionNamespace getVariable ["KFH_bodyDragDistance", 3.2];
    [_caller, _range, KFH_fnc_isFriendlyBodyDragTarget] call KFH_fnc_getCursorOrNearbyAllyTarget
};

KFH_fnc_getNearbyVehicleInjuredAlly = {
    params ["_caller"];

    if (isNull _caller) exitWith { objNull };

    private _range = missionNamespace getVariable ["KFH_vehicleCasualtyPullActionDistance", 8];
    private _vehicles = nearestObjects [_caller, ["LandVehicle", "Air", "Ship"], _range];
    private _candidates = [];

    {
        private _vehicle = _x;
        {
            if (
                !isNull _x &&
                {_x isNotEqualTo _caller} &&
                {_x isKindOf "CAManBase"} &&
                {[_x, _caller] call KFH_fnc_isFriendlyDragTarget} &&
                {vehicle _x isEqualTo _vehicle}
            ) then {
                _candidates pushBackUnique _x;
            };
        } forEach (crew _vehicle);
    } forEach _vehicles;

    if ((count _candidates) isEqualTo 0) exitWith { objNull };

    ([_candidates, [], {_caller distance2D (vehicle _x)}, "ASCEND"] call BIS_fnc_sortBy) select 0
};

KFH_fnc_getNearbyReviveAlly = {
    params ["_caller"];

    if (isNull _caller) exitWith { objNull };

    private _range = missionNamespace getVariable ["KFH_playerReviveActionDistance", 4];
    [_caller, _range, KFH_fnc_isFriendlyReviveTarget] call KFH_fnc_getCursorOrNearbyAllyTarget
};

KFH_fnc_reviveNearbyAllyLocal = {
    params [["_caller", player]];

    if (isNull _caller || {!alive _caller}) exitWith {};
    if (_caller getVariable ["KFH_manualReviveBusy", false]) exitWith {};

    private _casualty = [_caller] call KFH_fnc_getNearbyReviveAlly;
    if (isNull _casualty) exitWith {
        [_caller, "manual-revive-no-target"] call KFH_fnc_logReviveActionDiag;
        ["revive_no_ally"] call KFH_fnc_localNotifyKey;
    };
    if ((vehicle _casualty) isNotEqualTo _casualty) exitWith {
        [format ["Manual revive blocked by vehicle casualty caller=%1 casualty=%2 vehicle=%3", name _caller, name _casualty, typeOf (vehicle _casualty)]] call KFH_fnc_log;
        ["revive_pull_vehicle_first"] call KFH_fnc_localNotifyKey;
    };

    _caller setVariable ["KFH_manualReviveBusy", true];
    _casualty setVariable ["KFH_manualReviveTargetBusy", true, true];
    _casualty setVariable ["KFH_manualReviveTargetMedic", _caller, true];
    [_caller] call KFH_fnc_playManualReviveAnimationLocal;
    [_caller, _casualty] spawn {
        params ["_caller", "_casualty"];

        private _duration = missionNamespace getVariable ["KFH_playerReviveDuration", 4];
        sleep _duration;

        if (
            !isNull _caller &&
            {!isNull _casualty} &&
            {alive _caller} &&
            {alive _casualty} &&
            {[_casualty] call KFH_fnc_isIncapacitated} &&
            {(_caller distance2D _casualty) <= ((missionNamespace getVariable ["KFH_playerReviveActionDistance", 4]) + 0.75)}
        ) then {
            [_casualty] call KFH_fnc_reviveUnitFromDowned;
            ["manual_revived_player", [name _caller, name _casualty]] call KFH_fnc_notifyAllKey;
        } else {
            [format [
                "Manual revive interrupted caller=%1 casualty=%2 callerAlive=%3 casualtyAlive=%4 downed=%5 distance=%6",
                if (isNull _caller) then {"<null>"} else {name _caller},
                if (isNull _casualty) then {"<null>"} else {name _casualty},
                !isNull _caller && {alive _caller},
                !isNull _casualty && {alive _casualty},
                !isNull _casualty && {[_casualty] call KFH_fnc_isIncapacitated},
                if (isNull _caller || {isNull _casualty}) then {-1} else {round (_caller distance2D _casualty)}
            ]] call KFH_fnc_log;
            ["revive_interrupted"] call KFH_fnc_localNotifyKey;
        };

        if (!isNull _caller) then {
            _caller setVariable ["KFH_manualReviveBusy", false];
        };
        if (!isNull _casualty) then {
            _casualty setVariable ["KFH_manualReviveTargetBusy", false, true];
            _casualty setVariable ["KFH_manualReviveTargetMedic", objNull, true];
        };
    };
};

KFH_fnc_playManualReviveAnimationLocal = {
    params ["_unit"];

    if (isNull _unit) exitWith {};

    private _weapon = currentWeapon _unit;
    private _prone = (stance _unit) isEqualTo "PRONE";
    private _anim = switch (true) do {
        case (_weapon isEqualTo "" && {!_prone}): { "AinvPknlMstpSlayWnonDnon_medicOther" };
        case (_weapon isEqualTo "" && {_prone}): { "AinvPpneMstpSlayWnonDnon_medicOther" };
        case (_weapon isEqualTo primaryWeapon _unit && {!_prone}): { "AinvPknlMstpSlayWrflDnon_medicOther" };
        case (_weapon isEqualTo primaryWeapon _unit && {_prone}): { "AinvPpneMstpSlayWrflDnon_medicOther" };
        case (_weapon isEqualTo secondaryWeapon _unit && {!_prone}): { "AinvPknlMstpSlayWlnrDnon_medicOther" };
        case (_weapon isEqualTo handgunWeapon _unit && {!_prone}): { "AinvPknlMstpSlayWpstDnon_medicOther" };
        case (_weapon isEqualTo handgunWeapon _unit && {_prone}): { "AinvPpneMstpSlayWpstDnon_medicOther" };
        default { "AinvPknlMstpSlayWnonDnon_medicOther" };
    };

    _unit playMove _anim;
};

KFH_fnc_playDragCarrierAnimationLocal = {
    params ["_unit"];

    if (isNull _unit) exitWith {};

    private _weapon = currentWeapon _unit;
    private _anim = switch (true) do {
        case (_weapon isEqualTo ""): { "AcinPknlMstpSnonWnonDnon" };
        case (_weapon isEqualTo binocular _unit): { "AcinPknlMstpSnonWnonDnon" };
        case (_weapon isEqualTo primaryWeapon _unit): { "AcinPknlMstpSrasWrflDnon" };
        case (_weapon isEqualTo secondaryWeapon _unit): { "AcinPknlMstpSrasWrflDnon" };
        case (_weapon isEqualTo handgunWeapon _unit): { "AcinPknlMstpSnonWpstDnon" };
        default { "AcinPknlMstpSnonWnonDnon" };
    };

    [_unit, _anim] remoteExec ["playMove", 0, false];
};

KFH_fnc_playDragReleaseAnimationLocal = {
    params ["_unit"];

    if (isNull _unit) exitWith {};

    private _weapon = currentWeapon _unit;
    private _anim = switch (true) do {
        case (_weapon isEqualTo ""): { "AmovPknlMstpSnonWnonDnon" };
        case (_weapon isEqualTo binocular _unit): { "AmovPknlMstpSoptWbinDnon" };
        case (_weapon isEqualTo primaryWeapon _unit): { "AmovPknlMstpSrasWrflDnon" };
        case (_weapon isEqualTo secondaryWeapon _unit): { "AmovPknlMstpSrasWrflDnon" };
        case (_weapon isEqualTo handgunWeapon _unit): { "AmovPknlMstpSrasWpstDnon" };
        default { "AmovPknlMstpSnonWnonDnon" };
    };

    [_unit, _anim] remoteExec ["playMove", 0, false];
};

KFH_fnc_pullNearbyVehicleInjuredLocal = {
    params [["_caller", player]];

    private _casualty = [_caller] call KFH_fnc_getNearbyVehicleInjuredAlly;
    if (isNull _casualty) exitWith {
        [_caller, "manual-pull-no-target"] call KFH_fnc_logReviveActionDiag;
        ["pull_no_vehicle_injured"] call KFH_fnc_localNotifyKey;
    };

    [format ["Manual pull vehicle injured caller=%1 casualty=%2 vehicle=%3", name _caller, name _casualty, typeOf (vehicle _casualty)]] call KFH_fnc_log;
    _caller playActionNow (missionNamespace getVariable ["KFH_vehicleCasualtyPullAnimation", "MedicOther"]);
    [_casualty, _caller, "manual pull injured"] call KFH_fnc_extractCasualtyFromVehicle;
    ["pull_vehicle_injured_clear"] call KFH_fnc_localNotifyKey;
};

KFH_fnc_dropDraggedBodyLocal = {
    params [["_caller", player]];

    private _body = _caller getVariable ["KFH_draggedBody", objNull];
    if (isNull _body) exitWith {};

    detach _body;
    private _dropPos = [_caller, _caller modelToWorld (missionNamespace getVariable ["KFH_bodyDragDropOffset", [0, -1.15, 0]])] call KFH_fnc_findBodyDragGroundPosition;
    _body setPosATL _dropPos;
    _body setVariable ["KFH_draggedBodyBusy", false, true];
    _body setVariable ["KFH_draggedBy", objNull, true];
    _body setVariable ["KFH_dragPoseRefreshActive", false, true];
    _caller setVariable ["KFH_draggedBody", objNull];
    _caller forceWalk false;
    _caller setAnimSpeedCoef (missionNamespace getVariable ["KFH_playerAnimSpeedCoef", 1]);
    [_caller] call KFH_fnc_playDragReleaseAnimationLocal;

    if (alive _body) then {
        _body enableAI "MOVE";
        [_body] remoteExecCall ["KFH_fnc_applyDownedWaitPoseLocal", 0];
    };

    [format ["Drag dropped caller=%1 body=%2 pos=%3", name _caller, name _body, _dropPos]] call KFH_fnc_log;
    ["drag_body_dropped"] call KFH_fnc_localNotifyKey;
};

KFH_fnc_cleanupDraggingBodyLocal = {
    params ["_caller", "_body", ["_reason", "cleanup"]];

    if (!isNull _caller) then {
        _caller setVariable ["KFH_draggedBody", objNull];
        _caller forceWalk false;
        _caller setAnimSpeedCoef (missionNamespace getVariable ["KFH_playerAnimSpeedCoef", 1]);
        [_caller] call KFH_fnc_playDragReleaseAnimationLocal;
    };

    if (!isNull _body) then {
        detach _body;
        if (alive _body && {[_body] call KFH_fnc_isIncapacitated}) then {
            private _anchor = if (isNull _caller) then {_body} else {_caller};
            private _desiredPos = if (isNull _caller) then {
                getPosATL _body
            } else {
                _caller modelToWorld (missionNamespace getVariable ["KFH_bodyDragDropOffset", [0, -1.15, 0]])
            };
            _body setPosATL ([_anchor, _desiredPos] call KFH_fnc_findBodyDragGroundPosition);
        };
        _body setVariable ["KFH_draggedBodyBusy", false, true];
        _body setVariable ["KFH_draggedBy", objNull, true];
        _body setVariable ["KFH_dragPoseRefreshActive", false, true];
        if (alive _body && {[_body] call KFH_fnc_isIncapacitated}) then {
            [_body] remoteExecCall ["KFH_fnc_applyDownedWaitPoseLocal", 0];
        };
    };

    [format [
        "Drag cleanup reason=%1 caller=%2 body=%3 attached=%4",
        _reason,
        if (isNull _caller) then {"<null>"} else {name _caller},
        if (isNull _body) then {"<null>"} else {name _body},
        if (isNull _body) then {false} else {attachedTo _body}
    ]] call KFH_fnc_log;
};

KFH_fnc_applyDraggedBodyPoseLocal = {
    params ["_body"];

    if (isNull _body) exitWith {};
    if !(alive _body) exitWith {};
    if !(_body getVariable ["KFH_draggedBodyBusy", false]) exitWith {};

    private _anim = missionNamespace getVariable ["KFH_bodyDragAnimation", "AinjPpneMstpSnonWrflDnon"];
    _body setUnitPos "DOWN";
    _body switchMove _anim;
};

KFH_fnc_startDraggedBodyPoseRefresh = {
    params ["_body"];

    if (isNull _body) exitWith {};
    if (_body getVariable ["KFH_dragPoseRefreshActive", false]) exitWith {};

    _body setVariable ["KFH_dragPoseRefreshActive", true, true];
    [_body] spawn {
        params ["_trackedBody"];

        private _interval = missionNamespace getVariable ["KFH_bodyDragPoseRefreshSeconds", 0.8];
        while {
            !isNull _trackedBody &&
            {alive _trackedBody} &&
            {_trackedBody getVariable ["KFH_draggedBodyBusy", false]}
        } do {
            [_trackedBody] remoteExecCall ["KFH_fnc_applyDraggedBodyPoseLocal", 0];
            sleep _interval;
        };

        if (!isNull _trackedBody) then {
            _trackedBody setVariable ["KFH_dragPoseRefreshActive", false, true];
        };
    };
};

KFH_fnc_startDraggingBodyLocal = {
    params [["_caller", player]];

    if !(missionNamespace getVariable ["KFH_bodyDragEnabled", true]) exitWith {};
    if !(isNull (_caller getVariable ["KFH_draggedBody", objNull])) exitWith {};

    private _body = [_caller] call KFH_fnc_getNearbyDraggableAllyBody;
    if (isNull _body) exitWith {
        [_caller, "manual-drag-no-target"] call KFH_fnc_logReviveActionDiag;
        ["drag_no_body"] call KFH_fnc_localNotifyKey;
    };

    _body setVariable ["KFH_draggedBodyBusy", true, true];
    _body setVariable ["KFH_draggedBy", _caller, true];
    _caller setVariable ["KFH_draggedBody", _body];
    _caller forceWalk true;
    _caller setAnimSpeedCoef (missionNamespace getVariable ["KFH_bodyDragCarrierAnimSpeedCoef", 0.55]);
    [_caller] call KFH_fnc_playDragCarrierAnimationLocal;

    if (alive _body) then {
        _body disableAI "MOVE";
    };

    _body attachTo [_caller, missionNamespace getVariable ["KFH_bodyDragAttachOffset", [0, -1.25, 0.05]]];
    _body setDir (missionNamespace getVariable ["KFH_bodyDragAttachDir", 0]);
    [_body] call KFH_fnc_startDraggedBodyPoseRefresh;
    [_body] remoteExecCall ["KFH_fnc_applyDraggedBodyPoseLocal", 0];
    [format ["Drag started caller=%1 body=%2 forced=%3 alive=%4", name _caller, name _body, _body getVariable ["KFH_forcedDowned", false], alive _body]] call KFH_fnc_log;
    ["drag_started"] call KFH_fnc_localNotifyKey;

    [_caller, _body] spawn {
        params ["_caller", "_body"];
        waitUntil {
            sleep 0.2;
            isNull _caller ||
            {isNull _body} ||
            {!alive _caller} ||
            {[_caller] call KFH_fnc_isIncapacitated} ||
            {!alive _body} ||
            {!([_body] call KFH_fnc_isIncapacitated)} ||
            {isNull (_caller getVariable ["KFH_draggedBody", objNull])} ||
            {isNull (_body getVariable ["KFH_draggedBy", objNull])}
        };
        [_caller, _body, "watchdog"] call KFH_fnc_cleanupDraggingBodyLocal;
    };
};

KFH_fnc_canManualReviveLocal = {
    params [["_caller", player]];

    private _ok = !isNull _caller &&
    {alive _caller} &&
    {!([_caller] call KFH_fnc_isIncapacitated)} &&
    {!(_caller getVariable ["KFH_manualReviveBusy", false])} &&
    {!isNull ([_caller] call KFH_fnc_getNearbyReviveAlly)};

    if (!_ok) then {
        [_caller, "manual-revive-action-hidden"] call KFH_fnc_logReviveActionDiag;
    };

    _ok
};

KFH_fnc_canManualDragLocal = {
    params [["_caller", player]];

    private _ok = (missionNamespace getVariable ["KFH_bodyDragEnabled", true]) &&
    {!isNull _caller} &&
    {alive _caller} &&
    {!([_caller] call KFH_fnc_isIncapacitated)} &&
    {isNull (_caller getVariable ["KFH_draggedBody", objNull])} &&
    {!isNull ([_caller] call KFH_fnc_getNearbyDraggableAllyBody)};

    if (!_ok) then {
        [_caller, "manual-drag-action-hidden"] call KFH_fnc_logReviveActionDiag;
    };

    _ok
};

KFH_fnc_canManualDropDraggedBodyLocal = {
    params [["_caller", player]];

    !isNull _caller &&
    {alive _caller} &&
    {!isNull (_caller getVariable ["KFH_draggedBody", objNull])}
};

KFH_fnc_installPlayerCombatActions = {
    waitUntil { !isNull player };

    if (isNil { player getVariable "KFH_vehicleFlipActionId" }) then {
        private _flipActionId = player addAction [
            ["action_flip_vehicle"] call KFH_fnc_localizeAnnouncement,
            {
                params ["_target", "_caller"];
                private _vehicle = [_caller] call KFH_fnc_getNearbyFlippableVehicle;
                if (isNull _vehicle) exitWith {
                    ["flip_no_vehicle"] call KFH_fnc_localNotifyKey;
                };
                [_vehicle, _caller] remoteExecCall ["KFH_fnc_flipVehicleServer", 2];
            },
            nil,
            1.8,
            true,
            true,
            "",
            "missionNamespace getVariable ['KFH_vehicleFlipEnabled', true] && {!isNull ([_this] call KFH_fnc_getNearbyFlippableVehicle)}"
        ];

        player setVariable ["KFH_vehicleFlipActionId", _flipActionId];
    };

    if (isNil { player getVariable "KFH_reviveAllyActionId" }) then {
        private _reviveActionId = player addAction [
            ["action_revive_ally"] call KFH_fnc_localizeAnnouncement,
            {
                params ["_target", "_caller"];
                [_caller] call KFH_fnc_reviveNearbyAllyLocal;
            },
            nil,
            1.9,
            true,
            true,
            "",
            "[_this] call KFH_fnc_canManualReviveLocal"
        ];

        player setVariable ["KFH_reviveAllyActionId", _reviveActionId];
    };

    if (isNil { player getVariable "KFH_pullVehicleInjuredActionId" }) then {
        private _pullActionId = player addAction [
            ["action_pull_vehicle_injured"] call KFH_fnc_localizeAnnouncement,
            {
                params ["_target", "_caller"];
                [_caller] call KFH_fnc_pullNearbyVehicleInjuredLocal;
            },
            nil,
            1.85,
            false,
            true,
            "",
            "missionNamespace getVariable ['KFH_vehicleCasualtyPullEnabled', true] && {alive _this} && {!isNull ([_this] call KFH_fnc_getNearbyVehicleInjuredAlly)}"
        ];

        player setVariable ["KFH_pullVehicleInjuredActionId", _pullActionId];
    };

    if (isNil { player getVariable "KFH_dragBodyActionId" }) then {
        private _dragActionId = player addAction [
            ["action_drag_body"] call KFH_fnc_localizeAnnouncement,
            {
                params ["_target", "_caller"];
                [_caller] call KFH_fnc_startDraggingBodyLocal;
            },
            nil,
            1.7,
            false,
            true,
            "",
            "[_this] call KFH_fnc_canManualDragLocal"
        ];

        player setVariable ["KFH_dragBodyActionId", _dragActionId];
    };

    if (isNil { player getVariable "KFH_dropBodyActionId" }) then {
        private _dropActionId = player addAction [
            ["action_drop_body"] call KFH_fnc_localizeAnnouncement,
            {
                params ["_target", "_caller"];
                [_caller] call KFH_fnc_dropDraggedBodyLocal;
            },
            nil,
            1.75,
            false,
            true,
            "",
            "[_this] call KFH_fnc_canManualDropDraggedBodyLocal"
        ];

        player setVariable ["KFH_dropBodyActionId", _dropActionId];
    };
};
