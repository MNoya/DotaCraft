var Root = $.GetContextPanel()
var LocalPlayerID = Game.GetLocalPlayerID()

function Buy_Item(){    
    if(Root.Revive == null)
        Root.Revive = false
    
    var event, food_cost;
    var EnoughFood = true;
    var EnoughStock = true;
    if(Root.Revive){ // Tavern purchase - Revive hero
        food_cost = 5;
        event = "shops_tavern_revive_hero"
        
        EnoughFood = PlayerTables.HasEnoughFood(LocalPlayerID, food_cost);
        
    }else if(Root.Tavern){ // Tavern purchase - buying a hero
        food_cost = 5;
        event = "shops_tavern_buy_hero"
        
        EnoughFood = PlayerTables.HasEnoughFood(LocalPlayerID, food_cost);
        
    }else{ // Item
        event = "shops_buy_item";
        if (Root.Neutral)
            EnoughFood = PlayerTables.HasEnoughFood(LocalPlayerID, Root.ItemInfo.FoodCost);
            
        EnoughStock = Root.ItemInfo.CurrentStock > 0;
    };
    
    var EnoughLumber = PlayerTables.HasEnoughLumber(LocalPlayerID, Root.ItemInfo.LumberCost);
    var EnoughGold = PlayerTables.HasEnoughGold(LocalPlayerID, Root.ItemInfo.GoldCost);

    var bAllowedToPurchase = EnoughLumber && EnoughGold && EnoughStock && EnoughFood;

    if(bAllowedToPurchase) {
        if(Root.ItemInfo != 0)
            Root.ItemInfo.CurrentStock -= 1;
        
        GameEvents.SendCustomGameEventToServer(event, {"PlayerID":LocalPlayerID, "Shop":Root.Entity, "ItemName":Root.ItemName, "GoldCost":Root.ItemInfo.GoldCost, "LumberCost":Root.ItemInfo.LumberCost, "Neutral":Root.Neutral});
    }else{
        $.Msg("[UNIT SHOPS] Declined Player: "+Game.GetLocalPlayerID()+" from buying: "+Root.ItemName);
        //$.Msg("Enough Food = "+EnoughFood);
        //$.Msg("Enough Lumber = "+EnoughLumber);
        //$.Msg("Enough Gold  = "+EnoughGold);
        //$.Msg("Enough Stock = "+EnoughStock);
        
        var errorString = "";
        if(!EnoughFood)
            errorString = "#shops_not_enough_food";
        else if(!EnoughStock)
            errorString = "#shops_not_enough_stock";
        else if(!EnoughLumber)
            errorString = "#shops_not_enough_lumber";   
        else if(!EnoughGold)
            errorString = "#shops_not_enough_gold";
        else
            errorString = "dafuq how did I get here?";
        
        GameUI.CreateErrorMessage({message : errorString})
    };
}

function ShowToolTip(){ 
    var abilityButton = $("#ItemButton");
    if(!Root.Revive) // normal tooltip -- any non-revive function
        $.DispatchEvent("DOTAShowAbilityTooltip", abilityButton, Root.ItemName);
    else
        $.DispatchEvent("DOTAShowAbilityTooltip", abilityButton, "UI_UNITSHOPS_PLACEHOLDER_Hero_Revive");     
}

function HideToolTip(){
    var abilityButton = $("#ItemButton");
    $.DispatchEvent("DOTAHideAbilityTooltip", abilityButton);
}

function Setup_Panel(){ 
    GameEvents.Subscribe("shop_update_stock", Update_Central);
    
    var itemName = Root.ItemName
    if (itemName.substring(0,5) == "item_")
        itemName = itemName.substring(5)
    
    var image_path = "url('file://{images}/items/"+itemName+".png');"
    $("#ItemImage").style["background-image"] = image_path 
    
    $("#GoldCost").text = Root.ItemInfo.GoldCost;  
    
    if(Root.ItemInfo.LumberCost != 0){
        $("#LumberCost").text = Root.ItemInfo.LumberCost;
    }else{
        $("#LumberCost").visible = false;
    }
    
    $("#Stock").text = Root.ItemInfo.CurrentStock;
    
    if(Root.ItemInfo.FoodCost != null && Root.ItemInfo.FoodCost != 0)
        $("#Food").text = Root.ItemInfo.FoodCost;   
    else
        $("#FoodPanel").visible = false;
    
    if ($.Localize(Root.ItemName) != Root.ItemName)
        $("#ItemName").text = $.Localize(Root.ItemName)
    else
        $("#ItemName").text = $.Localize("DOTA_Tooltip_ability_"+Root.ItemName);
    
    if(Root.ItemInfo.RequiredTier==9000){
        $("#RequiredTier").text = "You need to upgrade your main building"
        Update_Tier_Required_Panels(Root.Tier)
    }
    else if(Root.ItemInfo.RequiredTier != 1){ 
        $("#RequiredTier").text = "Requires: "+$.Localize(Root.Race+"_tier_"+Root.ItemInfo.RequiredTier);
        Update_Tier_Required_Panels(Root.Tier)
    }else if(Root.Hero){
        $("#RequiredTier").text = "Revive this Hero instantly"
    }
}

function Update_Central(data){
    // this checks that update is the correct entity shop based on EntityIndex
    if(data.Index != Root.Entity || data.Item.ItemName != Root.ItemName){ 
        //$.Msg(Key+" is not "+Root.Entity) 
        return
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
                if(ItemValues.StockStartDelay != null){
                    if(ItemValues.StockStartDelay != 0){
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
        $("#GoldCost").visible = true
        $("#GoldCost").text = ItemValues.GoldCost;
        Root.ItemInfo.GoldCost = ItemValues.GoldCost
    }else{
        $("#GoldCost").visible = false
    }
    // lumber
    if(ItemValues.LumberCost != null || ItemValues.LumberCost != "0"){
        $("#LumberCost").visible = true
        $("#LumberCost").text = ItemValues.LumberCost;
        Root.ItemInfo.LumberCost = ItemValues.LumberCost
    }else{
        $("#LumberCost").visible = false
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
    $.Schedule(0.1, Setup_Panel)    
})();