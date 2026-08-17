local ADDON, ns = ...

-- A deliberately self-contained help layer.  It teaches the editor without
-- touching target settings, profiles, or another addon's frames.
local C = ns.COLORS
local WHITE = "Interface\\Buttons\\WHITE8X8"
local TITLE = "GameFontNormalLarge"
local BODY = "GameFontHighlightSmall"

local function Backdrop(frame, fill, border)
    frame:SetBackdrop({ bgFile = WHITE, edgeFile = WHITE, edgeSize = 1 })
    frame:SetBackdropColor(unpack(fill or C.card))
    frame:SetBackdropBorderColor(unpack(border or C.border))
end

local function Text(parent, font, value, color)
    local text = parent:CreateFontString(nil, "ARTWORK", font or BODY)
    text:SetText(value or "")
    text:SetTextColor(unpack(color or C.muted))
    return text
end

local function Button(parent, label, width, callback, primary)
    local button = CreateFrame("Button", nil, parent, "BackdropTemplate")
    button:SetHeight(22); button:SetWidth(width or 94)
    button._primary = primary
    Backdrop(button, primary and C.accent or C.cardAlt, C.border)
    local text = Text(button, "GameFontNormalSmall", label, primary and { 1, 1, 1, 1 } or C.accent)
    text:SetPoint("CENTER")
    button:SetFontString(text)
    button:SetScript("OnEnter", function(self)
        self:SetBackdropBorderColor(unpack(self._primary and C.teal or C.accent))
        if self._primary then self:SetBackdropColor(0.52, 0.36, 0.90, 1) end
    end)
    button:SetScript("OnLeave", function(self)
        self:SetBackdropBorderColor(unpack(C.border))
        self:SetBackdropColor(unpack(self._primary and C.accent or C.cardAlt))
    end)
    button:SetScript("OnClick", callback)
    return button
end

local function CloseButton(parent, callback)
    local button = CreateFrame("Button", nil, parent, "BackdropTemplate")
    button:SetSize(24, 24); button:SetFrameLevel(parent:GetFrameLevel() + 12)
    Backdrop(button, C.cardAlt, C.border)
    local strokes = {}
    for _, angle in ipairs({ math.pi / 4, -math.pi / 4 }) do
        local stroke = button:CreateTexture(nil, "ARTWORK")
        stroke:SetTexture(WHITE); stroke:SetSize(2, 13); stroke:SetPoint("CENTER")
        stroke:SetRotation(angle); stroke:SetVertexColor(unpack(C.accent))
        table.insert(strokes, stroke)
    end
    button:SetScript("OnEnter", function(self)
        self:SetBackdropBorderColor(unpack(C.teal)); for _, s in ipairs(strokes) do s:SetVertexColor(unpack(C.teal)) end
    end)
    button:SetScript("OnLeave", function(self)
        self:SetBackdropBorderColor(unpack(C.border)); for _, s in ipairs(strokes) do s:SetVertexColor(unpack(C.accent)) end
    end)
    button:SetScript("OnClick", callback)
    return button
end

local function GetState()
    if ns.GetTutorialState then
        local step, completed = ns:GetTutorialState()
        return tonumber(step) or 1, completed == true
    end
    return 1, false
end

local function SaveState(step, completed)
    if ns.SetTutorialState then ns:SetTutorialState(step, completed == true) end
end

local function Notice(message, color)
    local panel = ns.Options
    if panel and panel.active then
        panel.active:SetText(message)
        panel.active:SetTextColor(unpack(color or C.amber))
    end
end

local function IsCombat()
    return InCombatLockdown and InCombatLockdown() or false
end

local function CreateOutline()
    if ns.TutorialOutline then return ns.TutorialOutline end
    local outline = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    outline:SetFrameStrata("FULLSCREEN_DIALOG"); outline:SetFrameLevel(880); outline:EnableMouse(false)
    Backdrop(outline, { 0, 0, 0, 0 }, C.teal); outline:Hide()
    local group = outline:CreateAnimationGroup()
    group:SetLooping("REPEAT")
    local fade = group:CreateAnimation("Alpha"); fade:SetOrder(1); fade:SetFromAlpha(0.55); fade:SetToAlpha(1); fade:SetDuration(0.65); fade:SetSmoothing("IN_OUT")
    local fadeBack = group:CreateAnimation("Alpha"); fadeBack:SetOrder(2); fadeBack:SetFromAlpha(1); fadeBack:SetToAlpha(0.55); fadeBack:SetDuration(0.65); fadeBack:SetSmoothing("IN_OUT")
    outline.pulse = group
    ns.TutorialOutline = outline
    return outline
end

local function ClearOutline()
    local outline = ns.TutorialOutline
    if outline then outline.pulse:Stop(); outline:Hide() end
end

local function SafeShown(frame)
    if not frame or not frame.IsShown then return false end
    local ok, shown = pcall(frame.IsShown, frame)
    return ok and not (issecretvalue and issecretvalue(shown)) and shown == true
end

local function Highlight(frame)
    local outline = CreateOutline()
    if not SafeShown(frame) then ClearOutline(); return end
    local left, bottom, width, height
    if ns.GetUsableFrameRect then
        left, bottom, width, height = ns:GetUsableFrameRect(frame)
    end
    if not left or not bottom or not width or not height or width < 2 or height < 2 then ClearOutline(); return end
    outline:ClearAllPoints(); outline:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", left - 3, bottom - 3)
    outline:SetSize(width + 6, height + 6); outline:Show(); outline.pulse:Play()
end

local function EnsureOptions()
    if ns.CreateOptions then ns:CreateOptions() end
    if ns.Options and not ns.Options:IsShown() then ns.Options:Show() end
    return ns.Options
end

local function FindControl(kind)
    local panel = ns.Options
    if not panel then return nil end
    if kind == "targets" then return panel.targets end
    if kind == "pick" then return panel.pickButton or panel.targets end
    if kind == "selected" then return panel.tutorialSelectedRow or panel.targets end
    if kind == "center" then return panel.center end
    if kind == "add" then return panel.addReactionButton or panel.center end
    if kind == "otherwise" then return panel.otherwiseRow or panel.center end
    if kind == "managed" then return panel.managedOnlyButton end
    if kind == "tree" then return panel.treeViewButton end
    if kind == "filter" then return panel.targetFilter end
    if kind == "outline" then return panel.outlineButton or (panel.selectionOutlineEnabled and ns.SelectionOutline) end
    if kind == "cinematic" then return panel.cinematic end
    return nil
end

local STEPS = {
    { title = "Welcome to Frame Gambit", body = "Choose a frame. Tell it when to appear. Ordered rules decide its opacity. This short practice does not change your UI.", focus = "targets" },
    { title = "1. Choose and manage", body = "Try the practice frame below. In the real editor, Pick on screen and Discover visible UI find frames; the teal square means the profile manages one.", focus = "targets", practice = "select" },
    { title = "2. Add a reaction", body = "Add Mouseover to the practice frame. A reaction says: when this is true, use this opacity. Combat, Casting, and more work the same way.", focus = "center", practice = "reaction" },
    { title = "3. A gambit is priority", body = "Frame Gambit checks reactions from top to bottom. The first matching reaction wins. Try the board below.", focus = "center", board = true },
    { title = "4. Otherwise is rest", body = "No reaction matched? Otherwise decides the quiet opacity. Try the practice value. A low value keeps the screen calm without hiding or restyling the frame.", focus = "otherwise", practice = "otherwise" },
    { title = "5. See what you edit", body = "Frame outline marks the real frame you are editing. After the tour, Peek can collapse the editor while keeping that outline visible.", focus = "outline" },
    { title = "6. Let frames work together", body = "Hover groups reveal together. Linked children reveal from a source. Visibility children can follow a parent. Cinematic is a separate, calm profile.", focus = "cinematic" },
    { title = "You are ready", body = "Finish the tour, then use Pick on screen for a real frame. Start with Mouseover at 100% and Otherwise at 0–20%. Add Combat or Casting only when it helps.", focus = "pick", finish = true },
}

local function CanAdvance(tutorial)
    if tutorial.step == 2 then return tutorial.practiceSelected == true, "Manage the practice frame first." end
    if tutorial.step == 3 then return tutorial.practiceReaction == true, "Add Mouseover to the practice frame." end
    if tutorial.step == 4 then return tutorial.boardTried == true, "Try a state or swap the rule order." end
    if tutorial.step == 5 then return tutorial.otherwiseTried == true, "Try the Otherwise value." end
    return true
end

local function CreateHelp()
    if ns.HelpCenter then return ns.HelpCenter end
    local parent = EnsureOptions() or UIParent
    local help = CreateFrame("Frame", "FrameGambitHelpCenter", parent, "BackdropTemplate")
    help:SetFrameStrata("FULLSCREEN_DIALOG"); help:SetFrameLevel((parent:GetFrameLevel() or 500) + 80); help:SetToplevel(true); help:EnableMouse(true)
    help:SetPoint("TOPLEFT", parent, "TOPLEFT", 26, -26); help:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -26, 26)
    Backdrop(help, C.panel, C.teal); help:Hide()
    local title = Text(help, TITLE, "Help Center", C.teal); title:SetPoint("TOPLEFT", 22, -19)
    local sub = Text(help, BODY, "Clear answers, then a quick hands-on tour.", C.muted); sub:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -4)
    CloseButton(help, function() ns:CloseHelp() end):SetPoint("TOPRIGHT", -7, -7)

    local topics = {
        { "Start here", "Pick a frame, add a reaction, set Otherwise. That is the complete loop." },
        { "Gambit priority", "Top to bottom matters. The first matching reaction decides the opacity." },
        { "Relationships", "Groups reveal together. Links have a source. Visibility children can follow a parent." },
        { "Cinematic", "A separate calm scene for questing. Your normal profile is left alone." },
        { "Safety", "Frame Gambit only layers final opacity. It does not move, restyle, reparent, or change secure controls." },
        { "Troubleshooting", "Use Discover visible UI, select the right root, then use Frame outline or Peek to confirm it." },
    }
    help.topicButtons, help.topicBodies = {}, {}
    local rail = CreateFrame("Frame", nil, help, "BackdropTemplate"); rail:SetPoint("TOPLEFT", 18, -72); rail:SetPoint("BOTTOMLEFT", 18, 18); rail:SetWidth(175); Backdrop(rail, C.card, C.border)
    local page = CreateFrame("Frame", nil, help, "BackdropTemplate"); page:SetPoint("TOPLEFT", rail, "TOPRIGHT", 10, 0); page:SetPoint("BOTTOMRIGHT", -18, 18); Backdrop(page, C.card, C.border)
    help.page = page
    local pageTitle = Text(page, TITLE, "Start here", C.accent); pageTitle:SetPoint("TOPLEFT", 18, -18); help.pageTitle = pageTitle
    local pageBody = Text(page, "GameFontHighlight", "", C.muted); pageBody:SetPoint("TOPLEFT", 18, -54); pageBody:SetPoint("TOPRIGHT", -18, -54); pageBody:SetJustifyH("LEFT"); pageBody:SetJustifyV("TOP"); pageBody:SetWordWrap(true); help.pageBody = pageBody
    for i, topic in ipairs(topics) do
        local topicIndex, topicData = i, topic
        local button = Button(rail, topicData[1], 151, function()
            help.pageTitle:SetText(topicData[1]); help.pageBody:SetText(topicData[2])
            for index, other in ipairs(help.topicButtons) do
                other._primary = index == topicIndex; other:SetBackdropColor(unpack(index == topicIndex and C.accent or C.cardAlt))
                other:GetFontString():SetTextColor(unpack(index == topicIndex and { 1, 1, 1, 1 } or C.accent))
            end
        end, i == 1)
        button:SetPoint("TOPLEFT", rail, "TOPLEFT", 12, -14 - (i - 1) * 31); help.topicButtons[i] = button
    end
    help.pageBody:SetText(topics[1][2])
    local start = Button(page, "Start guided tutorial", 174, function() ns:StartTutorial() end, true)
    start:SetPoint("BOTTOMLEFT", 18, 18); help.start = start
    local restart = Button(page, "Restart tutorial", 130, function() ns:StartTutorial(1) end)
    restart:SetPoint("LEFT", start, "RIGHT", 8, 0); help.restart = restart
    local audit = Button(page, "Run audit", 86, function() if ns.RunDiagnostics then ns:RunDiagnostics() end; Notice("Frame Gambit audit printed to chat.", C.teal) end)
    audit:SetPoint("BOTTOMRIGHT", -18, 18)
    local auditHint = Text(page, BODY, "Not sure what is available? Run an audit; it only reports.", C.muted); auditHint:SetPoint("BOTTOMRIGHT", audit, "TOPRIGHT", 0, 8)
    help:SetScript("OnHide", function()
        -- Help is a child modal. Closing the editor also closes it, but does
        -- not change tutorial progress.
        ClearOutline()
    end)
    ns.HelpCenter = help
    return help
end

local function CreateTutorial()
    if ns.TutorialCard then return ns.TutorialCard end
    local card = CreateFrame("Frame", "FrameGambitTutorial", UIParent, "BackdropTemplate")
    card:SetSize(390, 220); card:SetFrameStrata("FULLSCREEN_DIALOG"); card:SetFrameLevel(890); card:SetToplevel(true); card:EnableMouse(true); card:SetClampedToScreen(true)
    Backdrop(card, C.panel, C.teal); card:Hide()
    local kicker = Text(card, BODY, "GUIDED TOUR", C.teal); kicker:SetPoint("TOPLEFT", 16, -14)
    local title = Text(card, TITLE, "", C.accent); title:SetPoint("TOPLEFT", 16, -33); card.title = title
    local body = Text(card, "GameFontHighlight", "", C.muted); body:SetPoint("TOPLEFT", 16, -65); body:SetPoint("TOPRIGHT", -16, -65); body:SetJustifyH("LEFT"); body:SetJustifyV("TOP"); body:SetWordWrap(true); card.body = body
    local progress = Text(card, BODY, "", C.muted); progress:SetPoint("BOTTOMLEFT", 16, 15); card.progress = progress
    card.back = Button(card, "Back", 58, function() ns.Tutorial.step = math.max(1, ns.Tutorial.step - 1); ns:RefreshTutorial() end)
    card.back:SetPoint("BOTTOMRIGHT", -157, 12)
    card.next = Button(card, "Next", 66, function()
        local tutorial = ns.Tutorial
        if not tutorial or tutorial.paused then return end
        local ready, message = CanAdvance(tutorial)
        if not ready then
            card.validation:SetText(message or "Try this step first.")
            return
        end
        if tutorial.step >= #STEPS then ns:CancelTutorial("complete"); return end
        tutorial.step = tutorial.step + 1; ns:RefreshTutorial()
    end, true)
    card.next:SetPoint("LEFT", card.back, "RIGHT", 6, 0)
    card.skip = Button(card, "Skip", 48, function() ns:CancelTutorial("skipped") end)
    card.skip:SetPoint("LEFT", card.next, "RIGHT", 6, 0)
    CloseButton(card, function() ns:CancelTutorial("closed") end):SetPoint("TOPRIGHT", -5, -5)

    local validation = Text(card, BODY, "", C.amber)
    validation:SetPoint("BOTTOMLEFT", 16, 39); validation:SetPoint("BOTTOMRIGHT", -16, 39)
    validation:SetJustifyH("LEFT"); card.validation = validation

    local practice = CreateFrame("Frame", nil, card, "BackdropTemplate")
    practice:SetPoint("TOPLEFT", 16, -123); practice:SetPoint("TOPRIGHT", -16, -123); practice:SetHeight(105)
    Backdrop(practice, C.cardAlt, C.border); practice:Hide(); card.practice = practice
    local practiceTitle = Text(practice, "GameFontNormal", "Practice frame", C.accent)
    practiceTitle:SetPoint("TOPLEFT", 12, -10)
    local practiceStatus = Text(practice, BODY, "Not managed", C.muted)
    practiceStatus:SetPoint("TOPRIGHT", -12, -11); practice.status = practiceStatus
    practice.manage = Button(practice, "Manage practice frame", 145, function()
        if not ns.Tutorial then return end
        ns.Tutorial.practiceSelected = true
        ns:RefreshTutorial()
    end, true)
    practice.manage:SetPoint("TOPLEFT", 12, -38)
    practice.add = Button(practice, "+ Mouseover -> 100%", 145, function()
        if not ns.Tutorial or not ns.Tutorial.practiceSelected then return end
        ns.Tutorial.practiceReaction = true
        ns:RefreshTutorial()
    end, true)
    practice.add:SetPoint("TOPLEFT", 12, -38)
    practice.otherwise = Button(practice, "Otherwise -> 12%", 145, function(self)
        if not ns.Tutorial then return end
        ns.Tutorial.otherwiseTried = true
        ns.Tutorial.practiceOtherwise = ns.Tutorial.practiceOtherwise == 0 and 12 or 0
        self:GetFontString():SetText("Otherwise -> " .. ns.Tutorial.practiceOtherwise .. "%")
        ns:RefreshTutorial()
    end)
    practice.otherwise:SetPoint("TOPLEFT", 12, -38)
    local practiceHint = Text(practice, BODY, "Safe practice only - your profiles stay untouched.", C.muted)
    practiceHint:SetPoint("BOTTOMLEFT", 12, 10)

    local board = CreateFrame("Frame", nil, card, "BackdropTemplate")
    board:SetPoint("TOPLEFT", 16, -123); board:SetPoint("TOPRIGHT", -16, -123); board:SetHeight(100); Backdrop(board, C.cardAlt, C.border); board:Hide()
    card.board = board; board.rows = { "Mouseover", "In combat", "Otherwise" }
    for i = 1, 3 do
        local label = Text(board, BODY, board.rows[i], i == 3 and C.muted or C.accent)
        label:SetPoint("TOPLEFT", 12, -7 - (i - 1) * 20); board["row" .. i] = label
    end
    board.row1:SetText("1  Mouseover -> 100%")
    board.row2:SetText("2  In combat -> 60%")
    board.row3:SetText("Otherwise -> 12%")
    local swap = Button(board, "Swap rows", 78, function()
        if ns.Tutorial then ns.Tutorial.boardTried = true end
        board.rows[1], board.rows[2] = board.rows[2], board.rows[1]
        board.row1:SetText("1  " .. board.rows[1] .. (board.rows[1] == "Mouseover" and " -> 100%" or " -> 60%"))
        board.row2:SetText("2  " .. board.rows[2] .. (board.rows[2] == "Mouseover" and " -> 100%" or " -> 60%"))
        if board.UpdateResult then board:UpdateResult() end
    end)
    swap:SetPoint("TOPRIGHT", -10, -7)
    local note = Text(board, BODY, "Both active -> Mouseover wins at 100%.", C.teal); note:SetPoint("BOTTOMLEFT", 12, 7); board.note = note
    board.selectedState = "Both"
    function board:UpdateResult()
        local state = self.selectedState or "Both"
        local result
        if state == "Quiet" then
            result = "No reaction matches -> Otherwise wins at 12%."
        elseif state == "Combat" then
            result = "In combat matches -> 60%."
        elseif state == "Hover" then
            result = "Mouseover matches -> 100%."
        else
            result = "Both match -> " .. self.rows[1] .. " wins because it is first."
        end
        self.note:SetText(result)
    end
    card.pills = {}
    for i, data in ipairs({ { "Quiet", C.muted }, { "Combat", C.amber }, { "Hover", C.teal }, { "Both", C.accent } }) do
        local stateName, stateColor, stateIndex = data[1], data[2], i
        local pill = Button(card, stateName, 56, function(self)
            if ns.Tutorial then ns.Tutorial.boardTried = true end
            for _, other in ipairs(card.pills) do other._primary = false; other:SetBackdropColor(unpack(C.cardAlt)) end
            self._primary = true; self:SetBackdropColor(unpack(stateColor))
            board.selectedState = stateName; board:UpdateResult()
        end)
        pill:SetPoint("TOPLEFT", 16 + (stateIndex - 1) * 62, -231); card.pills[stateIndex] = pill
    end
    card:SetScript("OnHide", function()
        -- Escape uses UISpecialFrames and hides the card directly.
        if ns.Tutorial and not ns.Tutorial.closing and not ns.Tutorial.hidingForCombat then ns:CancelTutorial("closed") end
    end)
    table.insert(UISpecialFrames, "FrameGambitTutorial")
    ns.TutorialCard = card
    return card
end

local function ResetTutorialDemo(card)
    local board = card and card.board
    if not board then return end
    board.rows = { "Mouseover", "In combat", "Otherwise" }
    board.row1:SetText("1  Mouseover -> 100%")
    board.row2:SetText("2  In combat -> 60%")
    board.row3:SetText("Otherwise -> 12%")
    board.selectedState = "Both"
    board:UpdateResult()
    for index, pill in ipairs(card.pills or {}) do
        pill._primary = index == 4
        pill:SetBackdropColor(unpack(index == 4 and C.accent or C.cardAlt))
    end
end

function ns:OpenHelp()
    if IsCombat() then Notice("Open Help outside combat.", C.amber); return end
    -- Help and the coach card are mutually exclusive. Save the live step
    -- before opening Help so Resume always describes the real tour state.
    if ns.Tutorial then ns:CancelTutorial("help_opened") end
    local help = CreateHelp()
    local savedStep, completed = GetState()
    if completed then
        help.start:GetFontString():SetText("Replay guided tutorial")
        help.restart:Hide()
    elseif savedStep > 1 then
        help.start:GetFontString():SetText("Resume guided tutorial")
        help.restart:Show()
    else
        help.start:GetFontString():SetText("Start guided tutorial")
        help.restart:Hide()
    end
    help:Show()
end

function ns:CloseHelp()
    if ns.HelpCenter then ns.HelpCenter:Hide() end
end

function ns:StartTutorial(requestedStep)
    if IsCombat() then Notice("The guided tutorial starts outside combat.", C.amber); return false end
    local panel = EnsureOptions()
    if not panel then return false end
    ns:CloseHelp()
    local savedStep, completed = GetState()
    local step = tonumber(requestedStep) or (completed and 1 or savedStep)
    step = math.max(1, math.min(#STEPS, step))
    ns.Tutorial = {
        step = step,
        paused = false,
        wasCompleted = completed == true,
        practiceOtherwise = 12,
        -- Practice state is intentionally not persisted. Seed only the
        -- prerequisites of a resumed step so it never becomes a dead end.
        practiceSelected = step >= 3,
        practiceReaction = step >= 4,
    }
    local card = CreateTutorial()
    ResetTutorialDemo(card)
    card:Show(); ns:RefreshTutorial()
    return true
end

function ns:CancelTutorial(reason)
    local tutorial = ns.Tutorial
    if not tutorial then return end
    local completed = reason == "complete" or tutorial.wasCompleted == true
    SaveState(completed and #STEPS or tutorial.step or 1, completed)
    ClearOutline()
    tutorial.closing = true
    if ns.TutorialCard then ns.TutorialCard:Hide() end
    ns.Tutorial = nil
    if ns.Options and ns.Options.helpButton and ns.Options.helpButton.tutorialDot then
        ns.Options.helpButton.tutorialDot:SetShown(not completed)
    end
    if completed then Notice("Tutorial complete. You can restart it any time from Help.", C.teal) end
end

function ns:RefreshTutorial()
    local tutorial, card = ns.Tutorial, ns.TutorialCard
    if not tutorial or not card or not card:IsShown() then return end
    if IsCombat() then ns:OnTutorialCombatStateChanged(true); return end
    local step = STEPS[tutorial.step] or STEPS[1]
    card.title:SetText(step.title); card.body:SetText(step.body)
    card.validation:SetText("")
    card.progress:SetText("Step " .. tutorial.step .. " of " .. #STEPS)
    card.back:SetShown(tutorial.step > 1); card.next:GetFontString():SetText(step.finish and "Finish" or "Next")
    local expanded = step.board == true or step.practice ~= nil
    card:SetHeight(expanded and 330 or 220)
    card.board:SetShown(step.board == true)
    for _, pill in ipairs(card.pills) do pill:SetShown(step.board == true) end
    card.practice:SetShown(step.practice ~= nil)
    card.practice.manage:SetShown(step.practice == "select")
    card.practice.add:SetShown(step.practice == "reaction")
    card.practice.otherwise:SetShown(step.practice == "otherwise")
    if step.practice then
        card.practice.status:SetText(tutorial.practiceSelected and "Managed" or "Not managed")
        card.practice.status:SetTextColor(unpack(tutorial.practiceSelected and C.teal or C.muted))
        card.practice.manage:GetFontString():SetText(tutorial.practiceSelected and "Practice frame managed" or "Manage practice frame")
        card.practice.add:GetFontString():SetText(tutorial.practiceReaction and "Mouseover added" or "+ Mouseover -> 100%")
        card.practice.otherwise:GetFontString():SetText("Otherwise -> " .. (tutorial.practiceOtherwise or 12) .. "%")
    end
    local target = FindControl(step.focus)
    Highlight(target)
    -- Put the card beside the highlighted target whenever there is room; the
    -- editor stays clickable and the explanation never sits on its target.
    card:SetScale(1)
    card:ClearAllPoints()
    local panel = ns.Options
    local compact = UIParent:GetWidth() < 1000 or UIParent:GetHeight() < 650
        or (panel and (panel:GetWidth() <= 800 or panel:GetHeight() <= 540))
    if compact then
        -- On a small viewport there is no honest way to fit the card beside a
        -- large editor pane. Dock it compactly and remove the competing box.
        ClearOutline()
        card:SetScale(0.88)
        card:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -14, 14)
        return
    end
    if SafeShown(target) then
        local left, bottom, width, height
        if ns.GetUsableFrameRect then
            left, bottom, width, height = ns:GetUsableFrameRect(target)
        end
        if left and bottom and width and height and left + width + 406 < UIParent:GetWidth() then
            card:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", left + width + 12, bottom + height)
        elseif left and bottom and width and height and left - 406 > 0 then
            card:SetPoint("TOPRIGHT", UIParent, "BOTTOMLEFT", left - 12, bottom + height)
        else
            card:SetPoint("CENTER", UIParent, "CENTER", 0, -UIParent:GetHeight() * 0.24)
        end
    else
        card:SetPoint("CENTER", UIParent, "CENTER", 0, -UIParent:GetHeight() * 0.24)
    end
end

function ns:OnTutorialCombatStateChanged(inCombat)
    local tutorial, card = ns.Tutorial, ns.TutorialCard
    if not tutorial or not card then return end
    if inCombat then
        tutorial.paused = true; tutorial.hidingForCombat = true; ClearOutline()
        card:Hide()
    elseif tutorial.paused then
        tutorial.paused = false; tutorial.hidingForCombat = false; card:Show(); card.next:Show(); card.skip:GetFontString():SetText("Skip"); ns:RefreshTutorial()
    end
end
