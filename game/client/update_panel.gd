extends VBoxContainer
## "Build / update available" strip in the menu of the Android build. The text is the button: tap it to update, install,
## retry or check again. Texts go through the HUD's i18n and are rebuilt when the language changes.

const AppUpdater = preload("res://client/app_updater.gd")

var i18n
var _updater: Node
var _label: Button
var _action := false
var _info := {}
var _downloaded_path := ""
var _key := ""
var _args: Array = []
var _hint := ""


func setup(translator) -> void:
	i18n = translator


func _ready() -> void:
	_label = Button.new()
	_label.flat = true
	_label.focus_mode = Control.FOCUS_NONE
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_label.custom_minimum_size = Vector2(0, 48)
	_label.add_theme_font_size_override("font_size", 13)
	_label.pressed.connect(_on_button)
	add_child(_label)
	_updater = AppUpdater.new()
	add_child(_updater)
	_updater.checked.connect(_on_checked)
	_updater.progress.connect(_on_progress)
	_updater.downloaded.connect(_on_downloaded)
	_updater.failed.connect(func(message: String) -> void: _show("update.error", [message], "retry"))
	_check()


func refresh_texts() -> void:
	if _label != null and _key != "":
		_render()


func _check() -> void:
	_show("update.checking", [AppUpdater.current_code()], "")
	_updater.check()


func _on_checked(result: Dictionary) -> void:
	match result["status"]:
		"available":
			_info = result
			_show("update.available", [result.get("name", "?"), int(result["code"])], "update")
		"up_to_date":
			_show("update.current", [AppUpdater.current_code()], "check")
		_:
			_show("update.error", [str(result["error"])], "retry")


func _on_button() -> void:
	if not _action:
		return
	if _downloaded_path != "":
		_install()
	elif not _info.is_empty() and _info.get("status") == "available":
		_show("update.downloading", [0, 0, 0], "")
		_updater.download(_info)
	else:
		_info = {}
		_check()


func _on_progress(received: int, total: int) -> void:
	_action = false
	_key = "update.downloading"
	_hint = ""
	_args = [100 * received / total if total > 0 else 0, "%.1f" % (received / 1048576.0), "%.1f" % (total / 1048576.0)]
	_render()


func _on_downloaded(path: String) -> void:
	_downloaded_path = path
	_install()


func _install() -> void:
	var outcome: String = _updater.install(_downloaded_path)
	match outcome:
		"ok":
			_show("update.confirm", [], "install")
		"need_permission":
			_show("update.permission", [], "install")
		_:
			_downloaded_path = ""
			_show("update.error", [outcome], "retry")


func _show(key: String, args: Array, hint: String) -> void:
	_key = key
	_args = args
	_hint = hint
	_action = hint != ""
	_render()


func _render() -> void:
	var text: String = i18n.t(_key, _args)
	_label.text = "%s\n%s" % [text, i18n.t("update.tap_" + _hint)] if _hint != "" else text
	var colour: Color = UiKit.ACCENT if _hint != "" else UiKit.MUTED
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		_label.add_theme_color_override(state, colour)
