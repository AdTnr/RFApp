-- Brief: RPM display widget showing Hspd telemetry in a 2x2 grid space

local M = {}

function M.draw(wgt, x, y, w, h)
    if w < 20 or h < 20 then return end
    
    local rpm = wgt.rpmValue or 0
    
    -- Format RPM value with comma separator for readability
    local rpmStr = string.format("%d", math.floor(rpm))
    
    -- Draw background
    --lcd.drawFilledRectangle(x, y, w, h, COLOR_THEME_SECONDARY1)
    --lcd.drawRectangle(x, y, w, h, COLOR_THEME_PRIMARY1, 1)
    
    -- Draw label "RPM" at top
    lcd.drawText(x , y, "RPM", SMLSIZE + LEFT + COLOR_THEME_PRIMARY2)
    
    -- Draw RPM value centered, large and bold
    lcd.drawText(x + w, y, rpmStr, MIDSIZE + BOLD + RIGHT + COLOR_THEME_PRIMARY2)
end

return M

