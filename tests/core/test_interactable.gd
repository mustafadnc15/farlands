extends GutTest

class Blocked extends Interactable:
	func can_interact(_peer_id: int) -> bool:
		return false

func test_layer_is_interact_only() -> void:
	var i := Interactable.new()
	add_child_autofree(i)
	assert_eq(i.collision_layer, 1 << 4)
	assert_eq(i.collision_mask, 0)
	assert_false(i.monitoring)

func test_in_group_after_ready() -> void:
	var i := Interactable.new()
	assert_false(i.is_in_group(&"interactable"))
	add_child_autofree(i)
	assert_true(i.is_in_group(&"interactable"))

func test_try_interact_emits() -> void:
	var i := Interactable.new()
	add_child_autofree(i)
	watch_signals(i)
	assert_true(i.try_interact(1))
	assert_signal_emitted_with_parameters(i, "interacted", [1])

func test_can_interact_false_blocks() -> void:
	var i := Blocked.new()
	add_child_autofree(i)
	watch_signals(i)
	assert_false(i.try_interact(1))
	assert_signal_not_emitted(i, "interacted")
