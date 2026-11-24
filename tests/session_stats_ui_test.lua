local function withStatsUI(body)
    local function noop() end
    local widgetMethods = {}
    local function widget(parent)
        local result = setmetatable({parent = parent, children = {}, scripts = {}, shown = true}, {__index = widgetMethods})
        if parent then table.insert(parent.children, result) end
        return result
    end
    function widgetMethods:CreateTexture() return widget(self) end
    widgetMethods.CreateFontString = widgetMethods.CreateTexture
    widgetMethods.CreateLine = widgetMethods.CreateTexture
    function widgetMethods:SetPoint(...) self.point = {...} end
    function widgetMethods:GetPoint() return unpack(self.point or {"CENTER", UIParent, "CENTER", 0, 0}) end
    function widgetMethods:GetEffectiveScale() return 1 end
    function widgetMethods:SetText(value) self.text = value end
    function widgetMethods:SetScript(event, handler) self.scripts[event] = handler end
    function widgetMethods:GetScript(event) return self.scripts[event] end
    function widgetMethods:Fire(event, ...)
        if self.scripts[event] then self.scripts[event](self, ...) end
    end
    function widgetMethods:SetShown(value)
        if self.shown == value then return end
        self.shown = value
        self:Fire(value and "OnShow" or "OnHide")
    end
    function widgetMethods:Show() self:SetShown(true) end
    function widgetMethods:Hide() self:SetShown(false) end
    function widgetMethods:IsShown() return self.shown end
    function widgetMethods:StartMoving() self.moving = true end
    function widgetMethods:StopMovingOrSizing() self.moving = false end
    function widgetMethods:RegisterForClicks(button) self.click = button end
    function widgetMethods:RegisterForDrag(button) self.drag = button end
    function widgetMethods:SetMouseMotionEnabled(enabled) self.mouseMotion = enabled end
    function widgetMethods:SetMouseClickEnabled(enabled) self.mouseClick = enabled end
    function widgetMethods:SetAllPoints(relative) self.allPoints = relative end
    for _, name in ipairs({
        "ClearAllPoints", "EnableMouse", "RegisterEvent", "SetClampedToScreen", "SetColorTexture", "SetDrawLayer",
        "SetEndPoint", "SetFont", "SetFrameStrata", "SetHeight", "SetHighlightTexture", "SetJustifyH",
        "SetMinMaxValues", "SetMovable", "SetRotation", "SetScrollChild", "SetShadowColor", "SetShadowOffset",
        "SetSize", "SetStartPoint", "SetStatusBarColor", "SetStatusBarTexture", "SetTexCoord", "SetTextColor",
        "SetThickness", "SetValue", "SetWidth", "SetWordWrap",
    }) do
        widgetMethods[name] = noop
    end

    local frames = {}
    local root = widget()
    local tooltip = {}
    function tooltip:SetOwner(owner) self.owner, self.lines = owner, {} end
    function tooltip:IsOwned(owner) return self.owner == owner end
    function tooltip:SetText(value) self.title = value end
    function tooltip:AddLine(line) table.insert(self.lines, line) end
    function tooltip:AddDoubleLine(label, value) self.lines[label] = value end
    function tooltip:Show() self.shown = true end
    function tooltip:Hide() self.owner, self.shown = nil, false end

    local xp = {level = 21, elapsed = 90, earned = 558, perHour = 4921, recentPerHour = 3671,
        recentWindow = 1800, eta = 720, remaining = 19800, questXP = 2000, rested = 9}
    local levels = {level = 21, currentLevelTime = 123, currentLevelTimePartial = true, totalTime = 14700,
        history = {{level = 20, seconds = 1800}, {level = 19, seconds = 2400},
            {level = 18, seconds = 4800}, {level = 17, seconds = 9600}}}
    local gold = {balance = 12000, income = 500, expenses = 800, net = -300, perHour = -3600,
        merchantSales = 20, merchantRepairs = 80, elapsed = 300}
    local live = {alt = false, xp = xp, levels = levels, gold = gold, requests = 0}
    local ns = {db = {xp = {}, player = {}},
        XP = {GetSummary = function() return xp end},
        LevelStats = {Snapshot = function() return levels end, Request = function() live.requests = live.requests + 1 end},
        GoldStats = {Snapshot = function() return gold end}}

    withGlobals({
        UIParent = root, UISpecialFrames = {}, GameTooltip = tooltip,
        GetLocale = function() return "enUS" end,
        InCombatLockdown = function() return false end,
        IsAltKeyDown = function() return live.alt end,
        C_AddOns = false,
        C_CurrencyInfo = {GetCoinTextureString = function(amount) return amount .. " coins" end},
        CreateFrame = function(kind, name, parent)
            if kind == "AuraContainer" then return end
            local frame = widget(parent)
            if name then frames[name] = frame end
            return frame
        end,
    }, function()
        for _, path in ipairs({
            "Locales.lua", "Core/Read.lua", "Core/Format.lua", "UI/Theme.lua", "UI/Widgets.lua",
            "UI/SessionStats.lua", "Modules/XP/View.lua", "Modules/Player/View.lua",
        }) do
            loadAddon(path, ns)
        end
        body(ns, frames, live, tooltip)
    end)
end

local function find(widget, condition)
    if condition(widget) then return widget end
    for _, child in ipairs(widget.children) do
        local result = find(child, condition)
        if result then return result end
    end
end

local function hasText(widget, text)
    return find(widget, function(child) return child:IsShown() and child.text == text end)
end

test("session stats panel refreshes live stats and asks for play time only on request", function()
    withStatsUI(function(ns, frames, live)
        assert(not frames.ForeverUI_SessionStats)
        ns.StatsView.Toggle()
        local panel = assert(frames.ForeverUI_SessionStats)
        assert(panel:IsShown() and live.requests == 0)
        for _, text in ipairs({
            "Level 21", "Level 20", "Level 19", "Level 18", "~0:02:03", "4:05:00",
            "4,921", "3,671", "558 XP", "0:12:00", "0:01:30", "19,800 XP",
            "12000 coins", "+500 coins", "-800 coins", "-300 coins", "-3600 coins", "+20 coins", "-80 coins",
        }) do
            assert(hasText(panel, text), "missing stats value " .. text)
        end
        assert(not hasText(panel, "Level 17"), "show only the most recent three completed levels")
        assert(hasText(panel, "Completed levels") ~= nil)
        local request = assert(find(panel, function(child) return child.label and child.label.text == ns.L.STATS_REQUEST_PLAY_TIME end))
        request:Fire("OnClick")
        assert(live.requests == 1)
        live.levels.currentLevelTime = 124
        live.levels.currentLevelTimePartial = false
        panel:Fire("OnUpdate", 1)
        assert(hasText(panel, "0:02:04"))
        live.xp.recentWindow = 43
        live.xp.recentPerHour = nil
        panel:Fire("OnUpdate", 1)
        assert(hasText(panel, "XP/h (last 30 min)") and not hasText(panel, "XP/h (last 0 min)"))
        live.xp.recentWindow = 163
        live.xp.recentPerHour = 1660
        panel:Fire("OnUpdate", 1)
        assert(hasText(panel, "XP/h (last 2 min)") and hasText(panel, "1,660"))
        live.levels.history = {}
        panel:Fire("OnUpdate", 1)
        assert(not hasText(panel, "Level 20") and hasText(panel, "–"))
        assert(UISpecialFrames[1] == "ForeverUI_SessionStats")
        local close = assert(find(panel, function(child) return child.label and child.label.text == "" end))
        close:Fire("OnClick")
        assert(not panel:IsShown())
        ns.StatsView.Toggle()
        ns.StatsView.Toggle()
        assert(not panel:IsShown() and live.requests == 1)
    end)
end)

test("XP badge opens stats only on plain clicks and retains the XP hover and Alt drag", function()
    withStatsUI(function(ns, frames, live, tooltip)
        local view = ns.XPView.Create("TestXP")
        ns.XPModel = {DisplayAmount = function() return 0 end, Segments = function()
            local value = {start = 0, size = 0}
            return {current = value, quest = value, rested = value}
        end}
        view.Render(live.xp)
        local badge = assert(find(view.frame, function(child) return child.icon ~= nil end))
        badge:Fire("OnEnter")
        assert(tooltip.shown and tooltip.owner == badge and tooltip.title == ns.L.EXPERIENCE)
        badge:Fire("OnLeave")
        assert(not tooltip.shown)
        live.alt = true
        badge:Fire("OnMouseDown", "LeftButton")
        badge:Fire("OnClick", "LeftButton")
        assert(not frames.ForeverUI_SessionStats)
        badge:Fire("OnMouseDown", "LeftButton")
        badge:Fire("OnDragStart", "LeftButton")
        assert(view.frame.moving)
        live.alt = false
        badge:Fire("OnDragStop")
        badge:Fire("OnClick", "LeftButton")
        assert(not view.frame.moving and not frames.ForeverUI_SessionStats)
        badge:Fire("OnMouseDown", "LeftButton")
        badge:Fire("OnClick", "LeftButton")
        assert(frames.ForeverUI_SessionStats:IsShown())
        local preview = ns.XPView.Create("TestXPPreview", true)
        local previewBadge = assert(find(preview.frame, function(child) return child.icon ~= nil end))
        assert(not previewBadge:GetScript("OnClick"))
    end)
end)

test("player gold has a motion-only hover target and displays signed session totals", function()
    withStatsUI(function(ns, _, _, tooltip)
        local view = ns.PlayerView.Create("TestPlayer")
        view.RenderMoney(12000)
        local hover = assert(find(view.frame, function(child) return child.mouseMotion end))
        assert(hover.mouseClick == false and hover.allPoints.text == "12000 coins")
        hover:Fire("OnEnter")
        assert(tooltip.shown and tooltip.owner == hover and tooltip.title == ns.L.STATS_GOLD)
        assert(tooltip.lines[ns.L.STATS_GOLD_INCOME] == "+500 coins")
        assert(tooltip.lines[ns.L.STATS_GOLD_EXPENSES] == "-800 coins")
        assert(tooltip.lines[ns.L.STATS_GOLD_NET] == "-300 coins")
        assert(tooltip.lines[ns.L.STATS_GOLD_RATE] == "-3600 coins")
        assert(tooltip.lines[ns.L.STATS_BALANCE] == nil)
        assert(tooltip.lines[ns.L.STATS_MERCHANT_SALES] == nil)
        assert(tooltip.lines[ns.L.STATS_MERCHANT_REPAIRS] == nil)
        hover:Fire("OnLeave")
        assert(not tooltip.shown)
        view.RenderMoney(nil)
        assert(not hover:IsShown())
        local preview = ns.PlayerView.Create("TestPlayerPreview", true)
        assert(not find(preview.frame, function(child) return child.mouseMotion end))
    end)
end)
