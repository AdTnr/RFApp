-- Brief: Governor state calculation from Gov telemetry sensor

local M = {}

local events = loadScript("/WIDGETS/RFApp/APPS/Events/store.lua", "tcd")()
local lcd = lcd

local getValue = getValue

local stateMap = {
    [0] = { label = "OFF",     name = "GOV_OFF",   bg = lcd.RGB(60, 60, 60),   fg = lcd.RGB(255, 255, 255) },
    [1] = { label = "IDLE",    name = "IDLE",      bg = lcd.RGB(0, 150, 255),  fg = COLOR_THEME_PRIMARY1 },
    [2] = { label = "SPOOLUP", name = "SPOOLUP",   bg = YELLOW,                 fg = COLOR_THEME_PRIMARY1 },
    [3] = { label = "RECOVERY",name = "RECOVERY",  bg = YELLOW,                 fg = COLOR_THEME_PRIMARY1 },
    [4] = { label = "ACTIVE",  name = "ACTIVE",    bg = GREEN,                  fg = COLOR_THEME_PRIMARY1 },
    [5] = { label = "HOLD",    name = "HOLD",      bg = ORANGE,                 fg = COLOR_THEME_PRIMARY1 },
    [6] = { label = "FALLBACK",name = "FALLBACK",  bg = RED,                    fg = COLOR_THEME_PRIMARY1 },
    [7] = { label = "AUTO",    name = "AUTO",      bg = lcd.RGB(0, 150, 255),  fg = COLOR_THEME_PRIMARY1 },
    [8] = { label = "BAILOUT", name = "BAILOUT",   bg = ORANGE,                 fg = COLOR_THEME_PRIMARY1 },
    [9] = { label = "BYPASS",  name = "BYPASS",    bg = lcd.RGB(80, 80, 80),   fg = COLOR_THEME_PRIMARY1 },
}

-- State descriptions for event logs (brief versions of table descriptions)
local stateDesc = {
    [0] = "Motor off",
    [1] = "Thr below handover",
    [2] = "Spooling to target",
    [3] = "Recovering from hold",
    [4] = "Locked on target",
    [5] = "Throttle off",
    [6] = "RPM signal lost",
    [7] = "Autorotation",
    [8] = "Auto bailout",
    [9] = "Gov disabled",
}

local defaultState = { label = "UNK", name = "UNKNOWN", bg = COLOR_THEME_SECONDARY1, fg = COLOR_THEME_PRIMARY2 }

local function resolveState(idx)
    if type(idx) ~= "number" then return defaultState end
    return stateMap[idx] or defaultState
end

function M.update(wgt, config)
    if not wgt then return end

    local gov = (wgt.telem and wgt.telem.gov)
    if gov == nil then
        gov = getValue(config.SENSOR_GOV)
    end

    if type(gov) ~= "number" then
        gov = -1
    else
        gov = math.floor(gov + 0.5)
    end

    local entry = resolveState(gov)

    wgt.govValue = gov
    wgt.govState = entry.label
    wgt.govBg = entry.bg
    wgt.govFg = entry.fg
    wgt.govStateName = entry.name

    if wgt._lastGovState ~= gov then
        if entry ~= defaultState then
            local msg = string.format("Gov: %s", entry.label)
            local desc = stateDesc[gov]
            if desc and desc ~= "" then
                msg = msg .. string.format(" (%s)", desc)
            end
            if events and events.append then
                events.append(msg)
            end
        end
        wgt._lastGovState = gov
    end
end

return M

