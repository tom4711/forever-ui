local _, ns = ...
local R = ns.Read
local ItemTooltips = {}
ns.ItemTooltips = ItemTooltips

local registered
local tooltipNames = {
    "GameTooltip", "ItemRefTooltip", "ShoppingTooltip1", "ShoppingTooltip2",
    "ItemRefShoppingTooltip1", "ItemRefShoppingTooltip2",
}

local function field(value, key)
    return R.Call(function() return value and value[key] end)
end

local function itemLink(tooltip, data)
    local link = field(data, "hyperlink")
    if type(link) == "string" and link ~= "" then return link end
    return R.Call(function()
        local _, activeLink = tooltip:GetItem()
        return activeLink
    end)
end

local function supportedTooltip(tooltip)
    for _, name in ipairs(tooltipNames) do
        if _G[name] == tooltip then return name end
    end
end

local function isLevelLabel(text)
    if type(text) ~= "string" then return false end
    text = text:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""):lower()
    local label = text:gsub("^%s+", ""):gsub("%s*:?%s*%d*%s*$", "")
    return label == "item level" or label == ns.L.TOOLTIP_ITEM_LEVEL:lower()
end

local function hasItemLevel(tooltip, name, data)
    local levelLine = Enum and Enum.TooltipDataLineType and Enum.TooltipDataLineType.ItemLevel
    local sections = field(data, "lines")
    if levelLine and type(sections) == "table" then
        for _, line in ipairs(sections) do
            if field(line, "type") == levelLine then return true end
        end
    end

    local count = R.Number(R.Call(tooltip.NumLines, tooltip)) or 0
    for index = 1, count do
        local line = _G[name .. "TextLeft" .. index]
        if line and isLevelLabel(R.Call(line.GetText, line)) then return true end
    end
    return false
end

local function decorate(tooltip, data)
    if not ns.db or not ns.db.comfort.tooltipItemLevel then return end
    local name = supportedTooltip(tooltip)
    if not name then return end

    local processing = R.Call(tooltip.GetProcessingTooltipInfo, tooltip)
    if field(processing, "append") == true then return end

    local item = C_Item
    local link = itemLink(tooltip, data)
    if not item or type(link) ~= "string" or link == ""
        or R.Call(item.IsEquippableItem, link) ~= true or hasItemLevel(tooltip, name, data) then return end
    local level = R.Number(R.Call(item.GetDetailedItemLevelInfo, link))
    if level and level > 0 then
        local color = ns.Theme.muted
        tooltip:AddDoubleLine(ns.L.TOOLTIP_ITEM_LEVEL, tostring(level), color[1], color[2], color[3], 1, 1, 1)
    end
end

function ItemTooltips.Init()
    if registered then return end
    local processor = TooltipDataProcessor
    local item = Enum and Enum.TooltipDataType and Enum.TooltipDataType.Item
    if not processor or not processor.AddTooltipPostCall or item == nil then return end
    processor.AddTooltipPostCall(item, decorate)
    registered = true
end
