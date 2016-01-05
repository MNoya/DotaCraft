function NetTableListenerUpdater(tableName, key, value){
	if( GameUI.CustomUIConfig.Player[key] != null)
		GameUI.CustomUIConfig.Player[key].Update(value);
};

function InitGoldUpdater(playerID){
	var playerGold = Players.GetGold(playerID)
	
	GameUI.CustomUIConfig.GetPlayer(playerID).Update( {gold : playerGold} );	
	
	$.Schedule(0.01, InitGoldUpdater);
};

(function () {
	$.Msg("[CUSTOM PLAYER OBJECT] Setup Started");
	CustomNetTables.SubscribeNetTableListener( "dotacraft_player_table", NetTableListenerUpdater );
	// create player table
	GameUI.CustomUIConfig.Player = {};
	
	var PlayerIDList = Game.GetAllPlayerIDs();
		
	// create player objects
	for( playerID of PlayerIDList ){
		var playerInfo = Game.GetLocalPlayerInfo(); 
		var playerTeam = playerInfo.player_team_id;
		if( playerTeam != 1 ){
			GameUI.CustomUIConfig.Player[playerID] = new Player(playerID);
			InitGoldUpdater(playerID);
		}else{
			$.Msg("Player is Spectator, skipping object creation");
		};
	}; 
	//
	// Defined Non-Player Object Functions
	//
	GameUI.CustomUIConfig.GetPlayer = function(pPlayerID){
		return this.Player[pPlayerID];
	};
	
	// print player objects
	for( playerID of PlayerIDList ){
		var playerInfo = Game.GetLocalPlayerInfo(); 
		var playerTeam = playerInfo.player_team_id;
		if( playerTeam != 1 ){
			$.Msg( GameUI.CustomUIConfig.GetPlayer(playerID) ); 
		}else{
			$.Msg("Player is Spectator, skipping object print");
		};
	};
	

	
	$.Msg("[CUSTOM PLAYER OBJECT] Setup Complete");
})();