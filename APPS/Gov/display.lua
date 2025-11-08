-- Brief: Governor state display showing one word in bold

local M = {}

function M.draw(wgt, x, y, w, h)
    if w < 20 or h < 20 then return end
    
    local state = wgt.govState or "UNKNOWN"
    local govValue = wgt.govValue or -1
    
    -- Determine background color based on governor state
    local bgColor = COLOR_THEME_SECONDARY1 -- default
    if govValue == 0 then      -- GOV OFF
        bgColor = lcd.RGB(60, 60, 60)  -- Dark grey
    elseif govValue == 1 then   -- IDLE
        bgColor = COLOR_THEME_SECONDARY1  -- Neutral
    elseif govValue == 2 then   -- SPOOLUP
        bgColor = YELLOW  -- Starting up
    elseif govValue == 3 then   -- RECOVERY
        bgColor = YELLOW  -- Recovering
    elseif govValue == 4 then   -- ACTIVE
        bgColor = GREEN  -- Good/active state
    elseif govValue == 5 then   -- HOLD
        bgColor = ORANGE  -- Throttle off
    elseif govValue == 6 then   -- FALLBACK
        bgColor = RED  -- Error/problem
    elseif govValue == 7 then   -- AUTO
        bgColor = lcd.RGB(0, 150, 255)  -- Cyan/Blue for autorotation
    elseif govValue == 8 then   -- BAILOUT
        bgColor = ORANGE  -- Recovery mode
    elseif govValue == 9 then   -- BYPASS
        bgColor = lcd.RGB(80, 80, 80)  -- Grey (disabled)
    end
    
    -- Draw background with state-appropriate color
    lcd.drawFilledRectangle(x, y, w, h, bgColor)
    lcd.drawRectangle(x, y, w, h, COLOR_THEME_PRIMARY1, 1)
    
    -- Draw state word in bold, centered
    lcd.drawText(x + w / 2, y + h / 2, state, BOLD + CENTER + VCENTER + COLOR_THEME_PRIMARY2)
end

return M

