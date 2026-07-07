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

## v0.3 Status

v0.3 adds static cat gaze hints. Cats do not move yet, but their eyes and subtle gaze markers help point toward interesting windows, ladder positions, or routes.

v0.3では、猫の視線ヒントを追加しました。猫はまだ動きませんが、視線や控えめなハイライトで、気にするべき窓やハシゴ位置を示します。

## v0.4 Status

v0.4 adds sleeping cats as static blockers. Sleeping cats do not move, but they can block outside wall cells, enterable windows, and room exits.

v0.4では、眠っている猫を静的な障害物として追加しました。猫はまだ動きませんが、外壁セル、入れる窓、室内からの出口を塞ぎます。

## v0.5 Status

v0.5 adds simple cat lures. Food bowls and bells can move a specified cat to a specified place. There is still no cat AI or pathfinding.

v0.5では、猫を動かすためのごはん皿とベルを追加しました。指定された猫を指定地点へ動かすだけで、猫AIや経路探索はまだありません。

## v0.6 Status

v0.6 adds static open and shut window states. Open windows can be entered; shut windows cannot be entered, but they still read as window cells on the outside wall. There is still no player-controlled opening or closing.

v0.6では、開いた窓と閉じた窓の初期状態を追加しました。開いた窓には入れますが、閉じた窓には入れません。プレイヤー操作で窓を開閉する処理はまだありません。

## Prototype Controls

- Move with arrow keys or WASD. The player can stand on ground, ledges, and ladder cells.
- Push the ladder one tile left or right with Shift + Left/Right while standing beside its bottom.
- Clean an adjacent dirty window with Space or Enter.
- Use an adjacent or same-cell food bowl or bell with Space or Enter.
- Enter a gold-highlighted open outside window with Space or Enter, then walk on indoor floor tiles with the same movement keys. Shut windows are visible but cannot be entered.
- Stand on a green-arrow indoor exit window and press Space or Enter to return to the linked blue landing marker outside.
- Undo the last move with Z, or reset the current stage with R.
