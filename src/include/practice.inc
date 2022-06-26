#if defined _practice_included_
    #endinput
#endif
#define _practice_included_

#define TAG_CHAT "[\x06Practice\x01]"
#define TAG_CONSOLE "[{GREEN}Practice{DEFAULT}]"
#define TAG_MENU "Practice | "
#define TAG_PLUG "[MP] "

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

stock const char szGrenadeTypes[][] =
{
    "Unkown",
    "Smoke",
    "Flashbang",
    "HE",
    "Molotov",
    "Decoy",
    "Incendiary"
}

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