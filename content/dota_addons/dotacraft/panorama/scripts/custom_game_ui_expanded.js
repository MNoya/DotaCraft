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

(function () {
	$.Msg("Expanding CustomGameUI functionality");
})();