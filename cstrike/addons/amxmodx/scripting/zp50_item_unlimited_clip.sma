/*================================================================================

    -------------------------------------------
    -*- [ZP50] Extra Item: Unlimited Clip 1.0 -*-
    -------------------------------------------

    ZP50 custom-shop compatible version.
    - Registers in zp50_items with cost 0.
    - Hidden from default /items unless bought by custom shop with ignorecost = 1.
    - Cost and limits are handled by zp_custom_shop.ini.

================================================================================*/

#include <amxmodx>
#include <fakemeta>
#include <zp50_core>
#include <zp50_items>

new const g_item_name[] = "Unlimited Clip"
const g_item_cost = 0

#if cellbits == 32
const OFFSET_CLIPAMMO = 51
#else
const OFFSET_CLIPAMMO = 65
#endif
const OFFSET_LINUX_WEAPONS = 4

new const MAXCLIP[] = { -1, 13, -1, 10, 1, 7, -1, 30, 30, 1, 30, 20, 25, 30, 35, 25, 12, 20,
            10, 30, 100, 8, 30, 30, 20, 2, 7, 30, 30, -1, 50 }

new g_itemid_infammo
new g_has_unlimited_clip[33]

public plugin_init()
{
    register_plugin("[ZP50] Extra: Unlimited Clip", "1.0", "MeRcyLeZZ / ZP50 Custom Shop")

    g_itemid_infammo = zp_items_register(g_item_name, g_item_cost)

    register_event("HLTV", "event_round_start", "a", "1=0", "2=0")
    register_message(get_user_msgid("CurWeapon"), "message_cur_weapon")
}

public client_disconnected(id)
{
    g_has_unlimited_clip[id] = false
}

public event_round_start()
{
    for (new id = 1; id <= 32; id++)
        g_has_unlimited_clip[id] = false
}

public zp_fw_items_select_pre(id, itemid, ignorecost)
{
    if (itemid != g_itemid_infammo)
        return ZP_ITEM_AVAILABLE;

    // Hide from default ZP /items menu. Custom shop uses ignorecost = 1.
    if (!ignorecost)
        return ZP_ITEM_DONT_SHOW;

    if (zp_core_is_zombie(id))
        return ZP_ITEM_NOT_AVAILABLE;

    if (g_has_unlimited_clip[id])
        return ZP_ITEM_NOT_AVAILABLE;

    return ZP_ITEM_AVAILABLE;
}

public zp_fw_items_select_post(id, itemid, ignorecost)
{
    if (itemid != g_itemid_infammo)
        return;

    g_has_unlimited_clip[id] = true
}

public message_cur_weapon(msg_id, msg_dest, msg_entity)
{
    if (!g_has_unlimited_clip[msg_entity])
        return;

    if (!is_user_alive(msg_entity) || get_msg_arg_int(1) != 1)
        return;

    static weapon, clip
    weapon = get_msg_arg_int(2)
    clip = get_msg_arg_int(3)

    if (weapon < 0 || weapon >= sizeof MAXCLIP)
        return;

    if (MAXCLIP[weapon] > 2)
    {
        set_msg_arg_int(3, get_msg_argtype(3), MAXCLIP[weapon])

        if (clip < 2)
        {
            static wname[32], weapon_ent
            get_weaponname(weapon, wname, charsmax(wname))
            weapon_ent = fm_find_ent_by_owner(-1, wname, msg_entity)

            if (pev_valid(weapon_ent))
                fm_set_weapon_ammo(weapon_ent, MAXCLIP[weapon])
        }
    }
}

stock fm_find_ent_by_owner(entity, const classname[], owner)
{
    while ((entity = engfunc(EngFunc_FindEntityByString, entity, "classname", classname)) && pev(entity, pev_owner) != owner) {}
    return entity;
}

stock fm_set_weapon_ammo(entity, amount)
{
    set_pdata_int(entity, OFFSET_CLIPAMMO, amount, OFFSET_LINUX_WEAPONS);
}
