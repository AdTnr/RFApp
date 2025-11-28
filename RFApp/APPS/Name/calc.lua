-- Brief: Model name retrieval from EdgeTX model info

local M = {}

local model = model

function M.update(wgt, config)
    -- Get model name from EdgeTX model info
    local modelInfo = model.getInfo()
    local name = modelInfo and modelInfo.name or "Unknown"
    
    -- Ensure name is a string
    if type(name) ~= "string" then
        name = tostring(name or "Unknown")
    end
    
    -- Remove ">" prefix character if present
    if #name > 0 and string.sub(name, 1, 1) == ">" then
        name = string.sub(name, 2)
    end
    
    wgt.modelName = name
end

return M

