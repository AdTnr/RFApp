-- Brief: RPM display widget showing Hspd telemetry in a 2x2 grid space with min/max

local M = {}

function M.draw(wgt, x, y, w, h)
    if w < 20 or h < 20 then return end
    
    local rpm = wgt.rpmValue or 0
    local rpmMin = wgt.rpmMin or rpm
    local rpmMax = wgt.rpmMax or rpm
    
    -- Format RPM values (RPM values are always integers)
    local rpmStr = string.format("%d", rpm)
    local minStr = string.format("%d Min", rpmMin)
    local maxStr = string.format("Max %d", rpmMax)
    
    -- Draw background
    --lcd.drawFilledRectangle(x, y, w, h, COLOR_THEME_SECONDARY1)
    lcd.drawRectangle(x, y, w, h, COLOR_THEME_PRIMARY2, 1)
    
    -- Draw label "RPM" at top
    lcd.drawText(x + w/2, y + h - 18, "RPM", BOLD + CENTER + COLOR_THEME_PRIMARY2)
    lcd.drawText(x + w/2, y + h/2 - 5, rpmStr, DBLSIZE + BOLD + CENTER + VCENTER + COLOR_THEME_PRIMARY2)
    -- Draw min/max RPM at bottom (smaller text)
    lcd.drawText(x + 2, y + h - 18, minStr, BOLD + COLOR_THEME_SECONDARY2)
    lcd.drawText(x + w - 2, y + h - 18, maxStr, BOLD + RIGHT + COLOR_THEME_SECONDARY2)
end

return M

