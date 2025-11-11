-- Shared telemetry retrieval for RFApp (moved from APPS/Core)

local M = {}

local getValue = getValue
local getRSSI = getRSSI
local getTime = getTime

-- Debounce function for PID and Rate telemetry values
-- Ignores intermediate values when switching (e.g., 1 -> 2 -> 3 becomes 1 -> 3)
local function debounceValue(wgt, fieldName, rawValue, debounceMs)
    debounceMs = debounceMs or 20
    
    -- Initialize debounce state if needed
    if not wgt.telemDebounce then
        wgt.telemDebounce = {}
    end
    
    local debounce = wgt.telemDebounce[fieldName]
    if not debounce then
        debounce = {
            pendingValue = nil,
            pendingTime = 0,
            lastStableValue = nil
        }
        wgt.telemDebounce[fieldName] = debounce
    end
    
    local currentTime = getTime()
    
    -- If no stable value yet and we have a value, set it immediately (first time)
    if debounce.lastStableValue == nil and rawValue ~= nil then
        debounce.lastStableValue = rawValue
        return rawValue
    end
    
    -- If value changed, start/restart debounce timer
    if rawValue ~= debounce.pendingValue then
        debounce.pendingValue = rawValue
        debounce.pendingTime = currentTime
        return debounce.lastStableValue -- Return last stable value while debouncing
    end
    
    -- If value is stable and debounce time has passed, update stable value
    if debounce.pendingValue ~= nil then
        local elapsed = currentTime - debounce.pendingTime
        if elapsed >= debounceMs then
            debounce.lastStableValue = debounce.pendingValue
            debounce.pendingValue = nil
            return debounce.lastStableValue
        else
            -- Still debouncing, return last stable value
            return debounce.lastStableValue
        end
    end
    
    -- No pending value, return current stable value
    return debounce.lastStableValue
end

function M.update(wgt, config)
    local t = wgt.telem
    if t == nil then t = {} end

    -- Debug: Check if we're getting called
    -- print("RFApp: telemetry.update() called")

    local dbg = config.Debug or {}
    local useDbg = (dbg.ENABLED == true) or (wgt.debug and wgt.debug.enabled == true)

    -- Core sensors (RotorFlight naming) or debug overrides
    if useDbg then
        t.volt = (wgt.debug and wgt.debug.volt) or dbg.VOLT or t.volt
        t.cells = (wgt.debug and wgt.debug.cells) or dbg.CELLS or t.cells
        t.pcnt = (wgt.debug and wgt.debug.pcnt) or dbg.PCNT or t.pcnt
        t.mah  = (wgt.debug and wgt.debug.mah)  or dbg.MAH  or t.mah
        t.arm  = (wgt.debug and wgt.debug.arm)  or dbg.ARM  or t.arm
        t.rssi = (wgt.debug and wgt.debug.rssi) or dbg.RSSI or t.rssi
        t.rpm  = (wgt.debug and wgt.debug.rpm) or dbg.RPM or t.rpm
        t.gov  = (wgt.debug and wgt.debug.gov) or dbg.GOV or t.gov
        t.pid  = (wgt.debug and wgt.debug.pid) or dbg.PID or t.pid
        t.rate = (wgt.debug and wgt.debug.rate) or dbg.RATE or t.rate
        t.resc = (wgt.debug and wgt.debug.resc) or dbg.RESC or t.resc
    else
        t.volt = getValue(config.SENSOR_VOLT)
        t.cells = getValue(config.SENSOR_CELLS)
        t.pcnt = getValue(config.SENSOR_PCNT)
        t.mah  = getValue(config.SENSOR_MAH)
        t.arm  = getValue(config.SENSOR_ARM)
        t.rssi = getRSSI()
        t.rpm  = getValue(config.SENSOR_RPM)
        t.gov  = getValue(config.SENSOR_GOV)
        
        -- Apply debouncing to PID and Rate telemetry
        local rawPid = getValue(config.SENSOR_PID)
        local rawRate = getValue(config.SENSOR_RATE)
        
        t.pid = debounceValue(wgt, "pid", rawPid, 50)
        t.rate = debounceValue(wgt, "rate", rawRate, 50)
        
        t.resc = getValue(config.SENSOR_RESC)

        -- Debug output to check sensor values
        -- if t.volt then
        --     print(string.format("RFApp: V=%.2f, C=%s, RSSI=%s, ARM=%s", t.volt or 0, tostring(t.cells), tostring(t.rssi), tostring(t.arm)))
        -- end

        -- Debug: Check what sensors are available
        -- local testSensors = {"Vbat", "Bat%", "Capa", "Cel#", "ARM", "Hspd", "Gov", "PID#", "RTE#", "Resc", "RxBt", "RSSI"}
        -- for _, sensor in ipairs(testSensors) do
        --     local val = getValue(sensor)
        --     if val then
        --         print(string.format("RFApp: Sensor %s = %s", sensor, tostring(val)))
        --     end
        -- end
    end

    wgt.telem = t
    return t
end

-- Calculate hash of telemetry values for change detection optimization
-- Optimized: avoids unnecessary math.floor for integer values, caches local variable
function M.calculateTelemetryHash(telem)
    if not telem then return 0 end
    -- Hash key telemetry values that affect display
    local hash = 0
    local v = telem.volt
    if v then hash = hash + (v * 100) end
    v = telem.current
    if v then hash = hash + (v * 100) end
    v = telem.mah
    if v then hash = hash + v end
    v = telem.percent
    if v then hash = hash + v end
    v = telem.cells
    if v then hash = hash + v end
    v = telem.rssi
    if v then hash = hash + v end
    v = telem.pid
    if v then hash = hash + v end
    v = telem.rate
    if v then hash = hash + v end
    v = telem.arm
    if v then hash = hash + v end
    v = telem.rescue
    if v then hash = hash + v end
    v = telem.rpm
    if v then hash = hash + v end
    v = telem.gov
    if v then hash = hash + v end
    return hash
end

return M


