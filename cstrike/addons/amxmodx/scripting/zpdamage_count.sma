#include <amxmodx>
#include <hamsandwich>

new g_last_pos[33]

public plugin_init()
{
    register_plugin("Random Damage Display", "1.4", "Char")

    RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage_Post", 1)
}

public fw_TakeDamage_Post(victim, inflictor, attacker, Float:damage, damagebits)
{
    if(attacker < 1 || attacker > 32)
        return HAM_IGNORED

    if(!is_user_connected(attacker) || attacker == victim || damage <= 0.0)
        return HAM_IGNORED

    new dmg = floatround(damage)

    new pos
    do {
        pos = random_num(0, 7)
    } while(pos == g_last_pos[attacker])

    g_last_pos[attacker] = pos

    new Float:x, Float:y

    switch(pos)
    {
        case 0: { x = 0.45; y = 0.45; }
        case 1: { x = 0.50; y = 0.44; }
        case 2: { x = 0.55; y = 0.45; }
        case 3: { x = 0.56; y = 0.50; }
        case 4: { x = 0.55; y = 0.56; }
        case 5: { x = 0.50; y = 0.57; }
        case 6: { x = 0.45; y = 0.56; }
        case 7: { x = 0.44; y = 0.50; }
    }

    set_dhudmessage(0, 255, 0, x, y, 0, 0.0, 0.4, 0.0, 0.0)
    show_dhudmessage(attacker, "%d", dmg)

    return HAM_IGNORED
}