var PlayerContainer = $("#PlayerListContainer")
var Root = $.GetContextPanel()

///////////////////////////////////////////////
// 			Local Variables & Tables		 //
///////////////////////////////////////////////

// table of all the dropdowns
var dotacraft_DropDowns = {
	1: "ColorDropDown",
	2: "TeamDropDown",
	3: "RaceDropDown"
}

// table of all the buttons
var dotacraft_Buttons = {
	1: "HudButton"
} 

//table for all team id's
var dotacraft_Teams = {
	0: 2,
	1: 3,
	2: 6,
	3: 7,
	4: 8,
	5: 9
}

// table used to store the colors
var dotacraft_Colors = {}

var current_TeamIndex = 0
var current_ColorIndex = 0
var DEVELOPER = false

///////////////////////////////////////////////
// 		Player Panel State Management		 //
///////////////////////////////////////////////

// function which handles the player panel status
function Player_Status(PlayerID, enabled, ready){
	// find panel and sethasclass
	var PlayerPanel = PlayerContainer.FindChildTraverse(PlayerID)
	PlayerPanel.SetHasClass("Ready", ready)
	
	//$.Msg("Player "+PlayerID+" is ready") 
	
	// find all drop-downs and toggle them
	for(var index in dotacraft_DropDowns){
		var dropdown = PlayerPanel.FindChildTraverse(dotacraft_DropDowns[index])	
		Toggle_Enabled_Panel(dropdown, enabled) 
	}
	
	// find button and sethasclass
	var button = PlayerPanel.FindChildTraverse("HudButton")
	if(button != null){
		button.SetHasClass("Ready", ready)
	}
	
	// we only want the host panel when he is not ready
	if(Game.GetLocalPlayerID() == PlayerID)
	{
		PlayerPanel.SetHasClass("Local", !ready)
	}
}

function Player_Spectator_Status(PlayerPanel){
	
	
}

// main logic behind when everybody is ready
// currently NOT IN USE, this only works when it's based on a "all ready" system
function Ready_Status(){
	var PlayerIDList = Game.GetAllPlayerIDs()
	var AmountOfPlayersReady = 0
	
	//$.Msg("CHECKING READY STATUS")
	// check all the player panel property .Ready
	for(var PlayerID of PlayerIDList){
		var PlayerPanel = PlayerContainer.FindChildTraverse(PlayerID)
		if(PlayerPanel != null && PlayerPanel.Ready != null){
			if(PlayerPanel.Ready){
				AmountOfPlayersReady++;
			}
		}
	}

	// if all players are ready and game hasn't already started, then start the game
	if(AmountOfPlayersReady == PlayerIDList+1 && !Root.Game_Started && !Root.CountDown){
		Start_Game()
	}
}

///////////////////////////////////////////////
// 		Create & Update Player Logic	 	 //
///////////////////////////////////////////////

// this function is called every seconds and creates any new players
// this function also checks the ready status
function CheckForNewPlayers(){
	//$.Msg("checking new players")
	Create_Players() 
	
	// loop this same function every minute
	if(!Root.Game_Started){
		$.Schedule(1, CheckForNewPlayers)
		//$.Schedule(0.5, Ready_Status)
	}
}

// main logic for creating players when connected
function Create_Players(){
	var ContainerRoot = $('#PlayerListContainer') 
	var PlayerIDList = Game.GetAllPlayerIDs()
	var LocalPlayerID = Game.GetLocalPlayerID()
	
	for(var PlayerID of PlayerIDList){	
		
		// check if player panel was already made or not
		if(!IsPlayerPanelCreated(PlayerID)){
			//$.Msg("Creating Player: #" +PlayerID)
			//$.Msg(Game.GetPlayerInfo(PlayerID))

			var PlayerPanel = $.CreatePanel("Panel", ContainerRoot, PlayerID);	
			PlayerPanel.BLoadLayout("file://{resources}/layout/custom_game/pre_game_player.xml", false, false);
			
			// if not local player disable everything and set local panel class to differentiate from others
			if(LocalPlayerID != PlayerID){
				//disable player panel completely
				Player_Status(PlayerID, false, false)
				
				// hide ready button
				var button = PlayerPanel.FindChildTraverse("HudButton")
				if(button != null){
					Toggle_Visibility_Panel(button, false)
				}
			}else{
				PlayerPanel.SetHasClass("Local", true)	
			}
			
			// if player is host
			if(isHost(PlayerID)){
				// add Host panel class to differentiate between host and normal players
				var Name = PlayerPanel.FindChildTraverse("PlayerName")
				var HostIcon = $.CreatePanel("Panel", Name, "Host_Icon");	
				HostIcon.AddClass("Host") 
				
				// set the start button visible to the host
				var Force_Start_Button = Root.FindChildTraverse("StartButton")
				Force_Start_Button.visible = true
			}
			// set initial starting variables + PlayerID
			PlayerPanel.PlayerID = PlayerID
			PlayerPanel.PlayerTeam = dotacraft_Teams[current_TeamIndex]
			PlayerPanel.PlayerColor = current_ColorIndex
			
			Increment_Variables()
		}
	}
} 

// main logic behind updating players, this is called when net_table changed
function Update_Player(TableName, Key, Value){
	// variables 
	var PlayerID = Key
	var ready = Boolise(Value.Ready)

	// PlayerID & Player Panel
	var LocalPlayerID = Game.GetLocalPlayerID()
	var PlayerPanel = PlayerContainer.FindChildTraverse(PlayerID)
	PlayerPanel.Ready = ready
	 
	$.Msg("Player "+PlayerID+" is updating") 
	 
	// find all drop-downs and update their selection
	for(var index in dotacraft_DropDowns){		
		var dropdown = PlayerPanel.FindChildTraverse(dotacraft_DropDowns[index])
		
		// determine which dropdown the current index is, and update accordingly
		if(dotacraft_DropDowns[index] == "ColorDropDown"){
			dropdown.SetSelected(Value.Color) 
		} 
		else if (dotacraft_DropDowns[index] == "TeamDropDown"){ 
			dropdown.SetSelected(Value.Team)
		}
		else if (dotacraft_DropDowns[index] == "RaceDropDown"){
			dropdown.SetSelected(Value.Race)
			
			// if local player change the race background to match the select race
			if(LocalPlayerID == PlayerID){
				SetRaceBackgroundImage(Value.Race)
			}
		}
	}
	
	// disable colors that are already taken
	Update_Available_Colors()
	
	// ready status for local player
	// currently doesn't do anything since the ready state will also be false and !false
	if(PlayerID == LocalPlayerID){
		// toggle the player panel
		Player_Status(PlayerID, !ready, ready) 
	}
}

// function which sets the local background image to that of the race
function SetRaceBackgroundImage(race){
	// if race is not 0, which is the random race
	var Left_Bar = Root.FindChildTraverse("Left_Bar")
	if(race != 0){
		// save image path and then assign it in the style
		var team_path = "url('s2r://panorama/images/selection/background_"+race+".vtex')"
		Left_Bar.style["background-image"] = team_path
	}else{ // if random
		Left_Bar.style["background-image"] = "url('s2r://panorama/images/backgrounds/gallery_background.png')"
	}
}

function Update_Available_Colors(){
	var PlayerIDList = Game.GetAllPlayerIDs()
	var PlayerColors = CustomNetTables.GetAllTableValues("dotacraft_player_table")
	var LocalPlayerID = Game.GetLocalPlayerID()
	
	// for all players
	for(var PlayerID of PlayerIDList){
		var PlayerPanel = PlayerContainer.FindChildTraverse(PlayerID)
		var dropdown = PlayerPanel.FindChildTraverse("ColorDropDown")
		
		// for all players in table
		for(var PlayerID of PlayerIDList){
			// color index to disable
			var color_index = PlayerColors[PlayerID].value.Color

			// find dropdown child
			var dropdown_child = dropdown.FindDropDownMenuChild(color_index) 
			dropdown_child.enabled = false
			dropdown_child.style["border"] = "3px solid black"

		}
	}	
}

///////////////////////////////////////////////
// 				Game Start Logic			 //
///////////////////////////////////////////////

// if everyone is ready this will be called
// essentially tells lua that the selection is over and sets the setup time to 0
function Start_Game(){
	$.Msg("Game Starting")
	//$.Msg(Root.CountDown)
	//$.Msg(Root.Game_Started)

	if(DEVELOPER){
		Initiate_Game()
		return;
	}
	
	// disable start button
	var Button = Root.FindChildTraverse("StartButton")
	Button.enabled = false
	
	// disable player panel
	var PlayerID = Game.GetLocalPlayerID()
	Player_Status(PlayerID, false, false)
	
	// set time left incase the button is pressed again
	Root.time_left = 3	
	
	//setup countdown
	CountDown()
}

function Initiate_Game(){
	// set Game_Started state to true
	Root.Game_Started = true
	
	$.Msg("Everyone is ready")
	// this will make the game_setup state go further and tells lua about this and then makes players
	Game.SetRemainingSetupTime(0);	
	GameEvents.SendCustomGameEventToServer("selection_over", {});
}

// simple timer function
function CountDown(){
	$.Msg("Countdown Time: "+Root.time_left)
	// set countdown true so that this function will start scheduling itself
	Root.CountDown = true
	
	var Left_Bar = Root.FindChildTraverse("Left_Bar")
	
	// create header
	var Timer_Header = $.CreatePanel("Label", Left_Bar, "CountDownHeader")
	Timer_Header.text = "Map starts in:"

	//create text
	var Timer_Text = $.CreatePanel("Label", Left_Bar, "CountDown")
	if(Root.time_left != 0){
		Timer_Text.text = Root.time_left
	}else{
		Timer_Text.text = "GL & HF"
	}
	// delete after 1 second
	Timer_Text.DeleteAsync(1) 
	
	// if time left is 0 then
	if(Root.time_left == 0){
		$.Msg("STARTING GAME NOW")
		Root.CountDown = false
		Root.Game_Started = false
	
		// start game
		$.Schedule(1, Initiate_Game)
	}else{
		Root.time_left--;	
	}
	
	// if countdown is true and game hasn't started THEN schedule
	if(Root.CountDown && !Root.Game_Started){
		$.Schedule(1, CountDown)
	}		
}

///////////////////////////////////////////////
// 				Setup & Commands			 //
///////////////////////////////////////////////

function Developer_Mode(args){
	if(args.developer){
		$.Msg("[Panaroma Developer Mode]")
		DEVELOPER = true
	}else{
		Developer = false
	}
}

// this is a function called by a command from console "skip_selection"
// it essentially forces the ready up stage and sends in current information
// PURELY DEBUG
function Skip_Selection(data){
	$.Msg("Everyone is ready")
	Game.SetRemainingSetupTime(0);	
	GameEvents.SendCustomGameEventToServer("selection_over", {});
}

function Setup_Panaroma_Color_Table(){
	// store color table inside this var
	var Colors = CustomNetTables.GetAllTableValues("dotacraft_color_table")

	// loop and add the Colors table to the local color table
	for (var key in Colors) {   
		dotacraft_Colors[key] = { r: Colors[key].value.r, g: Colors[key].value.g, b: Colors[key].value.b, "taken": false } 
	} 
}

function Setup_Minimap(){
	var Map_Info = Game.GetMapInfo()
	var Map_Name = Map_Info.map_display_name
	
	var Minimap_Panel = Root.FindChildTraverse("Minimap")
	var Minimap_Name = Root.FindChildTraverse("Minimap_Name")
	var Suggested_Players = Root.FindChildTraverse("Suggested_Players_Text")
	var Map_Description = Root.FindChildTraverse("Map_Description_Text")
	
	var Minimap_Image_Path = "url('file://{images}/selection/"+Map_Name+".vtex');"
	//$.Msg(Minimap_Image_Path)
	 
	// set minimap image path
	Minimap_Panel.style["background-image"] = Minimap_Image_Path
	// set minimap name text
	Minimap_Name.text = Map_Name
	
	//localized strings from addon
	Suggested_Players.text = $.Localize("#"+Map_Name+"_suggested_players");
	Map_Description.text = $.Localize("#"+Map_Name+"_map_description");
}

(function () {
	GameEvents.Subscribe( "panaroma_developer", Developer_Mode );
	//GameEvents subscribes
	GameEvents.Subscribe( "dotacraft_update_player", Update_Player );
	GameEvents.Subscribe( "dotacraft_skip_selection", Skip_Selection );
	CustomNetTables.SubscribeNetTableListener("dotacraft_player_table", Update_Player);
	CustomNetTables.SubscribeNetTableListener("dotacraft_color_table", Update_Available_Colors);
	
	Root.CountDown = false
	Root.Game_Started = false

	// setup function calls
	Setup_Panaroma_Color_Table()
	Setup_Minimap()
	
	Game.SetAutoLaunchEnabled(false);
    Game.SetTeamSelectionLocked(true);
	
	// check for new players, this also sets up the $.Schedule inside the function
	CheckForNewPlayers()
})();

///////////////////////////////////////////////
// 				Useful Functions			 //
///////////////////////////////////////////////

function Length(Panel){
	var No_End = 1
	for (i = 0; i <= No_End; i++) {	
		// if the current index wasn't a valid child, current index-1 is the total amount of children
		// this assumes you index from 0 - something
		if(Panel[i] == null){ 
		//$.Msg("length is:" +(i-1))
			return y = i-1
			break; 
		} 
		 
		No_End++;
	}
}
// increment team and color index variables
function Increment_Variables(){
	if(current_TeamIndex >= Length(dotacraft_Teams)){ 
		current_TeamIndex = 0
	}
	else{
		current_TeamIndex++;
	}
	
	if(current_ColorIndex >= Length(dotacraft_Colors)){
		current_ColorIndex = 0
	}
	else{
		current_ColorIndex++;
	}
} 

// this it to check whether a player panel was already created
function IsPlayerPanelCreated(PlayerID){
	// check the player panel of the container for playerID's
	if(PlayerContainer.FindChildTraverse(PlayerID) == null){
		return false
	} 
	else{
		return true
	}
}

// check if player is host
function isHost(PlayerID){
    var Player_Info = Game.GetPlayerInfo(PlayerID)
    
    if(!Player_Info)
    {
		$.Msg("Player does not exist = #"+PlayerID)
        return false;
    }

    return Player_Info.player_has_host_privileges;
}

// panel enabled
function Toggle_Enabled_Panel(panel, enabled){
	panel.enabled = enabled
}

// panel visibility
function Toggle_Visibility_Panel(panel, visible){
	panel.visible = visible
}

function Boolise(index){
	if(index == 0){
		return false
	}else{
		return true
	}	
}