-- Battery display helpers (moved from lib_battery_monitor_display)

local M = {}
local lcd = lcd
local string = string
local math = math

function M.formatCellVoltageString(cellVoltage, cellCount, cellDetected)
    if cellDetected then
        return string.format("%.2f V (%.0fS)", cellVoltage, cellCount)
    else
        return string.format("%.2f V (?S)", cellVoltage)
    end
end

function M.formatTotalVoltage(voltage)
    return string.format("%.2f V", voltage)
end

function M.formatPercentage(percent)
    return string.format("%.0f%%", percent)
end

function M.formatMah(mah)
    return string.format("%.0f mah", mah)
end

function M.getSecondaryInfoText(wgt)
    if wgt.bat_connected_low == 1 then
        return "Bat Connected Low"
    elseif wgt.useSensorM then
        return M.formatMah(wgt.vMah)
    else
        return nil
    end
end

local function getPercentColor(wgt)
    if wgt.vPercent <= 20 then return RED
    elseif wgt.vPercent <= 40 then return ORANGE
    elseif wgt.vPercent <= 60 then return YELLOW
    elseif wgt.vPercent <= 80 then return lcd.RGB(160, 255, 0)
    else return GREEN end
end

local function getBatteryFillColor(wgt)
    if wgt.bat_connected_low == 1 then return RED else return getPercentColor(wgt) end
end

local function drawBattery(wgt, myBatt)
    local fill_color = getBatteryFillColor(wgt)
    local pcntY = math.floor(wgt.vPercent / 100 * (myBatt.h - myBatt.cath_h))
    local rectY = wgt.zone.y + myBatt.y + myBatt.h - pcntY
    lcd.drawFilledRectangle(wgt.zone.x + myBatt.x, rectY, myBatt.w, pcntY, fill_color)
    lcd.drawLine(wgt.zone.x + myBatt.x, rectY, wgt.zone.x + myBatt.x + myBatt.w - 1, rectY, SOLID, wgt.cell_color)
    lcd.drawRectangle(wgt.zone.x + myBatt.x, wgt.zone.y + myBatt.y + myBatt.cath_h, myBatt.w, myBatt.h - myBatt.cath_h, wgt.cell_color, 2)
end

function M.drawEighthMonitor(wgt, x, y, w, h)
    local prevZone = wgt.zone
    wgt.zone = { x = x, y = y, w = w, h = h }
    local myBatt = { ["x"] = 2, ["y"] = 2, ["w"] = wgt.zone.w - 4, ["h"] = wgt.zone.h - 4, ["segments_w"] = 25, ["cath_w"] = 6, ["cath_h"] = 20 }
    local fill_color = getBatteryFillColor(wgt)
    lcd.drawGauge(wgt.zone.x + myBatt.x, wgt.zone.y + myBatt.y, myBatt.w, myBatt.h, wgt.vPercent, 100, fill_color)
    lcd.drawRectangle(wgt.zone.x + myBatt.x, wgt.zone.y + myBatt.y, myBatt.w, myBatt.h, wgt.text_color, 2)
    -- Dynamic text color for info lines: black above 50%, white at/below 50%
    local infoColor = (wgt.vPercent and wgt.vPercent > 40) and lcd.RGB(0, 0, 0) or lcd.RGB(255, 255, 255)
    local volts = string.format("%s / %s", M.formatTotalVoltage(wgt.vTotalLive), M.formatCellVoltageString(wgt.vCellLive, wgt.cellCount, wgt.cell_detected))
    lcd.drawText(wgt.zone.x + myBatt.x + 8, wgt.zone.y + myBatt.y + 4, volts, BOLD + LEFT + infoColor)
    local secondaryInfo = M.getSecondaryInfoText(wgt)
    if secondaryInfo then
        lcd.drawText(wgt.zone.x + myBatt.x + 8, wgt.zone.y + myBatt.y + 22, secondaryInfo, BOLD  + LEFT + infoColor)
    end
    lcd.drawText(
        wgt.zone.x + myBatt.x + myBatt.w - 4,
        wgt.zone.y + myBatt.y,
        M.formatPercentage(wgt.vPercent),
        BOLD + RIGHT + DBLSIZE + wgt.text_color
    )
    local reserveVal = wgt.vReserve or 0
    local reserveTxt = string.format("Reserve %d%%", reserveVal)
    lcd.drawText(wgt.zone.x + myBatt.x + 8, wgt.zone.y + myBatt.y + myBatt.h - 18, reserveTxt, LEFT + SMLSIZE + infoColor)
    wgt.zone = prevZone
end

return M


