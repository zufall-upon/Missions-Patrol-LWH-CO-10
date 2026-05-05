call compile preprocessFileLineNumbers "scripts\fn_preInit.sqf";

if (!hasInterface) exitWith {};

[] call KFH_fnc_applyLocalVisibilityParams;

[] spawn {
    waitUntil { !isNull player };
    [player] call KFH_fnc_applyStarterLoadout;
    if (missionNamespace getVariable ["KFH_caveLayoutEnabled", false]) then {
        [] call KFH_fnc_placePlayerAtCaveStartOnce;
    };
    if (missionNamespace getVariable ["KFH_dynamicRouteEnabled", false]) then {
        waitUntil {
            !(missionNamespace getVariable ["KFH_dynamicRouteEnabled", false]) ||
            {missionNamespace getVariable ["KFH_dynamicRouteBuilt", false]}
        };
        if (didJIP) then {
            [] call KFH_fnc_placeJipPlayerNearLeaderOnce;
        } else {
            [] call KFH_fnc_placePlayerAtDynamicStartOnce;
        };
    };
    [player] call KFH_fnc_applyFriendlyFireMitigation;
    [player] call KFH_fnc_installPlayerDownedProtection;
    ["Preload"] call BIS_fnc_arsenal;
    [] call KFH_fnc_installArsenalLoadoutTracker;
    sleep KFH_starterApplyDelay;
    [player] call KFH_fnc_forceInitialStarterLoadout;
    [player] call KFH_fnc_applyPrototypeCarryCapacity;
    [player] call KFH_fnc_installLoadoutSnapshotHandlers;
    [player] call KFH_fnc_installFlareSignalHandler;
    player setVariable ["KFH_clientReadyForInitialWave", true, true];
    player addEventHandler ["Respawn", {
        params ["_unit", "_corpse"];
        private _restoreAsDowned = missionNamespace getVariable ["KFH_respawnAsDownedPending", false];
        private _downedPos = missionNamespace getVariable ["KFH_respawnAsDownedPos", []];
        private _downedDir = missionNamespace getVariable ["KFH_respawnAsDownedDir", getDir _unit];
        private _downedVehicle = missionNamespace getVariable ["KFH_respawnAsDownedVehicle", objNull];
        private _wasVehicleCasualty = missionNamespace getVariable ["KFH_respawnAsDownedWasVehicle", false];

        missionNamespace setVariable ["KFH_respawnAsDownedPending", false];
        missionNamespace setVariable ["KFH_respawnAsDownedVehicle", objNull];
        missionNamespace setVariable ["KFH_respawnAsDownedWasVehicle", false];
        missionNamespace setVariable ["KFH_lastHumanCasualtyAt", time, true];
        [_unit, !_restoreAsDowned] call KFH_fnc_clearDownedState;
        [_unit, _corpse, _restoreAsDowned, _downedPos, _downedDir, _downedVehicle, _wasVehicleCasualty] spawn {
            params ["_unit", "_corpse", "_restoreAsDowned", "_downedPos", "_downedDir", "_downedVehicle", "_wasVehicleCasualty"];
            sleep 0.05;
            private _savedLoadout = [_unit, _corpse] call KFH_fnc_getSavedLoadout;

            if ((count _savedLoadout) > 0) then {
                _unit setUnitLoadout _savedLoadout;
                [_unit] call KFH_fnc_ensureNavigationItems;
                [_unit] call KFH_fnc_applyPrototypeCarryCapacity;
                [_unit, [], "respawn restored saved loadout"] call KFH_fnc_saveLoadoutSnapshot;
                [format ["Respawn restored saved loadout for %1.", name _unit]] call KFH_fnc_log;
            } else {
                [_unit] call KFH_fnc_applyStarterLoadout;
                [_unit] call KFH_fnc_applyPrototypeCarryCapacity;
            };

            [_unit] call KFH_fnc_installLoadoutSnapshotHandlers;
            [_unit] call KFH_fnc_installFlareSignalHandler;
            [_unit] call KFH_fnc_applyFriendlyFireMitigation;
            [_unit] call KFH_fnc_installPlayerDownedProtection;
            [_unit] call KFH_fnc_applyPrototypeCarryCapacity;
            _unit setVariable ["KFH_clientReadyForInitialWave", true, true];
            if (_restoreAsDowned) then {
                private _restoredInsideVehicle = false;
                if (_wasVehicleCasualty && {!isNull _downedVehicle}) then {
                    _unit setPosATL (getPosATL _downedVehicle);
                    _unit moveInCargo _downedVehicle;
                    if ((vehicle _unit) isEqualTo _unit) then {
                        _unit moveInAny _downedVehicle;
                    };
                    _restoredInsideVehicle = (vehicle _unit) isNotEqualTo _unit;
                    if (_restoredInsideVehicle) then {
                        _unit setVariable ["KFH_downedInsideVehicle", vehicle _unit, true];
                        _unit setVariable ["KFH_needsVehiclePull", true, true];
                    };
                };
                if (!_restoredInsideVehicle && {(count _downedPos) >= 2}) then {
                    _unit setPosATL _downedPos;
                    _unit setDir _downedDir;
                };
                [_unit, objNull, "respawn fallback downed restore"] call KFH_fnc_forceUnitDowned;
                [format [
                    "Respawn fallback restored %1 to downed state at casualty position (vehicle=%2 restoredInside=%3).",
                    name _unit,
                    if (_wasVehicleCasualty && {!isNull _downedVehicle}) then { typeOf _downedVehicle } else { "none" },
                    _restoredInsideVehicle
                ]] call KFH_fnc_log;
            } else {
                [] call KFH_fnc_scheduleLocalReviveCleanup;
            };
            [] spawn KFH_fnc_installPerspectiveControls;
            [] spawn KFH_fnc_installPlayerCombatActions;
            [] spawn KFH_fnc_installTacticalPingControls;
        };
    }];
    ["Local player ready. Starter kit issued."] call KFH_fnc_log;
};

[] spawn KFH_fnc_setupSupportActions;
[] spawn KFH_fnc_clientTopHudLoop;
if (missionNamespace getVariable ["KFH_rightHudEnabled", false]) then {
    [] spawn KFH_fnc_clientHudLoop;
};
[] spawn KFH_fnc_clientLoadoutTracker;
[] spawn KFH_fnc_downedSpectatorLoop;
[] spawn KFH_fnc_clientStaminaAssistLoop;
[] spawn KFH_fnc_clientPlayerPresenceLoop;
[] spawn KFH_fnc_clientPlayerPositionMarkerLoop;
[] call KFH_fnc_installTeammateWorldMarkersLocal;
[] spawn KFH_fnc_installTacticalPingControls;
[] spawn KFH_fnc_installPerspectiveControls;
[] spawn KFH_fnc_installPlayerCombatActions;
