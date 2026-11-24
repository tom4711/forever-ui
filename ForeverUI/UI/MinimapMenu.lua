local _, ns = ...
local UI, R = ns.UI, ns.Read
local Menu = {}
ns.MinimapMenu = Menu

local anchor, panel, placeholder, ticker
local parked = {}
local columns, cell = 6, 48
local otherCollectors = {"MBB", "MinimapButtonBag", "MinimapButtonButton"}
local knownLaunchers = {ForeverXPBarMinimapButton = true, OpenMapMinimapButton = true,
    MastercraftMinimapButton = true, WickCoreMinimapButton = true}

local function isLoaded(name)
    return R.Call(C_AddOns and C_AddOns.IsAddOnLoaded, name) == true
end

local function enabled()
    if not ns.db.minimapButton.collect then return false end
    for _, addon in ipairs(otherCollectors) do
        if isLoaded(addon) then return false end
    end
    return true
end

local function nameOfLauncher(frame)
    if frame == anchor or frame:IsForbidden() or frame:IsProtected() or not frame:IsObjectType("Button") then return end
    local name = R.Call(frame.GetName, frame)
    if type(name) ~= "string" then return end
    local addon = name:match("^(.+)[Mm]ini[Mm]ap[Bb]utton$")
    if knownLaunchers[name] or name:match("^LibDBIcon10_") or (addon and isLoaded(addon)) then return name end
end

local function pointsOf(frame)
    local points = {}
    for index = 1, frame:GetNumPoints() do points[index] = {frame:GetPoint(index)} end
    return points
end

local function rememberExternalPosition(frame, state)
    if not state.placed then return end
    local _, relative = frame:GetPoint(1)
    if relative and relative ~= panel then state.points = pointsOf(frame) end
end

local function rememberBrokerFade(frame, state)
    local name = state.name:match("^LibDBIcon10_(.+)$")
    if not name or frame.showOnMouseover ~= true or not LibStub then return end
    local library = R.Call(LibStub.GetLibrary, LibStub, "LibDBIcon-1.0", true)
    if library and R.Call(library.GetMinimapButton, library, name) == frame
        and R.Try(library.ShowOnEnter, library, name, false) then
        state.brokerFade = {library = library, name = name}
    end
end

local function forget(frame, state)
    local fade = state.brokerFade
    if fade and frame.showOnMouseover == false then
        R.Try(fade.library.ShowOnEnter, fade.library, fade.name, true)
    end
    parked[frame] = nil
end

local function releaseButtons()
    for frame, state in pairs(parked) do
        if frame:GetParent() == panel then
            rememberExternalPosition(frame, state)
            pcall(frame.SetParent, frame, state.parent)
            if frame:GetParent() == state.parent then
                frame:SetFrameStrata(state.strata)
                frame:SetFrameLevel(state.level)
                frame:ClearAllPoints()
                for _, point in ipairs(state.points) do frame:SetPoint(unpack(point, 1, 5)) end
            end
        end
        if frame:GetParent() ~= panel then forget(frame, state) end
    end
end

local function collect(root)
    if not root then return end
    for _, frame in ipairs({root:GetChildren()}) do
        local name = nameOfLauncher(frame)
        if name and frame:IsShown() then
            local state = {name = name, parent = root, points = pointsOf(frame),
                strata = frame:GetFrameStrata(), level = frame:GetFrameLevel()}
            pcall(frame.SetParent, frame, panel)
            if frame:GetParent() == panel then
                parked[frame] = state
                rememberBrokerFade(frame, state)
                frame:SetFrameStrata(panel:GetFrameStrata())
                frame:SetFrameLevel(panel:GetFrameLevel() + 3)
            end
        end
    end
end

local function layoutButtons()
    local visible = {}
    for frame, state in pairs(parked) do
        if frame:GetParent() ~= panel then
            forget(frame, state)
        elseif frame:IsShown() then
            visible[#visible + 1] = frame
        end
    end
    table.sort(visible, function(a, b) return parked[a].name < parked[b].name end)
    local count = #visible
    if count == 0 then panel:SetSize(190, 52)
    else panel:SetSize(12 + math.min(count, columns) * cell, 12 + math.ceil(count / columns) * cell) end
    placeholder:SetShown(count == 0)

    for index, frame in ipairs(visible) do
        local state = parked[frame]
        rememberExternalPosition(frame, state)
        local x = 6 + ((index - 1) % columns + 0.5) * cell
        local y = -6 - (math.floor((index - 1) / columns) + 0.5) * cell
        local point, relative, relativePoint, currentX, currentY = frame:GetPoint(1)
        if point ~= "CENTER" or relative ~= panel or relativePoint ~= "TOPLEFT"
            or currentX ~= x or currentY ~= y or frame:GetNumPoints() ~= 1 then
            frame:ClearAllPoints()
            frame:SetPoint("CENTER", panel, "TOPLEFT", x, y)
        end
        state.placed = true
    end
end

function Menu.Close()
    if panel then panel:Hide() end
end

function Menu.Refresh()
    if not anchor or InCombatLockdown() then return end
    if not enabled() then
        if ticker then ticker:Cancel(); ticker = nil end
        Menu.Close()
        releaseButtons()
        return
    end

    if not panel then
        panel = UI.CreatePanel(UIParent, "ForeverUI_MinimapMenu")
        -- LibDBIcon launchers can keep their fixed MEDIUM layer at level 8.
        -- Place the menu background below them without changing their fixed-layer flags.
        panel:SetFrameStrata("MEDIUM")
        panel:SetFrameLevel(1)
        panel:SetPoint("TOPRIGHT", anchor, "BOTTOMLEFT", -5, -5)
        panel:EnableMouse(true)
        panel:Hide()
        placeholder = UI.Text(panel, 11, ns.Theme.muted)
        placeholder:SetPoint("CENTER")
        placeholder:SetText(ns.L.MINIMAP_ADDONS_EMPTY)
    end
    collect(Minimap)
    collect(MinimapBackdrop)
    layoutButtons()
    if not ticker and C_Timer and C_Timer.NewTicker then ticker = C_Timer.NewTicker(1, Menu.Refresh) end
end

function Menu.Toggle()
    if not anchor or InCombatLockdown() or not enabled() then return end
    Menu.Refresh()
    if panel:IsShown() then
        Menu.Close()
    else
        panel:Show()
        -- A launcher's own OnShow script may have reapplied the minimap anchor.
        layoutButtons()
    end
end

function Menu.Init(button)
    if anchor then return end
    anchor = button
    local events = CreateFrame("Frame")
    events:RegisterEvent("PLAYER_ENTERING_WORLD")
    events:RegisterEvent("PLAYER_REGEN_ENABLED")
    events:RegisterEvent("GLOBAL_MOUSE_DOWN")
    events:SetScript("OnEvent", function(_, event)
        if event == "GLOBAL_MOUSE_DOWN" then
            if panel and panel:IsShown() and not panel:IsMouseOver() and not anchor:IsMouseOver() then Menu.Close() end
        else
            Menu.Refresh()
        end
    end)
    Menu.Refresh()
end
