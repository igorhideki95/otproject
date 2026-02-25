local window = nil
local selectedEntry = nil
local consoleEvent = nil
local taskButton = nil

local DAILY_TASK_OPCODE = 215

local function updateSummary(summary)
    if not window or not summary then
        return
    end

    local nextName = summary.nextRankName or "MAX"
    local nextFrags = tonumber(summary.nextRankFrags) or 0
    local currentFrags = tonumber(summary.rankFrags) or 0
    local remaining = math.max(0, nextFrags - currentFrags)

    window.rankName:setText(string.format("Rank: %s", summary.rankName or "Bronze Hunter"))
    window.rankFrags:setText(string.format("Task frags: %d", currentFrags))

    if nextName == "MAX" then
        window.nextRank:setText("Next rank: MAX")
    else
        window.nextRank:setText(string.format("Next rank: %s (%d frags left)", nextName, remaining))
    end

    local resetIn = tonumber(summary.resetIn) or 0
    local h = math.floor(resetIn / 3600)
    local m = math.floor((resetIn % 3600) / 60)
    window.dailyReset:setText(string.format("Daily reset in: %02dh %02dm", h, m))
end

function init()
    connect(g_game, {
        onGameStart = onGameStart,
        onGameEnd = destroy,
    })

    window = g_ui.displayUI("tasks")
    window:setVisible(false)

    Keybind.new("Windows", "show/hide Daily Tasks Window", "Ctrl+A", "")
    Keybind.bind("Windows", "show/hide Daily Tasks Window", {
        {
            type = KEY_DOWN,
            callback = toggleWindow,
        },
    })

    g_keyboard.bindKeyDown("Escape", hideWindow)
    taskButton = modules.client_topmenu.addLeftGameButton("taskButton", tr("Daily Tasks"), "/modules/game_tasks/images/taskIcon", toggleWindow)

    ProtocolGame.registerExtendedOpcode(DAILY_TASK_OPCODE, parseOpcode)
end

function terminate()
    disconnect(g_game, {
        onGameEnd = destroy,
    })

    ProtocolGame.unregisterExtendedOpcode(DAILY_TASK_OPCODE)

    if taskButton then
        taskButton:destroy()
        taskButton = nil
    end

    destroy()
    Keybind.delete("Windows", "show/hide Daily Tasks Window")
end

function onGameStart()
    if window then
        window:destroy()
        window = nil
    end

    window = g_ui.displayUI("tasks")
    window:setVisible(false)
    window.listSearch.search.onKeyPress = onFilterSearch
end

function destroy()
    if window then
        window:destroy()
        window = nil
    end
end

function parseOpcode(protocol, opcode, buffer)
    local ok, data = pcall(function()
        return json.decode(buffer)
    end)

    if not ok or type(data) ~= "table" then
        return
    end

    updateTasks(data)
end

function sendOpcode(data)
    local protocolGame = g_game.getProtocolGame()
    if protocolGame then
        protocolGame:sendExtendedOpcode(DAILY_TASK_OPCODE, json.encode(data))
    end
end

function onItemSelect(list, focusedChild, unfocusedChild, reason)
    if not focusedChild then
        return
    end

    selectedEntry = tonumber(focusedChild:getId())
    if not selectedEntry then
        return
    end

    window.finishButton:hide()
    window.startButton:hide()
    window.abortButton:hide()

    local children = window.selectionList:getChildren()
    for _, child in ipairs(children) do
        local id = tonumber(child:getId())
        if selectedEntry == id then
            local killsText = child.kills:getText()
            local completedToday = child:getTooltip() == "Completed today"

            if completedToday then
                window.startButton:hide()
                window.finishButton:hide()
                window.abortButton:hide()
            elseif child.progress:getWidth() == 159 and killsText:find("/") then
                window.finishButton:show()
            elseif killsText:find("/") then
                window.abortButton:show()
            else
                window.startButton:show()
            end
        end
    end
end

function onFilterSearch()
    addEvent(function()
        local searchText = window.listSearch.search:getText():lower():trim()
        local children = window.selectionList:getChildren()

        if searchText:len() >= 1 then
            for _, child in ipairs(children) do
                local text = child.name:getText():lower()
                if text:find(searchText) then
                    child:show()
                else
                    child:hide()
                end
            end
        else
            for _, child in ipairs(children) do
                child:show()
            end
        end
    end)
end

function start()
    if not selectedEntry then
        return not setTaskConsoleText("Please select monster from monster list.", "red")
    end

    sendOpcode({ action = "start", entry = selectedEntry })
end

function finish()
    if not selectedEntry then
        return not setTaskConsoleText("Please select monster from monster list.", "red")
    end

    sendOpcode({ action = "finish", entry = selectedEntry })
end

function abort()
    if not selectedEntry then
        return not setTaskConsoleText("Please select monster from monster list.", "red")
    end

    local confirm
    local yesFunc = function()
        confirm:destroy()
        confirm = nil
        sendOpcode({ action = "cancel", entry = selectedEntry })
    end

    local noFunc = function()
        confirm:destroy()
        confirm = nil
    end

    confirm = displayGeneralBox(tr("Daily Tasks"), tr("Do you really want to abort this task?"), {
        { text = tr("Yes"), callback = yesFunc },
        { text = tr("No"), callback = noFunc },
        anchor = AnchorHorizontalCenter,
    }, yesFunc, noFunc)
end

function updateTasks(data)
    if data.message then
        return setTaskConsoleText(data.message, data.color)
    end

    updateSummary(data.summary)

    local selectionList = window.selectionList
    selectionList.onChildFocusChange = onItemSelect
    selectionList:destroyChildren()
    local playerTaskIds = {}

    for _, task in ipairs(data.playerTasks or {}) do
        local button = g_ui.createWidget("SelectionButton", selectionList)
        button:setId(task.id)
        table.insert(playerTaskIds, task.id)
        button.creature:setOutfit(task.looktype)
        button.name:setText(task.name)
        button.kills:setText(string.format("Frags: %d/%d", task.done, task.kills))
        button.reward:setText(string.format("Reward: %d exp", task.exp))
        button.rewardTaskPoints:setText(string.format("Task Points: %d", task.taskPoints or 0))

        if task.finishedToday then
            button:setTooltip("Completed today")
            button.progress:setWidth(159)
            button.kills:setText("Completed today")
        else
            local progress = 159 * task.done / task.kills
            button.progress:setWidth(progress)
        end

        selectionList:focusChild(button)
    end

    for _, task in ipairs(data.allTasks or {}) do
        if not table.contains(playerTaskIds, task.id) then
            local button = g_ui.createWidget("SelectionButton", selectionList)
            button:setId(task.id)
            button.creature:setOutfit(task.looktype)
            button.name:setText(task.name)
            button.kills:setText(string.format("Required frags: %d", task.kills))
            button.reward:setText(string.format("Reward: %d exp", task.exp))
            button.rewardTaskPoints:setText(string.format("Task Points: %d", task.taskPoints or 0))
            button.progress:setWidth(0)
            selectionList:focusChild(button)
        end
    end

    selectionList:focusChild(selectionList:getFirstChild())
    onFilterSearch()
end

function toggleWindow()
    if not g_game.isOnline() then
        return
    end

    if window:isVisible() then
        sendOpcode({ action = "hide" })
        window:setVisible(false)
    else
        sendOpcode({ action = "info" })
        window:setVisible(true)
    end
end

function hideWindow()
    if not g_game.isOnline() then
        return
    end

    if window:isVisible() then
        sendOpcode({ action = "hide" })
        window:setVisible(false)
    end
end

function setTaskConsoleText(text, color)
    color = color or "white"

    window.info:setText(text)
    window.info:setColor(color)

    if consoleEvent then
        removeEvent(consoleEvent)
        consoleEvent = nil
    end

    consoleEvent = scheduleEvent(function()
        window.info:setText("")
    end, 5000)

    return true
end
