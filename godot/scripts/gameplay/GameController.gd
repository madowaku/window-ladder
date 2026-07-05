extends Node2D

const GridTypesRef = preload("res://scripts/core/GridTypes.gd")
const LevelLoaderScript = preload("res://scripts/core/LevelLoader.gd")
const LocalizationManagerScript = preload("res://scripts/core/LocalizationManager.gd")
const UndoManagerScript = preload("res://scripts/core/UndoManager.gd")

const CELL_SIZE := 64
const GRID_ORIGIN := Vector2(56, 104)
const LEVEL_IDS := ["1_01", "1_02", "1_03", "1_04", "1_05"]
const LEVEL_PATH_TEMPLATE := "res://levels/chapter_01/%s.json"
const STRINGS_PATH := "res://localization/strings.json"

var level_loader = LevelLoaderScript.new()
var localization = LocalizationManagerScript.new()
var undo_manager = UndoManagerScript.new()
var state
var initial_state
var current_level_index := 0
var language := "ja"

var hud_layer: CanvasLayer
var title_label: Label
var status_label: Label
var hint_label: Label
var undo_button: Button
var reset_button: Button
var language_button: Button
var clear_panel: PanelContainer
var clear_label: Label
var next_button: Button


func _ready() -> void:
	localization.load_strings(STRINGS_PATH)
	localization.set_language(language)
	_build_hud()
	load_stage(0)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var key: int = event.keycode
		if key == KEY_LEFT or key == KEY_A:
			if event.shift_pressed:
				try_move_ladder(-1)
			else:
				try_move_player(Vector2i(-1, 0))
		elif key == KEY_RIGHT or key == KEY_D:
			if event.shift_pressed:
				try_move_ladder(1)
			else:
				try_move_player(Vector2i(1, 0))
		elif key == KEY_UP or key == KEY_W:
			try_move_player(Vector2i(0, -1))
		elif key == KEY_DOWN or key == KEY_S:
			try_move_player(Vector2i(0, 1))
		elif key == KEY_SPACE or key == KEY_ENTER or key == KEY_KP_ENTER:
			try_clean()
		elif key == KEY_Z:
			undo()
		elif key == KEY_R:
			reset_stage()
		elif key == KEY_N and state != null and state.is_cleared:
			next_stage()


func load_stage(index: int) -> void:
	current_level_index = clampi(index, 0, LEVEL_IDS.size() - 1)
	var level_path = LEVEL_PATH_TEMPLATE % LEVEL_IDS[current_level_index]
	state = level_loader.load_level(level_path)
	if state == null:
		return
	initial_state = state.clone()
	undo_manager.clear()
	_update_hud()
	queue_redraw()


func try_move_player(direction: Vector2i) -> void:
	if state == null or state.is_cleared:
		return
	var next_position: Vector2i = state.player + direction
	if not can_player_stand(next_position):
		return

	undo_manager.push_state(state)
	state.player = next_position
	state.move_count += 1
	_after_state_changed()


func try_move_ladder(direction_x: int) -> void:
	if state == null or state.is_cleared:
		return
	if state.is_ladder_cell(state.player):
		return

	var ladder: Dictionary = state.ladder_at_bottom_neighbor(state.player)
	if ladder.is_empty():
		return
	if not can_move_ladder(ladder, direction_x):
		return

	undo_manager.push_state(state)
	ladder["x"] = int(ladder.get("x", 0)) + direction_x
	state.move_count += 1
	_after_state_changed()


func try_clean() -> void:
	if state == null or state.is_cleared:
		return

	var target: Vector2i = find_cleanable_window()
	if target == Vector2i(-1, -1):
		return

	undo_manager.push_state(state)
	state.set_tile(target, GridTypesRef.TileType.WINDOW_CLEAN)
	state.move_count += 1
	state.is_cleared = state.dirty_window_count() == 0
	_after_state_changed()


func undo() -> void:
	if state == null or not undo_manager.can_undo():
		return
	state = undo_manager.undo()
	_update_hud()
	queue_redraw()


func reset_stage() -> void:
	if initial_state == null:
		return
	state = initial_state.clone()
	undo_manager.clear()
	_update_hud()
	queue_redraw()


func next_stage() -> void:
	if current_level_index >= LEVEL_IDS.size() - 1:
		return
	load_stage(current_level_index + 1)


func can_player_stand(grid_position: Vector2i) -> bool:
	if state == null or not state.in_bounds(grid_position):
		return false
	if state.is_ladder_cell(grid_position):
		return true
	if state.has_cat_at(grid_position):
		return false
	return GridTypesRef.is_floor(state.get_tile(grid_position))


func can_move_ladder(ladder: Dictionary, direction_x: int) -> bool:
	var moved_ladder: Dictionary = ladder.duplicate(true)
	moved_ladder["x"] = int(moved_ladder.get("x", 0)) + direction_x
	for cell in state.ladder_cells(moved_ladder):
		if not state.in_bounds(cell):
			return false
		if cell == state.player:
			return false
		if GridTypesRef.is_solid_for_ladder(state.get_tile(cell)) or state.has_cat_at(cell):
			return false

	var support = Vector2i(int(moved_ladder.get("x", 0)), int(moved_ladder.get("bottom_y", 0)))
	return GridTypesRef.is_floor(state.get_tile(support))


func find_cleanable_window() -> Vector2i:
	var directions = [Vector2i(0, -1), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(1, 0)]
	for direction in directions:
		var candidate: Vector2i = state.player + direction
		if state.in_bounds(candidate) and state.get_tile(candidate) == GridTypesRef.TileType.WINDOW_DIRTY:
			return candidate
	return Vector2i(-1, -1)


func _after_state_changed() -> void:
	state.is_cleared = state.dirty_window_count() == 0
	_update_hud()
	queue_redraw()


func _build_hud() -> void:
	hud_layer = CanvasLayer.new()
	add_child(hud_layer)

	var hud_root = Control.new()
	hud_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	hud_layer.add_child(hud_root)

	title_label = Label.new()
	title_label.position = Vector2(24, 16)
	title_label.add_theme_font_size_override("font_size", 24)
	hud_root.add_child(title_label)

	status_label = Label.new()
	status_label.position = Vector2(24, 48)
	status_label.add_theme_font_size_override("font_size", 16)
	hud_root.add_child(status_label)

	hint_label = Label.new()
	hint_label.position = Vector2(24, 596)
	hint_label.add_theme_font_size_override("font_size", 14)
	hud_root.add_child(hint_label)

	undo_button = _make_button(Vector2(580, 18), Vector2(82, 34), _on_undo_button_pressed)
	hud_root.add_child(undo_button)

	reset_button = _make_button(Vector2(668, 18), Vector2(96, 34), _on_reset_button_pressed)
	hud_root.add_child(reset_button)

	language_button = _make_button(Vector2(680, 58), Vector2(84, 30), _on_language_button_pressed)
	hud_root.add_child(language_button)

	clear_panel = PanelContainer.new()
	clear_panel.position = Vector2(244, 206)
	clear_panel.size = Vector2(312, 164)
	clear_panel.custom_minimum_size = Vector2(312, 164)
	clear_panel.visible = false
	hud_root.add_child(clear_panel)

	var clear_box = VBoxContainer.new()
	clear_box.alignment = BoxContainer.ALIGNMENT_CENTER
	clear_box.add_theme_constant_override("separation", 16)
	clear_panel.add_child(clear_box)

	clear_label = Label.new()
	clear_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	clear_label.add_theme_font_size_override("font_size", 24)
	clear_box.add_child(clear_label)

	next_button = Button.new()
	next_button.size = Vector2(180, 42)
	next_button.custom_minimum_size = Vector2(180, 42)
	next_button.pressed.connect(_on_next_button_pressed)
	clear_box.add_child(next_button)


func _make_button(button_position: Vector2, size: Vector2, callback: Callable) -> Button:
	var button = Button.new()
	button.position = button_position
	button.size = size
	button.custom_minimum_size = size
	button.pressed.connect(callback)
	return button


func _update_hud() -> void:
	if state == null:
		return

	title_label.text = localization.tr_key(state.name_key)
	status_label.text = localization.tr_key("ui.status", {
		"stage": "%d-%02d" % [state.chapter, state.order],
		"moves": state.move_count,
		"dirty": state.dirty_window_count(),
	})
	hint_label.text = localization.tr_key("ui.controls")
	undo_button.text = localization.tr_key("ui.undo")
	reset_button.text = localization.tr_key("ui.reset")
	language_button.text = localization.tr_key("ui.language")
	clear_label.text = localization.tr_key("ui.stage_clear")

	var has_next = current_level_index < LEVEL_IDS.size() - 1
	next_button.text = localization.tr_key("ui.next_stage" if has_next else "ui.all_done")
	next_button.disabled = not has_next
	clear_panel.visible = state.is_cleared


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, get_viewport_rect().size), Color("#dff3ff"))
	if state == null:
		return

	_draw_building_backdrop()
	_draw_tiles()
	_draw_cats()
	_draw_ladders()
	_draw_player()


func _draw_building_backdrop() -> void:
	var board_size = Vector2(state.width * CELL_SIZE, state.height * CELL_SIZE)
	var rect = Rect2(GRID_ORIGIN - Vector2(8, 8), board_size + Vector2(16, 16))
	draw_rect(rect, Color("#f2d7b6"), true)
	draw_rect(rect, Color("#815f48"), false, 3.0)


func _draw_tiles() -> void:
	for y in range(state.height):
		for x in range(state.width):
			var cell = Vector2i(x, y)
			var rect = Rect2(grid_to_world(cell), Vector2(CELL_SIZE, CELL_SIZE))
			var tile = state.get_tile(cell)
			_draw_wall_cell(rect, x, y)
			if tile == GridTypesRef.TileType.GROUND:
				draw_rect(rect.grow(-3), Color("#7c6b56"), true)
			elif tile == GridTypesRef.TileType.LEDGE:
				draw_rect(Rect2(rect.position + Vector2(4, 42), Vector2(CELL_SIZE - 8, 16)), Color("#8b7355"), true)
				draw_rect(Rect2(rect.position + Vector2(4, 38), Vector2(CELL_SIZE - 8, 6)), Color("#f2e3c9"), true)
			elif tile == GridTypesRef.TileType.WALL:
				draw_rect(rect.grow(-2), Color("#a78a74"), true)
			elif tile == GridTypesRef.TileType.WINDOW_DIRTY:
				_draw_window(rect, false, false)
			elif tile == GridTypesRef.TileType.WINDOW_CLEAN:
				_draw_window(rect, true, false)
			elif tile == GridTypesRef.TileType.CAT_WINDOW:
				_draw_window(rect, true, true)
			draw_rect(rect, Color(0.47, 0.33, 0.24, 0.35), false, 1.0)


func _draw_wall_cell(rect: Rect2, x: int, y: int) -> void:
	var base = Color("#d9b98e") if (x + y) % 2 == 0 else Color("#d1ad7e")
	draw_rect(rect, base, true)


func _draw_window(rect: Rect2, clean: bool, is_cat_window: bool) -> void:
	var frame_rect = rect.grow(-12)
	var glass_rect = frame_rect.grow(-5)
	draw_rect(frame_rect, Color("#7b5540"), true)
	draw_rect(glass_rect, Color("#a7dff2") if clean else Color("#9aa0a7"), true)
	draw_line(glass_rect.position + Vector2(glass_rect.size.x * 0.5, 0), glass_rect.position + Vector2(glass_rect.size.x * 0.5, glass_rect.size.y), Color("#ecf8ff"), 2.0)
	draw_line(glass_rect.position + Vector2(0, glass_rect.size.y * 0.5), glass_rect.position + Vector2(glass_rect.size.x, glass_rect.size.y * 0.5), Color("#ecf8ff"), 2.0)
	if not clean:
		draw_circle(glass_rect.position + Vector2(13, 14), 6.0, Color("#6f716f"))
		draw_circle(glass_rect.position + Vector2(30, 28), 8.0, Color("#71745f"))
	if is_cat_window:
		draw_circle(glass_rect.get_center() + Vector2(0, 6), 14.0, Color("#2d2730"))
		draw_circle(glass_rect.get_center() + Vector2(-5, 3), 2.0, Color("#f8e777"))
		draw_circle(glass_rect.get_center() + Vector2(5, 3), 2.0, Color("#f8e777"))


func _draw_cats() -> void:
	for cat in state.cats:
		var cat_position = Vector2i(int(cat.get("x", 0)), int(cat.get("y", 0)))
		var rect = Rect2(grid_to_world(cat_position), Vector2(CELL_SIZE, CELL_SIZE))
		_draw_window(rect, true, true)
		var look_dir = str(cat.get("look_dir", "right"))
		var center = rect.get_center() + Vector2(0, 4)
		var eye_offset = Vector2(4 if look_dir == "right" else -4, 0)
		draw_circle(center + Vector2(-5, -1) + eye_offset, 2.0, Color("#f8e777"))
		draw_circle(center + Vector2(5, -1) + eye_offset, 2.0, Color("#f8e777"))


func _draw_ladders() -> void:
	for ladder in state.ladders:
		var cells = state.ladder_cells(ladder)
		if cells.is_empty():
			continue
		var x = int(ladder.get("x", 0))
		var bottom_y = int(ladder.get("bottom_y", 0))
		var length = int(ladder.get("length", 1))
		var top_world = grid_to_world(Vector2i(x, bottom_y - length + 1))
		var bottom_world = grid_to_world(Vector2i(x, bottom_y)) + Vector2(0, CELL_SIZE)
		var left_x = top_world.x + 20
		var right_x = top_world.x + CELL_SIZE - 20
		draw_line(Vector2(left_x, top_world.y + 7), Vector2(left_x, bottom_world.y - 7), Color("#8f552a"), 7.0)
		draw_line(Vector2(right_x, top_world.y + 7), Vector2(right_x, bottom_world.y - 7), Color("#8f552a"), 7.0)
		for offset in range(length):
			var y = top_world.y + offset * CELL_SIZE + 30
			draw_line(Vector2(left_x, y), Vector2(right_x, y), Color("#c98645"), 6.0)


func _draw_player() -> void:
	var rect = Rect2(grid_to_world(state.player), Vector2(CELL_SIZE, CELL_SIZE))
	var center = rect.get_center()
	draw_circle(center + Vector2(0, -12), 12.0, Color("#355c9b"))
	draw_rect(Rect2(center + Vector2(-13, 0), Vector2(26, 26)), Color("#457bd6"), true)
	draw_circle(center + Vector2(-4, -14), 2.0, Color("#fff5dc"))
	draw_circle(center + Vector2(5, -14), 2.0, Color("#fff5dc"))
	draw_line(center + Vector2(10, 8), center + Vector2(24, -2), Color("#8c5a35"), 4.0)
	draw_line(center + Vector2(21, -8), center + Vector2(29, 4), Color("#f2f6fa"), 5.0)


func grid_to_world(grid_position: Vector2i) -> Vector2:
	return GRID_ORIGIN + Vector2(grid_position.x * CELL_SIZE, grid_position.y * CELL_SIZE)


func _on_undo_button_pressed() -> void:
	undo()


func _on_reset_button_pressed() -> void:
	reset_stage()


func _on_next_button_pressed() -> void:
	next_stage()


func _on_language_button_pressed() -> void:
	language = "en" if language == "ja" else "ja"
	localization.set_language(language)
	_update_hud()
