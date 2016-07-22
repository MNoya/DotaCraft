
var Root = $.GetContextPanel();
var MAX_PLAYER_PER_ROW = 6;
var MAX_ROWS = 2;

// appreantly it's possible for spectators not to have a unit selected - possible future problems?
function SetupAbilityList(){ 
	var unit = Players.GetLocalPlayerPortraitUnit();
	$.Msg("creating ability panels");

		for(var i = 0; i < MAX_PLAYER_PER_ROW * MAX_ROWS; i++){ 
			var panelRow;
			if( i < MAX_PLAYER_PER_ROW )
				panelRow = Root.FindChildTraverse("AbilityTopRow")
			else
				panelRow = Root.FindChildTraverse("AbilityBottomRow")		
			
			var abilityPanel = $.CreatePanel( "Panel", panelRow, "Ability_"+i);
			abilityPanel.BLoadLayout( "file://{resources}/layout/custom_game/action_bar_ability.xml", false, false );			
		};  

};  

function UpdateAbilityList(){
	var unit = Players.GetLocalPlayerPortraitUnit();
	
	if( !Entities.IsHero( unit ) ){
		Root.visible = true;
		var inLearnMode = Game.IsInAbilityLearnMode();
		for(var i = 0; i < MAX_PLAYER_PER_ROW * MAX_ROWS; i++){	
			var abilityPanel = FindAbilityPanel(i);
			abilityPanel.UpdatePanel(unit, i, inLearnMode);
		};
	}else
		Root.visible = false;
};

function FindAbilityPanel(id){
	return Root.FindChildTraverse("Ability_"+id);
};

function OnLevelUpClicked()
{
	if ( Game.IsInAbilityLearnMode() )
	{
		Game.EndAbilityLearnMode();
	}
	else
	{
		Game.EnterAbilityLearnMode();
	}
}

(function(){
   	GameEvents.Subscribe( "dota_portrait_ability_layout_changed", UpdateAbilityList );
	GameEvents.Subscribe( "dota_player_update_selected_unit", UpdateAbilityList );
	GameEvents.Subscribe( "dota_player_update_query_unit", UpdateAbilityList );
	GameEvents.Subscribe( "dota_ability_changed", UpdateAbilityList );
	GameEvents.Subscribe( "dota_hero_ability_points_changed", UpdateAbilityList );
	
   SetupAbilityList();
})()
