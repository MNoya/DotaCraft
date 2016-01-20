var categoryIDs = {
	1 : "#Overview",
	2 : "#Units",
	3 : "#Heroes",
	4 : "#Resources"
};

var activeID = 1;
var playerData = { 1 : {}, 2 : {}, 3 : {}, 4 : {} };
function SwitchCategory(ID){
	if(ID != activeID){
		var newButton = $(categoryIDs[ID]);
		var oldButton = $(categoryIDs[activeID]);
		
		var newHeader = $(categoryIDs[ID]+"Headers");
		var oldHeader = $(categoryIDs[activeID]+"Headers");

		SetActiveButton(newButton, true);
		SetActiveButton(oldButton, false);
		
		SetActiveColumnHeader(newHeader, true);
		SetActiveColumnHeader(oldHeader, false);
		
		activeID = ID;
		UpdatePlayers(ID);
	};
};

function SetActiveButton(button, state){
	button.SetHasClass("Active", state);
	button.SetHasClass("Idle", !state);
};

function SetActiveColumnHeader(header, state){
	header.SetHasClass("visible", state);
	header.SetHasClass("collapse", !state);	
};

function UpdatePlayers(ID){
	var playerIDList = Game.GetAllPlayerIDs();
	for(var playerID of playerIDList){
		var player = PlayerContainer.GetChild(playerID);
		player.UpdateState(ID);
	};
};

var PlayerContainer = $("#PlayerContainer");
function CreatePlayers(){
	var playerIDList = Game.GetAllPlayerIDs();
	for(var playerID of playerIDList){
		var newPlayer = $.CreatePanel("Panel", PlayerContainer, playerID);
		newPlayer.state = activeID;
		newPlayer.PlayerID = playerID;
		newPlayer.BLoadLayout( "file://{resources}/layout/custom_game/end_screen_player.xml", false, false);
	};
};

function FinishGame(){
	Game.FinishGame();
};

function SetupFooter(){
	var time = GameDuration();
	 $("#ElapsedTime").text = "Elapsed Time:  "+time;
};

function GameDuration(){ 
	var time = Math.round(Game.GetDOTATime(false, false));
	var minutes = SecondsToMinutes(time);
	var seconds = time - (minutes * 60);
	return ( minutes+":"+seconds );
};

function SecondsToMinutes(time){
	return ( (time - (time % 60)) / 60 );
};

var bodyHeader = $("#BodyHeader");
function SetupColumnHeaderChildSizes(){ 
	$.Msg("Setting content width");
	var bodyHeaderChildCount = bodyHeader.GetChildCount();
	for(var i=1; i < bodyHeaderChildCount; i++){
		var child = bodyHeader.GetChild(i);
		var childCount = child.GetChildCount();
		
		// there's about 5-10% of width getting used for margin pushes
		var sizePerChild = 90 / childCount;
		for(var j=0; j < childCount; j++){
			child.GetChild(j).style["width"] = sizePerChild+"%";
		};
	};
};

(function () {
	SetupColumnHeaderChildSizes();
	SetupFooter();
	CreatePlayers();
	
	GameEvents.SendCustomGameEventToServer("endscreen_request_data", {});
})();