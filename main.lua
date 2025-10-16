------------------------------------------------------------------------------------------------------------------------
---                 3STATED | 3-State-Display - Widget für FrSky Ethos
---
---  FrSky Ethos Widget for textual and color-based display of 3 states from a source (switches, variables, ...).
---  Documentation: file://./readme.md
---
---  Development Environment: Ethos X20S Simulator Version 1.6.3
---  Test Environment:        FrSky Tandem X20 | Ethos 1.6.3 EU | Bootloader 1.4.15
---
---  Author: Andreas Kuhl (https://github.com/andreaskuhl)
---  License: GPL 3.0
---
---  Many thanks for the following helpful examples:
---    - Switch Display (V1.4 from 28.12.2024), JecoBerlin
---    - Ethos Status Widget / Ethos TriStatus Widget (V2.1 from 30.07.2025), Lothar Thole (https://github.com/lthole)
---
------------------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------------------------
--- Modul locals (constants)
------------------------------------------------------------------------------------------------------------------------

--- Application control and information
local WIDGET_VERSION      = "1.1.0"                                 -- version information
local WIDGET_KEY          = "3STATED"                               -- unique widget key (max. 7 characters)
local WIDGET_AUTOR        = "Andreas Kuhl (github.com/andreaskuhl)" -- author information
local DEBUG_MODE          = true                                    -- true: show debug information, false: release mode
local widgetCounter       = 0                                       -- debug: counter for widget instances (0 = no instance)

--- Libraries
local wHelper             = {} -- widget helper library
local wPaint              = {} -- widget paint library
local wConfig             = {} -- widget config library
local wStorage            = {} -- widget storage library

--- Translation
local STR                 = assert(loadfile("i18n/i18n.lua"))().translate -- load i18n and get translate function
local WIDGET_NAME_MAP     = assert(loadfile("i18n/w_name.lua"))()         -- load widget name map
local currentLocale       = system.getLocale()                            -- current system language

--- List indexes (used for listText, listBGColor and listTxColor)
local TITLE_INDEX         = 1
local STATE_DOWN          = 2
local STATE_MIDDLE        = 3
local STATE_UP            = 4

--- Defaults
local THRESHOLD_MIN       = -1024 -- Minimum threshold for configuration form.
local THRESHOLD_MAX       = 1024  -- Minimum threshold for configuration form.

--- User interface
local CONF_TITLES         = { "Title", "StateDown", "StateMiddle", "StateUp" }   -- configuration title (1-4)
local FONT_SIZES          = {
    FONT_XS, FONT_S, FONT_STD, FONT_L, FONT_XL, FONT_XXL }                       -- global font IDs (1-6)
local FONT_SIZE_SELECTION = {
    { "XS", 1 }, { "S", 2 }, { "M", 3 }, { "L", 4 }, { "XL", 5 }, { "XXL", 6 } } -- list for config listbox

------------------------------------------------------------------------------------------------------------------------
--- Local Helper functions
------------------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------------------------
--- Load and init Libraries.
local function initLibraries()
    -- load libraries with dependencies
    wHelper = dofile("lib/w_helper.lua")({ widgetVersion = WIDGET_VERSION, widgetKey = WIDGET_KEY, debugMode = DEBUG_MODE })
    wPaint = dofile("lib/w_paint.lua")({ wHelper = wHelper })
    wConfig = dofile("lib/w_config.lua")({ wHelper = wHelper })
    wStorage = dofile("lib/w_storage.lua")({ wHelper = wHelper })

    wHelper.Debug:new(0, "initLibraries"):info("libraries loaded")
end

------------------------------------------------------------------------------------------------------------------------
-- Check if the system language has changed and reload i18n if necessary.
local function updateLanguage(widget)
    local localeNow = system.getLocale()
    if localeNow ~= currentLocale then -- Language has changed, reload i18n
        wHelper.Debug:new(widget.no, "updateLanguage")
            :info("Language changed from " .. currentLocale .. " to " .. localeNow)
        STR = assert(loadfile("i18n/i18n.lua"))().translate
        currentLocale = localeNow
    end
end

------------------------------------------------------------------------------------------------------------------------
--- Widget handler
------------------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------------------------
-- Handler to get the widget name in the current system language.
local function name() -- Widget name (ASCII) - only for name() Handler
    local lang = system.getLocale and system.getLocale() or "en"
    return WIDGET_NAME_MAP[lang] or WIDGET_NAME_MAP["en"]
end

------------------------------------------------------------------------------------------------------------------------
--- Handler to create a new widget instance with default values.
local function create()
    widgetCounter                 = widgetCounter + 1
    local debug                   = wHelper.Debug:new(widgetCounter, "create"):info()

    --- widget defaults
    local FONT_SIZE_INDEX_DEFAULT = 5                      -- font size index default - see fontSizes (1=XS - 6=XXL)
    local BG_COLOR_TITLE          = lcd.RGB(40, 40, 40)    -- title background  -> dark gray
    local TX_COLOR_TITLE          = lcd.RGB(176, 176, 176) -- title text        -> light gray
    local BG_COLOR_DOWN           = lcd.RGB(0, 128, 0)     -- down background   -> green
    local TX_COLOR_DOWN           = COLOR_WHITE            -- down text         -> white
    local BG_COLOR_MID            = lcd.RGB(192, 128, 0)   -- middle background -> orange
    local TX_COLOR_MID            = COLOR_WHITE            -- middle text       -> white
    local BG_COLOR_UP             = lcd.RGB(192, 0, 0)     -- up background     -> red
    local TX_COLOR_UP             = COLOR_WHITE            -- up text           -> white

    --- Create widget data structure with default values.
    return {
        -- widget variables
        no              = widgetCounter,                                                          -- widget instance number
        width           = nil,                                                                    -- widget height
        height          = nil,                                                                    -- widget width

        source          = nil,                                                                    -- source
        sourceLastValue = 0,                                                                      -- last source value
        sourceShow      = true,                                                                   -- source switch
        titleShow       = true,                                                                   -- title switch
        titleColorUse   = true,                                                                   -- title color switch
        thresholdDown   = -50,                                                                    -- threshold for state down
        thresholdUp     = 50,                                                                     -- threshold for state up
        fontSizeIndex   = FONT_SIZE_INDEX_DEFAULT,                                                -- index of font size
        listText        = { STR("Title"), STR("StateDown"), STR("StateMiddle"), STR("StateUp") }, -- text list: title (1) and state (2-4)
        listBGColor     = { BG_COLOR_TITLE, BG_COLOR_DOWN, BG_COLOR_MID, BG_COLOR_UP },           -- background color list: title (1) and state (2-4)
        listTxColor     = { TX_COLOR_TITLE, TX_COLOR_DOWN, TX_COLOR_MID, TX_COLOR_UP },           -- text color list: title (1) and state (2-4)
        debugMode       = false,                                                                  -- true: shows internal values in the widget
        -- get source value function
        getSourceValue  = function(self) return (wHelper.existSource(self.source) and self.source:value()) or 0 end,
        -- get source text function
        getSourceText   = function(self) return (wHelper.existSource(self.source) and self.source:stringValue()) or "" end,
        -- get state function -> 1-3 meant(down/middle/up)
        getState        = function(self)
            if self:getSourceValue() < self.thresholdDown then
                return STATE_DOWN
            elseif self:getSourceValue() < self.thresholdUp then
                return STATE_MIDDLE
            else
                return STATE_UP
            end
        end
    }
end

------------------------------------------------------------------------------------------------------------------------
--- Handler to wake up the widget (check for source value changes and initiating redrawing if necessary).
local function wakeup(widget)
    local debug = wHelper.Debug:new(widget.no, "wakeup")
    if not wHelper.existSource(widget.source) then return end

    -- check if source value has changed
    local actValue = widget.source:value()
    if widget.sourceLastValue ~= actValue then
        lcd.invalidate()
        widget.sourceLastValue = actValue
        debug:info("widget value is changed to " ..
            "value = " .. actValue .. ", text = " .. widget:getSourceText() ..
            ", " .. widget:getState() .. " = " .. STR(CONF_TITLES[widget:getState()]))
    end
end

------------------------------------------------------------------------------------------------------------------------
--- Handler to paint (draw) the widget.
local function paint(widget)
    --------------------------------------------------------------------------------------------------------------------
    --- Format state text by replacing placeholders in a given string.
    --- Supported placeholders:
    ---   _v    -> widget:getSourceValue() as number (without decimals) -> "8"
    ---   _<N>v -> widget:getSourceValue() as float with N decimals (e.g., _3v for three decimals) -> "7,532"
    ---   _t    -> widget:getSourceText()-> "7,5V"
    ---   __    -> literal "_"
    local function formatText(stateText)
        -- local debug = wHelper.Debug:new(widget.no, "formatText")
        local UNDERSCORE_PLACEHOLDER = "\1"
        local sourceValue = (widget and widget:getSourceValue()) or 0
        local sourceText = (widget and widget:getSourceText()) or ""
        local text = stateText or ""
        -- debug:info("Input: " .. s .. ", value: " .. val .. ", text: " .. txt)

        if text == "" then return "" end

        text = text:gsub("__", UNDERSCORE_PLACEHOLDER) -- temporary placeholder for literal '__' to avoid accidental replacement

        text = text:gsub("_(%d+)v",                    -- value: replace floating formats like _0v, _1v, _2v, _3v etc. capture digits before v
            function(precision)
                local n = tonumber(precision) or 0
                local formatStr = string.format("%%.%df", n)
                return string.format(formatStr, tonumber(sourceValue) or 0)
            end)
        text = text:gsub("_v", string.format("%.0f", tonumber(sourceValue) or 0)) -- value: replace default float _v as value number (float without decimals)
        text = text:gsub("_t", function() return tostring(sourceText) end)        -- text: replace _t as value text (use function replacement so '%' in txt is not interpreted)
        text = text:gsub(UNDERSCORE_PLACEHOLDER, "_")                             -- restore literal underscore

        return text
    end

    --------------------------------------------------------------------------------------------------------------------
    --- Paint title text.
    local function paintTitle()
        -- local debug = wHelper.Debug:new(widget.no, "paintTitle"):info()
        local sourceText = ""
        local titleText = ""

        if not widget.sourceShow and not widget.titleShow then return end -- title disabled

        -- set source text
        if widget.sourceShow then
            if wHelper.existSource(widget.source) then
                sourceText = widget.source:name()
            else
                sourceText = "---"
            end
        end

        -- set title text
        if widget.titleShow and wHelper.existText(widget.listText[TITLE_INDEX]) then
            titleText = formatText(widget.listText[TITLE_INDEX])
        end

        -- combine source and title text
        if wHelper.existText(sourceText) and wHelper.existText(titleText) then -- both texts existent
            titleText = sourceText .. ": " .. titleText
        elseif wHelper.existText(sourceText) then                              -- only source text existent
            titleText = sourceText
        end

        -- paint title
        if widget.titleColorUse then
            -- title background and title text color
            wPaint.title(titleText, widget.listBGColor[TITLE_INDEX], widget.listTxColor[TITLE_INDEX])
        else
            -- use state colors
            wPaint.title(titleText, widget.listBGColor[widget:getState()], widget.listTxColor[widget:getState()])
        end
    end

    --------------------------------------------------------------------------------------------------------------------
    --- Paint debug information (shows internal values of the widget).
    local function paintDebugInfo()
        local debug = wHelper.Debug:new(widget.no, "paintDebugInfo"):info()
        assert(wHelper.existSource(widget.source))

        local line = {}

        --- line 1: source name and value
        line[1] = widget.source:name() .. ": " .. widget:getSourceValue() .. " (" .. widget:getSourceText() .. ")"

        -- line 2: state and thresholds
        if widget:getState() == STATE_DOWN then
            line[2] = "< " .. widget.thresholdDown
        elseif widget:getState() == STATE_MIDDLE then
            line[2] = ">= " .. widget.thresholdDown .. " & < " .. widget.thresholdUp
        elseif widget:getState() == STATE_UP then
            line[2] = ">= " .. widget.thresholdUp
        end

        -- line 3: state text
        if line[2] then
            line[2] = line[2] .. " -> " .. STR(CONF_TITLES[widget:getState()])
            line[3] = "\"" .. formatText(widget.listText[widget:getState()]) .. "\""
        else
            line[2] = "Status: " .. STR("StateUnknown")
            line[3] = ""
        end

        -- draw debug lines
        wPaint.text(line[1], FONT_S, TEXT_CENTERED, wPaint.LINE_CENTERED, -1)
        wPaint.text(line[2], FONT_S, TEXT_CENTERED, wPaint.LINE_CENTERED, 0)
        wPaint.text(line[3], FONT_S, TEXT_CENTERED, wPaint.LINE_CENTERED, 1)
    end

    --------------------------------------------------------------------------------------------------------------------
    ---  paint multiline state text
    local function paintStateText()
        local lines = wHelper.splitLines(widget.listText[widget:getState()])
        local n = #lines
        for i, line in ipairs(lines) do
            local offset = -n / 2 - 0.5 + i
            line = formatText(line)
            wPaint.text(line, FONT_SIZES[widget.fontSizeIndex], TEXT_CENTERED, wPaint.LINE_CENTERED, offset)
        end
    end

    --------------------------------------------------------------------------------------------------------------------
    --- Paint background, set text color and paint state text (or debug information in debug mode).
    local function paintState()
        local debug = wHelper.Debug:new(widget.no, "paintState"):info()
        assert(wHelper.existSource(widget.source))

        --- paint background and preset text color
        lcd.color(widget.listBGColor[widget:getState()])
        lcd.drawFilledRectangle(0, 0, widget.width, widget.height)

        --- paint title (must be before paint state text or debug information)
        paintTitle()

        lcd.color(widget.listTxColor[widget:getState()])

        --- paint state text (debug oder standard)
        if widget.debugMode then
            paintDebugInfo()
        else
            paintStateText()
        end
    end

    --------------------------------------------------------------------------------------------------------------------
    --- Paint source missed (no valid source selected) in red on black background.
    local function paintSourceMissed()
        local debug = wHelper.Debug:new(widget.no, "paintSourceMissed"):info()
        lcd.color(COLOR_BLACK)
        lcd.drawFilledRectangle(0, 0, widget.width, widget.height)

        --- paint title
        paintTitle()

        debug:warning("source not defined")

        -- paint "Source missed" text
        lcd.color(COLOR_RED)
        wPaint.widgetText(STR("SourceMissed"), FONT_STD)
    end

    --------------------------------------------------------------------------------------------------------------------
    --- Paint main
    local debug = wHelper.Debug:new(widget.no, "paint"):info()

    updateLanguage(widget)
    widget.width, widget.height = lcd.getWindowSize() -- set the actual widget size (always if the layout has been changed)
    wPaint.init({ widgetHeight = widget.height, widgetWidth = widget.width })

    if not wHelper.existSource(widget.source) then -- source missed
        paintSourceMissed()
    elseif widget:getState() == STATE_DOWN or widget:getState() == STATE_MIDDLE or widget:getState() == STATE_UP then
        paintState()
    else -- invalid state
        assert(false, "Error: Invalid widget state")
    end
end

------------------------------------------------------------------------------------------------------------------------
--- Handler to configure the widget (show configuration form).
local function configure(widget)
    local line
    local f

    --------------------------------------------------------------------------------------------------------------------
    --- Add configuration for title or state (text, background color and text color).
    local function addConfigBlock(index)
        wConfig.startPanel(CONF_TITLES[index])

        line = wConfig.addLineTitle(STR(CONF_TITLES[index]) .. " " .. STR("Text"))
        form.addTextField(line, nil, function() return widget.listText[index] end,
            function(value) widget.listText[index] = value end)

        line = wConfig.addLineTitle(STR(CONF_TITLES[index]) .. " " .. STR("BackgroundColor"))
        form.addColorField(line, nil, function() return widget.listBGColor[index] end,
            function(color) widget.listBGColor[index] = color end)

        line = wConfig.addLineTitle(STR(CONF_TITLES[index]) .. " " .. STR("TextColor"))
        form.addColorField(line, nil, function() return widget.listTxColor[index] end,
            function(color) widget.listTxColor[index] = color end)

        wConfig.endPanel()
    end

    --------------------------------------------------------------------------------------
    --- Configure main
    local debug = wHelper.Debug:new(widget.no, "configure"):info()
    updateLanguage(widget) -- check if system language has changed
    wConfig.init({ form = form, widget = widget, STR = STR })

    -- Source
    wConfig.addSourceField("source")

    -- Source switch
    wConfig.addBooleanField("sourceShow")

    -- STATE_DOWN threshold
    line = form.addLine(STR("Threshold") .. " " .. STR(CONF_TITLES[STATE_DOWN]))
    f = form.addNumberField(line, nil, THRESHOLD_MIN * 10, THRESHOLD_MAX * 10,
        function() return widget.thresholdDown * 10 end,
        function(value) widget.thresholdDown = value / 10 end);
    f:decimals(1)

    -- STATE_UP threshold
    line = form.addLine(STR("Threshold") .. " " .. STR(CONF_TITLES[STATE_UP]))
    f = form.addNumberField(line, nil, THRESHOLD_MIN * 10, THRESHOLD_MAX * 10,
        function() return widget.thresholdUp * 10 end,
        function(value) widget.thresholdUp = value / 10 end);
    f:decimals(1)

    -- Font size
    line = form.addLine(STR("FontSize"))
    form.addChoiceField(line, nil, FONT_SIZE_SELECTION, function() return widget.fontSizeIndex end,
        function(value) widget.fontSizeIndex = value end)

    -- Title
    wConfig.startPanel(CONF_TITLES[1])
    wConfig.addBooleanField("titleShow")
    line = wConfig.addLineTitle(STR(CONF_TITLES[1]) .. " " .. STR("Text"))
    form.addTextField(line, nil, function() return widget.listText[1] end,
        function(value) widget.listText[1] = value end)
    line = wConfig.addLineTitle(STR(CONF_TITLES[1]) .. " " .. STR("BackgroundColor"))
    form.addColorField(line, nil, function() return widget.listBGColor[1] end,
        function(color) widget.listBGColor[1] = color end)
    line = wConfig.addLineTitle(STR(CONF_TITLES[1]) .. " " .. STR("TextColor"))
    form.addColorField(line, nil, function() return widget.listTxColor[1] end,
        function(color) widget.listTxColor[1] = color end)
    wConfig.addBooleanField("titleColorUse")
    wConfig.endPanel()

    -- All states (with text, background color and text color)
    addConfigBlock(STATE_DOWN)   -- down
    addConfigBlock(STATE_MIDDLE) -- middle
    addConfigBlock(STATE_UP)     -- up

    -- Debug mode
    line = form.addLine(STR("DebugMode"))
    form.addBooleanField(line, nil, function() return widget.debugMode end,
        function(value) widget.debugMode = value end)

    -- Widget Info
    wConfig.startPanel(STR("WidgetInfo"))
    wConfig.addStaticText("Widget", STR("WidgetName"))
    wConfig.addStaticText("Version", WIDGET_VERSION)
    wConfig.addStaticText("Author", WIDGET_AUTOR)
    wConfig.endPanel()
end

------------------------------------------------------------------------------------------------------------------------
--- Handler to write (save) the widget configuration.
local function write(widget)
    local debug = wHelper.Debug:new(widget.no, "write"):info()

    -- write widget version number for user data format
    -- (storage of the version number only introduced with version 1.1.0)
    local versionNumber = 10000 * tonumber(string.match(WIDGET_VERSION, "(%d+)")) +
        100 * tonumber(string.match(WIDGET_VERSION, "%.(%d+)")) +
        tonumber(string.match(WIDGET_VERSION, "%.(%d+)$"))
    storage.write("Version", versionNumber)
    debug:info("store version: " .. versionNumber)

    -- Source and source switch
    storage.write("Source", widget.source)
    storage.write("SourceShow", widget.sourceShow)

    -- title show, text, background color and text color
    storage.write("TitleShow", widget.titleShow)
    storage.write("TitleText", widget.listText[TITLE_INDEX])
    storage.write("TitleBGColor", widget.listBGColor[TITLE_INDEX])
    storage.write("TitleTxColor", widget.listTxColor[TITLE_INDEX])
    storage.write("TitleColorUse", widget.titleColorUse)

    -- state thresholds and font size
    storage.write("ThresholdDown", widget.thresholdDown)
    storage.write("ThresholdUp", widget.thresholdUp)
    storage.write("FontSizeIndex", widget.fontSizeIndex)

    -- state text, background color and text color
    for stateIndex = STATE_DOWN, STATE_UP do
        storage.write("StateText" .. stateIndex, widget.listText[stateIndex])
        storage.write("StateBGColor" .. stateIndex, widget.listBGColor[stateIndex])
        storage.write("StateTxColor" .. stateIndex, widget.listTxColor[stateIndex])
    end

    -- debug mode
    storage.write("DebugMode", widget.debugMode)
end

------------------------------------------------------------------------------------------------------------------------
--- Handler to read (load) the widget configuration.
local function read(widget)
    local debug = wHelper.Debug:new(widget.no, "read"):info()

    -- check first field Version number ( storage of the version number only introduced with version 1.1.0)
    local firstField = storage.read("Version")
    local versionNumber = 10000 --- date source version number , default: 10000 (version 1.0.0)

    if firstField == nil or type(firstField) ~= "number" then
        debug:info("no version found -> set to Version 1.0.0 (010000)")
        versionNumber = 10000
    else
        versionNumber = firstField
        debug:info("found version: " .. tostring(versionNumber))
    end

    if versionNumber == 10000 then
        --  Version == 1.0.0.: no version number stored -> first field is source
        widget.source = firstField
    else
        -- Version > 1.0.0 first field is version number -> read source
        widget.source = storage.read("Source")
    end
    widget.sourceShow = storage.read("SourceShow")

    -- title text, background color and text color
    widget.titleShow = storage.read("TitleShow")
    widget.listText[TITLE_INDEX] = storage.read("TitleText")
    widget.listBGColor[TITLE_INDEX] = storage.read("TitleBGColor")
    widget.listTxColor[TITLE_INDEX] = storage.read("TitleTxColor")
    widget.titleColorUse = storage.read("TitleColorUse")

    -- state thresholds and font size
    widget.thresholdDown = storage.read("ThresholdDown")
    widget.thresholdUp = storage.read("ThresholdUp")
    widget.fontSizeIndex = storage.read("FontSizeIndex")

    -- state text, background color and text color
    for stateIndex = STATE_DOWN, STATE_UP do
        widget.listText[stateIndex] = storage.read("StateText" .. stateIndex)       -- state text
        widget.listBGColor[stateIndex] = storage.read("StateBGColor" .. stateIndex) -- background color
        widget.listTxColor[stateIndex] = storage.read("StateTxColor" .. stateIndex) -- text color
    end

    -- debug mode
    widget.debugMode = storage.read("DebugMode")
end

------------------------------------------------------------------------------------------------------------------------
--- Initialize the widget (register it in the system).
local function init()
    wHelper.Debug:new(0, "init")
    system.registerWidget({
        key = WIDGET_KEY,
        name = name,
        wakeup = wakeup,
        create = create,
        paint = paint,
        configure = configure,
        read = read,
        write = write,
        title = false
    })
end

------------------------------------------------------------------------------------------------------------------------
--- Module main
------------------------------------------------------------------------------------------------------------------------
warn("@on")
initLibraries()

return { init = init }
