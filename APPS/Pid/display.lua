-- Brief: 1x1 grid widget showing active PID profile from telemetry

local M = {}

local function normalizeValue(val)
    if type(val) ~= "number" then return nil end
    local v = math.floor(val + 0.5)
    if v < 0 then
        v = 0
    elseif v > 6 then
        v = 6
    end
    return v
end

local function formatValue(val)
    local v = normalizeValue(val)
    if v == nil then return "--" end
    return string.format("%d", v)
end

function M.draw(wgt, x, y, w, h)
    if w < 20 or h < 20 then return end

    local telem = (wgt and wgt.telem) or {}
    local pidVal = telem.pid
    local rateVal = telem.rate

    local labelStyle = BOLD + LEFT + COLOR_THEME_PRIMARY2
    local valueStyle = BOLD + RIGHT + COLOR_THEME_PRIMARY2

    local topY = y - 1
    local bottomY = y + math.max(12, math.floor(h / 2)) - 1

    lcd.drawText(x + 2, topY, "PID", labelStyle)
    lcd.drawText(x + w - 2, topY, formatValue(pidVal), valueStyle)

    lcd.drawText(x + 2, bottomY, "RATE", labelStyle)
    lcd.drawText(x + w - 2, bottomY, formatValue(rateVal), valueStyle)
end

return M