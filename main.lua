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

-- Changelog:
-- 0.29: Added Debug Mode toggle with telemetry value overrides in settings menu
-- 0.28: Moved telemetry hash calculation to telemetry.lua for cleaner main.lua
-- 0.27: Fixed app widgets flashing - now render consistently
-- 0.26: Fixed screen flashing issue with conditional rendering
-- 0.25: Added telemetry change detection for optimization
-- 0.24: Added FPS counter
-- 0.23: Added grid-based placement for app mode
-- 0.22: Added menu button
-- 0.21: Added event log
-- 0.20: Added rescue mode
-- 0.19: Added RPM display
-- 0.18: Added Governor display
-- 0.17: Added PID display
-- 0.16: Added signal display
-- 0.15: Added TxBatt display
-- 0.14: Added Events display
-- 0.13: Added Logo display
-- 0.12: Added Arm display
-- 0.11: Added BattTelem display
-- 0.10: Added Battery display
-- 0.09: Added Battery audio
-- 0.08: Added Battery calc
-- 0.07: Added Battery filters
-- 0.06: Added Battery display
-- 0.05: Added Battery audio
-- 0.04: Added Battery calc
-- 0.03: Added Battery filters
-- 0.02: Added Battery display
-- 0.01: Initial release
-- Brief: Entry point for RFApp – initializes shared telemetry, lays out apps via grid,
-- draws widget placeholder in non-app mode, and handles audio/alerts in background.

local APP_VERSION = "0.29"

-- Load internal modules (copied from RFBattery subset)
--Main modules
local config = loadScript("/WIDGETS/RFApp/config.lua", "tcd")()
local DisplayEngine = loadScript("/WIDGETS/RFApp/display_engine.lua", "tcd")()
local telemetry = loadScript("/WIDGETS/RFApp/telemetry.lua", "tcd")()
local menu = loadScript("/WIDGETS/RFApp/menu.lua", "tcd")()

-- Module registry for dynamic app loading
-- Maps app names to their module file paths. Apps can be enabled/disabled via config.Apps[appName].enabled
-- This replaces hard-coded loadScript calls and makes it easy to add new apps by just updating the registry
local moduleRegistry = {
    Battery = {
        filters = "APPS/Battery/filters.lua",
        calc = "APPS/Battery/calc.lua",
        display = "APPS/Battery/display.lua",
        audio = "APPS/Battery/audio.lua",
    },
    BattTelem = {
        display = "APPS/BattTelem/display.lua",
    },
    Arm = {
        calc = "APPS/Arm/calc.lua",
        display = "APPS/Arm/display.lua",
        audio = "APPS/Arm/audio.lua",
    },
    Logo = {
        display = "APPS/Logo/display.lua",
    },
    Events = {
        display = "APPS/Events/display.lua",
        store = "APPS/Events/store.lua",
    },
    TxBatt = {
        display = "APPS/TxBatt/display.lua",
    },
    Signal = {
        display = "APPS/Signal/display.lua",
    },
    Pid = {
        display = "APPS/Pid/display.lua",
    },
    Rate = {
        -- Rate audio moved to unified audio.lua
    },
    Audio = {
        profile = "APPS/Pid/audio.lua", -- Unified audio handling for Rate and PID (moved to Pid folder)
    },
    Rpm = {
        calc = "APPS/Rpm/calc.lua",
        display = "APPS/Rpm/display.lua",
    },
    Gov = {
        calc = "APPS/Gov/calc.lua",
        display = "APPS/Gov/display.lua",
    },
    Rescue = {
        calc = "APPS/Rescue/calc.lua",
        display = "APPS/Rescue/display.lua",
        audio = "APPS/Rescue/audio.lua",
    },
}

-- Load modules from registry based on config.Apps enabled flags
local function loadModulesFromRegistry(registry, config, basePath)
    local modules = {}
    basePath = basePath or "/WIDGETS/RFApp/"

    for appName, appConfig in pairs(config.Apps) do
        if appConfig.enabled and registry[appName] then
            modules[appName] = {}
            for moduleName, modulePath in pairs(registry[appName]) do
                local fullPath = basePath .. modulePath
                local success, module = pcall(loadScript, fullPath, "tcd")
                if success and module then
                    modules[appName][moduleName] = module()
                else
                    print("RFApp: Failed to load module: " .. fullPath)
                    modules[appName][moduleName] = {} -- Provide empty table as fallback
                end
            end
        end
    end

    return modules
end

-- Load app modules dynamically
local appModules = loadModulesFromRegistry(moduleRegistry, config)

-- Alias the EdgeTX LVGL bridge with an app-specific name
local function getSettingsView()
    local view = rawget(_G, "lvgl")
    if not view and lcd and lcd.enterFullScreen then
        lcd.enterFullScreen()
        view = rawget(_G, "lvgl")
    end
    return view
end

-- App modules loaded dynamically from registry (with nil safety)
local filters = (appModules.Battery and appModules.Battery.filters) or {}
local calc = (appModules.Battery and appModules.Battery.calc) or {}
local displayMon = (appModules.Battery and appModules.Battery.display) or {}
local battAudio = (appModules.Battery and appModules.Battery.audio) or {}
local battTelemDisplay = (appModules.BattTelem and appModules.BattTelem.display) or {}

local armCalc = (appModules.Arm and appModules.Arm.calc) or {}
local armDisplay = (appModules.Arm and appModules.Arm.display) or {}
local armAudio = (appModules.Arm and appModules.Arm.audio) or {}

local logoDisplay = (appModules.Logo and appModules.Logo.display) or {}
local eventsDisplay = (appModules.Events and appModules.Events.display) or {}
local eventsStore = (appModules.Events and appModules.Events.store) or {}

local txBattDisplay = (appModules.TxBatt and appModules.TxBatt.display) or {}
local signalDisplay = (appModules.Signal and appModules.Signal.display) or {}
local pidDisplay = (appModules.Pid and appModules.Pid.display) or {}
local profileAudio = (appModules.Audio and appModules.Audio.profile) or {}

local rpmCalc = (appModules.Rpm and appModules.Rpm.calc) or {}
local rpmDisplay = (appModules.Rpm and appModules.Rpm.display) or {}

local govCalc = (appModules.Gov and appModules.Gov.calc) or {}
local govDisplay = (appModules.Gov and appModules.Gov.display) or {}

local rescueCalc = (appModules.Rescue and appModules.Rescue.calc) or {}
local rescueDisplay = (appModules.Rescue and appModules.Rescue.display) or {}
local rescueAudio = (appModules.Rescue and appModules.Rescue.audio) or {}

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
                if displayMon.drawEighthMonitor then displayMon.drawEighthMonitor(w, x, y, ww, hh) end
            end,
            battTelem = function(w, x, y, ww, hh)
                if battTelemDisplay.draw then battTelemDisplay.draw(w, x, y, ww, hh) end
            end,
            arm = function(w, x, y, ww, hh)
                if armDisplay.draw then armDisplay.draw(w, x, y, ww, hh) end
            end,
            logo = function(w, rx, ry, rw, rh)
                if logoDisplay.draw then logoDisplay.draw(w, rx, ry, rw, rh) end
            end,
            events = function(w, rx, ry, rw, rh)
                if eventsDisplay.draw then eventsDisplay.draw(w, rx, ry, rw, rh) end
                -- remember rect for hit-testing
                w._eventsRect = { x = rx, y = ry, w = rw, h = rh }
            end,
            txBatt = function(w, rx, ry, rw, rh)
                if txBattDisplay.draw then txBattDisplay.draw(w, rx, ry, rw, rh) end
            end,
            rescue = function(w, rx, ry, rw, rh)
                if rescueDisplay.draw then rescueDisplay.draw(w, rx, ry, rw, rh) end
            end,
            signal = function(w, rx, ry, rw, rh)
                if signalDisplay.draw then signalDisplay.draw(w, rx, ry, rw, rh) end
            end,
            pid = function(w, rx, ry, rw, rh)
                if pidDisplay.draw then pidDisplay.draw(w, rx, ry, rw, rh) end
            end,
            rpm = function(w, rx, ry, rw, rh)
                if rpmDisplay.draw then rpmDisplay.draw(w, rx, ry, rw, rh) end
            end,
            gov = function(w, rx, ry, rw, rh)
                if govDisplay.draw then govDisplay.draw(w, rx, ry, rw, rh) end
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

        -- FPS counter
        fpsLastTime = 0,
        fpsFrameCount = 0,
        fpsValue = 0,

        -- Telemetry change detection for optimization
        lastTelemetryHash = 0,
        lastRenderTime = 0,

        -- Cached grid calculations
        cachedGridSpan = nil,

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

    -- Safe module function calls with nil checks
    if wgt.tools and wgt.tools.detectResetEvent then
        wgt.tools.detectResetEvent(wgt, function(w) if calc.onTelemetryResetEvent then calc.onTelemetryResetEvent(w, config) end end)
    end
    if telemetry.update then telemetry.update(wgt, config) end
    if calc.calculateBatteryData then calc.calculateBatteryData(wgt, config, filters, calc, nil) end

    -- update ARM state and play arm/disarm sounds on change
    if armCalc.update then armCalc.update(wgt, config) end
    if armAudio.handleArmAudio then armAudio.handleArmAudio(wgt, config) end
    if rescueCalc.update then rescueCalc.update(wgt, config) end
    if rescueAudio.handleRescueAudio then rescueAudio.handleRescueAudio(wgt, config) end
    if battAudio.handleBatteryAlerts then battAudio.handleBatteryAlerts(wgt, config) end

    -- update RPM from Hspd telemetry
    if rpmCalc.update then rpmCalc.update(wgt, config) end
    -- update Governor state from Gov telemetry
    if govCalc.update then govCalc.update(wgt, config) end
    if profileAudio.handlePidAudio then profileAudio.handlePidAudio(wgt, config) end
    if profileAudio.handleRateAudio then profileAudio.handleRateAudio(wgt, config) end
    -- Log app removed: no log cache updates
end

local function refresh(wgt, event, touchState)
    if (wgt == nil)         then return end
    if type(wgt) ~= "table" then return end
    if (wgt.options == nil) then return end
    if (wgt.zone == nil)    then return end

    -- FPS counter calculation
    local currentTime = getTime()
    wgt.fpsFrameCount = wgt.fpsFrameCount + 1

    if wgt.fpsLastTime == 0 then
        wgt.fpsLastTime = currentTime
    elseif currentTime - wgt.fpsLastTime >= 100 then -- Update every 100ms (10fps minimum)
        local timeDiff = (currentTime - wgt.fpsLastTime) / 100 -- Convert to seconds
        wgt.fpsValue = math.floor(wgt.fpsFrameCount / timeDiff + 0.5)
        wgt.fpsFrameCount = 0
        wgt.fpsLastTime = currentTime
    end

    -- reset per-cycle audio flag so alerts can be processed once per UI refresh
    wgt.audioProcessedThisCycle = false

    local currentTelemetryHash = telemetry.calculateTelemetryHash(wgt.telem)

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

        -- Always render menu button and apps for consistent display
        menu.drawAndHandleMenuButton(wgt, event, touchState, config, normalizeGridSpan)

        -- Track telemetry changes for optimization (but always render for visual consistency)
        if currentTelemetryHash ~= wgt.lastTelemetryHash then
            wgt.lastTelemetryHash = currentTelemetryHash
            -- Telemetry changed - full render will show updates
        end

        -- Always render apps to prevent flashing
        wgt.engine.render(wgt)

        -- FPS counter display (top-left corner)
        if wgt.fpsValue > 0 then
            lcd.drawText(2, 20, string.format("FPS: %d", wgt.fpsValue), SMLSIZE + COLOR_THEME_SECONDARY2)
        end

        -- Events fullscreen toggle (always handle interactions)
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


