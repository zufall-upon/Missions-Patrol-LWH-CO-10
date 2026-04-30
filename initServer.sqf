call compile preprocessFileLineNumbers "scripts\fn_preInit.sqf";

if (!isServer) exitWith {};

[] call KFH_fnc_applyServerRouteParams;
[] call KFH_fnc_applyDynamicRoute;
if (missionNamespace getVariable ["KFH_caveLayoutEnabled", false]) then {
    [] call KFH_fnc_applyCaveLayout;
};
[] spawn KFH_fnc_serverInit;
