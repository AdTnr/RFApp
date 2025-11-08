-- Brief: Minimal UI components (button, dropdown, slider) for in-app settings

local M = {}

function M.newState()
    return {
        settingsOpen = false,  -- Legacy, kept for compatibility
        menuOpen = false,      -- Menu screen open
        settingsScreen = false, -- Settings full-screen overlay
        debugScreen = false,    -- Debug full-screen overlay
        dropdownOpen = false,
        dropdownItems = nil,
        dropdownSelected = 1,
        dropdownRect = { x = 0, y = 0, w = 0, h = 0 },
        dropdownOnSelect = nil,
        activeControl = nil,
        sliderDragging = false,
        focusIndex = 1,
        reserveStart = nil,    -- Track reserve value when opening settings
        debugScroll = 0,       -- Debug screen scroll offset
    }
end

local function inRect(x, y, rx, ry, rw, rh)
    return x >= rx and x <= rx + rw and y >= ry and y <= ry + rh
end

function M.drawButton(x, y, w, h, title, focused)
    lcd.drawFilledRectangle(x, y, w, h, COLOR_THEME_FOCUS)
    lcd.drawRectangle(x, y, w, h, COLOR_THEME_FOCUS, 1)
    lcd.drawText(x + w / 2, y + h / 2, title, BOLD + CENTER + VCENTER + COLOR_THEME_PRIMARY2)
end

function M.handleButton(event, touchState, x, y, w, h)
    if not touchState then return false end
    if event == EVT_TOUCH_TAP and inRect(touchState.x, touchState.y, x, y, w, h) then
        return true
    end
    return false
end

function M.drawDropdownField(x, y, w, h, items, selected)
    lcd.drawRectangle(x, y, w, h, COLOR_THEME_PRIMARY1, 2)
    local text = items[selected] or ""
    lcd.drawText(x + 6, y + h / 2, text, VCENTER + COLOR_THEME_PRIMARY1)
    local dd = 10
    local yy = y + (h - dd) / 2
    local xx = x + w - 1.15 * dd - 4
    lcd.drawTriangle(x + w - 6, yy, (x + w - 6 + xx) / 2, yy + dd, xx, yy, COLOR_THEME_PRIMARY1)
end

function M.handleDropdown(ui, event, touchState, x, y, w, h, items, selected, onSelect)
    -- Tap on field: always open menu for this field/items (replaces any existing menu)
    if touchState and event == EVT_TOUCH_TAP and inRect(touchState.x, touchState.y, x, y, w, h) then
        ui.dropdownOpen = true
        ui.dropdownItems = items
        ui.dropdownSelected = selected
        ui.dropdownRect = { x = x, y = y + h + 4, w = w, h = math.min(#items * 24, math.floor(LCD_H * 0.6)) }
        ui.dropdownOnSelect = onSelect
        return selected, ui.dropdownOpen, true
    end

    if ui.dropdownOpen then
        local rx, ry, rw, rh = ui.dropdownRect.x, ui.dropdownRect.y, ui.dropdownRect.w, ui.dropdownRect.h
        local menuItems = ui.dropdownItems or items or {}
        lcd.drawFilledRectangle(rx, ry, rw, rh, lcd.RGB(255, 255, 255))
        lcd.drawRectangle(rx, ry, rw, rh, COLOR_THEME_PRIMARY1, 2)
        local lh = 24
        local visible = math.floor(rh / lh)
        for i = 1, math.min(#menuItems, visible) do
            local iy = ry + (i - 1) * lh
            if i == ui.dropdownSelected then
                lcd.drawFilledRectangle(rx + 1, iy + 1, rw - 2, lh - 2, COLOR_THEME_FOCUS)
            end
            lcd.drawText(rx + 6, iy + lh / 2, menuItems[i], VCENTER + COLOR_THEME_PRIMARY1)
        end
        if touchState and event == EVT_TOUCH_TAP then
            if inRect(touchState.x, touchState.y, rx, ry, rw, rh) then
                local idx = math.floor((touchState.y - ry) / lh) + 1
                if idx >= 1 and idx <= #menuItems then
                    ui.dropdownSelected = idx
                    ui.dropdownOpen = false
                    if ui.dropdownOnSelect then ui.dropdownOnSelect(idx) end
                    return idx, false, true
                end
            else
                ui.dropdownOpen = false
                return selected, false, true
            end
        end
        return selected, true, true
    end

    return selected, ui.dropdownOpen, false
end

function M.drawSlider(x, y, w, value, min, max)
    local barY = y
    lcd.drawFilledRectangle(x, barY - 2, w, 4, COLOR_THEME_PRIMARY3)
    local frac = 0
    if max > min then frac = (value - min) / (max - min) end
    if frac < 0 then frac = 0 elseif frac > 1 then frac = 1 end
    local xdot = x + math.floor(frac * w)
    lcd.drawFilledCircle(xdot, barY, 8, COLOR_THEME_PRIMARY2)
    for i = -1, 1 do
        lcd.drawCircle(xdot, barY, 8 + i, COLOR_THEME_PRIMARY3)
    end
end

function M.handleSlider(event, touchState, x, y, w, value, min, max, step)
    step = step or 1
    if not touchState then return value end
    if event == EVT_TOUCH_FIRST or event == EVT_TOUCH_SLIDE or event == EVT_TOUCH_TAP then
        if inRect(touchState.x, touchState.y, x, y - 12, w, 24) then
            local frac = (touchState.x - x) / w
            if frac < 0 then frac = 0 elseif frac > 1 then frac = 1 end
            local v = min + frac * (max - min)
            v = math.floor((v + step / 2) / step) * step
            if v < min then v = min end
            if v > max then v = max end
            return v
        end
    end
    return value
end

local function clamp(val, min, max)
    if val < min then return min end
    if val > max then return max end
    return val
end

function M.drawToggle(x, y, w, h, enabled)
    local radius = math.floor(h / 2)
    if radius < 6 then radius = 6 end

    local trackColor = enabled and COLOR_THEME_FOCUS or COLOR_THEME_PRIMARY3
    local outlineColor = COLOR_THEME_PRIMARY1
    local knobColor = COLOR_THEME_PRIMARY2
    local centerY = y + radius
    local left = x
    local right = x + w

    lcd.drawFilledRectangle(left + radius, y, w - 2 * radius, h, trackColor)
    lcd.drawFilledCircle(left + radius, centerY, radius, trackColor)
    lcd.drawFilledCircle(right - radius, centerY, radius, trackColor)

    --lcd.drawCircle(left + radius, centerY, radius, outlineColor)
    --lcd.drawCircle(right - radius, centerY, radius, outlineColor)
    --lcd.drawRectangle(left + radius, y, w - 2 * radius, h, outlineColor)

    local knobRadius = clamp(radius - 3, 3, radius - 1)
    local knobX = enabled and (right - radius) or (left + radius)
    lcd.drawFilledCircle(knobX, centerY, knobRadius, knobColor)
    lcd.drawCircle(knobX, centerY, knobRadius, outlineColor)
end

function M.handleToggle(event, touchState, x, y, w, h, value)
    if not touchState then return value, false end

    local isTouch = (event == EVT_TOUCH_TAP) or (event == EVT_TOUCH_SLIDE) or (event == EVT_TOUCH_FIRST)
    if not isTouch then return value, false end

    if not inRect(touchState.x, touchState.y, x, y, w, h) then
        return value, false
    end

    local newValue = value
    if event == EVT_TOUCH_TAP then
        newValue = not value
    else
        newValue = (touchState.x >= (x + w / 2))
    end

    if newValue ~= value then
        return newValue, true
    end

    return value, false
end

return M


