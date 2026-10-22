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


static func load_all(dir: String = "res://data") -> RefCounted:
	var gd = (load("res://core/game_data.gd") as GDScript).new()
	gd.load_from(dir)
	return gd


func load_from(dir: String) -> void:
	var t: Dictionary = _read(dir + "/towers.json")
	towers = t.towers
	elements = t.elements
	ultimate = t.ultimate
	creeps = _read(dir + "/creeps.json").creeps
	waves = _read(dir + "/waves_classic.json").waves
	matrix = _read(dir + "/matrix.json").multipliers
	rules = _read(dir + "/rules_classic.json")
	map = _read(dir + "/maps/" + rules.map + ".json")


func element_of(id: String) -> Dictionary:
	for e in elements:
		if e.id == id:
			return e
	return {}


func _read(path: String) -> Dictionary:
	var f := FileAccess.open(path, FileAccess.READ)
	assert(f != null, "cannot open " + path)
	var parsed = JSON.parse_string(f.get_as_text())
	assert(parsed is Dictionary, "invalid json: " + path)
	return parsed
