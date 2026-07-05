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
	_test_room_undo_and_reset(controller)
	_test_room_invalid_interactions(controller)

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
