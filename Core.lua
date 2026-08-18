local ADDON, ns = ...

ns.NAME = "Frame Gambit"
ns.VERSION = "2.7.0"
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
    cinematicPanelHooks = setmetatable({}, { __mode = "k" }),
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
        local playerGUID = SafeValuã®¶êÚ$z{-®éÜj×6öææV7FVE¶–EÒÒG'VP¢–bæ÷BF&vWG5¶–EÒF†Vâ—77VW5²6—77VW2²ÒÒ%&WfVÂw&÷W"ââF–væ÷7F–4”B†w&÷W”B’ââ"&VfW&Væ6W2âVæ6öçG&öÆÆVBF&vWBâ"Væ@¢Væ@¢Væ@¢–bÖVÖ&W'2Â"F†Vâ—77VW5²6—77VW2²ÒÒ%&WfVÂw&÷W"ââF–væ÷7F–4”B†w&÷W”B’ââ"†2fWvW"F†âGvòF&vWG2â"Væ@¢Væ@¢f÷"&VçD”BÂ6†–ÆG&Vâ–â—'2†Æ–æ·2’Fð¢Æö6Â6†–ÆEF&ÆRÒG—R†6†–ÆG&Vâ’ÓÒ'F&ÆR"æB6†–ÆG&Vâ÷"·Ð¢–bG—R‡&VçD”B’ãÒ'7G&–ær"F†Và¢—77VW5²6—77VW2²ÒÒ$Æ–æ²6÷W&6R–B—2æ÷B7G&–ærâ ¢VÇ6P¢–bæ÷BF&vWG5·&VçD”EÒF†Vâ—77VW5²6—77VW2²ÒÒ$Æ–æ²6÷W&6R"ââF–væ÷7F–4”B‡&VçD”B’ââ"—2æ÷B6öçG&öÆÆVBâ"Væ@¢Væ@¢–b6†–ÆG&VâãÒ6†–ÆEF&ÆRF†Vâ—77VW5²6—77VW2²ÒÒ$Æ–æ¶VB6†–ÆG&Vâf÷""ââF–væ÷7F–4”B‡&VçD”B’ââ"&RÖÆf÷&ÖVBâ"Væ@¢f÷"6†–ÆD”B–â—'2†6†–ÆEF&ÆR’Fð¢Æ–æ´6÷VçBÒÆ–æ´6÷VçB²¢–bG—R†6†–ÆD”B’ãÒ'7G&–ær"F†Và¢—77VW5²6—77VW2²ÒÒ$Æ–æ¶VB6†–ÆB–B—2æ÷B7G&–ærâ ¢VÇ6P¢–b6†–ÆD”BÓÒ&VçD”BF†Vâ—77VW5²6—77VW2²ÒÒ$Æ–æ²"ââF–væ÷7F–4”B‡&VçD”B’ââ"ö–çG2Fò—G6VÆbâ"Væ@¢–bæ÷BF&vWG5¶6†–ÆD”EÒF†Vâ—77VW5²6—77VW2²ÒÒ$Æ–æ¶VB6†–ÆB"ââF–væ÷7F–4”B†6†–ÆD”B’ââ"—2æ÷B6öçG&öÆÆVBâ"Væ@¢Væ@¢Væ@¢Væ@¢Æö6Âf—6—F–ærÂf—6—FVBÒ·ÒÂ·Ð¢Æö6ÂgVæ7F–öâ†4Æ–æ´7–6ÆR†–B¢–bf—6—F–æu¶–EÒF†Vâ&WGW&âG'VRVæ@¢–bf—6—FVE¶–EÒF†Vâ&WGW&âfÇ6RVæ@¢f—6—F–æu¶–EÒÒG'VP¢f÷"6†–ÆD”B–â—'2‡G—R†Æ–æ·5¶–EÒ’ÓÒ'F&ÆR"æBÆ–æ·5¶–EÒ÷"·Ò’Fð¢–b†4Æ–æ´7–6ÆR†6†–ÆD”B’F†Vâ&WGW&âG'VRVæ@¢Væ@¢f—6—F–æu¶–EÒÒæ–Ã²f—6—FVE¶–EÒÒG'VP¢&WGW&âfÇ6P¢Væ@¢f÷"&VçD”B–â—'2†Æ–æ·2’Fð¢–b†4Æ–æ´7–6ÆR‡&VçD”B’F†Và¢—77VW5²6—77VW2²ÒÒ$Æ–æ¶VBÖg&ÖRw&‚6öçF–ç2Æö÷â ¢'&V°¢Væ@¢Væ@¢Æö6Âf—6–&–Æ—G•&VçBÒ·Ð¢f÷"&VçD”BÂ6†–ÆG&Vâ–â—'2‡f—6–&–Æ—G”Æ–æ·2’Fð¢Æö6Â6†–ÆEF&ÆRÒG—R†6†–ÆG&Vâ’ÓÒ'F&ÆR"æB6†–ÆG&Vâ÷"·Ð¢–bG—R‡&VçD”B’ãÒ'7G&–ær"F†Và¢—77VW5²6—77VW2²ÒÒ$f—6–&–Æ—G’6÷W&6R–B—2æ÷B7G&–ærâ ¢VÇ6V–bæ÷BF&vWG5·&VçD”EÒF†Và¢—77VW5²6—77VW2²ÒÒ%f—6–&–Æ—G’6÷W&6R"ââF–væ÷7F–4”B‡&VçD”B’ââ"—2æ÷B6öçG&öÆÆVBâ ¢Væ@¢–b6†–ÆG&VâãÒ6†–ÆEF&ÆRF†Vâ—77VW5²6—77VW2²ÒÒ%f—6–&–Æ—G’6†–ÆG&Vâf÷""ââF–væ÷7F–4”B‡&VçD”B’ââ"&RÖÆf÷&ÖVBâ"Væ@¢f÷"6†–ÆD”BÂVæ&ÆVB–â—'2†6†–ÆEF&ÆR’Fð¢f—6–&–Æ—G”6÷VçBÒf—6–&–Æ—G”6÷VçB²¢–bG—R†6†–ÆD”B’ãÒ'7G&–ær"÷"Væ&ÆVBãÒG'VRF†Và¢—77VW5²6—77VW2²ÒÒ$f—6–&–Æ—G’6†–ÆBVçG'’—2ÖÆf÷&ÖVBâ ¢VÇ6P¢–b6†–ÆD”BÓÒ&VçD”BF†Vâ—77VW5²6—77VW2²ÒÒ%f—6–&–Æ—G’6÷W&6R"ââF–væ÷7F–4”B‡&VçD”B’ââ"ö–çG2Fò—G6VÆbâ"Væ@¢–bæ÷BF&vWG5¶6†–ÆD”EÒF†Vâ—77VW5²6—77VW2²ÒÒ%f—6–&–Æ—G’6†–ÆB"ââF–væ÷7F–4”B†6†–ÆD”B’ââ"—2æ÷B6öçG&öÆÆVBâ"Væ@¢–bf—6–&–Æ—G•&VçE¶6†–ÆD”EÒæBf—6–&–Æ—G•&VçE¶6†–ÆD”EÒãÒ&VçD”BF†Và¢—77VW5²6—77VW2²ÒÒ%f—6–&–Æ—G’6†–ÆB"ââF–væ÷7F–4”B†6†–ÆD”B’ââ"†2Ö÷&RF†âöæR&VçBâ ¢VÇ6P¢f—6–&–Æ—G•&VçE¶6†–ÆD”EÒÒ&VçD”@¢Væ@¢Væ@¢Væ@¢Væ@¢Æö6Âf—6–&–Æ—G•f—6—F–ærÂf—6–&–Æ—G•f—6—FVBÒ·ÒÂ·Ð¢Æö6ÂgVæ7F–öâ†5f—6–&–Æ—G”7–6ÆR†–B¢–bf—6–&–Æ—G•f—6—F–æu¶–EÒF†Vâ&WGW&âG'VRVæ@¢–bf—6–&–Æ—G•f—6—FVE¶–EÒF†Vâ&WGW&âfÇ6RVæ@¢f—6–&–Æ—G•f—6—F–æu¶–EÒÒG'VP¢f÷"6†–ÆD”B–â—'2‡G—R‡f—6–&–Æ—G”Æ–æ·5¶–EÒ’ÓÒ'F&ÆR"æBf—6–&–Æ—G”Æ–æ·5¶–EÒ÷"·Ò’Fð¢–b†5f—6–&–Æ—G”7–6ÆR†6†–ÆD”B’F†Vâ&WGW&âG'VRVæ@¢Væ@¢f—6–&–Æ—G•f—6—F–æu¶–EÒÒæ–Ã²f—6–&–Æ—G•f—6—FVE¶–EÒÒG'VP¢&WGW&âfÇ6P¢Væ@¢f÷"&VçD”B–â—'2‡f—6–&–Æ—G”Æ–æ·2’Fð¢–b†5f—6–&–Æ—G”7–6ÆR‡&VçD”B’F†Và¢—77VW5²6—77VW2²ÒÒ%f—6–&–Æ—G’Ö–æ†W&—Fæ6Rw&‚6öçF–ç2Æö÷â ¢'&V°¢Væ@¢Væ@¢f÷"–B–â—'2†6öææV7FVB’Fð¢Æö6Â6WGF–æw2Â†4Ö÷W6V÷fW"ÒF&vWG5¶–EÒÂfÇ6P¢f÷"òÂ&V7F–öâ–â——'2‡G—R‡6WGF–æw2’ÓÒ'F&ÆR"æBG—R‡6WGF–æw2ç&V7F–öç2’ÓÒ'F&ÆR"æB6WGF–æw2ç&V7F–öç2÷"·Ò’Fð¢–bG—R‡&V7F–öâ’ÓÒ'F&ÆR"æB&V7F–öâæ6öæF—F–öâÓÒ&Ö÷W6V÷fW""æB2‡G—R‡&V7F–öâç&WV—&VÖVçG2’ÓÒ'F&ÆR"æB&V7F–öâç&WV—&VÖVçG2÷"·Ò’ÓÒF†Vâ†4Ö÷W6V÷fW"ÒG'VS²'&V²Væ@¢Væ@¢–bæ÷B†4Ö÷W6V÷fW"F†Vâ—77VW5²6—77VW2²ÒÒ%&WfVÂÖw&÷WÖVÖ&W""ââF–væ÷7F–4”B†–B’ââ"Æ6·2âVæ6öæF—F–öæÂÖ÷W6V÷fW"&V7F–öââ"Væ@¢Væ@¢Æö6ÂFFW$f–Æ&ÆRÂFFW%Væf–Æ&ÆRÂVæf–Æ&ÆRÒÂÂ·Ð¢f÷"òÂF&vWB–â——'2‡6VÆbåF&vWG2’Fð¢Æö6Âf–Æ&ÆRÂòÂòÂæ÷FRÒ6VÆc¤vWEF&vWDf–Æ&–Æ—G’‡F&vWB¢–bf–Æ&ÆRF†Và¢FFW$f–Æ&ÆRÒFFW$f–Æ&ÆR²¢VÇ6P¢FFW%Væf–Æ&ÆRÒFFW%Væf–Æ&ÆR²¢Væf–Æ&ÆU²7Væf–Æ&ÆR²ÒÒF–væ÷7F–4”B‡F&vWBæÆ&VÂ’ââ"Ò"ââF–væ÷7F–4”B†æ÷FR¢Væ@¢Væ@¢F–væ÷7F–4ÖW76vR‚'b"ââ6VÆbådU%4”ôâââ"Â&öf–ÆS¢"ââ†F"ç&öf–ÆR÷"$FVfVÇB"’Â6VÆbä4ôÄõ%2çFVÂ¢F–væ÷7F–4ÖW76vR‚$6öæf–wW&VC¢"ââ6öæf–wW&VDf–Æ&ÆRââ"ò"ââ6öæf–wW&VBââ"7W'&VçFÇ’f–Æ&ÆRÂ&VÆF–öç6†—3¢"ââw&÷W6÷VçBââ"w&÷W2Â"ââÆ–æ´6÷VçBââ"†÷fW"Æ–æ·2Â"ââf—6–&–Æ—G”6÷VçBââ"f—6–&–Æ—G’Æ–æ·2â"Â6VÆbä4ôÄõ%2æ×WFVB¢F–væ÷7F–4ÖW76vR‚$FFW'3¢"ââFFW$f–Æ&ÆRââ"f–Æ&ÆRÂ"ââFFW%Væf–Æ&ÆRââ"Væf–Æ&ÆRâ"ÂFFW%Væf–Æ&ÆRâæB6VÆbä4ôÄõ%2æÖ&W"÷"6VÆbä4ôÄõ%2çFVÂ¢–b6—77VW2ÓÒF†Và¢F–væ÷7F–4ÖW76vR‚%6fVB&öf–ÆRw&‚—26öç6—7FVçBâ"Â6VÆbä4ôÄõ%2çFVÂ¢VÇ6P¢F–væ÷7F–4ÖW76vR‚%&öf–ÆRw&‚æVVG2GFVçF–öã¢"ââ6—77VW2ââ"—77VR"ââ‚6—77VW2ÓÒæB""÷"'2"’ââ"â"Â6VÆbä4ôÄõ%2æÖ&W"¢f÷"–æFW‚ÒÂÖF‚æÖ–âƒBÂ6—77VW2’FòF–væ÷7F–4ÖW76vR‚"Ò"ââ—77VW5¶–æFW…ÒÂ6VÆbä4ôÄõ%2æÖ&W"’Væ@¢–b6—77VW2âBF†VâF–væ÷7F–4ÖW76vR‚"Ò"ââ‚6—77VW2ÒB’ââ"Ö÷&R—77VR‡2“²W‡÷'B&Vf÷&R6†æv–ærç—F†–ærâ"Â6VÆbä4ôÄõ%2æÖ&W"’Væ@¢Væ@¢f÷"–æFW‚ÒÂÖF‚æÖ–âƒbÂ7Væf–Æ&ÆR’FòF–væ÷7F–4ÖW76vR‚%v—F–æs¢"ââVæf–Æ&ÆU¶–æFW…ÒÂ6VÆbä4ôÄõ%2æ×WFVB’Væ@¢–b7Væf–Æ&ÆRâbF†VâF–væ÷7F–4ÖW76vR‚%v—F–æs¢"ââ‚7Væf–Æ&ÆRÒb’ââ"Ö÷&RFFW"‡2’â"Â6VÆbä4ôÄõ%2æ×WFVB’Væ@¦Væ@ ¦Æö6ÂgVæ7F–öâ&Vg&W6…Æ–W$67F–æu7FFR‚¢Æö6Âö²Â67F–ærÒ6ÆÂ†gVæ7F–öâ‚¢Æö6Â67DæÖRÒG—R…Væ—D67F–æt–æfò’ÓÒ&gVæ7F–öâ"æBVæ—D67F–æt–æfò‚'Æ–W""’÷"æ–À¢–b67DæÖRãÒæ–ÂF†Vâ&WGW&âG'VRVæ@¢Æö6Â6†ææVÄæÖRÒG—R…Væ—D6†ææVÄ–æfò’ÓÒ&gVæ7F–öâ"æBVæ—D6†ææVÄ–æfò‚'Æ–W""’÷"æ–À¢&WGW&â6†ææVÄæÖRãÒæ–À¢VæB¢–bö²æBæ÷B—56V7&WB†67F–ær’F†Vâ'VçF–ÖRçÆ–W$67F–ærÒ67F–ærÓÒG'VRVæ@¦Væ@ ¦G&—fW"Ò7&VFTg&ÖR‚$g&ÖR"¦G&—fW#¥&Vv—7FW$WfVçB‚%Ä”U%ôÄôt”â"¦G&—fW#¥&Vv—7FW$WfVçB‚$DDôåôÄôDTB"¦G&—fW#¥&Vv—7FW$WfVçB‚%Ä”U%õ$TtTåôD•4$ÄTB"¦G&—fW#¥&Vv—7FW$WfVçB‚%Ä”U%õ$TtTåôTä$ÄTB"¦G&—fW#¥&Vv—7FW$WfVçB‚%Ä”U%õD$tUEô4„ätTB"¦G&—fW#¥&Vv—7FW$WfVçB‚$u$õUõ$õ5DU%õUDDR"¦G&—fW#¥&Vv—7FW$WfVçB‚%Ä”U%ôÔõTåEôD•5Ä•ô4„ätTB"¦G&—fW#¥&Vv—7FW$WfVçB‚%Ä”U%ôTåDU$”äuõtõ$ÄB"¦G&—fW#¥&Vv—7FW$WfVçB‚%¤ôäUô4„ätTB"¦G&—fW#¥&Vv—7FW$WfVçB‚%¤ôäUô4„ätTEô”äDôõ%2"¦G&—fW#¥&Vv—7FW$WfVçB‚%Ä”U%ôdÄu5ô4„ätTB"¦G&—fW#¥&Vv—7FW$WfVçB‚%Ä”U%ôDTB"¦G&—fW#¥&Vv—7FW$WfVçB‚%Ä”U%ôÄ•dR"¦G&—fW#¥&Vv—7FW$WfVçB‚%Ä”U%õTät„õ5B"¦G&—fW#¥&Vv—7FW$WfVçB‚%Tä•EôTåDU$TEõdT„”4ÄR"¦G&—fW#¥&Vv—7FW$WfVçB‚%Tä•EôU„•DTEõdT„”4ÄR"¦G&—fW#¥&Vv—7FW$WfVçB‚%UEô$EDÄUôõTä”äuõ5D%B"¦G&—fW#¥&Vv—7FW$WfVçB‚%UEô$EDÄUô4Äõ4R"¦G&—fW#¥&Vv—7FW$WfVçB‚$4„EôÕ4uôÄôõB"¦G&—fW#¥&Vv—7FW$WfVçB‚%UDDUô$”äD”äu2"¦G&—fW#¥&Vv—7FW$WfVçB‚%Tä•Eõ5TÄÄ45Eõ5D%B"¦G&—fW#¥&Vv—7FW$WfVçB‚%Tä•Eõ5TÄÄ45Eõ5Dõ"¦G&—fW#¥&Vv—7FW$WfVçB‚%Tä•Eõ5TÄÄ45Eôd”ÄTB"¦G&—fW#¥&Vv—7FW$WfVçB‚%Tä•Eõ5TÄÄ45Eôd”ÄTEõT”UB"¦G&—fW#¥&Vv—7FW$WfVçB‚%Tä•Eõ5TÄÄ45Eô”åDU%%UDTB"¦G&—fW#¥&Vv—7FW$WfVçB‚%Tä•Eõ5TÄÄ45Eô4„ääTÅõ5D%B"¦G&—fW#¥&Vv—7FW$WfVçB‚%Tä•Eõ5TÄÄ45Eô4„ääTÅõ5Dõ"¦G&—fW#¥&Vv—7FW$WfVçB‚%Tä•EõUB"¦G&—fW#¥&Vv—7FW$WfVçB‚$4ôÕä”ôåõUDDR"¦G&—fW#¥&Vv—7FW$WfVçB‚%Tä•EôU$"§6ÆÂ†G&—fW"å&Vv—7FW$WfVçBÂG&—fW"Â%44Tä$”õõUDDR"§6ÆÂ†G&—fW"å&Vv—7FW$WfVçBÂG&—fW"Â%UDDUõ4„U4„”eEôdõ$Ò"§6ÆÂ†G&—fW"å&Vv—7FW$WfVçBÂG&—fW"Â%UDDUõ4„U4„”eEôdõ$Õ2"§6ÆÂ†G&—fW"å&Vv—7FW$WfVçBÂG&—fW"Â%Ä”U%õ5T4”Ä•¤D”ôåô4„ätTB"§6ÆÂ†G&—fW"å&Vv—7FW$WfVçBÂG&—fW"Â%5TÄÅ5ô4„ätTB"§6ÆÂ†G&—fW"å&Vv—7FW$WfVçBÂG&—fW"Â%Tä•Eõ5TÄÄ45EôTÕõtU%õ5D%B"§6ÆÂ†G&—fW"å&Vv—7FW$WfVçBÂG&—fW"Â%Tä•Eõ5TÄÄ45EôTÕõtU%õ5Dõ"¦f÷"WfVçB–â—'2„UdTåEõDõôÔôÔTåB’FòG&—fW#¥&Vv—7FW$WfVçB†WfVçB’Væ@ ¦gVæ7F–öâç3¥v¶R‚¢–bæ÷BG&—fW#¤vWE67&—B‚$öåWFFR"’F†Và¢G&—fW#¥6WE67&—B‚$öåWFFR"ÂgVæ7F–öâ…òÂVÆ6VB’ç3¥F–6²†VÆ6VB’VæB¢Væ@¦Væ@ ¦G&—fW#¥6WE67&—B‚$öäWfVçB"ÂgVæ7F–öâ…òÂWfVçBÂâââ¢–bWfVçBÓÒ%Tä•EôU$"F†Và¢Æö6ÂVæ—BÒââà¢ÒÒ7FVÇF‚ö–çf—6–&–Æ—G’6†ævW2&RÆ–W"ÖöæÇ’f÷"F†—2FFöââFð¢ÒÒæ÷Bv¶RF†R6†&VBWfÇVF÷"f÷"WfW'’'G’öæÖWÆFRW&à¢–bG—R‡Væ—B’ãÒ'7G&–ær"÷"—56V7&WB‡Væ—B’÷"Væ—BãÒ'Æ–W""F†Vâ&WGW&âVæ@¢Væ@¢–bWfVçC¦ÖF6‚‚%åTä•Eõ5TÄÄ45Eò"’F†Và¢Æö6ÂVæ—BÒââà¢–bG—R‡Væ—B’ÓÒ'7G&–ær"æBæ÷B—56V7&WB‡Væ—B’æBVæ—BÓÒ'Æ–W""F†Và¢–bWfVçBÓÒ%Tä•Eõ5TÄÄ45Eõ5D%B"÷"WfVçBÓÒ%Tä•Eõ5TÄÄ45Eô4„ääTÅõ5D%B ¢÷"WfVçBÓÒ%Tä•Eõ5TÄÄ45EôTÕõtU%õ5D%B"F†Và¢'VçF–ÖRçÆ–W$67F–ærÒG'VP¢VÇ6V–bWfVçBÓÒ%Tä•Eõ5TÄÄ45Eõ5Dõ"÷"WfVçBÓÒ%Tä•Eõ5TÄÄ45Eôd”ÄTB ¢÷"WfVçBÓÒ%Tä•Eõ5TÄÄ45Eôd”ÄTEõT”UB"÷"WfVçBÓÒ%Tä•Eõ5TÄÄ45Eô”åDU%%UDTB ¢÷"WfVçBÓÒ%Tä•Eõ5TÄÄ45Eô4„ääTÅõ5Dõ"÷"WfVçBÓÒ%Tä•Eõ5TÄÄ45EôTÕõtU%õ5Dõ"F†Và¢'VçF–ÖRçÆ–W$67F–ærÒfÇ6P¢Væ@¢ÒÒ6öÖR7F÷÷7F'B—'2'&—fR–âF†R6ÖRWFFR†f÷"W†×ÆRv†Vâ¢ÒÒæ÷&ÖÂ67BfÆ÷w2–çFò6†ææVÂ’â&R×&VBöâF†RæW‡Bg&ÖR6òF†P¢ÒÒ6öæF—F–öâ&VfÆV7G2F†RÆ–W"w2f–æÂ67F–ær7FFRÂæ÷BWfVçB÷&FW"à¢5õF–ÖW"ägFW"ƒÂ&Vg&W6…Æ–W$67F–æu7FFR¢Væ@¢Væ@¢–bWfVçBÓÒ%Ä”U%ôÄôt”â"F†Và¢&–÷&—G”fFW$D"Ò6÷”FVfVÇG2„DTdTÅE2Â&–÷&—G”fFW$D"¢ç3¤Ö–w&FTFF&6R‚¢–bç2å&Vv—7FW%7F÷&VD7W7FöÔg&ÖW2F†Vâç3¥&Vv—7FW%7F÷&VD7W7FöÔg&ÖW2‚’Væ@¢ç3¤Vç7W&T6–æVÖF–5&öf–ÆR‚¢–bç2å&Vg&W6„6–æVÖF–4ÆWGFW&&÷‚F†Vâç3¥&Vg&W6„6–æVÖF–4ÆWGFW&&÷‚‚’Væ@¢–bç2å&Vg&W6„õ–Tg&ÖW2F†Vâç3¥&Vg&W6„õ–Tg&ÖW2‚’Væ@¢ç3¥&Vv—7FW$6–æVÖF–5T”ÖöFR‚¢ç3¤Vç7W&T6öææV7FVD†÷fW%'VÆW2‚¢&Vg&W6…Æ–W$67F–æu7FFR‚¢ç3¥v¶R‚¢ç3¤7&VFT÷F–öç2‚¢–bç3¤—46–æVÖF–47F—fR‚’F†Và¢ç3¥&–ÖT6–æVÖF–5F&vWG2‚¢ç3¥6WD6–æVÖF–5T”ÖöFR†ç3¤6åW6T6–æVÖF–4æF—fTÖöFR‚’¢ç3¤&Vv–ä6–æVÖF–4&Æ6¶÷WB‚¢Væ@¢&WGW&à¢Væ@¢–bWfVçBÓÒ$DDôåôÄôDTB"F†Và¢–bç2å&Vg&W6„õ–Tg&ÖW2F†Vâç3¥&Vg&W6„õ–Tg&ÖW2‚’Væ@¢–bç3¤—46–æVÖF–47F—fR‚’æBæ÷B–ä6öÖ&DÆö6¶F÷vâ‚’F†Và¢ÒÒÆöBÖöâÖFVÖæBFFöç2ögFVâ'&—fR–â'W'7G2â6öÆW66RF†VÒ6ð¢ÒÒ6–æVÖF–2F—66÷fW'2F†V—"&ö÷G2öæ6RgFW"F†R'W'7B–ç7FVBö`¢ÒÒ&W66ææ–ærF†RVçF—&RT’Gv–6Rf÷"WfW'’DDôåôÄôDTBWfVçBà¢'VçF–ÖRæ6–æVÖF–5&W66åFö¶VâÒ‡'VçF–ÖRæ6–æVÖF–5&W66åFö¶Vâ÷"’²¢Æö6ÂFö¶VâÒ'VçF–ÖRæ6–æVÖF–5&W66åFö¶Và¢5õF–ÖW"ägFW"ƒã3RÂgVæ7F–öâ‚¢–bFö¶VâÓÒ'VçF–ÖRæ6–æVÖF–5&W66åFö¶VâæBç3¤—46–æVÖF–47F—fR‚¢æBæ÷B–ä6öÖ&DÆö6¶F÷vâ‚’F†Vâç3¤&Vv–ä6–æVÖF–4&Æ6¶÷WB‚’Væ@¢VæB¢Væ@¢Væ@¢–bWfVçBÓÒ%Ä”U%ôTåDU$”äuõtõ$ÄB"F†Vâ&Vg&W6…Æ–W$67F–æu7FFR‚’Væ@¢–bç2ä6æ6VÅ–6¶W"æB†WfVçBÓÒ%Ä”U%õ$TtTåôD•4$ÄTB"÷"WfVçBÓÒ%Ä”U%ôTåDU$”äuõtõ$ÄB"÷"WfVçBÓÒ%UEô$EDÄUôõTä”äuõ5D%B"’F†Và¢ç3¤6æ6VÅ–6¶W"†WfVçBÓÒ%Ä”U%õ$TtTåôD•4$ÄTB"æB&6öÖ&B"÷"&–çFW''WFVB"¢Væ@¢–bWfVçBÓÒ%Ä”U%õ$TtTåôD•4$ÄTB"æBç2äöåGWF÷&–Ä6öÖ&E7FFT6†ævVBF†Và¢ç3¤öåGWF÷&–Ä6öÖ&E7FFT6†ævVB‡G'VR¢VÇ6V–bWfVçBÓÒ%Ä”U%õ$TtTåôTä$ÄTB"æBç2äöåGWF÷&–Ä6öÖ&E7FFT6†ævVBF†Và¢ç3¤öåGWF÷&–Ä6öÖ&E7FFT6†ævVB†fÇ6R¢VÇ6V–b†WfVçBÓÒ%Ä”U%ôTåDU$”äuõtõ$ÄB"÷"WfVçBÓÒ%UEô$EDÄUôõTä”äuõ5D%B"’æBç2ä6æ6VÅGWF÷&–ÂF†Và¢ç3¤6æ6VÅGWF÷&–Â‚&–çFW''WFVB"¢Væ@¢–bWfVçBÓÒ%Ä”U%õ$TtTåôD•4$ÄTB"æBç2ä6–æVÖF–4¶W”6GW&RæBç2ä6–æVÖF–4¶W”6GW&S¤—56†÷vâ‚’F†Và¢ç2ä6–æVÖF–4¶W”6GW&S¤†–FR‚¢Væ@¢–bWfVçBÓÒ$4„EôÕ4uôÄôõB"æB—4Æö6ÄÆö÷DÖW76vR‡6VÆV7Bƒ"Ââââ’Â6VÆV7Bƒ"Ââââ’’F†Và¢'VçF–ÖRæÖöÖVçG2æÆö÷BÒvWEF–ÖR‚¢Væ@¢Æö6ÂÖöÖVçBÒUdTåEõDõôÔôÔTåE¶WfVçEÐ¢–bG—R†ÖöÖVçB’ÓÒ'F&ÆR"F†Và¢Æö6Âæ÷rÒvWEF–ÖR‚¢f÷"òÂÖöÖVçD”B–â——'2†ÖöÖVçB’Fò'VçF–ÖRæÖöÖVçG5¶ÖöÖVçD”EÒÒæ÷rVæ@¢VÇ6V–bÖöÖVçBF†Và¢'VçF–ÖRæÖöÖVçG5¶ÖöÖVçEÒÒvWEF–ÖR‚¢Væ@¢–bWfVçBÓÒ%Ä”U%õ$TtTåôTä$ÄTB"F†Và¢ç3¥&W7F÷&UVæF–ætÇ†2‚¢–bç3¤—46–æVÖF–47F—fR‚’F†Vâç3¤&Vv–ä6–æVÖF–4&Æ6¶÷WB‚’Væ@¢Væ@¢–bWfVçBÓÒ%Ä”U%ôTåDU$”äuõtõ$ÄB"æBç3¤—46–æVÖF–47F—fR‚’æBæ÷B–ä6öÖ&DÆö6¶F÷vâ‚’F†Và¢ç3¤&Vv–ä6–æVÖF–4&Æ6¶÷WB‚¢Væ@¢–bWfVçBÓÒ%UDDUô$”äD”äu2"æBç2ä÷F–öç2æBç2ä÷F–öç3¤—56†÷vâ‚’F†Và¢ç3¥&VæFW$÷F–öç2‚¢Væ@¢ç3¥v¶R‚¢ÒÒF†R÷F–öâæVÂWFFW2—G2Æ—fR×7FFR6†—g&öÒF–6²â&V'V–ÆF–ær—G0¢ÒÒG–æÖ–2&÷w2f÷"WfW'’vÖRWfVçBv÷VÆB6öçF–çVÆÇ’7&VFR†–FFVâT¢ÒÒö&¦V7G2Â6òöæÇ’W‡Æ–6—BVF—F÷"7F–öç2&VG&r—Bà¦VæB ¥4Ä4…õ$”õ$•E”dDU#Ò"÷fFW" ¥4Ä4…õ$”õ$•E”dDU#"Ò"÷&–÷&—G–fFW" ¥4Ä4…õ$”õ$•E”dDU#2Ò"ög&ÖVvÖ&—B ¥4Ä4…õ$”õ$•E”dDU#BÒ"öfvÖ&—B ¥4Ä4…õ$”õ$•E”dDU#RÒ"öfr ¦gVæ7F–öâ&–÷&—G”fFW%õFövvÆT6–æVÖF–2‚¢Æö6Âö²Â&V6öâÂVæ&ÆVBÒç3¥FövvÆT6–æVÖF–2‚¢–bæ÷Bö²æBDTdTÅEô4„Eôe$ÔRæBDTdTÅEô4„Eôe$ÔRäFDÖW76vRF†Và¢DTdTÅEô4„Eôe$ÔS¤FDÖW76vR‚'Æ6fc”CsTddg&ÖRvÖ&—GÇ""ââF÷7G&–ær‡&V6öâ÷"$6–æVÖF–2ÖöFR6÷VÆBæ÷B&RFövvÆVBâ"’¢VÇ6V–bö²æBç2ä÷F–öç2æBç2ä÷F–öç2æ7F—fRF†Và¢ç2ä÷F–öç2æ7F—fS¥6WEFW‡B†Væ&ÆVBæB$6–æVÖF–2ÖöFRöâ"÷"$6–æVÖF–2ÖöFRöfb"¢ç2ä÷F–öç2æ7F—fS¥6WEFW‡D6öÆ÷"‡Vç6²†ç2ä4ôÄõ%2çFVÂ’¢Væ@¦Væ@ ¥6Æ6„6ÖDÆ—7Bå$”õ$•E”dDU"ÒgVæ7F–öâ†ÖW76vR¢Æö6Â6öÖÖæBÒ†ÖW76vR÷"""“¦ÖF6‚‚%âW2¢‚âÒ’W2¢B"“¦Æ÷vW"‚¢–b6öÖÖæBÓÒ'–6²"F†Và¢ç3¥7F'E–6¶W"‚¢VÇ6V–b6öÖÖæBÓÒ&VF—B"÷"6öÖÖæBÓÒ'7FGW2"F†Và¢ç3¥'VäF–væ÷7F–72‚¢VÇ6V–b6öÖÖæBÓÒ&6–æVÖF–2"÷"6öÖÖæBÓÒ&6–æVÖ"F†Và¢&–÷&—G”fFW%õFövvÆT6–æVÖF–2‚¢VÇ6P¢ç3¥FövvÆT÷F–öç2‚¢Væ@¦Væ@