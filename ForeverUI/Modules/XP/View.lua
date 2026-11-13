local _,ns=...
local UI,T=ns.UI,ns.Theme
ns.XPView={}
function ns.XPView.Create(name)
    local L=ns.L
    local frame=UI.CreatePanel(UIParent,name);frame:SetSize(620,145)
    local icon=UI.CreateIconButton(frame);icon:SetPoint("TOPLEFT",17,-17);icon:SetSize(48,48);icon.icon:SetTexture(T.icons.xp)
    local title=UI.Text(frame,21,T.goldLight);title:SetPoint("TOPLEFT",82,-17)
    local percent=UI.Text(frame,16,T.teal);percent:SetPoint("TOPRIGHT",-20,-21)
    local track=UI.Rect(frame,T.inset);track:SetPoint("TOPLEFT",82,-49);track:SetSize(518,16)
    local rested=UI.Rect(frame,T.rested);rested:SetPoint("TOPLEFT",track,"TOPLEFT",0,0);rested:SetHeight(16)
    local fill=UI.Rect(frame,T.xp);fill:SetPoint("TOPLEFT",track,"TOPLEFT",0,0);fill:SetHeight(16)
    local shine=UI.Rect(frame,{0.54,0.92,0.85,0.38});shine:SetPoint("TOPLEFT",fill,"TOPLEFT",0,0);shine:SetPoint("TOPRIGHT",fill,"TOPRIGHT",0,0);shine:SetHeight(2)
    local numbers=UI.Text(frame,11,T.text);numbers:SetPoint("TOPLEFT",82,-70)
    local rest=UI.Text(frame,11,T.muted);rest:SetPoint("TOPRIGHT",-20,-70)
    local rate=UI.Text(frame,11,T.muted);rate:SetPoint("TOPLEFT",20,-99)
    local eta=UI.Text(frame,11,T.muted);eta:SetPoint("TOPLEFT",220,-99)
    local elapsed=UI.Text(frame,11,T.muted);elapsed:SetPoint("TOPRIGHT",-20,-99)
    local earned=UI.Text(frame,11,T.muted);earned:SetPoint("TOPLEFT",20,-122)
    local reset=UI.Text(frame,10,T.gold);reset:SetPoint("TOPRIGHT",-20,-122)
    UI.MakeMovable(frame,"xp")
    local summary
    frame:SetScript("OnEnter",function(self)
        if not summary then return end
        GameTooltip:SetOwner(self,"ANCHOR_TOP");GameTooltip:SetText(L.EXPERIENCE,1,0.82,0.42)
        GameTooltip:AddLine(L.REMAINING..": "..ns.Format.Number(summary.remaining),0.79,0.85,0.84,true)
        GameTooltip:AddLine(L.SESSION_XP..": "..ns.Format.Number(summary.earned),0.79,0.85,0.84,true)
        if summary.measurementReset then GameTooltip:AddLine(L.RESET_MEASUREMENT,1,0.82,0.42,true)end
        GameTooltip:Show()
    end)
    frame:SetScript("OnLeave",function()GameTooltip:Hide()end)
    local view={frame=frame}
    function view.Render(data)
        summary=data
        title:SetText(data.atCap and L.MAX_LEVEL or L.LEVEL_PREFIX.." "..ns.Format.Number(data.level))
        local p=data.percent
        local pText=p and string.format("%.1f",p)or "–"
        if GetLocale()=="deDE"then pText=pText:gsub("%.",",")end
        percent:SetText(pText.." %")
        fill:SetShown(p~=nil and p>0);fill:SetWidth(math.max(1,518*(p or 0)/100))
        local resting=data.restedEnd and data.maximum and data.maximum>0 and data.restedEnd/data.maximum or 0
        rested:SetShown(resting>0);rested:SetWidth(math.max(1,518*resting))
        numbers:SetText(data.atCap and L.MAX_LEVEL_HINT or ns.Format.Number(data.current).." / "..ns.Format.Number(data.maximum).." XP")
        rest:SetText(data.atCap and ""or L.RESTED.." +"..ns.Format.Number(data.rested))
        rate:SetText(L.XP_HOUR..": |cffcbdad6"..ns.Format.Number(data.perHour).."|r")
        eta:SetText(L.NEXT_LEVEL..": |cffcbdad6"..ns.Format.Duration(data.eta).."|r")
        elapsed:SetText(L.SESSION..": |cffcbdad6"..ns.Format.Duration(data.elapsed).."|r")
        earned:SetText(L.SESSION_XP..": |cffcbdad6"..ns.Format.Number(data.earned).."|r")
        reset:SetText(data.measurementReset and L.RESET_SHORT or "")
    end
    frame:Hide();return view
end
