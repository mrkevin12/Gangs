#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <gangs>

#pragma newdecls optional
#include <regex>
#pragma newdecls required

// 3rd includes
#include <chat-processor>
#include <multicolors>

#include "gangs/global.sp"
#include "gangs/config.sp"
#include "gangs/events.sp"
#include "gangs/sqlconnect.sp"

// old structur
#include "gangs/sql.sp"
#include "gangs/native.sp"
#include "gangs/stock.sp"

// new structur
#include "gangs/shared.sp"
#include "gangs/gcreate.sp"
#include "gangs/glist.sp"
#include "gangs/gleft.sp"
#include "gangs/gmenu.sp"
#include "gangs/gdelete.sp"
#include "gangs/grename.sp"
#include "gangs/gchat.sp"
#include "gangs/gsettings.sp"
#include "gangs/gabort.sp"
#include "gangs/ginvite.sp"

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	g_hSQLConnected = CreateGlobalForward("Gangs_OnSQLConnected", ET_Ignore, Param_Cell);
	g_hGangCreated = CreateGlobalForward("Gangs_OnGangCreated", ET_Ignore, Param_Cell, Param_Cell);
	g_hGangLeft = CreateGlobalForward("Gangs_OnGangLeft", ET_Ignore, Param_Cell, Param_Cell);
	g_hGangDelete = CreateGlobalForward("Gangs_OnGangDelete", ET_Ignore, Param_Cell, Param_Cell, Param_String);
	g_hGangRename = CreateGlobalForward("Gangs_OnGangRename", ET_Ignore, Param_Cell, Param_Cell, Param_String, Param_String);
	g_hGangClientJoined = CreateGlobalForward("Gangs_OnClientJoinedGang", ET_Ignore, Param_Cell, Param_Cell); // TODO: maybe a second forward to block this 
	
	CreateNative("Gangs_IsClientInGang", Native_IsClientInGang);
	CreateNative("Gangs_GetClientLevel", Native_GetClientAccessLevel);
	CreateNative("Gangs_GetClientGang", Native_GetClientGang);
	CreateNative("Gangs_ClientLeftGang", Native_LeftClientGang);
	CreateNative("Gangs_CreateClientGang", Native_CreateClientGang);
	CreateNative("Gangs_DeleteClientGang", Native_DeleteClientGang);
	CreateNative("Gangs_OpenClientGang", Native_OpenClientGang);
	CreateNative("Gangs_RenameClientGang", Native_RenameClientGang);
	CreateNative("Gangs_GetRangName", Native_GetRangName);
	
	CreateNative("Gangs_GetName", Native_GetGangName);
	CreateNative("Gangs_GetPoints", Native_GetGangPoints);
	CreateNative("Gangs_AddPoints", Native_AddGangPoints);
	CreateNative("Gangs_RemovePoints", Native_RemoveGangPoints);
	CreateNative("Gangs_GetMaxMembers", Native_GetGangMaxMembers);
	CreateNative("Gangs_GetMembersCount", Native_GetGangMembersCount);
	CreateNative("Gangs_GetOnlinePlayers", Native_GetOnlinePlayerCount);
	
	RegPluginLibrary("gangs");
	
	return APLRes_Success;
}

public Plugin myinfo = 
{
	name = GANGS_NAME ... "Core",
	author = GANGS_AUTHOR,
	description = GANGS_DESCRIPTION,
	version = GANGS_VERSION,
	url = GANGS_URL
};

public void OnPluginStart()
{
	LoadTranslations("common.phrases");
	
	CreateConfig();
	
	RegConsoleCmd("sm_gang", Command_Gang);
	RegConsoleCmd("sm_g", Command_GangChat);
	RegConsoleCmd("sm_gcreate", Command_CreateGang);
	RegConsoleCmd("sm_glist", Command_ListGang);
	RegConsoleCmd("sm_gleft", Command_LeftGang);
	RegConsoleCmd("sm_gdelete", Command_DeleteGang);
	RegConsoleCmd("sm_grename", Command_RenameGang);
	RegConsoleCmd("sm_gabort", Command_AbortGang);
	RegConsoleCmd("sm_ginvite", Command_InviteGang);
	
	// for rename
	AddCommandListener(Command_Say, "say");
	AddCommandListener(Command_Say, "say2");
	AddCommandListener(Command_Say, "say_team");
	
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("bomb_planted", Event_BombPlanted);
	HookEvent("bomb_exploded", Event_BombExploded);
	HookEvent("bomb_defused", Event_BombDefused);
	HookEvent("hostage_follows", Event_HostageFollow);
	HookEvent("hostage_rescued", Event_HostageRescued);
	HookEvent("vip_escaped", Event_VipEscape);
	HookEvent("vip_killed", Event_VipKilled);
	HookEvent("player_changename", Event_ChangeName);
}

public void OnMapStart()
{
	Gangs_ClearArray();
	Gangs_CheckGame();
	Gangs_CreateCache();
	Gangs_SQLConnect();
}

public void OnClientPutInServer(int client)
{
	Format(g_sClientID[client], sizeof(g_sClientID[]), "0");
	Gangs_PushClientArray(client);
}

public void OnClientDisconnect(int client)
{
	Gangs_EraseClientArray(client);
	Format(g_sClientID[client], sizeof(g_sClientID[]), "0");
}
