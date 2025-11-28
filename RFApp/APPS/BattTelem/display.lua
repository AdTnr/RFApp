-- Brief: Raw battery telemetry display widget (compact, 2x2 grid)

local M = {}

local function formatValue(val, pattern, suffix)
    if val == nil then return "--" end
    local text
    if pattern then
        text = string.format(pattern, val)
    else
        text = tostring(val)
    end
    if suffix then
        text = text .. suffix
    end
    return text
end

local function asNumber(val)
    if type(val) == "number" then return val end
    return nil
end

function M.draw(wgt, x, y, w, h)
    if w < 40 or h < 40 then return end

    local telem = (wgt and wgt.telem) or {}
    local lineHeight = 14
    local cy = y

    lcd.drawText(x, cy, "Batt Telemetry", SMLSIZE + LEFT + COLOR_THEME_PRIMARY2)
    cy = cy + lineHeight

    local lines = {
        string.format("Volt: %s", formatValue(asNumber(telem.volt) and (math.floor(telem.volt * 100 + 0.5) / 100), "%.2f", "V")),
        string.format("Cells: %s", formatValue(asNumber(telem.cells), "%.0f")),
        string.format("Bat%%: %s", formatValue(asNumber(telem.pcnt), "%.0f", "%")),
        string.format("mAh: %s", formatValue(asNumber(telem.mah), "%.0f")),
        string.format("RSSI: %s", formatValue(asNumber(telem.rssi), "%.0f")),
        string.format("ARM: %s", formatValue(asNumber(telem.arm), "%.0f")),
        string.format("Src: %s", tostring(wgt and wgt.options and wgt.options.source_name or "")),
    }

    for _, line in ipairs(lines) do
        if cy + lineHeight > y + h then break end
        lcd.drawText(x, cy, line, SMLSIZE + LEFT + COLOR_THEME_PRIMARY2)
        cy = cy + lineHeight
    end
end

return M


