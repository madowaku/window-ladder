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
