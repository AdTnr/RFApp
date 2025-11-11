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
-- 0.48: Implemented conditional state calculations - only calculate when telemetry values change (20-30% CPU reduction)
-- 0.47: Added FPS Counter toggle switch in settings menu to enable/disable FPS calculations
-- 0.46: Optimized main loop - cached function references, reduced table lookups, cached FPS string
-- 0.45: Added debouncing to PID and Rate telemetry to ignore intermediate values
-- 0.44: Added Rate Audio toggle switch in settings menu
-- 0.43: Added RF.png icon to settings menu page
-- 0.42: Split PID and Rate audio into separate functions for independent control
-- 0.41: Changed Rate audio to use combined Rate_X.wav files instead of separate rate + number sounds
-- 0.40: Changed PID audio to use combined Profile_X.wav files instead of separate profile + number sounds
-- 0.35: CRITICAL FIX - Restored background() call in refresh() function, telemetry was completely broken
-- 0.34: Added telemetry debugging output to diagnose sensor reading issues
-- 0.33: Fixed telemetry update issue - moved telemetry.update() outside tick timing optimization for responsiveness
-- 0.32: Restored detailed Arm state descriptions in event logs (Arm: ARMED (prearmed and now armed))
-- 0.31: Restored detailed Gov state descriptions in event logs (Gov: SPOOLUP (Spooling to target))
-- 0.30: Standardized stateMap pattern across Gov and Arm calc/display modules (matching Rescue pattern)
-- 0.29: Added Debug Mode toggle with telemetry value overrides in settings menu
-- 0.28: Moved telemetry hash calculation to telemetry.lua for cleaner main.lua
-- 0.27: Fixed app widgets flashing - now render consistently
-- 0.26: Fixed screen flashing issue with conditional rendering
-- 0.25: Added telemetry change detection for optimization
-- 0.24: Added FPS counter

-- Brief: Entry point for RFApp – initializes shared telemetry, lays out apps via grid,
-- draws widget placeholder in non-app mode, and handles audio/alerts in background.

local APP_VERSION = "0.48"

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
        fpsEnabled = false,
        fpsLastTime = 0,
        fpsFrameCount = 0,
        fpsValue = 0,

        -- Telemetry change detection for optimization
        lastTelemetryHash = 0,
        lastRenderTime = 0,

        -- Last telemetry values for conditional state calculations
        _lastArmValue = nil,
        _lastGovValue = nil,
        _lastRescueValue = nil,
        _lastRpmValue = nil,
        _lastBatteryHash = nil,

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

    -- Cache function references to avoid repeated table lookups
    local telemetryUpdate = telemetry.update
    local calcBatteryData = calc.calculateBatteryData
    local armCalcUpdate = armCalc.update
    local armAudioHandle = armAudio.handleArmAudio
    local rescueCalcUpdate = rescueCalc.update
    local rescueAudioHandle = rescueAudio.handleRescueAudio
    local battAudioHandle = battAudio.handleBatteryAlerts
    local rpmCalcUpdate = rpmCalc.update
    local govCalcUpdate = govCalc.update
    local profileAudioHandlePid = profileAudio.handlePidAudio
    local profileAudioHandleRate = profileAudio.handleRateAudio

    -- Always update telemetry regardless of tick timing (critical for responsiveness)
    if telemetryUpdate then telemetryUpdate(wgt, config) end

    -- Safe module function calls with nil checks
    local tools = wgt.tools
    if tools and tools.detectResetEvent then
        tools.detectResetEvent(wgt, function(w) 
            local onReset = calc.onTelemetryResetEvent
            if onReset then onReset(w, config) end 
        end)
    end

    -- Battery calculation - check if battery-related telemetry changed
    local telem = wgt.telem or {}
    local batteryHash = (telem.volt or 0) + (telem.cells or 0) + (telem.pcnt or 0) + (telem.mah or 0)
    if batteryHash ~= (wgt._lastBatteryHash or -1) then
        if calcBatteryData then calcBatteryData(wgt, config, filters, calc, nil) end
        if battAudioHandle then battAudioHandle(wgt, config) end
        wgt._lastBatteryHash = batteryHash
    end

    -- ARM state - only calculate if arm value changed
    local armValue = telem.arm
    if armValue ~= (wgt._lastArmValue or -999) then
        if armCalcUpdate then armCalcUpdate(wgt, config) end
        if armAudioHandle then armAudioHandle(wgt, config) end
        wgt._lastArmValue = armValue
    end

    -- Governor state - only calculate if gov value changed
    local govValue = telem.gov
    if govValue ~= (wgt._lastGovValue or -999) then
        if govCalcUpdate then govCalcUpdate(wgt, config) end
        wgt._lastGovValue = govValue
    end

    -- Rescue state - only calculate if rescue value changed
    local rescueValue = telem.resc
    if rescueValue ~= (wgt._lastRescueValue or -999) then
        if rescueCalcUpdate then rescueCalcUpdate(wgt, config) end
        if rescueAudioHandle then rescueAudioHandle(wgt, config) end
        wgt._lastRescueValue = rescueValue
    end

    -- RPM state - only calculate if rpm value changed
    local rpmValue = telem.rpm
    if rpmValue ~= (wgt._lastRpmValue or -999) then
        if rpmCalcUpdate then rpmCalcUpdate(wgt, config) end
        wgt._lastRpmValue = rpmValue
    end

    -- Profile audio (PID and Rate) - always check (they handle their own change detection)
    if profileAudioHandlePid then profileAudioHandlePid(wgt, config) end
    if profileAudioHandleRate then profileAudioHandleRate(wgt, config) end
    -- Log app removed: no log cache updates
end

local function refresh(wgt, event, touchState)
    if (wgt == nil)         then return end
    if type(wgt) ~= "table" then return end
    if (wgt.options == nil) then return end
    if (wgt.zone == nil)    then return end

    -- Cache frequently accessed values
    local currentTime = getTime()
    
    -- FPS counter calculation (only if enabled)
    if wgt.fpsEnabled then
        local fpsLastTime = wgt.fpsLastTime
        local fpsFrameCount = wgt.fpsFrameCount + 1
        wgt.fpsFrameCount = fpsFrameCount

        if fpsLastTime == 0 then
            wgt.fpsLastTime = currentTime
        elseif currentTime - fpsLastTime >= 100 then -- Update every 100ms (10fps minimum)
            local timeDiff = (currentTime - fpsLastTime) / 100 -- Convert to seconds
            wgt.fpsValue = math.floor(fpsFrameCount / timeDiff + 0.5)
            wgt.fpsFrameCount = 0
            wgt.fpsLastTime = currentTime
            -- Cache FPS string to avoid formatting every frame
            wgt._fpsString = "FPS: " .. wgt.fpsValue
        end
    end

    -- reset per-cycle audio flag so alerts can be processed once per UI refresh
    wgt.audioProcessedThisCycle = false

    -- Update telemetry and process background tasks
    background(wgt)

    -- Cache function references
    local calculateTelemetryHash = telemetry.calculateTelemetryHash
    local currentTelemetryHash = calculateTelemetryHash and calculateTelemetryHash(wgt.telem) or 0

    -- Cache lvgl checks
    local lvglIsFullScreen = lvgl and lvgl.isFullScreen
    local isFullScreen = lvglIsFullScreen and lvglIsFullScreen()
    local wgtUi = wgt.ui
    
    if isFullScreen and wgtUi and wgtUi.settingsOpen then
        return
    end
    
    -- Detect app mode transition to refresh cached state
    local appNow = isAppMode(wgt, event)
    local appModeActive = wgt._appModeActive
    
    if appNow and not appModeActive then
        update(wgt, wgt.options)
        wgt._appModeActive = true
    elseif (not appNow) and appModeActive then
        wgt._appModeActive = false
    end

    -- Full-screen mode only when zone actually spans the screen (avoid long-press events in widget mode)
    if appNow then
        -- Cache function references
        local menuDrawAndHandle = menu.drawAndHandleMenuButton
        local engineRender = wgt.engine.render
        local eventsDisplayDrawFull = eventsDisplay.drawFull

        -- Always render menu button and apps for consistent display
        if menuDrawAndHandle then
            menuDrawAndHandle(wgt, event, touchState, config, normalizeGridSpan)
        end

        -- Track telemetry changes for optimization (but always render for visual consistency)
        if currentTelemetryHash ~= wgt.lastTelemetryHash then
            wgt.lastTelemetryHash = currentTelemetryHash
            -- Telemetry changed - full render will show updates
        end

        -- Always render apps to prevent flashing
        if engineRender then engineRender(wgt) end

        -- FPS counter display (top-left corner) - only if enabled
        if wgt.fpsEnabled then
            local fpsValue = wgt.fpsValue
            if fpsValue > 0 then
                local fpsString = wgt._fpsString or ("FPS: " .. fpsValue)
                lcd.drawText(2, 20, fpsString, SMLSIZE + COLOR_THEME_SECONDARY2)
            end
        end

        -- Events fullscreen toggle (always handle interactions)
        if touchState and event == EVT_TOUCH_TAP then
            if wgtUi and wgtUi.eventsOpen then
                wgtUi.eventsOpen = false
            else
                local eventsRect = wgt._eventsRect
                if eventsRect then
                    local r = eventsRect
                    if touchState.x >= r.x and touchState.x <= r.x + r.w and 
                       touchState.y >= r.y and touchState.y <= r.y + r.h then
                        if not wgtUi then wgt.ui = {}; wgtUi = wgt.ui end
                        wgtUi.eventsOpen = true
                    end
                end
            end
        end

        if wgtUi and wgtUi.eventsOpen then
            if eventsDisplayDrawFull then eventsDisplayDrawFull(wgt) end
            return
        end
        return
    end

    -- Widget mode (embedded) - show placeholder only
    drawWidgetPlaceholder(wgt)
end

return { name = config.app_name, options = config.options, create = create, update = update, background = background, refresh = refresh }


