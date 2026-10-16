extends SceneTree

const CivicSimulationScript := preload("res://scripts/game/civic_simulation.gd")
const SAVE_PATH := "user://brasil_em_jogo_save.json"
var _failures: Array[String] = []
var _checks := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var original: Variant = FileAccess.get_file_as_bytes(SAVE_PATH) if FileAccess.file_exists(SAVE_PATH) else null
	var sim: CivicSimulation = CivicSimulationScript.new()
	sim._reset_scopes()
	sim.year = 2026
	sim.quarter = 1
	sim.current_level = "municipal"
	sim.state_uf = "SP"
	sim.municipality_id = 3509502
	sim.municipality_name = "Campinas"
	var initial_budget := int(sim.current_scope().budget)
	var initial_health := float(sim.current_scope().services.saude)
	var action: Dictionary = sim.apply_policy("ubs")
	_check(bool(action.ok), "a política da saúde deve ser executável")
	_check(int(sim.current_scope().budget) < initial_budget, "a política deve comprometer o orçamento")
	_check(float(sim.current_scope().services.saude) > initial_health, "a política deve melhorar o serviço impactado")
	var bill: Dictionary = sim.pass_proposal("dados_abertos")
	_check(bool(bill.ok), "uma proposta disponível deve poder ser aprovada")
	_check(sim.active_laws().size() == 1, "a aprovação deve registrar uma norma")
	var review: Dictionary = sim.judge_law("dados_abertos", false)
	_check(bool(review.ok), "o Judiciário simulado deve revisar uma norma em vigor")
	_check(str(sim.active_laws()[0].status) == "Suspensa para revisão", "a decisão deve atualizar o status da norma")
	var quarter_result: Dictionary = sim.advance_quarter()
	_check(int(quarter_result.quarter) == 2 and int(quarter_result.year) == 2026, "avançar turno deve atualizar o calendário trimestral")
	_check(sim.community_groups().size() == 4, "a comunidade deve conter quatro grupos com prioridades distintas")
	var states: Variant = _load_json("res://data/brazil_states.json")
	var municipalities: Variant = _load_json("res://data/brazil_municipalities.json")
	var geo: Variant = _load_json("res://data/brazil_states.geojson")
	_check(states is Array and states.size() == 27, "o mapa deve listar as 27 unidades federativas")
	_check(municipalities is Array and municipalities.size() >= 5500, "o catálogo local deve permitir buscar municípios brasileiros")
	_check(geo is Dictionary and geo.get("features", []).size() == 27, "a malha territorial deve conter 27 geometrias estaduais")
	_check(_contains_campinas(municipalities), "a lista de municípios deve conter Campinas (SP)")
	_check(FileAccess.file_exists("res://assets/game/urna_ficticia.png"), "a urna fictícia deve ser integrada ao jogo")
	_check(FileAccess.file_exists("res://assets/game/portrait_lia.png"), "o jogo deve incluir arte de personagens ficcionais")
	if original == null:
		if FileAccess.file_exists(SAVE_PATH):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
	else:
		var restore := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
		if restore != null:
			restore.store_buffer(original)
			restore.close()
		_check(FileAccess.get_file_as_bytes(SAVE_PATH) == original, "o teste deve restaurar o arquivo de progresso original")
	if _failures.is_empty():
		print("[brasil-em-jogo-tests] PASS: %d verificações" % _checks)
		quit(0)
		return
	for failure: String in _failures:
		push_error("[brasil-em-jogo-tests] " + failure)
	print("[brasil-em-jogo-tests] FAIL: %d falhas em %d verificações" % [_failures.size(), _checks])
	quit(1)


func _load_json(path: String) -> Variant:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return null
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	return parsed


func _contains_campinas(rows: Variant) -> bool:
	if not rows is Array:
		return false
	for row: Variant in rows:
		if row is Dictionary and int(row.get("id", 0)) == 3509502 and str(row.get("uf", "")) == "SP":
			return true
	return false


func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures.append(message)
