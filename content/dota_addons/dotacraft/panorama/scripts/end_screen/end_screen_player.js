var Root = $.GetContextPanel();
var AI_Names = {
	8999: "CLOSED",
	9000: "OPEN",
	9001: "COMPUTER (EASY)",
	9002: "COMPUTER (NORMAL)",
	9003: "COMPUTER (HARD)"
};

function SetupPlayer(){
	SetupColumnHeaderChildSizes();
	PlayerInfo = Game.GetPlayerInfo(Root.PlayerID);
		
	// manage name & image
	if( Players.IsValidPlayerID(Root.PlayerID) ){
		PlayerInfo = Game.GetPlayerInfo(Root.PlayerID);
		
		$("#PlayerAvatar").visible = true;
		// assign steamid to avatar and playername panels
		$("#PlayerAvatar").steamid = PlayerInfo.player_steamid;
		$("#PlayerName").GetChild(0).text = PlayerInfo.player_name;
	}else{
		$("#PlayerAvatar").visible = false;
		$("#PlayerName").GetChild(0).text = AI_Names[Root.PlayerID];  
	};
	
	SetupPlayerColors();
	
	Root.UpdateState(Root.state);  
};

function SetupPlayerColors(){ 
	var playerColor = GameUI.CustomUIConfig.GetColor(Root.PlayerID);
	Root.RGB = playerColor;
	
	SetPlayerBackGroundColor(Root.RGB);
};

function SetPlayerBackGroundColor(color){
	Root.style["background-color"] = "rgb("+color.r+","+color.g+","+color.b+")";	
};

// team == true | set color either blue or red depending on enemy flag
// team == false | set playercolor which is stored in Root.RGB
Root.SetTeamColor = function(team, ally){
	if(team){ // set background to blue or red
		if(ally)
			SetPlayerBackGroundColor( {r:0, g:0, b:255} );	
		else
			SetPlayerBackGroundColor( {r:255, g:0, b:0} );
	}else{ // set back to player color
		SetPlayerBackGroundColor(Root.RGB);
	};
};

var lastState = Root.state;
Root.UpdateState = function(newState){
	var newColumns = bodyHeader.GetChild(newState - 1);
	var lastColumns = bodyHeader.GetChild(lastState); 
	
	newColumns.visible = true;
	lastColumns.visible = false;
	
	lastState = newState - 1;
}; 

var bodyHeader = $("#PlayerColumnStats");
function SetupColumnHeaderChildSizes(){
	$.Msg("Setting content width");
	var bodyHeaderChildCount = bodyHeader.GetChildCount();
	for(var i=0; i < bodyHeaderChildCount; i++){
		var child = bodyHeader.GetChild(i);
		var childCount = child.GetChildCount();
		
		// there's about 5-10% of width getting used for margin pushes
		var sizePerChild = 90 / childCount;
		for(var j=0; j < childCount; j++){
			child.GetChild(j).style["width"] = sizePerChild+"%";
		};
	};
};

function UpdatePlayer(data){
	$.Msg(data);
	if(data.key == Root.PlayerID){
		Root.data = data.table;
		$("#UnitScore").text = data.table.unit_score;
		$("#HeroScore").text =  data.table.hero_score;
		$("#ResourceScore").text =  data.table.resource_score;
		$("#TotalScore").text =  data.table.total_score;

		$("#UnitsProduced").text =  data.table.units_produced;
		$("#UnitsKilled").text =  data.table.units_killed;
		$("#BuildingsProduced").text =  data.table.buildings_produced;
		$("#BuildingsRazed").text =  data.table.buildings_razed;
		$("#LargestArmy").text =  data.table.largest_army;

		SetupHeroesUsed(data.table.heroes_used);
		$("#HeroesKilled").text =  data.table.heroes_killed;
		$("#ItemsObtained").text =  data.table.items_obtained;
		$("#MercenariesHired").text =  data.table.mercenaries_hired;
		$("#ExperiencedGained").text =  data.table.experienced_gained;

		$("#GoldMined").text =  data.table.gold_mined;
		$("#LumberHarvested").text =  data.table.lumber_harvested;
		$("#ResourceTraded").text =  data.table.resource_traded;
		$("#TechPercentage").text =  data.table.tech_percentage;
		$("#GoldLostToUpkeep").text =  data.table.gold_lost_to_upkeep;
	};
};

function SetupHeroesUsed(heroes_used){
	var HeroContainer = $("#HeroesHeaders").GetChild(0);
	for(var count in heroes_used){
		$.Msg(count)
		var child = HeroContainer.GetChild(count-1);
		child.heroname = heroes_used[count];
		child.heroimagestyle = "landscape";
	};
};

(function () {
	SetupPlayer();
	GameEvents.Subscribe( "endscreen_data", UpdatePlayer);
})();