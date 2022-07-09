public int Native_GetPracticeSetting(Handle hPlugin, int iParams)
{
	return 1;
}

public UserSetting Native_GetClientPracticeSetting(Handle hPlugin, int iParams)
{
    int iUserID = GetNativeCell(1);
    int iClient = GetClientOfUserId(iUserID);

    if (!g_EPlayer[iClient].bInitialized)
        return UserSetting_None;
    
    UserSetting iSetting = GetNativeCell(2);

    return view_as<UserSetting>(g_EPlayer[iClient].iSettings[iSetting]);
}

public bool Native_RegisterNative(Handle hPlugin, int iParams)
{
    
}