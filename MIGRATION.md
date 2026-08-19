# Moving from Priority Fader to Frame Gambit

Frame Gambit is the new install name for the addon previously distributed as
Priority Fader. This release keeps your configuration automatically.

## Update steps

1. Exit World of Warcraft.
2. Extract the transition ZIP so both
   `Interface/AddOns/FrameGambit/FrameGambit.toc` and
   `Interface/AddOns/PriorityFader/PriorityFader.toc` exist. The latter is a
   tiny settings bridge, not the old addon.
3. Leave `WTF/Account/.../SavedVariables/PriorityFader.lua` in place.
4. Start the game. The bridge loads that existing data and gives it to Frame
   Gambit before it evaluates any rules.

The migration preserves profiles, targets, reactions, relationships, custom
targets, Cinematic settings, tutorial progress, and the Cinematic keybinding.
It does not modify your old SavedVariables file manually. The bridge lets WoW
load the old package file for this transition, then Frame Gambit saves the
migrated configuration under its new package name.

## Compatibility

- New commands: `/fg` and `/framegambit`.
- Legacy `/pfader` and `/priorityfader` commands remain available for macros.
- New integration API: `FrameGambitAPI`.
- Legacy `PriorityFaderAPI` remains an alias, so integrations do not break.
- New exports begin with `FrameGambit-1:`; existing `PriorityFader-1:` exports
  can still be imported.
