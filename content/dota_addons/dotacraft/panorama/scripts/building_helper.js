'use strict';

var state = 'disabled';
var size = 0;
var pressedShift = false;
var modelParticle;
var gridParticles;

// Ghost Building Preferences
var GRID_ALPHA = 30 // Defines the transparency of the ghost squares

function StartBuildingHelper( params )
{
    if (params !== undefined)
    {
        state = params["state"];
        size = params["size"];
        pressedShift = GameUI.IsShiftDown();

        var scale = params["scale"]
        var entindex = params["entindex"];

        var localHeroIndex = Players.GetPlayerHeroEntityIndex( Players.GetLocalPlayer() );

        if (modelParticle !== undefined) {
            Particles.DestroyParticleEffect(modelParticle, true)
        }
        if (gridParticles !== undefined) {
            for (var i in gridParticles) {
                Particles.DestroyParticleEffect(gridParticles[i], true)
            }
        }

        // Building Ghost
        modelParticle = Particles.CreateParticle("particles/buildinghelper/ghost_model.vpcf", ParticleAttachment_t.PATTACH_ABSORIGIN, localHeroIndex);
        Particles.SetParticleControlEnt(modelParticle, 1, entindex, ParticleAttachment_t.PATTACH_ABSORIGIN_FOLLOW, "follow_origin", Entities.GetAbsOrigin(entindex), true)
        Particles.SetParticleControl(modelParticle, 2, [255,255,255]) //Keep the original color
        Particles.SetParticleControl(modelParticle, 3, [100,0,0]) //Grid Alpha
        Particles.SetParticleControl(modelParticle, 4, [scale,0,0]) //Model Scale

        // Grid squares
        gridParticles = [];
        for (var x=0; x < size*size; x++)
        {
            var particle = Particles.CreateParticle("particles/buildinghelper/square_sprite.vpcf", ParticleAttachment_t.PATTACH_CUSTOMORIGIN, 0)
            Particles.SetParticleControl(particle, 1, [32,0,0])
            Particles.SetParticleControl(particle, 3, [GRID_ALPHA,0,0])
            gridParticles.push(particle)
        }
    } 
    
    if (state == 'active')
    {
        $.Schedule(1/60, StartBuildingHelper);

        var mPos = GameUI.GetCursorPosition();
        var GamePos = Game.ScreenXYToWorld(mPos[0], mPos[1]);

        if ( GamePos !== null ) 
        {
            SnapToGrid(GamePos, size)

            var color = [0,255,0]
            var part = 0
            var halfSide = (size/2)*64
            var boundingRect = {}
            boundingRect["leftBorderX"] = GamePos[0]-halfSide
            boundingRect["rightBorderX"] = GamePos[0]+halfSide
            boundingRect["topBorderY"] = GamePos[1]+halfSide
            boundingRect["bottomBorderY"] = GamePos[1]-halfSide

            if (GamePos[0] > 10000000) return

            for (var x=boundingRect["leftBorderX"]+32; x <= boundingRect["rightBorderX"]-32; x+=64)
            {
                for (var y=boundingRect["topBorderY"]-32; y >= boundingRect["bottomBorderY"]+32; y-=64)
                {
                    var pos = [x,y,GamePos[2]]
                    if (part>size*size)
                    {
                        $.Msg(pos)
                        return
                    } 
                    var gridParticle = gridParticles[part]
                    Particles.SetParticleControl(gridParticle, 0, pos)     
                    part++; 

                    $.Msg("Put Grid Particle ["+part+"] on ",pos)
                    var screenX = Game.WorldToScreenX( pos[0], pos[1], pos[2] );
                    var screenY = Game.WorldToScreenY( pos[0], pos[1], pos[2] );
                    var mouseEntities = GameUI.FindScreenEntities( [screenX,screenY] );

                    // Color
                    if (mouseEntities.length > 0)
                    {
                        color = [255,0,0]
                    }
                    Particles.SetParticleControl(gridParticle, 2, color)            
                }
            }      

            // Update the model particle
            Particles.SetParticleControl(modelParticle, 0, GamePos)
        }

        if (!GameUI.IsShiftDown() && pressedShift)
        {
            EndBuildingHelper();
        }
    }
}

function EndBuildingHelper()
{
    state = 'disabled'
    Particles.DestroyParticleEffect(modelParticle, true)
    for (var i in gridParticles) {
        Particles.DestroyParticleEffect(gridParticles[i], true)
    }
}

function SendBuildCommand( params )
{
    $.Msg("Send Build command")
    var mPos = GameUI.GetCursorPosition();
    var GamePos = Game.ScreenXYToWorld(mPos[0], mPos[1]);
    GameEvents.SendCustomGameEventToServer( "building_helper_build_command", { "X" : GamePos[0], "Y" : GamePos[1], "Z" : GamePos[2] } );
    pressedShift = GameUI.IsShiftDown();

    // Cancel unless the player is holding shift
    if (!GameUI.IsShiftDown())
    {
        EndBuildingHelper(params);
        return true;
    }
}

function SendCancelCommand( params )
{
    EndBuildingHelper();
    GameEvents.SendCustomGameEventToServer( "building_helper_cancel_command", {} );
}

(function () {
    GameEvents.Subscribe( "building_helper_enable", StartBuildingHelper);
})();

// Main mouse event callback
GameUI.SetMouseCallback( function( eventName, arg ) {
    var CONSUME_EVENT = true;
    var CONTINUE_PROCESSING_EVENT = false;

    if ( GameUI.GetClickBehaviors() !== CLICK_BEHAVIORS.DOTA_CLICK_BEHAVIOR_NONE )
        return CONTINUE_PROCESSING_EVENT;

    if ( eventName === "pressed" && state === 'active')
    {
        // Left-click
        if ( arg === 0 )
        {
            return SendBuildCommand();
        }

        // Right-click
        if ( arg === 1 )
        {
            return SendCancelCommand();
        }
    }
    return CONTINUE_PROCESSING_EVENT;
} );

//-----------------------------------

function SnapToGrid(vec, size) {
    // Buildings are centered differently when the size is odd.
    if (size % 2 != 0) 
    {
        vec[0] = SnapToGrid32(vec[0])
        vec[1] = SnapToGrid32(vec[1])
    } 
    else 
    {
        vec[0] = SnapToGrid64(vec[0])
        vec[1] = SnapToGrid64(vec[1])
    }
}

function SnapToGrid64(coord) {
    return 64*Math.round(0.5+coord/64);
}

function SnapToGrid32(coord) {
    return 32+64*Math.round(coord/64);
}