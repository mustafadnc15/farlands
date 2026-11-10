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

func test_main_start_and_end() -> void:
	var main: Node = load("res://main/main.tscn").instantiate()
	add_child_autofree(main)
	main.start_game()
	assert_not_null(main.get_node_or_null("Game"))
	main.end_game()
	await get_tree().process_frame
	assert_null(main.get_node_or_null("Game"))
