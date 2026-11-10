## Loads every content definition resource at startup and serves lookups by id (contracts §7).
## No class_name: this script is the `Registry` autoload singleton.
extends Node

const CONTENT_ROOT := "res://content"

## Folder name -> def script every resource in that folder must be an instance of.
var _types: Dictionary[StringName, Script] = {
	&"items": ItemDef,
	&"recipes": RecipeDef,
	&"pieces": PieceDef,
	&"crops": CropDef,
	&"nodes": NodeDef,
	&"animals": AnimalDef,
	&"jobs": JobDef,
	&"trades": TradeDef,
}

## folder name -> { id: StringName -> def Resource }
var _defs: Dictionary[StringName, Dictionary] = {}


func _ready() -> void:
	load_from(CONTENT_ROOT)


## Clears all definitions, then scans `<root>/<type>/` recursively for .tres/.res files.
func load_from(root: String) -> void:
	_defs.clear()
	for folder: StringName in _types:
		_defs[folder] = {}
		var paths: Array[String] = []
		_collect_paths("%s/%s" % [root, folder], paths)
		paths.sort()
		for path: String in paths:
			_register(folder, path)


func item(id: StringName) -> ItemDef:
	return _lookup(&"items", id) as ItemDef

func recipe(id: StringName) -> RecipeDef:
	return _lookup(&"recipes", id) as RecipeDef

func piece(id: StringName) -> PieceDef:
	return _lookup(&"pieces", id) as PieceDef

func crop(id: StringName) -> CropDef:
	return _lookup(&"crops", id) as CropDef

func node_def(id: StringName) -> NodeDef:
	return _lookup(&"nodes", id) as NodeDef

func animal(id: StringName) -> AnimalDef:
	return _lookup(&"animals", id) as AnimalDef

func job(id: StringName) -> JobDef:
	return _lookup(&"jobs", id) as JobDef

func trade(id: StringName) -> TradeDef:
	return _lookup(&"trades", id) as TradeDef


func all_items() -> Array[ItemDef]:
	var out: Array[ItemDef] = []
	for d: Resource in _defs[&"items"].values():
		out.append(d as ItemDef)
	return out

func all_recipes() -> Array[RecipeDef]:
	var out: Array[RecipeDef] = []
	for d: Resource in _defs[&"recipes"].values():
		out.append(d as RecipeDef)
	return out

func all_pieces() -> Array[PieceDef]:
	var out: Array[PieceDef] = []
	for d: Resource in _defs[&"pieces"].values():
		out.append(d as PieceDef)
	return out

func all_crops() -> Array[CropDef]:
	var out: Array[CropDef] = []
	for d: Resource in _defs[&"crops"].values():
		out.append(d as CropDef)
	return out

func all_nodes() -> Array[NodeDef]:
	var out: Array[NodeDef] = []
	for d: Resource in _defs[&"nodes"].values():
		out.append(d as NodeDef)
	return out

func all_animals() -> Array[AnimalDef]:
	var out: Array[AnimalDef] = []
	for d: Resource in _defs[&"animals"].values():
		out.append(d as AnimalDef)
	return out

func all_jobs() -> Array[JobDef]:
	var out: Array[JobDef] = []
	for d: Resource in _defs[&"jobs"].values():
		out.append(d as JobDef)
	return out

func all_trades() -> Array[TradeDef]:
	var out: Array[TradeDef] = []
	for d: Resource in _defs[&"trades"].values():
		out.append(d as TradeDef)
	return out


func _lookup(folder: StringName, id: StringName) -> Resource:
	var defs: Dictionary = _defs.get(folder, {})
	if not defs.has(id):
		push_error("[registry] unknown %s id '%s'" % [String(folder).trim_suffix("s"), id])
		return null
	return defs[id]


func _register(folder: StringName, path: String) -> void:
	var res: Resource = load(path)
	var script: Script = _types[folder]
	if res == null or not is_instance_of(res, script):
		push_error("[registry] wrong type in %s (expected %s)" % [path, script.get_global_name()])
		return
	var id: StringName = res.get(&"id")
	if id == &"":
		push_error("[registry] empty id in %s" % path)
		return
	var defs: Dictionary = _defs[folder]
	if defs.has(id):
		push_error("[registry] duplicate id '%s' in %s (keeping %s)" % [id, path, (defs[id] as Resource).resource_path])
		return
	defs[id] = res


## Recursively gathers .tres/.res paths. Exported builds list resources as `name.tres.remap`,
## so the `.remap` suffix is stripped (load() resolves the original path). Other files (.gitkeep etc.)
## and missing folders are ignored silently.
func _collect_paths(dir: String, out: Array[String]) -> void:
	if not DirAccess.dir_exists_absolute(dir):
		return
	for file: String in DirAccess.get_files_at(dir):
		var file_name := file.trim_suffix(".remap")
		if file_name.ends_with(".tres") or file_name.ends_with(".res"):
			var path := "%s/%s" % [dir, file_name]
			if not out.has(path):
				out.append(path)
	for sub: String in DirAccess.get_directories_at(dir):
		_collect_paths("%s/%s" % [dir, sub], out)
