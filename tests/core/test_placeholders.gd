extends GutTest

const ANIMS: Array[String] = ["idle", "walk", "run", "jump", "fall", "land", "swing_axe", "swing_pick", "swing_hammer", "swing_hoe", "spear_thrust",
	"spear_aim", "spear_throw", "rod_cast", "rod_idle", "rod_reel", "water", "carry_idle", "carry_walk", "pickup", "eat", "sit", "sleep",
	"hurt", "die", "wave", "talk"]

func test_capsule_character_contract() -> void:
	var m := load("res://core/placeholders/capsule_character.tscn").instantiate() as Node3D
	add_child_autofree(m)
	assert_eq(m.name, &"Model")
	var ap := m.find_child("AnimationPlayer") as AnimationPlayer
	for a: String in ANIMS:
		assert_true(ap.has_animation(a), a)
	for n: String in ["hand_r", "hand_l", "shoulder_r", "back", "head_top"]:
		assert_not_null(m.find_child(n), n)

func test_item_and_piece_roots_named_model() -> void:
	for p: String in ["box_item", "box_piece"]:
		var n := load("res://core/placeholders/%s.tscn" % p).instantiate() as Node
		assert_eq(n.name, &"Model")
		n.free()

func test_attachment_sides() -> void:
	# Characters face -Z, so the character's right is +X.
	var m := load("res://core/placeholders/capsule_character.tscn").instantiate() as Node3D
	add_child_autofree(m)
	assert_gt((m.find_child("hand_r") as Node3D).position.x, 0.0, "hand_r on +X")
	assert_gt((m.find_child("shoulder_r") as Node3D).position.x, 0.0, "shoulder_r on +X")
	assert_lt((m.find_child("hand_l") as Node3D).position.x, 0.0, "hand_l on -X")
