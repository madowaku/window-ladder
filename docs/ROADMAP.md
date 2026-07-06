# Roadmap

## v0.1: Done

Outside-wall prototype complete:

- Five playable JSON stages.
- Player movement, ladder climbing, ladder sliding, window cleaning, clear detection, Undo, and Reset.
- Localization-ready UI string structure.
- Smoke tests and manual playtest notes recorded.

## v0.2: Window Interior

Current minimum implementation: let the player enter the tower through an outside window, walk on a small interior grid, and exit through another window back to a linked outside-wall coordinate.

Implemented first:

- `rooms` data in stage JSON.
- `enterable_window` outside tile support.
- Linked outside windows via `linked_room_id` and `linked_entry_id`.
- Room mode in `GameState`.
- Indoor floor movement and exit-window return.
- Undo/Reset across outside and room modes.
- Three v0.2 prototype stages: `2-01`, `2-02`, and `2-03`.

Still later:

- Box pushing.
- Interior switches.
- Extendable ladders.
- Opening and closing windows.
- Cat AI.
- Production asset generation.
- Phaser stage editor.

## v0.3: Cat Gaze Hints

Static cats now act as visual hints. Their gaze can point toward dirty windows, enterable windows, ladder positions, or exit clues.

No cat AI or movement yet.

## v0.4: Sleeping Cat

Sleeping cats now act as static blockers. They can occupy outside wall cells, block enterable windows, and prevent room exits that would land on their outside cell.

No cat AI or movement yet.

## v0.5: Bell / Food Bowl

Food bowls and bells can move a specified cat to a specified outside-wall position. This introduces player-triggered cat movement without cat AI, pathfinding, or autonomous behavior.

## Next Candidates

- Open / Shut Windows: 開いた窓は入口、閉じた窓は足場
- Box Push: 室内の最小押しギミック
- Extendable Ladder
- Cat AI or multi-step cat movement
