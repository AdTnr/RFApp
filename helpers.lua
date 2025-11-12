-- Helper functions for RFApp
-- Extracted from main.lua for better organization

local M = {}

-- Check if widget is in app mode (fullscreen)
function M.isAppMode(wgt, event)
    return (event ~= nil) and (wgt.zone and wgt.zone.w >= LCD_W - 1) and (wgt.zone.h >= LCD_H - 20) and (wgt.zone.x == 0) and (wgt.zone.y == 0)
end

-- Load RF logo bitmap
function M.loadRFLogo()
    if Bitmap and Bitmap.open then
        return Bitmap.open("/WIDGETS/RFApp/RF.png")
    end
    return nil
end

-- Normalize grid span to standard format
function M.normalizeGridSpan(span, defaultSpan, config)
    local src = span or defaultSpan or {}

    local row = src.row or src.r or src.r1 or src[1] or 1
    local col = src.col or src.c or src.c1 or src[3] or 1

    local rows = src.rows or src.rowSpan
    if not rows then
        local r2 = src.r2 or src[2] or row
        rows = (r2 - row + 1)
    end

    local cols = src.cols or src.colSpan
    if not cols then
        local c2 = src.c2 or src[4] or col
        cols = (c2 - col + 1)
    end

    rows = math.max(1, rows or 1)
    cols = math.max(1, cols or 1)

    local maxRows = config.GRID_ROWS or 8
    local maxCols = config.GRID_COLS or 8

    row = math.max(1, math.min(maxRows, row))
    col = math.max(1, math.min(maxCols, col))

    if row + rows - 1 > maxRows then
        rows = maxRows - row + 1
    end
    if col + cols - 1 > maxCols then
        cols = maxCols - col + 1
    end

    return { row = row, rows = rows, col = col, cols = cols }
end

-- Draw widget placeholder for widget mode
function M.drawWidgetPlaceholder(wgt, appVersion)
    local x = wgt.zone.x
    local y = wgt.zone.y
    local w = wgt.zone.w
    local h = wgt.zone.h
    lcd.drawRectangle(x, y, w, h, COLOR_THEME_PRIMARY3)
    lcd.drawText(x + w / 2, y + h / 2 - 12, "RFApp v" .. appVersion, DBLSIZE + CENTER + VCENTER + COLOR_THEME_PRIMARY2)
    lcd.drawText(x + w / 2, y + h / 2 + 18, "Long press to launch", CENTER + VCENTER + COLOR_THEME_PRIMARY2)
end

return M

