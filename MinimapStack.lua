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
local multiplier = 1
local scan

local function IsSecret(value)
    return issecretvalue and issecretvalue(value) or false
end

local function ValidAlpha(value)
    return type(value) == "number" and not IsSecret(value) and value == value
        and value >= 0 and value <= 1
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
        if count >= 1 then result[parent] = true end
    end
end

local function BeginScan(minimap)
    scan = { minimap = minimap, queue = Children(minimap), index = 1, seen = {}, found = {} }
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
            for _, nested in ipairs(Children(child)) do
                if not scan.seen[nested] then scan.queue[#scan.queue + 1] = nested end
            end
        end
    end
    if scan.index <= #scan.queue then return nil end
    AddEUIFlyoutPanels(scan.found, minimap)
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
        return
    end
    local changed = math.abs(multiplier - nextMultiplier) > 0.001
    multiplier = nextMultiplier
    if rescan and not scan then BeginScan(minimap) end
    if rescan then
        -- The EUI flyout is a tiny, exact adapter and should become a
        -- Cinematic exemption immediately; descendant pin discovery can keep
        -- progressing incrementally without delaying the visible button stack.
        local flyouts = {}
        AddEUIFlyoutPanels(flyouts, minimap)
        for frame in pairs(flyouts) do
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
        if self:FrameContainsCursor(frame) then return true end
    end
    return false
end
