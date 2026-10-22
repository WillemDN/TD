extends RefCounted
## Tiny translation helper: text lives in res://data/i18n/<lang>.json. Names of towers, creeps, elements and maps are
## stored as {nl, en} dictionaries inside the game data.

const LANGS := ["nl", "en"]

var lang := "en"
var _tables := {}


func _init() -> void:
	for l in LANGS:
		var f := FileAccess.open("res://data/i18n/%s.json" % l, FileAccess.READ)
		_tables[l] = JSON.parse_string(f.get_as_text())


func t(key: String, args: Array = []) -> String:
	var s: String = _tables[lang].get(key, _tables["en"].get(key, key))
	for i in args.size():
		s = s.replace("{%d}" % i, str(args[i]))
	return s


## Pick the current language from a {nl, en} name dictionary.
func n(names: Dictionary) -> String:
	return names.get(lang, names.get("en", ""))


func toggle() -> void:
	lang = "nl" if lang == "en" else "en"
