local ns={}
loadAddon("Modules/Hunter/FoodModel.lua",ns)
loadAddon("Modules/Hunter/ActionModel.lua",ns)
local function model() assert(ns.HunterActionModel,"Hunter action model is missing"); return ns.HunterActionModel end

test("aspect list includes only learned spells and selects each highest rank",function()
    local list=model().Aspects({[13163]=true,[13165]=true,[14318]=true,[14322]=true,[5118]=true,[13159]=false,[20043]=true,[34074]=true})
    assert(#list==5)
    assert(list[1].spellID==13163 and list[2].spellID==14322)
    assert(list[3].spellID==5118 and list[4].spellID==20043 and list[5].spellID==34074)
end)

test("aspect order and labels are stable",function()
    local list=model().Aspects({[13163]=true,[13165]=true,[5118]=true,[13159]=true,[20043]=true,[34074]=true})
    assert(#list==6)
    assert(list[1].key=="monkey" and list[2].key=="hawk" and list[6].key=="viper")
end)

test("pet spell availability distinguishes living dead missing and unknown",function()
    local m=model().PetAvailability
    local a=m(true,false);assert(a.mend and not a.revive)
    a=m(true,true);assert(not a.mend and a.revive)
    a=m(false,false);assert(not a.mend and not a.revive)
    a=m(nil,nil);assert(not a.mend and not a.revive)
end)


test("pet action picks the highest learned spell rank",function()
    assert(model().HighestKnown({136,3111,3661,3662},{[136]=true,[3661]=true})==3661)
    assert(model().HighestKnown({982},{})==nil)
end)


test("pet action macros target only the required pet state",function()
    assert(model().PetMacro("mend","Mend Pet")=="/cast [@pet,exists,nodead] Mend Pet")
    assert(model().PetMacro("revive","Revive Pet")=="/cast [@pet,dead] Revive Pet")
    assert(model().PetMacro("mend",nil)==nil)
end)

test("action slots remain distinct across independent refresh layouts",function()
    local a=model().Slots(6,{"mend","revive"})
    local b=model().Slots(6,{"mend","revive"})
    assert(a.mend==6 and a.revive==7 and b.mend==6 and b.revive==7)
end)

test("action positions use scaled hunter coordinates on a separate row",function()
    local g={left=100,top=500,scale=0.65,parentScale=1,parentLeft=0,parentBottom=0}
    local p=model().Position(g,7)
    assert(p.x==352 and p.y==389 and p.scale==0.65)
    local feed=ns.FoodModel.FeedPosition(g)
    assert(feed.x==332 and feed.y==334)
end)


test("spell refresh listeners use Forever event names only",function()
    local events=model().SpellEvents
    assert(#events==2 and events[1]=="SPELLS_CHANGED" and events[2]=="LEARNED_SPELL_IN_SKILL_LINE")
end)

test("secure hunter buttons accept mouse down and up on Forever",function()
    local clicks=model().ClickEvents
    assert(#clicks==2 and clicks[1]=="LeftButtonDown" and clicks[2]=="LeftButtonUp")
end)
