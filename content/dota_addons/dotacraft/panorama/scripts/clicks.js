"use strict";

// Handle Right Button events
function OnRightButtonPressed()
{
	$.Msg("OnRightButtonPressed")

	var iPlayerID = Players.GetLocalPlayer();
	var mainSelected = Players.GetLocalPlayerPortraitUnit(); 
	var mainSelectedName = Entities.GetUnitName( mainSelected )
	var cursor = GameUI.GetCursorPosition();
	var mouseEntities = GameUI.FindScreenEntities( cursor );
	mouseEntities = mouseEntities.filter( function(e) { return e.entityIndex != mainSelected; } )
	
	var pressedShift = GameUI.IsShiftDown();

	// Builder Right Click
	if ( IsBuilder(mainSelectedName) )
	{
		// Cancel BH
		SendCancelCommand();

		// If it's mousing over entities
		if (mouseEntities.length > 0)
		{
			for ( var e of mouseEntities )
			{
				var entityName = Entities.GetUnitName(e.entityIndex)
				// Gold mine rightclick
				if (entityName == "gold_mine"){
					$.Msg("Player "+iPlayerID+" Clicked on a gold mine")
					GameEvents.SendCustomGameEventToServer( "gold_gather_order", { pID: iPlayerID, mainSelected: mainSelected, targetIndex: e.entityIndex, queue: pressedShift})
					return true;
				}
				// Entangled gold mine rightclick
				else if (mainSelectedName == "nightelf_wisp" && entityName == "nightelf_entangled_gold_mine" && Entities.IsControllableByPlayer( e.entityIndex, iPlayerID )){
					$.Msg("Player "+iPlayerID+" Clicked on a entangled gold mine")
					GameEvents.SendCustomGameEventToServer( "gold_gather_order", { pID: iPlayerID, mainSelected: mainSelected, targetIndex: e.entityIndex, queue: pressedShift })
					return true;
				}
				// Haunted gold mine rightclick
				else if (mainSelectedName == "undead_acolyte" && entityName == "undead_haunted_gold_mine" && Entities.IsControllableByPlayer( e.entityIndex, iPlayerID )){
					$.Msg("Player "+iPlayerID+" Clicked on a haunted gold mine")
					GameEvents.SendCustomGameEventToServer( "gold_gather_order", { pID: iPlayerID, mainSelected: mainSelected, targetIndex: e.entityIndex, queue: pressedShift })
					return true;
				}
				// Repair rightclick
				else if ( (IsCustomBuilding(e.entityIndex) || IsMechanical(e.entityIndex)) && Entities.GetHealthPercent(e.entityIndex) < 100 && Entities.IsControllableByPlayer( e.entityIndex, iPlayerID ) ){
					$.Msg("Player "+iPlayerID+" Clicked on a building or mechanical unit with health missing")
					GameEvents.SendCustomGameEventToServer( "repair_order", { pID: iPlayerID, mainSelected: mainSelected, targetIndex: e.entityIndex, queue: pressedShift })
					return true;
				}
				return false;
			}
		}
			
	}

	// Building Right Click
	else if (IsCustomBuilding(mainSelected))
	{
		$.Msg("Building Right Click")

		// Click on a target entity
		if (mouseEntities.length > 0)
		{
			for ( var e of mouseEntities )
			{
				var entityName = Entities.GetUnitName(e.entityIndex)
				if ( entityName == "gold_mine" || ( Entities.IsControllableByPlayer( e.entityIndex, iPlayerID ) && (entityName == "nightelf_entangled_gold_mine" || entityName == "undead_haunted_gold_mine")))
				{
					$.Msg(" Targeted gold mine")
					GameEvents.SendCustomGameEventToServer( "building_rally_order", { pID: iPlayerID, mainSelected: mainSelected, rally_type: "mine", targetIndex: e.entityIndex })
				}
				else{
					$.Msg(" Targeted a building")
					GameEvents.SendCustomGameEventToServer( "building_rally_order", { pID: iPlayerID, mainSelected: mainSelected, rally_type: "target", targetIndex: e.entityIndex })
				}
				return true;
			}
		}
		// Click on a position
		else
		{
			$.Msg(" Targeted position")
			var GamePos = Game.ScreenXYToWorld(cursor[0], cursor[1]);
			GameEvents.SendCustomGameEventToServer( "building_rally_order", { pID: iPlayerID, mainSelected: mainSelected, rally_type: "position", position: GamePos})
			return true;
		}
	}

	// Unit rightclick
	if (mouseEntities.length > 0)
	{	
		for ( var e of mouseEntities )
		{
			// Moonwell rightclick
			if (IsCustomBuilding(e.entityIndex) && Entities.GetUnitName(e.entityIndex) == "nightelf_moon_well" && Entities.IsControllableByPlayer( e.entityIndex, iPlayerID ) )
			{
				$.Msg("Player "+iPlayerID+" Clicked on moon well to replenish")
				GameEvents.SendCustomGameEventToServer( "moonwell_order", { pID: iPlayerID, mainSelected: mainSelected, targetIndex: e.entityIndex })
				return false; //Keep the unit order
			}

			else
			{
				GameEvents.SendCustomGameEventToServer( "right_click_order", { pID: iPlayerID })
			}
		}
	}

	return false;
}

function IsBuilder(name) {
	return (name == "human_peasant" || name == "nightelf_wisp" || name == "orc_peon" || name == "undead_acolyte")
}

// Main mouse event callback
GameUI.SetMouseCallback( function( eventName, arg ) {
    var CONSUME_EVENT = true;
    var CONTINUE_PROCESSING_EVENT = false;

    if ( GameUI.GetClickBehaviors() !== CLICK_BEHAVIORS.DOTA_CLICK_BEHAVIOR_NONE )
        return CONTINUE_PROCESSING_EVENT;

    var mainSelectedName = Entities.GetUnitName( Players.GetLocalPlayerPortraitUnit())

    if ( eventName === "pressed" && IsBuilder(mainSelectedName))
    {
        // Left-click with a builder while BH is active
        if ( arg === 0 && state == "active")
        {
            return SendBuildCommand();
        }

        // Right-click (Cancel & Repair)
        if ( arg === 1 )
        {
            return OnRightButtonPressed();
        }
    }
    else if ( eventName === "pressed" || eventName === "doublepressed")
    {
        // Left-click
        if ( arg === 0 )
        {
            //OnLeftButtonPressed();
            return CONTINUE_PROCESSING_EVENT;
        }

        // Right-click
        if ( arg === 1 )
        {
            return OnRightButtonPressed();
        }
    }
    return CONTINUE_PROCESSING_EVENT;
} );