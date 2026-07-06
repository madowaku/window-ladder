class_name GameState
extends RefCounted

const GridTypesRef = preload("res://scripts/core/GridTypes.gd")

var stage_id: String = ""
var name_key: String = ""
var chapter: int = 1
var order: int = 1
var width: int = 0
var height: int = 0
var tiles: Array = []
var player: Vector2i = Vector2i.ZERO
var ladders: Array = []
var cats: Array = []
var cat_lures: Array = []
var enterable_windows: Array = []
var rooms: Dictionary = {}
var clear_condition_type: String = "clean_all_dirty_windows"
var mode: String = "outside"
var current_room_id: String = ""
var room_player: Vector2i = Vector2i.ZERO
var has_entered_room: bool = false
var move_count: int = 0
var is_cleared: bool = false


func clone():
	var copy = get_script().new()
	copy.stage_id = stage_id
	copy.name_key = name_key
	copy.chapter = chapter
	copy.order = order
	copy.width = width
	copy.height = height
	copy.tiles = _clone_tile_rows()
	copy.player = player
	copy.ladders = _clone_dictionary_array(ladders)
	copy.cats = _clone_dictionary_array(cats)
	copy.cat_lures = _clone_dictionary_array(cat_lures)
	copy.enterable_windows = _clone_dictionary_array(enterable_windows)
	copy.rooms = _clone_rooms()
	copy.clear_condition_type = clear_condition_type
	copy.mode = mode
	copy.current_room_id = current_room_id
	copy.room_player = room_player
	copy.has_entered_room = has_entered_room
	copy.move_count = move_count
	copy.is_cleared = is_cleared
	return copy


func in_bounds(position: Vector2i) -> bool:
	return position.x >= 0 and position.y >= 0 and position.x < width and position.y < height


func get_tile(position: Vector2i) -> int:
	if not in_bounds(position):
		return GridTypesRef.TileType.WALL
	return int(tiles[position.y][position.x])


func set_tile(position: Vector2i, tile: int) -> void:
	if in_bounds(position):
		tiles[position.y][position.x] = tile


func has_cat_at(position: Vector2i) -> bool:
	for cat in cats:
		if Vector2i(int(cat.get("x", -1)), int(cat.get("y", -1))) == position:
			return true
	return false


func has_sleeping_cat_at(position: Vector2i) -> bool:
	for cat in cats:
		if str(cat.get("state", "watching")) != "sleeping":
			continue
		if Vector2i(int(cat.get("x", -1)), int(cat.get("y", -1))) == position:
			return true
	return false


func dirty_window_count() -> int:
	var count := 0
	for y in range(height):
		for x in range(width):
			if int(tiles[y][x]) == GridTypesRef.TileType.WINDOW_DIRTY:
				count += 1
	return count


func active_position() -> Vector2i:
	if mode == "room":
		return room_player
	return player


func active_room() -> Dictionary:
	if mode != "room":
		return {}
	return rooms.get(current_room_id, {})


func room_in_bounds(room: Dictionary, position: Vector2i) -> bool:
	var size: Dictionary = room.get("size", {})
	var room_width := int(size.get("width", 0))
	var room_height := int(size.get("height", 0))
	return position.x >= 0 and position.y >= 0 and position.x < room_width and position.y < room_height


func get_room_tile(room: Dictionary, position: Vector2i) -> String:
	if not room_in_bounds(room, position):
		return "#"
	var rows: Array = room.get("tiles", [])
	if position.y >= rows.size():
		return "#"
	var row := str(rows[position.y])
	if position.x >= row.length():
		return "#"
	return row.substr(position.x, 1)


func is_room_walkable(position: Vector2i) -> bool:
	var room := active_room()
	if room.is_empty():
		return false
	var tile := get_room_tile(room, position)
	return tile == "F" or tile == "." or tile == "X"


func room_exit_at(position: Vector2i) -> Dictionary:
	var room := active_room()
	if room.is_empty():
		return {}
	for exit in room.get("exits", []):
		if typeof(exit) != TYPE_DICTIONARY:
			continue
		if Vector2i(int(exit.get("x", -1)), int(exit.get("y", -1))) == position:
			return exit
	return {}


func outside_window_at(position: Vector2i) -> Dictionary:
	for window in enterable_windows:
		if Vector2i(int(window.get("x", -1)), int(window.get("y", -1))) == position:
			return window
	return {}


func room_entry_position(room_id: String, entry_id: String) -> Vector2i:
	var room: Dictionary = rooms.get(room_id, {})
	var entries: Array = room.get("entries", [])
	for entry in entries:
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		if str(entry.get("id", "")) == entry_id:
			return Vector2i(int(entry.get("x", 0)), int(entry.get("y", 0)))
	return Vector2i.ZERO


func ladder_cells(ladder: Dictionary) -> Array:
	var cells := []
	var x := int(ladder.get("x", 0))
	var bottom_y := int(ladder.get("bottom_y", 0))
	var length := int(ladder.get("length", 1))
	for offset in range(length):
		cells.append(Vector2i(x, bottom_y - offset))
	return cells


func is_ladder_cell(position: Vector2i) -> bool:
	for ladder in ladders:
		if ladder_cells(ladder).has(position):
			return true
	return false


func ladder_at_bottom_neighbor(position: Vector2i) -> Dictionary:
	for ladder in ladders:
		var bottom := Vector2i(int(ladder.get("x", 0)), int(ladder.get("bottom_y", 0)))
		if position == bottom + Vector2i(-1, 0) or position == bottom + Vector2i(1, 0):
			return ladder
	return {}


func _clone_tile_rows() -> Array:
	var rows := []
	for row in tiles:
		var next_row := []
		for tile in row:
			next_row.append(tile)
		rows.append(next_row)
	return rows


func _clone_dictionary_array(source: Array) -> Array:
	var copy := []
	for item in source:
		copy.append((item as Dictionary).duplicate(true))
	return copy


func _clone_rooms() -> Dictionary:
	var copy := {}
	for key in rooms.keys():
		copy[key] = (rooms[key] as Dictionary).duplicate(true)
	return copy
