local _,ns=...
ns.Preview={}
local enabled=false
local hunter,xp
local function build()
    hunter=ns.HunterView.Create("ForeverUI_PreviewHunter",true)
    xp=ns.XPView.Create("ForeverUI_PreviewXP",true)
    hunter.Render({zone="ranged",ammoCount=1248,ammoIcon=ns.Theme.icons.ammo,ammoLow=false,petState="happy"})
    xp.Render({level=32,current=36240,maximum=62000,percent=36240/62000*100,rested=12400,restedEnd=48640,
        remaining=25760,earned=14632,elapsed=2832,perHour=18600,eta=25760/18600*3600,atCap=false,reliable=true})
end
function ns.Preview.IsEnabled()return enabled end
function ns.Preview.Refresh()
    if not hunter then return end
    xp.SetWidth(ns.db.xp.width)
    ns.UI.Place(hunter.frame,"hunter");ns.UI.Place(xp.frame,"xp")
    hunter.frame:SetShown(enabled and ns.db.hunter.enabled)
    xp.frame:SetShown(enabled and ns.db.xp.enabled)
end
function ns.Preview.SetEnabled(value)
    if InCombatLockdown()then ns.Print(ns.L.COMBAT);return false end
    if not hunter then build()end
    enabled=value==true;ns.Refresh()
    if ns.Options.Refresh then ns.Options.Refresh()end
    return true
end
