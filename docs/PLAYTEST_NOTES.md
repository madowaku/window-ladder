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

## v0.3.1 Cat Gaze Polish

- Reviewed `3-01` through `3-05` in Godot using visual preview captures and the existing clear walkthroughs.
- Tuned the gaze line and target glint slightly softer so the hint reads as attention rather than an answer marker.
- Nudged cat eyes a little farther toward `look_dir`; `3-01` still reads clearly as the introductory gaze stage.
- Kept `3-05` layout unchanged: the two cat hints are separated enough that the relay is readable without adding new rules.
- Godot MCP startup check: `res://scenes/Main.tscn` starts without reported errors.
- `RulesSmokeTest OK`.

## v0.4 Sleeping Cat

- Added `4-01` through `4-04` as minimum sleeping-cat blocker stages.
- Sleeping cats block entering their outside window and block room exits that would land on their outside cell.
- Sleeping cats are static only; no cat movement, bell, food bowl, or cat AI was added.
- Manual visual check: reviewed `4-01` through `4-04` via Godot preview captures. The closed eyes and small sleep mark read as sleeping, and `4-04` keeps the open route separate from the blocked window.
- `RulesSmokeTest OK` covers loading, intended clears, entry block, exit block, watching-cat non-blocking entry/exit behavior, Undo/Reset, and default `watching` state.

## v0.4.1 Sleeping Cat Polish

- Reviewed `4-01` through `4-04` with fresh Godot preview captures and the existing walkthrough routes.
- Replaced the letter-like sleep mark with small bubbles and curved closed eyes so sleeping reads more visually and less as text.
- `4-03` still communicates the blocked exit: the sleeping cat sits on the outside landing while the alternate blue marker remains nearby.
- `4-04` keeps the watching cat gaze, sleeping blocker, open window, and ladder visually separated.
- `RulesSmokeTest OK`.

## v0.5 Bell / Food Bowl Cat Lures

- Added `5-01` through `5-05` as compact lure stages for food bowls, room bells, gaze-to-lure hints, and a combined review.
- Food bowls and bells move one specified cat to one specified outside-wall coordinate; no cat AI, autonomous movement, pathfinding, box push, switches, or window open/shut rules were added.
- Automated coverage targets loading, JSON parsing, food bowl and bell activation, `target_state`, sleeping-cat blocks before activation, Undo/Reset, mode filtering, invalid targets, and existing `1-01` through `4-04` routes.
- Manual Godot window review: checked `5-01` through `5-05` in the DEBUG window.
- Food bowls and bells are distinguishable without text: bowls read as pale dishes with small food bits, while bells read as yellow bells with motion marks.
- Lure activation visibly moves the target cat; for room bells, the effect is confirmed by the previously blocked exit becoming usable and the cat appearing at the new outside-wall window after exit.
- `5-03` and `5-05` were nudged so the watching cat has a longer dotted gaze line toward the food bowl; `5-05` still reads as a compact review rather than an overloaded stage.
- `5-04` communicates "ring first": trying the exit first stays in the room, while returning to the visible bell clears the outside sleeping-cat block.
