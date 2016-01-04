function NetTableListenerUpdater(tableName, key, value){
	if( GameUI.CustomUIConfig.Player[key] != null)
		GameUI.CustomUIConfig.Player[key].Update(value);
};

function InitGoldUpdater(playerID){
	var PlayerGold = Players.GetGold(playerID)
	GameUI.CustomUIConfig.Player[playerID].Update( {gold : playerGold} );	
	
	$.Schedule(0.1, InitGoldUpdater);
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
		}else{
			$.Msg("Player is Spectator, skipping object creation");
		};
	}; 
	
	// print player objects
	for( playerID of PlayerIDList ){
		var playerInfo = Game.GetLocalPlayerInfo(); 
		var playerTeam = playerInfo.player_team_id;
		if( playerTeam != 1 ){
			$.Msg(GameUI.CustomUIConfig.Player[playerID]); 
		}else{
			$.Msg("Player is Spectator, skipping object print");
		};
	};
	
	$.Msg("[CUSTOM PLAYER OBJECT] Setup Complete");
})();