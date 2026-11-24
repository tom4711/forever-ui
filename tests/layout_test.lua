local function frame(left, bottom, width, height, scale, shown)
    return {
        GetRect = function() return left, bottom, width, height end,
        GetEffectiveScale = function() return scale end,
        IsVisible = function() return shown ~= false end,
    }
end

test("layout snapping aligns nearby visible frames across scales before using the grid", function()
    local ns = {UI = {}, db = {layout = {grid = true, snap = true}}}
    withGlobals({UIParent = frame(0, 0, 800, 600, 1)}, function()
        loadAddon("Core/Read.lua", ns)
        loadAddon("UI/Layout.lua", ns)
        local moving = frame(169, 263, 101, 80, 1)
        local guide = frame(55, 130, 26, 50, 2)
        local hidden = frame(168, 263, 101, 80, 1, false)
        ns.Layout.Register(moving, "xp")
        ns.Layout.Register(guide, "party")
        ns.Layout.Register(hidden, "target")
        local x, y = ns.Layout.Snap(moving, "xp")
        assert(x == -7 and y == -3)

        local isolated = frame(343, 220, 100, 63, 1)
        x, y = ns.Layout.Snap(isolated, "player")
        assert(x == -3 and y == -3)

        ns.db.layout.snap = false
        x, y = ns.Layout.Snap(moving, "xp")
        assert(x == 0 and y == 0)

        ns.db.layout.snap = true
        ns.db.layout.grid = false
        x, y = ns.Layout.Snap(moving, "xp")
        assert(x == -7 and y == -3)
    end)
end)

test("class docking keeps its offset independent of the free position and follows preview", function()
    local player = frame(100, 100, 150, 100, 1)
    local preview = frame(200, 100, 150, 100, 1)
    local class = frame(270, 384, 100, 50, 0.5)
    local usePreview = false
    local position = {point = "CENTER", relativePoint = "CENTER", x = 30, y = -55}
    local ns = {UI = {}, Preview = {IsEnabled = function() return usePreview end},
        db = {layout = {attachClass = true}, player = {enabled = true}, hunter = {position = position}}}
    withGlobals({ForeverUI_Player = player, ForeverUI_PreviewPlayer = preview}, function()
        loadAddon("Core/Read.lua", ns)
        loadAddon("UI/Layout.lua", ns)
        local anchor, x, y = ns.Layout.Dock("hunter")
        assert(anchor == player and x == 18 and y == 0)
        assert(ns.Layout.SaveDocked(class, "hunter", 0, 0))
        anchor, x, y = ns.Layout.Dock("hunter")
        assert(anchor == player and x == -230 and y == 34)
        assert(ns.db.hunter.position == position)
        usePreview = true
        assert(ns.Layout.Dock("hunter") == preview)
        ns.db.player.enabled = false
        assert(ns.Layout.Dock("hunter") == nil)
        ns.db.player.enabled = true
        ns.db.layout.attachClass = false
        assert(not ns.Layout.SaveDocked(class, "hunter", 0, 0))
        assert(ns.db.hunter.position == position)
    end)
end)

test("the layout mode permits dragging a locked frame and saves the snapped anchor after combat", function()
    local root = frame(0, 0, 1000, 800, 1)
    local moving = frame(127, 108, 100, 80, 1)
    local scripts = {}
    local combat, started, stopped = false, false, false
    local function noop() end
    moving.SetMovable, moving.EnableMouse, moving.RegisterForDrag = noop, noop, noop
    moving.ClearAllPoints, moving.SetScale = noop, noop
    moving.SetScript = function(_, event, callback) scripts[event] = callback end
    moving.StartMoving = function() started = true end
    moving.StopMovingOrSizing = function() stopped = true end
    moving.GetPoint = function() return "TOPLEFT", root, "BOTTOMLEFT", 127, 188 end
    moving.SetPoint = function(self, point, anchor, relative, x, y)
        self.anchor = {point, anchor, relative, x, y}
    end

    local ns = {Theme = {}, UI = {}, db = {locked = true, layout = {grid = true, snap = true},
        xp = {scale = 1, position = {point = "CENTER", relativePoint = "CENTER", x = 0, y = 0}}}}
    withGlobals({UIParent = root, InCombatLockdown = function() return combat end,
        IsAltKeyDown = function() return true end, CreateFrame = function() return {RegisterEvent = noop, SetScript = noop} end},
        function()
            loadAddon("Core/Read.lua", ns)
            loadAddon("UI/Widgets.lua", ns)
            loadAddon("UI/Layout.lua", ns)
            ns.UI.MakeMovable(moving, "xp")
            scripts.OnDragStart()
            assert(not started)
            ns.Layout.IsEditing = function() return true end
            scripts.OnDragStart()
            assert(started and moving.dragging)
            combat = true
            scripts.OnDragStop()
            assert(not stopped and not ns.UI.FlushDeferredMoves())
            combat = false
            assert(ns.UI.FlushDeferredMoves() and stopped and not moving.dragging)
            assert(ns.db.xp.position.x == 120 and ns.db.xp.position.y == 180)
            assert(moving.anchor[2] == root and moving.anchor[4] == 120 and moving.anchor[5] == 180)
        end)
end)
