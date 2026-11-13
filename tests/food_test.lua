local ns={}
loadAddon("Modules/Hunter/FoodModel.lua",ns)
local function model()
    assert(ns.FoodModel,"Food model is not implemented")
    return ns.FoodModel
end

test("food selection merges bag stacks and excludes inedible or empty items",function()
    local entries=model().Filter({
        {id=10,count=5,name="Meat",canEat=true},
        {id=10,count=7,name="Meat",canEat=true},
        {id=11,count=0,name="Empty",canEat=true},
        {id=12,count=5,name="Wrong food",canEat=false}})
    assert(#entries==1 and entries[1].id==10 and entries[1].count==12 and entries[1].ready==true)
end)

test("uncached food is visible but cannot be selected as ready",function()
    local entries=model().Filter({{id=10,count=3,canEat=true}})
    assert(#entries==1 and entries[1].ready==false)
    entries=model().Filter({{id=10,count=3,name="Meat",canEat=true}})
    assert(entries[1].ready==true)
end)

test("unknown edibility does not silently become suitable food",function()
    local entries=model().Filter({{id=10,count=3,name="Meat",canEat=nil}})
    assert(#entries==0)
end)

test("secure feed position is derived without anchoring it to the movable panel",function()
    local p=model().FeedPosition({point="CENTER",relativePoint="CENTER",x=0,y=-70})
    assert(p.point=="TOPLEFT" and p.relativePoint=="CENTER" and p.x==-78 and p.y==-131)
    p=model().FeedPosition({point="TOPLEFT",relativePoint="TOPLEFT",x=10,y=-15})
    assert(p.x==242 and p.y==-126)
end)
