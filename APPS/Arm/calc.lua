-- Simple ARM telemetry updater

local M = {}

local events = loadScript("/WIDGETS/RFApp/APPS/Events/store.lua", "tcd")()

local getValue = getValue

function M.update(wgt, config)
    local arm = (wgt.telem and wgt.telem.arm) or getValue(config.SENSOR_ARM)
    wgt.armValue = arm
    -- Mapping per telemetry spec:
    -- 0: Disarmed, never armed
    -- 1: Currently armed
    -- 2: Disarmed, but was armed before
    -- 3: Currently armed and was armed before (1+2)
    -- 4: Was armed with prearm (currently disarmed)
    -- 5: Currently armed and was armed with prearm (1+4)
    if arm == nil then
        wgt.armState = "UNKNN"
        wgt.isArmed = false
        wgt.armInfo = ""
        return
    end

    local armedStates = { [1]=true, [3]=true, [5]=true }
    local info = ""
    if arm == 0 then info = "never armed"
    elseif arm == 2 then info = "was armed and now disarmed"
    elseif arm == 3 then info = "was armed and now armed"
    elseif arm == 4 then info = "prearmed and now disarmed"
    elseif arm == 5 then info = "prearmed and now armed" end

    wgt.isArmed = armedStates[arm] == true
    wgt.armState = wgt.isArmed and "ARMED" or "SAFE"
    wgt.armInfo = info

    -- Record transitions as events when state changes
    if wgt._lastLoggedArm ~= wgt.armState then
        local msg = "ARM: " .. wgt.armState
        if wgt.armInfo and wgt.armInfo ~= "" then
            msg = msg .. " (" .. wgt.armInfo .. ")"
        end
        if events and events.append then events.append(msg) end
        wgt._lastLoggedArm = wgt.armState
    end
end

return M


