extends Node

const GameControllerScript = preload("res://scripts/gameplay/GameController.gd")

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


func _move(controller, direction: Vector2i) -> void:
	controller.try_move_player(direction)


func _assert(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
