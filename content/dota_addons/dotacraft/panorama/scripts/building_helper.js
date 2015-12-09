'use strict';

var state = 'disabled';
var size = 0;
var overlay_size = 0;
var grid_alpha = 30;
var overlay_alpha = 90;
var model_alpha = 100;
var recolor_ghost = false;
var pressedShift = false;
var altDown = false;
var modelParticle;
var gridParticles;
var overlayParticles;
var builderIndex;
var entityGrid;
var cutTrees = [];
var BLOCKED = 2;
var Root = $.GetContextPanel()
var constructionSize = CustomNetTables.GetAllTableValues( "construction_size" )

if (! Root.loaded)
{
    Root.GridNav = [];
    Root.squareX = 0;
    Root.squareY = 0;
    Root.loaded = true;
}


function StartBuildingHelper( params )
{
    if (params !== undefined)
    {
        // Set the parameters passed by AddBuilding
        state = params.state;
        size = params.size;
        overlay_size = size*3;
        grid_alpha = Number(params.grid_alpha);
        model_alpha = Number(params.model_alpha);
        recolor_ghost = Number(params.recolor_ghost);
        builderIndex = params.builderIndex;
        var scale = params.scale;
        var entindex = params.entindex;
        
        // If we chose to not recolor the ghost model, set it white
        var ghost_color = [0, 255, 0]
        if (!recolor_ghost)
            ghost_color = [255,255,255]

        pressedShift = GameUI.IsShiftDown();

        var localHeroIndex = Players.GetPlayerHeroEntityIndex( Players.GetLocalPlayer() );

        if (modelParticle !== undefined) {
            Particles.DestroyParticleEffect(modelParticle, true)
        }
        if (gridParticles !== undefined) {
            for (var i in gridParticles) {
                Particles.DestroyParticleEffect(gridParticles[i], true)
            }
        }
        if (overlayParticles !== undefined) {
            for (var i in overlayParticles) {
                Particles.DestroyParticleEffect(overlayParticles[i], true)
            }
        }

        // Building Ghost
        modelParticle = Particles.CreateParticle("particles/buildinghelper/ghost_model.vpcf", ParticleAttachment_t.PATTACH_ABSORIGIN, localHeroIndex);
        Particles.SetParticleControlEnt(modelParticle, 1, entindex, ParticleAttachment_t.PATTACH_ABSORIGIN_FOLLOW, "follow_origin", Entities.GetAbsOrigin(entindex), true)
        Particles.SetParticleControl(modelParticle, 2, ghost_color)
        Particles.SetParticleControl(modelParticle, 3, [model_alpha,0,0])
        Particles.SetParticleControl(modelParticle, 4, [scale,0,0])

        // Grid squares
        gridParticles = [];
        for (var x=0; x < size*size; x++)
        {
            var particle = Particles.CreateParticle("particles/buildinghelper/square_sprite.vpcf", ParticleAttachment_t.PATTACH_CUSTOMORIGIN, 0)
            Particles.SetParticleControl(particle, 1, [32,0,0])
            Particles.SetParticleControl(particle, 3, [grid_alpha,0,0])
            gridParticles.push(particle)
        }

        overlayParticles = [];
    }

    if (state == 'active')
    {   
        $.Schedule(1/60, StartBuildingHelper);

        // Get all the creature entities on the screen
        var entities = Entities.GetAllEntitiesByClassname('npc_dota_creature')
        var hero_entities = Entities.GetAllEntitiesByClassname('npc_dota_hero')
        var build_entities = Entities.GetAllEntitiesByClassname('npc_dota_building')
        var tree_entities = Entities.GetAllEntitiesByClassname('ent_dota_tree')
        entities = entities.concat(hero_entities)
        entities = entities.concat(build_entities)

        // Build the entity grid with the construction sizes and entity origins
        entityGrid = []
        for (var i = 0; i < entities.length; i++)
        {
            if (!Entities.IsAlive(entities[i]) || Entities.IsOutOfGame(entities[i])) continue
            var entPos = Entities.GetAbsOrigin( entities[i] )
            var squares = GetConstructionSize(entities[i])

            if (squares > 0)
            {
                // Block squares centered on the origin 
                BlockGridSquares(entPos, squares)
            }
            else
            {
                // Put visible chopped tree dummies on a separate table to skip trees
                if (Entities.GetUnitName(entities[i]) == 'tree_chopped')
                {
                    cutTrees[entPos] = entities[i]
                }
                // Block 2x2 squares if its an enemy unit
                else if (Entities.GetTeamNumber(entities[i]) != Entities.GetTeamNumber(builderIndex))
                {
                    BlockGridSquares(entPos, 2)
                }
            }      
        }

        // Handle trees
        for (var i = 0; i < tree_entities.length; i++) 
        {
            var treePos = Entities.GetAbsOrigin(tree_entities[i])
            // Block the grid if the tree isn't chopped
            if (cutTrees[treePos] === undefined)
                BlockGridSquares(treePos, 2)
        }

        var mPos = GameUI.GetCursorPosition();
        var GamePos = Game.ScreenXYToWorld(mPos[0], mPos[1]);
        GamePos[2]+=5 //Modify offset on ground based on the origin
        if ( GamePos !== null ) 
        {
            SnapToGrid(GamePos, size)

            var invalid;
            var color = [0,255,0]
            var part = 0
            var halfSide = (size/2)*64
            var boundingRect = {}
            boundingRect["leftBorderX"] = GamePos[0]-halfSide
            boundingRect["rightBorderX"] = GamePos[0]+halfSide
            boundingRect["topBorderY"] = GamePos[1]+halfSide
            boundingRect["bottomBorderY"] = GamePos[1]-halfSide

            if (GamePos[0] > 10000000) return

            // Building Base Grid
            for (var x=boundingRect["leftBorderX"]+32; x <= boundingRect["rightBorderX"]-32; x+=64)
            {
                for (var y=boundingRect["topBorderY"]-32; y >= boundingRect["bottomBorderY"]+32; y-=64)
                {
                    var pos = [x,y,GamePos[2]]
                    if (part>size*size)
                        return

                    var gridParticle = gridParticles[part]
                    Particles.SetParticleControl(gridParticle, 0, pos)     
                    part++; 

                    // Grid color turns red when over invalid position
                    color = [0,255,0]
                    if (IsBlocked(pos))
                    {
                        color = [255,0,0]
                        invalid = true
                    }

                    Particles.SetParticleControl(gridParticle, 2, color)   
                }
            }

            // Overlay Grid, visible with Alt pressed
            altDown = GameUI.IsAltDown();
            if (altDown)
            {
                // Create the particles
                if (overlayParticles && overlayParticles.length == 0)
                {
                    for (var y=0; y < overlay_size*overlay_size; y++)
                    {
                        var particle = Particles.CreateParticle("particles/buildinghelper/square_overlay.vpcf", ParticleAttachment_t.PATTACH_CUSTOMORIGIN, 0)
                        Particles.SetParticleControl(particle, 1, [32,0,0])
                        Particles.SetParticleControl(particle, 3, [0,0,0])
                        overlayParticles.push(particle)
                    }
                }

                color = [255,255,255]
                var part2 = 0
                var halfSide2 = (overlay_size/2)*64
                var boundingRect2 = {}
                boundingRect2["leftBorderX"] = GamePos[0]-halfSide2
                boundingRect2["rightBorderX"] = GamePos[0]+halfSide2
                boundingRect2["topBorderY"] = GamePos[1]+halfSide2
                boundingRect2["bottomBorderY"] = GamePos[1]-halfSide2

                for (var x2=boundingRect2["leftBorderX"]+32; x2 <= boundingRect2["rightBorderX"]-32; x2+=64)
                {
                    for (var y2=boundingRect2["topBorderY"]-32; y2 >= boundingRect2["bottomBorderY"]+32; y2-=64)
                    {
                        var pos2 = [x2,y2,GamePos[2]]
                        if (part2>=overlay_size*overlay_size)
                            return

                        color = [255,255,255] //White on empty positions
                        var overlayParticle = overlayParticles[part2]
                        Particles.SetParticleControl(overlayParticle, 0, pos2)     
                        part2++;

                        if (IsBlocked(pos2))
                            color = [255,0,0]                        

                        Particles.SetParticleControl(overlayParticle, 2, color)        
                        Particles.SetParticleControl(overlayParticle, 3, [overlay_alpha,0,0])
                    }
                }
            }
            else
            {
                // Destroy the particles, only once
                if (overlayParticles && overlayParticles.length != 0)
                {
                    for (var i in overlayParticles) {
                        Particles.DestroyParticleEffect(overlayParticles[i], true)
                    }
                    overlayParticles = [];
                }
            }

            // Update the model particle
            Particles.SetParticleControl(modelParticle, 0, GamePos)

            // Turn the model red if we can't build there
            if (recolor_ghost){
                if (invalid)
                    Particles.SetParticleControl(modelParticle, 2, [255,0,0])
                else
                    Particles.SetParticleControl(modelParticle, 2, [255,255,255])
            }
        }

        if ( (!GameUI.IsShiftDown() && pressedShift) || !Entities.IsAlive( builderIndex ) )
        {
            EndBuildingHelper();
        }
    }
}

function EndBuildingHelper()
{
    state = 'disabled'
    if (modelParticle !== undefined){
         Particles.DestroyParticleEffect(modelParticle, true)
    }
    for (var i in gridParticles) {
        Particles.DestroyParticleEffect(gridParticles[i], true)
    }
    for (var i in overlayParticles) {
        Particles.DestroyParticleEffect(overlayParticles[i], true)
    }
}

function SendBuildCommand( params )
{
    pressedShift = GameUI.IsShiftDown();
    var mainSelected = Players.GetLocalPlayerPortraitUnit(); 

    $.Msg("Send Build command. Queue: "+pressedShift)
    var mPos = GameUI.GetCursorPosition();
    var GamePos = Game.ScreenXYToWorld(mPos[0], mPos[1]);

    GameEvents.SendCustomGameEventToServer( "building_helper_build_command", { "builder": mainSelected, "X" : GamePos[0], "Y" : GamePos[1], "Z" : GamePos[2] , "Queue" : pressedShift } );

    // Cancel unless the player is holding shift
    if (!GameUI.IsShiftDown())
    {
        EndBuildingHelper(params);
        return true;
    }
    return true;
}

function SendCancelCommand( params )
{
    EndBuildingHelper();
    GameEvents.SendCustomGameEventToServer( "building_helper_cancel_command", {} );
}

function RegisterGNV(msg){
    var GridNav = [];
    var squareX = msg.squareX
    var squareY = msg.squareY
    $.Msg("Registering GNV ["+squareX+","+squareY+"]")

    var arr = [];
    // Thanks to BMD for this method
    for (var i=0; i<msg.gnv.length; i++){
        var code = msg.gnv.charCodeAt(i)+53;
        for (var j=6; j>=0; j-=2){
            var g = (code & (3 << j)) >> j;

            arr.push(g);
        }
    }

    // Load the GridNav
    var x = 0;
    for (var i = 0; i < squareX; i++) {
        GridNav[i] = []
        for (var j = 0; j < squareY; j++) {
            GridNav[i][j] = arr[x]
            x++
        }

        // ASCII Art
        //$.Msg(GridNav[i].join(''))
    }
    Root.GridNav = GridNav
    Root.squareX = squareX
    Root.squareY = squareY

    // Debug Prints
    var tab = {"0":0, "1":0, "2":0, "3":0};
    for (i=0; i<arr.length; i++)
    {
        tab[arr[i].toString()]++;
    }
    $.Msg("Free: ",tab["1"]," Blocked: ",tab["2"])
}

// Ask the server for the Terrain grid
function RequestGNV () {
    GameEvents.SendCustomGameEventToServer( "gnv_request", {} )
}

(function () {    
    RequestGNV()

    GameEvents.Subscribe( "building_helper_enable", StartBuildingHelper);
    GameEvents.Subscribe( "building_helper_end", EndBuildingHelper);
    
    GameEvents.Subscribe( "gnv_register", RegisterGNV);
})();

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
    return 64*Math.floor(0.5+coord/64);
}

function SnapToGrid32(coord) {
    return 32+64*Math.floor(coord/64);
}

function IsBlocked(position) {
    var x = WorldToGridPosX(position[0]) + Root.squareX/2
    var y = WorldToGridPosY(position[1]) + Root.squareY/2
    
    return (Root.GridNav[x][y] == BLOCKED) || IsEntityGridBlocked(x,y)
}

function IsEntityGridBlocked(x,y) {
    return (entityGrid[x] && entityGrid[x][y] == BLOCKED)
}

function BlockEntityGrid(position) {
    var x = WorldToGridPosX(position[0]) + Root.squareX/2
    var y = WorldToGridPosY(position[1]) + Root.squareY/2

    if (entityGrid[x] === undefined) entityGrid[x] = []

    entityGrid[x][y] = BLOCKED
}

function BlockGridSquares (position, squares) {
    var halfSide = (squares/2)*64
    var boundingRect = {}
    boundingRect["leftBorderX"] = position[0]-halfSide
    boundingRect["rightBorderX"] = position[0]+halfSide
    boundingRect["topBorderY"] = position[1]+halfSide
    boundingRect["bottomBorderY"] = position[1]-halfSide

    for (var x=boundingRect["leftBorderX"]+32; x <= boundingRect["rightBorderX"]-32; x+=64)
    {
        for (var y=boundingRect["topBorderY"]-32; y >= boundingRect["bottomBorderY"]+32; y-=64)
        {
            var pos = [x,y,0]
            BlockEntityGrid(pos)
        }
    }
}

function WorldToGridPosX(x){
    return Math.floor(x/64)
}

function WorldToGridPosY(y){
    return Math.floor(y/64)
}

function GetConstructionSize(entIndex) {
    var entName = Entities.GetUnitName(entIndex)
    var table = CustomNetTables.GetTableValue( "construction_size", entName)
    return table ? table.size : 0
}

function PrintGridCoords(x,y) {
    $.Msg('(',x,',',y,') = [',WorldToGridPosX(x),',',WorldToGridPosY(y),']')
}