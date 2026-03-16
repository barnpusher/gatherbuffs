local _, GB = ...

local ZygorBase = GB.AHSourceBase:New()
ZygorBase.__index = ZygorBase

function ZygorBase:GetTrendItem(itemID)
    if not (ZGV and ZGV.Gold) then
        return nil
    end
    local trends = ZGV.Gold.servertrends or ZGV.Gold.ServerTrends or ZGV.Gold.ServerTrend
    if trends and trends.items and trends.items[itemID] then
        return trends.items[itemID]
    end
    local globalTrends = ZGV.Gold.servertrends_global
    if globalTrends and globalTrends.items then
        return globalTrends.items[itemID]
    end
    return nil
end

function ZygorBase:HasScanData()
    if not (ZGV and ZGV.Gold and ZGV.Gold.Scan and ZGV.Gold.Scan.data) then
        return false
    end
    local data = ZGV.Gold.Scan.data
    local today = data.today
    return type(today) == "number" and type(data[today]) == "table" and next(data[today]) ~= nil
end

function ZygorBase:HasTrendData()
    if not (ZGV and ZGV.Gold) then
        return false
    end
    local trends = ZGV.Gold.servertrends
    if trends and type(trends.items) == "table" and next(trends.items) ~= nil then
        return true
    end
    local globalTrends = ZGV.Gold.servertrends_global
    return globalTrends and type(globalTrends.items) == "table" and next(globalTrends.items) ~= nil
end

function ZygorBase:GetLastScanTime()
    if not (ZGV and ZGV.Gold) then
        return nil
    end
    for _, tbl in ipairs({ ZGV.Gold.Scan, ZGV.Gold.servertrends, ZGV.Gold.ServerTrends, ZGV.Gold.db }) do
        if type(tbl) == "table" then
            for _, key in ipairs({ "lastScan", "scanTime", "updated", "lastUpdate", "timestamp", "scantime" }) do
                if type(tbl[key]) == "number" and tbl[key] > 1000000000 then
                    return tbl[key]
                end
            end
        end
    end
    return nil
end

function ZygorBase:AppendDebugLines(addLine)
    if not (ZGV and ZGV.Gold) then
        return
    end
    local scanTime = self:GetLastScanTime()
    addLine("  Last scan: " .. (scanTime and date("%Y-%m-%d %H:%M", scanTime) or "unknown"))
    addLine("  Realm scope: current character realm/faction")
    addLine("  Local scan data: " .. (self:HasScanData() and "available" or "not available"))
    addLine("  Trend data: " .. (self:HasTrendData() and "available" or "not available"))
end

GB.AHZygorBase = ZygorBase
