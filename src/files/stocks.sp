stock static bool IsPlayerMoving(int iButtons)
{
    return (iButtons & IN_FORWARD) || (iButtons & IN_MOVELEFT) || (iButtons & IN_MOVERIGHT) || (iButtons & IN_BACK);
}

stock void RestartGame(int iRoundTime = 1)
{
    ServerCommand("mp_restartgame %i", iRoundTime);
}

stock int RandomInt(int iMin, int iMax)
{
	return RoundToZero(GetURandomFloat() * (iMax - iMin + 1) + iMin);
}

stock GrenadeType GetGrenadeTypeByClassName(const char[] szClassName)
{
    switch (szClassName[2])
    {
        case 'o':   return GrenadeType_Smoke;
        case 'a':   return GrenadeType_Flash;
        case 'g':   return GrenadeType_HE;
        case 'l':   return GrenadeType_Molotov;
        case 'c':   return (szClassName[0] == 'i') ? GrenadeType_Incendiary : GrenadeType_Decoy;
    }

    return GrenadeType_Unkown;
}

stock char IntToStr(int iInt)
{
	decl char s[32];
	FormatEx(s, sizeof(s), "%i", iInt);
	return s;
}