extends Interactable
class_name NoteObj
## Readable note/document/photo in the world. Opens inspect panel.

var text_id: String = ""
var photo_id: String = ""
var once_flag: String = ""

func setup_note(id: String, p_once: String = "") -> void:
	text_id = id
	once_flag = p_once
	prompt = Fa.PROMPT["read"]

func setup_photo(id: String) -> void:
	photo_id = id
	prompt = Fa.PROMPT["examine"]

func can_interact() -> bool:
	return enabled

func interact(_player: Node) -> void:
	AudioMgr.play_sfx("res://assets/audio/sfx/paper.wav", -4.0)
	var panel: Control = load("res://scripts/ui/inspect.gd").new()
	if photo_id != "":
		var pdata: Dictionary = Fa.PHOTOS.get(photo_id, {})
		var body: String = str(pdata.get("cap", ""))
		panel.fill(body, "عکس خانوادگی — " + str(pdata.get("year", "")), str(pdata.get("img", "")))
		if not GameState.photos_seen.has(photo_id):
			GameState.photos_seen.append(photo_id)
			GameState.set_flag("seen_" + photo_id)
			if GameState.photos_seen.size() >= 4:
				EventBus.toast.emit(Fa.MSG["photos_hint"], 4.0)
				if GameState.has_item("symbols_paper"):
					var p2: Control = load("res://scripts/ui/inspect.gd").new()
					p2.fill(Fa.NOTES["photos_read"]["body"], Fa.NOTES["photos_read"]["title"])
					get_viewport().call_deferred("add_child", p2)
	else:
		var nd: Dictionary = Fa.NOTES.get(text_id, {})
		panel.fill(str(nd.get("body", "")), str(nd.get("title", "")))
		get_viewport().add_child(panel)
		if once_flag != "":
			GameState.set_flag(once_flag)
			match once_flag:
				"read_diary":
					EventBus.toast.emit(Fa.MSG["diary_hint"], 4.0)
				"read_vestibule_note":
					GameState.set_objective(Fa.OBJ["c4_fuse"])
	# mark story flags by text_id
	match text_id:
		"diary":
			GameState.set_flag("read_diary")
		"study_files":
			GameState.set_flag("read_study_files")
		"study_diagram":
			GameState.set_flag("read_diagram")
		"symbols_note":
			GameState.set_flag("has_symbols")
			GameState.add_item("symbols_paper")
		"cassette_text":
			pass
		"note_vestibule":
			GameState.set_flag("read_vestibule_note")
