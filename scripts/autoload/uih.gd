extends Node
## UIH — Persian UI factory: fonts, labels, buttons, panels.

var font_regular: FontFile
var font_medium: FontFile
var font_bold: FontFile

const COL_BG := Color(0.03, 0.045, 0.06, 0.92)
const COL_PANEL := Color(0.055, 0.075, 0.09, 0.96)
const COL_TEXT := Color(0.88, 0.90, 0.88)
const COL_DIM := Color(0.62, 0.66, 0.64)
const COL_ACCENT := Color(0.24, 0.62, 0.68)      # turquoise
const COL_ACCENT2 := Color(0.16, 0.45, 0.52)

func _ready() -> void:
        font_regular = load("res://assets/fonts/Vazirmatn-Regular.ttf")
        font_medium = load("res://assets/fonts/Vazirmatn-Medium.ttf")
        font_bold = load("res://assets/fonts/Vazirmatn-Bold.ttf")

func label(text: String, size: int = 20, color: Color = COL_TEXT, bold: bool = false) -> Label:
        var l := Label.new()
        l.text = text
        l.add_theme_font_override("font", font_bold if bold else font_regular)
        l.add_theme_font_size_override("font_size", size)
        l.add_theme_color_override("font_color", color)
        l.set("text_direction", Control.TEXT_DIRECTION_RTL)
        l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
        return l

func centered_label(text: String, size: int = 20, color: Color = COL_TEXT, bold: bool = false) -> Label:
        var l := label(text, size, color, bold)
        l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        return l

func button(text: String, size: int = 22, min_width: float = 320.0) -> Button:
        var b := Button.new()
        b.text = text
        b.add_theme_font_override("font", font_medium)
        b.add_theme_font_size_override("font_size", size)
        b.add_theme_color_override("font_color", COL_TEXT)
        b.add_theme_color_override("font_hover_color", Color(0.55, 0.92, 0.95))
        b.add_theme_color_override("font_pressed_color", Color(0.4, 0.85, 0.9))
        b.add_theme_color_override("font_focus_color", COL_TEXT)
        b.set("text_direction", Control.TEXT_DIRECTION_RTL)
        b.alignment = HORIZONTAL_ALIGNMENT_CENTER
        b.custom_minimum_size = Vector2(min_width, 52)
        var sb := StyleBoxFlat.new()
        sb.bg_color = Color(0.07, 0.10, 0.12, 0.85)
        sb.border_color = Color(0.18, 0.42, 0.48, 0.8)
        sb.set_border_width_all(1)
        sb.set_corner_radius_all(6)
        sb.set_content_margin_all(10)
        var sbh := sb.duplicate()
        sbh.bg_color = Color(0.10, 0.17, 0.19, 0.95)
        sbh.border_color = COL_ACCENT
        var sbp := sb.duplicate()
        sbp.bg_color = Color(0.13, 0.22, 0.25, 1.0)
        b.add_theme_stylebox_override("normal", sb)
        b.add_theme_stylebox_override("hover", sbh)
        b.add_theme_stylebox_override("pressed", sbp)
        b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
        b.pressed.connect(func(): AudioMgr.play_sfx("res://assets/audio/sfx/ui_click.wav", -6.0))
        return b

func panel_style(bg: Color = COL_PANEL, border: Color = Color(0.2, 0.5, 0.55, 0.6), radius: int = 10, border_w: int = 1) -> StyleBoxFlat:
        var sb := StyleBoxFlat.new()
        sb.bg_color = bg
        sb.border_color = border
        sb.set_border_width_all(border_w)
        sb.set_corner_radius_all(radius)
        sb.set_content_margin_all(18)
        return sb

func panel(bg: Color = COL_PANEL) -> PanelContainer:
        var p := PanelContainer.new()
        p.add_theme_stylebox_override("panel", panel_style(bg))
        return p

func vspace(px: float) -> Control:
        var c := Control.new()
        c.custom_minimum_size = Vector2(0, px)
        return c

func hspace(px: float) -> Control:
        var c := Control.new()
        c.custom_minimum_size = Vector2(px, 0)
        return c

## Wrap a full-screen panel in a CanvasLayer ABOVE the touch UI (layer 6) and HUD (layer 5),
## so its buttons receive touches on Android. The wrapper frees itself when the panel closes.
func overlay(panel: Control, layer_num: int = 20) -> CanvasLayer:
        var cl := CanvasLayer.new()
        cl.layer = layer_num
        cl.name = "OverlayLayer"
        cl.add_child(panel)
        panel.tree_exited.connect(cl.queue_free)
        return cl
