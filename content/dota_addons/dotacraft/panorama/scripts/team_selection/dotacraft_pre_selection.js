var PlayerContainer = $("#PlayerListContainer")
var Root = $.GetContextPanel()
var System;
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

// table used to store the colors
var dotacraft_Colors = {};

var current_TeamIndex = 0;
var current_ColorIndex = 0; 
var DEVELOPER = false; 

///////////////////////////////////////////////
// 					Buttons			 		 //
///////////////////////////////////////////////

function Toggle_Host_Container(){
	var container = Root.FindChildTraverse("HostContainer")	
	if(!container.BHasClass("Closed")){
		container.AddClass("Closed");
	}else{
		container.ToggleClass("Closed");
	};
};

function LockTeams()
{
	// set lockstate == true/false for all panels
 
}; 

///////////////////////////////////////////////
// 		Player Panel State Management		 //
///////////////////////////////////////////////

// function which handles the player panel status
function Player_Status(PlayerID, enabled, ready){
	// find panel and sethasclass
	var PlayerPanel = PlayerContainer.FindChildTraverse(PlayerID);
	PlayerPanel.SetHasClass("Ready", ready);
	
	//$.Msg("Player "+PlayerID+" is ready") 
	
	// find all drop-downs and toggle them
	for(var index in dotacraft_DropDowns){
		var dropdown = PlayerPanel.FindChildTraverse(dotacraft_DropDowns[index]);	
		dropdown.enabled = enabled
	};
	
	// find button and sethasclass
	var button = PlayerPanel.FindChildTraverse("HudButton")
	if(button != null){
		button.SetHasClass("Ready", ready);
	};
};

// main logic behind when everybody is ready
// currently NOT IN USE, this only works when it's based on a "all ready" system
function Ready_Status(){
	var PlayerIDList = Game.GetAllPlayerIDs();
	var AmountOfPlayersReady = 0;
	
	//$.Msg("CHECKING READY STATUS")
	// check all the player panel property .Ready
	for(var PlayerID of PlayerIDList){
		var PlayerPanel = PlayerContainer.FindChildTraverse(PlayerID);
		if(PlayerPanel != null && PlayerPanel.Ready != null){
			if(PlayerPanel.Ready){
				AmountOfPlayersReady++;
			};  
		};  
	}; 

	// if all players are ready and game hasn't already started, then start the game
	if(AmountOfPlayersReady == PlayerIDList+1 && !Root.Game_Started && !Root.CountDown){
		Start_Game(); 
	};   
};   

///////////////////////////////////////////////
// 		Create & Update Player Logic	 	 //
///////////////////////////////////////////////
// dotacraft pregame table =
// key = PanelID
// playerID = current assigned player ID
// color = current color Index
// team = current team Index
// race = current race index

function CheckAndCreateCurrentPlayers(){
	var NetTable = CustomNetTables.GetAllTableValues( "dotacraft_pregame_table" );
	var LocalPlayerID = Game.GetLocalPlayerID();  

	if( NetTable != null ){ 
		for(var table of NetTable){
			var PlayerID = parseInt(table.value.PlayerIndex);
			
			var PanelID = parseInt(table.key);
			var PlayerPanel = System.assignPlayer(PlayerID, PanelID);

			// Assign panel teamIndex and Color
			PlayerPanel.PlayerID = PlayerID;
			PlayerPanel.PlayerTeam = parseInt(table.value.Team);
			PlayerPanel.PlayerColor = parseInt(table.value.Color);
			PlayerPanel.Race = parseInt(table.value.Race);
		};
	};
};

function AssignYourself(){
	var LocalPlayerID = Game.GetLocalPlayerID();
	
	if( !System.isPlayerAssigned(LocalPlayerID) ){
		var PlayerPanel = System.assignPlayer(LocalPlayerID);
		$.Msg("PlayerPanel ="+PlayerPanel);

		// Assign panel teamIndex and Color
		PlayerPanel.PlayerID = LocalPlayerID;
		PlayerPanel.PlayerTeam = current_TeamIndex;
		PlayerPanel.PlayerColor = current_ColorIndex;
		
		// increment current team index
		Increment_Variables();
		 
		// send new player Information
		GameEvents.SendCustomGameEventToServer("update_pregame", {"PlayerID" : LocalPlayerID, "PanelID" : PlayerPanel.PanelID, "Team" : PlayerPanel.PlayerTeam, "Color" : PlayerPanel.PlayerColor, "Race" : 0});
	};
}; 

function CheckForHostprivileges(){
	if( isHost() ){
		// set the start button visible to the host
		var Force_Start_Button = Root.FindChildTraverse("StartButton");
		Force_Start_Button.visible = true;

		// enable host panel 
		var Host_Panel = Root.FindChildTraverse("HostPanel");
		Host_Panel.visible = true;
		
		System.setFullControl(true);
	};
};

function Update(){ 
	CheckCurrentSpectators(); 
	UpdateCurrentSpectators();
	$.Schedule(0.1, Update); 
};

var SpectatorRoot = $("#SpectatorListContainer");
var Spectators = new Array();
function CheckCurrentSpectators(){
	Spectators = Game.GetAllPlayerIDs();

	for(var Panel of System.getAllPanels()){
		if( Players.IsValidPlayerID(Panel.PlayerID) ){
			var Index = Spectators.indexOf(Panel.PlayerID)
			Spectators.splice(Index, 1);
		};
	};
};

function UpdateCurrentSpectators(){
	var PlayerIDList = Game.GetAllPlayerIDs();
	var SpectatorContainer = SpectatorRoot.FindChildTraverse("SpectatorContainer");

	for(var PlayerID of PlayerIDList){
		if( SpectatorContainer.FindChildTraverse(PlayerID) == null ){
			var PlayerLabel = $.CreatePanel("Label", SpectatorContainer, PlayerID);
			var PlayerName = Game.GetPlayerInfo(PlayerID).player_name;
			PlayerLabel.text = PlayerName;
			PlayerLabel.SetHasClass("Spectator", true);
		};
		
		var PlayerPanel = SpectatorContainer.FindChildTraverse(PlayerID);
		if( !Spectators.indexOf(PlayerID) )
			PlayerPanel.visible = true;
		else
			PlayerPanel.visible = false;
	};
};

function SetupPreGame(){
	// check for new players, this also sets up the $.Schedule inside the function
	CheckAndCreateCurrentPlayers(); 
	
	// assign local playerid to a panel
	AssignYourself(); 
	
	// check if host, if true enable buttons
	CheckForHostprivileges(); 
	Update()
};


///////////////////////////////////////////////
// 				Game Start Logic			 //
///////////////////////////////////////////////

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
	var Button = Root.FindChildTraverse("StartButton");
	Button.enabled = false;
	
	// disable player panel
	var PlayerID = Game.GetLocalPlayerID();
	Player_Status(PlayerID, false, false);
	
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

function FindLocalPlayerTeamID(){
	var TeamID = 3;
	for(var Panel of System.getAllPanels()){
		if( Panel.PlayerID == Game.GetLocalPlayerID() )
			TeamID = Panel.PlayerTeam;
	};
	return TeamID;
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

function Developer_Mode(args){
	if(args.developer){
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

function Setup_Minimap(){
	var Map_Info = Game.GetMapInfo()
	var Map_Name = Map_Info.map_display_name.substring(2);
	
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
 
(function () {
	// default to spectator
	Game.PlayerJoinTeam(3)
	
	GameEvents.Subscribe( "panaroma_developer", Developer_Mode );
	//GameEvents subscribes
	GameEvents.Subscribe( "dotacraft_skip_selection", Skip_Selection );
	
	Root.CountDown = false; 
	Root.Game_Started = false;

	// setup function calls
	Setup_Panaroma_Color_Table(); 
	Setup_Minimap(); 
	
	Game.SetAutoLaunchEnabled(false);
	Game.SetRemainingSetupTime(999);
    Game.SetTeamSelectionLocked(true); 
 
	var MapPlayerLimit = parseInt(Game.GetMapInfo().map_display_name.substring(0,1));
	if( MapPlayerLimit == null ){
		$.Msg("[Pre-Game] Map Name is invalid, unable to determine Player Limit, defaulting to 8");
		MaxPlayerLimit = 8;
	};
	
	var ContainerRoot = $('#PlayerListContainer'); 
	System = new TeamSelection(ContainerRoot, MapPlayerLimit, dotacraft_DropDowns, dotacraft_Teams);
	
	SetupPreGame(); 
})(); 

///////////////////////////////////////////////
// 				Useful Functions			 //
///////////////////////////////////////////////

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
// increment team and color index variables
function Increment_Variables(){
	if(current_TeamIndex >= Length(dotacraft_Teams)){ 
		current_TeamIndex = 0;
	}
	else{ 
		current_TeamIndex++;
	};
	
	if(current_ColorIndex >= Length(dotacraft_Colors)){
		current_ColorIndex = 0;
	}
	else{
		current_ColorIndex++;
	};
}

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

function Boolise(index){
	if(index == 0){
		return false;
	}else{
		return true;
	};
};