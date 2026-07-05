class_name LocalizationManager
extends RefCounted

var language: String = "ja"
var strings: Dictionary = {}


func load_strings(path: String) -> void:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Could not open localization file: %s" % path)
		strings = {}
		return

	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) == TYPE_DICTIONARY:
		strings = parsed
	else:
		push_error("Localization file is not a JSON object: %s" % path)
		strings = {}


func set_language(next_language: String) -> void:
	if next_language == "ja" or next_language == "en":
		language = next_language


func tr_key(key: String, values: Dictionary = {}) -> String:
	var entry: Dictionary = strings.get(key, {})
	var text := str(entry.get(language, entry.get("en", key)))
	if values.is_empty():
		return text
	return text.format(values)

