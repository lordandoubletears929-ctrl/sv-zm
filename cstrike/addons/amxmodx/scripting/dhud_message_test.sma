
#include <amxmodx>
#include <dhudmessage>

public plugin_init()
{
    register_plugin( "Test", "", "" );
    register_clcmd( "say /test", "ClientCommand_Test" );
}

public ClientCommand_Test( client )
{
    set_dhudmessage( 0, 160, 0, -1.0, 0.25, 2, 6.0, 3.0, 0.1, 1.5 );
    show_dhudmessage( client, "Welcome, Gordon Freeman." );
    
}
