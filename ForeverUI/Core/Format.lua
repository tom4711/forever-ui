local _,ns=...
ns.Format={}
function ns.Format.Number(value)
    if value==nil then return "–"end
    local text=string.format("%.0f",value)
    local separator=GetLocale()=="deDE" and "." or ","
    local reversed=text:reverse():gsub("(%d%d%d)","%1"..separator):reverse()
    if reversed:sub(1,1)==separator then reversed=reversed:sub(2)end
    return reversed
end
function ns.Format.Duration(value)
    if value==nil then return "–"end
    value=math.max(0,math.floor(value))
    local h=math.floor(value/3600);local m=math.floor(value/60)%60
    return string.format("%d:%02d:%02d",h,m,value%60)
end
