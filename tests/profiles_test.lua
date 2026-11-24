local ns = {}
loadAddon("Core/Settings.lua", ns)
loadAddon("Core/Bindings.lua", ns)
loadAddon("Core/Profiles.lua", ns)
local Profiles = ns.Profiles

test("profiles store independent account-wide snapshots and apply into the destination tables", function()
    local account = Profiles.Init(nil)
    local source = ns.Settings.Load({
        locked = false, classAccent = true, raidFrameStyle = true, enemyFrameStyle = true,
        inventory = {enabled = true, opacity = 0.78}, actionBars = {enabled = true, opacity = 0.31},
        comfort = {sellJunk = true, tooltipItemLevel = true}, minimapButton = {angle = 140, collect = true}, party = {enabled = true, replaceBlizzard = true},
        target = {enabled = true, scale = 0.85, showThreat = false},
        player = {scale = 1.35, hideBlizzardAuras = true}, xp = {width = 980, questDisplay = "percent", restedDisplay = "percent"},
        mage = {scale = 0.75, enabled = false, utilityGroup = {enabled = false, position = {x = 80, y = -63}}},
        hunter = {compactLayout = true, food = 100, aspectGroup = {position = {x = 16, y = -108}}},
    })
    assert(Profiles.Save("  Querformat  ", source) == "Querformat")
    source.player.scale = 1.65
    source.mage.utilityGroup.position.x = 700
    assert(Profiles.Init(account))
    assert(Profiles.List()[1] == "Querformat")

    local destination = ns.Settings.Load({mage = {utilityGroup = {enabled = true}}, hunter = {food = 101}})
    local sage = destination.mage
    local group = sage.utilityGroup
    local bags = destination.inventory
    assert(Profiles.Apply("Querformat", destination))
    assert(destination.locked == false and destination.classAccent and destination.raidFrameStyle and destination.enemyFrameStyle)
    assert(destination.comfort.sellJunk and destination.comfort.autoRepair == false and destination.comfort.tooltipItemLevel)
    assert(destination.player.hideBlizzardAuras)
    assert(destination.player.scale == 1.35 and destination.target.enabled and destination.target.scale == 0.85)
    assert(not destination.target.showThreat)
    assert(destination.xp.width == 980 and destination.xp.questDisplay == "percent" and destination.xp.restedDisplay == "percent")
    assert(destination.minimapButton.collect and destination.minimapButton.angle == 140 and destination.party.enabled and destination.party.replaceBlizzard)
    assert(destination.actionBars.enabled and destination.actionBars.opacity == 0.31)
    assert(destination.inventory == bags and bags.enabled and bags.opacity == 0.78)
    assert(destination.mage == sage and sage.utilityGroup == group and sage.enabled and group.enabled)
    assert(sage.scale == 0.75 and group.position.x == 80 and group.position.y == -63)
    assert(destination.hunter.food == 101 and destination.hunter.aspectGroup.position.y == -108)
    destination.mage.utilityGroup.position.x = 1000
    assert(Profiles.Apply("Querformat", destination) and group.position.x == 80)
end)

test("profile loading preserves character data even if an imported table includes it", function()
    local db = ns.Settings.Load({
        bindings = {HunterFeed = "CTRL-G"}, hunter = {food = 777, ammoWarning = 123},
        paladin = {weaponSets = {shield = 4, twoHand = 5}},
        xpSession = {earned = 803}, xp = {flight = {routes = {["A -> B"] = 100}}},
    })
    db.goldStats, db.levelStats = {version = 1}, {version = 1}
    local session, flight, bindings, weapons = db.xpSession, db.xp.flight, db.bindings, db.paladin.weaponSets
    local account = Profiles.Init(nil)
    assert(Profiles.Save("Demo", db))
    local data = account.profiles.Demo
    assert(data.xpSession == nil and data.bindings == nil and data.xp.flight == nil)
    assert(data.goldStats == nil and data.levelStats == nil)
    assert(data.hunter.food == nil and data.hunter.ammoWarning == nil and data.paladin.weaponSets == nil)
    data.xp.width = 740
    data.xpSession, data.bindings = {}, {}
    data.xp.flight, data.paladin.weaponSets = {}, {}
    data.hunter.food, data.hunter.ammoWarning = 1, 1
    assert(Profiles.Apply("Demo", db))
    assert(db.xp.width == 740 and db.xpSession == session and db.xpSession.earned == 803)
    assert(db.xp.flight == flight and flight.routes["A -> B"] == 100)
    assert(db.bindings == bindings and bindings.HunterFeed == "CTRL-G")
    assert(db.paladin.weaponSets == weapons and weapons.shield == 4 and weapons.twoHand == 5)
    assert(db.hunter.food == 777 and db.hunter.ammoWarning == 123)
end)

test("unknown profiles leave settings alone and malformed or older profile data is validated", function()
    local db = ns.Settings.Load({xp = {width = 1200}, player = {scale = 1.5}, classAccent = true})
    Profiles.Init({profiles = {Old = {xp = {width = -100}, player = {}}, ["bad|markup"] = {}, broken = false}})
    assert(#Profiles.List() == 1)
    assert(Profiles.Apply("Unknown", db) == false and db.xp.width == 1200)
    assert(Profiles.Save(" ", db) == nil and Profiles.Save("bad|markup", db) == nil)
    assert(Profiles.Apply("Old", db))
    assert(db.xp.width == 620 and db.player.scale == 1.5 and db.classAccent)
end)

test("profiles replace the complete pin list and preserve chosen dock positions", function()
    local account = Profiles.Init(nil)
    local original = ns.Settings.Load({
        player = {priorityAuras = {1243, 1459}}, layout = {attachClass = true},
        hunter = {dockPosition = {x = 42, y = -22}},
    })
    assert(Profiles.Save("Layout", original))
    original.player.priorityAuras[2] = nil
    local destination = ns.Settings.Load({player = {priorityAuras = {1, 2, 3, 4}}})
    Profiles.Init(account)
    assert(Profiles.Apply("Layout", destination) and destination.layout.attachClass)
    assert(table.concat(destination.player.priorityAuras, ",") == "1243,1459")
    assert(destination.hunter.dockPosition.x == 42 and destination.hunter.dockPosition.y == -22)
    assert(Profiles.Save("Empty", ns.Settings.Load(nil)))
    assert(Profiles.Apply("Empty", destination) and #destination.player.priorityAuras == 0)
end)
