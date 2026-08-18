# Frame Gambit changelog

## Unreleased

## 2.8.0 - Corrected public package

- Corrects the malformed 2.6.0/2.7.0 public ZIPs so Frame Gambit loads and
  every documented slash command works after installation.
- Cinematic now recognizes all Blizzard panel-manager windows as intentional
  player windows. It closes them when the scene starts, then keeps any opened
  afterward visible and usable above the scene, including future standard
  panels instead of relying on a hand-maintained exception list. Friends and
  guild/community windows also have direct Retail-version fallbacks. Bags,
  spells/talents, collections, group/PvP finder, calendar, profession, macro,
  keybinding, and common interaction frames have the same fallback coverage.

## 2.6.0 - Cinematic editor and expanded gambits

- Opening the World Map during Cinematic Mode now keeps every map view visible
  above the scene while Cinematic remains active.
- Adds `/fg` as the shortest slash alias for opening Frame Gambit.
- Adds a configurable **Form** reaction with a dense form picker and Yes/No
  state choice. Forms unavailable to the current class/spec are retained,
  muted, and skipped, enabling one profile to safely cover several specs.
  Supported entries are Druid forms, Shadowform, Ghost Wolf, and Demon Hunter
  Metamorphosis, including Devourer Void Metamorphosis.
- Establishes the reusable picker-card Boolean pattern: a two-part **Yes / No**
  control with the selected answer filled. The new **Movement** card uses it
  directly (Yes = moving; No = stationary); old Moving/Stationary rows remain
  supported in saved and imported profiles.
- Adds a repeatable **Spec** picker card. It asks for class first and then a
  spec, preserves other-class rows for shared profiles, and safely skips those
  rows until they apply to the current character.
- Adds **Stealthed / invisible**, **Fishing**, and **In Delve** conditions.
  Stealth refreshes only on player aura changes; fishing uses the player’s
  active Fishing channel; Delves use the supported party-state API.
- Adds an **On/Off** switch to every reaction row. Disabled rows retain their
  ordered configuration, are visibly greyed out, and are skipped by the
  evaluator. Form choice and row-enabled state round-trip through profile
  export/import.
- Added two precise pet conditions: **Class pet active** (the player's combat
  pet unit) and **Cosmetic companion active** (a summoned Pet Journal
  companion). They remain deliberately separate; there is no ambiguous
  "any pet" condition.
- Reflowed the live Cinematic strip into its own header row, so scene toggle,
  black bars, and shortcut controls no longer overlap the editor header or
  Presence panel. Entering Cinematic from the editor keeps it visibly open and
  starts the target rail on **Managed** frames.
- Cinematic editing now remaps the normal teal live-state cue to Cinematic
  orange across the editor. Unavailable and confirm-before-changing states use
  red addon-wide, keeping orange exclusive to Cinematic.
- Enabled reactions now remain fully legible and editable when they are not
  the currently matching row. Only a deliberately disabled **Off** reaction
  is greyed out. The header Cinematic control also becomes **Exit scene**
  while active, providing a second reliable way to return to the prior profile
  without closing the editor.
- The guided-tutorial card now stays above the live editor after each required
  click. On wide screens it docks in the free left column, leaving the real
  highlighted target or control unobstructed.
- Tutorial highlighting now always uses a small real control or rule row. It
  no longer falls back to an oversized editor-panel rectangle after a required
  click changes the editor contents. Reaction On/Off is now beside its drag
  handle, clearly separating row state from the condition's value controls.
- During the guided Mouseover lesson, the palette opens directly on Presence
  and highlights **Mouseover**; after selection, the focus moves to its real
  opacity control for the 100% choice.
- The tutorial now seeds **Otherwise** at 100% beside its 30% Stationary rule,
  so moving immediately demonstrates a visible first-match fallback change.
- Rebuilt the guided tutorial around a visible, session-only **Tutorial
  Frame** with the player's portrait. It is pinned to the real target rail and
  teaches actual selection, management, reaction creation, first-match
  priority, row movement, and Otherwise editing under a focused dim overlay;
  the target and its rules are removed automatically on every exit.
- Removed the dedicated Cinematic page. The orange Cinematic control now
  enters the live Cinematic profile directly in the main editor; its inline
  strip keeps the Cinematic On/Off toggle, black bars, and shortcut together.
- Removed the developer-facing `Run audit` action from Help. The read-only
  diagnostic remains available by `/pfader audit` when troubleshooting calls
  for it.
- Simplified the Cinematic page into scene-wide controls only. Frame
  visibility now has one source of truth: **Edit Cinematic profile** and the
  familiar ordered-rule editor; the duplicate quick-mode rows are gone.
- Removed the redundant Cinematic `Keep a frame` shortcut and its opaque
  exception count. Existing saved keeps are cleared once; use **Edit Cinematic
  profile** to add any custom frame through the normal, visible rules.
- Cinematic's dedicated toggle now leaves the Frame Gambit editor open for
  live scene setup, while slash/keybinding activation continues closing it with
  other game panels.
- Minimap `Hide at 0%` and `Scale with map` now also fade Super Tracking's
  alpha-escaping quest-direction arc when it is clamped to the screen edge.
- Fixed Cinematic's temporary panel exception for `HIGH`-strata windows, so
  EllesmereUI Bags and themed Character panels can appear above the scene when
  opened without disabling Cinematic Mode.
- Rebuilt Frame Gambit's Help & tutorial around the shared Resonance-style
  standalone window: a toggleable `? Help` control, centered draggable layout,
  topic rail, Escape close behavior, and retained tutorial/audit actions.
- Cinematic now closes Blizzard game panels as it starts, preventing invisible
  windows from retaining mouse input. Panels opened afterward, including
  supported top-level addon windows, remain visible above the scene until
  closed without leaving Cinematic Mode.
- Cinematic black bars now allow 0% through 25% (default 4%). At 0%, no
  letterbox is drawn. EllesmereUI Data Bars and XIV Databar remain visible
  above the bars without Frame Gambit changing either addon's frames, while
  world-space names and nameplates remain behind the letterbox.
- Minimap `Hide at 0%` and `Scale with map` now include Blizzard's separate
  quest, archaeology, and task-area rings, which do not follow icon scale.
- Fixed a regression that made experimental native Minimap marker modes
  unavailable on Retail clients exposing `SetIconScale` without a matching
  getter. Selecting a mode is now the explicit opt-in to its documented
  restoration fallback; the default remains untouched.
- Cinematic Mode now defaults its Minimap to `Hide at 0%`, so Blizzard's
  engine-drawn service and quest markers disappear with a fully faded map.
  Existing Cinematic profiles using the old unchanged default are upgraded;
  an intentional `Scale with map` choice is preserved.
- Reduced normal-profile evaluator work: Frame Gambit now queries only states
  referenced by enabled gambits and relies on its guarded alpha post-hooks,
  with a low-rate safety audit, instead of polling every managed frame's alpha
  and every supported game state at 20 Hz.
- Added a compact Help Center with focused guides for Gambits, relationships,
  Cinematic Mode, safety, and troubleshooting.
- Added a reusable, non-destructive guided tutorial for the complete
  Manage → React → Order → Otherwise → Preview flow, followed by a clear handoff
  to the real on-screen picker.
- Added an interactive priority board that demonstrates why the first
  matching line wins without changing a real profile.
- Added safe tutorial persistence, combat pause/resume, contextual highlights,
  and a Help notification until the tour is completed.
- Added optional mouse-transparent Cinematic letterbox bars. Their shared
  height is adjustable from 0% to 25% of the screen and adapts to resolution
  or UI-scale changes without modifying any Blizzard or addon frame.
- Added an experimental Minimap native-marker control with `Leave unchanged`,
  `Hide at 0%`, and `Scale with map` modes. It uses the Minimap compositor's
  icon-scale surface and never edits Blizzard tracking categories. Frame
  Gambit now recomposes later Blizzard scale requests and periodically
  reasserts the result after native marker-layer rebuilds.
- Native minimap marker composition now captures and restores the host's real
  icon scale instead of assuming 100%, accepts host scales above 1, and keeps
  failed restorations pending until they can complete safely.
- On clients where native marker scale is write-only, `Leave unchanged` remains
  completely non-invasive. Explicitly selecting an experimental marker mode
  uses a clearly disclosed 100% restoration baseline until Blizzard or the
  owning UI announces its real scale, preserving functional marker fading.
- Minimap native-marker mode now survives profile export/import through a
  backward-compatible optional record; older profile strings still import.
- The existing Chat target now becomes a complete Ellesmere Chat visibility
  proxy when that module is installed, covering its UIParent-level messages,
  panel, tabs, sidebar and chrome while returning native ownership to EUI when
  the target is released. Blizzard Chat remains the automatic fallback.
- Ellesmere Chat now explicitly uses host-owned physical timing: Frame Gambit
  controls ordered rules and fade-out wait, while Ellesmere performs its own
  supported animation without a competing or misleading duration control.
- Empty non-Cinematic profiles now detach Frame Gambit's shared 20 Hz evaluator
  until an event or editor mutation creates work again.
- Actionable editor warnings now use a persistent, dismissible amber notice
  with reserved layout space instead of being overwritten by the live-state
  label or briefly painting over rule text.

- Began the safe user-facing rename from Priority Fader to **Frame Gambit**.
  The editor, addon metadata, keybinding category, diagnostics, and help copy
  now use the new name and display the creator credit **by Mimezu**.
- Added `/framegambit` and `/fgambit` aliases. Existing `/pfader`, addon-folder,
  SavedVariables, profile export, frame names, and public API identifiers remain
  unchanged for compatibility.
- Fade transitions now finish in the exact configured time instead of using
  repeated easing that could take roughly five times longer. Brief reveals
  still complete before the configured wait and fade-out begin.
- Expanded fade-out wait time from 5 seconds to 15 seconds.
- Added a compact search field to Hover group, Linked children, and Visibility
  children pickers.
- Matched Resonance's raised custom close-button treatment so thick editor
  borders cannot paint over the control.
- Removed the duplicate header frame-picker action, moved the version and
  creator credit to the top-right, and added a Resonance-style resize grip.

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
