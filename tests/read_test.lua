local ns = {}
loadAddon("Core/Read.lua", ns)
local function read()
    assert(ns.Read and ns.Read.Number and ns.Read.Boolean, "safe readers are not implemented")
    return ns.Read
end

test("numbers include zero and negatives without coercion", function()
    local r=read()
    assert(r.Number(0)==0 and r.Number(-2.5)==-2.5)
    assert(r.Number("12")==nil and r.Number(nil)==nil)
end)

test("non-finite numbers cannot enter calculations", function()
    local r=read()
    assert(r.Number(0/0)==nil and r.Number(math.huge)==nil and r.Number(-math.huge)==nil)
end)

test("boolean false stays false instead of becoming unknown", function()
    local r=read()
    assert(r.Boolean(false)==false and r.Boolean(true)==true)
    assert(r.Boolean(0)==nil and r.Boolean("true")==nil)
end)

test("secret values are rejected before operations that inspect them", function()
    local r=read()
    local secret=setmetatable({}, {__eq=function() error("secret compared") end,
        __lt=function() error("secret ordered") end,__tostring=function() error("secret formatted") end})
    local previous=issecretvalue
    issecretvalue=function(value) return rawequal(value, secret) end
    local ok,err=pcall(function()
        assert(r.Number(secret)==nil and r.Boolean(secret)==nil)
        assert(r.Number(42)==42 and r.Boolean(false)==false)
    end)
    issecretvalue=previous
    assert(ok,err)
end)

test("readers work when the optional secret predicate is unavailable", function()
    local r=read()
    local previous=issecretvalue
    issecretvalue=nil
    assert(r.Number(12)==12 and r.Boolean(true)==true)
    issecretvalue=previous
end)


test("unavailable and restricted API calls return unknown",function()
    local r=read()
    assert(r.Call,"Read.Call is not implemented")
    assert(r.Call(nil)==nil)
    assert(r.Call(function()error("restricted")end)==nil)
    assert(r.Call(function()return false end)==false)
    assert(r.Call(function(a)return a end,42)==42)
end)


test("successful empty slots are distinct from inaccessible API results",function()
    local r=read()
    assert(r.Try,"Read.Try is not implemented")
    local ok,value=r.Try(function()return nil end)
    assert(ok==true and value==nil)
    ok,value=r.Try(function()error("restricted")end)
    assert(ok==false and value==nil)
end)
