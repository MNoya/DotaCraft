var PlayerContainer = $("#PlayerListContainer");
var SpectatorRoot = $("#SpectatorListContainer");
var Root = $.GetContextPanel();
var LocalPlayerID = Game.GetLocalPlayerID(); 

///////////////////////////////////////////////
// 			Local Variables & Tables		 //
///////////////////////////////////////////////

// table of all the dropdowns
var dotacraft_DropDowns = {
	1: "ColorDropDown",
	2: "TeamDropDown",
	3: "RaceDropDown"
};

// table of all the buttons
var dotacraft_Buttons = {
	1: "HudButton"
};
 
//table for all team id's
var dotacraft_Teams = {
	0: 2,
	1: 3,
	2: 6,
	3: 7,
	4: 8,
	5: 9
};

var ROUND_TIME = 120;
var currentTime = ROUND_TIME;
function HandleRoundTime(data){
	var time = data.Time;
	Root.FindChildTraverse("RoundTimer").text = "Round Time: "+time+"s";
	
	if ( time <= 0 ){
		Start_Game();
		Root.FindChildTraverse("RoundTimer").visible = false;
	};		
};

// table used to store the colors
var dotacraft_Colors = {};

var current_TeamIndex = 0;
var current_ColorIndex = 0; 
var DEVELOPER = false; 
var MAP_PLAYER_LIMIT;
(function () {
	// default everyone to radiant
	Game.PlayerJoinTeam(2);

	Developer_Mode();	
	Root.CountDown = false; 
	Root.Game_Started = false;

	Game.SetAutoLaunchEnabled(false);
	Game.SetRemainingSetupTime(99999);
    Game.SetTeamSelectionLocked(true); 
 
	MAP_PLAYER_LIMIT = parseInt(Game.GetMapInfo().map_display_name.split("_",1));
	if( MAP_PLAYER_LIMIT == null ){
		$.Msg("[Pre-Game] Map Name is invalid, unable to determine Player Limit, defaulting to 8");
		MAP_PLAYER_LIMIT = 8;
	};
	
	SetupTeamContainers();

	SetupLocalisation();
	Setup_Panaroma_Color_Table(); 
	SetupTeamDropDown();
	Setup_Minimap();	
	CreateAllPlayers(); 
	CheckForHostprivileges();
	var roundTimer = $.CreatePanel("Label", Root.FindChildTraverse("NotificationContainer"), "RoundTimer");
	$.Schedule(1, Update);
	
	//GameEvents subscribes 
	GameEvents.Subscribe( "dotacraft_skip_selection", Skip_Selection );
	GameEvents.Subscribe( "pregame_event", HandleEvents );
})();

function SetupLocalisation(){
	Root.FindChildTraverse("CreateBotText").text = $.Localize("button_create_bot");
	//Root.FindChildTraverse("LockPlayerLabel").text = $.Localize("toggle_lock_players");
	Root.FindChildTraverse("Host_Header").text = $.Localize("host_header");
	Root.FindChildTraverse("map_description_header").text = $.Localize("map_description")
	Root.FindChildTraverse("suggested_players_header").text = $.Localize("suggested_players");
};
 
function HandleEvents(data){
	var event = data.Event_Name;
	var updateTable = data.Info;
	
	//$.Msg("recieved event: "+event);
	
	if( event == "delete_bot" )
		DeletePlayer(updateTable);
	else if( event == "lock_players" )
		UpdatePlayerLock(updateTable);
	else if( event == "create_bot" )
		CreateBotLocally(updateTable);
	else if( event == "pregame_start" ) 
		Start_Game();
	else if( event == "roundtimer_update" )
		HandleRoundTime(updateTable);
};

function SendEventToServer(eventName, updateTable){
	GameEvents.SendCustomGameEventToServer("send_pregame_event", { "Event_Name": eventName, "Info" : updateTable});	
};

function DeletePlayer(data){
	var playerPanel = FindPlayerByPanelID(data.ID);

	if( playerPanel != null ){
		//$.Msg("Deleting player:"+playerPanel.PlayerID+" on panel: "+playerPanel.PanelID);
		playerPanel.DeleteAsync(0.1);		
	};
};

///////////////////////////////////////////////
// 					Buttons			 		 //
///////////////////////////////////////////////
function DisplayBotPopUp(){
	var newPlayerID = SelectBotPlayerID();
	if( newPlayerID <= MAP_PLAYER_LIMIT ){
		$('#BotOptions').ToggleClass("hidden");
	}else{
		CreateNotification("MAX BOT COUNT REACHED");
	};
};

function CreateBot(teamID)
{
	var newPlayerID = SelectBotPlayerID();
	if( newPlayerID <= MAP_PLAYER_LIMIT ){
		//var newTeamID = SelectedTeamIDBasedOnSmallestTeam();
		var newTeamID = parseInt(teamID);
		var newColorID = SelectUnusedColor();
		//var newColorID = 1;
		CreateBotLocally({ "ID" : newPlayerID, "TeamID" : newTeamID, "ColorID": newColorID, "invokingPlayerID": -1 });
		SendEventToServer("create_bot", { "ID" : newPlayerID, "TeamID" : newTeamID, "ColorID": newColorID, "invokingPlayerID": LocalPlayerID });
	}
};

function BotTeamSpecified(){
	var panel = Root.FindChildTraverse("TeamDropDown")
	if( panel.GetSelected().id != 0 ){
		CreateBot( panel.GetSelected().id );
		$('#BotOptions').ToggleClass("hidden");
		panel.SetSelected(0);
	}
};

function SelectBotPlayerID(){
	var botPlayerID = 0;
	var netTable = CustomNetTables.GetAllTableValues( "dotacraft_pregame_table" );
	
	for(k in netTable){
		if( netTable[k].value.Team == null ){
			return parseInt(k);
		};
	};
	return CurrentPlayersInGame();
};

// note: does not have to panelID, playerID also works with current system, panelID never gets changed.
PlayerContainer.HandlePanelDeletion = function(playerIDToDelete, panelID){
	// possible additions to come if ever :p
	DeletePlayerByPanelID(panelID);
};

function DeletePlayerByPanelID(panelID){
	SendEventToServer("delete_bot", {"ID" : panelID});
	GameEvents.SendCustomGameEventToServer("update_pregame", { "ID" : panelID, "Info" : {isNull : 1} });	
};

function CreateBotLocally(data){
	var newPlayerID = data.ID;
	
	if( FindPlayer(newPlayerID) == null && data.invokingPlayerID != LocalPlayerID ){
		Game.EmitSound("Building.Placement");
		var teamID = data.TeamID;
		var colorID = data.ColorID;
		var TeamContainer = Root.FindChildTraverse("Team_"+teamID);
		
		var PlayerPanel = $.CreatePanel("Panel", TeamContainer, "Player_"+newPlayerID);
		PlayerPanel.BLoadLayout("file://{resources}/layout/custom_game/pre_game_player.xml", false, false);
		
		PlayerPanel.Init(newPlayerID, teamID, colorID, 0, false);
		PlayerPanel.SetBot(1);
	}else
		$.Msg("[ERROR] REQUEST RECIEVED TO CREATE A PLAYER PANEL THAT ALREADY EXIST OR PLAYER IS HOST(IGNORE IF THIS IS TRUE)");
};

function SelectedTeamIDBasedOnSmallestTeam(){
	var TeamID = -1;
	var TeamCount = 0;
	for(var i = PlayerContainer.GetChildCount()-1; i >= 0 ; i--){ // loop through all the teams
		var teamPanel = PlayerContainer.GetChild(i);
		
		if( TeamID == -1 || (teamPanel.GetChildCount()-1) <= TeamCount ){ // we take 1 away cause of label.
			TeamID = i+1; // save team ID
			TeamCount = teamPanel.GetChildCount()-1; // save team length
		};
	};		
	return TeamID;
};

function SelectUnusedColor(){
	var netTable = CustomNetTables.GetAllTableValues( "dotacraft_pregame_table" );
	
	var selectedColor = -1;
	for(var i in dotacraft_Colors){ // loop through all available colours
		var colorInUse = false;
		if(selectedColor != -1) // break if selectedColor is not -1(means something was assigned on last iteration)
			break;
		
		for(var j in netTable){ // check if colour is already being used by another player(nettable)
			if(i == netTable[j].value.Color)
				colorInUse = true;
		};
		
		if( !colorInUse ) // if color is not in use, return this index
			selectedColor = i;
	};	
	return selectedColor;
};

function SetupTeamContainers(){
	for(var i =1; i < MAP_PLAYER_LIMIT+1; i+=1){
		var TeamContainer = $.CreatePanel("Panel", PlayerContainer, "Team_"+i);
		TeamContainer.TeamID = i;
		TeamContainer.AddClass("TeamContainer");

		TeamContainer.SetPanelEvent('onactivate', function(caller){
			return function(){
				var foundPlayerPanel = FindPlayer(LocalPlayerID);

				if( foundPlayerPanel != null && !foundPlayerPanel.Ready )
					foundPlayerPanel.SetTeam(caller.TeamID);			
			}
		}(TeamContainer));
	
		var label = $.CreatePanel("Label", TeamContainer, "Team_Label");
		label.AddClass("TeamLabel");
		label.text = i;
	};
};
 
function FindPlayer(playerID){
	return PlayerContainer.FindChildTraverse("Player_"+playerID);
};

function FindPlayerByPanelID(panelID){
	for(var i = 0; i < PlayerContainer.GetChildCount(); i+=1){ // loop through all the teams
		var teamPanel = PlayerContainer.GetChild(i);
		if( teamPanel == null )
			continue;
		for(var j = 1; j < teamPanel.GetChildCount(); j +=1){ // start at 1 - so to avoid the label
			var panel = teamPanel.GetChild(j);		
			if( panel.PanelID == panelID ) // get the child from the team panel and compare panel ID's
				return panel;
		};
	};
	return null;
};

function CurrentPlayersInGame(){
	var netTable = CustomNetTables.GetAllTableValues( "dotacraft_pregame_table" );

	var playerCount = 0;
	for (k in netTable){
		if( netTable[k].value.Team != null )
			playerCount += 1;
	};

	return playerCount;
};

function PlayerIDFromNetTable(){
	var netTable = CustomNetTables.GetAllTableValues( "dotacraft_pregame_table" );

	for (k in netTable){
		if( netTable[k].value.Team !== null )
			playerCount += 1;
	};	
};
/*
function CheckAndCreateTeamContainer(teamID){
	var TeamContainer = PlayerContainer.FindChildTraverse("Team_"+teamID);
	if ( TeamContainer == null ){
		TeamContainer = $.CreatePanel("Panel", PlayerContainer, "Team_"+teamID);
		TeamContainer.AddClass("TeamContainer");
	
		var label = $.CreatePanel("Label", TeamContainer, "Team_Label");
		label.AddClass("TeamLabel");
		label.text = "Team "+teamID;
	}; 
	return TeamContainer;
};*/

function Toggle_Host_Container(){
	var container = Root.FindChildTraverse("HostContainer")	
	if(!container.BHasClass("Closed")){
		container.AddClass("Closed");
	}else{
		container.ToggleClass("Closed");
	};
};

var LockState = false;
function LockPlayers(){
	var LockState = $("#LockPlayers").checked;
	SendEventToServer("lock_players", {Lock : LockState})
};

function UpdatePlayerLock(data){
	var locked = data.Lock

	// update lockstate
	for(var i = 0; i < CurrentPlayersInGame() ;i+=1)
	{
		FindPlayer(i).Lock(locked);
	};
}; 

///////////////////////////////////////////////
// 		Player Panel State Management		 //
///////////////////////////////////////////////

// main logic behind when everybody is ready
// currently NOT IN USE, this only works when it's based on a "all ready" system
function Ready_Status(){
	//$.Msg("CHECKING READY STATUS")
	// check all the player panel property .Ready
	var everyoneReady = true;
	var playerCount = 0;
	for(var i = 0; i <= MAP_PLAYER_LIMIT; i++){
		var PlayerPanel = FindPlayer(i);
		if(PlayerPanel != null){
			playerCount += 1;
			if( !PlayerPanel.PlayerReady){
				everyoneReady = false;
			};  
		};  
	}; 

	// if all players are ready and game hasn't already started, then start the game
	if( (everyoneReady && playerCount > 0) && !Root.Game_Started && !Root.CountDown){
		Start_Game();
		LockEverything();
	};   
};  

function LockEverything(){
	for(var i = 0; i <= MAP_PLAYER_LIMIT; i++){
		var PlayerPanel = FindPlayer(i);
		
		if( PlayerPanel != null )
			PlayerPanel.LockEverything();
	};
	
	Root.FindChildTraverse("CreateBot").enabled = false;
};

function Update(){
	Ready_Status();
	$.Schedule(1, Update);
};

///////////////////////////////////////////////
// 		Create & Update Player Logic	 	 //
///////////////////////////////////////////////
// dotacraft pregame table =
// playerID = current assigned player ID
// color = current color Index
// team = current team Index
// race = current race index

function CreateAllPlayers(){
	var playerTable = CustomNetTables.GetAllTableValues("dotacraft_pregame_table");
	
	var listOfPlayersInNettable = new Array();
	for(var playerID in playerTable){
		var playerDetails = playerTable[playerID].value;
		$.Msg("creating player #"+playerID);
		$.Msg(playerTable[playerID]);
		$.Msg(playerDetails);
		if( playerDetails.isNull == null){ // if isnull doesn't exist it means the nettable is not null
			$.Msg("valid nettable for player");
			var TeamContainer = Root.FindChildTraverse("Team_"+playerDetails.Team);
			var PlayerPanel = $.CreatePanel("Panel", TeamContainer, "Player_"+playerID);
			PlayerPanel.BLoadLayout("file://{resources}/layout/custom_game/pre_game_player.xml", false, false);
 
			PlayerPanel.Init(parseInt(playerID), parseInt(playerDetails.Team), parseInt(playerDetails.Color), parseInt(playerDetails.Race), parseInt(playerDetails.Ready));
			if( playerDetails.aiLVL != null )
				PlayerPanel.SetBot(playerDetails.aiLVL);
			
			
			listOfPlayersInNettable.push(parseInt(playerID));
		};
	};
	
	var playerIDs = Game.GetAllPlayerIDs();
	for(var playerIDInList of playerIDs){ // create all players from player id list that was not previously created by the nettable
		if(	!Contains(listOfPlayersInNettable, playerIDInList) ){
			var playerID = playerIDInList;
			var teamID = SelectedTeamIDBasedOnSmallestTeam();
			var colorID = playerID;
			var TeamContainer = Root.FindChildTraverse("Team_"+teamID);
		
			var PlayerPanel = $.CreatePanel("Panel", TeamContainer, "Player_"+playerID);
			PlayerPanel.BLoadLayout("file://{resources}/layout/custom_game/pre_game_player.xml", false, false);

			PlayerPanel.Init(playerID, teamID, colorID, 0, false);		
		};
	};
};

function Contains(array, item){
	return ( array.indexOf(item) != -1 );
};

function CheckForHostprivileges(){
	if( isHost() ){
		// set the start button visible to the host
		//var Force_Start_Button = Root.FindChildTraverse("StartButton");
		//Force_Start_Button.visible = true;

		// enable host panel 
		var Host_Panel = Root.FindChildTraverse("HostPanel");
		Host_Panel.visible = true;
		
		// SET HERE PREMISSIONS THAT HOST SHOULD HAVE
	};
};

///////////////////////////////////////////////
// 				Game Start Logic			 //
///////////////////////////////////////////////

function InitStartGame(){ 
	SendEventToServer("pregame_start", {});
};

// if everyone is ready this will be called
// essentially tells lua that the selection is over and sets the setup time to 0
function Start_Game(){
	$.Msg("Game Starting");
	//$.Msg(Root.CountDown)
	//$.Msg(Root.Game_Started)
	
	if(DEVELOPER){ 
		Initiate_Game();
		return;
	};
	
	// disable start button
	//var Button = Root.FindChildTraverse("StartButton");
	//Button.enabled = false;
	
	// set time left incase the button is pressed again
	Root.time_left = 3;
	
	//setup countdown
	CountDown();
};

function Initiate_Game(){
	// set Game_Started state to true
	Root.Game_Started = true;
	
	Root.DeleteAsync(0.1);
	
	$.Msg("Everyone is ready");	
	// this will make the game_setup state go further and tells lua about this and then makes players
	Game.SetRemainingSetupTime(0);
	GameEvents.SendCustomGameEventToServer("selection_over", {});
};

function CreateNotification(inputText){
	// create header
	var Timer_Header = $.CreatePanel("Label", Root.FindChildTraverse("NotificationContainer"), "CountDownHeader");
	Timer_Header.text = "ERROR: " + inputText;

	// delete after 1 second
	Timer_Header.DeleteAsync(2);		
};

// simple timer function
function CountDown(){
	$.Msg("Countdown Time: "+Root.time_left);
	// set countdown true so that this function will start scheduling itself
	Root.CountDown = true;
	
	var Left_Bar = Root.FindChildTraverse("Left_Bar");
	
	// create header
	var Timer_Header = $.CreatePanel("Label", Left_Bar, "CountDownHeader");
	Timer_Header.text = "Map starts in:";

	//create text
	var Timer_Text = $.CreatePanel("Label", Left_Bar, "CountDown");
	if(Root.time_left != 0){
		Timer_Text.text = Root.time_left;
	}else{
		Timer_Text.text = "GL & HF";
	};
	// delete after 1 second
	Timer_Text.DeleteAsync(1);
	
	// if time left is 0 then
	if(Root.time_left == 0){
		$.Msg("STARTING GAME NOW");
		Root.CountDown = false;
		Root.Game_Started = false;
	
		// start game
		$.Schedule(1, Initiate_Game);
	}else{
		Root.time_left--;	
	};
	
	// if countdown is true and game hasn't started THEN schedule
	if(Root.CountDown && !Root.Game_Started){
		$.Schedule(1, CountDown);
	};
};

///////////////////////////////////////////////
// 				Setup & Commands			 //
///////////////////////////////////////////////

function Developer_Mode(){
	if (CustomNetTables.GetTableValue("dotacraft_settings", "developer").value == true){
		$.Msg("[Panaroma Developer Mode]");
		DEVELOPER = true;
	}else{
		Developer = false;
	};
};

// this is a function called by a command from console "skip_selection"
// it essentially forces the ready up stage and sends in current information
// PURELY DEBUG
function Skip_Selection(data){
	$.Msg("Everyone is ready");
	
	Game.SetRemainingSetupTime(0);
	GameEvents.SendCustomGameEventToServer("selection_over", {});
};

function Setup_Panaroma_Color_Table(){    
	// store color table inside this var
	var Colors = CustomNetTables.GetAllTableValues("dotacraft_color_table");

	// loop and add the Colors table to the local color table
	for (var key in Colors) {   
		dotacraft_Colors[key] = { r: Colors[key].value.r, g: Colors[key].value.g, b: Colors[key].value.b, "taken": false };
	};
};    

function SetupTeamDropDown(){ // enable dropdown menu children count to player count
	var dropdown = Root.FindChildTraverse("TeamDropDown");

	var count = MAP_PLAYER_LIMIT;
 
	// init first child
	dropdown.FindDropDownMenuChild(0).text = $.Localize("team_select");
	dropdown.SetSelected(0);
	dropdown.GetChild(0).text = $.Localize("team_select");
	
	for (i = 1; i <= count; i++) {
		var dropdown_child = dropdown.FindDropDownMenuChild(i);
		dropdown_child.SetHasClass('hidden', false);
		dropdown_child.text = $.Localize("team") + " " + i;
	};
};  
  
function Setup_Minimap(){ 
	var Map_Info = Game.GetMapInfo()
	var Map_Name = Map_Info.map_display_name.substring(Map_Info.map_display_name.indexOf('_')+1);
	
	var Minimap_Panel = Root.FindChildTraverse("Minimap");
	var Minimap_Name = Root.FindChildTraverse("Minimap_Name");
	var Suggested_Players = Root.FindChildTraverse("Suggested_Players_Text");
	var Map_Description = Root.FindChildTraverse("Map_Description_Text");
	
	var Minimap_Image_Path = "url('file://{images}/selection/maps/"+Map_Name+".png');";
	//$.Msg(Minimap_Image_Path)
	 
	// set minimap image path
	Minimap_Panel.style["background-image"] = Minimap_Image_Path;
	// set minimap name text
	Minimap_Name.text = Map_Name;
	
	//localized strings from addon
	Suggested_Players.text = $.Localize("#"+Map_Name+"_suggested_players");
	Map_Description.text = $.Localize("#"+Map_Name+"_map_description");
};

function Length(Panel){
	var No_End = 1;
	for (i = 0; i <= No_End; i++) {	
		// if the current index wasn't a valid child, current index-1 is the total amount of children
		// this assumes you index from 0 - something
		if(Panel[i] == null){ 
		//$.Msg("length is:" +(i-1))
			return y = i-1;
			break; 
		};
		 
		No_End++;
	};
};

// check if player is host
function isHost(){
    var Player_Info = Game.GetPlayerInfo(Game.GetLocalPlayerID())

    if(!Player_Info)
    {
		//$.Msg("Player does not exist = #"+PlayerID);
        return false;
    }; 

    return Player_Info.player_has_host_privileges; 
}