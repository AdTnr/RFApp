-- ARM status display

local M = {}

function M.draw(wgt, x, y, w, h)
    local state = wgt.armState or "UNKNOWN"
    local label = (state == "SAFE") and "SAFE" or state
    local bg = COLOR_THEME_PRIMARY2
    local fg = COLOR_THEME_PRIMARY1
    -- Colors: SAFE (disarmed) green, ARMED red
    if state == "ARMED" then
        bg = RED
    elseif state == "SAFE" then
        bg = GREEN
    end
    lcd.drawFilledRectangle(x, y, w, h, bg)
    lcd.drawRectangle(x, y, w, h, COLOR_THEME_PRIMARY1, 1)
    lcd.drawText(x + w / 2, y + h / 2, label, BOLD + CENTER + VCENTER + fg)
    -- small subtitle with extra info (e.g., "prearm" or "was armed")
    if wgt.armInfo and wgt.armInfo ~= "" then
    --    lcd.drawText(x + w / 2, y + h / 2 + 12, wgt.armInfo, SMLSIZE + CENTER + COLOR_THEME_PRIMARY1)
    end
end

return M


