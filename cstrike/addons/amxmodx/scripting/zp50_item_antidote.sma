/*================================================================================

    ---------------------------
    -*- [ZP] Item: Antidote -*-
    ---------------------------

    ZP50 custom-shop compatible version.
    - Registers in zp50_items with cost 0.
    - Hidden from default /items unless bought by custom shop with ignorecost = 1.
    - Cost and limits are handled by zp_custom_shop.ini.

================================================================================*/

#define ITEM_NAME "Antidote"
#define ITEM_COST 0

#include <amxmodx>
#include <zp50_core>
#include <zp50_items>
#include <zp50_gamemodes>

new g_ItemID
new g_GameModeInfectionID
new g_GameModeMultiID
new cvar_deathmatch, cvar_respawn_after_last_human

public plugin_init()
{
    register_plugin("[ZP] Item: Antidote", ZP_VERSION_STRING, "ZP Dev Team / Custom Shop")

    g_ItemID = zp_items_register(ITEM_NAME, ITEM_COST)
}

public plugin_cfg()
{
    g_GameModeInfectionID = zp_gamemodes_get_id("Infection Mode")
    g_GameModeMultiID = zp_gamemodes_get_id("Multiple Infection Mode")
    cvar_deathmatch = get_cvar_pointer("zp_deathmatch")
    cvar_respawn_after_last_human = get_cvar_pointer("zp_respawn_after_last_human")
}

public zp_fw_items_select_pre(id, itemid, ignorecost)
{
    if (itemid != g_ItemID)
        return ZP_ITEM_AVAILABLE;

    // Hide from default ZP /items menu. Custom shop uses ignorecost = 1.
    if (!ignorecost)
        return ZP_ITEM_DONT_SHOW;

    new current_mode = zp_gamemodes_get_current()
    if (current_mode != g_GameModeInfectionID && current_mode != g_GameModeMultiID)
        return ZP_ITEM_NOT_AVAILABLE;

    if (!zp_core_is_zombie(id))
        return ZP_ITEM_NOT_AVAILABLE;

    if (zp_core_get_zombie_count() <= 1)
        return ZP_ITEM_NOT_AVAILABLE;

    if (cvar_deathmatch && get_pcvar_num(cvar_deathmatch) && cvar_respawn_after_last_human
    && !get_pcvar_num(cvar_respawn_after_last_human) && zp_core_get_human_count() == 1)
        return ZP_ITEM_NOT_AVAILABLE;

    return ZP_ITEM_AVAILABLE;
}

public zp_fw_items_select_post(id, itemid, ignorecost)
{
    if (itemid != g_ItemID)
        return;

    zp_core_cure(id, id)
}
