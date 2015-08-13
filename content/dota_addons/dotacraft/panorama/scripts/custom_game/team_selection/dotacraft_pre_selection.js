var PlayerContainer = $("#PlayerListContainer")

// Disable Start
// Description: Disables Panels if it is not local to the player or they are ready
// 

var dotacraft_DropDowns = {
	1: "ColorDropDown",
	2: "TeamDropDown",
	3: "RaceDropDown"
}

var dotacraft_Buttons = {
	1: "HudButton"
} 
// the centre of readying everything up
function Player_Status(PlayerID, enabled, ready){
	var PlayerPanel = PlayerContainer.FindChildTraverse(PlayerID)
	
	$.Msg("Player "+PlayerID+" is ready") 
	 
	// find all drop-downs and toggle them
	for(var index in dotacraft_DropDowns){
		var dropdown = PlayerPanel.FindChildTraverse(dotacraft_DropDowns[index])	
		Toggle_Enabled_Panel(dropdown, enabled) 
	}
	
	var button = PlayerPanel.FindChildTraverse("HudButton")
	Toggle_Ready_Button(PlayerPanel, button, ready)
	Toggle_Enabled_Panel(button, enabled)
}

// toggle button style to match current player state
function Toggle_Ready_Button(PlayerPanel, button, ready){
	if(ready == true){
		button.style["background-color"]= "gradient( linear, 0% 0%, 0% 100%, from( #80a438 ), to( #597227 ))"
		PlayerPanel.style["background-color"]= "gradient( linear, 0% 0%, 0% 100%, from( #80a438 ), to( #597227 ))"
	}
	else{
		button.style["background-color"]= "gradient( linear, 0% 0%, 0% 100%, from( #5A615Ecc ), to( #879695cc ))"
		PlayerPanel.style["background-color"]= "gradient( linear, 0% 0%, 0% 100%, from( #191e1e ), to( #292e2e ) )"
	}
}

// toggle panel.enabled to set them disabled so they cant change settings
function Toggle_Enabled_Panel(panel, enabled){
	panel.enabled = enabled
}

//
// Disable End
//

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
			
			if(LocalPlayerID != PlayerID){
				PlayerPanel.enabled = false
				Player_Status(PlayerID, false, false)
			}
			
			// set initial starting variables
			PlayerPanel.PlayerID = PlayerID
			PlayerPanel.PlayerTeam = 2
			PlayerPanel.PlayerColor = 2
			//$.Msg(PlayerPanel)
		
			dotacraft_PlayerCount++;
		}
	}
} 

function GetTeamNumber(){
	
}

function GetColor(){
	
	
}

function Ready_Status(){
	var PlayerIDList = Game.GetAllPlayerIDs()
	var AmountOfPlayersReady = 0
	
	for(var PlayerID of PlayerIDList){
		if(PlayerContainer.FindChildTraverse(PlayerID).Ready){
			AmountOfPlayersReady++;
		}
	}
	
	//$.Msg(AmountOfPlayersReady)
	if(AmountOfPlayersReady == PlayerIDList+1 && !Game_Started){
		Game_Started = true
		Everyone_Is_Ready()
	}
}

var Game_Started = false
function Everyone_Is_Ready(){
	$.Msg("Everyone is ready")
	Game.SetRemainingSetupTime(0);	
	GameEvents.SendCustomGameEventToServer("selection_over", {});
}

var dotacraft_PlayerCount = 0

function IsPlayerPanelCreated(PlayerID){
	if(PlayerContainer.FindChildTraverse(PlayerID) == null){
		return false
	} 
	else{
		return true
	}
}

function CheckForNewPlayers(){
	//$.Msg("checking new players")
	Create_Players() 
	
	// loop this same function every minute
	if(!Game_Started){
		$.Schedule(1, CheckForNewPlayers)
		$.Schedule(1, Ready_Status)
	}
}

function Update_Player(data){
	// variables
	var PlayerID = data.PlayerID
	var ready = data.Ready

	var LocalPlayerID = Game.GetLocalPlayerID()
	var PlayerPanel = PlayerContainer.FindChildTraverse(PlayerID)
	
	$.Msg("Player "+PlayerID+" is updating") 
	 
	// find all drop-downs and toggle them
	for(var index in dotacraft_DropDowns){
		var dropdown = PlayerPanel.FindChildTraverse(dotacraft_DropDowns[index])
		if(PlayerID == LocalPlayerID && !ready){
			Toggle_Enabled_Panel(dropdown, true)
		}
		else{
			Toggle_Enabled_Panel(dropdown, false)	
		}
		
		if(dotacraft_DropDowns[index] == "ColorDropDown"){
			$.Msg("setting Color")
			dropdown.SetSelected("color" +data.Color-1)
		}
		else if (dotacraft_DropDowns[index] == "TeamDropDown"){
			$.Msg("setting Team")
			dropdown.SetSelected("" +data.Team)	
		}
		else if (dotacraft_DropDowns[index] == "RaceDropDown"){
			$.Msg("setting Race")
			dropdown.SetSelected("" +data.Race)
		}
	}
	
	var button = PlayerPanel.FindChildTraverse("HudButton")
	Toggle_Ready_Button(PlayerPanel, button, ready)
}

function Skip_Selection(data){
	$.Msg("Everyone is ready")
	Game.SetRemainingSetupTime(0);	
	GameEvents.SendCustomGameEventToServer("selection_over", {});
}

(function () {
	GameEvents.Subscribe( "dotacraft_update_player", Update_Player );
	
	GameEvents.Subscribe( "dotacraft_skip_selection", Skip_Selection );
		
	Game.SetAutoLaunchEnabled(false);
    Game.SetTeamSelectionLocked(true);
	
	CheckForNewPlayers()
	
	Ready_Status()
})();