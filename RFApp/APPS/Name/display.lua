-- Brief: Model name display widget showing current model name

local M = {}

function M.draw(wgt, x, y, w, h)
    if w < 20 or h < 20 then return end
    
    local modelName = wgt.modelName or "Unknown"
    
    -- Draw model name centered
    lcd.drawText(x + w, y + h/2, modelName, DBLSIZE + RIGHT + VCENTER + COLOR_THEME_PRIMARY2)
end

return M

