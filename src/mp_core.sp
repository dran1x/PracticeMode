#include <cstrike>
#include <ripext/json>
#include <sdkhooks>
#include <sdktools>
#include <sourcemod>
#include <practice>

#if !defined RSVP_COMPILER
	#define decl static
#endif

#pragma dynamic 2046
#pragma semicolon 1
#pragma newdecls required

#include <files/globals.sp>
#include <files/stocks.sp>

public Plugin myinfo =
{
	name    = TAG_PLUG ... "Core",
	author  = "DRANIX",
	version = "0.2",
	url     = "https://github.com/dran1x"
}

public void OnPluginStart()
{
	Core.Initiate();

	LoadTranslations("mypractice.phrases");

	Core.cvAutoStart                     = CreateConVar("sm_practice_autostart", "1", "Should practicemode load automatically on mapstart", FCVAR_PROTECTED);
	Core.cvPatchGrenadeTrajectory        = CreateConVar("sm_practice_patch_trajectories", "1", "Should plugin patch granade trajectory trails", FCVAR_PROTECTED);
	Core.cvRandomGrenadeTrajectoryColors = CreateConVar("sm_practice_random_grenadecolors", "1", "Should grenade trails have random colors", FCVAR_PROTECTED);

	RegConsoleCmd("sm_psettings", Command_Settings);
}

public APLRes AskPluginLoad2(Handle hSelf, bool bLate, char[] szError, int iLength)
{
	if (GetEngineVersion() != Engine_CSGO)
	{
		strcopy(szError, iLength, "This plugin works only on CS:GO.");

		return APLRes_SilentFailure;
	}

	Core.fOnCoreIsReady = new GlobalForward("MP_OnCoreIsReady", ET_Ignore);
	Core.fPracticeStart = new GlobalForward("MP_OnPracticeStart", ET_Event);
	Core.fPracticeStart = new GlobalForward("MP_OnPracticeStop", ET_Ignore);
	Core.fOnPlayerThrowProjectile = new GlobalForward("MP_OnPlayerThrowProjectile", ET_Ignore, Param_Cell, Param_Cell);

	RegPluginLibrary(TAG_PLUG ... "Core");

	Call_StartForward(Core.fOnCoreIsReady);
	Call_Finish();

	return APLRes_Success;
}

public Action Command_Settings(int iClient, int iArgs)
{
	if (iClient <= 0)
		return Plugin_Handled;

	DisplaySettingsMenu(iClient);
	return Plugin_Handled;
}

void DisplaySettingsMenu(int iClient)
{
	decl char szTranslation[48];

	Menu hMenu = new Menu(Menu_SettingsHandler, (MENU_ACTIONS_DEFAULT | MenuAction_DisplayItem));
	hMenu.SetTitle(TAG_MENU ... "User Settings\n ", iClient);

	for (UserSetting i = UserSetting_DrawGrenadeTrajectories; i < UserSetting_Total; i++)
	{
		FormatEx(szTranslation, sizeof(szTranslation), "User Setting[%i]", view_as<int>(i));
		Format(szTranslation, sizeof(szTranslation), "%T", szTranslation, iClient);

		hMenu.AddItem(NULL_STRING, szTranslation);
	}

	hMenu.ExitButton = true;
	hMenu.Display(iClient, MENU_TIME_FOREVER);
}

public int Menu_SettingsHandler(Menu hMenu, MenuAction iAction, int iClient, int iOption)
{
	switch(iAction)
	{
		case MenuAction_Select:
		{
			g_EPlayer[iClient].iSettings[iOption] ^= view_as<int>(true);
			DisplaySettingsMenu(iClient);
		}

		case MenuAction_DisplayItem:
		{
			decl char szBuffer[32];
			decl char szTranslation[64];

			FormatEx(szTranslation, sizeof(szTranslation), "User Setting[%i]", view_as<int>(iOption));
			FormatEx(szBuffer, sizeof(szBuffer), "%T", (g_EPlayer[iClient].iSettings[iOption] == view_as<int>(true)) ? "User Setting ON" : "User Setting OFF", iClient);
			Format(szTranslation, sizeof(szTranslation), "%T %s", szTranslation, iClient, szBuffer);

			RedrawMenuItem(szTranslation);
		}

		case MenuAction_End:
		{
			delete hMenu;
		}
	}

	return 0;
}

public void OnMapStart()
{
	if (Core.cvAutoStart.BoolValue)
		Core.Start();
}

public void OnMapEnd()
{
	if (Core.bPracticeModeRunning && !Core.bPracticeModeRunning)
		Core.Stop();
}

public void OnClientPutInServer(int iClient)
{
    if (!IsFakeClient(iClient))
        g_EPlayer[iClient].Init(iClient);
}

public void OnClientDisconnect(int iClient)
{
	g_EPlayer[iClient].Clear();
}

public void OnEntityCreated(int iEntity, const char[] szClassName)
{
	if (!Core.bPracticeModeRunning)
		return;

	if (StrContains(szClassName, "_proj") != -1)
		SDKHook(iEntity, SDKHook_SpawnPost, SDKHook_OnEntitySpawnPost);
}

void SDKHook_OnEntitySpawnPost(int iEntity)
{
	if (!Core.cvPatchGrenadeTrajectory.BoolValue)
	{
		SDKUnhook(iEntity, SDKHook_SpawnPost, SDKHook_OnEntitySpawnPost);
		return;
	}

	int iClient = GetEntPropEnt(iEntity, Prop_Data, "m_hOwnerEntity");

	if (iClient > 0 && !IsFakeClient(iClient))
	{
		if (Core.fOnPlayerThrowProjectile.FunctionCount)
		{
			decl char szClassName[24];
			GetEdictClassname(iEntity, szClassName, sizeof(szClassName));

			Call_StartForward(Core.fOnPlayerThrowProjectile);
			Call_PushCell(GetClientUserId(iClient));
			Call_PushCell(view_as<int>(GetGrenadeTypeByClassName(szClassName)));
			Call_Finish();
		}

		if (Core.GrenadeTrajectory.BoolValue)
		{
			decl float fTrajectoryTime;
			decl float iWidths;
			decl int   iColors[4];

			for (int i = 1; i <= MaxClients; i++)
			{
				if (!IsClientConnected(i) || !IsClientInGame(i))
					continue;

				if (!view_as<bool>(g_EPlayer[i].iSettings[UserSetting_DrawGrenadeTrajectories]))
					continue;

				fTrajectoryTime = (GetClientTeam(i) == CS_TEAM_SPECTATOR) ? Core.GrenadeSpecTime.FloatValue : Core.GrenadeTime.FloatValue;

				if (Core.cvRandomGrenadeTrajectoryColors.BoolValue)
				{
					iColors[0] = RandomInt(0, 255);
					iColors[1] = RandomInt(0, 255);
					iColors[2] = RandomInt(0, 255);
					iColors[3] = 255;
				}

				iWidths = (Core.GrenadeThickness.FloatValue * 5);

				TE_SetupBeamFollow(iEntity, Core.iBeamSprite, 0, fTrajectoryTime, iWidths, iWidths, 1, iColors);
				TE_SendToClient(i);
			}
		}
	}

	SDKUnhook(iEntity, SDKHook_SpawnPost, SDKHook_OnEntitySpawnPost);
}