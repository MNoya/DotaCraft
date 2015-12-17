var Player = (function() {
	
	function Player(pPlayerID)
	{	
		var PlayerDetails = CustomNetTables.GetTableValue( "dotacraft_player_table", pPlayerID);

		this.setPlayerID(pPlayerID);
		this.setLumber(PlayerDetails.lumber);
		this.setGold(Players.GetGold(pPlayerID));
		this.setFoodUsed(PlayerDetails.food_used);
		this.setFoodLimit(PlayerDetails.food_limit);
		this.setColorID(PlayerDetails.Color);
		
		//$.Msg("Player      :"+this.mPlayerID);
		//$.Msg("Food Limit  :"+this.getFoodLimit());
		//$.Msg("Food Used   :"+this.getFoodUsed());
		//$.Msg("Gold        :"+this.getGold());
		//$.Msg("Lumber      :"+this.getLumber());
		//$.Msg("Color       :"+this.getColorID());
	}; 

	Player.prototype.setPlayerID = function(pPlayerID)
	{ 
		this.mPlayerID = pPlayerID;
	};
	Player.prototype.getPlayerID = function()
	{ 
		return this.mPlayerID;
	};
	
	Player.prototype.setLumber = function(pNewLumber){
		this.mLumber = pNewLumber;
	};	
	Player.prototype.getLumber = function(){
		return this.mLumber;
	};
	
	Player.prototype.setGold = function(pNewGold){
		this.mGold = pNewGold;
	};
	Player.prototype.getGold = function(){
		return this.mGold;
	};
	
	Player.prototype.setFoodUsed = function(pNewFoodUsed){
		this.mFoodUsed = pNewFoodUsed;
	};
	Player.prototype.getFoodUsed = function(){
		return this.mFoodUsed;
	};
	
	Player.prototype.setFoodLimit = function(pNewFoodLimit){
		this.mFoodLimit = pNewFoodLimit;
	};
	Player.prototype.getFoodLimit = function(){
		return this.mFoodLimit;
	}; 
	
	Player.prototype.setColorID = function(pColorID){
		this.mColorID = pColorID;
	};
	Player.prototype.getColorID = function(){
		return this.mColorID;
	};
	
	Player.prototype.Update = function(pValue){		
		$.Msg("Updating");
		
		this.setLumber(pValue.lumber);
		this.setGold(pValue.gold);
		this.setFoodUsed(pValue.food_used);
		this.setFoodLimit(pValue.food_limit);
		
		$.Msg("=== "+this.mPlayerID+" ===");
		$.Msg("Gold = "+this.getGold());
		//$.Msg(this.getFoodLimit());
		$.Msg("Lumber = "+this.getLumber());
		//$.Msg(this.getFoodUsed());
		$.Msg("=======");
	};
	
    return Player;
})();