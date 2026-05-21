/*================================================================================

    -------------------------------
    -*- ZP50 Custom Hub + Shop -*-
    -------------------------------

    - /menu, /zpmenu and M/chooseteam open this hub
    - Option 1: Buy Weapons
    - Option 2: Custom Extra Items
    - Zombie class saving is automatic; no manual menu option
    - Hidden VIP/Admin options
    - Unstuck
    - No "say /zclass" chat spam

    Put this near the END of plugins.ini, after ZP50 plugins and custom items.

================================================================================*/

#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <nvault>

#include <zp50_core>
#include <zp50_items>
#include <zp50_class_zombie>

#define PLUGIN  "ZP50 Custom Hub"
#define VERSION "1.1"
#define AUTHOR  "ChatGPT"

#define VIP_FLAG ADMIN_LEVEL_H
#define ADMIN_MENU_FLAG ADMIN_BAN

#define LIBRARY_BUY_MENUS "zp50_buy_menus"
#define LIBRARY_ZCLASS    "zp50_class_zombie"

native zp_buy_menus_show(id)
native zp_lasermine_get_cost(id)

new g_vault
new Float:g_next_unstuck[33]
new g_saved_class[33]

new const Float:g_unstuck_offsets[][3] =
{
    { 0.0, 0.0, 0.0 },
    { 32.0, 0.0, 0.0 },
    { -32.0, 0.0, 0.0 },
    { 0.0, 32.0, 0.0 },
    { 0.0, -32.0, 0.0 },
    { 32.0, 32.0, 0.0 },
    { -32.0, 32.0, 0.0 },
    { 32.0, -32.0, 0.0 },
    { -32.0, -32.0, 0.0 },
    { 0.0, 0.0, 32.0 },
    { 0.0, 0.0, 64.0 }
}

public plugin_init()
{
    register_plugin(PLUGIN, VERSION, AUTHOR)

    register_clcmd("say /menu", "cmd_main_menu")
    register_clcmd("say_team /menu", "cmd_main_menu")
    register_clcmd("say /zpmenu", "cmd_main_menu")
    register_clcmd("say_team /zpmenu", "cmd_main_menu")

    register_clcmd("chooseteam", "cmd_main_menu")
    register_clcmd("jointeam", "cmd_main_menu")

    register_clcmd("say /unstuck", "cmd_unstuck")
    register_clcmd("say_team /unstuck", "cmd_unstuck")

    g_vault = nvault_open("zp50_saved_zclasses")
    if (g_vault == INVALID_HANDLE)
        set_fail_state("Could not open nVault: zp50_saved_zclasses")
}

public plugin_natives()
{
    set_native_filter("native_filter")
}

public native_filter(const name[], index, trap)
{
    if (!trap)
        return PLUGIN_HANDLED

    return PLUGIN_CONTINUE
}

public plugin_end()
{
    if (g_vault != INVALID_HANDLE)
        nvault_close(g_vault)
}

public client_putinserver(id)
{
    g_saved_class[id] = -1
    g_next_unstuck[id] = 0.0
    set_task(3.0, "task_load_class", id)
}

public client_disconnected(id)
{
    save_current_zombie_class(id)
    remove_task(id)
}

public cmd_main_menu(id)
{
    if (!is_user_connected(id))
        return PLUGIN_HANDLED

    show_main_menu(id)
    return PLUGIN_HANDLED
}

show_main_menu(id)
{
    new menu = menu_create("\yZombie Plague Menu", "main_menu_handler")

    menu_additem(menu, "\wBuy Weapons", "1")
    menu_additem(menu, "\wExtra Items", "2")
    menu_additem(menu, "\wZombie Classes", "3")
    menu_additem(menu, "\wUnstuck", "4")

    if (get_user_flags(id) & VIP_FLAG)
        menu_additem(menu, "\yVIP Options", "5")

    if (get_user_flags(id) & ADMIN_MENU_FLAG)
        menu_additem(menu, "\rAdmin Menu", "6")

    menu_setprop(menu, MPROP_EXITNAME, "Exit")
    menu_display(id, menu)
}

public main_menu_handler(id, menu, item)
{
    if (item == MENU_EXIT)
    {
        menu_destroy(menu)
        return PLUGIN_HANDLED
    }

    new data[6], name[64], access, callback
    menu_item_getinfo(menu, item, access, data, charsmax(data), name, charsmax(name), callback)

    switch (str_to_num(data))
    {
        case 1: open_buy_weapons_menu(id)
        case 2: show_custom_items_menu(id)
        case 3: open_zombie_classes_menu(id)
        case 4: do_unstuck(id)
        case 5: show_vip_menu(id)
        case 6: client_cmd(id, "amxmodmenu")
    }

    menu_destroy(menu)
    return PLUGIN_HANDLED
}

open_buy_weapons_menu(id)
{
    if (LibraryExists(LIBRARY_BUY_MENUS, LibType_Library))
    {
        zp_buy_menus_show(id)
        return
    }

    client_cmd(id, "guns")
    client_cmd(id, "buyguns")
    client_cmd(id, "zpguns")
}

open_zombie_classes_menu(id)
{
    if (LibraryExists(LIBRARY_ZCLASS, LibType_Library))
    {
        zp_class_zombie_show_menu(id)
        return
    }

    client_cmd(id, "zclass")
    client_cmd(id, "zombieclass")
}

show_custom_items_menu(id)
{
    if (!is_user_alive(id))
        return

    new menu = menu_create("\yExtra Items", "custom_items_handler")

    new lm_itemid = zp_items_get_id("Lasermine")
    if (lm_itemid != -1)
    {
        new cost = get_lasermine_cost_safe(id)
        new text[64]
        formatex(text, charsmax(text), "\wLasermine \y%d AP", cost)
        menu_additem(menu, text, "1")
    }

    // Future examples:
    // menu_additem(menu, "\wAntidote Bomb \y30 AP", "2")
    // menu_additem(menu, "\wFrost Grenade \y20 AP", "3")
    // menu_additem(menu, "\wNapalm Grenade \y20 AP", "4")

    menu_setprop(menu, MPROP_EXITNAME, "Back")
    menu_display(id, menu)
}

public custom_items_handler(id, menu, item)
{
    if (item == MENU_EXIT)
    {
        menu_destroy(menu)
        show_main_menu(id)
        return PLUGIN_HANDLED
    }

    new data[6], name[64], access, callback
    menu_item_getinfo(menu, item, access, data, charsmax(data), name, charsmax(name), callback)

    switch (str_to_num(data))
    {
        case 1:
        {
            new lm_itemid = zp_items_get_id("Lasermine")
            if (lm_itemid != -1)
                zp_items_force_buy(id, lm_itemid, 1)
        }
    }

    menu_destroy(menu)
    return PLUGIN_HANDLED
}

get_lasermine_cost_safe(id)
{
    if (LibraryExists("zp_lasermine_perfect", LibType_Library))
        return zp_lasermine_get_cost(id)

    return 15
}

show_vip_menu(id)
{
    new menu = menu_create("\yVIP Options", "vip_menu_handler")

    menu_additem(menu, "\wBuy Weapons", "1")
    menu_additem(menu, "\wExtra Items", "2")
    menu_additem(menu, "\wUnstuck", "3")
    menu_additem(menu, "\dVIP feature coming soon", "4")

    menu_setprop(menu, MPROP_EXITNAME, "Back")
    menu_display(id, menu)
}

public vip_menu_handler(id, menu, item)
{
    if (item == MENU_EXIT)
    {
        menu_destroy(menu)
        show_main_menu(id)
        return PLUGIN_HANDLED
    }

    new data[6], name[64], access, callback
    menu_item_getinfo(menu, item, access, data, charsmax(data), name, charsmax(name), callback)

    switch (str_to_num(data))
    {
        case 1: open_buy_weapons_menu(id)
        case 2: show_custom_items_menu(id)
        case 3: do_unstuck(id)
        case 4: client_print_color(id, print_team_default, "^4[ZP]^1 VIP features can be added here later.")
    }

    menu_destroy(menu)
    return PLUGIN_HANDLED
}

public cmd_unstuck(id)
{
    do_unstuck(id)
    return PLUGIN_HANDLED
}

do_unstuck(id)
{
    if (!is_user_alive(id))
        return

    new Float:now = get_gametime()
    if (now < g_next_unstuck[id])
    {
        client_print_color(id, print_team_default, "^4[ZP]^1 Wait %.1f seconds to use unstuck again.", g_next_unstuck[id] - now)
        return
    }

    new Float:origin[3], Float:new_origin[3]
    pev(id, pev_origin, origin)

    for (new i = 0; i < sizeof g_unstuck_offsets; i++)
    {
        new_origin[0] = origin[0] + g_unstuck_offsets[i][0]
        new_origin[1] = origin[1] + g_unstuck_offsets[i][1]
        new_origin[2] = origin[2] + g_unstuck_offsets[i][2]

        if (is_hull_vacant(id, new_origin))
        {
            engfunc(EngFunc_SetOrigin, id, new_origin)
            set_pev(id, pev_velocity, Float:{0.0, 0.0, 0.0})

            g_next_unstuck[id] = now + 8.0
            client_print_color(id, print_team_default, "^4[ZP]^1 Unstuck done.")
            return
        }
    }

    client_print_color(id, print_team_default, "^4[ZP]^1 No safe unstuck spot found.")
}

bool:is_hull_vacant(id, const Float:origin[3])
{
    new hull = (pev(id, pev_flags) & FL_DUCKING) ? HULL_HEAD : HULL_HUMAN
    engfunc(EngFunc_TraceHull, origin, origin, DONT_IGNORE_MONSTERS, hull, id, 0)

    if (get_tr2(0, TR_StartSolid) || get_tr2(0, TR_AllSolid))
        return false

    return true
}

public zp_fw_class_zombie_select_post(id, classid)
{
    if (!is_user_connected(id))
        return

    g_saved_class[id] = classid
    save_zombie_class_id(id, classid)
}

public task_load_class(id)
{
    if (!is_user_connected(id))
        return

    new classid = load_zombie_class_id(id)

    if (classid < 0)
        return

    g_saved_class[id] = classid
    zp_class_zombie_set_next(id, classid)

    client_print_color(id, print_team_default, "^4[ZP]^1 Loaded saved zombie class.")
}

save_current_zombie_class(id)
{
    if (!is_user_connected(id))
        return

    new classid = zp_class_zombie_get_next(id)

    if (classid < 0)
        classid = zp_class_zombie_get_current(id)

    if (classid < 0)
        return

    g_saved_class[id] = classid
    save_zombie_class_id(id, classid)
}

save_zombie_class_id(id, classid)
{
    new key[96], value[16]
    get_save_key(id, key, charsmax(key))

    num_to_str(classid, value, charsmax(value))
    nvault_set(g_vault, key, value)
}

load_zombie_class_id(id)
{
    new key[96], value[16]
    get_save_key(id, key, charsmax(key))

    if (!nvault_get(g_vault, key, value, charsmax(value)))
        return -1

    return str_to_num(value)
}

get_save_key(id, key[], len)
{
    new authid[64]
    get_user_authid(id, authid, charsmax(authid))

    if (equal(authid, "STEAM_ID_LAN") || equal(authid, "VALVE_ID_LAN") || equal(authid, "STEAM_ID_PENDING") || equal(authid, "VALVE_ID_PENDING") || containi(authid, "LAN") != -1)
    {
        new name[32]
        get_user_name(id, name, charsmax(name))

        replace_all(name, charsmax(name), " ", "_")
        replace_all(name, charsmax(name), ";", "_")
        replace_all(name, charsmax(name), "^"", "_")

        formatex(key, len, "name:%s", name)
    }
    else
    {
        formatex(key, len, "auth:%s", authid)
    }
}
