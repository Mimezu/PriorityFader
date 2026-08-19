# Frame Gambit

**Hide the UI you do not need. Bring it back exactly when you do.**

Frame Gambit lets you decide when each part of your World of Warcraft UI
appears. Keep your screen clean while exploring, reveal important frames in
combat or on mouseover, bring back the Objective Tracker when a quest updates,
or create a complete Cinematic setup for questing and screenshots.

[**Download the latest version**](https://github.com/Mimezu/PriorityFader/releases/latest/download/FrameGambit.zip)

![Frame Gambit editor](.github/readme/editor-overview.png)

## What you can do

- Fade Blizzard and addon frames without changing their layout or style.
- Choose when each frame appears: combat, mouseover, casting, movement,
  targets, travel, quests, group content, and more.
- Order reactions by priority—the first matching reaction controls the frame.
- Reveal related frames together with hover groups and parent/child links.
- Adjust fade speed, wait time, and resting opacity for each frame.
- Pick frames directly on screen and preview them before editing.
- Save different profiles and share them with friends.
- Build a separate Cinematic Mode with black bars and its own shortcut.

## Simple rules, powerful results

Choose a frame, add the moments when you want to see it, and set what happens
the rest of the time. Reactions are checked from top to bottom, so your most
important rule should be first.

Every reaction can be turned off without deleting it. You can also drag the
whole row to change its priority whenever you like.

![Dragging a reaction to a new priority](.github/readme/drag-priority.png)

## Conditions for the way you play

Frame Gambit includes conditions for combat, mouseover, targets, casting,
movement, class and spec, forms, stealth, pets, groups, instances, world
locations, quest moments, travel states, and more. Add the same kind of
condition more than once when a setup needs several different variations.

| Presence conditions | Travel conditions |
| --- | --- |
| ![Presence condition picker](.github/readme/reaction-picker-presence.png) | ![Travel condition picker](.github/readme/reaction-picker-travel.png) |
| Combat, mouseover, movement, casting, forms, specs, stealth, and input keys. | Mounted, flying, skyriding, fishing, vehicles, swimming, flight paths, and more. |

## Bring frames back at the right moment

Your UI can react to short gameplay moments as well as ongoing states. For
example, the Objective Tracker can appear when you accept a quest, complete
an objective, or turn something in, then fade away again when you are done.

![Objective Tracker reacting to quest events](.github/readme/live-objectives.png)

## Frame relationships

Some parts of the UI belong together. Frame Gambit can treat them that way:

- **Hover group:** hovering one frame reveals the whole group.
- **Linked child:** a child can reveal its parent when needed.
- **Visibility child:** a child follows the visibility of its parent.

This is useful for Details windows, unit-frame families, bars, and any custom
layout where several frames should feel like one piece of UI.

## Cinematic Mode

Cinematic Mode gives you a cleaner view of the world without losing your
normal profile. It has its own frame rules, optional black bars, and a
keybindable shortcut. Open the Cinematic editor to fine-tune the scene using
the same rules you already know.

![Cinematic Mode profile editor](.github/readme/cinematic-editor.png)

## Profiles and sharing

Create profiles for different characters, specs, activities, or moods and
switch between them whenever you like. Profiles can be exported and sent to
friends, even when their UI setup is not exactly the same as yours.

## Built-in help

The Help window explains the main features in plain language. A guided
tutorial also lets you practice on a temporary frame inside the real editor,
then removes it when the lesson is finished.

## Installation

1. [Download the latest ZIP](https://github.com/Mimezu/PriorityFader/releases/latest/download/FrameGambit.zip).
2. Extract `FrameGambit` into `World of Warcraft/_retail_/Interface/AddOns/`.
3. Start WoW or reload the UI.
4. Open Frame Gambit with `/fg` or `/framegambit`.

## Compatibility

Frame Gambit is made for Retail WoW and works with Blizzard frames as well as
supported addon UI. It changes frame opacity only; the original UI keeps
control of its layout, styling, and behavior.

For addon integrations and technical details, see [INTEGRATION.md](INTEGRATION.md).

## Releases

Visit the [latest release page](https://github.com/Mimezu/PriorityFader/releases/latest)
for the newest install-ready build.
