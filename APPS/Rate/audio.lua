-- Audio handling for Rate profile changes (telemetry sensor RTE#)

local M = {}

local playFile = playFile

local function playSound(path)
    if path then
        playFile(path)
    end
end

local function normalizeRateValue(val)
    if type(val) ~= "number" then return nil end
    local v = math.floor(val + 0.5)
    if v < 0 then
        v = 0
    elseif v > 6 then
        v = 6
    end
    return v
end

local function isEnabled(wgt, config)
    if wgt and wgt.rateAudioEnabled ~= nil then
        return wgt.rateAudioEnabled
    end
    if config and config.rateAudioEnabled ~= nil then
        return config.rateAudioEnabled
    end
    if config and config.RATE_AUDIO_DEFAULT ~= nil then
        return config.RATE_AUDIO_DEFAULT
    end
    return true
end

function M.handleRateAudio(wgt, config)
    if not wgt or not wgt.telem or not isEnabled(wgt, config) then return end

    local rateVal = normalizeRateValue(wgt.telem.rate)
    if rateVal == nil then return end

    if wgt.rateAudioLastValue == nil then
        wgt.rateAudioLastValue = rateVal
        return
    end

    if rateVal ~= wgt.rateAudioLastValue then
        local rateSounds = config.Sounds and config.Sounds.Rate
        if rateSounds then
            playSound(rateSounds.announcement)
            if rateVal >= 1 and rateVal <= 6 then
                local numberSound = rateSounds.numbers and rateSounds.numbers[rateVal]
                playSound(numberSound)
            end
        end
        wgt.rateAudioLastValue = rateVal
    end
end

return M

