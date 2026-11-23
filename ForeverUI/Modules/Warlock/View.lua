local _, ns = ...
local UI, T = ns.UI, ns.Theme
ns.WarlockView = {}

function ns.WarlockView.Create(name, preview)
    local L = ns.L
    local root = UI.CreatePanel(UIParent, name)
    root:SetSize(381, 58)
    local title = UI.Text(root, 13, T.goldLight)
    title:SetPoint("TOPLEFT", 12, -8)
    title:SetText(L.WARLOCK)
    local demon = UI.Text(root, 11, T.text)
    demon:SetPoint("TOPLEFT", 12, -28)
    demon:SetWidth(235)
    local shards = UI.Text(root, 11, T.teal)
    shards:SetPoint("TOPRIGHT", -12, -10)
    local bar = CreateFrame("StatusBar", nil, root)
    bar:SetPoint("TOPLEFT", 12, -45)
    bar:SetSize(235, 4)
    bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    bar:SetStatusBarColor(unpack(T.teal))
    bar:Hide()

    local summons = UI.CreateClassGroup(root, "warlock", "summonGroup", L.WARLOCK_SUMMONS)
    local quick = UI.CreateClassGroup(root, "warlock", "macroGroup", L.QUICK_CASTS)
    local friendly = UI.CreateClassGroup(root, "warlock", "friendlyGroup", L.FRIENDLY_BUFFS)
    local view = {frame = root}

    local function makeFriendly(parent, entry)
        return UI.CreateClassAction(parent, entry, preview, T.icons.xp,
            L.BIND_UNENDING_BREATH, L.PRIEST_MACRO_NEAR_HINT)
    end

    local function summonButton(parent, entry)
        return UI.CreateClassAction(parent, entry, preview, T.icons.pet, L["SUMMON_" .. entry.key], L.WARLOCK_CLICK_HINT)
    end

    local function quickButton(parent, entry)
        local funnel = entry.key == "healthFunnel"
        local action = {spellID = entry.spellID, unit = entry.unit,
            bindingID = funnel and "WarlockFunnel" or "WarlockHealthstone"}
        return UI.CreateClassAction(parent, action, preview, T.icons.pet,
            funnel and L.WARLOCK_HEALTH_FUNNEL or L.WARLOCK_HEALTHSTONE,
            funnel and L.WARLOCK_FUNNEL_HINT or L.WARLOCK_HEALTHSTONE_HINT)
    end

    function view.RenderStatus(data)
        local state = data.demon.state
        demon:SetText(L["DEMON_" .. state] .. (data.demon.name and ": " .. data.demon.name or ""))
        demon:SetTextColor(unpack(state == "living" and T.good or state == "dead" and {1,0.35,0.27,1} or T.muted))
        shards:SetText(data.shards == nil and L.SHARDS_UNKNOWN or L.SHARDS .. ": " .. ns.Format.Number(data.shards))
        local companion = ns.db and ns.db.companion
        local hasHealth = not (companion and companion.enabled) and state == "living"
            and data.demon.health and data.demon.maxHealth and data.demon.maxHealth > 0
        if hasHealth then
            bar:SetMinMaxValues(0, data.demon.maxHealth)
            bar:SetValue(data.demon.health)
        end
        bar:SetShown(hasHealth and true or false)
    end

    function view.RenderActions(data, entries)
        if InCombatLockdown() then return false end
        local config = ns.db.warlock
        UI.RenderClassGroup(summons, config.summonGroup, entries or {}, data.visible, summonButton)
        UI.RenderClassGroup(quick, config.macroGroup, data.quickActions or {}, data.visible, quickButton)
        local breath
        if data.visible and config.friendlyGroup.enabled and (data.knowsBreath or preview) then
            breath = ns.FriendlyBuffs.Entry("WarlockBreath", 5697, preview)
        end
        UI.RenderClassGroup(friendly, config.friendlyGroup, breath and {breath} or {}, data.visible, makeFriendly)
        root:SetShown(data.visible == true)
        if not preview then ns.Bindings.Refresh() end
        return true
    end

    UI.MakeMovable(root, "warlock")
    root:Hide()
    return view
end
