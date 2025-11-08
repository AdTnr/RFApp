-- Rescue state telemetry handler

local M = {}

local lcd = lcd
local math = math

local events = loadScript("/WIDGETS/RFApp/APPS/Events/store.lua", "tcd")()

local getValue = getValue

local stateMap = {
    [0] = { label = "OFF",   name = "OFF",    bg = COLOR_THEME_PRIMARY2, fg = COLOR_THEME_PRIMARY1 },
    [1] = { label = "PULL",  name = "PULLUP", bg = ORANGE,               fg = COLOR_THEME_PRIMARY1 },
    [2] = { label = "FLIP",  name = "FLIP",   bg = RED,                  fg = COLOR_THEME_PRIMARY1 },
    [3] = { label = "CLIMB", name = "CLIMB",  bg = YELLOW,               fg = COLOR_THEME_PRIMARY1 },
    [4] = { label = "HOVER", name = "HOVER",  bg = GREEN,                fg = COLOR_THEME_PRIMARY1 },
    [5] = { label = "EXIT",  name = "EXIT",   bg = lcd.RGB(90, 90, 255), fg = COLOR_THEME_PRIMARY1 },
}

local defaultState = { label = "UNK", name = "UNKNOWN", bg = COLOR_THEME_PRIMARY2, fg = COLOR_THEME_PRIMARY1 }

local function resolveState(idx)
    if type(idx) ~= "number" then return defaultState end
    return stateMap[idx] or defaultState
end

function M.update(wgt, config)
    if not wgt then return end

    local resc = (wgt.telem and wgt.telem.resc)
    if resc == nil then
        resc = getValue(config.SENSOR_RESC)
    end

    if type(resc) ~= "number" then
        resc = -1
    else
        resc = math.floor(resc + 0.5)
    end

    local entry = resolveState(resc)

    wgt.rescueStateIndex = resc
    wgt.rescueLabel = entry.label
    wgt.rescueBg = entry.bg
    wgt.rescueFg = entry.fg
    wgt.rescueStateName = entry.name

    if wgt._lastRescueState ~= resc then
        if entry ~= defaultState then
            if events and events.append then
                events.append(string.format("Rescue: %s", entry.name))
            end
        end
        wgt._lastRescueState = resc
    end
end

return M


