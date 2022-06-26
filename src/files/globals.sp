enum OperatingSystem
{
    Unknown = -1,
    Windows = 0,
    Linux = 1,
    Mac = 2
}

enum struct Global
{
    bool bLateLoaded;
    OperatingSystem ServerOS;

    bool bPracticeModeRunning;
    int iBeamSprite;

    ConVar cvAutoStart;
    ConVar cvPatchGrenadeTrajectory;
    ConVar cvRandomGrenadeTrajectoryColors;

    ConVar IgnoreWinConditions;
    ConVar RoundTime;
    ConVar RespawnTerrorist;
    ConVar RespawnCounterTerrorist;

    // ConVar AllowNoclip;

    ConVar GrenadeTrajectory;
    ConVar GrenadeThickness;
    ConVar GrenadeSpecTime;
    ConVar GrenadeTime;

    GlobalForward fOnCoreIsReady;
    GlobalForward fPracticeStart;
    GlobalForward fPracticeStop;
    GlobalForward fOnPlayerThrowProjectile;

    void Initiate()
    {
        GameData hGameData = new GameData("practice.game.csgo");

        if (hGameData == null)
            SetFailState("%s Unable to get \"practice.game.csgo.txt\" gamedata", TAG_CONSOLE_NCLR);

        this.ServerOS = view_as<OperatingSystem>(hGameData.GetOffset("Platform"));
        delete hGameData;

        this.IgnoreWinConditions = FindConVar("mp_ignore_round_win_conditions");
        this.RoundTime = FindConVar("mp_roundtime");
        this.RespawnTerrorist = FindConVar("mp_respawn_on_death_t");
        this.RespawnCounterTerrorist = FindConVar("mp_respawn_on_death_ct");

        this.GrenadeTrajectory = FindConVar("sv_grenade_trajectory");
        this.GrenadeTrajectory.Flags = (GetConVarFlags(this.GrenadeTrajectory) & ~FCVAR_CHEAT);
        this.GrenadeThickness = FindConVar("sv_grenade_trajectory_thickness");
        this.GrenadeSpecTime = FindConVar("sv_grenade_trajectory_time_spectator");
        this.GrenadeTime = FindConVar("sv_grenade_trajectory_time");
    }

    void OnMapInit()
    {
        this.iBeamSprite = PrecacheModel("materials/sprites/laserbeam.vmt");
    }

    bool Start()
    {
        if (this.fPracticeStart.FunctionCount)
        {
            static Action hAction;

            Call_StartForward(this.fPracticeStart);
            Call_Finish(hAction);

            if (hAction >= Plugin_Handled)
                return false;
        }

        this.bPracticeModeRunning = true;

        this.IgnoreWinConditions.BoolValue = true;
        GameRules_SetProp("m_iRoundTime", 0);
        this.RoundTime.IntValue = 0;
        this.RespawnTerrorist.BoolValue = true;
        this.RespawnCounterTerrorist.BoolValue = true;

        return true;
    }

    void Stop()
    {
        this.bPracticeModeRunning = false;

        this.IgnoreWinConditions.BoolValue = false;
        GameRules_SetProp("m_iRoundTime", 1);
        this.RoundTime.IntValue = 1;
        this.RespawnTerrorist.BoolValue = false;
        this.RespawnCounterTerrorist.BoolValue = false;

        RestartGame();
    }
}

Global Core;

enum UserSetting
{
    UserSetting_DrawGrenadeTrajectories,
    UserSetting_RestrictMobilityNade,
    UserSetting_Total
}

enum struct EPlayer
{
    int iUserID;
    int iClient;
    int iSettings[UserSetting_Total];

    void Clear()
    {
        this.iUserID = -1;

        for (UserSetting i = UserSetting_DrawGrenadeTrajectories; i < UserSetting_Total; i++)
            this.iSettings[i] = 0;

        this.iClient = -1;
    }

    void Init(int iClient)
    {
        this.iUserID = GetSteamAccountID(iClient);
        this.iClient = iClient;
    }
}

EPlayer g_EPlayer[MAXPLAYERS + 1];