# Window Ladder / まどふき塔

Window Ladder / まどふき塔 is a small grid-based puzzle game about sliding ladders, cleaning windows, and following a mysterious cat through a tower.

The first prototype focuses on the outside-wall puzzle: move the ladder, climb it, clean dirty windows, and solve each tiny stage with a single neat idea.

Window Ladder / まどふき塔 は、スライド式ハシゴで塔の外壁を移動し、汚れた窓を掃除していくグリッド制パズルゲームです。

最初のプロトタイプでは、外壁だけの小さなステージを作り、ハシゴを動かす・登る・掃除するという基本の面白さを確認します。

## Development

- Engine: Godot 4.6
- Project path: `godot/`
- Main scene: `godot/scenes/Main.tscn`
- Level data: `godot/levels/chapter_01/*.json`
- Localization seed: `godot/localization/strings.json`
- Future asset workflow: `agent-sprite-forge`

Open the `godot/` folder in Godot and run the project.

## v0.1 Status

v0.1.0 is complete as an outside-wall prototype. It includes five playable JSON stages, grid movement, ladder climbing and sliding, window cleaning, clear detection, Undo, Reset, and localization-ready UI strings.

Not included in v0.1: interior mode, extendable ladders, opening/closing windows, cat AI, production asset generation, or the stage editor.

## Prototype Controls

- Move with arrow keys or WASD. The player can stand on ground, ledges, and ladder cells.
- Push the ladder one tile left or right with Shift + Left/Right while standing beside its bottom.
- Clean an adjacent dirty window with Space or Enter.
- Enter a highlighted outside window with Space or Enter, then walk on indoor floor tiles with the same movement keys.
- Stand on an indoor exit window and press Space or Enter to return to the linked outside wall coordinate.
- Undo the last move with Z, or reset the current stage with R.
