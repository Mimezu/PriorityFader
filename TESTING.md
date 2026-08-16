# Priority Fader Retail validation

Run this with Ellesmere enabled on a character that can enter and leave combat.
Use `/pfader audit` before and after the pass; it is read-only and reports the
active profile, graph consistency, and currently unavailable adapters.

## Out of combat

1. Open **Choose frame** and watch the one-time `Mapping visible UI` pass. FPS
   should recover immediately when mapping completes; remaining in the picker
   must not cause a sustained drop. Muted wireframes should cover Details,
   visible EUI bars, aura/cooldown viewers, chat, and Minimap regions.
2. Move over overlapping wireframes. Mouse wheel must cycle a stable stack and
   the teal box/title must distinguish an inner frame from the whole window.
   Confirm one named child and one named parent as separate targets. **Choose
   again** / Escape must return cleanly.
3. Open and cancel the picker twenty times. Its wireframe pool must remain
   bounded and no UI frame may change alpha, parent, level, mouse state, or
   scripts merely because it was inspected.
4. Use **Discover visible UI**. It should add visible top-level addon roots in
   one pass without enabling or fading them. Secret MiniAuras geometry must be
   skipped without a BugSack error.
5. Filter for a supported frame, select it, and choose **Use this frame**.
   Confirm Mouseover and In combat start above Otherwise.
6. Add two reactions with different opacity, drag one by its `::` handle past
   the other, and confirm the first matching row is now the intended rule.
7. Create a hover group and a parent→child link. Use **Preview frames** to
   confirm the teal/lavender/amber outlines match the direct relationships.
8. Create, switch, export, import, and delete a disposable profile. The import
   must create a new profile and leave the original untouched.

## Combat and transitions

1. With an action bar and unit frame controlled, enter combat. Verify alpha
   transitions continue, buttons still work, and no protected-action error is
   reported by the game.
2. Attempt picker and preview during combat. Both should refuse safely without
   covering controls or changing visibility.
3. Test fade-out delay while a frame is fading, then change its timing. The
   active fade episode should follow the new delay without a stale deadline.
4. Test conditional mouseover, group hover, and parent-only links. Hovering a
   child must not reveal its parent/siblings.
5. Open **Cinematic**. Toggle it on and off from two different ordinary
   profiles; it must return to the profile active immediately before it was
   enabled. Toggling in combat must refuse without entering a partial scene.
   Enter combat while cinematic is active and verify alpha-only transitions
   continue without protected-action errors.
6. In the Cinematic page, change a component mode, fine-tune it in Advanced
   rules, then return to the page. It must show `Custom rules` and require a
   second click before replacing that fine-tuning. Test Reset defaults, close
   the page, reopen it, and verify Reset requires confirmation again.
7. Assign a temporary Cinematic shortcut, test it, then clear it. Also assign
   a key already used by another command and verify the explicit confirmation;
   entering combat during key capture must cancel without changing bindings.

## Availability and coexistence

1. With Cinematic active, verify Details, chat, action bars, objectives, buffs,
   status/cast bars, EUI data bars, and cooldown viewers remain blacked out.
   Cause chat/cast bars to repaint and open a previously hidden addon window;
   none should flash visibly before returning to zero alpha.
2. Acquire and clear a target. Player and target frames should appear for the
   target and return to true zero at rest. Hover Minimap (including an EUI
   child button) and verify it reveals without showing the rest of the scene.
3. Open Dialogue UI at a quest NPC, loot with Blizzard and SpeedyAutoLoot, and
   test standard/custom/nested OPie rings. Those presentations, enemy
   nameplates, and world quest icons must remain visible. An unrelated
   fullscreen addon window must still be blacked out.
4. Change a blacked-out addon's own alpha while Cinematic is active, then turn
   Cinematic off. Its latest host alpha—not a hardcoded 1—must be restored.
   Repeat on a normal PF-managed target: the PF rule must stay visually in
   charge after the host repaint, then removal must restore that newest host
   alpha.

5. Select a known unavailable adapter. It should remain in the rail with an
   amber status and explanation, not display as host-hidden.
6. Reload UI, disable/re-enable an Ellesmere module, and rerun `/pfader audit`.
   Any missing target should report unavailable; returning frames should resume
   from a fresh fade episode and retain their own host visibility.
7. Do not treat Ellesmere Resource Bars as supported: they remain intentionally
   behind the host-visibility integration gate described in `ROADMAP.md`.
8. Verify that Ellesmere Cooldown Manager options remain clickable and its
   custom styling remains unchanged before and after configuring PF rules.

## Experimental Ellesmere CDM bars

1. In EUI, set each bar being tested to `Always Visible`, then reload once.
2. Search Priority Fader targets for `CDM icons`. Verify one amber experimental
   target exists for Cooldowns, Utility, Buffs, and every enabled custom bar.
3. Configure one bar with Mouseover at 100% and Otherwise at 0%. Verify only
   that EUI bar fades; its neighboring bars remain independent.
4. Trigger EUI cooldown-lowered, inactive, placeholder, proc-glow, and alert
   states. PF must scale their final opacity rather than replacing EUI's
   relative state, custom styling, or layout.
5. Move an ability between EUI bars and change spec. The icon must follow the
   PF rules of its newly assigned bar without retaining the former multiplier.
6. Reset/remove the PF target and disable/re-enable Priority Fader. The latest
   EUI-requested opacity must be restored and EUI options remain clickable.
7. Test a custom EUI CDM bar whose generated key contains a decimal point.
8. Repeat a reveal/fade transition in combat. PF must never show, hide,
   reparent, restyle, or change mouse behavior on an icon.
9. Reload or first enable the PF target during combat, then trigger EUI alert
   and cooldown alpha changes. The bar multiplier must compose immediately.
10. Switch EUI profiles, disable/re-enable EUI CDM, and pick a nested Cooldown
    child. Rebuilt icons must reacquire cleanly and the picker must select the
    semantic CDM bar. Repeat a PF profile handoff during combat.

## Minimap stack

1. Set Minimap Otherwise to 0%, then verify the map, pooled map pins that
   ignore parent alpha, EUI folio/compartment chrome, and the grouped addon
   button panel all disappear visually together.
2. Hover the map and its overhanging EUI child buttons. The normal Minimap
   rule must reveal the stack without changing button positions or clicks.
3. Remove/reset the Minimap target and verify every escaped child returns to
   the opacity last requested by Blizzard or EUI, not a forced 100%.

## Ellesmere player visibility wrapper

1. Enable Cinematic Mode with Player Frame set to Context + hover. Acquire a
   target out of combat: both Player and Target must appear immediately.
2. Test combat, hover, and Alt reveal while EUI's own Player visibility is set
   to Mouseover. Priority Fader's matching rule must take final visibility
   priority without moving, restyling, or changing clicks on the unit frame.
3. Disable Cinematic/remove the Player target. EUI's latest requested wrapper
   alpha must be restored rather than a hardcoded 100%.
