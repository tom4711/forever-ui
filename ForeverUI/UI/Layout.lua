local _, ns = ...
local UI, R = ns.UI, ns.Read
local Layout = {}
ns.Layout = Layout

local classModules = {
    hunter = true, paladin = true, warlock = true, priest = true, mage = true,
    shaman = true, druid = true, rogue = true, warrior = true,
}
local registered = {}
local gridStep, snapDistance = 20, 8
local editing = false
local grid, toolbar
local lines = {horizontal = {}, vertical = {}}

local function screenRect(frame)
    local ok, left, bottom, width, height = pcall(frame.GetRect, frame)
    if not ok then return end
    local scale = R.Number(R.Call(frame.GetEffectiveScale, frame))
    left, bottom = R.Number(left), R.Number(bottom)
    width, height = R.Number(width), R.Number(height)
    if not scale or scale <= 0 or not left or not bottom or not width or not height then return end
    return {left = left * scale, bottom = bottom * scale, width = width * scale, height = height * scale, scale = scale}
end

local function closest(source, guide, best, limit)
    for _, origin in ipairs(source) do
        for _, edge in ipairs(guide) do
            local delta = edge - origin
            local distance = math.abs(delta)
            if distance <= limit and (not best or distance < math.abs(best)
                or (distance == math.abs(best) and delta < best)) then
                best = delta
            end
        end
    end
    return best
end

function Layout.Register(frame, module)
    registered[frame] = module
end

function Layout.Dock(module)
    local config = ns.db.layout
    if not config or not config.attachClass or not classModules[module] or not ns.db.player.enabled then return end
    local preview = ns.Preview and ns.Preview.IsEnabled()
    local player = preview and ForeverUI_PreviewPlayer or ForeverUI_Player
    if not player then return end
    local offset = ns.db[module].dockPosition
    return player, offset and offset.x or 18, offset and offset.y or 0
end

function Layout.SaveDocked(frame, module, dx, dy)
    local anchor = Layout.Dock(module)
    if not anchor then return false end
    local item, player = screenRect(frame), screenRect(anchor)
    if item and player then
        ns.db[module].dockPosition = {
            x = (item.left + dx - player.left - player.width) / item.scale,
            y = (item.bottom + item.height + dy - player.bottom - player.height) / item.scale,
        }
    end
    return true
end

local function nearestGrid(origin, edge, step)
    return origin + math.floor((edge - origin) / step + 0.5) * step - edge
end

function Layout.Snap(frame, module)
    local config = ns.db.layout
    if not config or not config.snap then return 0, 0 end
    local item, screen = screenRect(frame), screenRect(UIParent)
    if not item or not screen then return 0, 0 end

    local xs = {item.left, item.left + item.width / 2, item.left + item.width}
    local ys = {item.bottom, item.bottom + item.height / 2, item.bottom + item.height}
    local dx, dy
    local limit = snapDistance * screen.scale
    for other, key in pairs(registered) do
        if other ~= frame and key ~= module and (module ~= "player" or not Layout.Dock(key))
            and R.Call(other.IsVisible, other) == true then
            local guide = screenRect(other)
            if guide then
                dx = closest(xs, {guide.left, guide.left + guide.width / 2, guide.left + guide.width}, dx, limit)
                dy = closest(ys, {guide.bottom, guide.bottom + guide.height / 2, guide.bottom + guide.height}, dy, limit)
            end
        end
    end
    if config.grid then
        local step = gridStep * screen.scale
        dx = dx or nearestGrid(screen.left, item.left, step)
        dy = dy or nearestGrid(screen.bottom, item.bottom + item.height, step)
    end
    return dx or 0, dy or 0
end

local function drawGrid(axis, count)
    local pool = lines[axis]
    for index = 1, count do
        local line = pool[index]
        if not line then
            line = UI.Rect(grid, {0.39, 0.54, 0.52, 0.18}, "BACKGROUND")
            if axis == "vertical" then
                line:SetWidth(1)
                line:SetPoint("BOTTOMLEFT", grid, "BOTTOMLEFT", index * gridStep, 0)
                line:SetPoint("TOPLEFT", grid, "TOPLEFT", index * gridStep, 0)
            else
                line:SetHeight(1)
                line:SetPoint("BOTTOMLEFT", grid, "BOTTOMLEFT", 0, index * gridStep)
                line:SetPoint("BOTTOMRIGHT", grid, "BOTTOMRIGHT", 0, index * gridStep)
            end
            pool[index] = line
        end
        line:Show()
    end
    for index = count + 1, #pool do pool[index]:Hide() end
end

function Layout.Refresh()
    if not grid then return end
    local showGrid = editing and ns.db.layout.grid
    grid:SetShown(showGrid)
    toolbar:SetShown(editing)
    if showGrid then
        drawGrid("vertical", math.floor(UIParent:GetWidth() / gridStep))
        drawGrid("horizontal", math.floor(UIParent:GetHeight() / gridStep))
    end
end

function Layout.IsEditing() return editing end

function Layout.SetEditing(enabled)
    if enabled and InCombatLockdown() then
        ns.Print(ns.L.COMBAT)
        return false
    end
    if enabled and not grid then
        grid = CreateFrame("Frame", nil, UIParent)
        grid:SetAllPoints(UIParent)
        grid:SetFrameStrata("BACKGROUND")
        grid:RegisterEvent("DISPLAY_SIZE_CHANGED")
        grid:RegisterEvent("UI_SCALE_CHANGED")
        grid:SetScript("OnEvent", Layout.Refresh)

        toolbar = UI.CreatePanel(UIParent)
        toolbar:SetFrameStrata("DIALOG")
        toolbar:SetSize(300, 70)
        toolbar:SetPoint("TOP", UIParent, "TOP", 0, -24)
        local done = UI.Button(toolbar, ns.L.LAYOUT_DONE, 170)
        done:SetPoint("TOP", 0, -8)
        done:SetScript("OnClick", function() Layout.SetEditing(false) end)
        local hint = UI.Text(toolbar, 11, ns.Theme.muted)
        hint:SetPoint("BOTTOM", 0, 9)
        hint:SetText(IsMacClient and IsMacClient() and ns.L.LAYOUT_DRAG_MAC or ns.L.LAYOUT_DRAG)
    end
    editing = enabled == true
    Layout.Refresh()
    return true
end
