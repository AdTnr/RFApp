-- Brief: Current (Amps) display widget showing Curr telemetry with max

local M = {}

function M.draw(wgt, x, y, w, h)
    if w < 20 or h < 20 then return end
    
    local amps = wgt.ampsValue or 0
    local ampsMax = wgt.ampsMax or amps
    
    -- Format current value (1 decimal place)
    local ampsStr = string.format("%.1f A", amps)
    local maxStr = string.format("Max %.1f", ampsMax)
    
    -- Draw background
    --lcd.drawRectangle(x, y, w, h, COLOR_THEME_PRIMARY2, 0)
    
    -- Draw label "A" at top
    lcd.drawText(x + 2, y, "Current", BOLD + LEFT + COLOR_THEME_PRIMARY2)
    
    -- Draw current value centered, large and bold
    lcd.drawText(x + 2, y + h/2, ampsStr, DBLSIZE + LEFT + VCENTER + COLOR_THEME_PRIMARY2)
    
    -- Draw max Amps at bottom (smaller text)
    lcd.drawText(x + 2, y + h - 18, maxStr, BOLD + LEFT + COLOR_THEME_SECONDARY2)

    --Experimental Bar
    --lcd.drawRectangle(x, y, 30, 100, COLOR_THEME_PRIMARY2, 1)
end

return M

