var Root = $.GetContextPanel();
var unit = Root.entityIndex;
var playerID = Game.GetLocalPlayerID();

function ReviveHero(){
	GameEvents.SendCustomGameEventToServer( "revive_hero", { "heroname" : Root.name, "heroindex" : Root.entityIndex} );
};

function SelectHero(){
	// if shift is down, add unit to selection, otherwie focus select
	if (GameUI.IsShiftDown() == true) {
		GameUI.SelectUnit(unit, true);
	}else{
		GameUI.SelectUnit(unit, false);	
	};

	if( WasMouseDoubleClicked() )
		GameEvents.SendCustomGameEventToServer( "reposition_player_camera", { entIndex: unit} );
};

var lastTime = 0;
var DOUBLE_CLICK_THRESHOLD = 0.5;
function WasMouseDoubleClicked(){
	var time = Game.GetGameTime();
	var lastClick = time - lastTime;
	var doubleClicked = false;
	
	if (lastClick <= DOUBLE_CLICK_THRESHOLD)
		doubleClicked = true;
		
	lastTime = time;	
	return doubleClicked;
};

function Update(){

	UpdateUnitHealthAndMana();
	UpdateUnitAbilityPoints();
	UpdateHeroOverlay();
	
	$.Schedule(0.1, Update);
};

function UpdateUnitHealthAndMana(){
	// calculate percentages
	var	heroHealthPercentage =  Entities.GetHealthPercent(unit);
	var	heroManaPercentage = Entities.GetMana(unit) / Entities.GetMaxMana(unit) * 100;
	
	// set to 0 if unit is dead
	if ( !Entities.IsAlive(unit)) {	
		heroHealthPercentage = 0;
		heroManaPercentage = 0;
	};

	// set health & mana width
	$("#HeroHealthBar").style['width'] = heroHealthPercentage+'%';
	$("#HeroManaBar").style['width'] = heroManaPercentage+'%';
};

function UpdateUnitAbilityPoints(){	
	var abilityPoints = getAbilityPoints();
	var pointsPanel = $("#AbilityPoints");
	var pointsPanelText = $("#AbilityPointsText");
	
	if ( abilityPoints > 0 ){	
		pointsPanel.visible = true
		pointsPanelText.text = abilityPoints;
	}
	else{
		pointsPanel.visible = false
	};
};

function getAbilityPoints(){
	return Entities.GetAbilityPoints(unit);
};

// hero panel overlay manager
var ITERATION_TRESHOLD = 15;
var currentIteration = 0;
var GracePeroid = false;
var UnderAttack = false;
function UpdateHeroOverlay(){	
	// find panels
	var overlay = $("#HeroOverlay");
	var reviveButton = $("#HeroReviveButton");
	var statusContainer = $("#HeroStatusContainer");
	
	var isAlive = Entities.IsAlive(unit);
	var isSelected = isUnitSelected();
	var gotAttacked = isUnitUnderAttack();

	if((gotAttacked || UnderAttack) && !GracePeroid){
		UnderAttack = true
		currentIteration++;
		
		if(currentIteration >= ITERATION_TRESHOLD){
			GracePeroid = true;
			UnderAttack = false;
		};
	}else if(GracePeroid){	
		currentIteration++;
		
		if(currentIteration >= ITERATION_TRESHOLD)
			GracePeroid = false
	};
	
	overlay.SetHasClass("AttackedOverlay", UnderAttack);	
	overlay.SetHasClass("FocusOverlay", ( isSelected && !UnderAttack ));
	
	// visibility tied to state of unit
	overlay.SetHasClass("DeadOverlay", !isAlive);
	reviveButton.visible = !isAlive;
	if(!isAlive){
		overlay.SetHasClass("FocusOverlay", false);
		overlay.SetHasClass("AttackedOverlay", false);
	};
	
	if(isAlive && !isSelected && !gotAttacked)
		overlay.visible = false;
	else
		overlay.visible = true;
	
	if(currentIteration >= ITERATION_TRESHOLD || !isAlive)
		currentIteration = 0;
};

var lastHealth = 0;
function isUnitUnderAttack(){	
	var currentHealth = Entities.GetHealth(unit);
	var underAttack = false;
	
	if( currentHealth < lastHealth)
		underAttack = true;
	
	lastHealth = currentHealth;
	return underAttack; 
};

function isUnitSelected(){
	var selected = false;
	for (i = 0; i < Players.GetSelectedEntities(playerID).length; i++) {
		if (Players.GetSelectedEntities(playerID)[i] == unit){
			selected = true;
			break;
		};
	};
	return selected;
};

(function () {
	$("#AbilityPoints").visible = false;
	$("#HeroOverlay").visible = false;
	$("#HeroReviveButton").visible = false;
	
	$("#HeroImage").heroid = Root.heroImageID;
	$("#HeroImage").heroname = Entities.GetUnitName(unit);
	$("#HeroImage").heroimagestyle = "landscape";
	
	Update();
	
	Game.AddCommand( "+SelectHeropanel"+Root.index, SelectHero, "", 0 );
})();