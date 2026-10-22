extends Node
## In-game updater for the Android build. The Mac publishes `version.json` and the
## APK (tools/build_android.sh); this asks "is there a newer build?", downloads it,
## verifies it and hands it to Android's installer (android/build/.../Updater.java).
##
## Android never installs apps silently: the user confirms the system prompt, and
## on first use must allow "install unknown apps" for this app.

signal checked(result: Dictionary)  ## {status: "up_to_date"|"available"|"error", ...}
signal progress(received: int, total: int)
signal downloaded(path: String)
signal failed(message: String)

const BASE_URL := "https://willems-macbook-pro.tail868144.ts.net:8443/app"
const JAVA_CLASS := "be.willem.guardians.Updater"

var base_urls: Array = [BASE_URL]
## Where the APK is saved. Empty = ask the Android side (private cache dir).
var download_dir := ""

var _base := ""  ## the base URL that worked for the last check
var _http: HTTPRequest
var _downloading := false
var _info := {}


## Only the Android build can install updates. `--update-ui` shows the panel on
## desktop for testing the flow (the final install step is skipped there).
static func supported() -> bool:
	return OS.has_feature("android") or OS.get_cmdline_user_args().has("--update-ui")


## Build number baked into the APK by tools/build.sh (0 when running from the editor).
static func current_code() -> int:
	return int(_build_info().get("code", 0))


static func current_name() -> String:
	return str(_build_info().get("name", "dev"))


static func _build_info() -> Dictionary:
	if not FileAccess.file_exists("res://build_info.json"):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://build_info.json"))
	return parsed if parsed is Dictionary else {}


func check() -> void:
	_try_check(0, [])


func _try_check(index: int, errors: Array) -> void:
	if index >= base_urls.size():
		checked.emit({"status": "error", "error": "Can't reach the update server (is Tailscale on?)\n" + "\n".join(errors)})
		return
	var base: String = base_urls[index]
	var http := HTTPRequest.new()
	http.timeout = 10.0
	add_child(http)
	http.request_completed.connect(func(result: int, code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
		http.queue_free()
		if result != HTTPRequest.RESULT_SUCCESS or code != 200:
			errors.append("%s: %s" % [base.get_slice("/", 2), _reason(result, code)])
			_try_check(index + 1, errors)
			return
		var parsed: Variant = JSON.parse_string(body.get_string_from_utf8())
		if not parsed is Dictionary or not (parsed as Dictionary).has("code"):
			checked.emit({"status": "error", "error": "Bad update info from server"})
			return
		var info: Dictionary = parsed
		_base = base
		_info = info
		info["status"] = "available" if int(info["code"]) > current_code() else "up_to_date"
		checked.emit(info))
	# The timestamp defeats any caching between us and the Mac.
	var err := http.request("%s/version.json?t=%d" % [base, Time.get_ticks_msec()])
	if err != OK:
		http.queue_free()
		errors.append("%s: could not start (%s)" % [base.get_slice("/", 2), error_string(err)])
		_try_check(index + 1, errors)


static func _reason(result: int, code: int) -> String:
	match result:
		HTTPRequest.RESULT_SUCCESS:
			return "HTTP %d" % code
		HTTPRequest.RESULT_CANT_RESOLVE:
			return "can't find that host"
		HTTPRequest.RESULT_CANT_CONNECT:
			return "can't connect"
		HTTPRequest.RESULT_TLS_HANDSHAKE_ERROR:
			return "secure connection failed"
		HTTPRequest.RESULT_TIMEOUT:
			return "timed out"
		HTTPRequest.RESULT_CONNECTION_ERROR:
			return "connection error"
		_:
			return "error %d" % result


const DOWNLOAD_TRIES := 4  ## a 100 MB download over a phone connection sometimes breaks off: try again before giving up

signal retrying(attempt: int, why: String)


func download(info: Dictionary = _info) -> void:
	if _downloading:
		return
	var dir := download_dir if download_dir != "" else _android_update_dir()
	if dir == "":
		failed.emit("No place to save the update")
		return
	_downloading = true
	_attempt(info, dir.path_join("update.apk"), 1, "")


## One try of the download. The address that answered the check comes first, then the other one (a different route may work when one drops out).
func _attempt(info: Dictionary, path: String, attempt: int, last_why: String) -> void:
	if attempt > DOWNLOAD_TRIES:
		_downloading = false
		failed.emit(last_why if last_why != "" else "Download failed")
		return
	if attempt > 1:
		retrying.emit(attempt, last_why)
	var bases: Array = [_base] if _base != "" else []
	for url: Variant in base_urls:
		if not bases.has(url):
			bases.append(url)
	var base := str(bases[(attempt - 1) % bases.size()])
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)  # (never build on what an earlier try left behind)
	_http = HTTPRequest.new()
	_http.download_file = path
	_http.accept_gzip = false  # an APK is already compressed, and the byte count must be the file's
	_http.use_threads = true
	_http.download_chunk_size = 262144
	_http.timeout = 180.0
	add_child(_http)
	var request := _http
	request.request_completed.connect(func(result: int, code: int, _headers: PackedStringArray, _body: PackedByteArray) -> void:
		request.queue_free()
		if result != HTTPRequest.RESULT_SUCCESS or code != 200:
			_attempt(info, path, attempt + 1, "Download failed (%s)" % _reason(result, code))
			return
		var expected := str(info.get("sha256", ""))
		var size := int(info.get("size", 0))
		var got := FileAccess.open(path, FileAccess.READ)
		var got_size: int = got.get_length() if got != null else 0
		got = null
		if size > 0 and got_size != size:
			_attempt(info, path, attempt + 1, "The download broke off (%d of %d bytes)" % [got_size, size])
			return
		if expected != "" and FileAccess.get_sha256(path) != expected:
			_attempt(info, path, attempt + 1, "Downloaded file is corrupt (checksum differs), try again")
			return
		_downloading = false
		downloaded.emit(path))
	if request.request("%s/%s" % [base, str(info.get("apk", "guardians.apk"))]) != OK:
		request.queue_free()
		_attempt(info, path, attempt + 1, "Could not start the download")


func _process(_delta: float) -> void:
	if _downloading and is_instance_valid(_http):
		progress.emit(_http.get_downloaded_bytes(), _http.get_body_size())


## Opens the Android installer for a downloaded APK.
## Returns "ok", "need_permission" (settings opened, ask again afterwards) or an error text.
func install(path: String) -> String:
	if not OS.has_feature("android"):
		return "ok"  # desktop test mode: nothing to install
	var runtime := Engine.get_singleton("AndroidRuntime")
	var updater := JavaClassWrapper.wrap(JAVA_CLASS)
	if runtime == null or updater == null:
		return "Updater is not available in this build"
	var activity: Object = runtime.getActivity()
	if not updater.canInstall(activity):
		updater.openInstallSettings(activity)
		return "need_permission"
	var error := str(updater.install(activity, path))
	return error if error != "" else "ok"


func _android_update_dir() -> String:
	if not OS.has_feature("android"):
		return OS.get_cache_dir()
	var runtime := Engine.get_singleton("AndroidRuntime")
	var updater := JavaClassWrapper.wrap(JAVA_CLASS)
	if runtime == null or updater == null:
		return ""
	return str(updater.updateDir(runtime.getActivity()))
