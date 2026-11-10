extends SceneTree
## Builds the grey-box island deterministically: levels/island.tscn plus the terrain mesh and its
## trimesh collision shape in levels/generated/. Layout: docs/content/level-island.md.
## Run: "$GODOT" --headless --path . -s tools/build_greybox_island.gd

const SEED: int = 20261110
const SCENE_PATH: String = "res://levels/island.tscn"
const GENERATED_DIR: String = "res://levels/generated"
const MESH_PATH: String = "res://levels/generated/island_terrain.res"
const SHAPE_PATH: String = "res://levels/generated/island_terrain_shape.res"
const NODE_MARKER_SCRIPT: String = "res://levels/node_marker.gd"
const FISHING_SPOT_SCRIPT: String = "res://levels/fishing_spot.gd"
const WILDLIFE_ZONE_SCRIPT: String = "res://levels/wildlife_zone.gd"

# Physics layers (docs/03-contracts.md section 3), as bit values.
const LAYER_TERRAIN: int = 1
const LAYER_NPC: int = 1 << 2
const LAYER_GHOST: int = 1 << 7
const LAYER_WATER: int = 1 << 8

# Terrain grid: 480 x 480 m, 2 m cells, centred on the origin.
const HALF_SIZE: float = 240.0
const CELL: float = 2.0
const CELLS: int = 240

# Height field.
const BASE_Y: float = 1.0
const ISLAND_RADIUS: float = 200.0
const WOBBLE: float = 20.0
const LAND_NOISE: float = 0.4
const COAST_FALL: float = 25.0
const SEA_FLOOR: float = -2.0
const RISE_CENTRE: Vector2 = Vector2(60.0, -130.0)
const RISE_RADIUS: float = 55.0
const RISE_TOP: float = 8.0
const POND_CENTRE: Vector2 = Vector2(90.0, 40.0)
const POND_WIDTH: float = 25.0
const POND_FLOOR: float = -0.5
# Free shape parameters (not fixed by the level doc).
const OUTLINE_SAMPLES: int = 720
const OUTLINE_NOISE_RADIUS: float = 2.2   # noise sampled on a circle of this radius -> a few lobes
const OUTLINE_NOISE_OFFSET: Vector2 = Vector2(2800.0, 2800.0)   # chosen so the coast stays within 200 m of the axes (walls fit the 480 m grid)
const OUTLINE_PIN_WIDTH: float = 0.5      # |sin| below this pins the radius to 200 m at the road ends
const LAND_NOISE_FREQ: float = 0.015
const SHELF_WIDTH: float = 20.0           # seabed ramps from Y 0 at the coast to SEA_FLOOR over this
const POND_FLAT_FRACTION: float = 0.6     # inner part of the pond radius that is at full depth

# Vertex colours.
const COLOR_GRASS: Color = Color(0.36, 0.55, 0.25)
const COLOR_SAND: Color = Color(0.82, 0.75, 0.52)
const COLOR_ROCK: Color = Color(0.5, 0.5, 0.48)
const COLOR_DIRT: Color = Color(0.45, 0.33, 0.2)
const SAND_BELOW: float = 0.6
const ROCK_ABOVE: float = 3.0

# Road, stall, piers, spawn.
const ROAD_X: float = 200.0
const ROAD_AMPLITUDE: float = 8.0
const ROAD_HALF_WIDTH: float = 2.0
const ROAD_MARGIN: float = 1.0
const ROAD_LIFT: float = 0.02
const ROAD_STEP: float = 2.0
const ROAD_VOLUME_STEP: float = 10.0
const STALL_CENTRE: Vector2 = Vector2(10.0, -10.0)
const STALL_SIZE: float = 8.0
const PIER_LENGTH: float = 24.0
const PIER_START: float = 196.0
const PIER_TOP: float = 0.35
const SPAWN_XZ: Vector2 = Vector2(-40.0, 30.0)
const SPAWN_LIFT: float = 0.1
const WALL_OFFSET: float = 40.0

# Markers.
const SPAWN_CLEAR: float = 15.0
const MIN_MARKER_Y: float = 0.8
const MARKER_SPACING: float = 2.0
const SPAWN_MEADOW: Rect2 = Rect2(-80.0, 5.0, 80.0, 60.0)

var _noise: FastNoiseLite
var _rng: RandomNumberGenerator
var _coast: PackedFloat32Array
var _land_noise_scale: float = 1.0
var _heights: PackedFloat32Array
var _placed: Dictionary = {}   # Vector2i cell -> Array of Vector2


func _init() -> void:
	_noise = FastNoiseLite.new()
	_noise.seed = SEED
	_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_noise.frequency = 1.0
	_noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	_noise.fractal_octaves = 3
	_rng = RandomNumberGenerator.new()
	_rng.seed = SEED
	_build_outline()
	_build_heights()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(GENERATED_DIR))
	var root: Node3D = _build_scene()
	_save_scene(root)
	root.free()
	quit()


# --- height field ------------------------------------------------------------------------------

func _build_outline() -> void:
	var raw: PackedFloat32Array = PackedFloat32Array()
	raw.resize(OUTLINE_SAMPLES)
	var max_abs: float = 0.0
	for k: int in OUTLINE_SAMPLES:
		var theta: float = TAU * k / OUTLINE_SAMPLES
		var p: Vector2 = Vector2(cos(theta), sin(theta)) * OUTLINE_NOISE_RADIUS + OUTLINE_NOISE_OFFSET
		var pin: float = smoothstep(0.0, OUTLINE_PIN_WIDTH, absf(sin(theta)))
		raw[k] = _noise.get_noise_2d(p.x, p.y) * pin
		max_abs = maxf(max_abs, absf(raw[k]))
	_coast = PackedFloat32Array()
	_coast.resize(OUTLINE_SAMPLES)
	for k: int in OUTLINE_SAMPLES:
		_coast[k] = ISLAND_RADIUS + WOBBLE * raw[k] / max_abs


func _coast_radius(theta: float) -> float:
	var f: float = fposmod(theta, TAU) / TAU * OUTLINE_SAMPLES
	var k: int = int(floor(f)) % OUTLINE_SAMPLES
	return lerpf(_coast[k], _coast[(k + 1) % OUTLINE_SAMPLES], f - floor(f))


func _raw_land_noise(x: float, z: float) -> float:
	return _noise.get_noise_2d(x * LAND_NOISE_FREQ, z * LAND_NOISE_FREQ)


## The single height function: every mesh vertex, and through _surface_y every marker, is built from it.
func _height(x: float, z: float) -> float:
	var p: Vector2 = Vector2(x, z)
	var r: float = p.length()
	var coast: float = _coast_radius(atan2(z, x))
	var profile: float
	if r <= coast - COAST_FALL:
		profile = BASE_Y
	elif r <= coast:
		profile = BASE_Y * (1.0 - smoothstep(coast - COAST_FALL, coast, r))
	else:
		profile = SEA_FLOOR * smoothstep(coast, coast + SHELF_WIDTH, r)
	var land: float = clampf(profile / BASE_Y, 0.0, 1.0)
	var rise: float = (RISE_TOP - BASE_Y) * (1.0 - smoothstep(0.0, RISE_RADIUS, p.distance_to(RISE_CENTRE)))
	var bumps: float = LAND_NOISE * _raw_land_noise(x, z) * _land_noise_scale
	var h: float = profile + land * (bumps + rise)
	var pond_r: float = POND_WIDTH * 0.5
	var pond: float = 1.0 - smoothstep(pond_r * POND_FLAT_FRACTION, pond_r, p.distance_to(POND_CENTRE))
	return lerpf(h, POND_FLOOR, pond)


func _grid_xz(i: int) -> float:
	return -HALF_SIZE + i * CELL


func _build_heights() -> void:
	var max_abs: float = 0.0
	for j: int in CELLS + 1:
		for i: int in CELLS + 1:
			max_abs = maxf(max_abs, absf(_raw_land_noise(_grid_xz(i), _grid_xz(j))))
	_land_noise_scale = 1.0 / max_abs
	_heights = PackedFloat32Array()
	_heights.resize((CELLS + 1) * (CELLS + 1))
	for j: int in CELLS + 1:
		for i: int in CELLS + 1:
			_heights[j * (CELLS + 1) + i] = _height(_grid_xz(i), _grid_xz(j))


func _h(i: int, j: int) -> float:
	return _heights[clampi(j, 0, CELLS) * (CELLS + 1) + clampi(i, 0, CELLS)]


## Height of the terrain mesh surface (same triangles as the mesh and its collision).
func _surface_y(x: float, z: float) -> float:
	var fx: float = (x + HALF_SIZE) / CELL
	var fz: float = (z + HALF_SIZE) / CELL
	var i: int = clampi(int(floor(fx)), 0, CELLS - 1)
	var j: int = clampi(int(floor(fz)), 0, CELLS - 1)
	var u: float = fx - i
	var v: float = fz - j
	var h00: float = _h(i, j)
	var h10: float = _h(i + 1, j)
	var h01: float = _h(i, j + 1)
	var h11: float = _h(i + 1, j + 1)
	if u + v <= 1.0:
		return h00 + (h10 - h00) * u + (h01 - h00) * v
	return h11 + (h01 - h11) * (1.0 - u) + (h10 - h11) * (1.0 - v)


func _road_z(x: float) -> float:
	return ROAD_AMPLITUDE * sin(PI * x / ROAD_X)


func _road_slope(x: float) -> float:
	return ROAD_AMPLITUDE * PI / ROAD_X * cos(PI * x / ROAD_X)


## Horizontal distance from (x, z) to the road centre line.
func _road_distance(x: float, z: float) -> float:
	var cx: float = clampf(x, -ROAD_X, ROAD_X)
	if absf(x) > ROAD_X:
		return Vector2(x - cx, z - _road_z(cx)).length()
	var s: float = _road_slope(x)
	return absf(z - _road_z(x)) / sqrt(1.0 + s * s)


# --- scene -------------------------------------------------------------------------------------

func _build_scene() -> Node3D:
	var root: Node3D = Node3D.new()
	root.name = &"Island"
	_add_terrain(root)
	_add_water(root)
	_add_road(root)
	_add_stall(root)
	_add_piers(root)
	var spawn: Marker3D = Marker3D.new()
	spawn.name = &"SpawnPoint"
	spawn.position = Vector3(SPAWN_XZ.x, _surface_y(SPAWN_XZ.x, SPAWN_XZ.y) + SPAWN_LIFT, SPAWN_XZ.y)
	_add_markers(root)
	_add_fishing_spots(root)
	_add_wildlife_zones(root)
	var nav: Node3D = Node3D.new()
	nav.name = &"NavRegions"
	root.add_child(nav)
	root.add_child(spawn)
	_add_environment(root)
	_add_boundary(root)
	return root


func _sub(res: Resource, id: String) -> Resource:
	res.resource_scene_unique_id = id
	return res


func _color_material(id: String, color: Color) -> StandardMaterial3D:
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 1.0
	return _sub(mat, id) as StandardMaterial3D


func _box_shape(id: String, size: Vector3) -> BoxShape3D:
	var shape: BoxShape3D = BoxShape3D.new()
	shape.size = size
	return _sub(shape, id) as BoxShape3D


func _collision(node_name: StringName, shape: Shape3D, pos: Vector3 = Vector3.ZERO) -> CollisionShape3D:
	var cs: CollisionShape3D = CollisionShape3D.new()
	cs.name = node_name
	cs.shape = shape
	cs.position = pos
	return cs


func _no_build_area(id: String, size: Vector3, pos: Vector3) -> Area3D:
	var area: Area3D = Area3D.new()
	area.name = &"NoBuild"
	area.collision_layer = LAYER_GHOST
	area.collision_mask = 0
	area.monitoring = false
	area.position = pos
	area.add_to_group(&"no_build", true)
	area.add_child(_collision(&"Shape", _box_shape(id, size)))
	return area


func _add_terrain(root: Node3D) -> void:
	var verts: PackedVector3Array = PackedVector3Array()
	var normals: PackedVector3Array = PackedVector3Array()
	var colors: PackedColorArray = PackedColorArray()
	var indices: PackedInt32Array = PackedInt32Array()
	for j: int in CELLS + 1:
		for i: int in CELLS + 1:
			var x: float = _grid_xz(i)
			var z: float = _grid_xz(j)
			var y: float = _h(i, j)
			verts.append(Vector3(x, y, z))
			normals.append(Vector3(_h(i - 1, j) - _h(i + 1, j), 2.0 * CELL, _h(i, j - 1) - _h(i, j + 1)).normalized())
			var c: Color = COLOR_GRASS
			if absf(x) <= ROAD_X and _road_distance(x, z) <= ROAD_HALF_WIDTH + 0.5:
				c = COLOR_DIRT
			elif y < SAND_BELOW:
				c = COLOR_SAND
			elif y > ROCK_ABOVE:
				c = COLOR_ROCK
			colors.append(c)
	var row: int = CELLS + 1
	for j: int in CELLS:
		for i: int in CELLS:
			var v00: int = j * row + i
			# Clockwise seen from above (Godot front faces); diagonal v10-v01 matches _surface_y.
			indices.append_array(PackedInt32Array([v00, v00 + 1, v00 + row, v00 + 1, v00 + row + 1, v00 + row]))
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh: ArrayMesh = ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var mat: StandardMaterial3D = _color_material("terrain_material", Color.WHITE)
	mat.vertex_color_use_as_albedo = true
	mesh.surface_set_material(0, mat)
	var shape: ConcavePolygonShape3D = mesh.create_trimesh_shape()
	ResourceSaver.save(mesh, MESH_PATH, ResourceSaver.FLAG_COMPRESS)
	ResourceSaver.save(shape, SHAPE_PATH, ResourceSaver.FLAG_COMPRESS)
	# Reload so the scene references the saved files instead of embedding them.
	mesh = ResourceLoader.load(MESH_PATH, "", ResourceLoader.CACHE_MODE_REPLACE) as ArrayMesh
	shape = ResourceLoader.load(SHAPE_PATH, "", ResourceLoader.CACHE_MODE_REPLACE) as ConcavePolygonShape3D

	var body: StaticBody3D = StaticBody3D.new()
	body.name = &"Terrain"
	body.collision_layer = LAYER_TERRAIN
	body.collision_mask = 0
	var mi: MeshInstance3D = MeshInstance3D.new()
	mi.name = &"Mesh"
	mi.mesh = mesh
	body.add_child(mi)
	body.add_child(_collision(&"Collision", shape))
	root.add_child(body)


func _add_water(root: Node3D) -> void:
	var water: Node3D = Node3D.new()
	water.name = &"Water"
	var plane: PlaneMesh = _sub(PlaneMesh.new(), "water_plane") as PlaneMesh
	plane.size = Vector2(2000.0, 2000.0)
	var mat: StandardMaterial3D = _color_material("water_material", Color(0.15, 0.4, 0.6, 0.85))
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.roughness = 0.2
	plane.material = mat
	var surface: MeshInstance3D = MeshInstance3D.new()
	surface.name = &"Surface"
	surface.mesh = plane
	surface.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	water.add_child(surface)
	var volume: Area3D = Area3D.new()
	volume.name = &"Volume"
	volume.collision_layer = LAYER_WATER
	volume.collision_mask = 0
	volume.add_child(_collision(&"Shape", _box_shape("water_volume", Vector3(2000.0, 4.0, 2000.0)), Vector3(0.0, -2.0, 0.0)))
	water.add_child(volume)
	root.add_child(water)


func _add_road(root: Node3D) -> void:
	var road: Node3D = Node3D.new()
	road.name = &"Road"
	var verts: PackedVector3Array = PackedVector3Array()
	var normals: PackedVector3Array = PackedVector3Array()
	var indices: PackedInt32Array = PackedInt32Array()
	var steps: int = int(2.0 * ROAD_X / ROAD_STEP)
	for k: int in steps + 1:
		var x: float = -ROAD_X + k * ROAD_STEP
		var t: Vector2 = Vector2(1.0, _road_slope(x)).normalized()
		var side: Vector2 = Vector2(-t.y, t.x) * ROAD_HALF_WIDTH   # points south (+Z)
		for s: float in [-1.0, 1.0]:
			var p: Vector2 = Vector2(x, _road_z(x)) + side * s
			verts.append(Vector3(p.x, _surface_y(p.x, p.y) + ROAD_LIFT, p.y))
			normals.append(Vector3.UP)
		if k < steps:
			var a: int = 2 * k   # north edge; a + 1 south edge
			indices.append_array(PackedInt32Array([a, a + 2, a + 1, a + 2, a + 3, a + 1]))
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh: ArrayMesh = _sub(ArrayMesh.new(), "road_mesh") as ArrayMesh
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	mesh.surface_set_material(0, _color_material("road_material", COLOR_DIRT))
	var mi: MeshInstance3D = MeshInstance3D.new()
	mi.name = &"Mesh"
	mi.mesh = mesh
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	road.add_child(mi)

	var area: Area3D = Area3D.new()
	area.name = &"NoBuild"
	area.collision_layer = LAYER_GHOST
	area.collision_mask = 0
	area.monitoring = false
	area.add_to_group(&"no_build", true)
	var width: float = 2.0 * (ROAD_HALF_WIDTH + ROAD_MARGIN)
	var segments: int = int(2.0 * ROAD_X / ROAD_VOLUME_STEP)
	for k: int in segments:
		var x0: float = -ROAD_X + k * ROAD_VOLUME_STEP
		var a: Vector2 = Vector2(x0, _road_z(x0))
		var b: Vector2 = Vector2(x0 + ROAD_VOLUME_STEP, _road_z(x0 + ROAD_VOLUME_STEP))
		var mid: Vector2 = (a + b) * 0.5
		var d: Vector2 = b - a
		var cs: CollisionShape3D = _collision(StringName("Segment%02d" % k),
				_box_shape("road_volume_%02d" % k, Vector3(d.length() + 1.0, 6.0, width)),
				Vector3(mid.x, _surface_y(mid.x, mid.y), mid.y))
		cs.rotation.y = atan2(-d.y, d.x)
		area.add_child(cs)
	road.add_child(area)
	root.add_child(road)


func _add_stall(root: Node3D) -> void:
	var top: float = -INF
	for a: int in 9:
		for b: int in 9:
			var x: float = STALL_CENTRE.x - STALL_SIZE * 0.5 + a * STALL_SIZE / 8.0
			var z: float = STALL_CENTRE.y - STALL_SIZE * 0.5 + b * STALL_SIZE / 8.0
			top = maxf(top, _surface_y(x, z))
	top += 0.1
	var stall: Node3D = Node3D.new()
	stall.name = &"MerchantStall"
	stall.position = Vector3(STALL_CENTRE.x, top, STALL_CENTRE.y)
	var pad: StaticBody3D = StaticBody3D.new()
	pad.name = &"Pad"
	pad.collision_layer = LAYER_TERRAIN
	pad.collision_mask = 0
	pad.position = Vector3(0.0, -0.5, 0.0)
	var size: Vector3 = Vector3(STALL_SIZE, 1.0, STALL_SIZE)
	var box: BoxMesh = _sub(BoxMesh.new(), "stall_pad_mesh") as BoxMesh
	box.size = size
	box.material = _color_material("stall_material", Color(0.6, 0.45, 0.3))
	var mi: MeshInstance3D = MeshInstance3D.new()
	mi.name = &"Mesh"
	mi.mesh = box
	pad.add_child(mi)
	pad.add_child(_collision(&"Collision", _box_shape("stall_pad_shape", size)))
	stall.add_child(pad)
	var merchant: Marker3D = Marker3D.new()
	merchant.name = &"MerchantSpawn"
	stall.add_child(merchant)
	stall.add_child(_no_build_area("stall_no_build", Vector3(STALL_SIZE, 6.0, STALL_SIZE), Vector3(0.0, 1.0, 0.0)))
	root.add_child(stall)


func _add_piers(root: Node3D) -> void:
	var piers: Node3D = Node3D.new()
	piers.name = &"Piers"
	var size: Vector3 = Vector3(PIER_LENGTH, 0.4, 2.0 * ROAD_HALF_WIDTH)
	var mesh: BoxMesh = _sub(BoxMesh.new(), "pier_mesh") as BoxMesh
	mesh.size = size
	mesh.material = _color_material("pier_material", Color(0.5, 0.36, 0.22))
	var shape: BoxShape3D = _box_shape("pier_shape", size)
	var no_build: Vector3 = Vector3(PIER_LENGTH + 2.0 * ROAD_MARGIN, 6.0, 2.0 * (ROAD_HALF_WIDTH + ROAD_MARGIN))
	for side: int in [-1, 1]:
		var pier: StaticBody3D = StaticBody3D.new()
		pier.name = &"WestPier" if side < 0 else &"EastPier"
		pier.collision_layer = LAYER_TERRAIN
		pier.collision_mask = 0
		var cx: float = side * (PIER_START + PIER_LENGTH * 0.5)
		pier.position = Vector3(cx, PIER_TOP - size.y * 0.5, _road_z(side * ROAD_X))
		var mi: MeshInstance3D = MeshInstance3D.new()
		mi.name = &"Mesh"
		mi.mesh = mesh
		pier.add_child(mi)
		pier.add_child(_collision(&"Collision", shape))
		var id: String = "west_pier_no_build" if side < 0 else "east_pier_no_build"
		pier.add_child(_no_build_area(id, no_build, Vector3(0.0, 2.0, 0.0)))
		piers.add_child(pier)
	root.add_child(piers)


# --- markers -----------------------------------------------------------------------------------

func _cell(p: Vector2) -> Vector2i:
	return Vector2i(int(floor(p.x / 4.0)), int(floor(p.y / 4.0)))


func _marker_ok(p: Vector2) -> bool:
	if _road_distance(p.x, p.y) <= ROAD_HALF_WIDTH + ROAD_MARGIN + 0.5:
		return false
	var half: float = STALL_SIZE * 0.5 + 1.0
	if absf(p.x - STALL_CENTRE.x) <= half and absf(p.y - STALL_CENTRE.y) <= half:
		return false
	if p.distance_to(SPAWN_XZ) <= SPAWN_CLEAR + 1.0:
		return false
	if _surface_y(p.x, p.y) <= MIN_MARKER_Y + 0.05:
		return false
	var c: Vector2i = _cell(p)
	for dx: int in [-1, 0, 1]:
		for dz: int in [-1, 0, 1]:
			for q: Vector2 in _placed.get(c + Vector2i(dx, dz), []):
				if p.distance_to(q) < MARKER_SPACING:
					return false
	return true


func _in_rect(r: Rect2) -> Vector2:
	return Vector2(_rng.randf_range(r.position.x, r.end.x), _rng.randf_range(r.position.y, r.end.y))


func _in_disc(centre: Vector2, radius: float) -> Vector2:
	var a: float = _rng.randf() * TAU
	return centre + Vector2(cos(a), sin(a)) * radius * sqrt(_rng.randf())


## Places `count` markers. `sample` returns a candidate position; `def_for` maps the index to a def id.
func _scatter(parent: Node3D, count: int, sample: Callable, def_for: Callable, extra_ok: Callable = Callable()) -> void:
	var placed: int = 0
	var tries: int = 0
	while placed < count and tries < count * 500:
		tries += 1
		var p: Vector2 = sample.call()
		if not _marker_ok(p) or (extra_ok.is_valid() and not extra_ok.call(p)):
			continue
		var def_id: StringName = def_for.call()
		var m: Marker3D = Marker3D.new()
		m.set_script(load(NODE_MARKER_SCRIPT))
		m.set(&"def_id", def_id)
		m.position = Vector3(p.x, _surface_y(p.x, p.y), p.y)
		m.name = StringName("%s_%04d" % [def_id, parent.get_child_count()])
		parent.add_child(m)
		var c: Vector2i = _cell(p)
		if not _placed.has(c):
			_placed[c] = []
		(_placed[c] as Array).append(p)
		placed += 1
	if placed < count:
		push_error("build_greybox_island: placed only %d of %d markers" % [placed, count])


func _add_markers(root: Node3D) -> void:
	var markers: Node3D = Node3D.new()
	markers.name = &"NodeMarkers"
	root.add_child(markers)
	var whole: Rect2 = Rect2(-HALF_SIZE, -HALF_SIZE, 2.0 * HALF_SIZE, 2.0 * HALF_SIZE)
	var forest: Rect2 = Rect2(-200.0, -200.0, 180.0, 185.0)        # NW quarter, dense
	var light_woods: Rect2 = Rect2(20.0, 20.0, 180.0, 180.0)       # SE, sparse
	var berry_meadow: Rect2 = Rect2(0.0, -110.0, 200.0, 105.0)     # NE meadow north of the road
	var fibre_meadow: Rect2 = Rect2(-200.0, 10.0, 190.0, 190.0)    # SW meadow
	var tree: Callable = func() -> StringName: return &"tree_small" if _rng.randf() < 0.6 else &"tree_large"
	var fixed: Callable = func(id: StringName) -> Callable: return func() -> StringName: return id
	var off_rise: Callable = func(p: Vector2) -> bool: return p.distance_to(RISE_CENTRE) > RISE_RADIUS
	_scatter(markers, 360, _in_rect.bind(forest), tree)
	_scatter(markers, 140, _in_rect.bind(light_woods), tree)
	_scatter(markers, 125, _in_disc.bind(RISE_CENTRE, 70.0), fixed.call(&"rock"))
	_scatter(markers, 25, _in_disc.bind(RISE_CENTRE, 35.0), fixed.call(&"ore_rock"))
	_scatter(markers, 100, _in_rect.bind(berry_meadow), fixed.call(&"berry_bush"), off_rise)
	_scatter(markers, 20, _in_rect.bind(SPAWN_MEADOW), fixed.call(&"berry_bush"))
	_scatter(markers, 110, _in_rect.bind(fibre_meadow), fixed.call(&"fibre_grass"))
	_scatter(markers, 40, _in_rect.bind(whole), fixed.call(&"fibre_grass"), off_rise)
	_scatter(markers, 40, _in_rect.bind(SPAWN_MEADOW), fixed.call(&"loose_stick"))
	_scatter(markers, 35, _in_rect.bind(whole), fixed.call(&"loose_stick"))
	_scatter(markers, 40, _in_rect.bind(SPAWN_MEADOW), fixed.call(&"loose_stone"))
	_scatter(markers, 35, _in_rect.bind(whole), fixed.call(&"loose_stone"))


# --- volumes -----------------------------------------------------------------------------------

func _add_fishing_spots(root: Node3D) -> void:
	var spots: Node3D = Node3D.new()
	spots.name = &"FishingSpots"
	var shape: CylinderShape3D = _sub(CylinderShape3D.new(), "fishing_shape") as CylinderShape3D
	shape.radius = 4.0
	shape.height = 3.0
	var places: Array[Vector2] = [POND_CENTRE + Vector2(-5.0, -2.0), POND_CENTRE + Vector2(5.0, 3.0)]
	for deg: float in [100.0, 65.0, 30.0]:   # south and east shore, just offshore in the shallows
		var theta: float = deg_to_rad(deg)
		places.append(Vector2(cos(theta), sin(theta)) * (_coast_radius(theta) + 6.0))
	for k: int in places.size():
		var spot: Area3D = Area3D.new()
		spot.set_script(load(FISHING_SPOT_SCRIPT))
		spot.name = StringName(("Pond%d" % (k + 1)) if k < 2 else ("Shore%d" % (k - 1)))
		spot.collision_layer = LAYER_WATER
		spot.collision_mask = 0
		spot.position = Vector3(places[k].x, 0.0, places[k].y)
		spot.add_child(_collision(&"Shape", shape))
		spots.add_child(spot)
	root.add_child(spots)


func _add_wildlife_zones(root: Node3D) -> void:
	var zones: Node3D = Node3D.new()
	zones.name = &"WildlifeZones"
	var specs: Array[Dictionary] = [
		{"name": &"DeerZone", "animal": &"deer", "pop": 6, "centre": Vector2(-110.0, -107.5), "size": Vector3(180.0, 40.0, 185.0)},
		{"name": &"RabbitZone", "animal": &"rabbit", "pop": 8, "centre": Vector2(110.0, 110.0), "size": Vector3(180.0, 40.0, 180.0)},
		{"name": &"BoarZone", "animal": &"boar", "pop": 4, "centre": RISE_CENTRE, "size": Vector3(120.0, 40.0, 120.0)},
	]
	for spec: Dictionary in specs:
		var zone: Area3D = Area3D.new()
		zone.set_script(load(WILDLIFE_ZONE_SCRIPT))
		zone.name = spec["name"]
		zone.set(&"animal_id", spec["animal"])
		zone.set(&"target_population", spec["pop"])
		zone.collision_layer = 0
		zone.collision_mask = LAYER_NPC
		var c: Vector2 = spec["centre"]
		zone.position = Vector3(c.x, 10.0, c.y)
		zone.add_child(_collision(&"Shape", _box_shape("%s_shape" % String(spec["animal"]), spec["size"])))
		zones.add_child(zone)
	root.add_child(zones)


func _add_environment(root: Node3D) -> void:
	var env_node: Node3D = Node3D.new()
	env_node.name = &"Environment"
	var sky_mat: ProceduralSkyMaterial = _sub(ProceduralSkyMaterial.new(), "sky_material") as ProceduralSkyMaterial
	sky_mat.ground_bottom_color = Color(0.1, 0.27, 0.4)   # below the horizon reads as more sea
	sky_mat.ground_horizon_color = Color(0.4, 0.55, 0.65)
	var sky: Sky = _sub(Sky.new(), "sky") as Sky
	sky.sky_material = sky_mat
	var env: Environment = _sub(Environment.new(), "environment") as Environment
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.fog_enabled = true
	env.fog_density = 0.0005
	env.fog_sky_affect = 0.0
	var we: WorldEnvironment = WorldEnvironment.new()
	we.name = &"WorldEnvironment"
	we.environment = env
	env_node.add_child(we)
	var sun: DirectionalLight3D = DirectionalLight3D.new()
	sun.name = &"Sun"
	sun.rotation_degrees = Vector3(-50.0, -30.0, 0.0)
	sun.shadow_enabled = true
	env_node.add_child(sun)
	root.add_child(env_node)


func _add_boundary(root: Node3D) -> void:
	var min_x: float = INF
	var max_x: float = -INF
	var min_z: float = INF
	var max_z: float = -INF
	for k: int in OUTLINE_SAMPLES:
		var theta: float = TAU * k / OUTLINE_SAMPLES
		var p: Vector2 = Vector2(cos(theta), sin(theta)) * _coast[k]
		min_x = minf(min_x, p.x)
		max_x = maxf(max_x, p.x)
		min_z = minf(min_z, p.y)
		max_z = maxf(max_z, p.y)
	min_x -= WALL_OFFSET
	max_x += WALL_OFFSET
	min_z -= WALL_OFFSET
	max_z += WALL_OFFSET
	print("build_greybox_island: walls x %.1f..%.1f z %.1f..%.1f" % [min_x, max_x, min_z, max_z])
	var boundary: Node3D = Node3D.new()
	boundary.name = &"Boundary"
	var span_x: float = max_x - min_x + 4.0
	var span_z: float = max_z - min_z + 4.0
	var walls: Array[Array] = [
		[&"WallNorth", Vector3((min_x + max_x) * 0.5, 20.0, min_z), Vector3(span_x, 60.0, 2.0)],
		[&"WallSouth", Vector3((min_x + max_x) * 0.5, 20.0, max_z), Vector3(span_x, 60.0, 2.0)],
		[&"WallWest", Vector3(min_x, 20.0, (min_z + max_z) * 0.5), Vector3(2.0, 60.0, span_z)],
		[&"WallEast", Vector3(max_x, 20.0, (min_z + max_z) * 0.5), Vector3(2.0, 60.0, span_z)],
	]
	for w: Array in walls:
		var wall: StaticBody3D = StaticBody3D.new()
		wall.name = w[0]
		wall.collision_layer = LAYER_TERRAIN
		wall.collision_mask = 0
		wall.position = w[1]
		wall.add_child(_collision(&"Collision", _box_shape("%s_shape" % String(w[0]).to_snake_case(), w[2])))
		boundary.add_child(wall)
	root.add_child(boundary)


# --- saving ------------------------------------------------------------------------------------

func _own(node: Node, owner_node: Node) -> void:
	for child: Node in node.get_children():
		child.owner = owner_node
		_own(child, owner_node)


func _save_scene(root: Node3D) -> void:
	_own(root, root)
	var packed: PackedScene = PackedScene.new()
	var err: Error = packed.pack(root)
	assert(err == OK)
	err = ResourceSaver.save(packed, SCENE_PATH)
	assert(err == OK)
	# Godot assigns random node unique_ids on pack; replace them with seeded ones so reruns are identical.
	var text: String = FileAccess.get_file_as_string(SCENE_PATH)
	var re: RegEx = RegEx.create_from_string("unique_id=\\d+")
	var ids: RandomNumberGenerator = RandomNumberGenerator.new()
	ids.seed = SEED
	var used: Dictionary = {}
	var out: PackedStringArray = PackedStringArray()
	var last: int = 0
	for m: RegExMatch in re.search_all(text):
		var id: int = ids.randi_range(1, 0x7FFFFFFF)
		while used.has(id):
			id = ids.randi_range(1, 0x7FFFFFFF)
		used[id] = true
		out.append(text.substr(last, m.get_start() - last))
		out.append("unique_id=%d" % id)
		last = m.get_end()
	out.append(text.substr(last))
	var f: FileAccess = FileAccess.open(SCENE_PATH, FileAccess.WRITE)
	f.store_string("".join(out))
	f.close()
	print("build_greybox_island: saved %s (%d markers)" % [SCENE_PATH, root.get_node("NodeMarkers").get_child_count()])
