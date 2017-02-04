// this assumes the panel has .index defined
GameUI.CustomUIConfig.SortByCustomIndex = function( container, bToggle ){
	$.Msg("Sorting child of panel: "+container.id);
	for(var i =0; i < container.GetChildCount() -1; i++){
		for(var j=0; j < container.GetChildCount() - i; j++){
			var child = container.GetChild(j);
			var child2 = container.GetChild(j+1);
			
			if( child2 != null ){
				if( child.index > child2.index){
					container.MoveChildAfter(child, child2);
				};
			};
		};
	};
};

// this assumes the
GameUI.CustomUIConfig.SortByTeamID = function( container, bToggle ){
	$.Msg("Sorting child of panel: "+container.id);
	for(var i =0; i < container.GetChildCount() -1; i++){
		for(var j=0; j < container.GetChildCount() - i; j++){
			var child = container.GetChild(j);
			var child2 = container.GetChild(j+1);
			
			var teamID = Players.GetTeam(child.PlayerID);
			
			if( child2 != null ){
				var teamID2 = Players.GetTeam(child2.PlayerID);
				if( teamID > teamID2 ){
					container.MoveChildAfter(child, child2);
				};
			};
		};
	};
};

// Functionality, not used haven't tested if it works
GameUI.CustomUIConfig.SwapChildren = function(container, child, child2){
	
	if( this.isNumber(child) && this.isNumber(child2) ){ // both children are index'
		container.MoveChildBefore( container.GetChild(child),  container.GetChild(child2) );
		container.MoveChildBefore( container.GetChild(child2),  container.GetChild(child) );
	}else if( this.isNumber(child) || this.isNumber(child2) ){ // children are different (index and object)
		$.Msg("Provide either indexes or child objects, don't do both bruv");
	}else{ // both children are objects
		var temp = child.id;
		container.MoveChildBefore( child,  child2 );
		container.MoveChildBefore( child2,  container.GetChild(temp) );
	};
};

GameUI.CustomUIConfig.isNumber = function( value ){
	return !isNan(value);
};

Entities.HasModifier = function(entIndex, modifierName){
	var nBuffs = Entities.GetNumBuffs(entIndex)
	for (var i = 0; i < nBuffs; i++) {
		if (Buffs.GetName(entIndex, Entities.GetBuff(entIndex, i)) == modifierName)
			return true
	};
	return false
};

function CreateErrorMessage(msg){
    var reason = msg.reason || 80;
    if (msg.message){
        GameEvents.SendEventClientSide("dota_hud_error_message", {"splitscreenplayer":0,"reason":reason ,"message":msg.message} );
    }
    else{
        GameEvents.SendEventClientSide("dota_hud_error_message", {"splitscreenplayer":0,"reason":reason} );
    }
}

GameUI.CreateErrorMessage = CreateErrorMessage;

(function(){
    GameEvents.Subscribe("dotacraft_error_message", CreateErrorMessage)

    // DOTAHud Hud
	var hud = $.GetContextPanel().GetParent().GetParent().GetParent();

	// Remove talent tree and backpack
	var newUI = hud.FindChildTraverse("HUDElements").FindChildTraverse("lower_hud").FindChildTraverse("center_with_stats").FindChildTraverse("center_block");
	newUI.FindChildTraverse("StatBranch").FindChildTraverse("StatBranchGraphics").FindChildTraverse("StatBranchChannel").style.visibility = "collapse";
	newUI.FindChildTraverse("StatBranch").FindChildTraverse("StatBranchBG").style.visibility = "collapse";
	newUI.FindChildTraverse("StatBranch").SetPanelEvent("onmouseover", function(){});
	newUI.FindChildTraverse("StatBranch").SetPanelEvent("onactivate", function(){});
	newUI.FindChildTraverse("inventory").FindChildTraverse("inventory_items").FindChildTraverse("inventory_backpack_list").style.visibility = "collapse";

	// Remove Scan and Glyph
	var glyphScanContainer = hud.FindChildTraverse("HUDElements").FindChildTraverse("lower_hud").FindChildTraverse("GlyphScanContainer");
	glyphScanContainer.FindChildTraverse("RadarButton").style.visibility = "collapse";

	// Fix side info panel
	var gameinfo = hud.FindChildTraverse("CustomUIRoot").FindChildTraverse("CustomUIContainer_GameInfo");
	gameinfo.FindChildTraverse("GameInfoPanel").style['margin-top'] = "0px";
	gameinfo.FindChildTraverse("GameInfoButton").style.transform = "translateY(120px)";

	// Fix gap next to abilities from ability tree
	newUI.FindChildTraverse("StatBranch").style.visibility = "collapse";

	newUI.FindChildTraverse("AbilitiesAndStatBranch").style.minWidth = "800px";
	newUI.FindChildTraverse("center_bg").style.height = "220px";

    $.Msg("Expanding CustomGameUI functionality");
})()