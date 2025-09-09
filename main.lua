------------------------------------------------------------------------------------------------------------------------
---                 3STATED | 3-Zustand-Anzeige (3-State-Display)
---
---  Widget für die textuelle und farbliche Anzeige von 3 Zuständen einer Quelle (Schalter, Variablen, ...).
---  Dokumentation: file://./readme.md
---
---  Entwicklungsumgebung: Ethos X20S-Simulator Version 1.6.3
---  Testumgebung:         FrSky Tandem X20 | Ethos 1.6.3 EU | Bootloader 1.4.15
---
---  Autor: Andreas Kuhl (https://github.com/andreaskuhl)
---  Lizenz: GPL 3.0
---
---  Vielen Dank für die folgenden hilfreichen Beispiele:
---    - Schalteranzeige (V1.4 vom 28.12.2024), JecoBerlin
---    - Ethos-Status-widget / Ethos-TriStatus-widget (V2.1 vom 30.07.2025), Lothar Thole (https://github.com/lthole)
------------------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------------------------
--- Modul locals (constants)
------------------------------------------------------------------------------------------------------------------------

--- Application control and information
local WIDGET_VERSION      = "1.1.0"                                 -- version information
local WIDGET_AUTOR        = "Andreas Kuhl (github.com/andreaskuhl)" -- author information
local WIDGET_KEY          = "3STATED"                               -- unique widget key (max. 7 characters)
local DEBUG_PREFIX        = "Widget " .. WIDGET_KEY .. " - "        -- prefix for debug messages
local DEBUG_MODE          = true                                    -- true: show debug information, false: release mode

--- Translation
local currentLocale       = system.getLocale()                            -- current system language for check if language has changed
local STR                 = assert(loadfile("i18n/i18n.lua"))().translate -- load i18n and get translate function
local widgetNameMap       = assert(loadfile("i18n/name.lua"))()           -- load widget name map

--- List indexes (used for listText, listBGColor and listTxColor)
local TITLE_INDEX         = 1
local STATE_DOWN          = 2
local STATE_MIDDLE        = 3
local STATE_UP            = 4

--- Defaults
local THRESHOLD_MIN       = -1024 -- Minimum threshold for configuration form.
local THRESHOLD_MAX       = 1024  -- Minimum threshold for configuration form.

--- User interface
local CONF_TITLES         = { "Title", "StateDown", "StateMiddle", "StateUp" }       -- configuration title (1-4)
local FONT_SIZES          = { FONT_XS, FONT_S, FONT_L, FONT_STD, FONT_XL, FONT_XXL } -- global font IDs (1-6)
local FONT_SIZE_SELECTION = { { "XS", 1 }, { "S", 2 }, { "M", 3 }, { "L", 4 },
    { "XL", 5 }, { "XXL", 6 } }                                                      -- font list for config listbox

------------------------------------------------------------------------------------------------------------------------
------ Helper functions
------------------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------------------------
---  Debug output function.
---  If DEBUG_MODE is true, it prints debug information to the console.
---  Format: "<tick> Widget <widget name> - <function name>() - <info text>"
local function debugInfo(functionName, infotext)
    if DEBUG_MODE then
        -- if infotext == nil then infotext = "" else infotext = ": " .. infotext end
        infotext = (infotext == nil) and "" or (": " .. infotext)
        print(string.format("%06d ", math.floor(os.clock() * 1000)) ..
            DEBUG_PREFIX .. functionName .. "()" .. infotext)
    end
end

------------------------------------------------------------------------------------------------------------------------
-- Check if the system language has changed and reload i18n if necessary.
local function updateLanguage()
    local localeNow = system.getLocale()
    if localeNow ~= currentLocale then
        -- Language has changed, reload i18n
        debugInfo("updateLanguage", "Language changed from " .. currentLocale .. " to " .. localeNow)
        STR = assert(loadfile("i18n/i18n.lua"))().translate
        currentLocale = localeNow
    end
end

------------------------------------------------------------------------------------------------------------------------
--- Check if the widget source exists and is valid.
local function existWidgetSource(widget)
    return (widget ~= nil) and (widget.source ~= nil) and (widget.source:name() ~= "---")
end

------------------------------------------------------------------------------------------------------------------------
--- Check if the text exists and is not empty.
local function existText(text)
    return (text ~= nil) and (text ~= "")
end

------------------------------------------------------------------------------------------------------------------------
---  Split text into lines based on a specified separator.
local function splitLines(text, separator)
    local lines = {}

    if not existText(text) then return lines end

    -- Add separator at the end to capture the last line
    text = text .. separator

    -- Split text into lines
    for line in string.gmatch(text, "(.-)" .. separator) do
        table.insert(lines, line)
    end

    return lines
end

------------------------------------------------------------------------------------------------------------------------
--- Widget handler
------------------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------------------------
-- Handler to get the widget name in the current system language.
local function name() -- Widget name (ASCII) - only for name() Handler
    local lang = system.getLocale and system.getLocale() or "en"
    return widgetNameMap[lang] or widgetNameMap["en"]
end

------------------------------------------------------------------------------------------------------------------------
--- Handler to create a new widget instance with default values.
local function create()
    debugInfo("create")

    -- Defaults
    local BG_COLOR_TITLE = lcd.RGB(40, 40, 40)    -- title background  -> dark gray
    local TX_COLOR_TITLE = lcd.RGB(176, 176, 176) -- title text        -> light gray
    local BG_COLOR_DOWN  = lcd.RGB(0, 128, 0)     -- down background   -> green
    local TX_COLOR_DOWN  = COLOR_WHITE            -- down text         -> white
    local BG_COLOR_MID   = lcd.RGB(192, 128, 0)   -- middle background -> orange
    local TX_COLOR_MID   = COLOR_WHITE            -- middle text       -> white
    local BG_COLOR_UP    = lcd.RGB(192, 0, 0)     -- up background     -> red
    local TX_COLOR_UP    = COLOR_WHITE            -- up text           -> white

    --- Create widget data structure with default values.
    return {
        value = {},                                                                        -- source value
        state = STATE_DOWN,                                                                -- actual state (1-3) meant(down/middle/up)
        sourceShow = true,                                                                 -- source switch
        titleShow = true,                                                                  -- title switch
        titleColorUse = true,                                                              -- title color switch
        thresholdDown = -50,                                                               -- threshold for state down
        thresholdUp = 50,                                                                  -- threshold for state up
        fontSizeIndex = 6,                                                                 -- index of font size - see fontSizes (1=XS - 6=XXL)
        listText = { STR("Title"), STR("StateDown"), STR("StateMiddle"), STR("StateUp") }, -- text list: title (1) and state (2-4)
        listBGColor = { BG_COLOR_TITLE, BG_COLOR_DOWN, BG_COLOR_MID, BG_COLOR_UP },        -- background color list: title (1) and state (2-4)
        listTxColor = { TX_COLOR_TITLE, TX_COLOR_DOWN, TX_COLOR_MID, TX_COLOR_UP },        -- text color list: title (1) and state (2-4)
        debugMode = false,                                                                 -- true: shows internal values in the widget
    }
end

------------------------------------------------------------------------------------------------------------------------
--- Handler to wake up the widget (check for source value changes and initiating redrawing if necessary).
local function wakeup(widget)
    --------------------------------------------------------------------------------------------------------------------
    --- Check if the state has changed (returns true if changed).
    local function isStateChanged(widget)
        local isChanged = false

        if not existWidgetSource(widget) then return false end

        -- check if source value has changed
        local actValue = widget.source:value()
        if widget.value ~= actValue then
            widget.value = actValue
            -- in debug mode always redraw on value change
            if widget.debugMode then isChanged = true end
        end

        -- determine new state by thresholds
        if (widget.value < widget.thresholdDown) then -- Down
            if (widget.state ~= STATE_DOWN) then
                widget.state = STATE_DOWN
                isChanged = true
            end
        elseif (widget.value < widget.thresholdUp) then -- Middle
            if (widget.state ~= STATE_MIDDLE) then
                widget.state = STATE_MIDDLE
                isChanged = true
            end
        elseif (widget.state ~= STATE_UP) then -- Up
            widget.state = STATE_UP
            isChanged = true
        end

        if isChanged then
            debugInfo("isStateChanged",
                "state is changed to " .. widget.state .. " = " .. STR(CONF_TITLES[widget.state]))
        end

        return isChanged
    end

    --------------------------------------------------------------------------------------------------------------------
    -- Wakeup main
    if isStateChanged(widget) then
        lcd.invalidate()
        debugInfo("wakeup", "LCD invalidate")
    end
end

------------------------------------------------------------------------------------------------------------------------
--- Handler to paint (draw) the widget.
local function paint(widget)
    local titleHeight   = 0 -- height of title box

    -- Vertical alignment constants for function drawTextCentered()
    local FREE_ABOVE    = 3 -- pixel free space at above title and/or text
    local FREE_BELOW    = 3 -- pixel free space below title and/or text
    local LINE_TOP      = 1 -- align top
    local LINE_CENTERED = 2 -- align middle (vertical centered)
    local LINE_BOTTOM   = 3 -- align bottom

    ---------------------------------------------------------------------------------------------------------------------
    --- Draw text centered in the widget.
    --- Parameters:
    ---   text         : text to draw (string)
    ---   fontSize     : font size (FONT_XS, FONT_S, FONT_L, FONT_STD, FONT_XL, FONT_XXL) - default: FONT_STD
    ---   verticalAlign: vertical alignment (LINE_ABOVE, LINE_CENTERED, LINE_BELOW) - default: LINE_CENTERED
    ---   shiftLine    : shift line (example: 0 = no shift, -1 = one line up, 0.5 = half line down) - default: 0
    --------------------------------------------------------------------------------------------------------------------
    local function drawTextCentered(text, fontSize, verticalAlign, shiftLine)
        local textWidth, textHeight -- text width and height
        local textPosY              -- text y position

        if not existText(text) then return end
        if not fontSize then fontSize = FONT_STD end
        if not verticalAlign then verticalAlign = LINE_CENTERED end
        if not shiftLine then shiftLine = 0 end

        lcd.font(fontSize) -- set font size
        _, textHeight = lcd.getTextSize("")

        if verticalAlign == LINE_TOP then        -- align top
            textPosY = FREE_ABOVE + titleHeight
        elseif verticalAlign == LINE_BOTTOM then -- align bottom
            textPosY = (widget.h - textHeight)   -- not FREE_BELOW, text height include enough descender (Unterlänge)
        else                                     -- align centered (default)
            textPosY = FREE_ABOVE + ((widget.h - titleHeight - FREE_ABOVE) / 2 - textHeight / 2) + titleHeight
        end

        textPosY = textPosY + (shiftLine * textHeight) -- shift line

        lcd.drawText((widget.w / 2), textPosY, text, TEXT_CENTERED)
    end

    --------------------------------------------------------------------------------------------------------------------
    --- Paint title text.
    local function paintTitle()
        local sourceText = ""
        local titleText = ""
        local local_title_h

        titleHeight = 0
        if not widget.sourceShow and not widget.titleShow then return end

        -- calculate title box height
        lcd.font(FONT_S)
        _, local_title_h = lcd.getTextSize("")
        local_title_h = FREE_ABOVE + local_title_h + FREE_BELOW

        if widget.titleColorUse then
            -- draw title background and set title text color
            lcd.color(widget.listBGColor[TITLE_INDEX])
            lcd.drawFilledRectangle(0, 0, widget.w, local_title_h)
            lcd.color(widget.listTxColor[TITLE_INDEX])
        else
            -- set state text color
            lcd.color(widget.listTxColor[widget.state])
        end
        if widget.sourceShow then
            -- set source text
            if existWidgetSource(widget) then
                sourceText = widget.source:name()
            else
                sourceText = "---"
            end
        end

        --- set title text
        if widget.titleShow and existText(widget.listText[TITLE_INDEX]) then -- set title text
            titleText = widget.listText[TITLE_INDEX]
        end

        --- combine source and title text
        if existText(sourceText) and existText(titleText) then -- both texts existent
            titleText = sourceText .. ": " .. titleText
        elseif existText(sourceText) then                      -- only source text existent
            titleText = sourceText
        end

        --- draw title text
        if existText(titleText) then
            drawTextCentered(titleText, FONT_S, LINE_TOP, 0)
        end

        titleHeight = local_title_h
    end
    --------------------------------------------------------------------------------------------------------------------
    --- Paint debug information (shows internal values of the widget).
    local function paintDebugInfo()
        debugInfo("paintDebugInfo")
        assert(existWidgetSource(widget))

        local line = {}

        --- line 1: source name and value
        line[1] = STR("Source") .. " " .. widget.source:name() .. ": " .. widget.value

        -- line 2: state and thresholds
        if widget.state == STATE_DOWN then
            line[2] = "< " .. widget.thresholdDown
        elseif widget.state == STATE_MIDDLE then
            line[2] = ">= " .. widget.thresholdDown .. " & < " .. widget.thresholdUp
        elseif widget.state == STATE_UP then
            line[2] = ">= " .. widget.thresholdUp
        end

        -- line 3: state text
        if line[2] then
            line[2] = line[2] .. " -> " .. STR(CONF_TITLES[widget.state])
            line[3] = "\"" .. widget.listText[widget.state] .. "\""
        else
            line[2] = "Status: " .. STR("StateUnknown")
            line[3] = ""
        end

        -- draw debug lines
        drawTextCentered(line[1], FONT_S, LINE_CENTERED, -1)
        drawTextCentered(line[2], FONT_S, LINE_CENTERED, 0)
        drawTextCentered(line[3], FONT_S, LINE_CENTERED, 1)
    end

    --------------------------------------------------------------------------------------------------------------------
    ---  paint multiline state text
    local function paintStateText()
        debugInfo("paintStateText")

        local lines = splitLines(widget.listText[widget.state], "_n_")
        local n = #lines
        for i, line in ipairs(lines) do
            local offset = -n / 2 - 0.5 + i
            debugInfo("paintStateText", string.format("Offset: %.2f | Zeile: %s", offset, line))
            drawTextCentered(line, FONT_SIZES[widget.fontSizeIndex], LINE_CENTERED, offset)
        end
    end

    --------------------------------------------------------------------------------------------------------------------
    --- Paint background, set text color and paint state text (or debug information in debug mode).
    local function paintState()
        debugInfo("paintState")
        assert(existWidgetSource(widget))

        --- paint background and preset text color
        lcd.color(widget.listBGColor[widget.state])
        lcd.drawFilledRectangle(0, 0, widget.w, widget.h)

        --- paint title (must be before paint state text or debug information)
        paintTitle()

        lcd.color(widget.listTxColor[widget.state])

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
        debugInfo("SourceMissed")
        lcd.color(COLOR_BLACK)
        lcd.drawFilledRectangle(0, 0, widget.w, widget.h)

        --- paint title (must be before paint state text or debug information)
        paintTitle()

        -- paint "Source missed" text
        lcd.color(COLOR_RED)
        drawTextCentered(STR("SourceMissed"), FONT_SIZES[FONT_STD], LINE_CENTERED)
    end

    --------------------------------------------------------------------------------------------------------------------
    --- Paint main
    debugInfo("paint")
    updateLanguage()     -- check if system language has changed

    if not widget.h then -- calculate widget
        debugInfo("paint", "calcWidget")
        widget.w, widget.h = lcd.getWindowSize()
    end

    if not existWidgetSource(widget) then -- source missed
        paintSourceMissed()
    elseif widget.state == STATE_DOWN or widget.state == STATE_MIDDLE or widget.state == STATE_UP then
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
        line = form.addLine(STR(CONF_TITLES[index]) .. " " .. STR("Text"))
        form.addTextField(line, nil, function() return widget.listText[index] end,
            function(value) widget.listText[index] = value end)

        line = form.addLine(STR(CONF_TITLES[index]) .. " " .. STR("BackgroundColor"))
        form.addColorField(line, nil, function() return widget.listBGColor[index] end,
            function(color) widget.listBGColor[index] = color end)

        line = form.addLine(STR(CONF_TITLES[index]) .. " " .. STR("TextColor"))
        form.addColorField(line, nil, function() return widget.listTxColor[index] end,
            function(color) widget.listTxColor[index] = color end)
    end

    --------------------------------------------------------------------------------------
    --- Add static text configuration.
    local function addConfigStaticText(title, text)
        line = form.addLine(title)
        form.addStaticText(line, nil, text)
    end

    --------------------------------------------------------------------------------------
    --- Configure main
    debugInfo("configure")
    updateLanguage() -- check if system language has changed

    -- Source
    line = form.addLine(STR("Source"))
    form.addSourceField(line, nil, function() return widget.source end,
        function(value) widget.source = value end)

    -- Source switch
    line = form.addLine(STR("SourceShow"))
    form.addBooleanField(line, nil, function() return widget.sourceShow end,
        function(value) widget.sourceShow = value end)

    -- Title switch
    line = form.addLine(STR("TitleShow"))
    form.addBooleanField(line, nil, function() return widget.titleShow end,
        function(value) widget.titleShow = value end)

    -- Title (with text, background color and text color)
    addConfigBlock(TITLE_INDEX) -- title

    -- Title color use switch
    line = form.addLine(STR(CONF_TITLES[TITLE_INDEX]) .. " " .. STR("ColorUse"))
    form.addBooleanField(line, nil, function() return widget.titleColorUse end,
        function(value) widget.titleColorUse = value end)


    -- STATE_DOWN threshold
    line = form.addLine(STR "Threshold" .. " " .. STR(CONF_TITLES[STATE_DOWN]))
    f = form.addNumberField(line, nil, THRESHOLD_MIN * 10, THRESHOLD_MAX * 10,
        function() return widget.thresholdDown * 10 end,
        function(value) widget.thresholdDown = value / 10 end);
    f:decimals(1)

    -- STATE_UP threshold
    line = form.addLine(STR "Threshold" .. " " .. STR(CONF_TITLES[STATE_UP]))
    f = form.addNumberField(line, nil, THRESHOLD_MIN * 10, THRESHOLD_MAX * 10,
        function() return widget.thresholdUp * 10 end,
        function(value) widget.thresholdUp = value / 10 end);
    f:decimals(1)

    -- Font size
    line = form.addLine(STR "FontSize")
    form.addChoiceField(line, nil, FONT_SIZE_SELECTION, function() return widget.fontSizeIndex end,
        function(value) widget.fontSizeIndex = value end)

    -- All states (with text, background color and text color)
    addConfigBlock(STATE_DOWN)   -- down
    addConfigBlock(STATE_MIDDLE) -- middle
    addConfigBlock(STATE_UP)     -- up

    -- Debug mode
    line = form.addLine(STR("DebugMode"))
    form.addBooleanField(line, nil, function() return widget.debugMode end,
        function(value) widget.debugMode = value end)

    -- Widget Info
    -- addConfigStaticText(STR("Widget"), name())
    addConfigStaticText(STR("Widget"), STR("WidgetName"))
    addConfigStaticText(STR("Version"), WIDGET_VERSION)
    addConfigStaticText(STR("Author"), WIDGET_AUTOR)
end

------------------------------------------------------------------------------------------------------------------------
--- Handler to write (save) the widget configuration.
local function write(widget)
    debugInfo("write", "")

    -- write widget version number for user data format
    -- (storage of the version number only introduced with version 1.1.0)
    local versionNumber = 10000 * tonumber(string.match(WIDGET_VERSION, "(%d+)")) +
        100 * tonumber(string.match(WIDGET_VERSION, "%.(%d+)")) +
        tonumber(string.match(WIDGET_VERSION, "%.(%d+)$"))
    storage.write("Version", versionNumber)
    debugInfo("write", "store version: " .. versionNumber)

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
    debugInfo("read")

    -- check first field Version number ( storage of the version number only introduced with version 1.1.0)
    local firstField = storage.read("Version")
    local versionNumber = 10000 --- date source version number , default: 10000 (version 1.0.0)

    if firstField == nil or type(firstField) ~= "number" then
        debugInfo("read", "no version found -> set to Version 1.0.0 (010000)")
        versionNumber = 10000
    else
        versionNumber = firstField
        debugInfo("read", "found version: " .. tostring(versionNumber))
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
    debugInfo("Init")
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
return { init = init }
