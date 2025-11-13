-- Brief: 1x1 grid RSSI signal strength widget with bars and percent

local M = {}

local function colorForRssi(p)
    if p <= 20 then return RED
    elseif p <= 40 then return ORANGE
    elseif p <= 70 then return YELLOW
    else return GREEN end
end

local function drawBars(x, y, w, h, p)

    -- 5 rounded bars (pills), increasing height
    local gap = 5
    local bars = 5
    local barW = math.max(3, math.floor((w - (bars - 1) * gap) / bars))
    if barW < 1 then barW = 1 end
    local totalWidth = bars * barW + (bars - 1) * gap
    local startX = x + math.floor((w - totalWidth) / 2)
    if startX < x then startX = x end
    local baseY = y + h - 1
    local stepH = math.max(6, math.floor(h / (bars + 1)))
    local active = math.floor((p / 100) * bars + 0.5)
    for i = 1, bars do
        local bh = stepH * i
        local bx = startX + (i - 1) * (barW + gap)
        local by = baseY - bh
        -- inactive: dark grey; active: bright white
        local clr = (i <= active) and lcd.RGB(255, 255, 255) or lcd.RGB(90, 90, 90)
        -- Rounded pill (filled only, no border)
        local r = math.min(math.floor(barW / 2), math.floor(bh / 2))
        if r < 1 then
            lcd.drawFilledRectangle(bx, by, barW + 1, bh, clr)
        else
            local midH = bh - 2 * r
            if midH > 0 then
                lcd.drawFilledRectangle(bx, by + r, barW + 1, midH, clr)
            end
            lcd.drawFilledCircle(bx + r, by + r, r, clr)
            lcd.drawFilledCircle(bx + r, by + bh - r, r, clr)
        end
    end
end

function M.draw(wgt, x, y, w, h)
    if w < 20 or h < 20 then return end
    -- Get RSSI from shared telemetry module
    local rssi = (wgt.telem and wgt.telem.rssi) or 0
    if rssi < 0 then rssi = 0 elseif rssi > 100 then rssi = 100 end

    -- Determine if RotorFlight telemetry is established (uses global rfConnected flag from telemetry.lua)
    local telemetryEstablished = (wgt.rfConnected == true)
    local rflColor = telemetryEstablished and GREEN or lcd.RGB(90, 90, 90)

    -- Draw "RFL" text in top-left corner
    lcd.drawText(x, y-1, "RFL", SMLSIZE + LEFT + rflColor)

    -- Full-bleed bars filling the grid cell
    local pad = 2
    drawBars(x + pad, y, w - 2 * pad, h, rssi)
end

return M


