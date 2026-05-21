#include <amxmodx>
#include <fun>
#include <fakemeta>
#include <hamsandwich>
#include <amx_settings_api>
#include <cs_weap_models_api>
#include <zp50_core>
#include <zp50_items>
#include <zp50_gamemodes>
#include <zp50_class_nemesis>

new const gNazwaPluginu[] = "[ZP] Addon: Antidote Bomb";
new const gWersjaPluginu[] = "1.2";
new const gAutorPluginu[] = "MisieQ / fixed for ZP50";

#define ITEM_NAME "Antidote Bomb"
#define ITEM_COST 0 // Shop manager controls real cost

#define MODEL_MAX_LENGTH 64
#define SOUND_MAX_LENGTH 64
#define SPRITE_MAX_LENGTH 64

new const ZP_SETTINGS_FILE[] = "zombieplague.ini";
new const sound_grenade_antidote_explode[][] = { "zombie_plague/grenade_antidote.wav" };
new const sound_grenade_antidote_player[][] = { "zombie_plague/player_antidote.wav" };

new g_model_grenade_antidote[MODEL_MAX_LENGTH] = "models/zombie_plague/v_grenade_antidote.mdl";
new g_sprite_grenade_trail[SPRITE_MAX_LENGTH] = "sprites/laserbeam.spr";
new g_sprite_grenade_ring[SPRITE_MAX_LENGTH] = "sprites/shockwave.spr";

new Array:g_sound_antidote_explode;
new Array:g_sound_antidote_player;

const Float:NADE_EXPLOSION_RADIUS = 240.0;
const PEV_NADE_TYPE = pev_iuser1;
const NADE_TYPE_ANTIDOTE = 6969;

new g_ItemID, g_trailSpr, g_exploSpr;
new Antidote[33];
new g_AntidoteBombCounter, cvar_antidote_bomb_round_limit;

public plugin_init()
{
	register_plugin(gNazwaPluginu, gWersjaPluginu, gAutorPluginu);
	
	register_event("HLTV", "event_round_start", "a", "1=0", "2=0");
	
	register_forward(FM_SetModel, "fw_SetModel");
	RegisterHam(Ham_Think, "grenade", "fw_ThinkGrenade");
	RegisterHam(Ham_Killed, "player", "fw_PlayerKilled");
	RegisterHam(Ham_Item_Deploy, "weapon_hegrenade", "fw_ItemDeploy", 1);
	
	g_ItemID = zp_items_register(ITEM_NAME, ITEM_COST);
	cvar_antidote_bomb_round_limit = register_cvar("zp_antidote_bomb_round_limit", "3");
}

public plugin_precache()
{
	g_sound_antidote_explode = ArrayCreate(SOUND_MAX_LENGTH, 1);
	g_sound_antidote_player = ArrayCreate(SOUND_MAX_LENGTH, 1);
	
	amx_load_setting_string_arr(ZP_SETTINGS_FILE, "Sounds", "GRENADE ANTIDOTE EXPLODE", g_sound_antidote_explode);
	amx_load_setting_string_arr(ZP_SETTINGS_FILE, "Sounds", "GRENADE ANTIDOTE PLAYER", g_sound_antidote_player);
	
	new index;
	if (ArraySize(g_sound_antidote_explode) == 0)
	{
		for (index = 0; index < sizeof sound_grenade_antidote_explode; index++)
			ArrayPushString(g_sound_antidote_explode, sound_grenade_antidote_explode[index]);
		
		amx_save_setting_string_arr(ZP_SETTINGS_FILE, "Sounds", "GRENADE ANTIDOTE EXPLODE", g_sound_antidote_explode);
	}
	
	if (ArraySize(g_sound_antidote_player) == 0)
	{
		for (index = 0; index < sizeof sound_grenade_antidote_player; index++)
			ArrayPushString(g_sound_antidote_player, sound_grenade_antidote_player[index]);
		
		amx_save_setting_string_arr(ZP_SETTINGS_FILE, "Sounds", "GRENADE ANTIDOTE PLAYER", g_sound_antidote_player);
	}

	if (!amx_load_setting_string(ZP_SETTINGS_FILE, "Weapon Models", "GRENADE ANTIDOTE", g_model_grenade_antidote, charsmax(g_model_grenade_antidote)))
		amx_save_setting_string(ZP_SETTINGS_FILE, "Weapon Models", "GRENADE ANTIDOTE", g_model_grenade_antidote);
	
	if (!amx_load_setting_string(ZP_SETTINGS_FILE, "Grenade Sprites", "TRAIL", g_sprite_grenade_trail, charsmax(g_sprite_grenade_trail)))
		amx_save_setting_string(ZP_SETTINGS_FILE, "Grenade Sprites", "TRAIL", g_sprite_grenade_trail);
	
	if (!amx_load_setting_string(ZP_SETTINGS_FILE, "Grenade Sprites", "RING", g_sprite_grenade_ring, charsmax(g_sprite_grenade_ring)))
		amx_save_setting_string(ZP_SETTINGS_FILE, "Grenade Sprites", "RING", g_sprite_grenade_ring);
	
	new sound[SOUND_MAX_LENGTH];
	for (index = 0; index < ArraySize(g_sound_antidote_explode); index++)
	{
		ArrayGetString(g_sound_antidote_explode, index, sound, charsmax(sound));
		precache_sound(sound);
	}
	
	for (index = 0; index < ArraySize(g_sound_antidote_player); index++)
	{
		ArrayGetString(g_sound_antidote_player, index, sound, charsmax(sound));
		precache_sound(sound);
	}
	
	precache_model(g_model_grenade_antidote);
	g_trailSpr = precache_model(g_sprite_grenade_trail);
	g_exploSpr = precache_model(g_sprite_grenade_ring);
}

public client_disconnected(id)
{
	Antidote[id] = 0;
}

public event_round_start()
{
	g_AntidoteBombCounter = 0;
	arrayset(Antidote, 0, sizeof Antidote);
}

public zp_fw_items_select_pre(id, itemid, ignorecost)
{
	if (itemid != g_ItemID)
		return ZP_ITEM_AVAILABLE;

	// Hide from the default ZP items menu.
	// The custom shop manager will call zp_items_force_buy(..., ignorecost = 1).
	if (!ignorecost)
		return ZP_ITEM_DONT_SHOW;

	if (zp_core_is_zombie(id))
		return ZP_ITEM_DONT_SHOW;

	return ZP_ITEM_AVAILABLE;
}

public zp_fw_items_select_post(id, itemid, ignorecost)
{
	if (itemid != g_ItemID)
		return;

	// Cost and round/global limits are controlled by zp50_custom_hub_cfg_shop.
	give_item(id, "weapon_hegrenade");
	Antidote[id] = 1;
	g_AntidoteBombCounter++;
}

public fw_ItemDeploy(wpn)
{
	new owner = pev(wpn, pev_owner);
	
	if (is_user_connected(owner) && Antidote[owner])
		set_pev(owner, pev_viewmodel2, g_model_grenade_antidote);
}

public fw_SetModel(entity, const model[])
{
	if (!pev_valid(entity))
		return FMRES_IGNORED;
	
	if (!equal(model, "models/w_hegrenade.mdl"))
		return FMRES_IGNORED;
	
	static Float:dmgtime;
	pev(entity, pev_dmgtime, dmgtime);
	
	if (dmgtime == 0.0)
		return FMRES_IGNORED;
	
	new owner = pev(entity, pev_owner);
	
	if (!is_user_connected(owner))
		return FMRES_IGNORED;
	
	if (zp_core_is_zombie(owner))
		return FMRES_IGNORED;

	if (Antidote[owner])
	{
		fm_set_rendering(entity, kRenderFxGlowShell, 0, 200, 0, kRenderNormal, 16);
	
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
		write_byte(TE_BEAMFOLLOW);
		write_short(entity);
		write_short(g_trailSpr);
		write_byte(10);
		write_byte(10);
		write_byte(255);
		write_byte(128);
		write_byte(0);
		write_byte(200);
		message_end();
	
		set_pev(entity, PEV_NADE_TYPE, NADE_TYPE_ANTIDOTE);
		Antidote[owner] = 0;
	}
	
	return FMRES_IGNORED;
}

public fw_ThinkGrenade(entity)
{
	if (!pev_valid(entity))
		return HAM_IGNORED;
	
	if (pev(entity, PEV_NADE_TYPE) != NADE_TYPE_ANTIDOTE)
		return HAM_IGNORED;
	
	static Float:dmgtime;
	pev(entity, pev_dmgtime, dmgtime);
	
	if (dmgtime > get_gametime())
		return HAM_IGNORED;
	
	cure_explode(entity);
	return HAM_SUPERCEDE;
}

public fw_PlayerKilled(victim, attacker, shouldgib)
{
	Antidote[victim] = 0;
}

cure_explode(ent)
{
	if (!pev_valid(ent))
		return;
	
	if (zp_gamemodes_get_current() == ZP_NO_GAME_MODE)
	{
		engfunc(EngFunc_RemoveEntity, ent);
		return;
	}
	
	static Float:origin[3];
	pev(ent, pev_origin, origin);
	
	create_blast(origin);
	
	static sound[SOUND_MAX_LENGTH];
	if (ArraySize(g_sound_antidote_explode) > 0)
	{
		ArrayGetString(g_sound_antidote_explode, random_num(0, ArraySize(g_sound_antidote_explode) - 1), sound, charsmax(sound));
		emit_sound(ent, CHAN_WEAPON, sound, 1.0, ATTN_NORM, 0, PITCH_NORM);
	}
	
	new attacker = pev(ent, pev_owner);
	
	// The owner may have been infected after throwing the bomb.
	// Still allow the grenade to cure zombies if the owner is connected.
	if (!is_user_connected(attacker))
	{
		engfunc(EngFunc_RemoveEntity, ent);
		return;
	}
	
	new victim = -1;
	
	while ((victim = engfunc(EngFunc_FindEntityInSphere, victim, origin, NADE_EXPLOSION_RADIUS)) != 0)
	{
		if (!is_user_alive(victim))
			continue;
		
		if (!zp_core_is_zombie(victim))
			continue;
		
		if (zp_core_is_first_zombie(victim) || zp_core_is_last_zombie(victim) || zp_class_nemesis_get(victim))
			continue;
		
		zp_core_cure(victim, attacker);
		
		if (ArraySize(g_sound_antidote_player) > 0)
		{
			ArrayGetString(g_sound_antidote_player, random_num(0, ArraySize(g_sound_antidote_player) - 1), sound, charsmax(sound));
			emit_sound(victim, CHAN_VOICE, sound, 1.0, ATTN_NORM, 0, PITCH_NORM);
		}
	}

	engfunc(EngFunc_RemoveEntity, ent);
}

create_blast(const Float:origin[3])
{
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, origin, 0);
	write_byte(TE_BEAMCYLINDER);
	engfunc(EngFunc_WriteCoord, origin[0]);
	engfunc(EngFunc_WriteCoord, origin[1]);
	engfunc(EngFunc_WriteCoord, origin[2]);
	engfunc(EngFunc_WriteCoord, origin[0]);
	engfunc(EngFunc_WriteCoord, origin[1]);
	engfunc(EngFunc_WriteCoord, origin[2] + 385.0);
	write_short(g_exploSpr);
	write_byte(0);
	write_byte(0);
	write_byte(4);
	write_byte(60);
	write_byte(0);
	write_byte(255);
	write_byte(128);
	write_byte(0);
	write_byte(200);
	write_byte(0);
	message_end();
	
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, origin, 0);
	write_byte(TE_BEAMCYLINDER);
	engfunc(EngFunc_WriteCoord, origin[0]);
	engfunc(EngFunc_WriteCoord, origin[1]);
	engfunc(EngFunc_WriteCoord, origin[2]);
	engfunc(EngFunc_WriteCoord, origin[0]);
	engfunc(EngFunc_WriteCoord, origin[1]);
	engfunc(EngFunc_WriteCoord, origin[2] + 470.0);
	write_short(g_exploSpr);
	write_byte(0);
	write_byte(0);
	write_byte(4);
	write_byte(60);
	write_byte(0);
	write_byte(255);
	write_byte(164);
	write_byte(0);
	write_byte(200);
	write_byte(0);
	message_end();
	
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, origin, 0);
	write_byte(TE_BEAMCYLINDER);
	engfunc(EngFunc_WriteCoord, origin[0]);
	engfunc(EngFunc_WriteCoord, origin[1]);
	engfunc(EngFunc_WriteCoord, origin[2]);
	engfunc(EngFunc_WriteCoord, origin[0]);
	engfunc(EngFunc_WriteCoord, origin[1]);
	engfunc(EngFunc_WriteCoord, origin[2] + 555.0);
	write_short(g_exploSpr);
	write_byte(0);
	write_byte(0);
	write_byte(4);
	write_byte(60);
	write_byte(0);
	write_byte(255);
	write_byte(200);
	write_byte(0);
	write_byte(200);
	write_byte(0);
	message_end();
}

stock fm_set_rendering(entity, fx = kRenderFxNone, r = 255, g = 255, b = 255, render = kRenderNormal, amount = 16)
{
	static Float:color[3];
	color[0] = float(r);
	color[1] = float(g);
	color[2] = float(b);
	
	set_pev(entity, pev_renderfx, fx);
	set_pev(entity, pev_rendercolor, color);
	set_pev(entity, pev_rendermode, render);
	set_pev(entity, pev_renderamt, float(amount));
}
