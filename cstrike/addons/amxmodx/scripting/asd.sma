#include <amxmodx>
#include <fun>
#include <zombieplague>

#define TASK_HUD 5000

public plugin_init()
{
    register_plugin("Russian Style HUD", "1.0", "Char")
    set_task(0.2, "ShowHUD", TASK_HUD, _, _, "b")
}

public ShowHUD()
{
    for(new id = 1; id <= 32; id++)
    {
        if(!is_user_alive(id))
            continue

        new hp = get_user_health(id)
        new ap = zp_get_user_ammo_packs(id)

        new class[32]

        if(zp_get_user_nemesis(id))
            copy(class, charsmax(class), "NEMESIS")
        else if(zp_get_user_survivor(id))
            copy(class, charsmax(class), "SURVIVOR")
        else if(zp_get_user_zombie(id))
            copy(class, charsmax(class), "ZOMBIE")
        else
            copy(class, charsmax(class), "HUMAN")

        set_dhudmessage(0, 255, 255, -1.0, 0.83, 0, 6.0, 1.1, 0.0, 0.0)

        show_dhudmessage(id,
            "[ VIDA: %d ]^n[ CLASE: %s ]^n[ AMMO PACKS: %d ]",
            hp, class, ap
        )
    }
}