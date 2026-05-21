#include <amxmodx>
#include <engine>
#include <fakemeta>

new g_WSprite

public plugin_precache()
{
    // Your sprite path
    g_WSprite = precache_model("sprites/hudfont/W.spr")
}

public plugin_init()
{
    register_plugin("Sprite Test", "1.0", "You")

    // Type /w in chat
    register_clcmd("say /w", "StartSprite")
}

public StartSprite(id)
{
    // Repeats every 0.1 sec
    set_task(0.1, "DrawSprite", id, _, _, "b")
}

public DrawSprite(id)
{
    if(!is_user_alive(id))
        return

    new Float:origin[3]
    pev(id, pev_origin, origin)

    // Only this player sees it
    message_begin(MSG_ONE_UNRELIABLE, SVC_TEMPENTITY, _, id)

    write_byte(TE_SPRITE)

    // Position
    engfunc(EngFunc_WriteCoord, origin[0])
    engfunc(EngFunc_WriteCoord, origin[1])
    engfunc(EngFunc_WriteCoord, origin[2] + 80.0)

    // Sprite
    write_short(g_WSprite)

    // Size (IMPORTANT)
    write_byte(3)

    // Brightness
    write_byte(255)

    message_end()
}