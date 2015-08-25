#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <regex>

#define PLUGIN_VERSION	"0.0.5"
#define ERR_INVALID_MAP	"Setting a workshop map (%s) as default map won't work, \
							please set a regular one like 'de_dust'"

// Cvar handles
ConVar g_cvarEnabled;
ConVar g_cvarFallbackMap;
ConVar g_cvarHibernateDelay;
ConVar g_cvarIngameOnly;
ConVar g_cvarExecuteConfig;
Handle g_RegexWorkshopMap;


public Plugin myinfo = {
	name = "[CS:GO] Server Hibernate Fix",
	author = "Nefarius",
	description = "Switches to defined map if server is empty",
	version = PLUGIN_VERSION,
	url = "https://github.com/jokroepke/ServerHibernateFix"
}

public void OnPluginStart() {
	// Matches a workshop map path
	g_RegexWorkshopMap = CompileRegex("^workshop[\\\\|\\/]\\d*[\\\\|\\/]");
	
	// Plugin version
	CreateConVar("sm_shf_version", PLUGIN_VERSION, "Version of Server Hibernate Fix", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_UNLOGGED|FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY);

	// Enable/disable plugin on the fly
	g_cvarEnabled = CreateConVar("sm_shf_enabled", "1", "Enables or disables plugin functionality <1 = Enabled/Default, 0 = Disabled>", 0, true, 0.0, true, 1.0);
	if (g_cvarEnabled == INVALID_HANDLE) {
		LogError("Couldn't register 'sm_shf_enabled'!");
	}

	// Set the map to fall back to
	g_cvarFallbackMap = CreateConVar("sm_shf_default_map", "de_dust", "Defines the default map to fall back to before server hibernates");
	if (g_cvarFallbackMap == null) {
		LogError("Couldn't register 'sm_shf_default_map'!");
	} else {
		// Monitor Cvar change to filter user input
		g_cvarFallbackMap.AddChangeHook(OnConvarChanged);
	}
	// Let's the user decide if only in-game clients count as connected players
	g_cvarIngameOnly = CreateConVar("sm_shf_ingame_clients_only", "0", "Trigger action if clients are <1 = Ingame, 0 = Connected/Default>", 0, true, 0.0, true, 1.0);
	if (g_cvarIngameOnly == null)
		LogError("Couldn't register 'sm_shf_ingame_clients_only'!");

	// Execute a custom config
	g_cvarExecuteConfig = CreateConVar("sm_shf_execute_config", "",
		"Execute config when fallback to default map");
	if (g_cvarExecuteConfig == null)
		LogError("Couldn't register 'sm_shf_execute_config'!");
	
	// Get hibernate delay Cvar
	g_cvarHibernateDelay = FindConVar("sv_hibernate_postgame_delay");
	if (g_cvarHibernateDelay == null) {
		SetFailState("'sv_hibernate_postgame_delay' not found! Is this CS:GO?");
	}
	
	// Get real player disconnect event
	HookEvent("player_disconnect", Event_PlayerDisconnect, EventHookMode_Post);
	
	// Load configuration file
	AutoExecConfig(true, "shf");
}

public void OnPluginEnd() {
	// Free Regex resources
	if (g_RegexWorkshopMap != INVALID_HANDLE)
		CloseHandle(g_RegexWorkshopMap);
}

public void OnMapStart() {
	// Set hibernation delay high enough for the plugin to handle events
	if (g_cvarHibernateDelay != INVALID_HANDLE)
		SetConVarInt(g_cvarHibernateDelay, 30);
}

public Action Event_PlayerDisconnect(Handle event, const char[] name, bool dontBroadcast) {
	// If a bot triggered this event, ignore
	if (GetEventBool(event, "bot"))
		return Plugin_Continue;
	
	// Delay fallback action to prevent race condition
	CreateTimer(GetRandomFloat(2.0, 10.0), Timer_ClientDisconnected);
	
	return Plugin_Continue;
}

public Action Timer_ClientDisconnected(Handle timer) {
	// Don't interfere if user has disabled functionality
	if (g_cvarEnabled.IntValue == 0)
		return Plugin_Continue;
	
	// Detect if server is really empty
	if (GetRealClientCount(g_cvarIngameOnly.IntValue == 1) == 0)
	{
		// Get fallback map name
		char map[128];
		g_cvarFallbackMap.GetString(map, 128);

		char map_current[128];
		GetCurrentMap(map_current, sizeof(map_current));
		
		// Don't switch if current map is fallback map
		if (StrEqual(map_current, map))
			return Plugin_Continue;
		
		// Validate that it's not a workshop map
		if (MatchRegex(g_RegexWorkshopMap, map) > 0)
			SetFailState(ERR_INVALID_MAP, map);
		
		LogMessage("Server is empty, changing map to '%s'", map);

		char cfg[128];
		g_cvarFallbackMap.GetString(cfg, 128);
		if (cfg[0])
		{
			ServerCommand("exec %s", cfg);
		}

		// Validate that map exists
		if (IsMapValid(map))
		{
			ForceChangeLevel(map, "Server is empty");
		}
		else
		{
			LogError("Couldn't change to '%s', does it exist?", map);
		}
	}
	
	return Plugin_Continue;
}

stock int GetRealClientCount(bool inGameOnly = true) {
	int clients = 0;
	int maxPlayers = GetMaxClients();

	// gets real player count depending on connection state
	for (int i = 1; i <= maxPlayers; i++) {
		if (((inGameOnly) ? IsClientInGame(i) : IsClientConnected(i)) && !IsFakeClient(i))
		{
			clients++;
		}
	}
	
	return clients;
}

public void OnConvarChanged(ConVar cvar, char[] oldVal, char[] newVal) {
	// Validate that it's not a workshop map
	if (MatchRegex(g_RegexWorkshopMap, newVal) > 0)
	{
		// Revert to default value and notify user about the error
		ResetConVar(cvar);
		LogError(ERR_INVALID_MAP, newVal);
	}
}