var Root = $.GetContextPanel();
var Parent = Root.GetParent();
var LocalPlayerID = Game.GetLocalPlayerID();
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
};

function SetupPanels(){
	var PlayerColor = PlayerTables.GetColor(LocalPlayerID);
	
	if(PlayerColor != null){
		var Color = "rgb("+PlayerColor.r+","+PlayerColor.g+","+PlayerColor.b+")";
		$("#PlayerAvatar").style["border"] = "2px solid "+Color;
	};
};

function OnToggleShare(){
	GameEvents.SendCustomGameEventToServer("trading_alliances_shareMask", { "targetPlayerID" : Root.PlayerID, "invokingPlayerID" : Game.GetLocalPlayerID()} );
};

function CalculateCurrentPendingResources(){
	var GoldAndLumber = {
				Gold : 0,
				Lumber : 0		
			};
			
	var LocalPlayerInfo	= Game.GetLocalPlayerInfo(); 
	var LocalPlayerTeam = LocalPlayerInfo.player_team_id;

	var PlayerIDList = Game.GetPlayerIDsOnTeam(LocalPlayerTeam);
	// loop through all id's found on this team
	for(var PlayerID of PlayerIDList){
		if( PlayerID != Game.GetLocalPlayerID() ){
			var PlayerPanel = Parent.FindChildTraverse(PlayerID);
			var GoldBox = PlayerPanel.FindChildTraverse("GoldBoxText");
			var LumberBox = PlayerPanel.FindChildTraverse("LumberBoxText");
			
			GoldAndLumber.Gold += parseInt(GoldBox.text);
			GoldAndLumber.Lumber += parseInt(LumberBox.text);
		};
	};
	return GoldAndLumber;
};

function CalculatePlayerResourcesLeft(pendingGold, pendingLumber){
	var PlayerGold = PlayerTables.GetGold(LocalPlayerID);
	var PlayerLumber = PlayerTables.GetLumber(LocalPlayerID);

	var GoldLeft = PlayerGold - pendingGold;
	var LumberLeft = PlayerLumber - pendingLumber;
	
	return { Gold : GoldLeft, Lumber : LumberLeft };
};

function Increment(State, pRightClicked){
	var TextBox;
	
	// work out current pending gold and lumber values
	var PendingResources = CalculateCurrentPendingResources();
	var GoldLeft = PendingResources.Gold;
	var LumberLeft = PendingResources.Lumber; 
	
	// work out current gold and lumber left( playerResources - PendingResources );
	var ResourcesLeft = CalculatePlayerResourcesLeft(GoldLeft, LumberLeft);
	var GoldLeft = ResourcesLeft.Gold;
	var LumberLeft = ResourcesLeft.Lumber;
	
	// State( 1 == gold, 2 == lumber )
	var PlayerGoldOrLumberResourceRemaining;
	if( State == 1){
		TextBox = $("#GoldBox").FindChild("GoldBoxText");	
		PlayerGoldOrLumberResourceRemaining = GoldLeft;
	}else{
		TextBox = $("#LumberBox").FindChild("LumberBoxText");
		PlayerGoldOrLumberResourceRemaining = LumberLeft;
	};
	
	// current value of the textbox before adding anything;
	var CurrentSum = parseInt(TextBox.text); 
	
	// work out new value
	var NewSum; 
	// if alt isn't down, we want to normally increment
	if( !GameUI.IsAltDown() ) {
		NewSum  = WorkOutNewIncrement(CurrentSum, pRightClicked);
		// work out the change
		var ChangeSum = NewSum - CurrentSum;	
		
		// cap NewSum at 0;
		if( NewSum < 0)
			NewSum = 0;
		else if(ChangeSum > PlayerGoldOrLumberResourceRemaining && !pRightClicked){ // if change is greater then current resources
			NewSum = CurrentSum + PlayerGoldOrLumberResourceRemaining;
		};
	}else{
		// if alt is down we want to increment to the highest possible value
		// if not right clicked (deduct), assign total gold or lumber left to value
		if( !pRightClicked ){
			if( State == 1 )
				NewSum = CurrentSum + GoldLeft;
			else
				NewSum = CurrentSum + LumberLeft;
		}else // if it is rightclick we simply want it to reset to 0
			NewSum = 0;
	};
	
	// assign NewSum as the new textbox value
	TextBox.text = NewSum;
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