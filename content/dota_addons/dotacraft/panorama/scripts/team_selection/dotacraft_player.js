//////////////////////////////////////////////
// 				Local Variables				//
//////////////////////////////////////////////
// panaroma color table, will most likely make a nettable for this
var COLOUR_TABLE = {}

var Root = $.GetContextPanel();
//////////////////////////////////////////////
// 					BUTTONS					//
//////////////////////////////////////////////

// ready up button
function ReadyUp(){
	// TOGGLE
	// if not ready, he's now ready
	if (!Root.PlayerReady){
		Root.PlayerReady = true;
	}else{ // if ready, he's now not ready 
		Root.PlayerReady = false;
	};

	// update ready status
	Update_Player();
};

// button click function for the team dropdown
function PlayerTeamChanged(){
	var dropdown = Root.FindChildTraverse("TeamDropDown");
	var team_index = dropdown.GetSelected().id;
	
	// set selected dropdown child and assign the index of the GetSelected as the new value
	dropdown.SetSelected(team_index);
	SetPanelInformation(parseInt(team_index), 1);
	
	// update player
	Update_Player();
};

// button click function for the race dropdown
function PlayerRaceChanged(){
	var dropdown = Root.FindChildTraverse("RaceDropDown");
	var race_index = dropdown.GetSelected().id;
	
	// set selected dropdown child and assign the index of the GetSelected as the new value
	dropdown.SetSelected(race_index);
	SetPanelInformation(parseInt(race_index), 2);	
	
	// update player
	Update_Player();
};

// button click function for the color dropdown
function PlayerColorChanged(){
	var dropdown = Root.FindChildTraverse("ColorDropDown");
	var color_index = dropdown.GetSelected().id;
	
	// set selected dropdown child and assign the index of the GetSelected as the new value
	dropdown.SetSelected(color_index);
	
	// reset last color
	var previous_dropdown_child = dropdown.FindDropDownMenuChild (Root.PlayerColor);
	previous_dropdown_child.enabled = true;
	previous_dropdown_child.style["border"] = "0px solid black";
	
	// save the new color index in the local variable
	SetPanelInformation(parseInt(color_index), 2);	 

	// change background color to match the setselected
	dropdown.style["background-color"] =  "rgb("+COLOUR_TABLE[color_index].r+","+COLOUR_TABLE[color_index].g+","+COLOUR_TABLE[color_index].b+")";
	
	// update player
	Update_Player();
};

function OptionsInput(){
	var OptionsDropDown = $("#OptionsDropDown");
	var SelectedIndex = parseInt(OptionsDropDown.GetSelected().id);

	if( SelectedIndex != null ){
		switch ( SelectedIndex ){
			case 0:
				Root.AI = false;	
				break;
			case 1:
				Root.AI = false;
				break;				
			case 2:
				SetPanelInformation(9001, 0)
				Root.AI = true;
				Setup_Player();
				break;
			case 3:
				SetPanelInformation(9002, 0)
				Root.AI = true;
				Setup_Player();
				break;
			case 4:
				SetPanelInformation(9003, 0)
				Root.AI = true;
				Setup_Player();
				break;
		};
	};
};

function SetPanelInformation(Value, State){
	// set panel && local variable values
	switch ( State ){
		case 0: // PlayerID
			Root.PlayerID = Value
			break;
		case 1: // TeamID
			Root.PlayerTeam = Value	
			break;
		case 2: // RaceID
			Root.PlayerRace = Value	
			break;
		case 3: // ColorID
			Root.PlayerColor = Value
			break;
	};		
};
//////////////////////////////////////////////
// 					Player Update			//  
//////////////////////////////////////////////
// update player logic
function Update_Player(){
	// save this info in the playerpanel and send it to lua net_tables
	//$.Msg("Player: #"+Root.PlayerID+" set to Team: #"+Root.PlayerTeam+" with color: "+Root.PlayerColor+" and race: #"+Root.PlayerRace+", ReadyStatus="+Root.PlayerReady);
	
	GameEvents.SendCustomGameEventToServer("update_pregame", { "PanelID": Root.PanelID, "PlayerID": Root.PlayerID, "Race": Root.PlayerRace, "Team": Root.PlayerTeam, "Color": Root.PlayerColor});
};  

// Globally available panel to this context
(function () {
	// save the context panel	
	Setup_Panaroma_Color_Table();
	Setup_Colours(Root);
	
	$.Schedule(0.1, Update);
})();

function Update(){
	Setup_Player();
	CurrentStateOfPanel();
	$.Schedule(0.01, Update);
};

function CurrentStateOfPanel(){
	var OptionsDropDown = $("#OptionsDropDown");
	var SelectedIndex = OptionsDropDown.GetSelected().id;

	if( SelectedIndex != null ){
		if( Players.IsValidPlayerID(Root.PlayerID) || Root.AI ){
			$("#ColorDropDown").visible = true;
			$("#RaceDropDown").visible = true;
			$("#TeamDropDown").visible = true;
		}else{
			$("#ColorDropDown").visible = false;
			$("#RaceDropDown").visible = false;
			$("#TeamDropDown").visible = false;	
		};
	};
};

///////////////////////////////////////////////
// 			One-Time INITIALISATION			 //
///////////////////////////////////////////////

var AI_Names = {
	8999: "Closed",
	9000: "Open",
	9001: "COMPUTER (EASY)",
	9002: "COMPUTER (NORMAL)",
	9003: "COMPUTER (HARD)"
}; 

// this function sets up all the components for the player once
function Setup_Player(){
	var PlayerInfo;
	if( Players.IsValidPlayerID(Root.PlayerID) ){
		PlayerInfo = Game.GetPlayerInfo(Root.PlayerID); 
		
		// assign steamid to avatar and playername panels
		$("#PlayerAvatar").steamid = PlayerInfo.player_steamid;
		$("#PlayerName").steamid = PlayerInfo.player_steamid;
	}else{
	//	$("#PlayerAvatar").steamid = PlayerInfo.player_steamid;
		$("#PlayerName").GetChild(0).text = AI_Names[Root.PlayerID];  
	};

	// default values
	Root.PlayerRace = 1;
	Root.PlayerReady = false;
	Root.PlayerTeam = 3;
	
	// set initial dropdown color
	var dropdown = Root.FindChildTraverse("ColorDropDown");
	dropdown.SetSelected(Root.PlayerColor);
	var key = Root.PlayerColor;
	
	dropdown.style["background-color"] =  "rgb("+COLOUR_TABLE[key].r+","+COLOUR_TABLE[key].g+","+COLOUR_TABLE[key].b+")";
	
	// initial update player call
	Update_Player();
};

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
    var Player_Info = Game.GetPlayerInfo(Root.PlayerID);
    
    if(!Player_Info)
    {
		$.Msg("Player does not exist = #"+Root.PlayerID);
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
			Root.PlayerColor = color_index;
			dropdown.SetSelected(color_index.toString());
			dropdown.style["background-color"] = COLOUR_TABLE[color_index];

			Update_Player();
		};
	});
	