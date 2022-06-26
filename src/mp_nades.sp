#include <anymap>
#include <practice>
#include <sdktools_functions>
#include <sourcemod>

#if !defined RSVP_COMPILER
	#define decl static
#endif

#pragma dynamic 1024
#pragma semicolon 1
#pragma newdecls required

bool g_bLateLoaded;

enum struct ENade
{
	GrenadeType iType;
	float fEyeAngles[3];
	float fAbsOriginAngles[3];
}

enum struct EPlayer
{
	int    iClient;
	int    iNadeIndex[GrenadeType_Total];
	int    iLastFlashIndex;
	float  fEyeAngles[3];
	float  fAbsOriginAngles[3];
	bool   bFlashPractice;
	AnyMap AMFlashes;

	void Clear()
	{
		this.iClient = -1;

		for (GrenadeType i = GrenadeType_Unkown; i < GrenadeType_Total; i++)
			this.iNadeIndex[i] = 0;

		this.iLastFlashIndex = 0;

		for (int i = 0; i < 3; i++)
		{
			this.fEyeAngles[i]       = 0.0;
			this.fAbsOriginAngles[i] = 0.0;
		}

		this.bFlashPractice = false;
		this.AMFlashes.Clear();
	}

	void Init(int iClient)
	{
		this.iClient   = iClient;
		this.AMFlashes = new AnyMap();
	}

	void Flash()
	{
		this.bFlashPractice = true;

		GetClientEyeAngles(this.iClient, this.fEyeAngles);
		GetClientAbsOrigin(this.iClient, this.fAbsOriginAngles);
	}

	void Nade(GrenadeType NadeType)
	{
		this.iNadeIndex[NadeType]++;

		if (NadeType == GrenadeType_Flash)
		{
			ENade hNade;

			hNade.fEyeAngles       = this.fEyeAngles;
			hNade.fAbsOriginAngles = this.fAbsOriginAngles;

			this.iLastFlashIndex = this.iNadeIndex[GrenadeType_Flash];

			this.AMFlashes.SetArray(this.iLastFlashIndex, hNade, sizeof(hNade));
		}
	}
}

EPlayer g_EPlayer[MAXPLAYERS + 1];

public Plugin myinfo =
{
	name    = TAG_PLUG ... "Nades",
	author  = "DRANIX",
	version = "0.1",
	url     = "https://github.com/dran1x" 
}

public void OnPluginStart()
{
	RegConsoleCmd("sm_flash", Command_Flash);

	if (g_bLateLoaded)
	{
		g_bLateLoaded = false;

		for (int i = 1; i <= MaxClients; i++)
			if (IsClientInGame(i))
				OnClientPutInServer(i);
	}
}

public APLRes AskPluginLoad2(Handle hSelf, bool bLate, char[] szError, int iLength)
{
	if (GetEngineVersion() != Engine_CSGO)
	{
		strcopy(szError, iLength, "This plugin works only on CS:GO.");

		return APLRes_SilentFailure;
	}

	g_bLateLoaded = bLate;

	return APLRes_Success;
}

public Action Command_Flash(int iClient, int iArgs)
{
	g_EPlayer[iClient].Flash();

	return Plugin_Handled;
}

public void MP_OnPracticeStop()
{
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

public void MP_OnPlayerThrowProjectile(int iUserID, GrenadeType NadeType)
{
	int iClient = GetClientOfUserId(iUserID);

	g_EPlayer[iClient].Nade(NadeType);

	if (g_EPlayer[iClient].bFlashPractice && NadeType == GrenadeType_Flash)
		CreateTimer(0.3, Timer_FlashTeleport, iUserID);
}

public Action Timer_FlashTeleport(Handle hTimer, int iUserID)
{
	int iClient = GetClientOfUserId(iUserID);

	if (!g_EPlayer[iClient].bFlashPractice)
		return Plugin_Stop;

	if (iClient <= 0 && !IsClientInGame(iClient) || !IsPlayerAlive(iClient))
		return Plugin_Stop;

	ENade hNade;

	g_EPlayer[iClient].AMFlashes.GetArray(g_EPlayer[iClient].iLastFlashIndex, hNade, sizeof(hNade));

	TeleportEntity(iClient, hNade.fAbsOriginAngles, hNade.fEyeAngles, NULL_VECTOR);

	SetEntityMoveType(iClient, MOVETYPE_NONE);

	CreateTimer(1.5, Timer_SetMovement, iUserID);

	return Plugin_Stop;
}

public Action Timer_SetMovement(Handle Timer, int iUserID)
{
	int iClient = GetClientOfUserId(iUserID);

	if (iClient <= 0 && !IsClientInGame(iClient) || !IsPlayerAlive(iClient))
		return Plugin_Stop;

	SetEntityMoveType(iClient, MOVETYPE_WALK);

	return Plugin_Stop;
}