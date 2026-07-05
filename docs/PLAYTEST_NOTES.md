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
