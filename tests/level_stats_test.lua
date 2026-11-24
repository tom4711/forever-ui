local function withLevelStats(run)
    local level, now, connected, inWorld, requests = 24, 100, true, false, 0
    local eventFrame
    local db
    local function event(name, ...)
        assert(eventFrame.events[name], "missing subscription for " .. name)
        eventFrame.scripts.OnEvent(eventFrame, name, ...)
    end
    local game = {
        enter = function(nextLevel)
            level, inWorld = nextLevel or level, true
            event("PLAYER_ENTERING_WORLD")
        end,
        leave = function(name)
            event(name or "PLAYER_LEAVING_WORLD")
            inWorld = false
        end,
        play = function(seconds)
            for _ = 1, seconds do
                now = now + 1
                eventFrame.scripts.OnUpdate(eventFrame, 1)
            end
        end,
        jump = function(seconds)
            now = now + seconds
            eventFrame.scripts.OnUpdate(eventFrame, seconds)
        end,
        connect = function(value) connected = value end,
        levelUp = function(nextLevel)
            level = nextLevel or level + 1
            event("PLAYER_LEVEL_UP", level)
        end,
        timePlayed = function(total, current) event("TIME_PLAYED_MSG", total, current) end,
        requests = function() return requests end,
    }

    withGlobals({
        GetTime = function() return now end,
        IsPlayerInWorld = function() return inWorld end,
        UnitIsConnected = function(unit) assert(unit == "player"); return connected end,
        UnitLevel = function(unit) assert(unit == "player"); return level end,
        RequestTimePlayed = function() requests = requests + 1 end,
        CreateFrame = function()
            eventFrame = {events = {}, scripts = {}}
            function eventFrame:RegisterEvent(name) self.events[name] = true end
            function eventFrame:SetScript(name, callback) self.scripts[name] = callback end
            return eventFrame
        end,
    }, function()
        local function boot(saved)
            local ns = {db = {}}
            loadAddon("Core/Read.lua", ns)
            loadAddon("Modules/Stats/Level.lua", ns)
            ns.db.levelStats = ns.LevelStats.Load(saved or db)
            db = ns.db.levelStats
            ns.LevelStats.Init()
            return ns.LevelStats
        end
        local stats = boot()
        game.reload = function()
            game.leave("PLAYER_LOGOUT")
            game.play(30)
            local newStats = boot()
            game.enter()
            return newStats
        end
        run(stats, game)
    end)
end

test("level playtime survives reload and excludes offline and disconnected intervals", function()
    withLevelStats(function(stats, game)
        assert(stats.Snapshot().currentLevelTime == nil)
        game.enter()
        game.play(15)
        local current = stats.Snapshot()
        assert(current.level == 24 and current.currentLevelTime == 15 and current.currentLevelTimePartial)
        assert(current.totalTime == nil)
        stats = game.reload()
        game.play(4)
        assert(stats.Snapshot().currentLevelTime == 19)
        game.leave()
        game.play(20)
        game.enter()
        game.play(3)
        assert(stats.Snapshot().currentLevelTime == 22)
        game.connect(false)
        game.play(20)
        game.connect(true)
        game.play(1)
        game.play(2)
        assert(stats.Snapshot().currentLevelTime == 24)
        game.jump(240)
        game.play(2)
        assert(stats.Snapshot().currentLevelTime == 26)
        assert(game.requests() == 0, "background playtime requests would print in chat")
    end)
end)

test("completed level playtime keeps the latest three known splits across reload", function()
    withLevelStats(function(stats, game)
        game.enter()
        game.play(15)
        game.levelUp()
        assert(#stats.Snapshot().history == 0, "the original level was observed only in part")
        for _, seconds in ipairs({41, 39, 22, 18}) do
            game.play(seconds)
            game.levelUp()
        end
        stats = game.reload()
        local current = stats.Snapshot()
        assert(current.level == 29 and current.currentLevelTime == 0 and not current.currentLevelTimePartial)
        local history = current.history
        assert(#history == 3)
        assert(history[1].level == 28 and history[1].seconds == 18)
        assert(history[2].level == 27 and history[2].seconds == 22)
        assert(history[3].level == 26 and history[3].seconds == 39)
        history[1].seconds = 999
        assert(stats.Snapshot().history[1].seconds == 18, "consumers get a snapshot of tracked history")
        game.levelUp(32)
        assert(stats.Snapshot().history[1].level == 28)
        game.leave()
        game.enter(33)
        assert(stats.Snapshot().currentLevelTimePartial)
        assert(stats.Snapshot().history[1].level == 28)
    end)
end)

test("played time reports anchor an existing level and refine its completed split", function()
    withLevelStats(function(stats, game)
        game.enter()
        game.play(15)
        game.timePlayed(1000, 140)
        local current = stats.Snapshot()
        assert(current.level == 24 and current.currentLevelTime == 140 and not current.currentLevelTimePartial)
        assert(current.totalTime == 1000)
        game.play(10)
        assert(stats.Snapshot().totalTime == 1010)
        game.levelUp()
        assert(stats.Snapshot().history[1].seconds == 150)
        game.timePlayed(1010, 150)
        assert(stats.Snapshot().currentLevelTime == 0, "the late reply was for the previous level")
        game.play(4)
        game.timePlayed(1018, 4)
        current = stats.Snapshot()
        assert(current.currentLevelTime == 4 and current.totalTime == 1018)
        assert(current.history[1].level == 24 and current.history[1].seconds == 154)
        game.timePlayed(1020, 1021)
        game.timePlayed(999, 4)
        assert(stats.Snapshot().totalTime == 1018)
        assert(stats.Snapshot().currentLevelTime == 4)
    end)
end)

test("played time requests require an explicit action and wait for stale data", function()
    withLevelStats(function(stats, game)
        game.enter()
        assert(game.requests() == 0)
        stats.Request()
        stats.Request()
        assert(game.requests() == 1, "repeated actions in the same window send one chat request")
        game.timePlayed(1000, 140)
        game.play(15)
        stats.Request()
        assert(game.requests() == 1, "recent data needs no new chat request")
        game.play(50)
        stats.Request()
        assert(game.requests() == 2)
    end)
end)

test("an unanchored late played reply cannot replace the new level timer", function()
    withLevelStats(function(stats, game)
        game.enter()
        game.levelUp()
        game.timePlayed(1000, 150)
        local current = stats.Snapshot()
        assert(current.currentLevelTime == 0 and current.totalTime == nil)
        game.play(4)
        game.timePlayed(1004, 4)
        assert(stats.Snapshot().currentLevelTime == 4)
        assert(stats.Snapshot().totalTime == 1004)
    end)
end)
