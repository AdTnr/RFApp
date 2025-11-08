-- Audio handling for PID profile changes

local M = {}

local playFile = playFile

local function playSound(path)
    if path then
        playFile(path)
    end
end

local function normalizePidValue(val)
    if type(val) ~= "number" then return nil end
    local v = math.floor(val + 0.5)
    if v < 0 then v = 0 elseif v > 6 then v = 6 end
    return v
end

function M.handlePidAudio(wgt, config)
    if not wgt or not wgt.telem then return end

    local pidVal = normalizePidValue(wgt.telem.pid)
    if pidVal == nil then return end

    if wgt.pidAudioLastPid == nil then
        wgt.pidAudioLastPid = pidVal
        return
    end

    if pidVal ~= wgt.pidAudioLastPid then
        local pidSounds = config.Sounds and config.Sounds.Pid
        if pidSounds then
            playSound(pidSounds.profile)
            if pidVal >= 1 and pidVal <= 6 then
                local numberSound = pidSounds.numbers and pidSounds.numbers[pidVal]
                playSound(numberSound)
            end
        end
        wgt.pidAudioLastPid = pidVal
    end
end

return M



