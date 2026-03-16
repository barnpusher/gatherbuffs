local _, GB = ...

local AUCTIONATOR_CALLER = "GatherBuffs"

local source = GB.AHSourceBase:New({
    id = "auctionator",
    label = "Auctionator",
    sortOrder = 50,
    autoOrder = 50,
})

function source:IsAvailable()
    return Auctionator and Auctionator.API and Auctionator.API.v1 and Auctionator.API.v1.GetAuctionPriceByItemID
end

function source:GetPrice(itemID)
    if Auctionator and Auctionator.API and Auctionator.API.v1 and Auctionator.API.v1.GetAuctionPriceByItemID then
        local ok, value = pcall(Auctionator.API.v1.GetAuctionPriceByItemID, AUCTIONATOR_CALLER, itemID)
        if ok and value and value > 0 then
            return value
        end
    end
    return nil
end

function source:GetStatusText()
    return "Auctionator: " .. (self:IsAvailable() and "active" or "not found")
end

GB.RegisterAhSource(source)
