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
    
    -- Track max Amps continuously
    if wgt.ampsValue > wgt.ampsMax then
        wgt.ampsMax = wgt.ampsValue
    end
    
    -- Calculate power (watts) = current (amps) * voltage (volts)
    -- Use battery monitor voltage (vTotalLive) if available, otherwise use telemetry voltage
    local voltage = wgt.vTotalLive or (wgt.telem and wgt.telem.volt) or 0
    wgt.powerValue = wgt.ampsValue * voltage
    
    -- Initialize max power tracking if needed
    if wgt.powerMax == nil then
        wgt.powerMax = wgt.powerValue
    end
    
    -- Track max power continuously
    if wgt.powerValue > wgt.powerMax then
        wgt.powerMax = wgt.powerValue
    end
    
    -- Calculate horsepower (HP) = power (watts) / 745.7
    -- 1 HP = 745.7 watts (mechanical horsepower)
    wgt.hpower = wgt.powerValue / 745.7
    
    -- Calculate max horsepower from max power
    wgt.hpowerMax = wgt.powerMax / 745.7
end

return M

