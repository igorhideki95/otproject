-- ============================================================
--  game_helper_healing / helper_healing.lua
--  Auto Healing Helper - usa spells e poções automaticamente
--  baseado nos thresholds de HP configurados pelo jogador.
-- ============================================================

HelperHealing = {}

-- ──────────────────────────────────────────────
-- Estado interno
-- ──────────────────────────────────────────────
local window          = nil
local statsWindow     = nil
local healingTab      = nil
local enabled         = true
local hotkey          = nil
local tickEvent       = nil
local TICK_INTERVAL   = 300  -- ms entre cada verificação

-- Configurações de healing (salvas em g_settings)
local config = {
    spell1Id      = 0,      -- clientId do spell 1 (primary)
    spell1Words   = '',     -- palavras do spell 1
    spell1Percent = 70,     -- % de HP para disparar spell 1

    spell2Id      = 0,
    spell2Words   = '',
    spell2Percent = 40,

    potion1Id     = 0,      -- itemId da poção 1
    potion1Percent= 70,

    potion2Id     = 0,
    potion2Percent= 40,
}

-- Estatísticas da sessão
local stats = {
    spellHeals   = 0,
    potionHeals  = 0,
    sessionStart = 0,
}

-- Controle de cooldown interno
local lastSpellTime  = 0
local lastPotionTime = 0
local SPELL_COOLDOWN  = 1000   -- ms
local POTION_COOLDOWN = 1000   -- ms

-- ──────────────────────────────────────────────
-- Funções auxiliares
-- ──────────────────────────────────────────────
local function saveConfig()
    for k, v in pairs(config) do
        g_settings.set('helperHealing_' .. k, tostring(v))
    end
    g_settings.set('helperHealing_enabled', tostring(enabled))
    if hotkey then
        g_settings.set('helperHealing_hotkey', hotkey)
    end
end

local function loadConfig()
    local function getNum(key, default)
        local v = g_settings.get('helperHealing_' .. key)
        return v and tonumber(v) or default
    end
    local function getStr(key, default)
        local v = g_settings.get('helperHealing_' .. key)
        return v or default
    end

    config.spell1Id       = getNum('spell1Id',       0)
    config.spell1Words    = getStr('spell1Words',     '')
    config.spell1Percent  = getNum('spell1Percent',   70)
    config.spell2Id       = getNum('spell2Id',        0)
    config.spell2Words    = getStr('spell2Words',     '')
    config.spell2Percent  = getNum('spell2Percent',   40)
    config.potion1Id      = getNum('potion1Id',       0)
    config.potion1Percent = getNum('potion1Percent',  70)
    config.potion2Id      = getNum('potion2Id',       0)
    config.potion2Percent = getNum('potion2Percent',  40)

    local ev = g_settings.get('helperHealing_enabled')
    enabled = (ev == nil or ev == 'true')
    hotkey  = g_settings.get('helperHealing_hotkey') or nil
end

local function getHPPercent()
    local player = g_game.getLocalPlayer()
    if not player then return 100 end
    local hp    = player:getHealth()
    local maxHp = player:getMaxHealth()
    if maxHp <= 0 then return 100 end
    return math.floor((hp / maxHp) * 100)
end

local function castSpell(words)
    if not words or words == '' then return false end
    g_game.talk(words)
    return true
end

local function usePotion(itemId)
    if not itemId or itemId <= 0 then return false end
    -- Procura a poção nos containers abertos
    local containers = g_game.getContainers()
    for _, container in pairs(containers) do
        local cap = container:getCapacity()
        for slot = 0, cap - 1 do
            local item = container:getItem(slot)
            if item and item:getId() == itemId then
                g_game.useInventoryItem(item:getId())
                return true
            end
        end
    end
    return false
end

local function updateStatusLabel()
    if not window then return end
    local statusValue = window:recursiveGetChildById('statusValueLabel')
    if not statusValue then return end
    if enabled then
        statusValue:setText('Enabled')
        statusValue:setColor('#00cc00')
    else
        statusValue:setText('Disabled')
        statusValue:setColor('#cc0000')
    end
end

local function updateItemBoxes()
    if not window then return end

    local function setBox(id, itemId)
        local box = window:recursiveGetChildById(id)
        if not box then return end
        if itemId and itemId > 0 then
            box:setItemId(itemId)
        else
            box:setItemId(0)
        end
    end

    setBox('spell1Icon',  config.spell1Id)
    setBox('spell2Icon',  config.spell2Id)
    setBox('potion1Icon', config.potion1Id)
    setBox('potion2Icon', config.potion2Id)
end

local function updateSpinners()
    if not window then return end

    local function setSpin(id, val)
        local spin = window:recursiveGetChildById(id)
        if spin then spin:setValue(val) end
    end

    setSpin('spell1Percent',  config.spell1Percent)
    setSpin('spell2Percent',  config.spell2Percent)
    setSpin('potion1Percent', config.potion1Percent)
    setSpin('potion2Percent', config.potion2Percent)
end

local function updateStats()
    if not statsWindow or not statsWindow:isVisible() then return end
    local total    = statsWindow:recursiveGetChildById('statsTotalHeals')
    local spells   = statsWindow:recursiveGetChildById('statsSpellHeals')
    local potions  = statsWindow:recursiveGetChildById('statsPotionHeals')
    local session  = statsWindow:recursiveGetChildById('statsSession')

    if total   then total:setText('Total Heals: '   .. (stats.spellHeals + stats.potionHeals)) end
    if spells  then spells:setText('Spell Heals: '  .. stats.spellHeals)  end
    if potions then potions:setText('Potion Heals: ' .. stats.potionHeals) end
    if session then
        local elapsed = os.time() - (stats.sessionStart > 0 and stats.sessionStart or os.time())
        session:setText('Session: ' .. elapsed .. 's')
    end
end

-- ──────────────────────────────────────────────
-- Loop principal de healing
-- ──────────────────────────────────────────────
local function onHealingTick()
    if not enabled then return end
    if not g_game.isOnline() then return end

    local hp  = getHPPercent()
    local now = g_clock.millis()

    -- ── Spell healing ──
    if now - lastSpellTime >= SPELL_COOLDOWN then
        -- Spell 2 tem prioridade por ser mais urgente (% menor)
        if config.spell2Words ~= '' and hp <= config.spell2Percent then
            if castSpell(config.spell2Words) then
                lastSpellTime = now
                stats.spellHeals = stats.spellHeals + 1
                updateStats()
                return
            end
        end

        if config.spell1Words ~= '' and hp <= config.spell1Percent then
            if castSpell(config.spell1Words) then
                lastSpellTime = now
                stats.spellHeals = stats.spellHeals + 1
                updateStats()
                return
            end
        end
    end

    -- ── Potion healing ──
    if now - lastPotionTime >= POTION_COOLDOWN then
        if config.potion2Id > 0 and hp <= config.potion2Percent then
            if usePotion(config.potion2Id) then
                lastPotionTime = now
                stats.potionHeals = stats.potionHeals + 1
                updateStats()
                return
            end
        end

        if config.potion1Id > 0 and hp <= config.potion1Percent then
            if usePotion(config.potion1Id) then
                lastPotionTime = now
                stats.potionHeals = stats.potionHeals + 1
                updateStats()
            end
        end
    end
end

-- ──────────────────────────────────────────────
-- Callbacks da UI
-- ──────────────────────────────────────────────
function HelperHealing.onToggleEnabled(checked)
    enabled = checked
    updateStatusLabel()
    saveConfig()
end

function HelperHealing.onSpell1PercentChange(value)
    config.spell1Percent = value
    saveConfig()
end

function HelperHealing.onSpell2PercentChange(value)
    config.spell2Percent = value
    saveConfig()
end

function HelperHealing.onPotion1PercentChange(value)
    config.potion1Percent = value
    saveConfig()
end

function HelperHealing.onPotion2PercentChange(value)
    config.potion2Percent = value
    saveConfig()
end

-- Abre um popup para o jogador escolher o spell (slot 1 ou 2)
local function openSpellSelector(slot)
    local menu = g_ui.createWidget('PopupMenu')
    menu:setGameMenu(true)

    -- Itera sobre os spells de cura conhecidos
    local healSpells = {
        {name = 'Light Healing',    words = 'exura',      id = 5},
        {name = 'Intense Healing',  words = 'exura gran', id = 6},
        {name = 'Ultimate Healing', words = 'exura vita', id = 0},
        {name = 'Divine Healing',   words = 'exura san',  id = 3},
        {name = 'Wound Cleansing',  words = 'exura ico',  id = 4},
    }

    -- Adiciona spells conhecidos pelo player via SpellInfo se disponível
    if SpellInfo and SpellInfo.Default then
        healSpells = {}
        for name, spell in pairs(SpellInfo.Default) do
            if spell.group and spell.group[2] then  -- grupo 2 = healing
                table.insert(healSpells, {name = spell.name, words = spell.words, id = spell.clientId})
            end
        end
        table.sort(healSpells, function(a, b) return a.name < b.name end)
    end

    menu:addOption('-- Nenhum --', function()
        if slot == 1 then
            config.spell1Id    = 0
            config.spell1Words = ''
        else
            config.spell2Id    = 0
            config.spell2Words = ''
        end
        updateItemBoxes()
        saveConfig()
    end)

    for _, spell in ipairs(healSpells) do
        local s = spell
        menu:addOption(s.name .. ' (' .. s.words .. ')', function()
            if slot == 1 then
                config.spell1Id    = s.id
                config.spell1Words = s.words
            else
                config.spell2Id    = s.id
                config.spell2Words = s.words
            end
            updateItemBoxes()
            saveConfig()
        end)
    end

    menu:display(g_window.getMousePosition())
end

local function openPotionSelector(slot)
    local menu = g_ui.createWidget('PopupMenu')
    menu:setGameMenu(true)

    local potions = {
        {name = 'Health Potion',        id = 7618},
        {name = 'Strong Health Potion', id = 7588},
        {name = 'Great Health Potion',  id = 7591},
        {name = 'Ultimate Health Potion', id = 7592},
        {name = 'Supreme Health Potion',  id = 23373},
    }

    menu:addOption('-- Nenhum --', function()
        if slot == 1 then
            config.potion1Id = 0
        else
            config.potion2Id = 0
        end
        updateItemBoxes()
        saveConfig()
    end)

    for _, potion in ipairs(potions) do
        local p = potion
        menu:addOption(p.name, function()
            if slot == 1 then
                config.potion1Id = p.id
            else
                config.potion2Id = p.id
            end
            updateItemBoxes()
            saveConfig()
        end)
    end

    menu:display(g_window.getMousePosition())
end

function HelperHealing.onSpell1IconClick(widget, mousePos, mouseButton)
    if mouseButton == MouseLeftButton then
        openSpellSelector(1)
    end
end

function HelperHealing.onSpell2IconClick(widget, mousePos, mouseButton)
    if mouseButton == MouseLeftButton then
        openSpellSelector(2)
    end
end

function HelperHealing.onPotion1IconClick(widget, mousePos, mouseButton)
    if mouseButton == MouseLeftButton then
        openPotionSelector(1)
    end
end

function HelperHealing.onPotion2IconClick(widget, mousePos, mouseButton)
    if mouseButton == MouseLeftButton then
        openPotionSelector(2)
    end
end

function HelperHealing.openSpell1Info()
    local msg = 'Spell 1 (Primary):\n'
              .. 'HP <= ' .. config.spell1Percent .. '%\n'
              .. 'Words: ' .. (config.spell1Words ~= '' and config.spell1Words or 'Not set')
    displayInfoBox('Spell Healing Info', msg)
end

function HelperHealing.openSpell2Info()
    local msg = 'Spell 2 (Secondary):\n'
              .. 'HP <= ' .. config.spell2Percent .. '%\n'
              .. 'Words: ' .. (config.spell2Words ~= '' and config.spell2Words or 'Not set')
    displayInfoBox('Spell Healing Info', msg)
end

function HelperHealing.openPotion1Info()
    local msg = 'Potion 1 (Primary):\n'
              .. 'HP <= ' .. config.potion1Percent .. '%\n'
              .. 'Item ID: ' .. config.potion1Id
    displayInfoBox('Potion Healing Info', msg)
end

function HelperHealing.openPotion2Info()
    local msg = 'Potion 2 (Secondary):\n'
              .. 'HP <= ' .. config.potion2Percent .. '%\n'
              .. 'Item ID: ' .. config.potion2Id
    displayInfoBox('Potion Healing Info', msg)
end

function HelperHealing.openSetKey()
    -- Abre o mapeador de tecla padrão do OTClient
    if modules.client_options then
        modules.client_options.show()
    end
end

-- ──────────────────────────────────────────────
-- Stats Window
-- ──────────────────────────────────────────────
function HelperHealing.openStats()
    if statsWindow then
        statsWindow:setVisible(true)
        updateStats()
    end
end

function HelperHealing.closeStats()
    if statsWindow then
        statsWindow:setVisible(false)
    end
end

function HelperHealing.resetStats()
    stats.spellHeals   = 0
    stats.potionHeals  = 0
    stats.sessionStart = os.time()
    updateStats()
end

-- ──────────────────────────────────────────────
-- Toggle principal (abrir/fechar janela)
-- ──────────────────────────────────────────────
function HelperHealing.toggle()
    if not window then return end
    if window:isVisible() then
        window:setVisible(false)
    else
        window:setVisible(true)
        window:raise()
        window:focus()
    end
end

-- ──────────────────────────────────────────────
-- Ciclo de vida do módulo
-- ──────────────────────────────────────────────
function HelperHealing.init()
    -- Carrega UI
    g_ui.importStyle('helper_healing')
    window      = g_ui.loadUI('helper_healing', modules.game_interface.getMapPanel())
    statsWindow = window:recursiveGetChildById('helperStatsWindow')

    -- Desanexa a statsWindow para ela flutuar livremente
    if statsWindow then
        statsWindow:setParent(rootWidget)
        statsWindow:setVisible(false)
        statsWindow:centerIn('parent')
    end

    -- Carrega config salva
    loadConfig()

    -- Aplica valores na UI
    updateStatusLabel()
    updateItemBoxes()
    updateSpinners()

    -- Checkbox de enabled
    local cb = window:recursiveGetChildById('enabledCheckBox')
    if cb then cb:setChecked(enabled) end

    -- Inicia stats
    stats.sessionStart = os.time()

    -- Inicia o tick de healing
    tickEvent = cycleEvent(onHealingTick, TICK_INTERVAL)

    -- Registra hotkey padrão (F8) se não houver salva
    if not hotkey then
        hotkey = 'F8'
        saveConfig()
    end
    g_hotkeys.bindKeyDown(hotkey, HelperHealing.toggle)

    -- Botão de toggle na barra lateral (se existir)
    local button = modules.game_interface.addBottomPanel and
                   modules.game_interface.addBottomPanel('helperHealingButton', '/images/game/icons/healing', 'Auto Healing Helper', HelperHealing.toggle)
end

function HelperHealing.terminate()
    if tickEvent then
        tickEvent:cancel()
        tickEvent = nil
    end

    if hotkey then
        g_hotkeys.unbindKeyDown(hotkey)
    end

    saveConfig()

    if statsWindow then
        statsWindow:destroy()
        statsWindow = nil
    end

    if window then
        window:destroy()
        window = nil
    end
end
