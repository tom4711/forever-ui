local _, ns = ...
local UI, T = ns.UI, ns.Theme
ns.PaladinView = {}
local friendlyBindings = {might = "PaladinMight", wisdom = "PaladinWisdom", kings = "PaladinKings"}

function ns.PaladinView.Create(name, preview)
    local L = ns.L
    local root = UI.CreatePanel(UIParent, name)
    root:SetSize(298, 31)
    local title = UI.Text(root, 13, T.goldLight)
    title:SetPoint("LEFT", 12, 0)
    title:SetText(L.PALADIN)
    local equipment = UI.Text(root, 10, T.muted)
    equipment:SetPoint("RIGHT", -12, 0)

    local auras = UI.CreateClassGroup(root, "paladin", "auraGroup", L.AURAS)
    local blessings = UI.CreateClassGroup(root, "paladin", "blessingGroup", L.BLESSINGS)
    local weapons = UI.CreateClassGroup(root, "paladin", "weaponGroup", L.WEAPON_SET)
    local quick = UI.CreateClassGroup(root, "paladin", "macroGroup", L.QUICK_CASTS)
    local friendly = UI.CreateClassGroup(root, "paladin", "friendlyGroup", L.FRIENDLY_BUFFS)

    local function makeFriendly(parent, entry)
        return UI.CreateClassAction(parent, entry, preview, T.icons.xp,
            L.FRIENDLY_BUFFS, L.PRIEST_MACRO_NEAR_HINT)
    end

    local function makeAction(parent, entry)
        if entry.key == "weaponSet" then
            return UI.CreateClassAction(parent, entry, preview, T.icons.settings, L.WEAPON_SET, L.WEAPON_SET_HINT)
        end
        local label = (entry.kind == "aura" and "AURA_" or "BLESSING_") .. entry.key
        local hint = entry.unit == "player" and L.PRIEST_MACRO_SELF_HINT or L.PALADIN_CLICK_HINT
        local button = UI.CreateClassAction(parent, entry, preview, T.icons.xp, L[label] or entry.key, hint)
        if entry.kind == "aura" then button.activeOutline = UI.ActionOutline(button) end
        if entry.unit == "player" then
            local badge = UI.Text(button, 9, T.goldLight)
            badge:SetPoint("BOTTOM", 0, 3)
            badge:SetText(L.PRIEST_MACRO_SELF)
        end
        return button
    end

    local view = {frame = root}
    local activeAura
    local function highlightAuras()
        for key, button in pairs(auras.buttons) do
            local state = activeAura == "unknown" and "unknown" or activeAura == key and "active" or "inactive"
            UI.SetActionState(button.activeOutline, state)
        end
    end

    function view.RenderStatus(data)
        activeAura = data.activeAura
        equipment:SetText(data.shieldState == "unknown" and L.SHIELD_UNKNOWN
            or data.shield and L.SHIELD_EQUIPPED or L.TWO_HAND_EQUIPPED)
        highlightAuras()
    end

    function view.RenderActions(data, actions, macro, isPreview, config)
        if InCombatLockdown() then return false end
        config = config or ns.db.paladin
        local auraEntries, blessingEntries, quickEntries, friendlyEntries = {}, {}, {}, {}
        for _, action in ipairs(actions or {}) do
            local entries = action.kind == "aura" and auraEntries or blessingEntries
            entries[#entries + 1] = action
            local binding = friendlyBindings[action.key]
            if binding and data.visible and config.friendlyGroup.enabled then
                local entry = ns.FriendlyBuffs.Entry(binding, action.spellID, preview)
                if entry then friendlyEntries[#friendlyEntries + 1] = entry end
            end
        end
        for _, action in ipairs(ns.PaladinModel.QuickActions(actions or {})) do
            local bindingID = action.key == "protection" and "PaladinProtection" or "PaladinFreedom"
            quickEntries[#quickEntries + 1] = {key = action.key, spellID = action.spellID, unit = "player", bindingID = bindingID}
        end
        local weaponEntries = (macro or isPreview) and {{key = "weaponSet", bindingID = "PaladinWeapons"}} or {}
        UI.RenderClassGroup(auras, config.auraGroup, auraEntries, data.visible, makeAction)
        UI.RenderClassGroup(blessings, config.blessingGroup, blessingEntries, data.visible, makeAction)
        UI.RenderClassGroup(weapons, config.weaponGroup, weaponEntries, data.visible, makeAction)
        UI.RenderClassGroup(quick, config.macroGroup, quickEntries, data.visible, makeAction)
        UI.RenderClassGroup(friendly, config.friendlyGroup, friendlyEntries, data.visible, makeFriendly)
        local weaponButton = weapons.buttons.weaponSet
        if weaponButton and not preview then
            weaponButton:SetAttribute("type1", macro and "macro" or nil)
            weaponButton:SetAttribute("macrotext1", macro)
        end
        highlightAuras()
        if not root.dragging then UI.Place(root, "paladin") end
        root:SetShown(data.visible == true)
        if not preview then ns.Bindings.Refresh() end
        return true
    end

    UI.MakeMovable(root, "paladin")
    root:Hide()
    return view
end
