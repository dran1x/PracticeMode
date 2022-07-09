#include <anymap>
#include <practice>
#include <sdkhooks>
#include <sdktools>
#include <sourcemod>

#if !defined RSVP_COMPILER
	#define decl static
#endif

#pragma dynamic 1024
#pragma semicolon 1
#pragma newdecls required

bool   g_bLateLoaded;
int    g_iBeamSprite;
ConVar g_cvGravity;

enum struct ENade
{
	GrenadeType iType;
	float       fEyeAngles[3];
	float       fAbsOriginAngles[3];
}

enum struct EPlayer
{
	int    iClient;
	int    iNadeIndex[GrenadeType_Total];
	// int    iLastNadeIndex;
	float  fEyeAngles[3];
	float  fAbsOriginAngles[3];
	bool   bNadePractice;
	AnyMap AMNades;

	void Clear()
	{
		this.iClient = -1;

		for (GrenadeType i = GrenadeType_Unkown; i < GrenadeType_Total; i++) this.iNadeIndex[i] = 0;

		// this.iLastNadeIndex = 0;

		for (int i = 0; i < 3; i++)
		{
			this.fEyeAngles[i]       = 0.0;
			this.fAbsOriginAngles[i] = 0.0;
		}

		this.bNadePractice = false;

		// if (this.AMFlashes != null)
		delete this.AMNades;
	}

	void Init(int iClient)
	{
		this.iClient = iClient;
		this.AMNades = new AnyMap();
	}

	void Flash()
	{
		this.bNadePractice = true;

		GetClientEyeAngles(this.iClient, this.fEyeAngles);
		GetClientAbsOrigin(this.iClient, this.fAbsOriginAngles);
	}

	void Nade(GrenadeType NadeType)
	{
		ENade iNade;

		iNade.fEyeAngles       = this.fEyeAngles;
		iNade.fAbsOriginAngles = this.fAbsOriginAngles;

		// this.iLastNadeIndex = this.iNadeIndex[NadeType]++;

		// this.AMNades.SetArray(this.iLastNadeIndex, iNade, sizeof(iNade));
		this.AMNades.SetArray(this.iNadeIndex[NadeType]++, iNade, sizeof(iNade));
	}

	int GetLastNade()
	{
		return this.AMNades.Size;
	}
}

EPlayer g_EPlayer[MAXPLAYERS + 1];

public Plugin myinfo =
{
	name    = TAG_PLUG... "Nades Module",
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

	g_cvGravity = FindConVar("sv_gravity");
}

public void OnMapStart()
{
	g_iBeamSprite = PrecacheModel("materials/sprites/physbeam.vmt");
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

public Action MP_OnPracticeStart()
{
	return Plugin_Continue;
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

	if (g_EPlayer[iClient].bNadePractice)
		CreateTimer(0.3, Timer_FlashTeleport, iUserID);
}

public Action Timer_FlashTeleport(Handle hTimer, int iUserID)
{
	int iClient = GetClientOfUserId(iUserID);

	if (!g_EPlayer[iClient].bNadePractice || !IsClientInGame(iClient) || !IsPlayerAlive(iClient))
		return Plugin_Stop;

	ENade iNade;

	g_EPlayer[iClient].AMNades.GetArray(g_EPlayer[iClient].GetLastNade(), iNade, sizeof(iNade));

	TeleportEntity(iClient, iNade.fAbsOriginAngles, iNade.fEyeAngles, NULL_VECTOR);

	SetEntityMoveType(iClient, MOVETYPE_NONE);

	CreateTimer(1.5, Timer_SetMovement, iUserID);

	return Plugin_Stop;
}

public Action Timer_SetMovement(Handle Timer, int iUserID)
{
	int iClient = GetClientOfUserId(iUserID);

	if (!IsClientInGame(iClient) || !IsPlayerAlive(iClient))
		return Plugin_Stop;

	SetEntityMoveType(iClient, MOVETYPE_WALK);

	return Plugin_Stop;
}

public void OnPlayerRunCmdPre(int iClient, int iButtons, int impulse, const float vel[3], const float angles[3], int weapon, int subtype, int cmdnum, int tickcount, int seed, const int mouse[2])
{
	if (!(iButtons & IN_ATTACK) && !(iButtons & IN_ATTACK2))
		return;

	static char szWeapon[32];
	GetClientWeapon(iClient, szWeapon, sizeof(szWeapon));

	static GrenadeType iNade;
	if ((iNade = GetGrenadeTypeByClassName(szWeapon)) != GrenadeType_Unkown)
	{
		static float fFactor, fDisplacement;

		switch (iButtons)
		{
			case (IN_ATTACK & IN_ATTACK2):
			{
				fFactor       = 0.6;
				fDisplacement = -6.0;
			}

			case IN_ATTACK:
			{
				fFactor       = 0.9;
				fDisplacement = 0.0;
			}

			case IN_ATTACK2:
			{
				fFactor       = 0.27;
				fDisplacement = -12.0;
			}
		}

		ShowTrajectory(iClient, iNade, fFactor, fDisplacement);
	}
}

// Thanks to Psycheat for this
stock void ShowTrajectory(int iClient, GrenadeType iNade, float factor, float disp)
{
	float GrenadeVelocity[3];
	float PlayerVelocity[3];
	float ThrowAngle[3];
	float ThrowVector[3];
	float ThrowVelocity;
	float gStart[3];
	float gEnd[3];
	float fwd[3];
	float right[3];
	float up[3];
	float dtime = 1.5;

	GetClientEyeAngles(iClient, ThrowAngle);
	ThrowAngle[0] = -10.0 + ThrowAngle[0] + FloatAbs(ThrowAngle[0]) * 10.0 / 90.0;

	GetAngleVectors(ThrowAngle, fwd, right, up);
	NormalizeVector(fwd, ThrowVector);

	GetClientEyePosition(iClient, gStart);

	for (int i = 0; i < 3; i++)
		gStart[i] += ThrowVector[i] * 16.0;

	gStart[2] += disp;

	GetEntPropVector(iClient, Prop_Data, "m_vecAbsVelocity", PlayerVelocity);

	ThrowVelocity = 750.0 * factor;
	ScaleVector(PlayerVelocity, 1.25);

	for (int i = 0; i < 3; i++)
	{
		GrenadeVelocity[i] = ThrowVector[i] * ThrowVelocity + PlayerVelocity[i];
	}

	float dt = 0.05;
	for (float t = 0.0; t <= dtime; t += dt)
	{
		gEnd[0] = gStart[0] + GrenadeVelocity[0] * dt;
		gEnd[1] = gStart[1] + GrenadeVelocity[1] * dt;

		float gForce      = 0.4 * g_cvGravity.FloatValue;
		float NewVelocity = GrenadeVelocity[2] - gForce * dt;
		float AvgVelocity = (GrenadeVelocity[2] + NewVelocity) / 2.0;

		gEnd[2]            = gStart[2] + AvgVelocity * dt;
		GrenadeVelocity[2] = NewVelocity;

		float mins[3] = { -2.0, -2.0, -2.0 };
		float maxs[3] = { 2.0, 2.0, 2.0 };

		Handle gRayTrace = TR_TraceHullEx(gStart, gEnd, mins, maxs, MASK_SHOT_HULL);

		if (TR_GetFraction(gRayTrace) != 1.0)
		{
			if (TR_GetEntityIndex(gRayTrace) == iClient && t == 0.0)
			{
				CloseHandle(gRayTrace);
				gStart = gEnd;
				continue;
			}

			TR_GetEndPosition(gEnd, gRayTrace);

			float NVector[3];
			TR_GetPlaneNormal(gRayTrace, NVector);

			float Impulse = 2.0 * GetVectorDotProduct(NVector, GrenadeVelocity);

			for (int i = 0; i < 3; i++)
			{
				GrenadeVelocity[i] -= Impulse * NVector[i];

				if (FloatAbs(GrenadeVelocity[i]) < 0.1)
					GrenadeVelocity[i] = 0.0;
			}

			float SurfaceElasticity = GetEntPropFloat(TR_GetEntityIndex(gRayTrace), Prop_Send, "m_flElasticity");
			float elasticity        = 0.45 * SurfaceElasticity;
			ScaleVector(GrenadeVelocity, elasticity);

			float ZVector[3] = { 0.0, 0.0, 1.0 };
			if (GetVectorDotProduct(NVector, ZVector) > 0.7)
			{
				if (iNade == GrenadeType_Incendiary || iNade == GrenadeType_Molotov)
					dtime = 0.0;
			}
		}

		delete gRayTrace;

		float width = 0.5;
		TE_SetupBeamPoints(gStart, gEnd, g_iBeamSprite, 0, 0, 0, 0.2, width, width, 0, 0.0, { 0, 100, 255, 255 }, 0);
		TE_SendToClient(iClient);

		gStart = gEnd;
	}
}