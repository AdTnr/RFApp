-- Audio handler for rescue state transitions

local M = {}

local playFile = playFile

local function playSound(path)
    if path then
        playFile(path)
    end
end

function M.handleRescueAudio(wgt, config)
    if not wgt or not config then return end

    local idx = wgt.rescueStateIndex
    if type(idx) ~= "number" or idx < 0 then
        wgt._lastRescueAudio = nil
        return
    end

    if wgt._lastRescueAudio == idx then
        return
    end

    local sounds = config.Sounds and config.Sounds.Rescue and config.Sounds.Rescue.states
    local path = sounds and sounds[idx]
    if path then
        playSound(path)
    end
    wgt._lastRescueAudio = idx
end

return M


