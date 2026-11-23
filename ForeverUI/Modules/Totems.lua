local _, ns = ...
local UI, T, R, L = ns.UI, ns.Theme, ns.Read, ns.L
local M = {}
ns.Totems = M

local elements = {
    {label = "TOTEM_FIRE", index = FIRE_TOTEM_SLOT or 1, spell = 3599, sample = 24},
    {label = "TOTEM_EARTH", index = EARTH_TOTEM_SLOT or 2, spell = 8075, sample = 87},
    {label = "TOTEM_WATER", index = WATER_TOTEM_SLOT or 3, spell = 5394, sample = 51},
    {label = "TOTEM_AIR", index = AIR_TOTEM_SLOT or 4, spell = 8512, sample = 116},
}

local function createFormatter()
    if not (C_DurationUtil and C_DurationUtil.CreateDurationTextBinding and C_StringUtil
        and C_StringUtil.CreateSecondsFormatter and Enum and Enum.SecondsFormatterAbbreviation
        and Enum.SecondsFormatterInterval) then return nil end

    local formatter = C_StringUtil.CreateSecondsFormatter()
    formatter:SetDefaultAbbreviation(Enum.SecondsFormatterAbbreviation.OneLetter)
    formatter:SetMinInterval(Enum.SecondsFormatterInterval.Seconds)
    formatter:SetMillisecondsThreshold(60)
    return formatter
end

local function setTime(slot, seconds)
    seconds = math.ceil(seconds)
    if seconds >= 60 then
        slot.time:SetFormattedText("%d:%02d", math.floor(seconds / 60), seconds % 60)
    else
        slot.time:SetFormattedText("%d", seconds)
    end
end

local function setSlot(slot, active, icon)
    if slot.binding then slot.binding:SetEnabled(false) end
    slot.expires = nil
    slot.active = active
    slot.icon:SetTexture(slot.fallbackIcon)
    slot.icon:SetAlpha(active and 1 or 0.24)
    slot.label:SetTextColor(unpack(active and T.goldLight or T.muted))
    slot.time:SetText("–")
    slot.time:SetAlpha(1)
    if active and ((issecretvalue and issecretvalue(icon)) or (type(icon) == "number" and icon > 0) or type(icon) == "string") then
        pcall(slot.icon.SetTexture, slot.icon, icon)
    end
end

local function setPresenceAlpha(region, haveTotem, inactiveAlpha)
    local setAlpha = region.SetAlphaFromBoolean
    if not setAlpha or not pcall(setAlpha, region, haveTotem, 1, inactiveAlpha) then
        region:SetAlpha(inactiveAlpha)
    end
end

local function refreshSlot(slot, now)
    if type(GetTotemInfo) ~= "function" then return end
    local ok, haveTotem, _, start, duration, icon = pcall(GetTotemInfo, slot.index)
    local active = ok and R.Boolean(haveTotem)
    local hidden = ok and issecretvalue and issecretvalue(haveTotem)
    if active ~= true and not hidden then
        setSlot(slot, false)
        return
    end

    setSlot(slot, true, icon)
    if hidden then
        slot.active = nil
        slot.label:SetTextColor(unpack(T.muted))
        setPresenceAlpha(slot.icon, haveTotem, 0.24)
        setPresenceAlpha(slot.time, haveTotem, 0)
    end
    local startTime, length = R.Number(start), R.Number(duration)
    if startTime and length and length > 0 then
        slot.expires = startTime + length
        if slot.expires > now then setTime(slot, slot.expires - now)
        else setSlot(slot, false) end
    elseif slot.binding and type(GetTotemDuration) == "function" then
        local read, native = pcall(GetTotemDuration, slot.index)
        if read and ((issecretvalue and issecretvalue(native)) or native ~= nil) then
            if pcall(slot.binding.SetDuration, slot.binding, native) then slot.binding:SetEnabled(true) end
        end
    end
end

local function createSlot(root, element, position, formatter, preview)
    local tile = CreateFrame("Frame", nil, root)
    tile:SetSize(47, 37)
    tile:SetPoint("TOPLEFT", 8 + (position - 1) * 51, -21)
    UI.DecorateControl(tile)

    local label = UI.Text(tile, 9, T.muted)
    label:SetPoint("TOP", 0, -4)
    label:SetText(L[element.label])
    local icon = tile:CreateTexture(nil, "ARTWORK")
    icon:SetPoint("BOTTOMLEFT", 4, 4)
    icon:SetSize(17, 17)
    icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    local fallback = R.Call(C_Spell and C_Spell.GetSpellTexture, element.spell)
        or R.Call(GetSpellTexture, element.spell) or T.icons.xp
    local time = UI.Text(tile, 8, T.text)
    time:SetPoint("BOTTOMRIGHT", -3, 8)
    time:SetJustifyH("RIGHT")

    local binding
    if formatter then
        binding = C_DurationUtil.CreateDurationTextBinding()
        binding:SetFormatter(formatter)
        binding:SetFontString(time)
    end

    local slot = {index = element.index, label = label, icon = icon, fallbackIcon = fallback, time = time, binding = binding}
    setSlot(slot, preview == true)
    if preview then setTime(slot, element.sample) end
    if not preview then
        tile:EnableMouse(true)
        tile:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            if slot.active and type(GameTooltip.SetTotem) == "function" then
                if not pcall(GameTooltip.SetTotem, GameTooltip, slot.index) then GameTooltip:SetText(L[element.label]) end
            else
                GameTooltip:SetText(L[element.label])
            end
            GameTooltip:Show()
        end)
        tile:SetScript("OnLeave", function() GameTooltip:Hide() end)
    end
    return slot
end

function M.Create(parent, preview)
    local root = CreateFrame("Frame", nil, parent)
    root:SetSize(216, 66)
    UI.DecorateGroup(root)
    local title = UI.Text(root, 10, T.goldLight)
    title:SetPoint("TOPLEFT", 8, -6)
    title:SetText(L.ACTIVE_TOTEMS)
    root:Hide()

    local slots = {}
    local formatter = not preview and createFormatter()
    for index, element in ipairs(elements) do slots[index] = createSlot(root, element, index, formatter, preview) end

    local function refresh(index)
        local now = GetTime()
        for _, slot in ipairs(slots) do
            if not index or slot.index == index then refreshSlot(slot, now) end
        end
    end

    if not preview then
        root:RegisterEvent("PLAYER_TOTEM_UPDATE")
        root:RegisterEvent("PLAYER_ENTERING_WORLD")
        root:RegisterEvent("PLAYER_REGEN_ENABLED")
        root:SetScript("OnEvent", function(self, event, index)
            if self:IsShown() then refresh(event == "PLAYER_TOTEM_UPDATE" and R.Number(index) or nil) end
        end)

        local elapsed = 0
        root:SetScript("OnUpdate", function(_, delta)
            elapsed = elapsed + delta
            if elapsed < 0.2 then return end
            elapsed = 0
            local now = GetTime()
            for _, slot in ipairs(slots) do
                if slot.expires then
                    local remaining = slot.expires - now
                    if remaining > 0 then setTime(slot, remaining)
                    else setSlot(slot, false) end
                end
            end
        end)
    end

    return {frame = root, Render = function(visible)
        if visible and not preview then refresh() end
        if not visible and not preview then
            for _, slot in ipairs(slots) do setSlot(slot, false) end
        end
        root:SetShown(visible == true)
    end}
end
