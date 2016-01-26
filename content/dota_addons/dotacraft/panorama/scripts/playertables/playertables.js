var PlayerTables = {};
PlayerTables.PLAYERTABLENAME = "dotacraft_player_table";
PlayerTables.COLORTABLENAME = "dotacraft_color_table";

PlayerTables.GetGold = function(pPlayerID){
	return CustomNetTables.GetTableValue( this.PLAYERTABLENAME, pPlayerID).gold;
};

PlayerTables.GetLumber = function(pPlayerID){
	return CustomNetTables.GetTableValue( this.PLAYERTABLENAME, pPlayerID).lumber;
};

PlayerTables.GetColorID = function(pPlayerID){
	return CustomNetTables.GetTableValue( this.PLAYERTABLENAME, pPlayerID).color_id;
};

PlayerTables.GetFoodUsed = function(pPlayerID){
	return CustomNetTables.GetTableValue( this.PLAYERTABLENAME, pPlayerID).food_used;
};

PlayerTables.GetFoodLimit = function(pPlayerID){
	return CustomNetTables.GetTableValue( this.PLAYERTABLENAME, pPlayerID).food_limit;
};

PlayerTables.HasEnoughFood = function(pPlayerID, pFoodAmount){
	var PlayerDetails = CustomNetTables.GetTableValue( this.PLAYERTABLENAME, pPlayerID);
	return ( (PlayerDetails.food_limit - PlayerDetails.food_used) >= pFoodAmount );
};

PlayerTables.HasEnoughGold = function(pPlayerID, pGoldAmount){
	return ( CustomNetTables.GetTableValue( this.PLAYERTABLENAME, pPlayerID).gold >= pGoldAmount );
};

PlayerTables.HasEnoughLumber = function(pPlayerID, pLumberAmount){
	return ( CustomNetTables.GetTableValue( this.PLAYERTABLENAME, pPlayerID).lumber >= pLumberAmount );
};

PlayerTables.GetTechTier = function(pPlayerID){
	return CustomNetTables.GetTableValue( this.PLAYERTABLENAME, pPlayerID).tech_tier;
};

PlayerTables.HasAltar = function(pPlayerID){
	return CustomNetTables.GetTableValue( this.PLAYERTABLENAME, pPlayerID).has_altar;
};

PlayerTables.HeroCount = function(pPlayerID){
	return CustomNetTables.GetTableValue( this.PLAYERTABLENAME, pPlayerID).hero_count;
};

PlayerTables.GetColor = function(pPlayerID){
	var color_index = this.GetColorID(pPlayerID);
	return CustomNetTables.GetTableValue( this.COLORTABLENAME, color_index);
};

(function () {
	$.Msg("[Initializing Custom NetTable Getters]");
})();