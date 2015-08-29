var Root = $.GetContextPanel()
var LocalPlayerID = Game.GetLocalPlayerID()

function Buy_Item(){	

	GameEvents.SendCustomGameEventToServer( "Shops_Buy", { "PlayerID" : LocalPlayerID, "Shop" : Root.Entity, "ItemName" : Root.ItemName, "Hero" : Root.Hero, "GoldCost" : Root.ItemInfo.GoldCost, "LumberCost" : Root.ItemInfo.LumberCost, "Tavern" : Root.Tavern } );
}

function ShowToolTip(){ 
	var abilityButton = $( "#ItemButton" );
	$.DispatchEvent( "DOTAShowAbilityTooltip", abilityButton, Root.ItemName );
}

function HideToolTip(){
	var abilityButton = $( "#ItemButton" );
	$.DispatchEvent( "DOTAHideAbilityTooltip", abilityButton );
}

function Setup_Panel(){
	CustomNetTables.SubscribeNetTableListener("dotacraft_shops_table", Update_Central);
	
	var image_path = "url('file://{images}/items/"+Root.ItemName+".png');"
	$("#ItemImage").style["background-image"] = image_path 
	
	$( "#GoldCost" ).text = Root.ItemInfo.GoldCost;  
	
	if(Root.ItemInfo.LumberCost != "0"){
		$( "#LumberCost" ).text = Root.ItemInfo.LumberCost;
	}else{
		$( "#LumberCost" ).visible = false;
	}
	
	$( "#Stock").text = Root.ItemInfo.CurrentStock;
	
	$( "#ItemName").text = $.Localize(Root.ItemName);
	
	if(Root.ItemInfo.RequiredTier == 9000){
		$( "#RequiredTier").text = "Coming Soon ™"
		Update_Tier_Required_Panels(Root.Tier)
	}
	else if(Root.ItemInfo.RequiredTier != 1){ 
		$( "#RequiredTier").text = "Requires: "+$.Localize(Root.Race+"_tier_"+Root.ItemInfo.RequiredTier);
		Update_Tier_Required_Panels(Root.Tier)
	}else if(Root.Hero){
		$( "#RequiredTier").text = "Revive this Hero instantly"
	}
}

function Update_Central(TableName, Key, Value){
	// this checks that update is the correct entity shop based on EntityIndex
	if(Key != Root.Entity){ 
		$.Msg(Key+" is not "+Root.Entity) 
		return
	}

	if(Value.PlayerID != null){
		if(Value.PlayerID != LocalPlayerID){
			$.Msg("Incorrect local PlayerID, returning")
			return
		}
	}
	
	var item = Root.ItemName
	var ItemValues
	if(Value.Hero){
		ItemValues = Value.Shop[item]
	}else{ 
		//$.Msg("Updating a Item")
		ItemValues = Value.Shop.Items[item]
	}
	
	if(ItemValues.CurrentStock != null){
		$( "#Stock").text = ItemValues.CurrentStock
	}
	
	// gold update
	if(ItemValues.GoldCost != null){
		$( "#GoldCost" ).text = ItemValues.GoldCost;
		Root.ItemInfo.GoldCost = ItemValues.GoldCost
	}
	// lumber
	if(ItemValues.LumberCost != "0"){
		$( "#LumberCost" ).text = ItemValues.LumberCost;
		Root.ItemInfo.LumberCost = ItemValues.LumberCost
	}
	
	if(ItemValues.RequiredTier != null){
		Root.ItemInfo.RequiredTier = ItemValues.RequiredTier
	}
	
	if(Value.Tier != null){
		Update_Tier_Required_Panels(Value.Tier)
	}		
}

function Update_Tier_Required_Panels(tier){
	
	if(tier >= Root.ItemInfo.RequiredTier)
	{
		$("#RequiredTier").visible = false
		$("#ItemButton").enabled = true
	}else{
		$("#ItemButton").enabled = false
		$("#RequiredTier").visible = true
	}
}


(function () { 
	$.Schedule( 0.1, Setup_Panel)
	
})();