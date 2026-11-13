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

test("secure feed placement follows actual clamped coordinates at equal scales",function()
    local p=model().FeedPosition({left=100,top=500,scale=1,parentScale=1,parentLeft=0,parentBottom=0})
    assert(p.point=="TOPLEFT" and p.relativePoint=="BOTTOMLEFT" and p.x==332 and p.y==334)
end)

test("feed placement accounts for different UIParent scale without moving off the row",function()
    local p=model().FeedPosition({left=25,top=200,scale=0.8,parentScale=0.64,parentLeft=10,parentBottom=5})
    assert(math.abs(p.x-249)<0.00001 and math.abs(p.y-30)<0.00001)
end)

test("unresolved frame geometry never becomes a guessed secure anchor",function()
    assert(model().FeedPosition({})==nil)
end)


test("a stocked selection that the current pet cannot eat is not ready",function()
    local m=model();assert(m.State,"Feed state is not implemented")
    assert(m.State({known=true,petExists=true,petDead=false,foodID=10,name="Meat",count=24,canEat=false})=="unsuitable")
end)

test("uncached selected food exposes a loading state",function()
    local m=model();assert(m.State,"Feed state is not implemented")
    assert(m.State({known=true,petExists=true,petDead=false,foodID=10,count=24,canEat=true})=="loading")
end)

test("absent and dead companions have explicit feed states",function()
    local m=model();assert(m.State,"Feed state is not implemented")
    assert(m.State({known=true,petExists=false})=="missing")
    assert(m.State({known=true,petExists=true,petDead=true})=="dead")
end)

test("ready empty and unknown stock use the same action state as feedback",function()
    local m=model();assert(m.State,"Feed state is not implemented")
    assert(m.State({known=true,petExists=true,petDead=false,foodID=10,name="Meat",count=24,canEat=true})=="ready")
    assert(m.State({known=true,petExists=true,petDead=false,foodID=10,name="Meat",count=0,canEat=true})=="empty")
    assert(m.State({known=true,petExists=true,petDead=false,foodID=10,name="Meat",canEat=true})=="unknown")
end)
