-- Simple ARM telemetry updater

local M = {}

local events = loadScript("/WIDGETS/RFApp/APPS/Events/store.lua", "tcd")()

local getValue = getValue

local stateMap = {
    [0] = { label = "SAFE",    name = "SAFE_NEVER_ARMED",   bg = COLOR_THEME_SECONDARY1, fg = COLOR_THEME_PRIMARY2 },
    [1] = { label = "ARMED",   name = "ARMED",              bg = RED,                    fg = COLOR_THEME_PRIMARY1 },
    [2] = { label = "SAFE",    name = "SAFE_WAS_ARMED",     bg = COLOR_THEME_SECONDARY1, fg = COLOR_THEME_PRIMARY2 },
    [3] = { label = "ARMED",   name = "ARMED_WAS_ARMED",    bg = RED,                    fg = COLOR_THEME_PRIMARY1 },
    [4] = { label = "SAFE",    name = "SAFE_PREARMED",      bg = ORANGE,                 fg = COLOR_THEME_PRIMARY1 },
    [5] = { label = "ARMED",   name = "ARMED_PREARMED",     bg = RED,                    fg = COLOR_THEME_PRIMARY1 },
}

-- State descriptions for event logs (brief versions of state meanings)
local stateDesc = {
    [0] = "never armed",
    [2] = "was armed and now disarmed",
    [3] = "was armed and now armed",
    [4] = "prearmed and now disarmed",
    [5] = "prearmed and now armed",
}

local defaultState = { label = "UNK", name = "UNKNOWN", bg = COLOR_THEME_SECONDARY1, fg = COLOR_THEME_PRIMARY2 }

local function resolveState(idx)
    if type(idx) ~= "number" then return defaultState end
    return stateMap[idx] or defaultState
end

function M.update(wgt, config)
    if not wgt then return end

    local arm = (wgt.telem and wgt.telem.arm)
    if arm == nil then
        arm = getValue(config.SENSOR_ARM)
    end

    if type(arm) ~= "number" then
        arm = -1
    else
        arm = math.floor(arm + 0.5)
    end

    local entry = resolveState(arm)

    wgt.armValue = arm
    wgt.armState = entry.label
    wgt.armBg = entry.bg
    wgt.armFg = entry.fg
    wgt.armStateName = entry.name

    -- Determine if armed for backward compatibility
    local armedStates = { [1]=true, [3]=true, [5]=true }
    wgt.isArmed = armedStates[arm] == true

    if wgt._lastArmState ~= arm then
        if entry ~= defaultState then
            local msg = string.format("Arm: %s", entry.label)
            local desc = stateDesc[arm]
            if desc and desc ~= "" then
                msg = msg .. string.format(" (%s)", desc)
            end
            if events and events.append then
                events.append(msg)
            end
        end
        wgt._lastArmState = arm
    end
end

return M


