#include <amxmodx>
#include <fun>
#include <cstrike>
#include <zombieplague>

#define TASK_HUD 5000

new const WEAPONNAMES[][] =
{
    "", "P228", "", "SCOUT", "HEGRENADE", "XM1014", "C4", "MAC10",
    "AUG", "SMOKEGRENADE", "ELITE", "FIVESEVEN", "UMP45", "SG550",
    "GALIL", "FAMAS", "USP", "GLOCK18", "AWP", "MP5", "M249",
    "M3", "M4A1", "TMP", "G3SG1", "FLASHBANG", "DEAGLE",
    "SG552", "AK47", "KNIFE", "P90"
}

public plugin_init()
{
    register_plugin("Custom ZP HUD", "1.6", "Char")

    register_dictionary("zp_custom_hud.txt")

    set_task(0.10, "ShowHUD", TASK_HUD, _, _, "b")
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
        {
            copy(class, charsmax(class), "Nemesis")
        }
        else if(zp_get_user_survivor(id))
        {
            copy(class, charsmax(class), "Survivor")
        }
        else if(zp_get_user_zombie(id))
        {
            new classid = zp_get_user_zombie_class(id)

            switch(classid)
            {
                case 0: copy(class, charsmax(class), "Classic")
                case 1: copy(class, charsmax(class), "Raptor")
                case 2: copy(class, charsmax(class), "Poison")
                case 3: copy(class, charsmax(class), "Fat")
                default: copy(class, charsmax(class), "Zombie")
            }
        }
        else
        {
            copy(class, charsmax(class), "Human")
        }

        new weaponid = get_user_weapon(id)

        new weapon[32]

        if(weaponid >= 0 && weaponid < sizeof WEAPONNAMES)
            copy(weapon, charsmax(weapon), WEAPONNAMES[weaponid])
        else
            copy(weapon, charsmax(weapon), "UNKNOWN")

        new text[192]

        formatex(text, charsmax(text),
            "%L",
            id,
            "ZP_HUD_FORMAT",
            ap,
            hp,
            class,
            weapon
        )

        // Gold color, left-bottom
        set_dhudmessage(
            255, 190, 40,
            0.01, 0.91,
            0,
            0.0,
            0.15,
            0.0,
            0.0
        )

        show_dhudmessage(id, text)
    }
}