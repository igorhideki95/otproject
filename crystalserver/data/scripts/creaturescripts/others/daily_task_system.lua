local DAILY_TASK_OPCODE = 215

local DailyTaskConfig = {
    taskPointsStorage = 5151,
    maximumTasks = 3,
    countForParty = true,
    maxDist = 7,
    activeStorageBase = 1500,
    totalFragsStorage = 1590,
    rankStorage = 1591,
    dailyFinishStorageBase = 1700,
    tasks = {
        { id = 1, name = "Rat", looktype = { type = 21 }, kills = 25, exp = 1500, taskPoints = 0 },
        { id = 2, name = "Cave Rat", looktype = { type = 56 }, kills = 25, exp = 2000, taskPoints = 50 },
        { id = 3, name = "Snake", looktype = { type = 28 }, kills = 25, exp = 2000, taskPoints = 30 },
        { id = 4, name = "Scorpion", looktype = { type = 43 }, kills = 25, exp = 2000, taskPoints = 30 },
        { id = 5, name = "Amazon", looktype = { type = 137, feet = 115, addons = 0, legs = 95, auxType = 7399, head = 113, body = 120 }, kills = 150, exp = 5000, taskPoints = 120 },
        { id = 6, name = "Valkyrie", looktype = { type = 139, feet = 96, addons = 0, legs = 76, auxType = 7399, head = 113, body = 38 }, kills = 150, exp = 8000, taskPoints = 160 },
    },
    ranks = {
        { id = 1, name = "Bronze Hunter", frags = 0 },
        { id = 2, name = "Silver Hunter", frags = 100 },
        { id = 3, name = "Gold Hunter", frags = 300 },
        { id = 4, name = "Platinum Hunter", frags = 700 },
        { id = 5, name = "Diamond Hunter", frags = 1200 },
    },
}

local function getDailyKey()
    return os.date("%Y%j")
end

local function sendJsonOpcode(player, opcode, payload)
    player:sendExtendedOpcode(opcode, json.encode(payload))
end

DailyTaskSystem = {
    playersViewing = {},
    byName = {},
}

function DailyTaskSystem.loadDatabase()
    if next(DailyTaskSystem.byName) then
        return true
    end

    for _, task in ipairs(DailyTaskConfig.tasks) do
        DailyTaskSystem.byName[task.name:lower()] = task
    end
    return true
end

function DailyTaskSystem.getTotalFrags(player)
    return math.max(0, player:getStorageValue(DailyTaskConfig.totalFragsStorage))
end

function DailyTaskSystem.getRankByFrags(frags)
    local current = DailyTaskConfig.ranks[1]
    local nextRank = nil

    for index, rank in ipairs(DailyTaskConfig.ranks) do
        if frags >= rank.frags then
            current = rank
        else
            nextRank = rank
            break
        end

        if index == #DailyTaskConfig.ranks then
            nextRank = nil
        end
    end

    return current, nextRank
end

function DailyTaskSystem.syncRankStorage(player)
    local frags = DailyTaskSystem.getTotalFrags(player)
    local currentRank = DailyTaskSystem.getRankByFrags(frags)
    player:setStorageValue(DailyTaskConfig.rankStorage, currentRank.id)
end

function DailyTaskSystem.getPlayerTaskIds(player)
    local taskIds = {}
    for _, task in ipairs(DailyTaskConfig.tasks) do
        if player:getStorageValue(DailyTaskConfig.activeStorageBase + task.id) > 0 then
            table.insert(taskIds, task.id)
        end
    end
    return taskIds
end

function DailyTaskSystem.isFinishedToday(player, task)
    local day = player:getStorageValue(DailyTaskConfig.dailyFinishStorageBase + task.id)
    return tostring(day) == getDailyKey()
end

function DailyTaskSystem.getCurrentTasks(player)
    local tasks = {}
    for _, task in ipairs(DailyTaskConfig.tasks) do
        local left = player:getStorageValue(DailyTaskConfig.activeStorageBase + task.id)
        if left > 0 then
            local copy = {
                id = task.id,
                name = task.name,
                looktype = task.looktype,
                kills = task.kills,
                exp = task.exp,
                taskPoints = task.taskPoints,
                left = left,
                done = task.kills - (left - 1),
                finishedToday = DailyTaskSystem.isFinishedToday(player, task),
            }
            table.insert(tasks, copy)
        end
    end

    return tasks
end

function DailyTaskSystem.getSummary(player)
    local frags = DailyTaskSystem.getTotalFrags(player)
    local rank, nextRank = DailyTaskSystem.getRankByFrags(frags)

    local resetAt = os.time({
        year = tonumber(os.date("%Y")),
        month = tonumber(os.date("%m")),
        day = tonumber(os.date("%d")) + 1,
        hour = 0,
        min = 0,
        sec = 0,
    })

    return {
        rankName = rank.name,
        rankFrags = frags,
        nextRankName = nextRank and nextRank.name or "MAX",
        nextRankFrags = nextRank and nextRank.frags or frags,
        resetIn = math.max(0, resetAt - os.time()),
    }
end

function DailyTaskSystem.sendData(player)
    local response = {
        allTasks = DailyTaskConfig.tasks,
        playerTasks = DailyTaskSystem.getCurrentTasks(player),
        summary = DailyTaskSystem.getSummary(player),
    }
    sendJsonOpcode(player, DAILY_TASK_OPCODE, response)
end

function DailyTaskSystem.startTask(player, entry)
    local playerTaskIds = DailyTaskSystem.getPlayerTaskIds(player)
    if #playerTaskIds >= DailyTaskConfig.maximumTasks then
        return sendJsonOpcode(player, DAILY_TASK_OPCODE, { message = "You can't take more daily tasks.", color = "red" })
    end

    for _, task in ipairs(DailyTaskConfig.tasks) do
        if task.id == entry then
            if table.contains(playerTaskIds, task.id) then
                return sendJsonOpcode(player, DAILY_TASK_OPCODE, { message = "You already have this task active.", color = "red" })
            end

            if DailyTaskSystem.isFinishedToday(player, task) then
                return sendJsonOpcode(player, DAILY_TASK_OPCODE, { message = "You already finished this daily task today.", color = "red" })
            end

            player:setStorageValue(DailyTaskConfig.activeStorageBase + task.id, task.kills + 1)
            sendJsonOpcode(player, DAILY_TASK_OPCODE, { message = "Daily task started.", color = "green" })
            return DailyTaskSystem.sendData(player)
        end
    end

    return sendJsonOpcode(player, DAILY_TASK_OPCODE, { message = "Unknown task.", color = "red" })
end

function DailyTaskSystem.cancelTask(player, entry)
    for _, task in ipairs(DailyTaskConfig.tasks) do
        if task.id == entry then
            if not table.contains(DailyTaskSystem.getPlayerTaskIds(player), task.id) then
                return sendJsonOpcode(player, DAILY_TASK_OPCODE, { message = "You don't have this task active.", color = "red" })
            end

            player:setStorageValue(DailyTaskConfig.activeStorageBase + task.id, -1)
            sendJsonOpcode(player, DAILY_TASK_OPCODE, { message = "Task aborted.", color = "green" })
            return DailyTaskSystem.sendData(player)
        end
    end

    return sendJsonOpcode(player, DAILY_TASK_OPCODE, { message = "Unknown task.", color = "red" })
end

function DailyTaskSystem.finishTask(player, entry)
    for _, task in ipairs(DailyTaskConfig.tasks) do
        if task.id == entry then
            if not table.contains(DailyTaskSystem.getPlayerTaskIds(player), task.id) then
                return sendJsonOpcode(player, DAILY_TASK_OPCODE, { message = "You don't have this task active.", color = "red" })
            end

            local left = player:getStorageValue(DailyTaskConfig.activeStorageBase + task.id)
            if left > 1 then
                return sendJsonOpcode(player, DAILY_TASK_OPCODE, { message = "Task isn't completed yet.", color = "red" })
            end

            player:setStorageValue(DailyTaskConfig.activeStorageBase + task.id, -1)
            player:setStorageValue(DailyTaskConfig.dailyFinishStorageBase + task.id, getDailyKey())
            player:addExperience(task.exp)

            local currentPoints = math.max(0, player:getStorageValue(DailyTaskConfig.taskPointsStorage))
            player:setStorageValue(DailyTaskConfig.taskPointsStorage, currentPoints + (task.taskPoints or 0))

            local frags = DailyTaskSystem.getTotalFrags(player) + task.kills
            player:setStorageValue(DailyTaskConfig.totalFragsStorage, frags)
            DailyTaskSystem.syncRankStorage(player)

            sendJsonOpcode(player, DAILY_TASK_OPCODE, { message = "Daily task finished! Progress and rank updated.", color = "green" })
            return DailyTaskSystem.sendData(player)
        end
    end

    return sendJsonOpcode(player, DAILY_TASK_OPCODE, { message = "Unknown task.", color = "red" })
end

function DailyTaskSystem.onAction(player, data)
    if type(data) ~= "table" then
        return
    end

    local action = data.action
    if action == "info" then
        DailyTaskSystem.playersViewing[player.uid] = true
        return DailyTaskSystem.sendData(player)
    end

    if action == "hide" then
        DailyTaskSystem.playersViewing[player.uid] = nil
        return true
    end

    local entry = tonumber(data.entry)
    if not entry then
        return sendJsonOpcode(player, DAILY_TASK_OPCODE, { message = "Invalid task entry.", color = "red" })
    end

    if action == "start" then
        return DailyTaskSystem.startTask(player, entry)
    end

    if action == "cancel" then
        return DailyTaskSystem.cancelTask(player, entry)
    end

    if action == "finish" then
        return DailyTaskSystem.finishTask(player, entry)
    end
end

function DailyTaskSystem.killForPlayer(player, task)
    local left = player:getStorageValue(DailyTaskConfig.activeStorageBase + task.id)
    if left <= 0 then
        return
    end

    if left == 1 then
        if DailyTaskSystem.playersViewing[player.uid] then
            sendJsonOpcode(player, DAILY_TASK_OPCODE, { message = "Task complete! Click finish to claim rewards.", color = "green" })
        end
        return
    end

    player:setStorageValue(DailyTaskConfig.activeStorageBase + task.id, left - 1)

    if DailyTaskSystem.playersViewing[player.uid] then
        DailyTaskSystem.sendData(player)
    end
end

function DailyTaskSystem.onKill(player, target)
    local task = DailyTaskSystem.byName[target:getName():lower()]
    if not task then
        return true
    end

    local tpos = target:getPosition()
    local party = player:getParty()

    if DailyTaskConfig.countForParty and party and party:getMembers() then
        for _, member in pairs(party:getMembers()) do
            local pos = member:getPosition()
            if pos.z == tpos.z and pos:getDistance(tpos) <= DailyTaskConfig.maxDist then
                DailyTaskSystem.killForPlayer(member, task)
            end
        end

        local leader = party:getLeader()
        if leader then
            local lpos = leader:getPosition()
            if lpos.z == tpos.z and lpos:getDistance(tpos) <= DailyTaskConfig.maxDist then
                DailyTaskSystem.killForPlayer(leader, task)
            end
        end
    else
        DailyTaskSystem.killForPlayer(player, task)
    end

    return true
end

local taskStartup = GlobalEvent("DailyTaskStartup")
function taskStartup.onStartup()
    return DailyTaskSystem.loadDatabase()
end
taskStartup:register()

local taskKill = CreatureEvent("DailyTaskKill")
function taskKill.onKill(creature, target)
    if not creature:isPlayer() or not Monster(target) then
        return true
    end

    DailyTaskSystem.onKill(creature, target)
    return true
end
taskKill:register()

local taskExtended = CreatureEvent("DailyTaskExtendedOpcode")
function taskExtended.onExtendedOpcode(player, opcode, buffer)
    if opcode ~= DAILY_TASK_OPCODE then
        return true
    end

    local ok, decoded = pcall(json.decode, buffer)
    if not ok then
        return true
    end

    DailyTaskSystem.onAction(player, decoded)
    return true
end
taskExtended:register()
