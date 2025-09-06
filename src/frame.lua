PizzaSlices:RegisterModule('frame', function ()
  PS.frame = CreateFrame('Frame', 'PizzaSlicesFrame', UIParent)

  local f = PS.frame
  f.targetAngle = nil
  f.pointerAngle = nil
  f:SetPoint('CENTER', 0, 100)
  f:SetFrameStrata('FULLSCREEN')
  f:SetWidth(1)
  f:SetHeight(1)
  f:Hide()

  f.circle = CreateFrame('Frame', 'PizzaSlicesCircle', f)
  f.circle:SetPoint('CENTER', 0, 0)
  f.circle.tex = f.circle:CreateTexture('PizzaSlicesCircleTex', 'ARTWORK')
  f.circle.tex:SetAllPoints(f.circle)
  f.circle.tex:SetTexture('Interface\\AddOns\\PizzaSlices\\img\\circle')

  f.circle.glow = CreateFrame('Frame', 'PizzaSlicesCircleGlow', f.circle)
  f.circle.glow:SetPoint('CENTER', 0, 0)
  f.circle.glow.tex = f.circle.glow:CreateTexture('PizzaSlicesCircleGlowTex', 'BACKGROUND')
  f.circle.glow.tex:SetAllPoints(f.circle.glow)
  f.circle.glow.tex:SetTexture('Interface\\AddOns\\PizzaSlices\\img\\glow')

  f.pointer = CreateFrame('Frame', 'PizzaSlicesPointer', f)
  f.pointer:SetPoint('CENTER', 0, 0)
  f.pointer.tex = f.pointer:CreateTexture('PizzaSlicesPointerTex', 'ARTWORK')
  f.pointer.tex:SetAllPoints(f.pointer)
  f.pointer.tex:SetTexture('Interface\\AddOns\\PizzaSlices\\img\\pointer')

  function PS.frame.open(ring)
    PS.ring = ring

    for idx, frame in PS.frames do
      frame:Hide()
    end

    local cx, cy = 0, 0
    local scale = UIParent:GetEffectiveScale()

    if C.openAtCursor then
      local w = GetScreenWidth() * scale
      local h = GetScreenHeight() * scale
      local cursx, cursy = GetCursorPosition()
      cx = (cursx - w / 2)
      cy = (cursy - h / 2)
    end

    PS.frame:ClearAllPoints()
    PS.frame:SetPoint('CENTER', cx / scale, cy / scale)
    PS.frame:SetAlpha(0)
    PS.frame.circle:SetWidth(120 * sqrt(C.scale))
    PS.frame.circle:SetHeight(120 * sqrt(C.scale))
    PS.frame.circle:SetAlpha(0)
    PS.frame.circle.glow:SetWidth(240 * sqrt(C.scale))
    PS.frame.circle.glow:SetHeight(240 * sqrt(C.scale))
    PS.frame.circle.glow:SetAlpha(0)
    PS.frame.pointer:SetWidth(400 * sqrt(C.scale))
    PS.frame.pointer:SetHeight(400 * sqrt(C.scale))
    PS.frame.pointer:SetAlpha(0)

    local radius = 300 * sqrt(C.scale)
    local angle = 90 -- 90 degress is 12 o'clock here
    for idx, slice in ring.slices do
      local x, y, nextAngle = PS.utils.getSliceCoords(idx, PS.utils.length(ring.slices), angle, radius)
      local fname = 'PizzaSlicesButton' .. idx
      local f = _G[fname]
      if not f then
        f = CreateFrame('Button', 'PizzaSlicesButton' .. idx, PS.frame)
        table.insert(PS.frames, f)
      end
      f:ClearAllPoints()
      f:SetPoint('CENTER', x, y)
      f:SetWidth(80 * sqrt(C.scale))
      f:SetHeight(80 * sqrt(C.scale))
      f:SetAlpha(0)
      f:Show()

      if not f.cd then
        f.cd = CreateFrame('Model', f:GetName() .. 'Cooldown', f, 'CooldownFrameTemplate')
        f.cd.noCooldownCount = true
      end

      if not f.cdtextFrame then
        f.cdtextFrame = CreateFrame('Frame', f:GetName() .. 'CooldownTextFrame', f)
        f.cdtextFrame:SetAllPoints(f)
        f.cdtextFrame:SetFrameLevel(f.cd:GetFrameLevel() + 1)
      end

      if not f.cdtext then
        f.cdtext = f.cdtextFrame:CreateFontString(f:GetName() .. 'CooldownText', 'OVERLAY', 'GameFontWhite')
        f.cdtext:SetPoint('CENTER', 0, 0)
        f.cdtext:SetFont(STANDARD_TEXT_FONT, 16, 'OUTLINE')
        f.cdtext:SetTextColor(1, 1, 1, 1)
        f.cdtext:Hide()
      end

      if string.sub(slice.action, 1, 6) == 'macro:' and C.showMacroNames then
        local macroName = string.gsub(slice.name, 'Macro: ', '')
        if not f.text then
          f.text = f:CreateFontString(f:GetName() .. 'Text', 'OVERLAY', 'GameFontWhite')
          f.text:SetPoint('TOP', f, 'BOTTOM', 0, -5)
          f.text:SetFont(STANDARD_TEXT_FONT, 14, 'OUTLINE')
          f.text:SetTextColor(1, 1, 1, 1)
        end
        f.text:SetText(macroName)
        f.text:Show()
      elseif f.text then
        f.text:Hide()
      end

      if slice.spellId or slice.itemId then
        local start, duration, enable

        if slice.spellId then
          local _, spellSlot = PS.utils.hasSpell(slice.name)
          if spellSlot then
            start, duration, enable = GetSpellCooldown(spellSlot, 'BOOKTYPE_SPELL')
          end
        else
          local bag, slot = PS.utils.findItem(slice.name)
          if bag and slot then
            start, duration, enable = GetContainerItemCooldown(bag, slot)
          end
        end

        if start and duration and duration > 0 then
          f.cd:Show()
          CooldownFrame_SetTimer(f.cd, start, duration, enable)
          f.cdtext:Show()
          f.cdtext.startTime = start
          f.cdtext.duration = duration
        else
          f.cd:Hide()
          f.cdtext:Hide()
        end
      else
        f.cd:Hide()
        f.cdtext:Hide()
      end

      f.radius = radius
      f.startAngle = angle
      f.angle = angle

      angle = nextAngle

      if not f.tex then
        f.tex = f:CreateTexture(f:GetName() .. 'Tex', 'ARTWORK')
      end
      f.tex:SetAllPoints(f)
      f.tex:SetTexture(ring.slices[idx].tex)
      f.tex:SetAlpha(0)

      if not f.borderlow then
        f.borderlow = f:CreateTexture(f:GetName() .. 'BorderLow', 'OVERLAY')
      end
      f.borderlow:SetAllPoints(f)
      f.borderlow:SetTexture('Interface\\AddOns\\PizzaSlices\\img\\borderlo')
      f.borderlow:SetAlpha(0)
      if C.blackBorders then
        f.borderlow:SetVertexColor(0, 0, 0, 1)
      else
        f.borderlow:SetVertexColor(slice.color.r, slice.color.g, slice.color.b, 1)
      end

      if not f.borderhigh then
        f.borderhigh = f:CreateTexture(f:GetName() .. 'BorderHigh', 'OVERLAY')
      end
      f.borderhigh:SetAllPoints(f)
      f.borderhigh:SetTexture('Interface\\AddOns\\PizzaSlices\\img\\borderhi')
      f.borderhigh:SetAlpha(0)
      if C.blackBorders then
        f.borderhigh:SetVertexColor(0, 0, 0, 1)
      else
        f.borderhigh:SetVertexColor(slice.color.r, slice.color.g, slice.color.b, 1)
      end

      if not f.oglow then
        f.oglow = f:CreateTexture(f:GetName() .. 'OuterGlow', 'BACKGROUND')
      end
      f.oglow:SetPoint('CENTER', 0, 0)
      f.oglow:SetWidth(f:GetWidth() * 2)
      f.oglow:SetHeight(f:GetHeight() * 2)
      f.oglow:SetTexture('Interface\\AddOns\\PizzaSlices\\img\\oglow')
      f.oglow:SetAlpha(0)
      -- f.oglow:SetVertexColor(slice.color.r, slice.color.g, slice.color.b, 1)

      if not f.iglow then
        f.iglow = f:CreateTexture(f:GetName() .. 'InnerGlow', 'OVERLAY')
      end
      f.iglow:SetPoint('CENTER', 0, 0)
      f.iglow:SetWidth(f:GetWidth())
      f.iglow:SetHeight(f:GetHeight())
      f.iglow:SetTexture('Interface\\AddOns\\PizzaSlices\\img\\iglow')
      f.iglow:SetAlpha(0)
      if C.blackBorders then
        f.iglow:SetVertexColor(1, 1, 1, 1)
      else
        f.iglow:SetVertexColor(slice.color.r, slice.color.g, slice.color.b, 1)
      end

      if string.sub(slice.action, 1, 5) == 'item:' then
        if not f.itemCount then
          f.itemCount = f:CreateFontString(f:GetName() .. 'Count', 'DIALOG', 'GameFontWhite')
          f.itemCount:SetFont(STANDARD_TEXT_FONT, 12, 'OUTLINE')
          f.itemCount:SetJustifyH('RIGHT')
          f.itemCount:SetJustifyV('BOTTOM')
          f.itemCount:SetPoint('TOPLEFT', 5, -5)
          f.itemCount:SetPoint('BOTTOMRIGHT', -5, 5)
        end
        local count = PS.utils.getItemCount(slice.name)
        if count then
          SetItemButtonCount(f, count)
        end
      elseif f.itemCount then
        f.itemCount:Hide()
      end

      ring.slices[idx].frame = f
      ring.slices[idx].selected = false
    end

    PS:SelectSlice(PS.ring.quickSelect)

    PS.frame:SetAlpha(0)
    PS.frame:Show()
  end

  local function getCircleCenterCoords()
    local point, relativeTo, relativePoint, xOfs, yOfs = PS.frame:GetPoint(1)
    local scale = UIParent:GetEffectiveScale()
    local w = PS.utils.round(GetScreenWidth() * scale)
    local h = PS.utils.round(GetScreenHeight() * scale)

    local x = PS.utils.round(w / 2 + xOfs * scale)
    local y = PS.utils.round(h / 2 + yOfs * scale)

    return x, y
  end

  local function calculateAngle(x1, y1, x2, y2)
    local x = x1 - x2
    local y = y1 - y2

    local radAngle = (math.atan2(y, x) - math.atan2(1, 0)) * -1
    local angle = radAngle * 180 / math.pi

    return PS.utils.mod(angle, 360), PS.utils.distance(x1, y1, x2, y2)
  end

  local pcursx = nil
  local pcursy = nil
  local function updateTargetAngle(controller)
    if controller then
      -- On controller, use mouse move delta to calculate the target angle.
      local cursx, cursy = GetCursorPosition()
      if pcursx and pcursy then
        local distance = PS.utils.distance(cursx, cursy, pcursx, pcursy)
        if distance > 3 then
          PS.frame.targetAngle = calculateAngle(cursx, cursy, pcursx, pcursy)
        end
      end
      pcursx = cursx
      pcursy = cursy
    else
      -- On mouse, simply use the current mouse cursor position
      local cursx, cursy = GetCursorPosition()
      local circx, circy = getCircleCenterCoords()
      local angle, radius = calculateAngle(cursx, cursy, circx, circy)
      if radius > (12 * sqrt(C.scale)) then
        PS.frame.targetAngle = angle
      end
    end
  end

  local function normalize(angle, max)
    if angle > max then
      return PS.utils.mod(angle, max) - max
    end

    if angle < -max then
      return PS.utils.mod(angle, -max) + max
    end

    return angle
  end

  local function rotatePointer()
    updateTargetAngle()

    if not PS.frame.targetAngle then 
      if not PS.frame.pointerAngle then
        PS.frame.pointer:Hide()
      end
      return
    end

    if not PS.frame.pointerAngle then
      PS.frame.pointerAngle = PS.frame.targetAngle
    end

    PS.frame.pointer:Show()

    if PS.frame.pointerAngle ~= PS.frame.targetAngle then
      local angleDiff = normalize(PS.frame.pointerAngle - PS.frame.targetAngle, 180)
      local sign = angleDiff < 0 and -1 or 1

      local rate
      if math.abs(angleDiff) > 60 then
        rate = 20
      elseif math.abs(angleDiff) > 15 then
        rate = 10
      else
        rate = 5
      end

      PS.frame.pointerAngle = PS.frame.pointerAngle - math.min(math.abs(angleDiff), rate) * sign
      if PS.frame.pointerAngle < 0 then
        PS.frame.pointerAngle = 360 + PS.utils.mod(PS.frame.pointerAngle, -360)
      end
      if PS.frame.pointerAngle > 360 then
        PS.frame.pointerAngle = PS.utils.mod(PS.frame.pointerAngle, 360)
      end
    end

    PS.utils.rotateTexture(PS.frame.pointer.tex, PS.frame.pointerAngle)
  end

  local function getStep(current, target, fixedDuration, speedScale)
    local diff = math.abs(target - current)
    if diff < .02 then return diff end
    local factor = PS.open and 1 or .5
    local duration = fixedDuration and 1 or C.animation.duration
    local step = diff / (PS.fps * duration / 15) * factor * (speedScale or 1)
    return step > .001 and step
  end

  function getNext(current, target, fixedDuration, speedScale)
    if current == target then return end

    local step = getStep(current, target, fixedDuration, speedScale)
    if not step then return target end

    local diff = target - current
    local nextStep = current < target and math.min(diff, step) or math.max(diff, -step)
    return current + nextStep
  end

  local circleAngle = 0
  function animateCircle()
    -- Constantly rotate circle + glow
    circleAngle = circleAngle + 1.5
    PS.utils.rotateTexture(PS.frame.circle.tex, circleAngle)
    PS.utils.rotateTexture(PS.frame.circle.glow.tex, circleAngle)

    -- Rotate pointer towards target angle if needed
    rotatePointer()

    local nextSize = getNext(PS.frame.circle:GetWidth(), (PS.open and 60 or 120) * sqrt(C.scale))
    if nextSize then
      PS.frame.circle:SetWidth(nextSize)
      PS.frame.circle:SetHeight(nextSize)
    end

    nextSize = getNext(PS.frame.circle.glow:GetWidth(), (PS.open and 120 or 240) * sqrt(C.scale))
    if nextSize then
      PS.frame.circle.glow:SetWidth(nextSize)
      PS.frame.circle.glow:SetHeight(nextSize)
    end

    nextSize = getNext(PS.frame.pointer:GetWidth(), (PS.open and 200 or 400) * sqrt(C.scale))
    if nextSize then
      PS.frame.pointer:SetWidth(nextSize)
      PS.frame.pointer:SetHeight(nextSize)
    end

    local nextAlpha = getNext(PS.frame.circle:GetAlpha(), PS.open and 1 or 0, false, 2)
    if nextAlpha then
      PS.frame.circle:SetAlpha(nextAlpha)
      PS.frame.circle.tex:SetAlpha(nextAlpha)
    end
  end

  function animate()
    animateCircle()

    local nextAlpha = getNext(PS.frame:GetAlpha(), PS.open and 1 or 0, false, .9)
    if nextAlpha then
      PS.frame:SetAlpha(nextAlpha)
    elseif not PS.open then
      PS.frame:Hide()
      return
    end

    -- Animate slice icons
    for idx, slice in PS.ring.slices do
      local targetSize = PS.open and 40 or 80
      local nextSize = getNext(slice.frame:GetWidth(), targetSize * sqrt(C.scale))
      if nextSize then
        slice.frame:SetWidth(nextSize)
        slice.frame:SetHeight(nextSize)
        slice.frame.oglow:SetWidth(nextSize * 2)
        slice.frame.oglow:SetHeight(nextSize * 2)
        slice.frame.iglow:SetWidth(nextSize * 64 / 60)
        slice.frame.iglow:SetHeight(nextSize * 64 / 60)
      end

      local targetAlpha = PS.open and 1 or 0
      local nextAlpha = getNext(slice.frame:GetAlpha(), targetAlpha)
      if nextAlpha then slice.frame:SetAlpha(nextAlpha) end
      if nextAlpha then slice.frame.tex:SetAlpha(nextAlpha) end
      if not nextAlpha and slice.frame.tex:GetAlpha() ~= targetAlpha then
        slice.frame.tex:SetAlpha(targetAlpha)
      end

      if slice.frame.text then
        if nextAlpha then
          slice.frame.text:SetAlpha(nextAlpha)
        elseif slice.frame.text:GetAlpha() ~= targetAlpha then
          slice.frame.tex:SetAlpha(targetAlpha)
        end
      end

      local nextBorderAlpha = slice.noBorder and 0 or nextAlpha
      if nextBorderAlpha then slice.frame.borderlow:SetAlpha(nextBorderAlpha) end
      if nextBorderAlpha then slice.frame.borderhigh:SetAlpha(nextBorderAlpha) end

      local nextOGlowAlpha = getNext(slice.frame.oglow:GetAlpha(), PS.open and slice.selected and 1 or 0)
      if nextOGlowAlpha then slice.frame.oglow:SetAlpha(nextOGlowAlpha) end

      local nextIGlowAlpha = getNext(slice.frame.iglow:GetAlpha(), PS.open and slice.selected and 1 or 0)
      if slice.noBorder then nextIGlowAlpha = 0 end
      if nextIGlowAlpha then slice.frame.iglow:SetAlpha(nextIGlowAlpha) end

      local sliceCount = PS.utils.length(PS.ring.slices)
      local targetRadius = slice.selected and 120 or 110
      if not PS.open then targetRadius = 250 end
      local nextRadius = getNext(slice.frame.radius, targetRadius * sqrt(C.scale), slice.selected)
      if nextRadius then
        local x, y = PS.utils.getSliceCoords(idx, sliceCount, slice.frame.angle, nextRadius)
        slice.frame:ClearAllPoints()
        slice.frame:SetPoint('CENTER', x, y)
        slice.frame.radius = nextRadius
      end

      if not PS.open and sliceCount > 1 then
        local nextAngle = getNext(slice.frame.angle, slice.frame.startAngle - 70 * C.animation.rotateOnClose)
        if nextAngle then
          local x, y = PS.utils.getSliceCoords(idx, sliceCount, nextAngle, nextRadius or slice.frame.radius)
          slice.frame:ClearAllPoints()
          slice.frame:SetPoint('CENTER', x, y)
          slice.frame.angle = nextAngle
        end
      end
    end

    -- Fade stuff if needed
    local circx, circy = getCircleCenterCoords()
    local cursx, cursy = GetCursorPosition()
    if PS.utils.distance(circx, circy, cursx, cursy) < 21 * sqrt(C.scale) then
      PS:SelectSlice(PS.ring.quickSelect)

      if C.blackBorders then
        PS.frame.circle.tex:SetVertexColor(0, 0, 0)
        PS.frame.circle.glow.tex:SetVertexColor(1, 1, 1)
        PS.frame.pointer.tex:SetVertexColor(.8, .8, .8)
      else
        local r, g, b = .8, .8, .8
        if PS.ring.quickSelect then
          r = PS.ring.slices[PS.ring.quickSelect].color.r
          g = PS.ring.slices[PS.ring.quickSelect].color.g
          b = PS.ring.slices[PS.ring.quickSelect].color.b
        end
        PS.frame.circle.tex:SetVertexColor(r, g, b)
        PS.frame.circle.glow.tex:SetVertexColor(r, g, b)
        PS.frame.pointer.tex:SetVertexColor(r, g, b)
      end

      local glowAlpha = PS.frame.circle.glow.tex:GetAlpha()
      if glowAlpha > 0 then
        PS.frame.circle.glow.tex:SetAlpha(math.max(glowAlpha - .05, 0))
      end

      local pointerAlpha = PS.frame.pointer.tex:GetAlpha()
      if pointerAlpha > 0 then
        PS.frame.pointer.tex:SetAlpha(math.max(pointerAlpha - .05, 0))
      end
    else
      -- Update selected slice
      local selectedIdx
      if PS.frame.pointerAngle then
        local sliceAngle = 360 / PS.utils.length(PS.ring.slices)
        selectedIdx = PS.utils.mod(math.ceil((PS.frame.pointerAngle - sliceAngle / 2) / sliceAngle), PS.utils.length(PS.ring.slices)) + 1
        PS:SelectSlice(selectedIdx)
      end

      if C.blackBorders then
        PS.frame.circle.tex:SetVertexColor(0, 0, 0)
        PS.frame.circle.glow.tex:SetVertexColor(1, 1, 1)
        PS.frame.pointer.tex:SetVertexColor(.8, .8, .8)
      else
        local r, g, b = 1, 1, 1
        if selectedIdx then
          local color = PS.ring.slices[selectedIdx].color
          r, g, b = color.r, color.g, color.b
        end
        PS.frame.circle.tex:SetVertexColor(r, g, b)
        PS.frame.circle.glow.tex:SetVertexColor(r, g, b)
        PS.frame.pointer.tex:SetVertexColor(r, g, b)
      end

      local glowAlpha = PS.frame.circle.glow.tex:GetAlpha()
      if glowAlpha < 1 then
        PS.frame.circle.glow.tex:SetAlpha(math.min(glowAlpha + .05, 1))
      end

      local pointerAlpha = PS.frame.pointer.tex:GetAlpha()
      if pointerAlpha < 1 then
        PS.frame.pointer.tex:SetAlpha(math.min(pointerAlpha + .05, 1))
      end
    end
  end

  PS.frame:SetScript('OnUpdate', function ()
    if not PS.ring then return end

    local now = GetTime()
    if (this.tick or 1/PS.fps) > now then return else this.tick = now + 1/PS.fps end

    animate()

    for _, slice in ipairs(PS.ring.slices) do
      local f = slice.frame
      if f and f.cdtext and f.cdtext:IsShown() then
        local now = GetTime()
        local remaining = (f.cdtext.startTime + f.cdtext.duration) - now
        if remaining <= 0 then
          f.cdtext:Hide()
        else
          if remaining < 3 then
            f.cdtext:SetText(string.format('%.1f', remaining))
            f.cdtext:SetTextColor(1, 0, 0, 1)
          else
            f.cdtext:SetText(PS.utils.toRoughTimeString(math.ceil(remaining)))
            f.cdtext:SetTextColor(1, 1, 1, 1)
          end
        end
      end
    end
  end)
end)
