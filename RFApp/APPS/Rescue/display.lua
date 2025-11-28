-- Rescue state display (1x1 grid)

local M = {}

function M.draw(wgt, x, y, w, h)
    if w < 20 or h < 20 then return end

    local label = (wgt and wgt.rescueLabel) or "UNK"
    local bg = (wgt and wgt.rescueBg) or COLOR_THEME_PRIMARY2
    local fg = (wgt and wgt.rescueFg) or COLOR_THEME_PRIMARY1

    lcd.drawFilledRectangle(x, y, w, h, bg)
    lcd.drawRectangle(x, y, w, h, COLOR_THEME_PRIMARY1, 1)

    lcd.drawText(x + 2, y - 2, "Resc", SMLSIZE + LEFT + fg)
    lcd.drawText(x + w / 2, y + h / 2 + 4, label, BOLD + CENTER + VCENTER + fg)
end

return M


