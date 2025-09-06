PizzaSlices = CreateFrame('Frame', 'PizzaSlices', UIParent)
local PS = PizzaSlices

PS.name = PS:GetName()
PS.open = false
PS.fps = 60

PS.modules = {}
PS.moduleNames = {}
PS.overrides = {}
PS.frames = {}
PS.env = {}

PS.Colors = {
  primary = '|cffa050ff',
  secondary = '|cffffffff',
  red = '|cffff462e',
  grey = '|cffaaaaaa',
  green = '|cff00ff98',
}

BINDING_HEADER_PIZZASLICES = 'PizzaSlices'
BINDING_NAME_PIZZASLICES_RING1 = 'Ring 1'
BINDING_NAME_PIZZASLICES_RING2 = 'Ring 2'
BINDING_NAME_PIZZASLICES_RING3 = 'Ring 3'
BINDING_NAME_PIZZASLICES_RING4 = 'Ring 4'
BINDING_NAME_PIZZASLICES_RING5 = 'Ring 5'
BINDING_NAME_PIZZASLICES_RING6 = 'Ring 6'
BINDING_NAME_PIZZASLICES_RING7 = 'Ring 7'
BINDING_NAME_PIZZASLICES_RING8 = 'Ring 8'
BINDING_NAME_PIZZASLICES_RING9 = 'Ring 9'
BINDING_NAME_PIZZASLICES_RING10 = 'Ring 10'
BINDING_NAME_PIZZASLICES_RING11 = 'Ring 11'
BINDING_NAME_PIZZASLICES_RING12 = 'Ring 12'
BINDING_NAME_PIZZASLICES_RING13 = 'Ring 13'
BINDING_NAME_PIZZASLICES_RING14 = 'Ring 14'
BINDING_NAME_PIZZASLICES_RING15 = 'Ring 15'
BINDING_NAME_PIZZASLICES_CLOSE = 'Close Ring'

setmetatable(PS.env, { __index = function (self, key)
  if key == 'T' then return end
  return getfenv(0)[key]
end})

function PS:GetEnv()
  if not PS.env.T then
    local locale = GetLocale() or 'enUS'
    PS.env.T = setmetatable({}, {
      __index = function(tbl, key)
        local value = tostring(key)
        rawset(tbl, key, value)
        return value
      end
    })
  end

  PS.env._G = getfenv(0)
  PS.env.C = PizzaSlices_config
  PS.env.PS = PizzaSlices

  return PS.env
end

setfenv(1, PS:GetEnv())

function PS:Print(msg, withPrefix)
  local prefix = withPrefix == false and '' or PS.Colors.primary .. 'Pizza' .. PS.Colors.secondary .. 'Slices:|r '
  DEFAULT_CHAT_FRAME:AddMessage(prefix .. msg)
end

function PS:PrintClean(msg)
  PS:Print(msg, false)
end

function PS:PrintError(msg)
  PS:Print(PS.Colors.red .. msg)
end

function PS:RegisterModule(name, module)
  if PS.modules[name] then return end
  PS.modules[name] = module
  table.insert(PS.moduleNames, name)
end

function PS:LoadModule(name)
  setfenv(PS.modules[name], PS:GetEnv())
  PS.modules[name]()
end

function PS:SelectSlice(selectedIdx)
  if not PS.ring then return end

  PS.selectedIdx = selectedIdx
  for idx, slice in PS.ring.slices do
    slice.selected = idx == selectedIdx
  end
end

function PS:Deselect()
  PS:SelectSlice()
end

local actions = {
  spell = function (v, slice)
    local spellName = v == '<name>' and slice.name or v
    if slice.rank then
      spellName = spellName .. '(' .. slice.rank .. ')'
    elseif string.find(spellName, '%(%w+%)') then
      -- See https://vanilla-wow-archive.fandom.com/wiki/API_CastSpellByName#Notes
      spellName = spellName .. '()'
    end
    CastSpellByName(spellName)
  end,

  raidmark = function (v)
    local isSolo = GetNumPartyMembers() == 0 and GetNumRaidMembers() == 0
    local soloRaidMark = PS.utils.hasSuperWoW() and isSolo

    if v == 'clear' then
      if PS.utils.hasSuperWoW() then
        for i = 1, 8 do
          if UnitExists('mark' .. i) then
            SetRaidTarget('mark' .. i, 0, soloRaidMark)
          end
        end
      else
        for i = 1, 8 do
          SetRaidTarget('player', i, soloRaidMark)
        end
        PS.clearRaidTargetAt = GetTime() + .15
      end
    else
      SetRaidTarget('target', tonumber(v), soloRaidMark)
    end
  end,

  itemrack = function (v, slice)
    if v == '<name>' then
      local _, _, setName = PS.utils.strSplit(slice.name, ' ')
      if setName then Rack.EquipSet(setName) end
    else
      Rack.EquipSet(v)
    end
  end,

  macro = function (v, slice)
    local runMacro = PS.macro.getRunMacro()
    if v == '<name>' then
      local macroName = string.gsub(slice.name, 'Macro: ', '')
      if macroName then runMacro(macroName) end
    else
      runMacro(v)
    end
  end,

  item = function (v, slice)
    local bag, slot = PS.utils.findItem(slice.name)
    if bag and slot then
      if IsShiftKeyDown() then
        PickupContainerItem(bag, slot)
        if CursorHasItem() then
          local link = GetContainerItemLink(bag, slot)
          if link then
            local _, _, name = string.find(link, '%[(.+)%]')
            if name then
              UseItemByName(name)
            end
          end
        end
      else
        UseContainerItem(bag, slot)
      end
    end
  end,
}

function PS:TriggerSliceAction(idx)
  if not idx or not PS.ring or not PS.ring.slices or not PS.ring.slices[idx] or not PS.ring.slices[idx].action then return end
  local slice = PS.ring.slices[idx]
  local actionType, actionValue = PS.utils.strSplit(slice.action, ':')
  local action = actions[actionType]
  if not action then
    PS:PrintError('Unable to trigger slice action "' .. slice.action .. '". Action type has no handler!')
    return
  end
  action(actionValue, slice)
end

function PS:Open(ringIdx, fromCommand)
  if not PizzaSlices_rings[ringIdx] then return end

  local ring = PS.utils.clone(PizzaSlices_rings[ringIdx])
  if not ring or PS.utils.length(ring.slices) == 0 then
    PS.open = false
    PS:Deselect()
    return
  end

  if fromCommand then
    for slot = 1, 120 do
      local macroName = GetActionText(slot)
      if macroName and PS.macro.opensRing(macroName, ringIdx) then
        local button = PS.utils.getButtonForSlot(slot)
        if not button then
          PS:PrintError('No button found for slot ' .. slot)
          return
        end
        local keys = PS.utils.getButtonBinding(button)
        if keys and PS.utils.length(keys) > 0 then
          for _, key in ipairs(keys) do
            local oldAction = GetBindingAction(key)
            SetBinding(key, 'PIZZASLICES_CLOSE')
            table.insert(PS.overrides, { key = key, oldAction = oldAction })
          end
        end
      end
    end
  end

  PS.open = fromCommand or keystate == 'down'
  if PS.open then
    PS.frame.open(ring)
  elseif PS.selectedIdx then
    PS:TriggerSliceAction(PS.selectedIdx)
    PS:Deselect()
  end
end

function PS:Close()
  -- Restore original key binds that were overridden if the
  -- ring was opened through slash command.
  for idx, override in ipairs(PS.overrides) do
    if override.key then
      SetBinding(override.key)
      if override.oldAction and override.oldAction ~= '' then
        SetBinding(override.key, override.oldAction)
        if PS.OnClose then
          PS.OnClose()
          PS.OnClose = nil
        end
      end
    end
  end
  PS.overrides = {}

  PS.open = false
  if PS.selectedIdx then
    PS:TriggerSliceAction(PS.selectedIdx)
    PS:Deselect()
  end
end

PS:RegisterEvent('ADDON_LOADED')
PS:RegisterEvent('CHAT_MSG_CHANNEL')
PS:SetScript('OnEvent', function ()
  if event == 'ADDON_LOADED' and arg1 == PS.name then
    PS:LoadConfig()

    for _, moduleName in PS.moduleNames do
      PS:LoadModule(moduleName)
    end

    for _, moduleName in PS.moduleNames do
      if PS[moduleName] and PS[moduleName].init then
        PS[moduleName].init()
      end
    end
  end

  if event == 'CHAT_MSG_CHANNEL' and arg2 ~= UnitName('player') then
    local _, _, source = string.find(arg4, '(%d+)%.')
    local channelName

    if source then
      _, channelName = GetChannelName(source)
    end

    if channelName == PS.channelName and string.sub(arg1, 1, 11) == PS:GetName() then
      local remoteVersion = tonumber(string.sub(arg1, 13, 17))
      if remoteVersion > PS.utils.getVersionNumber() and not PS.updateNotified then
        PS:Print('New version available! https://github.com/Pizzahawaiii/PizzaSlices')
        PS.updateNotified = true
      end
    end
  end
end)

PS:SetScript('OnUpdate', function ()
  if PS.clearRaidTargetAt and GetTime() > PS.clearRaidTargetAt then
    SetRaidTarget('player', 0)
    PS.clearRaidTargetAt = nil
  end
end)
