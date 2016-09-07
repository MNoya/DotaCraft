var Root = $.GetContextPanel()
var Shops = {}
var LocalPlayerID = Game.GetLocalPlayerID()
var shop_state = "on"

// create shop
function Create_Shop(args){ 
    // create the primary container
    var Container = $.CreatePanel("Panel", Root, args.Index)
    Container.AddClass("Container")
    
    // to lazy to convert to xml
    var Header = $.CreatePanel("Panel", Container, "ShopHeader");
    var HeaderText = $.CreatePanel("Label", Header, "ShopHeaderText");
    HeaderText.text = $.Localize( Entities.GetUnitName( args.Index ) );
    
    var Button = $.CreatePanel("Button", Header, "CloseButton");
    Button.SetPanelEvent('onactivate', (function(){
      return function(){
         Hide_All_Shops();
      };
    })());
    var ButtonLBL = $.CreatePanel("Label", Button, "CloseButtonText")
    ButtonLBL.text = "X";

    // create all the items
    for(var orderIndex in args.Shop){
        var key = args.Shop[orderIndex].ItemName
        $.Msg("Creating "+key)
        var shop_item = $.CreatePanel("Panel", Container, key)
        shop_item.BLoadLayout("file://{resources}/layout/custom_game/unit_shops_item.xml", false, false);
        shop_item.ItemName = key
        shop_item.ItemInfo = args.Shop[orderIndex]
        shop_item.Entity = args.Index
        shop_item.Race = Entities.GetUnitName(args.Index)
        shop_item.Tier = args.Tier
        shop_item.Order = orderIndex
        shop_item.Tavern = args.Tavern != null      
        shop_item.Neutral = args.Neutral
    } 
    
    Shops[args.Index] = args.Shop.Items
    Container.visible = false
    $.Msg("Created Shop: "+Entities.GetUnitName(args.Index))
    //Sort_Shop(Shops[args.Index], args.Index)
}

function CreateHeroPanel(args){
    var ShopUnit = args.Index
    var Shop = Root.FindChildTraverse(ShopUnit)
    var Hero = args.Hero
    var PlayerID = args.playerID
    
    if (Shop == null){
        $.Msg("Retuning, no shop found")
        return
    }
    
    if($("#"+PlayerID+"_"+Hero) != null)
        $("#"+PlayerID+"_"+Hero).RemoveAndDeleteChildren();
        
    var shop_item = $.CreatePanel("Panel", Shop, PlayerID+"_"+Hero)
    shop_item.BLoadLayout("file://{resources}/layout/custom_game/unit_shops_item.xml", false, false);
    shop_item.ItemName = args.Hero
    shop_item.ItemInfo = args.HeroInfo

    shop_item.Entity = args.Index
    shop_item.Hero = true
    
    if(args.Revive != null){
        shop_item.Revive = true
    }else{
        shop_item.Revive = false
    };
}

function CreateItemPanel(args) {
    var shop = Root.FindChildTraverse(args.Index)
    var item = args.ItemInfo.ItemName

    if(shop == null){
        $.Msg("Retuning, can't find shop panel for index "+args.Index)
        return
    }else if (item == null){
        $.Msg("Retuning, no ItemInfo.ItemName passed")
        return
    }

    var shop_item = $.CreatePanel("Panel", shop, Players.GetLocalPlayer()+"_"+item)
    shop_item.BLoadLayout("file://{resources}/layout/custom_game/unit_shops_item.xml", false, false);
    shop_item.ItemName = item
    shop_item.ItemInfo = args.ItemInfo
    shop_item.Entity = args.Index
    shop_item.Tavern = args.Tavern != null
    shop_item.Tier = args.Tier || 0
    shop_item.Neutral = args.Neutral
}

function DeletePanel(args){
    var shopIndex = args.Index
    var itemName = args.ItemName
        
    var container = Root.FindChildTraverse(shopIndex)
    if (container == null){
        $.Msg("Can't find shop for index "+shopIndex)
        return
    }
    var panel = container.FindChildTraverse(LocalPlayerID+"_"+itemName)
    if(panel == null){
        panel = container.FindChildTraverse(itemName)   
    }
    panel.DeleteAsync(0);
}

function Open_Shop(args) {
    var index = args.Shop
    ShowShop(index)
}

function ShowShop(entIndex){
    var PlayerID = Players.GetLocalPlayer();
    var Shop = Root.FindChildTraverse(entIndex)

    $.Msg("ShowShop ",entIndex," for Player "+PlayerID)

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
        Hide_All_Shops()
    else
        GameEvents.SendCustomGameEventToServer("open_closest_shop", {"UnitIndex" : mainSelected});
}

function Hide_All_Shops(){
    //$.Msg("Hide_All_Shops")
    shop_state = "off"
    for(var key in Shops){
        var Shop = Root.FindChildTraverse(key)
        if(Shop.visible == true){
            $.Msg("Set Hidden Shop: ",key)
            Shop.visible = false
        }
    }
}

function Delete_Shop_Content(args){
    var Shop = $("#"+args.Index)
    
    var bChildCount = Shop.GetChildCount()
    // loop and delete all the children
    for(i = 0; i < bChildCount; i++){
        var child = Shop.GetChild(i)
        $.Msg(child)
        if(!child.Revive){
            if(child != null && child.id.indexOf(LocalPlayerID.toString())){
                child.DeleteAsync(0);
            }
        };
    }
}

(function () {
    GameEvents.Subscribe("shops_create", Create_Shop);
    GameEvents.Subscribe("shops_open", Open_Shop);
    GameEvents.Subscribe("shops_create_hero_panel", CreateHeroPanel);
    GameEvents.Subscribe("shops_create_item_panel", CreateItemPanel);
    GameEvents.Subscribe("shops_delete_panel", DeletePanel);
    GameEvents.Subscribe("shops_remove_content", Delete_Shop_Content);
    GameEvents.Subscribe("shop_force_hide", Hide_All_Shops);

    GameUI.Keybinds.ToggleShop = function() { OnShopToggle() }
})();