local _, ns = ...
local UI, T, L, F = ns.UI, ns.Theme, ns.L, ns.Format
local StatsView = {}
ns.StatsView = StatsView

local panel
local goldRows = {
    {label = L.STATS_BALANCE, key = "balance"},
    {label = L.STATS_GOLD_INCOME, key = "income", signed = true, tooltip = true},
    {label = L.STATS_GOLD_EXPENSES, key = "expenses", signed = true, debit = true, tooltip = true},
    {label = L.STATS_GOLD_NET, key = "net", signed = true, tooltip = true},
    {label = L.STATS_GOLD_RATE, key = "perHour", signed = true, tooltip = true},
    {label = L.STATS_MERCHANT_SALES, key = "merchantSales", signed = true},
    {label = L.STATS_MERCHANT_REPAIRS, key = "merchantRepairs", signed = true, debit = true},
}

local function goldSnapshot()
    return ns.GoldStats and ns.GoldStats.Snapshot() or {}
end

local function goldText(data, row)
    local amount = data[row.key]
    if amount == nil then return F.Number(nil) end
    if row.debit then amount = -amount end
    local copper = math.floor(math.abs(amount) + 0.5)
    local sign = ""
    if row.signed and copper > 0 then sign = amount < 0 and "-" or "+" end
    local text = ns.Read.Call(C_CurrencyInfo and C_CurrencyInfo.GetCoinTextureString or GetCoinTextureString, copper, 11)
    if type(text) ~= "string" or text == "" then
        text = string.format("%s|TInterface\\MoneyFrame\\UI-GoldIcon:11|t %d|TInterface\\MoneyFrame\\UI-SilverIcon:11|t %d|TInterface\\MoneyFrame\\UI-CopperIcon:11|t",
            F.Number(math.floor(copper / 10000)), math.floor(copper / 100) % 100, copper % 100)
    end
    return sign .. text
end

function StatsView.ShowGoldTooltip(owner)
    local data = goldSnapshot()
    GameTooltip:SetOwner(owner, "ANCHOR_TOP")
    GameTooltip:SetText(L.STATS_GOLD, T.goldLight[1], T.goldLight[2], T.goldLight[3])
    local label, value = T.muted, T.text
    for _, row in ipairs(goldRows) do
        if row.tooltip then
            GameTooltip:AddDoubleLine(row.label, goldText(data, row), label[1], label[2], label[3], value[1], value[2], value[3])
        end
    end
    GameTooltip:Show()
end

local function makeRow(frame, label, x, y)
    local caption = UI.Text(frame, 11, T.muted)
    caption:SetPoint("TOPLEFT", x, -y)
    caption:SetText(label)
    local value = UI.Text(frame, 11, T.text)
    value:SetPoint("TOPRIGHT", frame, "TOPLEFT", x + 250, -y)
    value:SetJustifyH("RIGHT")
    return value, caption
end

local function heading(frame, text, x, y)
    local label = UI.Text(frame, 14, T.goldLight)
    label:SetPoint("TOPLEFT", x, -y)
    label:SetText(text)
end

local function levelLabel(level)
    return level and L.LEVEL_PREFIX .. " " .. F.Number(level) or L.STATS_CURRENT_LEVEL
end

local function xpText(value)
    return value and F.Number(value) .. " XP" or F.Number(nil)
end

local function build()
    local name = "ForeverUI_SessionStats"
    local frame = UI.CreatePanel(UIParent, name)
    frame:Hide()
    frame:SetSize(580, 358)
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("DIALOG")
    frame:EnableMouse(true)
    table.insert(UISpecialFrames, name)

    local title = UI.Text(frame, 21, T.goldLight)
    title:SetPoint("TOPLEFT", 23, -17)
    title:SetText(L.STATS_TITLE)
    UI.CloseButton(frame, function() frame:Hide() end)

    local left, right = 23, 307
    local divider = UI.Rect(frame, "edge", "BORDER", 0.35)
    divider:SetPoint("TOPLEFT", 289, -57)
    divider:SetSize(1, 277)

    heading(frame, L.EXPERIENCE, left, 55)
    local session = makeRow(frame, L.STATS_SESSION_TIME, left, 80)
    local earned = makeRow(frame, L.STATS_XP_EARNED, left, 98)
    local rate = makeRow(frame, L.STATS_XP_RATE, left, 116)
    local recent, recentLabel = makeRow(frame, "", left, 134)
    local remaining = makeRow(frame, L.STATS_XP_REMAINING, left, 152)
    local eta = makeRow(frame, L.STATS_LEVEL_ETA, left, 170)

    heading(frame, L.STATS_PLAY_TIME, left, 204)
    local request = UI.Button(frame, L.STATS_REQUEST_PLAY_TIME, 132)
    request:SetSize(132, 23)
    request:SetPoint("TOPRIGHT", frame, "TOPLEFT", left + 250, -199)
    request:SetScript("OnClick", function()
        if ns.LevelStats and ns.LevelStats.Request then ns.LevelStats.Request() end
    end)
    local total = makeRow(frame, L.STATS_TOTAL_PLAY_TIME, left, 231)
    local current, currentLabel = makeRow(frame, "", left, 249)
    heading(frame, L.STATS_LEVEL_HISTORY, left, 273)
    local history = {}
    for index = 1, 3 do
        local value, label = makeRow(frame, "", left, 278 + index * 18)
        history[index] = {value = value, label = label}
    end

    heading(frame, L.STATS_GOLD, right, 55)
    local goldValues = {}
    for index, row in ipairs(goldRows) do
        goldValues[index] = makeRow(frame, row.label, right, 80 + (index - 1) * 18)
    end

    local function refresh()
        local xp = ns.XP and ns.XP.GetSummary and ns.XP.GetSummary() or {}
        local levels = ns.LevelStats and ns.LevelStats.Snapshot() or {}
        local gold = goldSnapshot()
        session:SetText(F.Duration(xp.elapsed or gold.elapsed))
        earned:SetText(xpText(xp.earned))
        rate:SetText(F.Number(xp.perHour))
        local recentWindow = xp.recentPerHour and xp.recentWindow or 1800
        local recentMinutes = math.max(1, math.floor(recentWindow / 60))
        recentLabel:SetText(L.STATS_XP_RECENT:format(recentMinutes))
        recent:SetText(F.Number(xp.recentPerHour))
        remaining:SetText(xpText(xp.remaining))
        eta:SetText(F.Duration(xp.eta))

        total:SetText(F.Duration(levels.totalTime))
        currentLabel:SetText(levelLabel(levels.level or xp.level))
        local prefix = levels.currentLevelTime and levels.currentLevelTimePartial and "~" or ""
        current:SetText(prefix .. F.Duration(levels.currentLevelTime))
        local completed = levels.history or {}
        for index, row in ipairs(history) do
            local entry = completed[index]
            row.label:SetText(entry and levelLabel(entry.level) or "")
            row.value:SetText(entry and F.Duration(entry.seconds) or (index == 1 and F.Duration(nil) or ""))
        end
        for index, row in ipairs(goldRows) do
            goldValues[index]:SetText(goldText(gold, row))
        end
    end

    local elapsed = 0
    frame:SetScript("OnShow", function()
        elapsed = 0
        refresh()
    end)
    frame:SetScript("OnUpdate", function(_, delta)
        elapsed = elapsed + delta
        if elapsed >= 1 then
            elapsed = elapsed % 1
            refresh()
        end
    end)
    return frame
end

function StatsView.Toggle()
    if not panel then panel = build() end
    panel:SetShown(not panel:IsShown())
end
