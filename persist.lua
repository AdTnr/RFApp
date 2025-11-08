-- Brief: Save/load global RFApp options (reserve, text color) to SD card

local M = {}

local function getSettingsPath()
    return "/WIDGETS/RFApp/settings.lua"
end

function M.loadOptions()
    local path = getSettingsPath()
    local f = io.open(path, "r")
    if not f then return {} end
    io.close(f)
    local chunk = loadScript(path, "tcd")
    if not chunk then return {} end
    local ok, tbl = pcall(chunk)
    if not ok or type(tbl) ~= "table" then return {} end
    return tbl
end

function M.saveOptions(opts)
    local path = getSettingsPath()
    local reserve = tonumber(opts.reserve or opts["Reserve %"]) or 0
    local color = tonumber(opts.colorToggle)
    if color == nil then color = tonumber(opts["Text Color (0=White,1=Black)"]) or 0 end
    local rate = opts.rateAudio
    if rate == nil then rate = opts.rateAudioEnabled end
    if type(rate) == "boolean" then
        rate = rate and 1 or 0
    else
        rate = tonumber(rate) or 0
    end

    local out = {
        "return {",
        string.format("  reserve = %d,", reserve),
        string.format("  colorToggle = %d,", color),
        string.format("  rateAudio = %d,", rate),
        "}",
    }
    local f = io.open(path, "w")
    if f then
        for _, line in ipairs(out) do
            io.write(f, line)
            io.write(f, "\n")
        end
        io.close(f)
    end
end

return M


