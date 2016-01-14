var Root = $.GetContextPanel()

function Setup_Panel(){
	$.Msg("[CONTROL GROUP BUTTON] Creating control group button #: "+Root.index);
	$("#UnitCount").text = CountEntitiesInControlGroup();
	$("#ID").text = Root.index;
	
	AssignHotkeyPressedEvent()
	
	CheckSavedSelectionStates();
};  

function CountEntitiesInControlGroup(){
	var count = 0;
	for(var unit in Root.currentSelection)
		count++;

	return count;
};

function AssignHotkeyPressedEvent(){
	// Select Control Group Hotkeys
	Game.AddCommand( "+SelectControlGroup"+Root.index, OnControlGroupButtonPressed, "", 0 );
};

function CheckSavedSelectionStates(){
	var done = true;

	for(var unit of Root.currentSelection){
		if( isValidUnit(unit) )
			done = false;
	};
	
	if(!done){
		CheckUnitsInSelection();
		$.Schedule(0.1, CheckSavedSelectionStates);
	}else{
		Remove_Self();
	};
};

function CheckUnitsInSelection(){	
	for(var unit of Root.currentSelection){
		if( !isValidUnit(unit) ){
			var index = Root.currentSelection.indexOf(unit);
			Root.currentSelection.splice(index, 1);
		};
	};	
	$("#UnitCount").text = CountEntitiesInControlGroup();
};

function OnControlGroupButtonPressed(){
	ClearCurrentSelection();
	for(var unit of Root.currentSelection){
		if( isValidUnit(unit) ){ 
			GameUI.SelectUnit(unit, true);
		};
	};
};

(function () { 
	Setup_Panel();
})();

function Remove_Self(){
	$.Msg("[CONTROL GROUP BUTTON] Deleting self, entities are all dead");
	Root.RemoveAndDeleteChildren();
	Root.DeleteAsync(0);
};

function isValidUnit( unit ){
	return ( Entities.IsValidEntity(unit) && Entities.IsAlive(unit) );
};

function ClearCurrentSelection(){
	GameUI.SelectUnit(9999999, false);
};