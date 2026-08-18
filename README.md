Exit code: 0
Wall time: 0.4 seconds
Output:
# Frame Gambit

Frame Gambit is a World of Warcraft addon by **Mimezu** for approachable, ordered frame-visibility rules. It can manage Blizzard and addon-owned UI frames while leaving their layout, styling, and gameplay behavior with the original UI addon.

Highlights include:

- ordered, first-match visibility reactions;
- composite built-in targets for split UIs such as complete Details windows;
- mouseover groups and parent/child reveal relationships;
- visual frame discovery and selection;
- a configurable Cinematic Mode for an uncluttered questing view;
- viewer-level Cooldown Manager fading that composes with EllesmereUI;
- profiles, import/export, diagnostics, and native keybinding support.

## Help and guided tutorial

Open **? Help** from the editor header for short explanations of the Gambit
flow, relationships, Cinematic Mode, and safe integrations. The Help window
can be moved independently, but closes with the editor. **Start guided
tutorial** launches a non-destructive walkthrough with a temporary portrait
**Tutorial Frame**, contextual spotlights, and real editor actions. Its
temporary target and lesson rules are removed when the tour ends, is skipped,
or is interrupted; your profile is never changed.

## Conditions

Reactions may use **Class pet active** for a player's combat pet (such as a
Hunter or Warlock pet), or **Cosmetic companion active** for a summoned Pet
Journal companion. These are separate conditions; Frame Gambit intentionally
does not provide an ambiguous "any pet" condition.

Picker cards use a shared, explicit **Yes / No** segment: the filled answer is
the one the row matches. **Movement: Yes** means moving; **Movement: No**
means stationary. Use **Form** to choose a supported gameplay form and then
whether it should be active (**Yes**) or inactive (**No**). Form rows for
another class/spec remain saved but are visibly muted and skipped, so one
profile can cover multiple specs. Available choices are Druid forms,
Shadowform, Ghost Wolf, and Demon Hunter Metamorphosis (including Devourer
Void Metamorphosis). Configurable cards
are repeatable: add as many as needed, then order them like any other gambit.
The **Spec** card first chooses a class, then its spec; other-class rows are
retained, greyed out, and skipped so a shared profile can cover alts or future
spec changes.
The presence list also includes **Stealthed / invisible**; travel includes
**Fishing**; and Group & instance includes **In Delve**.

Every reaction row has an **On/Off** switch. Off rows stay in their place with
their complete setup intact, but never match until turned back on.

## Installation

Place this folder at:

```text
World of Warcraft/_retail_/Interface/AddOns/PriorityFader
```

Reload the UI, then open the addon with:

```text
/pfader
/framegambit
/fg
```

## Design boundary

Frame Gambit is an alpha-only presentation layer. It does not rewrite another addon's saved settings, reparent its frames, or replace its styling. Its internal `PriorityFader` identifiers remain available for saved-profile and integration compatibility during the staged rename. See [INTEGRATION.md](INTEGRATION.md), [ROADMAP.md](ROADMAP.md), and [TESTING.md](TESTING.md) for integration contracts, current limitations, and the release test matrix.

## Releases

Generated zip archives under `Versions/` are intentionally excluded from Git. Source releases should be represented by Git tags.

