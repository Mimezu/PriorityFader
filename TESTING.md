# Frame Gambit Retail validation

Run this with Ellesmere enabled on a character that can enter and leave combat.
Use `/pfader audit` before and after the pass; it is read-only and reports the
active profile, graph consistency, and currently unavailable adapters.

## Help Center and guided tutorial

1. Open Frame Gambit and confirm Help shows a small teal notification before
   completing the tour.
2. Open Help and switch through every topic. Confirm it is a centered,
   draggable standalone window with Resonance's topic rail, responsive scale,
   and Escape-close behavior. Close the editor while Help is open; Help must
   close with it. No frame setting should change.
3. Start the tutorial on a profile with no managed targets. A temporary
   portrait **Tutorial Frame** must appear at top-left and be pinned first in
   the real target rail. Complete Select, **Use this frame**, Stationary 30%,
   Mouseover 100%, row priority, and Otherwise with the real editor controls.
4. Each step must spotlight only its real control (and the temporary frame)
   while the rest of the UI is dimmed. The tutorial card and Tutorial Frame
   must remain readable and clickable above that dim layer.
5. On the priority step, hover while Stationary is first: the Tutorial Frame
   stays dim. Move Mouseover upward with the real `^` control, then hover it
   again: it reveals. Next must require both observations.
6. Test Back, Next, Skip, close, Escape, Help, Pick, Peek, closing the editor,
   and `/reload` mid-tour. Each interruption must clear the spotlight and
   remove the Tutorial Frame, its session target, and its rules. Resume may
   recreate only the lesson prerequisites; existing profile data stays intact.
7. Enter combat during the priority step. The tutorial card and spotlight must
   disappear, accept no clicks, and resume at the same step after combat.
8. Finish the tour and confirm the Help notification clears. Restart it, then
   abort; completion and the cleared notification must be preserved.
9. Run the tour for more than 2.5 seconds while Cinematic is active. Its card
   and temporary frame must remain fully visible through Cinematic root scans.
10. Resize the editor to 900x560. The subtitle must stop before Help, and the
   compact tutorial must dock without drawing a highlight or dim layer.
11. Compare the active profile before and after. Targets, reactions,
   relationships, timing, and opacity must remain unchanged.

## Cinematic letterbox

1. Open Cinematic options, enable Black bars, and drag Bar height from 0% to
   25%. While Cinematic is off the saved height must change without showing
   either bar.
2. At 0%, enable Cinematic and verify neither bar is shown. At any positive
   height, verify equal opaque black bars appear at the top and bottom, remain
   mouse-transparent, and resize live with the height slider.
3. Change UI scale or window resolution, then disable Cinematic. The bars must
   resize proportionally and disappear immediately without affecting any
   Blizzard, Ellesmere, OPie, DialogueUI, or other addon frame.
4. Reset Cinematic defaults and verify the letterbox returns to Off at 4%.
5. With cinematic bars enabled, verify EUI Data Bars and XIV Databar remain
   visible above the bars, while world-space nameplates and unit names behind
   the bar are covered. Neither data-bar addon should have any changed frame
   settings or lost interaction.
6. Open the Character panel and EllesmereUI Bags, then enable Cinematic. Both
   panels must close with the other game windows so they cannot retain mouse
   input while invisible. While Cinematic remains active, reopen Character,
   Bags, and `/res`: each must be visible and usable above the scene, then
   return to the blackout when closed.
7. While Cinematic remains active, open the main Blizzard panels: Character,
   Spellbook, Talents, Collections, Quest Log, Friends, Guild/Communities, and
   the World Map. Each must remain visible and usable above the scene without
   turning Cinematic off, then return to the blackout when closed. Switch the
   World Map between continent, zone, dungeon, and Delve views as part of this
   check.
8. Press the usual shortcut bindings for Bags, Character, Spells, Talents,
   Quest Log, Map, Social, and Guild. Also check Collections, Group Finder,
   PvP, Calendar, Professions, Macro, Key Bindings, and Escape. None may open
   invisibly or retain mouse input; closing it returns that window to the
   Cinematic blackout.
9. Press the orange Cinematic header button. The main editor must stay open,
   gain its orange border and show a separate inline Cinematic strip without
   covering the subtitle or Presence
   panel. Managed dots and live-state accents must be orange; unavailable
   target dots and warning/confirm states must be red. Use the strip's
   `Turn off` button to return to the previous profile without closing the
   editor. Slash/keybinding activation still closes the editor with other game
   panels.

## Out of combat

1. Add a **Form** reaction, select a form for the current class/spec, and
   verify **Yes** matches only while it is active and **No** only while it is
   inactive. Choose a form for another class/spec: its row must be visibly
   muted and must never match, including when set to No.
2. Turn a matching row **Off**. It must remain in place with its picker choice,
   opacity, requirements, and priority intact, become muted, and be skipped.
   Turn it On and confirm the original behavior returns.
3. Add two **Movement** cards. Each must show the same clear Yes/No segment;
   Yes matches only while moving and No only while stationary. Reorder them,
   then add a second Form card and confirm each configurable card keeps its
   own picker value and Boolean answer.
   In both Add reaction and Add requirements, confirm the top **CATEGORIES**
   rail is visually distinct from condition cards: muted category labels use
   a thin active underline, while selectable conditions remain raised cards.
   Open **Add reaction** with no AND picker involved and confirm every card in
   the selected category is visible and selectable.
   Add AND requirements from two categories and reopen the picker: each
   category holding a saved requirement must show a small teal corner marker.
   Hover the row's `+N` button and confirm its tooltip lists the base
   condition and all N added requirements.
   Add **In arena**, then confirm **In Delve**, **In dungeon**, **In open
   world**, every other specific instance type, **In party**, and **In raid** are greyed out
   and cannot be selected. Existing incompatible imported/saved requirements
   must be red but remain clickable so the player can remove them.
   In Travel, add **Pet battle** and confirm Vehicle, Flight path, Fishing,
   Mounted, Flying, Dragonriding, Swimming, and Underwater grey out. Remove
   it, then confirm Vehicle, Flight path, and Fishing are mutually exclusive,
   while **Swimming** and **Underwater** remain valid together.
   In Moments, select one quest event and confirm the other quest-event cards
   grey out. Loot window opened and Looted an item must remain combinable.
4. Add a **Spec** card. Its picker must ask for class first, then spec. Choose
   the current class/spec and confirm it matches; choose another spec in the
   class and confirm it is greyed when unmatched; choose another class and
   confirm it is retained, dimmed, and skipped. Add a second Spec card to
   verify the two rows remain independent and reorder normally.
5. On a character or effect that WoW reports as stealthed/invisible, verify
   **Stealthed / invisible** reacts immediately on entering and leaving it.
   Start and cancel Fishing to verify **Fishing** follows the player channel.
   Enter and complete a Delve to verify **In Delve** remains active through
   the run and turns off outside it.
6. Add a **Class pet active** reaction to a disposable target. Summon and
   dismiss a combat/class pet; only the first action must reveal the target.
   A cosmetic companion must not satisfy this condition.
7. Add a **Cosmetic companion active** reaction to a separate disposable
   target. Summon and dismiss a Pet Journal companion; only the first action
   must reveal that target. A combat/class pet must not satisfy it.
8. Open **Choose frame** and watch the one-time `Mapping visible UI` pass. FPS
   should recover immediately when mapping completes; remaining in the picker
   must not cause a sustained drop. Muted wireframes should cover Details,
   visible EUI bars, aura/cooldown viewers, chat, and Minimap regions.
9. Move over overlapping wireframes. Mouse wheel must cycle a stable stack and
   the teal box/title must distinguish an inner frame from the whole window.
   Confirm one named child and one named parent as separate targets. **Choose
   again** / Escape must return cleanly.
10. Open and cancel the picker twenty times. Its wireframe pool must remain
   bounded and no UI frame may change alpha, parent, level, mouse state, or
   scripts merely because it was inspected.
11. Use **Discover visible UI**. It should add visible top-level addon roots in
   one pass without enabling or fading them. Secret MiniAuras geometry must be
   skipped without a BugSack error.
   Add one disposable named and one anonymous session frame, then use **Remove
   from list**. The first click must only arm confirmation; the second removes
   the catalog entry and every profile relationship. Built-in targets must not
   offer this action.
12. Filter for a supported frame, select it, and choose **Use this frame**.
   Confirm Mouseover and In combat start above Otherwise.
13. Add two reactions with different opacity, drag one by its `::` handle past
   the other, and confirm the first matching row is now the intended rule.
   During the drag, the complete reaction card must follow the cursor and the
   remaining cards must make a live card-sized gap at the prospective drop
   position. Its condition text must stay centered like a stationary card;
   cancelling must restore the original order and card appearance.
14. Create a hover group and a parent→child link. Use **Preview frames** to
   confirm the teal/lavender/red outlines match the direct relationships.
15. Create, switch, export, import, and delete a disposable profile. The import
   must create a new profile and leave the original untouched.
16. Select a configured frame and press Copy. Select another frame; Paste must
   light only while the internal rule copy is valid. Paste it and verify fresh
   reaction IDs, identical order/timing/opacities, and no copied relationships.
17. The target rail always shows its hierarchy. Link an unmanaged child by
    dragging it onto a managed parent: it must become an indented clean follower
    with no starter rows shadowing inheritance. Add a local child rule and
    verify it wins when matched, then falls back to the parent's result. Reject
    cycles and a second parent.

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
6. Enter Cinematic from the orange header button. The normal editor must be
   the only place to edit targets and ordered rules; no dedicated Cinematic
   page or duplicate quick-mode rows may appear. Its inline strip must expose
   Cinematic: On, Shortcut, and Black bars only.
7. Assign a temporary Cinematic shortcut, test it, then clear it. Also assign
   a key already used by another command and verify the explicit confirmation;
   entering combat during key capture must cancel without changing bindings.
8. Add `Is casting` to a cast-bar target with Otherwise at 0%. Test a normal
   cast, channel, empowered cast, completion, failure, and interruption both
   in and out of combat. The state must start and clear without Lua errors or
   exposing spell-name secret values.

## Cinematic editor identity

1. Click the orange Cinematic header button while the mode is off. It must
   enter the normal editor on `Editing: Cinematic`, show the inline controls,
   and apply the restrained amber outer-border identity.
2. Confirm ordinary target rows, reaction controls, and action buttons remain
   lavender. Only the live profile cue, subtitle, outer editor border, and
   Cinematic strip should use warm amber.
3. Use the inline `Cinematic: On` button to return to a normal profile. The
   editor remains open and returns to Resonance lavender.
4. Re-enter Cinematic, set a shortcut and black-bar height in the strip, then
   reload. Both values must persist; no dedicated Cinematic page may appear.
5. Verify Cast Bar defaults to Casting only and Resource Bars defaults to
   Combat only. Both remain editable through the ordered-rule editor.

## Editor hierarchy

1. Open the normal editor at its default size. Confirm the header reads left
   to right as Help, Peek, Profile, then Cinematic; the version text must not
   collide with those controls.
2. Confirm the body has three clear work areas: **Targets**, the selected
   frame's ordered rules (including the first-match hint and Copy/Paste), and
   **Transition & relationships**. Pick and Discover sit together above the
   target search, while timing/outline controls are visibly separated from
   relationship controls in the inspector.
3. Resize the editor through its supported range, then enter and leave
   Cinematic. Columns must remain attached to the header/footer with no
   overlapping controls; the Cinematic strip must expand only beneath the
   header controls. Copy, Paste, Reset, and every relationship button must
   remain usable. All edits must still take effect immediately.
4. Confirm the Profile dropdown and reaction priority controls use drawn,
   mirrored triangle icons rather than missing-font squares. The remove X must
   use a muted deep-red border/text treatment. Start a reaction drag and
   confirm the ghost repeats those same icons.
5. In normal mode, Cinematic is a header entry action. Once active, **Turn
   off** in the inline strip must return to the prior profile, while the
   **Editing: Cinematic** profile control must open the profile picker. Choose
   a normal profile there and verify it exits Cinematic editing and switches
   to that profile without an editor notice.
6. Confirm the right inspector uses a compact Transition title/icon, separate
   Fade and Wait buttons, a Frame outline / Preview card, and three icon-led
   relationship cards. Tooltips must retain the explanatory detail.
7. Confirm the profile label contains no fallback-font square and has only the
   drawn dropdown triangle. The header action must read **Preview**. Reload
   in both normal and Cinematic editing, then verify every reaction's drawn
   remove X remains deep red.
8. Confirm the inspector uses the packaged flat lavender Transition, eye,
   group, link, and visibility icons with transparent backgrounds at normal
   UI scale and after changing UI scale. No icon may show a black box, stretch
   outside its card, or replace its button's click target.
9. Confirm inspector icons are visually smaller than their card labels and
   retain comfortable transparent padding. Open the timing picker from both
   compact controls: its two sliders must read **Fade duration** then **Wait
   before fade**, matching the values shown in the inspector.

## Availability and coexistence

1. With a mix of controlled and catalog-only targets, verify the target rail
   always preserves its hierarchy. Search frames and switch profiles; the
   rail must update without adding or removing rules.

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
   and shrink with the fade in the third. Quest, archaeology, and task-area
   rings must follow the same behavior. Reset/remove Minimap and verify
   standard marker scale and ring alpha return. Tracking categories must
   remain unchanged.
5. While Hide at 0% is resting, change zones, change the tracked objective,
   and open/close the map to force native marker rebuilds. No service, quest,
   portal, or tracked-item marker may reappear and remain visible.
6. Set a non-default native marker scale in the owning UI, enable each marker
   mode, then reset/remove Minimap. The exact host scale must return. Repeat a
   release during combat and verify restoration retries after combat.
7. Export and re-import a profile using each marker mode. The mode must survive;
   an older export without marker metadata must still import as Leave unchanged.
8. On a client with no readable native icon-scale getter, verify Leave unchanged
   performs no marker-scale write. Selecting either experimental mode must show
   the 100% fallback notice and make marker fading functional. If another UI
   later calls SetIconScale, verify that announced value replaces the assumed
   restoration baseline.
9. Reset Cinematic Mode and verify its Minimap target defaults to Hide at 0%.
   At rest, both the map and native service/quest markers must disappear. Change
   the Cinematic Minimap to Scale with map, reload, and verify migration keeps
   that explicit choice instead of replacing it.
10. Super-track a quest far enough away to clamp its directional indicator to
    the screen edge. At 0%, its blue quest-direction arc must disappear with
    the Minimap; it must return at the host's prior opacity when the Minimap is
    revealed, reset, or released.

## Normal evaluator performance

1. With Cinematic Mode off, configure several normal targets and include rules
   from target, movement, casting, travel, group/instance, and world categories.
   Verify each condition still changes opacity and ordered first-match behavior
   remains unchanged.
2. Let a managed frame settle, then make its owning addon repaint `SetAlpha`.
   Frame Gambit must immediately reapply its owned opacity and later restore the
   host's newest value when the target is reset or the profile changes.
3. Enter combat before a newly created or pooled target can receive its alpha
   post-hook. The fallback audit must reacquire the host value and enforce the
   configured opacity without Lua errors; leaving combat must install the hook.
4. Compare addon CPU with a representative 10-20 target profile before and
   after this build. Normal fading should remain smooth at 20 Hz while idle
   `GetAlpha` reads and unrelated game-state API calls are materially reduced.
5. Switch to an empty profile and close the editor. The shared evaluator should
   sleep until an event, target mutation, profile switch, or pending restore
   gives it work again.

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
