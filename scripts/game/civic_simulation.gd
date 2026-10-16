extends RefCounted
class_name CivicSimulation

const SAVE_PATH := "user://brasil_em_jogo_save.json"
const LEVELS := ["municipal", "state", "federal"]
const LEVEL_NAMES := {"municipal": "Município", "state": "Estado", "federal": "União"}
const BASE_SCOPES := {
	"municipal": {"budget": 42000000, "approval": 62.0, "services": {"saude": 57.0, "educacao": 64.0, "mobilidade": 53.0, "saneamento": 61.0}, "laws": []},
	"state": {"budget": 6800000000, "approval": 55.0, "services": {"saude": 59.0, "educacao": 62.0, "mobilidade": 56.0, "saneamento": 60.0}, "laws": []},
	"federal": {"budget": 380000000000, "approval": 51.0, "services": {"saude": 60.0, "educacao": 58.0, "mobilidade": 54.0, "saneamento": 58.0}, "laws": []}
}
const POLICY_LISTS := {
	"municipal": [
		{"id": "ubs", "title": "Mutirão nas UBS", "description": "Ampliar consultas e reduzir a fila da saúde básica.", "cost": 7500000, "effects": {"saude": 9.0}, "approval": 2.0},
		{"id": "escolas", "title": "Reforma de escolas", "description": "Reparar salas, banheiros e cozinhas da rede municipal.", "cost": 6200000, "effects": {"educacao": 8.0}, "approval": 1.5},
		{"id": "onibus", "title": "Corredores de ônibus", "description": "Melhorar a frequência e a conexão entre bairros.", "cost": 8900000, "effects": {"mobilidade": 9.0}, "approval": 1.2},
		{"id": "agua", "title": "Saneamento de bairro", "description": "Expandir drenagem e saneamento em áreas prioritárias.", "cost": 5500000, "effects": {"saneamento": 8.0}, "approval": 1.4}
	],
	"state": [
		{"id": "hospitais", "title": "Rede regional de hospitais", "description": "Reforçar atendimento especializado e regulação estadual.", "cost": 960000000, "effects": {"saude": 8.0}, "approval": 1.8},
		{"id": "ensino_medio", "title": "Escolas de tempo integral", "description": "Ampliar vagas e infraestrutura do ensino médio estadual.", "cost": 740000000, "effects": {"educacao": 8.0}, "approval": 1.4},
		{"id": "rodovias", "title": "Recuperação de rodovias", "description": "Recuperar trechos estaduais e melhorar a segurança viária.", "cost": 880000000, "effects": {"mobilidade": 8.0}, "approval": 1.1},
		{"id": "consorcio", "title": "Consórcio de saneamento", "description": "Coordenar obras regionais junto aos municípios.", "cost": 510000000, "effects": {"saneamento": 7.0}, "approval": 1.2}
	],
	"federal": [
		{"id": "sus", "title": "Apoio à atenção básica", "description": "Transferir recursos para fortalecer a rede pública de saúde.", "cost": 46000000000, "effects": {"saude": 7.0}, "approval": 1.8},
		{"id": "educacao_federal", "title": "Pacto pela alfabetização", "description": "Cooperar com estados e municípios por metas educacionais.", "cost": 38000000000, "effects": {"educacao": 8.0}, "approval": 1.6},
		{"id": "mobilidade_federal", "title": "Infraestrutura de integração", "description": "Apoiar corredores e projetos de mobilidade regional.", "cost": 51000000000, "effects": {"mobilidade": 7.0}, "approval": 1.2},
		{"id": "saneamento_federal", "title": "Fundo de saneamento", "description": "Co-financiar projetos com estados e municípios.", "cost": 29000000000, "effects": {"saneamento": 7.0}, "approval": 1.4}
	]
}
const PROPOSALS := [
	{"id": "dados_abertos", "title": "Transparência nos contratos", "description": "Publicar contratos e metas em formato aberto.", "cost": 950000, "effect": "Aumenta a confiança pública; pode elevar o custo de fiscalização."},
	{"id": "passe_estudantil", "title": "Passe estudantil integrado", "description": "Criar desconto tarifário para estudantes de baixa renda.", "cost": 3800000, "effect": "Ajuda a frequência escolar e o acesso ao transporte."},
	{"id": "audiencias", "title": "Audiências nos bairros", "description": "Instituir consultas públicas antes de obras de grande impacto.", "cost": 1100000, "effect": "Amplia participação; projetos podem levar mais tempo."}
]
const EVENTS := [
	{"title": "Chuva intensa", "description": "Uma chuva forte pressiona a drenagem e a manutenção urbana.", "service": "saneamento", "impact": -3.0, "cost": 1300000},
	{"title": "Mobilização comunitária", "description": "Moradores se organizam e ajudam a mapear prioridades locais.", "service": "educacao", "impact": 2.0, "cost": 0},
	{"title": "Pressão no atendimento", "description": "A procura por serviços de saúde cresce neste trimestre.", "service": "saude", "impact": -2.5, "cost": 900000},
	{"title": "Cooperação regional", "description": "Uma parceria entre governos melhora a execução de um serviço.", "service": "mobilidade", "impact": 2.0, "cost": 0}
]

var year := 2026
var quarter := 1
var current_level := "municipal"
var state_uf := "SP"
var municipality_id := 3509502
var municipality_name := "Campinas"
var scopes: Dictionary = {}
var event_log: Array[Dictionary] = []
var last_election: Dictionary = {}
var _rng := RandomNumberGenerator.new()


func _init() -> void:
	_rng.randomize()
	_reset_scopes()
	_load_state()


func _reset_scopes() -> void:
	scopes = BASE_SCOPES.duplicate(true)


func current_scope() -> Dictionary:
	return scopes.get(current_level, scopes["municipal"])


func set_level(level: String) -> void:
	if level in LEVELS:
		current_level = level
		save_state()


func set_location(city_id: int, city_name: String, uf: String) -> void:
	municipality_id = city_id
	municipality_name = city_name
	state_uf = uf
	save_state()


func level_name() -> String:
	return str(LEVEL_NAMES.get(current_level, "Município"))


func policy_options() -> Array:
	return POLICY_LISTS.get(current_level, POLICY_LISTS["municipal"]).duplicate(true)


func apply_policy(policy_id: String) -> Dictionary:
	var policy: Dictionary = {}
	for candidate: Dictionary in policy_options():
		if str(candidate.get("id", "")) == policy_id:
			policy = candidate
			break
	if policy.is_empty():
		return {"ok": false, "message": "Esta ação não pertence à esfera selecionada."}
	var scope: Dictionary = current_scope()
	var cost := int(policy.cost)
	if int(scope.budget) < cost:
		return {"ok": false, "message": "Orçamento insuficiente para esta ação."}
	scope.budget = int(scope.budget) - cost
	var services: Dictionary = scope.services
	for key: Variant in policy.effects:
		services[str(key)] = clampf(float(services.get(key, 50.0)) + float(policy.effects[key]), 0.0, 100.0)
	scope.services = services
	scope.approval = clampf(float(scope.approval) + float(policy.approval), 0.0, 100.0)
	scopes[current_level] = scope
	_add_event("Executivo: " + str(policy.title), "Investimento de " + format_money(cost) + " na esfera " + level_name() + ".")
	save_state()
	return {"ok": true, "message": "A ação foi iniciada. Os indicadores já refletem o primeiro efeito; impactos completos levam tempo."}


func pending_proposals() -> Array:
	var scope: Dictionary = current_scope()
	var passed: Dictionary = {}
	for law: Dictionary in scope.get("laws", []):
		passed[str(law.get("id", ""))] = true
	var result: Array = []
	for proposal: Dictionary in PROPOSALS:
		if not passed.has(str(proposal.id)):
			result.append(proposal.duplicate(true))
	return result


func pass_proposal(proposal_id: String) -> Dictionary:
	var proposal: Dictionary = {}
	for item: Dictionary in pending_proposals():
		if str(item.id) == proposal_id:
			proposal = item
			break
	if proposal.is_empty():
		return {"ok": false, "message": "Proposta não encontrada ou já votada."}
	var scope: Dictionary = current_scope()
	var cost := int(proposal.cost)
	if int(scope.budget) < cost:
		return {"ok": false, "message": "A proposta não cabe no orçamento atual."}
	scope.budget = int(scope.budget) - cost
	var laws: Array = scope.get("laws", [])
	laws.append({"id": proposal_id, "title": proposal.title, "status": "Em vigor", "cost": cost, "effect": proposal.effect})
	scope.laws = laws
	scope.approval = clampf(float(scope.approval) + 1.0, 0.0, 100.0)
	scopes[current_level] = scope
	_add_event("Legislativo: proposta aprovada", str(proposal.title) + " foi aprovada na esfera " + level_name() + ".")
	save_state()
	return {"ok": true, "message": "A proposta foi aprovada e seguirá para implementação e fiscalização."}


func judge_law(law_id: String, uphold: bool) -> Dictionary:
	var scope: Dictionary = current_scope()
	var laws: Array = scope.get("laws", [])
	for index: int in laws.size():
		var law: Dictionary = laws[index]
		if str(law.get("id", "")) != law_id or str(law.get("status", "")) != "Em vigor":
			continue
		law.status = "Mantida após revisão" if uphold else "Suspensa para revisão"
		laws[index] = law
		scope.laws = laws
		scope.approval = clampf(float(scope.approval) + (0.6 if uphold else -0.8), 0.0, 100.0)
		scopes[current_level] = scope
		_add_event("Judiciário: revisão concluída", str(law.title) + (" foi mantida." if uphold else " foi suspensa na simulação."))
		save_state()
		return {"ok": true, "message": "A decisão foi registrada como resultado da simulação didática."}
	return {"ok": false, "message": "Não há norma em vigor com esse identificador."}


func active_laws() -> Array:
	return current_scope().get("laws", []).duplicate(true)


func advance_quarter() -> Dictionary:
	quarter += 1
	if quarter > 4:
		quarter = 1
		year += 1
	var messages: Array[String] = []
	for level: String in LEVELS:
		var scope: Dictionary = scopes[level]
		var income := int(_quarterly_income(level))
		var expenses := int(_quarterly_expenses(level))
		scope.budget = max(0, int(scope.budget) + income - expenses)
		if int(scope.budget) == 0:
			scope.approval = maxf(0.0, float(scope.approval) - 1.5)
			for service: String in scope.services:
				scope.services[service] = maxf(0.0, float(scope.services[service]) - 0.6)
		scopes[level] = scope
	var event: Dictionary = EVENTS[_rng.randi_range(0, EVENTS.size() - 1)].duplicate(true)
	var target: Dictionary = current_scope()
	var services: Dictionary = target.services
	services[str(event.service)] = clampf(float(services.get(str(event.service), 50.0)) + float(event.impact), 0.0, 100.0)
	target.services = services
	target.budget = max(0, int(target.budget) - int(event.cost))
	target.approval = clampf(float(target.approval) + float(event.impact) * 0.25, 0.0, 100.0)
	scopes[current_level] = target
	var label := "%s — %s" % [event.title, event.description]
	_add_event("Evento do trimestre", label)
	messages.append(label)
	if quarter == 4:
		messages.append("Fechamento de %d: receitas e despesas foram atualizadas." % year)
	if year == 2028 and quarter == 1:
		messages.append("Ciclo municipal de 2028: a urna de demonstração fica disponível para treino.")
	save_state()
	return {"messages": messages, "event": event, "year": year, "quarter": quarter}


func community_groups() -> Array[Dictionary]:
	var services: Dictionary = current_scope().services
	var base := float(current_scope().approval)
	return [
		{"name": "Famílias", "need": "saúde e saneamento", "satisfaction": clampf((float(services.saude) + float(services.saneamento) + base) / 3.0, 0.0, 100.0)},
		{"name": "Juventude", "need": "educação e mobilidade", "satisfaction": clampf((float(services.educacao) + float(services.mobilidade) + base) / 3.0, 0.0, 100.0)},
		{"name": "Trabalhadores", "need": "transporte e saúde", "satisfaction": clampf((float(services.mobilidade) + float(services.saude) + base) / 3.0, 0.0, 100.0)},
		{"name": "Bairros periféricos", "need": "serviços e infraestrutura", "satisfaction": clampf((float(services.saneamento) + float(services.educacao) + base) / 3.0, 0.0, 100.0)}
	]


func record_election(result: Dictionary) -> void:
	last_election = result.duplicate(true)
	var scope: Dictionary = current_scope()
	if result.has("executive_winner"):
		scope.leader = str(result.executive_winner)
		scope.approval = clampf(float(scope.approval) + 2.0, 0.0, 100.0)
	scopes[current_level] = scope
	_add_event("Eleição simulada concluída", "A apuração fictícia foi concluída; os percentuais são gerados pelo jogo.")
	save_state()


func _quarterly_income(level: String) -> int:
	match level:
		"municipal": return 2800000
		"state": return 1020000000
		"federal": return 42000000000
	return 0


func _quarterly_expenses(level: String) -> int:
	match level:
		"municipal": return 2300000
		"state": return 960000000
		"federal": return 39400000000
	return 0


func _add_event(title: String, description: String) -> void:
	event_log.push_front({"title": title, "description": description, "year": year, "quarter": quarter})
	while event_log.size() > 6:
		event_log.pop_back()


func save_state() -> void:
	var payload := {"version": 1, "year": year, "quarter": quarter, "current_level": current_level, "state_uf": state_uf, "municipality_id": municipality_id, "municipality_name": municipality_name, "scopes": scopes, "event_log": event_log, "last_election": last_election}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(payload, "\t"))
		file.close()


func _load_state() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if not parsed is Dictionary or int(parsed.get("version", 0)) != 1:
		return
	year = int(parsed.get("year", year))
	quarter = clampi(int(parsed.get("quarter", quarter)), 1, 4)
	var level := str(parsed.get("current_level", "municipal"))
	current_level = level if level in LEVELS else "municipal"
	state_uf = str(parsed.get("state_uf", state_uf))
	municipality_id = int(parsed.get("municipality_id", municipality_id))
	municipality_name = str(parsed.get("municipality_name", municipality_name))
	var saved_scopes: Variant = parsed.get("scopes", {})
	if saved_scopes is Dictionary:
		for level_key: String in LEVELS:
			if saved_scopes.has(level_key) and saved_scopes[level_key] is Dictionary:
				scopes[level_key] = saved_scopes[level_key]
	var saved_log: Variant = parsed.get("event_log", [])
	if saved_log is Array:
		event_log.assign(saved_log)
	var saved_election: Variant = parsed.get("last_election", {})
	if saved_election is Dictionary:
		last_election = saved_election


static func format_money(amount: int) -> String:
	if amount >= 1000000000:
		return "R$ %.1f bi" % (float(amount) / 1000000000.0)
	if amount >= 1000000:
		return "R$ %.1f mi" % (float(amount) / 1000000.0)
	if amount >= 1000:
		return "R$ %.0f mil" % (float(amount) / 1000.0)
	return "R$ %d" % amount
