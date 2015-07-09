"use strict";

var skip = false
var selectionOverriden = false

function OnUpdateSelectedUnit( event )
{
	if (skip == true){
		skip = false;
		$.Schedule(0.03, function _override(){ selectionOverriden = false});
		//$.Msg("skip")
		return
	}

	var iPlayerID = Players.GetLocalPlayer();
	var selectedEntities = Players.GetSelectedEntities( iPlayerID );
	var mainSelected = Players.GetLocalPlayerPortraitUnit();

	//$.Msg( "OnUpdateSelectedUnit, main selected index: "+mainSelected+" "+Entities.GetUnitName( mainSelected ));
	//$.Msg(selectedEntities.length+" units selected")
	if (mainSelected == Players.GetPlayerHeroEntityIndex( iPlayerID )) {
		//$.Msg("Changing selection to base building")
		var entities = Entities.GetAllEntities()
		for (var i = 0; i < entities.length; i++) {
			if ( (Entities.GetUnitName( entities[i] ) != "") && Entities.IsControllableByPlayer( entities[i], iPlayerID )) {
				var unitName = Entities.GetUnitName( entities[i] )
				if (IsBaseName(unitName)){
					GameUI.SelectUnit(entities[i], false);
				}				
			}
		};
	}

	//$.Msg( "Player "+iPlayerID+" Selected Entities ("+(selectedEntities.length)+")" );
	if (selectedEntities.length > 1 && IsMixedBuildingSelectionGroup(selectedEntities) ){
		$.Msg( "IsMixedBuildingSelectionGroup, proceeding to deselect the buildings and get only the units ")
		for (var i = 0; i < selectedEntities.length; i++) {
			skip = true; // Makes it skip an update
			if (!IsCustomBuilding(selectedEntities[i]) && !selectionOverriden){
				selectionOverriden = true
				GameUI.SelectUnit(selectedEntities[i], false);
				$.Msg( "New selection group");
			}
			else if (!IsCustomBuilding(selectedEntities[i]) ){
				GameUI.SelectUnit(selectedEntities[i], true); //
				$.Msg( selectedEntities[i]+" added to the selection group");
			}
		}	
	}

	$.Schedule(0.03, SendSelectedEntities);
}

function SendSelectedEntities (params) {
	var iPlayerID = Players.GetLocalPlayer();
	var newSelectedEntities = Players.GetSelectedEntities( iPlayerID );
	GameEvents.SendCustomGameEventToServer( "update_selected_entities", { pID: iPlayerID, selected_entities: newSelectedEntities })
}

function IsBaseName( unitName ){
	if (unitName.indexOf("human") != -1){
		if ( (unitName.indexOf("town_hall") != -1) || (unitName.indexOf("keep")!= -1) || (unitName.indexOf("castle")!= -1) ){
			return true
		}
	}
	else if (unitName.indexOf("nightelf") != -1){
		if ( (unitName.indexOf("tree_of_life") != -1) || (unitName.indexOf("tree_of_ages")!= -1) || (unitName.indexOf("tree_of_eternity")!= -1) ){
			return true
		}
	}
	else if (unitName.indexOf("undead") != -1){
		if ( (unitName.indexOf("necropolis") != -1) || (unitName.indexOf("halls_of_the_dead")!= -1) || (unitName.indexOf("black_citadel")!= -1) ){
			return true
		}
	}
	else if (unitName.indexOf("orc") != -1){
		if ( (unitName.indexOf("great_hall") != -1) || (unitName.indexOf("stronghold")!= -1) || (unitName.indexOf("fortress")!= -1) ){
			return true
		}
	}
	else return false
}

// Returns whether the selection group contains both buildings and non-building units
function IsMixedBuildingSelectionGroup ( entityList ) {
	var buildings = 0
	var nonBuildings = 0
	for (var i = 0; i < entityList.length; i++) {
		if (IsCustomBuilding(entityList[i])){
			buildings++
		}
		else {
			nonBuildings++
		}
	}
	//$.Msg( "Buildings: ",buildings, " NonBuildings: ", nonBuildings)
	return (buildings>0 && nonBuildings>0)
}

function IsCustomBuilding( entityIndex ){
	var ability_building = Entities.GetAbilityByName( entityIndex, "ability_building")
	var ability_tower = Entities.GetAbilityByName( entityIndex, "ability_tower")
	if (ability_building != -1){
		//$.Msg(entityIndex+" IsCustomBuilding - Ability Index: "+ ability_building)
		return true
	}
	else if (ability_tower != -1){
		//$.Msg(entityIndex+" IsCustomBuilding Tower - Ability Index: "+ ability_tower)
		return true
	}
	else
		return false
}

function OnNPCSpawned ( event ){
	var npcIndex = event.entindex
	var unitName = Entities.GetUnitName( npcIndex )
	if (IsBaseName(unitName)){
		GameUI.SelectUnit(npcIndex, true);		
	}
}

function OnUpdateQueryUnit( event )
{
	$.Msg( "OnUpdateQueryUnit" );
}

(function () {
	GameEvents.Subscribe( "npc_spawned", OnNPCSpawned );
	GameEvents.Subscribe( "dota_player_update_selected_unit", OnUpdateSelectedUnit );
	GameEvents.Subscribe( "dota_player_update_query_unit", OnUpdateQueryUnit );
})();