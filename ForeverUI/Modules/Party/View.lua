local _, ns = ...
local UI, T, R, L = ns.UI, ns.Theme, ns.Read, ns.L
ns.PartyView = {}

local width, height, headerHeight, gap = 244, 72, 22, 6
local auraSize, auraGap, auraLimit = 17, 4, 4
local auraFilter = "HARMFUL|RAID"
local statusTexture = [[Interface\TargetingFrame\UI-StatusBar]]
local roleLabels = {TANK = "PARTY_TANK", HEALER = "PARTY_HEALER", DAMAGER = "PARTY_DAMAGE"}

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

local function createBar(parent, y, barHeight)
    local track = UI.Rect(parent, T.inset, "ARTWORK")
    track:SetPoint("TOPLEFT", 56, y)
    track:SetPoint("TOPRIGHT", -11, y)
    track:SetHeight(barHeight)
    local bar = CreateFrame("StatusBar", nil, parent)
    bar:SetAllPoints(track)
    bar:SetStatusBarTexture(statusTexture)
    return bar
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

local function createCard(root, index, preview)
    local unit = "party" .. index
    local button = CreateFrame("Button", nil, root, not preview and "SecureUnitButtonTemplate" or nil)
    button:SetSize(width, height)
    button:SetPoint("TOPLEFT", 0, -(headerHeight + gap + (index - 1) * (height + gap)))
    if not preview then SecureUnitButton_OnLoad(button, unit, openMenu) end
    UI.DecorateGroup(button)
    button:Hide()

    local portraitFrame = CreateFrame("Frame", nil, button)
    portraitFrame:SetSize(38, 38)
    portraitFrame:SetPoint("TOPLEFT", 10, -10)
    UI.DecorateActionButton(portraitFrame)
    local portrait = portraitFrame:CreateTexture(nil, "ARTWORK")
    portrait:SetPoint("TOPLEFT", 4, -4)
    portrait:SetPoint("BOTTOMRIGHT", -4, 4)

    local name = UI.Text(button, 13, T.goldLight)
    name:SetPoint("TOPLEFT", 56, -8)
    name:SetPoint("TOPRIGHT", -66, -8)
    name:SetWordWrap(false)
    local role = UI.Text(button, 9, T.muted)
    role:SetPoint("TOPRIGHT", -11, -10)
    local health = createBar(button, -26, 11)
    health:SetStatusBarColor(unpack(T.good))
    local amount = UI.Text(health, 9, T.text)
    amount:SetPoint("RIGHT", -4, 0)
    local power = createBar(button, -41, 4)

    local dock = CreateFrame("Frame", nil, button)
    dock:SetSize(auraLimit * (auraSize + auraGap), auraSize)
    dock:SetPoint("TOPLEFT", 56, -49)
    local native = not preview and nativeAuras(dock, unit)
    return {button = button, unit = unit, portrait = portrait, name = name, role = role,
        health = health, amount = amount, power = power, outline = UI.ActionOutline(button),
        auras = not native and fallbackAuras(dock) or nil,
    }
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

function ns.PartyView.Create(preview)
    local root = CreateFrame("Frame", nil, UIParent, not preview and "SecureHandlerStateTemplate" or nil)
    local totalHeight = headerHeight + 4 * (height + gap)
    root:SetSize(width, totalHeight)
    root:SetHitRectInsets(0, 0, 0, totalHeight - headerHeight)
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
    local live = false
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
            end
        end
    end

    function view.Render(event, changedUnit)
        if not live then return end
        for _, card in ipairs(cards) do
            local unit = card.unit
            if (not changedUnit or changedUnit == unit) and R.Boolean(R.Call(UnitExists, unit)) == true then
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
                if not event or event == "PLAYER_TARGET_CHANGED" then
                    local selected = R.Boolean(R.Call(UnitIsUnit, unit, "target")) == true
                    UI.SetActionState(card.outline, selected and "active" or "inactive")
                end
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
            UI.SetActionState(card.outline, index == 2 and "active" or "inactive")
            card.button:Show()
        end
        local sample = cards[3].auras[1]
        sample.icon:SetTexture(136016)
        sample:Show()
        root:Show()
    end

    return view
end
