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
function ns.FoodModel.FeedPosition(position)
    local x=position.point:find("LEFT") and 0 or position.point:find("RIGHT") and 620 or 310
    local y=position.point:find("TOP") and 0 or position.point:find("BOTTOM") and 100 or 50
    return {point="TOPLEFT",relativePoint=position.relativePoint,x=position.x+232-x,y=position.y-111+y}
end
