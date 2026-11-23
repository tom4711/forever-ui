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
function methods:CreateTexture() return widget("Texture", self) end
function methods:CreateFontString() return widget("FontString", self) end

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
