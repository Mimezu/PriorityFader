Exit code: 0
Wall time: 0.4 seconds
Total output lines: 3003
Output:
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
        panel.subtitle:SetText(cinematic and "Fine-tuning Cinematic Mode - changes are live." or "Choose visible UI, then decide how it should respond.")
        panel.subtitle:SetTextColor(unpack(cinematic and CINEMATIC_ACCENT or C.muted))
    end
end

local function LiveStateFill()
    return ns:IsCinematicEditorTheme() and CINEMATIC_BUTTON or { 0.05, 0.18, 0.17, 1 }
end

local function ClearChildren(frame)
    if not frame._rows then return end
    for _, child in ipairs(frame._rows) do child:Hide() end
    wipe(frame._rows)
end

local function Percent(value)
    return ("%d%%"):format(math.floor((value or 0) * 100 + 0.5))
end

local function Seconds(value)
    value = math.floor((tonumber(value) or 0) * 100 + 0.5) / 100
    if value % 1 == 0 then return string.format("%ds", value) end
    if (value * 10) % 1 == 0 then return string.format("%.1fs", value) end
    return string.format("%.2fs", value)
end

local function ShortText(value, limit)
    value = tostring(value or "")
    if #value <= limit then return value end
    return value:sub(1, math.max(1, limit - 3)) .. "..."
end

local function NormalizedDuration(value)
    value = math.max(0.5, math.min(30, tonumber(value) or 3))
    return math.floor(value * 4 + 0.5) / 4
end

-- Reaction rows are edited frequently.  Keep a small reusable set rather
-- than creating a new frame tree every time a value is nudged or reordered.

local function NewReactionRow(parent)
    local row = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    row:SetSize(10, 39); Backdrop(row, C.cardAlt)
    row.handle = CreateFrame("Button", nil, row)
    row.handle:SetSize(24, 39); row.handle:SetPoint("LEFT", 0, 0); row.handle:RegisterForDrag("LeftButton")
    row.handle.label = Text(row.handle, "GameFontNormal", "::", C.muted); row.handle.label:SetPoint("CENTER")
    row.handle:SetScript("OnDragStart", function(self)
        if self._targetID and self._reaction and self._row then ns:StartReactionDrag(self._targetID, self._reaction, self._row) end
    end)
    row.handle:SetScript("OnDragStop", function() ns:FinishReactionDrag() end)
    row.handle:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("Reorder reaction", unpack(C.accent))
        GameTooltip:AddLine("Drag this handle to place the reaction at a new priority. The top matching row still wins.", C.muted[1], C.muted[2], C.muted[3], true)
        GameTooltip:Show()
    end)
    row.handle:SetScript("OnLeave", GameTooltip_Hide)
    row.label = Text(row, "GameFontHighlight", "", C.accent); row.label:SetPoint("LEFT", 65, 0)
    row.formPicker = Button(row, "", 132, nil); row.formPicker:SetPoint("LEFT", 65, 0); row.formPicker:Hide()
    row.formExpected = BooleanChoice(row); row.formExpected:SetPoint("LEFT", row.formPicker, "RIGHT", 5, 0); row.formExpected:Hide()
    SetTooltip(row.formPicker, "Form", "Choose the form this reaction checks. Unavailable class/spec forms stay saved but are skipped.")
    SetTooltip(row.formExpected.yes, "Form is active", "This row matches while the chosen form is active.")
    SetTooltip(row.formExpected.no, "Form is inactive", "This row matches while the chosen form is available but inactive.")
    row.opacity = Button(row, "", 54, nil)
    row.opacity:RegisterForClicks("LeftButtonUp", "RightButtonUp"); row.opacity:SetPoint("RIGHT", -87, 0)
    SetTooltip(row.opacity, "Opacity", "Choose a preset or drag to a precise visibility level.")
    row.requirements = Button(row, "+", 22, nil); row.requirements:SetPoint("RIGHT", row.opacity, "LEFT", -5)
    SetTooltip(row.requirements, "Requirements", "Add or remove extra conditions. All requirements must be true.")
    -- Enable/disable is a row-level control, so it lives beside the drag
    -- handle rather than among the condition's value controls.
    row.enabled = Button(row, "On", 30, nil); row.enabled:SetPoint("LEFT", row.handle, "RIGHT", 5, 0)
    SetTooltip(row.enabled, "Reaction enabled", "Turn this gambit row off without removing its condition, priority, or settings.")
    row.duration = Button(row, "", 40, nil); row.duration:SetPoint("RIGHT", row.requirements, "LEFT", -5); row.duration:Hide()
    SetTooltip(row.duration, "Reaction duration", "Choose how long this event reaction stays active.")
    row.up = Button(row, "^", 22, nil); row.up:SetPoint("RIGHT", -60, 0)
    row.down = Button(row, "v", 22, nil); row.down:SetPoint("RIGHT", -34, 0)
    row.remove = Button(row, "x", 22, nil); row.remove:SetPoint("RIGHT", -8, 0)
    return row
end

SetTooltip = function(frame, title, body)
    frame._tooltipTitle, frame._tooltipBody = title, body
end

local function ConditionLabel(condition)
    return (ns.CONDITION_INFO[condition] and ns.CONDITION_INFO[condition].label) or condition
end

local function ReactionLabel(reaction)
    if reaction and reaction.condition == "form" then
        local option = ns.FORM_BY_ID and ns.FORM_BY_ID[reaction.formKey]
        return "Form: " .. (option and option.label or "Choose a form")
    end
    if reaction and reaction.condition == "spec…34823 tokens truncated…        local parentTarget = ns.TargetByID[visibilityParent]
        local hasLocalRules = settings and #(settings.reactions or {}) > 0
        local follows = Text(p, "GameFontHighlightSmall", (hasLocalRules and "Local rules, then: " or "Follows: ") .. (parentTarget and parentTarget.label or visibilityParent), C.teal)
        follows:SetPoint("TOPLEFT", previous, "BOTTOMLEFT", 0, -12); p._rows[#p._rows + 1] = follows
        local unlink = Button(p, "Stop following", 92, function()
            ns:RemoveVisibilityLink(visibilityParent, id); ns:RenderSelectedTarget(id)
        end)
        unlink:SetPoint("TOPLEFT", follows, "BOTTOMLEFT", 0, -4); p._rows[#p._rows + 1] = unlink
    end
end

local function NewPickerWireframe(picker)
    local wire = CreateFrame("Frame", nil, picker)
    wire:SetFrameLevel(903)
    wire:EnableMouse(false)
    wire.lines = {}
    for index = 1, 4 do
        local line = wire:CreateTexture(nil, "ARTWORK")
        line:SetColorTexture(C.border[1], C.border[2], C.border[3], 0.42)
        wire.lines[index] = line
    end
    wire.lines[1]:SetPoint("TOPLEFT"); wire.lines[1]:SetPoint("TOPRIGHT"); wire.lines[1]:SetHeight(2)
    wire.lines[2]:SetPoint("BOTTOMLEFT"); wire.lines[2]:SetPoint("BOTTOMRIGHT"); wire.lines[2]:SetHeight(2)
    wire.lines[3]:SetPoint("TOPLEFT"); wire.lines[3]:SetPoint("BOTTOMLEFT"); wire.lines[3]:SetWidth(2)
    wire.lines[4]:SetPoint("TOPRIGHT"); wire.lines[4]:SetPoint("BOTTOMRIGHT"); wire.lines[4]:SetWidth(2)
    return wire
end

local function PositionPickerWire(wire, entry, color, alpha)
    wire:ClearAllPoints()
    wire:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", entry.left, entry.bottom)
    wire:SetSize(entry.width, entry.height)
    for _, line in ipairs(wire.lines) do line:SetColorTexture(color[1], color[2], color[3], alpha) end
    wire:Show()
end

local function HidePickerWireframes(picker)
    for _, wire in ipairs(picker.overviewWires or {}) do wire:Hide() end
    for _, wire in ipairs(picker.candidateWires or {}) do wire:Hide() end
end

local function QueuePickerOverview(picker)
    for _, wire in ipairs(picker.overviewWires or {}) do wire:Hide() end
    local atlas = picker.atlas
    if not atlas or not atlas.finalized then return end
    picker.overviewWires = picker.overviewWires or {}
    picker.overviewIndex = 1
end

local function ContinuePickerOverview(picker)
    local atlas, index = picker.atlas, picker.overviewIndex
    if not atlas or not atlas.finalized or not index then return end
    local started = type(debugprofilestop) == "function" and debugprofilestop() or nil
    local processed = 0
    while index <= #(atlas.overview or {}) and processed < 10
        and (processed == 0 or not started or debugprofilestop() - started < 0.8) do
        local wire = picker.overviewWires[index]
        if not wire then wire = NewPickerWireframe(picker); wire:SetFrameLevel(902); picker.overviewWires[index] = wire end
        PositionPickerWire(wire, atlas.overview[index], C.accent, 0.48)
        index, processed = index + 1, processed + 1
    end
    picker.overviewIndex = index <= #(atlas.overview or {}) and index or nil
end

local function QueuePickerCandidateWires(picker)
    picker.candidateWires = picker.candidateWires or {}
    for _, wire in ipairs(picker.candidateWires) do wire:Hide() end
    picker.candidateWireIndex = 1
end

local function ContinuePickerCandidateWires(picker)
    local index = picker.candidateWireIndex
    if not index then return end
    local maximum = math.min(40, #(picker.candidates or {}))
    local started = type(debugprofilestop) == "function" and debugprofilestop() or nil
    local processed = 0
    while index <= maximum and processed < 8
        and (processed == 0 or not started or debugprofilestop() - started < 0.6) do
        local wire = picker.candidateWires[index]
        if not wire then wire = NewPickerWireframe(picker); wire:SetFrameLevel(903); picker.candidateWires[index] = wire end
        PositionPickerWire(wire, picker.candidates[index], C.teal, 0.72)
        index, processed = index + 1, processed + 1
    end
    picker.candidateWireIndex = index <= maximum and index or nil
end

function ns:CreatePicker()
    if self.Picker then return end
    local picker = CreateFrame("Button", "PriorityFaderPicker", UIParent)
    picker:SetAllPoints(UIParent); picker:SetFrameStrata("FULLSCREEN_DIALOG"); picker:SetFrameLevel(900)
    picker:EnableMouse(true); picker:EnableMouseWheel(true); picker:RegisterForClicks("LeftButtonUp")
    picker:SetNormalTexture("Interface\\Buttons\\WHITE8X8"); picker:GetNormalTexture():SetAlpha(0)
    picker.outline = CreateFrame("Frame", nil, picker, "BackdropTemplate"); Backdrop(picker.outline, { 0, 0, 0, 0 }, C.teal); picker.outline:SetFrameLevel(905); picker.outline:EnableMouse(false)
    picker.dock = CreateFrame("Frame", nil, picker, "BackdropTemplate"); picker.dock:SetSize(390, 90); picker.dock:SetPoint("TOP", 0, -34); picker.dock:SetFrameLevel(910); picker.dock:EnableMouse(true); Backdrop(picker.dock, C.panel, C.accent)
    picker.title = Text(picker.dock, "GameFontNormal", "Move over the UI you want to manage", C.accent); picker.title:SetPoint("TOPLEFT", 12, -11); picker.title:SetWidth(366); picker.title:SetWordWrap(false)
    picker.capability = Text(picker.dock, "GameFontHighlightSmall", "", C.teal); picker.capability:SetPoint("TOPLEFT", picker.title, "BOTTOMLEFT", 0, -4); picker.capability:SetWidth(366); picker.capability:SetWordWrap(false)
    picker.help = Text(picker.dock, "GameFontHighlightSmall", "Wheel: overlapping roots  |  Click: select  |  Esc: cancel", C.muted); picker.help:SetPoint("TOPLEFT", picker.capability, "BOTTOMLEFT", 0, -3); picker.help:SetWidth(366); picker.help:SetWordWrap(true)
    picker.use = Button(picker.dock, "Use this frame", 112, function() ns:UsePickedTarget() end, true); picker.use:SetPoint("BOTTOMRIGHT", -12, 10); picker.use:Hide()
    picker.again = Button(picker.dock, "Choose again", 96, function() ns:ChooseAgain() end); picker.again:SetPoint("RIGHT", picker.use, "LEFT", -7, 0); picker.again:Hide()
    picker.scrim = {}
    for i = 1, 4 do
        local dim = CreateFrame("Frame", nil, picker)
        dim:SetFrameLevel(901)
        local texture = dim:CreateTexture(nil, "BACKGROUND")
        texture:SetAllPoints()
        texture:SetColorTexture(0, 0, 0, 0.52)
        picker.scrim[i] = dim
    end
    picker:SetScript("OnUpdate", function(self, elapsed)
        self.updateElapsed = (self.updateElapsed or 0) + elapsed
        if self.overviewIndex then ContinuePickerOverview(self) end
        if self.candidateWireIndex then ContinuePickerCandidateWires(self) end
        if (self.atlas and not self.atlas.finalized) or self.updateElapsed >= 0.03 then
            self.updateElapsed = 0
            ns:UpdatePicker()
        end
    end)
    picker:SetScript("OnMouseWheel", function(_, delta) ns:CyclePicker(delta) end)
    picker:SetScript("OnClick", function() ns:SelectPickerCandidate() end)
    picker:SetScript("OnHide", function(self)
        local restore = self.exitReason == "cancel" and self.returnToOptions and not InCombatLockdown()
        local wasCinematicKeep = self.intent == "cinematic_keep"
        self.phase, self.pendingTargetID, self.pendingCandidate, self.candidates, self.index, self.mode, self.intent = nil, nil, nil, nil, 0, nil, nil
        self.atlas, self.lastCursorX, self.lastCursorY, self.forceVisual, self.updateElapsed, self.overviewIndex, self.candidateWireIndex = nil, nil, nil, nil, 0, nil, nil
        self.outline:Hide(); HidePickerWireframes(self)
        for _, dim in ipairs(self.scrim) do dim:Hide() end
        if wasCinematicKeep then
            ns.runtime.cinematicPickerReveal = nil
            if ns:IsCinematicActive() then
                if not InCombatLockdown() then ns:SetCinematicUIMode(ns:CanUseCinematicNativeMode()) end
                ns:UpdateCinematicBlackout()
            end
        end
        self.use:Hide(); self.again:Hide(); self.dock:SetHeight(90)
        if restore and ns.Options and not ns.Options:IsVisible() then ns.Options:Show() end
    end)
    table.insert(UISpecialFrames, picker:GetName())
    picker:Hide(); self.Picker = picker
end

function ns:StartPicker(intent)
    if InCombatLockdown() then
        if self.Options then self.Options.active:SetText("Frame selection is unavailable during combat") self.Options.active:SetTextColor(unpack(C.amber)) end
        return
    end
    self:CreatePicker()
    if intent == "cinematic_keep" and self:IsCinematicActive() then
        self.runtime.cinematicPickerReveal = true
        self:SetCinematicUIMode(false)
        self:UpdateCinematicBlackout()
    end
    self.Picker.mode, self.Picker.intent, self.Picker.candidates, self.Picker.index = "atlas", intent or "target", {}, 0
    self.Picker.returnToOptions = self.Options and self.Options:IsVisible() or false
    self.Picker.exitReason, self.Picker.phase, self.Picker.pendingTargetID, self.Picker.pendingCandidate = "cancel", "browse", nil, nil
    self.Picker.atlas = self:BeginPickerAtlas()
    self.Picker.lastCursorX, self.Picker.lastCursorY, self.Picker.forceVisual = nil, nil, true
    self.Picker.use:Hide(); self.Picker.again:Hide(); self.Picker.dock:SetHeight(70)
    self.Picker.help:SetTextColor(unpack(C.muted))
    if self.Options then self.Options:Hide() end
    self.Picker:Show(); self:UpdatePicker()
end

local function PickerFrame(candidate)
    if not candidate then return nil end
    if candidate.frame then return candidate.frame end
    return candidate.id and ns:ResolveTarget(candidate.id)
end

local function PickerCapability(candidate)
    if candidate and candidate.frame then
        if candidate.name then return candidate.isRoot and "Named UI root" or "Named UI frame", "This selection will be saved and resolved again after reload.", "teal" end
        return candidate.isRoot and "Session-only UI root" or "Session-only UI frame", "This unnamed selection can fade until you reload; it cannot be saved safely.", "amber"
    end
    return ns:GetTargetCapability(candidate)
end

function ns:UpdatePicker()
    local picker = self.Picker
    if not picker or not picker:IsShown() then return end
    local candidate
    if picker.phase == "confirm" then
        candidate = picker.pendingCandidate or (picker.pendingTargetID and self.TargetByID[picker.pendingTargetID])
        if not candidate or not PickerFrame(candidate) then self:ChooseAgain(); return end
    else
        if picker.atlas and not picker.atlas.finalized then
            local done = self:ContinuePickerAtlas(picker.atlas, 64)
            picker.outline:Hide(); picker.capability:Show()
            for _, dim in ipairs(picker.scrim) do dim:Hide() end
            picker.title:SetText("Mapping visible UI...")
            picker.capability:SetText(string.format("%d checked · %d eligible", picker.atlas.inspected or 0, picker.atlas.eligible or 0))
            picker.capability:SetTextColor(unpack(C.teal))
            picker.help:SetText("This happens once per selection · Esc: cancel")
            if not done then return end
            picker.forceVisual = true
            QueuePickerOverview(picker)
            ContinuePickerOverview(picker)
            if #(picker.atlas.entries or {}) == 0 then
                picker.title:SetText("No readable UI frames were mapped")
                picker.capability:SetText(string.format("%d frames checked · try /reload once", picker.atlas.inspected or 0))
                picker.capability:SetTextColor(unpack(C.amber))
            end
        end
        local x, y = self:GetUICursorPosition()
        local moved = x and y and (not picker.lastCursorX or math.abs(x - picker.lastCursorX) >= 1 or math.abs(y - picker.lastCursorY) >= 1)
        if moved then
            local previous = picker.candidates and picker.candidates[picker.index]
            picker.lastCursorX, picker.lastCursorY = x, y
            picker.candidates = self:GetPickerAtlasCandidates(picker.atlas, x, y)
            picker.index = 0
            if previous and previous.frame then
                for index, found in ipairs(picker.candidates) do
                    if found.frame == previous.frame then picker.index = index; break end
                end
            end
            if picker.index == 0 and #picker.candidates > 0 then picker.index = 1 end
            picker.forceVisual = true
        end
        local underCursor = picker.candidates or {}
        if #underCursor == 0 then
            picker.index = 0
        else
            picker.index = math.max(1, math.min(picker.index or 1, #underCursor))
        end
        candidate = picker.candidates[picker.index]
        if not moved and not picker.forceVisual then return end
    end
    local frame = PickerFrame(candidate)
    local left, bottom, width, height
    if candidate and candidate.derivedRect and candidate.left then
        -- A zero-sized logical container is represented by its cached union of
        -- visible descendants. Its own GetRect remains nil by definition.
        left, bottom, width, height = candidate.left, candidate.bottom, candidate.width, candidate.height
    elseif picker.phase == "browse" and candidate and candidate.left then
        left, bottom, width, height = candidate.left, candidate.bottom, candidate.width, candidate.height
    elseif frame then
        left, bottom, width, height = self:GetUsableFrameRect(frame)
    end
    local redrawWires = picker.forceVisual
    picker.forceVisual = nil
    if redrawWires then QueuePickerCandidateWires(picker); ContinuePickerCandidateWires(picker) end
    if not left or not bottom or not width or not height then
        if picker.phase == "confirm" then self:ChooseAgain(); return end
        picker.outline:Hide()
        for _, dim in ipairs(picker.scrim) do dim:Hide() end
        picker.capability:Show()
        local mapped = picker.atlas and #(picker.atlas.entries or {}) or 0
        if mapped == 0 then
            picker.title:SetText("No readable UI frames were mapped")
            picker.capability:SetText(string.format("%d frames checked · report this count", picker.atlas and picker.atlas.inspected or 0))
            picker.capability:SetTextColor(unpack(C.amber))
            picker.help:SetText("Esc: cancel")
        else
            picker.title:SetText("No UI frame under the cursor")
            picker.capability:SetText(string.format("%d frame regions mapped", mapped))
            picker.capability:SetTextColor(unpack(C.teal))
            picker.help:SetText("Move over a wireframe · Wheel: depth · Esc: cancel")
        end
        return
    end
    picker.outline:ClearAllPoints(); picker.outline:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", left - 3, bottom - 3); picker.outline:SetSize(width + 6, height + 6); picker.outline:Show()
    -- Four panels create a safe spotlight: real frames remain untouched, while
    -- the rest of the screen is gently de-emphasized during selection.
    local uiWidth, uiHeight = UIParent:GetWidth(), UIParent:GetHeight()
    local x, y, w, h = left, bottom, width, height
    local top, right = y + h, x + w
    local dims = picker.scrim
    dims[1]:ClearAllPoints(); dims[1]:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", 0, top); dims[1]:SetSize(uiWidth, math.max(0, uiHeight - top)); dims[1]:Show()
    dims[2]:ClearAllPoints(); dims[2]:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", 0, 0); dims[2]:SetSize(uiWidth, math.max(0, y)); dims[2]:Show()
    dims[3]:ClearAllPoints(); dims[3]:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", 0, y); dims[3]:SetSize(math.max(0, x), h); dims[3]:Show()
    dims[4]:ClearAllPoints(); dims[4]:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", right, y); dims[4]:SetSize(math.max(0, uiWidth - right), h); dims[4]:Show()
    if picker.phase == "confirm" then
        picker.title:SetText((picker.intent == "cinematic_keep" and "Keep visible: " or "Selected: ") .. candidate.label)
        local capability, _, tone = PickerCapability(candidate)
        picker.capability:Show(); picker.capability:SetText(capability); picker.capability:SetTextColor(unpack(C[tone] or C.accent))
        picker.help:SetText(picker.intent == "cinematic_keep" and "Confirm to keep this root visible in Cinematic Mode" or "Confirm or choose again")
    else
        local scope = candidate.isRoot == false and "inner frame" or "whole window"
        picker.title:SetText(ShortText(candidate.label, 30) .. " · " .. scope .. " · " .. picker.index .. " of " .. #picker.candidates)
        local capability, _, tone = PickerCapability(candidate)
        picker.capability:Show(); picker.capability:SetText(capability); picker.capability:SetTextColor(unpack(C[tone] or C.accent))
        picker.help:SetText("Wheel: overlapping roots  |  Click: select  |  Esc: cancel")
    end
end

function ns:CyclePicker(delta)
    local picker = self.Picker
    if picker.phase ~= "browse" then return end
    if not picker.candidates or #picker.candidates == 0 then return end
    picker.index = picker.index - delta
    if picker.index < 1 then picker.index = #picker.candidates elseif picker.index > #picker.candidates then picker.index = 1 end
    picker.forceVisual = true
    self:UpdatePicker()
end

function ns:SelectPickerCandidate()
    local picker = self.Picker
    local candidate = picker and picker.candidates and picker.candidates[picker.index]
    if not candidate or picker.phase ~= "browse" then return end
    picker.phase, picker.pendingCandidate, picker.pendingTargetID = "confirm", candidate, candidate.id
    picker.forceVisual = true
    picker.dock:SetHeight(123); picker.use:Show(); picker.again:Show()
    self:UpdatePicker()
end

function ns:ChooseAgain()
    local picker = self.Picker
    if not picker or not picker:IsShown() then return end
    picker.phase, picker.pendingTargetID, picker.pendingCandidate = "browse", nil, nil
    picker.forceVisual = true
    picker.dock:SetHeight(90); picker.use:Hide(); picker.again:Hide()
    picker.help:SetTextColor(unpack(C.muted))
    self:UpdatePicker()
end

function ns:UsePickedTarget()
    local picker = self.Picker
    local candidate = picker and picker.pendingCandidate
    if picker and picker.intent == "cinematic_keep" then
        local ok, reason
        if candidate and candidate.frame then ok, reason = self:KeepCinematicFrame(candidate.frame) end
        if not ok then
            self:ChooseAgain()
            picker.help:SetText(reason or "That frame is no longer available.")
            picker.help:SetTextColor(unpack(C.amber))
            return
        end
        picker.exitReason = "used"
        picker:Hide()
        if self.Options then self.Options:Show() end
        if self.CinematicOptions and self.CinematicOptions:IsShown() then
            self.CinematicOptions.status:SetText(reason)
            self.CinematicOptions.status:SetTextColor(unpack(C.teal))
            self:RenderCinematicOptions()
        end
        return
    end
    local targetID = candidate and candidate.id
    if candidate and candidate.frame then
        local id, reason = self:RegisterDiscoveredFrame(candidate.frame, candidate.label, true)
        if not id then
            self:ChooseAgain()
            picker.help:SetText(reason or "That frame is no longer available.")
            picker.help:SetTextColor(unpack(C.amber))
            return
        end
        targetID = id
    end
    local target = targetID and self.TargetByID[targetID]
    if not target or not self:ResolveTarget(targetID) then self:ChooseAgain(); return end
    if InCombatLockdown() then self:CancelPicker("interrupted"); return end
    picker.exitReason = "used"
    picker:Hide()
    self:AddTarget(targetID)
    self.Options.selected = targetID
    self.Options:Show()
end

function ns:CancelPicker(reason)
    if self.Picker and self.Picker:IsShown() then
        self.Picker.exitReason = reason == "cancel" and "cancel" or "interrupted"
        self.Picker:Hide()
    end
end

