"use strict";

/* 
Right click triggers the gather ability if the unit has it and clicks on a gold mine.
*/

var inAction = false;

// Handle Right Button events
function OnRightButtonPressed()
{
	//$.Msg("OnRightButtonPressed")

	var iPlayerID = Players.GetLocalPlayer();
	var mainSelected = Players.GetLocalPlayerPortraitUnit(); 
	var mainSelectedName = Entities.GetUnitName( mainSelected )
	var cursor = GameUI.GetCursorPosition();
	var mouseEntities = GameUI.FindScreenEntities( cursor );
	mouseEntities = mouseEntities.filter( function(e) { return e.entityIndex != mainSelected; } )
	
	//$.Msg("entities: ", mouseEntities.length)
	// Builder Right Click on gold mine
	if (mouseEntities.length > 0 && IsBuilder(mainSelectedName) )
	{
		for ( var e of mouseEntities )
		{
			if (Entities.GetUnitName(e.entityIndex) == "gold_mine"){
				$.Msg("Player "+iPlayerID+" Clicked on a gold mine")
				GameEvents.SendCustomGameEventToServer( "gold_gather_order", { pID: iPlayerID, mainSelected: mainSelected, targetIndex: e.entityIndex })
				return true;
			}
			else if (IsCustomBuilding(e.entityIndex) && Entities.GetHealthPercent(e.entityIndex) < 100 && Entities.IsControllableByPlayer( e.entityIndex, iPlayerID ) ){
				$.Msg("Player "+iPlayerID+" Clicked on a building with health missing")
				GameEvents.SendCustomGameEventToServer( "repair_order", { pID: iPlayerID, mainSelected: mainSelected, targetIndex: e.entityIndex })
				return true;
			}
			return false;
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
				if (Entities.GetUnitName(e.entityIndex) == "gold_mine"){
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

	return false;
}

function IsBuilder(name) {
	return (name == "human_peasant" || name == "nightelf_wisp" || name == "orc_peon" || name == "undead_acolyte")
}

// Main mouse event callback
GameUI.SetMouseCallback( function( eventName, arg ) {
	var CONSUME_EVENT = true;
	var CONTINUE_PROCESSING_EVENT = false;
	//$.Msg("MOUSE: ", eventName, " -- ", arg, " -- ", GameUI.GetClickBehaviors())

	if ( GameUI.GetClickBehaviors() !== CLICK_BEHAVIORS.DOTA_CLICK_BEHAVIOR_NONE )
		return CONTINUE_PROCESSING_EVENT;

	if ( eventName === "pressed" || eventName === "doublepressed")
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
