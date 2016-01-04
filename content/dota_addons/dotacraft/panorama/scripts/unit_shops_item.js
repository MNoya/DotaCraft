var Root = $.GetContextPanel()
var LocalPlayerID = Game.GetLocalPlayerID()
var LocalPlayerObject;
function Buy_Item(){	
	if(Root.Revive == null)
		Root.Revive = false
	
	var Player = GameUI.CustomUIConfig.Player[Game.GetLocalPlayerID()];
	
	var event, food_cost, bAllowedToPurchase;
	if(Root.Revive){
		event = "Shops_Buy_Tavern_Revive_Hero"
		food_cost = 5;
		bAllowedToPurchase = Player.HasEnoughFood(5) && Player.HasEnoughLumber(Root.ItemInfo.LumberCost) && Player.HasEnoughGold(Root.ItemInfo.GoldCost) && Root.ItemInfo.CurrentStock > 0;
	}else if(Root.Tavern){
		event = "Shops_Buy_Tavern_Buy_Hero"
		food_cost = 5;
		bAllowedToPurchase = Player.HasEnoughFood(5) && Player.HasEnoughLumber(Root.ItemInfo.LumberCost) && Player.HasEnoughGold(Root.ItemInfo.GoldCost);
	}else{
		event = "Shops_Buy_Item";
		food_cost = 0;
		bAllowedToPurchase = Player.HasEnoughLumber(Root.ItemInfo.LumberCost) && Player.HasEnoughGold(Root.ItemInfo.GoldCost) && Root.ItemInfo.CurrentStock > 0;
	};

	if(bAllowedToPurchase) {
		Root.ItemInfo.CurrentStock -= 1;
		GameEvents.SendCustomGameEventToServer( event, { "PlayerID" : LocalPlayerID, "Shop" : Root.Entity, "ItemName" : Root.ItemName, "GoldCost" : Root.ItemInfo.GoldCost, "LumberCost" : Root.ItemInfo.LumberCost  } );
	}else{
		$.Msg("Not allowed to purchase");
		$.Msg("Food = "+Player.HasEnoughFood(5));
		$.Msg("Lumber = "+Player.HasEnoughLumber(Root.ItemInfo.LumberCost));
		$.Msg("Gold  = "+Player.HasEnoughGold(Root.ItemInfo.GoldCost));
		//if( !LocalPlayerObject.HasEnoughFood(food_cost) )
			
		//else if( !LocalPlayerObject.HasEnoughLumber(Root.ItemInfo.LumberCost) )
			
		//else if( !LocalPlayerObject.HasEnoughGold(Root.ItemInfo.GoldCost) )
		
	};
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
	GameEvents.Subscribe( "unitshop_updateStock", Update_Central);
	
	var itemName = Root.ItemName
	if (itemName.substring(0,6) == "item_")
		itemName = itemName.substring(6)
	
	var image_path = "url('file://{images}/items/"+Root.ItemName+".png');"
	$("#ItemImage").style["background-image"] = image_path 
	
	$( "#GoldCost" ).text = Root.ItemInfo.GoldCost;  
	
	if(Root.ItemInfo.LumberCost != 0){
		$( "#LumberCost" ).text = Root.ItemInfo.LumberCost;
	}else{
		$( "#LumberCost" ).visible = false;
	}
	
	$( "#Stock").text = Root.ItemInfo.CurrentStock;
	
	$( "#ItemName").text = $.Localize(Root.ItemName);
	
	if(Root.ItemInfo.RequiredTier==9000){
		$( "#RequiredTier").text = "You need to upgrade your main building"
		Update_Tier_Required_Panels(Root.Tier)
	}
	else if(Root.ItemInfo.RequiredTier != 1){ 
		$( "#RequiredTier").text = "Requires: "+$.Localize(Root.Race+"_tier_"+Root.ItemInfo.RequiredTier);
		Update_Tier_Required_Panels(Root.Tier)
	}else if(Root.Hero){
		$( "#RequiredTier").text = "Revive this Hero instantly"
	}
	
	LocalPlayerObject = new Player(Game.GetLocalPlayerID());
}

function Update_Central(data){
	// this checks that update is the correct entity shop based on EntityIndex
	if(data.Index != Root.Entity || data.Item.ItemName != Root.ItemName){ 
		//$.Msg(Key+" is not "+Root.Entity) 
		return
	}

	if(data.PlayerID != null){
		if(data.PlayerID != LocalPlayerID){
			$.Msg("Incorrect local PlayerID, returning")
			return
		}
	}
	
	var item = Root.ItemName
	var ItemValues = data.Item

	if(ItemValues.CurrentStock != null){
		Root.ItemInfo.CurrentStock = ItemValues.CurrentStock;
		$("#Stock").text = ItemValues.CurrentStock
	}
	
	if(ItemValues.RestockRate != null){
		if(ItemValues.CurrentRefreshTime > 1){
				$("#ItemMask").visible = true
				//$.Msg(((100 / ItemValues.RestockRate) * ItemValues.CurrentRefreshTime)+"%")
				if( ItemValues.StockStartDelay != null){
					if( ItemValues.StockStartDelay != 0 ){
						$("#ItemMask").style["width"] = 100 - ((100 / ItemValues.StockStartDelay) * ItemValues.CurrentRefreshTime)+"%";
					}else{
						$("#ItemMask").style["width"] = 100 - ((100 / ItemValues.RestockRate) * ItemValues.CurrentRefreshTime)+"%";
					};
				}else{
					$("#ItemMask").style["width"] = 100 - ((100 / ItemValues.RestockRate) * ItemValues.CurrentRefreshTime)+"%";
				};
		}
		else{
				$("#ItemMask").style["width"] = "0px"
				$("#ItemMask").visible = false
		}
	}
	
	// gold update
	if(ItemValues.GoldCost != null || ItemValues.GoldCost != "0"){
		$( "#GoldCost" ).visible = true
		$( "#GoldCost" ).text = ItemValues.GoldCost;
		Root.ItemInfo.GoldCost = ItemValues.GoldCost
	}else{
		$( "#GoldCost" ).visible = false
	}
	// lumber
	if(ItemValues.LumberCost != null || ItemValues.LumberCost != "0"){
		$( "#LumberCost" ).visible = true
		$( "#LumberCost" ).text = ItemValues.LumberCost;
		Root.ItemInfo.LumberCost = ItemValues.LumberCost
	}else{
		$( "#LumberCost" ).visible = false
	}

	if(ItemValues.RequiredTier != null){
		Root.ItemInfo.RequiredTier = ItemValues.RequiredTier
	}
	
	if(Root.Tavern){
		if(!data.Altar){
			$("#RequiredTier").text = "Requires: Altar"
			Update_Tier_Required_Panels(0)
		}else{
			$("#RequiredTier").text = "Upgrade your Main Hall"
		}
			
		if(data.Altar || data.Altar == null){
			Update_Tier_Required_Panels(data.Tier)
		}
	}else{
		Update_Tier_Required_Panels(data.Tier)
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