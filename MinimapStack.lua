local ADDON, ns = ...

-- Some Minimap descendants deliberately ignore parent alpha (notably pooled
-- pins and addon chrome), while EUI can keep its grouped addon-button panel as
-- a UIParent sibling. The normal Minimap target remains the real Minimap frame
-- for Cinematic ownership and hover behavior. This helper only composes its PF
-- opacity onto visuals that can escape that parent fade.

local owned = setmetatable({}, { __mode = "k" })
local hostAlpha = setmetatable({}, { __mode = "k" })
local appliedAlpha = setmetatable({}, { __mode = "k" })
local guarded = setmetatable({}, { __mode = "k" })
local hooked = setmetatable({}, { __mode = "k" })
local pending = setmetatable({}, { __mode = "k" })
local hoverExcluded = setmetatable({}, { __mode = "k" })
local multiplier = 1
local scan
local nativeMarkerScale
local nativeMarkerWanted
-- The native marker compositor is separate from the Minimap alpha tree. Keep
-- its baseline unknown by default: some layouts use a non-default icon scale
-- and SetIconScale has no portable getter. Only an explicitly selected
-- experimental mode may opt into the documented 100% fallback.
local nativeMarkerHostScale
local nativeMarkerBaselineAssumed = false
local nativeMarkerMode
local nativeMarkerAlpha = 1
local nativeMarkerGuard = false
local nativeMarkerHooked = false
local nativeMarkerAuditAt = 0
local nativeMarkerRestorePending = false
-- Quest areas are rendered by a separate native blob-ring compositor. They
-- do not obey Minimap alpha or SetIconScale, so keep an independent, guarded
-- alpha lease for the three related Blizzard ring surfaces.
local nativeRingHostAlpha = {}
local nativeRingAppliedAlpha = {}
local nativeRingBaselineAssumed = {}
local nativeRingHooked = {}
local nativeRingGuard = false
local nativeRingAuditAt = 0
local nativeRingRestorePending = false

local NATIVE_RING_ALPHA_SETTERS = {
    "SetArchBlobRingAlpha",
    "SetQuestBlobRingAlpha",
    "SetTaskBlobRingAlpha",
}

ns.MINIMAP_NATIVE_MARKER_MODES = {
    keep = "Leave unchanged",
    hide_zero = "Hide at 0%",
    scale = "Scale with map",
}
ns.MINIMAP_NATIVE_MARKER_ORDER = { "keep", "hide_zero", "scale" }

local function IsSecret(value)
    return issecretvalue and issecretvalue(value) or false
end

local function ValidAlpha(value)
    return type(value) == "number" and not IsSecret(value) and value == value
        and value >= 0 and value <= 1
end

-- Unlike alpha, an icon scale is not bounded to 1.  Keep the validation
-- intentionally permissive so a host's legitimate large scale survives our
-- temporary compositor override and its later restoration.
local function ValidScale(value)
    return type(value) == "number" and not IsSecret(value) and value == value
        and value >= 0 and value < math.huge
end

local function Method(object, name, ...)
    if not object then return nil end
    local okMethod, callback = pcall(function() return object[name] end)
    if not okMethod or type(callback) ~= "function" then return nil end
    local ok, value = pcall(callback, object, ...)
    if not ok or IsSecret(value) then return nil end
    return value
end

local function Alpha(frame)
    local value = Method(frame, "GetAlpha")
    return ValidAlpha(value) and value or nil
end

local function SetAlpha(frame, value)
    if not ValidAlpha(value) then return false end
    guarded[frame] = true
    local ok = pcall(function() frame:SetAlpha(value) end)
    guarded[frame] = nil
    if ok then appliedAlpha[frame] = value end
    return ok
end

local function Apply(frame)
    local base = hostAlpha[frame]
    return owned[frame] and ValidAlpha(base) and SetAlpha(frame, base * multiplier) or false
end

local function HostAlphaChanged(frame, value)
    if guarded[frame] or not owned[frame] then return end
    if not ValidAlpha(value) then
        Apply(frame)
        return
    end
    hostAlpha[frame] = value
    Apply(frame)
end

local function Hook(frame)
    if hooked[frame] or type(hooksecurefunc) ~= "function" then return end
    if pcall(hooksecurefunc, frame, "SetAlpha", function(_, value) HostAlphaChanged(frame, value) end) then
        hooked[frame] = true
    end
end

local function Claim(frame)
    if not frame or owned[frame] then return end
    local base = Alpha(frame)
    if base == nil then return end
    local restore = pending[frame]
    if restore then
        if math.abs(base - restore.lastApplied) <= 0.001 then base = restore.base end
        pending[frame] = nil
    end
    owned[frame] = true
    hostAlpha[frame] = base
    Hook(frame)
    Apply(frame)
end

local function Release(frame)
    if not owned[frame] then return end
    local base, last = hostAlpha[frame], appliedAlpha[frame]
    local live = Alpha(frame)
    if base ~= nil and last ~= nil and live ~= nil and math.abs(live - last) <= 0.001 then
        if not SetAlpha(frame, base) then pending[frame] = { base = base, lastApplied = last } end
    elseif live == nil and base ~= nil and last ~= nil then
        pending[frame] = { base = base, lastApplied = last }
    end
    owned[frame] = nil
    hostAlpha[frame] = nil
    appliedAlpha[frame] = nil
end

local function IsDescendant(frame, ancestor)
    local current, seen, depth = frame, {}, 0
    while current and depth < 20 and not seen[current] do
        if current == ancestor then return true end
        seen[current] = true
        current = Method(current, "GetParent")
        depth = depth + 1
    end
    return false
end

local function Children(frame)
    if not frame then return {} end
    local okMethod, callback = pcall(function() return frame.GetChildren end)
    if not okMethod or type(callback) ~= "function" then return {} end
    local values = { pcall(callback, frame) }
    if not table.remove(values, 1) then return {} end
    return values
end

local function Regions(frame)
    if not frame then return {} end
    local okMethod, callback = pcall(function() return frame.GetRegions end)
    if not okMethod or type(callback) ~= "function" then return {} end
    local values = { pcall(callback, frame) }
    if not table.remove(values, 1) then return {} end
    return values
end

local function VisualChildren(frame)
    local values = Children(frame)
    for _, region in ipairs(Regions(frame)) do values[#values + 1] = region end
    return values
end

local function AddEUIFlyoutPanels(result, minimap)
    -- EUI's grouped addon buttons can live in one anonymous UIParent flyout
    -- rather than beneath Minimap. Claim that small shared panel, not each
    -- button and not an arbitrary addon's original UI root.
    local parents = {}
    for _, button in pairs(type(_G._EBS_CachedAddonButtons) == "table" and _G._EBS_CachedAddonButtons or {}) do
        local parent = Method(button, "GetParent")
        if parent and parent ~= UIParent and not IsDescendant(parent, minimap)
            and Method(parent, "GetParent") == UIParent and Method(parent, "GetName") == nil
            and Method(parent, "GetFrameStrata") == "DIALOG" then
            parents[parent] = (parents[parent] or 0) + 1
        end
    end
    for parent, count in pairs(parents) do
        -- Requiring a shared anonymous direct UIParent parent prevents a stale
        -- cached button from making PF claim an unrelated addon container.
        if count >= 1 then
            result[parent] = true
            -- The panel itself inherits PF's multiplier, but some third-party
            -- buttons deliberately ignore parent alpha. Lease only those
            -- escapees (and nested escapees), avoiding a double multiplier on
            -- ordinary children that already inherit the panel correctly.
            local queue, seen, index = VisualChildren(parent), {}, 1
            while index <= #queue and index <= 256 do
                local child = queue[index]
                index = index + 1
                if child and not seen[child] then
                    seen[child] = true
                    if Method(child, "IsIgnoringParentAlpha") == true then result[child] = true end
                    for _, nested in ipairs(VisualChildren(child)) do
                        if not seen[nested] then queue[#queue + 1] = nested end
                    end
                end
            end
        end
    end
end

local function HasClaimedAncestor(result, frame)
    local current, seen, depth = Method(frame, "GetParent"), {}, 0
    while current and depth < 20 and not seen[current] do
        if result[current] then return true end
        seen[current] = true
        current = Method(current, "GetParent")
        depth = depth + 1
    end
    return false
end

local function AddSemanticFrame(result, frame, minimap)
    if not frame or frame == minimap then return end
    local ignoresParent = Method(frame, "IsIgnoringParentAlpha") == true
    -- Ordinary Minimap children already inherit its opacity. Only claim the
    -- unusual children that explicitly opt out of parent alpha.
    if IsDescendant(frame, minimap) then
        if ignoresParent then result[frame] = true end
        return
    end
    -- If a semantic container is already leased, its normal descendants must
    -- not receive the multiplier twice. Descendants that ignore parent alpha
    -- remain separate leases by design.
    if HasClaimedAncestor(result, frame) then
        if ignoresParent then result[frame] = true end
        return
    end
    result[frame] = true
end

local function AddAlphaEscapingDescendants(result, root, minimap)
    -- Super Tracking owns a small, UIParent-level directional presentation.
    -- Its individual native regions can opt out of their root's alpha, so a
    -- root-only lease leaves the clamped quest-direction arc visible when the
    -- Minimap rests at zero. Walk only this known, narrow tree and claim those
    -- explicit alpha escapees; normal children still inherit the root once.
    local queue, seen, index = VisualChildren(root), {}, 1
    while index <= #queue and index <= 96 do
        local child = queue[index]
        index = index + 1
        if child and not seen[child] then
            seen[child] = true
            if Method(child, "IsIgnoringParentAlpha") == true then
                AddSemanticFrame(result, child, minimap)
            end
            for _, nested in ipairs(VisualChildren(child)) do
                if not seen[nested] then queue[#queue + 1] = nested end
            end
        end
    end
end

local function AddSemanticMinimapFrames(result, minimap)
    AddEUIFlyoutPanels(result, minimap)

    -- Retail's visible minimap is not one alpha tree. Mail, tracking and other
    -- indicators are commonly siblings of Minimap under MinimapCluster.
    local cluster = _G.MinimapCluster
    local indicator = cluster and cluster.IndicatorFrame
    AddSemanticFrame(result, indicator, minimap)
    AddSemanticFrame(result, cluster and cluster.Tracking, minimap)
    AddSemanticFrame(result, cluster and cluster.InstanceDifficulty, minimap)

    -- Stable Blizzard minimap surfaces which may move between Minimap,
    -- MinimapCluster and UIParent across layouts/skins.
    local known = {
        _G.AddonCompartmentFrame,
        _G.ExpansionLandingPageMinimapButton,
        _G.QueueStatusButton,
        _G.GameTimeFrame,
        _G.MiniMapTracking,
        _G.MiniMapMailFrame,
    }
    for _, frame in ipairs(known) do AddSemanticFrame(result, frame, minimap) end

    -- The navigation/super-tracking presentation is a UIParent root rather
    -- than a Minimap child. It belongs to the same visual stack but must not
    -- enlarge the minimap's mouseover hit area if Blizzard gives it a broad
    -- layout rectangle.
    local superTracked = _G.SuperTrackedFrame
    AddSemanticFrame(result, superTracked, minimap)
    if superTracked then
        hoverExcluded[superTracked] = true
        AddAlphaEscapingDescendants(result, superTracked, minimap)
    end

    -- LibDBIcon is the canonical registry for third-party minimap buttons.
    -- Querying its object table is both cheaper and more accurate than guessing
    -- ownership from names or screen position after another addon reparents it.
    local lib
    if type(_G.LibStub) == "table" or type(_G.LibStub) == "function" then
        local ok, value = pcall(_G.LibStub, "LibDBIcon-1.0", true)
        if ok and type(value) == "table" then lib = value end
    end
    for _, button in pairs(lib and type(lib.objects) == "table" and lib.objects or {}) do
        AddSemanticFrame(result, button, minimap)
    end

    -- EUI publishes the buttons it has collected even while their current
    -- parent changes between Minimap and its anonymous flyout.
    for _, button in pairs(type(_G._EBS_CachedAddonButtons) == "table" and _G._EBS_CachedAddonButtons or {}) do
        AddSemanticFrame(result, button, minimap)
    end
end

local function BeginScan(minimap)
    -- Minimap POIs are frequently Texture/Region objects rather than child
    -- Frames. Some deliberately ignore their pin or Minimap parent's alpha.
    -- Regions still expose GetAlpha/SetAlpha and can safely participate in the
    -- same composed visibility lease.
    scan = { minimap = minimap, queue = VisualChildren(minimap), index = 1, seen = {}, found = {} }
    AddSemanticMinimapFrames(scan.found, minimap)
end

local function ContinueScan(minimap)
    if not scan or scan.minimap ~= minimap then BeginScan(minimap) end
    local processed = 0
    local started = type(debugprofilestop) == "function" and debugprofilestop() or nil
    while scan.index <= #scan.queue and processed < 48
        and (processed == 0 or not started or debugprofilestop() - started < 0.60) do
        local child = scan.queue[scan.index]
        scan.index = scan.index + 1
        processed = processed + 1
        if child and not scan.seen[child] then
            scan.seen[child] = true
            if Method(child, "IsIgnoringParentAlpha") == true then scan.found[child] = true end
            for _, nested in ipairs(VisualChildren(child)) do
                if not scan.seen[nested] then scan.queue[#scan.queue + 1] = nested end
            end
        end
    end
    if scan.index <= #scan.queue then return nil end
    AddSemanticMinimapFrames(scan.found, minimap)
    local result = scan.found
    scan = nil
    return result
end

local function ProcessPending()
    if InCombatLockdown() then return end
    for frame, record in pairs(pending) do
        local live = Alpha(frame)
        if live ~= nil and math.abs(live - record.lastApplied) > 0.001 then
            pending[frame] = nil
        elseif live ~= nil and SetAlpha(frame, record.base) then
            pending[frame] = nil
            appliedAlpha[frame] = nil
        end
    end
end

local function ReadNativeMarkerScale(minimap)
    -- GetIconScale is available on current Retail builds, but it is deliberately
    -- optional here: UI skins and older client variants do not all publish it.
    -- A future host SetIconScale call is the other authoritative sourcзЛh‘йм¶»§q«^t][
B€Y€]]™SX\љЩ\’ЬЭШШ[HЏHљ[[€™]\›€]]™SX\љЩ\’ЬЭШШ[H[™€ШШ[[YHH™XY]]™SX\љЩ\”ШШ[JZ[љ[X\
B€Y€[YHЏHљ[[‚€]]™SX\љЩ\’ЬЭШШ[HH[YB€]]™SX\љЩ\ђ\Щ[[™P\ЬЭ[YYH[ЩB€[ЩZY€[ЭР\ЬЭ[YYY][[‚€KHЫЫYH™]Z[ќZ[И^ЬЩHЫ›HЩ]XЫЫ”ШШ[K€Щ[XЭ[™И[‚€KH^\љ[Y[ќ[X\љЩ\€[ЩH\ИH\Щ\‰ЬИ^XЪ]ЬZ[€И\ЩHB€KH]]™HL	HШШ[H\ИH[\Ь\ћH™\ЭЬ][Ы€\Щ[[™K€B€KHY][“X]™H[Ъ[™ЩY€[ЩH™]™\€™XXЪ\И\И]‚€]]™SX\љЩ\’ЬЭШШ[HHB€]]™SX\љЩ\ђ\Щ[[™P\ЬЭ[YYHќYB€[™€™]\›€]]™SX\љЩ\’ЬЭШШ[B™[™‚›ШШ[ќ[Э[Ы€\У]]™SX\љЩ\”Щ]\ЉZ[љ[X\
B€Y€›ЭZ[љ[X\[€™]\›€[ЩH[™€ШШ[ЪЛЩ]\€HШ[
ќ[Э[ЫЉ
H™]\›€Z[љ[X\”Щ]XЫЫ”ШШ[H[™
B€™]\›€ЪИ[™\JЩ]\ЉHOH™ќ[Э[Ы€‚™[™‚›ШШ[ќ[Э[Ы€Щ]]]™SX\љЩ\”ШШ[JZ[љ[X\[YJB€Y€›ЭZ[љ[X\Ь€›Э[YШШ[J[YJH[€™]\›€[ЩH[™€ШШ[ЪУY]ЩЩ]\€HШ[
ќ[Э[ЫЉ
H™]\›€Z[љ[X\”Щ]XЫЫ”ШШ[H[™
B€Y€›ЭЪУY]ЩЬ€\JЩ]\ЉHЏH™ќ[Э[Ы€€[€™]\›€[ЩH[™€]]™SX\љЩ\‘ЭX\™HќYB€ШШ[ЪИHШ[
Щ]\‹Z[љ[X\[YJB€]]™SX\љЩ\‘ЭX\™H[ЩB€™]\›€ЪВ™[™‚›ШШ[ќ[Э[Ы€]]™Tљ[™СЩ]\“[YJЩ]\“[YJB€™]\›€‘Щ]€‹€Щ]\“[YNњЭXЉ
B™[™‚›ШШ[ќ[Э[Ы€Ш\\™S]]™Tљ[™ТЬЭ[JZ[љ[X\Щ]\“[YK[ЭР\ЬЭ[YYY][
B€ШШ[Ы›ЭЫ€H]]™Tљ[™ТЬЭ[VЬЩ]\“[YWB€Y€Ы›ЭЫ€ЏHљ[[€™]\›€Ы›ЭЫ€[™€ШШ[[YHHY]Щ
Z[љ[X\]]™Tљ[™СЩ]\“[YJЩ]\“[YJJB€Y€[Y[J[YJH[‚€]]™Tљ[™ТЬЭ[VЬЩ]\“[YWHH[YB€]]™Tљ[™Р\Щ[[™P\ЬЭ[YYЬЩ]\“[YWHHљ[€[ЩZY€[ЭР\ЬЭ[YYY][[‚€KH\ЩHT\ИИ›ЭЫЫњЪ\Э[ќH›ЭљYHЩ]\њЛ€^\љ[Y[ќ[X\љЩ\‚€KH[Щ\И\ЩHHШ[YH^XЪ]L	H[XЪИ\ИЩ]XЫЫ”ШШ[H[ќ[B€KHЬЭ[››Э[Щ\ИH™X[љ[™И[H›ЭYЪ]ИЩ]\‹‚€]]™Tљ[™ТЬЭ[VЬЩ]\“[YWHHB€]]™Tљ[™Р\Щ[[™P\ЬЭ[YYЬЩ]\“[YWHHќYB€[™€™]\›€]]™Tљ[™ТЬЭ[VЬЩ]\“[YWB™[™‚›ШШ[ќ[Э[Ы€Щ]]]™Tљ[™Р[JZ[љ[X\Щ]\“[YK[YJB€Y€›ЭZ[љ[X\Ь€›Э[Y[J[YJH[€™]\›€[ЩH[™€ШШ[ЪУY]ЩЩ]\€HШ[
ќ[Э[ЫЉ
H™]\›€Z[љ[X\ЬЩ]\“[YWH[™
B€Y€›ЭЪУY]ЩЬ€\JЩ]\ЉHЏH™ќ[Э[Ы€€[€™]\›€[ЩH[™€]]™Tљ[™СЭX\™HќYB€ШШ[ЪИHШ[
Щ]\‹Z[љ[X\[YJB€]]™Tљ[™СЭX\™H[ЩB€™]\›€ЪВ™[™‚›ШШ[ќ[Э[Ы€]]™Tљ[™ХШ[ќY
ЬЭ[K[K[ЩJB€Y€[ЩHOHњШШ[H€[€™]\›€ЬЭ[H
€[H[™€Y€[ЩHOHљYWЮ™\›И€[€™]\›€[HHЊH[™Ь€ЬЭ[H[™™[™‚›ШШ[ќ[Э[Ы€ЫЪУ]]™SX\љЩ\”љ[™ЬКZ[љ[X\
B€Y€›ЭZ[љ[X\Ь€\JЫЪЬЩXЭ\™Yќ[КHЏH™ќ[Э[Ы€€[€™]\›€[™€›Ь€ЛЩ]\“[YH[€\Z\њКђUU‘WФ’S‘ЧРSWФСUT”КHВ€Y€›Э]]™Tљ[™ТЫЪЩYЬЩ]\“[YWH[‚€ШШ[ЪИHШ[
ЫЪЬЩXЭ\™Yќ[ЛZ[љ[X\Щ]\“[YKќ[Э[ЫЉЛ[YJB€Y€]]™Tљ[™СЭX\™Ь€›Э[Y[J[YJH[€™]\›€[™€]]™Tљ[™ТЬЭ[VЬЩ]\“[YWHH[YB€]]™Tљ[™Р\Щ[[™P\ЬЭ[YYЬЩ]\“[YWHHљ[€]]™Tљ[™Р\YY[VЬЩ]\“[YWHH[YB€]]™Tљ[™Ф™\ЭЬ™T[™[™ИH[ЩB€ШШ[Ш[ќYH]]™Tљ[™ХШ[ќY
[YK]]™SX\љЩ\ђ[K]]™SX\љЩ\“[ЩJB€Y€Ш[ќYЏHљ[[™X]XњК[YHHШ[ќY
H€ЊB€[™Щ]]]™Tљ[™Р[JZ[љ[X\Щ]\“[YKШ[ќY
H[‚€]]™Tљ[™Р\YY[VЬЩ]\“[YWHHШ[ќY€]]™Tљ[™Р]Y]]HЩ][YJ
B€[™€[™
B€Y€ЪИ[€]]™Tљ[™ТЫЪЩYЬЩ]\“[YWHHќYH[™€[™€[™™[™‚›ШШ[ќ[Э[Ы€™\ЭЬ™S]]™SX\љЩ\”љ[™ЬКZ[љ[X\
B€Y€™^
]]™Tљ[™Р\YY[JHOHљ[[‚€]]™Tљ[™Ф™\ЭЬ™T[™[™ИH[ЩB€]]™Tљ[™Р]Y]]H€™]\›€ќYB€[™€ШШ[ЫЫ\]HHќYB€›Ь€Щ]\“[YK\YY[€Z\њК]]™Tљ[™Р\YY[JHВ€ШШ[™\ЭЬ™HHШ\\™S]]™Tљ[™ТЬЭ[JZ[љ[X\Щ]\“[YJB€Y€™\ЭЬ™HOHљ[[‚€ЫЫ\]HH[ЩB€[ЩZY€X]XњК\YYH™\ЭЬ™JH€ЊH[™›ЭЩ]]]™Tљ[™Р[JZ[љ[X\Щ]\“[YK™\ЭЬ™JH[‚€ЫЫ\]HH[ЩB€[ЩB€]]™Tљ[™Р\YY[VЬЩ]\“[YWHHљ[€[™€[™€]]™Tљ[™Ф™\ЭЬ™T[™[™ИH›ЭЫЫ\]B€Y€ЫЫ\]H[€]]™Tљ[™Р]Y]]H[™€™]\›€ЫЫ\]B™[™‚›ШШ[ќ[Э[Ы€\]S]]™SX\љЩ\”љ[™ЬКZ[љ[X\[K[ЩJB€Y€[ЩHЏHљYWЮ™\›И€[™[ЩHЏHњШШ[H€[‚€™\ЭЬ™S]]™SX\љЩ\”љ[™ЬКZ[љ[X\
B€™]\›‚€[™€ЫЪУ]]™SX\љЩ\”љ[™ЬКZ[љ[X\
B€ШШ[›ЭИHЩ][YJ
B€›Ь€ЛЩ]\“[YH[€\Z\њКђUU‘WФ’S‘ЧРSWФСUT”КHВ€ШШ[ЬЭ[HHШ\\™S]]™Tљ[™ТЬЭ[JZ[љ[X\Щ]\“[YKќYJB€ШШ[Ш[ќYHЬЭ[H[™]]™Tљ[™ХШ[ќY
ЬЭ[K[K[ЩJB€ШШ[\YYH]]™Tљ[™Р\YY[VЬЩ]\“[YWB€KH]]™HX\™XќZ[ИШ[€™\ЭЬ™HH›Ш€љ[™ИЪ]Э]Ш[[™И]ИXB€KHЩ]\‹€™X\ЬЩ\ќЫ›HЪ[HHќ[HYYZ[љ[X\™YYИ]Y[‹‚€ШШ[]Y]YHHШ[ќY[™Ш[ќYHЊH[™›ЭИH]]™Tљ[™Р]Y]]ЏHЊЌB€Y€Ш[ќYЏHљ[[™
]Y]YHЬ€\YYOHљ[Ь€X]XњК\YYHШ[ќY
H€ЊJB€[™Щ]]]™Tљ[™Р[JZ[љ[X\Щ]\“[YKШ[ќY
H[‚€]]™Tљ[™Р\YY[VЬЩ]\“[YWHHШ[ќY€]]™Tљ[™Р]Y]]H›ЭВ€[™€[™€]]™Tљ[™Ф™\ЭЬ™T[™[™ИH[ЩB™[™‚›ШШ[ќ[Э[Ы€ЫЪУ]]™SX\љЩ\њКZ[љ[X\
B€Y€]]™SX\љЩ\’ЫЪЩYЬ€›ЭZ[љ[X\Ь€\JЫЪЬЩXЭ\™Yќ[КHЏH™ќ[Э[Ы€€[€™]\›€[™€ШШ[ЪИHШ[
ЫЪЬЩXЭ\™Yќ[ЛZ[љ[X\”Щ]XЫЫ”ШШ[H‹ќ[Э[ЫЉЛ[YJB€Y€]]™SX\љЩ\‘ЭX\™Ь€›Э[YШШ[J[YJH[€™]\›€[™€]]™SX\љЩ\’ЬЭШШ[HH[YB€]]™SX\љЩ\ђ\Щ[[™P\ЬЭ[YYH[ЩB€]]™SX\љЩ\”ШШ[HH[YB€]]™SX\љЩ\”™\ЭЬ™T[™[™ИH[ЩB€ШШ[Ш[ќY€Y€]]™SX\љЩ\“[ЩHOHњШШ[H€[‚€Ш[ќYH[YH
€]]™SX\љЩ\ђ[B€[ЩZY€]]™SX\љЩ\“[ЩHOHљYWЮ™\›И€[‚€Ш[ќYH]]™SX\љЩ\ђ[HHЊH[™Ь€[YB€[™€]]™SX\љЩ\•Ш[ќYHШ[ќY€Y€Ш[ќYЏHљ[[™X]XњК[YHHШ[ќY
H€ЊH[‚€Y€Щ]]]™SX\љЩ\”ШШ[JZ[љ[X\Ш[ќY
H[‚€]]™SX\љЩ\”ШШ[HHШ[ќY€]]™SX\љЩ\ђ]Y]]HЩ][YJ
B€[™€[™€[™
B€Y€ЪИ[€]]™SX\љЩ\’ЫЪЩYHќYH[™™[™‚›ШШ[ќ[Э[Ы€™\ЭЬ™S]]™SX\љЩ\њКZ[љ[X\
B€KHY€[€Э™\њљYHШ\И™]™\€\YY\™H\И›Э[™ИИ]XЪЛ€ЫX\‚€KH[[YYX][H]\€[€][\[™ИИњ™\ЭЬ™H€[€\ЬЭ[YYШШ[K‚€Y€]]™SX\љЩ\”ШШ[HOHљ[[‚€]]™SX\љЩ\•Ш[ќYHљ[€]]™SX\љЩ\“[ЩHHљ[€]]™SX\љЩ\ђ[HHB€]]™SX\љЩ\”™\ЭЬ™T[™[™ИH[ЩB€]]™SX\љЩ\ђ]Y]]H€™]\›€ќYB€[™‚€KHЭЬЫЫ\ЬЪ[™И[[YYX][K]™[€Y€HЬЭЩ]\€\И[\Ь\љ[B€KH[]Z[X›K€H]\€ЬЭЩ]XЫЫ”ШШ[HШ[]\Э™XЫЫYHH™]ИЬЭ€KH\Щ[[™H[њЭXYЩ€™Z[™И[њЩ›Ь›YYћHHЫYH[ЩK‚€]]™SX\љЩ\•Ш[ќYHљ[€]]™SX\љЩ\“[ЩHHљ[€]]™SX\љЩ\ђ[HHB€ШШ[™\ЭЬ™HHШ\\™S]]™SX\љЩ\’ЬЭШШ[JZ[љ[X\
B€Y€™\ЭЬ™HOHљ[[‚€KHЩH™]™\€Э™\ќЬљ]H[€[љЫ›ЭЫ€ЬЭШШ[K€ЩY\™]ћZ[™И[€Ш\ЩHB€KHЫY[ќ]\€^ЬЩ\ИHЩ]\€Ь€HЬЭШ[ИЩ]XЫЫ”ШШ[K‚€]]™SX\љЩ\”™\ЭЬ™T[™[™ИHќYB€™]\›€[ЩB€[™‚€Y€X]XњК]]™SX\љЩ\”ШШ[HH™\ЭЬ™JH€ЊH[™›ЭЩ]]]™SX\љЩ\”ШШ[JZ[љ[X\™\ЭЬ™JH[‚€KHZ[YЩ]\њИ\™H[њЪY[ќ\љ[™ИЫY[ќ™XќZ[ЛЫШЪЩЭЫ‹€В€KH›ЭЬЩHHЬљYЪ[[ЬЭШШ[NИH™^\]HЪ[™]ћK‚€]]™SX\љЩ\”™\ЭЬ™T[™[™ИHќYB€™]\›€[ЩB€[™‚€]]™SX\љЩ\”ШШ[HHљ[€KHЩY\H\Э]]Ьљ]]]™HЬЭ\Щ[[™K€ЫЫYH™]Z[ќZ[И^ЬЩB€KHЩ]XЫЫ”ШШ[HЪ]Э]HX]Ъ[™ИЩ]\‹ЫИ›Ь™Щ][™ИH[YH[››Э[ЩY€KHћHHЬЭЫЭ[XZЩHHШY™H^\љ[Y[ќ[[Щ\И[]Z[X›HYШZ[€Ы‚€KHH™\ћH™^ЩY\[[ЩH\]K€H]\€ЬЭЩ]\€™Yњ™\Ъ\И\И[YB€KH›ЭYЪЫЪУ]]™SX\љЩ\њЛ‚€]]™SX\љЩ\”™\ЭЬ™T[™[™ИH[ЩB€]]™SX\љЩ\ђ]Y]]H€™]\›€ќYB™[™‚›ШШ[ќ[Э[Ы€\]S]]™SX\љЩ\њКZ[љ[X\[K[ЩJB€Y€[ЩHЏHљYWЮ™\›И€[™[ЩHЏHњШШ[H€[‚€™\ЭЬ™S]]™SX\љЩ\њКZ[љ[X\
B€™]\›‚€[™€ЫЪУ]]™SX\љЩ\њКZ[љ[X\
B€ШШ[ЬЭШШ[HHШ\\™S]]™SX\љЩ\’ЬЭШШ[JZ[љ[X\ќYJB€Y€ЬЭШШ[HOHљ[[‚€KHHЩ]\€]Щ[€\И[]Z[X›HЬ€™Z™XЭY€ЩY\H™\]Y\ЭY€KH[ЩH™XЫЬ™Yќ]И›ЭЫZ[H]Hљ\ЭX[Ъ[™ЩHШ\И\YY‚€]]™SX\љЩ\“[ЩHH[ЩB€]]™SX\љЩ\ђ[HH[B€]]™SX\љЩ\•Ш[ќYHљ[€™]\›‚€[™€]]™SX\љЩ\“[ЩHH[ЩB€]]™SX\љЩ\ђ[HH[B€]]™SX\љЩ\”™\ЭЬ™T[™[™ИH[ЩB€ШШ[Ш[ќYH[ЩHOHњШШ[H€[™
ЬЭШШ[H
€[JB€Ь€
[HHЊH[™Ь€ЬЭШШ[JB€]]™SX\љЩ\•Ш[ќYHШ[ќY€ШШ[›ЭИHЩ][YJ
B€KH›^ћ\™	ЬИ]]™H›\ЫЫ\ЬЪ]Ь€Ш[€™XќZ[Ъ]Э]XZЪ[™ИHXB€KHЩ]XЫЫ”ШШ[HШ[€™X\ЬЩ\ќ]HЭИ]HЫИH™XќZ[]Y\ЭЬЩ\ќљXЩK\[‚€KH^Y\€Ш[››Э™[XZ[€љ\ЪX›HЪ[HHZ[љ[X\\Иќ[HYY‚€ШШ[]Y]YHHШ[ќYHЊH[™›ЭИH]]™SX\љЩ\ђ]Y]]ЏHЊЌB€Y€]Y]YHЬ€]]™SX\љЩ\”ШШ[HOHљ[Ь€X]XњК]]™SX\љЩ\”ШШ[HHШ[ќY
H€ЊH[‚€Y€Щ]]]™SX\љЩ\”ШШ[JZ[љ[X\Ш[ќY
H[‚€]]™SX\љЩ\”ШШ[HHШ[ќY€]]™SX\љЩ\ђ]Y]]H›ЭВ€[™€[™™[™‚™ќ[Э[Ы€њО‘Щ]Z[љ[X\]]™SX\љЩ\ђ]Z[Xљ[]J[ЩJB€ШШ[Z[љ[X\HСЛ“Z[љ[X\€Y€›ЭZ[љ[X\[€™]\›€[ЩK•H]]™HZ[љ[X\\И›Э]Z[X›K€€[™€Y€›Э\У]]™SX\љЩ\”Щ]\ЉZ[љ[X\
H[‚€™]\›€[ЩK•\ИЫХИќZ[Щ\И›Э^ЬЩH]]™HX\љЩ\€ШШ[[™Л€‚€[™€KH[њЭ[H™XY[Ы›HЬЭZЫЪИ]™[€Ъ[HX]љ[™ИX\љЩ\њИ[Ъ[™ЩY€Y‚€KH›^ћ\™Ь€HЭЫљ[™ИRH]\€[››Э[Щ\ИHШШ[K^\љ[Y[ќ[[Щ\В€KHШ[€™XЫЫYH]Z[X›HЪ]Э]ЭY\ЬЪ[™ИЬ€™\]Z\љ[™ИH™[ШY‚€ЫЪУ]]™SX\љЩ\њКZ[љ[X\
B€Y€Ш\\™S]]™SX\љЩ\’ЬЭШШ[JZ[љ[X\
HЏHљ[[‚€Y€]]™SX\љЩ\ђ\Щ[[™P\ЬЭ[YY[‚€™]\›€ќYK•\ИЫХИќZ[Ш[››Э™XYHЭ\њ™[ќ]]™HX\љЩ\€ШШ[K€™XШ]\ЩH[€^\љ[Y[ќ[X\љЩ\€[ЩH\ИЩ[XЭYњ[YHШ[Xљ]\И\Ъ[™ИL	H\И]И™\ЭЬ][Ы€\Щ[[™H[ќ[›^ћ\™Ь€HЭЫљ[™ИRH[››Э[Щ\И[›Э\€[YK€‚€[™€™]\›€ќYB€[™€ШШ[›ЭHH•\ИЫХИќZ[Ш[››Э™XYHЭ\њ™[ќ]]™HX\љЩ\€ШШ[K€ЪЫЬЪ[™И[€^\љ[Y[ќ[X\љЩ\€[ЩHЪ[^XЪ]H\ЩHL	H\И]И™\ЭЬ][Ы€\Щ[[™NИX]™H[Ъ[™ЩY™]™\€Ьљ]\И]€‚€Y€[ЩHOHљYWЮ™\›И€Ь€[ЩHOHњШШ[H€[‚€Ш\\™S]]™SX\љЩ\’ЬЭШШ[JZ[љ[X\ќYJB€[™€™]\›€ќYK›ЭB™[™‚™ќ[Э[Ы€њО’\УZ[љ[X\ЭXЪФ[™[™ХЫЬљК
B€™]\›€]]™SX\љЩ\”™\ЭЬ™T[™[™ИOHќYHЬ€]]™Tљ[™Ф™\ЭЬ™T[™[™ИOHќYB€Ь€ШШ[€ЏHљ[Ь€™^
[™[™КHЏHљ[™[™‚™ќ[Э[Ы€њО•\]SZ[љ[X\ЭXЪК™\ШШ[ЉB€›ШЩ\ЬФ[™[™К
B€ШШ[Z[љ[X\HСЛ“Z[љ[X\€ШШ[XЭ]™HHЩ[‹њќ[ќ[YH[™Щ[‹њќ[ќ[YKXЭ]™H[™Щ[‹њќ[ќ[YKXЭ]™K›Z[љ[X\€ШШ[ЫЫќ›ЫYHЩ[‹њќ[ќ[YH[™Щ[‹њќ[ќ[YK™њ[YPћRQ[™Щ[‹њќ[ќ[YK™њ[YPћRQ›Z[љ[X\OHZ[љ[X\€ШШ[™^][\Y\€HXЭ]™H[™XЭ]™K[B€Y€›ЭZ[љ[X\Ь€›ЭЫЫќ›ЫYЬ€›Э[Y[J™^][\Y\ЉH[‚€ШШ[њ[Y\ИHЯB€›Ь€њ[YH[€Z\њКЭЫ™Y
HИњ[Y\ЦИЩњ[Y\И
ИWHHњ[YH[™€›Ь€Лњ[YH[€\Z\њКњ[Y\КHИ™[X\ЩJњ[YJH[™€][\Y\€HB€ШШ[€Hљ[€™\ЭЬ™S]]™SX\љЩ\њКZ[љ[X\Ь€СЛ“Z[љ[X\
B€™\ЭЬ™S]]™SX\љЩ\”љ[™ЬКZ[љ[X\Ь€СЛ“Z[љ[X\
B€™]\›‚€[™€ШШ[Щ][™ЬИHЩ[‹‘Щ]\™Щ]Щ][™ЬИ[™Щ[Ћ‘Щ]\™Щ]Щ][™ЬК›Z[љ[X\ЉB€ШШ[X\љЩ\“[ЩHHЩ][™ЬИ[™Щ][™ЬЛ›]]™SX\љЩ\“[ЩHЬ€љЩY\‚€\]S]]™SX\љЩ\њКZ[љ[X\™^][\Y\‹X\љЩ\“[ЩJB€\]S]]™SX\љЩ\”љ[™ЬКZ[љ[X\™^][\Y\‹X\љЩ\“[ЩJB€ШШ[Ъ[™ЩYHX]XњК][\Y\€H™^][\Y\ЉH€ЊB€][\Y\€H™^][\Y\‚€Y€™\ШШ[€[™›ЭШШ[€[€™YЪ[”ШШ[ЉZ[љ[X\
H[™€Y€™\ШШ[€[‚€KHHURH›[Э]\ИH[ћK^XЭY\\€[™ЪЭ[™XЫЫYHB€KHЪ[™[X]XИ^[\[Ы€[[YYX][NИ\ШЩ[™[ќ[€\ШЫЭ™\ћHШ[€ЩY\€KH›ЩЬ™\ЬЪ[™И[Ь™[Y[ќ[HЪ]Э][^Z[™ИHљ\ЪX›Hќ]Ы€ЭXЪЛ‚€ШШ[Щ[X[ќXИHЯB€YЩ[X[ќXУZ[љ[X\њ[Y\КЩ[X[ќXЛZ[љ[X\
B€›Ь€њ[YH[€Z\њКЩ[X[ќXКHВ€ШШ[Э\’QHЩ[‹њќ[ќ[YK›X[YЩYQћQњ[YH[™Щ[‹њќ[ќ[YK›X[YЩYQћQњ[YVЩњ[YWB€Y€›ЭЭ\’QЬ€Э\’QOH›Z[љ[X\€[€ЫZ[Jњ[YJH[™€[™€[™€Y€ШШ[€[‚€ШШ[\ШЫЭ™\™YHЫЫќ[ќYTШШ[ЉZ[љ[X\
B€Y€\ШЫЭ™\™Y[‚€ШШ[Э\њ™[ќHЯB€›Ь€њ[YH[€Z\њК\ШЫЭ™\™Y
HВ€ШШ[Э\’QHЩ[‹њќ[ќ[YK›X[YЩYQћQњ[YH[™Щ[‹њќ[ќ[YK›X[YЩYQћQњ[YVЩњ[YWB€Y€›ЭЭ\’QЬ€Э\’QOH›Z[љ[X\€[‚€Э\њ™[ќЩњ[YWHHќYB€ЫZ[Jњ[YJB€[™€[™€ШШ[™]\™YHЯB€›Ь€њ[YH[€Z\њКЭЫ™Y
HИY€›ЭЭ\њ™[ќЩњ[YWH[€™]\™YИЬ™]\™Y
ИWHHњ[YH[™[™€›Ь€Лњ[YH[€\Z\њК™]\™Y
HИ™[X\ЩJњ[YJH[™€[™€[™€KH\™Щ]ЭЫ™\њЪ\Ш[€Ъ[™ЩHЪ]Э]Z[љ[X\ЬЫЩЮHЪ[™Ъ[™Л€™]™\‚€KHЫЫ\ЬЩHHЭXЪИ][\Y\€ЫќИHњ[YH›ЭИЫЫќ›ЫY^XЪ]HћB€KH[›Э\€љ[Ьљ]HY\€\™Щ]‚€ШШ[ЫЫ™›XЭYHЯB€›Ь€њ[YH[€Z\њКЭЫ™Y
HВ€ШШ[Э\’QHЩ[‹њќ[ќ[YK›X[YЩYQћQњ[YH[™Щ[‹њќ[ќ[YK›X[YЩYQћQњ[YVЩњ[YWB€Y€Э\’Q[™Э\’QЏH›Z[љ[X\€[€ЫЫ™›XЭYИШЫЫ™›XЭY
ИWHHњ[YH[™€[™€›Ь€Лњ[YH[€\Z\њКЫЫ™›XЭY
HИ™[X\ЩJњ[YJH[™€›Ь€њ[YH[€Z\њКЭЫ™Y
HВ€ШШ[\ЭH\YY[VЩњ[YWB€Y€›ЭЫЪЩYЩњ[YWH[‚€ШШ[]™HH[Jњ[YJB€Y€]™HЏHљ[[™\ЭЏHљ[[™X]XњК]™HH\Э
H€ЊH[€ЬЭ[VЩњ[YWHH]™H[™€[™€ШШ[Ш[ќYHЬЭ[VЩњ[YWH[™ЬЭ[VЩњ[YWH
€][\Y\‚€Y€Ш[ќY[™
Ъ[™ЩYЬ€\ЭOHљ[Ь€X]XњКШ[ќYH\Э
H€ЊJH[€\Jњ[YJH[™€[™™[™‚™ќ[Э[Ы€њО’\УZ[љ[X\ЭXЪСњ[YJњ[YJB€™]\›€њ[YH[™ЭЫ™YЩњ[YWHOHќYHЬ€[ЩB™[™‚™ќ[Э[Ы€њО“Z[љ[X\ЭXЪРЫЫќZ[њРЭ\њЫЬЉ
B€›Ь€њ[YH[€Z\њКЭЫ™Y
HВ€Y€›ЭЭ™\‘^ЫYYЩњ[YWH[™Щ[Ћ‘њ[YPЫЫќZ[њРЭ\њЫЬЉњ[YJH[€™]\›€ќYH[™€[™€™]\›€[ЩB™[™