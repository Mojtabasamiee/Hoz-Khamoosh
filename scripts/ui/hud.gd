extends CanvasLayer
## HUD — crosshair, prompt, objective, toasts, battery, buttons, fade.

var prompt_label: Label
var objective_label: Label
var crosshair: ColorRect
var battery: ProgressBar
var fade_rect: ColorRect
var toast_label: Label
var _toast_tw: Tween

func _ready() -> void:
        layer = 5
        # crosshair
        crosshair = ColorRect.new()
        crosshair.color = Color(1, 1, 1, 0.55)
        crosshair.custom_minimum_size = Vector2(5, 5)
        crosshair.set_anchors_preset(Control.PRESET_CENTER)
        crosshair.position = Vector2(-2.5, -2.5)
        crosshair.size = Vector2(5, 5)
        add_child(crosshair)

        # interaction prompt (bottom center)
        prompt_label = UIH.centered_label("", 24, Color(0.95, 0.97, 0.9), true)
        prompt_label.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
        prompt_label.position = Vector2(-260, -150)
        prompt_label.size = Vector2(520, 44)
        prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        add_child(prompt_label)

        # objective (top right)
        objective_label = UIH.label("", 20, Color(0.75, 0.9, 0.92))
        objective_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
        objective_label.position = Vector2(-520, 18)
        objective_label.size = Vector2(500, 60)
        objective_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
        objective_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        add_child(objective_label)

        # toast (upper center)
        toast_label = UIH.centered_label("", 22, Color(0.95, 0.9, 0.75))
        toast_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
        toast_label.position = Vector2(-420, 110)
        toast_label.size = Vector2(840, 70)
        toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        toast_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        toast_label.modulate.a = 0.0
        add_child(toast_label)

        # battery bar (top left, hidden)
        battery = ProgressBar.new()
        battery.custom_minimum_size = Vector2(150, 12)
        battery.set_anchors_preset(Control.PRESET_TOP_LEFT)
        battery.position = Vector2(24, 24)
        battery.min_value = 0
        battery.max_value = 100
        battery.value = 100
        battery.visible = false
        add_child(battery)

        # fade overlay
        fade_rect = ColorRect.new()
        fade_rect.color = Color(0, 0, 0, 1)
        fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
        fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
        add_child(fade_rect)
        fade_in(1.2)

        # buttons (pause + inventory) small top-left cluster — desktop only.
        # On Android the TouchUI layer provides its own bigger touch buttons.
        var btns := HBoxContainer.new()
        btns.position = Vector2(24, 48)
        btns.add_theme_constant_override("separation", 8)
        add_child(btns)
        var b_inv := UIH.button(Fa.UI["inventory"], 16, 110)
        b_inv.custom_minimum_size = Vector2(110, 40)
        b_inv.pressed.connect(func():
                var game := get_tree().get_first_node_in_group("game_root")
                if game != null:
                        game.call("toggle_inventory"))
        btns.add_child(b_inv)
        var b_pause := UIH.button("مکث", 16, 70)
        b_pause.custom_minimum_size = Vector2(70, 40)
        b_pause.pressed.connect(func():
                var game := get_tree().get_first_node_in_group("game_root")
                if game != null:
                        game.call("toggle_pause"))
        btns.add_child(b_pause)
        if OS.has_feature("android") or bool(AudioMgr.get_setting("force_touch", false)):
                btns.visible = false

        # signals
        EventBus.objective_changed.connect(_on_objective)
        EventBus.prompt_changed.connect(_on_prompt)
        EventBus.toast.connect(show_toast)
        EventBus.flashlight_state.connect(_on_flash)
        EventBus.request_fade.connect(func(out, dur): fade_out(dur) if out else fade_in(dur))

func _on_objective(t: String) -> void:
        objective_label.text = "هدف: " + t

func _on_prompt(t: String) -> void:
        prompt_label.text = t

func show_toast(text: String, dur: float = 3.0) -> void:
        toast_label.text = text
        if _toast_tw != null and _toast_tw.is_valid():
                _toast_tw.kill()
        toast_label.modulate.a = 0.0
        _toast_tw = create_tween()
        _toast_tw.tween_property(toast_label, "modulate:a", 1.0, 0.3)
        _toast_tw.tween_interval(dur)
        _toast_tw.tween_property(toast_label, "modulate:a", 0.0, 0.6)

func _on_flash(on: bool, b: float) -> void:
        battery.visible = on
        battery.value = b

func fade_out(dur: float = 1.0) -> void:
        var tw := create_tween()
        tw.tween_property(fade_rect, "color:a", 1.0, dur)

func fade_in(dur: float = 1.0) -> void:
        var tw := create_tween()
        tw.tween_property(fade_rect, "color:a", 0.0, dur)

func set_crosshair(show_it: bool) -> void:
        crosshair.visible = show_it
