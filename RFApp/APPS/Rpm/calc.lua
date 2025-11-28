-- Brief: RPM calculation from Hspd telemetry sensor with min/max tracking

local M = {}

local getValue = getValue
local getTime = getTime

function M.update(wgt, config)
    -- Get RPM from Hspd telemetry sensor
    local rpm = (wgt.telem and wgt.telem.rpm) or getValue(config.SENSOR_RPM)
    local currentTime = getTime()
    
    -- Initialize stuck RPM detection if needed
    if wgt._rpmStuckValue == nil then
        wgt._rpmStuckValue = rpm or 0
        wgt._rpmStuckTime = currentTime
        wgt._rpmStuckToZero = false
    end
    
    -- Get raw telemetry RPM value
    local rawRpm = rpm or 0
    
    -- Check if RPM is stuck (same value) and below 1000 RPM
    local rpmValue = rawRpm
    
    -- If we've already set RPM to 0 due to being stuck, keep it at 0 until telemetry changes or goes above 1000
    if wgt._rpmStuckToZero then
        if rawRpm >= 1000 or rawRpm ~= wgt._rpmStuckValue then
            -- Telemetry recovered or changed - reset stuck state
            wgt._rpmStuckToZero = false
            wgt._rpmStuckValue = rawRpm
            wgt._rpmStuckTime = currentTime
            rpmValue = rawRpm
        else
            -- Still stuck - keep showing 0
            rpmValue = 0
        end
    elseif rawRpm < 1000 then
        -- RPM is below 1000 - check if stuck
        if rawRpm == wgt._rpmStuckValue then
            -- Same value - check if stuck for more than 3 seconds (300 ticks)
            local elapsed = currentTime - wgt._rpmStuckTime
            if elapsed >= 300 then
                -- Stuck for more than 3 seconds - set to 0
                rpmValue = 0
                wgt._rpmStuckToZero = true
            end
        else
            -- Value changed - reset stuck tracking
            wgt._rpmStuckValue = rawRpm
            wgt._rpmStuckTime = currentTime
        end
    else
        -- RPM is 1000 or above - reset stuck tracking
        wgt._rpmStuckValue = rawRpm
        wgt._rpmStuckTime = currentTime
        wgt._rpmStuckToZero = false
    end
    
    -- Store RPM value for display
    wgt.rpmValue = rpmValue
    
    -- Ensure non-negative
    if wgt.rpmValue < 0 then wgt.rpmValue = 0 end
    
    -- Initialize min/max RPM tracking if needed
    if wgt.rpmMin == nil then
        wgt.rpmMin = wgt.rpmValue
    end
    if wgt.rpmMax == nil then
        wgt.rpmMax = wgt.rpmValue
    end
    
    -- Only update min/max when governor is ACTIVE (state 4)
    local govValue = wgt.govValue
    if govValue == 4 then
        -- Governor is ACTIVE - check if this is the first time entering ACTIVE state
        if wgt._govWasActive ~= true then
            -- First time governor becomes ACTIVE - reset min/max to current RPM
            wgt.rpmMin = wgt.rpmValue
            wgt.rpmMax = wgt.rpmValue
            wgt._govWasActive = true
        else
            -- Governor was already ACTIVE - track min/max RPM normally
            if wgt.rpmValue < wgt.rpmMin then
                wgt.rpmMin = wgt.rpmValue
            end
            if wgt.rpmValue > wgt.rpmMax then
                wgt.rpmMax = wgt.rpmValue
            end
        end
    else
        -- Governor is not ACTIVE - reset flag so min/max will reset next time it becomes active
        wgt._govWasActive = false
    end
    -- If governor is not ACTIVE, min/max values remain unchanged (frozen)
end

return M

