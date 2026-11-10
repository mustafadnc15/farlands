extends GutTest
const FIX := "res://tests/core/fixtures/registry"

func before_each() -> void:
	Registry.load_from(FIX)

func after_each() -> void:
	# The fixtures deliberately raise exactly these three load errors on every load.
	assert_push_error("duplicate id")
	assert_push_error("empty id")
	assert_push_error("wrong type")

func after_all() -> void:
	Registry.load_from("res://content")

func test_lookup_by_id() -> void:
	assert_eq(Registry.item(&"log").id, &"log")
	assert_eq(Registry.recipe(&"plank").id, &"plank")

func test_unknown_id_returns_null() -> void:
	assert_null(Registry.item(&"nope"))
	assert_push_error("unknown item")

func test_duplicate_keeps_first_and_reports() -> void:
	assert_eq(Registry.all_items().size(), 1)
	assert_ne(Registry.item(&"log").display_name, "Dup")

func test_wrong_type_and_empty_id_skipped() -> void:
	for d: ItemDef in Registry.all_items():
		assert_true(d is ItemDef)
		assert_ne(d.id, &"")

func test_real_content_loads() -> void:
	Registry.load_from("res://content")
	assert_not_null(Registry.item(&"log"))
	assert_eq(Registry.all_pieces().size(), 0)
