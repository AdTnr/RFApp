-- Brief: In-memory event store with timestamped append and last-N retrieval

local M = {}

-- Share state across modules via a single global table so writers/readers see the same buffer
_G.RFAPP_EVENTS = _G.RFAPP_EVENTS or { recent = {}, maxRecent = 20 }
local GV = _G.RFAPP_EVENTS

local getTime = getTime
local function timestamp()
    if getDateTime then
        local dt = getDateTime()
        if dt then
            -- compact date + time (MM-DD HH:MM:SS)
            return string.format("%02d-%02d %02d:%02d:%02d", dt.mon, dt.day, dt.hour, dt.min, dt.sec)
        end
    end
    local t = getTime() or 0
    return string.format("T+%ds", math.floor(t / 100))
end

local function push(line)
    local recent = GV.recent
    recent[#recent + 1] = line
    if #recent > (GV.maxRecent or 20) then
        table.remove(recent, 1)
    end
end

function M.append(text)
    local line = string.format("%s - %s", timestamp(), tostring(text))
    push(line)
end

function M.getLast(n)
    n = n or 2
    local out = {}
    local recent = GV.recent
    local count = #recent
    for i = count, math.max(1, count - n + 1), -1 do
        out[#out + 1] = recent[i]
    end
    return out
end

return M


