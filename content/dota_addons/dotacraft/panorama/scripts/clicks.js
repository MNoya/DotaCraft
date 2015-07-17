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
	var mouseEntities = GameUI.FindScreenEntities( GameUI.GetCursorPosition() );
	mouseEntities = mouseEntities.filter( function(e) { return e.entityIndex != mainSelected; } )
	
	//$.Msg("entities: ", mouseEntities.length)
	if (mouseEntities.length == 0 || !IsBuilder(mainSelectedName) )
	{
		return false;
	}
	else{
		for ( var e of mouseEntities )
		{
			if ( !e.accurateCollision )
				continue;
			if (Entities.GetUnitName(e.entityIndex) == "gold_mine"){
				$.Msg("Player "+iPlayerID+" Clicked on a gold mine")
				GameEvents.SendCustomGameEventToServer( "gold_gather_order", { pID: iPlayerID, mainSelected: mainSelected, targetIndex: e.entityIndex })
				return true;
			}
			else{
				return false;
			}
		}
		return false;
	}
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
