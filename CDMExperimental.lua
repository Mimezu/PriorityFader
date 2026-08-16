local ADDON, ns = ...

-- Experimental, Priority Fader-only Ellesmere CDM composition.
--
-- EUI bar frames are layout shells. The icons they arrange remain children
-- of Blizzard Cooldown Manager viewers, so fading a shell does not fade what
-- the player sees. These proxy targets use the shell only for geometry and
-- multiply the alpha EUI most recently requested for each icon. No EUI file,
-- database, point, style, state rule, or mouse setting is changed.

local proxiesByKey = {}
local frameToTarget = setmetatable({}, { __mode = "k" })
local iconOwner = setmetatable({}, { __mode = "k" })
local iconHostAlpha = setmetatable({}, { __mode = "k" })
local iconAppliedAlpha = setmetatable({}, { __mode = "k" })
local iconGuard = setmetatable({}, { __mode = "k" })
local iconHooked = setmetatable({}, { __mode = "k" })
local pendingIconRestore = setmetatable({}, { __mode = "k" })

local function MapPickerFrame(proxy, frame)
    if not proxy or not frame then return end
    frameToTarget[frame] = proxy.id
    proxy.mappedFrames[frame] = true
end

local function ClearPickerFrames(proxy)
    if not proxy then return end
    for frame in pairs(proxy.mappedFrames) do
        if frameToTarget[frame] == proxy.id then frameToTarget[frame] = nil end
    end
    proxy.mappedFrames = setmetatable({}, { __mode = "k" })
end

local function IsSecret(value)
    return issecretvalue and issecretvalue(value) or false
end

local function IsFiniteAlpha(value)
    return type(value) == "number" and not IsSecret(value) and value == value
        and value >= 0 and value <= 1
end

local function SafeMethod(object, method, ...)
    if not object then return nil end
    local okMethod, callback = pcall(function() return object[method] end)
    if not okMethod or type(callback) ~= "function" then return nil end
    local ok, value = pcall(callback, object, ...)
    if not ok or IsSecret(value) then return nil end
    return value
end

local function SafeIconAlpha(icon)
    local alpha = SafeMethod(icon, "GetAlpha")
    return IsFiniteAlpha(alpha) and alpha or nil
end

local function SetIconAlpha(icon, alpha)
    if not IsFiniteAlpha(alpha) then return false end
    iconGuard[icon] = true
    local ok = pcall(function() icon:SetAlpha(alpha) end)
    iconGuard[icon] = nil
    if ok then iconAppliedAlpha[icon] = alpha end
    return ok
end

local function EUIState()
    local eui = _G.EllesmereUI
    local modules = eui and eui._ModuleNS
    local module = modules and modules.EllesmereUICooldownManager
    if type(module) ~= "table" then return nil end
    local ecme = module.ECME
    local profile = ecme and ecme.db and ecme.db.profile
    if type(profile) ~= "table" or type(profile.cdmBars) ~= "table"
        or profile.cdmBars.enabled ~= true then return nil end
    if type(module.barDataByKey) ~= "table" or type(module.GetCDMBarFrame) ~= "function"
        or type(module.GetCDMBarIcons) ~= "function" then return nil end
    return module
end

local function IsLiveBar(module, key)
    if type(key) ~= "string" or key == "" or key == "focuskick" or key:sub(1, 7) == "__ghost" then return false end
    local data = module and module.barDataByKey and module.barDataByKey[key]
    return type(data) == "table" and data.enabled ~= false and data.isGhostBar ~= true
end

local function BarFrame(module, key)
    if not IsLiveBar(module, key) then return nil end
    local ok, frame = pcall(module.GetCDMBarFrame, key)
    return ok and frame or nil
end

local function BarIcons(module, key)
    if not IsLiveBar(module, key) then return nil end
    local ok, icons = pcall(module.GetCDMBarIcons, key)
    return ok and type(icons) == "table" and icons or nil
end

local function ApplyOwnedIcon(icon)
    local owner = iconOwner[icon]
    local host = iconHostAlpha[icon]
    if not owner or not owner.active or not IsFiniteAlpha(host) then return false end
    return SetIconAlpha(icon, host * owner.multiplier)
end

local function HostSetAlpha(icon, alpha)
    if iconGuard[icon] or not iconOwner[icon] then return end
    -- A protected state can make the host argument secret. We cannot inspect
    -- or save it, but we can safely reassert the last readable composition.
    if not IsFiniteAlpha(alpha) then
        ApplyOwnedIcon(icon)
        return
    end
    iconHostAlpha[icon] = alpha
    ApplyOwnedIcon(icon)
end

local function HookIcon(icon)
    if iconHooked[icon] or type(hooksecurefunc) ~= "function" then return end
    -- hooksecurefunc is a read-only posthook and does not replace EUI's method
    -- or alter secure attributes. Try it even when a pooled icon first appears
    -- in combat; pcall keeps a restricted frame fail-closed if Retail rejects
    -- that particular object.
    local ok = pcall(hooksecurefunc, icon, "SetAlpha", function(_, alpha) HostSetAlpha(icon, alpha) end)
    if ok then iconHooked[icon] = true end
end

local Proxy = {}
Proxy.__index = Proxy

function Proxy:GetRect()
    local module = EUIState()
    local frame = module and BarFrame(module, self.key)
    if not frame then return nil end
    return frame:GetRect()
end

function Proxy:IsShown()
    local module = EUIState()
    local frame = module and BarFrame(module, self.key)
    if not frame then return false end
    local shown = SafeMethod(frame, "IsShown")
    return shown == true
end

function Proxy:GetAlpha()
    return self.multiplier
end

function Proxy:SetAlpha(alpha)
    if not IsFiniteAlpha(alpha) then error("Priority Fader CDM multiplier must be between 0 and 1") end
    self.multiplier = alpha
    if self.active then
        -- Membership is refreshed on EUI's claim generation and the 1s
        -- compatibility fallback. A fade tick only paints the already-owned
        -- set once; it must not allocate/rescan the bar at 20 Hz.
        for icon in pairs(self.icons) do ApplyOwnedIcon(icon) end
    end
end

function Proxy:ClaimIcon(icon)
    if not icon or (type(icon) ~= "table" and type(icon) ~= "userdata") then return end
    local previous = iconOwner[icon]
    if previous and previous ~= self then previous:ReleaseIcon(icon) end
    if iconOwner[icon] == self then
        -- Reconcile an animation or unusual host write that bypassed
        -- SetAlpha before repainting it with the current PF multiplier.
        local live, applied = SafeIconAlpha(icon), iconAppliedAlpha[icon]
        if live ~= nil and applied ~= nil and math.abs(live - applied) > 0.001 then
            iconHostAlpha[icon] = live
        end
    else
        local alpha = SafeIconAlpha(icon)
        if alpha == nil then return end
        local pending = pendingIconRestore[icon]
        if pending then
            -- Reacquisition can happen before an out-of-combat restore. If
            -- the icon still has PF's last composition, carry forward EUI's
            -- saved base rather than compounding the old multiplier. A
            -- different live alpha means EUI already repainted and wins.
            if math.abs(alpha - pending.lastApplied) <= 0.001 then alpha = pending.base end
            pendingIconRestore[icon] = nil
        end
        iconOwner[icon] = self
        iconHostAlpha[icon] = alpha
    end
    self.icons[icon] = true
    MapPickerFrame(self, icon)
    HookIcon(icon)
    ApplyOwnedIcon(icon)
end

function Proxy:ReleaseIcon(icon)
    self.icons[icon] = nil
    if iconOwner[icon] ~= self then return true end
    local alpha = iconHostAlpha[icon]
    local lastApplied = iconAppliedAlpha[icon]
    local restored = alpha == nil or SetIconAlpha(icon, alpha)
    if not restored and alpha ~= nil and lastApplied ~= nil then
        -- Restore later only if the icon still carries PF's last write. If
        -- EUI repaints it first, EUI has already reclaimed ownership and its
        -- newer opacity must win.
        pendingIconRestore[icon] = { base = alpha, lastApplied = lastApplied }
    end
    iconOwner[icon] = nil
    iconHostAlpha[icon] = nil
    iconAppliedAlpha[icon] = nil
    return restored
end

function Proxy:RefreshIcons()
    if not self.active then return false end
    local module = EUIState()
    local icons = module and BarIcons(module, self.key)
    if not icons then
        -- BuildAllCDMBars briefly clears membership while the bar itself is
        -- still live. Drop the old icons but preserve this proxy's active
        -- lease and multiplier so the completed generation is reclaimed.
        self:DropIcons()
        return false
    end
    local current = setmetatable({}, { __mode = "k" })
    for _, icon in pairs(icons) do
        if icon then
            current[icon] = true
            self:ClaimIcon(icon)
            frameToTarget[icon] = self.id
        end
    end
    local retired = {}
    for icon in pairs(self.icons) do if not current[icon] then retired[#retired + 1] = icon end end
    for _, icon in ipairs(retired) do self:ReleaseIcon(icon) end
    return true
end

function Proxy:Acquire()
    self.active = true
    local ready = self:RefreshIcons()
    if not ready then self.active = false end
    return ready
end

function Proxy:DropIcons()
    local icons = {}
    for icon in pairs(self.icons) do icons[#icons + 1] = icon end
    for _, icon in ipairs(icons) do self:ReleaseIcon(icon) end
end

function Proxy:Release()
    self:DropIcons()
    self.active = false
    self.multiplier = 1
    return true
end

local function Checksum(text)
    local value = 5381
    for index = 1, #text do value = (value * 33 + text:byte(index)) % 2147483647 end
    return value
end

local function TargetID(key)
    local readable = key:gsub("[^%w_.%-]", "_"):sub(1, 40)
    return "experimental_cdm_" .. readable .. "_" .. Checksum(key)
end

local function GetOrCreateProxy(key)
    local proxy = proxiesByKey[key]
    if proxy then return proxy end
    proxy = setmetatable({
        key = key,
        id = TargetID(key),
        multiplier = 1,
        active = false,
        icons = setmetatable({}, { __mode = "k" }),
        mappedFrames = setmetatable({}, { __mode = "k" }),
    }, Proxy)
    proxiesByKey[key] = proxy
    return proxy
end

local function RegisterBarTarget(module, key)
    local data = module.barDataByKey[key]
    local proxy = GetOrCreateProxy(key)
    local barName = tostring(data.name or key):gsub("[%c|]", " "):match("^%s*(.-)%s*$")
    local label = "CDM icons · " .. (barName ~= "" and barName or key)
    if #label > 64 then label = label:sub(1, 61) .. "..." end
    local existing = ns.TargetByID[proxy.id]
    if existing then
        existing.label = label
        return proxy, false
    end
    local registered = ns:RegisterTarget({
        id = proxy.id,
        label = label,
        source = "Ellesmere CDM",
        protected = true,
        capability = "Experimental icon fade",
        capabilityTone = "amber",
        capabilityNote = "PF multiplies EUI's final icon opacity for this bar. Set its EUI visibility to Always Visible; EUI keeps styling and icon-state control.",
        resolve = function()
            local current = EUIState()
            return current and BarFrame(current, key) and proxy or nil
        end,
        acquire = function(frame) return frame:Acquire() end,
        release = function(frame) return frame:Release() end,
        skipManagedAlphaHook = true,
        cdmExperimental = true,
    })
    return proxy, registered == true
end

function ns:RefreshExperimentalCDMTargets()
    for icon, record in pairs(pendingIconRestore) do
        if not InCombatLockdown() then
            local live = SafeIconAlpha(icon)
            if live ~= nil and math.abs(live - record.lastApplied) > 0.001 then
                -- EUI changed the icon after PF's failed restore. Relinquish
                -- without writing stale state over the newer host decision.
                pendingIconRestore[icon] = nil
            elseif live ~= nil and SetIconAlpha(icon, record.base) then
                pendingIconRestore[icon] = nil
                iconAppliedAlpha[icon] = nil
            end
        end
    end
    local module = EUIState()
    local changed = false
    local previousBatch = self._batchRegistering
    self._batchRegistering = true
    if module then
        for key in pairs(module.barDataByKey) do
            if IsLiveBar(module, key) then
                local proxy, added = RegisterBarTarget(module, key)
                changed = changed or added
                ClearPickerFrames(proxy)
                local frame = BarFrame(module, key)
                if frame then MapPickerFrame(proxy, frame) end
                -- Let the visual picker choose the semantic bar target when
                -- it lands on one of the Blizzard-owned icons, even before
                -- the user has enabled PF control for that bar.
                local icons = BarIcons(module, key)
                for _, icon in pairs(icons or {}) do if icon then MapPickerFrame(proxy, icon) end end
                if proxy.active then proxy:RefreshIcons() end
            end
        end
    end
    for key, proxy in pairs(proxiesByKey) do
        if not module or not IsLiveBar(module, key) then
            ClearPickerFrames(proxy)
            if proxy.active then proxy:Release() end
        end
    end
    self._batchRegistering = previousBatch
    if changed and not previousBatch and self.RefreshOptions then self:RefreshOptions() end
end

function ns:GetExperimentalCDMTargetForFrame(frame)
    local current, seen, depth = frame, {}, 0
    while current and depth < 10 and not seen[current] do
        local id = frameToTarget[current]
        if id then return id end
        seen[current] = true
        current = SafeMethod(current, "GetParent")
        depth = depth + 1
    end
    self:RefreshExperimentalCDMTargets()
    current, seen, depth = frame, {}, 0
    while current and depth < 10 and not seen[current] do
        local id = frameToTarget[current]
        if id then return id end
        seen[current] = true
        current = SafeMethod(current, "GetParent")
        depth = depth + 1
    end
end

function ns:GetExperimentalCDMGeneration()
    local module = EUIState()
    local generation = module and module._cdmClaimGen
    return type(generation) == "number" and not IsSecret(generation) and generation or nil
end
