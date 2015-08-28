var Root = $.GetContextPanel()
var Shops = {}
var LocalPlayerID = Game.GetLocalPlayerID()

// create shop
function Create_Shop(args){	
	
	// create the primary container
	var Container = $.CreatePanel("Panel", Root, args.Index)
	Container.AddClass("Container")	
	//Container.visible = false
	 
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
	$.Msg("Set Container Invisible ",Container)
	//Sort_Shop(Shops[args.Index], args.Index)
}

function Current_Selected(){
	var PlayerID = Players.GetLocalPlayer();
	var mainSelected = Players.GetLocalPlayerPortraitUnit();
	 
	var Shop = Root.FindChildTraverse(mainSelected)
	if(Shop != null){
		ShowShop(mainSelected)
	}/*else{
		Hide_All_Shops()
	}*/
	
	$.Schedule(0.1, Current_Selected)
}

function ShowShop(entIndex){
	var PlayerID = Players.GetLocalPlayer();
	var Shop = Root.FindChildTraverse(entIndex)

	$.Msg("ShowShop for Player "+PlayerID)

	if(Shop != null){
		$.Msg(" Shop ",entIndex," Visible ",Shop)		
		Shop.visible = true
	}
}

function ShowPlease (index) { 
	var Shop = Root.FindChildTraverse(index)
	if(Shop != null){
		$.Msg(" PLEASE SHOW ",index)
		Shop.visible = true
	}
}

function HideShop(entIndex){
	var PlayerID = Players.GetLocalPlayer();
	var Shop = Root.FindChildTraverse(entIndex)

	$.Msg("HideShop for Player "+PlayerID)
	$.Msg(entIndex," ",Shop)

	Shop.visible = false
}



function Hide_All_Shops(){
	$.Msg("Hide_All_Shops")
	for(var key in Shops){
		var Shop = Root.FindChildTraverse(key)
		if(Shop.visible == true){
			$.Msg("Set Hidden Shop: ",key)
			Shop.visible = false
			$.Msg(Shop)
		}
	}
}

(function () {
	GameEvents.Subscribe( "Shops_Create", Create_Shop);
	
	Current_Selected()
})();