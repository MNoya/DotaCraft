
var rootparentORG = $('#HeroPanelsRoot')

function create_hero(data){
	// find the container inside the root
	var parent = $.FindChildInContext('#HeroPanelsContainer', rootparentORG)
	
	// create the Hero Image panel under the parent found above, assigning the panel name "hero_playerid_heroname"
	var hero = $.CreatePanel ('DOTAHeroImage', parent, 'Hero_'+data.playerid+'_'+data.heroname)
	hero.AddClass('HeroImage')
	hero.SetPanelEvent("onactivate", heroSelect(data.hero, data.playerid, data.heroname))
	
	var HeroOverlay = $.CreatePanel ('Panel', hero, 'Hero_Overlay_'+data.playerid+'_'+data.heroname)
	HeroOverlay.AddClass('HeroImageDead')
	HeroOverlay.visible = false
	
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
}

function update_hero(data){
	var playerid = data.playerid
	var heroname = data.heroname
	var hero = data.hero
	
	// calculate percentages
	var	heroHealthPercentage =  Entities.GetHealthPercent(hero)
	var	heroManaPercentage = Entities.GetMana(hero) / Entities.GetMaxMana(hero) * 100
	
	// if hero is dead, enable overlay
	var overlay = $.FindChildInContext('#Hero_Overlay_'+data.playerid+'_'+data.heroname, 'Hero_'+data.playerid+'_'+data.heroname)
	if (Entities.IsAlive(hero) == false) {
		heroHealthPercentage = 0
		heroManaPercentage = 0
	
		overlay.visible = true
	}
	else{
		overlay.visible = false
	}
	
	// find health bar and change health width
	var statusbar = $.FindChildInContext('#Hero_Health_'+data.playerid+'_'+data.heroname, 'Hero_Status_Container_'+data.playerid+'_'+data.heroname)
	statusbar.style['width'] = heroHealthPercentage+'%'
	
	// find mana bar and change mana width
	statusbar = $.FindChildInContext('#Hero_Mana_'+data.playerid+'_'+data.heroname, 'Hero_Status_Container_'+data.playerid+'_'+data.heroname)
	statusbar.style['width'] = heroManaPercentage+'%'
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
	
})();
