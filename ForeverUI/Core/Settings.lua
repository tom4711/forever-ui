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
local function position(value, y, default)
    value = tableOrEmpty(value)
    if not anchors[value.point] or not anchors[value.relativePoint] or not finite(value.x) or not finite(value.y) then
        default=default or {point="CENTER",relativePoint="CENTER",x=0,y=y}
        return {point=default.point,relativePoint=default.relativePoint,x=default.x,y=default.y}
    end
    return {point=value.point,relativePoint=value.relativePoint,x=value.x,y=value.y}
end
local function module(value, y, defaultPosition)
    value = tableOrEmpty(value)
    local scale = value.scale
    if not finite(scale) or scale < 0.5 or scale > 2 then scale = 1 end
    return {enabled=boolean(value.enabled,true),scale=scale,position=position(value.position,y,defaultPosition)}
end
local function appearance(value, defaultOpacity)
    value = tableOrEmpty(value)
    local opacity = value.opacity
    if not finite(opacity) or opacity < 0 or opacity > 1 then opacity = defaultOpacity end
    return {enabled = boolean(value.enabled, false), opacity = opacity}
end

local function actionGroup(value, x, y)
    value=tableOrEmpty(value)
    local saved=tableOrEmpty(value.position)
    local offsetX,offsetY=saved.x,saved.y
    if not finite(offsetX) or offsetX < -2000 or offsetX > 2000 then offsetX=x end
    if not finite(offsetY) or offsetY < -2000 or offsetY > 2000 then offsetY=y end
    return {enabled=boolean(value.enabled,true),position={x=offsetX,y=offsetY}}
end
local function flightSettings(value)
    value=tableOrEmpty(value)
    local scale=value.secondsPerUnit
    if not finite(scale)or scale<100 or scale>4000 then scale=650 end
    local source=tableOrEmpty(value.routes)
    local keys={}
    for route,seconds in pairs(source)do
        local split=type(route)=="string"and route:find(" -> ",1,true)
        if split and #route>=5 and #route<=150 and split>1 and split+4<=#route and not route:find("[|;\r\n\t]")
            and finite(seconds)and seconds>=5 and seconds<=3600 then keys[#keys+1]=route end
    end
    table.sort(keys)
    local routes={}
    for i=1,math.min(500,#keys)do local route=keys[i];routes[route]=source[route]end
    return {routes=routes,secondsPerUnit=scale,importedForeverXPBar=value.importedForeverXPBar==true}
end
function ns.Settings.Load(saved)
    saved = tableOrEmpty(saved)
    local hunter, xp = tableOrEmpty(saved.hunter), tableOrEmpty(saved.xp)
    local paladin, warlock = tableOrEmpty(saved.paladin), tableOrEmpty(saved.warlock)
    local priest=tableOrEmpty(saved.priest)
    local player=tableOrEmpty(saved.player)
    local result = {schemaVersion=1,locked=boolean(saved.locked,true),player=module(player,-70,{point="TOPLEFT",relativePoint="TOPLEFT",x=28,y=-28}),hunter=module(hunter,-70),xp=module(xp,-255),
        paladin=module(paladin,-400),warlock=module(warlock,-540),priest=module(priest,-400)}
    local mage, shaman, druid = tableOrEmpty(saved.mage), tableOrEmpty(saved.shaman), tableOrEmpty(saved.druid)
    result.mage = module(mage, -70)
    result.mage.buffGroup = actionGroup(mage.buffGroup, 14, -39)
    result.mage.utilityGroup = actionGroup(mage.utilityGroup, 166, -39)
    result.mage.interruptGroup = actionGroup(mage.interruptGroup, 14, -107)
    result.shaman = module(shaman, -70)
    result.shaman.totemGroup = actionGroup(shaman.totemGroup, 14, -39)
    result.shaman.buffGroup = actionGroup(shaman.buffGroup, 256, -39)
    result.shaman.utilityGroup = actionGroup(shaman.utilityGroup, 256, -107)
    result.shaman.interruptGroup = actionGroup(shaman.interruptGroup, 14, -149)
    result.druid = module(druid, -70)
    result.druid.buffGroup = actionGroup(druid.buffGroup, 14, -39)
    result.shaman.showTotemStatus = boolean(shaman.showTotemStatus, true)
    local rogue, warrior = tableOrEmpty(saved.rogue), tableOrEmpty(saved.warrior)
    result.rogue = module(rogue, -70)
    result.rogue.interruptGroup = actionGroup(rogue.interruptGroup, 14, -39)
    result.warrior = module(warrior, -70)
    result.warrior.stanceGroup = actionGroup(warrior.stanceGroup, 14, -39)
    result.warrior.interruptGroup = actionGroup(warrior.interruptGroup, 180, -39)
    local target = tableOrEmpty(saved.target)
    result.target = module(target, -70, {point="TOPLEFT",relativePoint="TOPLEFT",x=434,y=-28})
    result.target.enabled = boolean(target.enabled, false)
    local party = tableOrEmpty(saved.party)
    result.party = module(party, -360, {point="TOPLEFT",relativePoint="TOPLEFT",x=28,y=-362})
    result.party.enabled = boolean(party.enabled, false)
    result.party.replaceBlizzard = boolean(party.replaceBlizzard, false)
    result.companion = module(saved.companion, -284, {point="TOPLEFT",relativePoint="TOPLEFT",x=28,y=-284})
    result.castBar = module(saved.castBar, 72)
    result.classAccent = boolean(saved.classAccent, false)
    result.actionBars = appearance(saved.actionBars, 0.25)
    result.inventory = appearance(saved.inventory, 0.92)
    result.bindings = ns.Bindings and ns.Bindings.Load(saved.bindings) or {}
    local minimapButton=tableOrEmpty(saved.minimapButton)
    local angle=minimapButton.angle
    if not finite(angle) or angle < 0 or angle >= 360 then angle=225 end
    result.minimapButton={angle=angle}
    local sets=tableOrEmpty(paladin.weaponSets)
    local function equipmentSetId(value)
        return finite(value) and value>=0 and value==math.floor(value) and value or nil
    end
    result.paladin.weaponSets={shield=equipmentSetId(sets.shield),twoHand=equipmentSetId(sets.twoHand)}
    result.hunter.aspectGroup=actionGroup(hunter.aspectGroup,16,-72)
    result.hunter.petGroup=actionGroup(hunter.petGroup,280,-72)
    if not hunter.compactLayout then
        local aspects, pet = result.hunter.aspectGroup.position, result.hunter.petGroup.position
        if aspects.x == 16 and aspects.y == -108 then aspects.y = -72 end
        if pet.x == 280 and pet.y == -108 then pet.y = -72 end
    end
    result.hunter.compactLayout = true
    result.paladin.auraGroup = actionGroup(paladin.auraGroup, 14, -39)
    result.paladin.blessingGroup = actionGroup(paladin.blessingGroup, 256, -39)
    result.paladin.weaponGroup = actionGroup(paladin.weaponGroup, 14, -149)
    result.paladin.macroGroup = actionGroup(paladin.macroGroup, 256, -149)
    result.paladin.friendlyGroup = actionGroup(paladin.friendlyGroup, 14, -217)
    result.warlock.summonGroup = actionGroup(warlock.summonGroup, 14, -66)
    result.warlock.macroGroup = actionGroup(warlock.macroGroup, 256, -66)
    result.warlock.friendlyGroup = actionGroup(warlock.friendlyGroup, 14, -176)
    result.priest.buffGroup=actionGroup(priest.buffGroup,14,-34)
    result.priest.supportGroup=actionGroup(priest.supportGroup,210,-34)
    result.priest.macroGroup=actionGroup(priest.macroGroup,14,-102)
    if not priest.macroGroup then
        local buffPosition = result.priest.buffGroup.position
        local supportPosition = result.priest.supportGroup.position
        if buffPosition.x == 14 and buffPosition.y == -108 then buffPosition.y = -34 end
        if supportPosition.x == 250 and supportPosition.y == -108 then supportPosition.x, supportPosition.y = 210, -34 end
    end
    local warning = hunter.ammoWarning
    if not finite(warning) or warning < 0 or warning > 100000 then warning = 200 end
    if finite(hunter.food) and hunter.food>0 then result.hunter.food=math.floor(hunter.food)end
    result.hunter.ammoWarning = math.floor(warning)
    local width=xp.width
    result.xp.width=finite(width) and width>=620 and width<=1600 and math.floor(width)or 620
    result.xp.showAtCap = boolean(xp.showAtCap,true)
    result.xp.questDisplay=xp.questDisplay=="percent" and "percent" or "xp"
    result.xp.restedDisplay=xp.restedDisplay=="percent" and "percent" or "xp"
    result.xp.flight=flightSettings(xp.flight)
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
