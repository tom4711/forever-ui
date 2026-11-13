local _, ns = ...
ns.Settings = {}
local anchors = {TOPLEFT=true,TOP=true,TOPRIGHT=true,LEFT=true,CENTER=true,RIGHT=true,BOTTOMLEFT=true,BOTTOM=true,BOTTOMRIGHT=true}
local function tableOrEmpty(value)
    return type(value) == "table" and value or {}
end
local function finite(value)
    return type(value) == "number" and value == value and value ~= math.huge and value ~= -math.huge
end
local function boolean(value, default)
    if type(value) == "boolean" then return value end
    return default
end
local function position(value, y)
    value = tableOrEmpty(value)
    if not anchors[value.point] or not anchors[value.relativePoint] or not finite(value.x) or not finite(value.y) then
        return {point="CENTER",relativePoint="CENTER",x=0,y=y}
    end
    return {point=value.point,relativePoint=value.relativePoint,x=value.x,y=value.y}
end
local function module(value, y)
    value = tableOrEmpty(value)
    local scale = value.scale
    if not finite(scale) or scale < 0.5 or scale > 2 then scale = 1 end
    return {enabled=boolean(value.enabled,true),scale=scale,position=position(value.position,y)}
end
function ns.Settings.Load(saved)
    saved = tableOrEmpty(saved)
    local hunter, xp = tableOrEmpty(saved.hunter), tableOrEmpty(saved.xp)
    local result = {schemaVersion=1,locked=boolean(saved.locked,true),hunter=module(hunter,-70),xp=module(xp,-255)}
    local warning = hunter.ammoWarning
    if not finite(warning) or warning < 0 or warning > 100000 then warning = 200 end
    if finite(hunter.food) and hunter.food>0 then result.hunter.food=math.floor(hunter.food)end
    result.hunter.ammoWarning = math.floor(warning)
    local width=xp.width
    result.xp.width=finite(width) and width>=620 and width<=1600 and math.floor(width)or 620
    result.xp.showAtCap = boolean(xp.showAtCap,true)
    local session=saved.xpSession
    if type(session)=="table"then
        local copy={}
        for _,key in ipairs({"version","startedAt","earned"})do if finite(session[key])then copy[key]=session[key]end end
        copy.reliable=session.reliable==true;copy.measurementReset=session.measurementReset==true
        if type(session.last)=="table"then
            copy.last={atCap=session.last.atCap==true}
            for _,key in ipairs({"level","current","maximum","rested","at"})do
                if finite(session.last[key])then copy.last[key]=session.last[key]end
            end
        end
        result.xpSession=copy
    end
    return result
end
