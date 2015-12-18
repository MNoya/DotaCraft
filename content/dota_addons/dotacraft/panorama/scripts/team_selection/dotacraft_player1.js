//////////////////////////////////////////////
// 				Local Variables				//
//////////////////////////////////////////////
var dotacraft_PlayerID
var dotacraft_PlayerTeam
var dotacraft_PlayerColor
var dotacraft_Player_Info
var dotacraft_PlayerRace = 0
var dotacraft_PlayerReady = false

// panaroma color table, will most likely make a nettable for this
var CURRENT_COLOUR = 0
var COLOUR_TABLE = {}

//////////////////////////////////////////////
// 					BUTTONS					//
//////////////////////////////////////////////

// ready up button
function ReadyUp(){
	// TOGGLE
	// if not ready, he's now ready
	if (!dotacraft_PlayerReady){
		dotacraft_PlayerReady = true;
		PlayerPanel.Ready = true;
	}else{ // if ready, he's now not ready 
		dotacraft_PlayerReady = false;
		PlayerPanel.Ready = false;
	};

	// update ready status
	Update_Player();
};

// button click function for the team dropdown
function PlayerTeamChanged(){
	var dropdown = PlayerPanel.FindChildTraverse("TeamDropDown");
	var team_index = dropdown.GetSelected().id;
	
	// set selected dropdown child and assign the index of the GetSelected as the new value
	dropdown.SetSelected(team_index);
	dotacraft_PlayerTeam = parseInt(team_index, 10);
	
	// update player
	Update_Player();
};

// button click function for the race dropdown
function PlayerRaceChanged(){
	var dropdown = PlayerPanel.FindChildTraverse("RaceDropDown");
	var race_index = dropdown.GetSelected().id;
	
	// set selected dropdown child and assign the index of the GetSelected as the new value
	dropdown.SetSelected(race_index);
	dotacraft_PlayerRace = parseInt(race_index, 10);
	
	// update player
	Update_Player();
};

// button click function for the color dropdown
function PlayerColorChanged(){
	var dropdown = PlayerPanel.FindChildTraverse("ColorDropDown");
	var color_index = dropdown.GetSelected().id;
	
	// set selected dropdown child and assign the index of the GetSelected as the new value
	dropdown.SetSelected(color_index);
	
	// reset last color
	var previous_dropdown_child = dropdown.FindDropDownMenuChild (dotacraft_PlayerColor);
	previous_dropdown_child.enabled = true;
	previous_dropdown_child.style["border"] = "0px solid black";
	
	// save the new color index in the local variable
	dotacraft_PlayerColor = parseInt(color_index, 10);

	// change background color to match the setselected
	dropdown.style["background-color"] =  "rgb("+COLOUR_TABLE[color_index].r+","+COLOUR_TABLE[color_index].g+","+COLOUR_TABLE[color_index].b+")";
	
	// update player
	Update_Player();
};

//////////////////////////////////////////////
// 					Player Update			//
//////////////////////////////////////////////
// update player logic
function Update_Player(){
	// save this info in the playerpanel and send it to lua net_tables
	$.Msg("Player: #"+dotacraft_PlayerID+" set to Team: #"+dotacraft_PlayerTeam+" with color: "+dotacraft_PlayerColor+" and race: #"+dotacraft_PlayerRace+", ReadyStatus="+dotacraft_PlayerReady);
	
	$.Msg(dotacraft_PlayerReady);
	GameEvents.SendCustomGameEventToServer("update_player", { "ID": dotacraft_PlayerID, "Team": dotacraft_PlayerTeam, "Color": dotacraft_PlayerColor, "Race": dotacraft_PlayerRace, "Ready": dotacraft_PlayerReady});
};

// Globally available panel to this context
var PlayerPanel
(function () {
	// save the context panel
	PlayerPanel = $.GetContextPanel();
	
	Setup_Panaroma_Color_Table();
	Setup_Colours(PlayerPanel);
	
	$.Schedule(0.1, Setup_Player);
})();

///////////////////////////////////////////////
// 			One-Time INITIALISATION			 //
///////////////////////////////////////////////

// this function sets up all the components for the player once
function Setup_Player(){
	// assign default variables
	dotacraft_PlayerID = PlayerPanel.PlayerID;
	dotacraft_Player_Info = Game.GetPlayerInfo(dotacraft_PlayerID);
	dotacraft_PlayerTeam = PlayerPanel.PlayerTeam;
	dotacraft_PlayerColor = PlayerPanel.PlayerColor;
	PlayerPanel.Race = dotacraft_PlayerRace;
	PlayerPanel.Ready = dotacraft_PlayerReady;
	
	// set initial dropdown color
	var dropdown = PlayerPanel.FindChildTraverse("ColorDropDown");
	dropdown.SetSelected(dotacraft_PlayerColor);
	var key = dotacraft_PlayerColor;
	
	dropdown.style["background-color"] =  "rgb("+COLOUR_TABLE[key].r+","+COLOUR_TABLE[key].g+","+COLOUR_TABLE[key].b+")";
	
	// assign steamid to avatar and playername panels
	$("#PlayerAvatar").steamid = dotacraft_Player_Info.player_steamid;
	$("#PlayerName").steamid = dotacraft_Player_Info.player_steamid	;
	
	// initial update player call
	Update_Player();
}

function Setup_Panaroma_Color_Table(){
	// store color table inside this var
	var Colors = CustomNetTables.GetAllTableValues("dotacraft_color_table");

	// loop and add the Colors table to the local color table
	for (var key in Colors) {   
		COLOUR_TABLE[key] = { r: Colors[key].value.r, g: Colors[key].value.g, b: Colors[key].value.b };	
	} 
}

// setup the colors for the color dropdown
function Setup_Colours(panel){
	//$.Msg("Setting up colours")
	var dropdown = panel.FindChildTraverse("ColorDropDown");

	// count amount of dropdown children
	var count = Count_Dropdown_Children(dropdown, null);
  
	// iterate and assign colors
	for (i = 0; i <= count; i++) {
		var dropdown_child = dropdown.FindDropDownMenuChild(i);
		//$.Msg(COLOUR_TABLE[i].r)  
		dropdown_child.style["background-color"] = "rgb("+COLOUR_TABLE[i].r+","+COLOUR_TABLE[i].g+","+COLOUR_TABLE[i].b+")";
	};
};

///////////////////////////////////////////////
// 				Useful Functions			 //
///////////////////////////////////////////////

// counts how many "DROPDOWN" children can be found, only for dropdowns, since the only child for a dropdown is the selected dropdown child
function Count_Dropdown_Children(dropdown, name){
	// loop until an invalid index is found
	var No_End = 1;
	for (i = 0; i <= No_End; i++) {
		
		// determine whether we're checking an index or a "name_"+index
		var NameToCheck;
		if (name == null){
			NameToCheck = i;
		}
		else{
			NameToCheck = name+i;
		}
			
		// if the current index wasn't a valid child, current index-1 is the total amount of children
		// this assumes you index from 0 - something
		if(!dropdown.FindDropDownMenuChild(NameToCheck)){
			return y = i-1;
			break; 
		}
		 
		No_End++;
	};
};

// check if player is host
function isHost(){
    var Player_Info = dotacraft_Player_Info;
    
    if(!Player_Info)
    {
		$.Msg("Player does not exist = #"+dotacraft_PlayerID);
        return false;
    };

    return player.player_has_host_privileges;
};

// unused old example button click
var ChangeColour= (
	function(color_index, playerid, dropdown)
	{
		return function()
		{
			dotacraft_PlayerColor = color_index;
			dropdown.SetSelected(color_index.toString());
			dropdown.style["background-color"] = COLOUR_TABLE[color_index];

			Update_Player();
		};
	});
	