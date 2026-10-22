extends RefCounted
## All static game data (towers, creeps, waves, matrix, rules, map) loaded from res://data/*.json.

var towers := {}        # id -> tower definition
var elements := []      # [{id, color, name, towers: [ids]}]
var ultimate := ""
var creeps := {}        # id -> creep definition
var waves := []         # index 0 = level 1
var matrix := {}        # attack type -> armor type -> multiplier
var rules := {}
var map := {}
var mode := "classic"
var kind := "td"        # "td" (towers on a map) or "survivor" (one tower, a shop)
var weapons := {}       # mode survivor
var upgrades := {}
var enemies := {}
var rarities := []
var groups := {}        # tray tabs besides the elements (mode "elements": dual and triple towers) id -> {towers: [ids], ...}


## Every game mode lives in res://data/rules_<mode>.json. Optional "files" in the rules point to the mode's own tables,
## relative to the data folder; what is missing falls back to the classic tables.
static func load_all(dir: String = "res://data", mode_id: String = "classic") -> RefCounted:
	var gd = (load("res://core/game_data.gd") as GDScript).new()
	gd.load_from(dir, mode_id)
	return gd


static func rules_of(mode_id: String, dir: String = "res://data") -> Dictionary:
	return _read(dir + "/rules_" + mode_id + ".json")


static func mode_ids(dir: String = "res://data") -> Array:
	return _read(dir + "/modes.json").modes


func load_from(dir: String, mode_id: String = "classic") -> void:
	mode = mode_id
	rules = _read(dir + "/rules_" + mode_id + ".json")
	var files: Dictionary = rules.get("files", {})
	kind = String(rules.get("kind", "td"))
	if kind == "survivor":
		var wf: Dictionary = _read(dir + "/" + String(files.weapons))
		weapons = wf.weapons
		rarities = wf.rarities
		upgrades = _read(dir + "/" + String(files.upgrades)).upgrades
		enemies = _read(dir + "/" + String(files.enemies)).enemies
		return
	var t: Dictionary = _read(dir + "/" + String(files.get("towers", "towers.json")))
	towers = t.towers
	elements = t.elements
	ultimate = t.get("ultimate", "")
	groups = t.get("groups", {})
	creeps = _read(dir + "/" + String(files.get("creeps", "creeps.json"))).creeps
	waves = _read(dir + "/" + String(files.get("waves", "waves_classic.json"))).waves
	matrix = _read(dir + "/" + String(files.get("matrix", "matrix.json"))).multipliers
	map = _read(dir + "/maps/" + rules.map + ".json")


func element_of(id: String) -> Dictionary:
	for e in elements:
		if e.id == id:
			return e
	return {}


static func _read(path: String) -> Dictionary:
	var f := FileAccess.open(path, FileAccess.READ)
	assert(f != null, "cannot open " + path)
	var parsed = JSON.parse_string(f.get_as_text())
	assert(parsed is Dictionary, "invalid json: " + path)
	return parsed
