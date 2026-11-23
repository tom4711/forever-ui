local function withXPController(body)
    local live={clock=100,xp=21,taxi=false,zone="Stormwind"}
    local frame={SetShown=function(self,shown)self.shown=shown end}
    local queued={}
    local ns={db={xp={enabled=true,showAtCap=true,width=620}},
        Preview={IsEnabled=function()return false end},UI={Place=function()end}}
    ns.XPView={Create=function()
        return {frame=frame,SetWidth=function()end,Render=function(data)live.summary=data end}
    end}
    local function clock()return live.clock end
    withGlobals({
        CreateFrame=function()
            local events={RegisterEvent=function()end,SetScript=function(self,name,fn)self[name]=fn end}
            live.events=events
            return events
        end,
        UnitLevel=function()return 21 end,UnitXP=function()return live.xp end,UnitXPMax=function()return 100 end,
        GetMaxPlayerLevel=function()return 60 end,GetXPExhaustion=function()return 0 end,
        GetServerTime=clock,GetTime=clock,UnitOnTaxi=function()return live.taxi end,
        C_Timer={After=function(_,callback)queued[#queued+1]=callback end},C_QuestLog=false,
        GetNumTaxiNodes=false,NumTaxiNodes=function()return 2 end,
        TaxiNodeGetType=function(index)return index==1 and "CURRENT"or "REACHABLE"end,
        TaxiNodeName=function(index)return index==1 and "Stormwind"or "Ironforge"end,
        GetMinimapZoneText=function()return live.zone end,
        GetNumRoutes=function()return 1 end,TaxiGetNodeSlot=function(_,_,first)return first and 1 or 2 end,
        TaxiNodePosition=function(index)return index==1 and 0 or 0.5,index==1 and 0 or 0.5 end,
        TakeTaxiNode=function()end,TaxiRequestEarlyLanding=function()end,
        hooksecurefunc=function(name,callback)
            local original=_G[name]
            _G[name]=function(...)
                original(...)
                callback(...)
            end
        end,
        ForeverXPBarDB={flightRouteDurations={["Stormwind -> Ironforge"]=120},flightScale=700},
    },function()
        loadAddon("Core/Read.lua",ns)
        loadAddon("Modules/XP/Model.lua",ns)
        loadAddon("Modules/XP/Controller.lua",ns)
        function live:event(name,...)
            self.events.OnEvent(self.events,name,...)
        end
        function live:tick()
            self.events.OnUpdate(self.events,1)
        end
        function live:flush()
            local callbacks=queued
            queued={}
            for _,callback in ipairs(callbacks)do callback()end
        end
        body(ns,live,frame)
    end)
end

local function previousXPSession()
    return {version=1,startedAt=40,earned=12,reliable=true,last={level=21,current=20,maximum=100,rested=0,at=90}}
end

test("XP panel initializes from a live snapshot even before the world event",function()
    withXPController(function(ns,live,frame)
        ns.XP.Init()
        assert(frame.shown==true and live.summary.current==21 and live.summary.earned==0)
    end)
end)

test("Forever XP hides only the native experience visuals and restores them on swaps and disabling",function()
    withXPController(function(ns,live,frame)
        local function region(alpha,mouse)
            local object={alpha=alpha,mouse=mouse}
            function object:GetAlpha()return self.alpha end
            function object:SetAlpha(value)self.alpha=value end
            if mouse~=nil then
                function object:IsMouseEnabled()return self.mouse end
                function object:EnableMouse(value)self.mouse=value end
            end
            return object
        end
        local function statusSlot(index)
            local xp=region(0.8,true)
            xp.ExhaustionTick=region(1,true)
            local divider=region(0.7)
            return {
                bars={xp,region(1)},shownBarIndex=index,BarFrameTexture=region(0.9),divider=divider,
                HorizontalDividersPool={EnumerateActive=function()return pairs({[divider]=true})end},
                ApplyPendingBarToShow=function(self,nextIndex)self.shownBarIndex=nextIndex end,
                UpdateDividers=function(self)
                    local newDivider=region(0.6)
                    self.divider=newDivider
                    self.HorizontalDividersPool.EnumerateActive=function()return pairs({[newDivider]=true})end
                end,
            }
        end
        local main,secondary=statusSlot(1),statusSlot(2)
        local hookFunction=hooksecurefunc
        withGlobals({
            StatusTrackingBarInfo={BarsEnum={Experience=1,Reputation=2}},
            StatusTrackingBarManager={barContainers={main,secondary}},
            hooksecurefunc=function(owner,method,callback)
                if type(owner)=="string" then return hookFunction(owner,method)end
                local original=owner[method]
                owner[method]=function(...)
                    original(...)
                    callback(...)
                end
            end,
        },function()
            ns.XP.Init()
            assert(frame.shown and main.bars[1].alpha==0,"native XP remained visible")
            assert(not main.bars[1].mouse and not main.bars[1].ExhaustionTick.mouse)
            assert(main.BarFrameTexture.alpha==0 and main.divider.alpha==0)
            assert(secondary.BarFrameTexture.alpha==0.9 and secondary.bars[2].alpha==1)
            assert(main.bars[2].alpha==1)

            live:event("PLAYER_ENTERING_WORLD",false,true)
            live:flush()
            -- A later redraw can restore visual properties after the initial mask.
            main.bars[1]:SetAlpha(0.75)
            main.bars[1]:EnableMouse(true)
            main.bars[1].ExhaustionTick:EnableMouse(true)
            main.BarFrameTexture:SetAlpha(0.85)
            main.divider:SetAlpha(0.65)
            live:tick()
            assert(main.bars[1].alpha==0 and main.BarFrameTexture.alpha==0 and main.divider.alpha==0,
                "a redraw after UI reload brought back the native XP bar")
            assert(not main.bars[1].mouse and not main.bars[1].ExhaustionTick.mouse)

            main:UpdateDividers()
            assert(main.divider.alpha==0,"rebuilding dividers exposed the native bar")
            main:ApplyPendingBarToShow(2)
            secondary:ApplyPendingBarToShow(1)
            assert(main.BarFrameTexture.alpha==0.85 and main.divider.alpha==0.6)
            assert(main.bars[1].alpha==0.75 and main.bars[1].mouse and main.bars[1].ExhaustionTick.mouse)
            assert(secondary.BarFrameTexture.alpha==0 and secondary.bars[1].alpha==0)

            ns.Preview.IsEnabled=function()return true end
            ns.XP.Refresh()
            assert(not frame.shown and secondary.bars[1].alpha==0.8 and secondary.BarFrameTexture.alpha==0.9)
            ns.Preview.IsEnabled=function()return false end
            ns.XP.Refresh()
            assert(frame.shown and secondary.bars[1].alpha==0)

            ns.db.xp.enabled=false
            ns.XP.Refresh()
            assert(not frame.shown and secondary.bars[1].alpha==0.8 and secondary.bars[1].mouse)
            assert(secondary.BarFrameTexture.alpha==0.9 and secondary.divider.alpha==0.7)
            secondary:UpdateDividers()
            assert(secondary.divider.alpha==0.6,"native dividers were changed while Forever XP was disabled")
        end)
    end)
end)

test("XP controller preserves earned XP and elapsed time across a UI reload",function()
    withXPController(function(ns,live)
        ns.db.xpSession=previousXPSession()
        ns.XP.Init()
        live.clock=105
        live.xp=25
        live:event("PLAYER_ENTERING_WORLD",false,true)
        assert(live.summary.earned==17 and live.summary.elapsed==65,"reload lost the saved XP baseline")
        live.clock=110
        live.xp=28
        live:event("PLAYER_XP_UPDATE")
        live:flush()
        assert(ns.db.xpSession.earned==20 and ns.db.xpSession.startedAt==40)
    end)
end)

test("pre-world XP updates and logout preserve the saved session",function()
    withXPController(function(ns,live)
        ns.db.xpSession=previousXPSession()
        ns.XP.Init()
        live.clock=103
        live.xp=24
        live:event("PLAYER_XP_UPDATE")
        live:flush()
        assert(live.summary.current==24)
        assert(ns.db.xpSession.earned==12 and ns.db.xpSession.startedAt==40,"pre-world sample overwrote the saved session")
        live:event("PLAYER_LOGOUT")
        assert(ns.db.xpSession.earned==12 and ns.db.xpSession.startedAt==40,"pre-world logout overwrote the saved session")
    end)
end)

test("XP controller starts a new session at login and continues it across zone loads",function()
    withXPController(function(ns,live)
        ns.db.xpSession=previousXPSession()
        ns.XP.Init()
        live.clock=105
        live.xp=25
        live:event("PLAYER_ENTERING_WORLD",true,false)
        assert(live.summary.earned==0 and live.summary.elapsed==0)
        live.clock=120
        live.xp=35
        live:event("PLAYER_ENTERING_WORLD",false,false)
        assert(live.summary.earned==10 and live.summary.elapsed==15)
    end)
end)

test("taxi learns a full flight under the current taxi node name",function()
    withXPController(function(ns,live)
        live.zone="Trade District"
        ns.XP.Init()
        TakeTaxiNode(2)
        live.taxi=true
        live:tick()
        local active=ns.XP.FlightSnapshot()
        assert(active.route=="Stormwind -> Ironforge" and active.estimate==120,"taxi route used the minimap subzone")
        live.clock=250
        live.taxi=false
        live:tick()
        local saved=ns.db.xp.flight
        assert(saved.routes["Stormwind -> Ironforge"]==129 and saved.routes["Trade District -> Ironforge"]==nil)
    end)
end)

test("taxi shows its estimate and keeps imported data when the flight is only partly observed",function()
    withXPController(function(ns,live)
        ns.XP.Init()
        local saved=ns.db.xp.flight
        assert(saved.importedForeverXPBar and saved.routes["Stormwind -> Ironforge"]==120)
        TakeTaxiNode(2)
        live.taxi=true
        live:tick()
        live.clock=130
        live:tick()
        local active=live.summary.flight
        assert(active.active and active.elapsed==30 and active.estimate==120 and active.progress==0.25 and active.estimateIsApproximate==false)
        live.clock=140
        live.taxi=nil
        live:tick()
        assert(live.summary.flight.active and saved.routes["Stormwind -> Ironforge"]==120)
        live.clock=160
        live.taxi=true
        live:tick()
        live.clock=190
        live.taxi=false
        live:tick()
        assert(saved.routes["Stormwind -> Ironforge"]==120,"unreadable taxi state changed the learned route")
        assert(live.summary.flight.active==false,"landing did not hide the flight row")
        live.clock=200
        live.taxi=true
        ns.XP.Init()
        live.clock=260
        live.taxi=false
        live:tick()
        assert(saved.routes["Stormwind -> Ironforge"]==120,"an in-flight reload recorded a partial route")
        live.clock=300
        TakeTaxiNode(2)
        live.taxi=nil
        live:tick()
        live.clock=320
        live.taxi=true
        live:tick()
        live.clock=360
        live.taxi=false
        live:tick()
        assert(saved.routes["Stormwind -> Ironforge"]==120,"late taxi confirmation recorded a partial route")
    end)
end)

for _,phase in ipairs({"selected","active"})do
    test("requesting an early landing excludes the "..phase.." route from learning",function()
        withXPController(function(ns,live)
            ns.XP.Init()
            TakeTaxiNode(2)
            live.taxi=true
            if phase=="active"then live:tick()end
            TaxiRequestEarlyLanding()
            live:tick()
            assert(live.summary.flight.active,"requesting a landing hid the in-flight timer")
            live.clock=160
            live.taxi=false
            live:tick()
            local saved=ns.db.xp.flight
            assert(saved.routes["Stormwind -> Ironforge"]==120 and saved.secondsPerUnit==700,
                "early landing changed the imported route or flight calibration")
        end)
    end)
end

test("XP view adds a compact flight row only while flying and sizes its progress fill",function()
    local saved={UIParent=UIParent,GetLocale=GetLocale,GameTooltip=GameTooltip}
    local textures,labels={},{}
    local function widget()
        local o={}
        function o:SetPoint(...)self.point={...}end;function o:SetSize(w,h)self.width,self.height=w,h end
        function o:SetHeight(h)self.height=h end;function o:SetWidth(w)self.width=w end
        function o:SetText(t)self.text=t end;function o:SetShown(v)self.shown=v end
        function o:Show()self.shown=true end;function o:Hide()self.shown=false end
        function o:ClearAllPoints()self.point=nil end;function o:SetDrawLayer()end
        return o
    end
    local panel=widget();function panel:SetScript(name,fn)self[name]=fn end
    local theme={goldLight={},teal={},text={},inset={},xp={},quest={},rested={},restedText={},muted={}}
    local ns={Theme=theme,L=setmetatable({FLIGHT_TIME="Flugzeit"},{__index=function(_,k)return k end}),
        UI={CreatePanel=function()return panel end,CreateIconButton=function()return {icon={Hide=function()end},SetPoint=function()end,SetSize=function()end}end,
            Text=function()local t=widget();labels[#labels+1]=t;return t end,
            Rect=function(_,color)local t=widget();textures[#textures+1]=t;t.color=color;return t end,
            MakeMovable=function()end},db={xp={questDisplay="xp",restedDisplay="xp"}},
        XPModel=nil,Format={Number=function(v)return tostring(v or "?")end,Duration=function(v)return tostring(v or "?")end}}
    local modelNS={};loadAddon("Modules/XP/Model.lua",modelNS);ns.XPModel=modelNS.XPModel
    UIParent={};GetLocale=function()return "deDE"end;GameTooltip={}
    loadAddon("Modules/XP/View.lua",ns)
    local view=ns.XPView.Create("test")
    local base={level=21,current=50,maximum=100,rested=0,percent=50,perHour=0,earned=0,elapsed=60,questXP=0,reliable=true}
    view.Render(base);assert(panel.height==132 and labels[12].shown==false and textures[8].shown==false)
    base.flight={active=true,elapsed=31}
    view.Render(base)
    assert(panel.height==158 and labels[12].shown==true and labels[12].text=="Flugzeit: 31" and textures[8].shown==false)
    base.flight={active=true,elapsed=30,estimate=120,progress=0.25,estimateIsApproximate=true}
    view.Render(base)
    assert(panel.height==158 and labels[12].shown==true and labels[12].text=="Flugzeit: 30 / ~120")
    assert(textures[8].shown==true and textures[9].width==145)
    base.flight.progress=1.5;view.Render(base);assert(textures[9].width==580)
    UIParent=saved.UIParent;GetLocale=saved.GetLocale;GameTooltip=saved.GameTooltip
end)
