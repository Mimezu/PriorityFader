Exit code: 0
Wall time: 0.4 seconds
Total output lines: 3336
Output:
local ADDON, ns = ...

ns.NAME = "Frame Gambit"
ns.VERSION = "2.6.0"
BINDING_HEADER_PRIORITYFADER = "Frame Gambit"
BINDING_NAME_PRIORITYFADER_TOGGLE_CINEMATIC = "Toggle Frame Gambit Cinematic Mode"
ns.MAX_REACTIONS_PER_TARGET = 32
ns.COLORS = {
    panel = { 0.035, 0.04, 0.065, 0.98 },
    card = { 0.075, 0.075, 0.115, 0.96 },
    cardAlt = { 0.055, 0.06, 0.09, 0.96 },
    border = { 0.30, 0.22, 0.48, 0.85 },
    accent = { 0.61, 0.46, 1.0, 1 },
    teal = { 0.15, 0.82, 0.74, 1 },
    muted = { 0.62, 0.64, 0.72, 1 },
    -- Red is reserved for unavailable, unsafe, and confirm-before-changing
    -- states. Cinematic owns the warm orange identity color below.
    amber = { 0.94, 0.30, 0.30, 1 },
    cinematic = { 0.90, 0.52, 0.24, 1 },
}

local DEFAULTS = {
    version = 11,
    profile = "Default",
    tutorial = {
        completed = false,
        lastStep = 1,
    },
    cinematic = {
        letterboxEnabled = false,
        letterboxHeight = 0.04,
    },
    profiles = {
        Default = {
            targets = {},
            groups = {},
            links = {},
            visibilityLinks = {},
            nextReactionID = 1,
            nextGroupID = 1,
        },
    },
}

local DEFAULT_REACTIONS = {
    { id = "mouseover", condition = "mouseover", opacity = 1.00 },
    { id = "combat", condition = "combat", opacity = 1.00 },
}

local CONDITION_INFO = {
    mouseover = { label = "Mouseover", category = "presence", kind = "state" },
    linked_parent_hover = { label = "Linked parent hover", category = "legacy", kind = "state", internal = true },
    combat = { label = "In combat", category = "presence", kind = "state" },
    out_of_combat = { label = "Out of combat", category = "presence", kind = "state" },
    movement = { label = "Movement", category = "presence", kind = "state", restricted = true },
    -- Retained solely for existing saved profiles. New rules use the single
    -- Movement Boolean card: Yes = moving, No = stationary.
    moving = { label = "Moving", category = "presence", kind = "state", restricted = true, deprecated = true },
    stationary = { label = "Stationary", category = "presence", kind = "state", restricted = true, deprecated = true },
    casting = { label = "Is casting", category = "presence", kind = "state" },
    falling = { label = "Falling", category = "presence", kind = "state" },
    shift = { label = "Shift held", category = "presence", kind = "state" },
    control = { label = "Control held", category = "presence", kind = "state" },
    alt = { label = "Alt held", category = "presence", kind = "state" },
    dead = { label = "Dead or ghost", category = "presence", kind = "state" },
    stealth = { label = "Stealthed / invisible", category = "presence", kind = "state" },
    form = { label = "Form", category = "presence", kind = "state" },
    spec = { label = "Spec", category = "presence", kind = "state" },

    target_any = { label = "Has any target", category = "target", kind = "state" },
    target_hostile = { label = "Has hostile target", category = "target", kind = "state" },
    target_friendly = { label = "Has friendly target", category = "target", kind = "state" },
    target_dead = { label = "Target is dead", category = "target", kind = "state" },
    no_target = { label = "No target", category = "target", kind = "state" },

    mounted = { label = "Mounted", category = "travel", kind = "state" },
    flying = { label = "Flying", category = "travel", kind = "state" },
    dragonriding = { label = "Dragonriding / skyriding", category = "travel", kind = "state", restricted = true },
    swimming = { label = "Swimming", category = "travel", kind = "state" },
    underwater = { label = "Underwater", category = "travel", kind = "state" },
    vehicle = { label = "In vehicle", category = "travel", kind = "state" },
    taxi = { label = "On flight path", category = "travel", kind = "state" },
    pet_battle = { label = "Pet battle", category = "travel", kind = "state" },
    fishing = { label = "Fishing", category = "travel", kind = "state" },

    class_pet = { label = "Class pet active", category = "pets", kind = "state" },
    cosmetic_pet = { label = "Cosmetic companion active", category = "pets", kind = "state" },

    group = { label = "In party", category = "social", kind = "state" },
    raid = { label = "In raid", category = "social", kind = "state" },
    solo = { label = "Solo", category = "social", kind = "state" },
    instance = { label = "In an instance", category = "social", kind = "state" },
    open_world = { label = "In open world", category = "social", kind = "state" },
    dungeon = { label = "In dungeon", category = "social", kind = "state" },
    raid_instance = { label = "In raid instance", category = "social", kind = "state" },
    battleground = { label = "In battleground", category = "social", kind = "state" },
    arena = { label = "In arena", category = "social", kind = "state" },
    scenario = { label = "In scenario", category = "social", kind = "state" },
    delve = { label = "In Delve", category = "social", kind = "state" },

    resting = { label = "Resting", category = "world", kind = "state" },
    pvp_flagged = { label = "PvP flagged", category = "world", kind = "state", restricted = true },
    war_mode = { label = "War Mode enabled", category = "world", kind = "state" },
    indoors = { label = "Indoors", category = "world", kind = "state" },
    outdoors = { label = "Outdoors", category = "world", kind = "state" },
    quest_update = { label = "Quest updated", category = "moment", kind = "moment", duration = 3 },
    quest_accepted = { label = "Quest accepted", category = "moment", kind = "moment", duration = 3 },
    quest_turned_in = { label = "Quest turned in", category = "moment", kind = "moment", duration = 3 },
    quest_objective = { label = "Quest objective updated", category = "moment", kind = "moment", duration = 3 },
    loot = { label = "Looted an item", category = "moment", kind = "moment", duration = 4 },
    loot_opened = { label = "Loot window opened", category = "moment", kind = "moment", duration = 5 },

    -- Kept only to make existing early saved profiles migrate invisibly.
    target = { label = "Has any target", category = "legacy", kind = "state", internal = true },
    hostile_target = { label = "Has hostile target", category = "legacy", kind = "state", internal = true },
    pvp = { label = "PvP flagged", category = "legacy", kind = "state", internal = true },
}
ns.CONDITION_INFO = CONDITION_INFO

-- Form entries deliberately describe only gameplay forms that WoW exposes in
-- the player's shapeshift bar.  A reaction is skipped when its form is not
-- available to the current class/spec, which makes one profile safe to share
-- across specs without a negative Form row accidentally matching everywhere.
local FORM_OPTIONS = {
    { id = "druid_bear", label = "Bear Form", class = "DRUID", spellID = 5487 },
    { id = "druid_cat", label = "Cat Form", class = "DRUID", spellID = 768 },
    { id = "druid_travel", label = "Travel Form", class = "DRUID", spellID = 783 },
    { id = "druid_moonkin", label = "Moonkin Form", class = "DRUID", spellID = 24858 },
    { id = "priest_shadow", label = "Shadowform", class = "PRIEST", spellID = 232698 },
    { id = "shaman_ghost_wolf", label = "Ghost Wolf", class = "SHAMAN", spellID = 2645 },
    { id = "demonhunter_havoc_meta", label = "Metamorphosis (Havoc)", class = "DEMONHUNTER", spellID = 191427 },
    { id = "demonhunter_vengeance_meta", label = "Metamorphosis (Vengeance)", class = "DEMONHUNTER", spellID = 187827 },
    { id = "demonhunter_devourer_void_meta", label = "Void Metamorphosis (Devourer)", class = "DEMONHUNTER", spellID = 1225789 },
}
local FORM_BY_ID = {}
for _, option in ipairs(FORM_OPTIONS) do FORM_BY_ID[option.id] = option end
ns.FORM_OPTIONS, ns.FORM_BY_ID = FORM_OPTIONS, FORM_BY_ID

local SPEC_OPTIONS = {
    { class = "WARRIOR", classLabel = "Warrior", id = 71, label = "Arms" }, { class = "WARRIOR", classLabel = "Warrior", id = 72, label = "Fury" }, { class = "WARRIOR", classLabel = "Warrior", id = 73, label = "Protection" },
    { class = "PALADIN", classLabel = "Paladin", id = 65, label = "Holy" }, { class = "PALADIN", classLabel = "Paladin", id = 66, label = "Protection" }, { class = "PALADIN", classLabel = "Paladin", id = 70, label = "Retribution" },
    { class = "HUNTER", classLabel = "Hunter", id = 253, label = "Beast Mastery" }, { class = "HUNTER", classLabel = "Hunter", id = 254, label = "Marksmanship" }, { class = "HUNTER", classLabel = "Hunter", id = 255, label = "Survival" },
    { class = "ROGUE", classLabel = "Rogue", id = 259, label = "Assassination" }, { class = "ROGUE", classLabel = "Rogue", id = 260, label = "Outlaw" }, { class = "ROGUE", classLabel = "Rogue", id = 261, label = "Subtlety" },
    { class = "PRIEST", classLabel = "Priest", id = 256, label = "Discipline" }, { class = "PRIEST", classLabel = "Priest", id = 257, label = "Holy" }, { class = "PRIEST", classLabel = "Priest", id = 258, label = "Shadow" },
    { class = "DEATHKNIGHT", classLabel = "Death Knight", id = 250, label = "Blood" }, { class = "DEATHKNIGHT", classLabel = "Death Knight", id = 251, label = "Frost" }, { class = "DEATHKNIGHT", classLabel = "Death Knight", id = 252, label = "Unholy" },
    { class = "SHAMAN", classLabel = "Shaman", id = 262, label = "Elemental" }, { class = "SHAMAN", classLabel = "Shaman", id = 263, label = "Enhancement" }, { class = "SHAMAN", classLabel = "Shaman", id = 264, label = "Restoration" },
    { class = "MAGE", classLabel = "Mage", id = 62, label = "Arcane" }, { class = "MAGE", classLabel = "Mage", id = 63, label = "Fire" }, { class = "MAGE", classLabel = "Mage", id = 64, label = "Frost" },
    { class = "WARLOCK", classLabel = "Warlock", id = 265, label = "Affliction" }, { class = "WARLOCK", classLabel = "Warlock", id = 266, label = "Demonology" }, { class = "WARLOCK", classLabel = "Warlock", id = 267, label = "Destruction" },
    { class = "MONK", classLabel = "Monk", id = 268, label = "Brewmaster" }, { class = "MONK", classLabel = "Monk", id = 269, label = "Windwalker" }, { class = "MONK", classLabel = "Monk", id = 270, label = "Mistweaver" },
    { class = "DRUID", classLabel = "Druid", id = 102, label = "Balance" }, { class = "DRUID", classLabel = "Druid", id = 103, label = "Feral" }, { class = "DRUID", classLabel = "Druid", id = 104, label = "Guardian" }, { class = "DRUID", classLabel = "Druid", id = 105, label = "Restoration" },
    { class = "DEMONHUNTER", classLabel = "Demon Hunter", id = 577, label = "Havoc" }, { class = "DEMONHUNTER", classLabel = "Demon Hunter", id = 581, label = "Vengeance" }, { class = "DEMONHUNTER", classLabel = "Demon Hunter", id = 1480, label = "Devourer" },
    { class = "EVOKER", classLabel = "Evoker", id = 1467, label = "Devastation" }, { class = "EVOKER", classLabel = "Evoker", id = 1468, label = "Preservation" }, { class = "EVOKER", classLabel = "Evoker", id = 1473, label = "Augmentation" },
}
local SPEC_BY_ID, SPECS_BY_CLASS, CLASS_OPTIONS = {}, {}, {}
for _, option in ipairs(SPEC_OPTIONS) do
    SPEC_BY_ID[option.id] = option
    SPECS_BY_CLASS[option.class] = SPECS_BY_CLASS[option.class] or {}
    SPECS_BY_CLASS[option.class][#SPECS_BY_CLASS[option.class] + 1] = option
end
for classID, specs in pairs(SPECS_BY_CLASS) do CLASS_OPTIONS[#CLASS_OPTIONS + 1] = { id = classID, label = specs[1].classLabel } end
table.sort(CLASS_OPTIONS, function(a, b) return a.label < b.label end)
ns.SPEC_OPTIONS, ns.SPEC_BY_ID, ns.SPECS_BY_CLASS, ns.CLASS_OPTIONS = SPEC_OPTIONS, SPEC_BY_ID, SPECS_BY_CLASS, CLASS_OPTIONS
ns.CONDITION_CATEGORY_ORDER = {
    { id = "presence", label = "Presence" },
    { id = "target", label = "Target" },
    { id = "travel", label = "Travel" },
    { id = "pets", label = "Pets" },
    { id = "social", label = "Group & instance" },
    { id = "world", label = "World" },
    { id = "moment", label = "Moments" },
}

local EVENT_TO_MOMENT = {
    QUEST_ACCEPTED = { "quest_update", "quest_accepted" },
    QUEST_TURNED_IN = { "quest_update", "quest_turned_in" },
    QUEST_WATCH_UPDATE = { "quest_update", "quest_objective" },
    QUEST_LOG_UPDATE = "quest_update",
    LOOT_OPENED = "loot_opened",
}

local runtime = {
    baseAlpha = setmetatable({}, { __mode = "k" }),
    currentAlpha = setmetatable({}, { __mode = "k" }),
    frameByID = {},
    hovered = {},
    active = {},
    moments = {},
    context = {},
    fadeOutStarted = {},
    revealGoal = {},
    transitions = {},
    pendingRestore = setmetatable({}, { __mode = "k" }),
    pendingRelease = setmetatable({}, { __mode = "k" }),
    normalized = setmetatable({}, { __mode = "k" }),
    managedIDByFrame = setmetatable({}, { __mode = "k" }),
    managedAlphaHooks = setmetatable({}, { __mode = "k" }),
    managedAlphaAuditAt = setmetatable({}, { __mode = "k" }),
    managedAlphaGuard = setmetatable({}, { __mode = "k" }),
    immediateApply = {},
    cinematicBlackout = setmetatable({}, { __mode = "k" }),
    cinematicBlackoutHooks = setmetatable({}, { __mode = "k" }),
    cinematicAlphaGuard = setmetatable({}, { __mode = "k" }),
    cinematicExemptFrames = setmetatable({}, { __mode = "k" }),
    cinematicOpenWindows = setmetatable({}, { __mode = "k" }),
    cinematicRootScanAt = 0,
    cinematicAuditAt = 0,
    cinematicRevealActive = nil,
    cinematicRescanToken = 0,
    lastTick = 0,
    lastMouseTick = 0,
    playerCasting = false,
}
ns.runtime = runtime

-- Declared here so the evaluator can deliberately detach its shared OnUpdate
-- below, while the actual event driver remains created near the event list.
-- Keeping one driver (rather than per-target frame handlers) is important for
-- both performance and safe late-provider wakeups.
local driver

local SafeFrameAlpha

local function IsSecret(value)
    return issecretvalue and issecretvalue(value) or false
end

local function SafeBoolean(func, ...)
    if type(func) ~= "function" then return nil end
    local ok, value = pcall(func, ...)
    if not ok or IsSecret(value) then return nil end
    return value and true or false
end

local function SafeValue(func, ...)
    if type(func) ~= "function" then return nil end
    local ok, value = pcall(func, ...)
    if not ok or value == nil or IsSecret(value) then return nil end
    return value
end

local function CallFrameIsShown(frame)
    return frame:IsShown()
end

local function CallFrameGetRect(frame)
    return frame:GetRect()
end

local function CallFrameGetAlpha(frame)
    return frame:GetAlpha()
end

local function CallFrameSetAlpha(frame, alpha)
    frame:SetAlpha(alpha)
end

local function SafeSetFrameAlpha(frame, alpha)
    return pcall(CallFrameSetAlpha, frame, alpha)
end

local function IsLocalLootMessage(senderName, senderGUID)
    if senderGUID ~= nil then
        if IsSecret(senderGUID) then return false end
        local playerGUID = SafeValue(UnitGUID, "player")
        return playerGUID ~= nil and senderGUID == playerGUID
    end
    -- Older/nonstandard payloads may omit GUID.  Use only an exact, guarded
    -- local-name fallback; realm-normalization or chat-message parsing would
    -- risk claiming another player's loot.
    if senderName == nil or IsSecret(senderName) then return false end
    local playerName = SafeValue(UnitName, "player")
    return playerName ~= nil and senderName == playerName
end

local function CopyDefaults(defaults, value)
    if type(defaults) ~= "table" then return value == nil and defaults or value end
    local result = type(value) == "table" and value or {}
    for k, v in pairs(defaults) do
        if result[k] == nil then
            result[k] = CopyDefaults(v)
        elseif type(v) == "table" then
            result[k] = CopyDefaults(v, result[k])
        end
    end
    return result
end

local function DeepCopy(value, seen)
    if type(value) ~= "table" then return value end
    seen = seen or {}
    if seen[value] then return seen[value] end
    local copy = {}
    seen[value] = copy
    for key, child in pairs(value) do copy[DeepCopy(key, seen)] = DeepCopy(child, seen) end
    return copy
end

function ns:Profile()
    local db = PriorityFaderDB
    db.profiles = db.profiles or {}
    db.profile = db.profile or "Default"
    db.profiles[db.profile] = db.profiles[db.profile] or { targets = {}, groups = {}, links = {}, visibilityLinks = {}, nextReactionID = 1, nextGroupID = 1 }
    local profile = db.profiles[db.profile]
    profile.targets = type(profile.targets) == "table" and profile.targets or {}
    profile.groups = type(profile.groups) == "table" and profile.groups or {}
    profile.links = type(profile.links) == "table" and profile.links or {}
    profile.visibilityLinks = type(profile.visibilityLinks) == "table" and profile.visibilityLinks or {}
    profile.nextReactionID = tonumber(profile.nextReactionID) or 1
    profile.nextGroupID = tonumber(profile.nextGroupID) or 1
    return profile
end

function ns:NextReactionID()
    local profile = self:Profile()
    local id = profile.nextReactionID
    profile.nextReactionID = id + 1
    return id
end

function ns:NextGroupID()
    local profile = self:Profile()
    local id = profile.nextGroupID
    profile.nextGroupID = id + 1
    return id
end

function ns:MigrateDatabase()
    local db = PriorityFaderDB
    local oldVersion = tonumber(db.version) or 1
    local aliases = { target = "target_any", hostile_target = "target_hostile", pvp = "pvp_flagged" }
    local function RemoveProfileTargets(profile, matches)
        if type(profile) ~= "table" then return end
        profile.targets = type(profile.targets) == "table" and profile.targets or {}
        profile.groups = type(profile.groups) == "table" and profile.groups or {}
        profile.links = type(profile.links) == "table" and profile.links or {}
        profile.visibilityLinks = type(profile.visibilityLinks) == "table" and profile.visibilityLinks or {}
        local retired = {}
        for id in pairs(profile.targets) do if matches(id) then retired[#retired + 1] = id end end
        for _, id in ipairs(retired) do
            profile.targets[id] = nil
            for groupID, group in pairs(profile.groups) do
                if type(group) ~= "table" or type(group.members) ~= "table" then
                    profile.groups[groupID] = nil
                else
                    group.members[id] = nil
                    local count = 0
                    for memberID, enabled in pairs(group.members) do
                        if enabled == true and type(memberID) == "string" then count = count + 1 else group.members[memberID] = nil end
                    end
                    if count < 2 then profile.groups[groupID] = nil end
                end
            end
            profile.links[id] = nil
            for parentID, children in pairs(profile.links) do
                if type(children) ~= "table" then
                    profile.links[parentID] = nil
                else
                    children[id] = nil
                    if not next(children) then profile.links[parentID] = nil end
                end
            end
            profile.visibilityLinks[id] = nil
            for parentID, children in pairs(profile.visibilityLinks) do
                if type(children) ~= "table" then
                    profile.visibilityLinks[parentID] = nil
                else
                    children[id] = nil
                    if not next(children) then profile.visibilityLinks[parentID] = nil end
                end
            end
        end
    end
    local function RemapProfileTarget(profile, fromID, toID)
        if type(profile) ~= "table" or type(fromID) ~= "string" or fromID == toID then return end
        profile.targets = type(profile.targets) == "table" and profile.targets or {}
        profile.groups = type(profile.groups) == "table" and profile.groups or {}
        profile.links = type(profile.links) == "table" and profile.li…31484 tokens truncated…al
    -- targets.  Alpha transitions remain smooth at 20 Hz without an OnUpdate
    -- handler per frame.
    if now - runtime.lastTick < 0.05 then return end
    runtime.lastTick = now
    if now - runtime.lastMouseTick >= 0.08 then
        runtime.lastMouseTick = now
        self:UpdateHover()
    end
    self:BuildStateContext()
    local profile = self:Profile()
    for id in pairs(profile.targets or {}) do self:ApplyTarget(id, now) end
    if self.UpdateMinimapStack then
        local rescan = now - (runtime.lastMinimapStackScan or 0) >= 1
        if rescan then runtime.lastMinimapStackScan = now end
        self:UpdateMinimapStack(rescan)
    end
    if self:IsCinematicActive() then
        -- Outside combat, Alt suspends only Priority Fader's native role mode
        -- while the alpha ledger reveals its roots. This keeps the documented
        -- recovery gesture useful even for Blizzard-managed UI roles.
        if not InCombatLockdown() then
            local reveal = runtime.cinematicPickerReveal or (IsAltKeyDown and IsAltKeyDown()) or false
            self:SetCinematicUIMode(self:CanUseCinematicNativeMode() and not reveal)
        end
        if not InCombatLockdown() and now - (runtime.cinematicRootScanAt or 0) >= 2.5 then
            self:BeginCinematicBlackout()
        else
            self:UpdateCinematicBlackout()
        end
    end
    if self.Options and self.Options:IsVisible() then self:RefreshActiveState() end
    -- An empty profile should not keep a 20 Hz evaluator alive forever.  All
    -- game events, editor mutations, profile selection and late addon loads
    -- already call Wake(), so this does not trade correctness for idling.
    if not self:HasEvaluatorWork() then self:Sleep() end
end

local function SafeDiagnosticText(text)
    text = tostring(text or ""):gsub("|", "||"):gsub("[\r\n]", " ")
    if #text > 240 then text = text:sub(1, 237) .. "..." end
    return text
end

local function DiagnosticID(value)
    return SafeDiagnosticText(value):sub(1, 72)
end

local function DiagnosticMessage(text, color)
    local target = DEFAULT_CHAT_FRAME
    if target and target.AddMessage then target:AddMessage("|cff9D75FFFrame Gambit|r " .. SafeDiagnosticText(text), color and color[1], color and color[2], color and color[3]) end
end

function ns:RunDiagnostics()
    local db = PriorityFaderDB
    local profile = db and db.profiles and db.profiles[db.profile]
    if type(profile) ~= "table" then
        DiagnosticMessage("No active saved profile is loaded. Reload UI before using the audit.", self.COLORS.amber)
        return
    end
    local targets = type(profile.targets) == "table" and profile.targets or {}
    local groups = type(profile.groups) == "table" and profile.groups or {}
    local links = type(profile.links) == "table" and profile.links or {}
    local visibilityLinks = type(profile.visibilityLinks) == "table" and profile.visibilityLinks or {}
    local configured, configuredAvailable, groupCount, linkCount, visibilityCount = 0, 0, 0, 0, 0
    local issues, groupMembers, connected = {}, {}, {}
    if profile.targets ~= targets then issues[#issues + 1] = "Target settings are malformed." end
    if profile.groups ~= groups then issues[#issues + 1] = "Reveal groups are malformed." end
    if profile.links ~= links then issues[#issues + 1] = "Frame links are malformed." end
    if profile.visibilityLinks ~= visibilityLinks then issues[#issues + 1] = "Visibility inheritance is malformed." end
    for id, settings in pairs(targets) do
        configured = configured + 1
        if type(id) ~= "string" then
            issues[#issues + 1] = "A configured target id is not a string."
        else
            local available = self:GetTargetAvailability(id)
            if available then configuredAvailable = configuredAvailable + 1 end
            if not self.TargetByID[id] then issues[#issues + 1] = "Configured target " .. DiagnosticID(id) .. " no longer has an adapter." end
            if type(settings) ~= "table" or settings.enabled ~= true then issues[#issues + 1] = "Configured target " .. DiagnosticID(id) .. " is disabled or malformed." end
        end
    end
    for groupID, group in pairs(groups) do
        groupCount = groupCount + 1
        local members = 0
        local memberTable = type(group) == "table" and type(group.members) == "table" and group.members or {}
        if type(group) ~= "table" or group.members ~= memberTable then issues[#issues + 1] = "Reveal group " .. DiagnosticID(groupID) .. " is malformed." end
        for id in pairs(memberTable) do
            members = members + 1
            if type(id) ~= "string" then
                issues[#issues + 1] = "A reveal-group target id is not a string."
            elseif groupMembers[id] then
                issues[#issues + 1] = "Target " .. DiagnosticID(id) .. " appears in multiple reveal groups."
            end
            groupMembers[id] = groupID
            if type(id) == "string" then
                connected[id] = true
                if not targets[id] then issues[#issues + 1] = "Reveal group " .. DiagnosticID(groupID) .. " references an uncontrolled target." end
            end
        end
        if members < 2 then issues[#issues + 1] = "Reveal group " .. DiagnosticID(groupID) .. " has fewer than two targets." end
    end
    for parentID, children in pairs(links) do
        local childTable = type(children) == "table" and children or {}
        if type(parentID) ~= "string" then
            issues[#issues + 1] = "A link source id is not a string."
        else
            if not targets[parentID] then issues[#issues + 1] = "Link source " .. DiagnosticID(parentID) .. " is not controlled." end
        end
        if children ~= childTable then issues[#issues + 1] = "Linked children for " .. DiagnosticID(parentID) .. " are malformed." end
        for childID in pairs(childTable) do
            linkCount = linkCount + 1
            if type(childID) ~= "string" then
                issues[#issues + 1] = "A linked child id is not a string."
            else
                if childID == parentID then issues[#issues + 1] = "Link " .. DiagnosticID(parentID) .. " points to itself." end
                if not targets[childID] then issues[#issues + 1] = "Linked child " .. DiagnosticID(childID) .. " is not controlled." end
            end
        end
    end
    local visiting, visited = {}, {}
    local function HasLinkCycle(id)
        if visiting[id] then return true end
        if visited[id] then return false end
        visiting[id] = true
        for childID in pairs(type(links[id]) == "table" and links[id] or {}) do
            if HasLinkCycle(childID) then return true end
        end
        visiting[id] = nil; visited[id] = true
        return false
    end
    for parentID in pairs(links) do
        if HasLinkCycle(parentID) then
            issues[#issues + 1] = "Linked-frame graph contains a loop."
            break
        end
    end
    local visibilityParent = {}
    for parentID, children in pairs(visibilityLinks) do
        local childTable = type(children) == "table" and children or {}
        if type(parentID) ~= "string" then
            issues[#issues + 1] = "A visibility source id is not a string."
        elseif not targets[parentID] then
            issues[#issues + 1] = "Visibility source " .. DiagnosticID(parentID) .. " is not controlled."
        end
        if children ~= childTable then issues[#issues + 1] = "Visibility children for " .. DiagnosticID(parentID) .. " are malformed." end
        for childID, enabled in pairs(childTable) do
            visibilityCount = visibilityCount + 1
            if type(childID) ~= "string" or enabled ~= true then
                issues[#issues + 1] = "A visibility child entry is malformed."
            else
                if childID == parentID then issues[#issues + 1] = "Visibility source " .. DiagnosticID(parentID) .. " points to itself." end
                if not targets[childID] then issues[#issues + 1] = "Visibility child " .. DiagnosticID(childID) .. " is not controlled." end
                if visibilityParent[childID] and visibilityParent[childID] ~= parentID then
                    issues[#issues + 1] = "Visibility child " .. DiagnosticID(childID) .. " has more than one parent."
                else
                    visibilityParent[childID] = parentID
                end
            end
        end
    end
    local visibilityVisiting, visibilityVisited = {}, {}
    local function HasVisibilityCycle(id)
        if visibilityVisiting[id] then return true end
        if visibilityVisited[id] then return false end
        visibilityVisiting[id] = true
        for childID in pairs(type(visibilityLinks[id]) == "table" and visibilityLinks[id] or {}) do
            if HasVisibilityCycle(childID) then return true end
        end
        visibilityVisiting[id] = nil; visibilityVisited[id] = true
        return false
    end
    for parentID in pairs(visibilityLinks) do
        if HasVisibilityCycle(parentID) then
            issues[#issues + 1] = "Visibility-inheritance graph contains a loop."
            break
        end
    end
    for id in pairs(connected) do
        local settings, hasMouseover = targets[id], false
        for _, reaction in ipairs(type(settings) == "table" and type(settings.reactions) == "table" and settings.reactions or {}) do
            if type(reaction) == "table" and reaction.condition == "mouseover" and #(type(reaction.requirements) == "table" and reaction.requirements or {}) == 0 then hasMouseover = true; break end
        end
        if not hasMouseover then issues[#issues + 1] = "Reveal-group member " .. DiagnosticID(id) .. " lacks an unconditional Mouseover reaction." end
    end
    local adapterAvailable, adapterUnavailable, unavailable = 0, 0, {}
    for _, target in ipairs(self.Targets) do
        local available, _, _, note = self:GetTargetAvailability(target)
        if available then
            adapterAvailable = adapterAvailable + 1
        else
            adapterUnavailable = adapterUnavailable + 1
            unavailable[#unavailable + 1] = DiagnosticID(target.label) .. " - " .. DiagnosticID(note)
        end
    end
    DiagnosticMessage("v" .. self.VERSION .. " | Profile: " .. (db.profile or "Default"), self.COLORS.teal)
    DiagnosticMessage("Configured: " .. configuredAvailable .. "/" .. configured .. " currently available | Relationships: " .. groupCount .. " groups, " .. linkCount .. " hover links, " .. visibilityCount .. " visibility links.", self.COLORS.muted)
    DiagnosticMessage("Adapters: " .. adapterAvailable .. " available, " .. adapterUnavailable .. " unavailable.", adapterUnavailable > 0 and self.COLORS.amber or self.COLORS.teal)
    if #issues == 0 then
        DiagnosticMessage("Saved profile graph is consistent.", self.COLORS.teal)
    else
        DiagnosticMessage("Profile graph needs attention: " .. #issues .. " issue" .. (#issues == 1 and "" or "s") .. ".", self.COLORS.amber)
        for index = 1, math.min(4, #issues) do DiagnosticMessage("- " .. issues[index], self.COLORS.amber) end
        if #issues > 4 then DiagnosticMessage("- " .. (#issues - 4) .. " more issue(s); export before changing anything.", self.COLORS.amber) end
    end
    for index = 1, math.min(6, #unavailable) do DiagnosticMessage("Waiting: " .. unavailable[index], self.COLORS.muted) end
    if #unavailable > 6 then DiagnosticMessage("Waiting: " .. (#unavailable - 6) .. " more adapter(s).", self.COLORS.muted) end
end

local function RefreshPlayerCastingState()
    local ok, casting = pcall(function()
        local castName = type(UnitCastingInfo) == "function" and UnitCastingInfo("player") or nil
        if castName ~= nil then return true end
        local channelName = type(UnitChannelInfo) == "function" and UnitChannelInfo("player") or nil
        return channelName ~= nil
    end)
    if ok and not IsSecret(casting) then runtime.playerCasting = casting == true end
end

driver = CreateFrame("Frame")
driver:RegisterEvent("PLAYER_LOGIN")
driver:RegisterEvent("ADDON_LOADED")
driver:RegisterEvent("PLAYER_REGEN_DISABLED")
driver:RegisterEvent("PLAYER_REGEN_ENABLED")
driver:RegisterEvent("PLAYER_TARGET_CHANGED")
driver:RegisterEvent("GROUP_ROSTER_UPDATE")
driver:RegisterEvent("PLAYER_MOUNT_DISPLAY_CHANGED")
driver:RegisterEvent("PLAYER_ENTERING_WORLD")
driver:RegisterEvent("ZONE_CHANGED")
driver:RegisterEvent("ZONE_CHANGED_INDOORS")
driver:RegisterEvent("PLAYER_FLAGS_CHANGED")
driver:RegisterEvent("PLAYER_DEAD")
driver:RegisterEvent("PLAYER_ALIVE")
driver:RegisterEvent("PLAYER_UNGHOST")
driver:RegisterEvent("UNIT_ENTERED_VEHICLE")
driver:RegisterEvent("UNIT_EXITED_VEHICLE")
driver:RegisterEvent("PET_BATTLE_OPENING_START")
driver:RegisterEvent("PET_BATTLE_CLOSE")
driver:RegisterEvent("CHAT_MSG_LOOT")
driver:RegisterEvent("UPDATE_BINDINGS")
driver:RegisterEvent("UNIT_SPELLCAST_START")
driver:RegisterEvent("UNIT_SPELLCAST_STOP")
driver:RegisterEvent("UNIT_SPELLCAST_FAILED")
driver:RegisterEvent("UNIT_SPELLCAST_FAILED_QUIET")
driver:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")
driver:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START")
driver:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP")
driver:RegisterEvent("UNIT_PET")
driver:RegisterEvent("COMPANION_UPDATE")
driver:RegisterEvent("UNIT_AURA")
pcall(driver.RegisterEvent, driver, "SCENARIO_UPDATE")
pcall(driver.RegisterEvent, driver, "UPDATE_SHAPESHIFT_FORM")
pcall(driver.RegisterEvent, driver, "UPDATE_SHAPESHIFT_FORMS")
pcall(driver.RegisterEvent, driver, "PLAYER_SPECIALIZATION_CHANGED")
pcall(driver.RegisterEvent, driver, "SPELLS_CHANGED")
pcall(driver.RegisterEvent, driver, "UNIT_SPELLCAST_EMPOWER_START")
pcall(driver.RegisterEvent, driver, "UNIT_SPELLCAST_EMPOWER_STOP")
for event in pairs(EVENT_TO_MOMENT) do driver:RegisterEvent(event) end

function ns:Wake()
    if not driver:GetScript("OnUpdate") then
        driver:SetScript("OnUpdate", function(_, elapsed) ns:Tick(elapsed) end)
    end
end

driver:SetScript("OnEvent", function(_, event, ...)
    if event == "UNIT_AURA" then
        local unit = ...
        -- Stealth/invisibility changes are player-only for this addon.  Do
        -- not wake the shared evaluator for every party/nameplate aura.
        if type(unit) ~= "string" or IsSecret(unit) or unit ~= "player" then return end
    end
    if event:match("^UNIT_SPELLCAST_") then
        local unit = ...
        if type(unit) == "string" and not IsSecret(unit) and unit == "player" then
            if event == "UNIT_SPELLCAST_START" or event == "UNIT_SPELLCAST_CHANNEL_START"
                or event == "UNIT_SPELLCAST_EMPOWER_START" then
                runtime.playerCasting = true
            elseif event == "UNIT_SPELLCAST_STOP" or event == "UNIT_SPELLCAST_FAILED"
                or event == "UNIT_SPELLCAST_FAILED_QUIET" or event == "UNIT_SPELLCAST_INTERRUPTED"
                or event == "UNIT_SPELLCAST_CHANNEL_STOP" or event == "UNIT_SPELLCAST_EMPOWER_STOP" then
                runtime.playerCasting = false
            end
            -- Some stop/start pairs arrive in the same update (for example when a
            -- normal cast flows into a channel). Re-read on the next frame so the
            -- condition reflects the player's final casting state, not event order.
            C_Timer.After(0, RefreshPlayerCastingState)
        end
    end
    if event == "PLAYER_LOGIN" then
        PriorityFaderDB = CopyDefaults(DEFAULTS, PriorityFaderDB)
        ns:MigrateDatabase()
        if ns.RegisterStoredCustomFrames then ns:RegisterStoredCustomFrames() end
        ns:EnsureCinematicProfile()
        if ns.RefreshCinematicLetterbox then ns:RefreshCinematicLetterbox() end
        if ns.RefreshOPieFrames then ns:RefreshOPieFrames() end
        ns:RegisterCinematicUIMode()
        ns:EnsureConnectedHoverRules()
        RefreshPlayerCastingState()
        ns:Wake()
        ns:CreateOptions()
        if ns:IsCinematicActive() then
            ns:PrimeCinematicTargets()
            ns:SetCinematicUIMode(ns:CanUseCinematicNativeMode())
            ns:BeginCinematicBlackout()
        end
        return
    end
    if event == "ADDON_LOADED" then
        if ns.RefreshOPieFrames then ns:RefreshOPieFrames() end
        if ns:IsCinematicActive() and not InCombatLockdown() then
            -- Load-on-demand addons often arrive in bursts. Coalesce them so
            -- Cinematic discovers their roots once after the burst instead of
            -- rescanning the entire UI twice for every ADDON_LOADED event.
            runtime.cinematicRescanToken = (runtime.cinematicRescanToken or 0) + 1
            local token = runtime.cinematicRescanToken
            C_Timer.After(0.35, function()
                if token == runtime.cinematicRescanToken and ns:IsCinematicActive()
                    and not InCombatLockdown() then ns:BeginCinematicBlackout() end
            end)
        end
    end
    if event == "PLAYER_ENTERING_WORLD" then RefreshPlayerCastingState() end
    if ns.CancelPicker and (event == "PLAYER_REGEN_DISABLED" or event == "PLAYER_ENTERING_WORLD" or event == "PET_BATTLE_OPENING_START") then
        ns:CancelPicker(event == "PLAYER_REGEN_DISABLED" and "combat" or "interrupted")
    end
    if event == "PLAYER_REGEN_DISABLED" and ns.OnTutorialCombatStateChanged then
        ns:OnTutorialCombatStateChanged(true)
    elseif event == "PLAYER_REGEN_ENABLED" and ns.OnTutorialCombatStateChanged then
        ns:OnTutorialCombatStateChanged(false)
    elseif (event == "PLAYER_ENTERING_WORLD" or event == "PET_BATTLE_OPENING_START") and ns.CancelTutorial then
        ns:CancelTutorial("interrupted")
    end
    if event == "PLAYER_REGEN_DISABLED" and ns.CinematicKeyCapture and ns.CinematicKeyCapture:IsShown() then
        ns.CinematicKeyCapture:Hide()
    end
    if event == "CHAT_MSG_LOOT" and IsLocalLootMessage(select(2, ...), select(12, ...)) then
        runtime.moments.loot = GetTime()
    end
    local moment = EVENT_TO_MOMENT[event]
    if type(moment) == "table" then
        local now = GetTime()
        for _, momentID in ipairs(moment) do runtime.moments[momentID] = now end
    elseif moment then
        runtime.moments[moment] = GetTime()
    end
    if event == "PLAYER_REGEN_ENABLED" then
        ns:RestorePendingAlphas()
        if ns:IsCinematicActive() then ns:BeginCinematicBlackout() end
    end
    if event == "PLAYER_ENTERING_WORLD" and ns:IsCinematicActive() and not InCombatLockdown() then
        ns:BeginCinematicBlackout()
    end
    if event == "UPDATE_BINDINGS" and ns.Options and ns.Options:IsShown() then
        ns:RenderOptions()
    end
    ns:Wake()
    -- The option panel updates its live-state chip from Tick.  Rebuilding its
    -- dynamic rows for every game event would continually create hidden UI
    -- objects, so only explicit editor actions redraw it.
end)

SLASH_PRIORITYFADER1 = "/pfader"
SLASH_PRIORITYFADER2 = "/priorityfader"
SLASH_PRIORITYFADER3 = "/framegambit"
SLASH_PRIORITYFADER4 = "/fgambit"
SLASH_PRIORITYFADER5 = "/fg"
function PriorityFader_ToggleCinematic()
    local ok, reason, enabled = ns:ToggleCinematic()
    if not ok and DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then
        DEFAULT_CHAT_FRAME:AddMessage("|cff9D75FFFrame Gambit|r " .. tostring(reason or "Cinematic Mode could not be toggled."))
    elseif ok and ns.Options and ns.Options.active then
        ns.Options.active:SetText(enabled and "Cinematic Mode on" or "Cinematic Mode off")
        ns.Options.active:SetTextColor(unpack(ns.COLORS.teal))
    end
end

SlashCmdList.PRIORITYFADER = function(message)
    local command = (message or ""):match("^%s*(.-)%s*$"):lower()
    if command == "pick" then
        ns:StartPicker()
    elseif command == "audit" or command == "status" then
        ns:RunDiagnostics()
    elseif command == "cinematic" or command == "cinema" then
        PriorityFader_ToggleCinematic()
    else
        ns:ToggleOptions()
    end
end

