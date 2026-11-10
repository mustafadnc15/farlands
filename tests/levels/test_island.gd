extends GutTest

var level: Node3D

func before_all() -> void:
	level = load("res://levels/island.tscn").instantiate()
	add_child(level)
	await wait_physics_frames(2)

func after_all() -> void:
	level.free()

func _ground_y(x: float, z: float) -> float:
	var q := PhysicsRayQueryParameters3D.create(Vector3(x, 50, z), Vector3(x, -50, z), 1)
	var hit: Dictionary = level.get_world_3d().direct_space_state.intersect_ray(q)
	return -INF if hit.is_empty() else (hit.position as Vector3).y

func test_required_nodes() -> void:
	for p: String in ["Terrain", "Water", "Road", "MerchantStall/MerchantSpawn", "Piers", "NodeMarkers", "FishingSpots", "WildlifeZones", "NavRegions", "SpawnPoint", "Environment/Sun"]:
		assert_not_null(level.get_node_or_null(p), p)

func test_marker_counts() -> void:
	var counts: Dictionary = {}
	for m: NodeMarker in level.get_node("NodeMarkers").get_children():
		counts[m.def_id] = counts.get(m.def_id, 0) + 1
	assert_eq(counts[&"tree_small"] + counts[&"tree_large"], 500)
	assert_eq(counts[&"rock"], 125)
	assert_eq(counts[&"ore_rock"], 25)
	assert_eq(counts[&"berry_bush"], 120)
	assert_eq(level.get_node("FishingSpots").get_child_count(), 5)
	assert_eq(level.get_node("WildlifeZones").get_child_count(), 3)

func test_island_is_mostly_flat() -> void:      # spec: 85 % of land within ±1 m of base level (Y = 1)
	var land: int = 0
	var flat: int = 0
	for x: int in range(-200, 201, 10):
		for z: int in range(-200, 201, 10):
			var y: float = _ground_y(x, z)
			if y > 0.0:
				land += 1
				flat += int(absf(y - 1.0) <= 1.0)
	assert_gt(land, 800)
	assert_gt(float(flat) / land, 0.85)

func test_no_holes_inside_coast() -> void:
	for x: int in range(-150, 151, 10):
		for z: int in range(-150, 151, 10):
			assert_gt(_ground_y(x, z), -3.0, "hole at %d,%d" % [x, z])

func test_markers_respect_exclusions() -> void:
	var spawn: Vector3 = level.get_node("SpawnPoint").global_position
	for m: Node3D in level.get_node("NodeMarkers").get_children():
		assert_gt(m.global_position.distance_to(spawn), 15.0)
		assert_gt(m.global_position.y, 0.8)

func test_capsule_stands_at_spawn() -> void:     # M0 gate: "a capsule can stand on the island"
	var body := CharacterBody3D.new()
	body.collision_mask = 1
	var cs := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.height = 1.7
	cap.radius = 0.35
	cs.shape = cap
	cs.position.y = 0.85
	body.add_child(cs)
	level.add_child(body)
	body.global_position = level.get_node("SpawnPoint").global_position + Vector3.UP
	for i: int in 120:
		body.velocity.y -= 20.0 / 60.0
		body.move_and_slide()
		await wait_physics_frames(1)
	assert_true(body.is_on_floor())
	assert_between(body.global_position.y, 0.5, 2.5)
	body.free()

func test_no_build_volumes_exist() -> void:
	assert_gte(get_tree().get_nodes_in_group("no_build").size(), 4)   # road, stall, 2 piers
