-- Brief: Governor state calculation from Gov telemetry sensor

local M = {}

local events = loadScript("/WIDGETS/RFApp/APPS/Events/store.lua", "tcd")()

local getValue = getValue

-- State mapping: numeric value -> display word
local stateMap = {
    [0] = "GOV OFF",
    [1] = "IDLE",
    [2] = "SPOOLUP",
    [3] = "RECOVERY",
    [4] = "ACTIVE",
    [5] = "HOLD",
    [6] = "FALLBACK",
    [7] = "AUTO",
    [8] = "BAILOUT",
    [9] = "BYPASS",
}

-- State descriptions for event logs (brief versions of table descriptions)
local stateDesc = {
    [0] = "Motor off",
    [1] = "Thr below handover",
    [2] = "Spooling to target",
    [3] = "Recovering from hold",
    [4] = "Locked on target",
    [5] = "Throttle off",
    [6] = "RPM signal lost",
    [7] = "Autorotation",
    [8] = "Auto bailout",
    [9] = "Gov disabled",
}

function M.update(wgt, config)
    local gov = (wgt.telem and wgt.telem.gov) or getValue(config.SENSOR_GOV)
    wgt.govValue = gov
    
    if gov == nil then
        wgt.govState = "UNKNOWN"
        return
    end
    
    -- Map numeric value to display word
    local stateWord = stateMap[gov] or "UNKNOWN"
    wgt.govState = stateWord
    
    -- Record transitions as events when state changes
    if wgt._lastLoggedGov ~= wgt.govState then
        local msg = "GOV: " .. wgt.govState
        local desc = stateDesc[gov]
        if desc and desc ~= "" then
            msg = msg .. " (" .. desc .. ")"
        end
        if events and events.append then events.append(msg) end
        wgt._lastLoggedGov = wgt.govState
    end
end

return M

