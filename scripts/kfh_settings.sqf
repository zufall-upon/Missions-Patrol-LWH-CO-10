KFH_targetPlayers = 12;
KFH_difficultyParamDefault = 1;
KFH_difficultyNames = ["easy", "normal", "hard", "veryHard"];
KFH_enemyAccuracyParamDefault = 1;
KFH_enemyAccuracyNames = ["veryLow", "low", "normal", "high", "veryHigh"];
KFH_routeScaleParamDefault = 100;
KFH_checkpointCountParamDefault = 6;
KFH_threatScaleParamDefault = 100;
KFH_threatScaleMultiplier = 1;
KFH_announcementLanguageDefault = 0;
KFH_friendlyFireScale = 0.01;
KFH_captureRadius = 25;
KFH_enemyClearRadius = 65;
KFH_holdSeconds = 20;
KFH_captureAllowPartialClear = true;
KFH_captureClearRemainingRatio = 0.34;
KFH_captureWavePauseSeconds = 100;
KFH_checkpointSupplyDelay = 30;
KFH_extractHoldSeconds = 15;
KFH_extractBoardTimeoutSeconds = 60;
KFH_extractBoardWarnSeconds = 15;
KFH_finalPrepSeconds = 25;
KFH_pressureMax = 100;
KFH_pressureFailEnabled = false;
KFH_pressureEmergencyRelief = 55;
KFH_pressureEmergencyCooldown = 120;
KFH_pressureReinforceIntervalFloor = 26;
KFH_pressureReinforceIntervalScale = 0;
KFH_pressureReinforceMultiplierStep = 0.12;
KFH_pressureReinforceMultiplierMax = 1.75;
KFH_pressureReliefEventChance = 0.35;
KFH_pressureReliefEventAmount = 14;
KFH_pressureTickSeconds = 45;
KFH_pressureTickValue = 6;
KFH_pressureCheckpointRelief = 18;
KFH_rushEveryWaves = 7;
KFH_rushWaveMultiplier = 1.45;
KFH_rushPressureRelief = 10;
KFH_standardGunnerChance = 0.12;
KFH_rushGunnerChance = 0.1;
KFH_standardHeavyChance = 0.015;
KFH_rushHeavyChance = 0.035;
KFH_rushSupplyCarrierChance = 0.08;
KFH_rushSupplyCarrierMax = 2;
KFH_reinforceSeconds = 100;
KFH_reinforcePressure = 10;
KFH_waveCooldownNormalMinSeconds = 100;
KFH_waveCooldownNormalMaxSeconds = 100;
KFH_waveCooldownRushMinSeconds = 100;
KFH_waveCooldownRushMaxSeconds = 240;
KFH_waveCooldownMinSeconds = KFH_waveCooldownNormalMinSeconds;
KFH_waveCooldownMaxSeconds = KFH_waveCooldownNormalMaxSeconds;
KFH_waveCooldownFastClearSeconds = 100;
KFH_waveCooldownSlowClearSeconds = 100;
KFH_checkpointSecureCooldownSeconds = 180;
KFH_checkpointSecureCooldownEarlyUntil = 4;
KFH_checkpointSecureCooldownEarlySeconds = 60;
KFH_rushClearCooldownBonusSeconds = 0;
KFH_finalArsenalCooldownSeconds = 300;
KFH_extractPressureTickSeconds = 30;
KFH_extractPressureTickValue = 9;
KFH_extractReinforceSeconds = 60;
KFH_extractReinforcePressure = 12;
KFH_extractBaseWaveCount = 12;
KFH_extractDangerTickPenalty = 2;
KFH_extractDangerReinforcePenalty = 4;
KFH_extractDangerPressureBonus = 2;
KFH_extractDangerWaveStep = 2;
KFH_extractGunnerChance = 0.1;
KFH_extractHeavyChance = 0.05;
KFH_extractSupplyCarrierChance = 0.06;
KFH_extractSpawnFromFinalCheckpoint = true;
KFH_extractFlareRequired = true;
KFH_extractFlareRadius = 45;
KFH_extractFlareReminderSeconds = 45;
KFH_extractionHeliClass = "B_Heli_Transport_01_F";
KFH_extractionHeliBaseCount = 2;
KFH_extractionHeliSeatEstimate = 8;
KFH_extractionHeliSpacing = 85;
KFH_extractionHeliMinSlotSeparation = 70;
KFH_extractionHeliSpawnDistance = 950;
KFH_extractionHeliEvacDistance = 1200;
KFH_extractionHeliApproachHeight = 40;
KFH_extractionHeliLandHeight = 20;
KFH_extractionHeliFarEnoughDistance = 550;
KFH_extractionHeliLandCommandDistance = 220;
KFH_extractionHeliLandingTimeoutSeconds = 75;
KFH_extractionHeliForceSettleHeight = 0.35;
KFH_extractionHeliEvacNudgeSeconds = 12;
KFH_extractionHeliInvulnerable = true;
KFH_extractionHeliBackupRetryLimit = 2;
KFH_extractionHeliBackupRetryDelaySeconds = 4;
KFH_extractionTestModeDefault = 0;
KFH_extractionTestLzDistance = 140;
KFH_extractionTestPrepSeconds = 5;
KFH_objectiveSafeBuildingRadius = 24;
KFH_objectiveSafeTerrainRadius = 18;
KFH_objectiveRoadSearchRadius = 55;
KFH_extractSafeBuildingRadius = 42;
KFH_extractSafeTerrainRadius = 28;
KFH_extractSafeRoadClearRadius = 16;
KFH_extractSafeSearchDistances = [0, 70, 110, 150, 200, 260, 320];
KFH_wipeGraceSeconds = 20;
KFH_missionEndSyncDelay = 1.2;
KFH_runEventLogLimit = 18;
KFH_waveBaseCounts = [10, 14, 18];
KFH_checkpointEventPool = [
    "resupply",
    "surge",
    "hunter"
];
KFH_checkpointEventResupplyDelay = 30;
KFH_checkpointEventSurgeDelay = 16;
KFH_checkpointEventHunterDelay = 12;
KFH_caveLayoutEnabled = false;
KFH_caveLayoutUseRSPN = false;
KFH_caveDebugVehiclesEnabled = false;
KFH_dynamicRouteEnabled = true;
KFH_checkpointCount = 6;
KFH_checkpointCountMin = 3;
KFH_checkpointCountMax = 10;
KFH_routeSeed = -1;
KFH_dynamicRouteMinSpacing = 704;
KFH_dynamicRouteRoadSearchRadius = 360;
KFH_dynamicRouteRoadAttempts = 80;
KFH_dynamicRouteEdgeMargin = 850;
KFH_dynamicRouteFallbackGridStep = 900;
KFH_dynamicRouteRequireRoads = true;
KFH_dynamicRouteJitter = 500;
KFH_dynamicRouteLengthRatio = 0.48;
KFH_dynamicRoutePreferTargetDistance = true;
KFH_dynamicRouteUseLocationAnchors = true;
KFH_dynamicRouteLocationTypes = [
    "NameCityCapital",
    "NameCity",
    "NameVillage",
    "NameLocal",
    "Airport"
];
KFH_dynamicRouteAnchorAttempts = 48;
KFH_dynamicRouteSafeObjectRadius = 32;
KFH_dynamicRouteSafeTerrainRadius = 24;
KFH_dynamicRouteSlopeSampleDistance = 9;
KFH_dynamicRouteMaxSlopeHeightDiff = 3.1;
KFH_dynamicRouteSegmentSampleDistance = 220;
KFH_dynamicRouteMinSegmentFactor = 0.58;
KFH_dynamicRouteMaxSegmentFactor = 1.75;
KFH_dynamicRouteStartCheckpointMinDistance = 360;
KFH_dynamicRouteMaxTurnDegrees = 95;
KFH_dynamicRouteMinForwardProgressFactor = 0.42;
KFH_dynamicRouteBuildAttempts = 10;
KFH_dynamicRouteMinNodeSpacingFactor = 0.62;
KFH_debugShortRouteEnabled = true;
KFH_debugShortRouteAutoInEden = true;
KFH_debugShortRouteForce = false;
KFH_debugShortRouteScale = 0.33;
KFH_debugShortRouteMinSpacing = 420;
KFH_debugShortRouteLengthRatio = 0.14;
KFH_debugShortRouteTargetSegment = 680;
KFH_debugShortRouteMinTotalDistance = 1900;
KFH_debugShortRouteJitter = 180;
KFH_debugShortRouteEdgeMargin = 450;
KFH_routeScaleHalfMinSpacing = 440;
KFH_routeScaleHalfLengthRatio = 0.18;
KFH_routeScaleHalfTargetSegment = 780;
KFH_routeScaleHalfJitter = 210;
KFH_routeScaleHalfEdgeMargin = 520;
KFH_routeMarkerHiddenAlpha = 0;
KFH_routeMarkerSecuredAlpha = 0.45;
KFH_routeMarkerCurrentAlpha = 1;
KFH_routeMarkerRevealLookAhead = 0;
KFH_routeShowSpawnMarkers = false;
KFH_outbreakStartDate = [2035, 7, 6, 16, 20];
KFH_outbreakTwilightDate = [2035, 7, 6, 17, 35];
KFH_outbreakDuskDate = [2035, 7, 6, 18, 15];
KFH_outbreakCheckpointDates = [
    [2035, 7, 6, 17, 35],
    [2035, 7, 6, 17, 45],
    [2035, 7, 6, 17, 55],
    [2035, 7, 6, 18, 5],
    [2035, 7, 6, 18, 15],
    [2035, 7, 6, 18, 20],
    [2035, 7, 6, 18, 25],
    [2035, 7, 6, 18, 30],
    [2035, 7, 6, 18, 35],
    [2035, 7, 6, 18, 40]
];
KFH_outbreakRouteDressingEnabled = true;
KFH_outbreakCivilianEnabled = true;
KFH_outbreakCivilianChance = 0.65;
KFH_outbreakCivilianMaxPerNode = 3;
KFH_outbreakCivilianClasses = [
    "C_man_1",
    "C_man_polo_1_F",
    "C_man_polo_2_F",
    "C_man_polo_4_F",
    "C_man_polo_5_F"
];
KFH_outbreakCivilianPanicMoves = [
    "AmovPercMstpSnonWnonDnon",
    "ApanPknlMstpSnonWnonDnon_G01",
    "ApanPknlMstpSnonWnonDnon_G02",
    "ApanPpneMstpSnonWnonDnon_G01"
];
KFH_outbreakAbandonedVehicleFuelMin = 0.01;
KFH_outbreakAbandonedVehicleFuelMax = 0.09;
KFH_ambientTrafficEnabled = true;
KFH_ambientTrafficMaxSegment = 4;
KFH_ambientTrafficVehiclesPerSegment = 2;
KFH_ambientTrafficChance = 1;
KFH_ambientTrafficFuelMin = 0.25;
KFH_ambientTrafficFuelMax = 0.55;
KFH_ambientTrafficClasses = [
    "C_Hatchback_01_F",
    "C_Offroad_01_F",
    "C_Offroad_01_repair_F",
    "C_Van_01_transport_F",
    "C_Van_02_transport_F",
    "C_SUV_01_F"
];
KFH_cupAmbientTrafficClasses = [];
KFH_ambientTrafficDriverClasses = [
    "C_man_1",
    "C_man_polo_1_F",
    "C_man_polo_2_F"
];
KFH_envTrafficLoopEnabled = true;
KFH_envTrafficLoopSeconds = 14;
KFH_envTrafficMaxCivilianGroups = 24;
KFH_envTrafficMaxMilitaryGroups = 6;
KFH_envTrafficMinSpawnDistance = 180;
KFH_envTrafficMaxSpawnDistance = 850;
KFH_envTrafficDestinationDistance = 1400;
KFH_envTrafficRemovalDistance = 1500;
KFH_envTrafficCivilianChance = 0.95;
KFH_envTrafficCivilianChanceLate = 0;
KFH_envTrafficOncomingChance = 0.55;
KFH_envTrafficOncomingDirJitter = 32;
KFH_envTrafficSpawnUntilCheckpoint = 6;
KFH_envTrafficMilitaryChance = 0.45;
KFH_envTrafficMilitaryDelaySeconds = 55;
KFH_envTrafficMilitaryStartCheckpoint = 3;
KFH_envTrafficMilitaryProgressEnabled = true;
KFH_envTrafficMilitaryInitialScale = 0.25;
KFH_envTrafficMilitaryFullCheckpoint = 6;
KFH_envTrafficMilitaryArmedChance = 0.42;
KFH_envTrafficMilitaryArmorShare = 0.10;
KFH_envTrafficMilitaryMortarShare = 0.16;
KFH_cupVehiclePreferredChance = 1;
KFH_cupArmorVehiclePreferredChance = 1;
KFH_optionalContentLabel = "RHS/GM/CIS";
KFH_optionalContentClassPrefixes = ["rhs_", "rhsusf_", "rhsgref_", "rhssaf_", "gm_", "CIS_"];
KFH_optionalContentWeaponProbe = "rhs_weap_m4a1";
KFH_envMilitarySkillBase = 0.24;
KFH_envMilitarySkillRandom = 0.16;
KFH_envMilitaryAimingAccuracy = 0.08;
KFH_envMilitaryAimingShake = 0.12;
KFH_envMilitaryAimingSpeed = 0.18;
KFH_envMilitarySpotDistance = 0.34;
KFH_envMilitarySpotTime = 0.28;
KFH_envMilitaryCourage = 0.42;
KFH_envMilitaryCommanding = 0.32;
KFH_envMilitaryGeneral = 0.32;
KFH_envMilitaryProtectRating = true;
KFH_envTrafficMilitaryVehicleClasses = [
    "I_MRAP_03_F",
    "I_G_Offroad_01_F",
    "I_Truck_02_transport_F",
    "I_Truck_02_covered_F",
    "I_Truck_02_ammo_F"
];
KFH_cupEnvTrafficMilitaryVehicleClasses = [
    "rhsgref_nat_uaz",
    "rhsgref_nat_uaz_open",
    "rhsgref_nat_uaz_dshkm",
    "rhsgref_nat_ural",
    "rhsgref_nat_ural_open",
    "rhsgref_BRDM2",
    "rhsgref_BRDM2_HQ"
];
KFH_envTrafficMilitaryTransportVehicleClasses = [
    "I_MRAP_03_F",
    "I_G_Offroad_01_F",
    "I_Truck_02_transport_F",
    "I_Truck_02_covered_F",
    "I_Truck_02_ammo_F"
];
KFH_cupEnvTrafficMilitaryTransportVehicleClasses = [
    "rhsgref_nat_uaz",
    "rhsgref_nat_uaz_open",
    "rhsgref_nat_ural",
    "rhsgref_nat_ural_open",
    "rhsgref_BRDM2_HQ"
];
KFH_envTrafficMilitaryArmedLightVehicleClasses = [
    "I_G_Offroad_01_armed_F",
    "I_MRAP_03_hmg_F"
];
KFH_cupEnvTrafficMilitaryArmedLightVehicleClasses = [
    "rhsgref_nat_uaz_dshkm",
    "rhsgref_nat_uaz_ags",
    "rhsgref_BRDM2"
];
KFH_envTrafficMilitaryArmorVehicleClasses = [
    "I_APC_Wheeled_03_cannon_F",
    "I_APC_tracked_03_cannon_F",
    "I_MBT_03_cannon_F"
];
KFH_cupEnvTrafficMilitaryArmorVehicleClasses = [
    "rhsgref_nat_btr60",
    "rhsgref_BRDM2",
    "rhsgref_BRDM2_ATGM"
];
KFH_envTrafficMilitaryMortarVehicleClasses = [
    "B_MBT_01_arty_F",
    "B_MBT_01_mlrs_F"
];
KFH_cupEnvTrafficMilitaryMortarVehicleClasses = [
    "rhsusf_m113_usarmy_MK19",
    "rhsusf_m1025_w_mk19"
];
KFH_envTrafficMilitaryCrewClasses = [
    "I_G_Soldier_lite_F",
    "I_G_Soldier_F",
    "I_G_Soldier_GL_F"
];
KFH_cupEnvTrafficMilitaryCrewClasses = [
    "rhsgref_nat_rifleman",
    "rhssaf_army_m10_digital_rifleman_m21"
];
KFH_envTrafficCivilianCargoChance = 0.45;
KFH_envTrafficCivilianCargoItems = [
    ["FirstAidKit", "item", 2],
    ["SmokeShell", "magazine", 1],
    ["Chemlight_green", "magazine", 3],
    ["16Rnd_9x21_Mag", "magazine", 2]
];
KFH_showVehicleEntryChat = true;
KFH_envSceneEnabled = true;
KFH_envSceneSpawnRadiusMin = 85;
KFH_envSceneSpawnRadiusMax = 340;
KFH_envSceneEarlyUntilCheckpoint = 2;
KFH_envSceneCivilianPedestrianMaxEarly = 24;
KFH_envSceneCivilianPedestrianMaxLate = 0;
KFH_envSceneCivilianVehicleMaxEarly = 12;
KFH_envSceneCivilianVehicleMaxLate = 0;
KFH_envSceneMilitaryMaxEarly = 0;
KFH_envSceneMilitaryMaxLate = 5;
KFH_envSceneCivilianPedestriansPerTickEarly = 6;
KFH_envSceneCivilianPedestriansPerTickLate = 0;
KFH_envSceneCivilianVehiclesPerTickEarly = 3;
KFH_envSceneCivilianVehiclesPerTickLate = 0;
KFH_envSceneMilitaryPerTickEarly = 0;
KFH_envSceneMilitaryPerTickLate = 1;
KFH_envSceneMilitaryVehicleChance = 0.45;
KFH_envMilitarySeparationFromZombies = 180;
KFH_envMilitaryRespawnSeparationFromZombies = 260;
KFH_envMilitaryFootPatrolEnabled = true;
KFH_envMilitaryFootPatrolChance = 0.82;
KFH_envMilitaryFootPatrolMax = 7;
KFH_envMilitaryFootPatrolSizeMin = 4;
KFH_envMilitaryFootPatrolSizeMax = 6;
KFH_envMilitaryLoadoutCupPreferredChance = 1;
KFH_envMilitaryATChance = 0.38;
KFH_envMilitaryATVehicleScanRadius = 420;
KFH_envMilitaryCheckpointEnabled = true;
KFH_envMilitaryCheckpointChance = 0.72;
KFH_envMilitaryCheckpointMax = 5;
KFH_envMilitaryCheckpointGuardMin = 4;
KFH_envMilitaryCheckpointGuardMax = 6;
KFH_envMilitarySpawnTargetGraceSeconds = 5;
KFH_envMilitaryCheckpointObjects = [
    ["Land_BarGate_F", [0, 0, 0], 0],
    ["Land_CncBarrierMedium_F", [4.5, 0.8, 0], 90],
    ["Land_CncBarrierMedium_F", [-4.5, -0.8, 0], 270],
    ["RoadCone_F", [8, 3.8, 0], 0],
    ["RoadCone_F", [-8, -3.8, 0], 0]
];
KFH_civilianKillPressurePenalty = 8;
KFH_civilianKillExplosionChance = 0.08;
KFH_civilianKillExplosionClass = "Bo_Mk82";
KFH_civilianKillExplosionRadius = 14;
KFH_startPatrolVehicleClass = "C_Quadbike_01_F";
KFH_startPatrolVehicleFuelMin = 0.55;
KFH_startPatrolVehicleFuelMax = 0.65;
KFH_startPatrolVehicleMax = 6;
KFH_startPatrolVehiclePerPlayers = 2;
KFH_startPatrolVehicleGraceSeconds = 8;
KFH_startPatrolVehicleSpeedBoost = 1.25;
KFH_startPatrolVehicleBoostMaxKmh = 60;
KFH_vehicleFlipEnabled = true;
KFH_vehicleFlipDistance = 7;
KFH_vehicleFlipMaxSpeed = 2;
KFH_vehicleFlipVectorUpZ = 0.45;
KFH_vehicleThreatEnabled = true;
KFH_vehicleThreatLoopSeconds = 12;
KFH_vehicleThreatPressureByTier = [
    ["light", 1],
    ["medium", 2],
    ["heavy", 4],
    ["armor", 6],
    ["combat", 9]
];
KFH_checkpointDressingOffsets = [
    ["Land_MetalBarrel_F", [2, 4, 0], 0, 0, false],
    ["Land_MetalBarrel_F", [2, -5, 0], 0, 0, false],
    ["Land_BarGate_F", [0, 0, 0], 0, 0.25, false],
    ["Land_CncBarrier_stripes_F", [7, 4, 0], 30, 0.2, false],
    ["Land_Wreck_Car_F", [-11, -5, 0], -25, 0.65, false]
];
KFH_checkpointDressingSetNames = [
    "Roadblock",
    "Abandoned Aid Point",
    "Overrun Patrol",
    "Traffic Jam",
    "Burning Evac Stop"
];
KFH_checkpointDressingSets = [
    [
        ["Land_MetalBarrel_F", [2, 4, 0], 0, 0, false],
        ["Land_MetalBarrel_F", [2, -5, 0], 0, 0, false],
        ["Land_BarGate_F", [0, 0, 0], 0, 0.25, false],
        ["Land_CncBarrier_stripes_F", [7, 4, 0], 30, 0.2, false],
        ["Land_Wreck_Car_F", [-11, -5, 0], -25, 0.65, false]
    ],
    [
        ["Land_Camping_Light_F", [2, 5, 0], 180, 0, false],
        ["Land_PaperBox_closed_F", [5, 2, 0], 25, 0, false],
        ["Land_PaperBox_open_empty_F", [7, -2, 0], 320, 0, false],
        ["Land_GarbageBags_F", [-4, -5, 0], 10, 0, false],
        ["Land_CncBarrier_stripes_F", [-9, 4, 0], 80, 0.15, false]
    ],
    [
        ["Land_Wreck_Offroad_F", [-8, 5, 0], -35, 0.75, false],
        ["Land_JunkPile_F", [6, -6, 0], 20, 0.4, false],
        ["Land_Razorwire_F", [8, 5, 0], 70, 0.1, false],
        ["Land_MetalBarrel_F", [3, 8, 0], 0, 0.2, false],
        ["Land_CncBarrier_stripes_F", [-2, -8, 0], 110, 0.2, false]
    ],
    [
        ["C_Offroad_01_F", [-9, 8, 0], -25, 0.38, true],
        ["C_Hatchback_01_F", [-2, 11, 0], 10, 0.28, true],
        ["C_Van_01_transport_F", [8, 10, 0], 20, 0.42, true],
        ["Land_CncBarrier_stripes_F", [1, 5, 0], 85, 0.18, false],
        ["Land_GarbagePallet_F", [11, -5, 0], 25, 0, false]
    ],
    [
        ["Land_Camping_Light_F", [-3, 5, 0], 180, 0, false],
        ["Land_MetalBarrel_F", [2, 6, 0], 0, 0.35, true],
        ["Land_MetalBarrel_F", [3, 7, 0], 0, 0.35, true],
        ["C_SUV_01_F", [-8, -4, 0], 145, 0.35, true],
        ["Land_GarbageBags_F", [7, -4, 0], 80, 0, false],
        ["Land_PaperBox_open_full_F", [10, 2, 0], 15, 0, false]
    ]
];
KFH_checkpointMobilityVehiclesEnabled = true;
KFH_checkpointMobilityVehicleCount = 2;
KFH_checkpointMobilityVehicleCountByScale = [1, 1, 2, 2, 2, 3, 3, 3, 3, 3, 3, 3];
KFH_checkpointMobilityVehicleLateMax = 2;
KFH_checkpointMobilityVehicleFuelMin = 0.18;
KFH_checkpointMobilityVehicleFuelMax = 0.24;
KFH_checkpointMobilityVehicleClasses = [
    "C_Quadbike_01_F",
    "B_Quadbike_01_F",
    "B_LSV_01_unarmed_F",
    "C_Offroad_01_F"
];
KFH_cupCheckpointMobilityVehicleClasses = [
    "rhsusf_mrzr4_w",
    "rhsusf_m998_w_2dr",
    "B_LSV_01_unarmed_F"
];
KFH_checkpointMobilityVehicleOffsets = [
    [-13, -8, 0, -35],
    [13, -8, 0, 35]
];
KFH_routeRoadblockOffsets = [
    ["Land_CncBarrier_stripes_F", [0, 8, 0], 70, 0.2, false],
    ["Land_Wreck_Offroad_F", [-10, 11, 0], -35, 0.75, false],
    ["Land_JunkPile_F", [9, -8, 0], 20, 0.4, false],
    ["C_Hatchback_01_F", [13, 5, 0], 35, 0.25, true],
    ["Land_GarbageBags_F", [-5, -6, 0], 115, 0, false]
];
KFH_useManualSpawnMarkers = false;
KFH_spawnMinDistance = 18;
KFH_spawnMaxDistance = 34;
KFH_spawnAheadMinDistance = 70;
KFH_spawnAheadMaxDistance = 115;
KFH_spawnAheadConeDegrees = 28;
KFH_spawnAheadSafeRadius = 14;
KFH_spawnAheadAttempts = 16;
KFH_spawnAheadBlockerRadius = 7;
KFH_spawnMinPlayerDistance = 85;
KFH_spawnMinRespawnDistance = 75;
KFH_initialWaveReadyTimeout = 45;
KFH_initialWaveReadyBuffer = 3;
KFH_objectiveThreatRadius = 90;
KFH_checkpointStatusInterval = 10;
KFH_showCheckpointStatusChat = false;
KFH_showStartupDebugChat = false;
KFH_rightHudEnabled = false;
KFH_rightHudUpdateSeconds = 0.5;
KFH_activeEnemyHardCap = 50;
KFH_spawnCapWarningCooldown = 20;
KFH_enemyClasses = [
    "O_Soldier_F",
    "O_Soldier_lite_F",
    "O_G_Soldier_F"
];
KFH_useWebKnightZombies = true;
KFH_webKnightZombieTypes = [4, 5, 5, 4];
KFH_webKnightZombieMaxActive = 45;
KFH_webKnightInitDelay = 0.25;
KFH_meleeAttackRange = 1.25;
KFH_meleeAttackDamage = 0.18;
KFH_meleeAttackCooldown = 1.1;
KFH_meleeRetargetSeconds = 0.45;
KFH_meleeCommandMoveSeconds = 1.1;
KFH_meleeWalkDistance = 7;
KFH_meleeFaceDistance = 3.5;
KFH_meleeRunAnimSpeed = 0.96;
KFH_meleeWalkAnimSpeed = 0.72;
KFH_meleeRepathDistance = 1.35;
KFH_meleeStuckCheckSeconds = 1.4;
KFH_meleeStuckDistance = 0.45;
KFH_meleeStuckRepathOffset = 0.8;
KFH_meleeForcedDestinationSeconds = 0.8;
KFH_meleeCueDistance = 22;
KFH_meleeCueCooldown = 2.8;
KFH_zombieCueVolume = 3.4;
KFH_zombieCuePitchBase = 0.72;
KFH_zombieCuePitchRandom = 0.05;
KFH_zombieCueMaxDistance = 55;
KFH_meleeHitShake = [2.1, 0.22, 10];
KFH_quickStrikeRange = 2;
KFH_quickStrikeDamage = 0.24;
KFH_quickStrikeCooldown = 0.75;
KFH_playerLoadCoef = 0.05;
KFH_playerAnimSpeedCoef = 1.08;
KFH_playerFatigueKeepRatio = 0;
KFH_playerFatigueAssistSeconds = 0.35;
KFH_playerDisableFatigue = true;
KFH_playerDisableStamina = true;
KFH_meleeAttackAction = "GestureSpasm0";
KFH_meleeAttackLunge = 1.1;
KFH_topHudUpdateSeconds = 0.25;
KFH_debugTeammateEnabled = true;
KFH_debugTeammateHumanThreshold = 1;
KFH_debugTeammateClass = "B_Soldier_F";
KFH_debugTeammateName = "Echo";
KFH_debugTeammatePassiveCombat = false;
KFH_debugTeammatePrimaryWeapon = "arifle_MX_F";
KFH_debugTeammatePrimaryMagazine = "30Rnd_65x39_caseless_mag";
KFH_debugTeammatePrimaryAttachments = ["acc_flashlight", "optic_Holosight"];
KFH_debugTeammatePrimaryMagCount = 12;
KFH_debugTeammateBackpack = "B_AssaultPack_rgr";
KFH_debugTeammateMirrorPlayerLoadout = true;
KFH_debugTeammateMirrorInterval = 18;
KFH_debugTeammateSkill = 0.92;
KFH_debugTeammateAimingAccuracy = 0.46;
KFH_debugTeammateDamageScale = 0.42;
KFH_debugTeammateEngageRadius = 190;
KFH_debugTeammateRespawnDelay = 20;
KFH_debugTeammateReviveRange = 4;
KFH_debugTeammateReviveTimeout = 8;
KFH_debugTeammateReviveDuration = 2.8;
KFH_debugTeammateRescueTeleportDelay = 2.2;
KFH_debugTeammateAutoPullVehicleCasualties = true;
KFH_debugTeammateLastStandGraceSeconds = 90;
KFH_debugTeammateWipeGraceSeconds = 35;
KFH_scalingTestAlliesDefault = 0;
KFH_scalingTestAllyClass = "B_Soldier_F";
KFH_scalingTestAllyNames = ["Delta", "Mika", "Rook"];
KFH_scalingTestAllyRespawnDelay = 20;
KFH_scalingTestAllyMirrorInterval = 18;
KFH_playerDeathWipeGraceSeconds = 55;
KFH_playerDownedProtectionEnabled = true;
KFH_forcedDownedDamage = 0.42;
KFH_downedInterceptDamageThreshold = 0.72;
KFH_downedInterceptTotalDamageThreshold = 0.82;
KFH_respawnFallbackDownedEnabled = true;
KFH_revivedDamage = 0.35;
KFH_postReviveBlurSeconds = 0;
KFH_postReviveBlurClearDamage = 0.25;
KFH_reviveCleanupSeconds = 1.2;
KFH_postReviveInvulnerabilitySeconds = 5;
KFH_reviveGetUpAnimationEnabled = true;
KFH_reviveGetUpAnimation = "AmovPpneMstpSrasWrflDnon_AmovPercMstpSrasWrflDnon";
KFH_reviveGetUpAnimationProne = "AmovPpneMstpSrasWrflDnon";
KFH_reviveGetUpAnimationUnarmed = "AmovPpneMstpSnonWnonDnon_AmovPercMstpSnonWnonDnon";
KFH_reviveGetUpAnimationProneUnarmed = "AmovPpneMstpSnonWnonDnon";
KFH_reviveGetUpAnimationSeconds = 3.6;
KFH_reviveGetUpAnimationSpeedCoef = 0.55;
KFH_vehicleCasualtyPullEnabled = true;
KFH_vehicleCasualtyPullActionDistance = 8;
KFH_vehicleCasualtyPullSafeDistance = 12;
KFH_vehicleCasualtyPullImmunitySeconds = 6;
KFH_vehicleCasualtyPostReviveGraceSeconds = 8;
KFH_vehicleCasualtyPullMaxDistance = 55;
KFH_vehicleCasualtyPullMaxObjectiveDistance = 520;
KFH_vehicleCasualtyPullObjectiveFallbackDistance = 85;
KFH_vehicleCasualtyInvalidWorldMargin = 25;
KFH_debugEdenStartArsenalEnabled = true;
KFH_debugEdenStartArsenalOffset = [-5, -6, 0];
KFH_bodyDragEnabled = true;
KFH_bodyDragDistance = 3.2;
KFH_bodyDragAttachOffset = [0, 1.15, 0.05];
KFH_starterUniforms = [
    "U_B_CombatUniform_mcam_tshirt",
    "U_I_CombatUniform",
    "U_BG_Guerilla2_1",
    "U_BG_Guerilla2_2"
];
KFH_starterVests = [
    "V_BandollierB_rgr",
    "V_Rangemaster_belt",
    "V_Chestrig_khk"
];
KFH_starterHeadgear = [
    "",
    "H_Cap_tan",
    "H_Booniehat_khk"
];
KFH_starterSidearms = [
    ["hgun_P07_F", "16Rnd_9x21_Mag", "acc_flashlight_pistol"],
    ["hgun_Rook40_F", "16Rnd_9x21_Mag", "acc_flashlight_pistol"],
    ["hgun_PDW2000_F", "30Rnd_9x21_Mag", "optic_ACO_grn_smg"]
];
KFH_cupStarterUniforms = [
    "rhs_uniform_cu_ocp",
    "rhs_uniform_FROG01_d",
    "rhs_uniform_msv_emr",
    "rhs_uniform_g3_m81"
];
KFH_cupStarterVests = [
    "rhsusf_iotv_ocp_Rifleman",
    "rhsusf_spc_rifleman",
    "rhs_6b23_6sh116",
    "rhsgref_6b23"
];
KFH_cupStarterHeadgear = [
    "rhsusf_ach_helmet_ocp",
    "rhsusf_lwh_helmet_marpatd",
    "rhs_6b47",
    "rhssaf_helmet_m97_woodland"
];
KFH_cupStarterSidearms = [
    ["rhsusf_weap_m9", "rhsusf_mag_15Rnd_9x19_JHP", ""],
    ["rhsusf_weap_glock17g4", "rhsusf_mag_17Rnd_9x19_JHP", ""]
];
KFH_cupStarterPreferredChance = 1;
KFH_cupStarterMissingWarning = true;
KFH_starterMagCount = 6;
KFH_starterFirstAidCount = 3;
KFH_startSidearmCacheCoverageRatio = 1;
KFH_startSidearmCacheCoverageByDifficulty = [1, 1, 0.33, 0];
KFH_startSidearmCacheBundles = [
    ["hgun_PDW2000_F", "30Rnd_9x21_Mag", 10, ["optic_ACO_grn_smg", "acc_flashlight"]]
];
KFH_startToolKitCountsByDifficulty = [0, 0, 0, 0];
KFH_starterApplyDelay = 0;
KFH_starterRecheckDelay = 1.5;
KFH_starterEnforceWindow = 12;
KFH_supportUseDistance = 5;
KFH_supportSearchRadius = 45;
KFH_repairStationClass = "Box_NATO_AmmoVeh_F";
KFH_supportAmmoOffset = [8, -4, 0];
KFH_supportMedicalOffset = [11, -1, 0];
KFH_supportRepairOffset = [15, 4, 0];
KFH_checkpointAmmoOffset = [5, -3, 0];
KFH_checkpointMedicalOffset = [8, -1, 0];
KFH_checkpointBeaconOffsets = [
    [2, 4, 0],
    [2, -5, 0]
];
KFH_rewardCacheOffset = [11, 2, 0];
KFH_rewardWeaponCoverageRatio = 0.75;
KFH_rewardBackpackCoverageRatio = 0.35;
KFH_rewardWeaponMagazinePlayerBonusInterval = 2;
KFH_rewardPrePatrolATEnabled = true;
KFH_rewardPrePatrolATLauncherCount = 2;
KFH_rewardPrePatrolATBackpackCoverageRatio = 0.25;
KFH_rewardPrePatrolATBackpackMin = 2;
KFH_rewardPrePatrolATBackpacks = [
    "B_Carryall_mcamo",
    "B_Carryall_oli",
    "B_Bergen_mcamo_F",
    "B_Bergen_tna_F",
    "B_Bergen_hex_F"
];
KFH_rewardHelmetPool = [
    "H_HelmetB_light",
    "H_HelmetB_plain_mcamo",
    "H_HelmetB_camo",
    "H_HelmetSpecB",
    "H_HelmetB_grass"
];
KFH_cupRewardHelmetPool = [
    "rhsusf_ach_helmet_ocp",
    "rhsusf_lwh_helmet_marpatd",
    "rhs_6b47",
    "rhssaf_helmet_m97_woodland"
];
KFH_rewardVestPoolTier2 = [
    "V_PlateCarrier1_rgr"
];
KFH_cupRewardVestPoolTier2 = [
    "rhsusf_iotv_ocp_Rifleman",
    "rhsusf_spc_rifleman",
    "rhs_6b23_6sh116",
    "rhsgref_6b23"
];
KFH_rewardVestPoolTier3 = [
    "V_PlateCarrier2_rgr",
    "V_PlateCarrierGL_rgr"
];
KFH_cupRewardVestPoolTier3 = [
    "rhsusf_iotv_ocp_Rifleman",
    "rhsusf_spc_rifleman",
    "rhs_6b23_6sh116",
    "rhsgref_6b23"
];
KFH_rewardMedikitChanceTier3 = 0.18;
KFH_branchRewardEnabled = true;
KFH_branchRewardChance = 0.55;
KFH_branchRewardOffsetDistance = 520;
KFH_branchRewardMinDetourDistance = 320;
KFH_branchRewardRoadSearchRadius = 260;
KFH_branchRewardHiddenAlpha = 0;
KFH_branchRewardMarkerAlpha = 0.85;
KFH_branchRewardCacheClass = "Box_NATO_WpsSpecial_F";
KFH_branchRewardNoiseRadius = 38;
KFH_branchRewardPressureCost = 7;
KFH_branchRewardScreamerEnabled = true;
KFH_branchRewardScreamerClass = "Zombie_Special_OPFOR_Screamer";
KFH_branchRewardScreamerClassCandidates = [
    "Zombie_Special_OPFOR_Screamer"
];
KFH_branchRewardScreamerDistanceMin = 150;
KFH_branchRewardScreamerDistanceMax = 260;
KFH_branchRewardGuardCount = 2;
KFH_branchRewardGuardMaxActiveReserve = 2;
KFH_finalArsenalOffset = [14, 6, 0];
KFH_finalFlareCacheOffset = [24, 0, 0];
KFH_optionalBaseEnabled = true;
KFH_optionalBaseMarker = "kfh_optional_base";
KFH_optionalBaseOffsetDistance = 340;
KFH_optionalBaseForwardOffset = 90;
KFH_optionalBaseThreatBaseCount = 6;
KFH_optionalBaseGunnerChance = 0.18;
KFH_optionalBaseHeavyChance = 0.05;
KFH_optionalBaseSupplyCarrierChance = 0.12;
KFH_optionalBaseSpecialClass = "WBK_Goliaph_1";
KFH_optionalBaseSpecialClassCandidates = [
    "WBK_Goliaph_1",
    "WBK_Goliaph_2",
    "WBK_Goliaph_3",
    "WBK_SpecialZombie_Smasher_1",
    "WBK_SpecialZombie_Smasher_2",
    "WBK_SpecialZombie_Smasher_3"
];
KFH_optionalBaseSpecialMinDistance = 34;
KFH_optionalBaseSpecialMaxDistance = 70;
KFH_optionalBaseSpecialReserveSlots = 1;
KFH_optionalBaseJuggernautHordeReduction = 3;
KFH_optionalBaseMinDefenders = 2;
KFH_optionalBaseVehicleCount = 6;
KFH_optionalBaseVehicleFuelMin = 0.22;
KFH_optionalBaseVehicleFuelMax = 0.45;
KFH_optionalBaseVehicleInvulnerableUntilEntered = false;
KFH_optionalBaseVehicleClasses = [
    "B_MRAP_01_F",
    "B_MRAP_01_hmg_F",
    "B_APC_Wheeled_01_cannon_F",
    "B_APC_Tracked_01_rcws_F",
    "B_MBT_01_cannon_F"
];
KFH_cupOptionalBaseVehicleClasses = [
    "rhsusf_m1025_w",
    "rhsusf_m1025_w_m2",
    "rhsusf_m113_usarmy",
    "rhsusf_m113_usarmy_M2_90",
    "rhsusf_m1a1aimwd_usarmy",
    "rhsusf_m1a2sep1wd_usarmy"
];
KFH_optionalBaseVehicleOffsets = [
    [120, -95, 0, -25],
    [155, 20, 0, 12],
    [95, 130, 0, 42],
    [-120, -110, 0, -18],
    [-160, 10, 0, 22],
    [-105, 145, 0, 55]
];
KFH_juggernautDamageScale = 0.34;
KFH_juggernautAnimSpeed = 0.72;
KFH_checkpointSpecialEnabled = true;
KFH_checkpointSpecialStartCheckpoint = 1;
KFH_checkpointSpecialChance = 0.98;
KFH_checkpointSpecialRushChanceBonus = 0.18;
KFH_checkpointSpecialMaxActive = 13;
KFH_checkpointSpecialMinDistance = 42;
KFH_checkpointSpecialMaxDistance = 110;
KFH_screamerSpawnDistanceMin = 150;
KFH_screamerSpawnDistanceMax = 260;
KFH_knownBrokenSpecialClasses = [
    "WBK_SpecialInfected_Leaper_1_Cfg",
    "WBK_SpecialInfected_Leaper_2_Cfg",
    "Zombie_Special_OPFOR_Leaper_1",
    "Zombie_Special_OPFOR_Leaper_2",
    "Zombie_Special_BLUFOR_Leaper_1",
    "Zombie_Special_BLUFOR_Leaper_2",
    "Zombie_Special_GREENFOR_Leaper_1",
    "Zombie_Special_GREENFOR_Leaper_2"
];
KFH_leaperProxyEnabled = true;
KFH_leaperProxyCrawlEnabled = true;
KFH_leaperProxyAnimSpeed = 1.65;
KFH_leaperProxyRetargetSeconds = 0.12;
KFH_leaperProxyPounceMinDistance = 3.5;
KFH_leaperProxyPounceMaxDistance = 18;
KFH_leaperProxyPounceCooldown = 2.2;
KFH_leaperProxyPounceForwardVelocity = 10.5;
KFH_leaperProxyPounceUpVelocity = 0.65;
KFH_leaperProxyHumanAnchorEnabled = true;
KFH_leaperProxyHumanAnchorCheckpointDistance = 260;
KFH_leaperProxyHumanAnchorMinDistance = 65;
KFH_leaperProxyHumanAnchorMaxDistance = 135;
KFH_checkpointBloaterPerWaveEnabled = true;
KFH_checkpointBloaterPerWaveIgnoreBudget = true;
KFH_checkpointSpecialWaveRampCycle = 10;
KFH_checkpointSpecialRampExtraChanceMax = 0.65;
KFH_checkpointSpecialRampExtraMax = 1;
KFH_checkpointSpecialRoles = [
    ["screamer", ["Zombie_Special_OPFOR_Screamer"], 5],
    ["leaper", [""], 5],
    ["bloater", ["Zombie_Special_OPFOR_Boomer"], 16],
    ["goliath", ["WBK_Goliaph_1", "WBK_Goliaph_2", "WBK_Goliaph_3"], 1],
    ["smasher", ["WBK_SpecialZombie_Smasher_1", "WBK_SpecialZombie_Smasher_2", "WBK_SpecialZombie_Smasher_3", "WBK_SpecialZombie_Smasher_Acid_1", "WBK_SpecialZombie_Smasher_Acid_2", "WBK_SpecialZombie_Smasher_Acid_3", "WBK_SpecialZombie_Smasher_Hellbeast_1", "WBK_SpecialZombie_Smasher_Hellbeast_2", "WBK_SpecialZombie_Smasher_Hellbeast_3"], 1]
];
KFH_checkpointSpecialRampRoles = [
    ["screamer", ["Zombie_Special_OPFOR_Screamer"], 5],
    ["leaper", [""], 5],
    ["bloater", ["Zombie_Special_OPFOR_Boomer"], 4]
];
KFH_wildSpecialEnabled = true;
KFH_wildSpecialStartCheckpoint = 1;
KFH_wildSpecialLoopSeconds = 12;
KFH_wildSpecialChance = 0.98;
KFH_wildSpecialMaxActive = 10;
KFH_wildSpecialMinRoadDistance = 120;
KFH_wildSpecialAllowRouteFallback = false;
KFH_wildSpecialMinDistance = 130;
KFH_wildSpecialMaxDistance = 280;
KFH_wildSpecialRoles = [
    ["leaper", [""], 6],
    ["screamer", ["Zombie_Special_OPFOR_Screamer"], 3],
    ["bloater", ["Zombie_Special_OPFOR_Boomer"], 12]
];
KFH_extractionHeliCallDelaySeconds = 200;
KFH_extractionFinaleRushEnabled = true;
KFH_extractionFinaleSpecialIntervalSeconds = 30;
KFH_extractionFinaleSpecialPairChance = 0.35;
KFH_extractionFinaleSpecialMinDistance = 90;
KFH_extractionFinaleSpecialMaxDistance = 185;
KFH_extractionFinaleScreamerMinDistance = 170;
KFH_extractionFinaleScreamerMaxDistance = 300;
KFH_extractionFinaleJuggernautMinDistance = 230;
KFH_extractionFinaleJuggernautMaxDistance = 360;
KFH_extractionFinaleSpecialRoles = [
    ["screamer", ["Zombie_Special_OPFOR_Screamer"], 1],
    ["leaper", [""], 1],
    ["bloater", ["Zombie_Special_OPFOR_Boomer"], 4]
];
KFH_extractionFinaleJuggernautRoles = [
    ["goliath", ["WBK_Goliaph_1", "WBK_Goliaph_2", "WBK_Goliaph_3"], 1],
    ["smasher", ["WBK_SpecialZombie_Smasher_1", "WBK_SpecialZombie_Smasher_2", "WBK_SpecialZombie_Smasher_3"], 1]
];
KFH_finalBaseCompositionOffsets = [
    ["Land_HBarrier_Big_F", [4, 2, 0], 90, 0, false],
    ["Land_HBarrier_Big_F", [4, -3, 0], 90, 0, false],
    ["Land_HBarrierWall4_F", [13, 10, 0], 0, 0.05, false],
    ["Land_HBarrierWall4_F", [19, 10, 0], 355, 0.05, false],
    ["Land_HBarrier_Big_F", [12, -11, 0], 180, 0.08, false],
    ["Land_HBarrier_Big_F", [18, -11, 0], 180, 0.08, false],
    ["Land_HBarrier_5_F", [27, 6, 0], 120, 0.12, false],
    ["Land_HBarrier_5_F", [28, -2, 0], 50, 0.12, false],
    ["Land_Cargo_HQ_V1_F", [17, 3, 0], 180, 0.18, false],
    ["Land_Shed_Big_F", [21, 6, 0], 180, 0.28, false],
    ["Land_Cargo10_grey_F", [11, -7, 0], 180, 0.26, false],
    ["Land_PowerGenerator_F", [9, 8, 0], 180, 0.22, false],
    ["Land_TTowerSmall_2_F", [6, 10, 0], 0, 0.12, false],
    ["Land_Razorwire_F", [4, 9, 0], 90, 0.1, false],
    ["Land_Razorwire_F", [15, -14, 0], 0, 0.1, false],
    ["Land_Wreck_Truck_dropside_F", [26, -7, 0], 40, 0, false],
    ["Land_Wreck_Ural_F", [29, 4, 0], 305, 0, false],
    ["Land_MetalBarrel_F", [12, 9, 0], 0, 0.18, false],
    ["Land_MetalBarrel_F", [13, 10, 0], 0, 0.18, false],
    ["Land_PaperBox_closed_F", [14, -5, 0], 35, 0, false],
    ["Land_PaperBox_open_empty_F", [15, -5, 0], 330, 0, false]
];
KFH_finalBaseSupplyOffsets = [
    ["Box_NATO_WpsLaunch_F", [9, -6, 0], 180],
    ["Box_NATO_AmmoOrd_F", [20, -5, 0], 135],
    ["Box_NATO_Equip_F", [23, 6, 0], 180]
];
KFH_rushSupplyCarrierBackpacks = [
    "B_AssaultPack_rgr",
    "B_FieldPack_khk",
    "B_Kitbag_rgr"
];
KFH_rangedEnemyLoadouts = [
    ["SMG_02_F", "30Rnd_9x21_Mag_SMG_02", ["optic_ACO_grn_smg", "acc_flashlight"], 3],
    ["hgun_PDW2000_F", "30Rnd_9x21_Mag", ["optic_ACO_grn_smg", "acc_flashlight"], 4],
    ["arifle_TRG20_F", "30Rnd_556x45_Stanag", ["optic_Aco", "acc_flashlight"], 3]
];
KFH_cupOptionalEnabled = true;
KFH_cupBanVanillaWhenAvailable = true;
KFH_cupRewardPreferredChance = 1;
KFH_cupRangedEnemyPreferredChance = 1;
KFH_dynamicRhsRewardWeaponsEnabled = true;
KFH_dynamicRhsRewardPreferredChance = 1;
KFH_dynamicRhsRewardMaxPerCategory = 18;
KFH_dynamicRhsRewardPriorityTokens = ["m249", "m240", "mk48", "minimi", "saw", "pkm", "pkp"];
KFH_dynamicRhsRewardShotgunTokens = ["shotgun", "m590", "m1014", "saiga", "ks23", "ks-23"];
KFH_dynamicRhsRewardMachinegunTokens = ["m249", "m240", "mk48", "pkm", "pkp", "rpk", "mg3", "m60", "minimi", "machinegun", "machine gun", "lmg", "mmg"];
KFH_dynamicRhsRewardBattleRifleTokens = ["m14", "ebr", "sr25", "hk417", "g3", "fal", "scarh", "scar-h", "m110", "mk11", "svd", "svdp", "vss", "val"];
KFH_dynamicRhsRewardExcludedTokens = ["pistol", "makarov", "glock", "m9", "launcher", "rpg", "m136", "m72", "m320", "m203", "grenade launcher", "flare"];
KFH_dynamicRhsRewardShotgunAttachments = [];
KFH_dynamicRhsRewardMachinegunAttachments = ["rhs_acc_pkas", "rhs_acc_1p78", "optic_Arco"];
KFH_dynamicRhsRewardBattleRifleAttachments = ["optic_Arco", "rhsusf_acc_ACOG", "rhs_acc_pso1m2"];
KFH_cupRangedEnemyLoadouts = [
    ["rhs_weap_m4a1", "rhs_mag_30Rnd_556x45_M855A1_Stanag", ["optic_Arco"], 4],
    ["rhs_weap_m16a4", "rhs_mag_30Rnd_556x45_M855A1_Stanag", ["rhsusf_acc_ACOG"], 4],
    ["rhs_weap_ak74m", "rhs_30Rnd_545x39_7N10_AK", ["rhs_acc_ekp1"], 4],
    ["rhs_weap_akm", "rhs_30Rnd_762x39mm", ["rhs_acc_ekp1"], 4]
];
KFH_cupRewardWeaponBundlesTier1 = [
    ["rhs_weap_m4a1", "rhs_mag_30Rnd_556x45_M855A1_Stanag", 8, ["optic_Arco", "rhsusf_acc_grip1", "rhsusf_acc_anpeq15side"]],
    ["rhs_weap_m16a4", "rhs_mag_30Rnd_556x45_M855A1_Stanag", 8, ["rhsusf_acc_ACOG", "rhsusf_acc_grip2", "rhsusf_acc_anpeq15side"]],
    ["rhs_weap_ak74m", "rhs_30Rnd_545x39_7N10_AK", 8, ["rhs_acc_ekp1", "rhs_acc_perst1ik"]]
];
KFH_cupRewardWeaponBundlesTier2 = [
    ["rhs_weap_m14ebrri", "rhsusf_20Rnd_762x51_m118_special_Mag", 8, ["rhsusf_acc_ACOG", "rhsusf_acc_grip2"]],
    ["rhs_weap_svdp", "rhs_10Rnd_762x54mmR_7N1", 8, ["rhs_acc_pso1m2"]],
    ["rhs_weap_M320", "1Rnd_HE_Grenade_shell", 8, []]
];
KFH_cupRewardWeaponBundlesTier3 = [
    ["rhs_weap_pkm", "rhs_100Rnd_762x54mmR", 3, ["rhs_acc_pkas", "rhs_acc_1p78"]],
    ["rhs_weap_m14ebrri", "rhsusf_20Rnd_762x51_m118_special_Mag", 10, ["rhsusf_acc_ACOG", "rhsusf_acc_grip3"]],
    ["rhs_weap_M320", "1Rnd_HE_Grenade_shell", 10, []]
];
KFH_rewardAttachmentCargoTier1 = [];
KFH_rewardAttachmentCargoTier2 = [];
KFH_rewardAttachmentCargoTier3 = [];
KFH_cupRewardBackpackPoolTier1 = [
    "rhsusf_assault_eagleaiii_ocp",
    "rhsusf_falconii"
];
KFH_cupRewardBackpackPoolTier2 = [
    "rhsusf_assault_eagleaiii_ocp",
    "rhs_medic_bag"
];
KFH_cupRewardBackpackPoolTier3 = [
    "rhsusf_falconii",
    "rhssaf_kitbag_md2camo"
];
KFH_cupLauncherBundles = [
    ["rhs_weap_rpg7", "rhs_rpg7_PG7VL_mag", 2],
    ["rhs_weap_M136", "rhs_m136_mag", 1],
    ["rhs_weap_m72a7", "rhs_m72a7_mag", 1]
];
KFH_simpleLauncherBundles = [
    ["rhs_weap_M136", "rhs_m136_mag", 1],
    ["rhs_weap_m72a7", "rhs_m72a7_mag", 1]
];
KFH_rewardPrePatrolATLauncherBundles = [
    ["launch_NLAW_F", "NLAW_F", 1],
    ["rhs_weap_M136", "rhs_m136_mag", 1],
    ["rhs_weap_m72a7", "rhs_m72a7_mag", 1]
];
KFH_sideCacheAtLauncherBundles = [
    ["launch_B_Titan_short_F", "Titan_AT", 2],
    ["launch_RPG32_F", "RPG32_F", 3],
    ["launch_MRAWS_green_rail_F", "MRAWS_HEAT_F", 3],
    ["rhs_weap_rpg7", "rhs_rpg7_PG7VL_mag", 4]
];
KFH_sideCacheLargeBackpackCoverageRatio = 0.25;
KFH_sideCacheLargeBackpackMin = 2;
KFH_sideCacheLargeBackpacks = [
    "B_Carryall_mcamo",
    "B_Carryall_oli",
    "B_Bergen_mcamo_F",
    "B_Bergen_tna_F",
    "B_Bergen_hex_F"
];
KFH_sideCacheBonusMagazineCargo = [
    ["rhs_45Rnd_545X39_AK", 10],
    ["rhs_45Rnd_545X39_7N10_AK", 10],
    ["rhs_45Rnd_545X39_7N22_AK", 8],
    ["rhs_45Rnd_545X39_7U1_AK", 8],
    ["rhs_75Rnd_762x39mm", 10],
    ["rhs_100Rnd_762x54mmR", 8],
    ["200Rnd_65x39_cased_Box", 4],
    ["100Rnd_65x39_caseless_mag", 6],
    ["150Rnd_762x54_Box", 4]
];
KFH_sideCacheM4LargeMagazineWeapons = [
    "rhs_weap_m4a1",
    "rhs_weap_m16a4",
    "arifle_SPAR_01_blk_F",
    "arifle_SPAR_01_khk_F",
    "arifle_SPAR_01_snd_F",
    "arifle_SPAR_02_blk_F",
    "arifle_SPAR_02_khk_F",
    "arifle_SPAR_02_snd_F"
];
KFH_sideCacheM4LargeMagazineTokens = ["556", "5.56", "stanag", "cmag", "c-mag", "magpul"];
KFH_sideCacheM4LargeMagazineExcludeTokens = ["soft_pouch", "saw", "m249"];
KFH_sideCacheM4LargeMagazineMinAmmo = 40;
KFH_sideCacheM4LargeMagazineMaxTypes = 4;
KFH_sideCacheM4LargeMagazineCount = 6;
KFH_sideCacheM4LargeMagazineExplicitCargo = [
    ["150Rnd_556x45_Drum_Sand_Mag_Tracer_F", 6],
    ["150Rnd_556x45_Drum_Sand_Mag_F", 6],
    ["rhsusf_200Rnd_556x45_box", 4],
    ["rhsusf_200Rnd_556x45_mixed_box", 4],
    ["rhs_mag_100Rnd_556x45_M855A1_cmag", 6],
    ["rhs_mag_100Rnd_556x45_M855_cmag", 6],
    ["rhs_mag_100Rnd_556x45_Mk318_cmag", 6],
    ["rhs_mag_100Rnd_556x45_Mk262_cmag", 6]
];
KFH_sideCacheBonusItemCargo = [
    ["optic_Arco", 2],
    ["rhsusf_acc_ACOG", 2],
    ["rhsusf_acc_grip3", 2],
    ["rhs_acc_ekp1", 2],
    ["rhs_acc_pso1m2", 2],
    ["rhs_acc_perst1ik", 2]
];
KFH_agentUniforms = [
    "U_I_C_Soldier_Bandit_3_F",
    "U_BG_Guerilla2_2",
    "U_BG_leader"
];
KFH_agentHeadgear = [
    "H_Bandanna_khk_hs",
    "H_Shemag_olive_hs",
    "H_Booniehat_khk_hs"
];
KFH_heavyInfectedUniforms = [
    "U_O_CombatUniform_ocamo",
    "U_O_T_Soldier_F"
];
KFH_heavyInfectedVests = [
    "V_PlateCarrier1_blk",
    "V_HarnessO_brn"
];
KFH_heavyInfectedHeadgear = [
    "H_HelmetO_ocamo",
    "H_HelmetLeaderO_ocamo"
];
KFH_heavyInfectedBackpacks = [
    "B_FieldPack_ocamo",
    "B_Carryall_ocamo"
];
KFH_heavyInfectedDamageScale = 0.58;
KFH_heavyInfectedAnimSpeed = 0.82;
KFH_meleeLootEnabled = true;
KFH_enemyLootUseRecentRewardBundles = true;
KFH_enemyLootRecentBundleChance = 0.75;
KFH_enemyLootRecentBundleMaxMags = 2;
KFH_enemyLootRecentBundleAttachmentChance = 0.12;
KFH_meleeLootTable = [
    ["rhs_mag_30Rnd_556x45_M855A1_Stanag", 0, 1, 0.18],
    ["rhs_30Rnd_545x39_7N10_AK", 0, 1, 0.18],
    ["FirstAidKit", 0, 1, 0.22],
    ["SmokeShell", 0, 1, 0.10]
];
KFH_meleeLootFallbackChance = 0.55;
KFH_meleeLootFallbackItems = [
    "FirstAidKit",
    "SmokeShell"
];
KFH_agentLootTable = [
    ["rhs_mag_30Rnd_556x45_M855A1_Stanag", 1, 2, 0.38],
    ["rhs_30Rnd_545x39_7N10_AK", 1, 2, 0.34],
    ["rhs_30Rnd_762x39mm", 1, 2, 0.26],
    ["FirstAidKit", 0, 1, 0.20],
    ["SmokeShell", 0, 1, 0.12]
];
KFH_heavyInfectedLootTable = [
    ["FirstAidKit", 1, 2, 0.55],
    ["rhs_mag_30Rnd_556x45_M855A1_Stanag", 1, 3, 0.38],
    ["rhs_30Rnd_545x39_7N10_AK", 1, 3, 0.38],
    ["rhs_100Rnd_762x54mmR", 0, 1, 0.18],
    ["rhs_30Rnd_762x39mm", 1, 2, 0.22],
    ["SmokeShell", 0, 2, 0.28]
];
KFH_staleEnemyCleanupEnabled = true;
KFH_staleEnemyMinDistance = 520;
KFH_staleEnemyForgetSeconds = 8;
KFH_staleEnemyCheckSeconds = 8;
KFH_staleEnemyPressurePenalty = 1;
KFH_staleEnemyRelocateEnabled = true;
KFH_staleEnemyRelocateMinDistance = 90;
KFH_staleEnemyRelocateMaxDistance = 190;
KFH_staleEnemyRelocateCoverRadius = 95;
KFH_staleEnemyRelocateCoverOffsetMin = 4;
KFH_staleEnemyRelocateCoverOffsetMax = 9;
KFH_staleEnemyObjectiveGraceDistance = 360;
KFH_staleEnemyRelocateMaxObjectiveDistance = 260;
KFH_staleEnemyRelocateCoverTypes = ["TREE", "SMALL TREE", "BUSH", "ROCK", "ROCKS", "HOUSE", "BUILDING", "WALL", "FENCE", "HIDE"];
KFH_staleEnemyVisibleThreshold = 0.25;
KFH_rushDebtEnabled = true;
KFH_rushDebtMax = 24;
KFH_rushDebtInterestEnabled = true;
KFH_rushDebtInterestRatio = 0.25;
KFH_rushDebtInterestMin = 1;
KFH_rushDebtInterestMax = 4;
KFH_waveRecycleOffscreenEnabled = true;
KFH_waveRecycleObjectiveDistance = 240;
KFH_waveRecycleForceObjectiveDistance = 420;
KFH_waveRecycleHumanDistance = 260;
KFH_tacticalPingLifetime = 45;
KFH_tacticalPingMarkerColor = "ColorOrange";
KFH_playerPositionMarkerEnabled = true;
KFH_loadoutTrackSeconds = 6;
KFH_supportDecor = [
    ["Land_HBarrier_3_F", [3, -8, 0], 180],
    ["Land_HBarrier_3_F", [7, -8, 0], 180],
    ["Land_HBarrier_3_F", [11, -8, 0], 180],
    ["Land_BagFence_Long_F", [5, 4, 0], 90],
    ["Land_BagFence_Long_F", [9, 4, 0], 90],
    ["Land_Cargo_Patrol_V2_F", [18, 10, 0], 180]
];
