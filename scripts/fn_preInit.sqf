diag_log "[KFH] Bootstrap compile starting.";

if (
    (isNil "KFH_targetPlayers") ||
    {isNil "KFH_rushEveryWaves"} ||
    {isNil "KFH_playerLoadCoef"} ||
    {isNil "KFH_starterSidearms"} ||
    {isNil "KFH_starterUniforms"} ||
    {isNil "KFH_topHudUpdateSeconds"} ||
    {isNil "KFH_loadoutTrackSeconds"}
) then {
    call compile preprocessFileLineNumbers "scripts\kfh_settings.sqf";
};

if (isNil "KFH_fnc_serverInit") then {
    call compile preprocessFileLineNumbers "scripts\kfh_functions.sqf";
};

if (isNil "KFH_fnc_applyCaveLayout") then {
    call compile preprocessFileLineNumbers "scripts\kfh_cave_layout.sqf";
};

if (isNil "KFH_fnc_applyDynamicRoute") then {
    call compile preprocessFileLineNumbers "scripts\kfh_dynamic_route.sqf";
};

diag_log "[KFH] Bootstrap compile complete.";
