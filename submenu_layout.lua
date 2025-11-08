-- Brief: Layout engine for submenu screens (Settings, Debug) with automatic spacing

local M = {}

-- Control types
M.CONTROL_DROPDOWN = "dropdown"
M.CONTROL_SLIDER = "slider"
M.CONTROL_TOGGLE = "toggle"
M.CONTROL_LABEL = "label"

-- Helper to estimate text height
local function getTextHeight(text, size)
    local _, h = lcd.sizeText(text or "Ag", size)
    return h
end

function M.new(config)
    local layout = {
        config = config or {},
        controls = {},
        titleText = nil,
    }
    
    -- Get spacing config with defaults
    local cfg = layout.config.Submenu or {}
    layout.titleSize = cfg.TITLE_SIZE or SMLSIZE
    layout.titlePadding = cfg.TITLE_PADDING or 8
    layout.labelSize = cfg.LABEL_SIZE or SMLSIZE
    layout.dropdownLabelPadding = cfg.DROPDOWN_LABEL_PADDING or 8
    layout.sliderLabelPadding = cfg.SLIDER_LABEL_PADDING or 8
    layout.controlHeight = cfg.CONTROL_HEIGHT or 28
    layout.controlSpacing = cfg.CONTROL_SPACING or 38  -- Space between label start positions
    layout.sidePadding = cfg.SIDE_PADDING or 12
    layout.topPadding = cfg.TOP_PADDING or 8
    
    function layout.addTitle(text)
        layout.titleText = text
    end
    
    function layout.addControl(label, controlType, controlData)
        local control = {
            label = label,
            type = controlType,
            data = controlData or {},
        }
        layout.controls[#layout.controls + 1] = control
        return control
    end
    
    function layout.calculatePositions(screenX, screenY, screenW, screenH)
        local positions = {}
        local y = screenY + layout.topPadding
        
        -- Title position
        if layout.titleText then
            local titleHeight = getTextHeight(layout.titleText, layout.titleSize)
            positions.title = {
                x = screenX + layout.sidePadding,
                y = y,
                text = layout.titleText,
                size = layout.titleSize,
            }
            y = y + titleHeight + layout.titlePadding
        end
        
        -- Calculate control positions
        local controlY = y
        local labelHeight = getTextHeight("Ag", layout.labelSize)
        
        for i, control in ipairs(layout.controls) do
            local labelY = controlY
            -- Use different padding based on control type
            local labelPadding
            if control.type == M.CONTROL_SLIDER then
                labelPadding = layout.sliderLabelPadding
            else
                labelPadding = layout.dropdownLabelPadding
            end
            local controlYPos = labelY + labelHeight + labelPadding
            
            positions[i] = {
                label = {
                    text = control.label,
                    x = screenX + layout.sidePadding,
                    y = labelY,
                    size = layout.labelSize,
                },
                control = {
                    type = control.type,
                    x = screenX + layout.sidePadding,
                    y = controlYPos,
                    w = screenW - 2 * layout.sidePadding,
                    h = layout.controlHeight,
                    data = control.data,
                },
            }
            
            -- Move to next control position: next label starts at controlSpacing pixels from current label
            controlY = controlY + layout.controlSpacing
        end
        
        -- Calculate total content height for scrolling
        local totalHeight = controlY - screenY
        positions.totalHeight = totalHeight
        positions.contentStartY = y
        
        return positions
    end
    
    function layout.getScrollableHeight(screenH, contentStartY)
        return screenH - contentStartY - layout.sidePadding
    end
    
    return layout
end

return M

