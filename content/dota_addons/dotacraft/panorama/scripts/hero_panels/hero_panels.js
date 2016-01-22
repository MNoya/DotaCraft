var Root = $.GetContextPanel();
var heroPanelID = 1;
var container = $("#HeroPanelsContainer");

function CreateHeroPanel(data){
	var unitEntityIndex = data.entityIndex;
	$.Msg("Creating hero name:"+data.name+" index: "+unitEntityIndex);	

	if( $("#"+heroPanelID) == null ){
		var hero = $.CreatePanel ('Panel', container, heroPanelID);
		hero.entityIndex = unitEntityIndex;
		hero.index = heroPanelID;
		hero.BLoadLayout("file://{resources}/layout/custom_game/hero_panels_unit.xml", false, false);

		heroPanelID++;
	};
};

(function () {
	GameEvents.Subscribe( "create_hero", CreateHeroPanel );
})();