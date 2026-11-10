extends GutTest

func test_item_def_defaults() -> void:
	var d := ItemDef.new()
	assert_eq(d.id, &"")
	assert_eq(d.max_stack, 1)
	assert_false(d.bulky)
	assert_null(d.tool)

func test_tool_stats_fields() -> void:
	var t := ToolStats.new()
	t.tool_type = &"axe"
	t.power = 10.0
	t.max_durability = 60
	t.swing_time = 0.5
	t.reach = 2.5
	assert_eq(t.tool_type, &"axe")

func test_recipe_inputs_typed() -> void:
	var r := RecipeDef.new()
	r.inputs[&"stick"] = 2
	assert_eq(r.inputs[&"stick"], 2)
	assert_eq(r.output_count, 1)
	assert_eq(r.station, &"")

func test_trade_default_stock_unlimited() -> void:
	assert_eq(TradeDef.new().daily_stock, -1)

func test_all_defs_have_id_and_name() -> void:
	for d: Resource in [ItemDef.new(), RecipeDef.new(), PieceDef.new(), CropDef.new(), NodeDef.new(), AnimalDef.new(), JobDef.new(), TradeDef.new()]:
		assert_true("id" in d and "display_name" in d, d.get_script().resource_path)

func test_sample_log_loads() -> void:
	var log_def := load("res://content/items/log.tres") as ItemDef
	assert_not_null(log_def)
	assert_eq(log_def.id, &"log")
	assert_true(log_def.bulky)
	assert_eq(log_def.max_stack, 3)
