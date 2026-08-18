local ADDON, ns = ...
local C = ns.COLORS

local BASE_ACCENT = { C.accent[1], C.accent[2], C.accent[3], C.accent[4] }
local BASE_BORDER = { C.border[1], C.border[2], C.border[3], C.border[4] }
local BASE_TEAL = { C.teal[1], C.teal[2], C.teal[3], C.teal[4] }
local CINEMATIC_ACCENT = C.cinematic or { 0.90, 0.52, 0.24, 1 }
local CINEMATIC_BORDER = { 0.52, 0.29, 0.13, 0.88 }
local CINEMATIC_BUTTON = { 0.14, 0.085, 0.045, 1 }
local NORMAL_HEADER = { 0.085, 0.055, 0.14, 1 }
local themeObjects = setmetatable({}, { __mode = "k" })

local function TrackTheme(object, role)
    if not object then return end
    local roles = themeObjects[object] or {}
    roles[role] = true
    themeObjects[object] = roles
end

local function SetTealTexture(texture)
    TrackTheme(texture, "tealTexture")
    texture:SetColorTexture(unpack(C.teal))
end

local function Backdrop(frame, color, border)
    local actualColor, actualBorder = color or C.card, border or C.border
    if actualColor == C.accent then TrackTheme(frame, "background") end
    if actualColor == C.teal then TrackTheme(frame, "tealBackground") end
    if actualBorder == C.accent then TrackTheme(frame, "accentBorder") end
    if actualBorder == C.teal then TrackTheme(frame, "tealBorder") end
    if actualBorder == C.border then TrackTheme(frame, "border") end
    frame:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
    frame:SetBackdropColor(unpack(actualColor))
    frame:SetBackdropBorderColor(unpack(actualBorder))
end

-- Resonance-style scrollbars: a quiet inset rail with a slim, draggable
-- lavender thumb. The stock template's oversized arrows are hidden, and the
-- replacement lives in the gutter already reserved inside each card so it
-- never paints across the card border.
local function SkinScrollFrame(scroll)
    if not scroll or scroll._frameGambitScrollBar then return end

    local stock = scroll.ScrollBar or scroll.scrollBar
    if not stock and scroll.GetName and scroll:GetName() then
        stock = _G[scroll:GetName() .. "ScrollBar"]
    end
    if stock then
        stock:SetAlpha(0)
        stock:EnableMouse(false)
        stock:Hide()
    end

    scroll:EnableMouseWheel(true)
    if scroll.SetClipsChildren then scroll:SetClipsChildren(true) end

    local track = CreateFrame("Button", nil, scroll:GetParent(), "BackdropTemplate")
    track:SetPoint("TOPLEFT", scroll, "TOPRIGHT", 4, 0)
    track:SetPoint("BOTTOMLEFT", scroll, "BOTTOMRIGHT", 4, 0)
    track:SetWidth(12)
    track:SetFrameLevel(scroll:GetFrameLevel() + 8)
    track:EnableMouse(true)
    Backdrop(track, { 0.025, 0.03, 0.05, 0.78 }, { 0.20, 0.15, 0.34, 0.65 })

    local rail = track:CreateTexture(nil, "BACKGROUND")
    rail:SetTexture("Interface\\Buttons\\WHITE8X8")
    rail:SetVertexColor(C.border[1], C.border[2], C.border[3], 0.44)
    rail:SetPoint("TOP", 0, -3)
    rail:SetPoint("BOTTOM", 0, 3)
    rail:SetWidth(2)

    local thumb = CreateFrame("Button", nil, track, "BackdropTemplate")
    thumb:SetSize(6, 34)
    thumb:SetPoint("TOP", track, "TOP", 0, -2)
    thumb:SetFrameLevel(track:GetFrameLevel() + 1)
    thumb:EnableMouse(true)
    thumb:RegisterForDrag("LeftButton")
    Backdrop(thumb, { C.accent[1], C.accent[2], C.accent[3], 0.88 }, C.accent)

    local dragging, dragStartY, dragStartScroll
    local function Range()
        return math.max(0, tonumber(scroll:GetVerticalScrollRange()) or 0)
    end
    local function UpdateThumb()
        local maxScroll = Range()
        local trackHeight = math.max(1, track:GetHeight() - 4)
        if maxScroll <= 0 or trackHeight <= 1 then
            track:Hide()
            return
        end
        track:Show()
        local visibleHeight = math.max(1, scroll:GetHeight())
        local thumbHeight = math.min(trackHeight, math.max(28, trackHeight * visibleHeight / (visibleHeight + maxScroll)))
        local travel = math.max(0, trackHeight - thumbHeight)
        local ratio = math.max(0, math.min(1, (tonumber(scroll:GetVerticalScroll()) or 0) / maxScroll))
        thumb:SetHeight(thumbHeight)
        thumb:ClearAllPoints()
        thumb:SetPoint("TOP", track, "TOP", 0, -2 - ratio * travel)
    end
    local function StopDrag()
        if not dragging then return end
        dragging = false
        thumb:SetScript("OnUpdate", nil)
        thumb:SetBackdropColor(C.accent[1], C.accent[2], C.accent[3], 0.88)
        thumb:SetBackdropBorderColor(unpack(C.accent))
    end
    local function BeginDrag()
        local _, cursorY = GetCursorPosition()
        local scale = math.max(0.001, scroll:GetEffectiveScale())
        dragging = true
        dragStartY = cursorY / scale
        dragStartScroll = tonumber(scroll:GetVerticalScroll()) or 0
        thumb:SetBackdropColor(unpack(C.teal))
        thumb:SetBackdropBorderColor(unpack(C.teal))
        thumb:SetScript("OnUpdate", function()
            if not IsMouseButtonDown("LeftButton") then StopDrag(); return end
            local _, currentY = GetCursorPosition()
            local travel = math.max(1, track:GetHeight() - 4 - thumb:GetHeight())
            local delta = dragStartY - currentY / math.max(0.001, scroll:GetEffectiveScale())
            scroll:SetVerticalScroll(math.max(0, math.min(Range(), dragStartScroll + delta / travel * Range())))
            UpdateThumb()
        end)
    end

    thumb:SetScript("OnEnter", function(self)
        if not dragging then
            self:SetBackdropColor(C.teal[1], C.teal[2], C.teal[3], 0.88)
            self:SetBackdropBorderColor(unpack(C.teal))
        end
    end)
    thumb:SetScript("OnLeave", function(self)
        if not dragging then
            self:SetBackdropColor(C.accent[1], C.accent[2], C.accent[3], 0.88)
            self:SetBackdropBorderColor(unpack(C.accent))
        end
    end)
    thumb:SetScript("OnDragStart", BeginDrag)
    thumb:SetScript("OnDragStop", StopDrag)
    thumb:SetScript("OnMouseDown", function(_, button) if button == "LeftButton" then BeginDrag() end end)
    thumb:SetScript("OnMouseUp", StopDrag)

    track:SetScript("OnMouseDown", function(_, button)
        if button ~= "LeftButton" then return end
        local _, cursorY = GetCursorPosition()
        local scale = math.max(0.001, track:GetEffectiveScale())
        local offset = (track:GetTop() or 0) - cursorY / scale - thumb:GetHeight() * 0.5
        local travel = math.max(1, track:GetHeight() - 4 - thumb:GetHeight())
        scroll:SetVerticalScroll(math.max(0, math.min(Range(), offset / travel * Range())))
        UpdateThumb()
        BeginDrag()
    end)
    track:SetScript("OnMouseUp", StopDrag)

    scroll:SetScript("OnMouseWheel", function(self, delta)
        local nextScroll = (tonumber(self:GetVerticalScroll()) or 0) - delta * 50
        self:SetVerticalScroll(math.max(0, math.min(Range(), nextScroll)))
        UpdateThumb()
    end)
    scroll:HookScript("OnVerticalScroll", UpdateThumb)
    scroll:HookScript("OnScrollRangeChanged", UpdateThumb)
    scroll:HookScript("OnSizeChanged", UpdateThumb)
    scroll:HookScript("OnShow", function() C_Timer.After(0, UpdateThumb) end)
    scroll._frameGambitScrollBar = track
    scroll._frameGambitUpdateScrollBar = UpdateThumb
    C_Timer.After(0, UpdateThumb)
end

local function Text(parent, template, value, color)
    local label = parent:CreateFontString(nil, "ARTWORK", template or "GameFontHighlightSmall")
    label:SetText(value or "")
    local actualColor = color or C.muted
    if actualColor == C.accent then TrackTheme(label, "text") end
    if actualColor == C.teal then TrackTheme(label, "tealText") end
    label:SetTextColor(unpack(actualColor))
    return label
end

local SetTooltip

local function Button(parent, label, width, callback, primary)
    local button = CreateFrame("Button", nil, parent, "BackdropTemplate")
    button._primary = primary
    button:SetSize(width or 92, 22)
    Backdrop(button, primary and C.accent or C.cardAlt, C.border)
    local text = Text(button, "GameFontNormalSmall", label, primary and { 1, 1, 1, 1 } or C.accent)
    text:SetPoint("CENTER")
    button:SetFontString(text)
    button:SetScript("OnEnter", function(self)
        if self._selected and self._selectedColor then
            self:SetBackdropColor(unpack(self._selectedColor))
        else
            local selected = self._primary or self._selected
            local accent = C.accent
            self:SetBackdropColor(selected and math.min(1, accent[1] * 1.12) or 0.12,
                selected and math.min(1, accent[2] * 1.18) or 0.12,
                selected and math.min(1, accent[3] * 1.12) or 0.18, 1)
        end
        if self._tooltipTitle then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(self._tooltipTitle, unpack(C.accent))
            if self._tooltipBody then GameTooltip:AddLine(self._tooltipBody, C.muted[1], C.muted[2], C.muted[3], true) end
            GameTooltip:Show()
        end
    end)
    button:SetScript("OnLeave", function(self)
        self:SetBackdropColor(unpack(self._selected and self._selectedColor or (self._primary or self._selected) and C.accent or C.cardAlt))
        if self._tooltipTitle then GameTooltip_Hide() end
    end)
    button:SetScript("OnClick", callback)
    return button
end

-- The first configurable-card Boolean. Keep the interaction explicit rather
-- than making players infer a value from a cycling button: the current answer
-- is filled, the other answer remains visible, and later picker cards can use
-- this exact Yes/No segment without inventing another toggle treatment.
local function BooleanChoice(parent)
    local choice = CreateFrame("Frame", nil, parent)
    choice:SetSize(70, 22)
    choice.yes = Button(choice, "Yes", 34, function()
        if choice._onChange then choice._onChange(true) end
    end)
    choice.yes:SetPoint("LEFT")
    choice.no = Button(choice, "No", 34, function()
        if choice._onChange then choice._onChange(false) end
    end)
    choice.no:SetPoint("RIGHT")
    function choice:SetValue(value)
        self.value = value == true
        for selected, button in pairs({ [self.value] = self.yes, [not self.value] = self.no }) do
            button._selected, button._selectedColor = selected, C.teal
            button:SetBackdropColor(unpack(selected and C.teal or C.cardAlt))
            button:GetFontString():SetTextColor(unpack(selected and { 0.02, 0.06, 0.07, 1 } or C.muted))
        end
    end
    function choice:SetCallback(callback) self._onChange = callback end
    return choice
end

local function CloseButton(parent, callback)
    local button = CreateFrame("Button", nil, parent, "BackdropTemplate")
    button:SetSize(24, 24)
    -- Match Resonance: the close control is a raised corner element, not part
    -- of the panel border.  The extra level keeps thick Cinematic borders and
    -- nested header cards from painting over it.
    button:SetFrameLevel(parent:GetFrameLevel() + 20)
    Backdrop(button, C.cardAlt, C.border)
    local strokes = {}
    for index, angle in ipairs({ math.pi / 4, -math.pi / 4 }) do
        local stroke = button:CreateTexture(nil, "ARTWORK")
        stroke:SetTexture("Interface\\Buttons\\WHITE8X8")
        stroke:SetSize(2, 13)
        stroke:SetPoint("CENTER")
        stroke:SetRotation(angle)
        stroke:SetVertexColor(unpack(C.accent))
        strokes[index] = stroke
    end
    local function Tint(color)
        for _, stroke in ipairs(strokes) do stroke:SetVertexColor(unpack(color)) end
    end
    button:SetScript("OnEnter", function(self)
        self:SetBackdropColor(C.teal[1] * 0.17, C.teal[2] * 0.20, C.teal[3] * 0.20, 1)
        self:SetBackdropBorderColor(unpack(C.teal))
        Tint(C.teal)
    end)
    button:SetScript("OnLeave", function(self)
        self:SetBackdropColor(unpack(C.cardAlt))
        self:SetBackdropBorderColor(unpack(C.border))
        Tint(C.accent)
    end)
    button:SetScript("OnClick", callback or function() parent:Hide() end)
    SetTooltip(button, "Close", "Close this window.")
    return button
end

function ns:IsCinematicEditorTheme()
    local panel = self.Options
    return panel and self:IsCinematicActive() or false
end

function ns:ApplyEditorTheme(force)
    local cinematic = force
    if cinematic == nil then cinematic = self:IsCinematicEditorTheme() end
    -- Cinematic keeps its familiar lavender structure, but turns the normal
    -- green live-state cue orange so the active profile is unmistakable.
    for index = 1, 4 do
        C.accent[index], C.border[index], C.teal[index] = BASE_ACCENT[index], BASE_BORDER[index], BASE_TEAL[index]
        if cinematic then C.teal[index] = CINEMATIC_ACCENT[index] end
    end
    for object, roles in pairs(themeObjects) do
        if roles.text and object.SetTextColor then pcall(object.SetTextColor, object, unpack(C.accent)) end
        if roles.tealText and object.SetTextColor then pcall(object.SetTextColor, object, unpack(C.teal)) end
        if roles.background and object.SetBackdropColor then pcall(object.SetBackdropColor, object, unpack(C.accent)) end
        if roles.tealBackground and object.SetBackdropColor then pcall(object.SetBackdropColor, object, unpack(C.teal)) end
        if roles.accentBorder and object.SetBackdropBorderColor then pcall(object.SetBackdropBorderColor, object, unpack(C.accent)) end
        if roles.tealBorder and object.SetBackdropBorderColor then pcall(object.SetBackdropBorderColor, object, unpack(C.teal)) end
        if roles.tealTexture and object.SetColorTexture then pcall(object.SetColorTexture, object, unpack(C.teal)) end
        if roles.border and object.SetBackdropBorderColor then pcall(object.SetBackdropBorderColor, object, unpack(C.border)) end
    end
    local panel = self.Options
    if panel then
        -- The outer boundary is the persistent Cinematic editing cue. Give it
        -- enough weight to read at a glance without recoloring every control.
        panel:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            edgeSize = cinematic and 4 or 1,
        })
        panel:SetBackdropColor(unpack(C.panel))
        panel:SetBackdropBorderColor(unpack(cinematic and CINEMATIC_BORDER or BASE_BORDER))
    end
    if panel and panel.header then
        panel.header:SetBackdropColor(unpack(NORMAL_HEADER))
    end
    if panel and panel.cinematic then
        panel.cinematic._selected = true
        panel.cinematic._selectedColor = CINEMATIC_BUTTON
        panel.cinematic:SetBackdropColor(unpack(CINEMATIC_BUTTON))
        panel.cinematic:SetBackdropBorderColor(unpack(CINEMATIC_ACCENT))
        panel.cinematic:GetFontString():SetText(cinematic and "Exit scene" or "Cinematic")
        panel.cinematic:GetFontString():SetTextColor(unpack(CINEMATIC_ACCENT))
    end
    if panel and panel.subtitle then
        panel.subtitle:SetText(cinematic and "Fine-tuning Cinematic Mode - changes are live." oãÞúâÚ$z{-®éÜj×'VR“²&6¶G&÷‡–6¶W"æFö6²Â2çæVÂÂ2æ66VçB¢–6¶W"çF—FÆRÒFW‡B‡–6¶W"æFö6²Â$vÖTföçDæ÷&ÖÂ"Â$Ö÷fR÷fW"F†RT’–÷RvçBFòÖævR"Â2æ66VçB“²–6¶W"çF—FÆS¥6WEö–çB‚%DõÄTeB"Â"ÂÓ“²–6¶W"çF—FÆS¥6WEv–GF‚ƒ3cb“²–6¶W"çF—FÆS¥6WEv÷&Ew&†fÇ6R¢–6¶W"æ6&–Æ—G’ÒFW‡B‡–6¶W"æFö6²Â$vÖTföçD†–v†Æ–v‡E6ÖÆÂ"Â""Â2çFVÂ“²–6¶W"æ6&–Æ—G“¥6WEö–çB‚%DõÄTeB"Â–6¶W"çF—FÆRÂ$$õEDôÔÄTeB"ÂÂÓB“²–6¶W"æ6&–Æ—G“¥6WEv–GF‚ƒ3cb“²–6¶W"æ6&–Æ—G“¥6WEv÷&Ew&†fÇ6R¢–6¶W"æ†VÇÒFW‡B‡–6¶W"æFö6²Â$vÖTföçD†–v†Æ–v‡E6ÖÆÂ"Â%v†VVÃ¢÷fW&Æ–ær&ö÷G2Â6Æ–6³¢6VÆV7BÂW63¢6æ6VÂ"Â2æ×WFVB“²–6¶W"æ†VÇ¥6WEö–çB‚%DõÄTeB"Â–6¶W"æ6&–Æ—G’Â$$õEDôÔÄTeB"ÂÂÓ2“²–6¶W"æ†VÇ¥6WEv–GF‚ƒ3cb“²–6¶W"æ†VÇ¥6WEv÷&Ew&‡G'VR¢–6¶W"çW6RÒ'WGFöâ‡–6¶W"æFö6²Â%W6RF†—2g&ÖR"Â"ÂgVæ7F–öâ‚’ç3¥W6U–6¶VEF&vWB‚’VæBÂG'VR“²–6¶W"çW6S¥6WEö–çB‚$$õEDôÕ$”t…B"ÂÓ"Â“²–6¶W"çW6S¤†–FR‚¢–6¶W"æv–âÒ'WGFöâ‡–6¶W"æFö6²Â$6†ö÷6Rv–â"Â“bÂgVæ7F–öâ‚’ç3¤6†ö÷6Tv–â‚’VæB“²–6¶W"æv–ã¥6WEö–çB‚%$”t…B"Â–6¶W"çW6RÂ$ÄTeB"ÂÓrÂ“²–6¶W"æv–ã¤†–FR‚¢–6¶W"ç67&–ÒÒ·Ð¢f÷"’ÒÂBFð¢Æö6ÂF–ÒÒ7&VFTg&ÖR‚$g&ÖR"Âæ–ÂÂ–6¶W"¢F–Ó¥6WDg&ÖTÆWfVÂƒ“¢Æö6ÂFW‡GW&RÒF–Ó¤7&VFUFW‡GW&R†æ–ÂÂ$$4´u$õTäB"¢FW‡GW&S¥6WDÆÅö–çG2‚¢FW‡GW&S¥6WD6öÆ÷%FW‡GW&RƒÂÂÂãS"¢–6¶W"ç67&–Õ¶•ÒÒF–Ð¢Væ@¢–6¶W#¥6WE67&—B‚$öåWFFR"ÂgVæ7F–öâ‡6VÆbÂVÆ6VB¢6VÆbçWFFTVÆ6VBÒ‡6VÆbçWFFTVÆ6VB÷"’²VÆ6V@¢–b6VÆbæ÷fW'f–Wt–æFW‚F†Vâ6öçF–çVU–6¶W$÷fW'f–Wr‡6VÆb’Væ@¢–b6VÆbæ6æF–FFUv—&T–æFW‚F†Vâ6öçF–çVU–6¶W$6æF–FFUv—&W2‡6VÆb’Væ@¢–b‡6VÆbæFÆ2æBæ÷B6VÆbæFÆ2æf–æÆ—¦VB’÷"6VÆbçWFFTVÆ6VBãÒã2F†Và¢6VÆbçWFFTVÆ6VBÒ ¢ç3¥WFFU–6¶W"‚¢Væ@¢VæB¢–6¶W#¥6WE67&—B‚$öäÖ÷W6Uv†VVÂ"ÂgVæ7F–öâ…òÂFVÇF’ç3¤7–6ÆU–6¶W"†FVÇF’VæB¢–6¶W#¥6WE67&—B‚$öä6Æ–6²"ÂgVæ7F–öâ‚’ç3¥6VÆV7E–6¶W$6æF–FFR‚’VæB¢–6¶W#¥6WE67&—B‚$öä†–FR"ÂgVæ7F–öâ‡6VÆb¢Æö6Â&W7F÷&RÒ6VÆbæW†—E&V6öâÓÒ&6æ6VÂ"æB6VÆbç&WGW&åFô÷F–öç2æBæ÷B–ä6öÖ&DÆö6¶F÷vâ‚¢Æö6Âv46–æVÖF–4¶VWÒ6VÆbæ–çFVçBÓÒ&6–æVÖF–5ö¶VW ¢6VÆbç†6RÂ6VÆbçVæF–æuF&vWD”BÂ6VÆbçVæF–æt6æF–FFRÂ6VÆbæ6æF–FFW2Â6VÆbæ–æFW‚Â6VÆbæÖöFRÂ6VÆbæ–çFVçBÒæ–ÂÂæ–ÂÂæ–ÂÂæ–ÂÂÂæ–ÂÂæ–À¢6VÆbæFÆ2Â6VÆbæÆ7D7W'6÷%‚Â6VÆbæÆ7D7W'6÷%’Â6VÆbæf÷&6Uf—7VÂÂ6VÆbçWFFTVÆ6VBÂ6VÆbæ÷fW'f–Wt–æFW‚Â6VÆbæ6æF–FFUv—&T–æFW‚Òæ–ÂÂæ–ÂÂæ–ÂÂæ–ÂÂÂæ–ÂÂæ–À¢6VÆbæ÷WFÆ–æS¤†–FR‚“²†–FU–6¶W%v—&Vg&ÖW2‡6VÆb¢f÷"òÂF–Ò–â——'2‡6VÆbç67&–Ò’FòF–Ó¤†–FR‚’Væ@¢–bv46–æVÖF–4¶VWF†Và¢ç2ç'VçF–ÖRæ6–æVÖF–5–6¶W%&WfVÂÒæ–À¢–bç3¤—46–æVÖF–47F—fR‚’F†Và¢–bæ÷B–ä6öÖ&DÆö6¶F÷vâ‚’F†Vâç3¥6WD6–æVÖF–5T”ÖöFR†ç3¤6åW6T6–æVÖF–4æF—fTÖöFR‚’’Væ@¢ç3¥WFFT6–æVÖF–4&Æ6¶÷WB‚¢Væ@¢Væ@¢6VÆbçW6S¤†–FR‚“²6VÆbæv–ã¤†–FR‚“²6VÆbæFö6³¥6WD†V–v‡Bƒ“¢–b&W7F÷&RæBç2ä÷F–öç2æBæ÷Bç2ä÷F–öç3¤—5f—6–&ÆR‚’F†Vâç2ä÷F–öç3¥6†÷r‚’Væ@¢VæB¢F&ÆRæ–ç6W'B…T•7V6–Äg&ÖW2Â–6¶W#¤vWDæÖR‚’¢–6¶W#¤†–FR‚“²6VÆbå–6¶W"Ò–6¶W ¦Væ@ ¦gVæ7F–öâç3¥7F'E–6¶W"†–çFVçB¢–b–ä6öÖ&DÆö6¶F÷vâ‚’F†Và¢–b6VÆbä÷F–öç2F†Vâ6VÆbä÷F–öç2æ7F—fS¥6WEFW‡B‚$g&ÖR6VÆV7F–öâ—2Væf–Æ&ÆRGW&–ær6öÖ&B"’6VÆbä÷F–öç2æ7F—fS¥6WEFW‡D6öÆ÷"‡Vç6²„2æÖ&W"’’Væ@¢&WGW&à¢Væ@¢6VÆc¤7&VFU–6¶W"‚¢–b–çFVçBÓÒ&6–æVÖF–5ö¶VW"æB6VÆc¤—46–æVÖF–47F—fR‚’F†Và¢6VÆbç'VçF–ÖRæ6–æVÖF–5–6¶W%&WfVÂÒG'VP¢6VÆc¥6WD6–æVÖF–5T”ÖöFR†fÇ6R¢6VÆc¥WFFT6–æVÖF–4&Æ6¶÷WB‚¢Væ@¢6VÆbå–6¶W"æÖöFRÂ6VÆbå–6¶W"æ–çFVçBÂ6VÆbå–6¶W"æ6æF–FFW2Â6VÆbå–6¶W"æ–æFW‚Ò&FÆ2"Â–çFVçB÷"'F&vWB"Â·ÒÂ ¢6VÆbå–6¶W"ç&WGW&åFô÷F–öç2Ò6VÆbä÷F–öç2æB6VÆbä÷F–öç3¤—5f—6–&ÆR‚’÷"fÇ6P¢6VÆbå–6¶W"æW†—E&V6öâÂ6VÆbå–6¶W"ç†6RÂ6VÆbå–6¶W"çVæF–æuF&vWD”BÂ6VÆbå–6¶W"çVæF–æt6æF–FFRÒ&6æ6VÂ"Â&'&÷w6R"Âæ–ÂÂæ–À¢6VÆbå–6¶W"æFÆ2Ò6VÆc¤&Vv–å–6¶W$FÆ2‚¢6VÆbå–6¶W"æÆ7D7W'6÷%‚Â6VÆbå–6¶W"æÆ7D7W'6÷%’Â6VÆbå–6¶W"æf÷&6Uf—7VÂÒæ–ÂÂæ–ÂÂG'VP¢6VÆbå–6¶W"çW6S¤†–FR‚“²6VÆbå–6¶W"æv–ã¤†–FR‚“²6VÆbå–6¶W"æFö6³¥6WD†V–v‡Bƒs¢6VÆbå–6¶W"æ†VÇ¥6WEFW‡D6öÆ÷"‡Vç6²„2æ×WFVB’¢–b6VÆbä÷F–öç2F†Vâ6VÆbä÷F–öç3¤†–FR‚’Væ@¢6VÆbå–6¶W#¥6†÷r‚“²6VÆc¥WFFU–6¶W"‚¦Væ@ ¦Æö6ÂgVæ7F–öâ–6¶W$g&ÖR†6æF–FFR¢–bæ÷B6æF–FFRF†Vâ&WGW&âæ–ÂVæ@¢–b6æF–FFRæg&ÖRF†Vâ&WGW&â6æF–FFRæg&ÖRVæ@¢&WGW&â6æF–FFRæ–BæBç3¥&W6öÇfUF&vWB†6æF–FFRæ–B¦Væ@ ¦Æö6ÂgVæ7F–öâ–6¶W$6&–Æ—G’†6æF–FFR¢–b6æF–FFRæB6æF–FFRæg&ÖRF†Và¢–b6æF–FFRææÖRF†Vâ&WGW&â6æF–FFRæ—5&ö÷BæB$æÖVBT’&ö÷B"÷"$æÖVBT’g&ÖR"Â%F†—26VÆV7F–öâv–ÆÂ&R6fVBæB&W6öÇfVBv–âgFW"&VÆöBâ"Â'FVÂ"Væ@¢&WGW&â6æF–FFRæ—5&ö÷BæB%6W76–öâÖöæÇ’T’&ö÷B"÷"%6W76–öâÖöæÇ’T’g&ÖR"Â%F†—2VææÖVB6VÆV7F–öâ6âfFRVçF–Â–÷R&VÆöC²—B6ææ÷B&R6fVB6fVÇ’â"Â&Ö&W" ¢Væ@¢&WGW&âç3¤vWEF&vWD6&–Æ—G’†6æF–FFR¦Væ@ ¦gVæ7F–öâç3¥WFFU–6¶W"‚¢Æö6Â–6¶W"Ò6VÆbå–6¶W ¢–bæ÷B–6¶W"÷"æ÷B–6¶W#¤—56†÷vâ‚’F†Vâ&WGW&âVæ@¢Æö6Â6æF–FFP¢–b–6¶W"ç†6RÓÒ&6öæf—&Ò"F†Và¢6æF–FFRÒ–6¶W"çVæF–æt6æF–FFR÷"‡–6¶W"çVæF–æuF&vWD”BæB6VÆbåF&vWD'””E·–6¶W"çVæF–æuF&vWD”EÒ¢–bæ÷B6æF–FFR÷"æ÷B–6¶W$g&ÖR†6æF–FFR’F†Vâ6VÆc¤6†ö÷6Tv–â‚“²&WGW&âVæ@¢VÇ6P¢–b–6¶W"æFÆ2æBæ÷B–6¶W"æFÆ2æf–æÆ—¦VBF†Và¢Æö6ÂFöæRÒ6VÆc¤6öçF–çVU–6¶W$FÆ2‡–6¶W"æFÆ2ÂcB¢–6¶W"æ÷WFÆ–æS¤†–FR‚“²–6¶W"æ6&–Æ—G“¥6†÷r‚¢f÷"òÂF–Ò–â——'2‡–6¶W"ç67&–Ò’FòF–Ó¤†–FR‚’Væ@¢–6¶W"çF—FÆS¥6WEFW‡B‚$Ö–ærf—6–&ÆRT’âââ"¢–6¶W"æ6&–Æ—G“¥6WEFW‡B‡7G&–æræf÷&ÖB‚"VB6†V6¶VB+rVBVÆ–v–&ÆR"Â–6¶W"æFÆ2æ–ç7V7FVB÷"Â–6¶W"æFÆ2æVÆ–v–&ÆR÷"’¢–6¶W"æ6&–Æ—G“¥6WEFW‡D6öÆ÷"‡Vç6²„2çFVÂ’¢–6¶W"æ†VÇ¥6WEFW‡B‚%F†—2†Vç2öæ6RW"6VÆV7F–öâ+rW63¢6æ6VÂ"¢–bæ÷BFöæRF†Vâ&WGW&âVæ@¢–6¶W"æf÷&6Uf—7VÂÒG'VP¢VWVU–6¶W$÷fW'f–Wr‡–6¶W"¢6öçF–çVU–6¶W$÷fW'f–Wr‡–6¶W"¢–b2‡–6¶W"æFÆ2æVçG&–W2÷"·Ò’ÓÒF†Và¢–6¶W"çF—FÆS¥6WEFW‡B‚$æò&VF&ÆRT’g&ÖW2vW&RÖVB"¢–6¶W"æ6&–Æ—G“¥6WEFW‡B‡7G&–æræf÷&ÖB‚"VBg&ÖW26†V6¶VB+rG'’÷&VÆöBöæ6R"Â–6¶W"æFÆ2æ–ç7V7FVB÷"’¢–6¶W"æ6&–Æ—G“¥6WEFW‡D6öÆ÷"‡Vç6²„2æÖ&W"’¢Væ@¢Væ@¢Æö6Â‚Â’Ò6VÆc¤vWET”7W'6÷%÷6—F–öâ‚¢Æö6ÂÖ÷fVBÒ‚æB’æB†æ÷B–6¶W"æÆ7D7W'6÷%‚÷"ÖF‚æ'2‡‚Ò–6¶W"æÆ7D7W'6÷%‚’ãÒ÷"ÖF‚æ'2‡’Ò–6¶W"æÆ7D7W'6÷%’’ãÒ¢–bÖ÷fVBF†Và¢Æö6Â&Wf–÷W2Ò–6¶W"æ6æF–FFW2æB–6¶W"æ6æF–FFW5·–6¶W"æ–æFW…Ð¢–6¶W"æÆ7D7W'6÷%‚Â–6¶W"æÆ7D7W'6÷%’Ò‚Â¢–6¶W"æ6æF–FFW2Ò6VÆc¤vWE–6¶W$FÆ46æF–FFW2‡–6¶W"æFÆ2Â‚Â’¢–6¶W"æ–æFW‚Ò ¢–b&Wf–÷W2æB&Wf–÷W2æg&ÖRF†Và¢f÷"–æFW‚Âf÷VæB–â——'2‡–6¶W"æ6æF–FFW2’Fð¢–bf÷VæBæg&ÖRÓÒ&Wf–÷W2æg&ÖRF†Vâ–6¶W"æ–æFW‚Ò–æFWƒ²'&V²Væ@¢Væ@¢Væ@¢–b–6¶W"æ–æFW‚ÓÒæB7–6¶W"æ6æF–FFW2âF†Vâ–6¶W"æ–æFW‚ÒVæ@¢–6¶W"æf÷&6Uf—7VÂÒG'VP¢Væ@¢Æö6ÂVæFW$7W'6÷"Ò–6¶W"æ6æF–FFW2÷"·Ð¢–b7VæFW$7W'6÷"ÓÒF†Và¢–6¶W"æ–æFW‚Ò ¢VÇ6P¢–6¶W"æ–æFW‚ÒÖF‚æÖ‚ƒÂÖF‚æÖ–â‡–6¶W"æ–æFW‚÷"Â7VæFW$7W'6÷"’¢Væ@¢6æF–FFRÒ–6¶W"æ6æF–FFW5·–6¶W"æ–æFW…Ð¢–bæ÷BÖ÷fVBæBæ÷B–6¶W"æf÷&6Uf—7VÂF†Vâ&WGW&âVæ@¢Væ@¢Æö6Âg&ÖRÒ–6¶W$g&ÖR†6æF–FFR¢Æö6ÂÆVgBÂ&÷GFöÒÂv–GF‚Â†V–v‡@¢–b6æF–FFRæB6æF–FFRæFW&—fVE&V7BæB6æF–FFRæÆVgBF†Và¢ÒÒ¦W&ò×6—¦VBÆöv–6Â6öçF–æW"—2&W&W6VçFVB'’—G266†VBVæ–öâö`¢ÒÒf—6–&ÆRFW66VæFçG2â—G2÷vâvWE&V7B&VÖ–ç2æ–Â'’FVf–æ—F–öâà¢ÆVgBÂ&÷GFöÒÂv–GF‚Â†V–v‡BÒ6æF–FFRæÆVgBÂ6æF–FFRæ&÷GFöÒÂ6æF–FFRçv–GF‚Â6æF–FFRæ†V–v‡@¢VÇ6V–b–6¶W"ç†6RÓÒ&'&÷w6R"æB6æF–FFRæB6æF–FFRæÆVgBF†Và¢ÆVgBÂ&÷GFöÒÂv–GF‚Â†V–v‡BÒ6æF–FFRæÆVgBÂ6æF–FFRæ&÷GFöÒÂ6æF–FFRçv–GF‚Â6æF–FFRæ†V–v‡@¢VÇ6V–bg&ÖRF†Và¢ÆVgBÂ&÷GFöÒÂv–GF‚Â†V–v‡BÒ6VÆc¤vWEW6&ÆTg&ÖU&V7B†g&ÖR¢Væ@¢Æö6Â&VG&uv—&W2Ò–6¶W"æf÷&6Uf—7VÀ¢–6¶W"æf÷&6Uf—7VÂÒæ–À¢–b&VG&uv—&W2F†VâVWVU–6¶W$6æF–FFUv—&W2‡–6¶W"“²6öçF–çVU–6¶W$6æF–FFUv—&W2‡–6¶W"’Væ@¢–bæ÷BÆVgB÷"æ÷B&÷GFöÒ÷"æ÷Bv–GF‚÷"æ÷B†V–v‡BF†Và¢–b–6¶W"ç†6RÓÒ&6öæf—&Ò"F†Vâ6VÆc¤6†ö÷6Tv–â‚“²&WGW&âVæ@¢–6¶W"æ÷WFÆ–æS¤†–FR‚¢f÷"òÂF–Ò–â——'2‡–6¶W"ç67&–Ò’FòF–Ó¤†–FR‚’Væ@¢–6¶W"æ6&–Æ—G“¥6†÷r‚¢Æö6ÂÖVBÒ–6¶W"æFÆ2æB2‡–6¶W"æFÆ2æVçG&–W2÷"·Ò’÷" ¢–bÖVBÓÒF†Và¢–6¶W"çF—FÆS¥6WEFW‡B‚$æò&VF&ÆRT’g&ÖW2vW&RÖVB"¢–6¶W"æ6&–Æ—G“¥6WEFW‡B‡7G&–æræf÷&ÖB‚"VBg&ÖW26†V6¶VB+r&W÷'BF†—26÷VçB"Â–6¶W"æFÆ2æB–6¶W"æFÆ2æ–ç7V7FVB÷"’¢–6¶W"æ6&–Æ—G“¥6WEFW‡D6öÆ÷"‡Vç6²„2æÖ&W"’¢–6¶W"æ†VÇ¥6WEFW‡B‚$W63¢6æ6VÂ"¢VÇ6P¢–6¶W"çF—FÆS¥6WEFW‡B‚$æòT’g&ÖRVæFW"F†R7W'6÷""¢–6¶W"æ6&–Æ—G“¥6WEFW‡B‡7G&–æræf÷&ÖB‚"VBg&ÖR&Vv–öç2ÖVB"ÂÖVB’¢–6¶W"æ6&–Æ—G“¥6WEFW‡D6öÆ÷"‡Vç6²„2çFVÂ’¢–6¶W"æ†VÇ¥6WEFW‡B‚$Ö÷fR÷fW"v—&Vg&ÖR+rv†VVÃ¢FWF‚+rW63¢6æ6VÂ"¢Væ@¢&WGW&à¢Væ@¢–6¶W"æ÷WFÆ–æS¤6ÆV$ÆÅö–çG2‚“²–6¶W"æ÷WFÆ–æS¥6WEö–çB‚$$õEDôÔÄTeB"ÂT•&VçBÂ$$õEDôÔÄTeB"ÂÆVgBÒ2Â&÷GFöÒÒ2“²–6¶W"æ÷WFÆ–æS¥6WE6—¦R‡v–GF‚²bÂ†V–v‡B²b“²–6¶W"æ÷WFÆ–æS¥6†÷r‚¢ÒÒf÷W"æVÇ27&VFR6fR7÷FÆ–v‡C¢&VÂg&ÖW2&VÖ–âVçF÷V6†VBÂv†–ÆP¢ÒÒF†R&W7BöbF†R67&VVâ—2vVçFÇ’FRÖV×†6—¦VBGW&–ær6VÆV7F–öâà¢Æö6ÂV•v–GF‚ÂV”†V–v‡BÒT•&VçC¤vWEv–GF‚‚’ÂT•&VçC¤vWD†V–v‡B‚¢Æö6Â‚Â’ÂrÂ‚ÒÆVgBÂ&÷GFöÒÂv–GF‚Â†V–v‡@¢Æö6ÂF÷Â&–v‡BÒ’²‚Â‚²p¢Æö6ÂF–×2Ò–6¶W"ç67&–Ð¢F–×5³Ó¤6ÆV$ÆÅö–çG2‚“²F–×5³Ó¥6WEö–çB‚$$õEDôÔÄTeB"ÂT•&VçBÂ$$õEDôÔÄTeB"ÂÂF÷“²F–×5³Ó¥6WE6—¦R‡V•v–GF‚ÂÖF‚æÖ‚ƒÂV”†V–v‡BÒF÷’“²F–×5³Ó¥6†÷r‚¢F–×5³%Ó¤6ÆV$ÆÅö–çG2‚“²F–×5³%Ó¥6WEö–çB‚$$õEDôÔÄTeB"ÂT•&VçBÂ$$õEDôÔÄTeB"ÂÂ“²F–×5³%Ó¥6WE6—¦R‡V•v–GF‚ÂÖF‚æÖ‚ƒÂ’’“²F–×5³%Ó¥6†÷r‚¢F–×5³5Ó¤6ÆV$ÆÅö–çG2‚“²F–×5³5Ó¥6WEö–çB‚$$õEDôÔÄTeB"ÂT•&VçBÂ$$õEDôÔÄTeB"ÂÂ’“²F–×5³5Ó¥6WE6—¦R†ÖF‚æÖ‚ƒÂ‚’Â‚“²F–×5³5Ó¥6†÷r‚¢F–×5³EÓ¤6ÆV$ÆÅö–çG2‚“²F–×5³EÓ¥6WEö–çB‚$$õEDôÔÄTeB"ÂT•&VçBÂ$$õEDôÔÄTeB"Â&–v‡BÂ’“²F–×5³EÓ¥6WE6—¦R†ÖF‚æÖ‚ƒÂV•v–GF‚Ò&–v‡B’Â‚“²F–×5³EÓ¥6†÷r‚¢–b–6¶W"ç†6RÓÒ&6öæf—&Ò"F†Và¢–6¶W"çF—FÆS¥6WEFW‡B‚‡–6¶W"æ–çFVçBÓÒ&6–æVÖF–5ö¶VW"æB$¶VWf—6–&ÆS¢"÷"%6VÆV7FVC¢"’ââ6æF–FFRæÆ&VÂ¢Æö6Â6&–Æ—G’ÂòÂFöæRÒ–6¶W$6&–Æ—G’†6æF–FFR¢–6¶W"æ6&–Æ—G“¥6†÷r‚“²–6¶W"æ6&–Æ—G“¥6WEFW‡B†6&–Æ—G’“²–6¶W"æ6&–Æ—G“¥6WEFW‡D6öÆ÷"‡Vç6²„5·FöæUÒ÷"2æ66VçB’¢–6¶W"æ†VÇ¥6WEFW‡B‡–6¶W"æ–çFVçBÓÒ&6–æVÖF–5ö¶VW"æB$6öæf—&ÒFò¶VWF†—2&ö÷Bf—6–&ÆR–â6–æVÖF–2ÖöFR"÷"$6öæf—&Ò÷"6†ö÷6Rv–â"¢VÇ6P¢Æö6Â66÷RÒ6æF–FFRæ—5&ö÷BÓÒfÇ6RæB&–ææW"g&ÖR"÷"'v†öÆRv–æF÷r ¢–6¶W"çF—FÆS¥6WEFW‡B…6†÷'EFW‡B†6æF–FFRæÆ&VÂÂ3’ââ"+r"ââ66÷Rââ"+r"ââ–6¶W"æ–æFW‚ââ"öb"ââ7–6¶W"æ6æF–FFW2¢Æö6Â6&–Æ—G’ÂòÂFöæRÒ–6¶W$6&–Æ—G’†6æF–FFR¢–6¶W"æ6&–Æ—G“¥6†÷r‚“²–6¶W"æ6&–Æ—G“¥6WEFW‡B†6&–Æ—G’“²–6¶W"æ6&–Æ—G“¥6WEFW‡D6öÆ÷"‡Vç6²„5·FöæUÒ÷"2æ66VçB’¢–6¶W"æ†VÇ¥6WEFW‡B‚%v†VVÃ¢÷fW&Æ–ær&ö÷G2Â6Æ–6³¢6VÆV7BÂW63¢6æ6VÂ"¢Væ@¦Væ@ ¦gVæ7F–öâç3¤7–6ÆU–6¶W"†FVÇF¢Æö6Â–6¶W"Ò6VÆbå–6¶W ¢–b–6¶W"ç†6RãÒ&'&÷w6R"F†Vâ&WGW&âVæ@¢–bæ÷B–6¶W"æ6æF–FFW2÷"7–6¶W"æ6æF–FFW2ÓÒF†Vâ&WGW&âVæ@¢–6¶W"æ–æFW‚Ò–6¶W"æ–æFW‚ÒFVÇF¢–b–6¶W"æ–æFW‚ÂF†Vâ–6¶W"æ–æFW‚Ò7–6¶W"æ6æF–FFW2VÇ6V–b–6¶W"æ–æFW‚â7–6¶W"æ6æF–FFW2F†Vâ–6¶W"æ–æFW‚ÒVæ@¢–6¶W"æf÷&6Uf—7VÂÒG'VP¢6VÆc¥WFFU–6¶W"‚¦Væ@ ¦gVæ7F–öâç3¥6VÆV7E–6¶W$6æF–FFR‚¢Æö6Â–6¶W"Ò6VÆbå–6¶W ¢Æö6Â6æF–FFRÒ–6¶W"æB–6¶W"æ6æF–FFW2æB–6¶W"æ6æF–FFW5·–6¶W"æ–æFW…Ð¢–bæ÷B6æF–FFR÷"–6¶W"ç†6RãÒ&'&÷w6R"F†Vâ&WGW&âVæ@¢–6¶W"ç†6RÂ–6¶W"çVæF–æt6æF–FFRÂ–6¶W"çVæF–æuF&vWD”BÒ&6öæf—&Ò"Â6æF–FFRÂ6æF–FFRæ–@¢–6¶W"æf÷&6Uf—7VÂÒG'VP¢–6¶W"æFö6³¥6WD†V–v‡Bƒ#2“²–6¶W"çW6S¥6†÷r‚“²–6¶W"æv–ã¥6†÷r‚¢6VÆc¥WFFU–6¶W"‚¦Væ@ ¦gVæ7F–öâç3¤6†ö÷6Tv–â‚¢Æö6Â–6¶W"Ò6VÆbå–6¶W ¢–bæ÷B–6¶W"÷"æ÷B–6¶W#¤—56†÷vâ‚’F†Vâ&WGW&âVæ@¢–6¶W"ç†6RÂ–6¶W"çVæF–æuF&vWD”BÂ–6¶W"çVæF–æt6æF–FFRÒ&'&÷w6R"Âæ–ÂÂæ–À¢–6¶W"æf÷&6Uf—7VÂÒG'VP¢–6¶W"æFö6³¥6WD†V–v‡Bƒ““²–6¶W"çW6S¤†–FR‚“²–6¶W"æv–ã¤†–FR‚¢–6¶W"æ†VÇ¥6WEFW‡D6öÆ÷"‡Vç6²„2æ×WFVB’¢6VÆc¥WFFU–6¶W"‚¦Væ@ ¦gVæ7F–öâç3¥W6U–6¶VEF&vWB‚¢Æö6Â–6¶W"Ò6VÆbå–6¶W ¢Æö6Â6æF–FFRÒ–6¶W"æB–6¶W"çVæF–æt6æF–FFP¢–b–6¶W"æB–6¶W"æ–çFVçBÓÒ&6–æVÖF–5ö¶VW"F†Và¢Æö6Âö²Â&V6öà¢–b6æF–FFRæB6æF–FFRæg&ÖRF†Vâö²Â&V6öâÒ6VÆc¤¶VW6–æVÖF–4g&ÖR†6æF–FFRæg&ÖR’Væ@¢–bæ÷Bö²F†Và¢6VÆc¤6†ö÷6Tv–â‚¢–6¶W"æ†VÇ¥6WEFW‡B‡&V6öâ÷"%F†Bg&ÖR—2æòÆöævW"f–Æ&ÆRâ"¢–6¶W"æ†VÇ¥6WEFW‡D6öÆ÷"‡Vç6²„2æÖ&W"’¢&WGW&à¢Væ@¢–6¶W"æW†—E&V6öâÒ'W6VB ¢–6¶W#¤†–FR‚¢–b6VÆbä÷F–öç2F†Vâ6VÆbä÷F–öç3¥6†÷r‚’Væ@¢–b6VÆbä6–æVÖF–4÷F–öç2æB6VÆbä6–æVÖF–4÷F–öç3¤—56†÷vâ‚’F†Và¢6VÆbä6–æVÖF–4÷F–öç2ç7FGW3¥6WEFW‡B‡&V6öâ¢6VÆbä6–æVÖF–4÷F–öç2ç7FGW3¥6WEFW‡D6öÆ÷"‡Vç6²„2çFVÂ’¢6VÆc¥&VæFW$6–æVÖF–4÷F–öç2‚¢Væ@¢&WGW&à¢Væ@¢Æö6ÂF&vWD”BÒ6æF–FFRæB6æF–FFRæ–@¢–b6æF–FFRæB6æF–FFRæg&ÖRF†Và¢Æö6Â–BÂ&V6öâÒ6VÆc¥&Vv—7FW$F—66÷fW&VDg&ÖR†6æF–FFRæg&ÖRÂ6æF–FFRæÆ&VÂÂG'VR¢–bæ÷B–BF†Và¢6VÆc¤6†ö÷6Tv–â‚¢–6¶W"æ†VÇ¥6WEFW‡B‡&V6öâ÷"%F†Bg&ÖR—2æòÆöævW"f–Æ&ÆRâ"¢–6¶W"æ†VÇ¥6WEFW‡D6öÆ÷"‡Vç6²„2æÖ&W"’¢&WGW&à¢Væ@¢F&vWD”BÒ–@¢Væ@¢Æö6ÂF&vWBÒF&vWD”BæB6VÆbåF&vWD'””E·F&vWD”EÐ¢–bæ÷BF&vWB÷"æ÷B6VÆc¥&W6öÇfUF&vWB‡F&vWD”B’F†Vâ6VÆc¤6†ö÷6Tv–â‚“²&WGW&âVæ@¢–b–ä6öÖ&DÆö6¶F÷vâ‚’F†Vâ6VÆc¤6æ6VÅ–6¶W"‚&–çFW''WFVB"“²&WGW&âVæ@¢–6¶W"æW†—E&V6öâÒ'W6VB ¢–6¶W#¤†–FR‚¢6VÆc¤FEF&vWB‡F&vWD”B¢6VÆbä÷F–öç2ç6VÆV7FVBÒF&vWD”@¢6VÆbä÷F–öç3¥6†÷r‚¦Væ@ ¦gVæ7F–öâç3¤6æ6VÅ–6¶W"‡&V6öâ¢–b6VÆbå–6¶W"æB6VÆbå–6¶W#¤—56†÷vâ‚’F†Và¢6VÆbå–6¶W"æW†—E&V6öâÒ&V6öâÓÒ&6æ6VÂ"æB&6æ6VÂ"÷"&–çFW''WFVB ¢6VÆbå–6¶W#¤†–FR‚¢Væ@¦Væ@ 