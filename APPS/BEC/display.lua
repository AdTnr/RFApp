-- Brief: BEC voltage display widget showing Vbec telemetry with min

local M = {}

function M.draw(wgt, x, y, w, h)
    if w < 20 or h < 20 then return end
    
    local bec = wgt.becValue or 0
    local becMin = wgt.becMin or bec
    
    -- Format voltage value (2 decimal places)
    local becStr = string.format("%.2f V", bec)
    local minStr = string.format("Min %.2f V", becMin)
    
    -- Draw background
    --lcd.drawRectangle(x, y, w, h, COLOR_THEME_PRIMARY2, 0)
    
    -- Draw label at top
    lcd.drawText(x + w - 2, y, "BEC", BOLD + RIGHT + COLOR_THEME_PRIMARY2)
    
    -- Draw voltage value right-aligned, large and bold
    lcd.drawText(x + w - 2, y + h/2, becStr, DBLSIZE + RIGHT + VCENTER + COLOR_THEME_PRIMARY2)
    
    -- Draw min BEC voltage at bottom (smaller text) - only if enabled
    if wgt.showMaxMinValues ~= false then
        lcd.drawText(x + w - 2, y + h - 18, minStr, BOLD + RIGHT + COLOR_THEME_SECONDARY2)
    end
end

return M

