class_name UndoManager
extends RefCounted

var history: Array = []


func push_state(state) -> void:
	history.append(state.clone())


func can_undo() -> bool:
	return not history.is_empty()


func undo():
	if history.is_empty():
		return null
	return history.pop_back()


func clear() -> void:
	history.clear()
