function CreateControlGroup( index ){
	var iPlayerID = Players.GetLocalPlayer();
    var selectedEntities = Players.GetSelectedEntities(iPlayerID);
	
	CreateControlGroupButton(index, selectedEntities);
};

function CreateControlGroupButton( index, entities){
	if($("#ControlGroup"+index) == null){ // create panel if it doesn't exist
		var ControlGroupButton = $.CreatePanel("Panel", $("#ControlGroups"), "ControlGroup"+index);
		ControlGroupButton.index = index;
		ControlGroupButton.currentSelection = entities;
		ControlGroupButton.BLoadLayout("file://{resources}/layout/custom_game/control_group_button.xml", false, false);
	}else{ // if panel still exist, overwrite current saved selection
		$("#ControlGroup"+index).currentSelection = entities;
	};
	
	if( $("#ControlGroups").GetChildCount() >= 2 )
		GameUI.CustomUIConfig.SortByCustomIndex( $("#ControlGroups"), false );
};

function OnCreateControlGroupPressed( index ){
	if( isControlDown() )
		CreateControlGroup(index);
	else
		if( $("#ControlGroups").GetChild(index-1) != null )
			$("#ControlGroups").GetChild(index-1).OnControlGroupButtonPressed();
};

function isControlDown(){
	return GameUI.IsControlDown();
};

(function () {
	// Create Control Group Keybinds
	GameUI.Keybinds.ControlGroup1 = function() { OnCreateControlGroupPressed(1) }
	GameUI.Keybinds.ControlGroup2 = function() { OnCreateControlGroupPressed(2) }
	GameUI.Keybinds.ControlGroup3 = function() { OnCreateControlGroupPressed(3) }
	GameUI.Keybinds.ControlGroup4 = function() { OnCreateControlGroupPressed(4) }
	GameUI.Keybinds.ControlGroup5 = function() { OnCreateControlGroupPressed(5) }
	GameUI.Keybinds.ControlGroup6 = function() { OnCreateControlGroupPressed(6) }
	GameUI.Keybinds.ControlGroup7 = function() { OnCreateControlGroupPressed(7) }
})();