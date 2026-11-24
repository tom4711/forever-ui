local _, ns = ...
local R = ns.Read
local Gold = {}
ns.GoldStats = Gold

local events, state
local merchantTimeout = 5
local maxPending = 256

local function copper(value)
    local number = R.Number(value)
    if number and number >= 0 and number == math.floor(number) then return number end
end

local function now()
    return R.Number(R.Call(GetServerTime)) or R.Number(R.Call(time))
end

local function wallet()
    return copper(R.Call(GetMoney))
end

function Gold.Load(saved)
    if type(saved) ~= "table" or saved.version ~= 1 then return end
    local startedAt = R.Number(saved.startedAt)
    local balance, income, expenses = copper(saved.balance), copper(saved.income), copper(saved.expenses)
    if not startedAt or not balance or not income or not expenses then return end

    local pending = {}
    local savedPending = type(saved.pending) == "table" and saved.pending or {}
    for index = 1, math.min(#savedPending, maxPending) do
        local entry = savedPending[index]
        if type(entry) == "table" then
            local amount, at = copper(entry.amount), R.Number(entry.at)
            if amount and amount > 0 and at and at >= startedAt
                and (entry.kind == "sale" or entry.kind == "repair") then
                pending[#pending + 1] = {kind = entry.kind, amount = amount, at = at}
            end
        end
    end
    return {version = 1, startedAt = startedAt, balance = balance, income = income, expenses = expenses,
        merchantSales = math.min(income, copper(saved.merchantSales) or 0),
        merchantRepairs = math.min(expenses, copper(saved.merchantRepairs) or 0), pending = pending}
end

local function discardExpired(stamp)
    local pending = state.pending
    for index = #pending, 1, -1 do
        local at = pending[index].at
        if at > stamp or stamp - at > merchantTimeout then table.remove(pending, index) end
    end
end

local function record(delta)
    local pending = state.pending
    local sold, repaired = 0, 0
    for index, action in ipairs(pending) do
        if action.kind == "sale" then sold = sold + action.amount
        else repaired = repaired + action.amount end
        if sold - repaired == delta then
            state.income = state.income + sold
            state.expenses = state.expenses + repaired
            state.merchantSales = state.merchantSales + sold
            state.merchantRepairs = state.merchantRepairs + repaired
            for _ = 1, index do table.remove(pending, 1) end
            return
        end
    end

    if delta > 0 then state.income = state.income + delta
    else state.expenses = state.expenses - delta end
    -- An unmatched wallet update has no reliable transaction attribution.
    state.pending = {}
end

local function sample(stamp, balance)
    if not state or not stamp or not balance then return end
    discardExpired(stamp)
    local delta = balance - state.balance
    state.balance = balance
    if delta ~= 0 then record(delta) end
end

function Gold.MerchantAction(kind, expected, action, ...)
    local stamp = now()
    sample(stamp, wallet())
    local amount = copper(expected)
    local ticket
    if state and stamp and amount and amount > 0 and (kind == "sale" or kind == "repair") then
        ticket = {kind = kind, amount = amount, at = stamp}
        local pending = state.pending
        if #pending >= maxPending then table.remove(pending, 1) end
        pending[#pending + 1] = ticket
    end

    local ok = R.Try(action, ...)
    if not ok and ticket then
        for index, waiting in ipairs(state.pending) do
            if waiting == ticket then table.remove(state.pending, index); break end
        end
    end
    sample(now(), wallet())
    return ok
end

function Gold.Snapshot()
    if not state then return {balance = wallet()} end
    local stamp = now()
    local elapsed = stamp and math.max(0, stamp - state.startedAt)
    local net = state.income - state.expenses
    return {balance = state.balance, income = state.income, expenses = state.expenses,
        net = net, perHour = elapsed and elapsed >= 60 and net * 3600 / elapsed or nil,
        merchantSales = state.merchantSales, merchantRepairs = state.merchantRepairs, elapsed = elapsed}
end

local starting, ready
local function onEvent(_, event, initial, reloaded)
    local stamp, balance = now(), wallet()
    if event == "PLAYER_ENTERING_WORLD" then
        if initial or reloaded or not ready then
            ready = true
            state = reloaded and Gold.Load(ns.db.goldStats) or nil
            if state and stamp and state.startedAt > stamp then state = nil end
            starting = stamp
            ns.db.goldStats = state
        end
    elseif not ready then
        return
    end

    if not state and stamp and balance then
        state = {version = 1, startedAt = starting or stamp, balance = balance, income = 0,
            expenses = 0, merchantSales = 0, merchantRepairs = 0, pending = {}}
        ns.db.goldStats = state
    end
    sample(stamp, balance)
end

function Gold.Init()
    if events then return end
    events = CreateFrame("Frame")
    events:RegisterEvent("PLAYER_ENTERING_WORLD")
    events:RegisterEvent("PLAYER_MONEY")
    events:RegisterEvent("PLAYER_LOGOUT")
    events:SetScript("OnEvent", onEvent)
end
