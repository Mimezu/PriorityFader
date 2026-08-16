local ADDON, ns = ...
local C = ns.COLORS

local BASE_ACCENT = { C.accent[1], C.accent[2], C.accent[3], C.accent[4] }
local BASE_BORDER = { C.border[1], C.border[2], C.border[3], C.border[4] }
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

local function Backdrop(frame, color, border)
    local actualColor, actualBorder = color or C.card, border or C.border
    if actualColor == C.accent then TrackTheme(frame, "background") end
    if actualBorder == C.accent then TrackTheme(frame, "accentBorder") end
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

function ns:IsCinematicEditorTheme()
    local panel = self.Options
    return panel and (panel.cinematicView == true or self:IsCinematicActive()) or false
end

function ns:ApplyEditorTheme(force)
    local cinematic = force
    if cinematic == nil then cinematic = self:IsCinematicEditorTheme() end
    -- Cinematic is an identity cue, not a complete recolor. Keep the normal
    -- Resonance lavender controls and use warm amber only at scene boundaries.
    for index = 1, 4 do C.accent[index], C.border[index] = BASE_ACCENT[index], BASE_BORDER[index] end
    for object, roles in pairs(themeObjects) do
        if roles.text and object.SetTextColor then pcall(object.SetTextColor, object, unpack(C.accent)) end
        if roles.background and object.SetBackdropColor then pcall(object.SetBackdropColor, object, unpack(C.accent)) end
        if roles.accentBorder and object.SetBackdropBorderColor then pcall(object.SetBackdropBorderColor, object, unpack(C.accent)) end
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
        panel.cinematic:GetFontString():SetTextColor(unpack(CINEMATIC_ACCENT))
    end
    if panel and panel.subtitle then
        panel.subtitle:SetText(cinematic and "Fine-tuning Cinematic Mode - changes are live." or "Choose visible UI, then decide how present it should feel.")
        panel.subtitle:SetTextColor(unpack(cinematic and CINEMATIC_ACCENT or C.muted))
    end
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
    row.label = Text(row, "GameFontHighlight", "", C.accent); row.label:SetPoint("LEFT", 29, 0)
    row.opacity = Button(row, "", 54, nil)
    row.opacity:RegisterForClicks("LeftButtonUp", "RightButtonUp"); row.opacity:SetPoint("RIGHT", -87, 0)
    SetTooltip(row.opacity, "Opacity", "Choose a preset or drag to a precise visibility level.")
    row.requirements = Button(row, "+", 22, nil); row.requirements:SetPoint("RIGHT", row.opacity, "LEFT", -5)
    SetTooltip(row.requirements, "Requirements", "Add or remove extra conditions. All requirements must be true.")
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

local function RequirementIndex(reaction, condition)
    for index, existing in ipairs(reaction.requirements or {}) do
        if existing == condition then return index end
    end
end

function ns:CreateOptions()
    if self.Options then return end
    local panel = CreateFrame("Frame", "PriorityFaderOptions", UIParent, "BackdropTemplate")
    panel:SetSize(math.min(940, UIParent:GetWidth() - 40), math.min(610, UIParent:GetHeight() - 40))
    panel:SetPoint("CENTER")
    panel:SetFrameStrata("FULLSCREEN_DIALOG")
    panel:SetFrameLevel(500)
    panel:SetToplevel(true)
    panel:SetMovable(true)
    panel:SetResizable(true)
    panel:SetClampedToScreen(true)
    panel:EnableMouse(true)
    if panel.SetResizeBounds then panel:SetResizeBounds(760, 500, UIParent:GetWidth() - 20, UIParent:GetHeight() - 20) end
    Backdrop(panel, C.panel, C.border)
    panel:Hide()
    self.Options = panel

    -- Keep the frame being edited visible in context without changing its
    -- alpha, mouse handling, or ownership. FULLSCREEN stays below this
    -- FULLSCREEN_DIALOG options panel, so the marker never paints over the UI.
    local selectionOutline = CreateFrame("Frame", "PriorityFaderSelectionOutline", UIParent, "BackdropTemplate")
    selectionOutline:SetFrameStrata("FULLSCREEN"); selectionOutline:SetFrameLevel(850)
    selectionOutline:EnableMouse(false); selectionOutline:Hide()
    Backdrop(selectionOutline, { 0, 0, 0, 0 }, C.teal)
    selectionOutline.elapsed = 0
    selectionOutline:SetScript("OnUpdate", function(self, elapsed)
        self.elapsed = self.elapsed + elapsed
        if self.elapsed >= 0.10 then self.elapsed = 0; ns:RefreshSelectionOutline() end
    end)
    self.SelectionOutline = selectionOutline
    panel.selectionOutlineEnabled = true

    local peekBar = CreateFrame("Button", "PriorityFaderPeekBar", UIParent, "BackdropTemplate")
    peekBar:SetSize(360, 38); peekBar:SetPoint("TOP", UIParent, "TOP", 0, -22)
    peekBar:SetFrameStrata("FULLSCREEN_DIALOG"); peekBar:SetFrameLevel(520)
    peekBar:EnableMouse(true); peekBar:RegisterForClicks("LeftButtonUp"); peekBar:Hide()
    Backdrop(peekBar, C.panel, C.teal)
    peekBar.label = Text(peekBar, "GameFontHighlightSmall", "", C.teal)
    peekBar.label:SetPoint("LEFT", 12, 0); peekBar.label:SetPoint("RIGHT", -112, 0)
    peekBar.label:SetJustifyH("LEFT"); peekBar.label:SetWordWrap(false)
    peekBar.returnText = Text(peekBar, "GameFontNormal", "Return to editor", C.accent)
    peekBar.returnText:SetPoint("RIGHT", -12, 0)
    peekBar:SetScript("OnEnter", function() peekBar:SetBackdropBorderColor(unpack(C.accent)) end)
    peekBar:SetScript("OnLeave", function() peekBar:SetBackdropBorderColor(unpack(C.teal)) end)
    peekBar:SetScript("OnClick", function() ns:ExitEditorPeek() end)
    self.PeekBar = peekBar

    local header = CreateFrame("Frame", nil, panel, "BackdropTemplate")
    header:SetPoint("TOPLEFT", 12, -12); header:SetPoint("TOPRIGHT", -12, -12); header:SetHeight(62)
    Backdrop(header, NORMAL_HEADER, C.accent); panel.header = header
    header:EnableMouse(true); header:RegisterForDrag("LeftButton")
    header:SetScript("OnDragStart", function() panel:StartMoving() end)
    header:SetScript("OnDragStop", function() panel:StopMovingOrSizing() end)
    local icon = header:CreateTexture(nil, "ARTWORK")
    icon:SetSize(38, 38); icon:SetPoint("LEFT", 13, 0); icon:SetTexture("Interface\\Icons\\Spell_Mage_ArcaneOrb")
    local title = Text(header, "GameFontNormalLarge", "Priority Fader", C.accent)
    title:SetPoint("TOPLEFT", icon, "TOPRIGHT", 10, -11)
    local subtitle = Text(header, "GameFontHighlightSmall", "Choose visible UI, then decide how present it should feel.", C.muted)
    subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -4)
    panel.subtitle = subtitle
    local pick = Button(header, "Choose frame", 98, function() ns:StartPicker() end, true)
    pick:SetPoint("RIGHT", -43, 0)
    local profile = Button(header, "Profile: Default", 132, function()
        if ns:IsCinematicActive() then ns:OpenCinematicOptions() else ns:OpenProfilePicker() end
    end)
    profile:SetPoint("RIGHT", pick, "LEFT", -7, 0); profile:GetFontString():SetWidth(124); profile:GetFontString():SetWordWrap(false); panel.profile = profile
    local cinematic = Button(header, "Cinematic", 88, function()
        if panel.cinematicView then ns:CloseCinematicOptions() else ns:OpenCinematicOptions() end
    end)
    cinematic:SetPoint("RIGHT", profile, "LEFT", -7, 0); panel.cinematic = cinematic
    SetTooltip(cinematic, "Cinematic Mode", "Open the immersive scene controls. Orange identifies Cinematic settings and its fine-tuning editor.")
    local peek = Button(header, "Peek", 58, function() ns:EnterEditorPeek() end)
    peek:SetPoint("RIGHT", cinematic, "LEFT", -7, 0)
    SetTooltip(peek, "Peek at the game", "Temporarily collapses the editor while keeping the selected frame outlined. Click the small return bar to continue editing.")
    panel.peek = peek
    panel.pick = pick
    local close = CreateFrame("Button", nil, panel, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -4, -4)

    local targets = CreateFrame("Frame", nil, panel, "BackdropTemplate")
    targets:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -12); targets:SetPoint("BOTTOMLEFT", panel, "BOTTOMLEFT", 12, 48); targets:SetWidth(196)
    Backdrop(targets, C.card)
    panel.targets = targets; targets._rows = {}
    local targetsTitle = Text(targets, "GameFontNormal", "Targets", C.teal); targetsTitle:SetPoint("TOPLEFT", 12, -11)
    local managedOnly = Button(targets, "Managed", 70, function(self)
        panel.managedOnly = not panel.managedOnly
        if panel.managedOnly then
            local profileTargets = ns:Profile().targets
            local selectedSettings = panel.selected and profileTargets[panel.selected]
            if not selectedSettings or selectedSettings.enabled == false then
                panel.selected = nil
                for _, target in ipairs(ns.Targets) do
                    local settings = profileTargets[target.id]
                    if settings and settings.enabled ~= false then panel.selected = target.id; break end
                end
            end
        end
        ns:RenderOptions()
    end)
    managedOnly:SetPoint("TOPRIGHT", -10, -7)
    managedOnly:GetFontString():SetText("Managed")
    SetTooltip(managedOnly, "Managed frames only", "Shows only frames controlled by the current profile - the entries marked with the teal ON indicator. This only filters the list; it never changes your rules.")
    panel.managedOnlyButton = managedOnly
    local treeView = Button(targets, "List", 52, function()
        panel.treeView = not panel.treeView
        ns:RenderTargetRail()
    end)
    treeView:SetPoint("RIGHT", managedOnly, "LEFT", -4, 0)
    SetTooltip(treeView, "Target rail layout", "List keeps the discovery order. Tree places managed frames first and indents visibility children below their parent. In Tree mode, drag a managed card onto another to make it follow that frame.")
    panel.treeViewButton = treeView
    local add = Button(targets, "+ Pick on screen", 166, function() ns:StartPicker() end)
    add:SetPoint("TOPLEFT", 12, -36)
    local scan = Button(targets, "Discover visible UI", 166, function()
        if InCombatLockdown() then
            panel.active:SetText("Discover visible UI outside combat."); panel.active:SetTextColor(unpack(C.amber))
            return
        end
        local added, firstID = ns:DiscoverVisibleFrameRoots()
        if firstID then panel.selected = firstID end
        panel.active:SetText(added > 0 and (added .. " visible UI root" .. (added == 1 and " added. Select one to set its rules." or "s added. Select one to set its rules.")) or "Visible UI is already in your target list.")
        panel.active:SetTextColor(unpack(added > 0 and C.teal or C.muted))
        ns:RenderOptions()
    end)
    scan:SetPoint("TOPLEFT", 12, -63)
    local filter = CreateFrame("EditBox", nil, targets, "BackdropTemplate")
    filter:SetSize(166, 22); filter:SetPoint("TOPLEFT", 12, -91); filter:SetAutoFocus(false); filter:SetFontObject(GameFontHighlightSmall)
    filter:SetTextInsets(8, 8, 0, 0); filter:SetTextColor(unpack(C.accent)); TrackTheme(filter, "text"); Backdrop(filter, C.cardAlt, C.border)
    local filterHint = Text(filter, "GameFontHighlightSmall", "Filter frames...", C.muted)
    filterHint:SetPoint("LEFT", 8, 0); filter.hint = filterHint
    filter:SetScript("OnEditFocusGained", function() filterHint:Hide() end)
    filter:SetScript("OnEditFocusLost", function() if filter:GetText() == "" then filterHint:Show() end end)
    filter:SetScript("OnTextChanged", function(self)
        if self:GetText() == "" and not self:HasFocus() then filterHint:Show() else filterHint:Hide() end
        panel.targetQuery = self:GetText():lower()
        ns:RenderTargetRail()
    end)
    panel.targetFilter = filter
    local targetScroll = CreateFrame("ScrollFrame", nil, targets, "UIPanelScrollFrameTemplate")
    targetScroll:SetPoint("TOPLEFT", 8, -122); targetScroll:SetPoint("BOTTOMRIGHT", -26, 8); panel.targetScroll = targetScroll
    local targetContent = CreateFrame("Frame", nil, targetScroll)
    targetContent:SetSize(172, 1); targetScroll:SetScrollChild(targetContent)
    targetScroll:EnableMouseWheel(true)
    targetScroll:SetScript("OnMouseWheel", function(self, delta)
        self:SetVerticalScroll(math.max(0, math.min(self:GetVerticalScrollRange(), self:GetVerticalScroll() - delta * 45)))
    end)
    SkinScrollFrame(targetScroll)
    targetContent._rows = {}; panel.targetContent = targetContent

    local center = CreateFrame("Frame", nil, panel, "BackdropTemplate")
    center:SetPoint("TOPLEFT", targets, "TOPRIGHT", 10, 0); center:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -198, 48)
    Backdrop(center, C.card); panel.center = center; center._rows = {}
    local centerTitle = Text(center, "GameFontNormal", "Choose a target", C.teal); centerTitle:SetPoint("TOPLEFT", 14, -12); panel.centerTitle = centerTitle
    local active = Text(center, "GameFontHighlightSmall", "", C.muted); active:SetPoint("TOPRIGHT", -14, -14); panel.active = active
    local reactionScroll = CreateFrame("ScrollFrame", nil, center, "UIPanelScrollFrameTemplate")
    reactionScroll:SetPoint("TOPLEFT", 14, -43); reactionScroll:SetPoint("BOTTOMRIGHT", -29, 44); panel.reactionScroll = reactionScroll
    local reactionContent = CreateFrame("Frame", nil, reactionScroll)
    reactionContent:SetSize(math.max(1, center:GetWidth() - 43), 1); reactionScroll:SetScrollChild(reactionContent)
    center:SetScript("OnSizeChanged", function(_, width)
        reactionContent:SetWidth(math.max(1, width - 43))
    end)
    reactionScroll:EnableMouseWheel(true)
    reactionScroll:SetScript("OnMouseWheel", function(self, delta)
        self:SetVerticalScroll(math.max(0, math.min(self:GetVerticalScrollRange(), self:GetVerticalScroll() - delta * 45)))
    end)
    SkinScrollFrame(reactionScroll)
    reactionContent._rows = {}; panel.reactionContent = reactionContent
    panel.copyRules = Button(center, "Copy rules", 82, function()
        if not panel.selected then return end
        local ok, reason = ns:CopyTargetRules(panel.selected)
        panel.active:SetText(ok and "Rules copied" or reason); panel.active:SetTextColor(unpack(ok and C.teal or C.amber))
    end)
    panel.copyRules:SetPoint("BOTTOMRIGHT", -14, 10)
    SetTooltip(panel.copyRules, "Copy frame rules", "Copies ordered reactions, opacity, Otherwise, and fade timing to PFader's in-addon clipboard. Relationships are not copied.")
    panel.pasteRules = Button(center, "Paste rules", 82, function()
        if not panel.selected then return end
        local ok, reason = ns:PasteTargetRules(panel.selected)
        panel.active:SetText(ok and "Rules pasted" or reason); panel.active:SetTextColor(unpack(ok and C.teal or C.amber))
    end)
    panel.pasteRules:SetPoint("RIGHT", panel.copyRules, "LEFT", -7, 0)
    SetTooltip(panel.pasteRules, "Paste frame rules", "Replaces this frame's ordered reactions, opacity, Otherwise, and timing. It leaves hover and visibility relationships unchanged.")

    local presence = CreateFrame("Frame", nil, panel, "BackdropTemplate")
    presence:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -12, -86); presence:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -12, 48); presence:SetWidth(176)
    Backdrop(presence, C.card); panel.presence = presence; presence._rows = {}
    local pTitle = Text(presence, "GameFontNormal", "Presence", C.teal); pTitle:SetPoint("TOPLEFT", 12, -12)
    panel.presenceContent = CreateFrame("Frame", nil, presence); panel.presenceContent:SetPoint("TOPLEFT", 12, -41); panel.presenceContent:SetPoint("BOTTOMRIGHT", -12, 10); panel.presenceContent._rows = {}

    local note = Text(panel, "GameFontHighlightSmall", "Opacity changes are safe for supported targets; protected UI is never reconfigured in combat.", C.muted)
    note:SetPoint("BOTTOMLEFT", 18, 20)
    local reset = Button(panel, "Reset target", 98, function()
        if panel.selected then ns:RemoveTarget(panel.selected); panel.selected = nil; ns:RenderOptions() end
    end)
    reset:SetPoint("BOTTOMRIGHT", -18, 14)
    local forget
    forget = Button(panel, "Remove from list", 108, function()
        local id = panel.selected
        if not id or not ns:CanForgetCustomTarget(id) then return end
        if panel.forgetArmed ~= id then
            panel.forgetArmed = id
            panel.forgetToken = (panel.forgetToken or 0) + 1
            local token = panel.forgetToken
            forget:GetFontString():SetText("Confirm remove")
            panel.active:SetText("Removes this discovered frame, its rules, and its relationships from every profile.")
            panel.active:SetTextColor(unpack(C.amber))
            C_Timer.After(4, function()
                if panel.forgetToken == token then
                    panel.forgetArmed = nil
                    forget:GetFontString():SetText("Remove from list")
                end
            end)
            return
        end
        panel.forgetArmed = nil
        panel.forgetToken = (panel.forgetToken or 0) + 1
        local ok, reason = ns:ForgetCustomTarget(id)
        forget:GetFontString():SetText("Remove from list")
        panel.active:SetText(reason or "")
        panel.active:SetTextColor(unpack(ok and C.teal or C.amber))
        ns:RenderOptions()
    end)
    forget:SetPoint("RIGHT", reset, "LEFT", -7, 0)
    SetTooltip(forget, "Remove discovered frame", "Forgets a frame added through Pick on screen or Discover visible UI. This also removes its rules and relationships from every profile. Built-in adapters are never removed.")
    panel.forgetTarget = forget
    panel.mainFrames = { targets, center, presence, note, forget, reset }
    panel:SetScript("OnShow", function() ns:RenderOptions() end)
    panel:SetScript("OnHide", function()
        panel:StopMovingOrSizing()
        panel.forgetArmed = nil
        panel.forgetToken = (panel.forgetToken or 0) + 1
        forget:GetFontString():SetText("Remove from list")
        if ns.ReactionPalette and ns.ReactionPalette:IsShown() then ns.ReactionPalette:Hide() end
        if ns.ConnectionPicker and ns.ConnectionPicker:IsShown() then ns.ConnectionPicker:Hide() end
        if ns.OpacityPicker and ns.OpacityPicker:IsShown() then ns.OpacityPicker:Hide() end
        if ns.DurationPicker and ns.DurationPicker:IsShown() then ns.DurationPicker:Hide() end
        if ns.TimingPicker and ns.TimingPicker:IsShown() then ns.TimingPicker:Hide() end
        if ns.ProfilePicker and ns.ProfilePicker:IsShown() then ns.ProfilePicker:Hide() end
        if ns.ProfileDeleteConfirm and ns.ProfileDeleteConfirm:IsShown() then ns.ProfileDeleteConfirm:Hide() end
        if ns.ProfileTransfer and ns.ProfileTransfer:IsShown() then ns.ProfileTransfer:Hide() end
        if ns.CinematicModePicker and ns.CinematicModePicker:IsShown() then ns.CinematicModePicker:Hide() end
        if ns.CinematicKeyCapture and ns.CinematicKeyCapture:IsShown() then ns.CinematicKeyCapture:Hide() end
        if ns.SelectionOutline and not panel.peeking then ns.SelectionOutline:Hide() end
        ns:StopPreview()
        ns:CancelReactionDrag()
        if panel.peeking then ns:RefreshSelectionOutline() end
        if not panel.peeking then ns:ApplyEditorTheme(false) end
    end)
    table.insert(UISpecialFrames, panel:GetName())
end

function ns:ToggleOptions()
    self:CreateOptions()
    if self.Options.peeking then
        self:ExitEditorPeek()
    elseif self.Options:IsVisible() then
        self.Options:Hide()
    else
        self.Options:Show()
    end
end

function ns:EnterEditorPeek()
    local panel, bar = self.Options, self.PeekBar
    if not panel or not panel:IsVisible() or not bar then return end
    panel.peeking = true
    local target = panel.selected and self.TargetByID[panel.selected]
    bar.label:SetText("Viewing: " .. (target and target.label or "game UI"))
    bar:Show()
    panel:Hide()
    self:RefreshSelectionOutline()
end

function ns:ExitEditorPeek()
    local panel = self.Options
    if not panel or not panel.peeking then return end
    panel.peeking = nil
    if self.PeekBar then self.PeekBar:Hide() end
    panel:Show()
end

function ns:RefreshOptions()
    if self.Options and self.Options:IsVisible() then self:RenderOptions() end
end

local CINEMATIC_MODE_OPTIONS = {
    eui_player = { "context_hover", "target_hover", "combat_hover", "combat", "hover", "untouched" },
    eui_target = { "context_hover", "target_hover", "combat_hover", "combat", "hover", "untouched" },
    eui_main = { "combat_hover", "combat", "hover", "untouched" },
    eui_castbar = { "casting", "combat_hover", "combat", "hover", "untouched" },
    eui_resourcebars = { "combat", "combat_hover", "hover", "untouched" },
    minimap = { "hover", "untouched" },
    objectives = { "quest_hover", "hover", "untouched" },
    chat = { "loot_hover", "hover", "untouched" },
}

local function CinematicBindingText()
    local key = ns:GetCinematicBinding()
    if not key then return "Set shortcut" end
    return (GetBindingText and GetBindingText(key, "KEY_") or key) or key
end

local function CinematicKeyChord(key)
    if key == "ESCAPE" or key == "LALT" or key == "RALT" or key == "LCTRL" or key == "RCTRL" or key == "LSHIFT" or key == "RSHIFT" then return nil end
    local prefix = ""
    if IsShiftKeyDown and IsShiftKeyDown() then prefix = prefix .. "SHIFT-" end
    if IsControlKeyDown and IsControlKeyDown() then prefix = prefix .. "CTRL-" end
    if IsAltKeyDown and IsAltKeyDown() then prefix = prefix .. "ALT-" end
    return prefix .. key
end

function ns:CreateCinematicKeyCapture()
    if self.CinematicKeyCapture then return end
    local blocker = CreateFrame("Button", nil, self.Options, "BackdropTemplate")
    blocker:SetAllPoints(self.Options); blocker:SetFrameLevel(610); blocker:EnableMouse(true); blocker:RegisterForClicks("AnyUp")
    blocker:SetScript("OnClick", function() if ns.CinematicKeyCapture then ns.CinematicKeyCapture:Hide() end end)
    Backdrop(blocker, { 0, 0, 0, 0.48 }, { 0, 0, 0, 0 }); blocker:Hide()
    local capture = CreateFrame("Frame", "PriorityFaderCinematicKey", self.Options, "BackdropTemplate")
    capture:SetSize(330, 152); capture:SetFrameStrata("FULLSCREEN_DIALOG"); capture:SetFrameLevel(611); capture:EnableMouse(true); capture:EnableKeyboard(true)
    if capture.SetPropagateKeyboardInput then capture:SetPropagateKeyboardInput(false) end
    Backdrop(capture, C.panel, C.accent); capture:Hide(); capture.blocker = blocker; self.CinematicKeyCapture = capture
    table.insert(UISpecialFrames, capture:GetName())
    local title = Text(capture, "GameFontNormal", "Set Cinematic shortcut", C.accent); title:SetPoint("TOPLEFT", 14, -13)
    capture.copy = Text(capture, "GameFontHighlightSmall", "Press a key combination. Escape cancels. Any existing action on that shortcut will be replaced.", C.muted)
    capture.copy:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -6); capture.copy:SetPoint("RIGHT", -14, 0); capture.copy:SetJustifyH("LEFT"); capture.copy:SetWordWrap(true)
    capture.status = Text(capture, "GameFontHighlightSmall", "Waiting for a shortcut…", C.teal); capture.status:SetPoint("BOTTOMLEFT", 14, 16)
    local cancel = Button(capture, "Cancel", 70, function() capture:Hide() end); cancel:SetPoint("BOTTOMRIGHT", -12, 12)
    capture.use = Button(capture, "Use shortcut", 94, function()
        if capture.pending == nil then return end
        local ok, reason = ns:SetCinematicBinding(capture.pending or nil)
        if ok then capture:Hide(); ns:RenderCinematicOptions() else capture.status:SetText(reason); capture.status:SetTextColor(unpack(C.amber)) end
    end, true); capture.use:SetPoint("RIGHT", cancel, "LEFT", -7, 0); capture.use:Hide(); capture.status:SetPoint("RIGHT", capture.use, "LEFT", -8, 0); capture.status:SetWordWrap(true)
    capture:SetScript("OnKeyDown", function(_, key)
        if key == "ESCAPE" then capture:Hide(); return end
        if key == "BACKSPACE" or key == "DELETE" then
            capture.pending = false; capture.use:GetFontString():SetText("Clear shortcut"); capture.use:Show()
            capture.status:SetText("Clear the Cinematic shortcut?"); capture.status:SetTextColor(unpack(C.amber)); return
        end
        local chord = CinematicKeyChord(key)
        if not chord then return end
        capture.pending = chord; capture.use:GetFontString():SetText("Use shortcut"); capture.use:Show()
        local occupied = GetBindingAction and GetBindingAction(chord)
        local extra = occupied and occupied ~= "" and " It currently belongs to " .. occupied .. " and will be replaced." or ""
        local display = (GetBindingText and GetBindingText(chord, "KEY_") or chord) or chord
        capture.status:SetText("Use " .. display .. "?" .. extra); capture.status:SetTextColor(unpack(occupied and C.amber or C.teal))
    end)
    capture:SetScript("OnHide", function()
        capture.blocker:Hide()
        if not InCombatLockdown() then capture:EnableKeyboard(false) end
        capture.pending = nil; capture.use:Hide()
    end)
end

function ns:OpenCinematicKeyCapture()
    if InCombatLockdown() then
        if self.CinematicOptions then self.CinematicOptions.status:SetText("Change shortcuts outside combat."); self.CinematicOptions.status:SetTextColor(unpack(C.amber)) end
        return
    end
    self:CreateCinematicKeyCapture()
    local capture = self.CinematicKeyCapture
    capture.status:SetText("Waiting for a shortcut…"); capture.status:SetTextColor(unpack(C.teal))
    capture.status:SetText("Waiting for a shortcut...")
    capture:ClearAllPoints(); capture:SetPoint("CENTER", self.Options, "CENTER", 0, 0)
    capture.blocker:Show(); capture:Show(); capture:EnableKeyboard(true)
end

function ns:CreateCinematicModePicker()
    if self.CinematicModePicker then return end
    local blocker = CreateFrame("Button", nil, self.Options, "BackdropTemplate")
    blocker:SetAllPoints(self.Options); blocker:SetFrameLevel(606); blocker:EnableMouse(true); blocker:RegisterForClicks("AnyUp")
    blocker:SetScript("OnClick", function() if ns.CinematicModePicker then ns.CinematicModePicker:Hide() end end)
    Backdrop(blocker, { 0, 0, 0, 0.38 }, { 0, 0, 0, 0 }); blocker:Hide()
    local picker = CreateFrame("Frame", "PriorityFaderCinematicModes", self.Options, "BackdropTemplate")
    picker:SetSize(300, 250); picker:SetFrameStrata("FULLSCREEN_DIALOG"); picker:SetFrameLevel(607); picker:EnableMouse(true)
    Backdrop(picker, C.panel, C.accent); picker:Hide(); picker.blocker = blocker; picker.buttons = {}; self.CinematicModePicker = picker
    table.insert(UISpecialFrames, picker:GetName())
    picker.title = Text(picker, "GameFontNormal", "", C.accent); picker.title:SetPoint("TOPLEFT", 14, -13)
    picker.copy = Text(picker, "GameFontHighlightSmall", "Choose how this component appears in Cinematic Mode.", C.muted); picker.copy:SetPoint("TOPLEFT", picker.title, "BOTTOMLEFT", 0, -4); picker.copy:SetPoint("RIGHT", -14, 0); picker.copy:SetJustifyH("LEFT"); picker.copy:SetWordWrap(true)
    picker.close = Button(picker, "x", 22, function() picker:Hide() end); picker.close:SetPoint("TOPRIGHT", -9, -9)
    picker:SetScript("OnHide", function() picker.blocker:Hide(); picker.component = nil end)
end

function ns:OpenCinematicModePicker(component)
    self:CreateCinematicModePicker()
    local picker = self.CinematicModePicker
    picker.component = component
    picker.confirmMode = nil
    picker.copy:SetText("Choose how this component appears in Cinematic Mode."); picker.copy:SetTextColor(unpack(C.muted))
    picker.title:SetText(component.label)
    for _, button in ipairs(picker.buttons) do button:Hide() end
    local current = self:GetCinematicComponentMode(component.id)
    for index, mode in ipairs(CINEMATIC_MODE_OPTIONS[component.id] or {}) do
        local modeID = mode
        local button = picker.buttons[index]
        if not button then button = Button(picker, "", 264, nil); picker.buttons[index] = button end
        local selected = modeID == current
        button:Show(); button:ClearAllPoints(); button:SetPoint("TOPLEFT", 18, -65 - (index - 1) * 31)
        button._selected, button._selectedColor = selected, C.teal; button:SetBackdropColor(unpack(selected and C.teal or C.cardAlt))
        button:GetFontString():SetText(ns.CINEMATIC_MODE_LABELS[modeID]); button:GetFontString():SetTextColor(unpack(selected and { 0.02, 0.06, 0.07, 1 } or C.accent))
        button:SetScript("OnClick", function()
            if current == "custom" and picker.confirmMode ~= modeID then
                picker.confirmMode = modeID
                picker.copy:SetText("This replaces your fine-tuned rules. Click the same mode again to confirm.")
                picker.copy:SetTextColor(unpack(C.amber))
                return
            end
            local ok, reason = ns:SetCinematicComponentMode(component.id, modeID)
            if ok then picker:Hide(); ns:RenderCinematicOptions() else picker.copy:SetText(reason); picker.copy:SetTextColor(unpack(C.amber)) end
        end)
    end
    picker:ClearAllPoints(); picker:SetPoint("CENTER", self.Options, "CENTER", 0, 0)
    picker.blocker:Show(); picker:Show()
end

function ns:CreateCinematicOptions()
    if self.CinematicOptions then return end
    local page = CreateFrame("Frame", "PriorityFaderCinematicOptions", self.Options, "BackdropTemplate")
    page:SetPoint("TOPLEFT", self.Options, "TOPLEFT", 12, -86); page:SetPoint("BOTTOMRIGHT", self.Options, "BOTTOMRIGHT", -12, 48)
    Backdrop(page, C.card); page:Hide(); self.CinematicOptions = page
    page.title = Text(page, "GameFontNormalLarge", "Cinematic Mode", C.accent); page.title:SetPoint("TOPLEFT", 16, -14)
    page.copy = Text(page, "GameFontHighlightSmall", "A screen-clearing questing view. Hold Alt for a quick reveal; Keep a frame opens the scene for visual selection.", C.muted); page.copy:SetPoint("TOPLEFT", page.title, "BOTTOMLEFT", 0, -4)
    page.toggle = Button(page, "", 106, function()
        local ok, reason = ns:ToggleCinematic()
        page.status:SetText(ok and (ns:IsCinematicActive() and "Cinematic Mode on." or "Returned to your previous profile.") or reason)
        page.status:SetTextColor(unpack(ok and C.teal or C.amber)); ns:RenderCinematicOptions()
    end, true); page.toggle:SetPoint("TOPRIGHT", -16, -15)
    page.shortcut = Button(page, "", 138, function() ns:OpenCinematicKeyCapture() end); page.shortcut:SetPoint("TOPRIGHT", page.toggle, "BOTTOMLEFT", 0, -7)
    page.clear = Button(page, "Clear", 48, function()
        local ok, reason = ns:SetCinematicBinding(nil)
        page.status:SetText(ok and "Cinematic shortcut cleared." or reason); page.status:SetTextColor(unpack(ok and C.teal or C.amber)); ns:RenderCinematicOptions()
    end); page.clear:SetPoint("RIGHT", page.shortcut, "LEFT", -6, 0)
    local scene = CreateFrame("Frame", nil, page, "BackdropTemplate"); scene:SetPoint("TOPLEFT", 16, -79); scene:SetPoint("BOTTOMLEFT", 16, 55); scene:SetWidth(390); Backdrop(scene, C.cardAlt, C.border); page.scene = scene
    local sceneTitle = Text(scene, "GameFontNormal", "Scene visibility", C.teal); sceneTitle:SetPoint("TOPLEFT", 12, -11)
    local sceneCopy = Text(scene, "GameFontHighlightSmall", "Pick plain-language modes, or fine-tune the Cinematic profile when you need exact ordered rules.", C.muted); sceneCopy:SetPoint("TOPLEFT", sceneTitle, "BOTTOMLEFT", 0, -3); sceneCopy:SetPoint("RIGHT", -12, 0); sceneCopy:SetWordWrap(true)
    page.rows = {}
    for index, component in ipairs(ns.CINEMATIC_COMPONENTS) do
        local componentData = component
        local row = CreateFrame("Frame", nil, scene, "BackdropTemplate"); row:SetHeight(26); row:SetPoint("TOPLEFT", 10, -57 - (index - 1) * 28); row:SetPoint("TOPRIGHT", -10, -57 - (index - 1) * 28); Backdrop(row, C.card)
        row.label = Text(row, "GameFontHighlightSmall", componentData.label, C.accent); row.label:SetPoint("LEFT", 9, 0)
        row.mode = Button(row, "", 126, function() ns:OpenCinematicModePicker(componentData) end); row.mode:SetPoint("RIGHT", -6, 0)
        page.rows[index] = row
    end
    local kept = CreateFrame("Frame", nil, page, "BackdropTemplate"); kept:SetPoint("TOPLEFT", scene, "TOPRIGHT", 12, 0); kept:SetPoint("TOPRIGHT", -16, -79); kept:SetHeight(122); Backdrop(kept, C.cardAlt, C.border)
    local keptTitle = Text(kept, "GameFontNormal", "Always left alone", C.teal); keptTitle:SetPoint("TOPLEFT", 12, -11)
    local keptCopy = Text(kept, "GameFontHighlightSmall", "Enemy nameplates, quick-action palettes (OPie or Quickdraw), loot displays, quest conversations (DialogueUI or Blizzard), tooltips, and essential dialogs stay visible. Priority Fader never reparents or restyles them.", C.muted); keptCopy:SetPoint("TOPLEFT", keptTitle, "BOTTOMLEFT", 0, -5); keptCopy:SetPoint("RIGHT", -12, 0); keptCopy:SetJustifyH("LEFT"); keptCopy:SetWordWrap(true)
    local future = CreateFrame("Frame", nil, page, "BackdropTemplate"); future:SetPoint("TOPLEFT", kept, "BOTTOMLEFT", 0, -12); future:SetPoint("TOPRIGHT", -16, 0); future:SetHeight(92); Backdrop(future, C.cardAlt, C.border)
    local futureTitle = Text(future, "GameFontNormal", "Other visible UI", C.teal); futureTitle:SetPoint("TOPLEFT", 12, -11)
    future.copy = Text(future, "GameFontHighlightSmall", "Blackout watches eligible UI branches, including addon windows that appear later. Rescan forces an immediate refresh.", C.muted); future.copy:SetPoint("TOPLEFT", futureTitle, "BOTTOMLEFT", 0, -5); future.copy:SetPoint("RIGHT", -12, 0); future.copy:SetJustifyH("LEFT"); future.copy:SetWordWrap(true)
    future.rescan = Button(future, "Rescan", 64, function() ns:BeginCinematicBlackout(); ns:RenderCinematicOptions() end); future.rescan:SetPoint("BOTTOMRIGHT", -10, 9)
    future.keep = Button(future, "Keep a frame", 88, function() ns:StartPicker("cinematic_keep") end, true); future.keep:SetPoint("RIGHT", future.rescan, "LEFT", -6, 0)
    future.clear = Button(future, "Clear keeps", 76, function() ns:ClearCinematicKeeps(); ns:RenderCinematicOptions() end); future.clear:SetPoint("RIGHT", future.keep, "LEFT", -6, 0)
    page.blackout = future
    page.status = Text(page, "GameFontHighlightSmall", "", C.muted); page.status:SetPoint("BOTTOMLEFT", 16, 16); page.status:SetPoint("RIGHT", -230, 16); page.status:SetJustifyH("LEFT")
    page.advanced = Button(page, "Fine-tune profile", 124, function()
        if not ns:IsCinematicActive() then
            local ok, reason = ns:ToggleCinematic()
            if not ok then
                page.status:SetText(reason or "Cinematic Mode could not be enabled for live fine-tuning."); page.status:SetTextColor(unpack(C.amber))
                return
            end
        end
        ns:CloseCinematicOptions()
    end)
    SetTooltip(page.advanced, "Fine-tune Cinematic profile", "Opens the normal ordered-rule editor on the live Cinematic profile. If Cinematic is off, it is turned on first so you cannot accidentally edit another profile.")
    page.reset = Button(page, "Reset defaults", 106, function()
        if not page.resetArmed then
            page.resetArmed = true; page.resetToken = (page.resetToken or 0) + 1; local token = page.resetToken; page.reset:GetFontString():SetText("Confirm reset")
            page.status:SetText("Reset replaces your Cinematic scene settings. Click Confirm reset to continue."); page.status:SetTextColor(unpack(C.amber))
            C_Timer.After(5, function()
                if page.resetToken == token then page.resetArmed = nil; page.reset:GetFontString():SetText("Reset defaults") end
            end)
            return
        end
        page.resetArmed = nil; page.resetToken = (page.resetToken or 0) + 1; page.reset:GetFontString():SetText("Reset defaults")
        ns:ResetCinematicProfile(); page.status:SetText("Cinematic defaults restored."); page.status:SetTextColor(unpack(C.teal)); ns:RenderCinematicOptions()
    end); page.reset:SetPoint("BOTTOMRIGHT", -14, 12)
    page.advanced:SetPoint("RIGHT", page.reset, "LEFT", -7, 0)
    page:SetScript("OnHide", function() page.resetArmed = nil; page.resetToken = (page.resetToken or 0) + 1; page.reset:GetFontString():SetText("Reset defaults") end)
end

function ns:OpenCinematicOptions()
    self:CreateOptions(); self:CreateCinematicOptions()
    local panel = self.Options
    local page = self.CinematicOptions
    if not panel or not page then return end
    panel.cinematicView = true
    page.resetArmed = nil
    page.reset:GetFontString():SetText("Reset defaults")
    for _, frame in ipairs(panel.mainFrames or {}) do frame:Hide() end
    panel.pick:Hide(); panel.profile:Hide()
    panel.cinematic:SetWidth(104); panel.cinematic:GetFontString():SetText("Back to editor")
    page:Show()
    self:ApplyEditorTheme(true)
    self:RenderCinematicOptions()
end

function ns:CloseCinematicOptions()
    local panel = self.Options
    if not panel or not panel.cinematicView then return end
    panel.cinematicView = false
    if self.CinematicOptions then self.CinematicOptions:Hide() end
    for _, frame in ipairs(panel.mainFrames or {}) do frame:Show() end
    panel.pick:Show(); panel.profile:Show()
    panel.cinematic:SetWidth(88); panel.cinematic:GetFontString():SetText("Cinematic")
    self:ApplyEditorTheme()
    self:RenderOptions()
end

function ns:RenderCinematicOptions()
    local page = self.CinematicOptions
    if not page or not page:IsShown() then return end
    local active = self:IsCinematicActive()
    self:ApplyEditorTheme(true)
    page.title:SetTextColor(unpack(CINEMATIC_ACCENT))
    page.advanced:SetBackdropBorderColor(unpack(CINEMATIC_ACCENT)); page.advanced:GetFontString():SetTextColor(unpack(CINEMATIC_ACCENT))
    page.toggle:GetFontString():SetText(active and "Cinematic: On" or "Cinematic: Off")
    page.toggle._selected, page.toggle._selectedColor = active, CINEMATIC_ACCENT
    page.toggle:SetBackdropBorderColor(unpack(CINEMATIC_ACCENT))
    page.toggle:SetBackdropColor(unpack(active and CINEMATIC_ACCENT or C.cardAlt)); page.toggle:GetFontString():SetTextColor(unpack(active and { 0.10, 0.035, 0.01, 1 } or CINEMATIC_ACCENT))
    page.shortcut:GetFontString():SetText("Shortcut: " .. CinematicBindingText())
    if not page.resetArmed then page.reset:GetFontString():SetText("Reset defaults") end
    for index, component in ipairs(ns.CINEMATIC_COMPONENTS) do
        local mode = self:GetCinematicComponentMode(component.id)
        local row = page.rows[index]
        row.mode:GetFontString():SetText(ns.CINEMATIC_MODE_LABELS[mode] or "Custom rules")
        row.mode._selected, row.mode._selectedColor = false, nil
        row.mode:SetBackdropColor(unpack(C.cardAlt))
        row.mode:SetBackdropBorderColor(unpack(mode ~= "untouched" and C.teal or C.border))
        row.mode:GetFontString():SetTextColor(unpack(mode ~= "untouched" and C.teal or C.muted))
    end
    if page.blackout and page.blackout.copy then
        local blacked = self.runtime.cinematicBlackoutCount or 0
        local keeps = self:GetCinematicKeepCount()
        page.blackout.copy:SetText(blacked .. " UI branch" .. (blacked == 1 and " is" or "es are") .. " blacked out · " .. keeps .. " custom exception" .. (keeps == 1 and "" or "s") .. ". Keep a frame reveals the scene while you choose.")
    end
    if page.status:GetText() == "" then
        page.status:SetText(active and "Cinematic profile is live. Hold Alt to reveal configured scene frames." or "Configure the scene now; it applies the next time you turn Cinematic Mode on.")
        page.status:SetTextColor(unpack(C.muted))
    end
end

function ns:CreateReactionDrag()
    if self.ReactionDrag then return end
    local drag = CreateFrame("Frame", nil, self.Options)
    drag:SetAllPoints(self.Options); drag:SetFrameLevel(575); drag:EnableMouse(false); drag:Hide()
    drag.line = CreateFrame("Frame", nil, drag, "BackdropTemplate")
    drag.line:SetHeight(2); drag.line:EnableMouse(false); Backdrop(drag.line, C.teal, C.teal); drag.line:Hide()
    drag:SetScript("OnUpdate", function() ns:UpdateReactionDrag() end)
    self.ReactionDrag = drag
end

function ns:StartReactionDrag(id, reaction, row)
    if not self.Options or not self.Options:IsVisible() then return end
    local settings = self:GetTargetSettings(id)
    if not settings then return end
    local sourceIndex
    for index, candidate in ipairs(settings.reactions) do
        if candidate == reaction then sourceIndex = index; break end
    end
    if not sourceIndex then return end
    self:CreateReactionDrag()
    local drag = self.ReactionDrag
    if drag.active then self:CancelReactionDrag() end
    drag.active, drag.targetID, drag.reaction, drag.row = true, id, reaction, row
    drag.sourceIndex, drag.insertIndex = sourceIndex, sourceIndex
    row:SetAlpha(0.42); drag:Show(); self:UpdateReactionDrag()
end

function ns:UpdateReactionDrag()
    local drag = self.ReactionDrag
    if not drag or not drag.active then return end
    local panel = self.Options
    local settings = self:GetTargetSettings(drag.targetID)
    if not panel or not panel:IsVisible() or not settings then self:CancelReactionDrag(); return end
    local rows, count = panel.reactionContent._reactionRows or {}, #settings.reactions
    local _, cursorY = GetCursorPosition()
    cursorY = cursorY / UIParent:GetEffectiveScale()
    local insertIndex = count + 1
    for index = 1, count do
        local centerY
        if rows[index] then
            local _, value = rows[index]:GetCenter()
            centerY = value
        end
        if centerY and cursorY > centerY then insertIndex = index; break end
    end
    if drag.insertIndex == insertIndex and drag.line:IsShown() then return end
    drag.insertIndex = insertIndex
    local anchor = rows[math.min(insertIndex, count)]
    if not anchor then drag.line:Hide(); return end
    drag.line:ClearAllPoints()
    if insertIndex <= count then
        drag.line:SetPoint("TOPLEFT", anchor, "TOPLEFT", 1, 1); drag.line:SetPoint("TOPRIGHT", anchor, "TOPRIGHT", -1, 1)
    else
        drag.line:SetPoint("BOTTOMLEFT", anchor, "BOTTOMLEFT", 1, -1); drag.line:SetPoint("BOTTOMRIGHT", anchor, "BOTTOMRIGHT", -1, -1)
    end
    drag.line:Show()
end

function ns:CancelReactionDrag()
    local drag = self.ReactionDrag
    if not drag then return end
    if drag.row then drag.row:SetAlpha(1) end
    drag.active, drag.targetID, drag.reaction, drag.row = nil, nil, nil, nil
    drag.sourceIndex, drag.insertIndex = nil, nil
    drag.line:Hide(); drag:Hide()
end

function ns:FinishReactionDrag()
    local drag = self.ReactionDrag
    if not drag or not drag.active then return end
    local targetID, reaction, sourceIndex, insertIndex = drag.targetID, drag.reaction, drag.sourceIndex, drag.insertIndex
    self:CancelReactionDrag()
    local settings = self:GetTargetSettings(targetID)
    if not settings then return end
    for index, candidate in ipairs(settings.reactions) do
        if candidate == reaction then sourceIndex = index; break end
    end
    if not sourceIndex or not insertIndex then return end
    table.remove(settings.reactions, sourceIndex)
    if insertIndex > sourceIndex then insertIndex = insertIndex - 1 end
    insertIndex = math.max(1, math.min(#settings.reactions + 1, insertIndex))
    table.insert(settings.reactions, insertIndex, reaction)
    self:InvalidateTargetTransition(targetID)
    if self.Options and self.Options:IsVisible() and self.Options.selected == targetID then self:RenderSelectedTarget(targetID) end
end

function ns:CreatePreview()
    if self.Preview then return end
    local preview = CreateFrame("Frame", "PriorityFaderPreview", UIParent)
    preview:SetAllPoints(UIParent); preview:SetFrameStrata("FULLSCREEN_DIALOG"); preview:SetFrameLevel(880)
    preview:EnableMouse(false); preview:Hide(); preview.outlines, preview.token = {}, 0
    self.Preview = preview
end

function ns:StopPreview()
    local preview = self.Preview
    if not preview then return end
    preview.token = preview.token + 1
    for _, outline in ipairs(preview.outlines) do outline:Hide() end
    preview:Hide()
end

function ns:PreviewTarget(id)
    if InCombatLockdown() then
        if self.Options and self.Options.active then
            self.Options.active:SetText("Preview is unavailable during combat")
            self.Options.active:SetTextColor(unpack(C.amber))
        end
        return
    end
    if not self.TargetByID[id] then return end
    self:CreatePreview()
    local preview = self.Preview
    self:StopPreview()
    local kinds = { [id] = "selected" }
    local _, group = self:GetRevealGroup(id)
    for memberID in pairs(group and group.members or {}) do kinds[memberID] = memberID == id and "selected" or "group" end
    for childID in pairs(self:GetLinkedChildren(id)) do kinds[childID] = "child" end
    for _, parentID in ipairs(self:GetLinkParents(id)) do
        if not kinds[parentID] then kinds[parentID] = "parent" end
    end
    local visible, total = 0, 0
    local tones = { selected = C.accent, group = C.teal, child = C.teal, parent = C.amber }
    for _, target in ipairs(self.Targets) do
        local kind = kinds[target.id]
        if kind then
            total = total + 1
            local frame = self:ResolveTarget(target.id)
            local left, bottom, width, height
            if frame then left, bottom, width, height = self:GetUsableFrameRect(frame) end
            if left then
                visible = visible + 1
                local outline = preview.outlines[visible]
                if not outline then
                    outline = CreateFrame("Frame", nil, preview, "BackdropTemplate")
                    Backdrop(outline, { 0, 0, 0, 0 }, tones[kind] or C.teal)
                    preview.outlines[visible] = outline
                end
                outline:SetBackdropBorderColor(unpack(tones[kind] or C.teal))
                outline:ClearAllPoints(); outline:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", left - 3, bottom - 3)
                outline:SetSize(width + 6, height + 6); outline:Show()
            end
        end
    end
    if visible == 0 then
        if self.Options and self.Options.active then
            self.Options.active:SetText("No visible frame is available to preview")
            self.Options.active:SetTextColor(unpack(C.amber))
        end
        return
    end
    preview:Show()
    local token = preview.token
    C_Timer.After(2.2, function()
        if ns.Preview == preview and preview.token == token then ns:StopPreview() end
    end)
    if self.Options and self.Options.active then
        local label = visible == 1 and "frame" or "frames"
        local missing = total - visible
        self.Options.active:SetText("Previewing " .. visible .. " " .. label .. " for 2 seconds" .. (missing > 0 and " (" .. missing .. " unavailable)" or ""))
        self.Options.active:SetTextColor(unpack(C.teal))
    end
end

function ns:CreateProfilePicker()
    if self.ProfilePicker then return end
    local blocker = CreateFrame("Button", nil, self.Options, "BackdropTemplate")
    blocker:SetAllPoints(self.Options); blocker:SetFrameLevel(590); blocker:EnableMouse(true); blocker:RegisterForClicks("AnyUp")
    blocker:SetScript("OnClick", function() if ns.ProfilePicker then ns.ProfilePicker:Hide() end end)
    Backdrop(blocker, { 0, 0, 0, 0.30 }, { 0, 0, 0, 0 }); blocker:Hide()
    local picker = CreateFrame("Frame", "PriorityFaderProfiles", self.Options, "BackdropTemplate")
    picker:SetSize(382, 356); picker:SetFrameStrata("FULLSCREEN_DIALOG"); picker:SetFrameLevel(591); picker:EnableMouse(true)
    Backdrop(picker, C.panel, C.accent); picker:Hide(); picker.blocker = blocker; self.ProfilePicker = picker
    table.insert(UISpecialFrames, picker:GetName())
    picker.title = Text(picker, "GameFontNormal", "Profiles", C.accent); picker.title:SetPoint("TOPLEFT", 14, -13)
    picker.copy = Text(picker, "GameFontHighlightSmall", "Switch instantly, or create a copy of the active setup.", C.muted); picker.copy:SetPoint("TOPLEFT", picker.title, "BOTTOMLEFT", 0, -3)
    picker.export = Button(picker, "Export", 58, function() ns:OpenProfileTransfer("export") end); picker.export:SetPoint("TOPRIGHT", -43, -11)
    picker.import = Button(picker, "Import", 58, function() ns:OpenProfileTransfer("import") end); picker.import:SetPoint("RIGHT", picker.export, "LEFT", -5, 0)
    local close = Button(picker, "x", 22, function() picker:Hide() end); close:SetPoint("TOPRIGHT", -9, -9)
    local scroll = CreateFrame("ScrollFrame", nil, picker, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 14, -61); scroll:SetPoint("BOTTOMRIGHT", -29, 68); picker.scroll = scroll
    local content = CreateFrame("Frame", nil, scroll); content:SetSize(326, 1); scroll:SetScrollChild(content); content._rows = {}; picker.content = content
    scroll:EnableMouseWheel(true)
    scroll:SetScript("OnMouseWheel", function(self, delta)
        self:SetVerticalScroll(math.max(0, math.min(self:GetVerticalScrollRange(), self:GetVerticalScroll() - delta * 42)))
    end)
    SkinScrollFrame(scroll)
    picker.name = CreateFrame("EditBox", nil, picker, "BackdropTemplate")
    picker.name:SetSize(220, 22); picker.name:SetPoint("BOTTOMLEFT", 14, 18); picker.name:SetAutoFocus(false); picker.name:SetFontObject(GameFontHighlightSmall)
    picker.name:SetTextInsets(8, 8, 0, 0); Backdrop(picker.name, C.cardAlt, C.border); picker.name:SetTextColor(unpack(C.accent)); TrackTheme(picker.name, "text")
    picker.create = Button(picker, "Create copy", 106, function()
        local ok, reason = ns:CreateProfile(picker.name:GetText())
        if ok then picker:Hide() else picker.status:SetText(reason); picker.status:SetTextColor(unpack(C.amber)) end
    end, true)
    picker.create:SetPoint("LEFT", picker.name, "RIGHT", 8, 0)
    picker.name:SetScript("OnEnterPressed", function() picker.create:Click() end)
    picker.name:SetScript("OnEscapePressed", function() picker.name:ClearFocus() end)
    picker.status = Text(picker, "GameFontHighlightSmall", "", C.muted); picker.status:SetPoint("BOTTOMLEFT", 14, 4); picker.status:SetPoint("RIGHT", -14, 4); picker.status:SetJustifyH("LEFT")
    picker:SetScript("OnHide", function()
        picker.blocker:Hide(); picker.name:ClearFocus(); picker.name:SetText("")
        if ns.ProfileDeleteConfirm and ns.ProfileDeleteConfirm:IsShown() then ns.ProfileDeleteConfirm:Hide() end
        if ns.ProfileTransfer and ns.ProfileTransfer:IsShown() then ns.ProfileTransfer:Hide() end
    end)
end

function ns:CreateProfileTransfer()
    if self.ProfileTransfer then return end
    local blocker = CreateFrame("Button", nil, self.Options, "BackdropTemplate")
    blocker:SetAllPoints(self.Options); blocker:SetFrameLevel(594); blocker:EnableMouse(true); blocker:RegisterForClicks("AnyUp")
    blocker:SetScript("OnClick", function() if ns.ProfileTransfer then ns.ProfileTransfer:Hide() end end)
    Backdrop(blocker, { 0, 0, 0, 0.46 }, { 0, 0, 0, 0 }); blocker:Hide()
    local transfer = CreateFrame("Frame", "PriorityFaderProfileTransfer", self.Options, "BackdropTemplate")
    transfer:SetSize(470, 378); transfer:SetFrameStrata("FULLSCREEN_DIALOG"); transfer:SetFrameLevel(595); transfer:EnableMouse(true)
    Backdrop(transfer, C.panel, C.accent); transfer:Hide(); transfer.blocker = blocker; self.ProfileTransfer = transfer
    table.insert(UISpecialFrames, transfer:GetName())
    transfer.title = Text(transfer, "GameFontNormal", "", C.accent); transfer.title:SetPoint("TOPLEFT", 14, -13)
    transfer.copy = Text(transfer, "GameFontHighlightSmall", "", C.muted); transfer.copy:SetPoint("TOPLEFT", transfer.title, "BOTTOMLEFT", 0, -3)
    local close = Button(transfer, "x", 22, function() transfer:Hide() end); close:SetPoint("TOPRIGHT", -9, -9)
    local scroll = CreateFrame("ScrollFrame", nil, transfer, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 14, -62); scroll:SetPoint("BOTTOMRIGHT", -29, 92); transfer.scroll = scroll
    transfer.text = CreateFrame("EditBox", nil, scroll, "BackdropTemplate")
    transfer.text:SetMultiLine(true); transfer.text:SetAutoFocus(false); transfer.text:SetFontObject(ChatFontNormal)
    transfer.text:SetTextColor(unpack(C.accent)); TrackTheme(transfer.text, "text"); transfer.text:SetTextInsets(8, 8, 7, 7); transfer.text:SetWidth(410); transfer.text:SetHeight(154); transfer.text:SetMaxLetters(60000)
    Backdrop(transfer.text, C.cardAlt, C.border); scroll:SetScrollChild(transfer.text)
    SkinScrollFrame(scroll)
    transfer.nameLabel = Text(transfer, "GameFontHighlightSmall", "New profile name", C.teal); transfer.nameLabel:SetPoint("BOTTOMLEFT", 14, 67)
    transfer.name = CreateFrame("EditBox", nil, transfer, "BackdropTemplate")
    transfer.name:SetSize(224, 22); transfer.name:SetPoint("BOTTOMLEFT", 14, 40); transfer.name:SetAutoFocus(false); transfer.name:SetFontObject(GameFontHighlightSmall)
    transfer.name:SetTextInsets(8, 8, 0, 0); transfer.name:SetTextColor(unpack(C.accent)); TrackTheme(transfer.name, "text"); Backdrop(transfer.name, C.cardAlt, C.border)
    transfer.status = Text(transfer, "GameFontHighlightSmall", "", C.muted); transfer.status:SetPoint("BOTTOMLEFT", 14, 12); transfer.status:SetPoint("RIGHT", -14, 12); transfer.status:SetJustifyH("LEFT")
    transfer.action = Button(transfer, "", 108, nil, true); transfer.action:SetPoint("BOTTOMRIGHT", -14, 40)
    transfer.import = Button(transfer, "Import", 78, nil, true); transfer.import:SetPoint("RIGHT", transfer.action, "LEFT", -7, 0); transfer.import:Hide()
    transfer.text:SetScript("OnTextChanged", function(self)
        local lines = self.GetNumLines and self:GetNumLines() or 11
        self:SetHeight(math.max(154, math.min(24000, lines * 14 + 16)))
        if transfer.mode == "import" then
            transfer.validated = nil; transfer.import:Hide()
            transfer.status:SetText("Paste an export, then validate it."); transfer.status:SetTextColor(unpack(C.muted))
        end
    end)
    transfer.name:SetScript("OnEnterPressed", function()
        if transfer.import:IsShown() then transfer.import:Click() else transfer.action:Click() end
    end)
    transfer:SetScript("OnHide", function()
        transfer.blocker:Hide(); transfer.mode, transfer.validated = nil, nil
        transfer.text:ClearFocus(); transfer.name:ClearFocus(); transfer.text:SetText(""); transfer.name:SetText("")
    end)
end

function ns:OpenProfileTransfer(mode)
    self:CreateProfileTransfer()
    local transfer = self.ProfileTransfer
    transfer.mode, transfer.validated = mode, nil
    transfer.name:ClearFocus(); transfer.text:ClearFocus(); transfer.text:SetText(""); transfer.name:SetText("")
    transfer.import:Hide(); transfer.nameLabel:Hide(); transfer.name:Hide()
    transfer.scroll:SetVerticalScroll(0); transfer.action:Show()
    transfer:ClearAllPoints(); transfer:SetPoint("CENTER", self.Options, "CENTER", 0, 0)
    transfer.blocker:Show(); transfer:Show()
    if mode == "export" then
        transfer.title:SetText("Export " .. ShortText(PriorityFaderDB.profile, 24))
        transfer.copy:SetText("Copy this text and keep it somewhere safe. It contains this profile only.")
        transfer.action:GetFontString():SetText("Select all")
        transfer.action:SetScript("OnClick", function() transfer.text:SetFocus(); transfer.text:HighlightText() end)
        local text, reason = self:ExportProfile()
        if not text then
            transfer.status:SetText(reason); transfer.status:SetTextColor(unpack(C.amber)); transfer.action:Hide()
            return
        end
        transfer.text:SetText(text); transfer.text:SetFocus(); transfer.text:HighlightText()
        transfer.status:SetText("Press Ctrl+C to copy the selected export."); transfer.status:SetTextColor(unpack(C.teal))
    else
        transfer.title:SetText("Import profile")
        transfer.copy:SetText("Paste an export, validate it, then import it as a new profile.")
        transfer.nameLabel:Show(); transfer.name:Show()
        transfer.status:SetText("Paste an export, then validate it."); transfer.status:SetTextColor(unpack(C.muted))
        transfer.action:GetFontString():SetText("Validate")
        transfer.action:SetScript("OnClick", function()
            local profile, summary = ns:ParseProfileImport(transfer.text:GetText())
            if not profile then transfer.status:SetText(summary); transfer.status:SetTextColor(unpack(C.amber)); return end
            transfer.validated = true; transfer.import:Show()
            transfer.status:SetText("Ready: " .. summary.targets .. " targets, " .. summary.reactions .. " reactions.")
            transfer.status:SetTextColor(unpack(C.teal))
        end)
        transfer.import:SetScript("OnClick", function()
            if not transfer.validated then return end
            local ok, result = ns:ImportProfile(transfer.name:GetText(), transfer.text:GetText())
            if ok then
                transfer:Hide()
                if ns.ProfilePicker and ns.ProfilePicker:IsShown() then ns.ProfilePicker:Hide() end
            else
                transfer.status:SetText(result); transfer.status:SetTextColor(unpack(C.amber))
            end
        end)
        transfer.text:SetFocus()
    end
end

function ns:CreateProfileDeleteConfirm()
    if self.ProfileDeleteConfirm then return end
    local blocker = CreateFrame("Button", nil, self.Options, "BackdropTemplate")
    blocker:SetAllPoints(self.Options); blocker:SetFrameLevel(592); blocker:EnableMouse(true); blocker:RegisterForClicks("AnyUp")
    blocker:SetScript("OnClick", function() if ns.ProfileDeleteConfirm then ns.ProfileDeleteConfirm:Hide() end end)
    Backdrop(blocker, { 0, 0, 0, 0.42 }, { 0, 0, 0, 0 }); blocker:Hide()
    local confirm = CreateFrame("Frame", "PriorityFaderProfileDelete", self.Options, "BackdropTemplate")
    confirm:SetSize(326, 138); confirm:SetFrameStrata("FULLSCREEN_DIALOG"); confirm:SetFrameLevel(593); confirm:EnableMouse(true)
    Backdrop(confirm, C.panel, C.amber); confirm:Hide(); confirm.blocker = blocker; self.ProfileDeleteConfirm = confirm
    table.insert(UISpecialFrames, confirm:GetName())
    confirm.title = Text(confirm, "GameFontNormal", "Delete profile?", C.amber); confirm.title:SetPoint("TOPLEFT", 14, -13)
    confirm.copy = Text(confirm, "GameFontHighlightSmall", "", C.muted); confirm.copy:SetPoint("TOPLEFT", confirm.title, "BOTTOMLEFT", 0, -7); confirm.copy:SetPoint("RIGHT", -14, 0); confirm.copy:SetJustifyH("LEFT"); confirm.copy:SetWordWrap(true)
    local cancel = Button(confirm, "Cancel", 72, function() confirm:Hide() end); cancel:SetPoint("BOTTOMRIGHT", -101, 12)
    confirm.delete = Button(confirm, "Delete", 76, function()
        local ok, reason = ns:DeleteProfile(confirm.profileName)
        confirm:Hide()
        if ns.ProfilePicker and ns.ProfilePicker:IsShown() then
            ns:RenderProfilePicker()
            ns.ProfilePicker.status:SetText(ok and (reason or "Profile deleted.") or reason)
            ns.ProfilePicker.status:SetTextColor(unpack(ok and C.teal or C.amber))
        end
    end, true)
    confirm.delete:SetPoint("BOTTOMRIGHT", -14, 12)
    confirm:SetScript("OnHide", function() confirm.blocker:Hide(); confirm.profileName = nil end)
end

function ns:OpenProfileDeleteConfirm(name)
    self:CreateProfileDeleteConfirm()
    local confirm = self.ProfileDeleteConfirm
    confirm.profileName = name
    confirm.copy:SetText("Delete '" .. ShortText(name, 24) .. "'? This cannot be undone.")
    confirm:ClearAllPoints(); confirm:SetPoint("CENTER", self.Options, "CENTER", 0, 0)
    confirm.blocker:Show(); confirm:Show()
end

function ns:RenderProfilePicker()
    local picker = self.ProfilePicker
    if not picker or not picker:IsShown() then return end
    ClearChildren(picker.content)
    picker.content._profileRows = picker.content._profileRows or {}
    local active = PriorityFaderDB.profile
    local y = 0
    for index, name in ipairs(self:GetProfileNames()) do
        local profileName = name
        local row = picker.content._profileRows[index]
        if not row then
            row = Button(picker.content, "", 290, nil)
            row.delete = Button(picker.content, "x", 22, nil); row.delete:SetPoint("LEFT", row, "RIGHT", 8, 0)
            picker.content._profileRows[index] = row
        end
        local selected = profileName == active
        local systemCinematic = ns:IsCinematicProfileName(profileName)
        row:Show(); row:ClearAllPoints(); row:SetPoint("TOPLEFT", 0, -y); row._primary = selected
        row:SetBackdropColor(unpack(selected and C.accent or C.cardAlt)); row:GetFontString():SetText((selected and "Active: " or "") .. profileName .. (systemCinematic and " (managed)" or ""))
        row:GetFontString():SetTextColor(unpack(selected and { 1, 1, 1, 1 } or C.accent))
        row:SetScript("OnClick", function()
            local ok, reason = ns:SelectProfile(profileName)
            if ok then picker:Hide() else picker.status:SetText(reason); picker.status:SetTextColor(unpack(C.amber)) end
        end)
        row:SetEnabled(not systemCinematic); row:SetAlpha(systemCinematic and 0.58 or 1)
        if profileName == "Default" or systemCinematic then
            row.delete:Hide()
        else
            row.delete:Show(); row.delete:SetScript("OnClick", function()
                ns:OpenProfileDeleteConfirm(profileName)
            end)
        end
        picker.content._rows[#picker.content._rows + 1] = row
        if row.delete:IsShown() then picker.content._rows[#picker.content._rows + 1] = row.delete end
        y = y + 30
    end
    picker.content:SetHeight(math.max(1, y))
    picker.scroll:SetVerticalScroll(math.min(picker.scroll:GetVerticalScroll(), picker.scroll:GetVerticalScrollRange()))
end

function ns:OpenProfilePicker()
    self:CreateProfilePicker()
    local picker = self.ProfilePicker
    picker.status:SetText("New profiles start as a copy of " .. (PriorityFaderDB.profile or "Default") .. ".")
    picker.status:SetTextColor(unpack(C.muted))
    picker:ClearAllPoints(); picker:SetPoint("CENTER", self.Options, "CENTER", 0, 0)
    picker.blocker:Show(); picker:Show(); self:RenderProfilePicker()
end

function ns:RefreshActiveState()
    local panel = self.Options
    if not panel or not panel.selected then return end
    local state = self.runtime.active[panel.selected]
    if not state then return end
    if state.pendingRestore then
        panel.active:SetText("Waiting to restore previous profile")
        panel.active:SetTextColor(unpack(C.amber))
    elseif state.unavailable then
        panel.active:SetText("Unavailable")
        panel.active:SetTextColor(unpack(C.amber))
    elseif state.hostHidden then
        panel.active:SetText("Host hidden")
        panel.active:SetTextColor(unpack(C.amber))
    elseif state.reaction then
        local count = #(state.reaction.requirements or {})
        local info = ns.CONDITION_INFO[state.reaction.condition]
        local momentDetail = ""
        if info and info.kind == "moment" then
            local started = ns.runtime.moments[state.reaction.condition]
            local duration = state.reaction.duration or info.duration or 3
            if started then momentDetail = " (" .. Seconds(math.max(0, duration - (GetTime() - started))) .. " left)" end
        end
        local inherited = state.inheritedFrom and ns.TargetByID[state.inheritedFrom]
        local prefix = inherited and ("Following " .. inherited.label .. ": ") or "Active now: "
        panel.active:SetText(prefix .. ConditionLabel(state.reaction.condition) .. (count > 0 and " + " .. count or "") .. momentDetail .. " -> " .. Percent(state.desired))
        panel.active:SetTextColor(unpack(C.teal))
    else
        local inherited = state.inheritedFrom and ns.TargetByID[state.inheritedFrom]
        panel.active:SetText((inherited and ("Following " .. inherited.label .. ": At rest") or "Active now: At rest") .. " -> " .. Percent(state.desired))
        panel.active:SetTextColor(unpack(C.muted))
    end
end

function ns:CreateReactionPalette()
    if self.ReactionPalette then return end
    local blocker = CreateFrame("Button", nil, self.Options, "BackdropTemplate")
    blocker:SetAllPoints(self.Options); blocker:SetFrameLevel(578); blocker:EnableMouse(true); blocker:RegisterForClicks("AnyUp")
    blocker:SetScript("OnClick", function() end); Backdrop(blocker, { 0, 0, 0, 0.32 }, { 0, 0, 0, 0 }); blocker:Hide()
    local palette = CreateFrame("Frame", "PriorityFaderReactionPalette", self.Options, "BackdropTemplate")
    palette:SetSize(386, 298); palette:SetFrameStrata("FULLSCREEN_DIALOG"); palette:SetFrameLevel(580)
    palette:EnableMouse(true); Backdrop(palette, C.panel, C.accent); palette:Hide(); palette.blocker = blocker; self.ReactionPalette = palette
    table.insert(UISpecialFrames, palette:GetName())
    palette.title = Text(palette, "GameFontNormal", "Add a reaction", C.accent); palette.title:SetPoint("TOPLEFT", 14, -13)
    palette.context = Text(palette, "GameFontHighlightSmall", "First matching row wins.", C.muted); palette.context:SetPoint("TOPLEFT", palette.title, "BOTTOMLEFT", 0, -3)
    local close = Button(palette, "x", 22, function() palette:Hide() end); close:SetPoint("TOPRIGHT", -9, -9)
    palette.done = Button(palette, "Done", 66, function() palette:Hide() end, true); palette.done:SetPoint("BOTTOMRIGHT", -12, 11); palette.done:Hide()
    palette:SetScript("OnHide", function()
        palette.blocker:Hide()
        local targetID, refresh = palette.targetID, palette.mode == "requirements"
        palette.mode, palette.reaction = nil, nil
        if refresh and targetID and ns.Options and ns.Options:IsVisible() then ns:RenderSelectedTarget(targetID) end
    end)
    palette.tabs, palette.conditionButtons = {}, {}
    local tabY = -56
    for index, category in ipairs(self.CONDITION_CATEGORY_ORDER) do
        local categoryID = category.id
        local tab = Button(palette, category.label, 112, function()
            ns:ShowReactionCategory(categoryID)
        end)
        tab:SetPoint("TOPLEFT", 14 + ((index - 1) % 3) * 120, tabY - math.floor((index - 1) / 3) * 27)
        palette.tabs[category.id] = tab
    end
    palette.content = CreateFrame("Frame", nil, palette)
    palette.content:SetPoint("TOPLEFT", 14, -119); palette.content:SetPoint("BOTTOMRIGHT", -14, 12)
    for _, category in ipairs(self.CONDITION_CATEGORY_ORDER) do
        for key, info in pairs(self.CONDITION_INFO) do
            if info.category == category.id and not info.internal then
                local conditionKey, conditionInfo = key, info
                local button = Button(palette.content, info.label, 171, function()
                    local targetID = palette.targetID
                    local settings = targetID and ns:GetTargetSettings(targetID)
                    if palette.mode == "requirements" and palette.reaction then
                        local reaction = palette.reaction
                        reaction.requirements = reaction.requirements or {}
                        local requirementIndex = RequirementIndex(reaction, conditionKey)
                        if requirementIndex then
                            table.remove(reaction.requirements, requirementIndex)
                        elseif conditionKey ~= reaction.condition then
                            if reaction.condition == "mouseover" and #reaction.requirements == 0
                                and ns:RequiresUnconditionalMouseover(targetID) and ns:CountUnconditionalMouseover(settings) <= 1 then
                                palette.context:SetText("This reveal-group member needs one unconditional Mouseover reaction. Add another Mouseover row first.")
                                return
                            end
                            reaction.requirements[#reaction.requirements + 1] = conditionKey
                        end
                        ns:InvalidateTargetTransition(targetID)
                        ns:ShowReactionCategory(palette.categoryID)
                    elseif settings then
                        if #settings.reactions >= ns.MAX_REACTIONS_PER_TARGET then
                            palette.context:SetText("Each target supports up to " .. ns.MAX_REACTIONS_PER_TARGET .. " reactions.")
                            return
                        end
                        settings.reactions[#settings.reactions + 1] = {
                            id = ns:NextReactionID(), condition = conditionKey, opacity = 1,
                            duration = conditionInfo.duration,
                        }
                        ns:InvalidateTargetTransition(targetID)
                        palette:Hide(); ns:RenderSelectedTarget(targetID)
                    end
                end)
                SetTooltip(button, conditionInfo.label, conditionInfo.kind == "moment" and "Temporarily reacts after this event." or (conditionInfo.restricted and "Unavailable or secret values safely count as false." or "A live state reaction."))
                button.conditionKey, button.category = conditionKey, category.id
                palette.conditionButtons[#palette.conditionButtons + 1] = button
            end
        end
    end
end

function ns:ShowReactionCategory(categoryID)
    local palette = self.ReactionPalette
    if not palette then return end
    palette.categoryID = categoryID
    local settings = palette.targetID and self:GetTargetSettings(palette.targetID)
    for id, tab in pairs(palette.tabs) do
        local selected = id == categoryID
        tab._selected = selected
        tab:SetBackdropColor(unpack(selected and C.accent or C.cardAlt))
        tab:GetFontString():SetTextColor(unpack(selected and { 1, 1, 1, 1 } or C.accent))
    end
    local visible = {}
    for _, button in ipairs(palette.conditionButtons) do
        button:Hide()
        if button.category == categoryID then visible[#visible + 1] = button end
    end
    table.sort(visible, function(a, b) return ConditionLabel(a.conditionKey) < ConditionLabel(b.conditionKey) end)
    for index, button in ipairs(visible) do
        local reaction = palette.reaction
        local requirementMode = palette.mode == "requirements" and reaction
        local selected = requirementMode and RequirementIndex(reaction, button.conditionKey)
        local blocked = requirementMode and button.conditionKey == reaction.condition
        local exists = requirementMode and blocked
        button:ClearAllPoints(); button:SetPoint("TOPLEFT", ((index - 1) % 2) * 179, -math.floor((index - 1) / 2) * 30)
        button._selected, button._selectedColor = selected and true or false, C.teal
        button:SetBackdropColor(unpack(selected and C.teal or C.cardAlt))
        button:GetFontString():SetTextColor(unpack(selected and { 0.02, 0.06, 0.07, 1 } or C.accent))
        button:SetEnabled(not exists); button:SetAlpha(exists and 0.35 or 1); button:Show()
    end
end

function ns:OpenReactionPalette(id)
    self:CreateReactionPalette()
    local palette = self.ReactionPalette
    palette.targetID, palette.mode, palette.reaction = id, "reaction", nil
    palette.done:Hide()
    palette.title:SetText("Add a reaction")
    palette.context:SetText("For " .. (self.TargetByID[id] and self.TargetByID[id].label or "this frame") .. " - first matching row wins; duplicates can differ by requirements.")
    palette:ClearAllPoints(); palette:SetPoint("CENTER", self.Options, "CENTER", 0, 0)
    palette.blocker:Show(); palette:Show(); self:ShowReactionCategory(palette.categoryID or "presence")
end

function ns:OpenRequirementPalette(id, reaction)
    self:CreateReactionPalette()
    local palette = self.ReactionPalette
    palette.targetID, palette.mode, palette.reaction = id, "requirements", reaction
    palette.title:SetText("Add requirements")
    palette.context:SetText("Extra requirements for " .. ConditionLabel(reaction.condition) .. " - all selected conditions must be true.")
    palette.done:Show()
    palette:ClearAllPoints(); palette:SetPoint("CENTER", self.Options, "CENTER", 0, 0)
    palette.blocker:Show(); palette:Show(); self:ShowReactionCategory(palette.categoryID or "presence")
end

function ns:CreateConnectionPicker()
    if self.ConnectionPicker then return end
    local blocker = CreateFrame("Button", nil, self.Options, "BackdropTemplate")
    blocker:SetAllPoints(self.Options); blocker:SetFrameLevel(579); blocker:EnableMouse(true); blocker:RegisterForClicks("AnyUp")
    blocker:SetScript("OnClick", function() end)
    Backdrop(blocker, { 0, 0, 0, 0.42 }, { 0, 0, 0, 0 }); blocker:Hide()
    local picker = CreateFrame("Frame", "PriorityFaderConnections", self.Options, "BackdropTemplate")
    picker:SetSize(430, 380); picker:SetFrameStrata("FULLSCREEN_DIALOG"); picker:SetFrameLevel(581)
    picker:EnableMouse(true); Backdrop(picker, C.panel, C.accent); picker:Hide(); picker.blocker = blocker; self.ConnectionPicker = picker
    table.insert(UISpecialFrames, picker:GetName())
    picker.title = Text(picker, "GameFontNormal", "Connections", C.accent); picker.title:SetPoint("TOPLEFT", 14, -13)
    picker.copy = Text(picker, "GameFontHighlightSmall", "", C.muted); picker.copy:SetPoint("TOPLEFT", picker.title, "BOTTOMLEFT", 0, -4); picker.copy:SetPoint("RIGHT", -14, 0); picker.copy:SetJustifyH("LEFT")
    picker.status = Text(picker, "GameFontHighlightSmall", "Click frames to add or remove them.", C.teal); picker.status:SetPoint("TOPLEFT", picker.copy, "BOTTOMLEFT", 0, -6)
    picker.done = Button(picker, "Done", 66, function() picker:Hide() end, true); picker.done:SetPoint("BOTTOMRIGHT", -12, 12)
    picker.close = Button(picker, "x", 22, function() picker:Hide() end); picker.close:SetPoint("TOPRIGHT", -9, -9)
    local scroll = CreateFrame("ScrollFrame", nil, picker, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 14, -86); scroll:SetPoint("BOTTOMRIGHT", -29, 48)
    scroll:EnableMouseWheel(true)
    scroll:SetScript("OnMouseWheel", function(self, delta)
        self:SetVerticalScroll(math.max(0, math.min(self:GetVerticalScrollRange(), self:GetVerticalScroll() - delta * 58)))
    end)
    SkinScrollFrame(scroll)
    picker.scroll = scroll
    picker.content = CreateFrame("Frame", nil, scroll)
    picker.content:SetSize(382, 1)
    scroll:SetScrollChild(picker.content)
    picker.buttons = {}
    picker:SetScript("OnHide", function()
        picker.blocker:Hide()
        local sourceID = picker.sourceID
        picker.sourceID, picker.mode = nil, nil
        if sourceID and ns.TargetByID[sourceID] and ns.Options and ns.Options:IsVisible() then ns:RenderSelectedTarget(sourceID) end
    end)
end

function ns:RenderConnectionPicker()
    local picker = self.ConnectionPicker
    if not picker or not picker:IsShown() then return end
    local sourceID, mode = picker.sourceID, picker.mode
    if not self.TargetByID[sourceID] then picker:Hide(); return end
    picker.title:SetText(mode == "group" and "Hover group" or mode == "visibility" and "Visibility children" or "Linked children")
    picker.copy:SetText(mode == "group"
        and "Hover any selected frame to reveal the group together."
        or mode == "visibility"
            and "A child's own matching rules run first; otherwise it follows this frame's resolved opacity."
            or "Hover the source to reveal every selected child. A child reveals itself only when it has its own Mouseover rule.")
    local group = mode == "group" and select(2, self:GetRevealGroup(sourceID)) or nil
    local children = mode == "link" and self:GetLinkedChildren(sourceID) or nil
    local visibilityChildren = mode == "visibility" and self:GetVisibilityChildren(sourceID) or nil
    for _, button in pairs(picker.buttons) do button:Hide() end
    local availableTargets = self:GetAvailableTargets()
    for index, target in ipairs(availableTargets) do
        local targetID = target.id
        local button = picker.buttons[targetID]
        if not button then
            button = Button(picker.content, "", 185, nil)
            picker.buttons[targetID] = button
        end
        local isSource = targetID == sourceID
        local selected = mode == "group" and group and group.members[targetID]
            or mode == "link" and children[targetID]
            or mode == "visibility" and visibilityChildren[targetID]
        button:Show(); button:ClearAllPoints(); button:SetPoint("TOPLEFT", ((index - 1) % 2) * 193, -math.floor((index - 1) / 2) * 29)
        button._selected = selected and true or false; button._selectedColor = C.teal; button._primary = false
        button:SetBackdropColor(unpack(selected and C.teal or C.cardAlt))
        button:GetFontString():SetText((selected and "[on] " or "") .. target.label .. (isSource and " [source]" or ""))
        button:GetFontString():SetTextColor(unpack(selected and { 0.02, 0.06, 0.07, 1 } or C.accent))
        button:SetEnabled(not isSource); button:SetAlpha(isSource and 0.45 or 1)
        button:SetScript("OnClick", function()
            if mode == "group" then
                local _, current = ns:GetRevealGroup(sourceID)
                if current and current.members[targetID] then
                    ns:RemoveFromRevealGroup(targetID)
                else
                    local allowed, reason = ns:AddToRevealGroup(sourceID, targetID)
                    if not allowed then picker.status:SetText(reason); picker.status:SetTextColor(unpack(C.amber)); return end
                end
            elseif mode == "link" then
                if ns:GetLinkedChildren(sourceID)[targetID] then
                    ns:RemoveLink(sourceID, targetID)
                else
                    local allowed, reason = ns:AddLink(sourceID, targetID)
                    if not allowed then picker.status:SetText(reason); picker.status:SetTextColor(unpack(C.amber)); return end
                end
            else
                if ns:GetVisibilityChildren(sourceID)[targetID] then
                    ns:RemoveVisibilityLink(sourceID, targetID)
                else
                    local allowed, reason = ns:AddVisibilityLink(sourceID, targetID)
                    if not allowed then picker.status:SetText(reason); picker.status:SetTextColor(unpack(C.amber)); return end
                    picker.status:SetText(reason); picker.status:SetTextColor(unpack(C.teal))
                    ns:RenderConnectionPicker()
                    return
                end
            end
            picker.status:SetText("Click frames to add or remove them."); picker.status:SetTextColor(unpack(C.teal))
            ns:RenderConnectionPicker()
        end)
    end
    picker.content:SetHeight(math.max(1, math.ceil(#availableTargets / 2) * 29))
    picker.scroll:SetVerticalScroll(math.min(picker.scroll:GetVerticalScroll(), picker.scroll:GetVerticalScrollRange()))
end

function ns:OpenConnectionPicker(mode, sourceID)
    if not self.TargetByID[sourceID] then return end
    self:CreateConnectionPicker()
    local picker = self.ConnectionPicker
    picker.mode, picker.sourceID = mode, sourceID
    picker.scroll:SetVerticalScroll(0)
    picker:ClearAllPoints(); picker:SetPoint("CENTER", self.Options, "CENTER", 0, 0)
    picker.blocker:Show(); picker:Show(); self:RenderConnectionPicker()
end

function ns:CreateOpacityPicker()
    if self.OpacityPicker then return end
    local blocker = CreateFrame("Button", nil, self.Options, "BackdropTemplate")
    blocker:SetAllPoints(self.Options); blocker:SetFrameLevel(582); blocker:EnableMouse(true); blocker:RegisterForClicks("AnyUp")
    blocker:SetScript("OnClick", function() if ns.OpacityPicker then ns.OpacityPicker:Hide() end end)
    Backdrop(blocker, { 0, 0, 0, 0.22 }, { 0, 0, 0, 0 }); blocker:Hide()
    local picker = CreateFrame("Frame", "PriorityFaderOpacity", self.Options, "BackdropTemplate")
    picker:SetSize(294, 148); picker:SetFrameStrata("FULLSCREEN_DIALOG"); picker:SetFrameLevel(583); picker:EnableMouse(true)
    Backdrop(picker, C.panel, C.accent); picker:Hide(); picker.blocker = blocker; self.OpacityPicker = picker
    table.insert(UISpecialFrames, picker:GetName())
    picker.title = Text(picker, "GameFontNormal", "Opacity", C.accent); picker.title:SetPoint("TOPLEFT", 14, -13)
    picker.value = Text(picker, "GameFontNormal", "", C.teal); picker.value:SetPoint("TOPRIGHT", -42, -13)
    local close = Button(picker, "x", 22, function() picker:Hide() end); close:SetPoint("TOPRIGHT", -9, -9)
    picker.slider = CreateFrame("Slider", nil, picker, "BackdropTemplate")
    picker.slider:SetPoint("TOPLEFT", 16, -46); picker.slider:SetPoint("TOPRIGHT", -16, -46); picker.slider:SetHeight(14)
    picker.slider:SetOrientation("HORIZONTAL")
    picker.slider:SetMinMaxValues(0, 1); picker.slider:SetValueStep(0.01); picker.slider:SetObeyStepOnDrag(true)
    Backdrop(picker.slider, C.cardAlt, C.border)
    local thumb = picker.slider:CreateTexture(nil, "OVERLAY"); thumb:SetSize(12, 20); thumb:SetColorTexture(unpack(C.teal)); picker.slider:SetThumbTexture(thumb)
    picker.presets = {}
    for index, value in ipairs({ 0, 0.12, 0.30, 0.50, 0.70, 1.00 }) do
        local presetValue = value
        local button = Button(picker, Percent(value), 39, function()
            picker.slider:SetValue(presetValue)
        end)
        button:SetPoint("TOPLEFT", 16 + (index - 1) * 44, -78); picker.presets[#picker.presets + 1] = { button = button, value = value }
    end
    function picker:UpdateVisuals(value)
        self.value:SetText(Percent(value))
        for _, preset in ipairs(self.presets) do
            local selected = math.abs(value - preset.value) < 0.005
            preset.button._selected, preset.button._selectedColor = selected, C.teal
            preset.button:SetBackdropColor(unpack(selected and C.teal or C.cardAlt))
            preset.button:GetFontString():SetTextColor(unpack(selected and { 0.02, 0.06, 0.07, 1 } or C.accent))
        end
    end
    picker.done = Button(picker, "Done", 66, function() picker:Hide() end, true); picker.done:SetPoint("BOTTOMRIGHT", -12, 12)
    picker.slider:SetScript("OnValueChanged", function(_, value)
        if not picker.apply then return end
        value = math.floor(value * 100 + 0.5) / 100
        picker:UpdateVisuals(value); picker.apply(value)
    end)
    picker:SetScript("OnHide", function()
        picker.blocker:Hide(); picker.apply = nil; picker.valueTarget = nil
    end)
end

function ns:OpenOpacityPicker(label, value, apply, valueTarget)
    self:CreateOpacityPicker()
    local picker = self.OpacityPicker
    picker.title:SetText(label)
    picker.value:SetText(Percent(value))
    picker.apply, picker.valueTarget = apply, valueTarget
    picker:ClearAllPoints(); picker:SetPoint("CENTER", self.Options, "CENTER", 0, 0)
    picker.blocker:Show(); picker:Show(); picker.slider:SetValue(value); picker:UpdateVisuals(value)
end

function ns:CreateDurationPicker()
    if self.DurationPicker then return end
    local blocker = CreateFrame("Button", nil, self.Options, "BackdropTemplate")
    blocker:SetAllPoints(self.Options); blocker:SetFrameLevel(584); blocker:EnableMouse(true); blocker:RegisterForClicks("AnyUp")
    blocker:SetScript("OnClick", function() if ns.DurationPicker then ns.DurationPicker:Hide() end end)
    Backdrop(blocker, { 0, 0, 0, 0.22 }, { 0, 0, 0, 0 }); blocker:Hide()
    local picker = CreateFrame("Frame", "PriorityFaderDuration", self.Options, "BackdropTemplate")
    picker:SetSize(294, 148); picker:SetFrameStrata("FULLSCREEN_DIALOG"); picker:SetFrameLevel(585); picker:EnableMouse(true)
    Backdrop(picker, C.panel, C.accent); picker:Hide(); picker.blocker = blocker; self.DurationPicker = picker
    table.insert(UISpecialFrames, picker:GetName())
    picker.title = Text(picker, "GameFontNormal", "Reaction duration", C.accent); picker.title:SetPoint("TOPLEFT", 14, -13)
    picker.value = Text(picker, "GameFontNormal", "", C.teal); picker.value:SetPoint("TOPRIGHT", -42, -13)
    local close = Button(picker, "x", 22, function() picker:Hide() end); close:SetPoint("TOPRIGHT", -9, -9)
    picker.slider = CreateFrame("Slider", nil, picker, "BackdropTemplate")
    picker.slider:SetPoint("TOPLEFT", 16, -46); picker.slider:SetPoint("TOPRIGHT", -16, -46); picker.slider:SetHeight(14)
    picker.slider:SetOrientation("HORIZONTAL")
    picker.slider:SetMinMaxValues(0.5, 30); picker.slider:SetValueStep(0.25); picker.slider:SetObeyStepOnDrag(true)
    Backdrop(picker.slider, C.cardAlt, C.border)
    local thumb = picker.slider:CreateTexture(nil, "OVERLAY"); thumb:SetSize(12, 20); thumb:SetColorTexture(unpack(C.teal)); picker.slider:SetThumbTexture(thumb)
    picker.presets = {}
    for index, value in ipairs({ 1, 2, 3, 4, 6, 10 }) do
        local presetValue = value
        local button = Button(picker, Seconds(value), 39, function() picker.slider:SetValue(presetValue) end)
        button:SetPoint("TOPLEFT", 16 + (index - 1) * 44, -78); picker.presets[#picker.presets + 1] = { button = button, value = value }
    end
    function picker:UpdateVisuals(value)
        self.value:SetText(Seconds(value))
        for _, preset in ipairs(self.presets) do
            local selected = math.abs(value - preset.value) < 0.01
            preset.button._selected, preset.button._selectedColor = selected, C.teal
            preset.button:SetBackdropColor(unpack(selected and C.teal or C.cardAlt))
            preset.button:GetFontString():SetTextColor(unpack(selected and { 0.02, 0.06, 0.07, 1 } or C.accent))
        end
    end
    picker.done = Button(picker, "Done", 66, function() picker:Hide() end, true); picker.done:SetPoint("BOTTOMRIGHT", -12, 12)
    picker.slider:SetScript("OnValueChanged", function(_, value)
        if not picker.apply then return end
        value = math.floor(value * 4 + 0.5) / 4
        picker:UpdateVisuals(value); picker.apply(value)
    end)
    picker:SetScript("OnHide", function()
        picker.blocker:Hide(); picker.apply = nil
    end)
end

function ns:OpenDurationPicker(label, value, apply)
    self:CreateDurationPicker()
    local picker = self.DurationPicker
    local normalized = NormalizedDuration(value)
    picker.title:SetText(label .. " duration")
    picker.apply = apply
    picker.slider:SetValue(normalized)
    picker:UpdateVisuals(normalized)
    picker:ClearAllPoints(); picker:SetPoint("CENTER", self.Options, "CENTER", 0, 0)
    picker.blocker:Show(); picker:Show()
end

function ns:CreateTimingPicker()
    if self.TimingPicker then return end
    local blocker = CreateFrame("Button", nil, self.Options, "BackdropTemplate")
    blocker:SetAllPoints(self.Options); blocker:SetFrameLevel(586); blocker:EnableMouse(true); blocker:RegisterForClicks("AnyUp")
    blocker:SetScript("OnClick", function() if ns.TimingPicker then ns.TimingPicker:Hide() end end)
    Backdrop(blocker, { 0, 0, 0, 0.22 }, { 0, 0, 0, 0 }); blocker:Hide()
    local picker = CreateFrame("Frame", "PriorityFaderTiming", self.Options, "BackdropTemplate")
    picker:SetSize(318, 204); picker:SetFrameStrata("FULLSCREEN_DIALOG"); picker:SetFrameLevel(587); picker:EnableMouse(true)
    Backdrop(picker, C.panel, C.accent); picker:Hide(); picker.blocker = blocker; self.TimingPicker = picker
    table.insert(UISpecialFrames, picker:GetName())
    picker.title = Text(picker, "GameFontNormal", "Frame timing", C.accent); picker.title:SetPoint("TOPLEFT", 14, -13)
    picker.help = Text(picker, "GameFontHighlightSmall", "Applies to this target only.", C.muted); picker.help:SetPoint("TOPLEFT", picker.title, "BOTTOMLEFT", 0, -3)
    local close = Button(picker, "x", 22, function() picker:Hide() end); close:SetPoint("TOPRIGHT", -9, -9)
    picker.fadeLabel = Text(picker, "GameFontHighlightSmall", "Transition time", C.teal); picker.fadeLabel:SetPoint("TOPLEFT", 16, -58)
    picker.fadeValue = Text(picker, "GameFontHighlightSmall", "", C.teal); picker.fadeValue:SetPoint("TOPRIGHT", -18, -58)
    picker.fade = CreateFrame("Slider", nil, picker, "BackdropTemplate")
    picker.fade:SetPoint("TOPLEFT", 16, -80); picker.fade:SetPoint("TOPRIGHT", -16, -80); picker.fade:SetHeight(14)
    picker.fade:SetOrientation("HORIZONTAL")
    picker.fade:SetMinMaxValues(0.05, 2); picker.fade:SetValueStep(0.05); picker.fade:SetObeyStepOnDrag(true); Backdrop(picker.fade, C.cardAlt, C.border)
    local fadeThumb = picker.fade:CreateTexture(nil, "OVERLAY"); fadeThumb:SetSize(12, 20); fadeThumb:SetColorTexture(unpack(C.teal)); picker.fade:SetThumbTexture(fadeThumb)
    picker.delayLabel = Text(picker, "GameFontHighlightSmall", "Fade-out delay", C.teal); picker.delayLabel:SetPoint("TOPLEFT", 16, -116)
    picker.delayValue = Text(picker, "GameFontHighlightSmall", "", C.teal); picker.delayValue:SetPoint("TOPRIGHT", -18, -116)
    picker.delay = CreateFrame("Slider", nil, picker, "BackdropTemplate")
    picker.delay:SetPoint("TOPLEFT", 16, -138); picker.delay:SetPoint("TOPRIGHT", -16, -138); picker.delay:SetHeight(14)
    picker.delay:SetOrientation("HORIZONTAL")
    picker.delay:SetMinMaxValues(0, 5); picker.delay:SetValueStep(0.05); picker.delay:SetObeyStepOnDrag(true); Backdrop(picker.delay, C.cardAlt, C.border)
    local delayThumb = picker.delay:CreateTexture(nil, "OVERLAY"); delayThumb:SetSize(12, 20); delayThumb:SetColorTexture(unpack(C.teal)); picker.delay:SetThumbTexture(delayThumb)
    picker.done = Button(picker, "Done", 66, function() picker:Hide() end, true); picker.done:SetPoint("BOTTOMRIGHT", -12, 12)
    function picker:UpdateVisuals()
        self.fadeValue:SetText(string.format("%.2fs", self.fade:GetValue()))
        self.delayValue:SetText(string.format("%.2fs", self.delay:GetValue()))
    end
    local function ApplyTiming()
        if picker.loading then return end
        local settings = picker.targetID and ns:GetTargetSettings(picker.targetID)
        if not settings then return end
        settings.fadeDuration = math.floor(picker.fade:GetValue() * 100 + 0.5) / 100
        settings.fadeDelay = math.floor(picker.delay:GetValue() * 100 + 0.5) / 100
        picker:UpdateVisuals()
    end
    picker.fade:SetScript("OnValueChanged", ApplyTiming); picker.delay:SetScript("OnValueChanged", ApplyTiming)
    picker:SetScript("OnHide", function()
        local targetID = picker.targetID
        picker.blocker:Hide(); picker.targetID = nil
        if targetID and ns.Options and ns.Options:IsVisible() and ns.Options.selected == targetID then
            ns:RenderSelectedTarget(targetID)
        end
    end)
end

function ns:OpenTimingPicker(id, settings)
    self:CreateTimingPicker()
    local picker = self.TimingPicker
    picker.targetID, picker.loading = id, true
    picker.fade:SetValue(settings.fadeDuration); picker.delay:SetValue(settings.fadeDelay)
    picker.loading = nil; picker:UpdateVisuals()
    picker:ClearAllPoints(); picker:SetPoint("CENTER", self.Options, "CENTER", 0, 0)
    picker.blocker:Show(); picker:Show()
end

function ns:RenderTargetRail()
    local panel = self.Options
    if not panel or not panel:IsVisible() then return end
    local query = (panel.targetQuery or ""):match("^%s*(.-)%s*$"):lower()
    local profileTargets = self:Profile().targets
    if panel.managedOnlyButton then
        local enabled = panel.managedOnly == true
        panel.managedOnlyButton._selected = enabled
        panel.managedOnlyButton._selectedColor = enabled and { 0.05, 0.18, 0.17, 1 } or nil
        panel.managedOnlyButton:SetBackdropColor(unpack(enabled and { 0.05, 0.18, 0.17, 1 } or C.cardAlt))
        panel.managedOnlyButton:SetBackdropBorderColor(unpack(enabled and C.teal or C.border))
        panel.managedOnlyButton:GetFontString():SetTextColor(unpack(enabled and C.teal or C.accent))
    end
    if panel.treeViewButton then
        panel.treeViewButton:GetFontString():SetText(panel.treeView and "Tree" or "List")
        panel.treeViewButton._selected = panel.treeView == true
        panel.treeViewButton._selectedColor = panel.treeView and { 0.08, 0.10, 0.16, 1 } or nil
        panel.treeViewButton:SetBackdropColor(unpack(panel.treeView and { 0.08, 0.10, 0.16, 1 } or C.cardAlt))
        panel.treeViewButton:SetBackdropBorderColor(unpack(panel.treeView and C.accent or C.border))
    end
    ClearChildren(panel.targetContent)
    panel.targetContent._targetRows = panel.targetContent._targetRows or {}
    local orderedTargets, depthByID = self.Targets, {}
    if panel.treeView then
        orderedTargets = {}
        local targetByID, managed, visited = {}, {}, {}
        for _, target in ipairs(self.Targets) do
            targetByID[target.id] = target
            local settings = profileTargets[target.id]
            if settings and settings.enabled ~= false then managed[target.id] = true end
        end
        local function Append(id, depth)
            if visited[id] or not managed[id] or not targetByID[id] then return end
            visited[id], depthByID[id] = true, depth
            orderedTargets[#orderedTargets + 1] = targetByID[id]
            for _, candidate in ipairs(self.Targets) do
                if self:GetVisibilityChildren(id)[candidate.id] then Append(candidate.id, depth + 1) end
            end
        end
        for _, target in ipairs(self.Targets) do
            if managed[target.id] and not self:GetVisibilityParent(target.id) then Append(target.id, 0) end
        end
        for _, target in ipairs(self.Targets) do if managed[target.id] then Append(target.id, 0) end end
        for _, target in ipairs(self.Targets) do
            if not managed[target.id] then orderedTargets[#orderedTargets + 1] = target end
        end
    end
    local y = 0
    local shown = 0
    for _, target in ipairs(orderedTargets) do
        local searchable = (target.label .. " " .. (target.source or "") .. " " .. target.id):lower()
        local settings = profileTargets[target.id]
        local managed = settings ~= nil and settings.enabled ~= false
        if (not panel.managedOnly or managed) and (query == "" or searchable:find(query, 1, true)) then
            shown = shown + 1
            local index = shown
            local targetID = target.id
            local available, _, status, statusNote, statusTone = self:GetTargetAvailability(target)
            local chosen = panel.selected == target.id
            local row = panel.targetContent._targetRows[index]
            if not row then
                row = Button(panel.targetContent, "", 172, nil)
                row.dot = row:CreateTexture(nil, "OVERLAY"); row.dot:SetSize(5, 5); row.dot:SetPoint("LEFT", 7, 0)
                row:GetFontString():SetPoint("CENTER", 5, 0)
                panel.targetContent._targetRows[index] = row
            end
            local depth = panel.treeView and (depthByID[target.id] or 0) or 0
            local indent = math.min(36, depth * 12)
            row:SetWidth(172 - indent)
            row:Show(); row:ClearAllPoints(); row:SetPoint("TOPLEFT", indent, -y); y = y + 27
            row._primary = chosen
            row._targetID, row._managed = targetID, managed
            row:SetBackdropColor(unpack(chosen and C.accent or C.cardAlt))
            row:SetBackdropBorderColor(unpack(C.border))
            row:GetFontString():SetText((depth > 0 and ">  " or "") .. target.label); row:GetFontString():SetTextColor(unpack(chosen and { 1, 1, 1, 1 } or available and C.accent or C.muted))
            row.dot:SetColorTexture(unpack(available and (managed and C.teal or C.accent) or C.amber))
            SetTooltip(row, target.label, status .. ": " .. statusNote)
            row:SetScript("OnClick", function()
                panel.selected = targetID
                ns:RenderOptions()
            end)
            row:RegisterForDrag("LeftButton")
            row:SetScript("OnDragStart", function(self)
                if not panel.treeView or not self._managed then return end
                panel.treeDragID, panel.treeDropID = self._targetID, nil
                self:SetAlpha(0.55)
                panel.active:SetText("Drop this frame onto its visibility parent")
                panel.active:SetTextColor(unpack(C.teal))
            end)
            row:SetScript("OnDragStop", function(self)
                local childID, parentID = panel.treeDragID, panel.treeDropID
                panel.treeDragID, panel.treeDropID = nil, nil
                self:SetAlpha(available and 1 or 0.78)
                if childID and parentID and childID ~= parentID then
                    local ok, reason = ns:AddVisibilityLink(parentID, childID)
                    ns:RenderOptions()
                    panel.active:SetText(reason or (ok and "Visibility parent linked" or "Unable to link frames"))
                    panel.active:SetTextColor(unpack(ok and C.teal or C.amber))
                    return
                end
                ns:RenderOptions()
            end)
            if not row._treeHoverHooked then
                row:HookScript("OnEnter", function(self)
                    if panel.treeDragID and panel.treeDragID ~= self._targetID and self._managed then
                        panel.treeDropID = self._targetID
                        self:SetBackdropBorderColor(unpack(C.teal))
                    end
                end)
                row:HookScript("OnLeave", function(self)
                    if panel.treeDropID == self._targetID then
                        panel.treeDropID = nil
                        self:SetBackdropBorderColor(unpack(C.border))
                    end
                end)
                row._treeHoverHooked = true
            end
            row:SetAlpha(available and 1 or 0.78)
            panel.targetContent._rows[#panel.targetContent._rows + 1] = row
        end
    end
    if shown == 0 then
        local empty = panel.targetContent.empty
        if not empty then
            empty = Text(panel.targetContent, "GameFontHighlightSmall", "No supported frames match this filter.", C.muted)
            empty:SetPoint("TOPLEFT", 7, 0); empty:SetWidth(154); empty:SetJustifyH("LEFT"); empty:SetWordWrap(true)
            panel.targetContent.empty = empty
        end
        empty:SetText(panel.managedOnly and "This profile has no managed frames matching the filter." or "No supported frames match this filter.")
        empty:Show(); panel.targetContent._rows[#panel.targetContent._rows + 1] = empty; y = 38
    end
    panel.targetContent:SetHeight(math.max(1, y))
    if panel.targetScroll then
        panel.targetScroll:SetVerticalScroll(math.min(panel.targetScroll:GetVerticalScroll(), panel.targetScroll:GetVerticalScrollRange()))
    end
end

function ns:RenderOptions()
    local panel = self.Options
    if not panel or not panel:IsVisible() then return end
    self:ApplyEditorTheme()
    if panel.cinematicView then
        if self.SelectionOutline then self.SelectionOutline:Hide() end
        self:RenderCinematicOptions()
        return
    end
    if panel.profile then
        panel.profile:GetFontString():SetText(self:IsCinematicActive() and "Editing: Cinematic" or ("Profile: " .. ShortText(PriorityFaderDB.profile or "Default", 16)))
        panel.profile:SetBackdropBorderColor(unpack(self:IsCinematicActive() and CINEMATIC_ACCENT or C.border))
        panel.profile:GetFontString():SetTextColor(unpack(self:IsCinematicActive() and CINEMATIC_ACCENT or C.accent))
    end
    if not panel.selected or not self.TargetByID[panel.selected] then
        panel.selected = nil
        for _, target in ipairs(self.Targets) do
            if self:Profile().targets[target.id] then panel.selected = target.id; break end
        end
    end
    self:RenderTargetRail()
    self:RenderSelectedTarget(panel.selected)
    self:RefreshSelectionOutline()
end

function ns:RefreshSelectionOutline()
    local outline, panel = self.SelectionOutline, self.Options
    if not outline or not panel or (not panel:IsVisible() and not panel.peeking) or panel.cinematicView
        or panel.selectionOutlineEnabled == false or not panel.selected then
        if outline then outline:Hide() end
        return
    end
    local frame = self:ResolveTarget(panel.selected)
    local left, bottom, width, height
    if frame then left, bottom, width, height = self:GetUsableFrameRect(frame) end
    if not left then outline:Hide(); return end
    outline:ClearAllPoints()
    outline:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", left - 3, bottom - 3)
    outline:SetSize(width + 6, height + 6)
    outline:SetBackdropBorderColor(unpack(C.teal))
    outline:Show()
end

function ns:RenderSelectedTarget(id)
    local panel = self.Options
    ClearChildren(panel.reactionContent); ClearChildren(panel.presenceContent)
    local target = self.TargetByID[id]
    local settings = target and self:GetTargetSettings(id) or nil
    local canForget = target ~= nil and self:CanForgetCustomTarget(id)
    panel.forgetTarget:SetShown(canForget)
    if panel.forgetArmed ~= id then
        panel.forgetArmed = nil
        panel.forgetTarget:GetFontString():SetText("Remove from list")
    end
    local canPaste = target ~= nil and self:CanPasteTargetRules()
    panel.copyRules:SetEnabled(settings ~= nil); panel.copyRules:SetAlpha(settings and 1 or 0.42)
    panel.pasteRules:SetEnabled(canPaste); panel.pasteRules:SetAlpha(canPaste and 1 or 0.42)
    panel.pasteRules._selected, panel.pasteRules._selectedColor = canPaste, canPaste and { 0.05, 0.18, 0.17, 1 } or nil
    panel.pasteRules:SetBackdropColor(unpack(canPaste and { 0.05, 0.18, 0.17, 1 } or C.cardAlt))
    panel.pasteRules:SetBackdropBorderColor(unpack(canPaste and C.teal or C.border))
    panel.pasteRules:GetFontString():SetTextColor(unpack(canPaste and C.teal or C.muted))
    if not target then
        panel.centerTitle:SetText("Pick a frame to begin")
        panel.active:SetText("Your existing UI stays untouched until you choose a target.")
        panel.active:SetTextColor(unpack(C.muted))
        local begin = Button(panel.reactionContent, "Pick a frame", 116, function() ns:StartPicker() end, true)
        begin:SetPoint("TOPLEFT", 0, 0)
        panel.reactionContent._rows[#panel.reactionContent._rows + 1] = begin
        panel.reactionContent:SetHeight(30)
        return
    end
    local available, _, status, statusNote, statusTone = self:GetTargetAvailability(target)
    if not available then
        panel.centerTitle:SetText(target.label .. " is unavailable")
        panel.active:SetText(status)
        panel.active:SetTextColor(unpack(C[statusTone] or C.amber))
        local detail = Text(panel.reactionContent, "GameFontHighlightSmall", statusNote, C.muted)
        detail:SetPoint("TOPLEFT", 0, 0); detail:SetPoint("RIGHT", -10, 0); detail:SetJustifyH("LEFT"); detail:SetWordWrap(true)
        panel.reactionContent._rows[#panel.reactionContent._rows + 1] = detail
        local help = Text(panel.reactionContent, "GameFontHighlightSmall", "The saved rules remain intact. Return when this UI element exists, or reset the target to remove them.", C.muted)
        help:SetPoint("TOPLEFT", detail, "BOTTOMLEFT", 0, -10); help:SetPoint("RIGHT", -10, 0); help:SetJustifyH("LEFT"); help:SetWordWrap(true)
        panel.reactionContent._rows[#panel.reactionContent._rows + 1] = help
        panel.reactionContent:SetHeight(82)
        return
    end
    panel.centerTitle:SetText(target.label .. " reacts")
    if not settings then
        panel.active:SetText("Not controlled yet")
        panel.active:SetTextColor(unpack(C.muted))
        local use = Button(panel.reactionContent, "Use this frame", 130, function()
            ns:AddTarget(id)
            ns:RenderOptions()
        end, true)
        use:SetPoint("TOPLEFT", 0, 0)
        panel.reactionContent._rows[#panel.reactionContent._rows + 1] = use
        local help = Text(panel.reactionContent, "GameFontHighlightSmall", "Priority Fader starts with Mouseover and In combat at 100%, then fades to 12% at rest.", C.muted)
        help:SetPoint("TOPLEFT", use, "BOTTOMLEFT", 0, -10)
        help:SetPoint("RIGHT", -10, 0)
        help:SetJustifyH("LEFT"); help:SetWordWrap(true)
        panel.reactionContent._rows[#panel.reactionContent._rows + 1] = help
        panel.reactionContent:SetHeight(70)
        return
    end
    self:RefreshActiveState()

    local y = 0
    local activeState = ns.runtime.active[id]
    panel.reactionContent._reactionRows = panel.reactionContent._reactionRows or {}
    for index, reaction in ipairs(settings.reactions) do
        local reactionIndex, reactionData = index, reaction
        local row = panel.reactionContent._reactionRows[index]
        if not row then
            row = NewReactionRow(panel.reactionContent)
            panel.reactionContent._reactionRows[index] = row
        end
        row:Show(); row:ClearAllPoints(); row:SetPoint("TOPLEFT", 0, -y); row:SetPoint("TOPRIGHT", 0, -y)
        row.handle._targetID, row.handle._reaction, row.handle._row = id, reactionData, row
        local isActive = activeState and activeState.index == index
        row.handle.label:SetTextColor(unpack(isActive and C.teal or C.muted))
        row:SetBackdropColor(unpack(isActive and { 0.05, 0.18, 0.17, 1 } or C.cardAlt))
        row:SetBackdropBorderColor(unpack(isActive and C.teal or C.border))
        local requirementCount = #(reactionData.requirements or {})
        local info = ns.CONDITION_INFO[reactionData.condition]
        local isMoment = info and info.kind == "moment"
        row.label:ClearAllPoints(); row.label:SetPoint("LEFT", 29, 0)
        row.label:SetPoint("RIGHT", isMoment and row.duration or row.requirements, "LEFT", -5)
        row.label:SetText(ConditionLabel(reactionData.condition) .. (requirementCount > 0 and " + " .. requirementCount or "")); row.opacity:GetFontString():SetText(Percent(reactionData.opacity))
        row.label:SetTextColor(unpack(isActive and C.teal or C.accent))
        row.opacity:SetScript("OnClick", function(self, button)
            ns:OpenOpacityPicker(ConditionLabel(reactionData.condition), reactionData.opacity, function(value)
                reactionData.opacity = value
                ns:InvalidateTargetTransition(id)
                row.opacity:GetFontString():SetText(Percent(value))
            end, row.opacity)
        end)
        row.requirements:GetFontString():SetText(requirementCount > 0 and "+" .. requirementCount or "+")
        row.requirements:SetScript("OnClick", function() ns:OpenRequirementPalette(id, reactionData) end)
        if isMoment then
            row.duration:Show(); row.duration:GetFontString():SetText(Seconds(reactionData.duration or info.duration))
            row.duration:SetScript("OnClick", function()
                ns:OpenDurationPicker(ConditionLabel(reactionData.condition), reactionData.duration or info.duration, function(value)
                    reactionData.duration = value
                    row.duration:GetFontString():SetText(Seconds(value))
                end)
            end)
        else
            row.duration:Hide(); row.duration:SetScript("OnClick", nil)
        end
        row.up:SetScript("OnClick", function()
            if reactionIndex > 1 then settings.reactions[reactionIndex], settings.reactions[reactionIndex - 1] = settings.reactions[reactionIndex - 1], settings.reactions[reactionIndex]; ns:InvalidateTargetTransition(id); ns:RenderSelectedTarget(id) end
        end)
        row.down:SetScript("OnClick", function()
            if reactionIndex < #settings.reactions then settings.reactions[reactionIndex], settings.reactions[reactionIndex + 1] = settings.reactions[reactionIndex + 1], settings.reactions[reactionIndex]; ns:InvalidateTargetTransition(id); ns:RenderSelectedTarget(id) end
        end)
        row.remove:SetScript("OnClick", function()
            if reactionData.condition == "mouseover" and #(reactionData.requirements or {}) == 0
                and ns:RequiresUnconditionalMouseover(id) and ns:CountUnconditionalMouseover(settings) <= 1 then
                panel.active:SetText("This reveal-group member needs one unconditional Mouseover reaction.")
                panel.active:SetTextColor(unpack(C.amber))
                return
            end
            table.remove(settings.reactions, reactionIndex)
            ns:InvalidateTargetTransition(id)
            ns:RenderSelectedTarget(id)
        end)
        panel.reactionContent._rows[#panel.reactionContent._rows + 1] = row; y = y + 45
    end
    local add = Button(panel.reactionContent, "+ Add reaction", 130, function() ns:OpenReactionPalette(id) end, true)
    add:SetPoint("TOPLEFT", 0, -y); panel.reactionContent._rows[#panel.reactionContent._rows + 1] = add; y = y + 38
    local rest = CreateFrame("Frame", nil, panel.reactionContent, "BackdropTemplate")
    rest:SetSize(10, 39); rest:SetPoint("TOPLEFT", 0, -y); rest:SetPoint("TOPRIGHT", 0, -y); Backdrop(rest, { 0.045, 0.05, 0.07, 1 })
    local restLabel = Text(rest, "GameFontHighlight", "Otherwise", C.muted); restLabel:SetPoint("LEFT", 29, 0)
    local visibilityParent = ns:GetVisibilityParent(id)
    local visibilityParentTarget = visibilityParent and ns.TargetByID[visibilityParent]
    local restOpacity
    restOpacity = Button(rest, visibilityParent and ("Follow " .. (visibilityParentTarget and visibilityParentTarget.label or visibilityParent)) or Percent(settings.atRest), visibilityParent and 132 or 54, function(self, button)
        if visibilityParent then return end
        ns:OpenOpacityPicker("Otherwise", settings.atRest, function(value)
            settings.atRest = value
            ns:InvalidateTargetTransition(id)
            restOpacity:GetFontString():SetText(Percent(value))
        end, restOpacity)
    end)
    restOpacity:SetEnabled(not visibilityParent)
    restOpacity:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    SetTooltip(restOpacity, visibilityParent and "Inherited visibility" or "Otherwise opacity",
        visibilityParent and "No local reaction matched, so this frame uses its visibility parent's resolved opacity." or "Choose a preset or drag to a precise visibility level.")
    restOpacity:SetPoint("RIGHT", -8, 0); panel.reactionContent._rows[#panel.reactionContent._rows + 1] = rest
    y = y + 39
    panel.reactionContent:SetHeight(math.max(1, y))
    if panel.reactionScroll then
        panel.reactionScroll:SetVerticalScroll(math.min(panel.reactionScroll:GetVerticalScroll(), panel.reactionScroll:GetVerticalScrollRange()))
    end

    local p = panel.presenceContent
    local capability, capabilityNote, capabilityTone = ns:GetTargetCapability(target)
    local cap = Text(p, "GameFontHighlightSmall", capability, C[capabilityTone] or C.accent)
    cap:SetPoint("TOPLEFT", 0, 0); cap:SetWidth(152); cap:SetWordWrap(false); p._rows[#p._rows + 1] = cap
    local explain = Text(p, "GameFontHighlightSmall", capabilityNote, C.muted)
    explain:SetPoint("TOPLEFT", cap, "BOTTOMLEFT", 0, -5); explain:SetPoint("RIGHT", -2, 0); explain:SetJustifyH("LEFT"); explain:SetWordWrap(true); p._rows[#p._rows + 1] = explain
    local timing = Button(p, string.format("Fade %.2fs / wait %.2fs", settings.fadeDuration, settings.fadeDelay), 142, function()
        ns:OpenTimingPicker(id, settings)
    end)
    SetTooltip(timing, "Frame timing", "Set transition time and how long Priority Fader waits before fading down.")
    timing:SetPoint("TOPLEFT", explain, "BOTTOMLEFT", 0, -15); p._rows[#p._rows + 1] = timing
    local preview
    preview = Button(p, panel.selectionOutlineEnabled == false and "Frame outline: Off" or "Frame outline: On", 142, function()
        panel.selectionOutlineEnabled = not panel.selectionOutlineEnabled
        preview:GetFontString():SetText(panel.selectionOutlineEnabled and "Frame outline: On" or "Frame outline: Off")
        preview._selected = panel.selectionOutlineEnabled
        preview:SetBackdropColor(unpack(panel.selectionOutlineEnabled and C.teal or C.cardAlt))
        preview:GetFontString():SetTextColor(unpack(panel.selectionOutlineEnabled and { 0.02, 0.06, 0.07, 1 } or C.accent))
        ns:RefreshSelectionOutline()
    end)
    preview._selected = panel.selectionOutlineEnabled ~= false; preview._selectedColor = C.teal
    preview:SetBackdropColor(unpack(preview._selected and C.teal or C.cardAlt))
    preview:GetFontString():SetTextColor(unpack(preview._selected and { 0.02, 0.06, 0.07, 1 } or C.accent))
    SetTooltip(preview, "Frame outline", "Keeps a live boundary around the frame you are editing. It never changes frame opacity or mouse behavior.")
    preview:SetPoint("TOPLEFT", timing, "BOTTOMLEFT", 0, -6); p._rows[#p._rows + 1] = preview
    local group = Button(p, "+ Hover group", 142, function() ns:OpenConnectionPicker("group", id) end)
    group:SetPoint("TOPLEFT", preview, "BOTTOMLEFT", 0, -6); p._rows[#p._rows + 1] = group
    local link = Button(p, "+ Linked child", 142, function() ns:OpenConnectionPicker("link", id) end)
    link:SetPoint("TOPLEFT", group, "BOTTOMLEFT", 0, -6); p._rows[#p._rows + 1] = link
    SetTooltip(link, "Linked child", "Hovering this source reveals the child. The child reveals itself only if you keep or add a Mouseover rule on that child.")
    local visibility = Button(p, "+ Visibility child", 142, function() ns:OpenConnectionPicker("visibility", id) end)
    visibility:SetPoint("TOPLEFT", link, "BOTTOMLEFT", 0, -6); p._rows[#p._rows + 1] = visibility
    SetTooltip(visibility, "Visibility child", "The child's own matching rules run first. When none match, it follows this frame's final rule opacity.")
    local previous = visibility
    local _, revealGroup = ns:GetRevealGroup(id)
    if revealGroup then
        local count = 0; for _ in pairs(revealGroup.members) do count = count + 1 end
        local together = Text(p, "GameFontHighlightSmall", "Together: " .. count .. " frames", C.teal)
        together:SetPoint("TOPLEFT", previous, "BOTTOMLEFT", 0, -14); p._rows[#p._rows + 1] = together
        local leave = Button(p, "Leave", 54, function()
            ns:RemoveFromRevealGroup(id); ns:RenderSelectedTarget(id)
        end)
        leave:SetPoint("TOPLEFT", together, "BOTTOMLEFT", 0, -4); p._rows[#p._rows + 1] = leave; previous = leave
    end
    local children = ns:GetLinkedChildren(id)
    local childCount = 0; for _ in pairs(children) do childCount = childCount + 1 end
    if childCount > 0 then
        local reveals = Text(p, "GameFontHighlightSmall", "Reveals: " .. childCount .. " frame" .. (childCount == 1 and "" or "s"), C.teal)
        reveals:SetPoint("TOPLEFT", previous, "BOTTOMLEFT", 0, -12); p._rows[#p._rows + 1] = reveals
        local clear = Button(p, "Clear links", 82, function()
            local linked = {}; for childID in pairs(ns:GetLinkedChildren(id)) do linked[#linked + 1] = childID end
            for _, childID in ipairs(linked) do ns:RemoveLink(id, childID) end
            ns:RenderSelectedTarget(id)
        end)
        clear:SetPoint("TOPLEFT", reveals, "BOTTOMLEFT", 0, -4); p._rows[#p._rows + 1] = clear; previous = clear
    end
    local parents = ns:GetLinkParents(id)
    if #parents > 0 then
        local revealedBy = Text(p, "GameFontHighlightSmall", "Revealed by: " .. #parents .. " source" .. (#parents == 1 and "" or "s"), C.muted)
        revealedBy:SetPoint("TOPLEFT", previous, "BOTTOMLEFT", 0, -12); p._rows[#p._rows + 1] = revealedBy
        local unlink = Button(p, "Unlink me", 74, function()
            for _, parentID in ipairs(ns:GetLinkParents(id)) do ns:RemoveLink(parentID, id) end
            ns:RenderSelectedTarget(id)
        end)
        unlink:SetPoint("TOPLEFT", revealedBy, "BOTTOMLEFT", 0, -4); p._rows[#p._rows + 1] = unlink
        previous = unlink
    end
    local visibilityChildren = ns:GetVisibilityChildren(id)
    local visibilityCount = 0; for _ in pairs(visibilityChildren) do visibilityCount = visibilityCount + 1 end
    if visibilityCount > 0 then
        local follows = Text(p, "GameFontHighlightSmall", "Visibility children: " .. visibilityCount, C.teal)
        follows:SetPoint("TOPLEFT", previous, "BOTTOMLEFT", 0, -12); p._rows[#p._rows + 1] = follows
        local clear = Button(p, "Clear", 54, function()
            local ids = {}; for childID in pairs(ns:GetVisibilityChildren(id)) do ids[#ids + 1] = childID end
            for _, childID in ipairs(ids) do ns:RemoveVisibilityLink(id, childID) end
            ns:RenderSelectedTarget(id)
        end)
        clear:SetPoint("TOPLEFT", follows, "BOTTOMLEFT", 0, -4); p._rows[#p._rows + 1] = clear; previous = clear
    end
    local visibilityParent = ns:GetVisibilityParent(id)
    if visibilityParent then
        local parentTarget = ns.TargetByID[visibilityParent]
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
