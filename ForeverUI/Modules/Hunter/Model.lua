local _,ns=...
ns.HunterModel={}
function ns.HunterModel.ResolveZone(validTarget,shot,melee,near)
    if validTarget==false then return "none" end
    if validTarget~=true then return "unknown" end
    if shot==true then return "ranged" end
    if melee==true then return "melee" end
    if shot==false and melee==false then
        if near==true then return "deadzone" end
        if near==false then return "far" end
    end
    return "unknown"
end
function ns.HunterModel.AmmoTransition(previousLow,count,threshold)
    if threshold==0 then return false,false end
    if type(count)~="number" or count<0 then return previousLow==true,false end
    local low=count<threshold
    return low,low and not previousLow
end
function ns.HunterModel.ResolvePet(exists,dead,happiness)
    if exists==false then return "missing" end
    if exists~=true then return "unknown" end
    if dead==true then return "dead" end
    if dead~=false then return "unknown" end
    return ({[1]="unhappy",[2]="content",[3]="happy"})[happiness] or "unknown"
end
