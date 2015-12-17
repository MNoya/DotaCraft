var Root = $.GetContextPanel();
var System;
var ContainerPanel;
(function () {
//	GameEvents.Subscribe( "panaroma_developer", Developer_Mode );
	$.Schedule(1, SetupTradingAndAlliances);
})();

function CancelTrade(){
	HideTradePanel();
	System.ResetPlayersInput();
};

function ConfirmTrade(){
	HideTradePanel();
	System.CompleteTrade();
	System.ResetPlayersInput();
};

function HideTradePanel()
{
	ContainerPanel.style["visibility"] = "collapse";
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
	var LocalID = Game.GetLocalPlayerID();
	Root.LocalPlayerID = LocalID;
	
	System = new ResourceTradingAndAlliances(PlayerContainer);
	$.Msg("setting up trading_alliances");
};