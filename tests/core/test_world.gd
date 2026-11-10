extends GutTest

var game: Node

func before_each() -> void:
	game = load("res://main/game.tscn").instantiate()
	add_child_autofree(game)

func test_tree_shape() -> void:
	for p: String in ["World/Level", "World/Managers", "World/Players", "World/Npcs", "World/Dynamic", "UI"]:
		assert_not_null(game.get_node_or_null(p), p)

func test_world_in_group_and_typed() -> void:
	assert_true(get_tree().get_first_node_in_group("world") is World)

func test_manager_registration() -> void:
	var w := game.get_node("World") as World
	var m := Node.new()
	w.get_node("Managers").add_child(m)
	w.register_manager(&"build", m)
	assert_eq(w.get_manager(&"build"), m)
	assert_null(w.get_manager(&"farm"))
	assert_push_error("no manager registered")

func test_register_invalid_key_rejected() -> void:
	var w := game.get_node("World") as World
	var m := Node.new()
	w.get_node("Managers").add_child(m)
	w.register_manager(&"bogus", m)
	assert_push_error("invalid manager key")
	assert_null(w.get_manager(&"bogus"))
	assert_push_error("no manager registered")

func test_manager_can_find_world_in_its_ready() -> void:
	var probe_script := GDScript.new()
	probe_script.source_code = "extends Node\nvar found: Object = null\nfunc _ready() -> void:\n\tfound = get_tree().get_first_node_in_group(&\"world\")\n"
	assert_eq(probe_script.reload(), OK)
	var fresh: Node = load("res://main/game.tscn").instantiate()
	var probe := Node.new()
	probe.set_script(probe_script)
	fresh.get_node("World/Managers").add_child(probe)
	# before_each's game is already in the tree, so remove it to make the group lookup unambiguous.
	remove_child(game)
	add_child_autofree(fresh)
	add_child(game)
	assert_true(probe.get("found") is World, "manager sees World in its _ready")
	assert_eq(probe.get("found"), fresh.get_node("World"))

func test_main_start_and_end() -> void:
	var main: Node = load("res://main/main.tscn").instantiate()
	add_child_autofree(main)
	main.start_game()
	assert_not_null(main.get_node_or_null("Game"))
	var entity := Node3D.new()
	main.get_node("Game/World/Dynamic").add_child(entity)
	Entities.register(Entities.next_id(), entity)
	main.end_game()
	await get_tree().process_frame
	assert_null(main.get_node_or_null("Game"))
	assert_eq(Entities.get_next_id(), 1, "end_game clears Entities")

func test_end_game_from_ui_button() -> void:
	var main: Node = load("res://main/main.tscn").instantiate()
	add_child_autofree(main)
	main.start_game()
	var button := Button.new()
	main.get_node("Game/UI").add_child(button)
	button.pressed.connect(main.end_game)
	button.pressed.emit()
	await get_tree().process_frame
	assert_null(main.get_node_or_null("Game"))
	main.start_game()
	assert_not_null(main.get_node_or_null("Game"), "restarts after end_game")
