/*============================================================
    ZP50 DHUD Grande - Mejor para tamaño
============================================================*/

#include <amxmodx>
#include <fakemeta>
#include <dhudmessage>
#include <zp50_core>
#include <zp50_class_human>
#include <zp50_class_zombie>

public plugin_init()
{
    register_plugin("ZP50 DHUD Grande", "1.0", "Grok")
    set_task(0.5, "ShowDHUD", _, _, _, "b")
}

public ShowDHUD()
{
    for(new id = 1; id <= 32; id++)
    {
        if(!is_user_alive(id))
            continue;

        static class_name[32]
        
        if(zp_core_is_zombie(id))
        {
            zp_class_zombie_get_name(zp_class_zombie_get_current(id), class_name, charsmax(class_name))
            set_dhudmessage(255, 60, 60, 0.02, 0.88, 0, 6.0, 8.0, 0.0, 0.0)  // Tamaño 8.0
        }
        else
        {
            zp_class_human_get_name(zp_class_human_get_current(id), class_name, charsmax(class_name))
            set_dhudmessage(100, 200, 255, 0.02, 0.88, 0, 6.0, 8.0, 0.0, 0.0)
        }

        show_dhudmessage(id, "HP: %d^n%s", get_user_health(id), class_name)
    }
}