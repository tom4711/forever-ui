local _, ns = ...
local UI, T, R = ns.UI, ns.Theme, ns.Read
local visible = {}

local function insufficientPower(spellID)
    local api = C_Spell and C_Spell.IsSpellUsable
    if type(api) == "function" then
        local ok, _, missing = pcall(api, spellID)
        if ok then
            missing = R.Boolean(missing)
            if missing ~= nil then return missing end
        end
    end
    if type(IsUsableSpell) == "function" then
        local ok, _, missing = pcall(IsUsableSpell, spellID)
        return ok and R.Boolean(missing) == true
    end
    return false
end

local function refresh(state)
    local missing = insufficientPower(state.spellID)
    if state.missing == missing then return end
    state.missing = missing
    state.shade:SetShown(missing)
    state.marker:SetShown(missing)
end

local events = CreateFrame("Frame")
events:RegisterUnitEvent("UNIT_POWER_UPDATE", "player")
events:RegisterUnitEvent("UNIT_MAXPOWER", "player")
events:RegisterUnitEvent("UNIT_DISPLAYPOWER", "player")
events:RegisterEvent("ACTIONBAR_UPDATE_USABLE")
events:RegisterEvent("PLAYER_REGEN_ENABLED")
events:SetScript("OnEvent", function()
    for _, state in pairs(visible) do refresh(state) end
end)

function UI.TrackSpellPower(button, icon, spellID, warning)
    local shade = UI.Rect(button, {0.025, 0.08, 0.24, 0.58}, "OVERLAY")
    shade:SetAllPoints(icon)
    shade:SetShown(false)
    local marker = UI.Text(button, 14, T.restedText)
    marker:SetPoint("TOPRIGHT", icon, "TOPRIGHT", -1, 1)
    marker:SetText("!")
    marker:SetShown(false)

    local state = {spellID = spellID, shade = shade, marker = marker}
    local function show(self)
        visible[self] = state
        refresh(state)
    end
    button:HookScript("OnShow", show)
    button:HookScript("OnHide", function(self) visible[self] = nil end)
    button:HookScript("OnEnter", function(self)
        refresh(state)
        if marker:IsShown() and GameTooltip:IsOwned(self) then
            GameTooltip:AddLine(warning or ns.L.NOT_ENOUGH_POWER, unpack(T.restedText, 1, 3))
            GameTooltip:Show()
        end
    end)
    if button:IsVisible() then show(button) end
end
