-- ARM status display

local M = {}

function M.draw(wgt, x, y, w, h)
    if w < 20 or h < 20 then return end

    local state = wgt.armState or "UNK"
    local bg = wgt.armBg or COLOR_THEME_SECONDARY1
    local fg = wgt.armFg or COLOR_THEME_PRIMARY2

    -- Draw background with state-appropriate color
    lcd.drawFilledRectangle(x, y, w, h, bg)
    lcd.drawRectangle(x, y, w, h, COLOR_THEME_PRIMARY1, 1)

    -- Draw state word in bold, centered
    lcd.drawText(x + w / 2, y + h / 2, state, BOLD + CENTER + VCENTER + fg)
end

return M


