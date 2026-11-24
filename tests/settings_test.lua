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
    assert(c.player.hideBlizzardAuras == false)
end)

test("class accent is opt-in and preserves a saved boolean", function()
    assert(load(nil).classAccent == false)
    assert(load({classAccent = true}).classAccent == true)
    assert(load({classAccent = "true"}).classAccent == false)
end)

test("valid saved choices survive normalization", function()
    local c = load({locked=false, player={hideBlizzardAuras=true}, hunter={enabled=false,scale=1.25,ammoWarning=0,
        position={point="TOP",relativePoint="TOP",x=20,y=-40}}})
    assert(c.locked == false and c.hunter.enabled == false)
    assert(c.player.hideBlizzardAuras == true)
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

test("hunter action groups default visible with independent root-relative positions",function()
    local c=load(nil)
    assert(c.hunter.aspectGroup.enabled==true and c.hunter.petGroup.enabled==true)
    assert(c.hunter.aspectGroup.position.x==16 and c.hunter.aspectGroup.position.y==-72)
    assert(c.hunter.petGroup.position.x==280 and c.hunter.petGroup.position.y==-72)
    c.hunter.aspectGroup.position.x=99
    assert(load(nil).hunter.aspectGroup.position.x==16)
end)

test("hunter group migration moves only legacy defaults and runs once", function()
    local c = load({hunter = {
        aspectGroup = {position = {x = 16, y = -108}},
        petGroup = {position = {x = 302, y = -108}},
    }})
    assert(c.hunter.compactLayout == true)
    assert(c.hunter.aspectGroup.position.x == 16 and c.hunter.aspectGroup.position.y == -72)
    assert(c.hunter.petGroup.position.x == 302 and c.hunter.petGroup.position.y == -108)

    c.hunter.aspectGroup.position.y = -108
    local reloaded = load(c)
    assert(reloaded.hunter.aspectGroup.position.y == -108, "keep positions chosen after migration")
end)

test("hunter action group visibility and valid positions persist independently",function()
    local c=load({hunter={aspectGroup={enabled=false,position={x=34,y=-122}},
        petGroup={enabled=true,position={x=301,y=-116}}}})
    assert(c.hunter.aspectGroup.enabled==false and c.hunter.petGroup.enabled==true)
    assert(c.hunter.aspectGroup.position.x==34 and c.hunter.aspectGroup.position.y==-122)
    assert(c.hunter.petGroup.position.x==301 and c.hunter.petGroup.position.y==-116)
end)

test("malformed hunter group settings normalize without affecting the other group",function()
    local c=load({hunter={aspectGroup={enabled="yes",position={x=math.huge,y=12}},
        petGroup={enabled=false,position={x=150,y=-120}}}})
    assert(c.hunter.aspectGroup.enabled==true)
    assert(c.hunter.aspectGroup.position.x==16 and c.hunter.aspectGroup.position.y==12)
    assert(c.hunter.petGroup.enabled==false and c.hunter.petGroup.position.x==150)
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

test("flight estimate settings normalize defaults and valid learned routes",function()
    local defaults=load(nil)
    assert(defaults.xp.flight.secondsPerUnit==650 and defaults.xp.flight.routes and next(defaults.xp.flight.routes)==nil)
    assert(defaults.xp.flight.importedForeverXPBar==false)
    local c=load({xp={flight={secondsPerUnit=750,importedForeverXPBar=true,routes={ ["Stormwind -> Ironforge"]=120 }}}})
    assert(c.xp.flight.secondsPerUnit==750 and c.xp.flight.routes["Stormwind -> Ironforge"]==120)
    assert(c.xp.flight.importedForeverXPBar==true)
end)

test("malformed flight route data is bounded and discarded during settings load",function()
    local routes={["ZoneA -> ZoneB"]=120,["ZoneC -> ZoneD"]=4,[string.rep("x",151)]=90,["TooLong -> Duration"]=3601}
    for i=1,510 do routes[string.format("Zone%03d -> ZoneEnd",i)]=100 end
    local c=load({xp={flight={secondsPerUnit=99999,routes=routes,importedForeverXPBar="yes"}}})
    local count=0;for _ in pairs(c.xp.flight.routes)do count=count+1 end
    assert(c.xp.flight.secondsPerUnit==650 and c.xp.flight.importedForeverXPBar==false)
    assert(c.xp.flight.routes["ZoneC -> ZoneD"]==nil and c.xp.flight.routes["TooLong -> Duration"]==nil)
    assert(count<=500)
end)

test("paladin and warlock module settings default enabled with independent positions",function()
    local c=load(nil)
    assert(c.paladin.enabled==true and c.warlock.enabled==true)
    assert(c.paladin.scale==1 and c.warlock.scale==1)
    assert(c.paladin.position.x~=c.warlock.position.x or c.paladin.position.y~=c.warlock.position.y)
    c.paladin.position.x=77
    assert(load(nil).paladin.position.x~=77)
end)

test("paladin and warlock visibility, scale, positions and equipment sets persist independently",function()
    local c=load({paladin={enabled=false,scale=1.4,position={point="TOP",relativePoint="TOP",x=10,y=-30},weaponSets={shield=0,twoHand=29}},
        warlock={enabled=true,scale=0.8,position={point="BOTTOM",relativePoint="BOTTOM",x=-20,y=40}}})
    assert(c.paladin.enabled==false and c.warlock.enabled==true)
    assert(c.paladin.scale==1.4 and c.warlock.scale==0.8)
    assert(c.paladin.position.x==10 and c.warlock.position.x==-20)
    assert(c.paladin.weaponSets.shield==0 and c.paladin.weaponSets.twoHand==29)
end)

test("malformed paladin equipment set identifiers are discarded",function()
    local c=load({paladin={weaponSets={shield=-1,twoHand="29"}},warlock={enabled="yes"}})
    assert(c.paladin.weaponSets.shield==nil and c.paladin.weaponSets.twoHand==nil)
    assert(c.warlock.enabled==true)
end)

test("appearance settings opt in separately and keep the full opacity range", function()
    local defaults = load(nil)
    assert(defaults.actionBars.enabled == false and defaults.actionBars.opacity == 0.25)
    assert(defaults.inventory.enabled == false and defaults.inventory.opacity == 0.92)

    local saved = {actionBars = {enabled = true, opacity = 0}, inventory = {enabled = false, opacity = 1}}
    local config = load(saved)
    assert(config.actionBars.enabled and config.actionBars.opacity == 0)
    assert(not config.inventory.enabled and config.inventory.opacity == 1)
    config.actionBars.opacity = 0.5
    assert(saved.actionBars.opacity == 0)

    config = load({actionBars = {enabled = "yes", opacity = 0 / 0}, inventory = {enabled = true, opacity = 5}})
    assert(config.actionBars.enabled == false and config.actionBars.opacity == defaults.actionBars.opacity)
    assert(config.inventory.enabled == true and config.inventory.opacity == defaults.inventory.opacity)
end)

test("merchant switches default off and preserve independent saved values", function()
    local empty = load(nil)
    assert(empty.comfort and not empty.comfort.autoRepair and not empty.comfort.sellJunk)
    local chosen = load({comfort = {autoRepair = true, sellJunk = "true"}})
    assert(chosen.comfort.autoRepair and chosen.comfort.sellJunk == false)
    local sales = load({comfort = {autoRepair = false, sellJunk = true}})
    assert(sales.comfort.autoRepair == false and sales.comfort.sellJunk)
end)

test("new layout settings and aura pins preserve safe defaults and saved choices", function()
    local empty = load(nil)
    assert(empty.layout.grid and empty.layout.snap and not empty.layout.attachClass)
    assert(not empty.party.compact and empty.party.showPortrait and not empty.party.showMissingBuff)
    assert(not empty.actionBars.hideEmpty and empty.target.showOwnAuraTimers)
    assert(#empty.player.priorityAuras == 0 and empty.mage.dockPosition.x == 18)
    local saved = load({
        player = {priorityAuras = {1243, 1243, 0, 17, "1459", -1, math.huge, 2378, 589}},
        layout = {grid = false, snap = false, attachClass = true},
        mage = {dockPosition = {x = -39.5, y = -70}},
        party = {compact = true, showPortrait = false, showMissingBuff = true},
        target = {showOwnAuraTimers = false}, actionBars = {hideEmpty = true},
    })
    assert(table.concat(saved.player.priorityAuras, ",") == "1243,17,2378")
    assert(not saved.layout.grid and not saved.layout.snap and saved.layout.attachClass)
    assert(saved.mage.dockPosition.x == -39.5 and saved.mage.dockPosition.y == -70)
    assert(saved.party.compact and not saved.party.showPortrait and saved.party.showMissingBuff)
    assert(saved.actionBars.hideEmpty and not saved.target.showOwnAuraTimers)
end)

test("equipment item-level tooltips are an independent opt-in", function()
    assert(load(nil).comfort.tooltipItemLevel == false)
    assert(load({comfort = {tooltipItemLevel = true}}).comfort.tooltipItemLevel == true)
    assert(load({comfort = {tooltipItemLevel = "true"}}).comfort.tooltipItemLevel == false)
end)

test("the minimap launcher menu is optional and follows saved preferences", function()
    assert(not load(nil).minimapButton.collect)
    assert(load({minimapButton = {angle = 180, collect = true}}).minimapButton.collect)
    assert(not load({minimapButton = {collect = "true"}}).minimapButton.collect)
end)

test("the threat display defaults on and respects an opt-out", function()
    assert(load(nil).target.showThreat)
    assert(not load({target = {showThreat = false}}).target.showThreat)
end)
