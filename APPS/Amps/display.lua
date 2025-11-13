-- Brief: Current (Amps) display widget showing Curr telemetry with max

local M = {}
local lcd = lcd
local math = math

-- Color gradient function matching battery monitor (green to red)
local function getAmpsPercentColor(percent)
    if percent <= 20 then return GREEN
    elseif percent <= 40 then return lcd.RGB(160, 255, 0)
    elseif percent <= 60 then return YELLOW
    elseif percent <= 80 then return ORANGE
    else return RED end
end

function M.draw(wgt, x, y, w, h)
    if w < 20 or h < 20 then return end
    
    local amps = wgt.ampsValue or 0
    local ampsMax = wgt.ampsMax or amps
    
    -- Format current value (1 decimal place)
    local ampsStr = string.format("%.1fA", amps)
    local maxStr = string.format("Max %.1fA", ampsMax)
    
    -- Format horsepower (ensure it exists and handle nil)
    local hpower = wgt.hpower or 0
    local hpowerStr = string.format("%.1fHP", hpower)
    
    -- Format power: use kW if over 999W, otherwise use W
    local power = wgt.powerValue or 0
    local powerStr
    if power > 999 then
        local powerKW = power / 1000
        powerStr = string.format("%.1fkW", powerKW)
    else
        powerStr = string.format("%.0fW", power)
    end
    
    -- Format max power with max horsepower in brackets
    local powerMax = wgt.powerMax or 0
    local hpowerMax = wgt.hpowerMax or 0
    local maxPowerStr
    if powerMax > 999 then
        local powerMaxKW = powerMax / 1000
        maxPowerStr = string.format("Max %.1fkW (%.1fHP)", powerMaxKW, hpowerMax)
    else
        maxPowerStr = string.format("Max %.0fW (%.1fHP)", powerMax, hpowerMax)
    end
    
    -- Draw background
    --lcd.drawRectangle(x, y, w, h, COLOR_THEME_PRIMARY2, 0)
    local barwidth = 30
    local textoffset = x + barwidth + 10
    -- Draw label "A" at top
    lcd.drawText(textoffset - 4, y, "Current", BOLD + LEFT + COLOR_THEME_PRIMARY2)
    
    -- Draw current value centered, large and bold
    lcd.drawText(textoffset, y + 33, ampsStr, DBLSIZE + LEFT + VCENTER + COLOR_THEME_PRIMARY2)
    
    -- Draw max Amps at bottom (smaller text)
    lcd.drawText(textoffset, y + 45, maxStr, BOLD + LEFT + COLOR_THEME_SECONDARY2)
    lcd.drawText(textoffset - 4, y + 63, "Power", BOLD + LEFT + COLOR_THEME_PRIMARY2)
    lcd.drawText(textoffset, y + 81, powerStr, BOLD + LEFT + COLOR_THEME_PRIMARY2)
    lcd.drawText(textoffset, y + 99, hpowerStr, BOLD + LEFT + COLOR_THEME_PRIMARY2)
    lcd.drawText(textoffset, y + 117, maxPowerStr, BOLD + LEFT + COLOR_THEME_SECONDARY2)


    -- Bar visualization
    local pad = 2
    local barX = x + pad
    local barY = y + pad
    local barH = h - pad
    local borderWidth = 2
    
    -- Draw bar border
    lcd.drawRectangle(barX, barY, barwidth, barH, COLOR_THEME_PRIMARY2, borderWidth)
    
    -- Calculate fill percentage based on amps relative to ampsMax
    -- Remain empty when amps equals zero
    if amps > 0 and ampsMax > 0 then
        local percent = math.min(100, (amps / ampsMax) * 100)
        local fillHeight = math.floor(percent / 100 * barH)
        
        if fillHeight > 0 then
            -- Fill from bottom to top
            local fillY = barY + barH - fillHeight
            local fillColor = getAmpsPercentColor(percent)
            lcd.drawFilledRectangle(barX + borderWidth, fillY + borderWidth, barwidth - borderWidth*2, fillHeight - borderWidth*2, fillColor)
        end
    end
end

return M

