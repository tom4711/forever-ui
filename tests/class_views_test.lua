local methods = {}
local function widget(kind, parent, template)
    return setmetatable({kind = kind, parent = parent, template = template, attributes = {}, shown = true},
        {__index = methods})
end

for _, name in ipairs({
    "EnableMouse", "RegisterEvent", "RegisterForClicks", "RegisterForDrag", "SetAllPoints", "SetClampedToScreen",
    "SetColorTexture", "SetFont", "SetHeight", "SetJustifyH", "SetMinMaxValues", "SetMovable", "SetRotation",
    "SetScale", "SetScript", "SetShadowColor", "SetShadowOffset", "SetStatusBarColor", "SetStatusBarTexture",
    "SetTexCoord", "SetTextColor", "SetTexture", "SetValue", "SetVertexColor", "SetWidth",
}) do
    methods[name] = function() end
end

function methods:GetParent() return self.parent end
function methods:SetSize(width, height) self.width, self.height = width, height end
function methods:SetPoint(...) self.point = {...} end
function methods:ClearAllPoints() self.point = nil end
function methods:SetText(text) self.text = text end
function methods:GetStringWidth() return #self.text * 5 end
function methods:SetAttribute(key, value) self.attributes[key] = value end
function methods:SetShown(shown) self.shown = shown end
function methods:Show() self:SetShown(true) end
function methods:Hide() self:SetShown(false) end
function methods:SetColorTexture(...) self.color = {...} end
function methods:CreateTexture()
    local texture = widget("Texture", self)
    self.textures = self.textures or {}
    self.textures[#self.textures + 1] = texture
    return texture
end
function methods:CreateFontString()
    local font = widget("FontString", self)
    self.labels = self.labels or {}
    self.labels[#self.labels + 1] = font
    return font
end

local function findSpell(frames, root, spellID)
    for _, frame in ipairs(frames) do
        if frame.spellID == spellID and frame.parent and frame.parent.parent == root then return frame end
    end
end

local function assertSpellPreview(frames, live, preview, spellID)
    local action = assert(findSpell(frames, live.frame, spellID), "live action must be present")
    assert(action.template == "SecureActionButtonTemplate")
    assert(action.attributes.type1 == "spell" and action.attributes.spell == spellID)

    local sample = assert(findSpell(frames, preview.frame, spellID), "preview action must be present")
    assert(sample.template == nil and next(sample.attributes) == nil, "preview must not receive secure attributes")
    assert(action.cooldownTracked and action.powerTracked)
    assert(not sample.cooldownTracked and not sample.powerTracked)
    return action
end

test("class preview mode is fixed at view creation and live actions stay secure", function()
    local frames = {}
    withGlobals({
        UIParent = {},
        GetLocale = function() return "enUS" end,
        InCombatLockdown = function() return false end,
        C_Spell = false,
        GetSpellTexture = function(id) return id end,
        GetSpellInfo = function(id) return "Spell " .. id end,
        CreateFrame = function(kind, _, parent, template)
            local frame = widget(kind, parent, template)
            frames[#frames + 1] = frame
            return frame
        end,
    }, function()
        local ns = {}
        for _, file in ipairs({
            "Locales.lua", "Core/Read.lua", "Core/Format.lua", "Core/Bindings.lua", "Core/Settings.lua", "Core/FriendlyBuffs.lua",
            "UI/Theme.lua", "UI/Widgets.lua", "Modules/Paladin/Model.lua",
            "Modules/Paladin/View.lua", "Modules/Warlock/View.lua",
        }) do
            loadAddon(file, ns)
        end
        ns.db = ns.Settings.Load({companion = {enabled = false}})
        ns.UI.TrackSpellCooldown = function(button) button.cooldownTracked = true end
        ns.UI.TrackSpellPower = function(button) button.powerTracked = true end

        local aura = {key = "devotion", kind = "aura", spellID = 465}
        local loadout = "/equipset [equipped:shield] Two Hand; Shield Set"
        local paladin, paladinPreview = ns.PaladinView.Create("LivePaladin", false), ns.PaladinView.Create("PreviewPaladin", true)
        paladin.RenderStatus({activeAura = "unknown", shieldState = "unknown"})
        paladin.RenderActions({visible = true}, {aura}, loadout, true)
        paladinPreview.RenderActions({visible = true}, {aura}, loadout, false)
        assertSpellPreview(frames, paladin, paladinPreview, 465)
        for _, frame in ipairs(frames) do
            if frame.kind == "Button" and frame.parent and frame.parent.parent == paladinPreview.frame then
                assert(frame.template == nil and next(frame.attributes) == nil)
                assert(not frame.cooldownTracked and not frame.powerTracked)
            end
        end

        local warlock, warlockPreview = ns.WarlockView.Create("LiveWarlock", false), ns.WarlockView.Create("PreviewWarlock", true)
        local data = {visible = true, demon = {state = "living", name = "Imp", health = 5, maxHealth = 10}, shards = 0}
        local summons = {{key = "imp", spellID = 688}}
        warlock.RenderStatus(data)
        warlock.RenderActions(data, summons, true)
        warlockPreview.RenderActions(data, summons, false)
        local summon = assertSpellPreview(frames, warlock, warlockPreview, 688)

        local healthBar
        for _, frame in ipairs(frames) do
            if frame.kind == "StatusBar" and frame.parent == warlock.frame then healthBar = frame end
        end
        assert(healthBar and healthBar.shown, "living demon should show its fallback health bar")
        local healthBottom = healthBar.point[3] - healthBar.height
        local summonTop = summon.parent.point[5] + summon.point[5]
        assert(healthBottom > summonTop, "the fallback health bar must not overlap the summon buttons")
        ns.db.companion.enabled = true
        warlock.RenderStatus(data)
        assert(not healthBar.shown, "the companion frame should replace the fallback health bar")
    end)
end)

test("accent borders update in place independently of the panel background", function()
    withGlobals({
        UnitClass = function() return "Magier", "MAGE" end,
        C_ClassColor = {GetClassColor = function(class)
            if class == "MAGE" then return {r = 0.25, g = 0.78, b = 0.92} end
        end},
        RAID_CLASS_COLORS = false,
    }, function()
        local ns = {}
        loadAddon("Core/Read.lua", ns)
        loadAddon("UI/Theme.lua", ns)
        loadAddon("UI/Widgets.lua", ns)
        local panel = widget("Frame")
        ns.UI.Decorate(panel)
        local background = panel.textures[1]
        local accent = panel.textures[10]
        assert(accent.color[1] == ns.Theme.gold[1])
        ns.Theme.SetClassAccent(true)
        assert(accent.color[1] == 0.25 and accent.color[3] == 0.92)
        assert(background.color[1] == ns.Theme.background[1])
        ns.Theme.SetClassAccent(false)
        assert(accent.color[1] == ns.Theme.gold[1] and accent.color[3] == ns.Theme.gold[3])
    end)
end)

test("a mage action group keeps its saved class anchor without a standalone title panel", function()
    local frames = {}
    local dragModifiers = {shift = true}
    withGlobals({
        UIParent = {},
        GetLocale = function() return "enUS" end,
        InCombatLockdown = function() return false end,
        IsAltKeyDown = function() return true end,
        IsShiftKeyDown = function() return dragModifiers.shift end,
        UnitClass = function() return "Mage", "MAGE" end,
        IsPlayerSpell = function(id) return id == 168 end,
        C_SpellBook = false, C_Spell = false, IsSpellKnown = false,
        GetSpellTexture = function(id) return id end,
        GetSpellInfo = function(id) return "Spell " .. id end,
        CreateFrame = function(kind, _, parent, template)
            local frame = widget(kind, parent, template)
            function frame:SetScript(event, callback) self[event] = callback end
            function frame:StartMoving() self.moving = true end
            function frame:StopMovingOrSizing() self.moving = false end
            function frame:GetPoint() return unpack(self.point) end
            frames[#frames + 1] = frame
            return frame
        end,
    }, function()
        local ns = {}
        for _, file in ipairs({
            "Locales.lua", "Core/Read.lua", "Core/CombatQueue.lua", "Core/Bindings.lua", "Core/Settings.lua",
            "UI/Theme.lua", "UI/Widgets.lua", "Modules/ClassSupport.lua",
        }) do
            loadAddon(file, ns)
        end
        ns.db = ns.Settings.Load({locked = false})
        ns.Preview = {IsEnabled = function() return false end}
        ns.Refresh = ns.ClassSupport.Refresh
        ns.Bindings.Refresh = function() end
        ns.UI.TrackSpellCooldown = function() end
        ns.UI.TrackSpellPower = function() end
        ns.ClassSupport.Init()

        local root = frames[1]
        assert(root.shown and root.width == 250 and not root.labels and not root.textures,
            "the pure class title should not draw a panel")
        local action = assert(findSpell(frames, root, 168))
        local group = action.parent
        assert(group.shown and action.shown)
        assert(group.point[4] == 166 and group.point[5] == -39)

        group.dragGrip.OnDragStart()
        assert(root.moving and not group.moving)
        root:SetPoint("CENTER", UIParent, "CENTER", 25, -100)
        group.dragGrip.OnDragStop()
        assert(not root.moving and ns.db.mage.position.x == 25 and ns.db.mage.position.y == -100)
        assert(ns.db.mage.utilityGroup.position.x == 166)

        dragModifiers.shift = false
        group.dragGrip.OnDragStart()
        assert(group.moving and not root.moving)
        group:SetPoint("TOPLEFT", root, "TOPLEFT", 178, -54)
        group.dragGrip.OnDragStop()
        assert(not group.moving and ns.db.mage.utilityGroup.position.x == 178 and ns.db.mage.utilityGroup.position.y == -54)
    end)
end)
