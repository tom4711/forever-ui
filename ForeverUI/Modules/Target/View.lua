local _, ns = ...
local UI, T, R, M, L = ns.UI, ns.Theme, ns.Read, ns.TargetModel, ns.L
local TargetView = {}
ns.TargetView = TargetView

local width, panelHeight, castHeight, threatHeight, gap = 304, 85, 26, 24, 4
local auraSize, auraGap, auraLimit = 24, 4, 10
local auraRowHeight = auraSize + 12
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
    return icon, cooldown, stack, overlay
end

local function createAuraTimer(overlay)
    local timer = UI.Text(overlay, 9, T.goldLight)
    timer:SetPoint("TOPLEFT", overlay, "BOTTOMLEFT", -1, -1)
    timer:SetPoint("TOPRIGHT", overlay, "BOTTOMRIGHT", 1, -1)
    timer:SetJustifyH("CENTER")
    timer:SetWordWrap(false)
    return timer
end

function TargetView.CreateNativeAuras(dock, unit, filter, size, limit, timerMode)
    local addons = C_AddOns
    if not addons or not addons.IsAddOnLoaded or not addons.LoadAddOn then return end
    if not addons.IsAddOnLoaded("Blizzard_AuraContainer") then
        pcall(addons.LoadAddOn, "Blizzard_AuraContainer")
        if not addons.IsAddOnLoaded("Blizzard_AuraContainer") then return end
    end
    local created, container = pcall(CreateFrame, "AuraContainer", nil, dock, "CustomAuraContainerTemplate")
    if not created or not container then return end
    local initialized = false
    local splitDebuffs = timerMode == "own" and dock.SetClipsChildren
    local showTimers = true
    local timerLabels = {}
    local configured = pcall(function()
        container:SetPoint("TOPLEFT", dock, "TOPLEFT")
        -- Keep both groups on one line, clipped to the existing row's ten slots.
        container:SetFlowLayoutMaximumLineSize(limit * (size + auraGap) * (splitDebuffs and 2 or 1))
        local function addGroup(key, auraFilter, layoutIndex, withTimer)
            container:AddAuraGroup(key, auraFilter, {
                maxFrameCount = limit,
                layout = {elementWidth = size, elementHeight = size, elementSpacing = auraGap,
                    groupSpacing = auraGap, layoutIndex = layoutIndex},
                initializeFrame = function(button)
                    local icon, cooldown, stack, overlay = createAuraRegions(button)
                    if timerMode and cooldown.SetHideCountdownNumbers then
                        cooldown:SetHideCountdownNumbers(true)
                    end
                    button:SetIcon(icon)
                    button:SetDurationCooldown(cooldown)
                    button:SetApplicationCount(stack, nil)
                    if withTimer and button.SetDurationText then
                        local timer = createAuraTimer(overlay)
                        timer:SetShown(showTimers)
                        button:SetDurationText(timer, nil)
                        if splitDebuffs then timerLabels[#timerLabels + 1] = timer end
                    end
                    button:SetTooltipAnchorPoint("ANCHOR_TOP")
                    if button.SetCancelAuraButtons then button:SetCancelAuraButtons(nil) end
                    if button.SetMouseClickEnabled then button:SetMouseClickEnabled(false) end
                    if button.EnableMouseMotion then button:EnableMouseMotion(true) end
                    initialized = true
                end,
            })
        end
        if splitDebuffs then
            dock:SetClipsChildren(true)
            addGroup("OwnEffects", filter .. "|PLAYER", 1, true)
            addGroup("Effects", filter .. "|!PLAYER", 2)
        else
            addGroup("Effects", filter, 1, timerMode == "all")
        end
        container:SetUnit(unit)
    end)
    if not configured or not initialized then
        container:Hide()
        return
    end
    if not splitDebuffs then return container end

    local function setTimerVisibility(enabled)
        if showTimers == enabled then return end
        showTimers = enabled
        for _, timer in ipairs(timerLabels) do timer:SetShown(enabled) end
    end
    return container, setTimerVisibility
end

local function showAuraTooltip(button)
    local aura = button.aura
    if not aura then return end
    GameTooltip:SetOwner(button, "ANCHOR_TOP")
    local helpful = button.filter == "HELPFUL"
    local byInstance, byIndex
    if helpful then
        byInstance, byIndex = GameTooltip.SetUnitBuffByAuraInstanceID, GameTooltip.SetUnitBuff
    else
        byInstance, byIndex = GameTooltip.SetUnitDebuffByAuraInstanceID, GameTooltip.SetUnitDebuff
    end
    if aura.instanceID and byInstance and pcall(byInstance, GameTooltip, "target", aura.instanceID, button.filter) then
        return
    end
    if aura.index and byIndex and pcall(byIndex, GameTooltip, "target", aura.index, button.filter) then return end
    setValue(GameTooltip, GameTooltip.SetText, aura.name, helpful and L.BUFFS or L.DEBUFFS)
    GameTooltip:Show()
end

local function updateAuraTimer(button, now)
    local seconds = math.ceil((button.expirationTime - now) / button.timeMod)
    if seconds >= 3600 then
        button.timer:SetFormattedText("%dh", math.ceil(seconds / 3600))
    elseif seconds >= 600 then
        button.timer:SetFormattedText("%dm", math.ceil(seconds / 60))
    elseif seconds >= 60 then
        button.timer:SetFormattedText("%d:%02d", math.floor(seconds / 60), seconds % 60)
    elseif seconds > 0 then
        button.timer:SetFormattedText("%ds", seconds)
    else
        button.expirationTime = nil
        button.timer:SetText("")
    end
end

local function setAura(button, aura, showTimers)
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
    local rate = aura.timeMod and aura.timeMod > 0 and aura.timeMod or 1
    local now = GetTime()
    local timed = aura.duration and aura.duration > 0 and aura.expirationTime and aura.expirationTime > now
    local wantsTimer = showTimers and (button.filter == "HELPFUL" or aura.own)
    button.expirationTime = wantsTimer and timed and aura.expirationTime or nil
    button.timeMod = rate
    if button.expirationTime then
        updateAuraTimer(button, now)
    else
        button.timer:SetText("")
    end
    if M.Present(aura.durationObject) and cooldown.SetCooldownFromDurationObject
        and pcall(cooldown.SetCooldownFromDurationObject, cooldown, aura.durationObject) then
        cooldown:Show()
    elseif timed then
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
    local extension = castHeight + threatHeight + 2 * auraRowHeight + 4 * gap
    root:SetSize(width, panelHeight + extension)
    root:SetClampedToScreen(true)
    root:SetHitRectInsets(0, 0, 0, extension)
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
    local classLabel = UI.Text(panel, 11, T.text)
    classLabel:SetPoint("LEFT", level, "RIGHT", 8, 0)
    classLabel:SetPoint("RIGHT", healthAmount, "LEFT", -8, 0)
    classLabel:SetWordWrap(false)
    local healthTrack = UI.Rect(panel, T.inset, "BACKGROUND")
    healthTrack:SetPoint("TOPLEFT", 67, -47)
    healthTrack:SetPoint("TOPRIGHT", -12, -47)
    healthTrack:SetHeight(8)
    local healthBar = makeBar(panel, healthTrack)

    local destinationRow = CreateFrame("Frame", nil, panel)
    destinationRow:SetPoint("TOPLEFT", 10, -61)
    destinationRow:SetPoint("TOPRIGHT", -10, -61)
    destinationRow:SetHeight(17)
    UI.DecorateGroup(destinationRow)
    local destinationLabel = UI.Text(destinationRow, 10, T.muted)
    destinationLabel:SetPoint("LEFT", 5, 0)
    destinationLabel:SetText(L.TARGET_OF_TARGET)
    local destination = UI.Text(destinationRow, 11, T.text)
    destination:SetPoint("LEFT", destinationLabel, "RIGHT", 8, 0)
    destination:SetPoint("RIGHT", -5, 0)
    destination:SetJustifyH("RIGHT")
    destination:SetWordWrap(false)
    local destinationButton
    if not preview then
        destinationButton = CreateFrame("Button", nil, destinationRow, "SecureUnitButtonTemplate")
        destinationButton:SetAllPoints()
        destinationButton:SetHighlightTexture([[Interface\QuestFrame\UI-QuestTitleHighlight]], "ADD")
        SecureUnitButton_OnLoad(destinationButton, "targettarget")
        destinationButton:Hide()
    end

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

    local threatPanel = CreateFrame("Frame", nil, root)
    threatPanel:SetSize(width, threatHeight)
    UI.DecorateGroup(threatPanel)
    threatPanel:Hide()
    local threatTitle = UI.Text(threatPanel, 10, T.text)
    threatTitle:SetPoint("TOPLEFT", 7, -4)
    threatTitle:SetText(L.TARGET_THREAT)
    local threatAmount = UI.Text(threatPanel, 10, T.teal)
    threatAmount:SetPoint("TOPRIGHT", -7, -4)
    local threatTrack = UI.Rect(threatPanel, T.inset, "BACKGROUND")
    threatTrack:SetPoint("BOTTOMLEFT", 7, 4)
    threatTrack:SetPoint("BOTTOMRIGHT", -7, 4)
    threatTrack:SetHeight(3)
    local threatBar = makeBar(threatPanel, threatTrack)
    threatBar:SetMinMaxValues(0, 100)

    local function showThreatTooltip()
        GameTooltip:SetOwner(threatPanel, "ANCHOR_BOTTOMLEFT")
        GameTooltip:SetText(L.TARGET_THREAT, unpack(T.goldLight))
        local ranked = not preview and M.ThreatRoster() or {}
        if #ranked == 0 then
            GameTooltip:AddLine(L.TARGET_THREAT_NO_RANKING, unpack(T.muted))
        else
            GameTooltip:AddLine(L.TARGET_THREAT_RATIO, unpack(T.muted))
            for index = 1, math.min(#ranked, 6) do
                local row = ranked[index]
                local label = row.tanking and L.TARGET_THREAT_HOLDER:format(row.name) or row.name
                local percent = math.floor(row.amount / ranked[1].amount * 100 + 0.5)
                GameTooltip:AddDoubleLine(label, ("%d%%"):format(percent), 0.79, 0.85, 0.84, 1, 1, 1)
            end
        end
        GameTooltip:Show()
    end
    threatPanel:EnableMouse(true)
    threatPanel:SetScript("OnEnter", function()
        showThreatTooltip()
        if preview then return end
        local elapsed = 0
        threatPanel:SetScript("OnUpdate", function(self, delta)
            if not GameTooltip:IsOwned(self) then
                self:SetScript("OnUpdate", nil)
                return
            end
            elapsed = elapsed + delta
            if elapsed >= 0.5 then
                elapsed = 0
                showThreatTooltip()
            end
        end)
    end)
    local function hideThreatTooltip()
        threatPanel:SetScript("OnUpdate", nil)
        if GameTooltip:IsOwned(threatPanel) then GameTooltip:Hide() end
    end
    threatPanel:SetScript("OnLeave", hideThreatTooltip)
    threatPanel:SetScript("OnHide", hideThreatTooltip)

    local dock = CreateFrame("Frame", nil, root)
    local rowWidth = auraLimit * (auraSize + auraGap)
    dock:SetSize(rowWidth, 2 * auraRowHeight + gap)
    dock:SetPoint("TOPLEFT", panel, "BOTTOMLEFT", 4, -gap)
    local function auraRow(filter, y)
        local row = CreateFrame("Frame", nil, dock)
        row:SetSize(rowWidth, auraRowHeight)
        row:SetPoint("TOPLEFT", 0, y)
        local native, setNativeTimers
        if not preview then
            local timerMode = filter == "HELPFUL" and "all" or "own"
            native, setNativeTimers = TargetView.CreateNativeAuras(row, "target", filter, auraSize, auraLimit, timerMode)
        end
        return {frame = row, native = native, setNativeTimers = setNativeTimers, filter = filter, buttons = {}}
    end
    local buffs = auraRow("HELPFUL", 0)
    local debuffs = auraRow("HARMFUL", -auraRowHeight - gap)

    local function placeExtensions()
        local afterCast = castPanel:IsShown() and castPanel or panel
        threatPanel:ClearAllPoints()
        threatPanel:SetPoint("TOPLEFT", afterCast, "BOTTOMLEFT", 0, -gap)
        dock:ClearAllPoints()
        dock:SetPoint("TOPLEFT", threatPanel:IsShown() and threatPanel or afterCast, "BOTTOMLEFT", 4, -gap)
    end

    local function setCastShown(shown)
        if castPanel:IsShown() == shown then return end
        castPanel:SetShown(shown)
        placeExtensions()
    end

    local view = {frame = root, AuraLimit = auraLimit}

    function view.SetUnitWatch(enabled)
        if enabled then
            RegisterUnitWatch(root)
            RegisterUnitWatch(destinationButton)
        else
            UnregisterUnitWatch(destinationButton)
            destinationButton:Hide()
            UnregisterUnitWatch(root)
            root:Hide()
        end
    end

    function view.Identity(unitName, unitLevel, className)
        setValue(title, title.SetText, unitName, L.TARGET_FRAME)
        setValue(classLabel, classLabel.SetText, className, "")
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

    function view.Threat(data)
        local shown = data ~= nil
        if threatPanel:IsShown() ~= shown then
            threatPanel:SetShown(shown)
            placeExtensions()
        end
        if not data then return end

        local color = T.teal
        if data.state == "warning" then color = enemyHealth
        elseif data.state == "attention" then color = T.goldLight
        elseif data.state == "tanking" then color = T.good end
        threatBar:SetStatusBarColor(unpack(color))
        threatAmount:SetTextColor(unpack(color))
        local percent = R.Number(data.percent)
        local fill = data.percent
        if percent then fill = math.min(100, percent) end
        setValue(threatBar, threatBar.SetValue, fill, 0)
        if data.tanking then
            threatAmount:SetText(L.TARGET_THREAT_ON_YOU)
        elseif percent then
            threatAmount:SetFormattedText("%d%%", math.floor(percent + 0.5))
        elseif not M.Present(data.percent)
            or not pcall(threatAmount.SetFormattedText, threatAmount, "%s%%", data.percent) then
            threatAmount:SetText("–")
        end
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

    local function updateAuraTimers(row, elapsed)
        row.timerElapsed = (row.timerElapsed or 0) + elapsed
        if row.timerElapsed < 0.2 then return end
        row.timerElapsed = 0
        local anyTimer, now = false, GetTime()
        for _, button in ipairs(row.buttons) do
            if button.expirationTime then
                updateAuraTimer(button, now)
                anyTimer = anyTimer or button.expirationTime ~= nil
            end
        end
        if not anyTimer then row.frame:SetScript("OnUpdate", nil) end
    end

    local function renderAuras(row, auras, restricted, showTimers)
        if row.setNativeTimers then row.setNativeTimers(showTimers) end
        if row.native then
            -- Keep the engine renderer for effects that Lua cannot read.
            local useNative = restricted or #auras == 0
            row.native:SetShown(useNative)
            if useNative then
                row.native:UpdateAllAuras()
                auras = {}
            end
        end
        local auraButtons, anyTimer = row.buttons, false
        for index, aura in ipairs(auras) do
            local button = auraButtons[index]
            if not button then
                button = CreateFrame("Button", nil, row.frame)
                button.filter = row.filter
                button:SetSize(auraSize, auraSize)
                button:SetPoint("TOPLEFT", (index - 1) * (auraSize + auraGap), 0)
                local icon, cooldown, stack, overlay = createAuraRegions(button)
                button.icon, button.cooldown, button.stack = icon, cooldown, stack
                if cooldown.SetHideCountdownNumbers then cooldown:SetHideCountdownNumbers(true) end
                button.timer = createAuraTimer(overlay)
                button.outline = UI.ActionOutline(button)
                button:SetScript("OnEnter", showAuraTooltip)
                button:SetScript("OnLeave", function() GameTooltip:Hide() end)
                auraButtons[index] = button
            end
            setAura(button, aura, showTimers)
            anyTimer = anyTimer or button.expirationTime ~= nil
        end
        for index = #auras + 1, #auraButtons do
            local button = auraButtons[index]
            button.aura, button.expirationTime = nil, nil
            if GameTooltip:IsOwned(button) then GameTooltip:Hide() end
            button:Hide()
        end
        if anyTimer and not row.updateTimers then
            row.updateTimers = function(_, elapsed) updateAuraTimers(row, elapsed) end
        end
        row.frame:SetScript("OnUpdate", anyTimer and row.updateTimers or nil)
    end

    function view.Buffs(auras, restricted) renderAuras(buffs, auras, restricted, true) end
    function view.Debuffs(auras, restricted, showTimers)
        renderAuras(debuffs, auras, restricted, showTimers ~= false)
    end

    function view.ShowPreview(showTimers, showThreat)
        local now = GetTime()
        view.Identity(L.TARGET_DEMO, 32, L.MAGE)
        view.Destination(nil, true)
        view.Health(7580, 9400, true)
        view.Threat(showThreat ~= false and {percent = 92, state = "warning"} or nil)
        view.Cast({name = L.TARGET_CAST_DEMO, icon = 135812, startTime = now - 1.1, endTime = now + 1.4, interruptible = true})
        view.Buffs({{name = L.BUFFS, icon = 135906, duration = 1800, expirationTime = now + 1200}})
        view.Debuffs({
            {name = L.SHADOW_WORD_PAIN, icon = 136207, own = true, duration = 18, expirationTime = now + 11},
            {name = L.HUNTER_MARK, icon = 132212, duration = 120, expirationTime = now + 75},
        }, false, showTimers)
        root:Show()
    end

    return view
end
