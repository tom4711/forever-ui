local _, ns = ...
local UI, T = ns.UI, ns.Theme
local ActionBars = {}
ns.ActionBars = ActionBars

local stockBars = {
    "MainActionBar", "MultiBarBottomLeft", "MultiBarBottomRight",
    "MultiBarRight", "MultiBarLeft", "MultiBar5", "MultiBar6", "MultiBar7",
}
local trays, rims = {}, {}
local events
local darkEdge = {0.055, 0.035, 0.017, 0.95}

local function edge(frame, color, first, last, x, y, horizontal, thickness, opacity)
    local line = UI.Rect(frame, color, "BORDER", opacity)
    line:SetPoint(first, frame, first, x, y)
    line:SetPoint(last, frame, last, x, y)
    if horizontal then line:SetHeight(thickness) else line:SetWidth(thickness) end
end

local function outline(frame, color, outset, thickness, opacity)
    edge(frame, color, "TOPLEFT", "TOPRIGHT", 0, outset, true, thickness, opacity)
    edge(frame, color, "BOTTOMLEFT", "BOTTOMRIGHT", 0, -outset, true, thickness, opacity)
    edge(frame, color, "TOPLEFT", "BOTTOMLEFT", -outset, 0, false, thickness, opacity)
    edge(frame, color, "TOPRIGHT", "BOTTOMRIGHT", outset, 0, false, thickness, opacity)
end

local function createTray(bar)
    local frame = CreateFrame("Frame", nil, bar)
    frame.ignoreInLayout = true
    frame:EnableMouse(false)
    frame:SetFrameLevel(bar:GetFrameLevel())
    frame:SetPoint("TOPLEFT", bar, "TOPLEFT", -6, 6)
    frame:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT", 6, -6)
    local background = UI.Rect(frame, T.background, "BACKGROUND")
    background:SetAllPoints()
    outline(frame, darkEdge, 0, 3)
    outline(frame, "edge", -1, 1, 0.60)
    local tray = {frame = frame, background = background, art = bar.BorderArt}
    trays[bar] = tray
    return tray
end

local function createRim(button)
    local rim = CreateFrame("Frame", nil, button)
    rim:EnableMouse(false)
    rim:SetFrameLevel(button:GetFrameLevel() + 1)
    rim:SetAllPoints(button)
    outline(rim, darkEdge, 0, 3)
    outline(rim, "edge", -1, 1, 0.85)
    rims[button] = rim
    return rim
end

local function applyAppearance()
    local settings = ns.db and ns.db.actionBars
    if not settings or settings.enabled ~= true then
        for _, tray in pairs(trays) do
            tray.frame:Hide()
            if tray.art and tray.artAlpha then
                if ns.Read.Number(tray.art:GetAlpha()) == 0 then
                    tray.art:SetAlpha(tray.artAlpha)
                end
                tray.artAlpha = nil
            end
        end
        for _, rim in pairs(rims) do rim:Hide() end
        return
    end

    local opacity = math.min(1, math.max(0, ns.Read.Number(settings.opacity) or 0.25))
    for _, name in ipairs(stockBars) do
        local bar = _G[name]
        if bar and bar.actionButtons and #bar.actionButtons > 0 then
            local tray = trays[bar] or createTray(bar)
            -- Leave Edit Mode visibility and the native page controls in charge.
            if tray.art and not tray.artAlpha then
                local alpha = ns.Read.Number(tray.art:GetAlpha())
                if alpha then
                    tray.artAlpha = alpha
                    tray.art:SetAlpha(0)
                end
            end
            tray.background:SetAlpha(opacity)
            tray.frame:Show()
            for _, button in ipairs(bar.actionButtons) do
                local rim = rims[button] or createRim(button)
                rim:Show()
            end
        end
    end
end

function ActionBars.Refresh()
    ns.CombatQueue.Request("action-bar-appearance", applyAppearance)
end

function ActionBars.Init()
    if events then return end
    events = CreateFrame("Frame")
    events:RegisterEvent("PLAYER_ENTERING_WORLD")
    events:RegisterEvent("ADDON_LOADED")
    events:SetScript("OnEvent", function(_, event, addon)
        if event == "PLAYER_ENTERING_WORLD" or addon == "Blizzard_ActionBar" then
            ActionBars.Refresh()
        end
    end)
    ActionBars.Refresh()
end
