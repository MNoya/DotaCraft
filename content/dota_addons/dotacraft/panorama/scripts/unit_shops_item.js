var Root = $.GetContextPanel()
var LocalPlayerID = Game.GetLocalPlayerID()

function Buy_Item(){
	GameEvents.SendCustomGameEventToServer( "Shops_Buy", { "PlayerID" : LocalPlayerID, "Shop" : Root.Entity, "ItemName" : Root.ItemName } );
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
	CustomNetTables.SubscribeNetTableListener("dotacraft_shops_table", Update_Item);
 
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
	
	if(Root.ItemInfo.RequiredTier != 1){
		$( "#RequiredTier").text = "Requires: "+$.Localize(Root.Race+"_tier_"+Root.ItemInfo.RequiredTier);
		Update_Tier_Required_Panels(Root.Tier)
	}
}

function Update_Item(TableName, Key, Value){
	// this checks that update is the correct entity shop based on EntityIndex
	if(Key != Root.Entity){ 
		$.Msg(Key+" is not "+Root.Entity) 
		return
	}
	
	var item = Root.ItemName
	$( "#Stock").text = Value.Shop.Items[item].CurrentStock
	
	Update_Tier_Required_Panels(Value.Tier)

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