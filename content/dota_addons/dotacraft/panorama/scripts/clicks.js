"use strict"

var attackTable = CustomNetTables.GetAllTableValues( "attacks_enabled" )

function GetMouseTarget()
{
    var mouseEntities = GameUI.FindScreenEntities( GameUI.GetCursorPosition() )
    var localHeroIndex = Players.GetPlayerHeroEntityIndex( Players.GetLocalPlayer() )

    for ( var e of mouseEntities )
    {
        if ( !e.accurateCollision )
            continue
        return e.entityIndex
    }

    for ( var e of mouseEntities )
    {
        return e.entityIndex
    }

    return 0
}

// Handle Right Button events
function OnRightButtonPressed()
{
    $.Msg("OnRightButtonPressed")

    var iPlayerID = Players.GetLocalPlayer()
    var selectedEntities = Players.GetSelectedEntities( iPlayerID )
    var mainSelected = Players.GetLocalPlayerPortraitUnit() 
    var mainSelectedName = Entities.GetUnitName( mainSelected )    
    var targetIndex = GetMouseTarget()
    var cursor = GameUI.GetCursorPosition()
    var pressedShift = GameUI.IsShiftDown()
    var bMessageShown = false

    // Enemy right click
    if ( targetIndex && Entities.GetTeamNumber( targetIndex ) !== Entities.GetTeamNumber( mainSelected ) )
    {
        // If it can't be attacked by a unit on the selected group, send them to attack move and show an error (only once)
        
        var order = {
                    QueueBehavior : OrderQueueBehavior_t.DOTA_ORDER_QUEUE_DEFAULT,
                    ShowEffects : true,
                    OrderType : dotaunitorder_t.DOTA_UNIT_ORDER_ATTACK_MOVE,
                    Position : Entities.GetAbsOrigin( targetIndex ),
                }

        for (var i = 0; i < selectedEntities.length; i++)
        {
            if (! UnitCanAttackTarget(selectedEntities[i], targetIndex))
            {
                order.UnitIndex = selectedEntities[i]
                Game.PrepareUnitOrders( order )
                if (!bMessageShown)
                {
                    GameUI.CustomUIConfig().ErrorMessage({text : "#error_cant_target_air", style : {color:'#E62020'}, duration : 2})
                    bMessageShown = true
                }
            }
        }
        if (bMessageShown)
        {
            return true
        }
    }

    // Builder Right Click
    if ( IsBuilder( mainSelected ) )
    {
        // Cancel BH
        if (!pressedShift) SendCancelCommand()

        // If it's mousing over entities
        if (targetIndex)
        {
            var entityName = Entities.GetUnitName(targetIndex)
            // Gold mine rightclick
            if (entityName == "gold_mine"){
                $.Msg("Player "+iPlayerID+" Clicked on a gold mine")
                GameEvents.SendCustomGameEventToServer( "gold_gather_order", { pID: iPlayerID, mainSelected: mainSelected, targetIndex: targetIndex, queue: pressedShift})
                return true
            }
            // Entangled gold mine rightclick
            else if (mainSelectedName == "nightelf_wisp" && entityName == "nightelf_entangled_gold_mine" && Entities.IsControllableByPlayer( targetIndex, iPlayerID )){
                $.Msg("Player "+iPlayerID+" Clicked on a entangled gold mine")
                GameEvents.SendCustomGameEventToServer( "gold_gather_order", { pID: iPlayerID, mainSelected: mainSelected, targetIndex: targetIndex, queue: pressedShift })
                return true
            }
            // Haunted gold mine rightclick
            else if (mainSelectedName == "undead_acolyte" && entityName == "undead_haunted_gold_mine" && Entities.IsControllableByPlayer( targetIndex, iPlayerID )){
                $.Msg("Player "+iPlayerID+" Clicked on a haunted gold mine")
                GameEvents.SendCustomGameEventToServer( "gold_gather_order", { pID: iPlayerID, mainSelected: mainSelected, targetIndex: targetIndex, queue: pressedShift })
                return true
            }
            // Repair rightclick
            else if ( (IsCustomBuilding(targetIndex) || IsMechanical(targetIndex)) && Entities.GetHealthPercent(targetIndex) < 100 && Entities.IsControllableByPlayer( targetIndex, iPlayerID ) ){
                $.Msg("Player "+iPlayerID+" Clicked on a building or mechanical unit with health missing")
                GameEvents.SendCustomGameEventToServer( "repair_order", { pID: iPlayerID, mainSelected: mainSelected, targetIndex: targetIndex, queue: pressedShift })
                return true
            }
            else if (IsCustomBuilding(targetIndex) && mainSelectedName == "orc_peon" && Entities.GetUnitName( targetIndex ) == "orc_burrow"){
                $.Msg(" Targeted orc burrow")
                GameEvents.SendCustomGameEventToServer( "burrow_order", { pID: iPlayerID, mainSelected: mainSelected, targetIndex: targetIndex })
            }
            return false
        }
    }

    // Building Right Click
    else if (IsCustomBuilding(mainSelected))
    {
        $.Msg("Building Right Click")

        // Click on a target entity
        if (targetIndex)
        {
            var entityName = Entities.GetUnitName(targetIndex)
            if ( entityName == "gold_mine" || ( Entities.IsControllableByPlayer( targetIndex, iPlayerID ) && (entityName == "nightelf_entangled_gold_mine" || entityName == "undead_haunted_gold_mine")))
            {
                $.Msg(" Targeted gold mine")
                GameEvents.SendCustomGameEventToServer( "building_rally_order", { pID: iPlayerID, mainSelected: mainSelected, rally_type: "mine", targetIndex: targetIndex })
            }
            else if ( IsShop( mainSelected ) && Entities.IsControllableByPlayer( targetIndex, iPlayerID )  && ( Entities.IsHero( targetIndex ) || Entities.IsInventoryEnabled( targetIndex )) && Entities.GetRangeToUnit( mainSelected, targetIndex) <= 900)
            {
                $.Msg(" Targeted unit to shop")
                GameEvents.SendCustomGameEventToServer( "shop_active_order", { shop: mainSelected, unit: targetIndex, targeted: true})
            }
            else
            {
                $.Msg(" Targeted some entity to rally point")
                GameEvents.SendCustomGameEventToServer( "building_rally_order", { pID: iPlayerID, mainSelected: mainSelected, rally_type: "target", targetIndex: targetIndex })
            }
            return true
        }
        // Click on a position
        else
        {
            $.Msg(" Targeted position")
            var GamePos = Game.ScreenXYToWorld(cursor[0], cursor[1])
            GameEvents.SendCustomGameEventToServer( "building_rally_order", { pID: iPlayerID, mainSelected: mainSelected, rally_type: "position", position: GamePos})
            return true
        }
    }

    // Unit rightclick
    if (targetIndex)
    {
        // Moonwell rightclick
        if (IsCustomBuilding(targetIndex) && Entities.GetUnitName(targetIndex) == "nightelf_moon_well" && Entities.IsControllableByPlayer( targetIndex, iPlayerID ) )
        {
            $.Msg("Player "+iPlayerID+" Clicked on moon well to replenish")
            GameEvents.SendCustomGameEventToServer( "moonwell_order", { pID: iPlayerID, mainSelected: mainSelected, targetIndex: targetIndex })
            return false //Keep the unit order
        }

        else
        {
            GameEvents.SendCustomGameEventToServer( "right_click_order", { pID: iPlayerID })
        }
    }

    return false
}

// Handle Left Button events
function OnLeftButtonPressed() {
    $.Msg("OnLeftButtonPressed")

    var iPlayerID = Players.GetLocalPlayer()
    var mainSelected = Players.GetLocalPlayerPortraitUnit() 
    var mainSelectedName = Entities.GetUnitName( mainSelected )
    var targetIndex = GetMouseTarget()
    
    Hide_All_Shops()

    if (targetIndex)
    {
        if ((IsShop(targetIndex) && IsAlliedUnit(mainSelected,targetIndex)) || IsTavern(targetIndex))
        {
            $.Msg("Player "+iPlayerID+" Clicked on a Shop")
            ShowShop(targetIndex)

            // Hero or unit with inventory
            if (UnitCanPurchase(mainSelected))
            {
                GameEvents.SendCustomGameEventToServer( "shop_active_order", { shop: targetIndex, unit: mainSelected, targeted: true})
                return true
            }
        }
    }

    return false
}

function OnAttacksEnabledChanged (args) {
    attackTable = CustomNetTables.GetAllTableValues( "attacks_enabled" )
}

function UnitCanAttackTarget (unit, target) {
    var attacks_enabled = GetAttacksEnabled(unit)
    var target_type = GetMovementCapability(target)
  
    return (Entities.CanAcceptTargetToAttack(unit, target) || (attacks_enabled.indexOf(target_type) != -1))
}

function GetMovementCapability (entIndex) {
    return Entities.HasFlyMovementCapability( entIndex ) ? "air" : "ground"
}

function GetAttacksEnabled (unit) {
    var unitName = Entities.GetUnitName(unit)
    var attackTypes = CustomNetTables.GetTableValue( "attacks_enabled", unitName)
    return attackTypes ? attackTypes.enabled : "ground"
}

function UnitCanPurchase(entIndex) {
    return (Entities.IsRealHero(entIndex) || 
            Entities.GetAbilityByName(entIndex, "human_backpack") != -1 || 
            Entities.GetAbilityByName(entIndex, "orc_backpack") != -1 || 
            Entities.GetAbilityByName(entIndex, "nightelf_backpack") != -1 || 
            Entities.GetAbilityByName(entIndex, "undead_backpack") != -1)
}

function IsBuilder(entIndex) {
    var tableValue = CustomNetTables.GetTableValue( "builders", entIndex.toString())
    return (tableValue !== undefined) && (tableValue.IsBuilder == 1)
}

function IsShop(entIndex) {
    return (IsCustomBuilding(entIndex) && Entities.GetAbilityByName( entIndex, "ability_shop") != -1)
}

function IsTavern(entIndex) {
    return (Entities.GetUnitLabel( entIndex ) == "tavern")
}

function IsAlliedUnit(entIndex, targetIndex) {
    return (Entities.GetTeamNumber(entIndex) == Entities.GetTeamNumber(targetIndex))
}

function IsNeutralUnit(entIndex) {
    return (Entities.GetTeamNumber(entIndex) == DOTATeam_t.DOTA_TEAM_NEUTRALS)
}

(function () {
    CustomNetTables.SubscribeNetTableListener( "attacks_enabled", OnAttacksEnabledChanged );
})();

// Main mouse event callback
GameUI.SetMouseCallback( function( eventName, arg ) {
    var CONSUME_EVENT = true
    var CONTINUE_PROCESSING_EVENT = false
    var LEFT_CLICK = (arg === 0)
    var RIGHT_CLICK = (arg === 1)

    if ( GameUI.GetClickBehaviors() !== CLICK_BEHAVIORS.DOTA_CLICK_BEHAVIOR_NONE )
        return CONTINUE_PROCESSING_EVENT

    var mainSelected = Players.GetLocalPlayerPortraitUnit()

    if ( eventName === "pressed" || eventName === "doublepressed")
    {
        // Builder Clicks
        if (IsBuilder(mainSelected))
            if (LEFT_CLICK) 
                return (state == "active") ? SendBuildCommand() : OnLeftButtonPressed()
            else if (RIGHT_CLICK) 
                return OnRightButtonPressed()

        if (LEFT_CLICK) 
            return OnLeftButtonPressed()
        else if (RIGHT_CLICK) 
            return OnRightButtonPressed() 
        
    }
    return CONTINUE_PROCESSING_EVENT
} )