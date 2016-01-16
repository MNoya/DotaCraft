var Root = $.GetContextPanel();
var heroPanelID = 1;
var container = $("#HeroPanelsContainer");

function CreateHeroPanel(data){
	var unitName = data.name;
	var unitEntityIndex = data.entityIndex;
	var heroImageID = data.heroImageID
	$.Msg("Creating hero name:"+data.name+" index: "+unitEntityIndex);	

	// create the Hero Image panel under the parent found above, assigning the panel name "hero_playerid_heroname"
	var hero = $.CreatePanel ('Panel', container, heroPanelID);
	hero.name = unitName
	hero.entityIndex = unitEntityIndex;
	hero.index = heroPanelID;
	hero.heroImageID = heroImageID;
	hero.BLoadLayout("file://{resources}/layout/custom_game/hero_panels_unit.xml", false, false);

	heroPanelID++;
};

(function () {
	GameEvents.Subscribe( "create_hero", CreateHeroPanel );
})();