#include <amxmodx>

#define ICON_NAME "ammopacks"

new g_msgStatusIcon

public plugin_precache()
{
    precache_generic("sprites/ammopacks.spr")
    precache_generic("sprites/hud.txt")
}

public plugin_init()
{
    register_plugin("Custom StatusIcon Test", "1.0", "You")

    g_msgStatusIcon = get_user_msgid("StatusIcon")

    register_clcmd("say /ammo", "ShowAmmoIcon")
    register_clcmd("say /hideammo", "HideAmmoIcon")
}

public ShowAmmoIcon(id)
{
    message_begin(MSG_ONE, g_msgStatusIcon, _, id)
    write_byte(1)
    write_string(ICON_NAME)
    write_byte(0)
    write_byte(200)
    write_byte(255)
    message_end()
}

public HideAmmoIcon(id)
{
    message_begin(MSG_ONE, g_msgStatusIcon, _, id)
    write_byte(0)
    write_string(ICON_NAME)
    write_byte(0)
    write_byte(0)
    write_byte(0)
    message_end()
}