#if defined _practice_included_
    #endinput
#endif
#define _practice_included_

#define TAG_CHAT "[\x06Practice\x01]"
#define TAG_CONSOLE "[{GREEN}Practice{DEFAULT}]"
#define TAG_CONSOLE_NCLR "[Practice]"
#define TAG_MENU "Practice | "
#define TAG_PLUG "[MP] "

#define MAX_PLUGIN_NAME_LENTGH		32
#define MAX_DESCRIPTION_LENGTH		128
#define MAX_AUTHOR_LENGTH			64
#define MAX_PLUGIN_FILEPATH_LENGTH	(MAX_PLUGIN_NAME_LENTGH * 2)

#define GITHUB_REPOSITORY_LENGTH	100

enum UserSetting
{
    UserSetting_None,
    UserSetting_DrawGrenadeTrajectories,
    UserSetting_RestrictMobilityNade,
    UserSetting_Total
}

enum GrenadeType
{
    GrenadeType_Unkown,
    GrenadeType_Smoke,
    GrenadeType_Flash,
    GrenadeType_HE,
    GrenadeType_Molotov,
    GrenadeType_Decoy,
    GrenadeType_Incendiary,
    GrenadeType_Total
}

/**
 * @param iUserID	    Client userid that threw the nade.
 * @param NadeType		Type of nade entity.
 *
 */
native UserSetting MP_GetClientPracticeSetting(int iUserID, UserSetting iSetting);

/**
 * Called when practice core is fully functional.
 *
 */
forward void MP_OnCoreIsReady();

/**
 * Called on practice mode start.
 *
 * @return
 *  - Plugin_Continue	Continues loading.
 *  - Plugin_Handled	Stops loading.
 *  - Plugin_Stop		Stops loading.
 */
forward Action MP_OnPracticeStart();

/**
 * Called on practice mode end.
 *
 */
forward void MP_OnPracticeStop();

/**
 * Called on grenade entity spawn.
 *
 * @param iUserID	    Client userid that threw the nade.
 * @param NadeType		Type of nade entity.
 *
 */
forward void MP_OnPlayerThrowProjectile(int iUserID, GrenadeType NadeType);
// 
stock GrenadeType GetGrenadeTypeByClassName(const char[] szClassName)
{
    switch (szClassName[(2 + 7)])
    {
        case 'o':   return GrenadeType_Smoke;
        case 'a':   return GrenadeType_Flash;
        case 'g':   return GrenadeType_HE;
        case 'l':   return GrenadeType_Molotov;
        case 'c':   return (szClassName[0] == 'i') ? GrenadeType_Incendiary : GrenadeType_Decoy;
    }

    return GrenadeType_Unkown;
}

stock const char szGrenadeTypes[][] =
{
    "Unkown",
    "Smoke",
    "Flashbang",
    "HE",
    "Molotov",
    "Decoy",
    "Incendiary"
};

public SharedPlugin __pl_practice =
{
	name = TAG_PLUG ... "Core",
	file = "mp_core.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
}