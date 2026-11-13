local ns = {}
loadAddon("Core/Settings.lua", ns)
local function load(saved)
    assert(ns.Settings and ns.Settings.Load, "Settings.Load is not implemented")
    return ns.Settings.Load(saved)
end

test("fresh characters have usable independent module defaults", function()
    local c = load(nil)
    assert(c.hunter.enabled and c.xp.enabled)
    assert(c.hunter.scale == 1 and c.xp.scale == 1)
    assert(c.hunter.ammoWarning == 200 and c.xp.showAtCap == true)
    assert(c.locked == true and c.schemaVersion == 1)
end)

test("valid saved choices survive normalization", function()
    local c = load({locked=false, hunter={enabled=false,scale=1.25,ammoWarning=0,
        position={point="TOP",relativePoint="TOP",x=20,y=-40}}})
    assert(c.locked == false and c.hunter.enabled == false)
    assert(c.hunter.scale == 1.25 and c.hunter.ammoWarning == 0)
    assert(c.hunter.position.point == "TOP" and c.hunter.position.y == -40)
    assert(c.xp.enabled == true)
end)

test("malformed saved settings cannot break login", function()
    local c = load({locked="yes",hunter="bad",xp={scale=0,enabled="false",position={point="not-an-anchor",x=0/0,y=2}}})
    assert(c.locked == true and c.hunter.ammoWarning == 200)
    assert(c.xp.enabled == true and c.xp.scale == 1)
    assert(c.xp.position.point == "CENTER" and c.xp.position.y == -255)
end)

test("characters and callers do not share mutable position defaults", function()
    local a, b = load(nil), load(nil)
    a.hunter.position.x = 123
    assert(b.hunter.position.x == 0)
    local source={hunter={position={point="CENTER",relativePoint="CENTER",x=9,y=8}}}
    local c=load(source)
    c.hunter.position.x=50
    assert(source.hunter.position.x == 9)
end)

test("invalid numerical options fall back rather than producing broken frames", function()
    local c=load({hunter={scale=math.huge,ammoWarning=-1},xp={scale=0/0}})
    assert(c.hunter.scale == 1 and c.xp.scale == 1)
    assert(c.hunter.ammoWarning == 200)
end)


test("selected food survives reload without accepting invalid item identifiers",function()
    assert(load({hunter={food=1234}}).hunter.food==1234)
    assert(load({hunter={food=-1}}).hunter.food==nil)
end)


test("XP reload data survives normalization without sharing character state",function()
    local saved={xpSession={version=1,startedAt=10,earned=20,reliable=true,last={level=10,current=30,maximum=100,rested=0,at=60,atCap=false}}}
    local c=load(saved)
    assert(c.xpSession and c.xpSession.earned==20)
    c.xpSession.last.current=99
    assert(saved.xpSession.last.current==30)
end)


test("XP width persists independently of scale and defaults for existing characters",function()
    local c=load({xp={width=1100,scale=0.55}})
    assert(c.xp.width==1100 and c.xp.scale==0.55)
    assert(load({xp={scale=0.55}}).xp.width==620)
end)

test("corrupted XP widths cannot create unusable panels",function()
    assert(load({xp={width=0}}).xp.width==620)
    assert(load({xp={width=math.huge}}).xp.width==620)
end)


test("quest and rested XP display modes default independently to XP",function()
    local c=load(nil)
    assert(c.xp.questDisplay=="xp" and c.xp.restedDisplay=="xp")
    c=load({xp={questDisplay="percent",restedDisplay="xp"}})
    assert(c.xp.questDisplay=="percent" and c.xp.restedDisplay=="xp")
end)

test("invalid XP display modes safely default to XP",function()
    local c=load({xp={questDisplay="broken",restedDisplay=false}})
    assert(c.xp.questDisplay=="xp" and c.xp.restedDisplay=="xp")
end)
