extends Node

const GameControllerScript = preload("res://scripts/gameplay/GameController.gd")
const GridTypesRef = preload("res://scripts/core/GridTypes.gd")

var failures: Array = []


func _ready() -> void:
	var controller = GameControllerScript.new()
	add_child(controller)
	await get_tree().process_frame

	_assert(controller.state.stage_id == "1_01", "loads first stage")
	_solve_stage_1_01(controller)
	controller.undo()
	_assert(not controller.state.is_cleared, "undo restores dirty window after clear")
	controller.reset_stage()
	_assert(controller.state.move_count == 0, "reset restores move count")
	_assert(controller.state.player == Vector2i(2, 5), "reset restores player")

	_test_invalid_player_movement(controller)
	_test_clean_without_target(controller)
	_test_ladder_bounds(controller)
	_test_ladder_requires_support(controller)
	_test_ladder_locked_while_player_on_it(controller)
	_test_clear_locks_actions(controller)

	_solve_stage_1_02(controller)
	_solve_stage_1_03(controller)
	_solve_stage_1_04(controller)
	_solve_stage_1_05(controller)
	_solve_stage_2_01(controller)
	_solve_stage_2_02(controller)
	_solve_stage_2_03(controller)
	_solve_stage_3_01(controller)
	_solve_stage_3_02(controller)
	_solve_stage_3_03(controller)
	_solve_stage_3_04(controller)
	_solve_stage_3_05(controller)
	_solve_stage_4_01(controller)
	_solve_stage_4_02(controller)
	_solve_stage_4_03(controller)
	_solve_stage_4_04(controller)
	_test_room_undo_and_reset(controller)
	_test_room_invalid_interactions(controller)
	_test_cat_gaze_data_and_rules(controller)
	_test_sleeping_cat_rules(controller)

	if failures.is_empty():
		print("RulesSmokeTest OK")
		await get_tree().create_timer(5.0).timeout
		get_tree().quit(0)
	else:
		for failure in failures:
			push_error(failure)
		await get_tree().create_timer(5.0).timeout
		get_tree().quit(1)


func _solve_stage_1_01(controller) -> void:
	controller.load_stage(0)
	_move(controller, Vector2i(1, 0))
	_move(controller, Vector2i(0, -1))
	_move(controller, Vector2i(0, -1))
	controller.try_clean()
	_assert(controller.state.is_cleared, "stage 1-01 clears")


func _solve_stage_1_02(controller) -> void:
	controller.load_stage(1)
	controller.try_move_ladder(1)
	_move(controller, Vector2i(1, 0))
	_move(controller, Vector2i(1, 0))
	_move(controller, Vector2i(0, -1))
	_move(controller, Vector2i(0, -1))
	controller.try_clean()
	_assert(controller.state.is_cleared, "stage 1-02 clears")


func _solve_stage_1_03(controller) -> void:
	controller.load_stage(2)
	_move(controller, Vector2i(1, 0))
	_move(controller, Vector2i(0, -1))
	_move(controller, Vector2i(0, -1))
	controller.try_clean()
	_move(controller, Vector2i(0, 1))
	_move(controller, Vector2i(0, 1))
	_move(controller, Vector2i(-1, 0))
	controller.try_move_ladder(1)
	_move(controller, Vector2i(1, 0))
	controller.try_move_ladder(1)
	_move(controller, Vector2i(1, 0))
	controller.try_move_ladder(1)
	_move(controller, Vector2i(1, 0))
	_move(controller, Vector2i(1, 0))
	_move(controller, Vector2i(0, -1))
	_move(controller, Vector2i(0, -1))
	controller.try_clean()
	_assert(controller.state.is_cleared, "stage 1-03 clears")


func _solve_stage_1_04(controller) -> void:
	controller.load_stage(3)
	_move(controller, Vector2i(1, 0))
	_move(controller, Vector2i(0, -1))
	_move(controller, Vector2i(0, -1))
	_move(controller, Vector2i(0, -1))
	_move(controller, Vector2i(1, 0))
	controller.try_clean()
	_assert(controller.state.is_cleared, "stage 1-04 clears")


func _solve_stage_1_05(controller) -> void:
	controller.load_stage(4)
	controller.try_move_ladder(1)
	_move(controller, Vector2i(1, 0))
	_move(controller, Vector2i(1, 0))
	_move(controller, Vector2i(0, -1))
	_move(controller, Vector2i(0, -1))
	_move(controller, Vector2i(0, -1))
	controller.try_clean()
	_assert(controller.state.is_cleared, "stage 1-05 clears")


func _solve_stage_2_01(controller) -> void:
	controller.load_stage(5)
	_assert(controller.state.stage_id == "2_01", "loads stage 2-01")
	_move(controller, Vector2i(1, 0))
	controller.try_interact()
	_assert(controller.state.mode == "room", "2-01 enters a room")
	_move(controller, Vector2i(1, 0))
	controller.try_interact()
	_assert(controller.state.mode == "outside", "2-01 exits back outside")
	_assert(controller.state.player == Vector2i(5, 5), "2-01 exits at linked outside coordinate")


func _solve_stage_2_02(controller) -> void:
	controller.load_stage(6)
	_assert(controller.state.stage_id == "2_02", "loads stage 2-02")
	_move(controller, Vector2i(1, 0))
	controller.try_interact()
	_move(controller, Vector2i(1, 0))
	controller.try_interact()
	controller.try_clean()
	_assert(controller.state.is_cleared, "stage 2-02 clears after room exit")


func _solve_stage_2_03(controller) -> void:
	controller.load_stage(7)
	_assert(controller.state.stage_id == "2_03", "loads stage 2-03")
	controller.try_move_ladder(1)
	_move(controller, Vector2i(1, 0))
	_move(controller, Vector2i(1, 0))
	_move(controller, Vector2i(0, -1))
	_move(controller, Vector2i(0, -1))
	controller.try_interact()
	_move(controller, Vector2i(1, 0))
	controller.try_interact()
	controller.try_clean()
	_assert(controller.state.is_cleared, "stage 2-03 clears after ladder setup and room route")


func _solve_stage_3_01(controller) -> void:
	controller.load_stage(8)
	_assert(controller.state.stage_id == "3_01", "loads stage 3-01")
	_assert(not controller.state.cats[0].get("hint_target", {}).is_empty(), "3-01 parses cat hint target")
	_move(controller, Vector2i(1, 0))
	_move(controller, Vector2i(1, 0))
	_move(controller, Vector2i(0, -1))
	_move(controller, Vector2i(0, -1))
	controller.try_clean()
	_assert(controller.state.is_cleared, "stage 3-01 clears")


func _solve_stage_3_02(controller) -> void:
	controller.load_stage(9)
	_assert(controller.state.stage_id == "3_02", "loads stage 3-02")
	controller.try_move_ladder(1)
	_move(controller, Vector2i(1, 0))
	controller.try_move_ladder(1)
	_move(controller, Vector2i(1, 0))
	_move(controller, Vector2i(1, 0))
	_move(controller, Vector2i(0, -1))
	_move(controller, Vector2i(0, -1))
	controller.try_clean()
	_assert(controller.state.is_cleared, "stage 3-02 clears")


func _solve_stage_3_03(controller) -> void:
	controller.load_stage(10)
	_assert(controller.state.stage_id == "3_03", "loads stage 3-03")
	_move(controller, Vector2i(1, 0))
	controller.try_interact()
	_assert(controller.state.mode == "room", "3-03 enters the hinted window")
	_move(controller, Vector2i(1, 0))
	controller.try_interact()
	controller.try_clean()
	_assert(controller.state.is_cleared, "stage 3-03 clears")


func _solve_stage_3_04(controller) -> void:
	controller.load_stage(11)
	_assert(controller.state.stage_id == "3_04", "loads stage 3-04")
	_move(controller, Vector2i(1, 0))
	controller.try_interact()
	_move(controller, Vector2i(1, 0))
	controller.try_interact()
	_assert(controller.state.player == Vector2i(5, 3), "3-04 exits at the hinted landing")
	controller.try_clean()
	_assert(controller.state.is_cleared, "stage 3-04 clears")


func _solve_stage_3_05(controller) -> void:
	controller.load_stage(12)
	_assert(controller.state.stage_id == "3_05", "loads stage 3-05")
	_move(controller, Vector2i(1, 0))
	controller.try_interact()
	_move(controller, Vector2i(1, 0))
	controller.try_interact()
	_assert(controller.state.player == Vector2i(6, 5), "3-05 exits near the second cat hint")
	controller.try_move_ladder(-1)
	_move(controller, Vector2i(-1, 0))
	_move(controller, Vector2i(-1, 0))
	_move(controller, Vector2i(0, -1))
	_move(controller, Vector2i(0, -1))
	controller.try_clean()
	_assert(controller.state.is_cleared, "stage 3-05 clears")


func _solve_stage_4_01(controller) -> void:
	controller.load_stage(13)
	_assert(controller.state.stage_id == "4_01", "loads stage 4-01")
	_move(controller, Vector2i(1, 0))
	controller.try_interact()
	_assert(controller.state.mode == "outside", "4-01 sleeping cat blocks the nearby window")
	_move(controller, Vector2i(1, 0))
	_move(controller, Vector2i(1, 0))
	_move(controller, Vector2i(0, -1))
	_move(controller, Vector2i(0, -1))
	controller.try_clean()
	_assert(controller.state.is_cleared, "stage 4-01 clears around the sleeping cat")


func _solve_stage_4_02(controller) -> void:
	controller.load_stage(14)
	_assert(controller.state.stage_id == "4_02", "loads stage 4-02")
	_move(controller, Vector2i(1, 0))
	controller.try_interact()
	_assert(controller.state.mode == "outside", "4-02 sleeping cat blocks the first entrance")
	_move(controller, Vector2i(1, 0))
	_move(controller, Vector2i(1, 0))
	controller.try_interact()
	_assert(controller.state.mode == "room", "4-02 enters through the unblocked window")
	_move(controller, Vector2i(1, 0))
	controller.try_interact()
	controller.try_clean()
	_assert(controller.state.is_cleared, "stage 4-02 clears through the alternate entrance")


func _solve_stage_4_03(controller) -> void:
	controller.load_stage(15)
	_assert(controller.state.stage_id == "4_03", "loads stage 4-03")
	_move(controller, Vector2i(1, 0))
	controller.try_interact()
	_move(controller, Vector2i(1, 0))
	controller.try_interact()
	_assert(controller.state.mode == "room", "4-03 sleeping cat blocks the first exit")
	_move(controller, Vector2i(1, 0))
	controller.try_interact()
	controller.try_clean()
	_assert(controller.state.is_cleared, "stage 4-03 clears through the alternate exit")


func _solve_stage_4_04(controller) -> void:
	controller.load_stage(16)
	_assert(controller.state.stage_id == "4_04", "loads stage 4-04")
	_move(controller, Vector2i(1, 0))
	controller.try_interact()
	_assert(controller.state.mode == "outside", "4-04 sleeping cat blocks the decoy entrance")
	_move(controller, Vector2i(1, 0))
	controller.try_interact()
	_move(controller, Vector2i(1, 0))
	controller.try_interact()
	_move(controller, Vector2i(-1, 0))
	_move(controller, Vector2i(0, -1))
	_move(controller, Vector2i(0, -1))
	controller.try_clean()
	_assert(controller.state.is_cleared, "stage 4-04 clears with gaze hint and sleeping block")


func _test_room_undo_and_reset(controller) -> void:
	controller.load_stage(5)
	_move(controller, Vector2i(1, 0))
	controller.try_interact()
	_assert(controller.state.mode == "room", "room undo test enters room")
	controller.undo()
	_assert(controller.state.mode == "outside", "undo restores outside mode after entering room")

	controller.try_interact()
	_move(controller, Vector2i(1, 0))
	_assert(controller.state.room_player == Vector2i(2, 1), "room undo test moves inside room")
	controller.undo()
	_assert(controller.state.mode == "room", "undo inside room stays in room")
	_assert(controller.state.room_player == Vector2i(1, 1), "undo inside room restores room player")

	_move(controller, Vector2i(1, 0))
	controller.try_interact()
	_assert(controller.state.mode == "outside", "room reset test exits room")
	controller.undo()
	_assert(controller.state.mode == "room", "undo restores room mode after exiting room")
	_assert(controller.state.room_player == Vector2i(2, 1), "undo after room exit restores exit tile")

	controller.reset_stage()
	_assert(controller.state.mode == "outside", "reset from room restores outside mode")
	_assert(controller.state.player == Vector2i(2, 5), "reset from room restores v0.2 outside player")

	_move(controller, Vector2i(1, 0))
	controller.try_interact()
	_assert(controller.state.mode == "room", "room reset test enters room again")
	controller.reset_stage()
	_assert(controller.state.mode == "outside", "reset restores outside mode")
	_assert(controller.state.player == Vector2i(2, 5), "reset restores v0.2 outside player")


func _test_room_invalid_interactions(controller) -> void:
	controller.load_stage(5)
	var outside_player: Vector2i = controller.state.player
	var outside_moves: int = controller.state.move_count
	controller.try_interact()
	_assert(controller.state.mode == "outside", "non-enterable position does not enter room")
	_assert(controller.state.player == outside_player, "non-enterable interaction leaves outside player unchanged")
	_assert(controller.state.move_count == outside_moves, "non-enterable interaction does not increment moves")

	_move(controller, Vector2i(1, 0))
	controller.try_interact()
	_assert(controller.state.mode == "room", "invalid interaction test enters room")

	var room_player: Vector2i = controller.state.room_player
	var room_moves: int = controller.state.move_count
	_move(controller, Vector2i(0, -1))
	_assert(controller.state.room_player == room_player, "room player cannot move into wall")
	_assert(controller.state.move_count == room_moves, "room wall move does not increment moves")

	controller.try_interact()
	_assert(controller.state.mode == "room", "non-exit room interaction stays in room")
	_assert(controller.state.room_player == room_player, "non-exit room interaction leaves room player unchanged")
	_assert(controller.state.move_count == room_moves, "non-exit room interaction does not increment moves")

	var ladder_x: int = int(controller.state.ladders[0].get("x", 0))
	controller.try_move_ladder(1)
	_assert(int(controller.state.ladders[0].get("x", 0)) == ladder_x, "room mode blocks outside ladder movement")
	_assert(controller.state.move_count == room_moves, "room mode ladder input does not increment moves")

	controller.try_exit_room()
	_assert(controller.state.mode == "room", "direct exit call outside exit tile stays in room")

	_move(controller, Vector2i(1, 0))
	controller.try_interact()
	_assert(controller.state.mode == "outside", "invalid interaction test exits room")
	var exit_player: Vector2i = controller.state.player
	var exit_moves: int = controller.state.move_count
	controller.try_exit_room()
	_assert(controller.state.mode == "outside", "outside mode direct exit call stays outside")
	_assert(controller.state.player == exit_player, "outside mode direct exit call leaves player unchanged")
	_assert(controller.state.move_count == exit_moves, "outside mode direct exit call does not increment moves")


func _test_cat_gaze_data_and_rules(controller) -> void:
	controller.load_stage(8)
	var cat := controller.state.cats[0] as Dictionary
	var hint := cat.get("hint_target", {}) as Dictionary
	_assert(Vector2i(int(hint.get("x", -1)), int(hint.get("y", -1))) == Vector2i(4, 2), "cat hint target preserves grid coordinate")

	var start_dirty: int = controller.state.dirty_window_count()
	controller.try_clean()
	_assert(controller.state.dirty_window_count() == start_dirty, "hint target does not auto-clean windows")

	controller.state.player = Vector2i(1, 2)
	var start_player: Vector2i = controller.state.player
	var start_moves: int = controller.state.move_count
	_move(controller, Vector2i(1, 0))
	_assert(controller.state.player == start_player, "cat cell remains blocked with hint target")
	_assert(controller.state.move_count == start_moves, "blocked cat cell with hint target does not increment moves")

	controller.reset_stage()
	var reset_hint := controller.state.cats[0].get("hint_target", {}) as Dictionary
	_assert(Vector2i(int(reset_hint.get("x", -1)), int(reset_hint.get("y", -1))) == Vector2i(4, 2), "reset keeps cat hint target")


func _test_sleeping_cat_rules(controller) -> void:
	controller.load_stage(5)
	controller.state.cats.append({"id": "sleep_entry", "x": 3, "y": 4, "state": "sleeping"})
	_move(controller, Vector2i(1, 0))
	var entry_block_player: Vector2i = controller.state.player
	var entry_block_moves: int = controller.state.move_count
	controller.try_interact()
	_assert(controller.state.mode == "outside", "sleeping cat blocks entering its window")
	_assert(controller.state.player == entry_block_player, "sleeping cat entry block keeps outside player")
	_assert(controller.state.move_count == entry_block_moves, "sleeping cat entry block does not increment moves")

	controller.state.cats.clear()
	controller.try_interact()
	_move(controller, Vector2i(1, 0))
	controller.state.cats.append({"id": "sleep_exit", "x": 5, "y": 5, "state": "sleeping"})
	var room_player: Vector2i = controller.state.room_player
	var room_moves: int = controller.state.move_count
	controller.try_interact()
	_assert(controller.state.mode == "room", "sleeping cat blocks exiting onto its outside cell")
	_assert(controller.state.room_player == room_player, "sleeping cat exit block keeps room player")
	_assert(controller.state.move_count == room_moves, "sleeping cat exit block does not increment moves")

	controller.state.cats.clear()
	controller.try_interact()
	_assert(controller.state.mode == "outside", "exit works after sleeping cat is removed")

	controller.load_stage(8)
	var cat := controller.state.cats[0] as Dictionary
	_assert(str(cat.get("state", "watching")) == "watching", "missing cat state defaults to watching")
	controller.state.player = Vector2i(1, 2)
	var blocked_player: Vector2i = controller.state.player
	_move(controller, Vector2i(1, 0))
	_assert(controller.state.player == blocked_player, "watching cat still blocks standing on its cell")

	controller.load_stage(5)
	controller.state.cats.append({"id": "watch_entry", "x": 3, "y": 4, "state": "watching"})
	_move(controller, Vector2i(1, 0))
	controller.try_interact()
	_assert(controller.state.mode == "room", "watching cat does not block entering its window")
	_move(controller, Vector2i(1, 0))
	controller.state.cats.append({"id": "watch_exit", "x": 5, "y": 5, "state": "watching"})
	controller.try_interact()
	_assert(controller.state.mode == "outside", "watching cat does not block exiting onto its outside cell")

	controller.load_stage(13)
	_move(controller, Vector2i(1, 0))
	controller.try_interact()
	controller.reset_stage()
	_assert(controller.state.stage_id == "4_01", "sleeping cat reset keeps v0.4 stage")
	_assert(controller.state.mode == "outside", "sleeping cat reset restores outside mode")


func _test_invalid_player_movement(controller) -> void:
	controller.load_stage(0)
	var start_player: Vector2i = controller.state.player
	var start_moves: int = controller.state.move_count

	_move(controller, Vector2i(0, -1))
	_assert(controller.state.player == start_player, "player cannot move into air")
	_assert(controller.state.move_count == start_moves, "air move does not increment moves")

	controller.state.set_tile(Vector2i(1, 5), GridTypesRef.TileType.WALL)
	_move(controller, Vector2i(-1, 0))
	_assert(controller.state.player == start_player, "player cannot move into wall")
	_assert(controller.state.move_count == start_moves, "wall move does not increment moves")

	controller.state.set_tile(Vector2i(1, 5), GridTypesRef.TileType.GROUND)
	controller.state.set_tile(Vector2i(1, 5), GridTypesRef.TileType.WINDOW_DIRTY)
	_move(controller, Vector2i(-1, 0))
	_assert(controller.state.player == start_player, "player cannot move into window")
	_assert(controller.state.move_count == start_moves, "window move does not increment moves")


func _test_clean_without_target(controller) -> void:
	controller.load_stage(0)
	var start_moves: int = controller.state.move_count
	var dirty_count: int = controller.state.dirty_window_count()
	controller.try_clean()
	_assert(controller.state.move_count == start_moves, "clean without target does not increment moves")
	_assert(controller.state.dirty_window_count() == dirty_count, "clean without target leaves windows dirty")


func _test_ladder_bounds(controller) -> void:
	controller.load_stage(0)
	controller.state.ladders[0]["x"] = 0
	controller.state.player = Vector2i(1, 5)
	var start_x: int = int(controller.state.ladders[0].get("x", 0))
	var start_moves: int = controller.state.move_count
	controller.try_move_ladder(-1)
	_assert(int(controller.state.ladders[0].get("x", 0)) == start_x, "ladder cannot move out of bounds")
	_assert(controller.state.move_count == start_moves, "out of bounds ladder move does not increment moves")


func _test_ladder_requires_support(controller) -> void:
	controller.load_stage(0)
	controller.state.set_tile(Vector2i(2, 5), GridTypesRef.TileType.EMPTY)
	var start_x: int = int(controller.state.ladders[0].get("x", 0))
	var start_moves: int = controller.state.move_count
	controller.try_move_ladder(-1)
	_assert(int(controller.state.ladders[0].get("x", 0)) == start_x, "ladder cannot move onto unsupported bottom")
	_assert(controller.state.move_count == start_moves, "unsupported ladder move does not increment moves")


func _test_ladder_locked_while_player_on_it(controller) -> void:
	controller.load_stage(0)
	controller.state.player = Vector2i(3, 5)
	var start_x: int = int(controller.state.ladders[0].get("x", 0))
	var start_moves: int = controller.state.move_count
	controller.try_move_ladder(1)
	_assert(int(controller.state.ladders[0].get("x", 0)) == start_x, "ladder cannot move while player is on it")
	_assert(controller.state.move_count == start_moves, "ladder move while occupied does not increment moves")


func _test_clear_locks_actions(controller) -> void:
	controller.load_stage(0)
	_solve_stage_1_01(controller)
	var cleared_player: Vector2i = controller.state.player
	var cleared_ladder_x: int = int(controller.state.ladders[0].get("x", 0))
	var cleared_moves: int = controller.state.move_count
	var cleared_dirty: int = controller.state.dirty_window_count()

	_move(controller, Vector2i(0, 1))
	controller.try_clean()
	controller.try_move_ladder(1)

	_assert(controller.state.player == cleared_player, "clear state blocks player movement")
	_assert(int(controller.state.ladders[0].get("x", 0)) == cleared_ladder_x, "clear state blocks ladder movement")
	_assert(controller.state.move_count == cleared_moves, "clear state actions do not increment moves")
	_assert(controller.state.dirty_window_count() == cleared_dirty, "clear state cleaning leaves windows unchanged")


func _move(controller, direction: Vector2i) -> void:
	controller.try_move_player(direction)


func _assert(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
