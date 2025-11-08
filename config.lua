--===================================================================
-- RFApp Configuration (global constants, layout, and resources)
--===================================================================

local M = {}

---------------------------------------------------------------------
-- 1. Module Metadata & Paths
---------------------------------------------------------------------
M.app_name = "RFApp"
M.AUDIO_PATH = "/WIDGETS/RFApp/Audio/"

local function audioFile(name)
    return M.AUDIO_PATH .. name
end

---------------------------------------------------------------------
-- 2. Audio Library (central reference for every sound asset)
---------------------------------------------------------------------
M.Sounds = {
    Arm = {
        armed = audioFile("Armed.wav"),
        disarmed = audioFile("Disarmed.wav"),
    },

    Pid = {
        profile = audioFile("Profile.wav"),
        numbers = {},
    },

    Rescue = {
        states = {
            [0] = audioFile("Safe.wav"),
            [1] = audioFile("Rescue.wav"),
            [2] = audioFile("Flip.wav"),
            [3] = audioFile("Climb.wav"),
            [4] = audioFile("Hover.wav"),
            [5] = audioFile("Exit.wav"),
        },
    },

    Rate = {
        announcement = audioFile("Rate.wav"),
        numbers = {},
    },

    Battery = {
        insertedLow = audioFile("Battery_Connected_is_Low.wav"),
        status = {
            nominal = audioFile("battry.wav"),
            low = audioFile("Battery_Low.wav"),
            critical = audioFile("Battery_Critical.wav"),
        },
    },
}

M.RATE_AUDIO_DEFAULT = true
M.HARDWIRED_RESERVE_PERCENT = 30
M.HARDWIRED_TEXT_COLOR_TOGGLE = 0

-- PID & Rate number callouts reuse "1.wav".."6.wav"
for idx = 1, 6 do
    M.Sounds.Pid.numbers[idx] = audioFile(string.format("%d.wav", idx))
    M.Sounds.Rate.numbers[idx] = M.Sounds.Pid.numbers[idx]
end

---------------------------------------------------------------------
-- 3. Battery Behaviour & Telemetry Timing
---------------------------------------------------------------------
-- Battery warning thresholds (percentages)
M.singleStepThreshold = 10
M.battLowMargin = 5

-- Telemetry update smoothing delays (milliseconds)
M.TELEMETRY_STABILIZATION_DELAY = 500
M.RSSI_DISCONNECT_DELAY = 200
M.ZERO_VOLTAGE_DELAY = 200

-- Battery-inserted low detection
M.batteryInsertedLowPercent = 98
M.BATTERY_MIN_VOLTAGE = 3.0
M.LOW_BAT_INS_VOLTAGE = 4.09
M.BATTERY_CONNECTED_LOW_DELAY = 0
M.BAT_INSERTED_DETECT_WINDOW = 300

-- Voltage filter behaviour
M.VFLT_SAMPLES_DEFAULT = 150
M.VFLT_INTERVAL_DEFAULT = 10

---------------------------------------------------------------------
-- 4. Telemetry Sources & Global Variables
---------------------------------------------------------------------
M.GV_CEL = 3

M.SENSOR_VOLT  = "Vbat"
M.SENSOR_PCNT  = "Bat%"
M.SENSOR_MAH   = "Capa"
M.SENSOR_CELLS = "Cel#"
M.SENSOR_ARM   = "ARM"
M.SENSOR_RPM   = "Hspd"
M.SENSOR_GOV   = "Gov"
M.SENSOR_PID   = "PID#"
M.SENSOR_RESC  = "Resc"
M.SENSOR_RATE  = "RTE#"

---------------------------------------------------------------------
-- 5. Widget Options & Presentation Defaults
---------------------------------------------------------------------
M.OPT_RESERVE = "Reserve %"
M.OPT_COLOR_TOGGLE = "Text Color (0=White,1=Black)"

M.options = {}

-- Screen borders / padding
M.BORDER_LEFT   = 0
M.BORDER_RIGHT  = 0
M.BORDER_TOP    = 0
M.BORDER_BOTTOM = 0

-- Grid definition (8x8 full screen layout)
M.GRID_ROWS = 8
M.GRID_COLS = 8
M.GRID_CELL_PADDING = 1         -- inner padding inside each grid cell (pixels)
M.GRID_CELL_BORDER = 1          -- border width around a cell when drawn (pixels)
M.GRID_DRAW_CELL_BORDER = false -- set true to draw a border around each placed widget

-- Transmitter battery display thresholds (volts)
M.TXBATT_MIN = 6.9 -- (3.45V per cell)
M.TXBATT_MAX = 8.4 -- (4.2V per cell)

---------------------------------------------------------------------
-- 6. App Layout Definitions (row/col origin + span counts)
--    row  = starting grid row (1 = top)
--    rows = number of grid rows to occupy
--    col  = starting grid column (1 = left)
--    cols = number of grid columns to occupy
---------------------------------------------------------------------
M.Apps = {
    Battery = {
        GRID = { row = 6, rows = 2, col = 1, cols = 8 },
        singleStepThreshold = M.singleStepThreshold,
        battLowMargin = M.battLowMargin,
        lipoPercentListSplit = nil, -- populated after LiPo table definition
    },

    BattTelem = {
        GRID = { row = 3, rows = 3, col = 7, cols = 2 },},
        Arm = {GRID = { row = 1, rows = 1, col = 2, cols = 1 },},
        Rescue = {GRID = { row = 1, rows = 1, col = 6, cols = 1 },},
        Events = {GRID = { row = 8, rows = 1, col = 1, cols = 6 },},
        TxBatt = {GRID = { row = 1, rows = 1, col = 8, cols = 1 },},
        Rpm = {GRID = { row = 3, rows = 2, col = 1, cols = 2 },},
        Gov = {GRID = { row = 1, rows = 1, col = 3, cols = 2 },},
        Pid = {GRID = { row = 1, rows = 1, col = 5, cols = 1 },},
    }

---------------------------------------------------------------------
-- 7. UI Chrome & Submenus
---------------------------------------------------------------------
M.UI = {
    SettingsButton = {
        GRID = { row = 8, rows = 1, col = 7, cols = 2 },
    },
}



M.Brand = {
    Logo = {
        GRID = { row = 1, rows = 1, col = 1, cols = 1 },
        W = 78,
        H = 38,
    },
}

---------------------------------------------------------------------
-- 8. Compatibility Aliases (legacy code references)
---------------------------------------------------------------------
M.BM_GRID    = M.Apps.Battery.GRID
M.ARM_GRID   = M.Apps.Arm.GRID
M.BTN_GRID   = M.UI.SettingsButton.GRID
M.RF_LOGO_GRID = M.Brand.Logo.GRID
M.RF_LOGO_W  = M.Brand.Logo.W
M.RF_LOGO_H  = M.Brand.Logo.H

---------------------------------------------------------------------
-- 9. LiPo Voltage Lookup Table
---------------------------------------------------------------------
M.lipoPercentListSplit = {
    { { 3.000,  0 }, { 3.093,  1 }, { 3.196,  2 }, { 3.301,  3 }, { 3.401,  4 }, { 3.477,  5 }, { 3.544,  6 }, { 3.601,  7 }, { 3.637,  8 }, { 3.664,  9 }, { 3.679, 10 }, { 3.683, 11 }, { 3.689, 12 }, { 3.692, 13 } },
    { { 3.705, 14 }, { 3.710, 15 }, { 3.713, 16 }, { 3.715, 17 }, { 3.720, 18 }, { 3.731, 19 }, { 3.735, 20 }, { 3.744, 21 }, { 3.753, 22 }, { 3.756, 23 }, { 3.758, 24 }, { 3.762, 25 }, { 3.767, 26 } },
    { { 3.774, 27 }, { 3.780, 28 }, { 3.783, 29 }, { 3.786, 30 }, { 3.789, 31 }, { 3.794, 32 }, { 3.797, 33 }, { 3.800, 34 }, { 3.802, 35 }, { 3.805, 36 }, { 3.808, 37 }, { 3.811, 38 }, { 3.815, 39 } },
    { { 3.818, 40 }, { 3.822, 41 }, { 3.825, 42 }, { 3.829, 43 }, { 3.833, 44 }, { 3.836, 45 }, { 3.840, 46 }, { 3.843, 47 }, { 3.847, 48 }, { 3.850, 49 }, { 3.854, 50 }, { 3.857, 51 }, { 3.860, 52 } },
    { { 3.863, 53 }, { 3.866, 54 }, { 3.870, 55 }, { 3.874, 56 }, { 3.879, 57 }, { 3.888, 58 }, { 3.893, 59 }, { 3.897, 60 }, { 3.902, 61 }, { 3.906, 62 }, { 3.911, 63 }, { 3.918, 64 } },
    { { 3.923, 65 }, { 3.928, 66 }, { 3.939, 67 }, { 3.943, 68 }, { 3.949, 69 }, { 3.955, 70 }, { 3.961, 71 }, { 3.968, 72 }, { 3.974, 73 }, { 3.981, 74 }, { 3.987, 75 }, { 3.994, 76 } },
    { { 4.001, 77 }, { 4.007, 78 }, { 4.014, 79 }, { 4.021, 80 }, { 4.029, 81 }, { 4.036, 82 }, { 4.044, 83 }, { 4.052, 84 }, { 4.062, 85 }, { 4.074, 86 }, { 4.085, 87 }, { 4.095, 88 } },
    { { 4.105, 89 }, { 4.111, 90 }, { 4.116, 91 }, { 4.120, 92 }, { 4.125, 93 }, { 4.129, 94 }, { 4.135, 95 }, { 4.145, 96 }, { 4.176, 97 }, { 4.179, 98 }, { 4.193, 99 }, { 4.200, 100 } },
}

-- Make LiPo table available directly from the Battery app config
M.Apps.Battery.lipoPercentListSplit = M.lipoPercentListSplit

return M


