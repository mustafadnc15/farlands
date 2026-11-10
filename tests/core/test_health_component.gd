extends GutTest

var hp: HealthComponent

func before_each() -> void:
	hp = HealthComponent.new()
	add_child_autofree(hp)
	watch_signals(hp)

func test_starts_full() -> void:
	assert_eq(hp.health, 100.0)
	assert_false(hp.is_dead())

func test_damage_reduces_and_emits_changed() -> void:
	hp.damage(30.0, &"fall")
	assert_eq(hp.health, 70.0)
	assert_signal_emitted_with_parameters(hp, "changed", [70.0, 100.0])

func test_damage_clamps_at_zero() -> void:
	hp.damage(150.0, &"fall")
	assert_eq(hp.health, 0.0)
	assert_true(hp.is_dead())

func test_died_emits_once() -> void:
	hp.damage(150.0, &"fall")
	hp.damage(10.0, &"fall")
	assert_signal_emit_count(hp, "died", 1)
	assert_signal_emitted_with_parameters(hp, "died", [&"fall"])

func test_negative_or_zero_damage_ignored() -> void:
	hp.damage(0.0, &"x")
	hp.damage(-5.0, &"x")
	assert_eq(hp.health, 100.0)
	assert_signal_not_emitted(hp, "changed")

func test_heal_clamps_to_max() -> void:
	hp.damage(10.0, &"x")
	hp.heal(50.0)
	assert_eq(hp.health, 100.0)

func test_heal_ignored_when_dead() -> void:
	hp.damage(200.0, &"x")
	hp.heal(20.0)
	assert_eq(hp.health, 0.0)
	assert_true(hp.is_dead())

func test_revive_restores() -> void:
	hp.damage(200.0, &"x")
	hp.revive(50.0)
	assert_eq(hp.health, 50.0)
	assert_false(hp.is_dead())
	hp.damage(100.0, &"y")
	assert_signal_emit_count(hp, "died", 2)
