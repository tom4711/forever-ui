local _,ns=...
ns.Preview={}
local enabled=false
local hunter,xp,paladin,warlock,priest,player
local function classToken()
    if type(UnitClass)~="function"then return nil end
    local ok,_,class=pcall(UnitClass,"player")
    return ok and class or nil
end
local function build()
    hunter=ns.HunterView.Create("ForeverUI_PreviewHunter",true)
    xp=ns.XPView.Create("ForeverUI_PreviewXP",true)
    paladin=ns.PaladinView.Create("ForeverUI_PreviewPaladin",true)
    warlock=ns.WarlockView.Create("ForeverUI_PreviewWarlock",true)
    priest=ns.PriestView.Create("ForeverUI_PreviewPriest",true)
    player=ns.PlayerView.Create("ForeverUI_PreviewPlayer",true)
    player.RenderMoney(1234506)
    hunter.Render({zone="ranged",ammoCount=1248,ammoIcon=ns.Theme.icons.ammo,ammoLow=false,petState="happy"})
    xp.Render({level=32,current=36240,maximum=62000,percent=36240/62000*100,rested=12400,restedEnd=48640,
        remaining=25760,questXP=6200,earned=14632,elapsed=2832,perHour=18600,eta=25760/18600*3600,atCap=false,reliable=true})
end
function ns.Preview.IsEnabled()return enabled end
function ns.Preview.Refresh()
    if not hunter then return end
    xp.SetWidth(ns.db.xp.width)
    hunter.SetToolbar(ns.HunterActionModel.GroupLayout(5,#ns.HunterActionModel.PetActionOrder,ns.db.hunter.aspectGroup.position,ns.db.hunter.petGroup.position),ns.db.hunter)
    ns.UI.Place(hunter.frame,"hunter");ns.UI.Place(xp.frame,"xp");ns.UI.Place(player.frame,"player")
    local class=classToken()
    ns.ClassSupport.Preview(enabled, class)
    ns.Target.Preview(enabled)
    ns.Party.SetPreview(enabled)
    ns.Companion.Preview(enabled, class)
    hunter.frame:SetShown(enabled and class=="HUNTER" and ns.db.hunter.enabled)
    local paladinSample={visible=enabled and class=="PALADIN" and ns.db.paladin.enabled,shield=true,activeAura="devotion",shieldState="shield"}
    paladin.RenderStatus(paladinSample)
    paladin.RenderActions(paladinSample,{{key="devotion",kind="aura",spellID=465},{key="retribution",kind="aura",spellID=7294},{key="might",kind="blessing",spellID=19740},{key="wisdom",kind="blessing",spellID=19742},{key="protection",kind="blessing",spellID=1022},{key="freedom",kind="blessing",spellID=1044}},nil,true,ns.db.paladin)
    local warlockSample={visible=enabled and class=="WARLOCK" and ns.db.warlock.enabled,
        demon={state="living",name=ns.L.DEMON_SAMPLE,health=8400,maxHealth=10000},shards=3,
        quickActions=ns.WarlockModel.QuickActions({[755]=true,[6201]=true})}
    warlock.RenderStatus(warlockSample)
    warlock.RenderActions(warlockSample,{{key="imp",spellID=688},{key="voidwalker",spellID=697},{key="succubus",spellID=712}},true)
    ns.UI.Place(warlock.frame,"warlock")
    local priestSample = {visible = enabled and class == "PRIEST" and ns.db.priest.enabled}
    local priestActions = ns.PriestModel.Actions({
        [1243] = true, [588] = true, [15473] = true, [17] = true, [139] = true,
        [527] = true, [528] = true, [2006] = true, [976] = true, [14752] = true, [15487] = true,
    })
    priest.RenderActions(priestSample,priestActions,{fortitude="active",innerFire="active",shadowform="active"},true,ns.db.priest)
    ns.UI.Place(priest.frame,"priest")
    if enabled and not player.frame:IsShown() then
        local now = GetTime()
        player.Render({
            visible = true, name = "Arthas", level = 32, portrait = ns.Theme.icons.hunter, resting = true,
            health = 7840, maxHealth = 9600, powerType = "MANA", power = 5120, maxPower = 7200,
            buffs = {{spellID = 1243, name = ns.L.POWER_WORD_FORTITUDE, duration = 1800, expirationTime = now + 1320}},
            debuffs = {{spellID = 589, name = ns.L.SHADOW_WORD_PAIN, duration = 18, expirationTime = now + 18, dispellable = true}},
        })
    elseif not enabled then
        player.frame:Hide()
    end
    xp.frame:SetShown(enabled and ns.db.xp.enabled)
end
function ns.Preview.SetEnabled(value)
    if InCombatLockdown()then ns.Print(ns.L.COMBAT);return false end
    if not hunter then build()end
    enabled=value==true;ns.Refresh()
    if ns.Options.Refresh then ns.Options.Refresh()end
    return true
end
