extends GutTest

const ACTIONS: Array[StringName] = [&"move_forward", &"move_back", &"move_left", &"move_right", &"jump", &"sprint",
	&"interact", &"use_tool", &"alt_use", &"hotbar_1", &"hotbar_2", &"hotbar_3", &"hotbar_4", &"hotbar_5", &"hotbar_6",
	&"hotbar_next", &"hotbar_prev", &"inventory", &"build_menu", &"rotate_piece_left", &"rotate_piece_right",
	&"toggle_snap", &"cancel", &"drop_item", &"chat", &"pause"]
const LAYERS: Array[String] = ["terrain", "player", "npc", "piece", "interact", "node", "drop", "ghost", "water"]

func test_all_input_actions_exist() -> void:
	for a in ACTIONS:
		assert_true(InputMap.has_action(a), "missing action %s" % a)
		assert_gt(InputMap.action_get_events(a).size(), 0, "no binding for %s" % a)

func test_physics_layer_names() -> void:
	for i in LAYERS.size():
		assert_eq(ProjectSettings.get_setting("layer_names/3d_physics/layer_%d" % (i + 1)), LAYERS[i])
