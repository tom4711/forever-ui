local _, ns = ...
local T, R = ns.Theme, ns.Read
local Appearance = {}
ns.UnitFrameAppearance = Appearance

local skins, hookedLayouts = {}, {}
local events, refreshPending

local function accent(owner, anchor, first, last, opacity, horizontal)
    -- Native health fills use BORDER. Threat and selection highlights draw above this trim.
    local line = owner:CreateTexture(nil, "ARTWORK", nil, -2)
    T.BindAccent(line, "edge", opacity)
    line:SetPoint(first, anchor, first)
    line:SetPoint(last, anchor, last)
    if horizontal then line:SetHeight(1) else line:SetWidth(1) end
    return line
end

local function createSkin(owner, anchor, stock)
    local fill = owner:CreateTexture(nil, "BACKGROUND", nil, 1)
    fill:SetColorTexture(unpack(T.background))
    if stock then
        -- The boss name and level are above its health bar. The mana bar sits immediately below it.
        fill:SetPoint("TOPLEFT", anchor, "TOPLEFT", -5, 19)
        fill:SetPoint("BOTTOMRIGHT", anchor, "BOTTOMRIGHT", 5, -12)
    else
        fill:SetPoint("TOPLEFT", anchor, "TOPLEFT")
        fill:SetPoint("BOTTOMRIGHT", anchor, "BOTTOMRIGHT")
    end
    local opacity = stock and 0.92 or 0.65
    local skin = {stock = stock, regions = {
        fill,
        accent(owner, fill, "TOPLEFT", "TOPRIGHT", opacity, true),
        accent(owner, fill, "BOTTOMLEFT", "BOTTOMRIGHT", opacity, true),
        accent(owner, fill, "TOPLEFT", "BOTTOMLEFT", opacity, false),
        accent(owner, fill, "TOPRIGHT", "BOTTOMRIGHT", opacity, false),
    }}
    skins[owner] = skin
    return skin
end

local function createBossAuras(frame, anchor, unit)
    local targetView = ns.TargetView
    if not targetView or not targetView.CreateNativeAuras then return end

    local dock = CreateFrame("Frame", nil, frame)
    dock:SetSize(120, 42)
    dock:SetPoint("TOPRIGHT", anchor, "TOPLEFT", -5, 0)
    local debuffs = CreateFrame("Frame", nil, dock)
    debuffs:SetSize(120, 19)
    debuffs:SetPoint("TOPLEFT", 0, -22)
    targetView.CreateNativeAuras(dock, unit, "HELPFUL", 18, 5)
    targetView.CreateNativeAuras(debuffs, unit, "HARMFUL", 18, 5)
    return dock
end

local function setEnabled(skin, enabled)
    if skin.enabled ~= enabled then
        skin.enabled = enabled
        for _, region in ipairs(skin.regions) do region:SetShown(enabled) end
        if skin.auraDock then skin.auraDock:SetShown(enabled) end
    end

    local stock = skin.stock
    if not stock then return end
    local alpha = R.Number(stock:GetAlpha())
    if enabled and alpha and alpha > 0 then
        skin.stockAlpha = alpha
        stock:SetAlpha(0)
    elseif not enabled and skin.stockAlpha then
        if alpha == 0 then stock:SetAlpha(skin.stockAlpha) end
        skin.stockAlpha = nil
    end
end

local function watchLayout(container, method)
    if not hookedLayouts[container] and type(container[method]) == "function"
        and type(hooksecurefunc) == "function" then
        hookedLayouts[container] = pcall(hooksecurefunc, container, method, Appearance.Refresh)
    end
end

local function belongsTo(frame, container)
    local parent = frame:GetParent()
    while parent do
        if parent == container then return true end
        parent = parent:GetParent()
    end
    return false
end

local function applyAppearance()
    local active = {}
    local function decorate(owner, anchor, stock)
        local skin = skins[owner] or createSkin(owner, anchor, stock)
        active[owner] = true
        setEnabled(skin, true)
        return skin
    end
    local function compact(frame)
        if frame.healthBar then decorate(frame, frame) end
    end

    local raid = CompactRaidFrameContainer
    if ns.db.raidFrameStyle and raid and raid.ApplyToFrames then
        watchLayout(raid, "LayoutFrames")
        -- Blizzard's iterator also visits the independently parented party and arena frames.
        raid:ApplyToFrames("all", function(frame)
            if frame.healthBar and belongsTo(frame, raid) then decorate(frame, frame) end
        end)
    end

    if ns.db.enemyFrameStyle then
        local bossContainer = BossTargetFrameContainer
        local bosses = bossContainer and bossContainer.BossTargetFrames or {}
        for index, frame in ipairs(bosses) do
            local shell = frame.TargetFrameContainer
            local content = frame.TargetFrameContent and frame.TargetFrameContent.TargetFrameContentMain
            if shell and shell.FrameTexture and content and content.HealthBarsContainer then
                local skin = decorate(shell, content.HealthBarsContainer, shell.FrameTexture)
                if not skin.auraDock then skin.auraDock = createBossAuras(frame, skin.regions[1], "boss" .. index) end
            end
        end

        local arena = CompactArenaFrame
        if arena then
            watchLayout(arena, "RefreshMembers")
            for _, frame in ipairs(arena.memberUnitFrames or {}) do compact(frame) end
            for _, frame in ipairs(arena.petUnitFrames or {}) do compact(frame) end
            local preMatch = arena.PreMatchFramesContainer
            for _, frame in ipairs(preMatch and preMatch.preMatchUnitFrames or {}) do decorate(frame, frame) end
        end
    end

    for owner, skin in pairs(skins) do
        if not active[owner] then setEnabled(skin, false) end
    end
end

function Appearance.Refresh()
    if events then ns.CombatQueue.Request("unitFrameAppearance", applyAppearance) end
end

local function scheduleRefresh()
    if refreshPending then return end
    if C_Timer and C_Timer.After then
        refreshPending = true
        C_Timer.After(0, function()
            refreshPending = false
            Appearance.Refresh()
        end)
    else
        Appearance.Refresh()
    end
end

function Appearance.Init()
    if events then return end
    events = CreateFrame("Frame")
    events:RegisterEvent("PLAYER_ENTERING_WORLD")
    events:RegisterEvent("GROUP_ROSTER_UPDATE")
    events:RegisterEvent("ADDON_LOADED")
    events:SetScript("OnEvent", function(_, event, addon)
        if event ~= "ADDON_LOADED" or addon == "Blizzard_CompactRaidFrames" or addon == "Blizzard_UnitFrame" then
            scheduleRefresh()
        end
    end)
    Appearance.Refresh()
end
