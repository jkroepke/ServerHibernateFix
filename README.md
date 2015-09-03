ServerHibernateFix
==================

A Sourcemod Plugin to work-around the [workshop map server hibernate problem](https://forums.alliedmods.net/showthread.php?t=196133) on Counter-Strike: Global Offensive.

Dependencies
------------
* [Counter-Strike: Global Offensive](http://store.steampowered.com/app/730/)
* [SourceMod](http://www.sourcemod.net/) at least version 1.7.1

Installation
------------
* Downloade `shf.smx` from [here](https://github.com/nefarius/ServerHibernateFix/releases/latest) and move it to your `addons/sourcemod/plugins` directory
* Execute `sm plugins load shf` on your server console
* Adjust `cfg/sourcemod/shf.cfg` to your needs

Cvars
-----
```
// Defines the default map to fall back to before server hibernates
// -
// Default: "de_dust"
sm_shf_default_map "de_dust"

// Enables or disables plugin functionality <1 = Enabled/Default, 0 = Disabled>
// -
// Default: "1"
// Minimum: "0.000000"
// Maximum: "1.000000"
sm_shf_enabled "1"

// Execute config when fallback to default map
// -
// Default: ""
sm_shf_execute_config ""

// Trigger action if clients are <1 = Ingame, 0 = Connected/Default>
// -
// Default: "0"
// Minimum: "0.000000"
// Maximum: "1.000000"
sm_shf_ingame_clients_only "0"
```
