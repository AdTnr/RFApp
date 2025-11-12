-- Brief: RPM calculation from Hspd telemetry sensor with min/max tracking

local M = {}

local getValue = getValue

function M.update(wgt, config)
    -- Get RPM from Hspd telemetry sensor
    local rpm = (wgt.telem and wgt.telem.rpm) or getValue(config.SENSOR_RPM)
    
    -- Store RPM value for display
    wgt.rpmValue = rpm or 0
    
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

