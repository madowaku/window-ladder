class_name LevelLoader
extends RefCounted

const GameStateScript = preload("res://scripts/core/GameState.gd")
const GridTypesRef = preload("res://scripts/core/GridTypes.gd")


func load_level(path: String):
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Could not open level file: %s" % path)
		return null

	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("Level file is not a JSON object: %s" % path)
		return null

	var data: Dictionary = parsed
	var state = GameStateScript.new()
	state.stage_id = str(data.get("id", ""))
	state.name_key = str(data.get("name_key", ""))
	state.chapter = int(data.get("chapter", 1))
	state.order = int(data.get("order", 1))

	var size: Dictionary = data.get("size", {})
	state.width = int(size.get("width", 0))
	state.height = int(size.get("height", 0))

	var player: Dictionary = data.get("player", {})
	state.player = Vector2i(int(player.get("x", 0)), int(player.get("y", 0)))
	state.tiles = _parse_tiles(data.get("tiles", []), state.width, state.height)
	state.ladders = _clone_dictionary_array(data.get("ladders", []))
	state.cats = _clone_dictionary_array(data.get("cats", []))
	state.cat_lures = _clone_dictionary_array(data.get("cat_lures", []))
	state.enterable_windows = _clone_dictionary_array(data.get("enterable_windows", []))
	state.rooms = _parse_rooms(data.get("rooms", []))
	var clear_condition: Dictionary = data.get("clear_condition", {})
	state.clear_condition_type = str(clear_condition.get("type", "clean_all_dirty_windows"))
	state.is_cleared = state.clear_condition_type == "clean_all_dirty_windows" and state.dirty_window_count() == 0
	return state


func _parse_tiles(rows: Array, width: int, height: int) -> Array:
	var parsed_rows := []
	for y in range(height):
		var source := ""
		if y < rows.size():
			source = str(rows[y])
		var parsed_row := []
		for x in range(width):
			var symbol := "."
			if x < source.length():
				symbol = source.substr(x, 1)
			parsed_row.append(GridTypesRef.tile_from_symbol(symbol))
		parsed_rows.append(parsed_row)
	return parsed_rows


func _clone_dictionary_array(source: Array) -> Array:
	var copy := []
	for item in source:
		if typeof(item) == TYPE_DICTIONARY:
			copy.append((item as Dictionary).duplicate(true))
	return copy


func _parse_rooms(source: Array) -> Dictionary:
	var rooms := {}
	for room_data in source:
		if typeof(room_data) != TYPE_DICTIONARY:
			continue
		var room: Dictionary = (room_data as Dictionary).duplicate(true)
		rooms[str(room.get("id", ""))] = room
	return rooms
