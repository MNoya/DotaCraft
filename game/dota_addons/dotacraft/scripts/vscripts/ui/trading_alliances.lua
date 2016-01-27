function dotacraft:TradeOffers(args)
	--DeepPrintTable(args.Trade);
	-- not much error handling going on yet, will attempt do most of it at the javascript side
	
	local SendingPlayerID = args.Trade.SendID
	local RecievingPlayerID = args.Trade.RecieveID
	
	local GoldAmount = args.Trade.Gold
	local LumberAmount = args.Trade.Lumber

	-- deduct gold & lumber from sending player
	Players:ModifyLumber(SendingPlayerID, -LumberAmount)
	Players:ModifyGold(SendingPlayerID, -GoldAmount)
	
	-- add gold & lumber to recieving player
	Players:ModifyLumber(RecievingPlayerID, LumberAmount)
	Players:ModifyGold(RecievingPlayerID, GoldAmount)

    Scores:IncrementResourcesTraded( SendingPlayerID, LumberAmount + GoldAmount )
end