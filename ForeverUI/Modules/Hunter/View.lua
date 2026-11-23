local _,ns=...
local UI,T=ns.UI,ns.Theme
ns.HunterView={}
function ns.HunterView.Create(name,preview)
    local L=ns.L
    local root=CreateFrame("Frame",name,UIParent)
    root:SetSize(460,64);root:SetClampedToScreen(true)
    local frame=UI.CreatePanel(root);frame:SetSize(460,64);frame:SetPoint("TOPLEFT",root,"TOPLEFT",0,0)
    local function label(size,color,x,y,value)
        local text=UI.Text(frame,size,color);text:SetPoint("TOPLEFT",x,y);text:SetText(value or "");return text
    end
    label(10,T.gold,14,-9,L.RANGE_LABEL)
    local range=label(17,T.goldLight,14,-23)
    local hint=label(10,T.good,14,-44);hint:SetWidth(209)
    label(10,T.muted,230,-11,L.AMMO)
    local ammoIcon=frame:CreateTexture(nil,"ARTWORK");ammoIcon:SetSize(15,15);ammoIcon:SetPoint("TOPLEFT",230,-34)
    local ammo=label(17,T.text,248,-31)
    label(10,T.muted,326,-11,L.PET)
    local moodIcon=frame:CreateTexture(nil,"ARTWORK");moodIcon:SetSize(15,15);moodIcon:SetPoint("TOPLEFT",326,-34)
    local mood=label(12,T.good,345,-34)
    local moodHover=CreateFrame("Frame",nil,frame)
    moodHover:SetPoint("TOPLEFT",324,-27);moodHover:SetSize(122,28);moodHover:EnableMouse(true)
    local petState="unknown"
    moodHover:SetScript("OnEnter",function(self)
        GameTooltip:SetOwner(self,"ANCHOR_TOP");GameTooltip:SetText(L.PET,1,0.82,0.42)
        GameTooltip:AddLine(L["PET_"..petState],0.79,0.85,0.84,true)
        GameTooltip:AddLine(L["PET_HINT_"..petState],0.79,0.85,0.84,true);GameTooltip:Show()
    end)
    moodHover:SetScript("OnLeave",function()GameTooltip:Hide()end)
    local view={frame=root}
    local groupLayout=ns.HunterActionModel.GroupLayout(preview and 5 or 0,preview and #ns.HunterActionModel.PetActionOrder or 0)
    local function groupBox(title)
        local group=CreateFrame("Frame",nil,root)
        group:SetSize(1,56);group:SetClampedToScreen(true);UI.DecorateGroup(group)
        group.title=UI.Text(group,9,T.muted);group.title:SetJustifyH("CENTER")
        group.title:SetPoint("TOPLEFT",16,-4);group.title:SetPoint("TOPRIGHT",-6,-4);group.title:SetText(title)
        group:Hide()
        return group
    end
    local aspectGroup=groupBox(L.ASPECTS)
    local petGroup=groupBox(L.PET)
    UI.MakeGroupMovable(aspectGroup,"aspectGroup")
    UI.MakeGroupMovable(petGroup,"petGroup")
    view.groups={aspects=aspectGroup,pet=petGroup}
    local menu=UI.CreateIconButton(petGroup,nil,true);menu:SetSize(36,36);menu.icon:SetTexture(T.icons.bag)
    UI.Tooltip(menu,L.FOOD,preview and L.PREVIEW_HINT or nil)
    menu:SetScript("OnClick",function()if not preview and ns.HunterFeed then ns.HunterFeed.ShowMenu(menu)end end)
    if preview then
        for index=1,5 do
            local sample=UI.CreateIconButton(aspectGroup,nil,true);sample:SetSize(32,32)
            sample.icon:SetTexture(index==2 and (ns.Read.Call(C_Spell and C_Spell.GetSpellTexture,14322)or T.icons.hunter)or T.icons.hunter)
            sample:SetPoint("TOPLEFT",aspectGroup,"TOPLEFT",groupLayout.aspects.actions[index],-18)
        end
        for index, key in ipairs(ns.HunterActionModel.PetActionOrder) do
            local sample=UI.CreateIconButton(petGroup,nil,true);sample:SetSize(32,32)
            local spellID = ns.HunterActionModel.PetSpells[key][1]
            sample.icon:SetTexture(ns.Read.Call(C_Spell and C_Spell.GetSpellTexture, spellID) or T.icons.pet)
            local label = key == "markAttack" and L.HUNTER_MARK_ATTACK or ns.Read.Call(C_Spell and C_Spell.GetSpellName, spellID)
            UI.Tooltip(sample, label or L.PET, L.PREVIEW_HINT)
            sample:SetPoint("TOPLEFT",petGroup,"TOPLEFT",groupLayout.pet.actions[index],-18)
        end
        local previewFeed=UI.CreateIconButton(petGroup,nil,true);previewFeed:SetSize(36,36);previewFeed.icon:SetTexture(T.icons.food)
        previewFeed:SetPoint("TOPLEFT",petGroup,"TOPLEFT",groupLayout.pet.feed,-16);UI.Tooltip(previewFeed,L.FEED,L.PREVIEW_HINT)
    end
    UI.MakeMovable(root,"hunter")
    function view.SetToolbar(layout,config)
        local function apply()
            if InCombatLockdown()then return false end
            local aspectsPosition=config and config.aspectGroup.position or {x=layout.aspects.x,y=layout.aspects.y}
            local petPosition=config and config.petGroup.position or {x=layout.pet.x,y=layout.pet.y}
            aspectGroup:SetSize(math.max(1,layout.aspects.width),56)
            aspectGroup:ClearAllPoints();aspectGroup:SetPoint("TOPLEFT",root,"TOPLEFT",aspectsPosition.x,aspectsPosition.y)
            petGroup:SetSize(layout.pet.width,56)
            petGroup:ClearAllPoints();petGroup:SetPoint("TOPLEFT",root,"TOPLEFT",petPosition.x,petPosition.y)
            aspectGroup:SetShown(config and config.aspectGroup.enabled and layout.aspects.width>0)
            petGroup:SetShown(config and config.petGroup.enabled)
            menu:ClearAllPoints();menu:SetPoint("TOPLEFT",petGroup,"TOPLEFT",layout.pet.food,-16)
            return true
        end
        ns.CombatQueue.Request("hunterGroups",apply)
    end
    if preview then view.SetToolbar(groupLayout,ns.db.hunter)end
    function view.Render(data)
        local zone=data.zone or "unknown"
        range:SetText(L["ZONE_"..zone])
        hint:SetText(L["HINT_"..zone])
        local color=zone=="ranged" and T.good or zone=="deadzone" and {1,0.35,0.27,1} or zone=="melee" and T.goldLight or T.muted
        hint:SetTextColor(unpack(color))
        ammo:SetText(data.ammoCount and ns.Format.Number(data.ammoCount) or "–")
        ammo:SetTextColor(unpack(data.ammoLow and {1,0.35,0.27,1} or T.text))
        ammoIcon:SetTexture(data.ammoIcon or T.icons.ammo)
        local state=data.petState or "unknown";petState=state
        mood:SetText(L["PET_"..state])
        mood:SetTextColor(unpack(state=="happy" and T.good or state=="unhappy" and {1,0.35,0.27,1} or T.muted))
        local atlas=({unhappy="UI-PetMad",content="UI-PetNeutral",happy="UI-PetHappiness"})[state]
        if atlas and C_Texture and C_Texture.GetAtlasInfo(atlas) then moodIcon:SetAtlas(atlas)
        else moodIcon:SetTexture(T.icons.pet)end
        moodIcon:SetDesaturated(state=="missing" or state=="dead")
    end
    root:Hide()
    return view
end
