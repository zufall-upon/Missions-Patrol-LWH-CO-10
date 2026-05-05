KFH_fnc_saveLoadoutSnapshot = {
    params ["_unit", ["_loadout", []], ["_reason", "snapshot"]];

    if (isNull _unit) exitWith {};
    if ((count _loadout) isEqualTo 0) then {
        _loadout = getUnitLoadout _unit;
    };

    _unit setVariable ["KFH_savedLoadout", _loadout, true];

    if (isPlayer _unit) then {
        private _uid = getPlayerUID _unit;
        if !(_uid isEqualTo "") then {
            missionNamespace setVariable [format ["KFH_savedLoadout_%1", _uid], _loadout, true];
        };
    };

    [format ["Loadout snapshot saved for %1 reason=%2.", name _unit, _reason]] call KFH_fnc_log;
};

KFH_fnc_updateSavedLoadout = {
    params ["_unit", ["_reason", "update"]];

    if (isNull _unit) exitWith {};
    if !(alive _unit) exitWith {};

    [_unit, [], _reason] call KFH_fnc_saveLoadoutSnapshot;
};

KFH_fnc_ensureNavigationItems = {
    params ["_unit"];

    if (isNull _unit) exitWith {};

    {
        if !(_x in assignedItems _unit) then {
            _unit linkItem _x;
        };
    } forEach ["ItemMap", "ItemCompass", "ItemWatch", "ItemRadio", "ItemGPS"];
};

KFH_fnc_getSavedLoadout = {
    params ["_unit", ["_corpse", objNull]];

    private _loadout = [];
    if (!isNull _corpse) then {
        _loadout = _corpse getVariable ["KFH_savedLoadout", []];
    };
    if (((count _loadout) isEqualTo 0) && {!isNull _unit}) then {
        _loadout = _unit getVariable ["KFH_savedLoadout", []];
    };
    if (((count _loadout) isEqualTo 0) && {!isNull _unit} && {isPlayer _unit}) then {
        private _uid = getPlayerUID _unit;
        if !(_uid isEqualTo "") then {
            _loadout = missionNamespace getVariable [format ["KFH_savedLoadout_%1", _uid], []];
        };
    };

    _loadout
};

KFH_fnc_installLoadoutSnapshotHandlers = {
    params ["_unit"];

    if (isNull _unit) exitWith {};
    if (_unit getVariable ["KFH_loadoutSnapshotHandlersInstalled", false]) exitWith {};

    _unit setVariable ["KFH_loadoutSnapshotHandlersInstalled", true];
    _unit addEventHandler ["InventoryClosed", {
        params ["_unit"];
        [_unit, "inventory closed"] call KFH_fnc_updateSavedLoadout;
    }];
    _unit addEventHandler ["Take", {
        params ["_unit"];
        [_unit, "item taken"] call KFH_fnc_updateSavedLoadout;
    }];
    _unit addEventHandler ["Put", {
        params ["_unit"];
        [_unit, "item put"] call KFH_fnc_updateSavedLoadout;
    }];
    _unit addEventHandler ["Killed", {
        params ["_unit"];
        if (isPlayer _unit) then {
            missionNamespace setVariable ["KFH_lastHumanCasualtyAt", time, true];
        };
        [_unit, [], "killed"] call KFH_fnc_saveLoadoutSnapshot;
    }];
};

KFH_fnc_installArsenalLoadoutTracker = {
    if !(hasInterface) exitWith {};
    if (missionNamespace getVariable ["KFH_arsenalLoadoutTrackerInstalled", false]) exitWith {};

    missionNamespace setVariable ["KFH_arsenalLoadoutTrackerInstalled", true];
    [missionNamespace, "arsenalClosed", {
        if (!isNull player && {alive player}) then {
            [player, "arsenal closed"] call KFH_fnc_updateSavedLoadout;
        };
    }] call BIS_fnc_addScriptedEventHandler;
};

KFH_fnc_installFlareSignalHandler = {
    params ["_unit"];

    if (isNull _unit) exitWith {};
    if (_unit getVariable ["KFH_flareSignalHandlerInstalled", false]) exitWith {};

    _unit setVariable ["KFH_flareSignalHandlerInstalled", true];
    _unit addEventHandler ["FiredMan", {
        params ["_unit", "_weapon", "_muzzle", "_mode", "_ammo", "_magazine", "_projectile"];

        if ((missionNamespace getVariable ["KFH_phase", "boot"]) isNotEqualTo "extract") exitWith {};
        if !([_weapon, _ammo] call KFH_fnc_isFlareShot) exitWith {};

        [_unit, getPosATL _unit, _weapon, _ammo] remoteExecCall ["KFH_fnc_reportFlareLaunch", 2];
    }];
};

