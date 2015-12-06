"use strict";

function EmitClientSound(msg)
{
    if (msg.sound){
        $.Msg(msg)
        Game.EmitSound(msg.sound); 
    }
}

(function(){
    GameEvents.Subscribe( "emit_client_sound", EmitClientSound);
})()