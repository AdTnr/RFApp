-- Brief: RPM calculation from Hspd telemetry sensor

local M = {}

local getValue = getValue

function M.update(wgt, config)
    -- Get RPM from Hspd telemetry sensor
    local rpm = (wgt.telem and wgt.telem.rpm) or getValue(config.SENSOR_RPM)
    
    -- Store RPM value for display
    wgt.rpmValue = rpm or 0
    
    -- Ensure non-negative
    if wgt.rpmValue < 0 then wgt.rpmValue = 0 end
end

return M

