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
