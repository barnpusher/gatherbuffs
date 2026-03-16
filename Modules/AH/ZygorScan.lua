local _, GB = ...

local source = GB.AHZygorBase:New({
    id = "zygor_scan",
    label = "Zygor Scan",
    sortOrder = 20,
    autoOrder = 20,
})

function source:IsAvailable()
    return self:HasScanData()
end

function source:GetPrice(itemID)
    if ZGV and ZGV.Gold and ZGV.Gold.Scan and ZGV.Gold.Scan.GetPrice then
        local ok, value = pcall(ZGV.Gold.Scan.GetPrice, ZGV.Gold.Scan, itemID)
        if ok and value and value > 0 then
            return value
        end
    end
    return nil
end

function source:GetStatusText()
    if not (ZGV and ZGV.Gold) then
        return "Zygor Scan: not found"
    end
    return "Zygor Scan: " .. (self:IsAvailable() and "available" or "not available")
end

GB.RegisterAhSource(source)
