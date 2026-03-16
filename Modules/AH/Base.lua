local _, GB = ...

local AHSourceBase = {}
AHSourceBase.__index = AHSourceBase

function AHSourceBase:New(def)
    def = def or {}
    setmetatable(def, self)
    return def
end

function AHSourceBase:GetID()
    return self.id
end

function AHSourceBase:GetLabel()
    return self.label or self.id or "Unknown"
end

function AHSourceBase:GetSortOrder()
    return self.sortOrder or self.autoOrder or math.huge
end

function AHSourceBase:IsInAutoOrder()
    return self.autoOrder ~= nil
end

function AHSourceBase:IsAvailable()
    return false
end

function AHSourceBase:GetPrice(itemID)
    return nil
end

function AHSourceBase:GetStatusText()
    return string.format("%s: %s", self:GetLabel(), self:IsAvailable() and "available" or "not found")
end

function AHSourceBase:AppendDebugLines(addLine)
end

GB.AHSourceBase = AHSourceBase
