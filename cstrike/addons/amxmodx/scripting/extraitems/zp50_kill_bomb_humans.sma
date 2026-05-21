//-----------------------

#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <hamsandwich>
#include <fun>
#include <zp50_items>
#include <zp50_core>
#include <zp50_ammopacks>
#include <zp50_gamemodes>
#include <zp50_class_survivor>
#include <zp50_class_nemesis>

//-----------------------

#define PLUGIN "ZP Extra KillBomb For Humans"
#define VERSION "1.0"
#define AUTHOR "H.RED.ZONE"

//-----------------------

const Float:NADE_EXPLOSION_RADIUS = 240.0 //Set radius of explosion for kill
const PEV_NADE_TYPE = pev_flTimeStepSound
const NADE_TYPE_KILLBOMB = 6669

//-----------------------

const COLOR_R = 100 //Set red
const COLOR_G = 200 //Set green
const COLOR_B = 200 //Set blue

//-----------------------

const BUY_LIMIT = 2 //Set limit on round.

//-----------------------

new const ITEM_NAME[] = "Kill Bomb"
new const ITEM_COST = 30

//-----------------------

new const MODEL_P[] = "models/zombie_plague/p_kill_bomb_humans.mdl"
new const MODEL_V[] = "models/zombie_plague/v_kill_bomb_humans.mdl"
new const MODEL_W[] = "models/zombie_plague/w_kill_bomb_humans.mdl"

//-----------------------

new const SPRITES_TRAIL[] = "sprites/laserbeam.spr"
new const SPRITES_EXPLODE[] = "sprites/blue.spr"

//-----------------------

new const SOUND_BUY[] = "zombie_plague/killbomb_buy.wav"
new const SOUND_EXPLODE[] = "zombie_plague/killbomb_exp.wav"

//-----------------------

new g_itemid_killbomb, g_killbomb_spr_trail, g_killbomb_spr_exp, g_maxplayers, g_roundend, g_killbombbuycount
new g_haskillbomb[33], g_killedbykillbomb[33]
new cvar_bonushp, cvar_surfree, cvar_enablekill, cvar_allow_survivor

//-----------------------

public plugin_precache()
{
	precache_model(MODEL_P)
	precache_model(MODEL_V)
	precache_model(MODEL_W)
	
	g_killbomb_spr_trail = precache_model(SPRITES_TRAIL)
	g_killbomb_spr_exp = precache_model(SPRITES_EXPLODE)
	
	precache_sound(SOUND_BUY)
	precache_sound(SOUND_EXPLODE)
}

//-----------------------

public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	register_event("HLTV", "EventHLTV", "a", "1=0", "2=0")
	register_event("DeathMsg", "EventDeathMsg", "a")
	register_event("CurWeapon", "EventCurWeapon", "be", "1=1")
	register_logevent("logevent_round_end", 2, "1=Round_End")
	register_message(get_user_msgid("DeathMsg"), "MessageDeathMsg")
	
	register_forward(FM_SetModel, "fw_SetModel")
	RegisterHam(Ham_Think, "grenade", "fw_ThinkGrenade")
	
	cvar_bonushp = register_cvar("zp_killbomb_hp","10000") //HP 
	cvar_surfree = register_cvar("zp_killbomb_sur","1") //Give Survivor Kill Bomb
	cvar_enablekill = register_cvar("zp_killbomb_enabled","1") //Enable bomb
	cvar_allow_survivor = register_cvar("zp_killbomb_survivorbuy","1") //Can survivor buy
	
	g_maxplayers = get_maxplayers()
	g_itemid_killbomb = zp_items_register(ITEM_NAME, ITEM_COST)
}

//-----------------------

public client_putinserver(id) g_haskillbomb[id] = 0

//-----------------------

public client_disconnect(id) g_haskillbomb[id] = 0

//-----------------------

public EventHLTV()
{
	g_killbombbuycount = 0
	
	for(new id = 1; id <= g_maxplayers; id++)
	{
		if(is_user_connected(id)) g_haskillbomb[id] = 0
	}	
}

//-----------------------

public EventDeathMsg()
{
	new id = read_data(2)
	if(is_user_connected(id)) g_haskillbomb[id] = 0
}

//-----------------------

public EventCurWeapon(id)
{
	if(g_haskillbomb[id])
	{
		if(get_user_weapon(id) == CSW_SMOKEGRENADE)
		{
			set_pev(id, pev_viewmodel2, MODEL_V)
			set_pev(id, pev_weaponmodel2, MODEL_P)
		}
	}
}

//-----------------------

public MessageDeathMsg(msg_id, msg_dest, id)
{
	static attacker, victim
	attacker = get_msg_arg_int(1)
	victim = get_msg_arg_int(2)
	
	if(!is_user_connected(attacker) || attacker == victim) return PLUGIN_CONTINUE
	
	if(g_killedbykillbomb[victim]) set_msg_arg_string(4, "grenade")
	
	return PLUGIN_CONTINUE
}

//-----------------------

public logevent_round_end() g_roundend = 1

//-----------------------

public zp_round_started() g_roundend = 0

//-----------------------

public zp_extra_item_selected(id, item)
{
	if(item == g_itemid_killbomb)
	{
		if(g_roundend)
		{
			client_print(id, print_chat, "[ZP] Item not available at this time.")
			return PLUGIN_HANDLED
		}
		if(g_killbombbuycount >= BUY_LIMIT)
		{
			client_print(id, print_chat, "[ZP] Maximum usage has been reach (max: %i).", BUY_LIMIT)
			return PLUGIN_HANDLED
		}
		if(user_has_weapon(id, CSW_SMOKEGRENADE))
		{
			client_print(id, print_chat, "[ZP] Current grenade slot is full (SmokeGrenade).")
			return PLUGIN_HANDLED
		}
		if(g_haskillbomb[id])
		{
			client_print(id, print_chat, "[ZP] You already have a %s.", ITEM_NAME)
			return PLUGIN_HANDLED
		}
		
		g_killbombbuycount += 1
		g_haskillbomb[id] = 1
		give_item(id, "weapon_smokegrenade")
		client_print(id, print_chat, "[ZP] You have bought a %s.", ITEM_NAME)
		emit_sound(id, CHAN_VOICE, SOUND_BUY, 1.0, ATTN_NORM, 0, PITCH_NORM)
	}
	
	return PLUGIN_CONTINUE
}

//-----------------------

public zp_user_infected_post(id)
{
	if(zp_class_survivor_get(id) && get_pcvar_num(cvar_surfree))
	{
		g_haskillbomb[id] = 1
		give_item(id, "weapon_smokegrenade")
		client_print(id, print_center, "*** You got a %s, enjoy killing humans ***", ITEM_NAME)
	}
}

//-----------------------

public zp_user_humanized_post(id) g_haskillbomb[id] = 0

//-----------------------

public fw_SetModel(entity, const model[])
{
	if(!pev_valid(entity)) return FMRES_IGNORED
	
	static Float:dmgtime
	pev(entity, pev_dmgtime, dmgtime)
	
	if(dmgtime == 0.0) return FMRES_IGNORED
	
	static owner; owner = pev(entity, pev_owner)
	if(g_haskillbomb[owner] && equal(model[7], "w_sm", 4))
	{
		set_rendering(entity, kRenderFxGlowShell, COLOR_R, COLOR_G, COLOR_B, kRenderNormal, 0)
			
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
		write_byte(TE_BEAMFOLLOW)
		write_short(entity)
		write_short(g_killbomb_spr_trail)
		write_byte(10)
		write_byte(3)
		write_byte(COLOR_R)
		write_byte(COLOR_G)
		write_byte(COLOR_B)
		write_byte(192)
		message_end()
		
		set_pev(entity, PEV_NADE_TYPE, NADE_TYPE_KILLBOMB)
		engfunc(EngFunc_SetModel, entity, MODEL_W)
		g_haskillbomb[owner] = 0
		
		return FMRES_SUPERCEDE
	}
	
	return FMRES_IGNORED
}

//-----------------------

public fw_ThinkGrenade(entity)
{
	if(!pev_valid(entity)) return HAM_IGNORED
	
	static Float:dmgtime, Float:current_time
	pev(entity, pev_dmgtime, dmgtime)
	current_time = get_gametime()
	
	if(dmgtime > current_time) return HAM_IGNORED
	
	if(pev(entity, PEV_NADE_TYPE) == NADE_TYPE_KILLBOMB)
	{
		KillBombExplode(entity)
		return HAM_SUPERCEDE
	}
	
	return HAM_IGNORED
}

//-----------------------

KillBombExplode(ent)
{
	if (g_roundend) return
	
	static Float:originF[3]
	pev(ent, pev_origin, originF)
	
	message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
	write_byte(TE_EXPLOSION)
	write_coord(floatround(originF[0]))
	write_coord(floatround(originF[1]))
	write_coord(floatround(originF[2]))
	write_short(g_killbomb_spr_exp)
	write_byte(40)
	write_byte(30)
	write_byte(14)
	message_end()
	
	emit_sound(ent, CHAN_WEAPON, SOUND_EXPLODE, 1.0, ATTN_NORM, 0, PITCH_NORM)
	
	static attacker
	attacker = pev(ent, pev_owner)
	if (!is_user_connected(attacker))
	{
		engfunc(EngFunc_RemoveEntity, ent)
		return
	}
	
	static victim
	victim = -1
	
	while((victim = engfunc(EngFunc_FindEntityInSphere, victim, originF, NADE_EXPLOSION_RADIUS)) != 0)
	{
		if(!is_user_alive(victim) || !zp_core_is_zombie(victim) || zp_class_survivor_get(victim))
			continue
		
		g_killedbykillbomb[victim] = 1
		ExecuteHamB(Ham_Killed, victim, attacker, 0)
		g_killedbykillbomb[victim] = 0
		
		static health; health = get_user_health(attacker)
		set_user_health(attacker, health+get_pcvar_num(cvar_bonushp))
	}
	
	engfunc(EngFunc_RemoveEntity, ent)
}

//-----------------------

public zp_fw_items_select_pre(id, itemid)
{
	if (itemid == g_itemid_killbomb)
	{
		if (get_pcvar_num(cvar_enablekill) == 0) 
			return ZP_ITEM_DONT_SHOW;
			
		if (zp_class_nemesis_get(id) || zp_core_is_zombie(id)) 
			return ZP_ITEM_DONT_SHOW; 
			
		if (get_pcvar_num(cvar_allow_survivor) == 0 && zp_class_survivor_get(id)) 
			return ZP_ITEM_DONT_SHOW; 
			
		return ZP_ITEM_AVAILABLE; 
	}
	return ZP_ITEM_AVAILABLE;
}

//-----------------------
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
