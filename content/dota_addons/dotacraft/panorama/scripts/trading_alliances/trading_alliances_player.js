var Root = $.GetContextPanel();
var PlayerObject;
(function () {
	$.Msg("setting up trading_alliances player");
	$.Schedule(1, SetupPlayer);
})();

function SetupPlayer(){	
	var playerInfo = Game.GetPlayerInfo(Root.PlayerID);
	var PlayerSteamID = playerInfo.player_steamid;
	// set steamID to initialise avatar image and player name
	$("#PlayerAvatar").steamid = PlayerSteamID;
	$("#PlayerName").steamid = PlayerSteamID;
		
	// setup panels
	SetupPanels(); 
	
	// create player object & create a listener
	PlayerObject = new Player(Root.PlayerID);
	CustomNetTables.SubscribeNetTableListener("dotacraft_player_table", UpdatePlayer);
};

function UpdatePlayer(TableName, Key, Value){
	if(Key == Root.PlayerID)
		PlayerObject.Update(Value);
};

function SetupPanels(){
	var PlayerTable = CustomNetTables.GetTableValue( "dotacraft_player_table", Root.PlayerID);
	var PlayerColorTable = CustomNetTables.GetAllTableValues("dotacraft_color_table");
	
	if(PlayerTable != null){
		var Color = "rgb("+PlayerColorTable[PlayerTable.Color].value.r+","+PlayerColorTable[PlayerTable.Color].value.g+","+PlayerColorTable[PlayerTable.Color].value.b+")";
		$("#PlayerAvatar").style["border"] = "2px solid "+Color; 
	};
};

function Increment(State, pRightClicked){
	// State( 1 == gold, 2 == lumber )
	var TextBox;

	var PlayerGoldOrLumberResource = CustomNetTables.GetTableValue( "dotacraft_player_table", Root.PlayerID).lumber;
	if( State == 1){
		TextBox = $("#GoldBox").FindChild("GoldBoxText");	
		PlayerGoldOrLumberResource = PlayerObject.getGold();
	}else{
		TextBox = $("#LumberBox").FindChild("LumberBoxText");
		PlayerGoldOrLumberResource = PlayerObject.getLumber() ;
	};
	
	var CurrentSum = parseInt(TextBox.text); 
	
	// work out new value
	var NewSum;
	if( !GameUI.IsAltDown() )
		NewSum  = WorkOutNewIncrement(CurrentSum, pRightClicked);
	else{
		if( !pRightClicked )
			NewSum  = PlayerGoldOrLumberResource;
		else
			NewSum = 0;
	};
	
	// check if player has enough funds to afford
	var sufficientFunds = NewSum  <= PlayerGoldOrLumberResource && NewSum  >= 0;
	if(sufficientFunds)
		TextBox.text = NewSum;
	else{
		if(NewSum  >= 0)
			TextBox.text = PlayerGoldOrLumberResource;
		else
			TextBox.text = 0;
	};
};

function WorkOutNewIncrement(pCurrentValue, pRightClicked){
	var NewSum = 0;
	var Increment = 100;
	var ShiftIncrement = 1000;
	
	// check which keys are down in order to determine the effect of the new sum.
	if( GameUI.IsShiftDown() ){
		if ( !pRightClicked )
			NewSum = pCurrentValue + ShiftIncrement;
		else
			NewSum = pCurrentValue + -ShiftIncrement;
	}else{
		if ( !pRightClicked )
			NewSum = pCurrentValue + Increment;
		else
			NewSum = pCurrentValue + -Increment; 
	};
		
	return NewSum;
};