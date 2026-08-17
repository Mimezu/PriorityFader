# Frame Gambit Retail validation

Run this with Ellesmere enabled on a character that can enter and leave combat.
Use `/pfader audit` before and after the pass; it is read-only and reports the
active profile, graph consistency, and currently unavailable adapters.

## Help Center and guided tutorial

1. Open Frame Gambit and confirm Help shows a small teal notification before
   completing the tour.
2. Open Help and switch through every topic. No frame setting should change.
3. Start the tutorial on a profile with no managed targets. Complete the
   practice-frame Manage, Mouseover, priority, and Otherwise actions. They
   must gate Next without creating or changing a real target.
4. Test Back, Next, Skip, the close button, and Escape; every exit must remove
   the highlight and leave the editor usable. Clicking real Pick or Peek while
   the tour is open must cancel cleanly and must not strand an overlay.
5. On the priority step, select Quiet, Combat, Hover, and Both. Swap the first
   two rows and confirm the displayed winner changes only for Both.
6. Close and reopen the editor mid-tour. No tutorial overlay may remain.
   Also click Help during the tour: the coach must close, Help must open above
   the editor, and Resume must return to the saved step.
7. Enter combat during the priority-board step. The tutorial card and outline
   must disappear, accept no clicks, and resume at the same step after combat.
8. Finish the tour and confirm the Help notification clears. Restart it, then
   abort; completion and the cleared notification must be preserved.
9. Run the tour for more than 2.5 seconds while Cinematic is active. Its card
   and outline must remain fully visible through Cinematic root rescans.
10. Resize the editor to 760x500. The subtitle must stop before Help, and the
   compact tutorial must dock without drawing a highlight beneath its card.
11. Compare the active profile before and after. Targets, reactions,
   relationships, timing, and opacity must remain unchanged.

## Cinematic letterbox

1. Open Cinematic options, enable Black bars, and drag Bar height from 4% to
   25%. While Cinematic is off the saved height must change without showing
   either bar.
2. Enable Cinematic and verify equal opaque black bars appear at the top and
   bottom, remain mouse-transparent, and resize live with the height slider.
3. Change UI scale or window resolution, then disable Cinematic. The bars must
   resize proportionally and disappear immediately without affecting any
   Blizzard, Ellesmere, OPie, DialogueUI, or other addon frame.
4. Reset Cinematic defaults and verify the letterbox returns to Off at 10%.

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
   Add one disposable named and one anonymous session frame, then use **Remove
   from list**. The first click must only arm confirmation; the second removes
   the catalog entry and every profile relationship. Built-in targets must not
   offer this action.
5. Filter for a supported frame, select it, and choose **Use this frame**.
   Confirm Mouseover and In combat start above Otherwise.
6. Add two reactions with different opacity, drag one by its `::` handle past
   the other, and confirm the first matching row is now the intended rule.
7. Create a hover group and a parent→child link. Use **Preview frames** to
   confirm the teal/lavender/amber outlines match the direct relationships.
8. Create, switch, export, import, and delete a disposable profile. The import
   must create a new profile and leave the original untouched.
9. Select a configured frame and press Copy. Select another frame; Paste must
   light only while the internal rule copy is valid. Paste it and verify fresh
   reaction IDs, identical order/timing/opacities, and no copied relationships.
10. Switch the target rail between List and Tree. Link an unmanaged child by
    dragging it onto a managed parent: it must become an indented clean follower
    with no starter rows shadowing inheritance. Add a local child rule and
    verify it wins when matched, then falls back to the parent's result. Reject
    cycles and a second parent. Switch back to List without changing behavior.

## Details windows

1. With two Details instances visible, use the built-in `Details window 1` and
   `Details window 2` targets. Otherwise 0% must fade each matching title bar,
   toolbar, background, and damage/healing rows as one unit.
2. Hover the title and the meter body; both regions must satisfy Mouseover for
   only their own logical window.
3. Change a Details window's displayed attribute, skin, size, and position.
   Priority Fader must not alter those settings. Disable/re-enable an instance
   and confirm its latest Details alpha is restored when PF releases it.
4. Use Pick on screen over a Details title, row, and nested control. Each must
   resolve to the canonical built-in Details window rather than create another
   partial custom target. Previously discovered partial Details entries may be
   removed with `Remove from list`.

## Optional providers and fallbacks

1. With Details enabled, verify Details window targets are registered and the
   Blizzard Damage Meter remains a separate native fallback. Disable Details
   and reload: no Details rows may remain in a fresh catalog, and `Blizzard
   Damage Meter` must resolve when its native window is enabled.
2. Enable Ellesmere Damage Meters and verify one target per current window
   slot. Rebuild/switch its profile and confirm current frames are reacquired
   without changing EUI styling or settings.
3. Test Cinematic quest interactions once with DialogueUI and once without it;
   the active DialogueUI or Blizzard quest conversation must remain visible.
4. Open OPie and Ellesmere Quickdraw separately during Cinematic. Their live
   palettes must remain visible and interactive while unrelated UI stays dark.

## Combat and transitions

1. With an action bar and unit frame controlled, enter combat. Verify alpha
   transitions continue, buttons still work, and no protected-action error is
   reported by the game.
2. Attempt picker and preview during combat. Both should refuse safely without
   covering controls or changing visibility.
3. Test fade-out delay while a frame is fading, then change its timing. The
   active fade episode should follow the new delay without a stale deadline.
   With a long transition, briefly trigger Moving, Is casting, and Has target;
   each reveal must still reach its requested opacity, then wait for the full
   configured delay, then fade toward the newly matching rule.
4. Test conditional mouseover, group hover, and parent-only links. Hovering a
   child must not reveal its parent/siblings.
   Create a linked child with Otherwise at 0%, then remove its Mouseover row:
   hovering the source must fully reveal it, while hovering the child itself
   must leave it hidden. Add Mouseover back and confirm either hover reveals it.
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
8. Add `Is casting` to a cast-bar target with Otherwise at 0%. Test a normal
   cast, channel, empowered cast, completion, failure, and interruption both
   in and out of combat. The state must start and clear without Lua errors or
   exposing spell-name secret values.

## Cinematic editor identity

1. Open the Cinematic page while the mode is off. Its title, outer editor
   border, main Cinematic button, and toggle must use the warm amber identity.
2. Click Fine-tune profile while off. Cinematic must turn on and the ordered
   editor must show `Editing: Cinematic` with the restrained amber mode cues.
3. Use Back to editor from the dedicated page and the Cinematic button from
   the fine-tuning editor. Neither route may open or mutate another profile.
4. Turn Cinematic off and return to a normal profile. The editor returns to
   Resonance lavender while the Cinematic entry button remains orange.
5. Confirm that ordinary target rows, reaction controls, and action buttons
   remain lavender while fine-tuning Cinematic. Only Cinematic controls, the
   live profile cue, subtitle, and outer editor border should use warm amber.
6. On the dedicated page, move the pointer across every quick-mode button.
   No button may remain filled teal after the pointer leaves it.
7. Verify Cast Bar defaults to Casting only and Resource Bars defaults to
   Combat only. Both must remain editable through their quick-mode menus and
   the ordered-rule editor.

## Availability and coexistence

1. Toggle `Managed only` with a mix of controlled and catalog-only targets.
   Only targets belonging to the current profile should remain in the rail;
   switching profiles must immediately reflect that profile without adding or
   removing any rules.

1. With Cinematic active, verify Details, chat, action bars, objectives, buffs,
   status/cast bars, EUI data bars, and cooldown viewers remain blacked out.
   Cause chat/cast bars to repaint and open a previously hidden addon window;
   none should flash visibly before returning to zero alpha.
2. Acquire and clear a target. Player and target frames should appear for the
   target and return to true zero at rest. Hover Minimap (including an EUI
   child button) and verify it reveals without showing the rest of the scene.
   At rest, verify quest POIs, tracked-item pins, mail/tracking indicators,
   LibDBIcon buttons, and EUI's grouped button flyout all follow the Minimap
   opacity. Repeat once with EUI Minimap disabled. Super-tracking must not make
   the entire screen act as the Minimap hover region.
3. Open Dialogue UI at a quest NPC, loot with Blizzard and SpeedyAutoLoot, and
   test standard/custom/nested OPie rings. Those presentations, enemy
   nameplates, and world quest icons must remain visible. An unrelated
   fullscreen addon window must still be blacked out.
4. Change a blacked-out addon's own alpha while Cinematic is active, then turn
   Cinematic off. Its latest host alpha—not a hardcoded 1—must be restored.
   Repeat on a normal PF-managed target: the PF rule must stay visually in
   charge after the host repaint, then removal must restore that newest host
   alpha.
5. Compare FPS with Cinematic off/on in the same static scene for at least 15
   seconds. Alt/Peek and addon alpha repaints must remain immediate without a
   sustained drop from scanning hundreds of roots at frame-update frequency.

6. Select a known unavailable adapter. It should remain in the rail with an
   amber status and explanation, not display as host-hidden.
7. Reload UI, disable/re-enable an Ellesmere module, and rerun `/pfader audit`.
   Any missing target should report unavailable; returning frames should resume
   from a fresh fade episode and retain their own host visibility.
8. Do not treat Ellesmere Resource Bars as supported: they remain intentionally
   behind the host-visibility integration gate described in `ROADMAP.md`.
9. Verify that Ellesmere Cooldown Manager options remain clickable and its
   custom styling remains unchanged before and after configuring PF rules.

## Cooldown Manager viewers

1. In EUI, set each bar being tested to `Always Visible`, then reload once.
2. Verify `CDM · Cooldowns`, `CDM · Utility`, and `CDM · Buffs` are available.
3. Give each category a different rule and confirm its whole viewer fades as
   one layer while EUI styling, placement, alerts, and cooldown states remain
   unchanged.
4. Create or move an EUI custom bar. Confirm it inherits the PF rule of its
   underlying Cooldowns, Utility, or Buffs category.
5. Open every EUI CDM options page before and after PF transitions. Every
   control must remain clickable and all visual settings must remain intact.
6. Change spec/EUI profile and repeat in combat. Viewer fading must resume
   without PF showing, hiding, reparenting, or restyling individual icons.
7. Reset/remove the PF target and switch PF profiles. The latest viewer alpha
   requested by its owner must be restored rather than a forced 100%.

## Minimap stack

1. Set Minimap Otherwise to 0%, then verify the map, pooled map pins that
   ignore parent alpha, EUI folio/compartment chrome, the grouped addon button
   panel, and buttons inside that panel which ignore parent alpha all disappear
   visually together without ordinary children being double-dimmed.
2. Hover the map and its overhanging EUI child buttons. The normal Minimap
   rule must reveal the stack without changing button positions or clicks.
3. Remove/reset the Minimap target and verify every escaped child returns to
   the opacity last requested by Blizzard or EUI, not a forced 100%.
4. Cycle the experimental native-marker control through Leave unchanged, Hide
   at 0%, and Scale with map. Verify Blizzard service/quest markers remain
   unchanged in the first mode, disappear only at full rest in the second,
   and shrink with the fade in the third. Reset/remove Minimap and verify
   standard marker scale returns. Tracking categories must remain unchanged.
5. While Hide at 0% is resting, change zones, change the tracked objective,
   and open/close the map to force native marker rebuilds. No service, quest,
   portal, or tracked-item marker may reappear and remain visible.
6. Set a non-default native marker scale in the owning UI, enable each marker
   mode, then reset/remove Minimap. The exact host scale must return. Repeat a
   release during combat and verify restoration retries after combat.
7. Export and re-import a profile using each marker mode. The mode must survive;
   an older export without marker metadata must still import as Leave unchanged.
8. On a client with no readable native icon-scale getter, verify the editor says
   Markers: unavailable and explains why. It must not write or restore an
   assumed 100% scale. If another UI later calls SetIconScale, reopen the editor
   and verify the controls become available using that captured host value.

## Ellesmere Chat

1. With Ellesmere Chat enabled, configure the canonical Chat target at 0% rest
   with Mouseover reveal. Verify its messages, background, tabs, sidebar and
   chrome fade together and can wake again after reaching zero.
2. Reset/remove Chat and verify Ellesmere immediately resumes its configured
   visibility and idle-fade behavior. Repeat with Ellesmere Chat disabled and
   verify the same target falls back to Blizzard ChatFrame1.
3. Open Chat timing. The transition must be labelled as Ellesmere-owned and
   disabled, while Frame Gambit's fade-out wait remains editable and honored.
4. Try to remove the final unconditional Mouseover row from a relationship
   that requires it. Verify a persistent amber notice receives its own layout
   space, remains readable, and can be dismissed without overlapping rules.

## Ellesmere player visibility wrapper

1. Enable Cinematic Mode with Player Frame set to Context + hover. Acquire a
   target out of combat: both Player and Target must appear immediately.
2. Test combat, hover, and Alt reveal while EUI's own Player visibility is set
   to Mouseover. Priority Fader's matching rule must take final visibility
   priority without moving, restyling, or changing clicks on the unit frame.
3. Disable Cinematic/remove the Player target. EUI's latest requested wrapper
   alpha must be restored rather than a hardcoded 100%.
