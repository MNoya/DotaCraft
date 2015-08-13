
var dotacraft_PlayerID
var dotacraft_PlayerTeam
var dotacraft_PlayerColor
var dotacraft_Player_Info
var dotacraft_PlayerRace = 0
var dotacraft_PlayerReady = false

function Update_Player(){
	// save this info in the playerpanel and send it to lua
	PlayerPanel.PlayerID = dotacraft_PlayerID
	PlayerPanel.Team = dotacraft_PlayerTeam
	PlayerPanel.Color = dotacraft_PlayerColor
	PlayerPanel.Race = dotacraft_PlayerRace
	
	$.Msg("Player: #"+dotacraft_PlayerID+" set to Team: #"+dotacraft_PlayerTeam+" with color: "+dotacraft_PlayerColor+" and race: #"+dotacraft_PlayerRace+", ReadyStatus="+dotacraft_PlayerReady);
	
	GameEvents.SendCustomGameEventToServer("update_player", { "ID": dotacraft_PlayerID, "Team": dotacraft_PlayerTeam, "Color": dotacraft_PlayerColor, "Race": dotacraft_PlayerRace, "Ready": dotacraft_PlayerReady});
}

function isHost(){
    var Player_Info = dotacraft_Player_Info
    
    if(!Player_Info)
    {
		$.Msg("Player does not exist = #"+dotacraft_PlayerID)
        return false;
    }

    return player.player_has_host_privileges;
}

var CURRENT_COLOUR = 0
var COLOUR_TABLE = []
COLOUR_TABLE[0] = "red"
COLOUR_TABLE[1] = "blue"
COLOUR_TABLE[2] = "purple"
COLOUR_TABLE[3] = "yellow"
COLOUR_TABLE[4] = "orange" 
COLOUR_TABLE[5] = "brown"
COLOUR_TABLE[6] = "white"
COLOUR_TABLE[7] = "black"
COLOUR_TABLE[8] = "pink"
COLOUR_TABLE[9] = "magenta"

function Setup_Colours(panel){
	//$.Msg("Setting up colours")
	var dropdown = panel.FindChildTraverse("ColorDropDown")
	
	var count = Count_Dropdown_Children(dropdown, "color_")
	//$.Msg(count)
	for (i = 0; i <= count; i++) {
		var dropdown_child = dropdown.FindDropDownMenuChild("color_"+i)
		dropdown_child.AddClass("Color")
		dropdown_child.style["background-color"] = COLOUR_TABLE[CURRENT_COLOUR]
		dropdown_child.SetPanelEvent("onactivate", ChangeColour(i, dotacraft_PlayerID, dropdown))
		
		// increment current colour
		CURRENT_COLOUR++;
	}
	CURRENT_COLOUR = 0
}

// button click
var ChangeColour= (
	function(color_index, playerid, dropdown)
	{
		return function()
		{
			dotacraft_PlayerColor = color_index
			dropdown.SetSelected("color_"+color_index.toString())
			dropdown.style["background-color"] = COLOUR_TABLE[color_index]

			Update_Player()
		}
	});
	
function ReadyUp(){
	
	if (!dotacraft_PlayerReady){
		dotacraft_PlayerReady = true 
		PlayerPanel.Ready = true
	}
	else{
		dotacraft_PlayerReady = false
		PlayerPanel.Ready = false
	}

	Update_Player()
}
// button click event for the team dropdown
function PlayerTeamChanged(){
	var dropdown = PlayerPanel.FindChildTraverse("TeamDropDown")
	var team_index = dropdown.GetSelected().id
	
	dropdown.SetSelected(team_index)
	dotacraft_PlayerTeam = parseInt(team_index, 10)
	
	Update_Player()
}

// buton click event for the team dropdown
function PlayerRaceChanged(){ 
	var dropdown = PlayerPanel.FindChildTraverse("RaceDropDown")
	var race_index = dropdown.GetSelected().id
	
	dropdown.SetSelected(race_index)
	dotacraft_PlayerRace = parseInt(race_index, 10)
	
	Update_Player()	
}

// buton click event for the color dropdown
function PlayerColorChanged(){
	
}

// counts how many children can be found
function Count_Dropdown_Children(dropdown, name){
	for (i = 0; i <= 1000; i++) {
		if(!dropdown.FindDropDownMenuChild(name+i)){
			return y = i-1
			break;
		} 
	}
}

function Setup_Player(){
	// assign panel playerid / get player info and save
	dotacraft_PlayerID = PlayerPanel.PlayerID
	dotacraft_Player_Info = Game.GetPlayerInfo(dotacraft_PlayerID)
	
	// assign default variables to panel
	dotacraft_PlayerTeam = PlayerPanel.PlayerTeam
	dotacraft_PlayerColor = PlayerPanel.PlayerColor
	PlayerPanel.Race = dotacraft_PlayerRace
	PlayerPanel.Ready = dotacraft_PlayerReady
	
	$("#PlayerAvatar").steamid = dotacraft_Player_Info.player_steamid
	$("#PlayerName").steamid = dotacraft_Player_Info.player_steamid	
	Update_Player()
}

// Globally available panel to this context
var PlayerPanel
(function () {
	// save the context panel
	PlayerPanel = $.GetContextPanel();
	 
	Setup_Colours(PlayerPanel) 
	
	$.Schedule(0.1, Setup_Player)
})();