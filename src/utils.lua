PizzaSlices:RegisterModule('utils', function ()
  PS.utils = {}

  -- TODO: Move math utils to separate math module?
  function PS.utils.mod(x, y)
    return x - math.floor(x / y) * y
  end

  function PS.utils.round(n)
    return math.floor(n + .5)
  end

  function PS.utils.pow(x)
    return x * x
  end

  function PS.utils.distance(x1, y1, x2, y2)
    return sqrt(PS.utils.pow(x1 - x2) + PS.utils.pow(y1 - y2))
  end

  function PS.utils.length(t)
    local count = 0
    for _ in pairs(t) do count = count + 1 end
    return count
  end

  function PS.utils.toRoughTimeString(seconds)
    if seconds < 60 then return seconds .. '' end

    local minutes = seconds / 60
    if minutes < 60 then return math.floor(minutes) .. 'm' end

    local hours = minutes / 60
    if hours < 24 then return '~ ' .. math.floor(hours) .. 'h' end

    local days = hours / 24
    return '~ ' .. math.floor(days + 0.5) .. 'd'
  end

  function PS.utils.strSplit(str, delimiter, asTable)
    if not str then return nil end
    local delimiter, fields = delimiter or ':', {}
    local pattern = string.format('([^%s]+)', delimiter)
    string.gsub(str, pattern, function(c) fields[table.getn(fields)+1] = c end)
    if asTable then return fields end
    return unpack(fields)
  end

  function PS.utils.capitalize(str)
    return string.upper(string.sub(str, 1, 1)) .. string.sub(str, 2, -1)
  end

  function PS.utils.clone(tbl)
    local clone = {}
    for k, v in pairs(tbl) do
      clone[k] = type(v) == 'table' and PS.utils.clone(v) or v
    end
    return clone
  end

  function PS.utils.getSliceCoords(idx, count, angle, radius)
    local angleRad = angle * math.pi / 180
    local x = radius * math.cos(angleRad)
    local y = radius * math.sin(angleRad)
    local nextAngle = angle - 360 / count
    return x, y, nextAngle
  end

  local function calculateCorner(angle)
    local r = rad(angle)
    return .5 + math.cos(r) / sqrt(2), .5 + math.sin(r) / sqrt(2)
  end

  function PS.utils.rotateTexture(texture, angle)
    local a = angle * -1
    local LRx, LRy = calculateCorner(a + 45)
    local LLx, LLy = calculateCorner(a + 135)
    local ULx, ULy = calculateCorner(a + 225)
    local URx, URy = calculateCorner(a - 45)

    texture:SetTexCoord(ULx, ULy, LLx, LLy, URx, URy, LRx, LRy)
  end

  local function hue2rgb(p, q, t)
    if t < 0 then t = t + 1 end
    if t > 1 then t = t - 1 end
    if t < 1/6 then return p + (q - p) * 6 * t end
    if t < 1/2 then return q end
    if t < 2/3 then return p + (q - p) * (2/3 - t) * 6 end
    return p
  end

  local function hsl2rgb(h, s, l)
    local r, g, b

    if s == 0 then
      r = g 
      g = b
      b = l
    else
      local q = l < .5 and l * (1 + s) or l + s - l * s
      local p = 2 * l - q
      r = hue2rgb(p, q, h + 1/3)
      g = hue2rgb(p, q, h)
      b = hue2rgb(p, q, h - 1/3)
    end

    return r, g, b
  end

  function PS.utils.getRandomColor()
    local h, s, l = math.random(0, 360) / 360, math.random(42, 98) / 100, math.random(40, 90) / 100
    local r, g, b = hsl2rgb(h, s, l)
    return { r = r, g = g, b = b }
  end

  function PS.utils.hasPfUI()
    return IsAddOnLoaded('pfUI') and pfUI and pfUI.uf and pfUI.env and pfUI.env.C
  end

  function PS.utils.getButtonForSlot(slot)
    if PS.utils.hasPfUI() and pfUI_config and pfUI_config.disabled.actionbar ~= '1' then
      if slot >= 1 and slot <= 12 then
        return _G['pfActionBarMainButton' .. slot]
      elseif slot >= 13 and slot <= 24 then
        return _G['pfActionBarPagingButton' .. (slot - 12)]
      elseif slot >= 25 and slot <= 36 then
        return _G['pfActionBarRightButton' .. (slot - 24)]
      elseif slot >= 37 and slot <= 48 then
        return _G['pfActionBarVerticalButton' .. (slot - 36)]
      elseif slot >= 49 and slot <= 60 then
        return _G['pfActionBarLeftButton' .. (slot - 48)]
      elseif slot >= 61 and slot <= 72 then
        return _G['pfActionBarTopButton' .. (slot - 60)]
      elseif slot >= 73 and slot <= 84 then
        return _G['pfActionBarStanceBar1Button' .. (slot - 72)]
      elseif slot >= 85 and slot <= 96 then
        return _G['pfActionBarStanceBar2Button' .. (slot - 84)]
      elseif slot >= 97 and slot <= 108 then
        return _G['pfActionBarStanceBar3Button' .. (slot - 96)]
      elseif slot >= 109 and slot <= 120 then
        return _G['pfActionBarStanceBar4Button' .. (slot - 108)]
      end
    else
      if slot >= 25 and slot <= 36 then
        return _G['MultiBarRightButton' .. (slot - 24)]
      elseif slot >= 37 and slot <= 48 then
        return _G['MultiBarLeftButton' .. (slot - 36)]
      elseif slot >= 49 and slot <= 60 then
        return _G['MultiBarBottomRightButton' .. (slot - 48)]
      elseif slot >= 61 and slot <= 72 then
        return _G['MultiBarBottomLeftButton' .. (slot - 60)]
      elseif slot >= 73 and slot <= 84 then
        return _G['ActionButton' .. (slot - 72)]
      end
      return nil
    end
  end

  local patterns = {
    -- Default buttons
    { '^ActionButton(%d+)',              'ACTIONBUTTON' },
    { '^MultiBarBottomLeftButton(%d+)',  'MULTIACTIONBAR1BUTTON' },
    { '^MultiBarBottomRightButton(%d+)', 'MULTIACTIONBAR2BUTTON' },
    { '^MultiBarRightButton(%d+)',       'MULTIACTIONBAR3BUTTON' },
    { '^MultiBarLeftButton(%d+)',        'MULTIACTIONBAR4BUTTON' },

    -- pfUI buttons
    { '^pfActionBarMainButton(%d+)',       'ACTIONBUTTON' },
    { '^pfActionBarTopButton(%d+)',        'MULTIACTIONBAR1BUTTON' },
    { '^pfActionBarLeftButton(%d+)',       'MULTIACTIONBAR2BUTTON' },
    { '^pfActionBarRightButton(%d+)',      'MULTIACTIONBAR3BUTTON' },
    { '^pfActionBarVerticalButton(%d+)',   'MULTIACTIONBAR4BUTTON' },
    { '^pfActionBarPagingButton(%d+)',     'PGPAGING' },
    { '^pfActionBarStanceBar1Button(%d+)', 'PFSTANCEONE' },
    { '^pfActionBarStanceBar2Button(%d+)', 'PFSTANCETWO' },
    { '^pfActionBarStanceBar3Button(%d+)', 'PFSTANCETHREE' },
    { '^pfActionBarStanceBar4Button(%d+)', 'PFSTANCEFOUR' },
  }
  function PS.utils.getButtonBinding(button)
    local name = button:GetName()
    for _, pattern in ipairs(patterns) do
      local _, _, idx = string.find(name, pattern[1])
      if idx then
        local binding = pattern[2] .. idx
        local keys = { GetBindingKey(binding) }
        return keys
      end
    end
  end

  function PS.utils.findItem(name)
    for bag = 0, 4 do
      for slot = 1, GetContainerNumSlots(bag) do
        local link = GetContainerItemLink(bag, slot)
        if link then
          local _, _, id = string.find(link, '(%d+):')
          local itemName = GetItemInfo(id)
          if itemName and itemName ~= '' and string.lower(itemName) == string.lower(name) then
            return bag, slot
          end
        end
      end
    end
  end

  function PS.utils.getItemCount(name)
    local count = 0
    for bag = 0, 4 do
      for slot = 1, GetContainerNumSlots(bag) do
        local link = GetContainerItemLink(bag, slot)
        if link then
          local _, _, id = string.find(link, '(%d+):')
          local itemName = GetItemInfo(id)
          if itemName and itemName ~= '' and string.lower(itemName) == string.lower(name) then
            local _, c = GetContainerItemInfo(bag, slot)
            count = count + c
          end
        end
      end
    end
    return count
  end

  function PS.utils.hasSpell(name, rank)
    for i = 1, GetNumSpellTabs() do
      local _, _, offset, spellCount = GetSpellTabInfo(i)
      for spellSlot = offset + spellCount, offset + 1, -1 do
        local spellName, spellRank = GetSpellName(spellSlot, 'spell')
        if spellName == name then
          if not rank then return true, spellSlot end
          if spellRank == rank then return true, spellSlot end
        end
      end
    end

    return false
  end

  function PS.utils.isActiveSpell(name, rank)
    if string.find(rank, 'Passive') then return false end
    if name == 'Hardcore' then return false end
    return true
  end

  function PS.utils.getVersion()
    return tostring(GetAddOnMetadata(PS:GetName(), 'Version'))
  end

  function PS.utils.getVersionNumber()
    local major, minor, patch = PS.utils.strSplit(PS.utils.getVersion(), '.')
    major = tonumber(major) or 0
    minor = tonumber(minor) or 0
    patch = tonumber(patch) or 0
    return major * 10000 + minor * 100 + patch
  end

  function PS.utils.hasSuperWoW()
    return SetAutoloot ~= nil
  end
end)
