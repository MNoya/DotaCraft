var ResourceTradingAndAlliances = (function() {
	function ResourceTradingAndAlliances(pRoot){
		this.mPlayerPanels = new Array();
		this.mRoot = pRoot;
		this.mCurrentTransaction = new Array();
		
		for(var PlayerID of Game.GetAllPlayerIDs()){
			if( Players.IsValidPlayerID(PlayerID) )
				this.mCurrentTransaction[PlayerID] = new Array();
		};
		// setup players 
		this.SetupPlayers(); 
	};

	ResourceTradingAndAlliances.prototype.getPlayerPanel = function(pPlayerID){
		return this.mPlayerPanels[pPlayerID];
	};
 
	ResourceTradingAndAlliances.prototype.getAllPlayerPanels = function(){
		return this.mPlayerPanels;
	};
	
	ResourceTradingAndAlliances.prototype.addPlayerPanel = function(pPlayerID, pPlayerPanel){
		this.mPlayerPanels[pPlayerID] = pPlayerPanel; 
	}; 
		
	ResourceTradingAndAlliances.prototype.SetupPlayers = function(){
		// get local player info 
		var LocalPlayerInfo	= Game.GetLocalPlayerInfo(); 
		var LocalPlayerTeam = LocalPlayerInfo.player_team_id;

		var PlayerIDList = Game.GetPlayerIDsOnTeam(LocalPlayerTeam);
		//var PlayerIDList = Game.GetAllPlayerIDs();
		// loop through all id's found on this team
		for(var PlayerID of PlayerIDList){
			// if valid ID & not local player
			if(	Players.IsValidPlayerID(PlayerID) && Game.GetLocalPlayerID() != PlayerID )
				this.CreatePlayer(PlayerID);
			else if( !Players.IsValidPlayerID(PlayerID) )
				$.Msg("[Resource Trading and Alliances] PlayerID= "+PlayerID+" is not valid, Function=setupPlayers");
		};
	};
	
	// create player panel
	ResourceTradingAndAlliances.prototype.CreatePlayer = function(pPlayerID){ 
		var PlayerPanel = $.CreatePanel("Panel", this.mRoot, pPlayerID);
		PlayerPanel.BLoadLayout("file://{resources}/layout/custom_game/trading_alliances_player.xml", false, false);
		
		PlayerPanel.PlayerID = pPlayerID;
		PlayerPanel.CurrentGold = 0;
		PlayerPanel.CurrentLumber = 0;
		
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
			if(Panel != null){
				var GoldBox = Panel.FindChildTraverse("GoldBoxText");
				var LumberBox = Panel.FindChildTraverse("LumberBoxText");
				GoldBox.text = 0;
				LumberBox.text = 0;
			};
		};
	};
	
	ResourceTradingAndAlliances.prototype.CompleteTrade = function(){
		// for each existing panel reset their input to 0.
		for(var Panel of this.mPlayerPanels)
		{
			if( Panel != null){
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
	};  
	
    return ResourceTradingAndAlliances;
})();
