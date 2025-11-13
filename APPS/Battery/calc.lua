-- Battery calculation functions for RFApp (moved to APPS/Battery)

local M = {}

local getValue = getValue
local getFieldInfo = getFieldInfo
local getTime = getTime
local getRSSI = getRSSI
local model = model
local playNumber = playNumber
local math = math

function M.applyReservePercentage(percent, reserve)
    if percent < reserve then
        return percent - reserve
    else
        local usable = 100 - reserve
        return (percent - reserve) / usable * 100
    end
end

function M.getCellPercent(cellValue, lipoPercentListSplit)
    if cellValue == nil then
        return 0
    end
    if (cellValue > 4.2) then
        return 100
    end
    for i1, v1 in ipairs(lipoPercentListSplit) do
        if (cellValue <= v1[#v1][1]) then
            for i2, v2 in ipairs(v1) do
                if v2[1] >= cellValue then
                    return v2[2]
                end
            end
        end
    end
    return 0
end

function M.calcCellCount(singleVoltage)
    if singleVoltage     < 4.3  then return 1
    elseif singleVoltage < 8.6  then return 2
    elseif singleVoltage < 12.9 then return 3
    elseif singleVoltage < 17.2 then return 4
    elseif singleVoltage < 21.5 then return 5
    elseif singleVoltage < 25.8 then return 6
    elseif singleVoltage < 30.1 then return 7
    elseif singleVoltage < 34.4 then return 8
    elseif singleVoltage < 38.7 then return 9
    elseif singleVoltage < 43.0 then return 10
    elseif singleVoltage < 51.6 then return 12
    elseif singleVoltage < 60.2 then return 14
    end
    return 1
end

function M.resetWidget(wgt, config)
    wgt.isDataAvailable = false
    wgt.vTotalLive = 0
    wgt.vCellLive = 0
    wgt.vPercent = 0
    wgt.mainValue = 0
    wgt.secondaryValue = 0
    wgt.vMah = 0
    wgt.useSensorP = false
    wgt.useSensorM = false
    wgt.useSensorC = false
    wgt.vflt = {}
    wgt.vflti = 0
    wgt.vfltNextUpdate = 0
    wgt.cellCount = 1
    wgt.cell_detected = false
    wgt.periodic1 = wgt.tools.periodicInit()
    wgt.bat_connected_low = 0
    wgt.bat_connected_low_played = false
    wgt.bat_connected_low_timer = 0
    wgt.rssiDisconnectTime = 0
    wgt.zeroVoltageTime = 0
    wgt.audioProcessedThisCycle = false
    wgt.wasTelemetryLost = true
    wgt.telemReconnectTime = 0
    wgt.batInsDetectDeadline = 0
    wgt.batLowOffset = 0
end

function M.onTelemetryResetEvent(wgt, config)
    wgt.telemResetCount = (wgt.telemResetCount or 0) + 1
    wgt.battPercentPlayed = -1
    wgt.battNextPlay = 0
    wgt.battPercentSetDuringCellDetection = false
    wgt.vMin = 99
    wgt.vMax = 0
    M.resetWidget(wgt, config)
end

function M.calculateBatteryData(wgt, config, filters, calc, audio)
    -- Use global rfConnected flag from telemetry.lua (based on *Cnt heartbeat detection)
    local currentTime = getTime()
    
    -- Check if RotorFlight is connected (rfConnected flag set by telemetry.lua)
    if wgt.rfConnected ~= true then
        -- RotorFlight not connected - reset widget
        M.resetWidget(wgt, config)
        return
    end
    
    -- RotorFlight is connected - set battery inserted detection deadline immediately (no delay)
    if wgt.batInsDetectDeadline == 0 then
        wgt.batInsDetectDeadline = currentTime + config.BAT_INSERTED_DETECT_WINDOW
    end

    local v = (wgt.telem and wgt.telem.volt) or getValue(config.SENSOR_VOLT)
    if v ~= nil and v == 0 then
        if wgt.zeroVoltageTime == 0 then
            wgt.zeroVoltageTime = currentTime
        end
        local elapsed = currentTime - wgt.zeroVoltageTime
        if elapsed >= config.ZERO_VOLTAGE_DELAY then
            M.resetWidget(wgt, config)
            return
        else
            wgt.isDataAvailable = false
            return
        end
    else
        if wgt.zeroVoltageTime > 0 then
            wgt.zeroVoltageTime = 0
        end
    end

    if type(v) == "table" then
        if (#v > 1) then
            wgt.isDataAvailable = false
            return
        end
    elseif not (v ~= nil and v >= 1) then
        wgt.isDataAvailable = false
        return
    end

    local sensorCells = (wgt.telem and wgt.telem.cells) or getValue(config.SENSOR_CELLS)
    wgt.useSensorC = (sensorCells ~= nil and sensorCells > 0)
    if wgt.useSensorC then
        local newCellCount = math.floor(sensorCells)
        if newCellCount ~= wgt.cellCount then
            wgt.cellCount = newCellCount
            wgt.cell_detected = true
            wgt.vMin = 99
            wgt.vMax = 0
        else
            wgt.cell_detected = true
        end
    elseif not wgt.cell_detected then
        local newCellCount = M.calcCellCount(v)
        if (wgt.tools.periodicHasPassed(wgt.periodic1)) then
            wgt.cell_detected = true
            wgt.periodic1 = wgt.tools.periodicInit()
            wgt.cellCount = newCellCount
        else
            if newCellCount ~= wgt.cellCount then
                wgt.vMin = 99
                wgt.vMax = 0
            end
            wgt.cellCount = newCellCount
        end
    end

    if v > wgt.vMax then wgt.vMax = v end
    wgt.vTotalLive = v
    wgt.vCellLive = wgt.vTotalLive / wgt.cellCount

    local pcnt = (wgt.telem and wgt.telem.pcnt) or getValue(config.SENSOR_PCNT)
    wgt.useSensorP = (pcnt ~= nil and pcnt >= 0)
    local basePercent
    if wgt.bat_connected_low == 1 then
        if wgt.useSensorP then
            local adjusted = pcnt - (wgt.batLowOffset or 0)
            if adjusted < 0 then adjusted = 0 end
            if adjusted > 100 then adjusted = 100 end
            basePercent = adjusted
        else
            basePercent = filters.updateFilteredvPercent(wgt, M.getCellPercent(wgt.vCellLive, config.lipoPercentListSplit), config)
        end
    elseif wgt.useSensorP then
        basePercent = pcnt
    else
        basePercent = filters.updateFilteredvPercent(wgt, M.getCellPercent(wgt.vCellLive, config.lipoPercentListSplit), config)
    end

    do
        local reserveVal = wgt.vReserve
        if wgt.options then
            local rv = wgt.options[config.OPT_RESERVE]
            if rv ~= nil then reserveVal = math.max(0, math.min(50, rv)) end
        end
        if reserveVal == nil then reserveVal = 0 end
        wgt.vReserve = reserveVal
        wgt.vPercent = M.applyReservePercentage(basePercent, reserveVal)
    end

    -- Battery inserted low detection window (after stabilization)
    if wgt.bat_connected_low == 0 then
        local now = getTime()
        if wgt.cell_detected
            and wgt.batInsDetectDeadline ~= 0 and now <= wgt.batInsDetectDeadline
            and wgt.vPercent > (config.batteryInsertedLowPercent or 98)
            and wgt.vCellLive < (config.LOW_BAT_INS_VOLTAGE or 4.08)
            and wgt.vCellLive >= (config.BATTERY_MIN_VOLTAGE or 3.0) then
            -- confirm with small delay if configured
            if wgt.bat_connected_low_timer == 0 then
                wgt.bat_connected_low_timer = now
            end
            local elapsed = now - wgt.bat_connected_low_timer
            if elapsed >= (config.BATTERY_CONNECTED_LOW_DELAY or 0) then
                wgt.bat_connected_low = 1
                -- capture offset between telemetry percent and voltage-derived percent
                if wgt.useSensorP then
                    local calcPercentRaw = M.getCellPercent(wgt.vCellLive, config.lipoPercentListSplit)
                    local offset = pcnt - calcPercentRaw
                    if offset < 0 then offset = 0 end
                    if offset > 100 then offset = 100 end
                    wgt.batLowOffset = offset
                else
                    wgt.batLowOffset = 0
                end
            end
        else
            wgt.bat_connected_low_timer = 0
        end
    end

    local mahValue = (wgt.telem and wgt.telem.mah) or getValue(config.SENSOR_MAH)
    wgt.useSensorM = (mahValue ~= nil and mahValue >= 0)
    if wgt.useSensorM then wgt.vMah = mahValue end

    wgt.mainValue = wgt.vCellLive
    wgt.secondaryValue = wgt.vTotalLive
    if wgt.mainValue < wgt.vMin and wgt.mainValue > 1 then wgt.vMin = wgt.mainValue end
    wgt.isDataAvailable = true
    if not wgt.cell_detected and wgt.tools.getDurationMili(wgt.periodic1) == -1 then
        wgt.tools.periodicStart(wgt.periodic1, config.TELEMETRY_STABILIZATION_DELAY * 10)
    end
end

return M


