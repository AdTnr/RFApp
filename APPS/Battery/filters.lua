-- Voltage filtering functions for battery percentage calculation (moved)

local M = {}

local getTime = getTime
local math = math

function M.getFilteredvPercent(wgt)
    local count = #wgt.vflt
    if count == 0 then return 0 end
    local sum = 0
    local validCount = 0
    for i=1, count do
        if wgt.vflt[i] > 0 then
            sum = sum + wgt.vflt[i]
            validCount = validCount + 1
        end
    end
    if validCount == 0 then return 0 end
    return math.ceil(sum / validCount)
end

function M.preallocateFilterArray(wgt, config)
    if wgt.vfltSamples > 0 and #wgt.vflt == 0 then
        for i = 1, wgt.vfltSamples do wgt.vflt[i] = nil end
    end
end

function M.updateFilteredvPercent(wgt, vPercent, config)
    if wgt.vfltSamples == 0 or wgt.vfltSamples == nil then
        wgt.vfltSamples = config.VFLT_SAMPLES_DEFAULT
        M.preallocateFilterArray(wgt, config)
    end
    local hasValidSamples = false
    for i=1, #wgt.vflt do
        if wgt.vflt[i] ~= nil and wgt.vflt[i] > 0 then hasValidSamples = true break end
    end
    if vPercent > 0 and getTime() > wgt.vfltNextUpdate and wgt.vfltSamples > 0 then
        wgt.vflt[wgt.vflti + 1] = vPercent
        wgt.vflti = (wgt.vflti + 1) % wgt.vfltSamples
        wgt.vfltNextUpdate = getTime() + wgt.vfltInterval
    end
    if not hasValidSamples and vPercent > 0 then return vPercent end
    return M.getFilteredvPercent(wgt)
end

return M


