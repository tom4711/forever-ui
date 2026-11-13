local _,ns=...
local UI,T=ns.UI,ns.Theme
ns.XPView={}
function ns.XPView.Create(name,preview)
    local L=ns.L
    local frame=UI.CreatePanel(UIParent,name);frame:SetSize(620,132)
    local icon=UI.CreateIconButton(frame);icon:SetPoint("TOPLEFT",18,-14);icon:SetSize(38,38);icon.icon:Hide()
    local xpMark=UI.Text(icon,19,T.goldLight);xpMark:SetPoint("CENTER",0,1);xpMark:SetText("XP")
    local title=UI.Text(frame,21,T.goldLight);title:SetPoint("TOPLEFT",70,-17)
    local percent=UI.Text(frame,16,T.teal);percent:SetPoint("TOPRIGHT",-20,-20)
    local numbers=UI.Text(frame,12,T.text);numbers:SetPoint("TOP",frame,"TOP",0,-23)
    local barWidth=580
    local track=UI.Rect(frame,T.inset,"BACKGROUND");track:SetDrawLayer("BACKGROUND",1)
    track:SetPoint("TOPLEFT",20,-57);track:SetSize(barWidth,23)
    local fill=UI.Rect(frame,T.xp);fill:SetDrawLayer("ARTWORK",1);fill:SetHeight(23)
    local quest=UI.Rect(frame,T.quest);quest:SetDrawLayer("ARTWORK",2);quest:SetHeight(23)
    local rested=UI.Rect(frame,T.rested);rested:SetDrawLayer("ARTWORK",3);rested:SetHeight(23)
    local shine=UI.Rect(frame,{0.6,0.95,0.9,0.45},"OVERLAY");shine:SetPoint("TOPLEFT",fill,"TOPLEFT",0,0);shine:SetPoint("TOPRIGHT",fill,"TOPRIGHT",0,0);shine:SetHeight(2)
    local questEdge=UI.Rect(frame,T.goldLight,"OVERLAY");questEdge:SetSize(1,23)
    local restedEdge=UI.Rect(frame,T.restedText,"OVERLAY");restedEdge:SetSize(1,23)
    local currentLabel=UI.Text(frame,10,T.teal);currentLabel:SetPoint("TOPLEFT",20,-86)
    local questLabel=UI.Text(frame,10,T.goldLight);questLabel:SetPoint("TOP",frame,"TOP",0,-86)
    local rest=UI.Text(frame,10,T.restedText);rest:SetPoint("TOPRIGHT",-20,-86)
    local rate=UI.Text(frame,11,T.muted);rate:SetPoint("TOPLEFT",20,-109)
    local earned=UI.Text(frame,11,T.muted)
    local eta=UI.Text(frame,11,T.muted)
    local elapsed=UI.Text(frame,11,T.muted);elapsed:SetPoint("TOPRIGHT",-20,-109)
    UI.MakeMovable(frame,"xp")
    local summary
    frame:SetScript("OnEnter",function(self)
        if not summary then return end
        GameTooltip:SetOwner(self,"ANCHOR_TOP");GameTooltip:SetText(L.EXPERIENCE,1,0.82,0.42)
        GameTooltip:AddLine(L.REMAINING..": "..ns.Format.Number(summary.remaining),0.79,0.85,0.84,true)
        GameTooltip:AddLine(L.QUEST_XP..": "..ns.Format.Number(summary.questXP),1,0.82,0.42,true)
        GameTooltip:AddLine(L.RESTED..": "..ns.Format.Number(summary.rested),0.57,0.75,0.96,true)
        GameTooltip:AddLine(L.QUEST_PREVIEW_HINT,0.79,0.85,0.84,true)
        if summary.measurementReset then GameTooltip:AddLine(L.RESET_MEASUREMENT,1,0.82,0.42,true)end
        GameTooltip:Show()
    end)
    frame:SetScript("OnLeave",function()GameTooltip:Hide()end)
    local view={frame=frame}
    local function displayText(amount,mode,maximum)
        local value=ns.XPModel.DisplayAmount(amount,maximum,mode)
        if value==nil then return "–" end
        if mode=="percent" then
            local text=string.format("%.1f",value)
            if GetLocale()=="deDE" then text=text:gsub("%.",",") end
            return text.." %"
        end
        return "+"..ns.Format.Number(value).." XP"
    end
    local function segment(texture,value)
        texture:ClearAllPoints();texture:SetPoint("TOPLEFT",track,"TOPLEFT",barWidth*value.start,0)
        texture:SetWidth(math.max(0.01,barWidth*value.size));texture:SetShown(value.size>0)
    end
    function view.SetWidth(width)
        frame:SetWidth(width);barWidth=width-40;track:SetWidth(barWidth)
        earned:ClearAllPoints();earned:SetPoint("TOPLEFT",frame,"TOPLEFT",width*0.27,-109)
        eta:ClearAllPoints();eta:SetPoint("TOPLEFT",frame,"TOPLEFT",width*0.53,-109)
        if summary then view.Render(summary)end
    end
    function view.Render(data)
        summary=data
        title:SetText(data.atCap and L.MAX_LEVEL or L.LEVEL_PREFIX.." "..ns.Format.Number(data.level))
        local p=data.percent
        local pText=p and string.format("%.1f",p)or "–"
        if GetLocale()=="deDE"then pText=pText:gsub("%.",",")end
        percent:SetText(pText.." %")
        local segments=ns.XPModel.Segments(data)
        segment(fill,segments.current);segment(quest,segments.quest);segment(rested,segments.rested)
        shine:SetShown(segments.current.size>0)
        questEdge:ClearAllPoints();questEdge:SetPoint("TOPLEFT",track,"TOPLEFT",barWidth*segments.quest.start,0);questEdge:SetShown(segments.quest.size>0)
        restedEdge:ClearAllPoints();restedEdge:SetPoint("TOPLEFT",track,"TOPLEFT",barWidth*segments.rested.start,0);restedEdge:SetShown(segments.rested.size>0)
        numbers:SetText(data.atCap and L.MAX_LEVEL_HINT or ns.Format.Number(data.current).." / "..ns.Format.Number(data.maximum).." XP")
        currentLabel:SetText(preview and L.PREVIEW or L.CURRENT_XP)
        questLabel:SetText(data.atCap and ""or L.QUEST_XP.." "..displayText(data.questXP,ns.db.xp.questDisplay,data.maximum))
        rest:SetText(data.atCap and ""or L.RESTED.." "..displayText(data.rested,ns.db.xp.restedDisplay,data.maximum))
        rate:SetText("XP/h: |cffcbdad6"..ns.Format.Number(data.perHour).."|r")
        earned:SetText((data.measurementReset and L.GAIN_RESET or L.GAIN_SHORT)..": |cffcbdad6"..ns.Format.Number(data.earned).." XP|r")
        eta:SetText(L.NEXT_LEVEL..": |cffcbdad6"..ns.Format.Duration(data.eta).."|r")
        elapsed:SetText(L.SESSION..": |cffcbdad6"..ns.Format.Duration(data.elapsed).."|r")
    end
    view.SetWidth(620)
    frame:Hide();return view
end
