-- Brief: BEC voltage calculation from Vbec telemetry sensor with min tracking

local M = {}

local getValue = getValue

function M.update(wgt, config)
    -- Get BEC voltage from Vbec telemetry sensor
    local vbec = (wgt.telem and wgt.telem.vbec) or getValue(config.SENSOR_VBEC)
    
    -- Store BEC voltage value for display
    wgt.becValue = vbec or 0
    
    -- Ensure non-negative
    if wgt.becValue < 0 then wgt.becValue = 0 end
    
    -- Initialize min BEC tracking if needed
    if wgt.becMin == nil then
        wgt.becMin = wgt.becValue
    end
    
    -- Only update min when governor is ACTIVE (state 4)
    local govValue = wgt.govValue
    if govValue == 4 then
        -- Governor is ACTIVE - check if this is the first time entering ACTIVE state
        if wgt._govWasActiveForBec ~= true then
            -- First time governor becomes ACTIVE - reset min to current BEC voltage
            wgt.becMin = wgt.becValue
            wgt._govWasActiveForBec = true
        else
            -- Governor was already ACTIVE - track min BEC voltage normally
            if wgt.becValue < wgt.becMin then
                wgt.becMin = wgt.becValue
            end
        end
    else
        -- Governor is not ACTIVE - reset flag so min will reset next time it becomes active
        wgt._govWasActiveForBec = false
    end
    -- If governor is not ACTIVE, min value remains unchanged (frozen)
end

return M

