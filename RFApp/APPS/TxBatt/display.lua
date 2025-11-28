-- Brief: 1x1 grid TX battery monitor with compact icon and percent

local M = {}

local function getTxVoltage()
    local fi = getFieldInfo and (getFieldInfo("tx-voltage") or getFieldInfo("tx-volts"))
    if fi and fi.id then return getValue(fi.id) end
    return getValue("tx-voltage") or getValue("tx-volts")
end

local function colorForPercent(p)
    if p <= 15 then return RED
    elseif p <= 35 then return ORANGE
    elseif p <= 60 then return YELLOW
    else return GREEN end
end

-- Draw a small battery icon with a cathode and dynamic fill
local function drawTinyBattery(x, y, w, h, p)
    lcd.drawRectangle(x, y, w, h, COLOR_THEME_PRIMARY1, 1)
    local cathW = math.max(3, math.floor(w * 0.08))
    local bodyW = w - cathW - 1
    -- make the battery slimmer vertically (~70% of available height) and center it
    local bodyH = math.max(8, math.floor(h * 0.7))
    local bodyX = x + 1
    local bodyY = y + math.floor((h - bodyH) / 2)
    -- body outline
    lcd.drawRectangle(bodyX, bodyY, bodyW, bodyH, COLOR_THEME_PRIMARY2, 2)
    -- cathode
    lcd.drawFilledRectangle(x + w - cathW, y + math.floor(h/2) - math.floor(bodyH*0.18), cathW, math.floor(bodyH*0.36), COLOR_THEME_PRIMARY2)
    -- fill
    local innerW = bodyW - 4
    local innerH = bodyH - 4
    local fillW = math.max(0, math.floor(innerW * (p / 100)))
    local fx = bodyX + 2
    local fy = bodyY + 2
    lcd.drawFilledRectangle(fx, fy, fillW, innerH, colorForPercent(p))
    -- percent text centered inside battery
    local pct = string.format("%d%%", p)
    local textColor = (p > 40) and lcd.RGB(0,0,0) or lcd.RGB(255,255,255)
    lcd.drawText(fx + math.floor(innerW/2), fy + math.floor(innerH/2), pct, BOLD + CENTER + VCENTER + textColor)
end

local cfg = loadScript("/WIDGETS/RFApp/config.lua", "tcd")()

function M.draw(wgt, x, y, w, h)
    -- safe bounds
    if w < 20 or h < 20 then return end

    local v = getTxVoltage()
    if not v then v = 0 end

    -- thresholds (defaults for 2S Li-Ion)
    local minV = (cfg and cfg.TXBATT_MIN) or 6.6
    local maxV = (cfg and cfg.TXBATT_MAX) or 8.4
    if maxV <= minV then maxV = minV + 0.1 end
    local p = math.floor(((v - minV) / (maxV - minV)) * 100 + 0.5)
    if p < 0 then p = 0 elseif p > 100 then p = 100 end

    -- layout: full-width icon (percentage rendered inside)
    local pad = 1
    local iconW = w - 2*pad - 8
    local iconH = h - 2*pad
    local iconX = x + pad + 2
    local iconY = y + pad + 1
    drawTinyBattery(iconX, iconY, iconW, iconH, p)
    
    
end

return M


