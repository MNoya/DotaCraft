var categoryIDs = {
	1 : "#Overview",
	2 : "#Units",
	3 : "#Heroes",
	4 : "#Resources"
};

var WINNING_TEAM_BORDER_COLOR = "gold"

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

var localPlayerID = Game.GetLocalPlayerID();
var playerInfo = Game.GetPlayerInfo(localPlayerID);
var teamColors = false;
function ToggleTeamColors(){
	var teamID = playerInfo.player_team_id;
	
	// toggle team color state
	teamColors = !teamColors;

	// allied team members
	var allies = Game.GetPlayerIDsOnTeam(teamID);
	for(var playerID of allies){
		var player = PlayerContainer.GetChild(playerID);
		player.SetTeamColor(teamColors, true)
	};
	
	// enemies, detected by checking if they're not indexOf allies list
	var playerIDList = Game.GetAllPlayerIDs();
	for(var playerID of playerIDList){	
		if( allies.indexOf(playerID) == -1){
			player.SetTeamColor(teamColors, false);
		};
	};
};

function SetWinningTeamBorders(){
	var winningTeam = Game.GetGameWinner();

	// allied team members
	var allies = Game.GetPlayerIDsOnTeam(winningTeam);
	for(var playerID of allies){
		var player = PlayerContainer.GetChild(playerID);
		player.style["border"] = "5px solid "+WINNING_TEAM_BORDER_COLOR;
	};
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

function SortByTeam(){
	var Container = PlayerContainer;
	$.Msg("Sorting child of panel: "+Container.id);
	for(var i =0; i < Container.GetChildCount(); i++){
		
		var playerInfo = Game.GetPlayerInfo(i);
		var teamID = playerInfo.player_team_id;

		for(var j=0; j < Container.GetChildCount() - 1; j++){
			var child = Container.GetChild(i);
			var child2 = Container.GetChild(i+1);

			var playerInfo2 = Game.GetPlayerInfo(j);
			var teamID2 = playerInfo2.player_team_id;		

			if( child2 != null ){
				if( teamID > teamID2 ){
					Container.MoveChildAfter(child, child2);
				};
			};
			
		};
	};
};

function SortPlayersByColumn(columnID){
	
	var Container = PlayerContainer;
	$.Msg("Sorting child of panel: "+Container.id);
	for(var i =0; i < Container.GetChildCount(); i++){
		for(var j=0; j < Container.GetChildCount() - 1; j++){
			var child = Container.GetChild(i);
			var child2 = Container.GetChild(i+1);
			
			var playerInfo = child.data;
			var playerInfo2 = child2.data;

			if( child2 != null ){
				var isLower = CheckColumnValue(columnID, playerInfo, playerInfo2)
				$.Msg(isLower)
				if( isLower ){
					Container.MoveChildAfter(child, child2);
				};
			};
			
		};
	};	
	
};

function CheckColumnValue(columnID, data1, data2){
	switch(columnID){		
		case 1:
			return (data1.unit_score <= data2.unit_score);
			break;
		case 2:
			return (data1.hero_score <= data2.hero_score);		
			break;
		case 3:
			return (data1.resource_score <= data2.resource_score);			
			break;
		case 4:
			return (data1.total_score <= data2.total_score);			
			break;
			
		case 5:
			return (data1.units_produced <= data2.units_produced);		
			break;
		case 6:
			return (data1.units_killed <= data2.unit_killed);
			break;
		case 7:
			return (data1.buildings_produced <= data2.buildings_produced);
			break;
		case 8:
			return (data1.buildings_razed <= data2.buildings_razed);	
			break;
		case 9:
			return (data1.largest_army <= data2.largest_army);
			break;
			
		case 10:
			return true
			break;
		case 11:
			return (data1.heroes_killed <= data2.heroes_killed);
			break;
		case 12:
			return (data1.items_obtained <= data2.items_obtained);
			break;
		case 13:
			return (data1.mercenaries_hired <= data2.mercenaries_hired);
			break;
		case 14:
			return (data1.experienced_gained <= data2.experienced_gained);
			break;
			
		case 15:
			return (data1.gold_mined <= data2.gold_mined);
			break;
		case 16:
			return (data1.lumber_harvested <= data2.lumber_harvested);
			break;		
		case 17:
			return (data1.resource_traded <= data2.resource_traded);
			break;
		case 18:
			return (data1.tech_percentage <= data2.tech_percentage);
			break;
		case 19:
			return (data1.gold_lost_to_upkeep <= data2.gold_lost_to_upkeep);
			break;
	};
	
};

function SortChildren( Container ){
	$.Msg("Sorting child of panel: "+Container.id);
	for(var i =0; i < Container.GetChildCount(); i++){
		for(var j=0; j < Container.GetChildCount() - 1; j++){
			var child = Container.GetChild(i);
			var child2 = Container.GetChild(i+1);
			
			if( child2 != null ){
				if( child.index > child2.index ){
					Container.MoveChildAfter(child, child2);
				};
			};
		};
	};
};

(function () {
	SetupColumnHeaderChildSizes();
	SetupFooter();
	CreatePlayers();
	SetWinningTeamBorders();
	
	GameEvents.SendCustomGameEventToServer("endscreen_request_data", {});
})();