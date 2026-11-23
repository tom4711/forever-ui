local _, ns = ...
local UI, R = ns.UI, ns.Read
local visible = {}
local globalCooldown = 61304

local function cooldownTimes(spellID)
    local info = R.Call(C_Spell and C_Spell.GetSpellCooldown, spellID)
    if type(info) == "table" then
        if R.Boolean(info.isEnabled) == false then return end
        return R.Number(info.startTime), R.Number(info.duration), R.Number(info.modRate)
    end
    if type(GetSpellCooldown) == "function" then
        local ok, start, duration, enabled, rate = pcall(GetSpellCooldown, spellID)
        if ok and R.Boolean(enabled) ~= false and R.Number(enabled) ~= 0 then
            return R.Number(start), R.Number(duration), R.Number(rate)
        end
    end
end

local function refresh(state, gcdStart, gcdDuration)
    local frame = state.frame
    if frame.SetCooldownFromDurationObject then
        local duration = R.Call(C_Spell and C_Spell.GetSpellCooldownDuration, state.spellID, true)
        if duration and pcall(frame.SetCooldownFromDurationObject, frame, duration) then return end
    end
    local start, duration, rate = cooldownTimes(state.spellID)
    if start and duration and duration > 0 and (start ~= gcdStart or duration ~= gcdDuration) then
        frame:SetCooldown(start, duration, rate or 1)
    else
        frame:Clear()
    end
end

local events = CreateFrame("Frame")
events:RegisterEvent("SPELL_UPDATE_COOLDOWN")
events:RegisterEvent("ACTIONBAR_UPDATE_COOLDOWN")
events:RegisterEvent("PLAYER_REGEN_ENABLED")
events:SetScript("OnEvent", function()
    if not next(visible) then return end
    local gcdStart, gcdDuration = cooldownTimes(globalCooldown)
    for _, state in pairs(visible) do refresh(state, gcdStart, gcdDuration) end
end)

function UI.TrackSpellCooldown(button, icon, spellID)
    local frame = CreateFrame("Cooldown", nil, button, "CooldownFrameTemplate")
    frame:SetAllPoints(icon)
    frame:EnableMouse(false)
    frame:SetDrawEdge(false)
    frame:SetSwipeColor(0.02, 0.03, 0.04, 0.64)
    frame:SetHideCountdownNumbers(false)
    local state = {frame = frame, spellID = spellID}

    local function show(self)
        visible[self] = state
        refresh(state, cooldownTimes(globalCooldown))
    end
    button:HookScript("OnShow", show)
    button:HookScript("OnHide", function(self) visible[self] = nil end)
    if button:IsVisible() then show(button) end
end
