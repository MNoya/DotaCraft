/*

Entry Point object and nettable declaration

	LocalPlayerObject = new Player(Game.GetLocalPlayerID());
	CustomNetTables.SubscribeNetTableListener("dotacraft_player_table", UpdatePlayer);
	
	Functions for updating:
	
	function UpdatePlayerGold(){
		var PlayerGold = Players.GetGold(Game.GetLocalPlayerID());
		LocalPlayerObject.setGold(PlayerGold);
	};

	// function which updates the local player object using nettable
	function UpdatePlayer(TableName, Key, Value){
		if(Key == Game.GetLocalPlayerID())
			LocalPlayerObject.Update(Value);
	};

*/
//GameUI.CustomUIConfig()
var Player = (function() {
	
	function Player(pPlayerID)
	{	
		var PlayerDetails = CustomNetTables.GetTableValue( "dotacraft_player_table", pPlayerID);
		
		this.setPlayerID(pPlayerID);
		$.Msg(PlayerDetails)
		this.Update(PlayerDetails);
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
	
	Player.prototype.setHasAltar = function(pHasAltar){
		this.mHasAltar = pHasAltar;
	};
	Player.prototype.getHasAltar = function(){
		return this.mHasAltar;
	};
	
	Player.prototype.setHeroCount = function(pHeroCount){
		this.mHeroCount = pHeroCount;
	};
	Player.prototype.getHeroCount = function(){
		return this.mHeroCount;
	};
	
	Player.prototype.setTechTier = function(pTechTier){
		this.mTechTier = pTechTier;
	};
	Player.prototype.getTechTier = function(){
		return this.mTechTier;
	};
	
	Player.prototype.HasEnoughFood = function(pFoodAmount, pLocalisedErrorString){
		
		return ( (this.getFoodLimit() - this.getFoodUsed()) >= pFoodAmount )		
	};
	
	Player.prototype.HasEnoughGold = function(pGoldAmount, pLocalisedErrorString){
		
		return ( pGoldAmount <= this.getGold() )
	};
	
	Player.prototype.HasEnoughLumber = function(pLumberAmount, pLocalisedErrorString){
		
		return ( pLumberAmount <= this.getLumber() )
	};
	
	Player.prototype.Update = function(pValue){		
		$.Msg("[PLAYER OBJECT] Updating Player: "+ this.getPlayerID());
		
		if(pValue.lumber){
			this.setLumber(pValue.lumber);
			$.Msg("Updating Lumber = "+this.getLumber());			
		};
		if(pValue.gold){
			this.setGold(pValue.gold);
			$.Msg("Updating Gold = "+this.getGold());
		};
		if(pValue.food_used){
			this.setFoodUsed(pValue.food_used);
			$.Msg("Updating Food Used = "+this.getFoodUsed());
		};
		if(pValue.food_limit){
			this.setFoodLimit(pValue.food_limit)
			$.Msg("Updating Food Limit = "+this.getFoodLimit());
		};
		if(pValue.hero_count){
			this.setHeroCount(pValue.hero_count);
			$.Msg("Updating Hero Count = "+this.getHeroCount());			
		};
		if(pValue.has_altar){
			this.setHasAltar(pValue.has_altar);
			$.Msg("Updating Has Altar = "+ this.getHasAltar());			
		};
		if(pValue.tech_tier){
			this.setTechTier(pValue.tech_tier);
			$.Msg("Updating Tech Tier = "+this.getTechTier());
		};
		
		$.Msg("[PLAYER OBJECT] Finished Updating");
		//$.Msg("Gold = "+this.getGold());
		//$.Msg("Lumber = "+this.getLumber());
		//$.Msg(this.getFoodLimit());
		//$.Msg(this.getFoodUsed());
		//$.Msg("Has Altar = "+ this.getHasAltar());
		//$.Msg("Hero Count = "+this.getHeroCount());
		//$.Msg("Tech Tier = "+this.getTechTier());
		//$.Msg("================ END =====================");
	};
	
    return Player;
})();