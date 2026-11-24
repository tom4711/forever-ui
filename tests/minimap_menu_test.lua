local function node(name, parent)
    local frame = {name = name, parent = parent, shown = true, points = {}, scripts = {},
        level = 8, strata = "MEDIUM"}
    function frame:GetName() return self.name end
    function frame:GetParent() return self.parent end
    function frame:SetParent(value) self.parent = value end
    function frame:GetNumPoints() return #self.points end
    function frame:GetPoint(index) return unpack(self.points[index or 1] or {}, 1, 5) end
    function frame:ClearAllPoints() self.points = {} end
    function frame:SetPoint(...) self.points[#self.points + 1] = {...} end
    function frame:GetFrameLevel() return self.level end
    function frame:SetFrameLevel(value)
        if not self.fixedLevel then self.level = value end
    end
    function frame:GetFrameStrata() return self.strata end
    function frame:SetFrameStrata(value)
        if not self.fixedStrata then self.strata = value end
    end
    function frame:IsShown() return self.shown end
    function frame:IsVisible() return self.shown and (not self.parent or self.parent:IsVisible()) end
    function frame:IsMouseOver() return self.hover == true end
    function frame:SetShown(value) self.shown = value end
    function frame:Hide() self.shown = false end
    function frame:Show() self.shown = true end
    function frame:SetSize(width, height) self.width, self.height = width, height end
    function frame:IsObjectType(kind) return kind == "Button" and self.button ~= false end
    function frame:IsForbidden() return false end
    function frame:IsProtected() return self.protected == true end
    function frame:SetText(value) self.text = value end
    function frame:EnableMouse() end
    function frame:RegisterEvent() end
    function frame:SetScript(event, callback) self.scripts[event] = callback end
    return frame
end

local function withMenu(body)
    local combat, ticker, events, menu, clicks, tooltipCalls = false, nil, nil, nil, 0, 0
    local competingCollector = false
    local root = node("UIParent")
    local map = node("Minimap", root)
    local settings = node("ForeverUI_SettingsMinimapButton", map)
    local broker = node("LibDBIcon10_Spoken", map)
    broker.showOnMouseover = true
    broker.fixedStrata, broker.fixedLevel = true, true
    local library = {
        GetMinimapButton = function(_, name) if name == "Spoken" then return broker end end,
        ShowOnEnter = function(_, name, fade) assert(name == "Spoken"); broker.showOnMouseover = fade end,
    }
    broker:SetPoint("CENTER", map, "CENTER", 35, -45)
    broker:SetPoint("BOTTOM", map, "CENTER", 2, 5)
    broker:SetScript("OnClick", function(_, button) assert(button == "RightButton"); clicks = clicks + 1 end)
    broker:SetScript("OnEnter", function() tooltipCalls = tooltipCalls + 1 end)
    local native = node("MiniMapTrackingButton", map)
    local pin = node("QuestieFramePin5", map)
    local protected = node("LibDBIcon10_Protected", map)
    protected.protected = true
    local custom = node("OpenMapMinimapButton", map)
    custom:Hide()
    local standard = node("AnotherAddonMinimapButton", map)
    local buttons = {settings, broker, native, pin, protected, custom, standard}
    function map:GetChildren()
        local children = {}
        for _, item in ipairs(buttons) do if item.parent == self then children[#children + 1] = item end end
        return unpack(children)
    end
    local options = {collect = false}
    local ns = {db = {minimapButton = options}, L = {MINIMAP_ADDONS_EMPTY = "Keine Addon-Symbole"},
        Theme = {muted = {}}, UI = {
            CreatePanel = function(parent, name) menu = node(name, parent); return menu end,
            Text = function(parent) return node(nil, parent) end,
        }}
    withGlobals({
        Minimap = map, UIParent = root, MinimapBackdrop = false,
        InCombatLockdown = function() return combat end,
        CreateFrame = function() events = node(); return events end,
        C_AddOns = {IsAddOnLoaded = function(name)
            return name == "AnotherAddon" or (competingCollector and name == "MBB")
        end},
        LibStub = {GetLibrary = function(_, name) if name == "LibDBIcon-1.0" then return library end end},
        C_Timer = {NewTicker = function(_, callback)
            ticker = {run = callback, Cancel = function() ticker = nil end}
            return ticker
        end},
    }, function()
        loadAddon("Core/Read.lua", ns)
        loadAddon("UI/MinimapMenu.lua", ns)
        ns.MinimapMenu.Init(settings)
        body({menu = ns.MinimapMenu, options = options, map = map, settings = settings,
            panel = function() return menu end, tick = function() ticker.run() end,
            emit = function(event) events.scripts.OnEvent(events, event) end,
            combat = function(value) combat = value end,
            competing = function(value) competingCollector = value end,
            counters = function() return clicks, tooltipCalls end,
            broker = broker, custom = custom, standard = standard, native = native, pin = pin, protected = protected})
    end)
end

test("minimap menu collects only addon launchers and restores actual frames on opt-out", function()
    withMenu(function(fixture)
        local f = fixture
        assert(f.broker.parent == f.map and f.broker:IsVisible())
        f.options.collect = true
        f.menu.Refresh()
        local panel = f.panel()
        assert(f.broker.parent == panel and f.standard.parent == panel and not f.broker:IsVisible())
        assert(f.settings.parent == f.map and f.native.parent == f.map and f.pin.parent == f.map)
        assert(f.protected.parent == f.map and f.custom.parent == f.map and not f.custom:IsShown())

        f.menu.Toggle()
        assert(f.broker:IsVisible() and f.broker.showOnMouseover == false)
        f.broker.scripts.OnClick(f.broker, "RightButton")
        f.broker.scripts.OnEnter(f.broker)
        local clicked, hovered = f.counters()
        assert(clicked == 1 and hovered == 1)
        f.emit("GLOBAL_MOUSE_DOWN")
        assert(not f.broker:IsVisible())

        f.options.collect = false
        f.menu.Refresh()
        assert(f.broker:IsVisible() and f.broker.parent == f.map and f.standard.parent == f.map)
        assert(f.broker.showOnMouseover == true)
        assert(f.broker.strata == "MEDIUM" and f.broker.level == 8 and f.broker:GetNumPoints() == 2)
        local point, anchor, relative, x, y = f.broker:GetPoint(1)
        assert(point == "CENTER" and anchor == f.map and relative == "CENTER" and x == 35 and y == -45)
    end)
end)

test("the minimap backdrop renders behind both fixed and ordinary launchers", function()
    withMenu(function(f)
        f.options.collect = true
        f.menu.Refresh()
        f.menu.Toggle()
        local panel = f.panel()
        local layers = {BACKGROUND = 1, LOW = 2, MEDIUM = 3, HIGH = 4, DIALOG = 5}
        for _, button in ipairs({f.broker, f.standard}) do
            local layer, background = layers[button.strata], layers[panel.strata]
            assert(layer > background or (layer == background and button.level > panel.level),
                "the menu background must be below the original button")
        end
        assert(f.broker.fixedStrata and f.broker.fixedLevel)
        assert(f.broker.strata == "MEDIUM" and f.broker.level == 8)
    end)
end)

test("minimap menu respects late visibility, repositioning and combat", function()
    withMenu(function(f)
        f.options.collect = true
        f.combat(true)
        f.menu.Refresh()
        assert(f.broker.parent == f.map)
        f.combat(false)
        f.emit("PLAYER_REGEN_ENABLED")
        local panel = f.panel()
        assert(f.broker.parent == panel)
        f.custom:Show()
        f.tick()
        assert(f.custom.parent == panel)
        f.custom:Hide()
        f.menu.Toggle()
        assert(not f.custom:IsVisible())

        f.broker:ClearAllPoints()
        f.broker:SetPoint("CENTER", f.map, "CENTER", 77, 44)
        f.tick()
        local _, anchor = f.broker:GetPoint()
        assert(anchor == panel)
        f.options.collect = false
        f.combat(true)
        f.menu.Refresh()
        assert(f.broker.parent == panel)
        f.combat(false)
        f.emit("PLAYER_REGEN_ENABLED")
        local _, target, _, x, y = f.broker:GetPoint()
        assert(target == f.map and x == 77 and y == 44)
        assert(f.custom.parent == f.map and not f.custom:IsShown())
    end)
end)

test("a dedicated minimap collector can take over without losing the original buttons", function()
    withMenu(function(f)
        f.options.collect = true
        f.menu.Refresh()
        assert(f.broker.parent == f.panel())
        f.competing(true)
        f.tick()
        assert(f.broker.parent == f.map)
        f.menu.Toggle()
        assert(not f.panel():IsShown())
    end)
end)
