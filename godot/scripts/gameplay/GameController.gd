extends Node2D

const GridTypesRef = preload("res://scripts/core/GridTypes.gd")
const LevelLoaderScript = preload("res://scripts/core/LevelLoader.gd")
const LocalizationManagerScript = preload("res://scripts/core/LocalizationManager.gd")
const UndoManagerScript = preload("res://scripts/core/UndoManager.gd")
const RoomViewScript = preload("res://scripts/gameplay/RoomView.gd")

const CELL_SIZE := 64
const GRID_ORIGIN := Vector2(56, 104)
const LEVEL_IDS := ["1_01", "1_02", "1_03", "1_04", "1_05", "2_01", "2_02", "2_03", "3_01", "3_02", "3_03", "3_04", "3_05", "4_01", "4_02", "4_03", "4_04", "5_01", "5_02", "5_03", "5_04", "5_05"]
const LEVEL_PATH_TEMPLATE := "res://levels/chapter_01/%s.json"
const STRINGS_PATH := "res://localization/strings.json"

var level_loader = LevelLoaderScript.new()
var localization = LocalizationManagerScript.new()
var undo_manager = UndoManagerScript.new()
var room_view = RoomViewScript.new()
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
			try_interact()
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
	var next_position: Vector2i = state.active_position() + direction
	if not can_player_stand(next_position):
		return

	undo_manager.push_state(state)
	if state.mode == "room":
		state.room_player = next_position
	else:
		state.player = next_position
	state.move_count += 1
	_after_state_changed()


func try_move_ladder(direction_x: int) -> void:
	if state == null or state.is_cleared or state.mode != "outside":
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
	if state == null or state.is_cleared or state.mode != "outside":
		return

	var target: Vector2i = find_cleanable_window()
	if target == Vector2i(-1, -1):
		return

	undo_manager.push_state(state)
	state.set_tile(target, GridTypesRef.TileType.WINDOW_CLEAN)
	state.move_count += 1
	state.is_cleared = state.dirty_window_count() == 0
	_after_state_changed()


func try_interact() -> void:
	if state == null or state.is_cleared:
		return
	if state.mode == "room":
		if try_activate_cat_lure():
			return
		try_exit_room()
		return

	var dirty_target: Vector2i = find_cleanable_window()
	if dirty_target != Vector2i(-1, -1):
		try_clean()
		return
	if try_activate_cat_lure():
		return
	try_enter_room()


func try_activate_cat_lure() -> bool:
	var lure: Dictionary = find_activatable_cat_lure()
	if lure.is_empty():
		return false

	var target_cat_id := str(lure.get("target_cat_id", ""))
	var target_cat_index := find_cat_index(target_cat_id)
	if target_cat_index < 0:
		return false

	var target_data = lure.get("target_position", {})
	if typeof(target_data) != TYPE_DICTIONARY:
		return false
	var target_position := Vector2i(int(target_data.get("x", -1)), int(target_data.get("y", -1)))
	if not state.in_bounds(target_position):
		return false

	var cat: Dictionary = state.cats[target_cat_index]
	var current_position := Vector2i(int(cat.get("x", -1)), int(cat.get("y", -1)))
	if current_position == target_position:
		return false
	if has_other_cat_at(target_position, target_cat_id):
		return false
	if state.mode == "outside" and target_position == state.player:
		return false

	undo_manager.push_state(state)
	cat["x"] = target_position.x
	cat["y"] = target_position.y
	if lure.has("target_state"):
		cat["state"] = str(lure.get("target_state", cat.get("state", "watching")))
	state.move_count += 1
	_after_state_changed()
	return true


func try_enter_room() -> void:
	var window: Dictionary = find_enterable_window()
	if window.is_empty():
		return
	var room_id = str(window.get("linked_room_id", ""))
	var entry_id = str(window.get("linked_entry_id", ""))
	if not state.rooms.has(room_id):
		return

	undo_manager.push_state(state)
	state.mode = "room"
	state.current_room_id = room_id
	state.room_player = state.room_entry_position(room_id, entry_id)
	state.has_entered_room = true
	state.move_count += 1
	_update_hud()
	queue_redraw()


func try_exit_room() -> void:
	var exit: Dictionary = state.room_exit_at(state.room_player)
	if exit.is_empty():
		return
	var outside_position := Vector2i(int(exit.get("outside_x", state.player.x)), int(exit.get("outside_y", state.player.y)))
	if state.has_sleeping_cat_at(outside_position):
		return

	undo_manager.push_state(state)
	state.mode = "outside"
	state.current_room_id = ""
	state.player = outside_position
	state.move_count += 1
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
	if state != null and state.mode == "room":
		return state.is_room_walkable(grid_position)
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
	if state.mode != "outside":
		return Vector2i(-1, -1)
	var directions = [Vector2i(0, -1), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(1, 0)]
	for direction in directions:
		var candidate: Vector2i = state.player + direction
		if state.in_bounds(candidate) and state.get_tile(candidate) == GridTypesRef.TileType.WINDOW_DIRTY:
			return candidate
	return Vector2i(-1, -1)


func find_enterable_window() -> Dictionary:
	var directions = [Vector2i(0, -1), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(1, 0)]
	for direction in directions:
		var candidate: Vector2i = state.player + direction
		if state.in_bounds(candidate) and state.get_tile(candidate) == GridTypesRef.TileType.ENTERABLE_WINDOW and not state.has_sleeping_cat_at(candidate):
			return state.outside_window_at(candidate)
	return {}


func find_activatable_cat_lure() -> Dictionary:
	if state == null:
		return {}
	for lure in state.cat_lures:
		if typeof(lure) != TYPE_DICTIONARY:
			continue
		if not is_cat_lure_active_in_current_mode(lure):
			continue
		var lure_position := Vector2i(int(lure.get("x", -1)), int(lure.get("y", -1)))
		var player_position: Vector2i = state.active_position()
		var distance: int = abs(player_position.x - lure_position.x) + abs(player_position.y - lure_position.y)
		if distance <= 1:
			return lure
	return {}


func is_cat_lure_active_in_current_mode(lure: Dictionary) -> bool:
	var kind := str(lure.get("kind", ""))
	if kind != "food_bowl" and kind != "bell":
		return false
	var lure_mode := str(lure.get("mode", "outside"))
	if lure_mode != state.mode:
		return false
	if lure_mode == "room" and str(lure.get("room_id", "")) != state.current_room_id:
		return false
	return true


func find_cat_index(cat_id: String) -> int:
	for index in range(state.cats.size()):
		var cat: Dictionary = state.cats[index]
		if str(cat.get("id", "")) == cat_id:
			return index
	return -1


func has_other_cat_at(position: Vector2i, target_cat_id: String) -> bool:
	for cat in state.cats:
		if str(cat.get("id", "")) == target_cat_id:
			continue
		if Vector2i(int(cat.get("x", -1)), int(cat.get("y", -1))) == position:
			return true
	return false


func _after_state_changed() -> void:
	if state.clear_condition_type == "return_to_outside":
		state.is_cleared = state.mode == "outside" and state.has_entered_room
	else:
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
	title_label.add_theme_color_override("font_color", Color("#2f4858"))
	hud_root.add_child(title_label)

	status_label = Label.new()
	status_label.position = Vector2(24, 48)
	status_label.add_theme_font_size_override("font_size", 16)
	status_label.add_theme_color_override("font_color", Color("#395767"))
	hud_root.add_child(status_label)

	hint_label = Label.new()
	hint_label.position = Vector2(24, 596)
	hint_label.add_theme_font_size_override("font_size", 14)
	hint_label.add_theme_color_override("font_color", Color("#395767"))
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
	hint_label.text = localization.tr_key("ui.room_controls" if state.mode == "room" else "ui.controls")
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

	if state.mode == "room":
		room_view.draw_room(self, state, GRID_ORIGIN, CELL_SIZE)
		_draw_cat_lures()
		_draw_room_player()
		return

	_draw_building_backdrop()
	_draw_tiles()
	_draw_exit_landing_markers()
	_draw_cat_lures()
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
				_draw_window(rect, true, false)
				_draw_cat_face(rect, "right")
			elif tile == GridTypesRef.TileType.ENTERABLE_WINDOW:
				_draw_window(rect, true, false)
				_draw_enterable_window_marker(rect)
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
		_draw_cat_face(rect, "right")


func _draw_enterable_window_marker(rect: Rect2) -> void:
	var center := rect.get_center()
	draw_rect(rect.grow(-8), Color("#f6c84f"), false, 4.0)
	draw_circle(center + Vector2(0, 18), 9.0, Color("#f6c84f"))
	draw_line(center + Vector2(0, 11), center + Vector2(0, -9), Color("#f6c84f"), 4.0)
	draw_line(center + Vector2(0, -9), center + Vector2(-8, -1), Color("#f6c84f"), 4.0)
	draw_line(center + Vector2(0, -9), center + Vector2(8, -1), Color("#f6c84f"), 4.0)


func _draw_exit_landing_markers() -> void:
	for room in state.rooms.values():
		for exit in room.get("exits", []):
			if typeof(exit) != TYPE_DICTIONARY:
				continue
			var landing := Vector2i(int(exit.get("outside_x", -1)), int(exit.get("outside_y", -1)))
			if not state.in_bounds(landing):
				continue
			var rect := Rect2(grid_to_world(landing), Vector2(CELL_SIZE, CELL_SIZE))
			var center := rect.get_center()
			draw_circle(center, 13.0, Color(0.26, 0.69, 0.86, 0.9))
			draw_circle(center, 7.0, Color("#dff3ff"))
			draw_line(center + Vector2(-11, 0), center + Vector2(11, 0), Color("#2d7f9b"), 3.0)
			draw_line(center + Vector2(0, -11), center + Vector2(0, 11), Color("#2d7f9b"), 3.0)


func _draw_cat_lures() -> void:
	for lure in state.cat_lures:
		if typeof(lure) != TYPE_DICTIONARY:
			continue
		if not is_cat_lure_active_in_current_mode(lure):
			continue
		var position := Vector2i(int(lure.get("x", -1)), int(lure.get("y", -1)))
		var rect := Rect2(grid_to_world(position), Vector2(CELL_SIZE, CELL_SIZE))
		var kind := str(lure.get("kind", ""))
		if kind == "food_bowl":
			_draw_food_bowl(rect)
		elif kind == "bell":
			_draw_bell(rect)


func _draw_food_bowl(rect: Rect2) -> void:
	var center := rect.get_center() + Vector2(0, 10)
	draw_circle(center, 17.0, Color("#cfd9e2"))
	draw_arc(center, 18.0, 0.05, PI - 0.05, 18, Color("#6d7d8f"), 3.0)
	draw_circle(center + Vector2(-7, -4), 2.5, Color("#b98244"))
	draw_circle(center + Vector2(1, -6), 2.5, Color("#9f6b3d"))
	draw_circle(center + Vector2(8, -3), 2.5, Color("#b98244"))


func _draw_bell(rect: Rect2) -> void:
	var center := rect.get_center() + Vector2(0, 3)
	draw_arc(center + Vector2(-22, -5), 11.0, -0.55, 0.55, 10, Color(0.52, 0.44, 0.22, 0.45), 2.0)
	draw_arc(center + Vector2(22, -5), 11.0, PI - 0.55, PI + 0.55, 10, Color(0.52, 0.44, 0.22, 0.45), 2.0)
	draw_circle(center + Vector2(0, -19), 5.0, Color("#f7d45b"))
	draw_arc(center, 18.0, PI, TAU, 24, Color("#8f6a24"), 3.0)
	draw_colored_polygon([
		center + Vector2(-17, 0),
		center + Vector2(-10, -22),
		center + Vector2(10, -22),
		center + Vector2(17, 0)
	], Color("#f4bf44"))
	draw_line(center + Vector2(-18, 0), center + Vector2(18, 0), Color("#8f6a24"), 3.0)
	draw_circle(center + Vector2(0, 3), 4.0, Color("#8f6a24"))


func _draw_cats() -> void:
	for cat in state.cats:
		var cat_position = Vector2i(int(cat.get("x", 0)), int(cat.get("y", 0)))
		var rect = Rect2(grid_to_world(cat_position), Vector2(CELL_SIZE, CELL_SIZE))
		var look_dir := str(cat.get("look_dir", "right"))
		var cat_state := str(cat.get("state", "watching"))
		if cat_state != "sleeping":
			_draw_cat_hint(cat, cat_position)
		_draw_window(rect, true, false)
		if cat_state == "sleeping":
			_draw_sleeping_cat_face(rect)
		else:
			_draw_cat_face(rect, look_dir)


func _draw_cat_face(rect: Rect2, look_dir: String) -> void:
	var glass_rect = rect.grow(-17)
	var center = glass_rect.get_center() + Vector2(0, 6)
	var eye_offset := _cat_eye_offset(look_dir)
	draw_circle(center, 14.0, Color("#2d2730"))
	draw_circle(center + Vector2(-5, -1) + eye_offset, 2.3, Color("#f8e777"))
	draw_circle(center + Vector2(5, -1) + eye_offset, 2.3, Color("#f8e777"))
	draw_circle(center + Vector2(0, 5) + eye_offset * 0.35, 1.6, Color("#f1a4b9"))


func _draw_sleeping_cat_face(rect: Rect2) -> void:
	var glass_rect = rect.grow(-17)
	var center = glass_rect.get_center() + Vector2(0, 7)
	draw_circle(center, 14.0, Color("#2d2730"))
	draw_arc(center + Vector2(-6, -3), 4.0, 0.1, PI - 0.1, 8, Color("#f8e777"), 2.0)
	draw_arc(center + Vector2(6, -3), 4.0, 0.1, PI - 0.1, 8, Color("#f8e777"), 2.0)
	draw_circle(center + Vector2(0, 5), 1.6, Color("#f1a4b9"))
	var sleep_color := Color(0.95, 0.98, 1.0, 0.72)
	draw_circle(center + Vector2(10, -12), 2.6, Color(0.95, 0.98, 1.0, 0.38))
	draw_circle(center + Vector2(15, -18), 3.6, sleep_color)
	draw_circle(center + Vector2(22, -25), 5.0, Color(0.95, 0.98, 1.0, 0.5))


func _cat_eye_offset(look_dir: String) -> Vector2:
	if look_dir == "left":
		return Vector2(-5, 0)
	if look_dir == "up":
		return Vector2(0, -5)
	if look_dir == "down":
		return Vector2(0, 5)
	return Vector2(5, 0)


func _draw_cat_hint(cat: Dictionary, cat_position: Vector2i) -> void:
	if not cat.has("hint_target") or typeof(cat.get("hint_target")) != TYPE_DICTIONARY:
		return
	var target_data: Dictionary = cat.get("hint_target")
	var target := Vector2i(int(target_data.get("x", cat_position.x)), int(target_data.get("y", cat_position.y)))
	if not state.in_bounds(target):
		return

	var from := grid_to_world(cat_position) + Vector2(CELL_SIZE, CELL_SIZE) * 0.5
	var to := grid_to_world(target) + Vector2(CELL_SIZE, CELL_SIZE) * 0.5
	var direction := to - from
	if direction.length() <= 1.0:
		return
	var unit := direction.normalized()
	from += unit * 19.0
	to -= unit * 15.0
	_draw_dotted_line(from, to, Color(0.98, 0.88, 0.33, 0.34), 2.5, 7.0, 8.0)

	var target_rect := Rect2(grid_to_world(target), Vector2(CELL_SIZE, CELL_SIZE))
	var target_center := target_rect.get_center()
	draw_circle(target_center, 13.0, Color(0.98, 0.88, 0.33, 0.11))
	draw_circle(target_center, 4.0, Color(0.98, 0.88, 0.33, 0.34))


func _draw_dotted_line(from: Vector2, to: Vector2, color: Color, width: float, dash: float, gap: float) -> void:
	var direction := to - from
	var length := direction.length()
	if length <= 0.0:
		return
	var unit := direction / length
	var cursor := 0.0
	while cursor < length:
		var segment_end = minf(cursor + dash, length)
		draw_line(from + unit * cursor, from + unit * segment_end, color, width)
		cursor += dash + gap


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


func _draw_room_player() -> void:
	var rect = Rect2(grid_to_world(state.room_player), Vector2(CELL_SIZE, CELL_SIZE))
	var center = rect.get_center()
	draw_circle(center + Vector2(0, -8), 12.0, Color("#355c9b"))
	draw_rect(Rect2(center + Vector2(-13, 3), Vector2(26, 24)), Color("#457bd6"), true)
	draw_circle(center + Vector2(-4, -10), 2.0, Color("#fff5dc"))
	draw_circle(center + Vector2(5, -10), 2.0, Color("#fff5dc"))


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
