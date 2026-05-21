/*================================================================================

    -------------------------------
    -*- ZP50 Custom Hub + CFG Shop -*-
    -------------------------------

    Files:
    - addons/amxmodx/configs/zp_custom_shop.ini
    - addons/amxmodx/data/lang/zp_custom_hub.txt

    This plugin controls:
    - /menu, /zpmenu, M key
    - Buy Weapons
    - Custom Extra Items shop
    - AP costs from cfg
    - per-player round limit
    - global round limit
    - better unstuck
    - automatic zombie class saving

================================================================================*/

#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <nvault>
#include <amx_settings_api>

#include <zp50_core>
#include <zp50_items>
#include <zp50_class_zombie>
#include <zp50_ammopacks>

#define PLUGIN  "ZP50 Custom Hub"
#define VERSION "1.3-debug"
#define AUTHOR  "ChatGPT"

#define VIP_FLAG ADMIN_LEVEL_H
#define ADMIN_MENU_FLAG ADMIN_BAN

#define LIBRARY_BUY_MENUS "zp50_buy_menus"
#define LIBRARY_ZCLASS    "zp50_class_zombie"

#define SHOP_CFG_FILE "zp_custom_shop.ini"
#define SHOP_MAX_COSTS 8
#define SHOP_ITEMS 4

#define TEAM_ANY 0
#define TEAM_HUMAN 1
#define TEAM_ZOMBIE 2

native zp_buy_menus_show(id)

enum
{
    SHOP_ANTIDOTE = 0,
    SHOP_UNLIMITED_CLIP,
    SHOP_LASERMINE,
    SHOP_ANTIDOTE_BOMB
}

new const g_shop_section[SHOP_ITEMS][] =
{
    "Antidote",
    "Unlimited Clip",
    "Lasermine",
    "Antidote Bomb"
}

new const g_shop_default_itemid[SHOP_ITEMS][] =
{
    "Antidote",
    "Unlimited Clip",
    "Lasermine",
    "Antidote Bomb"
}

new const g_shop_default_name[SHOP_ITEMS][] =
{
    "Antidote",
    "Unlimited Clip",
    "Lasermine",
    "Antidote Bomb"
}

new const g_shop_default_costs[SHOP_ITEMS][] =
{
    "15,25",
    "10,15,25",
    "15,20,25",
    "35,50,65"
}

new const g_shop_default_player_limit[SHOP_ITEMS] =
{
    2, 0, 3, 3
}

new const g_shop_default_global_limit[SHOP_ITEMS] =
{
    0, 0, 8, 5
}

new const g_shop_default_team[SHOP_ITEMS] =
{
    TEAM_HUMAN,
    TEAM_HUMAN,
    TEAM_HUMAN,
    TEAM_HUMAN
}

new g_shop_enabled[SHOP_ITEMS]
new g_shop_itemid_str[SHOP_ITEMS][32]
new g_shop_name[SHOP_ITEMS][32]
new g_shop_costs[SHOP_ITEMS][SHOP_MAX_COSTS]
new g_shop_cost_count[SHOP_ITEMS]
new g_shop_limit_player[SHOP_ITEMS]
new g_shop_limit_global[SHOP_ITEMS]
new g_shop_team[SHOP_ITEMS]
new g_shop_vip_only[SHOP_ITEMS]
new g_shop_admin_only[SHOP_ITEMS]
new g_shop_zp_itemid[SHOP_ITEMS]

new g_shop_bought_player[SHOP_ITEMS][33]
new g_shop_bought_global[SHOP_ITEMS]

new g_vault
new Float:g_next_unstuck[33]
new g_saved_class[33]

new const Float:g_unstuck_dirs[][3] =
{
    { 1.0, 0.0, 0.0 },
    { -1.0, 0.0, 0.0 },
    { 0.0, 1.0, 0.0 },
    { 0.0, -1.0, 0.0 },
    { 1.0, 1.0, 0.0 },
    { -1.0, 1.0, 0.0 },
    { 1.0, -1.0, 0.0 },
    { -1.0, -1.0, 0.0 }
}

new const Float:g_unstuck_z[] =
{
    0.0, 18.0, 36.0, 54.0, 72.0, -18.0
}

public plugin_init()
{
    register_plugin(PLUGIN, VERSION, AUTHOR)
    register_dictionary("zp_custom_hub.txt")

    register_clcmd("say /menu", "cmd_main_menu")
    register_clcmd("say_team /menu", "cmd_main_menu")
    register_clcmd("say /zpmenu", "cmd_main_menu")
    register_clcmd("say_team /zpmenu", "cmd_main_menu")

    register_clcmd("chooseteam", "cmd_main_menu")
    register_clcmd("jointeam", "cmd_main_menu")

    register_clcmd("say /unstuck", "cmd_unstuck")
    register_clcmd("say_team /unstuck", "cmd_unstuck")

    register_event("HLTV", "event_round_start", "a", "1=0", "2=0")

    g_vault = nvault_open("zp50_saved_zclasses")
    if (g_vault == INVALID_HANDLE)
        set_fail_state("Could not open nVault: zp50_saved_zclasses")
}

public plugin_cfg()
{
    load_shop_config()
    resolve_shop_item_ids()
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

public event_round_start()
{
    for (new item = 0; item < SHOP_ITEMS; item++)
    {
        g_shop_bought_global[item] = 0
        for (new id = 1; id <= 32; id++)
            g_shop_bought_player[item][id] = 0
    }
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

/*================================================================================
    Config
================================================================================*/

load_shop_config()
{
    for (new i = 0; i < SHOP_ITEMS; i++)
    {
        g_shop_enabled[i] = 1
        copy(g_shop_itemid_str[i], charsmax(g_shop_itemid_str[]), g_shop_default_itemid[i])
        copy(g_shop_name[i], charsmax(g_shop_name[]), g_shop_default_name[i])
        g_shop_limit_player[i] = g_shop_default_player_limit[i]
        g_shop_limit_global[i] = g_shop_default_global_limit[i]
        g_shop_team[i] = g_shop_default_team[i]
        g_shop_vip_only[i] = 0
        g_shop_admin_only[i] = 0

        new costs_text[96]
        copy(costs_text, charsmax(costs_text), g_shop_default_costs[i])

        if (!amx_load_setting_int(SHOP_CFG_FILE, g_shop_section[i], "ENABLED", g_shop_enabled[i]))
            amx_save_setting_int(SHOP_CFG_FILE, g_shop_section[i], "ENABLED", g_shop_enabled[i])

        if (!amx_load_setting_string(SHOP_CFG_FILE, g_shop_section[i], "ITEM_ID", g_shop_itemid_str[i], charsmax(g_shop_itemid_str[])))
            amx_save_setting_string(SHOP_CFG_FILE, g_shop_section[i], "ITEM_ID", g_shop_itemid_str[i])

        if (!amx_load_setting_string(SHOP_CFG_FILE, g_shop_section[i], "NAME", g_shop_name[i], charsmax(g_shop_name[])))
            amx_save_setting_string(SHOP_CFG_FILE, g_shop_section[i], "NAME", g_shop_name[i])

        if (!amx_load_setting_string(SHOP_CFG_FILE, g_shop_section[i], "COSTS", costs_text, charsmax(costs_text)))
            amx_save_setting_string(SHOP_CFG_FILE, g_shop_section[i], "COSTS", costs_text)

        if (!amx_load_setting_int(SHOP_CFG_FILE, g_shop_section[i], "LIMIT_PER_PLAYER_ROUND", g_shop_limit_player[i]))
            amx_save_setting_int(SHOP_CFG_FILE, g_shop_section[i], "LIMIT_PER_PLAYER_ROUND", g_shop_limit_player[i])

        if (!amx_load_setting_int(SHOP_CFG_FILE, g_shop_section[i], "LIMIT_GLOBAL_ROUND", g_shop_limit_global[i]))
            amx_save_setting_int(SHOP_CFG_FILE, g_shop_section[i], "LIMIT_GLOBAL_ROUND", g_shop_limit_global[i])

        new team_text[16]
        switch (g_shop_team[i])
        {
            case TEAM_HUMAN: copy(team_text, charsmax(team_text), "HUMAN")
            case TEAM_ZOMBIE: copy(team_text, charsmax(team_text), "ZOMBIE")
            default: copy(team_text, charsmax(team_text), "ANY")
        }

        if (!amx_load_setting_string(SHOP_CFG_FILE, g_shop_section[i], "TEAM", team_text, charsmax(team_text)))
            amx_save_setting_string(SHOP_CFG_FILE, g_shop_section[i], "TEAM", team_text)

        if (!amx_load_setting_int(SHOP_CFG_FILE, g_shop_section[i], "VIP_ONLY", g_shop_vip_only[i]))
            amx_save_setting_int(SHOP_CFG_FILE, g_shop_section[i], "VIP_ONLY", g_shop_vip_only[i])

        if (!amx_load_setting_int(SHOP_CFG_FILE, g_shop_section[i], "ADMIN_ONLY", g_shop_admin_only[i]))
            amx_save_setting_int(SHOP_CFG_FILE, g_shop_section[i], "ADMIN_ONLY", g_shop_admin_only[i])

        parse_costs(i, costs_text)
        parse_team(i, team_text)
    }
}

parse_costs(item, costs_text[])
{
    g_shop_cost_count[item] = 0

    new copy_text[96], part[16]
    copy(copy_text, charsmax(copy_text), costs_text)

    while (copy_text[0] && g_shop_cost_count[item] < SHOP_MAX_COSTS)
    {
        strtok(copy_text, part, charsmax(part), copy_text, charsmax(copy_text), ',')
        trim(part)
        trim(copy_text)

        if (strlen(part) > 0)
        {
            g_shop_costs[item][g_shop_cost_count[item]] = max(0, str_to_num(part))
            g_shop_cost_count[item]++
        }
    }

    if (g_shop_cost_count[item] <= 0)
    {
        g_shop_costs[item][0] = 0
        g_shop_cost_count[item] = 1
    }
}

parse_team(item, team_text[])
{
    if (equali(team_text, "HUMAN"))
        g_shop_team[item] = TEAM_HUMAN
    else if (equali(team_text, "ZOMBIE"))
        g_shop_team[item] = TEAM_ZOMBIE
    else
        g_shop_team[item] = TEAM_ANY
}

resolve_shop_item_ids()
{
    for (new i = 0; i < SHOP_ITEMS; i++)
        g_shop_zp_itemid[i] = zp_items_get_id(g_shop_itemid_str[i])
}

/*================================================================================
    Main Menu
================================================================================*/

public cmd_main_menu(id)
{
    if (!is_user_connected(id))
        return PLUGIN_HANDLED

    show_main_menu(id)
    return PLUGIN_HANDLED
}

show_main_menu(id)
{
    new title[64]
    formatex(title, charsmax(title), "\y%L", id, "ZP_MENU_TITLE")

    new menu = menu_create(title, "main_menu_handler")

    new text[64]
    formatex(text, charsmax(text), "\w%L", id, "ZP_MENU_BUY_WEAPONS")
    menu_additem(menu, text, "1")
    formatex(text, charsmax(text), "\w%L", id, "ZP_MENU_EXTRA_ITEMS")
    menu_additem(menu, text, "2")
    formatex(text, charsmax(text), "\w%L", id, "ZP_MENU_ZOMBIE_CLASSES")
    menu_additem(menu, text, "3")
    formatex(text, charsmax(text), "\w%L", id, "ZP_MENU_UNSTUCK")
    menu_additem(menu, text, "4")

    if (get_user_flags(id) & VIP_FLAG)
    {
        formatex(text, charsmax(text), "\y%L", id, "ZP_MENU_VIP")
        menu_additem(menu, text, "5")
    }

    if (get_user_flags(id) & ADMIN_MENU_FLAG)
    {
        formatex(text, charsmax(text), "\r%L", id, "ZP_MENU_ADMIN")
        menu_additem(menu, text, "6")
    }

    formatex(text, charsmax(text), "%L", id, "ZP_MENU_EXIT")
    menu_setprop(menu, MPROP_EXITNAME, text)
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

/*================================================================================
    Custom Shop
================================================================================*/

show_custom_items_menu(id)
{
    if (!is_user_alive(id))
        return

    new title[64]
    formatex(title, charsmax(title), "\y%L", id, "ZP_SHOP_TITLE")

    new menu = menu_create(title, "custom_items_handler")

    new shown
    for (new i = 0; i < SHOP_ITEMS; i++)
    {
        if (!should_show_shop_item(id, i))
            continue

        new data[6], text[128], cost
        num_to_str(i, data, charsmax(data))
        cost = get_shop_cost(id, i)

        new player_limit_text[8], global_limit_text[8]
        get_limit_text(g_shop_limit_player[i], player_limit_text, charsmax(player_limit_text))
        get_limit_text(g_shop_limit_global[i], global_limit_text, charsmax(global_limit_text))

        if (is_shop_item_available(id, i))
            formatex(text, charsmax(text), "\w%s \y%d AP \r[%d/%s] \d[%d/%s]", g_shop_name[i], cost, g_shop_bought_player[i][id], player_limit_text, g_shop_bought_global[i], global_limit_text)
        else
            formatex(text, charsmax(text), "\d%s %d AP [%d/%s] [%d/%s]", g_shop_name[i], cost, g_shop_bought_player[i][id], player_limit_text, g_shop_bought_global[i], global_limit_text)

        menu_additem(menu, text, data)
        shown++
    }

    if (!shown)
    {
        client_print_color(id, print_team_default, "^4[ZP]^1 %L", id, "ZP_SHOP_NO_ITEMS")
        menu_destroy(menu)
        return
    }

    new back[32]
    formatex(back, charsmax(back), "%L", id, "ZP_MENU_BACK")
    menu_setprop(menu, MPROP_EXITNAME, back)
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

    buy_shop_item(id, str_to_num(data))

    menu_destroy(menu)
    return PLUGIN_HANDLED
}

bool:should_show_shop_item(id, item)
{
    if (!g_shop_enabled[item])
        return false

    if (g_shop_zp_itemid[item] == -1)
        return false

    if (g_shop_vip_only[item] && !(get_user_flags(id) & VIP_FLAG))
        return false

    if (g_shop_admin_only[item] && !(get_user_flags(id) & ADMIN_MENU_FLAG))
        return false

    if (g_shop_team[item] == TEAM_HUMAN && zp_core_is_zombie(id))
        return false

    if (g_shop_team[item] == TEAM_ZOMBIE && !zp_core_is_zombie(id))
        return false

    return true
}

bool:is_shop_item_available(id, item)
{
    if (!should_show_shop_item(id, item))
        return false

    if (g_shop_limit_player[item] > 0 && g_shop_bought_player[item][id] >= g_shop_limit_player[item])
        return false

    if (g_shop_limit_global[item] > 0 && g_shop_bought_global[item] >= g_shop_limit_global[item])
        return false

    if (zp_ammopacks_get(id) < get_shop_cost(id, item))
        return false

    return true
}

get_shop_cost(id, item)
{
    new bought = g_shop_bought_player[item][id]

    if (bought >= g_shop_cost_count[item])
        bought = g_shop_cost_count[item] - 1

    return g_shop_costs[item][bought]
}

buy_shop_item(id, item)
{
    if (item < 0 || item >= SHOP_ITEMS || !is_user_alive(id))
        return

    if (!should_show_shop_item(id, item))
        return

    if (g_shop_limit_player[item] > 0 && g_shop_bought_player[item][id] >= g_shop_limit_player[item])
    {
        client_print_color(id, print_team_default, "^4[ZP]^1 %L", id, "ZP_SHOP_PLAYER_LIMIT")
        return
    }

    if (g_shop_limit_global[item] > 0 && g_shop_bought_global[item] >= g_shop_limit_global[item])
    {
        client_print_color(id, print_team_default, "^4[ZP]^1 %L", id, "ZP_SHOP_GLOBAL_LIMIT")
        return
    }

    new cost = get_shop_cost(id, item)
    new ap = zp_ammopacks_get(id)

    if (ap < cost)
    {
        client_print_color(id, print_team_default, "^4[ZP]^1 %L", id, "ZP_SHOP_NOT_ENOUGH_AP", cost)
        return
    }

    zp_ammopacks_set(id, ap - cost)

    g_shop_bought_player[item][id]++
    g_shop_bought_global[item]++

    zp_items_force_buy(id, g_shop_zp_itemid[item], 1)

    client_print_color(id, print_team_default, "^4[ZP]^1 %L", id, "ZP_SHOP_BOUGHT", g_shop_name[item], cost)
}

get_limit_text(limit, output[], len)
{
    if (limit <= 0)
        copy(output, len, "-")
    else
        num_to_str(limit, output, len)
}

/*================================================================================
    VIP Menu
================================================================================*/

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

/*================================================================================
    Improved Unstuck
================================================================================*/

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
        client_print_color(id, print_team_default, "^4[ZP]^1 %L", id, "ZP_UNSTUCK_WAIT", g_next_unstuck[id] - now)
        return
    }

    new Float:origin[3], Float:new_origin[3]
    pev(id, pev_origin, origin)

    // First try moving slightly upward.
    for (new z = 0; z < sizeof g_unstuck_z; z++)
    {
        new_origin[0] = origin[0]
        new_origin[1] = origin[1]
        new_origin[2] = origin[2] + g_unstuck_z[z]

        if (is_hull_vacant(id, new_origin))
        {
            finish_unstuck(id, new_origin)
            return
        }
    }

    // Then try wider rings around the player.
    for (new radius = 24; radius <= 192; radius += 24)
    {
        for (new z = 0; z < sizeof g_unstuck_z; z++)
        {
            for (new d = 0; d < sizeof g_unstuck_dirs; d++)
            {
                new_origin[0] = origin[0] + g_unstuck_dirs[d][0] * float(radius)
                new_origin[1] = origin[1] + g_unstuck_dirs[d][1] * float(radius)
                new_origin[2] = origin[2] + g_unstuck_z[z]

                if (is_hull_vacant(id, new_origin))
                {
                    finish_unstuck(id, new_origin)
                    return
                }
            }
        }
    }

    client_print_color(id, print_team_default, "^4[ZP]^1 %L", id, "ZP_UNSTUCK_FAILED")
}

finish_unstuck(id, const Float:origin[3])
{
    engfunc(EngFunc_SetOrigin, id, origin)
    set_pev(id, pev_velocity, Float:{0.0, 0.0, 0.0})
    set_pev(id, pev_flags, pev(id, pev_flags) & ~FL_ONGROUND)

    g_next_unstuck[id] = get_gametime() + 6.0
    client_print_color(id, print_team_default, "^4[ZP]^1 %L", id, "ZP_UNSTUCK_DONE")
}

bool:is_hull_vacant(id, const Float:origin[3])
{
    new hull = (pev(id, pev_flags) & FL_DUCKING) ? HULL_HEAD : HULL_HUMAN

    // IGNORE_MONSTERS avoids failing just because another player/bot is touching you.
    engfunc(EngFunc_TraceHull, origin, origin, IGNORE_MONSTERS, hull, id, 0)

    if (get_tr2(0, TR_StartSolid) || get_tr2(0, TR_AllSolid))
        return false

    return true
}

/*================================================================================
    Auto Save / Load Zombie Class
================================================================================*/

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
