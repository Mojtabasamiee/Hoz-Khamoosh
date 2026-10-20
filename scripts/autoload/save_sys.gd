extends Node
## SaveSys — JSON save/load with graceful corruption handling.

const PATH := "user://hoz_khamoosh_save.json"

func has_save() -> bool:
	return FileAccess.file_exists(PATH)

func save_game(data: Dictionary) -> bool:
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(JSON.stringify(data, "\t"))
	f.close()
	return true

func load_game() -> Dictionary:
	if not has_save():
		return {}
	var f := FileAccess.open(PATH, FileAccess.READ)
	if f == null:
		return {}
	var txt := f.get_as_text()
	f.close()
	var parsed = JSON.parse_string(txt)
	if typeof(parsed) != TYPE_DICTIONARY:
		# corrupted or invalid: remove it gracefully
		DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))
		return {}
	return parsed

func delete_save() -> void:
	if has_save():
		DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))
