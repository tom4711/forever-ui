local function withGold(body)
    local now, balance = 100, 1000
    local events = {registered = {}}
    function events:RegisterEvent(event) self.registered[event] = true end
    function events:SetScript(_, callback) self.onEvent = callback end
    local ns = {db = {}}

    local function emit(event, ...)
        assert(events.registered[event], "missing event " .. event)
        events.onEvent(events, event, ...)
    end
    withGlobals({
        CreateFrame = function() return events end,
        GetServerTime = function() return now end,
        GetMoney = function() return balance end,
    }, function()
        loadAddon("Core/Read.lua", ns)
        loadAddon("Modules/Stats/Gold.lua", ns)
        ns.GoldStats.Init()
        body(ns, emit, function(value) now = value end, function(value) balance = value end)
    end)
end

test("gold session records separate earnings, expenses, net and the hourly balance", function()
    withGold(function(ns, emit, clock, wallet)
        emit("PLAYER_ENTERING_WORLD", true, false)
        clock(130)
        wallet(1400)
        emit("PLAYER_MONEY")
        wallet(1300)
        emit("PLAYER_MONEY")
        emit("PLAYER_MONEY")

        local data = ns.GoldStats.Snapshot()
        assert(data.balance == 1300 and data.income == 400 and data.expenses == 100 and data.net == 300)
        assert(data.elapsed == 30 and data.perHour == nil)
        clock(3700)
        assert(ns.GoldStats.Snapshot().perHour == 300)
    end)
end)

test("gold session survives a reload and starts fresh on character login", function()
    withGold(function(ns, emit, clock, wallet)
        emit("PLAYER_ENTERING_WORLD", true, false)
        clock(140)
        wallet(1360)
        emit("PLAYER_MONEY")
        emit("PLAYER_LOGOUT")
        loadAddon("Core/Settings.lua", ns)
        ns.db = ns.Settings.Load(ns.db)
        clock(160)
        emit("PLAYER_ENTERING_WORLD", false, true)
        wallet(1240)
        emit("PLAYER_MONEY")
        local data = ns.GoldStats.Snapshot()
        assert(data.elapsed == 60 and data.income == 360 and data.expenses == 120 and data.net == 240)

        clock(5000)
        wallet(7000)
        emit("PLAYER_ENTERING_WORLD", true, false)
        data = ns.GoldStats.Snapshot()
        assert(data.elapsed == 0 and data.balance == 7000 and data.net == 0)
    end)
end)

test("merchant stats count matching wallet movements and keep categories separate from gross totals", function()
    withGold(function(ns, emit, clock, wallet)
        emit("PLAYER_ENTERING_WORLD", true, false)
        local run = ns.GoldStats.MerchantAction
        assert(run("sale", 300, function()
            wallet(1300)
            emit("PLAYER_MONEY")
        end))
        assert(run("sale", 110, function() end))
        assert(run("repair", 70, function() end))
        clock(102)
        wallet(1340)
        emit("PLAYER_MONEY")

        local data = ns.GoldStats.Snapshot()
        assert(data.income == 410 and data.expenses == 70 and data.net == 340)
        assert(data.merchantSales == 410 and data.merchantRepairs == 70)
        assert(not run("repair", 70, function() error("repair failed") end))
        wallet(1270)
        emit("PLAYER_MONEY")
        data = ns.GoldStats.Snapshot()
        assert(data.expenses == 140 and data.merchantRepairs == 70)

        assert(run("sale", 75, function() end))
        clock(120)
        wallet(1345)
        emit("PLAYER_MONEY")
        data = ns.GoldStats.Snapshot()
        assert(data.income == 485 and data.merchantSales == 410)
    end)
end)
