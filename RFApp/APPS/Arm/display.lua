-- ARM status display

local M = {}

function M.draw(wgt, x, y, w, h)
    if w < 20 or h < 20 then return end

    local state = wgt.armState or "UNK"
    local bg = wgt.armBg or COLOR_THEME_SECONDARY1
    local fg = wgt.armFg or COLOR_THEME_PRIMARY2
    local isArmed = wgt.isArmed or false

    -- Flash background when armed (alternate between normal bg and brighter color)
    if isArmed then
        local currentTime = getTime()
        local flashRate = 100 -- Flash every 10 ticks (10 * 10ms = 100ms)
        local flashState = (currentTime // flashRate) % 2
        
        if flashState == 0 then
            -- Normal background (already RED from state map)
            -- bg stays as is
        else
            -- Flashing background - alternate to brighter color for visibility
            bg = BLACK -- Flash with yellow for high visibility
        end
    end

    -- Draw background with state-appropriate color (flashing if armed)
    lcd.drawFilledRectangle(x, y, w, h, bg)
    lcd.drawRectangle(x, y, w, h, COLOR_THEME_PRIMARY1, 1)

    -- Draw state word in bold, centered
    lcd.drawText(x + w / 2, y + h / 2, state, BOLD + CENTER + VCENTER + fg)
end

return M


