var TeamSelection = (function() {
	function TeamSelection(pRoot, pPlayerLimit, pDropDowns, pTeams){
		this.mPanels = new Array();
		this.mEmptyPanelIDs = new Array();
		this.mRoot = pRoot;
		this.mPlayerLimit = pPlayerLimit;
		this.mDropDowns = pDropDowns;
		this.mTeams = pTeams;
		this.mCount = 0;
		
		// setup players 
		this.SetupPanels(); 
	};

	TeamSelection.prototype.getPanel = function(pPanelID){
		return this.mPanels[pPanelID];
	};
 
	TeamSelection.prototype.getAllPanels = function(){
		return this.mPanels;
	};
	
	TeamSelection.prototype.panelCount = function(){
		return this.mCount;
	};
	
	TeamSelection.prototype.addPanel = function(pID, pPanel){
		this.mPanels[pID] = pPanel;
	}; 
	
	TeamSelection.prototype.isPlayerAssigned = function(pPlayerID){
		var PlayerAlreadyAssigned = false;
		for(var Panels of this.getAllPanels()){			
			if(Panels.PlayerID == pPlayerID)
				PlayerAlreadyAssigned = true;			
		};	
		return PlayerAlreadyAssigned;
	};

	TeamSelection.prototype.assignPlayer = function(pPlayerID, pPanelID){	
		var PlayerPanel = false;
		if( pPanelID == null)
			PlayerPanel = this.FindEmptySlot();
		else
			PlayerPanel = this.getPanel(pPanelID);

		return PlayerPanel;
	};
	
	TeamSelection.prototype.FindEmptySlot = function(){
		var SelectedPanel = false;
		// loop through all panels checking their AI flag
		for(var Panel of this.mPanels.reverse()){
			if ( Panel != null ){
				if( parseInt(Panel.PlayerID) == 9000 ) {
					SelectedPanel = Panel;
				};
			};
		};
		return SelectedPanel;
	};
	
	TeamSelection.prototype.SetupPanels = function(){
		// create panels equal to player limit
		for(var i = 0; i < this.mPlayerLimit; i+=1){
			this.CreateTemplate(i);
		};
	};
	
	TeamSelection.prototype.CreateTemplate = function(pID){
		var TemplatePanel = $.CreatePanel("Panel", this.mRoot, pID);
		TemplatePanel.BLoadLayout("file://{resources}/layout/custom_game/pre_game_player.xml", false, false);
		
		// assign panel values
		TemplatePanel.PanelID = pID;
		TemplatePanel.PlayerID = 9000;
		TemplatePanel.PlayerColor = pID;
		TemplatePanel.PlayerReady = false;
		
		this.mCount+=1;
					
		this.addPanel(pID, TemplatePanel);
	};
	
	TeamSelection.prototype.setFullControl = function(pEnabled){	
		for(var Panel of this.mPanels){
			Panel.enabled = pEnabled;
		};
	};
				
	TeamSelection.prototype.isHost = function(pPlayerID){
		var Player_Info = Game.GetPlayerInfo(pPlayerID)  
		if(!Player_Info)
		{
			$.Msg("Player does not exist = #"+pPlayerID);
			return false;
		};
		return Player_Info.player_has_host_privileges;	
	};

    return TeamSelection;
})();
