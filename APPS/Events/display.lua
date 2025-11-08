-- Brief: Events display - shows last two events in small text, bottom-left grid cell

local M = {}

local events = loadScript("/WIDGETS/RFApp/APPS/Events/store.lua", "tcd")()

function M.draw(wgt, x, y, w, h)
    local pad = 0
    local x0 = x + pad
    local y0 = y + pad
    -- No header; pack as many lines as fit, no top/bottom padding
    local lineHeight = 10
    local maxLines = math.max(1, math.floor(h / lineHeight))
    local lines = events.getLast(maxLines) -- newest first
    for i = 1, #lines do
        local yy = y0 + (i - 1) * lineHeight
        if yy + lineHeight > y + h then break end
        lcd.drawText(x0, yy, lines[i], LEFT + SMLSIZE + COLOR_THEME_PRIMARY2)
    end
end

-- Full-screen overlay showing as many events as fit the screen height
function M.drawFull(wgt)
    -- dim background
    lcd.drawFilledRectangle(0, 0, LCD_W, LCD_H, COLOR_THEME_PRIMARY2)
    -- pack lines tightly, newest first
    local lineHeight = 12
    local pad = 8
    local maxLines = math.max(1, math.floor((LCD_H - pad - 4) / lineHeight))
    local lines = events.getLast(maxLines)
    local y0 = pad
    for i = 1, #lines do
        local yy = y0 + (i - 1) * lineHeight
        if yy + lineHeight > LCD_H then break end
        lcd.drawText(6, yy, lines[i], LEFT + SMLSIZE + COLOR_THEME_PRIMARY1)
    end
end

return M


