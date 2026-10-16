extends Node

signal locale_changed(locale: String)

const LOCALE := "pt-BR"
const CATALOG_PATH := "res://localization/pt-BR.json"
var _catalog: Dictionary = {}
var _locale := LOCALE


func _ready() -> void:
	_catalog = _load_catalog()
	_locale = LOCALE


static func detect_locale(_system_locale: String) -> String:
	return LOCALE


static func resolve_locale(_saved_locale: String, _system_locale: String) -> String:
	return LOCALE


func _load_catalog() -> Dictionary:
	var file := FileAccess.open(CATALOG_PATH, FileAccess.READ)
	if file == null:
		push_error("I18n: catálogo pt-BR ausente.")
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	return parsed if parsed is Dictionary else {}


func text(key: String, replacements: Dictionary = {}) -> String:
	var result := str(_catalog.get(key, key))
	for token: Variant in replacements:
		result = result.replace("{%s}" % str(token), str(replacements[token]))
	return result


func t(key: String, replacements: Dictionary = {}) -> String:
	return text(key, replacements)


func get_locale() -> String:
	return _locale


func set_locale(locale: String) -> void:
	if locale != LOCALE or locale == _locale:
		return
	_locale = LOCALE
	locale_changed.emit(_locale)


func toggle_locale() -> void:
	# O jogo é intencionalmente pt-BR nesta versão.
	pass


func catalog_keys(locale: String) -> Array:
	return _catalog.keys() if locale == LOCALE else []
