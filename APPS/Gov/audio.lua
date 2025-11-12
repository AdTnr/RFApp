-- Audio handler for governor state transitions

local M = {}

local playFile = playFile

local function playSound(path)
    if path then
        playFile(path)
    end
end

function M.handleGovAudio(wgt, config)
    if not wgt or not config then return end

    local idx = wgt.govValue
    if type(idx) ~= "number" or idx < 0 then
        wgt._lastGovAudio = nil
        return
    end

    -- Only play audio when state changes
    if wgt._lastGovAudio == idx then
        return
    end

    local sounds = config.Sounds and config.Sounds.Gov and config.Sounds.Gov.states
    local path = sounds and sounds[idx]
    
    -- Only play if there's an audio file for this state
    if path then
        playSound(path)
    end
    
    wgt._lastGovAudio = idx
end

return M

