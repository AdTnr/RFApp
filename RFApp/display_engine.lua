-- Brief: Grid/region-based layout engine for placing sub-widgets on screen
local M = {}

function M.new()
    local engine = {
        regions = {},
        widgets = {},
        sortedDirty = true,
        gridRows = 8,
        gridCols = 8,
    }

    local function sortWidgets()
        table.sort(engine.widgets, function(a, b)
            local za = a.z or 0
            local zb = b.z or 0
            if za == zb then return a.name < b.name end
            return za < zb
        end)
        engine.sortedDirty = false
    end

    function engine.defineRegion(id, rectFn)
        engine.regions[id] = rectFn
    end

    function engine.setGrid(rows, cols)
        engine.gridRows = rows or 8
        engine.gridCols = cols or 8
    end

    function engine.setConfig(cfg)
        engine.config = cfg
    end

    local function normalizeGridSpan(grid)
        local rows = engine.gridRows
        local cols = engine.gridCols

        local rowStart = (grid and (grid.row or grid.r or grid.r1 or grid[1])) or 1
        local colStart = (grid and (grid.col or grid.c or grid.c1 or grid[3])) or 1

        local rowSpan = (grid and (grid.rows or grid.rowSpan))
        if not rowSpan then
            local r2 = (grid and (grid.r2 or grid[2])) or rowStart
            rowSpan = (r2 - rowStart + 1)
        end

        local colSpan = (grid and (grid.cols or grid.colSpan))
        if not colSpan then
            local c2 = (grid and (grid.c2 or grid[4])) or colStart
            colSpan = (c2 - colStart + 1)
        end

        rowSpan = math.max(1, rowSpan or 1)
        colSpan = math.max(1, colSpan or 1)

        rowStart = math.max(1, math.min(rows, rowStart))
        colStart = math.max(1, math.min(cols, colStart))

        if rowStart + rowSpan - 1 > rows then
            rowSpan = rows - rowStart + 1
        end
        if colStart + colSpan - 1 > cols then
            colSpan = cols - colStart + 1
        end

        return {
            row = rowStart,
            rows = rowSpan,
            col = colStart,
            cols = colSpan,
        }
    end

    local function gridRect(grid)
        local span = normalizeGridSpan(grid)
        local cellW = math.floor(LCD_W / engine.gridCols)
        local cellH = math.floor(LCD_H / engine.gridRows)
        local x = (span.col - 1) * cellW
        local y = (span.row - 1) * cellH
        local w = span.cols * cellW
        local h = span.rows * cellH
        local pad = (engine.config and engine.config.GRID_CELL_PADDING) or 1
        x = x + pad
        y = y + pad
        w = w - 2 * pad
        h = h - 2 * pad
        if w < 0 then w = 0 end
        if h < 0 then h = 0 end
        return { x = x, y = y, w = w, h = h, pad = pad }
    end

    function engine.placeWidgetGrid(name, drawFn, grid, z)
        engine.widgets[#engine.widgets + 1] = {
            name = name,
            draw = drawFn,
            grid = normalizeGridSpan(grid),
            z = z or 0,
        }
        engine.sortedDirty = true
    end

    function engine.placeWidget(name, drawFn, regionId, z)
        engine.widgets[#engine.widgets + 1] = { name = name, draw = drawFn, regionId = regionId, z = z or 0 }
        engine.sortedDirty = true
    end

    function engine.clearWidgets()
        engine.widgets = {}
        engine.sortedDirty = true
    end

    local function clampRect(x, y, w, h)
        if x < 0 then x = 0 end
        if y < 0 then y = 0 end
        if x + w > LCD_W then w = LCD_W - x end
        if y + h > LCD_H then h = LCD_H - y end
        return x, y, w, h
    end

    function engine.render(wgt)
        if engine.sortedDirty then sortWidgets() end
        
        -- CRITICAL: EdgeTX clears screen every frame, so we must render every frame
        -- Render all widgets (no conditional rendering since screen is cleared)
        for _, item in ipairs(engine.widgets) do
            local rect
            if item.grid then
                rect = gridRect(item.grid)
            elseif item.regionId then
                local rf = engine.regions[item.regionId]
                if rf then rect = rf(wgt) end
            end
            if rect then
                local x, y, w, h = rect.x or 0, rect.y or 0, rect.w or 0, rect.h or 0
                x, y, w, h = clampRect(math.floor(x), math.floor(y), math.floor(w), math.floor(h))
                if w > 0 and h > 0 then
                    if engine.config and engine.config.GRID_DRAW_CELL_BORDER then
                        local b = engine.config.GRID_CELL_BORDER or 1
                        -- draw border tightly around content
                        lcd.drawRectangle(x, y, w, h, COLOR_THEME_PRIMARY3, b)
                    end
                    item.draw(wgt, x, y, w, h)
                end
            end
        end
    end

    -- Helper: clamp a grid span {row,rows,col,cols} to valid values
    local function resolveGrid(config, span, fallback)
        local candidate = span or fallback or { row = 1, rows = 1, col = 1, cols = 1 }
        local normalized = normalizeGridSpan(candidate)

        local maxRows = config.GRID_ROWS or engine.gridRows
        local maxCols = config.GRID_COLS or engine.gridCols

        if normalized.row > maxRows then normalized.row = maxRows end
        if normalized.col > maxCols then normalized.col = maxCols end
        if normalized.row + normalized.rows - 1 > maxRows then
            normalized.rows = maxRows - normalized.row + 1
        end
        if normalized.col + normalized.cols - 1 > maxCols then
            normalized.cols = maxCols - normalized.col + 1
        end

        return normalized
    end

    -- High-level: place all configured widgets (battery, arm, rf logo, log)
    -- drawFns = { battery = fn(w,x,y,w,h), arm = fn(...), logo = fn(...), log = fn(...) }
    function engine.placeConfiguredWidgets(wgt, config, drawFns, rfLogo)
        engine.clearWidgets()

        -- Battery monitor
        local bmGrid = resolveGrid(config, config.BM_GRID, { row = 6, rows = 2, col = 1, cols = 8 })
        engine.placeWidgetGrid("batteryMonitor", function(w, x, y, ww, hh)
            if drawFns and drawFns.battery then drawFns.battery(w, x, y, ww, hh) end
        end, bmGrid, 0)

        if drawFns and drawFns.battTelem then
            local btGrid = resolveGrid(config, config.Apps and config.Apps.BattTelem and config.Apps.BattTelem.GRID, { row = 3, rows = 3, col = 7, cols = 2 })
            engine.placeWidgetGrid("batteryTelemetry", function(w, x, y, ww, hh)
                drawFns.battTelem(w, x, y, ww, hh)
            end, btGrid, 0)
        end

        -- ARM status
        local armGrid = resolveGrid(config, config.ARM_GRID, { row = 1, rows = 1, col = 2, cols = 1 })
        engine.placeWidgetGrid("armStatus", function(w, x, y, ww, hh)
            if drawFns and drawFns.arm then drawFns.arm(w, x, y, ww, hh) end
        end, armGrid, 0)

        -- RF logo (centered inside span with themed background)
        local logoGrid = resolveGrid(config, config.RF_LOGO_GRID, { row = 1, rows = 1, col = 1, cols = 1 })
        engine.placeWidgetGrid("rfLogo", function(w, rx, ry, rw, rh)
            --lcd.drawFilledRectangle(rx, ry, rw, rh, COLOR_THEME_FOCUS)
            if drawFns and drawFns.logo then
                drawFns.logo(w, rx, ry, rw, rh)
                return
            end
            if rfLogo then
                local bw = config.RF_LOGO_W or 50
                local bh = config.RF_LOGO_H or 33
                local sx = (rw * 100) / bw
                local sy = (rh * 100) / bh
                local scale = math.floor(math.min(sx, sy))
                if scale < 1 then scale = 1 end
                local sw = math.floor(bw * scale / 100)
                local sh = math.floor(bh * scale / 100)
                local cx = rx + math.floor((rw - sw) / 2)
                local cy = ry + math.floor((rh - sh) / 2)
                lcd.drawBitmap(rfLogo, cx, cy, scale)
            end
        end, logoGrid, -1)

        -- Events app
        if drawFns and drawFns.events then
            local evGrid = resolveGrid(config, config.Apps and config.Apps.Events and config.Apps.Events.GRID, { row = 8, rows = 1, col = 1, cols = 6 })
            engine.placeWidgetGrid("eventsApp", function(w, rx, ry, rw, rh)
                drawFns.events(w, rx, ry, rw, rh)
            end, evGrid, 0)
        end

        -- TX battery app (1x1 cell)
        if drawFns and drawFns.txBatt then
            local tbGrid = resolveGrid(config, config.Apps and config.Apps.TxBatt and config.Apps.TxBatt.GRID, { row = 1, rows = 1, col = 8, cols = 1 })
            engine.placeWidgetGrid("txBatt", function(w, rx, ry, rw, rh)
                drawFns.txBatt(w, rx, ry, rw, rh)
            end, tbGrid, 0)
        end
        if drawFns and drawFns.pid then
            local pidGrid = resolveGrid(config, config.Apps and config.Apps.Pid and config.Apps.Pid.GRID, { row = 1, rows = 1, col = 5, cols = 1 })
            engine.placeWidgetGrid("pidProfile", function(w, rx, ry, rw, rh)
                drawFns.pid(w, rx, ry, rw, rh)
            end, pidGrid, 0)
        end
        if drawFns and drawFns.rescue then
            local rescueGrid = resolveGrid(config, config.Apps and config.Apps.Rescue and config.Apps.Rescue.GRID, { row = 1, rows = 1, col = 6, cols = 1 })
            engine.placeWidgetGrid("rescue", function(w, rx, ry, rw, rh)
                drawFns.rescue(w, rx, ry, rw, rh)
            end, rescueGrid, 0)
        end
        if drawFns and drawFns.signal then
            local sgGrid = resolveGrid(config, config.Apps and config.Apps.Signal and config.Apps.Signal.GRID, { row = 1, rows = 1, col = 7, cols = 1 })
            engine.placeWidgetGrid("signal", function(w, rx, ry, rw, rh)
                drawFns.signal(w, rx, ry, rw, rh)
            end, sgGrid, 0)
        end
        if drawFns and drawFns.amps then
            local ampsGrid = resolveGrid(config, config.Apps and config.Apps.Amps and config.Apps.Amps.GRID, { row = 2, rows = 1, col = 7, cols = 1 })
            engine.placeWidgetGrid("amps", function(w, rx, ry, rw, rh)
                drawFns.amps(w, rx, ry, rw, rh)
            end, ampsGrid, 0)
        end
        if drawFns and drawFns.bec then
            local becGrid = resolveGrid(config, config.Apps and config.Apps.BEC and config.Apps.BEC.GRID, { row = 2, rows = 2, col = 7, cols = 2 })
            engine.placeWidgetGrid("bec", function(w, rx, ry, rw, rh)
                drawFns.bec(w, rx, ry, rw, rh)
            end, becGrid, 0)
        end
        if drawFns and drawFns.name then
            local nameGrid = resolveGrid(config, config.Apps and config.Apps.Name and config.Apps.Name.GRID, { row = 5, rows = 1, col = 6, cols = 2 })
            engine.placeWidgetGrid("name", function(w, rx, ry, rw, rh)
                drawFns.name(w, rx, ry, rw, rh)
            end, nameGrid, 0)
        end
        if drawFns and drawFns.rpm then
            local rpmGrid = resolveGrid(config, config.Apps and config.Apps.Rpm and config.Apps.Rpm.GRID, { row = 3, rows = 2, col = 1, cols = 2 })
            engine.placeWidgetGrid("rpm", function(w, rx, ry, rw, rh)
                drawFns.rpm(w, rx, ry, rw, rh)
            end, rpmGrid, 0)
        end
        if drawFns and drawFns.gov then
            local govGrid = resolveGrid(config, config.Apps and config.Apps.Gov and config.Apps.Gov.GRID, { row = 1, rows = 1, col = 3, cols = 2 })
            engine.placeWidgetGrid("gov", function(w, rx, ry, rw, rh)
                drawFns.gov(w, rx, ry, rw, rh)
            end, govGrid, 0)
        end
    end

    return engine
end

return M


