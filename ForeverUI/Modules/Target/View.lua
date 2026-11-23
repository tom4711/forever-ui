local _, ns = ...
local UI, T, R, M, L = ns.UI, ns.Theme, ns.Read, ns.TargetModel, ns.L
local TargetView = {}
ns.TargetView = TargetView

local width, panelHeight, castHeight, gap = 304, 85, 26, 4
local auraSize, auraGap, auraLimit = 24, 4, 10
local barTexture = [[Interface\TargetingFrame\UI-StatusBar]]
local enemyHealth = {0.80, 0.30, 0.25, 1}
local unknownIcon = 134400

local function setValue(widget, setter, value, fallback)
    if not M.Present(value) or not pcall(setter, widget, value) then setter(widget, fallback) end
end

local function setHealth(bar, label, current, maximum)
    local publicMaximum = R.Number(maximum)
    local hasMaximum = (issecretvalue and issecretvalue(maximum)) or (publicMaximum and publicMaximum > 0)
    if not hasMaximum or not pcall(bar.SetMinMaxValues, bar, 0, maximum) then
        bar:SetMinMaxValues(0, 1)
    end
    setValue(bar, bar.SetValue, current, 0)

    local function amount(value)
        if issecretvalue and issecretvalue(value) then return value end
        local number = R.Number(value)
        return number and ns.Format.Number(number) or "–"
    end
    if not pcall(label.SetFormattedText, label, "%s / %s", amount(current), amount(maximum)) then
        label:SetText("– / –")
    end
end

local function makeBar(parent, track)
    local bar = CreateFrame("StatusBar", nil, parent)
    bar:SetAllPoints(track)
    bar:SetStatusBarTexture(barTexture)
    bar:SetMinMaxValues(0, 1)
    bar:SetValue(0)
    return bar
end

local function createAuraRegions(button)
    UI.DecorateActionButton(button)
    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetPoint("TOPLEFT", 3, -3)
    icon:SetPoint("BOTTOMRIGHT", -3, 3)
    icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    local cooldown = CreateFrame("Cooldown", nil, button, "CooldownFrameTemplate")
    cooldown:SetAllPoints(icon)
    cooldown:SetDrawBling(false)
    cooldown:SetReverse(true)
    if cooldown.SetUseAuraDisplayTime then cooldown:SetUseAuraDisplayTime(true) end
    local overlay = CreateFrame("Frame", nil, button)
    overlay:SetAllPoints()
    overlay:SetFrameLevel(cooldown:GetFrameLevel() + 1)
    local stack = UI.Text(overlay, 9, T.text)
    stack:SetPoint("BOTTOMRIGHT", -2, 1)
    return icon, cooldown, stack
end

local function createNativeDebuffs(dock)
    local addons = C_AddOns
    if not addons or not addons.IsAddOnLoaded or not addons.LoadAddOn then return end
    if not addons.IsAddOnLoaded("Blizzard_AuraContainer") then
        pcall(addons.LoadAddOn, "Blizzard_AuraContainer")
        if not addons.IsAddOnLoaded("Blizzard_AuraContainer") then return end
    end
    local created, container = pcall(CreateFrame, "AuraContainer", nil, dock, "CustomAuraContainerTemplate")
    if not created or not container then return end
    local configured = pcall(function()
        container:SetPoint("TOPLEFT")
        container:SetFlowLayoutMaximumLineSize(auraLimit * (auraSize + auraGap))
        -- Blizzard's default comparator puts effects cast by the player first.
        container:AddAuraGroup("Debuffs", "HARMFUL", {
            maxFrameCount = auraLimit,
            layout = {elementWidth = auraSize, elementHeight = auraSize, elementSpacing = auraGap},
            initializeFrame = function(button)
                local icon, cooldown, stack = createAuraRegions(button)
                button:SetIcon(icon)
                button:SetDurationCooldown(cooldown)
                button:SetApplicationCount(stack, nil)
                button:SetTooltipAnchorPoint("ANCHOR_TOP")
                if button.SetMouseClickEnabled then button:SetMouseClickEnabled(false) end
                if button.EnableMouseMotion then button:EnableMouseMotion(true) end
            end,
        })
        container:SetUnit("target")
    end)
    if configured then return container end
    container:Hide()
end

local function showAuraTooltip(button)
    local aura = button.aura
    if not aura then return end
    GameTooltip:SetOwner(button, "ANCHOR_TOP")
    if aura.instanceID and GameTooltip.SetUnitDebuffByAuraInstanceID
        and pcall(GameTooltip.SetUnitDebuffByAuraInstanceID, GameTooltip, "target", aura.instanceID, "HARMFUL") then
        return
    end
    if aura.index and GameTooltip.SetUnitDebuff
        and pcall(GameTooltip.SetUnitDebuff, GameTooltip, "target", aura.index, "HARMFUL") then
        return
    end
    setValue(GameTooltip, GameTooltip.SetText, aura.name, L.DEBUFFS)
    GameTooltip:Show()
end

local function setAura(button, aura)
    button.aura = aura
    setValue(button.icon, button.icon.SetTexture, aura.icon, unknownIcon)
    local count = R.Number(aura.applications)
    if issecretvalue and issecretvalue(aura.applications) then
        setValue(button.stack, button.stack.SetText, aura.applications, "")
    else
        button.stack:SetText(count and count > 1 and count or "")
    end
    UI.SetActionState(button.outline, aura.own and "active" or nil)
    local cooldown = button.cooldown
    if M.Present(aura.durationObject) and cooldown.SetCooldownFromDurationObject
        and pcall(cooldown.SetCooldownFromDurationObject, cooldown, aura.durationObject) then
        cooldown:Show()
    elseif aura.duration and aura.duration > 0 and aura.expirationTime and aura.expirationTime > GetTime() then
        local rate = aura.timeMod and aura.timeMod > 0 and aura.timeMod or 1
        cooldown:SetCooldown(aura.expirationTime - aura.duration, aura.duration, rate)
        cooldown:Show()
    else
        cooldown:Hide()
    end
    button:Show()
    if GameTooltip:IsOwned(button) then showAuraTooltip(button) end
end

function TargetView.Create(name, preview)
    local root = CreateFrame("Button", name, UIParent, not preview and "SecureUnitButtonTemplate" or nil)
    root:Hide()
    root:SetSize(width, panelHeight + castHeight + auraSize + 2 * gap)
    root:SetClampedToScreen(true)
    root:SetHitRectInsets(0, 0, 0, castHeight + auraSize + 2 * gap)
    if not preview then SecureUnitButton_OnLoad(root, "target", TargetFrame_OpenMenu) end
    UI.MakeMovable(root, "target")

    local panel = UI.CreatePanel(root)
    panel:SetPoint("TOPLEFT")
    panel:SetSize(width, panelHeight)
    local portraitFrame = CreateFrame("Frame", nil, panel)
    portraitFrame:SetSize(46, 46)
    portraitFrame:SetPoint("TOPLEFT", 10, -10)
    UI.DecorateActionButton(portraitFrame)
    local portrait = portraitFrame:CreateTexture(nil, "ARTWORK")
    portrait:SetPoint("TOPLEFT", 4, -4)
    portrait:SetPoint("BOTTOMRIGHT", -4, 4)

    local title = UI.Text(panel, 16, T.goldLight)
    title:SetPoint("TOPLEFT", 67, -10)
    title:SetPoint("TOPRIGHT", -12, -10)
    title:SetWordWrap(false)
    local level = UI.Text(panel, 11, T.muted)
    level:SetPoint("TOPLEFT", 67, -32)
    local healthAmount = UI.Text(panel, 11, T.text)
    healthAmount:SetPoint("TOPRIGHT", -12, -32)
    healthAmount:SetJustifyH("RIGHT")
    local healthTrack = UI.Rect(panel, T.inset, "BACKGROUND")
    healthTrack:SetPoint("TOPLEFT", 67, -47)
    healthTrack:SetPoint("TOPRIGHT", -12, -47)
    healthTrack:SetHeight(8)
    local healthBar = makeBar(panel, healthTrack)

    local destinationLabel = UI.Text(panel, 10, T.muted)
    destinationLabel:SetPoint("TOPLEFT", 12, -65)
    destinationLabel:SetText(L.TARGET_OF_TARGET)
    local destination = UI.Text(panel, 11, T.text)
    destination:SetPoint("TOPLEFT", destinationLabel, "TOPRIGHT", 8, 0)
    destination:SetPoint("TOPRIGHT", -12, -65)
    destination:SetJustifyH("RIGHT")
    destination:SetWordWrap(false)

    local castPanel = CreateFrame("Frame", nil, root)
    castPanel:SetPoint("TOPLEFT", panel, "BOTTOMLEFT", 0, -gap)
    castPanel:SetSize(width, castHeight)
    UI.DecorateGroup(castPanel)
    local interruptOutline = not preview and ns.InterruptCue.Outline(castPanel)
    castPanel:Hide()
    local castIcon = castPanel:CreateTexture(nil, "ARTWORK")
    castIcon:SetPoint("LEFT", 5, 0)
    castIcon:SetSize(16, 16)
    castIcon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    local castName = UI.Text(castPanel, 11, T.text)
    castName:SetPoint("TOPLEFT", 27, -4)
    castName:SetPoint("TOPRIGHT", -126, -4)
    castName:SetWordWrap(false)
    local castStatus = UI.Text(castPanel, 10, T.muted)
    castStatus:SetPoint("TOPRIGHT", -7, -5)
    local castTrack = UI.Rect(castPanel, T.inset, "BACKGROUND")
    castTrack:SetPoint("BOTTOMLEFT", 27, 4)
    castTrack:SetPoint("BOTTOMRIGHT", -7, 4)
    castTrack:SetHeight(3)
    local castBar = makeBar(castPanel, castTrack)
    local nativeCastBar = makeBar(castPanel, castTrack)

    local dock = CreateFrame("Frame", nil, root)
    dock:SetSize(auraLimit * (auraSize + auraGap), auraSize)
    dock:SetPoint("TOPLEFT", panel, "BOTTOMLEFT", 4, -gap)
    local nativeDebuffs
    if not preview then nativeDebuffs = createNativeDebuffs(dock) end
    local auraButtons = {}

    local function setCastShown(shown)
        if castPanel:IsShown() == shown then return end
        castPanel:SetShown(shown)
        dock:ClearAllPoints()
        dock:SetPoint("TOPLEFT", shown and castPanel or panel, "BOTTOMLEFT", 4, -gap)
    end

    local view = {frame = root, NativeDebuffs = nativeDebuffs ~= nil, AuraLimit = auraLimit}

    function view.SetUnitWatch(enabled)
        if enabled then
            RegisterUnitWatch(root)
        else
            UnregisterUnitWatch(root)
            root:Hide()
        end
    end

    function view.Identity(unitName, unitLevel)
        setValue(title, title.SetText, unitName, L.TARGET_FRAME)
        local numericLevel = R.Number(unitLevel)
        if issecretvalue and issecretvalue(unitLevel) then
            if not pcall(level.SetFormattedText, level, "%s %s", L.LEVEL_PREFIX, unitLevel) then
                level:SetText(L.LEVEL_UNKNOWN)
            end
        elseif numericLevel and numericLevel > 0 then
            level:SetFormattedText("%s %d", L.LEVEL_PREFIX, numericLevel)
        elseif numericLevel == -1 then
            level:SetText(L.TARGET_LEVEL_BOSS)
        else
            level:SetText(L.LEVEL_UNKNOWN)
        end
        if preview or type(SetPortraitTexture) ~= "function" or not pcall(SetPortraitTexture, portrait, "target") then
            portrait:SetTexture(preview and 132182 or unknownIcon)
        end
    end

    function view.Destination(name, isPlayer)
        destination:SetTextColor(unpack(isPlayer and T.goldLight or T.text))
        if isPlayer then destination:SetText(L.TARGET_IS_YOU)
        else setValue(destination, destination.SetText, name, "–") end
    end

    function view.Health(current, maximum, hostile)
        healthBar:SetStatusBarColor(unpack(hostile and enemyHealth or T.good))
        setHealth(healthBar, healthAmount, current, maximum)
    end

    function view.Cast(cast)
        if not cast then
            setCastShown(false)
            castPanel:SetScript("OnUpdate", nil)
            if not preview then ns.InterruptCue.SetCast(interruptOutline) end
            return
        end
        local directions = Enum and Enum.StatusBarTimerDirection
        local direction = directions and (cast.channel and directions.RemainingTime or directions.ElapsedTime)
        local interpolation = Enum and Enum.StatusBarInterpolation
        local native = direction ~= nil and nativeCastBar.SetTimerDuration and M.Present(cast.duration)
            and pcall(nativeCastBar.SetTimerDuration, nativeCastBar, cast.duration,
                interpolation and interpolation.Immediate or 0, direction)
        local progress = M.CastProgress(cast, GetTime())
        if cast.endTime and not progress then view.Cast(nil); return end
        local color, text = T.gold, ""
        if cast.interruptible == true then
            text = L.TARGET_CAST_INTERRUPTIBLE
        elseif cast.interruptible == false then
            color, text = T.muted, L.TARGET_CAST_UNINTERRUPTIBLE
        end
        setValue(castName, castName.SetText, cast.name, L.TARGET_CAST)
        setValue(castIcon, castIcon.SetTexture, cast.icon, unknownIcon)
        castStatus:SetText(text)
        castBar:SetShown(not native)
        nativeCastBar:SetShown(native == true)
        local fill = native and nativeCastBar or castBar
        fill:SetStatusBarColor(unpack(color))
        if not native then castBar:SetValue(progress or 0) end
        setCastShown(true)
        if not preview then ns.InterruptCue.SetCast(interruptOutline, cast.notInterruptible) end
        if cast.endTime and not preview then
            castPanel:SetScript("OnUpdate", function()
                local value = M.CastProgress(cast, GetTime())
                if value == nil then view.Cast(nil)
                elseif not native then castBar:SetValue(value) end
            end)
        else
            castPanel:SetScript("OnUpdate", nil)
        end
    end

    function view.RefreshNativeDebuffs()
        if nativeDebuffs and nativeDebuffs.UpdateAllAuras then nativeDebuffs:UpdateAllAuras() end
    end

    function view.Debuffs(auras)
        if nativeDebuffs then return end
        for index, aura in ipairs(auras) do
            local button = auraButtons[index]
            if not button then
                button = CreateFrame("Button", nil, dock)
                button:SetSize(auraSize, auraSize)
                button:SetPoint("TOPLEFT", (index - 1) * (auraSize + auraGap), 0)
                button.icon, button.cooldown, button.stack = createAuraRegions(button)
                button.outline = UI.ActionOutline(button)
                button:SetScript("OnEnter", showAuraTooltip)
                button:SetScript("OnLeave", function() GameTooltip:Hide() end)
                auraButtons[index] = button
            end
            setAura(button, aura)
        end
        for index = #auras + 1, #auraButtons do
            local button = auraButtons[index]
            button.aura = nil
            if GameTooltip:IsOwned(button) then GameTooltip:Hide() end
            button:Hide()
        end
    end

    function view.ShowPreview()
        local now = GetTime()
        view.Identity(L.TARGET_DEMO, 32)
        view.Destination(nil, true)
        view.Health(7580, 9400, true)
        view.Cast({name = L.TARGET_CAST_DEMO, icon = 135812, startTime = now - 1.1, endTime = now + 1.4, interruptible = true})
        view.Debuffs({
            {name = L.SHADOW_WORD_PAIN, icon = 136207, own = true, duration = 18, expirationTime = now + 11},
            {name = L.HUNTER_MARK, icon = 132212, duration = 120, expirationTime = now + 75},
        })
        root:Show()
    end

    return view
end
