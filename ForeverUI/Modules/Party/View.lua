local _, ns = ...
local UI, T, R, L = ns.UI, ns.Theme, ns.Read, ns.L
ns.PartyView = {}

local width, headerHeight = 244, 22
local auraSize, auraGap, auraLimit = 17, 4, 4
local auraFilter = "HARMFUL|RAID"
local statusTexture = [[Interface\TargetingFrame\UI-StatusBar]]
local roleLabels = {TANK = "PARTY_TANK", HEALER = "PARTY_HEALER", DAMAGER = "PARTY_DAMAGE"}
local groupRanks = {
    PRIEST = {21562, 21564, 25392, 48161, 48162},
    MAGE = {23028, 27126, 27127, 42995, 43002},
    DRUID = {21849, 21850, 26990, 26991, 48469, 48470},
}
local blessingFamilies = {
    might = "might", greaterMight = "might",
    wisdom = "wisdom", greaterWisdom = "wisdom",
    kings = "kings", greaterKings = "kings",
    salvation = "salvation",
}

local function secret(value)
    return issecretvalue and issecretvalue(value)
end

local function readDisplay(api, ...)
    if type(api) ~= "function" then return nil end
    local ok, value = pcall(api, ...)
    if ok then return value end
end

local function setDisplay(object, setter, value, fallback)
    if (secret(value) or value ~= nil) and pcall(setter, object, value) then return end
    setter(object, fallback)
end

local function setBar(bar, current, maximum)
    local numericMax = R.Number(maximum)
    if not ((secret(maximum) or (numericMax and numericMax > 0)) and pcall(bar.SetMinMaxValues, bar, 0, maximum)) then
        bar:SetMinMaxValues(0, 1)
    end
    setDisplay(bar, bar.SetValue, current, 0)
end

local function createBar(parent)
    local track = UI.Rect(parent, T.inset, "ARTWORK")
    local bar = CreateFrame("StatusBar", nil, parent)
    bar:SetAllPoints(track)
    bar:SetStatusBarTexture(statusTexture)
    return bar, track
end

local function portraitFallback(portrait, class)
    local coords = CLASS_ICON_TCOORDS and CLASS_ICON_TCOORDS[class]
    if coords then
        portrait:SetTexture([[Interface\Glues\CharacterCreate\UI-CharacterCreate-Classes]])
        portrait:SetTexCoord(unpack(coords))
    else
        portrait:SetTexture(T.icons.settings)
        portrait:SetTexCoord(0, 1, 0, 1)
    end
end

local function auraRegions(button)
    UI.DecorateActionButton(button)
    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetPoint("TOPLEFT", 2, -2)
    icon:SetPoint("BOTTOMRIGHT", -2, 2)
    local cooldown = CreateFrame("Cooldown", nil, button, "CooldownFrameTemplate")
    cooldown:SetAllPoints(icon)
    cooldown:SetReverse(true)
    cooldown:SetDrawBling(false)
    cooldown:SetHideCountdownNumbers(true)
    UI.SetActionState(UI.ActionOutline(button), "active")
    return icon, cooldown
end

local function nativeAuras(dock, unit)
    local ok, container = pcall(CreateFrame, "AuraContainer", nil, dock, "CustomAuraContainerTemplate")
    if not ok or not container then return end
    ok = pcall(function()
        container:SetPoint("TOPLEFT")
        container:SetFlowLayoutMaximumLineSize(auraLimit * (auraSize + auraGap))
        container:AddAuraGroup("Dispellable", auraFilter, {
            maxFrameCount = auraLimit,
            layout = {elementWidth = auraSize, elementHeight = auraSize, elementSpacing = auraGap},
            initializeFrame = function(button)
                local icon, cooldown = auraRegions(button)
                button:SetIcon(icon)
                button:SetDurationCooldown(cooldown)
                button:SetTooltipAnchorPoint("ANCHOR_RIGHT")
                if button.SetMouseClickEnabled then button:SetMouseClickEnabled(false) end
                if button.EnableMouseMotion then button:EnableMouseMotion(true) end
                if button.SetPropagateMouseMotion then button:SetPropagateMouseMotion(true) end
            end,
        })
        container:SetUnit(unit)
    end)
    if ok then return container end
    container:Hide()
end

local function fallbackAuras(dock)
    local buttons = {}
    for index = 1, auraLimit do
        local button = CreateFrame("Frame", nil, dock)
        button:SetSize(auraSize, auraSize)
        button:SetPoint("TOPLEFT", (index - 1) * (auraSize + auraGap), 0)
        button.icon, button.cooldown = auraRegions(button)
        button:Hide()
        buttons[index] = button
    end
    return buttons
end

local function updateAuras(card)
    if not card.auras then return end
    local api = C_UnitAuras and C_UnitAuras.GetAuraDataByIndex
    for index, button in ipairs(card.auras) do
        local aura = R.Call(api, card.unit, index, auraFilter)
        if type(aura) == "table" then
            setDisplay(button.icon, button.icon.SetTexture, aura.icon, T.icons.xp)
            local duration, expiry = R.Number(aura.duration), R.Number(aura.expirationTime)
            if duration and duration > 0 and expiry and expiry > GetTime() then
                button.cooldown:SetCooldown(expiry - duration, duration, R.Number(aura.timeMod) or 1)
            else
                button.cooldown:Clear()
            end
            button:Show()
        else
            button:Hide()
        end
    end
end

local function openMenu(frame, unit, ...)
    if type(CompactUnitFrame_OpenMenu) == "function" then
        CompactUnitFrame_OpenMenu(frame, unit, ...)
    elseif type(UnitPopup_OpenMenu) == "function" then
        UnitPopup_OpenMenu("PARTY", {ownerFrame = frame, unit = unit})
    end
end

local function showUnitTooltip(card)
    local tooltip, button, unit = GameTooltip, card.button, card.unit
    if not tooltip or R.Boolean(R.Call(UnitExists, unit)) ~= true then return end
    if GameTooltip_SetDefaultAnchor then GameTooltip_SetDefaultAnchor(tooltip, button)
    else tooltip:SetOwner(button, "ANCHOR_RIGHT") end
    if tooltip:SetUnit(unit) then
        if card.missingBuff:IsShown() and L.PARTY_MISSING_BUFF then
            tooltip:AddLine(L.PARTY_MISSING_BUFF, unpack(T.goldLight))
        end
        tooltip:Show()
    end
end

local function hideUnitTooltip(button)
    if GameTooltip and GameTooltip:IsOwned(button) then GameTooltip:Hide() end
end

local function createCard(root, index, preview)
    local unit = "party" .. index
    local button = CreateFrame("Button", nil, root, not preview and "SecureUnitButtonTemplate" or nil)
    UI.DecorateGroup(button)
    button:Hide()

    local portraitFrame = CreateFrame("Frame", nil, button)
    UI.DecorateActionButton(portraitFrame)
    local portrait = portraitFrame:CreateTexture(nil, "ARTWORK")
    portrait:SetPoint("TOPLEFT", 4, -4)
    portrait:SetPoint("BOTTOMRIGHT", -4, 4)

    local name = UI.Text(button, 13, T.goldLight)
    name:SetWordWrap(false)
    local role = UI.Text(button, 9, T.muted)
    local missingBuff = UI.Text(button, 10, T.goldLight)
    missingBuff:SetText("•")
    missingBuff:Hide()
    local health, healthTrack = createBar(button)
    health:SetStatusBarColor(unpack(T.good))
    local amount = UI.Text(health, 9, T.text)
    amount:SetJustifyH("RIGHT")
    amount:SetPoint("RIGHT", -4, 0)
    local power, powerTrack = createBar(button)

    local dock = CreateFrame("Frame", nil, button)
    dock:SetSize(auraLimit * (auraSize + auraGap), auraSize)
    local native = not preview and nativeAuras(dock, unit)
    local card = {button = button, unit = unit, portraitFrame = portraitFrame, portrait = portrait,
        name = name, role = role, missingBuff = missingBuff,
        health = health, healthTrack = healthTrack, amount = amount, power = power, powerTrack = powerTrack,
        dock = dock, outline = UI.ActionOutline(button),
        auras = not native and fallbackAuras(dock) or nil,
    }
    if not preview then
        SecureUnitButton_OnLoad(button, unit, openMenu)
        button.unit = unit
        button:EnableMouse(true)
        button:SetScript("OnEnter", function() showUnitTooltip(card) end)
        button:SetScript("OnLeave", hideUnitTooltip)
        button:SetScript("OnHide", hideUnitTooltip)
    end
    return card
end

local function placeTrack(track, left, right, y, height)
    track:ClearAllPoints()
    track:SetPoint("TOPLEFT", left, y)
    track:SetPoint("TOPRIGHT", right, y)
    track:SetHeight(height)
end

local function layoutCard(card, index, compact, showPortrait, showMissingBuff, height, gap)
    local left = showPortrait and (compact and 43 or 56) or 11
    local nameY = compact and -4 or -8
    local barRight = compact and -99 or -11
    local button = card.button
    button:SetSize(width, height)
    button:ClearAllPoints()
    button:SetPoint("TOPLEFT", 0, -(headerHeight + gap + (index - 1) * (height + gap)))

    card.portraitFrame:ClearAllPoints()
    card.portraitFrame:SetSize(compact and 27 or 38, compact and 27 or 38)
    card.portraitFrame:SetPoint("TOPLEFT", compact and 8 or 10, compact and -7 or -10)
    card.portraitFrame:SetShown(showPortrait)
    card.name:ClearAllPoints()
    card.name:SetPoint("TOPLEFT", left, nameY)
    card.name:SetPoint("TOPRIGHT", showMissingBuff and -79 or -66, nameY)
    card.role:ClearAllPoints()
    card.role:SetPoint("TOPRIGHT", showMissingBuff and -23 or -11, nameY - 2)
    card.missingBuff:ClearAllPoints()
    card.missingBuff:SetPoint("TOPRIGHT", -10, nameY - 1)

    placeTrack(card.healthTrack, left, barRight, compact and -22 or -26, compact and 8 or 11)
    placeTrack(card.powerTrack, left, barRight, compact and -34 or -41, compact and 3 or 4)
    card.dock:ClearAllPoints()
    if compact then card.dock:SetPoint("TOPRIGHT", -10, -22)
    else card.dock:SetPoint("TOPLEFT", left, -49) end
end

local function amount(value)
    if secret(value) then return value end
    local number = R.Number(value)
    return number and ns.Format.Number(number) or "–"
end

local function updateHealth(card, current, maximum)
    setBar(card.health, current, maximum)
    if not pcall(card.amount.SetFormattedText, card.amount, "%s / %s", amount(current), amount(maximum)) then
        card.amount:SetText("– / –")
    end
end

local function updatePower(card, current, maximum, powerType)
    local color = PowerBarColor and PowerBarColor[powerType]
    if color then card.power:SetStatusBarColor(color.r, color.g, color.b)
    else card.power:SetStatusBarColor(unpack(T.teal)) end
    setBar(card.power, current, maximum)
end

local function updateIdentity(card)
    local unit = card.unit
    setDisplay(card.name, card.name.SetText, readDisplay(UnitName, unit), L.PARTY_MEMBER)
    if not card.portraitFrame:IsShown() then return end
    card.portrait:SetTexCoord(0, 1, 0, 1)
    if not SetPortraitTexture or not pcall(SetPortraitTexture, card.portrait, unit) then
        portraitFallback(card.portrait)
    end
end

local function updateState(card)
    local unit = card.unit
    local label
    if R.Boolean(R.Call(UnitIsConnected, unit)) == false then label = "PARTY_OFFLINE"
    elseif R.Boolean(R.Call(UnitIsDeadOrGhost, unit)) == true then label = "PARTY_DEAD"
    else label = roleLabels[R.Call(UnitGroupRolesAssigned, unit)] end
    card.role:SetText(L[label] or "")
end

local function updateRange(card)
    local dim = false
    if type(UnitInRange) == "function" and R.Boolean(R.Call(UnitIsConnected, card.unit)) == true then
        local ok, inRange, checkedRange = pcall(UnitInRange, card.unit)
        dim = ok and R.Boolean(checkedRange) == true and R.Boolean(inRange) == false
    end
    card.button:SetAlpha(dim and 0.55 or 1)
end

local function knowsAnyRank(ranks)
    for _, id in ipairs(ranks or {}) do
        if R.SpellKnown(id) then return true end
    end
    return false
end

local function addLearnedFamily(result, ranks, equivalent)
    if not knowsAnyRank(ranks) and not knowsAnyRank(equivalent) then return end
    for _, id in ipairs(ranks or {}) do result[id] = true end
    for _, id in ipairs(equivalent or {}) do result[id] = true end
end

local function learnedGroupBuffs()
    local class = R.Call(function()
        local _, token = UnitClass("player")
        return token
    end)
    local result = {}
    if class == "PRIEST" and ns.PriestModel then
        for _, entry in ipairs(ns.PriestModel.SpellActions) do
            if entry.key == "fortitude" then
                addLearnedFamily(result, entry.spells, groupRanks.PRIEST)
                break
            end
        end
    elseif class == "PALADIN" and ns.PaladinModel then
        local families = {salvation = {25895}}
        for _, entry in ipairs(ns.PaladinModel.SpellGroups) do
            local family = blessingFamilies[entry.key]
            if family then
                local ranks = families[family] or {}
                for _, id in ipairs(entry.spells) do ranks[#ranks + 1] = id end
                families[family] = ranks
            end
        end
        for _, ranks in pairs(families) do addLearnedFamily(result, ranks) end
    elseif class == "MAGE" or class == "DRUID" then
        addLearnedFamily(result, ns.ClassSupport and ns.ClassSupport.GroupBuffRanks(class), groupRanks[class])
    end
    if next(result) then return result end
end

local function confirmedMissingBuff(unit, buffs)
    if not buffs or R.Boolean(R.Call(UnitIsConnected, unit)) ~= true
        or R.Boolean(R.Call(UnitIsDeadOrGhost, unit)) ~= false
        or R.Boolean(R.Call(UnitIsVisible, unit)) ~= true then return false end
    local isRestricted = C_Secrets and C_Secrets.ShouldAurasBeSecret
    if isRestricted and R.Boolean(R.Call(isRestricted)) ~= false then return false end
    local getter = C_UnitAuras and C_UnitAuras.GetAuraDataByIndex
    for index = 1, 80 do
        local ok, aura = R.Try(getter, unit, index, "HELPFUL")
        if not ok then return false end
        if aura == nil then return true end
        if type(aura) ~= "table" then return false end
        local id = R.Number(R.Call(function() return aura.spellId end))
        if not id or buffs[id] then return false end
    end
    return false
end

local function showMissingBuff(card, missing)
    if card.missingBuff:IsShown() == missing then return end
    card.missingBuff:SetShown(missing)
    if GameTooltip and GameTooltip:IsOwned(card.button) then showUnitTooltip(card) end
end

local rangeEvents = {UNIT_IN_RANGE_UPDATE = true, UNIT_CONNECTION = true, UNIT_PHASE = true,
    PLAYER_REGEN_DISABLED = true, PLAYER_REGEN_ENABLED = true}
local spellEvents = {SPELLS_CHANGED = true, LEARNED_SPELL_IN_SKILL_LINE = true}

function ns.PartyView.Create(preview)
    local root = CreateFrame("Frame", nil, UIParent, not preview and "SecureHandlerStateTemplate" or nil)
    root:SetClampedToScreen(true)
    UI.MakeMovable(root, "party")
    root:Hide()
    local title = CreateFrame("Frame", nil, root)
    title:SetSize(width, headerHeight)
    title:SetPoint("TOPLEFT")
    UI.DecorateGroup(title)
    local label = UI.Text(title, 12, T.goldLight)
    label:SetPoint("LEFT", 10, 0)
    label:SetText(L.PARTY_MEMBERS)

    if not preview then
        local addons = C_AddOns
        if addons and addons.LoadAddOn and addons.IsAddOnLoaded and not addons.IsAddOnLoaded("Blizzard_AuraContainer") then
            pcall(addons.LoadAddOn, "Blizzard_AuraContainer")
        end
    end
    local cards = {}
    for index = 1, 4 do cards[index] = createCard(root, index, preview) end

    local view = {frame = root}
    local live, compact, portraitEnabled, buffHintEnabled, buffs = false
    function view.ApplySettings(config)
        local nextCompact = config.compact == true
        local nextPortrait = config.showPortrait ~= false
        local nextBuffHint = config.showMissingBuff == true
        if compact == nextCompact and portraitEnabled == nextPortrait and buffHintEnabled == nextBuffHint then return end
        compact, portraitEnabled, buffHintEnabled = nextCompact, nextPortrait, nextBuffHint
        local height, gap = compact and 44 or 72, compact and 4 or 6
        local totalHeight = headerHeight + #cards * (height + gap)
        root:SetSize(width, totalHeight)
        root:SetHitRectInsets(0, 0, 0, totalHeight - headerHeight)
        for index, card in ipairs(cards) do
            layoutCard(card, index, compact, portraitEnabled, buffHintEnabled, height, gap)
        end
    end

    function view.SetLive(enabled)
        if live == enabled then return end
        live = enabled
        if enabled then
            for _, card in ipairs(cards) do RegisterUnitWatch(card.button) end
            RegisterStateDriver(root, "visibility", "[group:raid] hide; [group:party] show; hide")
        else
            UnregisterStateDriver(root, "visibility")
            root:Hide()
            for _, card in ipairs(cards) do
                UnregisterUnitWatch(card.button)
                card.button:Hide()
                card.button:SetAlpha(1)
                showMissingBuff(card, false)
            end
        end
    end

    function view.Render(event, changedUnit)
        if not live then return end
        if not event or spellEvents[event] then buffs = buffHintEnabled and learnedGroupBuffs() or nil end
        for _, card in ipairs(cards) do
            local unit = card.unit
            local matchesUnit = not changedUnit or changedUnit == unit
            local exists = matchesUnit and R.Boolean(R.Call(UnitExists, unit)) == true
            if exists then
                if not event or event == "UNIT_NAME_UPDATE" or event == "UNIT_PORTRAIT_UPDATE" or event == "UNIT_CONNECTION" then
                    updateIdentity(card)
                end
                if not event or event == "UNIT_CONNECTION" or event == "UNIT_FLAGS" or event == "UNIT_HEALTH" then
                    updateState(card)
                end
                if not event or event == "UNIT_HEALTH" or event == "UNIT_MAXHEALTH" then
                    updateHealth(card, readDisplay(UnitHealth, unit), readDisplay(UnitHealthMax, unit))
                end
                if not event or event == "UNIT_POWER_UPDATE" or event == "UNIT_MAXPOWER" or event == "UNIT_DISPLAYPOWER" then
                    updatePower(card, readDisplay(UnitPower, unit), readDisplay(UnitPowerMax, unit),
                        R.Number(R.Call(UnitPowerType, unit)))
                end
                if not event or event == "UNIT_AURA" then updateAuras(card) end
                if not event or rangeEvents[event] then updateRange(card) end
                if not event or rangeEvents[event] or spellEvents[event] or event == "UNIT_AURA" or event == "UNIT_FLAGS" then
                    showMissingBuff(card, confirmedMissingBuff(unit, buffs))
                end
                if not event or event == "PLAYER_TARGET_CHANGED" then
                    local selected = R.Boolean(R.Call(UnitIsUnit, unit, "target")) == true
                    UI.SetActionState(card.outline, selected and "active" or "inactive")
                end
            elseif matchesUnit then
                card.button:SetAlpha(1)
                showMissingBuff(card, false)
            end
        end
    end

    function view.ShowPreview()
        local classes = {"WARRIOR", "PRIEST", "ROGUE", "MAGE"}
        local names = {"Brom", "Liora", "Mara", "Tavin"}
        local roles = {"PARTY_TANK", "PARTY_HEALER", "PARTY_DAMAGE", "PARTY_DAMAGE"}
        local health = {2450, 1900, 1080, 2200}
        local powers = {1, 0, 3, 0}
        for index, card in ipairs(cards) do
            card.name:SetText(names[index])
            card.role:SetText(L[roles[index]])
            portraitFallback(card.portrait, classes[index])
            updateHealth(card, health[index], 2500)
            updatePower(card, 90 - index * 10, 100, powers[index])
            card.button:SetAlpha(index == 4 and 0.55 or 1)
            showMissingBuff(card, buffHintEnabled and index == 2)
            UI.SetActionState(card.outline, index == 2 and "active" or "inactive")
            card.button:Show()
        end
        local sample = cards[3].auras[1]
        sample.icon:SetTexture(136016)
        sample:Show()
        root:Show()
    end

    view.ApplySettings(ns.db and ns.db.party or {})
    return view
end
