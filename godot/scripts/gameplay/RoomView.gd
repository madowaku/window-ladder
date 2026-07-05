class_name RoomView
extends RefCounted


func draw_room(canvas: CanvasItem, state, origin: Vector2, cell_size: int) -> void:
	var room: Dictionary = state.active_room()
	if room.is_empty():
		return

	var size: Dictionary = room.get("size", {})
	var width = int(size.get("width", 0))
	var height = int(size.get("height", 0))
	var board_size = Vector2(width * cell_size, height * cell_size)
	var frame = Rect2(origin - Vector2(8, 8), board_size + Vector2(16, 16))
	canvas.draw_rect(frame, Color("#5f6f7a"), true)
	canvas.draw_rect(frame, Color("#263845"), false, 3.0)

	for y in range(height):
		for x in range(width):
			var cell = Vector2i(x, y)
			var rect = Rect2(origin + Vector2(x * cell_size, y * cell_size), Vector2(cell_size, cell_size))
			var tile = state.get_room_tile(room, cell)
			if tile == "#":
				canvas.draw_rect(rect, Color("#2f3f4a"), true)
			elif tile == "X":
				canvas.draw_rect(rect, Color("#badcf4"), true)
				canvas.draw_rect(rect.grow(-12), Color("#7b5540"), true)
				canvas.draw_rect(rect.grow(-18), Color("#b9ecff"), true)
				_draw_exit_marker(canvas, rect)
			else:
				canvas.draw_rect(rect, Color("#d8c7a3"), true)
			canvas.draw_rect(rect, Color(0.1, 0.15, 0.18, 0.35), false, 1.0)


func _draw_exit_marker(canvas: CanvasItem, rect: Rect2) -> void:
	var center = rect.get_center()
	canvas.draw_rect(rect.grow(-7), Color("#6fd083"), false, 4.0)
	canvas.draw_line(center + Vector2(-12, 0), center + Vector2(12, 0), Color("#276a3a"), 4.0)
	canvas.draw_line(center + Vector2(12, 0), center + Vector2(4, -8), Color("#276a3a"), 4.0)
	canvas.draw_line(center + Vector2(12, 0), center + Vector2(4, 8), Color("#276a3a"), 4.0)
