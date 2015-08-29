var Root = $.GetContextPanel()
var Shops = {}
var LocalPlayerID = Game.GetLocalPlayerID()
var shop_state = "on"

// create shop
function Create_Shop(args){	
	
	// create the primary container
	var Container = $.CreatePanel("Panel", Root, args.Index)
	Container.AddClass("Container")	
	 
	// create all the items
	for(var Item in args.Shop.Items){
		var shop_item = $.CreatePanel("Panel", Container, Item)
		shop_item.BLoadLayout("file://{resources}/layout/custom_game/unit_shops_item.xml", false, false);
		shop_item.ItemName = Item
		shop_item.ItemInfo = args.Shop.Items[Item]
		shop_item.Entity = args.Index
		shop_item.Race = args.Race
		shop_item.Tier = args.Tier
	} 
	
	Shops[args.Index] = args.Shop.Items
	Container.visible = false
	//Sort_Shop(Shops[args.Index], args.Index)
}

function Current_Selected(){
	var PlayerID = Players.GetLocalPlayer();
	var mainSelected = Players.GetLocalPlayerPortraitUnit();
	 
	/*var Shop = Root.FindChildTraverse(mainSelected)
	if(Shop != null){
		ShowShop(mainSelected)
	}else{
		Hide_All_Shops()
	}
	
	$.Schedule(0.1, Current_Selected)*/
}

function Open_Shop(args) {
	var index = args.Shop
	ShowShop(index)
}

function ShowShop(entIndex){
	var PlayerID = Players.GetLocalPlayer();
	var Shop = Root.FindChildTraverse(entIndex)

	$.Msg("ShowShop ",entIndex,"for Player "+PlayerID)

	if(Shop != null){
		$.Msg(" Shop ",entIndex," is now Visible")		
		Shop.visible = true
		shop_state = "on"
	}
}

function HideShop(entIndex){
	var PlayerID = Players.GetLocalPlayer();
	var Shop = Root.FindChildTraverse(entIndex)

	$.Msg("HideShop ",entIndex," for Player "+PlayerID)

	Shop.visible = false
	shop_state = "off"
}

function OnShopToggle() {
	var PlayerID = Players.GetLocalPlayer();
	var mainSelected = Players.GetLocalPlayerPortraitUnit();

	// If shop isn't open, try to open the shop closest to the main selected unit
	// If the shop panel is open, close it
	if (shop_state == "on")
	{
		Hide_All_Shops()
	}
	else
	{
		GameEvents.SendCustomGameEventToServer( "open_closest_shop", { "PlayerID" : LocalPlayerID, "UnitIndex" : mainSelected } );
	}

}

function Hide_All_Shops(){
	$.Msg("Hide_All_Shops")
	shop_state = "off"
	for(var key in Shops){
		var Shop = Root.FindChildTraverse(key)
		if(Shop.visible == true){
			$.Msg("Set Hidden Shop: ",key)
			Shop.visible = false
		}
	}
}

Game.AddCommand( "+ToggleShop", OnShopToggle, "", 0 );

(function () {
	GameEvents.Subscribe( "Shops_Create", Create_Shop);
	GameEvents.Subscribe( "Shops_Open", Open_Shop);
})();