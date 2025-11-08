-- Brief: Timing utilities and telemetry reset detection for RFApp

local app_name, p2 = ...

local M = {}
M.app_name = app_name

local function log(s)
    -- print(M.app_name .. ": " .. s)
end

function M.periodicInit()
    local t = {}
    t.startTime = -1
    t.durationMili = -1
    return t
end

function M.periodicStart(t, durationMili)
    t.startTime = getTime()
    t.durationMili = durationMili
end

function M.periodicHasPassed(t)
    if (t.durationMili <= 0) then return false end
    local elapsed = getTime() - t.startTime
    local elapsedMili = elapsed * 10
    if (elapsedMili < t.durationMili) then return false end
    return true
end

function M.getDurationMili(t)
    return t.durationMili
end

function M.detectResetEvent(wgt, callback_onTelemetryResetEvent)
    local currMinRSSI = getValue('RSSI-')
    if (currMinRSSI == nil) then return end
    if (currMinRSSI == wgt.telemResetLowestMinRSSI) then return end
    if (currMinRSSI < wgt.telemResetLowestMinRSSI) then
        wgt.telemResetLowestMinRSSI = currMinRSSI
        return
    end
    wgt.telemResetLowestMinRSSI = 101
    callback_onTelemetryResetEvent(wgt)
end

return M


