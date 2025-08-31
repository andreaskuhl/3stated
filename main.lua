------------------------------------------------------------------------------------------------------------------------
---                 3STATED | 3-Zustand-Anzeige (3-State-Display)
---
---  Widget für die textuelle und farbliche Anzeige von 3 Zuständen einer Quelle (Schalter, Variablen, ...).
---  Dokumentation: file://./readme.md
---
---  Entwicklungsumgebung: Ethos X20S-Simulator Version 1.6.2
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

--- Function for retrieving translations from translation files
local STR               = assert(loadfile("i18n/i18n.lua"))().translate

--- Application control and information
local WIDGET_VERSION    = "1.0.0"                                 -- Version information
local WIDGET_AUTOR      = "Andreas Kuhl (github.com/andreaskuhl)" -- Author information
local WIDGET_KEY        = "3STATED"                               -- Unique widget key (max. 7 characters)
local DEBUG_PREFIX      = "Widget " .. WIDGET_KEY .. " - "        -- Prefix for debug messages
local DEBUG_MODE        = true                                    -- true: show Debug information

--- List indexes (used for listText, listBGColor and listTxColor)
local TITLE_INDEX       = 1
local STATE_DOWN        = 2
local STATE_MIDDLE      = 3
local STATE_UP          = 4

--- Defaults
local THRESHOLD_MIN     = -1024 -- Minimum threshold for configuration form.
local THRESHOLD_MAX     = 1024  -- Minimum threshold for configuration form.

--- User interface
local listConfTitle_int = { STR("Title"), STR("StateDown"), STR("StateMiddle"), STR("StateUp") }         -- Text configuration title (1-4)
local fontSizeList      = { FONT_XS, FONT_S, FONT_L, FONT_STD, FONT_XL, FONT_XXL }                       -- Global font IDs (1-6)
local fontSizeSelection = { { "XS", 1 }, { "S", 2 }, { "M", 3 }, { "L", 4 }, { "XL", 5 }, { "XXL", 6 } } -- Font list for config listbox


------------------------------------------------------------------------------------------------------------------------
------ Helper functions
------------------------------------------------------------------------------------------------------------------------

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
--- Return the widget name.
local function name()
    return STR("WidgetName")
end

------------------------------------------------------------------------------------------------------------------------
---  Debug output function.
---  If DEBUG_MODE is true, it prints debug information to the console.
---  Format: "<tick> Widget <widget name> - <function name>() - <info text>"
local function debugInfo(functionName, infotext)
    if DEBUG_MODE then
        -- if infotext == nil then infotext = "" else infotext = ": " .. infotext end
        infotext = (infotext == nil) and "" or (": " .. infotext)
        print(string.format("%06d ", math.floor(os.clock() * 1000)) .. DEBUG_PREFIX .. functionName .. "()" .. infotext)
    end
end

------------------------------------------------------------------------------------------------------------------------
--- Widget handler
------------------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------------------------
--- Handler to create a new widget instance with default values.
local function create()
    debugInfo("create")

    -- Defaults
    local BGCOLORTITLE = lcd.RGB(40, 40, 40)    -- title background  -> dark gray
    local TXCOLORTITLE = lcd.RGB(176, 176, 176) -- title text        -> light gray
    local BGCOLORDOWN  = lcd.RGB(0, 128, 0)     -- down background     -> green
    local TXCOLORDOWN  = COLOR_WHITE            -- down text         -> white
    local BGCOLORMID   = lcd.RGB(192, 128, 0)   -- middle background -> orange
    local TXCOLORMID   = COLOR_WHITE            -- middle text       -> white
    local BGCOLORUP    = lcd.RGB(192, 0, 0)     -- up background   -> red
    local TXCOLORUP    = COLOR_WHITE            -- up text           -> white

    --- Create widget data structure with default values.
    return {
        value = {},                                                                        -- source value
        state = STATE_DOWN,                                                                -- actual state (1-3) meant(down/middle/up)
        sourceShow = true,                                                                 -- Source switch
        titleShow = true,                                                                  -- Title switch
        titleColorUse = true,                                                              -- Title color switch
        thresholdDown = -50,                                                               -- threshold for state down
        thresholdUp = 50,                                                                  -- threshold for state up
        fontSizeIndex = 6,                                                                 -- index of font size - see fontSizeList (1=XS - 6=XXL)
        listText = { STR("Title"), STR("StateDown"), STR("StateMiddle"), STR("StateUp") }, -- text list: title (1) and state (2-4)
        listBGColor = { BGCOLORTITLE, BGCOLORDOWN, BGCOLORMID, BGCOLORUP },                -- background color list: title (1) and state (2-4)
        listTxColor = { TXCOLORTITLE, TXCOLORDOWN, TXCOLORMID, TXCOLORUP },                -- text color list: title (1) and state (2-4)
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
                "state is changed to " .. widget.state .. " = " .. listConfTitle_int[widget.state])
        end

        return isChanged
    end

    --------------------------------------------------------------------------------------------------------------------
    --- Wakeup main
    -- debugInfo("wakeup")
    if isStateChanged(widget) then
        lcd.invalidate()
        debugInfo("wakeup", "LCD invalidate")
    end
end

------------------------------------------------------------------------------------------------------------------------
--- Handler to paint (draw) the widget.
local function paint(widget)
    local title_h       = 0

    -- Vertical alignment constants for function drawTextCentered()
    local FREE_TOP      = 3 -- pixel free space at Top
    local FREE_TITLE    = 3 -- pixel free space below Title
    local LINE_TOP      = 1 -- align top
    local LINE_CENTERED = 2 -- align middle (centered)
    local LINE_BOTTOM   = 3 -- align bottom

    ---------------------------------------------------------------------------------------------------------------------
    --- Draw text centered in the widget.
    --- Parameters:
    ---   text         : text to draw (string)
    ---   fontSize     : font size (FONT_XS, FONT_S, FONT_L, FONT_STD, FONT_XL, FONT_XXL) - default: FONT_STD
    ---   verticalAlign: vertical alignment (LINE_TOP, LINE_CENTERED, LINE_BOTTOM) - default: LINE_CENTERED
    ---   shiftLine    : shift line (0 = no shift, -1 = one line up, 1 = one line down) - default: 0
    --------------------------------------------------------------------------------------------------------------------
    local function drawTextCentered(text, fontSize, verticalAlign, shiftLine)
        local text_w, text_h
        local yPos

        if text == nil or text == "" then return end
        if fontSize == nil then fontSize = FONT_STD end
        if verticalAlign == nil then verticalAlign = LINE_CENTERED end
        if shiftLine == nil then shiftLine = 0 end

        lcd.font(fontSize) -- set font size
        _, text_h = lcd.getTextSize("")

        if verticalAlign == LINE_TOP then        -- align top
            yPos = FREE_TOP + title_h
        elseif verticalAlign == LINE_BOTTOM then -- align bottom
            yPos = (widget.h - text_h)
        else                                     -- align centered (default)
            yPos = ((widget.h - title_h - FREE_TOP) / 2 - text_h / 2) + title_h + FREE_TOP
        end

        yPos = yPos + (shiftLine * text_h) -- shift line

        lcd.drawText((widget.w / 2), yPos, text, TEXT_CENTERED)
    end

    --------------------------------------------------------------------------------------------------------------------
    --- Paint title text.
    local function paintTitle()
        local sourceText = ""
        local titleText = ""
        local local_title_h

        title_h = 0
        if not widget.sourceShow and not widget.titleShow then return end

        -- calculate title box height
        lcd.font(FONT_S)
        _, local_title_h = lcd.getTextSize("")
        local_title_h = FREE_TOP + local_title_h + FREE_TITLE

        if widget.titleColorUse then
            --- draw title background and set title text color
            lcd.color(widget.listBGColor[TITLE_INDEX])
            lcd.drawFilledRectangle(0, 0, widget.w, local_title_h)
            lcd.color(widget.listTxColor[TITLE_INDEX])
        else
            -- set state text color
            lcd.color(widget.listTxColor[widget.state])
        end
        --- set source text
        if widget.sourceShow then -- set source text
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

        title_h = local_title_h
    end
    --------------------------------------------------------------------------------------------------------------------
    --- Paint debug information (shows internal values of the widget).
    local function paintDebugInfo()
        debugInfo("paintDebugInfo")
        assert(existWidgetSource(widget))

        local line = {}

        line[1] = STR("Source") .. " " .. widget.source:name() .. ": " .. widget.value

        if widget.state == STATE_DOWN then
            line[2] = "< " .. widget.thresholdDown
        elseif widget.state == STATE_MIDDLE then
            line[2] = ">= " .. widget.thresholdDown .. " & < " .. widget.thresholdUp
        elseif widget.state == STATE_UP then
            line[2] = ">= " .. widget.thresholdUp
        end

        if line[2] then
            line[2] = line[2] .. " -> " .. listConfTitle_int[widget.state]
            line[3] = "\"" .. widget.listText[widget.state] .. "\""
        else
            line[2] = "Status: " .. STR("StateUnknown")
            line[3] = ""
        end

        drawTextCentered(line[1], FONT_S, LINE_CENTERED, -1)
        drawTextCentered(line[2], FONT_S, LINE_CENTERED, 0)
        drawTextCentered(line[3], FONT_S, LINE_CENTERED, 1)
    end

    --------------------------------------------------------------------------------------------------------------------
    --- Paint background, set text color and paint state text (or debug information in debug mode).
    local function paintState()
        debugInfo("paintState")
        assert(existWidgetSource(widget))

        --- paint background and preset text color
        lcd.color(widget.listBGColor[widget.state])
        lcd.drawFilledRectangle(0, 0, widget.w, widget.h)

        --- paint title
        paintTitle()

        lcd.color(widget.listTxColor[widget.state])

        --- paint state text (debug oder standard)
        if widget.debugMode then
            paintDebugInfo()
        else
            drawTextCentered(widget.listText[widget.state], fontSizeList[widget.fontSizeIndex], LINE_CENTERED)
        end
    end

    --------------------------------------------------------------------------------------------------------------------
    --- Paint source missed (no valid source selected) in red on black background.
    local function paintSourceMissed()
        debugInfo("SourceMissed")
        lcd.color(COLOR_BLACK)
        lcd.drawFilledRectangle(0, 0, widget.w, widget.h)

        paintTitle()

        lcd.color(COLOR_RED)
        drawTextCentered(STR("SourceMissed"), fontSizeList[FONT_STD], LINE_CENTERED)
    end

    --------------------------------------------------------------------------------------------------------------------
    --- Paint main
    debugInfo("paint")
    if widget.h == nil then -- calculate widget
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
        local line

        line = form.addLine(listConfTitle_int[index] .. " " .. STR("Text"))
        form.addTextField(line, nil, function() return widget.listText[index] end,
            function(value) widget.listText[index] = value end)

        line = form.addLine(listConfTitle_int[index] .. " " .. STR("BackgroundColor"))
        form.addColorField(line, nil, function() return widget.listBGColor[index] end,
            function(color) widget.listBGColor[index] = color end)

        line = form.addLine(listConfTitle_int[index] .. " " .. STR("TextColor"))
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
    line = form.addLine(listConfTitle_int[TITLE_INDEX] .. " " .. STR("ColorUse"))
    form.addBooleanField(line, nil, function() return widget.titleColorUse end,
        function(value) widget.titleColorUse = value end)


    -- STATE_DOWN threshold
    line = form.addLine(STR "Threshold" .. " " .. listConfTitle_int[STATE_DOWN])
    f = form.addNumberField(line, nil, THRESHOLD_MIN * 10, THRESHOLD_MAX * 10,
        function() return widget.thresholdDown * 10 end,
        function(value) widget.thresholdDown = value / 10 end);
    f:decimals(1)

    -- STATE_UP threshold
    line = form.addLine(STR "Threshold" .. " " .. listConfTitle_int[STATE_UP])
    f = form.addNumberField(line, nil, THRESHOLD_MIN * 10, THRESHOLD_MAX * 10,
        function() return widget.thresholdUp * 10 end,
        function(value) widget.thresholdUp = value / 10 end);
    f:decimals(1)

    -- Font size
    line = form.addLine(STR "FontSize")
    form.addChoiceField(line, nil, fontSizeSelection, function() return widget.fontSizeIndex end,
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
    addConfigStaticText(STR("Widget"), STR("WidgetName"))
    addConfigStaticText(STR("Version"), WIDGET_VERSION)
    addConfigStaticText(STR("Author"), WIDGET_AUTOR)
end

------------------------------------------------------------------------------------------------------------------------
--- Handler to write (save) the widget configuration.
local function write(widget)
    debugInfo("write", "")

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

    -- source and source switch
    widget.source = storage.read("Source")
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
        create = create,
        paint = paint,
        configure = configure,
        read = read,
        write = write,
        wakeup = wakeup,
        title = false
    })
end

------------------------------------------------------------------------------------------------------------------------
--- Module main
------------------------------------------------------------------------------------------------------------------------
return { init = init }
