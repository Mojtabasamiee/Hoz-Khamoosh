extends Node
## GameState — progress, flags, items, chapter flow.

const MAX_CHAPTER := 8

var chapter: int = 1
var objective: String = ""
var flags: Dictionary = {}
var items: Array = []
var photos_seen: Array = []
var decision: String = ""
var ui_open: bool = false
var loaded_from_save: bool = false
var ending_watched: String = ""

func _ready() -> void:
	randomize()

func reset_new_game() -> void:
	chapter = 1
	flags = {}
	items = ["note_letter"]
	photos_seen = []
	decision = ""
	ui_open = false
	loaded_from_save = false
	ending_watched = ""
	set_objective(Fa.OBJ["c1_read"])

func has_item(id: String) -> bool:
	return items.has(id)

func add_item(id: String) -> void:
	if not items.has(id):
		items.append(id)
		EventBus.item_added.emit(id)

func remove_item(id: String) -> void:
	if items.has(id):
		items.erase(id)
		EventBus.item_removed.emit(id)

func set_flag(name: String, value: bool = true) -> void:
	flags[name] = value

func get_flag(name: String) -> bool:
	return flags.get(name, false)

func set_objective(text: String) -> void:
	objective = text
	EventBus.objective_changed.emit(text)

func set_chapter(n: int) -> void:
	chapter = n
	EventBus.chapter_changed.emit(n)

func set_ui_open(open: bool) -> void:
	ui_open = open
	EventBus.ui_open_changed.emit(open)

func to_save_data() -> Dictionary:
	return {
		"chapter": chapter,
		"objective": objective,
		"flags": flags,
		"items": items,
		"photos_seen": photos_seen,
		"decision": decision,
		"ending_watched": ending_watched,
	}

func apply_save(data: Dictionary) -> void:
	chapter = int(data.get("chapter", 1))
	objective = str(data.get("objective", ""))
	flags = data.get("flags", {})
	items = data.get("items", [])
	photos_seen = data.get("photos_seen", [])
	decision = str(data.get("decision", ""))
	ending_watched = str(data.get("ending_watched", ""))
	loaded_from_save = true

func to_fa_num(s: String) -> String:
	return Fa.to_fa_num(s)
