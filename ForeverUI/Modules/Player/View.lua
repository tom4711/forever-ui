local _,ns=...
local UI,T=ns.UI,ns.Theme
ns.PlayerView={}

local function spellTexture(spellID)
    if not spellID then return nil end
    local texture=ns.Read.Call(C_Spell and C_Spell.GetSpellTexture,spellID)
    if texture then return texture end
    local info=ns.Read.Call(C_Spell and C_Spell.GetSpellInfo,spellID)
    if type(info)=="table"and info.iconID then return info.iconID end
    return nil
end

local powerFallbackColors = {RAGE = {0.82, 0.23, 0.2}, ENERGY = {0.93, 0.76, 0.22}}

local function setPowerAppearance(widget, powerType)
    local L = ns.L
    local label = powerType and (_G[powerType] or L[powerType])
    widget.caption:SetText(type(label) == "string" and label or L.RESOURCE)
    local color = powerType ~= "MANA" and PowerBarColor and PowerBarColor[powerType]
    if color and color.r and color.g and color.b then
        widget.bar:SetStatusBarColor(color.r, color.g, color.b)
    else
        widget.bar:SetStatusBarColor(unpack(powerFallbackColors[powerType] or T.teal))
    end
end

local function setResource(widget,current,maximum)
    local currentSecret=issecretvalue and issecretvalue(current)==true or false
    local maximumSecret=issecretvalue and issecretvalue(maximum)==true or false
    if maximumSecret then
        widget.bar:SetMinMaxValues(0,maximum)
    elseif type(maximum)=="number"and maximum>0 then
        widget.bar:SetMinMaxValues(0,maximum)
    else
        widget.bar:SetMinMaxValues(0,1)
    end
    if currentSecret then
        widget.bar:SetValue(current)
    elseif type(current)=="number"then
        widget.bar:SetValue(current)
    else
        widget.bar:SetValue(0)
    end
    if currentSecret and maximumSecret then
        widget.amount:SetFormattedText("%s / %s",current,maximum)
    elseif currentSecret then
        widget.amount:SetFormattedText("%s / %s",current,type(maximum)=="number"and ns.Format.Number(maximum)or"–")
    elseif maximumSecret then
        widget.amount:SetFormattedText("%s / %s",type(current)=="number"and ns.Format.Number(current)or"–",maximum)
    elseif type(current)=="number"and type(maximum)=="number"and maximum>0 then
        widget.amount:SetText(ns.Format.Number(current).." / "..ns.Format.Number(maximum))
    else
        widget.amount:SetText("– / –")
    end
end

function ns.PlayerView.Create(name,preview)
    local L=ns.L
    local readOnly=preview==true
    local width, statusHeight, iconsPerRow = 390, 104, 8
    local iconSize, iconGap, maxAuras = 34, 6, 40
    local rowHeight, groupHeight, gap = iconSize + iconGap, 64, 6
    local height = statusHeight + 2 * (groupHeight + gap)
    local root=CreateFrame("Frame",name,UIParent)
    -- Keep the stock pet and attached cast bar above the panel when their layouts overlap.
    root:SetFrameStrata("BACKGROUND")
    root:Hide()
    root:SetSize(width,height)
    root:SetClampedToScreen(true)
    local panel=UI.CreatePanel(root)
    panel:SetPoint("TOPLEFT",root,"TOPLEFT")
    panel:SetSize(width,height)

    local portrait=UI.CreateIconButton(panel,nil,true)
    portrait:SetSize(62,62)
    portrait:SetPoint("TOPLEFT",16,-20)
    if not readOnly then
        portrait:RegisterForClicks("RightButtonUp")
        portrait:SetScript("OnClick", function(self)
            if type(UnitPopup_OpenMenu) == "function" then
                UnitPopup_OpenMenu("SELF", {unit = "player", fromPlayerFrame = true, ownerFrame = self})
            end
        end)
        UI.Tooltip(portrait, L.PLAYER_MENU, L.PLAYER_MENU_HINT)
    end
    local title=UI.Text(panel,18,T.goldLight)
    title:SetPoint("TOPLEFT",90,-20)
    local level=UI.Text(panel,12,T.muted)
    level:SetPoint("TOPLEFT",90,-47)
    local resting = UI.Text(panel, 10, T.restedText)
    resting:SetPoint("TOPLEFT", level, "BOTTOMLEFT", 0, -6)
    resting:SetText(L.REST_AREA)
    resting:Hide()

    local function resource(label,y,color)
        local caption=UI.Text(panel,10,T.muted)
        caption:SetPoint("TOPLEFT",215,y)
        caption:SetText(label)
        local amount=UI.Text(panel,10,T.text)
        amount:SetPoint("TOPRIGHT",-18,y)
        amount:SetJustifyH("RIGHT")
        local background=UI.Rect(panel,T.inset,"BACKGROUND")
        background:SetPoint("TOPLEFT",215,y-16)
        background:SetSize(155,8)
        local bar=CreateFrame("StatusBar",nil,panel)
        bar:SetPoint("TOPLEFT",background,"TOPLEFT")
        bar:SetSize(155,8)
        bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
        bar:SetStatusBarColor(unpack(color))
        bar:SetMinMaxValues(0,1)
        bar:SetValue(0)
        return {caption=caption,amount=amount,bar=bar}
    end
    local health=resource(L.HEALTH,-20,T.good)
    local power=resource(L.RESOURCE,-59,T.teal)

    local function makeAuraGroup(label, y)
        local frame = CreateFrame("Frame", nil, panel)
        frame:SetPoint("TOPLEFT", 10, y)
        frame:SetSize(width - 20, groupHeight)
        UI.DecorateGroup(frame)
        local caption = UI.Text(frame, 9, T.muted)
        caption:SetPoint("TOPLEFT", 12, -5)
        caption:SetText(label)

        local scroll = CreateFrame("ScrollFrame", nil, frame)
        scroll:SetPoint("TOPLEFT", 8, -18)
        scroll:SetSize(width - 36, rowHeight)
        local content = CreateFrame("Frame", nil, scroll)
        content:SetSize(width - 36, rowHeight)
        scroll:SetScrollChild(content)
        local group = {scroll = scroll, content = content, buttons = {}, page = 1, pages = 1}

        local function showPage()
            scroll:SetVerticalScroll((group.page - 1) * rowHeight)
            if group.native and group.page > 1 then
                -- The client owns the live aura count. Only the requested row is public here.
                caption:SetFormattedText("%s · %d", label, group.page)
            elseif not group.native and group.pages > 1 then
                caption:SetFormattedText("%s · %d/%d", label, group.page, group.pages)
            else
                caption:SetText(label)
            end
        end
        group.showPage = showPage
        scroll:SetScript("OnMouseWheel", function(_, delta)
            group.page = math.max(1, math.min(group.pages, group.page - delta))
            showPage()
        end)
        return group
    end
    local buffs = makeAuraGroup(L.BUFFS, -statusHeight)
    local debuffs = makeAuraGroup(L.DEBUFFS, -statusHeight - groupHeight - gap)

    local function createAuraRegions(button)
        button:SetSize(iconSize, iconSize)
        UI.DecorateActionButton(button)
        local icon = button:CreateTexture(nil, "ARTWORK")
        icon:SetPoint("TOPLEFT", 4, -4)
        icon:SetPoint("BOTTOMRIGHT", -4, 4)
        icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

        local cooldown = CreateFrame("Cooldown", nil, button, "CooldownFrameTemplate")
        cooldown:SetAllPoints(icon)
        cooldown:SetDrawSwipe(true)
        cooldown:SetDrawBling(false)
        cooldown:SetReverse(true)
        if cooldown.SetMinimumCountdownDuration then cooldown:SetMinimumCountdownDuration(0) end
        if cooldown.SetUseAuraDisplayTime then cooldown:SetUseAuraDisplayTime(true) end

        local labels = CreateFrame("Frame", nil, button)
        labels:SetAllPoints()
        labels:SetFrameLevel(cooldown:GetFrameLevel() + 1)
        local stack = UI.Text(labels, 9, T.text)
        stack:SetPoint("TOPRIGHT", -3, -3)
        stack:SetJustifyH("RIGHT")
        local timer = UI.Text(labels, 9, T.goldLight)
        timer:SetPoint("BOTTOMLEFT", 3, 3)
        return icon, cooldown, stack, timer
    end

    local function createDispelOutline(button)
        local outline = UI.ActionOutline(button)
        for _, texture in ipairs(outline) do texture:SetAlpha(0.75) end
        return outline
    end

    local function createAuraButton(parent, harmful)
        local button = CreateFrame("Button", nil, parent)
        button.icon, button.cooldown, button.stack, button.timer = createAuraRegions(button)
        if harmful then button.dispelOutline = createDispelOutline(button) end
        button:EnableMouse(true)
        button:SetScript("OnEnter",function(self)
            if not self.auraName then return end
            GameTooltip:SetOwner(self,"ANCHOR_TOP")
            GameTooltip:SetText(self.auraName,1,0.82,0.42)
            if self.auraDescription then GameTooltip:AddLine(self.auraDescription,0.79,0.85,0.84,true)end
            GameTooltip:Show()
        end)
        button:SetScript("OnLeave",function()GameTooltip:Hide()end)
        return button
    end

    local function attachNativeAuras(group, filter, dispelFilter)
        local ok, container = pcall(CreateFrame, "AuraContainer", nil, group.content, "CustomAuraContainerTemplate")
        if not ok or not container then return false end
        local initialized = false
        local configured = pcall(function()
            container:SetPoint("TOPLEFT", group.content, "TOPLEFT", 4, -2)
            container:SetFlowLayoutMaximumLineSize(iconsPerRow * rowHeight)
            local function addGroup(key, auraFilter, dispellable, layoutIndex)
                container:AddAuraGroup(key, auraFilter, {
                    maxFrameCount = maxAuras,
                    layout = {
                        elementWidth = iconSize, elementHeight = iconSize,
                        elementSpacing = iconGap, lineSpacing = iconGap,
                        groupSpacing = iconGap, groupLineSpacing = iconGap, layoutIndex = layoutIndex,
                    },
                    initializeFrame = function(button)
                        local icon, cooldown, stack, timer = createAuraRegions(button)
                        cooldown:SetHideCountdownNumbers(true)
                        button:SetIcon(icon)
                        button:SetDurationCooldown(cooldown)
                        button:SetApplicationCount(stack, nil)
                        button:SetDurationText(timer, nil)
                        button:SetTooltipAnchorPoint("ANCHOR_TOP")
                        button:SetCancelAuraButtons(nil)
                        pcall(button.SetMouseClickEnabled, button, false)
                        pcall(button.EnableMouseMotion, button, true)
                        if dispellable then UI.SetActionState(createDispelOutline(button), "active") end
                        initialized = true
                    end,
                })
            end
            if dispelFilter then addGroup("DispellableAuras", dispelFilter, true, 1) end
            addGroup("PlayerAuras", filter, false, 2)
            container:SetUnit("player")
        end)
        if not configured or not initialized then
            pcall(container.Hide, container)
            return false
        end

        -- Use a public, fixed-size scroll child so the layout does not read the native aura geometry.
        group.native = true
        if dispelFilter then group.dispelContainer = container end
        group.pages = math.ceil(maxAuras / iconsPerRow)
        group.content:SetHeight(group.pages * rowHeight)
        group.scroll:UpdateScrollChildRect()
        group.scroll:EnableMouseWheel(true)
        return true
    end

    if not readOnly then
        local addons = C_AddOns
        if addons and addons.IsAddOnLoaded and addons.LoadAddOn and not addons.IsAddOnLoaded("Blizzard_AuraContainer") then
            pcall(addons.LoadAddOn, "Blizzard_AuraContainer")
        end
        attachNativeAuras(buffs, "HELPFUL")
        -- RAID matches harmful auras the player can dispel. Keep both filters in one native flow.
        if not attachNativeAuras(debuffs, "HARMFUL|!RAID", "HARMFUL|RAID") then
            attachNativeAuras(debuffs, "HARMFUL")
        end
    end

    local function updateTimerText(button, now)
        local seconds = button.expirationTime and math.ceil((button.expirationTime - now) / button.timeMod) or 0
        if seconds > 3600 then
            button.timer:SetFormattedText("%dh", math.ceil(seconds / 3600))
        elseif seconds >= 600 then
            button.timer:SetFormattedText("%dm", math.ceil(seconds / 60))
        elseif seconds >= 60 then
            button.timer:SetFormattedText("%d:%02d", math.floor(seconds / 60), seconds % 60)
        elseif seconds > 0 then
            button.timer:SetFormattedText("%ds", seconds)
        else
            button.timer:SetText("")
        end
    end

    local auraGroups = {buffs, debuffs}
    local elapsed = 0
    local function updateLuaTimers(_, delta)
        elapsed = elapsed + delta
        if elapsed < 0.25 then return end
        elapsed = 0
        local now = GetTime()
        for _, group in ipairs(auraGroups) do
            for _, button in ipairs(group.buttons) do
                if button.expirationTime and button:IsShown() then updateTimerText(button, now) end
            end
        end
    end
    if not (buffs.native and debuffs.native) then
        root:SetScript("OnUpdate", updateLuaTimers)
    end

    local function setAuraTimer(button, entry)
        local cooldown = button.cooldown
        local now = GetTime()
        button.expirationTime = entry.expirationTime and entry.expirationTime > now and entry.expirationTime or nil
        button.timeMod = entry.timeMod and entry.timeMod > 0 and entry.timeMod or 1
        updateTimerText(button, now)
        cooldown:SetHideCountdownNumbers(button.expirationTime ~= nil)
        local durationObject = entry.durationObject
        local hasDurationObject = (issecretvalue and issecretvalue(durationObject)) or durationObject ~= nil
        if hasDurationObject and cooldown.SetCooldownFromDurationObject
            and pcall(cooldown.SetCooldownFromDurationObject, cooldown, durationObject) then
            cooldown:Show()
        elseif entry.duration and entry.duration > 0
            and button.expirationTime then
            cooldown:SetCooldown(button.expirationTime - entry.duration, entry.duration, button.timeMod)
            cooldown:Show()
        else
            cooldown:Hide()
        end
    end

    local function renderAuras(group, entries)
        if group.native or group.entries == entries then return end
        group.entries = entries
        entries = entries or {}
        for index, entry in ipairs(entries) do
            local button = group.buttons[index]
            if not button then
                button = createAuraButton(group.content, group == debuffs)
                group.buttons[index] = button
                local row = math.floor((index - 1) / iconsPerRow)
                local column = (index - 1) % iconsPerRow
                button:SetPoint("TOPLEFT", 4 + column * rowHeight, -2 - row * rowHeight)
            end
            button.icon:SetTexture(entry.icon or spellTexture(entry.spellID) or T.icons.xp)
            button.auraName, button.auraDescription = entry.name, entry.description
            UI.SetActionState(button.dispelOutline, entry.dispellable == true and "active" or nil)
            local stacked = entry.applications and entry.applications > 1
            button.stack:SetText(stacked and entry.applications or "")
            button.stack:SetShown(stacked == true)
            setAuraTimer(button, entry)
            button:Show()
        end
        for index = #entries + 1, #group.buttons do group.buttons[index]:Hide() end
        group.pages = math.max(1, math.ceil(#entries / iconsPerRow))
        group.page = math.min(group.page, group.pages)
        group.content:SetHeight(group.pages * rowHeight)
        group.scroll:UpdateScrollChildRect()
        group.scroll:EnableMouseWheel(group.pages > 1)
        group.showPage()
    end

    local view = {frame = root, nativeBuffs = buffs.native, nativeDebuffs = debuffs.native}
    function view.RefreshDispels()
        local container = debuffs.dispelContainer
        if container and container.UpdateAllAuras then pcall(container.UpdateAllAuras, container) end
    end
    function view.Render(data)
        data=data or{}
        title:SetText(type(data.name)=="string"and data.name or L.PLAYER)
        level:SetText(data.level and (L.LEVEL_PREFIX.." "..data.level)or L.LEVEL_UNKNOWN)
        resting:SetShown(data.resting == true)
        if not readOnly and data.portrait=="player"and type(SetPortraitTexture)=="function"then
            pcall(SetPortraitTexture,portrait.icon,"player")
        else
            portrait.icon:SetTexture(data.portrait or (readOnly and T.icons.hunter) or T.icons.xp)
        end
        setResource(health,data.health,data.maxHealth)
        setPowerAppearance(power,data.powerType)
        setResource(power,data.power,data.maxPower)
        renderAuras(buffs, data.buffs)
        renderAuras(debuffs, data.debuffs)
        root:SetShown(data.visible==true)
    end
    UI.MakeMovable(root,"player")
    return view
end
