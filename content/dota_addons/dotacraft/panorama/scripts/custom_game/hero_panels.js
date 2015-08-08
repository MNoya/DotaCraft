
var rootparentORG = $('#HeroPanelsRoot')

var HeroPanelID = 1
function create_hero(data){
	// find the container inside the root
	var parent = $.FindChildInContext('#HeroPanelsContainer', rootparentORG)
	
	// create the Hero Image panel under the parent found above, assigning the panel name "hero_playerid_heroname"
	var hero = $.CreatePanel ('DOTAHeroImage', parent, HeroPanelID)
	// save paramaters to object
	hero.Inheroid = data.heroid
	hero.Inheroname = data.heroname
	hero.Inhero = data.hero
	hero.Inplayerid = data.playerid
	
	hero.AddClass('HeroImage')
	hero.SetPanelEvent("onactivate", heroSelect(data.hero, data.playerid, data.heroname))
	
	var HeroOverlay = $.CreatePanel ('Panel', hero, 'Hero_Overlay_'+data.playerid+'_'+data.heroname)
	HeroOverlay.AddClass('HeroImageDead')
	HeroOverlay.visible = false
	
	var ReviveButton = $.CreatePanel ('Button', parent, 'Hero_revive_'+data.playerid+'_'+data.heroname)
	ReviveButton.AddClass('HeroReviveButton')
	ReviveButton.visible = false
	ReviveButton.SetPanelEvent("onactivate", heroRevive(data.hero, data.playerid, data.heroname))
	
	var ReviveButtonLBL = $.CreatePanel ('Label', ReviveButton, 'Hero_revive_label_'+data.playerid+'_'+data.heroname)
	ReviveButtonLBL.AddClass('HeroReviveButtonText')
	ReviveButtonLBL.text = "Revive"
	ReviveButtonLBL.hittest = false
	
	var levelup = $.CreatePanel ('Panel', hero, 'Hero_levelup_'+data.playerid+'_'+data.heroname)
	levelup.AddClass('LevelUp')
	levelup.visible = false
	
	var levelupLBL = $.CreatePanel ('Label', levelup, 'Hero_levelup_label_'+data.playerid+'_'+data.heroname)
	levelupLBL.AddClass('LevelUpText')
	levelupLBL.hittest = false
	
	var selectionfocus = $.CreatePanel ('Panel', hero, 'Hero_selectionfocus_'+data.playerid+'_'+data.heroname)
	selectionfocus.AddClass('Focus')
	selectionfocus.visible = false
	
	// assign all the properties for the HeroImage panel
	hero.heroid = data.heroid
	hero.heroname = data.heroname
	hero.heroimagestyle = data.imagestyle

	var HeroStatusContainer = $.CreatePanel ('Panel', parent, 'Hero_Status_Container_'+data.playerid+'_'+data.heroname)
	HeroStatusContainer.AddClass('HeroStatusContainer')
		
	var healthbar = $.CreatePanel ('Panel', HeroStatusContainer, 'Hero_Health_'+data.playerid+'_'+data.heroname)
	healthbar.AddClass('HeroHealthBar')
	
	var manabar = $.CreatePanel ('Panel', HeroStatusContainer, 'Hero_Mana_'+data.playerid+'_'+data.heroname)
	manabar.AddClass('HeroManaBar')
	
	var abilitypoints = $.CreatePanel ('Panel', parent, 'Hero_abilitypoints_'+data.playerid+'_'+data.heroname)
	abilitypoints.AddClass('AbilityPoints')
	abilitypoints.visible = false	

	HeroPanelID = HeroPanelID + 1
}

function OnFirstHeroButtonPressed (args) {
	var playerid = Players.GetLocalPlayer();

	Key_Bind_Pressed(1, playerid)
}

function OnSecondHeroButtonPressed (args) {
	var playerid = Players.GetLocalPlayer();

	Key_Bind_Pressed(2, playerid)
}

function OnThirdHeroButtonPressed (args) {
	var playerid = Players.GetLocalPlayer();

	Key_Bind_Pressed(3, playerid)
}

function Key_Bind_Pressed(key_pressed, playerid){
	
	if ($('#'+key_pressed) != null){	
		var heropanel = $('#'+key_pressed)
		
		// take values from the object and save them
		var hero = heropanel.Inhero
		var heroname = heropanel.Inheroname
		var playerid = heropanel.Inplayerid
		
		clicked_portrait(hero, playerid, heroname) 
	}
}

function update_hero(data){
	var playerid = data.playerid
	var heroname = data.heroname
	var hero = data.hero
	
	// calculate percentages
	var	heroHealthPercentage =  Entities.GetHealthPercent(hero)
	var	heroManaPercentage = Entities.GetMana(hero) / Entities.GetMaxMana(hero) * 100
	
	// set to 0 if hero is dead
	if (Entities.IsAlive(hero) == false) {	
		heroHealthPercentage = 0
		heroManaPercentage = 0
	}
	
	// find health bar and change health width
	var statusbar = $.FindChildInContext('#Hero_Health_'+data.playerid+'_'+data.heroname, 'Hero_Status_Container_'+data.playerid+'_'+data.heroname)
	statusbar.style['width'] = heroHealthPercentage+'%'
	
	// find mana bar and change mana width
	statusbar = $.FindChildInContext('#Hero_Mana_'+data.playerid+'_'+data.heroname, 'Hero_Status_Container_'+data.playerid+'_'+data.heroname)
	statusbar.style['width'] = heroManaPercentage+'%'
	
	//$.Msg(Entities.HasUpgradeableAbilities(hero))
	var overlay = $.FindChildInContext('#Hero_levelup_'+data.playerid+'_'+data.heroname, hero)
	if (data.unspent_points > 0){
		overlay.visible = true
		var overlaytext = overlay.GetChild(0)
		overlaytext.text = data.unspent_points
		$.Msg(overlaytext)
	}
	else{
		overlay.visible = false
	}
	
	// check if any overlays need to be added
	hero_overlay(data)
}

// first true value is saved and then returned so that they don't overlap, meaning the order of importance
function hero_overlay(data){	
	var playerid = data.playerid
	var heroname = data.heroname
	var hero = data.hero
	
	// find panels
	var overlay = $.FindChildInContext('#Hero_Overlay_'+data.playerid+'_'+data.heroname, 'Hero_'+data.playerid+'_'+data.heroname)
	var button = $.FindChildInContext('#Hero_revive_'+data.playerid+'_'+data.heroname, 'Hero_'+data.playerid+'_'+data.heroname)
	var statuscontainer = $.FindChildInContext('#Hero_Status_Container_'+data.playerid+'_'+data.heroname, 'Hero_'+data.playerid+'_'+data.heroname)
	// if hero is dead, enable overlay
	if (Entities.IsAlive(hero) == false) {			
		// set panels visible
		overlay.visible = true
		button.visible = true
		statuscontainer.visible = false		
		return
	}
	else{
		// set panels invisible
		overlay.visible = false
		button.visible = false
		statuscontainer.visible = true
	}
	
	// iterate through the GetSelectedEntities table and find the heroid, if true he is selected  and save that as boolean
	var heroFound = false
	for (i = 0; i < Players.GetSelectedEntities(playerid).length; i++) {
		if(Players.GetSelectedEntities(playerid)[i] == null){
			break
		}
		if (Players.GetSelectedEntities(playerid)[i] == hero){
			heroFound = true
			break;
		}
	}
	
	// if hero not found or not damaged, there's nothing below that has to be done, so return
	var selectionfocus = $.FindChildInContext('#Hero_selectionfocus_'+data.playerid+'_'+data.heroname, 'Hero_Status_Container_'+data.playerid+'_'+data.heroname)
	if (heroFound == false && data.damaged == false){
		selectionfocus.visible = false
		return
	}
	
	// if damage, then hero was damaged, change style
	if (data.damaged){
		selectionfocus.visible = true
		selectionfocus.style["box-shadow"] = "inset 1px 1px 50% red"
		selectionfocus.style["opacity"] = 0.6
		selectionfocus.style["background-color"] = "red"
		return
	}
	
	// if hero found, it has been selected, change style
	if (heroFound){
		selectionfocus.visible = true
		selectionfocus.style["opacity"] = 0.2
		selectionfocus.style["box-shadow"] = "inset 1px 1px 50% gold"
		selectionfocus.style["background-color"] = null
		return
	}
}

// button click variable capture
var heroSelect = (
	function(hero, playerid, heroname)  
	{ 
		return function() 
		{
			clicked_portrait(hero, playerid, heroname)
		}
	});
	
	// button click variable capture
var heroRevive = (
	function(hero, playerid, heroname)  
	{ 
		return function() 
		{
			revive_hero(hero, playerid, heroname)
		}
	});
	
function revive_hero(hero, playerid, heroname){	
	GameEvents.SendCustomGameEventToServer( "revive_hero", { "heroname" : heroname, "playerid" : playerid, "heroindex" : hero} );
}

var double_clicked = []
function clicked_portrait(hero, playerid, heroname){
	// if shift is down, add unit to selection, otherwie focus select
	if (GameUI.IsShiftDown() == true) {
		GameUI.SelectUnit( hero, true )	
	}
	else{
		GameUI.SelectUnit( hero, false )			
	}
	
	// if equal to 2 then panel was double pressed
	double_clicked[playerid] = double_clicked[playerid] + 1
	if (double_clicked[playerid] == 2){
		GameEvents.SendCustomGameEventToServer( "center_hero_camera", { "heroname" : heroname, "playerid" : playerid} );
	}
	
	// reset counter every 0.5 sec
	$.Schedule(0.5, reset_double_clicked)
}
//CustomGameEventManager:RegisterListener( "player_tp", TeleportPlayer )
//function dotacraft:RepositionPlayerCamera( event )	

function reset_double_clicked(){
	var playerid = Game.GetLocalPlayerID()
	double_clicked[playerid] = 0
}

(function () {
	GameEvents.Subscribe( "create_hero", create_hero );
	GameEvents.Subscribe( "update_hero", update_hero );
	
	Game.AddCommand( "+FirstHero", OnFirstHeroButtonPressed, "", 0 );
	Game.AddCommand( "+SecondHero", OnSecondHeroButtonPressed, "", 0 );
	Game.AddCommand( "+ThirdHero", OnThirdHeroButtonPressed, "", 0 );
	
})();
