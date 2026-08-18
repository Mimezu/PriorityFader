local ADDON, ns = ...

-- A self-contained coach layer. It teaches the real editor through one
-- session-only Frame Gambit frame, never touching a player's existing UI.
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

local function CreateSpotlight()
    if ns.TutorialSpotlight then return ns.TutorialSpotlight end
    local spotlight = { frames = {} }
    for index = 1, 4 do
        local dim = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
        dim:SetFrameStrata("FULLSCREEN_DIALOG"); dim:SetFrameLevel(840); dim:EnableMouse(false)
        Backdrop(dim, { 0, 0, 0, 0.68 }, { 0, 0, 0, 0 }); dim:Hide()
        spotlight.frames[index] = dim
    end
    ns.TutorialSpotlight = spotlight
    return spotlight
end

local function ClearSpotlight()
    local spotlight = ns.TutorialSpotlight
    if not spotlight then return end
    for _, dim in ipairs(spotlight.frames or {}) do dim:Hide() end
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

local function Spotlight(frame)
    if not SafeShown(frame) or not ns.GetUsableFrameRect then ClearSpotlight(); return end
    local left, bottom, width, height = ns:GetUsableFrameRect(frame)
    if not left or not bottom or not width or not height or width < 2 or height < 2 then ClearSpotlight(); return end
    local uiWidth, uiHeight = UIParent:GetSize()
    local right, top = left + width, bottom + height
    local dims = CreateSpotlight().frames
    dims[1]:ClearAllPoints(); dims[1]:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", 0, top); dims[1]:SetSize(uiWidth, math.max(0, uiHeight - top))
    dims[2]:ClearAllPoints(); dims[2]:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", 0, 0); dims[2]:SetSize(uiWidth, math.max(0, bottom))
    dims[3]:ClearAllPoints(); dims[3]:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", 0, bottom); dims[3]:SetSize(math.max(0, left), math.max(0, height))
    dims[4]:ClearAllPoints(); dims[4]:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", right, bottom); dims[4]:SetSize(math.max(0, uiWidth - right), math.max(0, height))
    for _, dim in ipairs(dims) do dim:Show() end
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
    if kind == "tutorial_target" then return panel.tutorialTargetRow or panel.targets end
    if kind == "tutorial_use" then
        -- Once the player has clicked Use this frame, that button is gone.
        -- Continue with a small real-row focus instead of outlining the whole
        -- workspace while they read the confirmation.
        return panel.tutorialUseButton or (panel.reactionContent and panel.reactionContent._reactionRows or {})[1]
    end
    if kind == "tutorial_stationary" then
        for _, row in ipairs(panel.reactionContent and panel.reactionContent._reactionRows or {}) do
            if row._tutorialReaction and row._tutorialReaction.condition == "stationary" then return row end
        end
        return (panel.reactionContent and panel.reactionContent._reactionRows or {})[1]
    end
    if kind == "add" then
        local rows = panel.reactionContent and panel.reactionContent._reactionRows or {}
        -- While the card palette is open, show the learner exactly where
        -- Mouseover lives. Once it is added, guide the second half of this
        -- step by spotlighting that row's opacity control.
        local palette = ns.ReactionPalette
        if palette and palette:IsShown() then
            for _, button in ipairs(palette.conditionButtons or {}) do
                if button.conditionKey == "mouseover" and SafeShown(button) then return button end
            end
        end
        for _, row in ipairs(rows) do
            if row._tutorialReaction and row._tutorialReaction.condition == "mouseover" then return row.opacity end
        end
        return panel.addReactionButton
    end
    if kind == "tutorial_move" then
        for _, row in ipairs(panel.reactionContent and panel.reactionContent._reactionRows or {}) do
            if row._tutorialReaction and row._tutorialReaction.condition == "mouseover" then return row.up end
        end
        return nil
    end
    if kind == "otherwise" then return panel.otherwiseRow end
    if kind == "managed" then return panel.managedOnlyButton end
    if kind == "tree" then return panel.treeViewButton end
    if kind == "filter" then return panel.targetFilter end
    if kind == "outline" then return panel.outlineButton or (panel.selectionOutlineEnabled and ns.SelectionOutline) end
    if kind == "cinematic" then return panel.cinematic end
    if kind == "tutorial_frame" then return ns.TutorialPracticeFrame end
    return nil
end

local STEPS = {
    { title = "Welcome to Frame Gambit", body = "This is a real, temporary Tutorial Frame at the top-left of your screen. Nothing from this lesson is saved. We will manage it with the same editor you will use for your own UI.", focus = "tutorial_frame" },
    { title = "1. Select the Tutorial Frame", body = "The temporary Tutorial Frame is pinned to the top of the real target list. Click its target row now.", focus = "tutorial_target" },
    { title = "2. Manage it for real", body = "Click Use this frame. The editor will take over only this temporary frame's opacity; its layout and behavior remain untouched.", focus = "tutorial_use" },
    { title = "3. Quiet at rest", body = "The lesson now gives the Tutorial Frame one real rule: Stationary â†’ 30%. You are standing still, so it rests at 30%; Otherwise is 100%, so move for a moment to see the visible difference. This is a normal first-match reaction, not a fake preview.", focus = "tutorial_stationary" },
    { title = "4. Add Mouseover â†’ 100%", body = "Use the real + Add reaction button, choose Mouseover, then set its opacity to 100%. It will be added below Stationary on purpose.", focus = "add" },
    { title = "5. Priority is the gambit", body = "Hover the Tutorial Frame. It still stays dim because both rules match and Stationary is first. Use the real ^ button to move Mouseover above Stationary, then hover the frame again to confirm it reveals.", focus = "tutorial_move" },
    { title = "6. Otherwise is the fallback", body = "Use the real Otherwise opacity control and choose a value different from 100%. Otherwise applies only when no reaction above it matches.", focus = "otherwise" },
    { title = "7. See what you edit", body = "Frame outline marks the real frame you are editing. Try it now. After the tour, Peek can collapse the editor while keeping that outline visible.", focus = "outline" },
    { title = "You are ready", body = "You managed a real temporary frame, added a reaction, saw priority win, moved a row, and set Otherwise. Hover groups and linked children use the same ordered-rule idea; Cinematic is a separate profile. Finish to remove the Tutorial Frame and every lesson rule.", focus = "cinematic", finish = true },
}

local function CanAdvance(tutorial)
    local id = tutorial.targetID
    local settings = id and ns.GetTargetSettings and ns:GetTargetSettings(id)
    if tutorial.step == 2 then return ns.Options and ns.Options.selected == id, "Select Tutorial Frame in the target list first." end
    if tutorial.step == 3 then return settings ~= nil and settings.enabled ~= false, "Click Use this frame first." end
    if tutorial.step == 5 then
        for _, reaction in ipairs(settings and settings.reactions or {}) do
            if reaction.condition == "mouseover" and math.abs((reaction.opacity or 0) - 1) < 0.001 then return true end
        end
        return false, "Add Mouseover and set its opacity to 100%."
    end
    if tutorial.step == 6 then
        local first = settings and settings.reactions and settings.reactions[1]
        return first and first.condition == "mouseover" and tutorial.hoveredBeforePriority == true and tutorial.hoveredAfterPriority == true,
            "Hover while Stationary is first, then move Mouseover above it and hover again."
    end
    if tutorial.step == 7 then return settings and math.abs((settings.atRest or 1) - 1) > 0.001, "Choose a different Otherwise opacity." end
    return true
end

local function EnsureTutorialFrame()
    local frame = ns.TutorialPracticeFrame
    if frame then frame:Show(); return frame end
    frame = CreateFrame("Button", nil, UIParent, "BackdropTemplate")
    frame:SetSize(196, 62); frame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 18, -18)
    frame:SetFrameStrata("FULLSCREEN_DIALOG"); frame:SetFrameLevel(860); frame:SetToplevel(true); frame:EnableMouse(true)
    Backdrop(frame, { 0.045, 0.06, 0.09, 0.98 }, C.teal)
    local portrait = frame:CreateTexture(nil, "ARTWORK")
    portrait:SetSize(42, 42); portrait:SetPoint("LEFT", 9, 0)
    if SetPortraitTexture then SetPortraitTexture(portrait, "player") else portrait:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark") end
    local title = Text(frame, "GameFontNormal", "TUTORIAL FRAME", C.teal); title:SetPoint("TOPLEFT", portrait, "TOPRIGHT", 9, -9)
    local detail = Text(frame, BODY, "Temporary practice target", C.muted); detail:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -4)
    frame:SetScript("OnEnter", function()
        local tutorial = ns.Tutorial
        local settings = tutorial and tutorial.targetID and ns.GetTargetSettings and ns:GetTargetSettings(tutorial.targetID)
        local first = settings and settings.reactions and settings.reactions[1]
        if tutorial and tutorial.step == 6 and first then
            if first.condition == "stationary" then
                tutorial.hoveredBeforePriority = true
            elseif first.condition == "mouseover" then
                tutorial.hoveredAfterPriority = true
            end
            ns:RefreshTutorial()
        end
    end)
    ns.TutorialPracticeFrame = frame
    return fra×M´¶‰žËkºwµçp¹ÁÉ•Ù¥½ÕÍM•±•Ñ••¹(€€€•¹(€€€¥˜¹Ì¹I•¹‘•É=ÁÑ¥½¹ÌÑ¡•¸¹ÌéI•¹‘•É=ÁÑ¥½¹Ì ¤•¹)•¹()±½…°™Õ¹Ñ¥½¸É•…Ñ•!•±À ¤(€€€¥˜¹Ì¹!•±Á•¹Ñ•ÈÑ¡•¸É•ÑÕÉ¸¹Ì¹!•±Á•¹Ñ•È•¹(€€€±½…°¡•±À€ôÉ•…Ñ•É…µ” ‰É…µ”ˆ°€‰É…µ•…µ‰¥Ñ!•±Á•¹Ñ•Èˆ°U%A…É•¹Ð°€‰	…­‘É½ÁQ•µÁ±…Ñ”ˆ¤(€€€¡•±ÀéM•ÑM¥é” ÜØÀ°€ÔÔÔ¤(€€€±½…°™Õ¹Ñ¥½¸¥ÑQ½MÉ••¸ ¤(€€€€€€€±½…°Õ¥]¥‘Ñ °Õ¥!•¥¡Ð€ôU%A…É•¹Ðé•ÑM¥é” ¤(€€€€€€€¡•±ÀéM•ÑM…±”¡µ…Ñ ¹µ…à À¸ÔÀ°µ…Ñ ¹µ¥¸ Ä°€¡Õ¥]¥‘Ñ €´€ÌÀ¤€¼€ÜØÀ°€¡Õ¥!•¥¡Ð€´€ÌÀ¤€¼€ÔÔÔ¤¤¤(€€€•¹(€€€¥ÑQ½MÉ••¸ ¤(€€€¡•±ÀéM•ÑA½¥¹Ð ‰9QHˆ¤(€€€¡•±ÀéM•ÑÉ…µ•MÑÉ…Ñ„ ‰U11MI9}%1=ˆ¤ì¡•±ÀéM•ÑÉ…µ•1•Ù•° àÔÀ¤ì¡•±ÀéM•ÑQ½Á±•Ù•°¡ÑÉÕ”¤(€€€¡•±ÀéM•Ñ5½Ù…‰±”¡ÑÉÕ”¤ì¡•±ÀéM•Ñ±…µÁ•‘Q½MÉ••¸¡ÑÉÕ”¤ì¡•±Àé¹…‰±•5½ÕÍ”¡ÑÉÕ”¤(€€€	…­‘É½À¡¡•±À°¹Á…¹•°°¹…•¹Ð¤ì¡•±Àé!¥‘” ¤(€€€±½Í•	ÕÑÑ½¸¡¡•±À°™Õ¹Ñ¥½¸ ¤¹Ìé±½Í•!•±À ¤•¹¤éM•ÑA½¥¹Ð ‰Q=AI%!Pˆ°€´à°€´à¤(€€€±½…°Ñ¥Ñ±”€ôQ•áÐ¡¡•±À°€‰…µ•½¹Ñ9½Éµ…±!Õ”ˆ°€‰!•±À€˜ÑÕÑ½É¥…°ˆ°¹…•¹Ð¤ìÑ¥Ñ±”éM•ÑA½¥¹Ð ‰Q=A1Pˆ°€ÈÀ°€´Äà¤(€€€±½…°ÍÕ‰Ñ¥Ñ±”€ôQ•áÐ¡¡•±À°	=d°€‰1•…É¸Ñ¡”™±½Ü¥¸„µ¥¹ÕÑ”°½È½Á•¸…¹äÑ½Á¥ŒÝ¡•¸å½Ô¹••¥Ð¸ˆ°¹µÕÑ•¤ìÍÕ‰Ñ¥Ñ±”éM•ÑA½¥¹Ð ‰Q=A1Pˆ°Ñ¥Ñ±”°€‰	=QQ=51Pˆ°€À°€´Ô¤(€€€±½…°‘É…œ€ôÉ•…Ñ•É…µ” ‰É…µ”ˆ°¹¥°°¡•±À¤(€€€‘É…œéM•ÑA½¥¹Ð ‰Q=A1Pˆ¤ì‘É…œéM•ÑA½¥¹Ð ‰Q=AI%!Pˆ¤ì‘É…œéM•Ñ!•¥¡Ð Ôà¤(€€€‘É…œé¹…‰±•5½ÕÍ”¡ÑÉÕ”¤ì‘É…œéI•¥ÍÑ•É½ÉÉ…œ ‰1•™Ñ	ÕÑÑ½¸ˆ¤(€€€‘É…œéM•ÑMÉ¥ÁÐ ‰=¹É…MÑ…ÉÐˆ°™Õ¹Ñ¥½¸ ¤¡•±ÀéMÑ…ÉÑ5½Ù¥¹œ ¤•¹¤(€€€‘É…œéM•ÑMÉ¥ÁÐ ‰=¹É…MÑ½Àˆ°™Õ¹Ñ¥½¸ ¤¡•±ÀéMÑ½Á5½Ù¥¹=ÉM¥é¥¹œ ¤•¹¤((€€€±½…°Ñ½Á¥Ì€ôì(€€€€€€€ìÑ¥Ñ±”€ô€‰MÑ…ÉÐ¡•É”ˆ°ÍÕµµ…Éä€ô€‰Q¡”ÅÕ¥¬±½½Àˆ°‰½‘ä€ô€‰A¥¬„™É…µ”°…‘„É•…Ñ¥½¸°Ñ¡•¸Í•Ð=Ñ¡•ÉÝ¥Í”¸Q¡…Ð¥ÌÑ¡”½µÁ±•Ñ”É…µ”…µ‰¥Ð±½½À¸ˆô°(€€€€€€€ìÑ¥Ñ±”€ô€‰…µ‰¥ÐÁÉ¥½É¥Ñäˆ°ÍÕµµ…Éä€ô€‰¥ÉÍÐµ…Ñ¡¥¹œÉ•…Ñ¥½¸Ý¥¹Ìˆ°‰½‘ä€ô€‰É…µ”…µ‰¥Ð¡•­ÌÉ•…Ñ¥½¹Ì™É½´Ñ½ÀÑ¼‰½ÑÑ½´¸Q¡”™¥ÉÍÐµ…Ñ¡¥¹œÉ•…Ñ¥½¸‘•¥‘•ÌÑ¡”™É…µ”Ì½Á…¥Ñä¸ˆô°(€€€€€€€ìÑ¥Ñ±”€ô€‰I•±…Ñ¥½¹Í¡¥ÁÌˆ°ÍÕµµ…Éä€ô€‰1•ÐÉ•±…Ñ•U$Ý½É¬Ñ½•Ñ¡•Èˆ°‰½‘ä€ô€‰É½ÕÁÌÉ•Ù•…°Ñ½•Ñ¡•È¸1¥¹­Ì¡…Ù”„Í½ÕÉ”¸Y¥Í¥‰¥±¥Ñä¡¥±‘É•¸…¸™½±±½Ü„Á…É•¹Ð¸ˆô°(€€€€€€€ìÑ¥Ñ±”€ô€‰¥¹•µ…Ñ¥Œˆ°ÍÕµµ…Éä€ô€‰Í•Á…É…Ñ”…±´Í•¹”ˆ°‰½‘ä€ô€‰¥¹•µ…Ñ¥Œ¥Ì„ÅÕ•ÍÑ¥¹œÁÉ½™¥±”Ñ¡…Ð±•…Ù•Ìå½ÕÈ¹½Éµ…°ÁÉ½™¥±”…±½¹”¸¹Ñ•È¥Ð™É½´Ñ¡”½É…¹”¥¹•µ…Ñ¥Œ‰ÕÑÑ½¸°Ñ¡•¸•‘¥Ð¥ÑÌ™É…µ•ÌÝ¥Ñ Ñ¡”™…µ¥±¥…È•‘¥Ñ½È¸%ÑÌÑ½ÀÍÑÉ¥À¡½±‘ÌÑ¡”µ½‘”Ñ½±”°‰±…¬‰…ÉÌ°…¹Í¡½ÉÑÕÐ¸ˆô°(€€€€€€€ìÑ¥Ñ±”€ô€‰M…™•Ñäˆ°ÍÕµµ…Éä€ô€‰AÉ•Í•¹Ñ…Ñ¥½¸°¹½Ð½¹ÑÉ½°ˆ°‰½‘ä€ô€‰É…µ”…µ‰¥Ð±…å•ÉÌ™¥¹…°½Á…¥Ñä½¹±ä¸%Ð‘½•Ì¹½Ðµ½Ù”°É•ÍÑå±”°É•Á…É•¹Ð°Í¡½Ü°¡¥‘”°½È¡…¹”Í•ÕÉ”½¹ÑÉ½±Ì½Ý¹•‰ä	±¥éé…É½È…¹½Ñ¡•È…‘‘½¸¸ˆô°(€€€€€€€ìÑ¥Ñ±”€ô€‰QÉ½Õ‰±•Í¡½½Ñ¥¹œˆ°ÍÕµµ…Éä€ô€‰½¹™¥É´Ñ¡”¥¹Ñ•¹‘•™É…µ”ˆ°‰½‘ä€ô€‰UÍ”¥Í½Ù•ÈÙ¥Í¥‰±”U$°Í•±•ÐÑ¡”É¥¡ÐÉ½½Ð°Ñ¡•¸ÕÍ”É…µ”½ÕÑ±¥¹”½ÈA••¬Ñ¼½¹™¥É´¥Ð¸Q¡•Í”¡•­Ì‘¼¹½Ð¡…¹”Ñ¡”™É…µ”Ì±…å½ÕÐ½ÈÍ•ÑÑ¥¹Ì¸ˆô°(€€€ô(€€€±½…°É…¥°€ôÉ•…Ñ•É…µ” ‰É…µ”ˆ°¹¥°°¡•±À°€‰	…­‘É½ÁQ•µÁ±…Ñ”ˆ¤(€€€É…¥°éM•ÑA½¥¹Ð ‰Q=A1Pˆ°€Äà°€´ÜØ¤ìÉ…¥°éM•ÑA½¥¹Ð ‰	=QQ=51Pˆ°€Äà°€ØÈ¤ìÉ…¥°éM•Ñ]¥‘Ñ  ÄäÀ¤ì	…­‘É½À¡É…¥°°¹…É‘±Ð°¹‰½É‘•È¤(€€€±½…°Á…”€ôÉ•…Ñ•É…µ” ‰É…µ”ˆ°¹¥°°¡•±À°€‰	…­‘É½ÁQ•µÁ±…Ñ”ˆ¤(€€€Á…”éM•ÑA½¥¹Ð ‰Q=A1Pˆ°É…¥°°€‰Q=AI%!Pˆ°€ÄÈ°€À¤ìÁ…”éM•ÑA½¥¹Ð ‰	=QQ=5I%!Pˆ°€´Äà°€ØÈ¤ì	…­‘É½À¡Á…”°¹…É°¹‰½É‘•È¤(€€€¡•±À¹Ñ½Á¥	ÕÑÑ½¹Ì°¡•±À¹Á…”€ôíô°Á…”(€€€Á…”¹Ñ¥Ñ±”€ôQ•áÐ¡Á…”°€‰…µ•½¹Ñ9½Éµ…±!Õ”ˆ°€ˆˆ°¹Ñ•…°¤ìÁ…”¹Ñ¥Ñ±”éM•ÑA½¥¹Ð ‰Q=A1Pˆ°€ÈÈ°€´ÈÈ¤(€€€Á…”¹ÍÕµµ…Éä€ôQ•áÐ¡Á…”°€‰…µ•½¹Ñ!¥¡±¥¡Ðˆ°€ˆˆ°¹µÕÑ•¤ìÁ…”¹ÍÕµµ…ÉäéM•ÑA½¥¹Ð ‰Q=A1Pˆ°Á…”¹Ñ¥Ñ±”°€‰	=QQ=51Pˆ°€À°€´Ø¤(€€€Á…”¹ÉÕ±”€ôÁ…”éÉ•…Ñ•Q•áÑÕÉ”¡¹¥°°€‰IQ]=I,ˆ¤ìÁ…”¹ÉÕ±”éM•ÑQ•áÑÕÉ”¡]!%Q¤ìÁ…”¹ÉÕ±”éM•ÑA½¥¹Ð ‰Q=A1Pˆ°Á…”¹ÍÕµµ…Éä°€‰	=QQ=51Pˆ°€À°€´ÄÐ¤ìÁ…”¹ÉÕ±”éM•ÑA½¥¹Ð ‰I%!Pˆ°Á…”°€‰I%!Pˆ°€´ÈÈ°€À¤ìÁ…”¹ÉÕ±”éM•Ñ!•¥¡Ð Ä¤ìÁ…”¹ÉÕ±”éM•ÑY•ÉÑ•á½±½È¡Õ¹Á…¬¡¹‰½É‘•È¤¤(€€€Á…”¹‰½‘ä€ôQ•áÐ¡Á…”°€‰…µ•½¹Ñ!¥¡±¥¡Ðˆ°€ˆˆ°ì€À¸àÐ°€À¸àÔ°€À¸äÄ°€Äô¤ìÁ…”¹‰½‘äéM•ÑA½¥¹Ð ‰Q=A1Pˆ°Á…”¹ÉÕ±”°€‰	=QQ=51Pˆ°€À°€´ÈÀ¤ìÁ…”¹‰½‘äéM•ÑA½¥¹Ð ‰	=QQ=5I%!Pˆ°€´ÈÈ°€ÈÈ¤ìÁ…”¹‰½‘äéM•Ñ)ÕÍÑ¥™å  ‰1Pˆ¤ìÁ…”¹‰½‘äéM•Ñ)ÕÍÑ¥™åX ‰Q=@ˆ¤ìÁ…”¹‰½‘äéM•Ñ]½É‘]É…À¡ÑÉÕ”¤ìÁ…”¹‰½‘äéM•ÑMÁ…¥¹œ Ì¤(€€€™Õ¹Ñ¥½¸¡•±ÀéM¡½ÝQ½Á¥Œ¡¥¹‘•à¤(€€€€€€€Í•±˜¹Ñ½Á¥Œ€ô¥¹‘•à(€€€€€€€±½…°Ñ½Á¥Œ€ôÑ½Á¥Ím¥¹‘•át(€€€€€€€Á…”¹Ñ¥Ñ±”éM•ÑQ•áÐ¡Ñ½Á¥Œ¹Ñ¥Ñ±”¤ìÁ…”¹ÍÕµµ…ÉäéM•ÑQ•áÐ¡Ñ½Á¥Œ¹ÍÕµµ…Éä¤ìÁ…”¹‰½‘äéM•ÑQ•áÐ¡Ñ½Á¥Œ¹‰½‘ä¤(€€€€€€€™½È‰ÕÑÑ½¹%¹‘•à°‰ÕÑÑ½¸¥¸¥Á…¥ÉÌ¡Í•±˜¹Ñ½Á¥	ÕÑÑ½¹Ì¤‘¼(€€€€€€€€€€€±½…°Í•±•Ñ•€ô‰ÕÑÑ½¹%¹‘•à€ôô¥¹‘•à(€€€€€€€€€€€‰ÕÑÑ½¸¹}ÁÉ¥µ…Éä€ô™…±Í”(€€€€€€€€€€€‰ÕÑÑ½¸éM•Ñ	…­‘É½Á½±½È¡Õ¹Á…¬¡Í•±•Ñ•…¹ì€À¸Àà°€À¸ÈÈ°€À¸ÈÀ°€Äô½È¹…É‘±Ð¤¤(€€€€€€€€€€€‰ÕÑÑ½¸éM•Ñ	…­‘É½Á	½É‘•É½±½È¡Õ¹Á…¬¡Í•±•Ñ•…¹¹Ñ•…°½È¹‰½É‘•È¤¤(€€€€€€€€€€€‰ÕÑÑ½¸é•Ñ½¹ÑMÑÉ¥¹œ ¤éM•ÑQ•áÑ½±½È¡Õ¹Á…¬¡Í•±•Ñ•…¹¹Ñ•…°½È¹…•¹Ð¤¤(€€€€€€€•¹(€€€•¹(€€€™½È¥¹‘•à°Ñ½Á¥Œ¥¸¥Á…¥ÉÌ¡Ñ½Á¥Ì¤‘¼(€€€€€€€±½…°Ñ½Á¥%¹‘•à€ô¥¹‘•à(€€€€€€€±½…°‰ÕÑÑ½¸€ô	ÕÑÑ½¸¡É…¥°°Ñ½Á¥Œ¹Ñ¥Ñ±”°€ÄÜÐ°™Õ¹Ñ¥½¸ ¤¡•±ÀéM¡½ÝQ½Á¥Œ¡Ñ½Á¥%¹‘•à¤•¹¤(€€€€€€€‰ÕÑÑ½¸éM•Ñ!•¥¡Ð ÐÈ¤ì‰ÕÑÑ½¸éM•ÑA½¥¹Ð ‰Q=A1Pˆ°€à°€´à€´€¡¥¹‘•à€´€Ä¤€¨€ÐÜ¤(€€€€€€€‰ÕÑÑ½¸é•Ñ½¹ÑMÑÉ¥¹œ ¤é±•…É±±A½¥¹ÑÌ ¤ì‰ÕÑÑ½¸é•Ñ½¹ÑMÑÉ¥¹œ ¤éM•ÑA½¥¹Ð ‰1Pˆ°€ÄÀ°€À¤ì‰ÕÑÑ½¸é•Ñ½¹ÑMÑÉ¥¹œ ¤éM•Ñ)ÕÍÑ¥™å  ‰1Pˆ¤(€€€€€€€‰ÕÑÑ½¸é!½½­MÉ¥ÁÐ ‰=¹1•…Ù”ˆ°™Õ¹Ñ¥½¸¡Í•±˜¤(€€€€€€€€€€€¥˜¡•±À¹Ñ½Á¥Œ€ôôÑ½Á¥%¹‘•àÑ¡•¸(€€€€€€€€€€€€€€€Í•±˜éM•Ñ	…­‘É½Á½±½È À¸Àà°€À¸ÈÈ°€À¸ÈÀ°€Ä¤ìÍ•±˜éM•Ñ	…­‘É½Á	½É‘•É½±½È¡Õ¹Á…¬¡¹Ñ•…°¤¤(€€€€€€€€€€€•¹(€€€€€€€•¹¤(€€€€€€€¡•±À¹Ñ½Á¥	ÕÑÑ½¹Ím¥¹‘•át€ô‰ÕÑÑ½¸(€€€•¹(€€€±½…°ÍÑ…ÉÐ€ô	ÕÑÑ½¸¡¡•±À°€‰MÑ…ÉÐÕ¥‘•ÑÕÑ½É¥…°ˆ°€ÄäÀ°™Õ¹Ñ¥½¸ ¤¡•±Àé!¥‘” ¤ì¹ÌéMÑ…ÉÑQÕÑ½É¥…° ¤•¹°ÑÉÕ”¤(€€€ÍÑ…ÉÐéM•ÑA½¥¹Ð ‰	=QQ=51Pˆ°€Äà°€Äà¤ì¡•±À¹ÍÑ…ÉÐ€ôÍÑ…ÉÐ(€€€±½…°É•ÍÑ…ÉÐ€ô	ÕÑÑ½¸¡¡•±À°€‰I•ÍÑ…ÉÐÑÕÑ½É¥…°ˆ°€ÄÈÔ°™Õ¹Ñ¥½¸ ¤¡•±Àé!¥‘” ¤ì¹ÌéMÑ…ÉÑQÕÑ½É¥…° Ä¤•¹¤(€€€É•ÍÑ…ÉÐéM•ÑA½¥¹Ð ‰1Pˆ°ÍÑ…ÉÐ°€‰I%!Pˆ°€à°€À¤ì¡•±À¹É•ÍÑ…ÉÐ€ôÉ•ÍÑ…ÉÐ(€€€±½…°±½Í”€ô	ÕÑÑ½¸¡¡•±À°€‰±½Í”ˆ°€äÀ°™Õ¹Ñ¥½¸ ¤¡•±Àé!¥‘” ¤•¹¤(€€€±½Í”éM•ÑA½¥¹Ð ‰	=QQ=5I%!Pˆ°€´Äà°€Äà¤(€€€¡•±ÀéM•ÑMÉ¥ÁÐ ‰=¹!¥‘”ˆ°™Õ¹Ñ¥½¸ ¤(€€€€€€€¡•±ÀéMÑ½Á5½Ù¥¹=ÉM¥é¥¹œ ¤(€€€€€€€±•…É=ÕÑ±¥¹” ¤(€€€•¹¤(€€€¡•±ÀéM•ÑMÉ¥ÁÐ ‰=¹M¡½Üˆ°™Õ¹Ñ¥½¸ ¤¥ÑQ½MÉ••¸ ¤ì¡•±ÀéI…¥Í” ¤•¹¤(€€€¡•±ÀéM¡½ÝQ½Á¥Œ Ä¤(€€€±½…°‘¥ÍÁ±…åÙ•¹ÑÌ€ôÉ•…Ñ•É…µ” ‰É…µ”ˆ¤(€€€‘¥ÍÁ±…åÙ•¹ÑÌéI•¥ÍÑ•ÉÙ•¹Ð ‰%MA1e}M%i}!9ˆ¤ì‘¥ÍÁ±…åÙ•¹ÑÌéI•¥ÍÑ•ÉÙ•¹Ð ‰U%}M1}!9ˆ¤(€€€‘¥ÍÁ±…åÙ•¹ÑÌéM•ÑMÉ¥ÁÐ ‰=¹Ù•¹Ðˆ°™Õ¹Ñ¥½¸ ¤¥˜¡•±Àé%ÍM¡½Ý¸ ¤Ñ¡•¸¥ÑQ½MÉ••¸ ¤•¹•¹¤(€€€¥˜U%MÁ•¥…±É…µ•ÌÑ¡•¸U%MÁ•¥…±É…µ•ÍlU%MÁ•¥…±É…µ•Ì€¬€Åt€ô¡•±Àé•Ñ9…µ” ¤•¹(€€€¹Ì¹!•±Á•¹Ñ•È€ô¡•±À(€€€É•ÑÕÉ¸¡•±À)•¹()±½…°™Õ¹Ñ¥½¸É•…Ñ•QÕÑ½É¥…° ¤(€€€¥˜¹Ì¹QÕÑ½É¥…±…ÉÑ¡•¸É•ÑÕÉ¸¹Ì¹QÕÑ½É¥…±…É•¹(€€€±½…°…É€ôÉ•…Ñ•É…µ” ‰É…µ”ˆ°€‰É…µ•…µ‰¥ÑQÕÑ½É¥…°ˆ°U%A…É•¹Ð°€‰	…­‘É½ÁQ•µÁ±…Ñ”ˆ¤(€€€€´´Q¡”½… …ÉµÕÍÐÉ•µ…¥¸É•…‘…‰±”…™Ñ•ÈÑ¡”Á±…å•È±¥­Ì„É•…°(€€€€´´•‘¥Ñ½È½¹ÑÉ½°¸-••À¥Ð…‰½Ù”Ñ¡”½ÁÑ¥½¹ÌÁ…¹•°ìI•™É•Í¡QÕÑ½É¥…°…±Í¼(€€€€´´É…¥Í•Ì¥Ð…™Ñ•È•Ù•Éä±¥Ù”µ•‘¥Ñ½ÈÉ•™É•Í ¸(€€€…ÉéM•ÑM¥é” ÌäÀ°€ÈÈÀ¤ì…ÉéM•ÑÉ…µ•MÑÉ…Ñ„ ‰U11MI9}%1=ˆ¤ì…ÉéM•ÑÉ…µ•1•Ù•° äÔÀ¤ì…ÉéM•ÑQ½Á±•Ù•°¡ÑÉÕ”¤ì…Éé¹…‰±•5½ÕÍ”¡ÑÉÕ”¤ì…ÉéM•Ñ±…µÁ•‘Q½MÉ••¸¡ÑÉÕ”¤(€€€	…­‘É½À¡…É°¹Á…¹•°°¹Ñ•…°¤ì…Éé!¥‘” ¤(€€€±½…°­¥­•È€ôQ•áÐ¡…É°	=d°€‰U%Q=UHˆ°¹Ñ•…°¤ì­¥­•ÈéM•ÑA½¥¹Ð ‰Q=A1Pˆ°€ÄØ°€´ÄÐ¤(€€€±½…°Ñ¥Ñ±”€ôQ•áÐ¡…É°Q%Q1°€ˆˆ°¹…•¹Ð¤ìÑ¥Ñ±”éM•ÑA½¥¹Ð ‰Q=A1Pˆ°€ÄØ°€´ÌÌ¤ì…É¹Ñ¥Ñ±”€ôÑ¥Ñ±”(€€€±½…°‰½‘ä€ôQ•áÐ¡…É°€‰…µ•½¹Ñ!¥¡±¥¡Ðˆ°€ˆˆ°¹µÕÑ•¤ì‰½‘äéM•ÑA½¥¹Ð ‰Q=A1Pˆ°€ÄØ°€´ØÔ¤ì‰½‘äéM•ÑA½¥¹Ð ‰Q=AI%!Pˆ°€´ÄØ°€´ØÔ¤ì‰½‘äéM•Ñ)ÕÍÑ¥™å  ‰1Pˆ¤ì‰½‘äéM•Ñ)ÕÍÑ¥™åX ‰Q=@ˆ¤ì‰½‘äéM•Ñ]½É‘]É…À¡ÑÉÕ”¤ì…É¹‰½‘ä€ô‰½‘ä(€€€±½…°ÁÉ½É•ÍÌ€ôQ•áÐ¡…É°	=d°€ˆˆ°¹µÕÑ•¤ìÁÉ½É•ÍÌéM•ÑA½¥¹Ð ‰	=QQ=51Pˆ°€ÄØ°€ÄÔ¤ì…É¹ÁÉ½É•ÍÌ€ôÁÉ½É•ÍÌ(€€€…É¹‰…¬€ô	ÕÑÑ½¸¡…É°€‰	…¬ˆ°€Ôà°™Õ¹Ñ¥½¸ ¤¹Ì¹QÕÑ½É¥…°¹ÍÑ•À€ôµ…Ñ ¹µ…à Ä°¹Ì¹QÕÑ½É¥…°¹ÍÑ•À€´€Ä¤ì¹ÌéI•™É•Í¡QÕÑ½É¥…° ¤•¹¤(€€€…É¹‰…¬éM•ÑA½¥¹Ð ‰	=QQ=5I%!Pˆ°€´ÄÔÜ°€ÄÈ¤(€€€…É¹¹•áÐ€ô	ÕÑÑ½¸¡…É°€‰9•áÐˆ°€ØØ°™Õ¹Ñ¥½¸ ¤(€€€€€€€±½…°ÑÕÑ½É¥…°€ô¹Ì¹QÕÑ½É¥…°(€€€€€€€¥˜¹½ÐÑÕÑ½É¥…°½ÈÑÕÑ½É¥…°¹Á…ÕÍ•Ñ¡•¸É•ÑÕÉ¸•¹(€€€€€€€±½…°É•…‘ä°µ•ÍÍ…”€ô…¹‘Ù…¹”¡ÑÕÑ½É¥…°¤(€€€€€€€¥˜¹½ÐÉ•…‘äÑ¡•¸(€€€€€€€€€€€…É¹Ù…±¥‘…Ñ¥½¸éM•ÑQ•áÐ¡µ•ÍÍ…”½È€‰QÉäÑ¡¥ÌÍÑ•À™¥ÉÍÐ¸ˆ¤(€€€€€€€€€€€É•ÑÕÉ¸(€€€€€€€•¹(€€€€€€€¥˜ÑÕÑ½É¥…°¹ÍÑ•À€øô€MQALÑ¡•¸¹Ìé…¹•±QÕÑ½É¥…° ‰½µÁ±•Ñ”ˆ¤ìÉ•ÑÕÉ¸•¹(€€€€€€€¥˜ÑÕÑ½É¥…°¹ÍÑ•À€ôô€ÌÑ¡•¸M••‘QÕÑ½É¥…±MÑ…Ñ¥½¹…ÉåIÕ±”¡ÑÕÑ½É¥…°¤•¹(€€€€€€€ÑÕÑ½É¥…°¹ÍÑ•À€ôÑÕÑ½É¥…°¹ÍÑ•À€¬€Äì¹ÌéI•™É•Í¡QÕÑ½É¥…° ¤(€€€•¹°ÑÉÕ”¤(€€€…É¹¹•áÐéM•ÑA½¥¹Ð ‰1Pˆ°…É¹‰…¬°€‰I%!Pˆ°€Ø°€À¤(€€€…É¹Í­¥À€ô	ÕÑÑ½¸¡…É°€‰M­¥Àˆ°€Ðà°™Õ¹Ñ¥½¸ ¤¹Ìé…¹•±QÕÑ½É¥…° ‰Í­¥ÁÁ•ˆ¤•¹¤(€€€…É¹Í­¥ÀéM•ÑA½¥¹Ð ‰1Pˆ°…É¹¹•áÐ°€‰I%!Pˆ°€Ø°€À¤(€€€±½Í•	ÕÑÑ½¸¡…É°™Õ¹Ñ¥½¸ ¤¹Ìé…¹•±QÕÑ½É¥…° ‰±½Í•ˆ¤•¹¤éM•ÑA½¥¹Ð ‰Q=AI%!Pˆ°€´Ô°€´Ô¤((€€€±½…°Ù…±¥‘…Ñ¥½¸€ôQ•áÐ¡…É°	=d°€ˆˆ°¹…µ‰•È¤(€€€Ù…±¥‘…Ñ¥½¸éM•ÑA½¥¹Ð ‰	=QQ=51Pˆ°€ÄØ°€Ìä¤ìÙ…±¥‘…Ñ¥½¸éM•ÑA½¥¹Ð ‰	=QQ=5I%!Pˆ°€´ÄØ°€Ìä¤(€€€Ù…±¥‘…Ñ¥½¸éM•Ñ)ÕÍÑ¥™å  ‰1Pˆ¤ì…É¹Ù…±¥‘…Ñ¥½¸€ôÙ…±¥‘…Ñ¥½¸((€€€…ÉéM•ÑMÉ¥ÁÐ ‰=¹!¥‘”ˆ°™Õ¹Ñ¥½¸ ¤(€€€€€€€€´´Í…Á”ÕÍ•ÌU%MÁ•¥…±É…µ•Ì…¹¡¥‘•ÌÑ¡”…É‘¥É•Ñ±ä¸(€€€€€€€¥˜¹Ì¹QÕÑ½É¥…°…¹¹½Ð¹Ì¹QÕÑ½É¥…°¹±½Í¥¹œ…¹¹½Ð¹Ì¹QÕÑ½É¥…°¹¡¥‘¥¹½É½µ‰…ÐÑ¡•¸¹Ìé…¹•±QÕÑ½É¥…° ‰±½Í•ˆ¤•¹(€€€•¹¤(€€€Ñ…‰±”¹¥¹Í•ÉÐ¡U%MÁ•¥…±É…µ•Ì°€‰É…µ•…µ‰¥ÑQÕÑ½É¥…°ˆ¤(€€€¹Ì¹QÕÑ½É¥…±…É€ô…É(€€€É•ÑÕÉ¸…É)•¹()™Õ¹Ñ¥½¸¹Ìé=Á•¹!•±À ¤(€€€¥˜%Í½µ‰…Ð ¤Ñ¡•¸9½Ñ¥” ‰=Á•¸!•±À½ÕÑÍ¥‘”½µ‰…Ð¸ˆ°¹…µ‰•È¤ìÉ•ÑÕÉ¸•¹(€€€€´´!•±À…¹Ñ¡”½… …É…É”µÕÑÕ…±±ä•á±ÕÍ¥Ù”¸M…Ù”Ñ¡”±¥Ù”ÍÑ•À(€€€€´´‰•™½É”½Á•¹¥¹œ!•±ÀÍ¼I•ÍÕµ”…±Ý…åÌ‘•ÍÉ¥‰•ÌÑ¡”É•…°Ñ½ÕÈÍÑ…Ñ”¸(€€€¥˜¹Ì¹QÕÑ½É¥…°Ñ¡•¸¹Ìé…¹•±QÕÑ½É¥…° ‰¡•±Á}½Á•¹•ˆ¤•¹(€€€±½…°¡•±À€ôÉ•…Ñ•!•±À ¤(€€€±½…°Í…Ù•‘MÑ•À°½µÁ±•Ñ•€ô•ÑMÑ…Ñ” ¤(€€€¥˜½µÁ±•Ñ•Ñ¡•¸(€€€€€€€¡•±À¹ÍÑ…ÉÐé•Ñ½¹ÑMÑÉ¥¹œ ¤éM•ÑQ•áÐ ‰I•Á±…äÕ¥‘•ÑÕÑ½É¥…°ˆ¤(€€€€€€€¡•±À¹É•ÍÑ…ÉÐé!¥‘” ¤(€€€•±Í•¥˜Í…Ù•‘MÑ•À€ø€ÄÑ¡•¸(€€€€€€€¡•±À¹ÍÑ…ÉÐé•Ñ½¹ÑMÑÉ¥¹œ ¤éM•ÑQ•áÐ ‰I•ÍÕµ”Õ¥‘•ÑÕÑ½É¥…°ˆ¤(€€€€€€€¡•±À¹É•ÍÑ…ÉÐéM¡½Ü ¤(€€€•±Í”(€€€€€€€¡•±À¹ÍÑ…ÉÐé•Ñ½¹ÑMÑÉ¥¹œ ¤éM•ÑQ•áÐ ‰MÑ…ÉÐÕ¥‘•ÑÕÑ½É¥…°ˆ¤(€€€€€€€¡•±À¹É•ÍÑ…ÉÐé!¥‘” ¤(€€€•¹(€€€¡•±ÀéM¡½ÝQ½Á¥Œ Ä¤(€€€¡•±ÀéM¡½Ü ¤(€€€¡•±ÀéI…¥Í” ¤)•¹()™Õ¹Ñ¥½¸¹ÌéQ½±•!•±À ¤(€€€¥˜¹Ì¹!•±Á•¹Ñ•È…¹¹Ì¹!•±Á•¹Ñ•Èé%ÍM¡½Ý¸ ¤Ñ¡•¸(€€€€€€€¹Ìé±½Í•!•±À ¤(€€€€€€€É•ÑÕÉ¸(€€€•¹(€€€¹Ìé=Á•¹!•±À ¤)•¹()™Õ¹Ñ¥½¸¹Ìé±½Í•!•±À ¤(€€€¥˜¹Ì¹!•±Á•¹Ñ•ÈÑ¡•¸¹Ì¹!•±Á•¹Ñ•Èé!¥‘” ¤•¹)•¹()™Õ¹Ñ¥½¸¹ÌéMÑ…ÉÑQÕÑ½É¥…°¡É•ÅÕ•ÍÑ•‘MÑ•À¤(€€€¥˜%Í½µ‰…Ð ¤Ñ¡•¸9½Ñ¥” ‰Q¡”Õ¥‘•ÑÕÑ½É¥…°ÍÑ…ÉÑÌ½ÕÑÍ¥‘”½µ‰…Ð¸ˆ°¹…µ‰•È¤ìÉ•ÑÕÉ¸™…±Í”•¹(€€€±½…°Á…¹•°€ô¹ÍÕÉ•=ÁÑ¥½¹Ì ¤(€€€¥˜¹½ÐÁ…¹•°Ñ¡•¸É•ÑÕÉ¸™…±Í”•¹(€€€¹Ìé±½Í•!•±À ¤(€€€±½…°Í…Ù•‘MÑ•À°½µÁ±•Ñ•€ô•ÑMÑ…Ñ” ¤(€€€±½…°ÍÑ•À€ôÑ½¹Õµ‰•È¡É•ÅÕ•ÍÑ•‘MÑ•À¤½È€¡½µÁ±•Ñ•…¹€Ä½ÈÍ…Ù•‘MÑ•À¤(€€€ÍÑ•À€ôµ…Ñ ¹µ…à Ä°µ…Ñ ¹µ¥¸ MQAL°ÍÑ•À¤¤(€€€¹Ì¹QÕÑ½É¥…°€ôì(€€€€€€€ÍÑ•À€ôÍÑ•À°(€€€€€€€Á…ÕÍ•€ô™…±Í”°(€€€€€€€Ý…Í½µÁ±•Ñ•€ô½µÁ±•Ñ•€ôôÑÉÕ”°(€€€ô(€€€±½…°ÍÑ…ÉÑ•°É•…Í½¸€ôMÑ…ÉÑQÕÑ½É¥…±Q…É•Ð¡¹Ì¹QÕÑ½É¥…°°ÍÑ•À€ø€Ä¤(€€€¥˜¹½ÐÍÑ…ÉÑ•Ñ¡•¸(€€€€€€€±½…°ÑÕÑ½É¥…°€ô¹Ì¹QÕÑ½É¥…°(€€€€€€€¹Ì¹QÕÑ½É¥…°€ô¹¥°(€€€€€€€±•…¹ÕÁQÕÑ½É¥…±Q…É•Ð¡ÑÕÑ½É¥…°¤(€€€€€€€9½Ñ¥”¡É•…Í½¸½È€‰Q¡”Ñ•µÁ½É…ÉäQÕÑ½É¥…°É…µ”½Õ±¹½Ð‰”É•…Ñ•¸ˆ°¹…µ‰•È¤(€€€€€€€É•ÑÕÉ¸™…±Í”(€€€•¹(€€€±½…°…É€ôÉ•…Ñ•QÕÑ½É¥…° ¤(€€€…ÉéM¡½Ü ¤ì¹ÌéI•™É•Í¡QÕÑ½É¥…° ¤(€€€É•ÑÕÉ¸ÑÉÕ”)•¹()™Õ¹Ñ¥½¸¹Ìé…¹•±QÕÑ½É¥…°¡É•…Í½¸¤(€€€±½…°ÑÕÑ½É¥…°€ô¹Ì¹QÕÑ½É¥…°(€€€¥˜¹½ÐÑÕÑ½É¥…°Ñ¡•¸É•ÑÕÉ¸•¹(€€€±½…°½µÁ±•Ñ•€ôÉ•…Í½¸€ôô€‰½µÁ±•Ñ”ˆ½ÈÑÕÑ½É¥…°¹Ý…Í½µÁ±•Ñ•€ôôÑÉÕ”(€€€M…Ù•MÑ…Ñ”¡½µÁ±•Ñ•…¹€MQAL½ÈÑÕÑ½É¥…°¹ÍÑ•À½È€Ä°½µÁ±•Ñ•¤(€€€±•…É=ÕÑ±¥¹” ¤ì±•…ÉMÁ½Ñ±¥¡Ð ¤(€€€ÑÕÑ½É¥…°¹±½Í¥¹œ€ôÑÉÕ”(€€€¥˜¹Ì¹QÕÑ½É¥…±…ÉÑ¡•¸¹Ì¹QÕÑ½É¥…±…Éé!¥‘” ¤•¹(€€€¹Ì¹QÕÑ½É¥…°€ô¹¥°(€€€±•…¹ÕÁQÕÑ½É¥…±Q…É•Ð¡ÑÕÑ½É¥…°¤(€€€¥˜¹Ì¹=ÁÑ¥½¹Ì…¹¹Ì¹=ÁÑ¥½¹Ì¹¡•±Á	ÕÑÑ½¸…¹¹Ì¹=ÁÑ¥½¹Ì¹¡•±Á	ÕÑÑ½¸¹ÑÕÑ½É¥…±½ÐÑ¡•¸(€€€€€€€¹Ì¹=ÁÑ¥½¹Ì¹¡•±Á	ÕÑÑ½¸¹ÑÕÑ½É¥…±½ÐéM•ÑM¡½Ý¸¡¹½Ð½µÁ±•Ñ•¤(€€€•¹(€€€¥˜½µÁ±•Ñ•Ñ¡•¸9½Ñ¥” ‰QÕÑ½É¥…°½µÁ±•Ñ”¸e½Ô…¸É•ÍÑ…ÉÐ¥Ð…¹äÑ¥µ”™É½´!•±À¸ˆ°¹Ñ•…°¤•¹)•¹()™Õ¹Ñ¥½¸¹ÌéI•™É•Í¡QÕÑ½É¥…° ¤(€€€±½…°ÑÕÑ½É¥…°°…É€ô¹Ì¹QÕÑ½É¥…°°¹Ì¹QÕÑ½É¥…±…É(€€€¥˜¹½ÐÑÕÑ½É¥…°½È¹½Ð…É½È¹½Ð…Éé%ÍM¡½Ý¸ ¤Ñ¡•¸É•ÑÕÉ¸•¹(€€€¥˜%Í½µ‰…Ð ¤Ñ¡•¸¹Ìé=¹QÕÑ½É¥…±½µ‰…ÑMÑ…Ñ•¡…¹•¡ÑÉÕ”¤ìÉ•ÑÕÉ¸•¹(€€€±½…°ÍÑ•À€ôMQAMmÑÕÑ½É¥…°¹ÍÑ•Át½ÈMQAMlÅt(€€€…É¹Ñ¥Ñ±”éM•ÑQ•áÐ¡ÍÑ•À¹Ñ¥Ñ±”¤ì…É¹‰½‘äéM•ÑQ•áÐ¡ÍÑ•À¹‰½‘ä¤(€€€…É¹Ù…±¥‘…Ñ¥½¸éM•ÑQ•áÐ ˆˆ¤(€€€…É¹ÁÉ½É•ÍÌéM•ÑQ•áÐ ‰MÑ•À€ˆ€¸¸ÑÕÑ½É¥…°¹ÍÑ•À€¸¸€ˆ½˜€ˆ€¸¸€MQAL¤(€€€…É¹‰…¬éM•ÑM¡½Ý¸¡ÑÕÑ½É¥…°¹ÍÑ•À€ø€Ä¤ì…É¹¹•áÐé•Ñ½¹ÑMÑÉ¥¹œ ¤éM•ÑQ•áÐ¡ÍÑ•À¹™¥¹¥Í …¹€‰¥¹¥Í ˆ½È€‰9•áÐˆ¤(€€€…ÉéM•Ñ!•¥¡Ð ÈÈÀ¤(€€€±½…°Ñ…É•Ð€ô¥¹‘½¹ÑÉ½°¡ÍÑ•À¹™½ÕÌ¤(€€€!¥¡±¥¡Ð¡Ñ…É•Ð¤ìMÁ½Ñ±¥¡Ð¡Ñ…É•Ð¤(€€€€´´AÕÐÑ¡”…É‰•Í¥‘”Ñ¡”¡¥¡±¥¡Ñ•Ñ…É•ÐÝ¡•¹•Ù•ÈÑ¡•É”¥ÌÉ½½´ìÑ¡”(€€€€´´•‘¥Ñ½ÈÍÑ…åÌ±¥­…‰±”…¹Ñ¡”•áÁ±…¹…Ñ¥½¸¹•Ù•ÈÍ¥ÑÌ½¸¥ÑÌÑ…É•Ð¸(€€€…ÉéM•ÑM…±” Ä¤(€€€…Éé±•…É±±A½¥¹ÑÌ ¤(€€€±½…°Á…¹•°€ô¹Ì¹=ÁÑ¥½¹Ì(€€€±½…°½µÁ…Ð€ôU%A…É•¹Ðé•Ñ]¥‘Ñ  ¤€ð€ÄÀÀÀ½ÈU%A…É•¹Ðé•Ñ!•¥¡Ð ¤€ð€ØÔÀ(€€€€€€€½È€¡Á…¹•°…¹€¡Á…¹•°é•Ñ]¥‘Ñ  ¤€ðô€àÀÀ½ÈÁ…¹•°é•Ñ!•¥¡Ð ¤€ðô€ÔÐÀ¤¤(€€€¥˜½µÁ…ÐÑ¡•¸(€€€€€€€€´´=¸„Íµ…±°Ù¥•ÝÁ½ÉÐÑ¡•É”¥Ì¹¼¡½¹•ÍÐÝ…äÑ¼™¥ÐÑ¡”…É‰•Í¥‘”„(€€€€€€€€´´±…É”•‘¥Ñ½ÈÁ…¹”¸½¬¥Ð½µÁ…Ñ±ä…¹É•µ½Ù”Ñ¡”½µÁ•Ñ¥¹œ‰½à¸(€€€€€€€±•…É=ÕÑ±¥¹” ¤ì±•…ÉMÁ½Ñ±¥¡Ð ¤(€€€€€€€…ÉéM•ÑM…±” À¸àà¤(€€€€€€€…ÉéM•ÑA½¥¹Ð ‰	=QQ=5I%!Pˆ°U%A…É•¹Ð°€‰	=QQ=5I%!Pˆ°€´ÄÐ°€ÄÐ¤(€€€€€€€…ÉéI…¥Í” ¤(€€€€€€€É•ÑÕÉ¸(€€€•¹(€€€€´´¹½Éµ…°•‘¥Ñ½È±•…Ù•Ì„•¹•É½ÕÌ½±Õµ¸Ñ¼¥ÑÌ±•™Ð½¸Ý¥‘”ÍÉ••¹Ì¸(€€€€´´½­¥¹œÑ¡”•áÁ±…¹…Ñ¥½¸Ñ¡•É”­••ÁÌ¥ÐÙ¥Í¥‰±”€©…¹¨ÁÉ•Ù•¹ÑÌ¥Ð™É½´(€€€€´´½Ù•É¥¹œÑ¡”É•…°Ñ…É•ÐÉ½Ü½È‰ÕÑÑ½¸Ñ¡”Á±…å•ÈµÕÍÐ±¥¬¹•áÐ¸(€€€±½…°Á…¹•±1•™Ð(€€€¥˜Á…¹•°…¹¹Ì¹•ÑUÍ…‰±•É…µ•I•ÐÑ¡•¸Á…¹•±1•™Ð€ô¹Ìé•ÑUÍ…‰±•É…µ•I•Ð¡Á…¹•°¤•¹(€€€¥˜Á…¹•±1•™Ð…¹Á…¹•±1•™Ð€øô€ÐÈÈÑ¡•¸(€€€€€€€…ÉéM•ÑA½¥¹Ð ‰	=QQ=51Pˆ°U%A…É•¹Ð°€‰	=QQ=51Pˆ°€Äà°€Äà¤(€€€€€€€…ÉéI…¥Í” ¤(€€€€€€€É•ÑÕÉ¸(€€€•¹(€€€¥˜M…™•M¡½Ý¸¡Ñ…É•Ð¤Ñ¡•¸(€€€€€€€±½…°±•™Ð°‰½ÑÑ½´°Ý¥‘Ñ °¡•¥¡Ð(€€€€€€€¥˜¹Ì¹•ÑUÍ…‰±•É…µ•I•ÐÑ¡•¸(€€€€€€€€€€€±•™Ð°‰½ÑÑ½´°Ý¥‘Ñ °¡•¥¡Ð€ô¹Ìé•ÑUÍ…‰±•É…µ•I•Ð¡Ñ…É•Ð¤(€€€€€€€•¹(€€€€€€€¥˜±•™Ð…¹‰½ÑÑ½´…¹Ý¥‘Ñ …¹¡•¥¡Ð…¹±•™Ð€¬Ý¥‘Ñ €¬€ÐÀØ€ðU%A…É•¹Ðé•Ñ]¥‘Ñ  ¤Ñ¡•¸(€€€€€€€€€€€…ÉéM•ÑA½¥¹Ð ‰Q=A1Pˆ°U%A…É•¹Ð°€‰	=QQ=51Pˆ°±•™Ð€¬Ý¥‘Ñ €¬€ÄÈ°‰½ÑÑ½´€¬¡•¥¡Ð¤(€€€€€€€•±Í•¥˜±•™Ð…¹‰½ÑÑ½´…¹Ý¥‘Ñ …¹¡•¥¡Ð…¹±•™Ð€´€ÐÀØ€ø€ÀÑ¡•¸(€€€€€€€€€€€…ÉéM•ÑA½¥¹Ð ‰Q=AI%!Pˆ°U%A…É•¹Ð°€‰	=QQ=51Pˆ°±•™Ð€´€ÄÈ°‰½ÑÑ½´€¬¡•¥¡Ð¤(€€€€€€€•±Í”(€€€€€€€€€€€…ÉéM•ÑA½¥¹Ð ‰9QHˆ°U%A…É•¹Ð°€‰9QHˆ°€À°€µU%A…É•¹Ðé•Ñ!•¥¡Ð ¤€¨€À¸ÈÐ¤(€€€€€€€•¹(€€€•±Í”(€€€€€€€…ÉéM•ÑA½¥¹Ð ‰9QHˆ°U%A…É•¹Ð°€‰9QHˆ°€À°€µU%A…É•¹Ðé•Ñ!•¥¡Ð ¤€¨€À¸ÈÐ¤(€€€•¹(€€€…ÉéI…¥Í” ¤)•¹()™Õ¹Ñ¥½¸¹Ìé=¹QÕÑ½É¥…±½µ‰…ÑMÑ…Ñ•¡…¹•¡¥¹½µ‰…Ð¤(€€€±½…°ÑÕÑ½É¥…°°…É€ô¹Ì¹QÕÑ½É¥…°°¹Ì¹QÕÑ½É¥…±…É(€€€¥˜¹½ÐÑÕÑ½É¥…°½È¹½Ð…ÉÑ¡•¸É•ÑÕÉ¸•¹(€€€¥˜¥¹½µ‰…ÐÑ¡•¸(€€€€€€€ÑÕÑ½É¥…°¹Á…ÕÍ•€ôÑÉÕ”ìÑÕÑ½É¥…°¹¡¥‘¥¹½É½µ‰…Ð€ôÑÉÕ”ì±•…É=ÕÑ±¥¹” ¤ì±•…ÉMÁ½Ñ±¥¡Ð ¤(€€€€€€€…Éé!¥‘” ¤(€€€•±Í•¥˜ÑÕÑ½É¥…°¹Á…ÕÍ•Ñ¡•¸(€€€€€€€ÑÕÑ½É¥…°¹Á…ÕÍ•€ô™…±Í”ìÑÕÑ½É¥…°¹¡¥‘¥¹½É½µ‰…Ð€ô™…±Í”ì…ÉéM¡½Ü ¤ì…É¹¹•áÐéM¡½Ü ¤ì…É¹Í­¥Àé•Ñ½¹ÑMÑÉ¥¹œ ¤éM•ÑQ•áÐ ‰M­¥Àˆ¤ì¹ÌéI•™É•Í¡QÕÑ½É¥…° ¤(€€€•¹)•¹