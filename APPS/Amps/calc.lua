-- Brief: Current (Amps) calculation from Curr telemetry sensor with max tracking

local M = {}

local getValue = getValue

function M.update(wgt, config)
    -- Get current from Curr telemetry sensor
    local curr = (wgt.telem and wgt.telem.curr) or getValue(config.SENSOR_CURR)
    
    -- Store current value for display
    wgt.ampsValue = curr or 0
    
    -- Ensure non-negative
    if wgt.ampsValue < 0 then wgt.ampsValue = 0 end
    
    -- Initialize max Amps tracking if needed
    if wgt.ampsMax == nil then
        wgt.ampsMax = wgt.ampsValue
    end
    
    -- Only update max when governor is ACTIVE (state 4)
    local govValue = wgt.govValue
    if govValue == 4 then
        -- Governor is ACTIVE - check if this is the first time entering ACTIVE state
        if wgt._govWasActiveForAmps ~= true then
            -- First time governor becomes ACTIVE - reset max to current Amps
            wgt.ampsMax = wgt.ampsValue
            wgt._govWasActiveForAmps = true
        else
            -- Governor was already ACTIVE - track max Amps normally
            if wgt.ampsValue > wgt.ampsMax then
                wgt.ampsMax = wgt.ampsValue
            end
        end
    else
        -- Governor is not ACTIVE - reset flag so max will reset next time it becomes active
        wgt._govWasActiveForAmps = false
    end
    -- If governor is not ACTIVE, max value remains unchanged (frozen)
end

return M

