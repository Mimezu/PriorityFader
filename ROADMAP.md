# Frame Gambit release plan

## Cinematic Mode (v2.2.2)

- Cinematic Mode is a managed, reversible profile—not a replacement parent UI.
  Turning it on remembers the current normal profile; turning it off restores
  that profile with the same safe alpha handoff used for ordinary switching.
- Its dedicated page gives simple scene modes today and reserves a separate
  Scene actions area for future gestures and other non-visibility behavior.
- The default scene suppresses eligible Blizzard roles through WoW's native
  UI-mode service and leases addon roots (plus explicit shared-parent branches)
  through a reversible alpha ledger. It never changes UIParent alpha, so
  conditional exceptions can still reveal themselves.
- Player and target appear while a target exists (or on hover); Minimap is
  hover-only. Enemy/world nameplates, OPie renderers, Blizzard and SpeedyAutoLoot
  loot, Dialogue UI quests, tooltips, and essential dialogs remain visible.
- A guarded post-hook on a currently leased root closes one-frame races when
  its owner calls Show or SetAlpha. The host's latest requested alpha remains
  the restoration value; the hook is inert outside Cinematic Mode.
- The mode has an unbound native keybinding, `/pfader cinematic`, and an
  in-addon shortcut capture. Binding edits are unavailable in combat.

## Current foundation (v2.2.2)

- Explicit adapters, a one-time time-sliced visual frame atlas, exact named
  frame persistence, and a narrow external-adapter API. The atlas never runs
  continuously and uses pooled mouse-transparent wireframes.
- Ordered opacity reactions: first matching row wins, `Otherwise` is the
  fallback, and advanced rows can require several conditions at once.
- Safe state and moment conditions, group/link hover semantics, timed
  reactions, and per-target transition timing.
- A compact Resonance-style editor with a confirmed spotlight picker,
  capability guidance, searchable target rail, read-only connection preview,
  direct priority ordering, repeatable in-game diagnostics, and an
  independently reviewed SavedVariables migration path.

## Current profile support and portability (v1.8)

- Named profiles can be created as a copy of the active setup, switched, and
  deleted with a safe Default fallback and explicit confirmation.
- Profile switching restores the old profile's controlled alpha before the
  new profile evaluates, including a guarded deferred handoff for providers.
- Individual profiles can be exported and imported through a bounded,
  validated transfer flow. Imports are integrity checked, require a new name,
  and cannot replace an existing profile.
- Profile transport accepts only a deliberately capped, loop-free graph with
  connection-safe hover fallbacks, so an imported setup remains editable.

## Ellesmere Cooldown Manager

Version 2.5 uses the stable Blizzard Cooldown Manager viewers as the ownership
boundary. This keeps Priority Fader above EllesmereUI: EUI continues to style,
position, group, and animate icons, while PF fades the Cooldowns, Utility, or
Buffs viewer as a whole.

Custom EUI bars inherit the rule for their underlying viewer category. Per-EUI
bar independence remains a possible future enhancement only if Ellesmere
publishes a durable read-only bar membership API; PF will not patch EUI or
depend on its private daily-changing internals to provide it.

## Host-visibility adapters (research gate)

Ellesmere resource bars deliberately remain unsupported. Their host uses
`IsShown() + alpha 0` as its own visibility state, so a generic fader could
incorrectly reveal a bar that Ellesmere intentionally hid.

Before adding them, define an opt-in adapter contract that supplies:

- a stable hover rectangle or composite rectangle;
- a host-visible signal that is independent from Priority Fader's alpha; and
- a way to restore only Priority Fader's contribution without overriding the
  host's visibility decision.

Normal target adapters never inspect external databases or execute global-frame
path scripts. A guarded alpha post-hook records the latest host alpha and
reapplies PF's current rule opacity while controlled; it cannot distinguish an
alpha-zero host visibility sentinel from a styling alpha. That ambiguity is why
resource bars still require a richer opt-in host-visible contract.

## Live validation before broader release

Test each release in retail WoW with Ellesmere enabled:

1. Out of combat: pick, confirm, reset, and restore every supported target.
2. In combat: action/unit-frame alpha transitions, no protected-action errors,
   no picker/editor input interception.
3. Rules: hover priority over ordinary reactions, all-of requirements,
   moment expiry, and transition-delay edits while fading.
4. Relationships: group reveal, parent-only propagation, removal, and profile
   migration from old saved variables.
5. Coexistence: reload UI and disable/re-enable Ellesmere modules to ensure
   unavailable adapters never leave a stale alpha behind.
