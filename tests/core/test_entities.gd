extends GutTest


func before_each() -> void:
	Entities.clear()


func after_all() -> void:
	Entities.clear()


func test_ids_start_at_one_and_increase() -> void:
	assert_eq(Entities.next_id(), 1)
	assert_eq(Entities.next_id(), 2)


func test_register_find_unregister() -> void:
	var n := Node.new()
	add_child_autofree(n)
	Entities.register(7, n)
	assert_eq(Entities.find(7), n)
	Entities.unregister(7)
	assert_null(Entities.find(7))


func test_find_unknown_is_null() -> void:
	assert_null(Entities.find(999))


func test_find_freed_node_is_null() -> void:
	var n := Node.new()
	add_child(n)
	Entities.register(3, n)
	n.free()
	assert_null(Entities.find(3))


func test_register_duplicate_id_keeps_first() -> void:
	var a := Node.new()
	var b := Node.new()
	add_child_autofree(a)
	add_child_autofree(b)
	Entities.register(5, a)
	Entities.register(5, b)
	assert_push_error("[entities]")
	assert_eq(Entities.find(5), a)


func test_counter_restore() -> void:
	Entities.set_next_id(4567)
	assert_eq(Entities.next_id(), 4567)
	assert_eq(Entities.get_next_id(), 4568)


func test_clear_resets() -> void:
	Entities.next_id()
	Entities.clear()
	assert_eq(Entities.next_id(), 1)
