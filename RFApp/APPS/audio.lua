-- Unified audio handling for profile changes (Rate and PID telemetry sensors)

local M = {}

local playFile = playFile

local function playSound(path)
    if path then
        playFile(path)
    end
end

local function normalizeValue(val)
    if type(val) ~= "number" then return nil end
    local v = math.floor(val + 0.5)
    if v < 0 then
        v = 0
    elseif v > 6 then
        v = 6
    end
    return v
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

-- Generic function to handle profile audio changes
local function handleProfileAudio(wgt, config, telemField, lastValueField, soundConfig, announcementSound)
    if not wgt or not wgt.telem then return end

    -- Check if rate audio is enabled for rate changes
    if telemField == "rate" and not isRateEnabled(wgt, config) then return end

    local currentVal = normalizeValue(wgt.telem[telemField])
    if currentVal == nil then return end

    if wgt[lastValueField] == nil then
        wgt[lastValueField] = currentVal
        return
    end

    if currentVal ~= wgt[lastValueField] then
        local profileSounds = config.Sounds and config.Sounds[soundConfig]
        if profileSounds then
            playSound(profileSounds[announcementSound])
            if currentVal >= 1 and currentVal <= 6 then
                local numberSound = profileSounds.numbers and profileSounds.numbers[currentVal]
                playSound(numberSound)
            end
        end
        wgt[lastValueField] = currentVal
    end
end

function M.handleRateAudio(wgt, config)
    handleProfileAudio(wgt, config, "rate", "rateAudioLastValue", "Rate", "announcement")
end

function M.handlePidAudio(wgt, config)
    handleProfileAudio(wgt, config, "pid", "pidAudioLastPid", "Pid", "profile")
end

return M
