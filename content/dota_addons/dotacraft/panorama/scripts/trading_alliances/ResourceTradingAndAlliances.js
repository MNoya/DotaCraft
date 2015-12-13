var ResourceTradingAndAlliances = (function() {
	function ResourceTradingAndAlliances(pRoot){
		this.mPlayerPanels = new Array();
		this.mRoot = pRoot;

		// setup players
		this.SetupPlayers(); 
		
		// check gold & lumber
		this.CheckGold();
	};

	ResourceTradingAndAlliances.prototype.getPlayerPanel = function(pPlayerID){
		return this.mPlayerPanels[pPlayerID];
	};
		
	ResourceTradingAndAlliances.prototype.addPlayerPanel = function(pPlayerID, pPlayerPanel){
		this.mPlayerPanels[pPlayerID] = pPlayerPanel; 
	}; 
		
	ResourceTradingAndAlliances.prototype.SetupPlayers = function(){
		// get local player info 
		var LocalPlayerInfo	= Game.GetLocalPlayerInfo(); 
		var LocalPlayerTeam = LocalPlayerInfo.player_team_id;

		var PlayerIDList = Game.GetPlayerIDsOnTeam(LocalPlayerTeam);
		
		for(var PlayerID of Game.GetAllPlayerIDs()){
			//if(	Players.IsValidPlayerID(PlayerID) && Game.GetLocalPlayerID() != PlayerID )
				this.CreatePlayer(PlayerID);
			//else
			//	$.Msg("[Resource Trading and Alliances] PlayerID= "+PlayerID+" is not valid, Function=setupPlayers");
		};
	};
		
	// create player panel
	ResourceTradingAndAlliances.prototype.CreatePlayer = function(pPlayerID){ 
		var PlayerPanel = $.CreatePanel("Panel", this.mRoot, pPlayerID);
		PlayerPanel.BLoadLayout("file://{resources}/layout/custom_game/trading_alliances_player.xml", false, false);
		
		PlayerPanel.PlayerID = pPlayerID;
		
		this.addPlayerPanel(pPlayerID, PlayerPanel);
	};
		
	// remove player from panel
	ResourceTradingAndAlliances.prototype.RemovePlayer = function(pPlayerID){
		var PlayerPanel = Root.FindChildTraverse(PlayerID);
		PlayerPanel.visibility = "hidden";
	};
		
	ResourceTradingAndAlliances.prototype.ResetPlayersInput = function(){
		// for each existing panel reset their input to 0.
		for(var Panel of this.mPlayerPanels)
		{
			var GoldBox = Panel.FindChildTraverse("GoldBoxText");
			var LumberBox = Panel.FindChildTraverse("LumberBoxText");
			GoldBox.text = 0;
			LumberBox.text = 0;
		};
	};
	
	ResourceTradingAndAlliances.prototype.SendPlayersInput = function(){
		// for each existing panel reset their input to 0.
		for(var Panel of this.mPlayerPanels)
		{
			var GoldBox = Panel.FindChildTraverse("GoldBoxText");
			var LumberBox = Panel.FindChildTraverse("LumberBoxText");
			
			// if both text boxes are 0 then there was no intended trade.
			if( GoldBox.text == "0" && LumberBox.text == "0" ){
				//$.Msg("SKIPPING");
				continue;
			}; 
			
			// player trade details
			var TradeDetails = {
				"SendID" : Game.GetLocalPlayerID(),
				"RecieveID" : parseInt(Panel.PlayerID),
				"Gold" : parseInt(GoldBox.text),
				"Lumber" : parseInt(LumberBox.text),
			};
			
			// send trade details to server
			GameEvents.SendCustomGameEventToServer("trading_alliances_trade_confirm", {"Trade" : TradeDetails} );
		};
	};  
	
	ResourceTradingAndAlliances.prototype.CheckLumber = function(pNewLumber){
		// for each existing panel check their current value
		for(var Panel of this.mPlayerPanels)
		{
			var LumberBox = Panel.FindChildTraverse("LumberBoxText");
			if(LumberBox.text > pNewLumber)
				LumberBox.text = pNewLumber;
		};
	};
	
	ResourceTradingAndAlliances.prototype.CheckGold = function(){
		var NewGold = Players.GetGold(Game.GetLocalPlayerID()); 
		// for each existing panel check their current value
		for(var Panel of this.mPlayerPanels)
		{
			var GoldBox = Panel.FindChildTraverse("GoldBoxText");
			if(GoldBox.text > NewGold)
				GoldBox.text = NewGold;
		};
	};
	
    return ResourceTradingAndAlliances;
})();
