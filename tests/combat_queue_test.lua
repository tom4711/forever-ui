local ns={}
loadAddon("Core/CombatQueue.lua",ns)
local function queue(predicate)
    assert(ns.CombatQueue and ns.CombatQueue.New,"CombatQueue is not implemented")
    return ns.CombatQueue.New(predicate)
end

test("protected work waits until combat ends",function()
    local combat=true
    local q=queue(function()return combat end)
    local applied=0
    q.Request("feed",function()applied=applied+1 end)
    q.Flush();assert(applied==0)
    combat=false;q.Flush();assert(applied==1)
    q.Flush();assert(applied==1)
end)

test("only the latest requested configuration is applied",function()
    local combat=true
    local q=queue(function()return combat end)
    local choice
    q.Request("food",function()choice=1 end)
    q.Request("food",function()choice=2 end)
    combat=false;q.Flush();assert(choice==2)
end)

test("combat restarting during flush preserves remaining work",function()
    local combat=true
    local q=queue(function()return combat end)
    local applied=0
    local function apply()applied=applied+1;combat=true end
    q.Request("first",apply);q.Request("second",apply)
    combat=false;q.Flush();assert(applied==1)
    combat=false;q.Flush();assert(applied==2)
end)

test("out of combat changes apply immediately and clear stale requests",function()
    local combat=true
    local q=queue(function()return combat end)
    local value=0
    q.Request("layout",function()value=1 end)
    combat=false;q.Request("layout",function()value=2 end)
    q.Flush();assert(value==2)
end)

test("a failed deferred callback is reported and does not block independent work", function()
    local combat, attempts, applied = true, 0, 0
    local errors = {}
    local q = ns.CombatQueue.New(function() return combat end, function(key, message)
        errors[#errors + 1] = {key, message}
    end)
    local function apply()
        attempts = attempts + 1
        if attempts == 1 then error("failed to update a frame") end
        applied = applied + 1
    end
    for _, key in ipairs({"party", "bindings", "inventory"}) do q.Request(key, apply) end
    combat = false
    assert(q.Flush() == false)
    assert(attempts == 3 and applied == 2 and #errors == 1)
    assert(type(errors[1][1]) == "string" and errors[1][2]:find("failed to update a frame", 1, true))
    assert(q.Flush() == true and attempts == 3)
end)

test("an immediate callback failure is reported without leaving a stale request", function()
    local reported
    local q = ns.CombatQueue.New(function() return false end, function(key) reported = key end)
    assert(q.Request("frame", function() error("unavailable") end) == false)
    assert(reported == "frame" and q.Flush() == true)
    assert(q.Request("frame", function() end) == true)
end)
