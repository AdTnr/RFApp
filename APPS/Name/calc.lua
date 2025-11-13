-- Brief: Model name retrieval from EdgeTX model info

local M = {}

local model = model

function M.update(wgt, config)
    -- Get model name from EdgeTX model info
    local modelInfo = model.getInfo()
    wgt.modelName = modelInfo and modelInfo.name or "Unknown"
end

return M

