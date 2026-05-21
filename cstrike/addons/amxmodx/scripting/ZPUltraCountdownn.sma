#include <amxmodx>
#include <fakemeta>
#include <zombieplague>

new seconds
new g_release

new const sound_path[] = "countdown"

new const countdown_sounds[][] = 
{
    "countdown/10.wav", "countdown/9.wav", "countdown/8.wav", "countdown/7.wav",
    "countdown/6.wav", "countdown/5.wav", "countdown/4.wav", "countdown/3.wav",
    "countdown/2.wav", "countdown/1.wav"
}

public plugin_init()
{
    register_plugin("[ZP] Countdown Cool", "1.7", "Skeen")
    
    register_event("HLTV", "Round_Start", "a", "1=0", "2=0")
    register_logevent("Round_End", 2, "1=Round_End")
    
    g_release = register_cvar("cd_release", "10")
}

public plugin_precache()
{
    for(new i = 0; i < sizeof(countdown_sounds); i++)
        precache_sound(countdown_sounds[i])
}

public Round_Start()
{
    remove_task(0)
    set_task(3.0, "StartCountdown")
}

public StartCountdown()
{
    seconds = 10
    Countdown()
    set_task(1.0, "Countdown", 0, _, _, "a", 10)
}

public Countdown()
{
    new szMessage[48]
    
    if(seconds >= 6)
        formatex(szMessage, charsmax(szMessage), "The Virus will be released in %d", seconds)
    else if(seconds >= 3)
        formatex(szMessage, charsmax(szMessage), "Infection starts in %d", seconds)
    else
        formatex(szMessage, charsmax(szMessage), "%d", seconds)
    
    // Color
    if(seconds == 1)
        set_hudmessage(255, 0, 0, -1.0, 0.35, 0, 0.0, 1.2, 0.0, 0.0, -1)
    else
        set_hudmessage(255, 255, 255, -1.0, 0.35, 0, 0.0, 1.0, 0.0, 0.0, -1)
    
    show_hudmessage(0, szMessage)
    
    if(seconds >= 1 && seconds <= 10)
        client_cmd(0, "spk %s/%d", sound_path, seconds)
    
    if(seconds <= get_pcvar_num(g_release))
    {
        for(new i = 1; i <= 32; i++)
        {
            if(is_user_alive(i) && !is_user_bot(i))
                set_pev(i, pev_flags, pev(i, pev_flags) & ~FL_FROZEN)
        }
    }
    
    seconds -= 1
    
    if(seconds <= 0)
    {
        remove_task(0)
        set_task(0.8, "ShowGo")   // ← Retrasado a 0.8 segundos
    }
}

public ShowGo()
{
    set_hudmessage(255, 0, 0, -1.0, 0.35, 0, 0.0, 2.5, 0.5, 0.5, -1)  // Más tiempo visible
    show_hudmessage(0, "GO!")
}

public Round_End()
{
    remove_task(0)
    client_cmd(0, "mp3 stop")
}