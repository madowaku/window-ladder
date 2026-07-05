# Playtest Notes

## v0.1.0

- Five stages manually cleared in the Godot DEBUG window.
- `RulesSmokeTest OK`.
- Stage `1-03` is clearable and keeps the intended "reuse the ladder" insight, but the number of ladder pushes is a little high. Consider tuning it after v0.1.

## v0.2 Checkpoint

- Added automated coverage for the first outside-to-room-to-outside routes.
- Added `2-01`, `2-02`, and `2-03` as minimum room-transition stages.
- Manually cleared `1-01` through `2-03` in the Godot DEBUG window.
- Verified room entry, indoor movement, room exit, post-exit outside actions, Undo, and Reset.

## v0.2.1 Polish

- Replayed `2-01`, `2-02`, and `2-03` after visual polish.
- Gold outside-window markers, green indoor exit arrows, and blue outside landing markers made the room route easier to read without extra mechanics.
- No stage layout changes were needed in this pass.

## v0.3 Cat Gaze Hints

- Added `3-01` through `3-05` as static cat-gaze stages.
- Godot MCP startup check: `res://scenes/Main.tscn` starts without reported errors.
- `RulesSmokeTest OK` covers loading, intended clears for `3-01` through `3-05`, Undo/Reset, blocked cat cells, and `hint_target` staying visual-only.
- Visual manual follow-up: judge whether the gaze line is too strong, too weak, readable without text, and whether `3-05` stays compact enough.
