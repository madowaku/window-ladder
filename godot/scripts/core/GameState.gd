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


func dirty_window_count() -> int:
	var count := 0
	for y in range(height):
		for x in range(width):
			if int(tiles[y][x]) == GridTypesRef.TileType.WINDOW_DIRTY:
				count += 1
	return count


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
