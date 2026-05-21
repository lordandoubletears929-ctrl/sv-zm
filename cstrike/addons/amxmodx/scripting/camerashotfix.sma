#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>

#define RECOIL_MULT 0.15 // 0.15 = 15% recoil visual

new Float:g_oldPunch[33][3]

new const WEAPONS[][] =
{
    "weapon_p228",
    "weapon_scout",
    "weapon_xm1014",
    "weapon_mac10",
    "weapon_aug",
    "weapon_elite",
    "weapon_fiveseven",
    "weapon_ump45",
    "weapon_sg550",
    "weapon_galil",
    "weapon_famas",
    "weapon_usp",
    "weapon_glock18",
    "weapon_awp",
    "weapon_mp5navy",
    "weapon_m249",
    "weapon_m3",
    "weapon_m4a1",
    "weapon_tmp",
    "weapon_g3sg1",
    "weapon_deagle",
    "weapon_sg552",
    "weapon_ak47",
    "weapon_p90"
}

public plugin_init()
{
    register_plugin("Ham Soft Visual Recoil", "1.0", "Char")

    for(new i = 0; i < sizeof WEAPONS; i++)
    {
        RegisterHam(Ham_Weapon_PrimaryAttack, WEAPONS[i], "fw_PrimaryAttack_Pre", 0)
        RegisterHam(Ham_Weapon_PrimaryAttack, WEAPONS[i], "fw_PrimaryAttack_Post", 1)
    }
}

public fw_PrimaryAttack_Pre(ent)
{
    new id = pev(ent, pev_owner)

    if(id < 1 || id > 32 || !is_user_alive(id))
        return HAM_IGNORED

    pev(id, pev_punchangle, g_oldPunch[id])

    return HAM_IGNORED
}

public fw_PrimaryAttack_Post(ent)
{
    new id = pev(ent, pev_owner)

    if(id < 1 || id > 32 || !is_user_alive(id))
        return HAM_IGNORED

    new Float:newPunch[3]
    pev(id, pev_punchangle, newPunch)

    newPunch[0] = g_oldPunch[id][0] + ((newPunch[0] - g_oldPunch[id][0]) * RECOIL_MULT)
    newPunch[1] = g_oldPunch[id][1] + ((newPunch[1] - g_oldPunch[id][1]) * RECOIL_MULT)
    newPunch[2] = g_oldPunch[id][2] + ((newPunch[2] - g_oldPunch[id][2]) * RECOIL_MULT)

    set_pev(id, pev_punchangle, newPunch)

    return HAM_IGNORED
}