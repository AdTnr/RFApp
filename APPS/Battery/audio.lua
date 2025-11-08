-- Audio and alert handling functions (aligned with RFBattery behavior)

local M = {}

local getValue = getValue
local getTime = getTime
local playHaptic = playHaptic
local playFile = playFile
local playNumber = playNumber
local math = math

local function playSound(path)
    if path then
        playFile(path)
    end
end

local function getBatterySounds(config)
    local sounds = config.Sounds
    return (sounds and sounds.Battery) or {}
end

function M.handleBatteryAlerts(wgt, config)
    if wgt.audioProcessedThisCycle then return end
    wgt.audioProcessedThisCycle = true

    local batterySounds = getBatterySounds(config)

    -- Determine disarmed state: prefer ARM app's isArmed flag; fallback to SENSOR_ARM==2
    local isDisarmed
    if wgt.isArmed ~= nil then
        isDisarmed = (wgt.isArmed == false)
    else
        local armValue = getValue(config.SENSOR_ARM)
        isDisarmed = (armValue ~= nil and armValue == 2)
    end

    -- Battery inserted low: always announce (tone+file), regardless of ARM
    if wgt.bat_connected_low == 1 and not wgt.bat_connected_low_played then
        wgt.bat_connected_low_played = true
        playHaptic(100, 0, PLAY_NOW)
        playSound(batterySounds.insertedLow)
    elseif wgt.bat_connected_low == 0 then
        wgt.bat_connected_low_played = false
    end

    -- Voice alerts (only when armed or ARM sensor missing) and data available
    if (not isDisarmed) and wgt.isDataAvailable then
        local fvpcnt = wgt.vPercent or 0
        local battva
        if fvpcnt > (config.singleStepThreshold or 15) then
            battva = math.ceil(fvpcnt / 10) * 10
        else
            battva = fvpcnt
        end

        -- Silence until cell_detected
        if not wgt.cell_detected then
            wgt.battPercentPlayed = battva
            wgt.battPercentSetDuringCellDetection = true
            return
        end

        local critical = (wgt.vReserve == 0) and (config.singleStepThreshold or 15) or 0

        if wgt.battPercentSetDuringCellDetection then
            wgt.battPercentSetDuringCellDetection = false
            wgt.battPercentPlayed = battva
            wgt.battNextPlay = getTime() + 500
            return
        end

        -- If not using Bat% telemetry and not near critical, silence routine reports
        if not wgt.useSensorP and battva > critical + (config.battLowMargin or 5) then
            wgt.battPercentPlayed = battva
        end

        local shouldAnnounce = (wgt.battPercentPlayed ~= battva or battva <= 0) and getTime() > (wgt.battNextPlay or 0)
        if battva == 100 then
            wgt.battPercentPlayed = battva
            return
        end

        if shouldAnnounce then
            wgt.battPercentPlayed = battva
            wgt.battNextPlay = getTime() + 500

            local statusSounds = batterySounds.status or {}
            if battva > critical + (config.battLowMargin or 5) then
                playSound(statusSounds.nominal)
            elseif battva > critical then
                playSound(statusSounds.low)
            else
                playSound(statusSounds.critical)
                playHaptic(100, 0, PLAY_NOW)
            end

            playNumber(battva, 13)
        end
    end
end

return M


