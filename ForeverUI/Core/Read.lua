local _, ns = ...
ns.Read = {}
local function secret(value)
    return issecretvalue and issecretvalue(value)
end
function ns.Read.Number(value)
    if secret(value) or type(value) ~= "number" then return nil end
    if value ~= value or value == math.huge or value == -math.huge then return nil end
    return value
end
function ns.Read.Boolean(value)
    if secret(value) or type(value) ~= "boolean" then return nil end
    return value
end

function ns.Read.Try(fn,...)
    if type(fn)~="function" then return false,nil end
    local ok,value=pcall(fn,...)
    if not ok or secret(value) then return false,nil end
    return true,value
end
function ns.Read.Call(fn,...)
    local ok,value=ns.Read.Try(fn,...)
    if ok then return value end
end
