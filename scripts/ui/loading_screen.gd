extends CanvasLayer
## LoadingScreen — fullscreen loader: Persian title, animated bar, rotating control tips.
## Usage:  var ls = load("res://scripts/ui/loading_screen.gd").new()
##         ls.setup("عنوان", "زیرنویس")
##         get_viewport().add_child(ls)
##         ... heavy work ...
##         ls.close(0.6)

var title_text := ""
var sub_text := ""
var _root: Control
var tip_label: Label
var _bar: ProgressBar
var _tip_idx := 0
var _tip_acc := 0.0
var _closing := false

func setup(title: String, sub: String = "") -> void:
        title_text = title
        sub_text = sub

func _ready() -> void:
        layer = 30
        process_mode = Node.PROCESS_MODE_ALWAYS

        _root = Control.new()
        _root.set_anchors_preset(Control.PRESET_FULL_RECT)
        _root.mouse_filter = Control.MOUSE_FILTER_IGNORE
        add_child(_root)

        var bg := ColorRect.new()
        bg.color = Color(0.01, 0.015, 0.025, 1.0)
        bg.set_anchors_preset(Control.PRESET_FULL_RECT)
        _root.add_child(bg)

        # faint vignette-ish accent line
        var line := ColorRect.new()
        line.color = Color(0.24, 0.62, 0.68, 0.35)
        line.anchor_left = 0.3
        line.anchor_right = 0.7
        line.anchor_top = 0.0
        line.anchor_bottom = 0.0
        line.offset_top = 0
        line.offset_bottom = 2
        _root.add_child(line)

        var vb := VBoxContainer.new()
        vb.set_anchors_preset(Control.PRESET_FULL_RECT)
        vb.alignment = BoxContainer.ALIGNMENT_CENTER
        vb.add_theme_constant_override("separation", 8)
        _root.add_child(vb)

        var title := UIH.centered_label(title_text if title_text != "" else Fa.GAME_TITLE, 36, UIH.COL_ACCENT, true)
        vb.add_child(title)
        if sub_text != "":
                vb.add_child(UIH.centered_label(sub_text, 18, UIH.COL_DIM))

        vb.add_child(UIH.vspace(30))
        _bar = ProgressBar.new()
        _bar.show_percentage = false
        _bar.custom_minimum_size = Vector2(440, 8)
        _bar.max_value = 1.0
        _bar.value = 0.0
        var sb := StyleBoxFlat.new()
        sb.bg_color = Color(0.08, 0.12, 0.14, 0.9)
        sb.set_corner_radius_all(4)
        var sbf := StyleBoxFlat.new()
        sbf.bg_color = UIH.COL_ACCENT
        sbf.set_corner_radius_all(4)
        _bar.add_theme_stylebox_override("background", sb)
        _bar.add_theme_stylebox_override("fill", sbf)
        var cc := CenterContainer.new()
        cc.add_child(_bar)
        vb.add_child(cc)

        vb.add_child(UIH.vspace(26))
        tip_label = UIH.centered_label("", 17, Color(0.72, 0.8, 0.78))
        tip_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        tip_label.custom_minimum_size = Vector2(0, 60)
        var tcc := CenterContainer.new()
        tip_label.custom_minimum_size = Vector2(560, 56)
        tcc.add_child(tip_label)
        vb.add_child(tcc)

        vb.add_child(UIH.vspace(16))
        vb.add_child(UIH.centered_label(Fa.DEV_NAME + "  |  SGS", 13, Color(0.42, 0.47, 0.47)))

        _pick_tip()

func _process(delta: float) -> void:
        # smooth indeterminate sweep 0 -> 1 -> 0
        var t := fmod(Time.get_ticks_msec() / 1700.0, 1.0)
        _bar.value = 0.5 - 0.5 * cos(t * TAU)
        # rotate tips every 3.5s
        _tip_acc += delta
        if _tip_acc >= 3.5:
                _tip_acc = 0.0
                _pick_tip()

func _pick_tip() -> void:
        if tip_label == null:
                return
        tip_label.text = "« " + Fa.LOAD_TIPS[_tip_idx % Fa.LOAD_TIPS.size()] + " »"
        _tip_idx += 1

func close(min_delay: float = 0.4) -> void:
        if _closing:
                return
        _closing = true
        await get_tree().create_timer(min_delay).timeout
        var tw := create_tween()
        tw.tween_property(_root, "modulate:a", 0.0, 0.5)
        tw.tween_callback(queue_free)
