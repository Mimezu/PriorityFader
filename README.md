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

Open **Help** from the editor header for short explanations of the Gambit
flow, relationships, Cinematic Mode, and safe integrations. **Start guided
tutorial** launches a non-destructive walkthrough with contextual highlights
and an interactive rule-order demonstration. It never writes practice rules
into your profile.

## Installation

Place this folder at:

```text
World of Warcraft/_retail_/Interface/AddOns/PriorityFader
```

Reload the UI, then open the addon with:

```text
/pfader
/framegambit
```

## Design boundary

Frame Gambit is an alpha-only presentation layer. It does not rewrite another addon's saved settings, reparent its frames, or replace its styling. Its internal `PriorityFader` identifiers remain available for saved-profile and integration compatibility during the staged rename. See [INTEGRATION.md](INTEGRATION.md), [ROADMAP.md](ROADMAP.md), and [TESTING.md](TESTING.md) for integration contracts, current limitations, and the release test matrix.

## Releases

Generated zip archives under `Versions/` are intentionally excluded from Git. Source releases should be represented by Git tags.
