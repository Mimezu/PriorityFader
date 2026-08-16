# Priority Fader

Priority Fader is a World of Warcraft addon for approachable, ordered frame-visibility rules. It can manage Blizzard and addon-owned UI frames while leaving their layout, styling, and gameplay behavior with the original UI addon.

Highlights include:

- ordered, first-match visibility reactions;
- mouseover groups and parent/child reveal relationships;
- visual frame discovery and selection;
- a configurable Cinematic Mode for an uncluttered questing view;
- experimental per-bar EllesmereUI Cooldown Manager fading;
- profiles, import/export, diagnostics, and native keybinding support.

## Installation

Place this folder at:

```text
World of Warcraft/_retail_/Interface/AddOns/PriorityFader
```

Reload the UI, then open the addon with:

```text
/pfader
```

## Design boundary

Priority Fader is an alpha-only presentation layer. It does not rewrite another addon's saved settings, reparent its frames, or replace its styling. See [INTEGRATION.md](INTEGRATION.md), [ROADMAP.md](ROADMAP.md), and [TESTING.md](TESTING.md) for integration contracts, current limitations, and the release test matrix.

## Releases

Generated zip archives under `Versions/` are intentionally excluded from Git. Source releases should be represented by Git tags.
