-- Shared telemetry retrieval for RFApp (moved from APPS/Core)

local M = {}

local getValue = getValue
local getRSSI = getRSSI

function M.update(wgt, config)
    local t = wgt.telem
    if t == nil then t = {} end

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
    end

    wgt.telem = t
    return t
end

return M


