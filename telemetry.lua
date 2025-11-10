-- Shared telemetry retrieval for RFApp (moved from APPS/Core)

local M = {}

local getValue = getValue
local getRSSI = getRSSI

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
        t.pid  = getValue(config.SENSOR_PID)
        t.rate = getValue(config.SENSOR_RATE)
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
function M.calculateTelemetryHash(telem)
    if not telem then return 0 end
    -- Hash key telemetry values that affect display
    local hash = 0
    if telem.volt then hash = hash + math.floor(telem.volt * 100) end
    if telem.current then hash = hash + math.floor(telem.current * 100) end
    if telem.mah then hash = hash + telem.mah end
    if telem.percent then hash = hash + telem.percent end
    if telem.cells then hash = hash + telem.cells end
    if telem.rssi then hash = hash + telem.rssi end
    if telem.pid then hash = hash + telem.pid end
    if telem.rate then hash = hash + telem.rate end
    if telem.arm then hash = hash + telem.arm end
    if telem.rescue then hash = hash + telem.rescue end
    if telem.rpm then hash = hash + telem.rpm end
    if telem.gov then hash = hash + telem.gov end
    return hash
end

return M


