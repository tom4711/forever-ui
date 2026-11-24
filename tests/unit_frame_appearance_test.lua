test("native raid, boss, and arena skins are independent, reversible, and safe during combat", function()
    local locked = false
    local function texture(alpha)
        local region = {alpha = alpha or 1, shown = true}
        function region:GetAlpha() return self.alpha end
        function region:SetAlpha(value) self.alpha = value end
        function region:SetColorTexture(...) self.color = {...} end
        function region:SetPoint(...) self.points = self.points or {}; self.points[#self.points + 1] = {...} end
        function region:SetHeight() end
        function region:SetWidth() end
        function region:SetShown(value) self.shown = value end
        return region
    end
    local function frame(parent)
        local object = {textures = {}, healthBar = {}}
        function object:GetParent() return parent end
        function object:CreateTexture(_, layer, _, sublevel)
            assert(not locked, "creating art must wait until after combat")
            local art = texture()
            art.layer, art.sublevel = layer, sublevel
            self.textures[#self.textures + 1] = art
            return art
        end
        return object
    end

    local auraRows, auraDock = {}, nil
    local raid, party, arena = frame(), frame(), frame()
    local direct = frame(raid)
    local grouped = frame(frame(raid))
    local arenaEnemy = frame(arena)
    local art = texture(0.8)
    local bossShell = frame()
    bossShell.FrameTexture = art
    local boss = {
        TargetFrameContainer = bossShell,
        TargetFrameContent = {TargetFrameContentMain = {HealthBarsContainer = {}}},
    }
    raid.units = {direct, grouped, party, arenaEnemy}
    function raid:ApplyToFrames(_, callback)
        for _, member in ipairs(self.units) do callback(member) end
    end
    function raid:LayoutFrames() end
    arena.memberUnitFrames = {arenaEnemy}
    function arena:RefreshMembers() end

    withGlobals({
        InCombatLockdown = function() return locked end,
        CompactRaidFrameContainer = raid,
        BossTargetFrameContainer = {BossTargetFrames = {boss}},
        CompactArenaFrame = arena,
        CreateFrame = function(_, _, parent)
            if not parent then return {RegisterEvent = function() end, SetScript = function() end} end
            local dock = frame(parent)
            function dock:SetSize() end
            function dock:SetPoint() end
            function dock:SetShown(value) self.shown = value end
            if parent == boss then auraDock = dock end
            return dock
        end,
        hooksecurefunc = function(owner, method, hook)
            local original = owner[method]
            owner[method] = function(self)
                original(self)
                hook()
            end
        end,
    }, function()
        local ns = {db = {raidFrameStyle = false, enemyFrameStyle = false}, TargetView = {
            CreateNativeAuras = function(_, unit, filter)
                auraRows[#auraRows + 1] = unit .. "/" .. filter
                return true
            end,
        }}
        loadAddon("Core/Read.lua", ns)
        loadAddon("Core/CombatQueue.lua", ns)
        loadAddon("UI/Theme.lua", ns)
        loadAddon("Modules/UnitFrameAppearance.lua", ns)
        ns.UnitFrameAppearance.Init()
        assert(#direct.textures == 0 and #bossShell.textures == 0 and #arenaEnemy.textures == 0)
        assert(art.alpha == 0.8)

        ns.db.raidFrameStyle = true
        ns.UnitFrameAppearance.Refresh()
        assert(#direct.textures > 0 and #grouped.textures == #direct.textures)
        assert(direct.healthBar and #party.textures == 0 and #arenaEnemy.textures == 0 and #bossShell.textures == 0)
        local fill, rim = direct.textures[1], direct.textures[2]
        assert(fill.layer == "BACKGROUND" and rim.layer == "ARTWORK" and rim.sublevel < 0)
        local pooled = frame(raid)
        locked = true
        raid.units[#raid.units + 1] = pooled
        raid:LayoutFrames()
        assert(#pooled.textures == 0)
        locked = false
        assert(ns.CombatQueue.Flush())
        assert(#pooled.textures == #direct.textures)

        ns.db.enemyFrameStyle = true
        ns.UnitFrameAppearance.Refresh()
        assert(#arenaEnemy.textures > 0 and #bossShell.textures > 0 and art.alpha == 0)
        assert(auraRows[1] == "boss1/HELPFUL" and auraRows[2] == "boss1/HARMFUL")
        assert(bossShell.textures[1].points[1][2] == boss.TargetFrameContent.TargetFrameContentMain.HealthBarsContainer)
        ns.db.raidFrameStyle = false
        ns.UnitFrameAppearance.Refresh()
        assert(not fill.shown and bossShell.textures[1].shown)
        ns.db.enemyFrameStyle = false
        ns.UnitFrameAppearance.Refresh()
        assert(art.alpha == 0.8 and not bossShell.textures[1].shown and not arenaEnemy.textures[1].shown)
        assert(not auraDock.shown)
    end)
end)
