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

test("active aspect is found even when a lower known rank aura is active",function()
    local m=model()
    local aspects=m.Aspects({[13165]=true,[14322]=true,[5118]=true})
    assert(m.ActiveAspect(aspects,{[13165]=true,[14322]=false,[5118]=false})=="hawk")
end)

test("active aspect reports none only when every known rank is readable and inactive",function()
    local m=model()
    local aspects=m.Aspects({[13165]=true,[14322]=true,[5118]=true})
    assert(m.ActiveAspect(aspects,{[13165]=false,[14322]=false,[5118]=false})==nil)
end)

test("active aspect preserves unknown when no aura query is readable",function()
    local m=model()
    local aspects=m.Aspects({[13165]=true,[14322]=true,[5118]=true})
    assert(m.ActiveAspect(aspects,{[13165]=false,[14322]=nil,[5118]=false})=="unknown")
end)

test("active aspect query reads every learned rank and returns the active aspect",function()
    local m=model()
    local aspects=m.Aspects({[13165]=true,[14322]=true,[5118]=true})
    local queried={}
    local active=m.QueryActiveAspect(aspects,function(id)
        queried[id]=true
        return id==13165
    end)
    assert(active=="hawk")
    assert(queried[13165] and queried[14322] and queried[5118])
end)

test("active aspect query reports unknown if the aura API cannot answer",function()
    local m=model()
    local aspects=m.Aspects({[13165]=true,[5118]=true})
    assert(m.QueryActiveAspect(aspects,function()return nil end)=="unknown")
end)

test("active aspect query preserves a known inactive result",function()
    local m=model()
    local aspects=m.Aspects({[13165]=true,[5118]=true})
    assert(m.QueryActiveAspect(aspects,function()return false end)==nil)
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


test("Mend Pet macro targets only a living pet",function()
    assert(model().PetMacro("mend","Mend Pet")=="/cast [@pet,exists,nodead] Mend Pet")
    assert(model().PetMacro("mend",nil)==nil)
end)

test("revive pet uses its learned spell ID without a pet-target macro condition",function()
    local action=model().PetAction("revive",982,"Revive Pet")
    assert(action.type=="spell" and action.spell==982)
    assert(action.spell==model().PetSpells.revive[1])
    assert(action.macrotext==nil)
end)

test("action slots remain distinct across independent refresh layouts",function()
    local a=model().Slots(6,{"mend","revive"})
    local b=model().Slots(6,{"mend","revive"})
    assert(a.mend==6 and a.revive==7 and b.mend==6 and b.revive==7)
end)

test("action positions use scaled hunter coordinates on a separate row",function()
    local g={left=100,top=500,scale=0.65,parentScale=1,parentLeft=0,parentBottom=0}
    local p=model().Position(g,model().Toolbar(8).actions[8])
    assert(p.x==382 and p.y==389 and p.scale==0.65)
    local feed=ns.FoodModel.FeedPosition(g)
    assert(feed.x==332 and feed.y==389)
end)


test("spell refresh listeners use Forever event names only",function()
    local events=model().SpellEvents
    assert(#events==2 and events[1]=="SPELLS_CHANGED" and events[2]=="LEARNED_SPELL_IN_SKILL_LINE")
end)

test("secure hunter buttons accept mouse down and up on Forever",function()
    local clicks=model().ClickEvents
    assert(#clicks==2 and clicks[1]=="LeftButtonDown" and clicks[2]=="LeftButtonUp")
end)

test("hunter toolbar keeps learned actions and tools evenly grouped",function()
    local t=model().Toolbar(5)
    assert(t.actions[1]==16 and t.actions[5]==168)
    assert(t.feed==214 and t.food==258 and t.settings==302)
    assert(t.actions[5]+32<t.feed)
end)

test("hunter toolbar still fits eight learned actions",function()
    local t=model().Toolbar(8)
    assert(t.actions[8]==282 and t.feed==328 and t.settings==416)
end)

test("separate hunter groups fit aspects pet actions feed food and settings at full scale",function()
    local t=model().GroupLayout(5,2)
    assert(t.aspects.x==16 and t.aspects.width==218)
    assert(t.aspects.actions[1]==24 and t.aspects.actions[5]==176)
    assert(t.pet.x==280 and t.pet.width==192)
    assert(t.pet.actions[1]==24 and t.pet.actions[2]==62)
    assert(t.pet.feed==102 and t.pet.food==146)
    assert(t.settings==484)
    assert(t.aspects.x+t.aspects.width<t.pet.x)
    assert(t.pet.x+t.pet.width<t.settings)
end)

test("hunter pet group fits feeding tools when no pet spells are learned",function()
    local t=model().GroupLayout(6,0)
    assert(t.aspects.x+t.aspects.width<t.pet.x)
    assert(t.pet.feed==24 and t.pet.food==68)
    assert(t.pet.x+t.pet.width<t.settings)
end)

test("aspect and pet group offsets remain independent relative to the Hunter control",function()
    local t=model().GroupLayout(5,2,{x=42,y=-115},{x=340,y=-130})
    assert(t.aspects.x==42 and t.aspects.y==-115)
    assert(t.pet.x==340 and t.pet.y==-130)
    assert(t.aspects.x~=t.pet.x and t.aspects.y~=t.pet.y)
end)

test("dragged group offsets preserve the measured root-relative coordinates at scaled UI sizes",function()
    local offset=model().GroupOffset(410,270,310,370)
    assert(offset.x==100 and offset.y==-100)
end)
