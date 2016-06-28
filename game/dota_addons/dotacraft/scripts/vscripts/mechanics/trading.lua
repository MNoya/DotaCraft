if not Trading then
    Trading = class({})
end

function Trading:Init()
    CustomGameEventManager:RegisterListener("trading_alliances_trade_confirm", Dynamic_Wrap(Trading, "Offers")) 

    self.initialized = true
end

function Trading:Offers(args)
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

if not Trading.initialized then Trading:Init() end
