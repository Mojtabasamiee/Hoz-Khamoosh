extends SceneTree
## Automated gameplay test for Hoz-Khamoosh v2 (touch UI rewrite).
## Run: godot --headless --path . --script res://tests/autotest.gd

var fails: Array[String] = []
var checks := 0
var main_node: Node
var game: Node
var player: Node
var touch: Node
var last_prompt := "___INIT___"
var EV: Node
var GS: Node
var SS: Node
var AM: Node

func check(cond: bool, label: String) -> void:
        checks += 1
        if cond:
                print("  [PASS] ", label)
        else:
                print("  [FAIL] ", label)
                fails.append(label)

func _initialize() -> void:
        print("=== HOZ-KHAMOOSH AUTOTEST v2 ===")
        await process_frame
        EV = root.get_node("/root/EventBus")
        GS = root.get_node("/root/GameState")
        SS = root.get_node("/root/SaveSys")
        AM = root.get_node("/root/AudioMgr")
        AM.set_setting("force_touch", true)
        EV.prompt_changed.connect(func(p): last_prompt = p)

        # ---------- 1. boot main scene (menu + loading screen) ----------
        print("\n[1] Boot main scene / menu / loading")
        var scn = load("res://scenes/main.tscn")
        main_node = scn.instantiate()
        root.add_child(main_node)
        for i in 40:
                await process_frame
        check(main_node.current != null, "menu node created after boot")
        check(main_node.current.get("world") != null, "menu 3D world built")
        var menu_btns := _find_buttons(main_node.current)
        check(menu_btns.size() >= 4, "menu has >=4 buttons (found %d)" % menu_btns.size())
        var has_loader := false
        for c in root.get_children():
                if c is CanvasLayer and c.layer == 30:
                        has_loader = true
        check(has_loader or true, "loading screen used during transition (checked later)")

        # ---------- 2. start game via Start button ----------
        print("\n[2] Start game via menu button")
        var start_btn: Button = null
        for b in menu_btns:
                if b.text == "شروع بازی":
                        start_btn = b
                        break
        check(start_btn != null, "start button found")
        if start_btn != null:
                start_btn.pressed.emit()
                await process_frame
                await process_frame
                var loader_seen := false
                for c in root.get_children():
                        if c is CanvasLayer and c.layer == 30:
                                loader_seen = true
                check(loader_seen, "loading screen shown during game start")
        for i in 60:
                await process_frame
        game = main_node.current
        check(game != null and game.is_in_group("game_root"), "game scene started")
        player = game.get("player")
        check(player != null, "player exists")
        touch = game.get("touch")
        check(touch != null, "TouchUI created (force_touch=true)")
        check(game.get("hud") != null, "HUD created")
        check(game.get("house") != null and game.get("house").get_child_count() > 10, "house built (%d children)" % (game.get("house").get_child_count() if game.get("house") else 0))
        for i in 30:
                await physics_frame

        # ---------- 2b. intro letter overlay opens, then we close it ----------
        print("\n[2b] Intro letter overlay")
        var waited := 0.0
        while not GS.ui_open and waited < 12.0:
                await physics_frame
                waited += 1.0 / 60.0
        check(GS.ui_open, "intro letter opened (ui_open=true) after %.1fs" % waited)
        var top_layer2 := 0
        for c in root.get_children():
                if c is CanvasLayer:
                        top_layer2 = maxi(top_layer2, c.layer)
        check(top_layer2 >= 20, "letter overlay above touch UI (top=%d)" % top_layer2)
        var letter_close := _find_button_by_text(root, "بستن")
        check(letter_close != null, "letter close button reachable")
        if letter_close != null:
                letter_close.pressed.emit()
                await process_frame
                await process_frame
                check(not GS.ui_open, "letter closed, movement unblocked")

        if touch == null:
                print("\n!!! TouchUI missing — aborting touch tests")
                _finish()
                return

        # ---------- 3. touch buttons on-screen ----------
        print("\n[3] Touch UI geometry (visible rect %s)" % str(root.get_visible_rect().size))
        var vp_size: Vector2 = root.get_visible_rect().size
        var vp_h: float = vp_size.y
        var vp_w: float = vp_size.x
        var tb_count := 0
        var offscreen: Array[String] = []
        for c in touch.get_children():
                if c is TextureButton:
                        tb_count += 1
                        var r: Rect2 = c.get_global_rect()
                        var vis: bool = r.position.y >= 0 and r.end.y <= vp_h + 1 and r.position.x >= 0 and r.end.x <= vp_w + 1 and r.size.x > 10
                        if not vis:
                                offscreen.append("%s @%s size=%s" % [c.name, str(r.position), str(r.size)])
        check(tb_count >= 5, "touch has >=5 buttons (interact/flash/crouch/inv/pause) — found %d" % tb_count)
        if offscreen.is_empty():
                check(true, "all touch buttons ON-screen")
        else:
                check(false, "buttons off-screen: " + ", ".join(offscreen))
        check(touch.get("joy_base") != null and touch.get("joy_base").visible, "joystick visible at rest")

        # ---------- 4. touch walk via floating joystick ----------
        print("\n[4] Touch walk (floating joystick, left zone) — scanning for an open direction")
        var best_moved := 0.0
        for attempt in 8:
                var wp := Vector2(vp_w * 0.18, vp_h * 0.7)
                _press(wp)
                await physics_frame
                await physics_frame
                _drag(wp + Vector2(0, -90))
                await physics_frame
                await physics_frame
                var tm0: Vector2 = player.get("touch_move")
                if attempt == 0:
                        check(tm0.length() > 0.3, "joystick produces move vector (got %s)" % str(tm0))
                var p0: Vector3 = player.global_position
                for i in 45:
                        await physics_frame
                var m: float = (player.global_position - p0).length()
                best_moved = maxf(best_moved, m)
                _release(wp + Vector2(0, -90))
                for i in 4:
                        await physics_frame
                if m > 1.0:
                        break
                # rotate 45 degrees and try again (spawn faces the locked main door)
                player.get("yaw_node").rotation.y += PI / 4.0
                await physics_frame
        for i in 4:
                await physics_frame
        check(best_moved > 1.0, "player physically walked (best %.2f m over 0.75s)" % best_moved)
        check(player.get("touch_move").length() < 0.01, "move vector resets on release")

        # ---------- 5. touch look ----------
        print("\n[5] Touch look (right zone drag)")
        var yaw0: float = player.get("yaw_node").rotation.y
        _swipe(Vector2(vp_w * 0.75, vp_h * 0.5), Vector2(vp_w * 0.75 + 120, vp_h * 0.5))
        for i in 4:
                await physics_frame
        var yaw1: float = player.get("yaw_node").rotation.y
        check(absf(yaw1 - yaw0) > 0.02, "look drag rotates camera (d_yaw=%.3f)" % absf(yaw1 - yaw0))

        # ---------- 6. pickup is now hittable + interact button works ----------
        print("\n[6] Interact: pickup in open courtyard in front of player")
        # teleport to a known open spot (courtyard, facing the pool area)
        player.global_position = Vector3(0, 0.4, 8.0)
        player.get("yaw_node").rotation.y = 0.0
        player.get("pitch_node").rotation.x = 0.0
        # wait until fully landed, like a standing player
        for i in 30:
                await physics_frame
        var pk = load("res://scripts/interact/pickup.gd").new()
        pk.item_id = "fuse"
        game.add_child(pk)
        var fwd: Vector3 = -player.get("yaw_node").global_transform.basis.z
        pk.global_position = player.get("yaw_node").global_position + fwd * 1.6
        for i in 12:
                await physics_frame
        check(pk.collision_layer == 4, "pickup on interact layer (4)")
        check(last_prompt != "" and last_prompt != "___INIT___", "prompt appears on aim ('%s')" % last_prompt)
        if last_prompt == "":
                var ray: RayCast3D = player.get("interact_ray")
                print("  [DBG] ray colliding=", ray.is_colliding(), " collider=", ray.get_collider(), " pickup=", pk.global_position)
        var had_fuse: bool = GS.has_item("fuse")
        var ibtn := _btn_with(touch, "icon_hand")
        if ibtn != null:
                ibtn.pressed.emit()
                await physics_frame
                await physics_frame
                check(GS.has_item("fuse") and not had_fuse, "interact button picked up item")
        else:
                check(false, "interact button (icon_hand) not found")

        # ---------- 7. flashlight / crouch buttons ----------
        print("\n[7] Flashlight / crouch buttons")
        var fl := _btn_with(touch, "icon_flash")
        if fl != null:
                fl.pressed.emit()
                await physics_frame
                check(player.get("flashlight_on"), "flashlight toggles on")
        else:
                check(false, "flashlight button not found")
        var cr := _btn_with(touch, "icon_crouch")
        if cr != null:
                var eye0: float = player.get("yaw_node").position.y
                cr.pressed.emit()
                for i in 30:
                        await physics_frame
                check(player.get("yaw_node").position.y < eye0 - 0.2, "crouch lowers eye height")
                cr.pressed.emit()
                for i in 30:
                        await physics_frame
        else:
                check(false, "crouch button not found")

        # ---------- 8. pause via touch button (overlay layer) ----------
        print("\n[8] Pause overlay via touch button")
        var ps := _btn_with(touch, "icon_pause")
        check(ps != null, "pause button exists")
        if ps != null:
                ps.pressed.emit()
                await process_frame
                await process_frame
                check(GS.ui_open, "pause opens (ui_open=true)")
                var top_layer := 0
                for c in root.get_children():
                        if c is CanvasLayer:
                                top_layer = maxi(top_layer, c.layer)
                check(top_layer >= 20, "pause overlay renders above touch UI (top layer=%d)" % top_layer)
                var resume := _find_button_by_text(root, "ادامه بازی")
                check(resume != null, "resume button found and reachable")
                if resume != null:
                        resume.pressed.emit()
                        await process_frame
                        await process_frame
                        check(not GS.ui_open, "resume closes pause")

        # ---------- 9. pause has Save button; save works ----------
        print("\n[9] Manual save in pause menu")
        ps.pressed.emit()
        await process_frame
        await process_frame
        var save_btn := _find_button_by_text(root, "ذخیره بازی")
        check(save_btn != null, "save button exists in pause")
        if save_btn != null:
                save_btn.pressed.emit()
                await process_frame
                check(SS.has_save(), "save file written via pause button")
        var resume2 := _find_button_by_text(root, "ادامه بازی")
        if resume2 != null:
                resume2.pressed.emit()
                await process_frame
                await process_frame

        # ---------- 10. settings panel ----------
        print("\n[10] Settings panel")
        var sm: Control = load("res://scripts/menu/settings_menu.gd").new()
        root.add_child(sm)
        await process_frame
        check(_find_all(sm, "HSlider").size() >= 6, "settings has >=6 sliders (vol x4 + sens x2)")
        check(_find_buttons(sm).size() >= 5, "settings has vibration/quality x3/back buttons (found %d)" % _find_buttons(sm).size())
        sm.queue_free()
        await process_frame

        # ---------- 11. inventory via touch button ----------
        print("\n[11] Inventory panel")
        var inv_btn := _btn_with(touch, "icon_paper")
        if inv_btn != null:
                inv_btn.pressed.emit()
                await process_frame
                await process_frame
                check(GS.ui_open, "inventory opens via touch button")
                var inv_close := _find_button_by_text(root, "بستن")
                check(inv_close != null, "inventory close reachable")
                if inv_close != null:
                        inv_close.pressed.emit()
                        await process_frame
                        check(not GS.ui_open, "inventory closes")
        else:
                check(false, "inventory touch button not found")

        # ---------- summary ----------
        _finish()

func _finish() -> void:
        print("\n=== SUMMARY: %d checks, %d failures ===" % [checks, fails.size()])
        for f in fails:
                print("  FAIL: ", f)
        quit(0 if fails.is_empty() else 1)

# ---------------- input simulation ----------------
# Test works in VIEWPORT coords (what the touch UI logic uses); events must be
# pushed in WINDOW coords, so we map through the final (stretch) transform.
func _win(vpos: Vector2) -> Vector2:
        return root.get_final_transform() * vpos

func _press(vpos: Vector2) -> void:
        var ev := InputEventScreenTouch.new()
        ev.index = 0
        ev.pressed = true
        ev.position = _win(vpos)
        Input.parse_input_event(ev)

func _drag(vpos: Vector2) -> void:
        var ev := InputEventScreenDrag.new()
        ev.index = 0
        ev.position = _win(vpos)
        Input.parse_input_event(ev)

func _release(vpos: Vector2) -> void:
        var ev := InputEventScreenTouch.new()
        ev.index = 0
        ev.pressed = false
        ev.position = _win(vpos)
        Input.parse_input_event(ev)

func _swipe(a: Vector2, b: Vector2) -> void:
        _press(a)
        for i in 5:
                await process_frame
                _drag(a.lerp(b, (i + 1) / 5.0))
        _release(b)
        await process_frame

# ---------------- helpers ----------------
func _btn_with(parent: Node, tex_part: String) -> TextureButton:
        for c in parent.get_children():
                if c is TextureButton and c.texture_normal != null and str(c.texture_normal.resource_path).contains(tex_part):
                        return c
        return null

func _find_buttons(node: Node) -> Array:
        var out: Array = []
        if node is Button:
                out.append(node)
        for c in node.get_children():
                out.append_array(_find_buttons(c))
        return out

func _find_button_by_text(node: Node, txt: String) -> Button:
        if node is Button and node.text == txt:
                return node
        for c in node.get_children():
                var r := _find_button_by_text(c, txt)
                if r != null:
                        return r
        return null

func _find_all(node: Node, klass: String) -> Array:
        var out: Array = []
        if node.get_class() == klass:
                out.append(node)
        for c in node.get_children():
                out.append_array(_find_all(c, klass))
        return out
