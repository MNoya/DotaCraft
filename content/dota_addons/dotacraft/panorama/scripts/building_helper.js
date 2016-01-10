'use strict';

GameUI.SetRenderBottomInsetOverride( 0 );

var state = 'disabled';
var frame_rate = 1/30;
var tree_update_interval = 1;
var size = 0;
var overlay_size = 0;
var range = 0;
var pressedShift = false;
var altDown = false;
var requires;
var modelParticle;
var propParticle;
var propScale;
var offsetZ;
var gridParticles;
var overlayParticles;
var rangeOverlay;
var rangeOverlayActive;
var builderIndex;
var entityGrid = [];
var tree_entities = [];
var distance_to_gold_mine;
var last_tree_update = Game.GetGameTime();
var treeGrid = [];
var cutTrees = [];
var BLOCKED = 2;
var GRID_TYPES = [];

// building_settings.kv options
var grid_alpha = CustomNetTables.GetTableValue( "building_settings", "grid_alpha").value
var alt_grid_alpha = CustomNetTables.GetTableValue( "building_settings", "alt_grid_alpha").value
var alt_grid_squares = CustomNetTables.GetTableValue( "building_settings", "alt_grid_squares").value;
var range_overlay_alpha = CustomNetTables.GetTableValue( "building_settings", "range_overlay_alpha").value
var model_alpha = CustomNetTables.GetTableValue( "building_settings", "model_alpha").value
var recolor_ghost = CustomNetTables.GetTableValue( "building_settings", "recolor_ghost").value;
var turn_red = CustomNetTables.GetTableValue( "building_settings", "turn_red").value;
var permanent_alt_grid = CustomNetTables.GetTableValue( "building_settings", "permanent_alt_grid").value;
var update_trees = CustomNetTables.GetTableValue( "building_settings", "update_trees").value;

var HEIGHT_RESTRICTION
if (CustomNetTables.GetTableValue( "building_settings", "height_restriction") !== undefined)
    HEIGHT_RESTRICTION = CustomNetTables.GetTableValue( "building_settings", "height_restriction").value;

var Root = $.GetContextPanel()
var localHeroIndex = Players.GetPlayerHeroEntityIndex( Players.GetLocalPlayer() );

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
        range = params.range;
        overlay_size = size + alt_grid_squares * 2;
        builderIndex = params.builderIndex;
        requires = params.requires;
        var scale = params.scale;
        var entindex = params.entindex;
        var propScale = params.propScale;
        offsetZ = params.offsetZ;

        if (requires !== undefined)
        {
            if (GRID_TYPES[requires] === undefined)
                GRID_TYPES[requires] = GRID_TYPES.length + BLOCKED + 1
        }

        distance_to_gold_mine = HasGoldMineDistanceRestriction(entindex)
        
        // If we chose to not recolor the ghost model, set it white
        var ghost_color = [0, 255, 0]
        if (!recolor_ghost)
            ghost_color = [255,255,255]

        pressedShift = GameUI.IsShiftDown();

        if (modelParticle !== undefined) {
            Particles.DestroyParticleEffect(modelParticle, true)
        }
        if (propParticle !== undefined) {
            Particles.DestroyParticleEffect(propParticle, true)
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
        if (rangeOverlay !== undefined) {
            Particles.DestroyParticleEffect(rangeOverlay, true)
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

        // Prop particle attachment
        if (params.propIndex !== undefined)
        {
            propParticle = Particles.CreateParticle("particles/buildinghelper/ghost_model.vpcf", ParticleAttachment_t.PATTACH_ABSORIGIN, localHeroIndex);
            Particles.SetParticleControlEnt(propParticle, 1, params.propIndex, ParticleAttachment_t.PATTACH_ABSORIGIN_FOLLOW, "attach_hitloc", Entities.GetAbsOrigin(params.propIndex), true)
            Particles.SetParticleControl(propParticle, 2, ghost_color)
            Particles.SetParticleControl(propParticle, 3, [model_alpha,0,0])
            Particles.SetParticleControl(propParticle, 4, [propScale,0,0])
        }
            
        rangeOverlayActive = false;
        overlayParticles = [];
    }

    if (state == 'active')
    {   
        $.Schedule(frame_rate, StartBuildingHelper);

        // Get all the creature entities on the screen
        var entities = Entities.GetAllEntitiesByClassname('npc_dota_building')
        var hero_entities = Entities.GetAllHeroEntities()
        var creature_entities = Entities.GetAllEntitiesByClassname('npc_dota_creature')
        entities = entities.concat(hero_entities)
        entities = entities.concat(creature_entities)

        // Build the entity grid with the construction sizes and entity origins
        entityGrid = []
        for (var i = 0; i < entities.length; i++)
        {
            if (!Entities.IsAlive(entities[i]) || Entities.IsOutOfGame(entities[i])) continue
            var entPos = Entities.GetAbsOrigin( entities[i] )
            var squares = GetConstructionSize(entities[i])
            
            if (squares > 0 && ( IsCustomBuilding(entities[i]) || IsGoldMine(entities[i])))
            {
                if (IsGoldMine(entities[i]))
                    BlockGridSquares(entPos, squares, requires)
                else
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

        // Update treeGrid (slowly, as its the most expensive)
        if (update_trees)
        {
            var time = Game.GetGameTime()
            var time_since_last_tree_update = time - last_tree_update
            if (time_since_last_tree_update > tree_update_interval)
            {
                last_tree_update = time
                tree_entities = Entities.GetAllEntitiesByClassname('ent_dota_tree')
                for (var i = 0; i < tree_entities.length; i++)
                {
                    var treePos = Entities.GetAbsOrigin(tree_entities[i])
                    BlockGridSquares(treePos, 2, "TREE")
                }
            }
        }

        var mPos = GameUI.GetCursorPosition();
        var GamePos = Game.ScreenXYToWorld(mPos[0], mPos[1]);
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

            var closeToGoldMine = TooCloseToGoldmine(GamePos)

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
                    if (IsBlocked(pos) || closeToGoldMine)
                    {
                        color = [255,0,0]
                        invalid = true
                    }

                    Particles.SetParticleControl(gridParticle, 2, color)   
                }
            }

            // Overlay Grid, visible with Alt pressed
            altDown = permanent_alt_grid || GameUI.IsAltDown();
            if (altDown)
            {
                // Create the particles
                if (overlayParticles && overlayParticles.length == 0)
                {
                    for (var y=0; y < overlay_size*overlay_size; y++)
                    {
                        var particle = Particles.CreateParticle("particles/buildinghelper/square_overlay.vpcf", ParticleAttachment_t.PATTACH_CUSTOMORIGIN, 0)
                        Particles.SetParticleControl(particle, 1, [32,0,0])
                        Particles.SetParticleControl(particle, 3, [alt_grid_alpha,0,0])
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

                        if (IsBlocked(pos2) || TooCloseToGoldmine(pos2))
                            color = [255,0,0]                        

                        Particles.SetParticleControl(overlayParticle, 2, color)
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
            if (propParticle !== undefined) Particles.SetParticleControl(propParticle, 0, [GamePos[0],GamePos[1],GamePos[2]+offsetZ])

            // Destroy the range overlay if its not a valid building location
            if (invalid)
            {
                if (rangeOverlayActive && rangeOverlay !== undefined)
                {
                    Particles.DestroyParticleEffect(rangeOverlay, true)
                    rangeOverlayActive = false
                }
            }
            else
            {
                if (!rangeOverlayActive)
                {
                    rangeOverlay = Particles.CreateParticle("particles/buildinghelper/range_overlay.vpcf", ParticleAttachment_t.PATTACH_CUSTOMORIGIN, localHeroIndex)
                    Particles.SetParticleControl(rangeOverlay, 1, [range,0,0])
                    Particles.SetParticleControl(rangeOverlay, 2, [255,255,255])
                    Particles.SetParticleControl(rangeOverlay, 3, [range_overlay_alpha,0,0])
                    rangeOverlayActive = true
                }              
            }

            if (rangeOverlay !== undefined)
                Particles.SetParticleControl(rangeOverlay, 0, GamePos)

            // Turn the model red if we can't build there
            if (turn_red){
                invalid ? Particles.SetParticleControl(modelParticle, 2, [255,0,0]) : Particles.SetParticleControl(modelParticle, 2, [255,255,255])
                if (propParticle !== undefined)
                    invalid ? Particles.SetParticleControl(propParticle, 2, [255,0,0]) : Particles.SetParticleControl(propParticle, 2, [255,255,255])
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
    if (propParticle !== undefined){
         Particles.DestroyParticleEffect(propParticle, true)
    }
    if (rangeOverlay !== undefined){
        Particles.DestroyParticleEffect(rangeOverlay, true)
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

    if (requires !== undefined)
        return !IsSpecialGrid(x,y, requires)

    var restrictHeight = (HEIGHT_RESTRICTION !== undefined) ? position[2] < HEIGHT_RESTRICTION : false

    return restrictHeight || Root.GridNav[x][y] == BLOCKED || IsEntityGridBlocked(x,y) || IsTreeGridBlocked(x,y)
}

function IsEntityGridBlocked(x,y) {
    return (entityGrid[x] && entityGrid[x][y] == BLOCKED)
}

function IsTreeGridBlocked(x,y) {
    return (treeGrid[x] && treeGrid[x][y] == BLOCKED)
}

function IsSpecialGrid (x,y, gridType) {
    return (entityGrid[x] && entityGrid[x][y] == GRID_TYPES[gridType])
}

function BlockEntityGrid(position, gridType) {
    var x = WorldToGridPosX(position[0]) + Root.squareX/2
    var y = WorldToGridPosY(position[1]) + Root.squareY/2

    if (entityGrid[x] === undefined) entityGrid[x] = []

    if (gridType !== undefined)
    {
        entityGrid[x][y] = GRID_TYPES[gridType]
    }
    else
        entityGrid[x][y] = BLOCKED
}

// Trees block 2x2
function BlockTreeGrid (position) {
    var x = WorldToGridPosX(position[0]) + Root.squareX/2
    var y = WorldToGridPosY(position[1]) + Root.squareY/2

    if (treeGrid[x] === undefined) treeGrid[x] = []

    treeGrid[x][y] = BLOCKED
}

function BlockGridSquares (position, squares, gridType) {
    var halfSide = (squares/2)*64
    var boundingRect = {}
    boundingRect["leftBorderX"] = position[0]-halfSide
    boundingRect["rightBorderX"] = position[0]+halfSide
    boundingRect["topBorderY"] = position[1]+halfSide
    boundingRect["bottomBorderY"] = position[1]-halfSide

    if (gridType == "TREE")
    {
        for (var x=boundingRect["leftBorderX"]+32; x <= boundingRect["rightBorderX"]-32; x+=64)
        {
            for (var y=boundingRect["topBorderY"]-32; y >= boundingRect["bottomBorderY"]+32; y-=64)
            {
                var pos = [x,y,0]
                BlockTreeGrid(pos)
            }
        }
    }
    else
    {
        for (var x=boundingRect["leftBorderX"]+32; x <= boundingRect["rightBorderX"]-32; x+=64)
        {
            for (var y=boundingRect["topBorderY"]-32; y >= boundingRect["bottomBorderY"]+32; y-=64)
            {
                var pos = [x,y,0]
                BlockEntityGrid(pos, gridType)
            }
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

function HasGoldMineDistanceRestriction(entIndex) {
    var entName = Entities.GetUnitName(entIndex)
    var table = CustomNetTables.GetTableValue( "construction_size", entName)
    return table ? table.distance_to_gold_mine : 0
}

function GetClosestDistanceToGoldMine(position) {
    var building_entities = Entities.GetAllEntitiesByClassname('npc_dota_building')

    var minDistance = 99999
    for (var i = 0; i < building_entities.length; i++)
    {
        if (Entities.GetUnitName(building_entities[i]) == "gold_mine")
        {
            var distance_to_this_mine = Length2D(position, Entities.GetAbsOrigin(building_entities[i]))
            if (distance_to_this_mine < minDistance)
                minDistance = distance_to_this_mine
        }
    }
    return minDistance
}

function TooCloseToGoldmine(position) {
    return (distance_to_gold_mine > 0 && GetClosestDistanceToGoldMine(position) < distance_to_gold_mine)
}

function Length2D(v1, v2) {
    return Math.sqrt( (v2[0]-v1[0])*(v2[0]-v1[0]) + (v2[1]-v1[1])*(v2[1]-v1[1]) + (v2[2]-v1[2])*(v2[2]-v1[2]) )
}

function PrintGridCoords(x,y) {
    $.Msg('(',x,',',y,') = [',WorldToGridPosX(x),',',WorldToGridPosY(y),']')
}