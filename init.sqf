if (isNil "KFH_fnc_log") then {
    call compile preprocessFileLineNumbers "scripts\fn_preInit.sqf";
};

["Mission init.sqf reached."] call KFH_fnc_log;
