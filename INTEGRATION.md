# Priority Fader integration API

Priority Fader is a companion layer: it owns only its own opacity rules and
saved variables.  An external UI can opt in by registering a stable adapter;
it must not expose its configuration database.

```lua
local ok, reason = PriorityFaderAPI.RegisterTarget({
  id = "myui.main_bar", -- Stable forever; changing it loses the user's rule.
  label = "Main action bar",
  source = "My UI",
  protected = true,
  capability = "Live fade in combat",
  capabilityTone = "teal", -- teal, accent, amber, or muted
  capabilityNote = "Priority Fader fades this bar but never changes its secure buttons.",
  resolve = function()
    return MyUI_MainBar
  end,
})
```

`resolve()` may return `nil` until the frame exists.  The returned frame must
provide `GetRect`, `IsShown`, `GetAlpha`, and `SetAlpha`.  A provider may
alternatively pass stable global frame names as `names = { "MyUI_MainBar" }`.

Registration is intentionally one-way.  Providers cannot change profiles,
reactions, alpha values, or relationship settings. Priority Fader never shows,
hides, reparents, or changes secure attributes on registered frames. While a
target is actively controlled, a guarded `SetAlpha` post-hook remembers the
host's newest alpha for restoration and reapplies PF's current opacity. The
hook is inert after ownership ends and never replaces the host method.

The in-game frame atlas can also register an exact named global frame without
an adapter. Unnamed frames are deliberately session-only. Adapter registration
remains preferable when a UI needs a composite hit region, host-visibility
signal, dynamic resolver, or more precise capability guidance.

Cinematic Mode separately leases eligible top-level UI roots and explicit
shared-parent child branches for its blackout scene. It uses guarded post-hooks
only to reapply zero alpha when a leased frame shows or its owning addon
repaints alpha. Those hooks are inert outside the scene and never replace frame
methods, mouse behavior, layout, or styling.

`capability` and `capabilityTone` are optional user-facing guidance shown in
the target editor and picker. `capabilityNote` is the bounded explanatory copy
shown in the editor. They describe the adapter's limits; they do not grant
Priority Fader any extra control over the frame.

Keep `label` and `source` to at most 64 characters, `capability` concise (48
characters or fewer), and `capabilityNote` to at most 240 characters so they
remain readable in the compact editor and bounded in diagnostic output.

## Ellesmere Cooldown Manager

Priority Fader 2.3 adds an experimental target for each live EUI CDM bar,
including custom bars. EUI's bar frame supplies the hover area, while Priority
Fader multiplies the final opacity EUI requests for the Blizzard-owned icons
assigned to that bar. At 100%, the icons use EUI's exact opacity; at 0%, they
are visually suppressed. EUI retains styling, placement, cooldown states,
alerts, and icon membership.

Set each managed bar's EUI visibility to **Always Visible**, then configure its
`CDM icons · ...` target through the normal Priority Fader workflow. The
integration does not edit EUI source or SavedVariables and requires no EUI
patch. It is marked experimental because EUI's internal runtime API is not a
published compatibility contract and may change in a future daily update.

## In-game audit

Run `/pfader audit` (or `/priorityfader status`) to print a read-only summary
of the active profile, its relationship graph, and adapter availability. This
is useful before reproducing a frame issue; it never changes a profile or a
registered frame.
