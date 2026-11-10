extends GutTest

const SIGNALS: Array[StringName] = [
	&"item_picked_up", &"item_crafted", &"tool_used", &"node_hit", &"node_depleted",
	&"piece_placed", &"piece_completed", &"piece_removed", &"crop_planted", &"crop_harvested",
	&"player_damaged", &"player_died", &"player_respawned", &"player_ate", &"trade_done",
	&"coins_changed", &"worker_hired", &"worker_job_changed", &"ui_toast",
]


func test_all_contract_signals_exist() -> void:
	for s: StringName in SIGNALS:
		assert_true(Events.has_signal(s), "missing %s" % s)


func test_net_stub_is_host_offline() -> void:
	assert_true(Net.is_host())
	assert_eq(Net.sender_id(), 1)
