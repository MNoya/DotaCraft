(function () {
	$.Msg("[Initializing Custom NetTable Getters]");
	
	// CONST string to indicate the player net table name
	GameUI.CustomUIConfig.PLAYERTABLENAME = "dotacraft_player_table";
	
	GameUI.CustomUIConfig.GetGold = function(pPlayerID){
		return CustomNetTables.GetTableValue( this.PLAYERTABLENAME, pPlayerID).gold;
	};
	
	GameUI.CustomUIConfig.GetLumber = function(pPlayerID){
		return CustomNetTables.GetTableValue( this.PLAYERTABLENAME, pPlayerID).lumber;
	};
	
	GameUI.CustomUIConfig.GetColorID = function(pPlayerID){
		return CustomNetTables.GetTableValue( this.PLAYERTABLENAME, pPlayerID).color_id;
	};
	
	GameUI.CustomUIConfig.GetFoodUsed = function(pPlayerID){
		return CustomNetTables.GetTableValue( this.PLAYERTABLENAME, pPlayerID).food_used;
	};
	
	GameUI.CustomUIConfig.GetFoodLimit = function(pPlayerID){
		return CustomNetTables.GetTableValue( this.PLAYERTABLENAME, pPlayerID).food_limit;
	};
	
	GameUI.CustomUIConfig.HasEnoughFood = function(pPlayerID, pFoodAmount){
		var PlayerDetails = CustomNetTables.GetTableValue( this.PLAYERTABLENAME, pPlayerID);
		return ( (PlayerDetails.food_limit - PlayerDetails.food_used) >= pFoodAmount )
	};
	
	GameUI.CustomUIConfig.HasEnoughGold = function(pPlayerID, pGoldAmount){
		return ( CustomNetTables.GetTableValue( this.PLAYERTABLENAME, pPlayerID).gold >= pGoldAmount );
	};
	
	GameUI.CustomUIConfig.HasEnoughLumber = function(pPlayerID, pLumberAmount){
		return ( CustomNetTables.GetTableValue( this.PLAYERTABLENAME, pPlayerID).lumber >= pLumberAmount );
	};
	
	GameUI.CustomUIConfig.GetTechTier = function(pPlayerID){
		return CustomNetTables.GetTableValue( this.PLAYERTABLENAME, pPlayerID).tech_tier;		
	};
	
	GameUI.CustomUIConfig.HasAltar = function(pPlayerID){
		return CustomNetTables.GetTableValue( this.PLAYERTABLENAME, pPlayerID).has_altar;		
	};
	
	GameUI.CustomUIConfig.HeroCount = function(pPlayerID){
		return CustomNetTables.GetTableValue( this.PLAYERTABLENAME, pPlayerID).hero_count;		
	};
	
	$.Msg("[Finished Initializing Custom NetTable Getters]");
})();