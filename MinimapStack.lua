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
    -- A future host SetIconScale call is the other authoritative source.
    local value = Method(minimap, "GetIconScale")
    return ValidScale(value) and value or nil
end

local function CaptureNativeMarkerHostScale(minimap, allowAssumedDefault)
    if nativeMarkerHostScale ~= nil then return nativeMarkerHostScale end
    local value = ReadNativeMarkerScale(minimap)
    if value ~= nil then
        nativeMarkerHostScale = value
        nativeMarkerBaselineAssumed = false
    elseif allowAssumedDefault then
        -- Some Retail builds expose only SetIconScale. Selecting an
        -- experimental marker mode is the user's explicit opt-in to use the
        -- native 100% scale as the temporary restoration baseline. The
        -- default "Leave unchanged" mode never reaches this path.
        nativeMarkerHostScale = 1
        nativeMarkerBaselineAssumed = true
    end
    return nativeMarkerHostScale
end

local function HasNativeMarkerSetter(minimap)
    if not minimap then return false end
    local ok, setter = pcall(function() return minimap.SetIconScale end)
    return ok and type(setter) == "function"
end

local function SetNativeMarkerScale(minimap, value)
    if not minimap or not ValidScale(value) then return false end
    local okMethod, setter = pcall(function() return minimap.SetIconScale end)
    if not okMethod or type(setter) ~= "function" then return false end
    nativeMarkerGuard = true
    local ok = pcall(setter, minimap, value)
    nativeMarkerGuard = false
    return ok
end

local function NativeRingGetterName(setterName)
    return "Get" .. setterName:sub(4)
end

local function CaptureNativeRingHostAlpha(minimap, setterName, allowAssumedDefault)
    local known = nativeRingHostAlpha[setterName]
    if known ~= nil then return known end
    local value = Method(minimap, NativeRingGetterName(setterName))
    if ValidAlpha(value) then
        nativeRingHostAlpha[setterName] = value
        nativeRingBaselineAssumed[setterName] = nil
    elseif allowAssumedDefault then
        -- These APIs do not consistently provide getters. Experimental marker
        -- modes use the same explicit 100% fallback as SetIconScale until the
        -- host announces a real ring alpha through its setter.
        nativeRingHostAlpha[setterName] = 1
        nativeRingBaselineAssumed[setterName] = true
    end
    return nativeRingHostAlpha[setterName]
end

local function SetNativeRingAlpha(minimap, setterName, value)
    if not minimap or not ValidAlpha(value) then return false end
    local okMethod, setter = pcall(function() return minimap[setterName] end)
    if not okMethod or type(setter) ~= "function" then return false end
    nativeRingGuard = true
    local ok = pcall(setter, minimap, value)
    nativeRingGuard = false
    return ok
end

local function NativeRingWanted(hostAlpha, alpha, mode)
    if mode == "scale" then return hostAlpha * alpha end
    if mode == "hide_zero" then return alpha <= 0.001 and 0 or hostAlpha end
end

local function HookNativeMarkerRings(minimap)
    if not minimap or type(hooksecurefunc) ~= "function" then return end
    for _, setterName in ipairs(NATIVE_RING_ALPHA_SETTERS) do
        if not nativeRingHooked[setterName] then
            local ok = pcall(hooksecurefunc, minimap, setterName, function(_, value)
                if nativeRingGuard or not ValidAlpha(value) then return end
                nativeRingHostAlpha[setterName] = value
                nativeRingBaselineAssumed[setterName] = nil
                nativeRingAppliedAlpha[setterName] = value
                nativeRingRestorePending = false
                local wanted = NativeRingWanted(value, nativeMarkerAlpha, nativeMarkerMode)
                if wanted ~= nil and math.abs(value - wanted) > 0.001
                    and SetNativeRingAlpha(minimap, setterName, wanted) then
                    nativeRingAppliedAlpha[setterName] = wanted
                    nativeRingAuditAt = GetTime()
                end
            end)
            if ok then nativeRingHooked[setterName] = true end
        end
    end
end

local function RestoreNativeMarkerRings(minimap)
    if next(nativeRingAppliedAlpha) == nil then
        nativeRingRestorePending = false
        nativeRingAuditAt = 0
        return true
    end
    local complete = true
    for setterName, applied in pairs(nativeRingAppliedAlpha) do
        local restore = CaptureNativeRingHostAlpha(minimap, setterName)
        if restore == nil then
            complete = false
        elseif math.abs(applied - restore) > 0.001 and not SetNativeRingAlpha(minimap, setterName, restore) then
            complete = false
        else
            nativeRingAppliedAlpha[setterName] = nil
        end
    end
    nativeRingRestorePending = not complete
    if complete then nativeRingAuditAt = 0 end
    return complete
end

local function UpdateNativeMarkerRings(minimap, alpha, mode)
    if mode ~= "hide_zero" and mode ~= "scale" then
        RestoreNativeMarkerRings(minimap)
        return
    end
    HookNativeMarkerRings(minimap)
    local now = GetTime()
    for _, setterName in ipairs(NATIVE_RING_ALPHA_SETTERS) do
        local hostAlpha = CaptureNativeRingHostAlpha(minimap, setterName, true)
        local wanted = hostAlpha and NativeRingWanted(hostAlpha, alpha, mode)
        local applied = nativeRingAppliedAlpha[setterName]
        -- Native map rebuilds can restore a blob ring without calling its Lua
        -- setter. Reassert only while a fully faded Minimap needs it hidden.
        local auditDue = wanted and wanted <= 0.001 and now - nativeRingAuditAt >= 0.25
        if wanted ~= nil and (auditDue or applied == nil or math.abs(applied - wanted) > 0.001)
            and SetNativeRingAlpha(minimap, setterName, wanted) then
            nativeRingAppliedAlpha[setterName] = wanted
            nativeRingAuditAt = now
        end
    end
    nativeRingRestorePending = false
end

local function HookNativeMarkers(minimap)
    if nativeMarkerHooked or not minimap or type(hooksecurefunc) ~= "function" then return end
    local ok = pcall(hooksecurefunc, minimap, "SetIconScale", function(_, value)
        if nativeMarkerGuard or not ValidScale(value) then return end
        nativeMarkerHostScale = value
        nativeMarkerBaselineAssumed = false
        nativeMarkerScale = value
        nativeMarkerRestorePending = false
        local wanted
        if nativeMarkerMode == "scale" then
            wanted = value * nativeMarkerAlpha
        elseif nativeMarkerMode == "hide_zero" then
            wanted = nativeMarkerAlpha <= 0.001 and 0 or value
        end
        nativeMarkerWanted = wanted
        if wanted ~= nil and math.abs(value - wanted) > 0.001 then
            if SetNativeMarkerScale(minimap, wanted) then
                nativeMarkerScale = wanted
                nativeMarkerAuditAt = GetTime()
            end
        end
    end)
    if ok then nativeMarkerHooked = true end
end

local function RestoreNativeMarkers(minimap)
    -- If an override was never applied there is nothing to put back.  Clear
    -- immediately rather than attempting to "restore" an assumed scale.
    if nativeMarkerScale == nil then
        nativeMarkerWanted = nil
        nativeMarkerMode = nil
        nativeMarkerAlpha = 1
        nativeMarkerRestorePending = false
        nativeMarkerAuditAt = 0
        return true
    end

    -- Stop composing immediately, even if the host setter is temporarily
    -- unavailable.  A later host SetIconScale call must become the new host
    -- baseline instead of being transformed by the old fade mode.
    nativeMarkerWanted = nil
    nativeMarkerMode = nil
    nativeMarkerAlpha = 1
    local restore = CaptureNativeMarkerHostScale(minimap)
    if restore == nil then
        -- We never overwrite an unknown host scale.  Keep retrying in case the
        -- client later exposes a getter or the host calls SetIconScale.
        nativeMarkerRestorePending = true
        return false
    end

    if math.abs(nativeMarkerScale - restore) > 0.001 and not SetNativeMarkerScale(minimap, restore) then
        -- Failed setters are transient during client rebuilds/lockdown.  Do
        -- not lose the original host scale; the next update will retry.
        nativeMarkerRestorePending = true
        return false
    end

    nativeMarkerScale = nil
    -- Keep the last authoritative host baseline. Some Retail builds expose
    -- SetIconScale without a matching getter, so forgetting a value announced
    -- by the host would make the safe experimental modes unavailable again on
    -- the very next keep-mode update. A later host setter refreshes this value
    -- through HookNativeMarkers.
    nativeMarkerRestorePending = false
    nativeMarkerAuditAt = 0
    return true
end

local function UpdateNativeMarkers(minimap, alpha, mode)
    if mode ~= "hide_zero" and mode ~= "scale" then
        RestoreNativeMarkers(minimap)
        return
    end
    HookNativeMarkers(minimap)
    local hostScale = CaptureNativeMarkerHostScale(minimap, true)
    if hostScale == nil then
        -- The setter itself is unavailable or rejected. Keep the requested
        -- mode recorded, but do not claim that a visual change was applied.
        nativeMarkerMode = mode
        nativeMarkerAlpha = alpha
        nativeMarkerWanted = nil
        return
    end
    nativeMarkerMode = mode
    nativeMarkerAlpha = alpha
    nativeMarkerRestorePending = false
    local wanted = mode == "scale" and (hostScale * alpha)
        or (alpha <= 0.001 and 0 or hostScale)
    nativeMarkerWanted = wanted
    local now = GetTime()
    -- Blizzard's native blip compositor can rebuild without making a Lua
    -- SetIconScale call. Reassert at a low rate so a rebuilt quest/service-pin
    -- layer cannot remain visible while the Minimap is fully faded.
    local auditDue = wanted <= 0.001 and now - nativeMarkerAuditAt >= 0.25
    if auditDue or nativeMarkerScale == nil or math.abs(nativeMarkerScale - wanted) > 0.001 then
        if SetNativeMarkerScale(minimap, wanted) then
            nativeMarkerScale = wanted
            nativeMarkerAuditAt = now
        end
    end
end

function ns:GetMinimapNativeMarkerAvailability(mode)
    local minimap = _G.Minimap
    if not minimap then return false, "The native Minimap is not available." end
    if not HasNativeMarkerSetter(minimap) then
        return false, "This WoW build does not expose native marker scaling."
    end
    -- Install the read-only post-hook even while leaving markers unchanged. If
    -- Blizzard or the owning UI later announces a scale, experimental modes
    -- can become available without guessing or requiring a reload.
    HookNativeMarkers(minimap)
    if CaptureNativeMarkerHostScale(minimap) ~= nil then
        if nativeMarkerBaselineAssumed then
            return true, "This WoW build cannot read the current native marker scale. Because an experimental marker mode is selected, Frame Gambit is using 100% as its restoration baseline until Blizzard or the owning UI announces another value."
        end
        return true
    end
    local note = "This WoW build cannot read the current native marker scale. Choosing an experimental marker mode will explicitly use 100% as its restoration baseline; Leave unchanged never writes it."
    if mode == "hide_zero" or mode == "scale" then
        CaptureNativeMarkerHostScale(minimap, true)
    end
    return true, note
end

function ns:HasMinimapStackPendingWork()
    return nativeMarkerRestorePending == true or nativeRingRestorePending == true
        or scan ~= nil or next(pending) ~= nil
end

function ns:UpdateMinimapStack(rescan)
    ProcessPending()
    local minimap = _G.Minimap
    local active = self.runtime and self.runtime.active and self.runtime.active.minimap
    local controlled = self.runtime and self.runtime.frameByID and self.runtime.frameByID.minimap == minimap
    local nextMultiplier = active and active.alpha
    if not minimap or not controlled or not ValidAlpha(nextMultiplier) then
        local frames = {}
        for frame in pairs(owned) do frames[#frames + 1] = frame end
        for _, frame in ipairs(frames) do Release(frame) end
        multiplier = 1
        scan = nil
        RestoreNativeMarkers(minimap or _G.Minimap)
        RestoreNativeMarkerRings(minimap or _G.Minimap)
        return
    end
    local settings = self.GetTargetSettings and self:GetTargetSettings("minimap")
    local markerMode = settings and settings.nativeMarkerMode or "keep"
    UpdateNativeMarkers(minimap, nextMultiplier, markerMode)
    UpdateNativeMarkerRings(minimap, nextMultiplier, markerMode)
    local changed = math.abs(multiplier - nextMultiplier) > 0.001
    multiplier = nextMultiplier
    if rescan and not scan then BeginScan(minimap) end
    if rescan then
        -- The EUI flyout is a tiny, exact adapter and should become a
        -- Cinematic exemption immediately; descendant pin discovery can keep
        -- progressing incrementally without delaying the visible button stack.
        local semantic = {}
        AddSemanticMinimapFrames(semantic, minimap)
        for frame in pairs(semantic) do
            local otherID = self.runtime.managedIDByFrame and self.runtime.managedIDByFrame[frame]
            if not otherID or otherID == "minimap" then Claim(frame) end
        end
    end
    if scan then
        local discovered = ContinueScan(minimap)
        if discovered then
        local current = {}
        for frame in pairs(discovered) do
            local otherID = self.runtime.managedIDByFrame and self.runtime.managedIDByFrame[frame]
            if not otherID or otherID == "minimap" then
                current[frame] = true
                Claim(frame)
            end
        end
        local retired = {}
        for frame in pairs(owned) do if not current[frame] then retired[#retired + 1] = frame end end
        for _, frame in ipairs(retired) do Release(frame) end
        end
    end
    -- Target ownership can change without Minimap topology changing. Never
    -- compose the stack multiplier onto a frame now controlled explicitly by
    -- another Priority Fader target.
    local conflicted = {}
    for frame in pairs(owned) do
        local otherID = self.runtime.managedIDByFrame and self.runtime.managedIDByFrame[frame]
        if otherID and otherID ~= "minimap" then conflicted[#conflicted + 1] = frame end
    end
    for _, frame in ipairs(conflicted) do Release(frame) end
    for frame in pairs(owned) do
        local last = appliedAlpha[frame]
        if not hooked[frame] then
            local live = Alpha(frame)
            if live ~= nil and last ~= nil and math.abs(live - last) > 0.001 then hostAlpha[frame] = live end
        end
        local wanted = hostAlpha[frame] and hostAlpha[frame] * multiplier
        if wanted and (changed or last == nil or math.abs(wanted - last) > 0.001) then Apply(frame) end
    end
end

function ns:IsMinimapStackFrame(frame)
    return frame and owned[frame] == true or false
end

function ns:MinimapStackContainsCursor()
    for frame in pairs(owned) do
        if not hoverExcluded[frame] and self:FrameContainsCursor(frame) then return true end
    end
    return false
end
