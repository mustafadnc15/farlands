extends SceneTree
## Writes input actions, 3D physics layer names and the GUT plugin flag into project.godot.
## Idempotent. Run: "$GODOT" --headless --path . -s tools/setup_project.gd

const LAYERS: Array[String] = ["terrain", "player", "npc", "piece", "interact", "node", "drop", "ghost", "water"]

func _init() -> void:
	var keys: Dictionary[StringName, Array] = {
		&"move_forward": [KEY_W], &"move_back": [KEY_S], &"move_left": [KEY_A], &"move_right": [KEY_D],
		&"jump": [KEY_SPACE], &"sprint": [KEY_SHIFT], &"interact": [KEY_E],
		&"hotbar_1": [KEY_1], &"hotbar_2": [KEY_2], &"hotbar_3": [KEY_3],
		&"hotbar_4": [KEY_4], &"hotbar_5": [KEY_5], &"hotbar_6": [KEY_6],
		&"inventory": [KEY_TAB], &"build_menu": [KEY_B],
		&"rotate_piece_left": [KEY_Q], &"rotate_piece_right": [KEY_R], &"toggle_snap": [KEY_X],
		&"cancel": [KEY_ESCAPE], &"pause": [KEY_ESCAPE], &"drop_item": [KEY_G], &"chat": [KEY_ENTER],
	}
	for action: StringName in keys:
		var events: Array = []
		for code: int in keys[action]:
			events.append(_key(code))
		_set_action(action, events)
	_set_action(&"use_tool", [_mouse(MOUSE_BUTTON_LEFT)])
	_set_action(&"alt_use", [_mouse(MOUSE_BUTTON_RIGHT)])
	_set_action(&"hotbar_prev", [_mouse(MOUSE_BUTTON_WHEEL_UP)])
	_set_action(&"hotbar_next", [_mouse(MOUSE_BUTTON_WHEEL_DOWN)])
	for i in LAYERS.size():
		ProjectSettings.set_setting("layer_names/3d_physics/layer_%d" % (i + 1), LAYERS[i])
	ProjectSettings.set_setting("editor_plugins/enabled", PackedStringArray(["res://addons/gut/plugin.cfg"]))
	var err: int = ProjectSettings.save()
	if err != OK:
		push_error("setup_project: ProjectSettings.save failed (%d)" % err)
	quit(0 if err == OK else 1)

func _key(code: int) -> InputEventKey:
	var e := InputEventKey.new()
	e.physical_keycode = code as Key
	return e

func _mouse(button: int) -> InputEventMouseButton:
	var e := InputEventMouseButton.new()
	e.button_index = button as MouseButton
	return e

func _set_action(action: StringName, events: Array) -> void:
	ProjectSettings.set_setting("input/%s" % action, {"deadzone": 0.5, "events": events})
