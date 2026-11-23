local _,ns=...
local UI,T=ns.UI,ns.Theme
ns.PriestView={}
local actionLabels={fortitude="POWER_WORD_FORTITUDE",shadowProtection="SHADOW_PROTECTION",
    divineSpirit="DIVINE_SPIRIT",innerFire="INNER_FIRE",shadowform="SHADOWFORM",
    shield="POWER_WORD_SHIELD",renew="RENEW",dispelMagic="DISPEL_MAGIC",cureDisease="CURE_DISEASE",resurrection="RESURRECTION",silence="PRIEST_SILENCE"}
local bindingIDs = {fortitudeNearby = "PriestFortitudeNearby", fortitudeSelf = "PriestFortitudeSelf",
    shieldSelf = "PriestShieldSelf", renewSelf = "PriestRenewSelf",
    shadowProtectionNearby = "PriestShadowProtection", divineSpiritNearby = "PriestSpirit", silence = "PriestSilence",
    shieldMouseover = "PriestShieldMouseover", renewMouseover = "PriestRenewMouseover"}
local function spellInfo(spellID)
    return ns.Read.Call(C_Spell and C_Spell.GetSpellInfo,spellID)
end
local function spellTexture(spellID)
    local texture=ns.Read.Call(C_Spell and C_Spell.GetSpellTexture,spellID)
    if texture then return texture end
    local info=spellInfo(spellID)
    if type(info)=="table"and info.iconID then return info.iconID end
    return ns.Read.Call(GetSpellTexture,spellID)
end
local function spellName(spellID)
    local name=ns.Read.Call(C_Spell and C_Spell.GetSpellName,spellID)
    if name then return name end
    local info=spellInfo(spellID)
    if type(info)=="table"and info.name then return info.name end
    return ns.Read.Call(GetSpellInfo,spellID)
end
function ns.PriestView.Create(name,preview)
    local L=ns.L
    local readOnly=preview==true
    local root = UI.CreateClassAnchor(name, "priest", 156, 26)

    local function makeGroup(label, settingsKey)
        local frame = CreateFrame("Frame", nil, root)
        frame:SetSize(140, 60)
        UI.DecorateGroup(frame)
        local caption = UI.Text(frame, 9, T.muted)
        caption:SetPoint("TOPLEFT", 18, -4)
        caption:SetText(label)
        UI.MakeGroupMovable(frame, settingsKey, "priest")
        frame:Hide()
        return {frame = frame, caption = caption, buttons = {}}
    end

    local buffs = makeGroup(L.BUFFS_FORM, "buffGroup")
    local support = makeGroup(L.SUPPORT, "supportGroup")
    local macros = makeGroup(L.PRIEST_MACROS, "macroGroup")
    local view = {frame = root, groups = {buffs = buffs.frame, support = support.frame, macros = macros.frame}}
    local hoverLabel = UI.Text(macros.frame, 10, T.muted)
    hoverLabel:SetPoint("TOPLEFT", 12, -61)
    hoverLabel:SetPoint("TOPRIGHT", -12, -61)
    hoverLabel:SetWordWrap(false)
    local rangeLabel = UI.Text(macros.frame, 10, T.muted)
    rangeLabel:SetPoint("TOPLEFT", 12, -77)
    local auraLabel = UI.Text(macros.frame, 10, T.muted)
    auraLabel:SetPoint("TOPRIGHT", -12, -77)
    auraLabel:SetJustifyH("RIGHT")

    function view.GetFortitudeSpell()
        local button = macros.buttons.fortitudeNearby
        return button and button.spellID
    end

    function view.RenderFortitudeHint(hasMouseover, name, inRange, hasBuff)
        if not hasMouseover then
            hoverLabel:SetText(L.PRIEST_FORTITUDE_HOVER)
            rangeLabel:SetText("")
            auraLabel:SetText("")
            return
        end
        hoverLabel:SetText(type(name) == "string" and name or L.PRIEST_FORTITUDE_TARGET)
        rangeLabel:SetText(inRange == nil and L.PRIEST_FORTITUDE_RANGE_UNKNOWN
            or inRange and L.PRIEST_FORTITUDE_IN or L.PRIEST_FORTITUDE_OUT)
        rangeLabel:SetTextColor(unpack(inRange == nil and T.muted
            or inRange and T.good or {1, 0.53, 0.39, 1}))
        auraLabel:SetText(hasBuff == nil and L.PRIEST_FORTITUDE_AURA_UNKNOWN
            or hasBuff and L.PRIEST_FORTITUDE_ACTIVE or L.PRIEST_FORTITUDE_MISSING)
        auraLabel:SetTextColor(unpack(hasBuff == false and T.goldLight or T.muted))
    end

    local function makeButton(parent, entry, groupName)
        local bindingID = not readOnly and bindingIDs[entry.key] or nil
        local name = bindingID and ns.Bindings.ButtonName(bindingID)
        local button = CreateFrame("Button", name, parent, not readOnly and "SecureActionButtonTemplate" or nil)
        if name then ns.Bindings.Watch(bindingID, button) end
        button:SetSize(36, 36)
        UI.DecorateActionButton(button)
        button.icon = button:CreateTexture(nil, "ARTWORK")
        button.icon:SetPoint("TOPLEFT", 4, -4)
        button.icon:SetPoint("BOTTOMRIGHT", -4, 4)
        button.icon:SetTexture(spellTexture(entry.spellID) or T.icons.xp)
        button.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

        local spell = spellName(entry.spellID)
        local action = entry.key:gsub("Nearby$", ""):gsub("Self$", ""):gsub("Mouseover$", "")
        local labelKey = actionLabels[action]
        local label = spell or L[labelKey] or entry.key
        local hint = L.PRIEST_CLICK_HINT
        if entry.mode then
            local badge = UI.Text(button, 9, T.goldLight)
            badge:SetPoint("BOTTOM", 0, 3)
            if entry.mode == "mouseover" then
                badge:SetText(L.PRIEST_MACRO_MOUSEOVER)
                hint = L.PRIEST_MACRO_MOUSEOVER_HINT
            elseif entry.mode == "nearby" then
                badge:SetText(L.PRIEST_MACRO_NEAR)
                hint = L.PRIEST_MACRO_NEAR_HINT
            else
                badge:SetText(L.PRIEST_MACRO_SELF)
                hint = L.PRIEST_MACRO_SELF_HINT
            end
        end
        if not readOnly then
            button:RegisterForClicks("LeftButtonDown", "LeftButtonUp")
            button:SetAttribute("useOnKeyDown", false)
            if entry.mode == "nearby" or entry.mode == "mouseover" then
                local makeMacro = entry.mode == "mouseover" and ns.FriendlyBuffs.MouseoverMacro or ns.FriendlyBuffs.Macro
                local macro = makeMacro(spell or L[labelKey])
                if macro then
                    button:SetAttribute("type1", "macro")
                    button:SetAttribute("macrotext1", macro)
                end
            elseif entry.mode == "self" then
                button:SetAttribute("type1", "spell")
                button:SetAttribute("spell", entry.spellID)
                button:SetAttribute("unit", "player")
            else
                button:SetAttribute("type1", "spell")
                button:SetAttribute("spell", entry.spellID)
            end
        end
        UI.Tooltip(button, label, readOnly and L.PREVIEW_HINT or hint)
        if not readOnly then
            UI.TrackSpellCooldown(button, button.icon, entry.spellID)
            UI.TrackSpellPower(button, button.icon, entry.spellID)
            if entry.interrupt then ns.InterruptCue.Track(button, entry.spellID) end
        end
        if groupName == "buffs" then button.activeOutline = UI.ActionOutline(button) end
        button.spellID = entry.spellID
        return button
    end

    local function renderGroup(group, groupName, entries, states, visible, config)
        local frame = group.frame
        local show = visible and config.enabled and #entries > 0
        if not frame.dragging then
            frame:ClearAllPoints()
            frame:SetPoint("TOPLEFT", root, "TOPLEFT", config.position.x, config.position.y)
        end
        local wanted = {}
        local columns = groupName == "macros" and 5 or math.max(1, #entries)
        local extraHeight = math.max(0, math.ceil(#entries / columns) - 1) * 42
        for index, entry in ipairs(entries) do
            wanted[entry.key] = true
            local button = group.buttons[entry.key]
            if not button or button.spellID ~= entry.spellID then
                if button then button:Hide() end
                button = makeButton(frame, entry, groupName)
                group.buttons[entry.key] = button
            end
            button:ClearAllPoints()
            local column, row = (index - 1) % columns, math.floor((index - 1) / columns)
            button:SetPoint("TOPLEFT", frame, "TOPLEFT", 24 + column * 42, -18 - row * 42)
            button:Show()
            if groupName == "buffs" then
                UI.SetActionState(button.activeOutline, states and states[entry.key] or "unknown")
            end
        end
        for key, button in pairs(group.buttons) do
            if not wanted[key] then
                button:Hide()
                group.buttons[key] = nil
            end
        end
        local showHint = groupName == "macros" and wanted.fortitudeNearby == true
        frame:SetSize(math.max(30 + group.caption:GetStringWidth(), 30 + math.min(#entries, columns) * 42, showHint and 246 or 0),
            (showHint and 96 or 60) + extraHeight)
        if groupName == "macros" then
            hoverLabel:SetPoint("TOPLEFT", 12, -61 - extraHeight)
            hoverLabel:SetPoint("TOPRIGHT", -12, -61 - extraHeight)
            rangeLabel:SetPoint("TOPLEFT", 12, -77 - extraHeight)
            auraLabel:SetPoint("TOPRIGHT", -12, -77 - extraHeight)
            hoverLabel:SetShown(showHint)
            rangeLabel:SetShown(showHint)
            auraLabel:SetShown(showHint)
            if showHint and readOnly then view.RenderFortitudeHint(true, L.PREVIEW, true, false) end
        end
        frame:SetShown(show)
        return show
    end

    function view.RenderActions(data, actions, states, preview, config)
        if not preview and InCombatLockdown() then return false end
        config = config or ns.db.priest
        local showBuffs = renderGroup(buffs, "buffs", actions.buffs, states, data.visible, config.buffGroup)
        local showSupport = renderGroup(support, "support", actions.support, nil, data.visible, config.supportGroup)
        local showMacros = config.macroGroup and renderGroup(macros, "macros", actions.macros or {}, nil, data.visible, config.macroGroup)
        root:SetShown(showBuffs or showSupport or showMacros)
        if not readOnly then ns.Bindings.Refresh() end
        return true
    end
    root:Hide();return view
end
