local _, ns = ...
local ActionBars = {}
ns.ActionBars = ActionBars

-- Forever's standard bars share the same action button template.
local stockBars = {
    "MainActionBar",
    "MultiBarBottomLeft",
    "MultiBarBottomRight",
    "MultiBarRight",
    "MultiBarLeft",
    "MultiBar5",
    "MultiBar6",
    "MultiBar7",
}

local decorations = {}
local events

local function addGoldAccent(frame, left, right, alpha)
    local accent = frame:CreateTexture(nil, "BORDER")
    accent:SetPoint(left, frame, left, 4, 0)
    accent:SetPoint(right, frame, right, -4, 0)
    accent:SetHeight(1)
    local gold = ns.Theme.gold
    accent:SetColorTexture(gold[1], gold[2], gold[3], alpha)
end

local function createDecoration(button)
    -- Inherit native visibility and scale. The decoration sits behind the button
    -- and outside the bar's direct children, which participate in Edit Mode layout.
    local frame = CreateFrame("Frame", nil, button)
    frame:EnableMouse(false)
    frame:SetFrameLevel(button:GetFrameLevel() - 1)
    frame:SetPoint("TOPLEFT", button, "TOPLEFT", -1, 2)
    frame:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 1, -2)

    local background = frame:CreateTexture(nil, "BACKGROUND")
    background:SetAllPoints()
    local petrol = ns.Theme.background
    background:SetColorTexture(petrol[1], petrol[2], petrol[3], 1)

    addGoldAccent(frame, "TOPLEFT", "TOPRIGHT", 0.28)
    addGoldAccent(frame, "BOTTOMLEFT", "BOTTOMRIGHT", 0.16)
    local decoration = { frame = frame, background = background }
    decorations[button] = decoration
    return decoration
end

local function applyAppearance()
    local settings = ns.db and ns.db.actionBars
    if not settings or settings.enabled ~= true then
        for _, decoration in pairs(decorations) do
            decoration.frame:Hide()
        end
        return
    end

    local opacity = settings.opacity
    if type(opacity) ~= "number" or opacity ~= opacity then opacity = 0.25 end
    opacity = math.min(1, math.max(0, opacity))

    for _, name in ipairs(stockBars) do
        local bar = _G[name]
        if bar and bar.actionButtons then
            for _, button in ipairs(bar.actionButtons) do
                local decoration = decorations[button] or createDecoration(button)
                decoration.background:SetAlpha(opacity)
                decoration.frame:Show()
            end
        end
    end
end

function ActionBars.Refresh()
    ns.CombatQueue.Request("actionBarAppearance", applyAppearance)
end

function ActionBars.Init()
    if events then return end
    events = CreateFrame("Frame")
    events:RegisterEvent("PLAYER_ENTERING_WORLD")
    events:SetScript("OnEvent", ActionBars.Refresh)
    ActionBars.Refresh()
end
