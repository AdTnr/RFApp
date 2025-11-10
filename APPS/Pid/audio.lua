-- Unified audio handling for profile changes (Rate and PID telemetry sensors)

local M = {}

local playFile = playFile
local getTime = getTime

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

-- Check for simultaneous PID/Rate changes to the same value
local function checkSimultaneousChange(wgt, telemField, currentVal, otherField)
    if not wgt or not wgt.telem then return false end

    local otherCurrentVal = normalizeValue(wgt.telem[otherField])
    if otherCurrentVal == nil then return false end

    -- Check if the other field also changed to the same value recently
    local changeKey = telemField .. "_change_" .. currentVal
    local otherChangeKey = otherField .. "_change_" .. currentVal

    if wgt[otherChangeKey] and getTime() - wgt[otherChangeKey] <= 200 then -- 200ms window
        -- Both changed to same value within time window
        return true
    end

    -- Record this change
    wgt[changeKey] = getTime()
    return false
end

-- Generic function to handle profile audio changes
local function handleProfileAudio(wgt, config, telemField, lastValueField, soundConfig, announcementSound)
    if not wgt or not wgt.telem then return end

    -- Check if rate audio is enabled for rate changes
    if telemField == "rate" and not isRateEnabled(wgt, config) then return end

    local currentVal = normalizeValue(wgt.telem[telemField])
    if currentVal == nil then return end

    -- Never play audio when changing to zero
    if currentVal == 0 then
        wgt[lastValueField] = currentVal
        return
    end

    if wgt[lastValueField] == nil then
        wgt[lastValueField] = currentVal
        return
    end

    if currentVal ~= wgt[lastValueField] then
        local profileSounds = config.Sounds and config.Sounds[soundConfig]

        -- Check for simultaneous changes to same value
        local otherField = (telemField == "rate") and "pid" or "rate"
        local simultaneousChange = checkSimultaneousChange(wgt, telemField, currentVal, otherField)

        if profileSounds then
            -- If simultaneous change, only play the profile sound (no numbers)
            if simultaneousChange then
                playSound(profileSounds[announcementSound])
            else
                -- Normal behavior: play announcement + number
                playSound(profileSounds[announcementSound])
                if currentVal >= 1 and currentVal <= 6 then
                    local numberSound = profileSounds.numbers and profileSounds.numbers[currentVal]
                    playSound(numberSound)
                end
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
