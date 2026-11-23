local _,ns=...
ns.FoodModel={}
function ns.FoodModel.Filter(items)
    local byId,entries={},{}
    for _,item in ipairs(items)do
        if type(item.id)=="number" and item.canEat==true and type(item.count)=="number" and item.count>0 then
            local entry=byId[item.id]
            if not entry then
                entry={id=item.id,count=0,ready=false,icon=item.icon}
                byId[item.id]=entry;entries[#entries+1]=entry
            end
            entry.count=entry.count+item.count
            if type(item.name)=="string" and item.name~=""then entry.name=item.name;entry.ready=true end
        end
    end
    table.sort(entries,function(a,b)return a.id<b.id end)
    return entries
end
function ns.FoodModel.FeedPosition(geometry,offset)
    for _,key in ipairs({"left","top","scale","parentScale","parentLeft","parentBottom"})do
        local value=geometry[key]
        if type(value)~="number"or value~=value or value==math.huge or value==-math.huge then return nil end
    end
    if geometry.scale<=0 or geometry.parentScale<=0 then return nil end
    local ratio=geometry.parentScale/geometry.scale
    return {point="TOPLEFT",relativePoint="BOTTOMLEFT",x=geometry.left+(offset or 232)-geometry.parentLeft*ratio,
        y=geometry.top-111-geometry.parentBottom*ratio}
end

function ns.FoodModel.State(data)
    if data.known~=true then return "unlearned"end
    if data.petExists==false then return "missing"end
    if data.petExists~=true then return "unknown"end
    if data.petDead==true then return "dead"end
    if data.petDead~=false then return "unknown"end
    if not data.foodID then return "unselected"end
    if not data.name then return "loading"end
    if data.count==nil then return "unknown"end
    if data.count<=0 then return "empty"end
    if data.canEat==false then return "unsuitable"end
    if data.canEat~=true then return "unknown"end
    return "ready"
end
