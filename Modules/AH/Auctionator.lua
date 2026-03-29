local _, GB = ...

local AUCTIONATOR_CALLER = "GatherBuffs"

local source = GB.AHSourceBase:New({
    id = "auctionator",
    label = "Auctionator",
    sortOrder = 50,
    autoOrder = 50,
})

function source:IsAvailable()
    return Auctionator and Auctionator.API and Auctionator.API.v1
        and (Auctionator.API.v1.GetAuctionPriceByItemID or Auctionator.API.v1.GetAuctionPriceByItemLink)
end

function source:GetPrice(itemID)
    local api = Auctionator and Auctionator.API and Auctionator.API.v1
    if not api then
        return nil
    end

    if api.GetAuctionPriceByItemID then
        local ok, value = pcall(api.GetAuctionPriceByItemID, AUCTIONATOR_CALLER, itemID)
        if ok and type(value) == "number" and value > 0 then
            return value
        end
    end

    if api.GetAuctionPriceByItemLink then
        local itemLink = select(2, GetItemInfo(itemID))
        if itemLink then
            local ok, value = pcall(api.GetAuctionPriceByItemLink, AUCTIONATOR_CALLER, itemLink)
            if ok and type(value) == "number" and value > 0 then
                return value
            end
        end
    end

    return nil
end

function source:GetStatusText()
    return "Auctionator: " .. (self:IsAvailable() and "active" or "not found")
end

GB.RegisterAhSource(source)
