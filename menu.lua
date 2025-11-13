--[[
#########################################################################
#                                                                       #
# RFApp - Menu/Settings Module                                          #
#                                                                       #
# Contains settings page and menu button functionality                  #
#                                                                       #
#########################################################################
]]

-- UI helper functions (extracted from simple_ui.lua)
local function inRect(x, y, rx, ry, rw, rh)
    return x >= rx and x <= rx + rw and y >= ry and y <= ry + rh
end

local function drawButton(x, y, w, h, title, focused)
    lcd.drawFilledRectangle(x, y, w, h, COLOR_THEME_FOCUS)
    lcd.drawRectangle(x, y, w, h, COLOR_THEME_FOCUS, 1)
    lcd.drawText(x + w / 2, y + h / 2, title, BOLD + CENTER + VCENTER + COLOR_THEME_PRIMARY2)
end

local function handleButton(event, touchState, x, y, w, h)
    if not touchState then return false end
    if event == EVT_TOUCH_TAP and inRect(touchState.x, touchState.y, x, y, w, h) then
        return true
    end
    return false
end

-- Tear down the LVGL settings page and reset state when leaving app mode or pressing back
local function closeSettingsPage(wgt)
    if not (wgt and wgt.ui and wgt.ui.settingsOpen) then return end
    wgt.ui.settingsOpen = false
    if lvgl then
        lvgl.clear()
    end
end

local function openSettingsPage(wgt)
    if not lvgl then return end
    if not wgt.ui then wgt.ui = {} end

    -- Initialize debug settings
    if not wgt.debug then
        wgt.debug = {
            enabled = false,
            volt = 52,
            cells = 12,
            pcnt = 85,
            mah = 759,
            arm = 1,
            rssi = 90,
            rpm = 2214,
            gov = 4,
            rate = 3,
            pid = 3,
            resc = 0,
            curr = 52,
            vbec = 8.4
        }
    end

    -- Initialize rate audio enabled setting (default to true)
    if wgt.rateAudioEnabled == nil then
        wgt.rateAudioEnabled = true
    end

    -- Initialize FPS counter enabled setting (default to false)
    if wgt.fpsEnabled == nil then
        wgt.fpsEnabled = false
    end

    wgt.ui.settingsValue = wgt.ui.settingsValue or 0
    wgt.ui.settingsOpen = true

    lvgl.clear()

    local page = lvgl.page({
        title = "RFApp Settings",
        subtitle = "Debug & Control",
        icon = "/WIDGETS/RFApp/rf2.png",
        back = function()
            closeSettingsPage(wgt)
        end,
    })

    local uit = {
        {
            type = "box",
            flexFlow = lvgl.FLOW_COLUMN,
            flexPad = lvgl.PAD_MED,
            w = LCD_W,
            children = {
                -- Debug Mode Toggle
                {
                    type = "box",
                    flexFlow = lvgl.FLOW_ROW,
                    children = {
                        { type = "label", text = "Debug Mode:", font = BOLD, w = 120 },
                        {
                            type = "toggle",
                            get = function() return wgt.debug.enabled and 1 or 0 end,
                            set = function(v)
                                wgt.debug.enabled = (v ~= 0)
                                -- Force page rebuild to show/hide debug fields
                                openSettingsPage(wgt)
                            end,
                        },
                    },
                },

                -- Rate Audio Toggle
                {
                    type = "box",
                    flexFlow = lvgl.FLOW_ROW,
                    children = {
                        { type = "label", text = "Rate Audio:", font = BOLD, w = 120 },
                        {
                            type = "toggle",
                            get = function() return wgt.rateAudioEnabled and 1 or 0 end,
                            set = function(v)
                                wgt.rateAudioEnabled = (v ~= 0)
                            end,
                        },
                    },
                },

                -- FPS Counter Toggle
                {
                    type = "box",
                    flexFlow = lvgl.FLOW_ROW,
                    children = {
                        { type = "label", text = "FPS Counter:", font = BOLD, w = 120 },
                        {
                            type = "toggle",
                            get = function() return wgt.fpsEnabled and 1 or 0 end,
                            set = function(v)
                                wgt.fpsEnabled = (v ~= 0)
                            end,
                        },
                    },
                },

                -- Demo Value (always visible)
                {
                    type = "box",
                    flexFlow = lvgl.FLOW_ROW,
                    children = {
                        { type = "label", text = "Demo Value:", font = BOLD, w = 120 },
                        {
                            type = "numberEdit",
                            min = -1024,
                            max = 1024,
                            step = 1,
                            w = 90,
                            get = function()
                                return wgt.ui.settingsValue or 0
                            end,
                            set = function(v)
                                wgt.ui.settingsValue = v
                            end,
                        },
                    },
                },

                -- Debug telemetry overrides (only visible when debug mode enabled)
                wgt.debug.enabled and {
                    type = "box",
                    flexFlow = lvgl.FLOW_COLUMN,
                    flexPad = lvgl.PAD_SMALL,
                    children = {
                        { type = "label", text = "Debug Telemetry Values:", font = BOLD },
                        {
                            type = "box",
                            flexFlow = lvgl.FLOW_ROW,
                            children = {
                                { type = "label", text = "Voltage:", w = 80 },
                                {
                                    type = "numberEdit",
                                    min = 0,
                                    max = 55,
                                    step = 0.5,
                                    w = 70,
                                    get = function() return wgt.debug.volt end,
                                    set = function(v) wgt.debug.volt = v end,
                                },
                            },
                        },
                        {
                            type = "box",
                            flexFlow = lvgl.FLOW_ROW,
                            children = {
                                { type = "label", text = "Cells:", w = 80 },
                                {
                                    type = "numberEdit",
                                    min = 1,
                                    max = 12,
                                    step = 1,
                                    w = 70,
                                    get = function() return wgt.debug.cells end,
                                    set = function(v) wgt.debug.cells = v end,
                                },
                            },
                        },
                        {
                            type = "box",
                            flexFlow = lvgl.FLOW_ROW,
                            children = {
                                { type = "label", text = "%:", w = 80 },
                                {
                                    type = "numberEdit",
                                    min = 0,
                                    max = 100,
                                    step = 1,
                                    w = 70,
                                    get = function() return wgt.debug.pcnt end,
                                    set = function(v) wgt.debug.pcnt = v end,
                                },
                            },
                        },
                        {
                            type = "box",
                            flexFlow = lvgl.FLOW_ROW,
                            children = {
                                { type = "label", text = "mAh:", w = 80 },
                                {
                                    type = "numberEdit",
                                    min = 0,
                                    max = 10000,
                                    step = 10,
                                    w = 70,
                                    get = function() return wgt.debug.mah end,
                                    set = function(v) wgt.debug.mah = v end,
                                },
                            },
                        },
                        {
                            type = "box",
                            flexFlow = lvgl.FLOW_ROW,
                            children = {
                                { type = "label", text = "Armed:", w = 80 },
                                {
                                    type = "numberEdit",
                                    min = 0,
                                    max = 4,
                                    step = 1,
                                    w = 70,
                                    get = function() return wgt.debug.arm end,
                                    set = function(v) wgt.debug.arm = v end,
                                },
                            },
                        },
                        {
                            type = "box",
                            flexFlow = lvgl.FLOW_ROW,
                            children = {
                                { type = "label", text = "RSSI:", w = 80 },
                                {
                                    type = "numberEdit",
                                    min = 0,
                                    max = 100,
                                    step = 1,
                                    w = 70,
                                    get = function() return wgt.debug.rssi end,
                                    set = function(v) wgt.debug.rssi = v end,
                                },
                            },
                        },
                        {
                            type = "box",
                            flexFlow = lvgl.FLOW_ROW,
                            children = {
                                { type = "label", text = "RPM:", w = 80 },
                                {
                                    type = "numberEdit",
                                    min = 0,
                                    max = 3000,
                                    step = 100,
                                    w = 70,
                                    get = function() return wgt.debug.rpm end,
                                    set = function(v) wgt.debug.rpm = v end,
                                },
                            },
                        },
                        {
                            type = "box",
                            flexFlow = lvgl.FLOW_ROW,
                            children = {
                                { type = "label", text = "Gov:", w = 80 },
                                {
                                    type = "numberEdit",
                                    min = 0,
                                    max = 9,
                                    step = 1,
                                    w = 70,
                                    get = function() return wgt.debug.gov end,
                                    set = function(v) wgt.debug.gov = v end,
                                },
                            },
                        },
                        {
                            type = "box",
                            flexFlow = lvgl.FLOW_ROW,
                            children = {
                                { type = "label", text = "Rate:", w = 80 },
                                {
                                    type = "numberEdit",
                                    min = 0,
                                    max = 6,
                                    step = 1,
                                    w = 70,
                                    get = function() return wgt.debug.rate end,
                                    set = function(v) wgt.debug.rate = v end,
                                },
                            },
                        },
                        {
                            type = "box",
                            flexFlow = lvgl.FLOW_ROW,
                            children = {
                                { type = "label", text = "PID:", w = 80 },
                                {
                                    type = "numberEdit",
                                    min = 0,
                                    max = 6,
                                    step = 1,
                                    w = 70,
                                    get = function() return wgt.debug.pid end,
                                    set = function(v) wgt.debug.pid = v end,
                                },
                            },
                        },
                        {
                            type = "box",
                            flexFlow = lvgl.FLOW_ROW,
                            children = {
                                { type = "label", text = "Rescue:", w = 80 },
                                {
                                    type = "numberEdit",
                                    min = 0,
                                    max = 6,
                                    step = 1,
                                    w = 70,
                                    get = function() return wgt.debug.resc end,
                                    set = function(v) wgt.debug.resc = v end,
                                },
                            },
                        },
                        {
                            type = "box",
                            flexFlow = lvgl.FLOW_ROW,
                            children = {
                                { type = "label", text = "Curr:", w = 80 },
                                {
                                    type = "numberEdit",
                                    min = 0,
                                    max = 200,
                                    step = 0.1,
                                    w = 70,
                                    get = function() return wgt.debug.curr end,
                                    set = function(v) wgt.debug.curr = v end,
                                },
                            },
                        },
                        {
                            type = "box",
                            flexFlow = lvgl.FLOW_ROW,
                            children = {
                                { type = "label", text = "Vbec:", w = 80 },
                                {
                                    type = "numberEdit",
                                    min = 0,
                                    max = 20,
                                    step = 0.01,
                                    w = 70,
                                    get = function() return wgt.debug.vbec end,
                                    set = function(v) wgt.debug.vbec = v end,
                                },
                            },
                        },
                    },
                } or nil,

                {
                    type = "button",
                    text = "Close",
                    press = function()
                        closeSettingsPage(wgt)
                    end,
                },
            },
        },
    }

    wgt.ui.settingsPage = page:build(uit)
end

-- Draw and handle Menu button (replaces Settings button)
local function drawAndHandleMenuButton(wgt, event, touchState, config, normalizeGridSpan)
    -- Cache grid calculations to avoid recalculation every frame
    if not wgt.cachedGridSpan then
        wgt.cachedGridSpan = normalizeGridSpan(config.BTN_GRID, { row = 8, rows = 1, col = 7, cols = 2 }, config)
        wgt.cachedCellW = math.floor(LCD_W / config.GRID_COLS)
        wgt.cachedCellH = math.floor(LCD_H / config.GRID_ROWS)
    end

    local span = wgt.cachedGridSpan
    local cellW = wgt.cachedCellW
    local cellH = wgt.cachedCellH
    local btnX = (span.col - 1) * cellW
    local btnY = (span.row - 1) * cellH
    local btnW = span.cols * cellW
    local btnH = span.rows * cellH

    -- Handle button interaction and draw button
    local buttonPressed = handleButton(event, touchState, btnX, btnY, btnW, btnH)
    if buttonPressed then
        openSettingsPage(wgt)
    end

    drawButton(btnX, btnY, btnW, btnH, "Menu")

    return buttonPressed -- Return true if interaction occurred
end

return {
    closeSettingsPage = closeSettingsPage,
    openSettingsPage = openSettingsPage,
    drawAndHandleMenuButton = drawAndHandleMenuButton,
}
