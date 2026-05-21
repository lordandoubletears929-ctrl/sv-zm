#include <amxmodx>
#include <cstrike>
#include <fakemeta>
#include <hamsandwich>
#include <cs_ham_bots_api>
#include <zp50_core>
#define LIBRARY_NEMESIS "zp50_class_nemesis"
#include <zp50_class_nemesis>
#define LIBRARY_SURVIVOR "zp50_class_survivor"
#include <zp50_class_survivor>

#define TASK_NIGHTVISION 100
#define ID_NIGHTVISION (taskid - TASK_NIGHTVISION)

new NVISION_Light[4]
new sZpLight[16]

#define flag_get(%1,%2) (%1 & (1 << (%2 & 31)))
#define flag_get_boolean(%1,%2) (flag_get(%1,%2) ? true : false)
#define flag_set(%1,%2) %1 |= (1 << (%2 & 31))
#define flag_unset(%1,%2) %1 &= ~(1 << (%2 & 31))

new g_NightVisionActive

new cvar_nvision_zombie, cvar_nvision_human, cvar_nvision_spec, cvar_nvision_nemesis, cvar_nvision_survivor
new cvar_nvision_light

public plugin_init()
{
	register_plugin("[ZP] Nightvision", ZP_VERSION_STRING, "Leo_[BH] & ZP Dev Team")
	
	register_clcmd("nightvision", "clcmd_nightvision_toggle")
	RegisterHam(Ham_Killed, "player", "fw_PlayerKilled_Post", 1)
	RegisterHamBots(Ham_Killed, "fw_PlayerKilled_Post", 1)
	
	register_forward(FM_PlayerPreThink, "fw_clientPreThink", 0)
	
	register_event("HLTV", "event_round_start", "a", "1=0", "2=0")
	
	cvar_nvision_light = register_cvar("zp_nvision_light", "m")
	
	cvar_nvision_zombie = register_cvar("zp_nvision_zombie", "2") // 1-give only // 2-give and enable

	cvar_nvision_human = register_cvar("zp_nvision_human", "0") // 1-give only // 2-give and enable

	cvar_nvision_spec = register_cvar("zp_nvision_spec", "2") // 1-give only // 2-give and enable

	// Nemesis Class loaded?
	if (LibraryExists(LIBRARY_NEMESIS, LibType_Library))
	{
		cvar_nvision_nemesis = register_cvar("zp_nvision_nemesis", "2") // 1-give only // 2-give and enable
	}
	
	// Survivor Class loaded?
	if (LibraryExists(LIBRARY_SURVIVOR, LibType_Library))
	{
		cvar_nvision_survivor = register_cvar("zp_nvision_survivor", "1") // 1-give only // 2-give and enable
	}
}

public plugin_cfg()
{
	new configsdir[128]
	get_localinfo("amxx_configsdir", configsdir, 127)
	server_cmd("exec %s/zp_nvision.cfg", configsdir)
	
	get_pcvar_string( cvar_nvision_light, NVISION_Light, 3 );
}

public plugin_natives()
{
	set_module_filter("module_filter")
	set_native_filter("native_filter")
}
public module_filter(const module[])
{
	if (equal(module, LIBRARY_NEMESIS) || equal(module, LIBRARY_SURVIVOR))
		return PLUGIN_HANDLED;
	
	return PLUGIN_CONTINUE;
}
public native_filter(const name[], index, trap)
{
	if (!trap)
		return PLUGIN_HANDLED;
		
	return PLUGIN_CONTINUE;
}

public zp_fw_core_infect_post(id, attacker)
{
	// Nemesis Class loaded?
	if (LibraryExists(LIBRARY_NEMESIS, LibType_Library) && zp_class_nemesis_get(id))
	{
		if (get_pcvar_num(cvar_nvision_nemesis))
		{
			if (!cs_get_user_nvg(id)) cs_set_user_nvg(id, 1)
			
			if (get_pcvar_num(cvar_nvision_nemesis) == 2)
			{
				if (!flag_get(g_NightVisionActive, id))
					clcmd_nightvision_toggle(id)
			}
			else if (flag_get(g_NightVisionActive, id))
				clcmd_nightvision_toggle(id)
		}
		else
		{
			cs_set_user_nvg(id, 0)
			
			if (flag_get(g_NightVisionActive, id))
				DisableNightVision(id)
		}
	}
	else
	{
		if (get_pcvar_num(cvar_nvision_zombie))
		{
			if (!cs_get_user_nvg(id)) cs_set_user_nvg(id, 1)
			
			if (get_pcvar_num(cvar_nvision_zombie) == 2)
			{
				if (!flag_get(g_NightVisionActive, id))
					clcmd_nightvision_toggle(id)
			}
			else if (flag_get(g_NightVisionActive, id))
				clcmd_nightvision_toggle(id)
		}
		else
		{
			cs_set_user_nvg(id, 0)
			
			if (flag_get(g_NightVisionActive, id))
				DisableNightVision(id)
		}
	}
	
//	// Always give nightvision to PODBots
//	if (is_user_bot(id) && !cs_get_user_nvg(id))
//		cs_set_user_nvg(id, 1)
}

public zp_fw_core_cure_post(id, attacker)
{
	// Survivor Class loaded?
	if (LibraryExists(LIBRARY_SURVIVOR, LibType_Library) && zp_class_survivor_get(id))
	{
		if (get_pcvar_num(cvar_nvision_survivor))
		{
			if (!cs_get_user_nvg(id)) cs_set_user_nvg(id, 1)
			
			if (get_pcvar_num(cvar_nvision_survivor) == 2)
			{
				if (!flag_get(g_NightVisionActive, id))
					clcmd_nightvision_toggle(id)
			}
			else if (flag_get(g_NightVisionActive, id))
				clcmd_nightvision_toggle(id)
		}
		else
		{
			cs_set_user_nvg(id, 0)
			
			if (flag_get(g_NightVisionActive, id))
				DisableNightVision(id)
		}
	}
	else
	{
		if (get_pcvar_num(cvar_nvision_human))
		{
			if (!cs_get_user_nvg(id)) cs_set_user_nvg(id, 1)
			
			if (get_pcvar_num(cvar_nvision_human) == 2)
			{
				if (!flag_get(g_NightVisionActive, id))
					clcmd_nightvision_toggle(id)
			}
			else if (flag_get(g_NightVisionActive, id))
				clcmd_nightvision_toggle(id)
		}
		else
		{
			cs_set_user_nvg(id, 0)
			
			if (flag_get(g_NightVisionActive, id))
				DisableNightVision(id)
		}
	}
	
//	// Always give nightvision to PODBots
//	if (is_user_bot(id) && !cs_get_user_nvg(id))
//		cs_set_user_nvg(id, 1)
}

public clcmd_nightvision_toggle(id)
{
	if (is_user_alive(id))
	{
		// Player owns nightvision?
		if (!cs_get_user_nvg(id))
			return PLUGIN_CONTINUE;
	}
	else
	{
		// Spectator nightvision disabled?
		if (!get_pcvar_num(cvar_nvision_spec))
			return PLUGIN_CONTINUE;
	}
	
	if (flag_get(g_NightVisionActive, id))
		DisableNightVision(id)
	else
		EnableNightVision(id)
	
	return PLUGIN_HANDLED;
}

// Ham Player Killed Post Forward
public fw_PlayerKilled_Post(victim, attacker, shouldgib)
{
	// Enable spectators nightvision?
	spectator_nightvision(victim)
}

public client_putinserver(id)
{
	// Enable spectators nightvision?
	set_task(0.1, "spectator_nightvision", id)
}

public spectator_nightvision(id)
{
	// Player disconnected
	if (!is_user_connected(id))
		return;
	
	// Not a spectator
	if (is_user_alive(id))
		return;
	
	if (get_pcvar_num(cvar_nvision_spec) == 2)
	{
		if (!flag_get(g_NightVisionActive, id))
			clcmd_nightvision_toggle(id)
	}
	else if (flag_get(g_NightVisionActive, id))
		DisableNightVision(id)
}

public client_disconnect(id)
{
	// Reset nightvision flags
	flag_unset(g_NightVisionActive, id)
	cmd_get_real_light()
}

EnableNightVision(id)
{
	flag_set(g_NightVisionActive, id)
	cmd_get_real_light()
}

DisableNightVision(id)
{
	flag_unset(g_NightVisionActive, id)
	cmd_get_real_light()
}

public fw_clientPreThink(id)
{
	if(is_user_connected(id) && !is_user_bot(id)) // Not send to nots 
	{
		if (!flag_get(g_NightVisionActive, id))
			set_player_light(id, sZpLight)
		else if (flag_get(g_NightVisionActive, id))
			set_player_light(id, NVISION_Light)
	}
}

public cmd_get_real_light()
{
	new cvar_light_zp = get_cvar_pointer("zp_lighting") 
	get_pcvar_string(cvar_light_zp, sZpLight, 15)
}

public event_round_start() 
{
	cmd_get_real_light()
	
	for(new i = 1; i <= 32; i++)
	{
		if(!is_user_connected(i)) continue
		if(is_user_bot(i)) continue
		
		set_player_light(i, sZpLight)
	}
}

stock set_player_light(id, const LightStyle[])
{
//	message_begin(MSG_ONE, SVC_LIGHTSTYLE, .player = id)
	message_begin(MSG_ONE_UNRELIABLE, SVC_LIGHTSTYLE, .player = id) // UNRELIABLE
	
	write_byte(0)
	write_string(LightStyle)
	message_end()
}

