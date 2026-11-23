local _, ns = ...
ns.UI = ns.UI or {}
ns.Theme = {
    background={0.021,0.081,0.103,0.98}, inset={0.012,0.045,0.058,1},
    gold={0.83,0.63,0.27,1}, goldLight={1,0.82,0.42,1}, goldDark={0.27,0.17,0.055,1},
    text={0.79,0.85,0.84,1}, muted={0.53,0.65,0.65,1}, teal={0.16,0.79,0.79,1},
    good={0.48,0.82,0.48,1}, xp={0.16,0.62,0.62,1}, quest={0.82,0.59,0.22,1}, rested={0.22,0.39,0.68,1}, restedText={0.57,0.75,0.96,1},
    font=STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF",
    icons={hunter=132222,ammo=132382,pet=132161,food=133974,bag=133633,settings=134063,xp=134400},
}

local T = ns.Theme
local gold = {
    edge = T.gold,
    light = T.goldLight,
    dark = T.goldDark,
    shadow = {0.47, 0.32, 0.11, 1},
}
local palette = gold
local accents = setmetatable({}, {__mode = "k"})

local function playerPalette()
    if type(UnitClass) ~= "function" then return end
    local _, class = UnitClass("player")
    if not class then return end
    local R = ns.Read
    local color = R.Call(C_ClassColor and C_ClassColor.GetClassColor, class)
        or (RAID_CLASS_COLORS and RAID_CLASS_COLORS[class])
    if not color then return end
    local r, g, b = R.Number(color.r), R.Number(color.g), R.Number(color.b)
    if not r or not g or not b then return end
    return {
        edge = {r, g, b, 1},
        light = {0.24 + r * 0.76, 0.24 + g * 0.76, 0.24 + b * 0.76, 1},
        dark = {0.035 + r * 0.28, 0.035 + g * 0.28, 0.035 + b * 0.28, 1},
        shadow = {0.035 + r * 0.53, 0.035 + g * 0.53, 0.035 + b * 0.53, 1},
    }
end

local function paintAccent(texture, accent)
    local color = palette[accent.shade]
    texture:SetColorTexture(color[1], color[2], color[3], accent.opacity)
end

function T.BindAccent(texture, shade, opacity)
    local accent = {shade = shade, opacity = opacity or 1}
    accents[texture] = accent
    paintAccent(texture, accent)
end

function T.SetClassAccent(enabled)
    palette = (enabled and playerPalette()) or gold
    for texture, accent in pairs(accents) do paintAccent(texture, accent) end
end
