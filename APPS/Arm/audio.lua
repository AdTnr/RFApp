-- Audio for ARM state transitions

local M = {}

local playFile = playFile

local function playSound(path)
    if path then
        playFile(path)
    end
end

local function getArmSound(config, key)
    local sounds = config.Sounds and config.Sounds.Arm
    return sounds and sounds[key]
end

local function playArmed(config)
    playSound(getArmSound(config, "armed"))
end

local function playDisarmed(config)
    playSound(getArmSound(config, "disarmed"))
end

function M.handleArmAudio(wgt, config)
    if wgt.isArmed == nil then return end
    if wgt.armAudioLastArmed == nil then
        wgt.armAudioLastArmed = not wgt.isArmed -- force announce first time
    end
    if wgt.isArmed ~= wgt.armAudioLastArmed then
        if wgt.isArmed then
            playArmed(config)
        else
            playDisarmed(config)
        end
        wgt.armAudioLastArmed = wgt.isArmed
    end
end

return M


