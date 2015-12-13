var Root = $.GetContextPanel();
var System;  
var ContainerPanel;
var PlayerObjectList = new Array();
(function () {
//	GameEvents.Subscribe( "panaroma_developer", Developer_Mode );
	$.Schedule(1, SetupTradingAndAlliances);
})();
 
function CancelTrade(){
	HideTradePanel();
}; 
 
function ConfirmTrade(){
	System.SendPlayersInput();
	HideTradePanel();
};

function LocalPlayerLumberChanged(pNewLumber){
	System.CheckLumber(LocalPlayerLumberChanged);
};

function LocalPlayerGoldChanged(){
	System.CheckGold();
	$.Schedule(1, LocalPlayerGoldChanged);
};

function HideTradePanel()
{
	ContainerPanel.style["visibility"] = "collapse";
	System.ResetPlayersInput();
};

function ToggleRootPanel(){
	if(ContainerPanel.style["visibility"] == "collapse")
		ContainerPanel.style["visibility"] = "visible";
	else
		ContainerPanel.style["visibility"] = "collapse";
	
	System.ResetPlayersInput();
};
 
function SetupTradingAndAlliances(){
	ContainerPanel = Root.FindChildTraverse("TradingAlliancesContainer");
	var PlayerContainer = ContainerPanel.FindChildTraverse("PlayerContainer");

	System = new ResourceTradingAndAlliances(PlayerContainer); 
	$.Msg("setting up trading_alliances");

	// can't put this into my object cause it breaks it somehow, cba figuring out why ;P
	GameEvents.Subscribe( "player_lumber_changed",	LocalPlayerLumberChanged);	
	$.Schedule(1, LocalPlayerGoldChanged);
}; 