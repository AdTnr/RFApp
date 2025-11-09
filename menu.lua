--[[
#########################################################################
#                                                                       #
# RFApp - Menu/Settings Module                                          #
#                                                                       #
# Contains settings page and menu button functionality                  #
#                                                                       #
#########################################################################
]]

-- Tear down the LVGL settings page and reset state when leaving app mode or pressing back
local function closeSettingsPage(wgt)
    if not (wgt and wgt.ui and wgt.ui.settingsOpen) then return end
    wgt.ui.settingsOpen = false
    if lvgl then
        lvgl.clear()
    end
end

local function openSettingsPage(wgt)
    if not lvgl then return end
    if not wgt.ui then wgt.ui = {} end

    wgt.ui.settingsValue = wgt.ui.settingsValue or 0
    wgt.ui.settingsOpen = true

    lvgl.clear()

    local page = lvgl.page({
        title = "RFApp Settings",
        subtitle = "Demo Control",
        back = function()
            closeSettingsPage(wgt)
        end,
    })

    local uit = {
        {
            type = "box",
            flexFlow = lvgl.FLOW_COLUMN,
            flexPad = lvgl.PAD_LARGE,
            w = LCD_W,
            children = {
                {
                    type = "box",
                    flexFlow = lvgl.FLOW_ROW,
                    children = {
                        { type = "label", text = "Demo Value:", font = BOLD },
                        {
                            type = "numberEdit",
                            min = -1024,
                            max = 1024,
                            step = 1,
                            w = 90,
                            get = function()
                                return wgt.ui.settingsValue or 0
                            end,
                            set = function(v)
                                wgt.ui.settingsValue = v
                            end,
                        },
                    },
                },
                {
                    type = "button",
                    text = "Close",
                    press = function()
                        closeSettingsPage(wgt)
                    end,
                },
            },
        },
    }

    wgt.ui.settingsPage = page:build(uit)
end

-- Draw and handle Menu button (replaces Settings button)
local function drawAndHandleMenuButton(wgt, event, touchState, config, UI, normalizeGridSpan)
    -- Menu button positioned by BTN_GRID span
    local span = normalizeGridSpan(config.BTN_GRID, { row = 8, rows = 1, col = 7, cols = 2 })
    local cellW = math.floor(LCD_W / config.GRID_COLS)
    local cellH = math.floor(LCD_H / config.GRID_ROWS)
    local btnX = (span.col - 1) * cellW
    local btnY = (span.row - 1) * cellH
    local btnW = span.cols * cellW
    local btnH = span.rows * cellH

    UI.drawButton(btnX, btnY, btnW, btnH, "Menu")
    if UI.handleButton(event, touchState, btnX, btnY, btnW, btnH) then
        openSettingsPage(wgt)
    end
end

return {
    closeSettingsPage = closeSettingsPage,
    openSettingsPage = openSettingsPage,
    drawAndHandleMenuButton = drawAndHandleMenuButton,
}
