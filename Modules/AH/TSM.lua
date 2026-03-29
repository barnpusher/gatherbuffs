local _, GB = ...

local source = GB.AHSourceBase:New({
    id = "tsm",
    label = "TSM",
    sortOrder = 10,
    autoOrder = 10,
})

function source:IsAvailable()
    return TSM_API ~= nil
end

function source:GetPrice(itemID)
    local itemString = "i:" .. itemID
    local customPriceKeys = { "DBMarket", "dbmarket" }

    if TSM_API and TSM_API.GetCustomPriceValue then
        for _, customPriceKey in ipairs(customPriceKeys) do
            local ok, value = pcall(TSM_API.GetCustomPriceValue, customPriceKey, itemString)
            if ok and type(value) == "number" and value > 0 then
                return value
            end
        end
    end
    if TSM_API and TSM_API.FOUR and TSM_API.FOUR.CustomPrice and TSM_API.FOUR.CustomPrice.GetValue then
        for _, customPriceKey in ipairs(customPriceKeys) do
            local ok, value = pcall(TSM_API.FOUR.CustomPrice.GetValue, customPriceKey, itemString)
            if ok and type(value) == "number" and value > 0 then
                return value
            end
        end
    end
    return nil
end

function source:GetStatusText()
    if TSM_API then
        return "TSM: active" .. (TSM_API.FOUR and " (v4)" or " (v3)")
    end
    return "TSM: not found"
end

GB.RegisterAhSource(source)
