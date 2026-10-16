extends SceneTree

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_verify")


func _verify() -> void:
	_check(ProjectSettings.get_setting("application/config/name") == "Brasil em Jogo", "identidade exportada")
	for path: String in [
		"res://data/brazil_states.json",
		"res://data/brazil_municipalities.json",
		"res://data/brazil_states.geojson",
	]:
		_check(FileAccess.file_exists(path), "dado geográfico no pack: " + path)
	for path: String in [
		"res://assets/game/brazil_states_basemap.png",
		"res://assets/game/community_groups.png",
		"res://assets/game/portrait_lia.png",
		"res://assets/game/urna_ficticia.png",
		"res://assets/game/three_powers.png",
		"res://assets/game/public_challenge.png",
	]:
		_check(ResourceLoader.exists(path), "asset do jogo no pack: " + path)
	_check(not ResourceLoader.exists("res://test/brasil_em_jogo_smoke.gd"), "teste-fumaça excluído do pack")
	_check(not root.has_node("GlobalLeaderboard"), "sem placar ou autoload online")
	var packed := load("res://scenes/main.tscn") as PackedScene
	_check(packed != null, "cena principal exportada")
	if packed != null:
		var main := packed.instantiate()
		root.add_child(main)
		await process_frame
		await process_frame
		_check(str(main.get("_page")) == "dashboard", "pack inicia no painel geral")
		var states: Array = main.get("_states")
		var municipalities: Array = main.get("_municipalities")
		_check(states.size() == 27, "pack carrega as 27 unidades federativas")
		_check(municipalities.size() >= 5500, "pack carrega o catálogo local de municípios")
		var map := _find_map(main)
		_check(map != null, "mapa interativo exportado")
		if map != null:
			var features: Array = map.get("_features")
			_check(features.size() == 27, "mapa carrega as geometrias das 27 UFs")
		main.call("_show_page", "elections")
		await process_frame
		_check(str(main.get("_page")) == "elections", "página eleitoral abre no pack")
		main.call("_start_ballot", "municipal")
		await process_frame
		_check(str(main.get("_page")) == "ballot", "urna municipal fictícia abre no pack")
		_check(main.get("_ballot_candidate_label") is Label, "painel de conferência da urna exportado")
		main.queue_free()
		await process_frame
	if _failures.is_empty():
		print("[exported-pack] PASS: identidade, dados offline, mapa, páginas e urna fictícia")
		quit(0)
	else:
		for failure: String in _failures:
			push_error("[exported-pack] " + failure)
		quit(1)


func _find_map(node: Node) -> Node:
	var attached_script := node.get_script() as Script
	if attached_script != null and attached_script.resource_path == "res://scripts/ui/brasil_map.gd":
		return node
	for child: Node in node.get_children():
		var found := _find_map(child)
		if found != null:
			return found
	return null


func _check(condition: bool, context: String) -> void:
	if not condition and context not in _failures:
		_failures.append(context)
