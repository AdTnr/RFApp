-- Brief: RF Logo display app - draws branded logo centered in its grid cell

local M = {}

local config = loadScript("/WIDGETS/RFApp/config.lua", "tcd")() -- imports logo native size and theme config

function M.draw(wgt, x, y, w, h)
    -- Draw signpost shape: rectangle body with triangle pointer on the right
    local pointerWidth = math.max(8, math.floor(h * 0.4)) -- Triangle width based on height
    local bodyWidth = w - pointerWidth
    
    -- Draw rectangular body (left portion)
    lcd.drawFilledRectangle(x, y, bodyWidth, h, COLOR_THEME_FOCUS)
    --lcd.drawRectangle(x, y, bodyWidth, h, COLOR_THEME_PRIMARY1, 1)
    
    -- Draw triangle pointer on the right (pointing right)
    local triX = x + bodyWidth
    local triY1 = y
    local triY2 = y + h
    local triX2 = x + w
    local triYMid = y + math.floor(h / 2)
    -- Draw filled triangle pointing right
    lcd.drawFilledTriangle(triX, triY1, triX2, triYMid, triX, triY2, COLOR_THEME_FOCUS)
    --lcd.drawLine(triX, triY1, triX2, triYMid, SOLID, COLOR_THEME_PRIMARY1, 1)
    --lcd.drawLine(triX2, triYMid, triX, triY2, SOLID, COLOR_THEME_PRIMARY1, 1)
    
    if not wgt.rfLogo then return end -- bitmap loaded in main.lua (Bitmap.open("/WIDGETS/RFApp/RF.png"))

    -- Native bitmap size (in pixels) from config; used to compute uniform scaling
    local bw = config.RF_LOGO_W or 52
    local bh = config.RF_LOGO_H or 32

    -- Compute scale percentage that fits the logo inside the rectangular body while preserving aspect ratio
    local sx = (bodyWidth * 100) / bw
    local sy = (h * 100) / bh
    local scale = math.floor(math.min(sx, sy) * 0.6) -- reduce ~40% to leave padding inside the rectangle
    if scale < 1 then scale = 1 end            -- never scale below 1%

    -- Compute the on-screen width/height after scaling and center within the rectangular body
    local sw = math.floor(bw * scale / 100)
    local sh = math.floor(bh * scale / 100)
    local cx = x + math.floor((bodyWidth - sw) / 2)
    local cy = y + math.floor((h - sh) / 2)

    -- Draw the bitmap centered in the rectangular body portion
    lcd.drawBitmap(wgt.rfLogo, cx, cy, scale)
end

return M


