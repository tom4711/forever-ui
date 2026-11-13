local addon, ns = ...
function ns.Print(message)
    DEFAULT_CHAT_FRAME:AddMessage("|cffd4a447Forever UI|r: "..message)
end
local events=CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED")
events:RegisterEvent("PLAYER_LOGIN")
events:SetScript("OnEvent",function(_,event,name)
    if event=="ADDON_LOADED" and name==addon then
        ns.db=ns.Settings.Load(ForeverUICharDB)
        ForeverUICharDB=ns.db
    elseif event=="PLAYER_LOGIN" then
        SLASH_FOREVERUI1="/fui"
        SlashCmdList.FOREVERUI=function(message)
            if message:match("^%s*preview%s*$") then ns.Preview.SetEnabled(not ns.Preview.IsEnabled())
            else ns.Options.Toggle() end
        end
        ns.Print(ns.L.READY)
    end
end)
