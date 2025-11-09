--[[
#########################################################################
#                                                                       #
# RFApp - Multi-function Telemetry Widget (initial: Battery Monitor)    #
#                                                                       #
# This initial version implements a full-screen layout with a Battery    #
# Monitor occupying a quarter of the screen width (top strip).          #
# Code is self-contained: logic copied from RFBattery (no external deps) #
#                                                                       #
#########################################################################
]]

-- Brief: Entry point for RFApp – initializes shared telemetry, lays out apps via grid,
-- draws widget placeholder in non-app mode, and handles audio/alerts in background.

local APP_VERSION = "0.15"

-- Load internal modules (copied from RFBattery subset)
--Main modules
local config = loadScript("/WIDGETS/RFApp/config.lua", "tcd")()
local DisplayEngine = loadScript("/WIDGETS/RFApp/display_engine.lua", "tcd")()
local UI = loadScript("/WIDGETS/RFApp/simple_ui.lua", "tcd")()
local telemetry = loadScript("/WIDGETS/RFApp/telemetry.lua", "tcd")()
local menu = loadScript("/WIDGETS/RFApp/menu.lua", "tcd")()

-- Alias the EdgeTX LVGL bridge with an app-specific name
local function getSettingsView()
    local view = rawget(_G, "lvgl")
    if not view and lcd and lcd.enterFullScreen then
        lcd.enterFullScreen()
        view = rawget(_G, "lvgl")
    end
    return view
end

-- Battery app modules
local filters = loadScript("/WIDGETS/RFApp/APPS/Battery/filters.lua", "tcd")()
local calc = loadScript("/WIDGETS/RFApp/APPS/Battery/calc.lua", "tcd")()
local displayMon = loadScript("/WIDGETS/RFApp/APPS/Battery/display.lua", "tcd")()
local battAudio = loadScript("/WIDGETS/RFApp/APPS/Battery/audio.lua", "tcd")()
local battTelemDisplay = loadScript("/WIDGETS/RFApp/APPS/BattTelem/display.lua", "tcd")()

-- Arm app modules
local armCalc = loadScript("/WIDGETS/RFApp/APPS/Arm/calc.lua", "tcd")()
local armDisplay = loadScript("/WIDGETS/RFApp/APPS/Arm/display.lua", "tcd")()
local armAudio = loadScript("/WIDGETS/RFApp/APPS/Arm/audio.lua", "tcd")()

-- Logo app modules
local logoDisplay = loadScript("/WIDGETS/RFApp/APPS/Logo/display.lua", "tcd")()
-- Events app modules
local eventsDisplay = loadScript("/WIDGETS/RFApp/APPS/Events/display.lua", "tcd")()
local eventsStore = loadScript("/WIDGETS/RFApp/APPS/Events/store.lua", "tcd")()
-- TX battery app
local txBattDisplay = loadScript("/WIDGETS/RFApp/APPS/TxBatt/display.lua", "tcd")()
local signalDisplay = loadScript("/WIDGETS/RFApp/APPS/Signal/display.lua", "tcd")()
local pidDisplay = loadScript("/WIDGETS/RFApp/APPS/Pid/display.lua", "tcd")()
local pidAudio = loadScript("/WIDGETS/RFApp/APPS/Pid/audio.lua", "tcd")()
local rateAudio = loadScript("/WIDGETS/RFApp/APPS/Rate/audio.lua", "tcd")()
-- RPM app modules
local rpmCalc = loadScript("/WIDGETS/RFApp/APPS/Rpm/calc.lua", "tcd")()
local rpmDisplay = loadScript("/WIDGETS/RFApp/APPS/Rpm/display.lua", "tcd")()
-- Governor app modules
local govCalc = loadScript("/WIDGETS/RFApp/APPS/Gov/calc.lua", "tcd")()
local govDisplay = loadScript("/WIDGETS/RFApp/APPS/Gov/display.lua", "tcd")()
-- Rescue app modules
local rescueCalc = loadScript("/WIDGETS/RFApp/APPS/Rescue/calc.lua", "tcd")()
local rescueDisplay = loadScript("/WIDGETS/RFApp/APPS/Rescue/display.lua", "tcd")()
local rescueAudio = loadScript("/WIDGETS/RFApp/APPS/Rescue/audio.lua", "tcd")()

-- Cache globals
local getValue = getValue
local model = model
local math = math

-- Simple logger (disabled)
local function log(s)
    -- print("RFApp: " .. s)
end

-- Update options and color settings
local update
local function isAppMode(wgt, event)
    return (event ~= nil) and (wgt.zone and wgt.zone.w >= LCD_W - 1) and (wgt.zone.h >= LCD_H - 20) and (wgt.zone.x == 0) and (wgt.zone.y == 0)
end

local function loadRFLogo()
    if Bitmap and Bitmap.open then
        return Bitmap.open("/WIDGETS/RFApp/RF.png")
    end
    return nil
end

local function normalizeGridSpan(span, defaultSpan)
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

-- Helpers moved into display_engine.lua

-- Minimal placeholder for widget mode (like LibGUI/loadable.lua example)
local function drawWidgetPlaceholder(wgt)
    local x = wgt.zone.x
    local y = wgt.zone.y
    local w = wgt.zone.w
    local h = wgt.zone.h
    lcd.drawRectangle(x, y, w, h, COLOR_THEME_PRIMARY3)
    lcd.drawText(x + w / 2, y + h / 2 - 12, "RFApp v" .. APP_VERSION, DBLSIZE + CENTER + VCENTER + COLOR_THEME_PRIMARY2)
    lcd.drawText(x + w / 2, y + h / 2 + 18, "Long press to launch", CENTER + VCENTER + COLOR_THEME_PRIMARY2)
end

update = function(wgt, options)
    if (wgt == nil) then return end
    wgt.options = options

    if wgt.rateAudioEnabled == nil then
        wgt.rateAudioEnabled = (config.RATE_AUDIO_DEFAULT ~= false)
    end
    config.rateAudioEnabled = wgt.rateAudioEnabled

    -- Set source name from hardcoded sensor
    wgt.options.source_name = config.SENSOR_VOLT

    -- Hard-wired text and reserve settings
    local colorToggle = config.HARDWIRED_TEXT_COLOR_TOGGLE
    wgt.options[config.OPT_COLOR_TOGGLE] = colorToggle
    if colorToggle == 1 then
        wgt.text_color = lcd.RGB(0, 0, 0)
    else
        wgt.text_color = lcd.RGB(255, 255, 255)
    end
    wgt.cell_color = wgt.text_color

    local reserveValue = math.max(0, math.min(50, config.HARDWIRED_RESERVE_PERCENT or 0))
    wgt.options[config.OPT_RESERVE] = reserveValue
    wgt.vReserve = reserveValue
    config.singleStepThreshold = (reserveValue > 0) and reserveValue or 10

    -- Configure grid-based placement for app mode
    if wgt.engine then
        wgt.engine.setConfig(config)
        wgt.engine.placeConfiguredWidgets(wgt, config, {
            battery = function(w, x, y, ww, hh)
                displayMon.drawEighthMonitor(w, x, y, ww, hh)
            end,
            battTelem = function(w, x, y, ww, hh)
                battTelemDisplay.draw(w, x, y, ww, hh)
            end,
            arm = function(w, x, y, ww, hh)
                armDisplay.draw(w, x, y, ww, hh)
            end,
            logo = function(w, rx, ry, rw, rh)
                logoDisplay.draw(w, rx, ry, rw, rh)
            end,
            events = function(w, rx, ry, rw, rh)
                eventsDisplay.draw(w, rx, ry, rw, rh)
                -- remember rect for hit-testing
                w._eventsRect = { x = rx, y = ry, w = rw, h = rh }
            end,
            txBatt = function(w, rx, ry, rw, rh)
                txBattDisplay.draw(w, rx, ry, rw, rh)
            end,
            rescue = function(w, rx, ry, rw, rh)
                rescueDisplay.draw(w, rx, ry, rw, rh)
            end,
            signal = function(w, rx, ry, rw, rh)
                signalDisplay.draw(w, rx, ry, rw, rh)
            end,
            pid = function(w, rx, ry, rw, rh)
                pidDisplay.draw(w, rx, ry, rw, rh)
            end,
            rpm = function(w, rx, ry, rw, rh)
                rpmDisplay.draw(w, rx, ry, rw, rh)
            end,
            gov = function(w, rx, ry, rw, rh)
                govDisplay.draw(w, rx, ry, rw, rh)
            end,
        }, wgt.rfLogo)
    end
end

local function create(zone, options)
    local initialColor
    if config.HARDWIRED_TEXT_COLOR_TOGGLE == 1 then
            initialColor = lcd.RGB(0, 0, 0)
        else
            initialColor = lcd.RGB(255, 255, 255)
    end

    local wgt = {
        zone = zone,
        options = options,
        counter = 0,

        text_color = initialColor,
        cell_color = initialColor,
        border_l = config.BORDER_LEFT,
        border_r = config.BORDER_RIGHT,
        border_t = config.BORDER_TOP,
        border_b = config.BORDER_BOTTOM,

        rateAudioEnabled = (config.RATE_AUDIO_DEFAULT ~= false),

        telemResetCount = 0,
        telemResetLowestMinRSSI = 101,
        isDataAvailable = 0,
        vMax = 0,
        vMin = 0,
        vTotalLive = 0,
        vPercent = 0,
        vMah = 0,
        cellCount = 1,
        cell_detected = false,
        bat_connected_low = 0,
        bat_connected_low_played = false,
        bat_connected_low_timer = 0,
        vCellLive = 0,
        mainValue = 0,
        secondaryValue = 0,

        battNextPlay = 0,
        battPercentPlayed = -1,
        battPercentSetDuringCellDetection = false,
        audioProcessedThisCycle = false,

        vflt = {},
        vflti = 0,
        vfltSamples = 0,
        vfltInterval = 0, 
        vfltNextUpdate = 0,

        useSensorP = false,
        useSensorM = false,

        telemReconnectTime = 0,
        wasTelemetryLost = false,
        rssiDisconnectTime = 0,
        zeroVoltageTime = 0,
        
        batInsDetectDeadline = 0,
        batLowOffset = 0,

        rescueStateIndex = -1,
        rescueLabel = "OFF",
        rescueBg = COLOR_THEME_PRIMARY2,
        rescueFg = COLOR_THEME_PRIMARY1,

        -- optional runtime debug overrides (set enabled=true and values as needed)
        -- debug = { enabled=true, volt=15.5, cells=4, pcnt=62, mah=500, arm=1, rssi=80 },
    }

    -- imports
    wgt.ToolsClass = loadScript("/WIDGETS/" .. config.app_name .. "/widget_tools.lua", "tcd")
    wgt.tools = wgt.ToolsClass(config.app_name)

    -- init display engine and regions
    wgt.engine = DisplayEngine.new()
    wgt.engine.setGrid(config.GRID_ROWS, config.GRID_COLS)

    -- init simple ui state (used only for fullscreen event log)
    wgt.ui = { eventsOpen = false }

    -- hard-wire options to config defaults
    options[config.OPT_COLOR_TOGGLE] = config.HARDWIRED_TEXT_COLOR_TOGGLE
    options[config.OPT_RESERVE] = config.HARDWIRED_RESERVE_PERCENT

    -- initialize runtime state (ensures telemetry stabilization and cell detection timers start)
    calc.resetWidget(wgt, config)

    update(wgt, options)
    wgt._appModeActive = false
    wgt.rfLogo = loadRFLogo()
    config.rateAudioEnabled = wgt.rateAudioEnabled
    return wgt
end

local function background(wgt)
    if (wgt == nil) then return end
    wgt.tools.detectResetEvent(wgt, function(w) calc.onTelemetryResetEvent(w, config) end)
    telemetry.update(wgt, config)
    calc.calculateBatteryData(wgt, config, filters, calc, nil)
    -- update ARM state and play arm/disarm sounds on change
    armCalc.update(wgt, config)
    armAudio.handleArmAudio(wgt, config)
    rescueCalc.update(wgt, config)
    rescueAudio.handleRescueAudio(wgt, config)
    battAudio.handleBatteryAlerts(wgt, config)
    -- update RPM from Hspd telemetry
    rpmCalc.update(wgt, config)
    -- update Governor state from Gov telemetry
    govCalc.update(wgt, config)
    pidAudio.handlePidAudio(wgt, config)
    rateAudio.handleRateAudio(wgt, config)
    -- Log app removed: no log cache updates
end

local function refresh(wgt, event, touchState)
    if (wgt == nil)         then return end
    if type(wgt) ~= "table" then return end
    if (wgt.options == nil) then return end
    if (wgt.zone == nil)    then return end

    -- reset per-cycle audio flag so alerts can be processed once per UI refresh
    wgt.audioProcessedThisCycle = false

    background(wgt)

    if lvgl and lvgl.isFullScreen and lvgl.isFullScreen() and wgt.ui and wgt.ui.settingsOpen then
        return
    end
    -- Detect app mode transition to refresh cached state
    local appNow = isAppMode(wgt, event)
    if appNow and not wgt._appModeActive then
        update(wgt, wgt.options)
        wgt._appModeActive = true
    elseif (not appNow) and wgt._appModeActive then
        wgt._appModeActive = false
    end

    -- Full-screen mode only when zone actually spans the screen (avoid long-press events in widget mode)
    if appNow then
        -- Always draw menu button (no actions wired behind it)
        menu.drawAndHandleMenuButton(wgt, event, touchState, config, UI, normalizeGridSpan)
        
        -- Always render apps first
        wgt.engine.render(wgt)
        
        -- Events fullscreen toggle
            if touchState and event == EVT_TOUCH_TAP then
                if wgt.ui and wgt.ui.eventsOpen then
                    wgt.ui.eventsOpen = false
                elseif wgt._eventsRect then
                    local r = wgt._eventsRect
                    if touchState.x >= r.x and touchState.x <= r.x + r.w and touchState.y >= r.y and touchState.y <= r.y + r.h then
                    if not wgt.ui then wgt.ui = {} end
                        wgt.ui.eventsOpen = true
                    end
                end
            end
            if wgt.ui and wgt.ui.eventsOpen then
                eventsDisplay.drawFull(wgt)
                return
        end
        return
    end

    -- Widget mode (embedded) - show placeholder only
    drawWidgetPlaceholder(wgt)
end

return { name = config.app_name, options = config.options, create = create, update = update, background = background, refresh = refresh }


