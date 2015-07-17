"use strict";

/* 
Right click triggers the gather ability if the unit has it and clicks on a gold mine.
*/

var inAction = false;

// Gather ability is expected to be on the first slot
function SendGoldGatherOrder( targetEntIndex )
{
	var order = {
		OrderType : dotaunitorder_t.DOTA_UNIT_ORDER_CAST_TARGET,
		TargetIndex : targetEntIndex,
		AbilityIndex : Entities.GetAbility( Players.GetLocalPlayerPortraitUnit(), 0 ),
		Queue : false,
		ShowEffects : false
	};

	$.Msg('trying ', Entities.IsAlive( order.TargetIndex), Abilities.IsCooldownReady( order.AbilityIndex), !Abilities.IsInAbilityPhase( order.AbilityIndex), Abilities.GetAbilityName(order.AbilityIndex) );
	if ( Entities.IsAlive( order.TargetIndex) && Abilities.IsCooldownReady( order.AbilityIndex ) && !Abilities.IsInAbilityPhase( order.AbilityIndex ) && !Abilities.IsHidden( order.AbilityIndex ))
	{
		$.Msg("ORDER");
		Game.PrepareUnitOrders( order );
	}
	else{
		$.Msg("NO")
	}
}

// Handle Right Button events
function OnRightButtonPressed()
{
	$.Msg("OnRightButtonPressed")

	var iPlayerID = Players.GetLocalPlayer();
	var mainSelected = Players.GetLocalPlayerPortraitUnit(); 
	var mainSelectedName = Entities.GetUnitName( mainSelected )
	var mouseEntities = GameUI.FindScreenEntities( GameUI.GetCursorPosition() );
	mouseEntities = mouseEntities.filter( function(e) { return e.entityIndex != mainSelected; } )
	
	$.Msg("entities: ", mouseEntities.length)
	if (mouseEntities.length == 0 || (mainSelectedName != "human_peasant"))
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
				SendGoldGatherOrder( e.entityIndex )
				return true;
			}
			else{
				return false;
			}
		}
		return false;
	}
}

// Main mouse event callback
GameUI.SetMouseCallback( function( eventName, arg ) {
	var CONSUME_EVENT = true;
	var CONTINUE_PROCESSING_EVENT = false;
	$.Msg("MOUSE: ", eventName, " -- ", arg, " -- ", GameUI.GetClickBehaviors())

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
			$.Msg("OnRightButtonPressed")
			return OnRightButtonPressed();
		}
	}
	return CONTINUE_PROCESSING_EVENT;
} );
