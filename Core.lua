local ADDON, ns = ...

ns.NAME = "Priority Fader"
ns.VERSION = "2.3.0"
BINDING_HEADER_PRIORITYFADER = "Priority Fader"
BINDING_NAME_PRIORITYFADER_TOGGLE_CINEMATIC = "Toggle Cinematic Mode"
ns.MAX_REACTIONS_PER_TARGET = 32
ns.COLORS = {
    panel = { 0.035, 0.04, 0.065, 0.98 },
    card = { 0.075, 0.075, 0.115, 0.96 },
    cardAlt = { 0.055, 0.06, 0.09, 0.96 },
    border = { 0.30, 0.22, 0.48, 0.85 },
    accent = { 0.61, 0.46, 1.0, 1 },
    teal = { 0.15, 0.82, 0.74, 1 },
    muted = { 0.62, 0.64, 0.72, 1 },
    amber = { 0.94, 0.65, 0.22, 1 },
}

local DEFAULTS = {
    version = 8,
    profile = "Default",
    cinematic = {},
    profiles = {
        Default = {
            targets = {},
            groups = {},
            links = {},
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
    combat = { label = "In combat", category = "presence", kind = "state" },
    out_of_combat = { label = "Out of combat", category = "presence", kind = "state" },
    moving = { label = "Moving", category = "presence", kind = "state", restricted = true },
    stationary = { label = "Stationary", category = "presence", kind = "state", restricted = true },
    falling = { label = "Falling", category = "presence", kind = "state" },
    shift = { label = "Shift held", category = "presence", kind = "state" },
    control = { label = "Control held", category = "presence", kind = "state" },
    alt = { label = "Alt held", category = "presence", kind = "state" },
    dead = { label = "Dead or ghost", category = "presence", kind = "state" },

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
ns.CONDITION_CATEGORY_ORDER = {
    { id = "presence", label = "Presence" },
    { id = "target", label = "Target" },
    { id = "travel", label = "Travel" },
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
    pendingRestore = setmetatable({}, { __mode = "k" }),
    pendingRelease = setmetatable({}, { __mode = "k" }),
    normalized = setmetatable({}, { __mode = "k" }),
    managedIDByFrame = setmetatable({}, { __mode = "k" }),
    managedAlphaHooks = setmetatable({}, { __mode = "k" }),
    managedAlphaGuard = setmetatable({}, { __mode = "k" }),
    immediateApply = {},
    cinematicBlackout = setmetatable({}, { __mode = "k" }),
    cinematicBlackoutHooks = setmetatable({}, { __mode = "k" }),
    cinematicAlphaGuard = setmetatable({}, { __mode = "k" }),
    cinematicExemptFrames = setmetatable({}, { __mode = "k" }),
    cinematicRootScanAt = 0,
    lastTick = 0,
    lastMouseTick = 0,
    lastCDMRefresh = 0,
}
ns.runtime = runtime

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
    db.profiles[db.profile] = db.profiles[db.profile] or { targets = {}, groups = {}, links = {}, nextReactionID = 1, nextGroupID = 1 }
    local profile = db.profiles[db.profile]
    profile.targets = type(profile.targets) == "table" and profile.targets or {}
    profile.groups = type(profile.groups) == "table" and profile.groups or {}
    profile.links = type(profile.links) == "table" and profile.links or {}
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
        end
    end
    if oldVersion < 2 then
        for _, profile in pairs(db.profiles or {}) do
            profile.targets = type(profile.targets) == "table" and profile.targets or {}
            profile.groups = type(profile.groups) == "table" and profile.groups or {}
            profile.links = type(profile.links) == "table" and profile.links or {}
            local nextID, nextGroupID = tonumber(profile.nextReactionID) or 1, tonumber(profile.nextGroupID) or 1
            for _, settings in pairs(profile.targets) do
                local reactions = type(settings) == "table" and settings.reactions or {}
                if type(settings) == "table" then settings.reactions = reactions end
                for _, reaction in ipairs(reactions) do
                    if type(reaction) == "table" then
                        reaction.condition = aliases[reaction.condition] or reaction.condition
                        if type(reaction.id) ~= "number" then reaction.id, nextID = nextID, nextID + 1 end
                    end
                end
            end
            for key, group in pairs(profile.groups) do
                if type(group) ~= "table" or type(group.members) ~= "table" then
                    profile.groups[key] = nil
                else
                    local count = 0
                    for memberID, enabled in pairs(group.members) do
                        if enabled ~= true or type(memberID) ~= "string" then group.members[memberID] = nil else count = count + 1 end
                    end
                    if count < 2 then profile.groups[key] = nil end
                end
                nextGroupID = nextGroupID + 1
            end
            profile.nextReactionID, profile.nextGroupID = nextID, nextGroupID
        end
    end
    if oldVersion < 3 then
        for _, profile in pairs(db.profiles or {}) do
            for _, settings in pairs(type(profile.targets) == "table" and profile.targets or {}) do
                for _, reaction in ipairs(type(settings) == "table" and settings.reactions or {}) do
                    if type(reaction) == "table" then
                        local requirements, seen = {}, {}
                        for _, condition in ipairs(type(reaction.requirements) == "table" and reaction.requirements or {}) do
                            if type(condition) == "string" and condition ~= reaction.condition and not seen[condition] then
                                requirements[#requirements + 1], seen[condition] = condition, true
                            end
                        end
                        reaction.requirements = requirements
                    end
                end
            end
        end
    end
    if oldVersion < 4 then
        -- This v1.1 target was an invisible 1x1 Resource Bars anchor.  It
        -- cannot provide a useful hover region and would compound child alpha.
        for _, profile in pairs(db.profiles or {}) do
            if type(profile.targets) == "table" then profile.targets.eui_resources = nil end
            if type(profile.groups) == "table" then
                for key, group in pairs(profile.groups) do
                    if type(group) ~= "table" or type(group.members) ~= "table" then
                        profile.groups[key] = nil
                    else
                        group.members.eui_resources = nil
                        local count = 0
                        for memberID, enabled in pairs(group.members) do
                            if enabled == true and type(memberID) == "string" then count = count + 1 else group.members[memberID] = nil end
                        end
                        if count < 2 then profile.groups[key] = nil end
                    end
                end
            end
            if type(profile.links) == "table" then
                profile.links.eui_resources = nil
                for parentID, children in pairs(profile.links) do
                    if type(children) ~= "table" then
                        profile.links[parentID] = nil
                    else
                        children.eui_resources = nil
                        if not next(children) then profile.links[parentID] = nil end
                    end
                end
            end
        end
    end
    if oldVersion < 5 then
        db.cinematic = type(db.cinematic) == "table" and db.cinematic or {}
    end
    if oldVersion < 6 then
        -- v1.9 temporarily exposed CDM adapters through a source-level EUI
        -- bridge. Remove every saved reference now that CDM is deliberately
        -- outside Priority Fader's standalone compatibility contract.
        for _, profile in pairs(db.profiles or {}) do
            local retired = {}
            for id in pairs(type(profile.targets) == "table" and profile.targets or {}) do
                if type(id) == "string" and id:match("^eui_cdm_") then retired[#retired + 1] = id end
            end
            for _, id in ipairs(retired) do
                profile.targets[id] = nil
                for groupID, group in pairs(type(profile.groups) == "table" and profile.groups or {}) do
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
                if type(profile.links) == "table" then
                    profile.links[id] = nil
                    for parentID, children in pairs(profile.links) do
                        if type(children) ~= "table" then
                            profile.links[parentID] = nil
                        else
                            children[id] = nil
                            if not next(children) then profile.links[parentID] = nil end
                        end
                    end
                end
            end
        end
    end
    if oldVersion < 7 then
        db.customTargets = type(db.customTargets) == "table" and db.customTargets or {}
        -- Anonymous frame-picker targets intentionally last only for the UI
        -- session in which they were chosen. They cannot resolve safely after
        -- reload, so discard their saved rule graph instead of leaving ghosts.
        for _, profile in pairs(db.profiles or {}) do
            local retired = {}
            for id in pairs(type(profile.targets) == "table" and profile.targets or {}) do
                if type(id) == "string" and id:match("^session_frame_") then retired[#retired + 1] = id end
            end
            for _, id in ipairs(retired) do
                profile.targets[id] = nil
                for groupID, group in pairs(type(profile.groups) == "table" and profile.groups or {}) do
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
                if type(profile.links) == "table" then
                    profile.links[id] = nil
                    for parentID, children in pairs(profile.links) do
                        if type(children) ~= "table" then profile.links[parentID] = nil
                        else children[id] = nil; if not next(children) then profile.links[parentID] = nil end end
                    end
                end
            end
        end
    end
    if oldVersion < 8 then
        -- Cinematic Mode is a screen-clearing scene. Chat, objectives, and the
        -- action bar now fall under its blackout layer rather than being quiet
        -- default scene components. Keep only the requested essentials.
        for _, profile in pairs(db.profiles or {}) do
            if type(profile) == "table" and profile.cinematicSystem then
                RemoveProfileTargets(profile, function(id)
                    return id == "chat" or id == "objectives" or id == "eui_main"
                end)
            end
        end
    end
    -- Session-only roots cannot survive a reload. Do this every login rather
    -- than only during the schema migration that introduced them.
    for _, profile in pairs(db.profiles or {}) do
        RemoveProfileTargets(profile, function(id) return type(id) == "string" and id:match("^session_frame_") end)
    end
    db.version = 8
end

local CINEMATIC_PROFILE_LABEL = "Cinematic Mode"
local CINEMATIC_TEMPLATE_VERSION = 3
local CINEMATIC_COMPONENTS = {
    { id = "eui_player", label = "Player frame", default = "context_hover", rest = 0 },
    { id = "eui_target", label = "Target frame", default = "context_hover", rest = 0 },
    { id = "minimap", label = "Minimap", default = "hover", rest = 0 },
}
ns.CINEMATIC_COMPONENTS = CINEMATIC_COMPONENTS

local CINEMATIC_MODE_CONDITIONS = {
    context_hover = { "alt", "mouseover", "combat", "target_any" },
    target_hover = { "alt", "mouseover", "target_any" },
    combat_hover = { "alt", "mouseover", "combat" },
    combat = { "alt", "combat" },
    hover = { "alt", "mouseover" },
    quest_hover = { "alt", "mouseover", "quest_update", "quest_accepted", "quest_turned_in", "quest_objective" },
    loot_hover = { "alt", "mouseover", "loot", "loot_opened" },
}
ns.CINEMATIC_MODE_LABELS = {
    untouched = "Untouched",
    context_hover = "Combat, target + hover",
    target_hover = "Target + hover",
    combat_hover = "Combat + hover",
    combat = "Combat only",
    hover = "Hover only",
    quest_hover = "Quest + hover",
    loot_hover = "Loot + hover",
    custom = "Custom rules",
}

local function NewCinematicSettings(profile, mode, rest)
    local conditions = CINEMATIC_MODE_CONDITIONS[mode]
    if not conditions then return nil end
    local settings = { enabled = true, atRest = rest or 0.05, fadeDuration = 0.25, fadeDelay = 0.35, reactions = {}, cinematicMode = mode }
    for _, condition in ipairs(conditions) do
        settings.reactions[#settings.reactions + 1] = { id = profile.nextReactionID, condition = condition, opacity = 1 }
        profile.nextReactionID = profile.nextReactionID + 1
    end
    return settings
end

local function CinematicSettingsMatch(settings, mode, rest)
    local conditions = CINEMATIC_MODE_CONDITIONS[mode]
    if type(settings) ~= "table" or not conditions
        or math.abs((settings.atRest or 0) - rest) > 0.0001
        or math.abs((settings.fadeDuration or 0) - 0.25) > 0.0001
        or math.abs((settings.fadeDelay or 0) - 0.35) > 0.0001
        or type(settings.reactions) ~= "table" or #settings.reactions ~= #conditions then return false end
    for index, condition in ipairs(conditions) do
        local reaction = settings.reactions[index]
        if not reaction or reaction.condition ~= condition or reaction.opacity ~= 1 or #(reaction.requirements or {}) > 0 then return false end
        local info = CONDITION_INFO[condition]
        if info and info.kind == "moment" and math.abs((reaction.duration or info.duration or 3) - (info.duration or 3)) > 0.0001 then return false end
    end
    return true
end

function ns:GetCinematicProfileName()
    local cinematic = PriorityFaderDB and PriorityFaderDB.cinematic
    return cinematic and cinematic.profileName
end

function ns:IsCinematicProfileName(name)
    return type(name) == "string" and name == self:GetCinematicProfileName()
end

function ns:EnsureCinematicProfile()
    local db = PriorityFaderDB
    db.cinematic = type(db.cinematic) == "table" and db.cinematic or {}
    local cinematic = db.cinematic
    cinematic.actions = type(cinematic.actions) == "table" and cinematic.actions or {}
    cinematic.templateVersion = tonumber(cinematic.templateVersion) or 1
    local profileName = cinematic.profileName
    local created = false
    if type(profileName) ~= "string" or not db.profiles[profileName] or not db.profiles[profileName].cinematicSystem then
        profileName = CINEMATIC_PROFILE_LABEL
        local suffix = 2
        while db.profiles[profileName] and not db.profiles[profileName].cinematicSystem do
            profileName = CINEMATIC_PROFILE_LABEL .. " " .. suffix
            suffix = suffix + 1
        end
        cinematic.profileName = profileName
        db.profiles[profileName] = db.profiles[profileName] or { targets = {}, groups = {}, links = {}, nextReactionID = 1, nextGroupID = 1 }
        local profile = db.profiles[profileName]
        created = true
        profile.cinematicSystem = true
        profile.targets, profile.groups, profile.links = {}, {}, {}
        profile.nextReactionID, profile.nextGroupID = 1, 1
        for _, component in ipairs(CINEMATIC_COMPONENTS) do
            profile.targets[component.id] = NewCinematicSettings(profile, component.default, component.rest)
        end
    end
    local profile = db.profiles[cinematic.profileName]
    if type(profile) == "table" then
        profile.nextReactionID = tonumber(profile.nextReactionID) or 1
        profile.nextGroupID = tonumber(profile.nextGroupID) or 1
    end
    if not created and cinematic.templateVersion < CINEMATIC_TEMPLATE_VERSION and type(profile) == "table" then
        profile.targets = type(profile.targets) == "table" and profile.targets or {}
        -- Upgrade only untouched v1 defaults. Advanced edits remain exactly as
        -- the user made them and simply show as Custom in the dedicated page.
        if CinematicSettingsMatch(profile.targets.eui_player, "combat_hover", 0.05) then
            profile.targets.eui_player = NewCinematicSettings(profile, "target_hover", 0)
        end
        if CinematicSettingsMatch(profile.targets.eui_target, "combat_hover", 0.05) then
            profile.targets.eui_target = NewCinematicSettings(profile, "target_hover", 0)
        end
        if CinematicSettingsMatch(profile.targets.minimap, "hover", 0.05) then
            profile.targets.minimap = NewCinematicSettings(profile, "hover", 0)
        end
        if CinematicSettingsMatch(profile.targets.eui_player, "target_hover", 0) then
            profile.targets.eui_player = NewCinematicSettings(profile, "context_hover", 0)
        end
        if CinematicSettingsMatch(profile.targets.eui_target, "target_hover", 0) then
            profile.targets.eui_target = NewCinematicSettings(profile, "context_hover", 0)
        end
    end
    cinematic.templateVersion = CINEMATIC_TEMPLATE_VERSION
    return cinematic.profileName, db.profiles[cinematic.profileName]
end

function ns:GetCinematicProfile()
    local _, profile = self:EnsureCinematicProfile()
    return profile
end

function ns:IsCinematicActive()
    return PriorityFaderDB and PriorityFaderDB.profile == self:GetCinematicProfileName()
end

local CINEMATIC_LOCKED_NAMES = {
    NamePlateDriverFrame = true,
    LootFrame = true,
    GroupLootContainer = true,
    LootHistoryFrame = true,
    SpeedyAutoLoot_LootDisplayAnchor = true,
    DUIQuestFrame = true,
    QuestFrame = true,
    GossipFrame = true,
    GameTooltip = true,
    ItemRefTooltip = true,
    StaticPopup1 = true,
    StaticPopup2 = true,
    StaticPopup3 = true,
    StaticPopup4 = true,
    GameMenuFrame = true,
    SettingsPanel = true,
}

local CINEMATIC_UI_MODE = "PriorityFader.Cinematic"
local CINEMATIC_UI_ROLES = {
    "actionBars",
    "arenaFrames",
    "buffs",
    "chat",
    "cooldownViewers",
    "encounterUI",
    "extraAbilities",
    "microMenu",
    "objectives",
    "pvp",
    "statusBars",
    "widgets",
}

function ns:RegisterCinematicUIMode()
    if runtime.cinematicUIModeRegistered then return true end
    if not UIModeUtil or type(UIModeUtil.RegisterMode) ~= "function" or type(UIModeUtil.SetModeActive) ~= "function" then
        runtime.cinematicUIModeAvailable = false
        return true
    end
    local ok = pcall(UIModeUtil.RegisterMode, CINEMATIC_UI_MODE, { rolesetBlocklist = CINEMATIC_UI_ROLES })
    if not ok then return false, "WoW's native UI scene could not be prepared." end
    runtime.cinematicUIModeRegistered = true
    runtime.cinematicUIModeAvailable = true
    return true
end

function ns:SetCinematicUIMode(active)
    if InCombatLockdown() then return false, "Toggle Cinematic Mode outside combat." end
    local ok, reason = self:RegisterCinematicUIMode()
    if not ok then return false, reason end
    if not runtime.cinematicUIModeAvailable then return true end
    if runtime.cinematicUIModeActive == (active == true) then return true end
    local changed = pcall(UIModeUtil.SetModeActive, CINEMATIC_UI_MODE, active == true)
    if not changed then return false, "WoW could not change the native UI scene." end
    runtime.cinematicUIModeActive = active == true
    return true
end

local function SafeFrameName(frame)
    if not frame then return nil end
    local ok, name = pcall(function() return frame:GetName() end)
    return ok and not IsSecret(name) and type(name) == "string" and name or nil
end

local function SafeFrameMarker(frame, key)
    if not frame then return nil end
    local ok, marker = pcall(function() return frame[key] end)
    return ok and not IsSecret(marker) and marker or nil
end

local function IsCinematicNameplateFrame(frame, name)
    if not frame then return false end
    if type(name) == "string" and name:match("^NamePlate") then return true end
    -- Ellesmere's enemy and friendly nameplates are anonymous pooled
    -- UIParent roots. Once initialized they retain this exact mixin contract
    -- even while pooled/hidden, allowing Cinematic to pre-exempt them before
    -- an enemy appears without reading or changing Ellesmere's settings.
    local mixed = SafeFrameMarker(frame, "_mixedIn") == true
    local setUnit = SafeFrameMarker(frame, "SetUnit")
    local clearUnit = SafeFrameMarker(frame, "ClearUnit")
    local health = SafeFrameMarker(frame, "health")
    return mixed and type(setUnit) == "function" and type(clearUnit) == "function" and health ~= nil
end

function ns:RefreshCinematicExemptions()
    local frames = setmetatable({}, { __mode = "k" })
    local profile = self:GetCinematicProfile()
    for id in pairs(profile.targets or {}) do
        local frame = self:ResolveTarget(id)
        local visual = frame
        local okVisual, resolvedVisual = pcall(function()
            return frame and type(frame.GetPriorityFaderVisualFrame) == "function" and frame:GetPriorityFaderVisualFrame() or nil
        end)
        if okVisual and resolvedVisual then visual = resolvedVisual end
        local boundary = frame and self.GetEUIUnitFrameBoundary and self:GetEUIUnitFrameBoundary(frame)
        local root = visual and self:GetFramePickerRoot(visual)
        if boundary then
            local owner = self.GetEUIUnitFrameOwner and self:GetEUIUnitFrameOwner(frame) or frame
            -- The EUI hider is only a secure structural switch. Keep it alive,
            -- exempt the exact rule-owned unit button, and lease its unwanted
            -- siblings independently in BeginCinematicBlackout.
            frames[boundary], frames[owner], frames[visual] = true, true, true
        elseif root then
            frames[root] = true
        end
    end
    for frame in pairs(runtime.cinematicKeepFrames or {}) do
        local boundary = self.GetEUIUnitFrameBoundary and self:GetEUIUnitFrameBoundary(frame)
        if boundary then
            local owner = self.GetEUIUnitFrameOwner and self:GetEUIUnitFrameOwner(frame) or frame
            frames[boundary], frames[owner], frames[frame] = true, true, true
        else
            local root = self:GetFramePickerRoot(frame)
            if root then frames[root] = true end
        end
    end
    local keepNames = PriorityFaderDB and PriorityFaderDB.cinematic and PriorityFaderDB.cinematic.keepNames
    for name, keep in pairs(type(keepNames) == "table" and keepNames or {}) do
        local frame = keep == true and type(name) == "string" and _G[name] or nil
        local boundary = frame and self.GetEUIUnitFrameBoundary and self:GetEUIUnitFrameBoundary(frame)
        if boundary then
            local owner = self.GetEUIUnitFrameOwner and self:GetEUIUnitFrameOwner(frame) or frame
            frames[boundary], frames[owner], frames[frame] = true, true, true
        end
    end
    runtime.cinematicExemptFrames = frames
    if self.RefreshOPieFrames then self:RefreshOPieFrames() end
end

function ns:IsCinematicBlackoutExempt(root)
    if not root or root == UIParent or root == WorldFrame or self:IsPriorityFaderFrame(root) then return true end
    local name = SafeFrameName(root)
    if name and CINEMATIC_LOCKED_NAMES[name] then return true end
    if IsCinematicNameplateFrame(root, name) then return true end
    if self.IsOPieSceneFrame and self:IsOPieSceneFrame(root) then return true end
    if self.IsLootSceneFrame and self:IsLootSceneFrame(root) then return true end
    if self.IsMinimapStackFrame and self:IsMinimapStackFrame(root) then return true end
    if SafeFrameMarker(root, "LIKE_GLOBAL_GAMETOOLTIP") == true then return true end
    if runtime.cinematicExemptFrames and runtime.cinematicExemptFrames[root] then return true end
    local keepNames = PriorityFaderDB and PriorityFaderDB.cinematic and PriorityFaderDB.cinematic.keepNames
    if name and type(keepNames) == "table" and keepNames[name] == true then return true end
    return runtime.cinematicKeepFrames and runtime.cinematicKeepFrames[root] == true or false
end

function ns:KeepCinematicFrame(frame)
    local visual = frame
    local okVisual, resolvedVisual = pcall(function()
        return frame and type(frame.GetPriorityFaderVisualFrame) == "function" and frame:GetPriorityFaderVisualFrame() or nil
    end)
    if okVisual and resolvedVisual then visual = resolvedVisual end
    local root = self:GetFramePickerRoot(visual)
    if not root then return false, "That frame cannot be kept safely." end
    local owner = self.GetEUIUnitFrameOwner and self:GetEUIUnitFrameOwner(frame)
    local managed = owner or root
    local name = SafeFrameName(managed)
    if name then
        PriorityFaderDB.cinematic.keepNames = type(PriorityFaderDB.cinematic.keepNames) == "table" and PriorityFaderDB.cinematic.keepNames or {}
        PriorityFaderDB.cinematic.keepNames[name] = true
    else
        runtime.cinematicKeepFrames = runtime.cinematicKeepFrames or setmetatable({}, { __mode = "k" })
        runtime.cinematicKeepFrames[visual] = true
    end
    self:RefreshCinematicExemptions()
    if self:IsCinematicActive() and not InCombatLockdown() then self:SetCinematicUIMode(false) end
    self:UpdateCinematicBlackout()
    return true, name and "This UI root will stay visible in Cinematic Mode." or "This unnamed UI root will stay visible until you reload."
end

function ns:ClearCinematicKeeps()
    if not PriorityFaderDB or not PriorityFaderDB.cinematic then return end
    PriorityFaderDB.cinematic.keepNames = {}
    runtime.cinematicKeepFrames = setmetatable({}, { __mode = "k" })
    self:RefreshCinematicExemptions()
    self:BeginCinematicBlackout()
end

function ns:GetCinematicKeepCount()
    local count = 0
    for _ in pairs(PriorityFaderDB and PriorityFaderDB.cinematic and PriorityFaderDB.cinematic.keepNames or {}) do count = count + 1 end
    for _ in pairs(runtime.cinematicKeepFrames or {}) do count = count + 1 end
    return count
end

function ns:CanUseCinematicNativeMode()
    if self:GetCinematicKeepCount() > 0 then return false end
    local allowed = { eui_player = true, eui_target = true, minimap = true }
    local profile = self:GetCinematicProfile()
    for id in pairs(profile.targets or {}) do if not allowed[id] then return false end end
    return true
end

local function SetCinematicFrameAlpha(frame, alpha)
    runtime.cinematicAlphaGuard[frame] = true
    local ok = SafeSetFrameAlpha(frame, alpha)
    runtime.cinematicAlphaGuard[frame] = nil
    return ok
end

local function CinematicHostAlphaChanged(frame, alpha)
    if runtime.cinematicAlphaGuard[frame] or not ns:IsCinematicActive() then return end
    local record = runtime.cinematicBlackout[frame]
    if not record then return end
    if IsSecret(alpha) or type(alpha) ~= "number" then
        local reveal = runtime.cinematicPickerReveal or (IsAltKeyDown and IsAltKeyDown()) or false
        if not reveal and not ns:IsCinematicBlackoutExempt(frame) and SetCinematicFrameAlpha(frame, 0) then
            record.appliedAlpha = 0
        end
        return
    end
    record.baseAlpha = alpha
    record.appliedAlpha = alpha
    local reveal = runtime.cinematicPickerReveal or (IsAltKeyDown and IsAltKeyDown()) or false
    if not reveal and not ns:IsCinematicBlackoutExempt(frame) and SetCinematicFrameAlpha(frame, 0) then
        record.appliedAlpha = 0
    end
end

local function CinematicRootShown(frame)
    if not ns:IsCinematicActive() then return end
    local record = runtime.cinematicBlackout[frame]
    if record and not ns:IsCinematicBlackoutExempt(frame)
        and not runtime.cinematicPickerReveal and not (IsAltKeyDown and IsAltKeyDown()) then
        if SetCinematicFrameAlpha(frame, 0) then record.appliedAlpha = 0 end
    end
end

function ns:HookCinematicRoot(root)
    if not root then return end
    local state = runtime.cinematicBlackoutHooks[root]
    if type(state) ~= "table" then state = {}; runtime.cinematicBlackoutHooks[root] = state end
    local methodOK, hookScript = pcall(function() return root.HookScript end)
    if not state.onShow and methodOK and type(hookScript) == "function" then
        state.onShow = pcall(hookScript, root, "OnShow", CinematicRootShown) == true
    end
    if not state.alpha and type(hooksecurefunc) == "function" then
        state.alpha = pcall(hooksecurefunc, root, "SetAlpha", CinematicHostAlphaChanged) == true
    end
end

local function LeaseCinematicFrame(self, frame)
    if not frame or self:IsCinematicBlackoutExempt(frame) then return false end
    local alpha = SafeFrameAlpha(frame)
    if alpha == nil then return false end
    local record = runtime.cinematicBlackout[frame]
    if not record then
        record = { baseAlpha = alpha, appliedAlpha = alpha }
        runtime.cinematicBlackout[frame] = record
    end
    self:HookCinematicRoot(frame)
    return true
end

function ns:BeginCinematicBlackout()
    if not self:IsCinematicActive() or not self.GetUIParentFrameRoots then return false end
    if InCombatLockdown() then runtime.cinematicScanPending = true; return false, "Cinematic blackout will scan when combat ends." end
    runtime.cinematicScanPending = nil
    self:RefreshCinematicExemptions()
    local count = 0
    for _, root in ipairs(self:GetUIParentFrameRoots(true)) do
        if LeaseCinematicFrame(self, root) then count = count + 1 end
    end
    -- Shared structural roots (currently Ellesmere's secure unit hider) stay
    -- visible for exact exceptions; their non-exempt child branches still join
    -- the same alpha-only ledger and restoration lifecycle.
    if self.GetCinematicNestedBlackoutFrames then
        for _, frame in ipairs(self:GetCinematicNestedBlackoutFrames()) do
            if LeaseCinematicFrame(self, frame) then count = count + 1 end
        end
    end
    runtime.cinematicBlackoutCount = count
    runtime.cinematicRootScanAt = GetTime()
    self:UpdateCinematicBlackout()
    return true, count
end

function ns:UpdateCinematicBlackout()
    if not self:IsCinematicActive() then return end
    local reveal = runtime.cinematicPickerReveal or (IsAltKeyDown and IsAltKeyDown()) or false
    local count = 0
    for root, record in pairs(runtime.cinematicBlackout) do
        if self:IsCinematicBlackoutExempt(root) then
            local current = SafeFrameAlpha(root)
            if current == nil then
                runtime.pendingRestore[root] = record.baseAlpha
            elseif math.abs(current - (record.appliedAlpha or current)) < 0.01
                and not SetCinematicFrameAlpha(root, record.baseAlpha) then
                runtime.pendingRestore[root] = record.baseAlpha
            end
            runtime.cinematicBlackout[root] = nil
        else
            local current = SafeFrameAlpha(root)
            if current == nil then
                -- Secret or temporarily unreadable alpha is not an ownership
                -- release. Reassert blackout without comparing the secret
                -- value; pcall fails closed if the protected frame rejects it.
                if not reveal and SetCinematicFrameAlpha(root, 0) then record.appliedAlpha = 0 end
                count = count + 1
            else
                if math.abs(current - (record.appliedAlpha or current)) > 0.01 then record.baseAlpha = current end
                local desired = reveal and record.baseAlpha or 0
                if math.abs(current - desired) > 0.001 and SetCinematicFrameAlpha(root, desired) then record.appliedAlpha = desired end
                count = count + 1
            end
        end
    end
    runtime.cinematicBlackoutCount = count
end

function ns:ReconcileCinematicOwnership()
    if not self:IsCinematicActive() then return end
    self:RefreshCinematicExemptions()
    -- Release anything that just became an explicit rule-owned exception,
    -- then update the native role layer and acquire newly unowned branches in
    -- the same synchronous editor mutation.
    self:UpdateCinematicBlackout()
    if InCombatLockdown() then
        runtime.cinematicScanPending = true
        return
    end
    self:SetCinematicUIMode(self:CanUseCinematicNativeMode())
    self:BeginCinematicBlackout()
end

function ns:EndCinematicBlackout()
    for root, record in pairs(runtime.cinematicBlackout) do
        local current = SafeFrameAlpha(root)
        runtime.cinematicBlackout[root] = nil
        if current ~= nil and math.abs(current - (record.appliedAlpha or current)) < 0.01 then
            if not SetCinematicFrameAlpha(root, record.baseAlpha) then runtime.pendingRestore[root] = record.baseAlpha end
        elseif current == nil then
            runtime.pendingRestore[root] = record.baseAlpha
        end
    end
    runtime.cinematicBlackoutCount = 0
    runtime.cinematicRootScanAt = 0
end

function ns:GetCinematicComponentMode(id)
    local settings = self:GetCinematicProfile().targets[id]
    if not settings then return "untouched" end
    local component
    for _, candidate in ipairs(CINEMATIC_COMPONENTS) do if candidate.id == id then component = candidate; break end end
    if not component or math.abs((settings.atRest or 0) - component.rest) > 0.0001
        or math.abs((settings.fadeDuration or 0) - 0.25) > 0.0001
        or math.abs((settings.fadeDelay or 0) - 0.35) > 0.0001 then return "custom" end
    local conditions = CINEMATIC_MODE_CONDITIONS[settings.cinematicMode]
    if not conditions or type(settings.reactions) ~= "table" or #settings.reactions ~= #conditions then return "custom" end
    for index, condition in ipairs(conditions) do
        local reaction = settings.reactions[index]
        if not reaction or reaction.condition ~= condition or reaction.opacity ~= 1 or #(reaction.requirements or {}) > 0 then return "custom" end
        local info = CONDITION_INFO[condition]
        if info and info.kind == "moment" and math.abs((reaction.duration or info.duration or 3) - (info.duration or 3)) > 0.0001 then return "custom" end
    end
    return settings.cinematicMode
end

function ns:SetCinematicComponentMode(id, mode)
    local profile = self:GetCinematicProfile()
    local component
    for _, candidate in ipairs(CINEMATIC_COMPONENTS) do if candidate.id == id then component = candidate; break end end
    if not component then return false, "That Cinematic component is not supported." end
    if mode == "untouched" then
        if self:IsCinematicActive() then self:RemoveTarget(id) else profile.targets[id] = nil end
    elseif CINEMATIC_MODE_CONDITIONS[mode] then
        profile.targets[id] = NewCinematicSettings(profile, mode, component.rest)
    else
        return false, "Choose one of the available modes."
    end
    if self:IsCinematicActive() then
        if self.PrimeCinematicTargets then self:PrimeCinematicTargets() end
        self:BeginCinematicBlackout()
    end
    self:Wake()
    self:RefreshOptions()
    return true
end

function ns:ResetCinematicProfile()
    local profile = self:GetCinematicProfile()
    if self:IsCinematicActive() then
        local ids = {}
        for id in pairs(runtime.frameByID) do ids[#ids + 1] = id end
        for _, id in ipairs(ids) do self:RestoreControlledFrame(id) end
        for id in pairs(runtime.active) do runtime.active[id] = nil end
        for id in pairs(runtime.hovered) do runtime.hovered[id] = nil end
        for id in pairs(runtime.fadeOutStarted) do runtime.fadeOutStarted[id] = nil end
    end
    profile.targets, profile.groups, profile.links = {}, {}, {}
    profile.nextReactionID, profile.nextGroupID = 1, 1
    for _, component in ipairs(CINEMATIC_COMPONENTS) do
        profile.targets[component.id] = NewCinematicSettings(profile, component.default, component.rest)
    end
    if self:IsCinematicActive() then
        if self.PrimeCinematicTargets then self:PrimeCinematicTargets() end
        self:BeginCinematicBlackout()
    end
    self:Wake()
    self:RefreshOptions()
end

function ns:ToggleCinematic()
    if InCombatLockdown() then return false, "Toggle Cinematic Mode outside combat.", self:IsCinematicActive() end
    local cinematicName = self:EnsureCinematicProfile()
    local db = PriorityFaderDB
    if db.profile == cinematicName then
        local returnProfile = db.cinematic.returnProfile
        if type(returnProfile) ~= "string" or not db.profiles[returnProfile] or returnProfile == cinematicName then returnProfile = "Default" end
        local ok, reason = self:SelectProfile(returnProfile, true)
        if ok then db.cinematic.returnProfile = nil end
        return ok, reason, false
    end
    db.cinematic.returnProfile = db.profile
    local ok, reason = self:SelectProfile(cinematicName, true)
    if ok then
        if self.PrimeCinematicTargets then self:PrimeCinematicTargets() end
        local modeOK, modeReason = self:SetCinematicUIMode(self:CanUseCinematicNativeMode())
        if not modeOK then
            self:SelectProfile(db.cinematic.returnProfile or "Default", true)
            db.cinematic.returnProfile = nil
            return false, modeReason, false
        end
        local scanned, scanReason = self:BeginCinematicBlackout()
        if not scanned and scanReason then reason = scanReason end
    end
    return ok, reason, true
end

function ns:GetCinematicBinding()
    local primary = GetBindingKey and GetBindingKey("PRIORITYFADER_TOGGLE_CINEMATIC")
    return primary
end

function ns:SetCinematicBinding(key)
    if InCombatLockdown() then return false, "Change shortcuts outside combat." end
    if not SetBinding or not SaveBindings then return false, "WoW key binding controls are unavailable." end
    local oldPrimary, oldSecondary = GetBindingKey("PRIORITYFADER_TOGGLE_CINEMATIC")
    local replacedAction = key and GetBindingAction and GetBindingAction(key)
    if key and SetBinding(key, "PRIORITYFADER_TOGGLE_CINEMATIC") == false then return false, "WoW rejected that shortcut." end
    if oldPrimary and oldPrimary ~= key then SetBinding(oldPrimary, nil) end
    if oldSecondary and oldSecondary ~= key then SetBinding(oldSecondary, nil) end
    local bindingSet = (GetCurrentBindingSet and GetCurrentBindingSet()) or 1
    if SaveBindings(bindingSet) == false then
        if key then SetBinding(key, replacedAction and replacedAction ~= "" and replacedAction or nil) end
        if oldPrimary then SetBinding(oldPrimary, "PRIORITYFADER_TOGGLE_CINEMATIC") end
        if oldSecondary then SetBinding(oldSecondary, "PRIORITYFADER_TOGGLE_CINEMATIC") end
        SaveBindings(bindingSet)
        return false, "WoW could not save that shortcut; the previous binding was restored."
    end
    return true
end

function ns:GetTargetSettings(id, create)
    local profile = self:Profile()
    local settings = profile.targets[id]
    if not settings and create then
        settings = {
            enabled = true,
            atRest = 0.12,
            fadeDuration = 0.20,
            fadeDelay = 0.80,
            reactions = CopyDefaults(DEFAULT_REACTIONS),
        }
        profile.targets[id] = settings
    end
    if settings then
        -- Saved variables outlive versions.  Keep a partial or older record
        -- harmless instead of letting the update loop index nil values.
        settings.enabled = settings.enabled ~= false
        settings.atRest = tonumber(settings.atRest) or 0.12
        settings.fadeDuration = math.max(0.05, math.min(2, tonumber(settings.fadeDuration) or 0.20))
        settings.fadeDelay = math.max(0, math.min(5, tonumber(settings.fadeDelay) or 0.80))
        settings.reactions = type(settings.reactions) == "table" and settings.reactions or {}
        if not runtime.normalized[settings] then
            local valid = {}
            for _, reaction in ipairs(settings.reactions) do
                if type(reaction) == "table" and type(reaction.condition) == "string" then
                    if type(reaction.id) ~= "number" then reaction.id = self:NextReactionID() end
                    reaction.opacity = math.max(0, math.min(1, tonumber(reaction.opacity) or 1))
                    local info = CONDITION_INFO[reaction.condition]
                    if info and info.kind == "moment" then
                        local duration = math.max(0.5, math.min(30, tonumber(reaction.duration) or info.duration or 3))
                        reaction.duration = math.floor(duration * 4 + 0.5) / 4
                    else
                        reaction.duration = nil
                    end
                    local requirements, seen = {}, {}
                    for _, condition in ipairs(type(reaction.requirements) == "table" and reaction.requirements or {}) do
                        if type(condition) == "string" and condition ~= reaction.condition and not seen[condition] then
                            requirements[#requirements + 1], seen[condition] = condition, true
                        end
                    end
                    reaction.requirements = requirements
                    valid[#valid + 1] = reaction
                end
            end
            settings.reactions = valid
            runtime.normalized[settings] = true
        end
    end
    return settings
end

function ns:AddTarget(id)
    local previous = self:GetTargetSettings(id)
    local ownershipChanged = not previous or previous.enabled == false
    local settings = self:GetTargetSettings(id, true)
    settings.enabled = true
    if ownershipChanged and self.ReconcileCinematicOwnership then self:ReconcileCinematicOwnership() end
    self:Wake()
    self:RefreshOptions()
    return settings
end

function ns:RestoreControlledFrame(id)
    local frame = runtime.frameByID[id]
    if not frame then return end
    local target = self.TargetByID[id]
    local alpha = runtime.baseAlpha[frame]
    runtime.managedIDByFrame[frame] = nil
    runtime.managedAlphaGuard[frame] = true
    local restored = alpha == nil or SafeSetFrameAlpha(frame, alpha)
    runtime.managedAlphaGuard[frame] = nil
    if alpha ~= nil and not restored then
        runtime.pendingRestore[frame] = alpha
        if target and target.release then runtime.pendingRelease[frame] = target.release end
    elseif target and target.release then
        pcall(target.release, frame)
    end
    runtime.baseAlpha[frame] = nil
    runtime.currentAlpha[frame] = nil
    runtime.frameByID[id] = nil
end

function ns:GetProfileNames()
    local db = PriorityFaderDB
    local names = {}
    for name in pairs(db.profiles or {}) do
        if type(name) == "string" and name ~= "" then names[#names + 1] = name end
    end
    table.sort(names, function(a, b)
        if a == "Default" then return true end
        if b == "Default" then return false end
        return a:lower() < b:lower()
    end)
    return names
end

local function NormalizeProfileName(name)
    if type(name) ~= "string" then return nil end
    name = name:match("^%s*(.-)%s*$")
    if name == "" or #name > 24 or not name:match("^[%w][%w %-%_']*$") then return nil end
    return name
end

local function FindProfileName(db, name)
    local wanted = name:lower()
    for existing in pairs(db.profiles or {}) do
        if type(existing) == "string" and existing:lower() == wanted then return existing end
    end
end

function ns:SelectProfile(name, preserveCinematicReturn)
    name = NormalizeProfileName(name)
    local db = PriorityFaderDB
    if not name or not db.profiles or not db.profiles[name] then return false, "That profile does not exist." end
    if db.profile == name then return true end
    if self:IsCinematicActive() then
        local modeOK, modeReason = self:SetCinematicUIMode(false)
        if not modeOK then return false, modeReason end
        self:EndCinematicBlackout()
    end
    local ids = {}
    for id in pairs(runtime.frameByID) do ids[#ids + 1] = id end
    for _, id in ipairs(ids) do self:RestoreControlledFrame(id) end
    for id in pairs(runtime.active) do runtime.active[id] = nil end
    for id in pairs(runtime.hovered) do runtime.hovered[id] = nil end
    for id in pairs(runtime.fadeOutStarted) do runtime.fadeOutStarted[id] = nil end
    for id in pairs(runtime.immediateApply) do runtime.immediateApply[id] = nil end
    db.profile = name
    if not preserveCinematicReturn and db.cinematic and db.cinematic.profileName ~= name then
        db.cinematic.returnProfile = nil
    end
    self:Profile()
    self:EnsureConnectedHoverRules()
    if self.Options then
        self.Options.selected = nil
        self.Options.active:SetText("Profile switched to " .. name)
        self.Options.active:SetTextColor(unpack(self.COLORS.teal))
    end
    self:Wake()
    self:RefreshOptions()
    return true
end

function ns:CreateProfile(name)
    if self:IsCinematicActive() then return false, "Turn off Cinematic Mode before creating a normal profile." end
    name = NormalizeProfileName(name)
    local db = PriorityFaderDB
    if not name then return false, "Use 1-24 letters, numbers, spaces, hyphens, underscores, or apostrophes." end
    if FindProfileName(db, name) then return false, "That profile name is already in use." end
    db.profiles[name] = DeepCopy(self:Profile())
    return self:SelectProfile(name)
end

function ns:DeleteProfile(name)
    name = NormalizeProfileName(name)
    local db = PriorityFaderDB
    if not name or not db.profiles[name] then return false, "That profile does not exist." end
    if name == "Default" then return false, "Default is kept as a safe fallback." end
    if self:IsCinematicProfileName(name) then return false, "Cinematic Mode is managed from its dedicated page." end
    local resetCinematicReturn = db.cinematic and db.cinematic.returnProfile == name
    if db.profile == name then self:SelectProfile("Default") end
    db.profiles[name] = nil
    if resetCinematicReturn then db.cinematic.returnProfile = "Default" end
    self:RefreshOptions()
    return true, resetCinematicReturn and "Profile deleted. Cinematic Mode will return to Default." or "Profile deleted."
end

local function SortedKeys(values)
    local keys = {}
    for key in pairs(values or {}) do if type(key) == "string" then keys[#keys + 1] = key end end
    table.sort(keys)
    return keys
end

local function EncodeField(value)
    return (tostring(value or ""):gsub("([^%w%-%_%.])", function(char)
        return string.format("%%%02X", string.byte(char))
    end))
end

local function DecodeField(value)
    if type(value) ~= "string" then return nil end
    local position = 1
    while true do
        local percent = value:find("%", position, true)
        if not percent then break end
        local hex = value:sub(percent + 1, percent + 2)
        if #hex ~= 2 or not hex:match("^%x%x$") then return nil end
        position = percent + 3
    end
    return (value:gsub("%%(%x%x)", function(hex) return string.char(tonumber(hex, 16)) end))
end

local function SplitFields(line)
    local fields = {}
    for field in (line .. "|"):gmatch("(.-)|") do fields[#fields + 1] = field end
    return fields
end

local function IsSafeImportID(value, limit)
    return type(value) == "string" and value ~= "" and #value <= (limit or 96) and not value:find("[%c]")
end

local function ImportNumber(value, minimum, maximum)
    local number = tonumber(value)
    if not number or number ~= number or number < minimum or number > maximum then return nil end
    return number
end

local function ProfileChecksum(body)
    local checksum = 0
    for index = 1, #body do checksum = (checksum + string.byte(body, index) * index) % 65521 end
    return string.format("%04X", checksum)
end

local function ImportFailure(message)
    return nil, message
end

function ns:ExportProfile(name)
    name = NormalizeProfileName(name or PriorityFaderDB.profile)
    if self:IsCinematicProfileName(name) then return nil, "Turn off Cinematic Mode before exporting a normal profile." end
    local profile = name and PriorityFaderDB.profiles and PriorityFaderDB.profiles[name]
    if not profile then return nil, "That profile does not exist." end
    local lines = { "PF1" }
    for _, targetID in ipairs(SortedKeys(profile.targets)) do
        local settings = profile.targets[targetID]
        if type(settings) == "table" and IsSafeImportID(targetID) then
            -- Disabled targets are not currently a user-facing profile option.
            -- Exporting them as active keeps every successful payload portable.
            local enabled = "1"
            local atRest = math.max(0, math.min(1, tonumber(settings.atRest) or 0.12))
            local fadeDuration = math.max(0.05, math.min(2, tonumber(settings.fadeDuration) or 0.20))
            local fadeDelay = math.max(0, math.min(5, tonumber(settings.fadeDelay) or 0.80))
            lines[#lines + 1] = table.concat({ "T", EncodeField(targetID), enabled, atRest, fadeDuration, fadeDelay }, "|")
            for _, reaction in ipairs(type(settings.reactions) == "table" and settings.reactions or {}) do
                local info = type(reaction) == "table" and CONDITION_INFO[reaction.condition]
                if info and not info.internal and type(reaction.id) == "number" then
                    local requirements = {}
                    for _, requirement in ipairs(type(reaction.requirements) == "table" and reaction.requirements or {}) do
                        local requirementInfo = CONDITION_INFO[requirement]
                        if requirementInfo and not requirementInfo.internal and requirement ~= reaction.condition then requirements[#requirements + 1] = requirement end
                    end
                    local duration = info.kind == "moment" and math.max(0.5, math.min(30, tonumber(reaction.duration) or info.duration or 3)) or ""
                    lines[#lines + 1] = table.concat({ "R", EncodeField(targetID), reaction.id, EncodeField(reaction.condition), math.max(0, math.min(1, tonumber(reaction.opacity) or 1)), duration, EncodeField(table.concat(requirements, ",")) }, "|")
                end
            end
        end
    end
    for _, groupID in ipairs(SortedKeys(profile.groups)) do
        local group = profile.groups[groupID]
        if type(group) == "table" and type(group.members) == "table" and IsSafeImportID(groupID) then
            local members = {}
            for _, memberID in ipairs(SortedKeys(group.members)) do if group.members[memberID] == true and IsSafeImportID(memberID) then members[#members + 1] = EncodeField(memberID) end end
            if #members >= 2 then lines[#lines + 1] = table.concat({ "G", EncodeField(groupID), EncodeField(group.name or "Reveal group"), EncodeField(table.concat(members, ",")) }, "|") end
        end
    end
    for _, parentID in ipairs(SortedKeys(profile.links)) do
        local children = profile.links[parentID]
        if type(children) == "table" and IsSafeImportID(parentID) then
            local childIDs = {}
            for _, childID in ipairs(SortedKeys(children)) do if children[childID] == true and IsSafeImportID(childID) then childIDs[#childIDs + 1] = EncodeField(childID) end end
            if #childIDs > 0 then lines[#lines + 1] = table.concat({ "L", EncodeField(parentID), EncodeField(table.concat(childIDs, ",")) }, "|") end
        end
    end
    local body = table.concat(lines, "\n")
    local export = "PriorityFader-1:" .. ProfileChecksum(body) .. "\n" .. body
    local valid, reason = self:ParseProfileImport(export)
    if not valid then return nil, "This profile cannot be exported: " .. reason end
    return export
end

function ns:ParseProfileImport(text)
    if type(text) ~= "string" or #text > 60000 then return ImportFailure("Paste a Priority Fader export under 60 KB.") end
    text = text:gsub("\r\n", "\n"):gsub("\n+$", "")
    local checksum, body = text:match("^PriorityFader%-1:([0-9A-Fa-f]+)\r?\n([%s%S]+)$")
    if not checksum or not body or checksum:upper() ~= ProfileChecksum(body) then return ImportFailure("That export is incomplete or has been changed.") end
    local lines = {}
    for line in body:gmatch("[^\r\n]+") do lines[#lines + 1] = line end
    if lines[1] ~= "PF1" then return ImportFailure("This is not a Priority Fader profile export.") end
    local profile = { targets = {}, groups = {}, links = {}, nextReactionID = 1, nextGroupID = 1 }
    local reactionIDs, reactionsByTarget, memberToGroup, targetCount, reactionCount, groupCount, edgeCount = {}, {}, {}, 0, 0, 0, 0
    for index = 2, #lines do
        local fields = SplitFields(lines[index])
        local tag = fields[1]
        if tag == "T" and #fields == 6 then
            local id = DecodeField(fields[2])
            local atRest = ImportNumber(fields[4], 0, 1)
            local fadeDuration = ImportNumber(fields[5], 0.05, 2)
            local fadeDelay = ImportNumber(fields[6], 0, 5)
            if not IsSafeImportID(id) or profile.targets[id] or fields[3] ~= "1" or not atRest or not fadeDuration or not fadeDelay then return ImportFailure("A target entry is invalid.") end
            targetCount = targetCount + 1; if targetCount > 120 then return ImportFailure("An import can contain at most 120 targets.") end
            profile.targets[id] = { enabled = true, atRest = atRest, fadeDuration = fadeDuration, fadeDelay = fadeDelay, reactions = {} }
        elseif tag == "R" and #fields == 7 then
            local targetID, condition, requirements = DecodeField(fields[2]), DecodeField(fields[4]), DecodeField(fields[7])
            local id = ImportNumber(fields[3], 1, 1000000000)
            local opacity = ImportNumber(fields[5], 0, 1)
            local info = condition and CONDITION_INFO[condition]
            if not IsSafeImportID(targetID) or not profile.targets[targetID] or not id or id % 1 ~= 0 or reactionIDs[id] or not opacity or not info or info.internal or requirements == nil then return ImportFailure("A reaction entry is invalid.") end
            local duration = nil
            if info.kind == "moment" then
                duration = ImportNumber(fields[6], 0.5, 30)
                if not duration then return ImportFailure("A moment duration is invalid.") end
            elseif fields[6] ~= "" then return ImportFailure("A state reaction cannot have a duration.") end
            local required, seen = {}, {}
            for requirement in (requirements or ""):gmatch("[^,]+") do
                local requirementInfo = CONDITION_INFO[requirement]
                if not requirementInfo or requirementInfo.internal or requirement == condition or seen[requirement] then return ImportFailure("A reaction requirement is invalid.") end
                required[#required + 1], seen[requirement] = requirement, true
            end
            reactionIDs[id] = true; reactionCount = reactionCount + 1
            if reactionCount > 800 then return ImportFailure("An import can contain at most 800 reactions.") end
            reactionsByTarget[targetID] = (reactionsByTarget[targetID] or 0) + 1
            if reactionsByTarget[targetID] > self.MAX_REACTIONS_PER_TARGET then return ImportFailure("An import can contain at most " .. self.MAX_REACTIONS_PER_TARGET .. " reactions per target.") end
            profile.targets[targetID].reactions[#profile.targets[targetID].reactions + 1] = { id = id, condition = condition, opacity = opacity, duration = duration, requirements = required }
            profile.nextReactionID = math.max(profile.nextReactionID, id + 1)
        elseif tag == "G" and #fields == 4 then
            local groupID, groupName, membersText = DecodeField(fields[2]), DecodeField(fields[3]), DecodeField(fields[4])
            if not IsSafeImportID(groupID, 64) or profile.groups[groupID] or not IsSafeImportID(groupName, 64) then return ImportFailure("A reveal group is invalid.") end
            local members = {}
            for encodedMemberID in (membersText or ""):gmatch("[^,]+") do
                local memberID = DecodeField(encodedMemberID)
                if not IsSafeImportID(memberID) or not profile.targets[memberID] or members[memberID] or memberToGroup[memberID] then return ImportFailure("A reveal group member is invalid.") end
                members[memberID] = true
            end
            local count = 0; for _ in pairs(members) do count = count + 1 end
            if count < 2 then return ImportFailure("A reveal group needs at least two targets.") end
            groupCount = groupCount + 1; if groupCount > 60 then return ImportFailure("An import can contain at most 60 reveal groups.") end
            for memberID in pairs(members) do memberToGroup[memberID] = groupID end
            profile.groups[groupID] = { name = groupName, members = members }
            local generatedDigits = groupID:match("^group(%d+)$")
            if generatedDigits and #generatedDigits <= 10 then
                local generatedID = tonumber(generatedDigits)
                if generatedID and generatedID <= 1000000000 then profile.nextGroupID = math.max(profile.nextGroupID, generatedID + 1) end
            end
        elseif tag == "L" and #fields == 3 then
            local parentID, childrenText = DecodeField(fields[2]), DecodeField(fields[3])
            if not IsSafeImportID(parentID) or not profile.targets[parentID] or profile.links[parentID] then return ImportFailure("A link source is invalid.") end
            local children = {}
            for encodedChildID in (childrenText or ""):gmatch("[^,]+") do
                local childID = DecodeField(encodedChildID)
                if not IsSafeImportID(childID) or not profile.targets[childID] or childID == parentID or children[childID] then return ImportFailure("A linked child is invalid.") end
                children[childID] = true
                edgeCount = edgeCount + 1; if edgeCount > 500 then return ImportFailure("An import can contain at most 500 links.") end
            end
            if not next(children) then return ImportFailure("A link needs at least one child.") end
            profile.links[parentID] = children
        else
            return ImportFailure("The export contains an unknown entry.")
        end
    end
    -- Connected frames need an unconditional hover fallback.  Do this before
    -- accepting the profile so imported data can never be repaired past the
    -- per-target reaction cap after it becomes active.
    local connectionTargets = {}
    for _, group in pairs(profile.groups) do
        for memberID in pairs(group.members or {}) do connectionTargets[memberID] = true end
    end
    for parentID, children in pairs(profile.links) do
        connectionTargets[parentID] = true
        for childID in pairs(children) do connectionTargets[childID] = true end
    end
    for id in pairs(connectionTargets) do
        local hasFallback = false
        for _, reaction in ipairs(profile.targets[id].reactions) do
            if reaction.condition == "mouseover" and #(reaction.requirements or {}) == 0 then
                hasFallback = true
                break
            end
        end
        if not hasFallback then
            return ImportFailure("Every connected frame needs an unconditional Mouseover reaction.")
        end
    end
    local function Reaches(id, sought, seen)
        if id == sought then return true end
        if seen[id] then return false end
        seen[id] = true
        for childID in pairs(profile.links[id] or {}) do if Reaches(childID, sought, seen) then return true end end
        return false
    end
    for parentID, children in pairs(profile.links) do
        for childID in pairs(children) do if Reaches(childID, parentID, {}) then return ImportFailure("The import contains a linked-frame loop.") end end
    end
    return profile, { targets = targetCount, reactions = reactionCount }
end

function ns:ImportProfile(name, text)
    name = NormalizeProfileName(name)
    if not name then return false, "Use a valid new profile name." end
    local db = PriorityFaderDB
    if FindProfileName(db, name) then return false, "That profile name is already in use." end
    local profile, summary = self:ParseProfileImport(text)
    if not profile then return false, summary end
    db.profiles[name] = profile
    local ok, reason = self:SelectProfile(name)
    if not ok then db.profiles[name] = nil; return false, reason end
    return true, summary
end

function ns:RemoveTarget(id)
    self:RestoreControlledFrame(id)
    self:Profile().targets[id] = nil
    runtime.active[id] = nil
    runtime.hovered[id] = nil
    runtime.fadeOutStarted[id] = nil
    local profile = self:Profile()
    for key, group in pairs(profile.groups or {}) do
        if group.members then
            group.members[id] = nil
            local count = 0; for _ in pairs(group.members) do count = count + 1 end
            if count < 2 then profile.groups[key] = nil end
        end
    end
    for parentID, children in pairs(profile.links or {}) do
        if parentID == id then
            profile.links[parentID] = nil
        else
            children[id] = nil
            if not next(children) then profile.links[parentID] = nil end
        end
    end
    if self.ConnectionPicker and self.ConnectionPicker:IsShown() and self.ConnectionPicker.sourceID == id then
        self.ConnectionPicker:Hide()
    end
    if self.ReconcileCinematicOwnership then self:ReconcileCinematicOwnership() end
    self:RefreshOptions()
end

function ns:EnsureMouseoverReaction(id)
    local settings = self:GetTargetSettings(id, true)
    if self:HasUnconditionalMouseover(settings) then return true end
    if #settings.reactions >= self.MAX_REACTIONS_PER_TARGET then
        return false, "This frame already has the maximum of " .. self.MAX_REACTIONS_PER_TARGET .. " reactions. Remove one before linking it."
    end
    -- Preserve a user's more specific hover variants (for example,
    -- Mouseover + Shift) before adding the connection-safe fallback.
    local insertAt = 1
    for index, reaction in ipairs(settings.reactions) do
        if reaction.condition == "mouseover" then insertAt = index + 1 end
    end
    table.insert(settings.reactions, insertAt, { id = self:NextReactionID(), condition = "mouseover", opacity = 1 })
    return true
end

function ns:CountUnconditionalMouseover(settings)
    local count = 0
    for _, reaction in ipairs(settings.reactions) do
        if reaction.condition == "mouseover" and #(reaction.requirements or {}) == 0 then count = count + 1 end
    end
    return count
end

function ns:HasUnconditionalMouseover(settings)
    return self:CountUnconditionalMouseover(settings) > 0
end

function ns:CanEnsureMouseoverReaction(id)
    local settings = self:GetTargetSettings(id)
    if not settings or self:HasUnconditionalMouseover(settings) then return true end
    if #settings.reactions >= self.MAX_REACTIONS_PER_TARGET then
        return false, "This frame already has the maximum of " .. self.MAX_REACTIONS_PER_TARGET .. " reactions. Remove one before linking it."
    end
    return true
end

function ns:GetRevealGroup(id)
    local groups = self:Profile().groups or {}
    for key, group in pairs(groups) do
        if group.members and group.members[id] then return key, group end
    end
end

function ns:AddToRevealGroup(id, memberID)
    if id == memberID then return false, "A frame cannot join a reveal group with itself." end
    local groups = self:Profile().groups
    local key, group = self:GetRevealGroup(id)
    local memberKey, memberGroup = self:GetRevealGroup(memberID)
    local mustFit = { [id] = true, [memberID] = true }
    for existingID in pairs(group and group.members or {}) do mustFit[existingID] = true end
    for existingID in pairs(memberGroup and memberGroup.members or {}) do mustFit[existingID] = true end
    for targetID in pairs(mustFit) do
        local allowed, reason = self:CanEnsureMouseoverReaction(targetID)
        if not allowed then return false, reason end
    end
    if not group then
        key, group = "group" .. self:NextGroupID(), { name = "Reveal group", members = { [id] = true } }
        groups[key] = group
    end
    if memberGroup and memberGroup ~= group then
        for existingID in pairs(memberGroup.members or {}) do group.members[existingID] = true end
        groups[memberKey] = nil
    end
    group.members[memberID] = true
    self:AddTarget(id)
    self:AddTarget(memberID)
    for targetID in pairs(mustFit) do
        local allowed, reason = self:EnsureMouseoverReaction(targetID)
        if not allowed then return false, reason end
    end
    return true
end

function ns:RemoveFromRevealGroup(id)
    local key, group = self:GetRevealGroup(id)
    if not group then return end
    group.members[id] = nil
    local count = 0
    for _ in pairs(group.members) do count = count + 1 end
    if count < 2 then self:Profile().groups[key] = nil end
end

function ns:GetLinkedChildren(parentID)
    return self:Profile().links[parentID] or {}
end

function ns:GetLinkParents(childID)
    local parents = {}
    for parentID, children in pairs(self:Profile().links or {}) do
        if children[childID] then parents[#parents + 1] = parentID end
    end
    return parents
end

function ns:RemoveLink(parentID, childID)
    local links = self:Profile().links
    if not links[parentID] then return end
    links[parentID][childID] = nil
    if not next(links[parentID]) then links[parentID] = nil end
end

function ns:CanAddLink(parentID, childID)
    if parentID == childID then return false, "A frame cannot link to itself." end
    local links = self:Profile().links
    local function Reaches(from, sought, seen)
        if from == sought then return true end
        if seen[from] then return false end
        seen[from] = true
        for nextID in pairs(links[from] or {}) do
            if Reaches(nextID, sought, seen) then return true end
        end
        return false
    end
    if Reaches(childID, parentID, {}) then return false, "That link would create a loop." end
    return true
end

function ns:AddLink(parentID, childID)
    local allowed, reason = self:CanAddLink(parentID, childID)
    if not allowed then return false, reason end
    allowed, reason = self:CanEnsureMouseoverReaction(parentID)
    if not allowed then return false, reason end
    allowed, reason = self:CanEnsureMouseoverReaction(childID)
    if not allowed then return false, reason end
    local links = self:Profile().links
    links[parentID] = links[parentID] or {}
    links[parentID][childID] = true
    self:AddTarget(parentID)
    self:AddTarget(childID)
    allowed, reason = self:EnsureMouseoverReaction(parentID)
    if not allowed then return false, reason end
    allowed, reason = self:EnsureMouseoverReaction(childID)
    if not allowed then return false, reason end
    return true
end

function ns:HasHoverConnection(id)
    local _, group = self:GetRevealGroup(id)
    return group ~= nil or next(self:GetLinkedChildren(id)) ~= nil or #self:GetLinkParents(id) > 0
end

function ns:EnsureConnectedHoverRules()
    local profile = self:Profile()
    local allSafe = true
    for id in pairs(profile.targets) do
        if self:HasHoverConnection(id) then
            local safe = self:EnsureMouseoverReaction(id)
            if not safe then allSafe = false end
        end
    end
    return allSafe
end

function ns:RestorePendingAlphas()
    if InCombatLockdown() then return end
    for frame, alpha in pairs(runtime.pendingRestore) do
        self:RestorePendingFrame(frame)
    end
end

function ns:RestorePendingFrame(frame)
    local alpha = runtime.pendingRestore[frame]
    if alpha == nil then return true end
    if SafeSetFrameAlpha(frame, alpha) then
        runtime.pendingRestore[frame] = nil
        local release = runtime.pendingRelease[frame]
        runtime.pendingRelease[frame] = nil
        if release then pcall(release, frame) end
        return true
    end
    return false
end

function ns:HasReaction(settings, condition)
    for _, reaction in ipairs(settings.reactions or {}) do
        if reaction.condition == condition then return true end
    end
    return false
end

function ns:UsesCondition(settings, condition)
    for _, reaction in ipairs(settings.reactions or {}) do
        if reaction.condition == condition then return true end
        for _, requirement in ipairs(reaction.requirements or {}) do
            if requirement == condition then return true end
        end
    end
    return false
end

function ns:BuildStateContext()
    local context = {}
    context.combat = SafeBoolean(InCombatLockdown)
    if context.combat ~= nil then context.out_of_combat = not context.combat end
    context.target_any = SafeBoolean(UnitExists, "target")
    context.target = context.target_any -- v0.1 alias
    if context.target_any ~= nil then context.no_target = not context.target_any end
    if context.target_any then
        context.target_hostile = SafeBoolean(UnitCanAttack, "player", "target")
        context.hostile_target = context.target_hostile -- v0.1 alias
        context.target_friendly = SafeBoolean(UnitCanAssist, "player", "target")
        context.target_dead = SafeBoolean(UnitIsDeadOrGhost, "target")
    end
    local ok, speed = pcall(GetUnitSpeed, "player")
    if ok and not IsSecret(speed) and type(speed) == "number" then
        context.moving = speed > 0
        context.stationary = not context.moving
    end
    context.falling = SafeBoolean(IsFalling)
    context.shift = SafeBoolean(IsShiftKeyDown)
    context.control = SafeBoolean(IsControlKeyDown)
    context.alt = SafeBoolean(IsAltKeyDown)
    context.dead = SafeBoolean(UnitIsDeadOrGhost, "player")
    context.mounted = SafeBoolean(IsMounted)
    context.flying = SafeBoolean(IsFlying)
    context.swimming = SafeBoolean(IsSwimming)
    context.underwater = SafeBoolean(IsSubmerged)
    context.vehicle = SafeBoolean(UnitInVehicle, "player")
    if context.vehicle == false then context.vehicle = SafeBoolean(UnitHasVehicleUI, "player") end
    context.taxi = SafeBoolean(UnitOnTaxi, "player")
    if C_PetBattles then context.pet_battle = SafeBoolean(C_PetBattles.IsInBattle) end
    if C_PlayerInfo then context.dragonriding = SafeBoolean(C_PlayerInfo.GetGlidingInfo) end
    local inGroup, inRaid = SafeBoolean(IsInGroup), SafeBoolean(IsInRaid)
    context.raid = inRaid
    if inGroup ~= nil and inRaid ~= nil then context.group = inGroup and not inRaid end
    if inGroup ~= nil then context.solo = not inGroup end
    local instanceOK, inInstance, instanceType = pcall(IsInInstance)
    if instanceOK and not IsSecret(inInstance) and not IsSecret(instanceType) then
        context.instance = inInstance and true or false
        if inInstance then
            context.dungeon = instanceType == "party"
            context.raid_instance = instanceType == "raid"
            context.battleground = instanceType == "pvp"
            context.arena = instanceType == "arena"
            context.scenario = instanceType == "scenario"
        else
            context.open_world = true
        end
    end
    context.resting = SafeBoolean(IsResting)
    context.pvp_flagged = SafeBoolean(UnitIsPVP, "player"); context.pvp = context.pvp_flagged -- v0.1 alias
    if C_PvP then context.war_mode = SafeBoolean(C_PvP.IsWarModeDesired) end
    context.indoors = SafeBoolean(IsIndoors); context.outdoors = SafeBoolean(IsOutdoors)
    runtime.context = context
end

function ns:ConditionIsMet(condition, id, reaction, isRequirement)
    if condition == "mouseover" then return runtime.hovered[id] == true or self:IsConnectionHovered(id) end
    local info = CONDITION_INFO[condition]
    if info and info.kind == "moment" then
        local occurred = runtime.moments[condition]
        local duration = isRequirement and info.duration or reaction.duration or info.duration or 3
        return occurred and (GetTime() - occurred) <= duration or false
    end
    -- A nil context value is deliberately unknown, never false.  In
    -- particular, negative rules never become accidentally true in secret UI.
    return runtime.context[condition] == true
end

function ns:ReactionIsMet(reaction, id)
    if not self:ConditionIsMet(reaction.condition, id, reaction) then return false end
    for _, condition in ipairs(reaction.requirements or {}) do
        if not self:ConditionIsMet(condition, id, reaction, true) then return false end
    end
    return true
end

function ns:Evaluate(id, settings)
    for index, reaction in ipairs(settings.reactions or {}) do
        if self:ReactionIsMet(reaction, id) then
            return reaction.opacity or 1, index, reaction
        end
    end
    return settings.atRest or 0.12, nil, nil
end

function ns:GetUsableFrameRect(frame)
    if not frame then return end
    local shownOK, shown = pcall(CallFrameIsShown, frame)
    -- Retail can return secret values for a visible frame's geometry.  They
    -- are valid values, but addon Lua may not compare or do arithmetic with
    -- them. Treat just that frame as unreadable rather than aborting a whole
    -- on-screen discovery pass.
    if not shownOK or IsSecret(shown) or shown ~= true then return end
    local rectOK, left, bottom, width, height = pcall(CallFrameGetRect, frame)
    if not rectOK or IsSecret(left) or IsSecret(bottom) or IsSecret(width) or IsSecret(height)
        or type(left) ~= "number" or type(bottom) ~= "number"
        or type(width) ~= "number" or type(height) ~= "number"
        or left ~= left or bottom ~= bottom or width ~= width or height ~= height
        or math.abs(left) > 10000000 or math.abs(bottom) > 10000000
        or math.abs(width) > 10000000 or math.abs(height) > 10000000
        or width <= 0 or height <= 0 then return end
    return left, bottom, width, height
end

local function SafeFrameShown(frame)
    local ok, shown = pcall(CallFrameIsShown, frame)
    return ok and not IsSecret(shown) and shown == true
end

SafeFrameAlpha = function(frame)
    local ok, alpha = pcall(CallFrameGetAlpha, frame)
    if not ok or IsSecret(alpha) or type(alpha) ~= "number" or alpha ~= alpha or math.abs(alpha) > 1000 then return nil end
    return alpha
end

local function SetManagedFrameAlpha(frame, alpha)
    runtime.managedAlphaGuard[frame] = true
    local ok = SafeSetFrameAlpha(frame, alpha)
    runtime.managedAlphaGuard[frame] = nil
    return ok
end

local function ManagedHostAlphaChanged(frame, alpha)
    if runtime.managedAlphaGuard[frame] or runtime.cinematicAlphaGuard[frame]
        or IsSecret(alpha) or type(alpha) ~= "number" or alpha ~= alpha then return end
    local id = runtime.managedIDByFrame[frame]
    if not id or runtime.frameByID[id] ~= frame then return end
    -- Preserve the host's newest alpha for eventual restoration, but keep the
    -- PF presentation as the top-level visibility layer while this target is
    -- controlled. This composes with addon repaints without editing their DB,
    -- scripts, layout, or styling state.
    runtime.baseAlpha[frame] = alpha
    runtime.currentAlpha[frame] = alpha
    local active = runtime.active[id]
    local owned = active and active.alpha
    if type(owned) == "number" and math.abs(alpha - owned) > 0.001
        and SetManagedFrameAlpha(frame, owned) then
        runtime.currentAlpha[frame] = owned
    end
end

function ns:HookManagedFrameAlpha(frame)
    if not frame or runtime.managedAlphaHooks[frame] or InCombatLockdown() or type(hooksecurefunc) ~= "function" then return end
    if pcall(hooksecurefunc, frame, "SetAlpha", ManagedHostAlphaChanged) then
        runtime.managedAlphaHooks[frame] = true
    end
end

function ns:FrameContainsCursor(frame)
    local left, bottom, width, height = self:GetUsableFrameRect(frame)
    if not left then return false end
    local cursorOK, x, y = pcall(GetCursorPosition)
    local scaleOK, scale = pcall(function() return UIParent:GetEffectiveScale() end)
    if not cursorOK or not scaleOK or IsSecret(x) or IsSecret(y) or IsSecret(scale)
        or type(x) ~= "number" or type(y) ~= "number" or type(scale) ~= "number"
        or x ~= x or y ~= y or scale ~= scale or scale <= 0 then return false end
    x, y = x / scale, y / scale
    return x >= left and x <= left + width and y >= bottom and y <= bottom + height
end

function ns:IsConnectionHovered(id)
    local profile = self:Profile()
    for _, group in pairs(profile.groups or {}) do
        if group.members and group.members[id] then
            for memberID in pairs(group.members) do
                if runtime.hovered[memberID] then return true end
            end
        end
    end
    local function AncestorHovered(childID, seen)
        if seen[childID] then return false end
        seen[childID] = true
        for parentID, children in pairs(profile.links or {}) do
            if children and children[childID] then
                if runtime.hovered[parentID] or AncestorHovered(parentID, seen) then return true end
            end
        end
        return false
    end
    return AncestorHovered(id, {})
end

function ns:UpdateHover()
    local profile = self:Profile()
    local needed = {}
    for id, settings in pairs(profile.targets or {}) do
        if settings.enabled and self:UsesCondition(settings, "mouseover") then needed[id] = true end
    end
    for _, group in pairs(profile.groups or {}) do
        for memberID in pairs(group.members or {}) do needed[memberID] = true end
    end
    for parentID in pairs(profile.links or {}) do needed[parentID] = true end
    for id, settings in pairs(profile.targets or {}) do
        if settings.enabled and needed[id] then
            local frame = self:ResolveTarget(id)
            if frame and self.FrameInteractionContainsCursor then
                runtime.hovered[id] = self:FrameInteractionContainsCursor(frame, id == "minimap")
                if id == "minimap" and not runtime.hovered[id] and self.MinimapStackContainsCursor then
                    runtime.hovered[id] = self:MinimapStackContainsCursor()
                end
            else
                runtime.hovered[id] = frame and self:FrameContainsCursor(frame) or false
            end
        else
            runtime.hovered[id] = false
        end
    end
end

function ns:ApplyTarget(id, elapsed)
    local settings = self:GetTargetSettings(id)
    if not settings or not settings.enabled then return end
    local frame, target = self:ResolveTarget(id)
    local previous = runtime.frameByID[id]
    if previous and previous ~= frame then self:RestoreControlledFrame(id) end
    if not frame then
        runtime.fadeOutStarted[id] = nil
        runtime.active[id] = { unavailable = true }
        return
    end
    -- A profile switch may be waiting to restore this provider frame's old
    -- alpha. Do that first; never capture an old faded alpha as the new base.
    if not self:RestorePendingFrame(frame) then
        runtime.active[id] = { pendingRestore = true }
        return
    end
    if previous ~= frame and target and target.acquire then
        local acquired, usable = pcall(target.acquire, frame)
        if not acquired or usable == false then
            runtime.active[id] = { unavailable = true }
            return
        end
    end
    runtime.frameByID[id] = frame
    runtime.managedIDByFrame[frame] = id
    if not (target and target.skipManagedAlphaHook) then self:HookManagedFrameAlpha(frame) end
    local desired, index, reaction = self:Evaluate(id, settings)
    local current = runtime.currentAlpha[frame]
    if current == nil then
        current = SafeFrameAlpha(frame)
        if current == nil then
            runtime.active[id] = { hostHidden = true }
            return
        end
        runtime.baseAlpha[frame] = current
        runtime.currentAlpha[frame] = current
    else
        -- A provider may have repainted alpha before its post-hook could be
        -- installed (for example, the frame first appeared during combat).
        -- Reconcile against the live value so cached state can never strand PF
        -- at a stale opacity. The hook closes this window once combat ends.
        local live = SafeFrameAlpha(frame)
        if live ~= nil and math.abs(live - current) > 0.001 then
            runtime.baseAlpha[frame] = live
            runtime.currentAlpha[frame] = live
            current = live
        end
    end
    if not SafeFrameShown(frame) then
        -- Prepare opacity while the host has the frame hidden. SetAlpha does
        -- not Show it, but it prevents a cast bar, transient window, or pooled
        -- addon frame from appearing bright for one tick (or for fadeDelay)
        -- when its owner later shows it.
        runtime.fadeOutStarted[id] = nil
        if math.abs(current - desired) > 0.001 then
            if SetManagedFrameAlpha(frame, desired) then
                current = desired
                runtime.currentAlpha[frame] = desired
            end
        end
        runtime.active[id] = {
            alpha = current,
            desired = desired,
            index = index,
            reaction = reaction,
            hostHidden = true,
            protected = target and target.protected,
        }
        return
    end
    if runtime.immediateApply[id] then
        runtime.immediateApply[id] = nil
        runtime.fadeOutStarted[id] = nil
        if math.abs(current - desired) > 0.001 and SetManagedFrameAlpha(frame, desired) then
            current = desired
            runtime.currentAlpha[frame] = desired
        end
        runtime.active[id] = {
            alpha = current,
            desired = desired,
            index = index,
            reaction = reaction,
            hostHidden = false,
            protected = target and target.protected,
        }
        return
    end
    local now = GetTime()
    if desired < current and (settings.fadeDelay or 0) > 0 then
        -- Keep the start of this fade-out transition, not a frozen deadline,
        -- so a live delay edit takes effect immediately without restarting it.
        runtime.fadeOutStarted[id] = runtime.fadeOutStarted[id] or now
        if now < runtime.fadeOutStarted[id] + settings.fadeDelay then
            runtime.active[id] = { alpha = current, desired = desired, index = index, reaction = reaction, hostHidden = false, protected = target and target.protected }
            return
        end
    else
        runtime.fadeOutStarted[id] = nil
    end
    local duration = math.max(0.01, settings.fadeDuration or 0.2)
    local step = elapsed and math.min(1, elapsed / duration) or 1
    local alpha = current + (desired - current) * step
    if math.abs(alpha - desired) < 0.005 then alpha = desired end
    if math.abs(alpha - current) > 0.001 then
        local ok = SetManagedFrameAlpha(frame, alpha)
        if ok then runtime.currentAlpha[frame] = alpha else alpha = current end
    end
    runtime.active[id] = {
        alpha = alpha,
        desired = desired,
        index = index,
        reaction = reaction,
        hostHidden = false,
        protected = target and target.protected,
    }
end

function ns:PrimeCinematicTargets()
    if not self:IsCinematicActive() then return end
    self:BuildStateContext()
    self:UpdateHover()
    local ids = {}
    for id in pairs(self:Profile().targets or {}) do
        ids[#ids + 1] = id
        runtime.immediateApply[id] = true
    end
    for _, id in ipairs(ids) do self:ApplyTarget(id, nil) end
end

function ns:Tick(elapsed)
    local now = GetTime()
    -- One shared, capped evaluator keeps the addon light even with several
    -- targets.  Alpha transitions remain smooth at 20 Hz without an OnUpdate
    -- handler per frame.
    if now - runtime.lastTick < 0.05 then return end
    local delta = now - runtime.lastTick
    runtime.lastTick = now
    local cdmGeneration = self.GetExperimentalCDMGeneration and self:GetExperimentalCDMGeneration() or nil
    if self.RefreshExperimentalCDMTargets and (cdmGeneration ~= runtime.lastCDMGeneration
        or now - (runtime.lastCDMRefresh or 0) >= 1) then
        runtime.lastCDMRefresh = now
        runtime.lastCDMGeneration = cdmGeneration
        self:RefreshExperimentalCDMTargets()
    end
    if now - runtime.lastMouseTick >= 0.08 then
        runtime.lastMouseTick = now
        self:UpdateHover()
    end
    self:BuildStateContext()
    local profile = self:Profile()
    for id in pairs(profile.targets or {}) do self:ApplyTarget(id, delta) end
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
        if not InCombatLockdown() and now - (runtime.cinematicRootScanAt or 0) >= 1 then
            self:BeginCinematicBlackout()
        else
            self:UpdateCinematicBlackout()
        end
    end
    if self.Options and self.Options:IsVisible() then self:RefreshActiveState() end
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
    if target and target.AddMessage then target:AddMessage("|cff9D75FFPriority Fader|r " .. SafeDiagnosticText(text), color and color[1], color and color[2], color and color[3]) end
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
    local configured, configuredAvailable, groupCount, linkCount = 0, 0, 0, 0
    local issues, groupMembers, connected = {}, {}, {}
    if profile.targets ~= targets then issues[#issues + 1] = "Target settings are malformed." end
    if profile.groups ~= groups then issues[#issues + 1] = "Reveal groups are malformed." end
    if profile.links ~= links then issues[#issues + 1] = "Frame links are malformed." end
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
            connected[parentID] = true
            if not targets[parentID] then issues[#issues + 1] = "Link source " .. DiagnosticID(parentID) .. " is not controlled." end
        end
        if children ~= childTable then issues[#issues + 1] = "Linked children for " .. DiagnosticID(parentID) .. " are malformed." end
        for childID in pairs(childTable) do
            linkCount = linkCount + 1
            if type(childID) ~= "string" then
                issues[#issues + 1] = "A linked child id is not a string."
            else
                if childID == parentID then issues[#issues + 1] = "Link " .. DiagnosticID(parentID) .. " points to itself." end
                connected[childID] = true
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
    for id in pairs(connected) do
        local settings, hasMouseover = targets[id], false
        for _, reaction in ipairs(type(settings) == "table" and type(settings.reactions) == "table" and settings.reactions or {}) do
            if type(reaction) == "table" and reaction.condition == "mouseover" and #(type(reaction.requirements) == "table" and reaction.requirements or {}) == 0 then hasMouseover = true; break end
        end
        if not hasMouseover then issues[#issues + 1] = "Connected target " .. DiagnosticID(id) .. " lacks an unconditional Mouseover reaction." end
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
    DiagnosticMessage("Configured: " .. configuredAvailable .. "/" .. configured .. " currently available | Relationships: " .. groupCount .. " groups, " .. linkCount .. " links.", self.COLORS.muted)
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

local driver = CreateFrame("Frame")
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
for event in pairs(EVENT_TO_MOMENT) do driver:RegisterEvent(event) end

function ns:Wake()
    if not driver:GetScript("OnUpdate") then
        driver:SetScript("OnUpdate", function(_, elapsed) ns:Tick(elapsed) end)
    end
end

driver:SetScript("OnEvent", function(_, event, ...)
    if event == "PLAYER_LOGIN" then
        PriorityFaderDB = CopyDefaults(DEFAULTS, PriorityFaderDB)
        ns:MigrateDatabase()
        if ns.RegisterStoredCustomFrames then ns:RegisterStoredCustomFrames() end
        if ns.RefreshExperimentalCDMTargets then ns:RefreshExperimentalCDMTargets() end
        ns:EnsureCinematicProfile()
        if ns.RefreshOPieFrames then ns:RefreshOPieFrames() end
        ns:RegisterCinematicUIMode()
        ns:EnsureConnectedHoverRules()
        ns:Wake()
        ns:CreateOptions()
        if ns:IsCinematicActive() then
            ns:PrimeCinematicTargets()
            ns:SetCinematicUIMode(ns:CanUseCinematicNativeMode())
            ns:BeginCinematicBlackout()
            C_Timer.After(0.5, function() if ns:IsCinematicActive() then ns:BeginCinematicBlackout() end end)
        end
        return
    end
    if event == "ADDON_LOADED" then
        if ns.RefreshOPieFrames then ns:RefreshOPieFrames() end
        if ns.RefreshExperimentalCDMTargets then ns:RefreshExperimentalCDMTargets() end
        if ns:IsCinematicActive() and not InCombatLockdown() then
            ns:BeginCinematicBlackout()
            C_Timer.After(0.1, function() if ns:IsCinematicActive() then ns:BeginCinematicBlackout() end end)
        end
    end
    if ns.CancelPicker and (event == "PLAYER_REGEN_DISABLED" or event == "PLAYER_ENTERING_WORLD" or event == "PET_BATTLE_OPENING_START") then
        ns:CancelPicker(event == "PLAYER_REGEN_DISABLED" and "combat" or "interrupted")
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
        C_Timer.After(0.5, function() if ns:IsCinematicActive() then ns:BeginCinematicBlackout() end end)
    end
    if event == "UPDATE_BINDINGS" and ns.CinematicOptions and ns.CinematicOptions:IsShown() then
        ns:RenderCinematicOptions()
    end
    ns:Wake()
    -- The option panel updates its live-state chip from Tick.  Rebuilding its
    -- dynamic rows for every game event would continually create hidden UI
    -- objects, so only explicit editor actions redraw it.
end)

SLASH_PRIORITYFADER1 = "/pfader"
SLASH_PRIORITYFADER2 = "/priorityfader"
function PriorityFader_ToggleCinematic()
    local ok, reason, enabled = ns:ToggleCinematic()
    if not ok and DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then
        DEFAULT_CHAT_FRAME:AddMessage("|cff9D75FFPriority Fader|r " .. tostring(reason or "Cinematic Mode could not be toggled."))
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
