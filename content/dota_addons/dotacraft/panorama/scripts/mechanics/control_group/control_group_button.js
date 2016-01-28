var Root = $.GetContextPanel()
var LeaderOfControlGroupEntIndex;

function Setup_Panel(){
	$.Msg("[CONTROL GROUP BUTTON] Creating control group button #: "+Root.index);
	$("#UnitCount").text = CountEntitiesInControlGroup();
	$("#ID").text = Root.index;
	
	CheckSavedSelectionStates();
};  

function CountEntitiesInControlGroup(){
	var count = 0;
	for(var unit in Root.currentSelection)
		count++;

	return count;
};

function CheckSavedSelectionStates(){
	var done = true;

	for(var unit of Root.currentSelection){
		if( isValidUnit(unit) )
			done = false;
	};
	
	if(!done){
		CheckUnitsInSelection();
		var newLeader = DetermineLeader();

		if( newLeader != LeaderOfControlGroupEntIndex ){
			LeaderOfControlGroupEntIndex = newLeader;
			SetUnitImage();
		};
		
		$.Schedule(0.1, CheckSavedSelectionStates);
	}else{
		Remove_Self();
	};
};

function SetUnitImage(){
	var unitName = Entities.GetUnitName(LeaderOfControlGroupEntIndex);
	var path = "url('file://{images}/units/"+unitName+".png');";
	$("#UnitImage").style["background-image"] = path;
};

var unitCounter = {}
function DetermineLeader(){
	// empty out existing array
	unitCounter = {}
	var newLeader = 0;

	// check all units
	for(var unit of Root.currentSelection){
		var unitName = Entities.GetUnitName(unit);
		if( Entities.IsHero(unit) ){
			newLeader = unit;
			break;
		};
	};
	
	if( newLeader == 0)
		newLeader = Root.currentSelection[0];
	
	return newLeader;
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

// NOTE
// Change event entity index being send once future implementations have been made to priorities units
// NOTE
function SelectGroupButtonPress(){
	var context = $.GetContextPanel();
	context.OnControlGroupButtonPressed();
};

var lastTime = 0;
var DOUBLE_CLICK_THRESHOLD = 0.5;
function WasPanelDoubleClicked(){
	var time = Game.GetGameTime();
	var lastClick = time - lastTime;
	
	if (lastClick <= DOUBLE_CLICK_THRESHOLD)
		GameEvents.SendCustomGameEventToServer( "reposition_player_camera", { entIndex: LeaderOfControlGroupEntIndex });

	lastTime = time;
};

Root.OnControlGroupButtonPressed = function(){
	ClearCurrentSelection();
	for(var unit of Root.currentSelection){
		if( isValidUnit(unit) ){ 
			GameUI.SelectUnit(unit, true);
		};
	};
	WasPanelDoubleClicked();
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