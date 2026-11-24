local function withTooltip(body)
    local namespace = {db = {comfort = {tooltipItemLevel = false}},
        L = {TOOLTIP_ITEM_LEVEL = "Gegenstandsstufe"}, Theme = {muted = {0.5, 0.6, 0.7}}}
    local lines, postCall = {}, nil
    local tooltip = {}
    function tooltip:GetItem() return "Ausrüstung", self.link end
    function tooltip:GetName() return "GameTooltip" end
    function tooltip:NumLines() return #lines end
    function tooltip:AddDoubleLine(label, value)
        lines[#lines + 1] = {label = label, value = value}
        local line = lines[#lines]
        _G["GameTooltipTextLeft" .. #lines] = {GetText = function() return line.label end}
    end
    local context = {
        render = function(data, target) postCall(target or tooltip, data) end,
        lines = lines, tooltip = tooltip, comfort = namespace.db.comfort,
    }
    local equippable = {
        ["item:11:5"] = 18,
        ["item:245"] = 23,
        ["item:9"] = 0,
    }
    withGlobals({
        GameTooltip = tooltip, ItemRefTooltip = false, ShoppingTooltip1 = false, ShoppingTooltip2 = false,
        GameTooltipTextLeft1 = false, GameTooltipTextLeft2 = false,
        Enum = {TooltipDataType = {Item = 0}, TooltipDataLineType = {ItemLevel = 31}},
        C_Item = {
            IsEquippableItem = function(link) return equippable[link] ~= nil end,
            GetDetailedItemLevelInfo = function(link) return equippable[link] end,
        },
        TooltipDataProcessor = {AddTooltipPostCall = function(kind, callback)
            assert(kind == 0 and not postCall, "item post-call is registered once")
            postCall = callback
        end},
    }, function()
        loadAddon("Core/Read.lua", namespace)
        loadAddon("Modules/ItemTooltips.lua", namespace)
        namespace.ItemTooltips.Init()
        namespace.ItemTooltips.Init()
        body(context)
    end)
end

test("item tooltip uses the full item link and respects the live comfort setting", function()
    withTooltip(function(context)
        local data = {hyperlink = "item:11:5", id = 11}
        context.render(data)
        assert(#context.lines == 0)
        context.comfort.tooltipItemLevel = true
        context.render(data)
        assert(#context.lines == 1)
        assert(context.lines[1].label == "Gegenstandsstufe" and context.lines[1].value == "18")
        context.render(data)
        assert(#context.lines == 1, "reprocessing the same tooltip must not append the line twice")
    end)
end)

test("item tooltip skips non-equipment, unavailable levels and existing item-level rows", function()
    withTooltip(function(context)
        context.comfort.tooltipItemLevel = true
        context.render({hyperlink = "item:77"})
        context.render({hyperlink = "item:9"})
        context.render({hyperlink = "item:11:5", lines = {{type = 31, leftText = "Gegenstandsstufe 18"}}})
        assert(#context.lines == 0)
        context.tooltip:AddDoubleLine("Item level", "23")
        context.tooltip.link = "item:245"
        context.render({})
        assert(#context.lines == 1, "an existing addon item-level line must be left intact")
    end)
end)

test("a regular item tooltip can resolve an item via the tooltip's GetItem link", function()
    withTooltip(function(context)
        context.comfort.tooltipItemLevel = true
        context.tooltip.link = "item:245"
        context.render({})
        assert(#context.lines == 1 and context.lines[1].value == "23")
    end)
end)
