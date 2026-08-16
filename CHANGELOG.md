# Priority Fader changelog

## 2.5.0 - stable CDM viewers and complete minimap flyout fading

- Replaces the private experimental EUI CDM bridge with first-class Blizzard
  Cooldowns, Utility, and Buffs viewer targets. EUI continues to own every
  icon's styling, position, alerts, cooldown state, and bar membership.
- Custom EUI bars intentionally inherit the PF rule of their underlying viewer
  category, avoiding dependencies on EUI's daily-changing private internals.
- Migrates existing picker-created viewer rules to the canonical targets and
  removes obsolete experimental targets without leaving group or link ghosts.
- Treats Minimap as a semantic stack: pooled POI regions, Blizzard tracking
  and indicator branches, UIParent super-tracking, LibDBIcon buttons, and EUI's
  grouped flyout now follow the one Minimap rule without double-fading normal
  descendants.
- Adds built-in logical targets for Details windows. Each one fades the title,
  controls, background, and separately-parented meter rows together instead of
  exposing Details' implementation frames as misleading independent choices.
- Introduces optional semantic providers rather than requiring one personal UI
  stack. Details targets register only when Details exists; Ellesmere Damage
  Meter windows register when that module exists; Blizzard's native Damage
  Meter remains the no-addon fallback. Cinematic quest conversations resolve
  through DialogueUI or Blizzard, and quick-action palettes through OPie or
  Ellesmere Quickdraw.
- Lets discovered and on-screen-picked frames be removed from the catalog with
  a two-step confirmation, cleaning their rules and relationships in every
  profile while keeping built-in adapters intact.
- Makes the Cinematic editing boundary four pixels thick for a clearer mode
  cue while ordinary controls retain the calmer Resonance palette.
- Replaces Cinematic's 20 Hz full blackout sweep with immediate frame hooks,
  reveal-state updates, and a low-rate safety audit. Root discovery is slower
  and load-on-demand addon scans are debounced, removing the largest sustained
  FPS cost when hundreds of UI branches are blacked out.
- Adds visibility inheritance, an optional managed-frame tree, drag-to-link,
  and per-target Copy/Paste so related frames can share behavior without
  duplicating every ordered rule manually.
- Commits brief reveal conditions to their full requested opacity before the
  configured wait and fade-out. Short movement, casts, mouseovers, and target
  changes can no longer leave a frame stranded halfway through its transition.
- Replaces Blizzard's bulky arrow scrollbars throughout the editor with the
  slim Resonance rail and draggable thumb. Every rail is inset into its card's
  reserved gutter, so it no longer overlaps or crops across panel borders.
- Makes Linked child genuinely directional. Hovering the source always reveals
  the child, while hovering the child reveals itself only when that child has
  its own Mouseover row. Existing links keep their existing rows and behavior.

## 2.4.2 - quieter Cinematic identity and quick components

- Limits the warm Cinematic accent to scene controls, the live editing cue,
  and the outer editor border; ordinary controls remain Resonance lavender.
- Fixes Cinematic quick-mode buttons retaining a teal filled hover state.
- Adds Cast Bar (Casting only) and Resource Bars (Combat only) to the default
  Cinematic scene controls and profile template.

## 2.4.1 - managed target filter

- Adds a compact Managed only toggle to the target rail. It shows only frames
  controlled by the current profile without changing any frame or rule.

## 2.4.0 - Cinematic editing clarity and casting state

- Replaces the ambiguous duplicate Rules actions with a single header-level
  Back to editor action and a clearly named Fine-tune profile action.
- Fine-tuning always opens the Cinematic system profile; if the scene is off,
  Priority Fader turns it on first rather than editing the active normal
  profile by accident.
- Introduces a warm Cinematic identity for its dedicated controls and live
  profile editor. Version 2.4.2 narrows that treatment after visual testing.
- Adds `Is casting` as a normal state condition for player casts, channels,
  and empowered casts, including combat-safe event tracking.

## 2.3.0 - experimental EUI CDM icon bars

- Adds one normal Priority Fader target for every live Ellesmere CDM bar,
  including user-created custom bars.
- Uses the EUI bar shell for hover geometry while fading its assigned
  Blizzard icon frames, since those icons are not children of the shell.
- Composes PF opacity with EUI's latest per-icon opacity so hidden,
  cooldown-lowered, alert, placeholder, styling, and layout behavior remain
  owned by EUI.
- Restores the latest EUI-requested opacity whenever PF releases a CDM bar.
- Picker selections on an EUI CDM shell now resolve to its dedicated icon-bar
  target instead of a misleading container-only target.
- Makes no changes to EllesmereUI files or SavedVariables.
- Extends the existing Minimap target to fade descendants that explicitly
  ignore parent alpha and EUI's separate grouped-button panel, while preserving
  each element's own host opacity and click behavior.
- Makes the Ellesmere Player Frame adapter control EUI's real player
  visibility wrapper while retaining the unit frame itself for hover and
  preview geometry. This fixes Player remaining invisible in Cinematic Mode
  even though the equivalent Target rule was active.

## 2.2.6 - reliable visual selector

- Replaced the selector's failing global frame enumeration with the same
  UIParent hierarchy used successfully by visible-UI discovery. Visible roots
  and descendants are mapped incrementally, then indexed for cursor and wheel
  selection.
- Increased overview guides to clear two-pixel lavender wireframes and stacked
  candidates to teal, while keeping every overlay mouse-transparent.
- Mapping totals now remain visible after scanning and distinguish an empty map
  from simply pointing at world space outside a UI frame.
- Cinematic Mode now explicitly exempts Blizzard's nameplate driver and
  Ellesmere's anonymous pooled enemy/friendly nameplate roots, including while
  those pools are hidden and waiting to be reused.
- Untouched Cinematic player/target defaults now reveal for combat, any target,
  or hover. Existing customized rules remain unchanged.

## 2.2.5 - full-canvas editor peek

- Added a compact Peek control to the Rules header. It collapses the full
  editor into a small top-center return bar so the entire game canvas can be
  inspected without moving or resizing the options window.
- The selected target's live teal outline remains visible during Peek, making
  centrally positioned frames easy to identify before returning to the exact
  editor state.

## 2.2.4 - horizontal slider input

- Explicitly set opacity, reaction-duration, transition-time, and fade-delay
  sliders to horizontal orientation. Their input direction now matches the
  visible track and thumb movement.

## 2.2.3 - frame map recovery and edit-in-context

- Fixed the visual frame atlas publishing an empty map after its deferred
  finalization failed silently. Mapping now uses an explicit visible-parent
  walk and completes directly, while the expensive frame enumeration remains
  time-sliced.
- The picker now reports both checked and eligible frame counts while mapping,
  and gives a useful diagnostic instead of a misleading empty hover state if
  no readable frames can be published.
- Selecting a target in the Rules editor now draws a persistent,
  mouse-transparent teal boundary around the live frame. The existing preview
  control is now an on-by-default outline toggle; the marker follows moving
  frames and disappears with the editor or on the Cinematic page.
- Hover-group and linked-child choices now live in a bounded two-column
  scroll area with mouse-wheel support, so discovered frames cannot overflow
  the modal or cover its actions.

## 2.2.2 - visual frame atlas and cinematic hardening

- Rebuilt Pick on Screen around a one-time, time-sliced UI atlas. The picker no
  longer walks thousands of live frames every tenth of a second, and cursor
  selection uses a small cached spatial index after mapping completes. The
  full frame list and atlas finalization are completed incrementally without a
  silent frame-count cutoff.
- Added pooled, mouse-transparent wireframes for the main visible UI regions.
  Moving over a box reveals its local frame stack; the mouse wheel now chooses
  the exact inner frame or whole-window scope shown by the teal outline.
- Added descendant-union geometry for zero-sized addon anchors, stable named
  child-frame persistence, and a bounded session-only fallback for anonymous
  frames. Auto-discovery remains a single read-only pass.
- Cinematic Mode now uses WoW's native UI-role suppression where available,
  without touching UIParent or suppressing unit frames and the Minimap. Addon
  roots remain controlled by Priority Fader's reversible alpha ledger.
- Added guarded OnShow/SetAlpha post-hooks for blacked-out roots so chat, cast
  bars, and other self-repainting addon frames cannot flash between evaluator
  ticks. Host alpha remains the value restored when Cinematic Mode ends.
- Normal managed targets now use the same guarded ownership principle: a host
  repaint updates the restoration alpha while PF immediately reapplies its
  current rule opacity. Hidden transient frames are prepared before Show.
- Cinematic defaults are now truly hidden at rest: player and target appear
  with any target (or hover), while the Minimap appears on hover. Existing
  untouched 2.2 defaults migrate; customized Advanced rules are preserved.
- Replaced broad fullscreen/OPie guesses with exact read-only preservation for
  OPie's shared proxy and anonymous ring renderer, Dialogue UI's quest frame,
  Blizzard loot/dialog frames, and SpeedyAutoLoot's compact loot display.
- Ellesmere's shared secure unit-frame hider is handled as a structural
  pass-through: player/target remain rule-owned while focus, pet, ToT, and boss
  siblings join the blackout. Minimap hover includes its visible EUI controls.

## 2.2.1 - Explorer recovery

- Fixed the live picker and visible-UI discovery stopping at the first modern
  Blizzard frame whose geometry is protected by secret values. Those frames
  are now skipped safely, allowing the scan to continue to ordinary addon and
  EUI roots.

## 2.2.0 - Cinematic blackout scene

- Cinematic Mode now snapshots visible, eligible top-level UI roots and fades
  them to a true blackout, including normal addon windows such as Details.
- Player frame, target frame, and Minimap keep their simple Cinematic rules;
  action bars, chat, objectives, and other UI are now blacked out by default.
- Added `Rescan` for newly opened UI and `Keep a frame`: hold Alt to reveal the
  scene, pick a root, and make it a persistent exception when it has a name.
- Nameplates, OPie, loot, warnings, dialogs, and system UI remain protected
  exceptions. The blackout only changes alpha; it never edits another addon's
  settings, layout, styling, click handling, or code.

## 2.1.0 - Live frame explorer

- Replaced the adapter-only frame picker with a live UI-frame explorer. Hover
  any visible UI, use the wheel to step through overlapping roots, then select
  the root Priority Fader should manage.
- Named roots are saved and restored on reload; anonymous roots are clearly
  marked session-only rather than becoming broken saved targets.

## 2.0.2 - Picker and Cinematic repairs

- Fixed the frame picker’s rectangle handling, which could repeatedly error on
  a valid frame and prevent selection.
- Fixed the Cinematic page reference, so opening, closing, and its controls
  now address the actual page instead of a missing panel field.

## 2.0.1 - CDM integration rollback

- Removed the experimental Ellesmere Cooldown Manager bridge and all CDM
  targets. Priority Fader no longer changes, depends on, or hooks EUI source.
- Saved CDM targets and their relationships are removed safely during the
  update, leaving EUI's own CDM styling, options, and click behavior alone.
- CDM will remain unsupported until there is a stable, official integration
  surface that works without modifying EUI.

## 2.0.0 - Cinematic Mode

- Added a dedicated Cinematic Mode page: a quiet, reversible questing view
  backed by its own managed profile and a remembered return profile.
- Added simple scene controls for player/target frames, main action bar,
  minimap, objectives, and chat. Advanced changes remain available through
  the normal ordered-rule editor while the cinematic scene is active.
- Enemy nameplates, OPie, and loot windows remain intentionally untouched and
  owned by their existing UI systems.
- Added an unbound native `Toggle Cinematic Mode` keybinding, `/pfader
  cinematic`, and a combat-safe in-addon shortcut capture with replacement
  confirmation and rollback if WoW cannot save a new binding.
- Resetting the scene is explicitly confirmed, expires after a short delay,
  and never strands a previously faded target.

## 1.9.0 - Ellesmere Cooldown Manager bridge

- Added a composition-safe bridge for every normal live Ellesmere Cooldown
  Manager bar, including user-created bars. The target catalog discovers live
  bar keys through EUI's module API; it never reads EUI's saved settings.
- Priority Fader now contributes an external opacity multiplier inside EUI's
  own icon-opacity pipeline. EUI keeps ownership of visibility, placeholders,
  cooldown-state effects, vehicle handling, and combat-safe icon behavior.
- CDM targets require the EUI bar to use **Always visible**. If EUI hides a
  bar for one of its own rules, Priority Fader respects that decision.

## 1.8.0 - repeatable validation

- Added `/pfader audit` (also `/priorityfader status`): a bounded, read-only
  chat report of adapter availability and active-profile graph health.
- The audit distinguishes expected unavailable frames from configuration faults
  and checks group/link structure, link loops, and connected-hover fallbacks.
- Added a focused [Retail validation script](TESTING.md) covering picker UX,
  direct priority ordering, relationships, profiles, combat, and coexistence.

## 1.7.0 - direct priority ordering

- Added direct drag reordering for reaction rows. A teal insertion line shows
  where the row will land; priority changes only when the drag is released.
- The drag operation uses one temporary, mouse-transparent overlay, respects
  scrolled lists and UI scale, and safely cancels when the editor closes.
- Retained the arrow controls as a compact precise alternative.

## 1.6.0 - adapter diagnostics

- The target rail now keeps every registered adapter visible. Amber entries
  explain why a frame is not currently available instead of silently vanishing.
- Selecting an unavailable target preserves its rules and shows a plain-language
  recovery message; available, host-hidden, and unavailable states are now
  distinct throughout the runtime and editor.
- Reworked shared tooltips so they retain the Resonance-style hover feedback
  without replacing button scripts or accumulating handlers.

## 1.5.0 - faster target setup

- Added a compact literal filter to the target rail. Search by frame name,
  source, or stable adapter ID without disturbing the current rule editor.
- Added a two-second, read-only frame preview. It outlines the selected frame
  plus its direct hover-group and link relationships, using no opacity or
  protected-frame changes.
- Kept the target rail independently pooled, so filtering remains lightweight
  even while the selected target has a large rule stack.

## 1.4.0 - portable profiles

- Added compact validated export/import for individual profiles. Imports have a
  versioned envelope, integrity check, size limits, and always create a new
  profile rather than replacing one.
- Added bounded, scrollable transfer and reaction editors, with clear
  validation feedback and no unbounded pasted-data or row allocation path.
- Hardened profile graphs: groups are disjoint, links are loop-free and capped,
  and every connected frame keeps its required unconditional Mouseover rule
  without exceeding the per-target reaction limit.

## 1.3.0 - named profiles

- Added compact named profiles: create a safe copy of the active setup, switch
  directly, and delete only after a clear confirmation. Default is preserved
  as the recovery profile.
- Profile switches restore the previous profile's alpha before a new profile
  claims the frame, including guarded handoff for provider frames that fail a
  restore temporarily.

## 1.2.0 - expanded Ellesmere unit frames

- Added explicit Ellesmere adapters for pet, target-of-target, focus target,
  and boss frames, all verified against the installed Ellesmere version.
- Made the target rail scrollable as the supported catalog grows.
- Retired the former invisible Resource Bars anchor and cleaned its old saved
  relationships. Individual resource bars remain deferred until Ellesmere can
  offer a safe host-visibility integration point.

## 1.1.0 - capability guidance

- Added clear, color-coded capability status in both picker stages, so a frame's
  limitations are visible before it is selected.
- Added bounded explanatory guidance in the target editor and a documented
  adapter API for external UI authors to describe their own limits.

## 1.0.0 - frame timing

- Replaced the old cycling fade button with a compact timing panel for each
  target: transition time (0.05–2.00s) and fade-out delay (0–5.00s).
- Timing edits apply live, including while a frame is already waiting to fade;
  the summary now states both values plainly.

## 0.9.0 - timed reactions

- Moment reactions now show their duration directly in the priority stack and
  open the same compact preset-and-slider control used for opacity.
- Added exact quarter-second durations from 0.5 to 30 seconds, plus a live
  countdown in the active-state chip while a timed reaction is winning.

## 0.8.0 - advanced reactions

- Added optional all-of requirements to every reaction row: configure compact
  combinations such as **In combat + Has hostile target** with one opacity.
- Preserved first-match priority, including requirements and timed moments, so
  complex rows stay clear and predictable.
- Made hover groups and links self-protecting: connected frames always retain
  an unconditional Mouseover reaction, including when an older profile loads.

## 0.7.0 - provider integration

- Added a deliberately narrow, versioned `PriorityFaderAPI.RegisterTarget()`
  adapter API for other UI authors.
- Added [integration guidance](INTEGRATION.md) and strict frame contract
  validation; providers cannot alter profiles or opacity rules.
- Tracked the actual frame instance controlled by each target, restoring it
  safely when a resolver changes, fails, or is removed.

## 0.6.0 - broader safe reactions

- Added out-of-combat, stationary/falling, Shift/Control/Alt, flight-path,
  open-world/scenario, War Mode, and more precise quest/loot reactions.
- Split quest moments into accepted, turned in, and objective-updated variants.
- "Looted an item" now reacts only to a guarded local-player loot event; party
  and raid loot messages cannot activate it.

## 0.5.0 - intentional frame selection

- Picker now follows a safe Pick -> Confirm -> Use flow. First click freezes
  the spotlight; only **Use this frame** changes the profile.
- Added Choose again, reliable Escape restoration, and no unexpected editor
  opening when `/pfader pick` is used from a closed window.
- Picker cancels cleanly for combat, pet battles, and world transitions, and
  validates a selected frame's geometry before applying it.

## 0.4.0 - opacity controls

- Replaced opacity click-cycling with a compact modal control: six useful
  presets plus a precise live slider.
- Added modal input capture and Escape/Done dismissal for the opacity control.

## 0.3.0 - relationship editor

- Replaced the remaining vanilla group/link menus with a compact multi-select
  connection editor in the Resonance visual language.
- Added direct add/remove editing for hover groups and linked children, with
  Done/close/Escape controls and clear source labels.
- Linked parent hover now propagates through its descendant branch; cycles are
  rejected before they can be saved.

## 0.2.0 — rule palette and safe state snapshot

- Added a categorized, compact reaction palette: Presence, Target, Travel,
  Group & instance, World, and Moments.
- Added safe, fail-closed target, travel, group, instance, world, and
  event-moment conditions.
- Sampled game state once per evaluation pass; all targets now share that
  snapshot while mouseover remains target-specific.
- Added database v2 migration and stable numeric reaction/group IDs.
- Added active-rule highlighting, a locked **Otherwise** fallback label, and
  basic relationship status/removal controls.
- Linked parents now reveal their full descendant branch; hovering a child
  continues to reveal that child alone.
- Preserved combat safety: the addon remains alpha-only and picker cancellation
  no longer reopens settings when combat begins.

## 0.1.0 — first playable build

- Initial adapters, ordered opacity reactions, spotlight picker, grouping, and
  parent-to-child hover links.
