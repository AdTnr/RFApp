local M = {}

local playFile = playFile

local function playSound(path)
    if path then
        playFile(path)
    end
end

local function isRateEnabled(wgt, config)
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

local function handlePidAudioInternal(wgt, config)
    if not wgt or not wgt.telem then return end

    local currentVal = wgt.telem.pid
    if currentVal == nil then return end

    if wgt.pidAudioLastPid == nil then
        wgt.pidAudioLastPid = currentVal
        return
    end

    if currentVal ~= wgt.pidAudioLastPid then
        if currentVal >= 1 and currentVal <= 6 then
            local combinedSound = config.AUDIO_PATH .. "Profile_" .. currentVal .. ".wav"
            playSound(combinedSound)
        end
        wgt.pidAudioLastPid = currentVal
    end
end

local function handleRateAudioInternal(wgt, config)
    if not wgt or not wgt.telem then return end

    if not isRateEnabled(wgt, config) then return end

    local currentVal = wgt.telem.rate
    if currentVal == nil then return end

    if wgt.rateAudioLastValue == nil then
        wgt.rateAudioLastValue = currentVal
        return
    end

    if currentVal ~= wgt.rateAudioLastValue then
        if currentVal >= 1 and currentVal <= 6 then
            local combinedSound = config.AUDIO_PATH .. "Rate_" .. currentVal .. ".wav"
            playSound(combinedSound)
        end
        wgt.rateAudioLastValue = currentVal
    end
end

function M.handleRateAudio(wgt, config)
    handleRateAudioInternal(wgt, config)
end

function M.handlePidAudio(wgt, config)
    handlePidAudioInternal(wgt, config)
end

return M
