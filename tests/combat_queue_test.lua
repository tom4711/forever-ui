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
