//////////////////////////////////////////////
// 				Local Variables				//
//////////////////////////////////////////////
var COLOUR_TABLE = {}
var Root = $.GetContextPanel();
var LocalPlayerID = Game.GetLocalPlayerID();
var PlayerContainer = Root.GetParent().GetParent();
var DROPDOWN_SOUND_EVENT_NAME = "Hero_Warlock.Attack";
var MOVE_SOUND_EVENT_NAME = "DOTA_Item.Daedelus.Crit";

//////////////////////////////////////////////
// 					BUTTONS					//
//////////////////////////////////////////////

// function for player to sit initially
Root.Init = function(playerID, teamID, colorID, raceID){
	Root.PlayerID = playerID;
	Root.PlayerTeam = teamID;
	Root.PlayerColor = colorID;
	Root.PlayerRace = raceID;
	
	Root.PanelID = playerID;
	Root.PlayerReady = false;
	Root.Locked = false;

	//Root.FindChildTraverse("TeamDropDown").SetSelected(teamID);
	//Root.FindChildTraverse("RaceDropDown").SetSelected(raceID);
	//Root.FindChildTraverse("ColorDropDown").SetSelected(colorID);
	
	$.Msg("Initialising player #"+Root.PlayerID);
	PlayerPanelSetup();
	
	if( Root.PlayerID == LocalPlayerID ) // initial update only done by the local player
		UpdatePlayer();
};

Root.Lock = function(lock)
{
	UpdatePlayer( {Lock: lock} );
};

Root.SetBot = function(aiLVL){
	if( isLocalPlayerHost() ) // host only
		$("#OptionsDropDown").RemoveClass("hidden");
	
	Root.Bot = true;
	Root.aiLVL = aiLVL;
	$("#PlayerAvatar").visible = false;
	$("#PlayerName").GetChild(0).text = Bot_Names[aiLVL];  
	
	if ( isLocalPlayerHost() ){
		UpdatePlayer();
	};
};

// ready up button
function ReadyUp(){
	// TOGGLE
	// if not ready, he's now ready
	if (!Root.PlayerReady){
		Root.PlayerReady = true;
	}else{ // if ready, he's now not ready 
		Root.PlayerReady = false;
	};

	UpdatePlayer({ Ready: Root.PlayerReady });
};

Root.FindChildTraverse("OptionsDropDown").SetPanelEvent('oninputsubmit', function OptionsInput(){
	var selectedID = $("#OptionsDropDown").GetSelected().id;
	
	if( selectedID == 0)
		PlayerContainer.HandlePanelDeletion(Root.PlayerID, Root.PanelID);
	else
		UpdatePlayer( {"Bot_Name" : selectedID, "Bot": 1 });
});

/*
// button click function for the team dropdown
Root.FindChildTraverse("TeamDropDown").SetPanelEvent('oninputsubmit', function PlayerTeamChanged(){
	var dropdown = Root.FindChildTraverse("TeamDropDown");
	var team_index = dropdown.GetSelected().id;

	dropdown.SetSelected(team_index);
	var newTeam = parseInt(team_index);
	Root.PlayerTeam = newTeam;
	
	UpdatePlayer( { Team: newTeam } );
});
*/

Root.Copy = function(playerPanel){
	UpdatePlayer({Team : playerPanel.PlayerTeam, Race: playerPanel.PlayerRace, Color: playerPanel.PlayerColor, newPlayerID: playerPanel.PlayerID});
};

Root.SetTeam = function(teamID){ 
	if( !Root.Locked && teamID != Root.PlayerTeam ){ // only if not locked
		Game.EmitSound(MOVE_SOUND_EVENT_NAME);
		Root.PlayerTeam = teamID;
		UpdatePlayer( { Team: teamID } );
	};
};

// button click function for the race dropdown
Root.FindChildTraverse("RaceDropDown").SetPanelEvent('oninputsubmit', function PlayerRaceChanged(){
	Game.EmitSound(DROPDOWN_SOUND_EVENT_NAME);
	var dropdown = Root.FindChildTraverse("RaceDropDown");
	var race_index = dropdown.GetSelected().id;

	dropdown.SetSelected(race_index);	
	var newRace = parseInt(race_index);	
	Root.PlayerRace = newRace;
	
	UpdatePlayer( { Race: newRace } );
});

// button click function for the color dropdown
Root.FindChildTraverse("ColorDropDown").SetPanelEvent('oninputsubmit', function PlayerColorChanged(){
	Game.EmitSound(DROPDOWN_SOUND_EVENT_NAME);
	var dropdown = Root.FindChildTraverse("ColorDropDown");
	var color_index = dropdown.GetSelected().id;

	// save the new color index in the local variable
	dropdown.SetSelected(color_index);
	var old_color_index = Root.PlayerColor;
	var newColor = parseInt(color_index);
	Root.PlayerColor = newColor;
	
	UpdateColorDropDownColor();
	
	UpdatePlayer( { Color : newColor, OldColor : old_color_index } );
});

//////////////////////////////////////////////
// 					Player Update			//  
//////////////////////////////////////////////
// update player logic
function UpdatePlayer( UpdateTable ){
	$.Msg("updating player #"+Root.PlayerID+", update changes:");
	$.Msg(UpdateTable);
	// save this info in the playerpanel and send it to lua net_tables
	//$.Msg("Player: #"+Root.PlayerID+" set to Team: #"+Root.PlayerTeam+" with color: "+Root.PlayerColor+" and race: #"+Root.PlayerRace+", ReadyStatus="+Root.PlayerReady+");
	if( UpdateTable == null ) // assumes we just want to send an update of the current panel
		UpdateTable = {};
	
	if( UpdateTable.Team == null ) // team
		UpdateTable.Team = Root.PlayerTeam;
	if( UpdateTable.Race == null ) // race
		UpdateTable.Race = Root.PlayerRace;
	if( UpdateTable.Color == null ) // color
		UpdateTable.Color = Root.PlayerColor;
	if( UpdateTable.Ready == null )
		UpdateTable.Ready = Root.PlayerReady;
	if( UpdateTable.Bot == null && Root.Bot )
		UpdateTable.Bot = true;
	if( Root.Bot && UpdateTable.aiLVL == null )
		UpdateTable.aiLVL = Root.aiLVL;
	
	GameEvents.SendCustomGameEventToServer("update_pregame", {"ID" : Root.PlayerID, "Info" : UpdateTable});
};

// Globally available panel to this context
(function () {
	// setup functions
	SetupLocalisation();
	Setup_Panaroma_Color_Table();
	Setup_Colours(Root);
	CustomNetTables.SubscribeNetTableListener("dotacraft_pregame_table", NetTableUpdatePlayer);
})();

function SetupLocalisation(){
	var race_dropdown = Root.FindChildTraverse("RaceDropDown");
	
	for(var i = 0; i <= Count_Dropdown_Children(race_dropdown); i++)
		race_dropdown.FindDropDownMenuChild(i).text = $.Localize("race_"+i);
	
	race_dropdown.GetChild(0).text = $.Localize("race_0"); // set race dropdown to this localisation due to the dropdown being initialised when the text was empty
	
	var options_dropdown = Root.FindChildTraverse("OptionsDropDown");	
	for(var i = 0; i <= Count_Dropdown_Children(options_dropdown); i++)
		options_dropdown.FindDropDownMenuChild(i).text = $.Localize("options_dropdown_"+i);
};

function HandleReadyStatus(ready){
	Root.SetHasClass("Ready", ready);
	UpdatePanelLockState(Boolise(ready));
	Root.PlayerReady = ready;		
};

// main logic behind updating players, this is called when net_table changed
function NetTableUpdatePlayer(tableName, key, val){
	if( isHost(parseInt(key)) && Root.Bot ) // mirror host ready status if bot
		HandleReadyStatus(val.Ready);
	
	if( key == Root.PlayerID ){	
		// variables  
		var PlayerID = key;
		if(val.Bot != null && val.Bot_Name != null){
			if( isLocalPlayerHost() ) // host only
				$("#OptionsDropDown").RemoveClass("hidden");
			
			Root.aiLVL = val.Bot_Name;
			
			$("#PlayerAvatar").visible = false;
			$("#PlayerName").GetChild(0).text = Bot_Names[val.Bot_Name];  
		};
		
		if( val.Ready != null  )
			HandleReadyStatus(val.Ready);
		
		$.Msg("[Player]: "+PlayerID+" is updating"); 

		if( val.Lock != null){
			UpdatePanelLockState(Boolise(val.Lock));
			Root.Locked = val.Lock;
		};
		
		
		if( (val.Team != null) || (val.Color != null) || (val.Race != null) ){
			if( val.Team != null){
				Root.PlayerTeam = val.Team
				var newTeamPanel = Root.GetParent().GetParent().FindChildTraverse("Team_"+val.Team);
				Root.SetParent(newTeamPanel);
			}
			if( val.Race != null)
				Root.PlayerRace = val.Race;
			if( val.Color != null)
				Root.PlayerColor = val.Color;
			
			
			// find all drop-downs and update their selection
			for(var index in dotacraft_DropDowns){ 	 
				var dropdown = Root.FindChildTraverse(dotacraft_DropDowns[index]);
				
				// determine which dropdown the current index is, and update accordingly
				if(dotacraft_DropDowns[index] == "ColorDropDown" && val.Color != null){
					$.Msg("updating color");
					UpdateColorDropDownColor();
					ChangeColourOfDropDownChild(val.Color, val.OldColor);
				} 
				/*else if (dotacraft_DropDowns[index] == "TeamDropDown" && val.Team != null  ){  
					$.Msg("updating team");
					dropdown.SetSelected(val.Team);
					var newTeamPanel = Root.GetParent().GetParent().FindChildTraverse("Team_"+val.Team);
					Root.SetParent(newTeamPanel);
				}*/
				else if (dotacraft_DropDowns[index] == "RaceDropDown" && val.Race != null  ){
					$.Msg("updating race");
					dropdown.SetSelected(val.Race);
					
					// if local player change the race background to match the select race
					if(LocalPlayerID == PlayerID){
						//SetRaceBackgroundImage(Value.Race);
					};
				};
			};
		};
	};
	
	UpdateAvailableColors();
}; 

function UpdateAvailableColors(){
	var netTable = CustomNetTables.GetAllTableValues( "dotacraft_pregame_table" );
	
	var dropdown = Root.FindChildTraverse("ColorDropDown");
	
	for(var i =0; i < Count_Dropdown_Children(dropdown, ""); i+=1){
		var dropdown_child = dropdown.FindDropDownMenuChild(i);
		dropdown_child.visible = true;
	};
	
	for(k in netTable){
		if( netTable[k].value.Color != null && netTable[k].value.Color != {} ){
			var dropdown_child = dropdown.FindDropDownMenuChild(netTable[k].value.Color);
			dropdown_child.visible = false;
		};
	};
};

var Bot_Names = {
	1: "AI(EASY)",
	2: "AI(NORMAL)",
	3: "AI(HARD)"
}; 

function Boolise(index){
	if(index == 0){
		return false;
	}else{
		return true;
	};
};

function ChangeColourOfDropDownChild(newID, oldID){
	var dropdown = Root.FindChildTraverse("ColorDropDown");

	if(oldID != null){	
		var oldChild = dropdown.FindDropDownMenuChild(oldID);
		oldChild.visible = true;
	};

	if(newID != null){		
		var newChild = dropdown.FindDropDownMenuChild(newID);
		newChild.visible = false;
	};
};

// function which sets the local background image to that of the race
function SetRaceBackgroundImage(race){
	// if race is not 0, which is the random race
	var Left_Bar = Root.GetParent().GetParent();
	if(race != 0){
		// save image path and then assign it in the style
		var team_path = "url('s2r://panorama/images/selection/background_"+race+".png')";
		Left_Bar.style["background-image"] = team_path;
	}else{ // if random
		Left_Bar.style["background-image"] = "url('s2r://panorama/images/backgrounds/gallery_background.png')";
	};
};

var dotacraft_DropDowns = {
	1: "ColorDropDown",
//	2: "TeamDropDown",
	3: "RaceDropDown"
};

function PlayerPanelSetup(){
	var PlayerInfo;
	
	// manage name & image
	if( Players.IsValidPlayerID(Root.PlayerID) ){
		PlayerInfo = Game.GetPlayerInfo(Root.PlayerID);
		
		$("#PlayerAvatar").visible = true;
		// assign steamid to avatar and playername panels
		$("#PlayerAvatar").steamid = PlayerInfo.player_steamid;
		$("#PlayerName").GetChild(0).text = PlayerInfo.player_name;
	};
	
	if( LocalPlayerID == Root.PlayerID )
		Root.SetHasClass("Local", true);
	else
		Root.SetHasClass("Local", false);
	
	// manage hosticon display
	if( isPlayerHost() ){
		// add Host panel class to differentiate between host and normal players
		var Name = Root.FindChildTraverse('PanelOptions'); 
		var HostIcon = $("#Host_Icon");
		if( HostIcon == null ){
			HostIcon = $.CreatePanel("Panel", Name, "Host_Icon");
			HostIcon.SetHasClass("Host", true);	
		}else
			HostIcon.visible = true;
	}else{
		var HostIcon = $("#Host_Icon");
		if(HostIcon != null){
			HostIcon.visible = false;
		};
	};
	
	UpdateColorDropDownColor();
	
	// set dropdown enabled states
	if( Root.PlayerID == LocalPlayerID || ( !Players.IsValidPlayerID(Root.PlayerID) && isLocalPlayerHost()) )
		SetDropDownStates(true);
	else  // if Root.Locked && !isHost()
		SetDropDownStates(false);
};

function UpdatePanelLockState(lock)
{
	if( (isLocalPlayerHost() && lock) || ( isLocalPlayerHost() && Root.Bot) ) // if host && locked, enable all panels
		SetDropDownStates(true);
	else if( Root.PlayerID == LocalPlayerID && !lock ) // if panel belongs to local player && not locked, enable panel
		SetDropDownStates(true);
	else
		SetDropDownStates(false); // lock panels otherwise
};

function UpdateColorDropDownColor()
{
	var dropdown = Root.FindChildTraverse("ColorDropDown");
	dropdown.SetSelected(Root.PlayerColor);
	dropdown.style["background-color"] =  "rgb("+COLOUR_TABLE[Root.PlayerColor].r+","+COLOUR_TABLE[Root.PlayerColor].g+","+COLOUR_TABLE[Root.PlayerColor].b+")";	
	
	var color = "rgb("+COLOUR_TABLE[Root.PlayerColor].r+","+COLOUR_TABLE[Root.PlayerColor].g+","+COLOUR_TABLE[Root.PlayerColor].b+")";
	//var shadecolor = "rgb("+COLOUR_TABLE[Root.PlayerColor].r * 0.1+","+COLOUR_TABLE[Root.PlayerColor].g * 0.1+","+COLOUR_TABLE[Root.PlayerColor].b * 0.1+")";
	//var colortext = "gradient( linear, 0% 0%, 0% 100%, from( "+color+" ), to( "+shadecolor+" ));"
	var colortext = color;
	Root.FindChildTraverse("PlayerColor").style["background-color"] = colortext;	
};

function SetDropDownStates(Enabled){
	for(var index in dotacraft_DropDowns){
		var dropdown = Root.FindChildTraverse(dotacraft_DropDowns[index]);	
		if( dropdown != null )
			dropdown.enabled = Enabled;
	};	
};

Root.LockEverything = function(){
	SetDropDownStates(true);
	Root.FindChildTraverse("ReadyButton").enabled = false;
};

function Setup_Panaroma_Color_Table(){
	// store color table inside this var
	var Colors = CustomNetTables.GetAllTableValues("dotacraft_color_table");

	// loop and add the Colors table to the local color table
	for (var key in Colors) {   
		COLOUR_TABLE[key] = { r: Colors[key].value.r, g: Colors[key].value.g, b: Colors[key].value.b };	
	};
};

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

function isHost(playerID){
    var Player_Info = Game.GetPlayerInfo(playerID);
    
    if(!Player_Info)
    {
		//$.Msg("Player does not exist = #"+Root.PlayerID);
        return false;
    };

    return Player_Info.player_has_host_privileges;	
};

// check if player is host
function isPlayerHost(){
    return isHost(Root.PlayerID);
};

function isLocalPlayerHost(){
    return isHost(LocalPlayerID);
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
	