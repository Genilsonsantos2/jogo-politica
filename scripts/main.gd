extends Control

const CivicSimulationScript := preload("res://scripts/game/civic_simulation.gd")
const BrasilMapScript := preload("res://scripts/ui/brasil_map.gd")
const PORTRAIT_LIA: Texture2D = preload("res://assets/game/portrait_lia.png")
const PORTRAIT_DAVI: Texture2D = preload("res://assets/game/portrait_davi.png")
const PORTRAIT_NOEMI: Texture2D = preload("res://assets/game/portrait_noemi.png")
const BALLOT_MACHINE: Texture2D = preload("res://assets/game/urna_ficticia.png")
const COMMUNITY_ART: Texture2D = preload("res://assets/game/community_groups.png")
const POWERS_ART: Texture2D = preload("res://assets/game/three_powers.png")
const PUBLIC_CHALLENGE_ART: Texture2D = preload("res://assets/game/public_challenge.png")
const BACKGROUND := Color("f6f2e8")
const PAPER := Color("fffdf6")
const INK := Color("233d38")
const MUTED := Color("6a7b73")
const GREEN := Color("267b67")
const GREEN_PALE := Color("e0eee7")
const CORAL := Color("c16b51")
const BORDER := Color("d7ddd1")
const CANDIDATES := [
	{"name": "Lia Monteiro", "party": "Rede do Bairro (RB)", "prefix": "13", "strength": 36.0, "texture": PORTRAIT_LIA, "promise": "Atenção básica e escuta pública"},
	{"name": "Davi Andrade", "party": "Pacto Cívico (PC)", "prefix": "20", "strength": 34.0, "texture": PORTRAIT_DAVI, "promise": "Educação e contas abertas"},
	{"name": "Noemi Santana", "party": "Aliança Pública (AP)", "prefix": "45", "strength": 30.0, "texture": PORTRAIT_NOEMI, "promise": "Mobilidade e serviços nos bairros"}
]
const SERVICE_LABELS := {"saude": "Saúde", "educacao": "Educação", "mobilidade": "Mobilidade", "saneamento": "Saneamento"}
const LEVELS := ["municipal", "state", "federal"]
const LEVEL_TEXT := {"municipal": "Município", "state": "Estado", "federal": "País / União"}

var sim: CivicSimulation
var _states: Array = []
var _municipalities: Array = []
var _state_names: Dictionary = {}
var _page := "dashboard"
var _page_root: VBoxContainer
var _year_label: Label
var _location_label: Label
var _status_label: Label
var _scope_picker: OptionButton
var _search_results: VBoxContainer
var _city_search: LineEdit
var _city_state_filter: OptionButton
var _ballot_jobs: Array[String] = []
var _ballot_index := 0
var _ballot_entry := ""
var _ballot_white_pending := false
var _ballot_choices: Dictionary = {}
var _ballot_status: Label
var _ballot_number_label: Label
var _ballot_line_edit: LineEdit
var _ballot_portrait: TextureRect
var _ballot_candidate_label: Label
var _ballot_candidate_detail: Label
var _election_result: Dictionary = {}
var _is_ballot_page := false


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	custom_minimum_size = Vector2(900, 620)
	sim = CivicSimulationScript.new()
	_load_reference_data()
	_build_shell()
	_render_page()


func _load_reference_data() -> void:
	_states = _load_json_array("res://data/brazil_states.json")
	_municipalities = _load_json_array("res://data/brazil_municipalities.json")
	for state: Dictionary in _states:
		_state_names[str(state.get("uf", ""))] = str(state.get("name", ""))


func _load_json_array(path: String) -> Array:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Brasil em Jogo: dado local ausente: " + path)
		return []
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	return parsed if parsed is Array else []


func _build_shell() -> void:
	var backdrop := ColorRect.new()
	backdrop.color = BACKGROUND
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 22)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_right", 22)
	margin.add_theme_constant_override("margin_bottom", 14)
	add_child(margin)
	var shell := VBoxContainer.new()
	shell.add_theme_constant_override("separation", 14)
	margin.add_child(shell)
	_build_header(shell)
	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 16)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	shell.add_child(body)
	_build_sidebar(body)
	var scroll := ScrollContainer.new()
	scroll.name = "PageScroll"
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	body.add_child(scroll)
	_page_root = VBoxContainer.new()
	_page_root.name = "PageContent"
	_page_root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_page_root.add_theme_constant_override("separation", 14)
	scroll.add_child(_page_root)
	var footer := _label("Jogo offline • personagens e urnas fictícios • sem afiliação ou conexão com o TSE", 12, MUTED)
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	shell.add_child(footer)


func _build_header(parent: VBoxContainer) -> void:
	var panel := _card(PAPER)
	panel.custom_minimum_size = Vector2(0, 72)
	parent.add_child(panel)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	panel.add_child(row)
	var brand := VBoxContainer.new()
	brand.add_theme_constant_override("separation", 1)
	brand.custom_minimum_size = Vector2(245, 0)
	row.add_child(brand)
	var title := _label("BRASIL EM JOGO", 23, INK)
	title.add_theme_font_size_override("font_size", 23)
	brand.add_child(title)
	brand.add_child(_label("CIDADANIA • SIMULAÇÃO 2D", 10, GREEN))
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spacer)
	_location_label = _label("Campinas • SP", 14, INK)
	_location_label.custom_minimum_size = Vector2(170, 0)
	_location_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(_location_label)
	_scope_picker = OptionButton.new()
	_scope_picker.custom_minimum_size = Vector2(165, 40)
	for i: int in LEVELS.size():
		_scope_picker.add_item(str(LEVEL_TEXT[LEVELS[i]]), i)
	_scope_picker.item_selected.connect(_on_scope_selected)
	row.add_child(_scope_picker)
	var ballot_button := _button("VOTAR · DEMO", GREEN, Callable(self, "_open_elections"))
	ballot_button.custom_minimum_size = Vector2(140, 40)
	row.add_child(ballot_button)
	_year_label = _label("2026 · 1º trimestre", 14, GREEN)
	_year_label.custom_minimum_size = Vector2(130, 0)
	_year_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(_year_label)


func _build_sidebar(parent: HBoxContainer) -> void:
	var panel := _card(PAPER)
	panel.custom_minimum_size = Vector2(202, 0)
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	parent.add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	panel.add_child(column)
	column.add_child(_label("PAINEL DA COMUNIDADE", 11, MUTED))
	column.add_child(_nav_button("Visão geral", "dashboard"))
	column.add_child(_nav_button("Executivo", "executive"))
	column.add_child(_nav_button("Legislativo", "legislative"))
	column.add_child(_nav_button("Judiciário", "judiciary"))
	column.add_child(_nav_button("Comunidade", "community"))
	column.add_child(_nav_button("Eleições e urna", "elections"))
	column.add_child(_nav_button("Escolher cidade", "cities"))
	var note := _label("CENÁRIO FICTÍCIO\nAções simplificadas para fins educativos.", 11, MUTED)
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(Control.new())
	column.add_child(note)


func _nav_button(text: String, page: String) -> Button:
	var b := Button.new()
	b.text = text
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.custom_minimum_size = Vector2(170, 42)
	b.set_meta("navigation_page", page)
	b.add_to_group("page_navigation")
	b.pressed.connect(_show_page.bind(page))
	_apply_button_style(b, GREEN if page == _page else PAPER)
	return b


func _card(background: Color = PAPER) -> PanelContainer:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = BORDER
	style.set_border_width_all(1)
	style.set_corner_radius_all(14)
	style.set_content_margin_all(14)
	panel.add_theme_stylebox_override("panel", style)
	return panel


func _image_view(texture: Texture2D, extent: Vector2) -> TextureRect:
	var image := TextureRect.new()
	image.texture = texture
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	image.custom_minimum_size = extent
	image.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	image.clip_contents = true
	return image


func _label(text: String, font_size: int = 15, color: Color = INK) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label


func _button(text: String, accent: Color, action: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 42)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.pressed.connect(action)
	_apply_button_style(b, accent)
	return b


func _apply_button_style(button: Button, accent: Color) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = accent
	normal.border_color = accent.darkened(0.10) if accent == GREEN else BORDER
	normal.set_border_width_all(1)
	normal.set_corner_radius_all(10)
	normal.set_content_margin_all(9)
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = accent.lightened(0.08)
	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = accent.darkened(0.08)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("focus", normal)
	button.add_theme_color_override("font_color", PAPER if accent == GREEN else INK)
	button.add_theme_color_override("font_hover_color", PAPER if accent == GREEN else INK)
	button.add_theme_font_size_override("font_size", 14)


func _show_page(page: String) -> void:
	_page = page
	_is_ballot_page = page == "ballot"
	var active_page := "elections" if page == "ballot" or page == "results" else page
	for nav: Button in get_tree().get_nodes_in_group("page_navigation"):
		var nav_page := str(nav.get_meta("navigation_page", ""))
		_apply_button_style(nav, GREEN if nav_page == active_page else PAPER)
	_render_page()


func _render_page() -> void:
	if _page_root == null or sim == null:
		return
	for child: Node in _page_root.get_children():
		_page_root.remove_child(child)
		child.queue_free()
	_year_label.text = "%d · %sº trimestre" % [sim.year, str(sim.quarter)]
	_location_label.text = _scope_title()
	if _scope_picker != null:
		_scope_picker.select(LEVELS.find(sim.current_level))
	_status_label = null
	match _page:
		"dashboard": _build_dashboard()
		"executive": _build_executive()
		"legislative": _build_legislative()
		"judiciary": _build_judiciary()
		"community": _build_community()
		"elections": _build_elections()
		"cities": _build_cities()
		"ballot": _build_ballot()
		"results": _build_results()
		_: _build_dashboard()


func _scope_title() -> String:
	match sim.current_level:
		"municipal": return "%s • %s" % [sim.municipality_name, sim.state_uf]
		"state": return "%s • %s" % [str(_state_names.get(sim.state_uf, "Estado")), sim.state_uf]
		"federal": return "Brasil • União"
	return "Brasil"


func _heading(kicker: String, title: String, description: String) -> void:
	_page_root.add_child(_label(kicker.to_upper(), 11, GREEN))
	_page_root.add_child(_label(title, 25, INK))
	_page_root.add_child(_label(description, 14, MUTED))


func _build_dashboard() -> void:
	var scope: Dictionary = sim.current_scope()
	_heading("GOVERNO E VIDA PÚBLICA", _scope_title(), "Acompanhe decisões, serviços e prioridades que conectam a cidade, o estado e o país.")
	var stats := HBoxContainer.new()
	stats.add_theme_constant_override("separation", 10)
	_page_root.add_child(stats)
	_add_stat(stats, "ORÇAMENTO", CivicSimulationScript.format_money(int(scope.budget)), "recursos disponíveis", GREEN)
	_add_stat(stats, "APROVAÇÃO", "%d%%" % roundi(float(scope.approval)), "confiança pública", CORAL)
	_add_stat(stats, "PERÍODO", "%dº tri." % sim.quarter, "%d" % sim.year, INK)
	_add_stat(stats, "PROPOSTAS", str(sim.pending_proposals().size()), "na pauta legislativa", INK)
	var feature_row := HBoxContainer.new()
	feature_row.add_theme_constant_override("separation", 12)
	feature_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_page_root.add_child(feature_row)
	var map_card := _card()
	map_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	feature_row.add_child(map_card)
	var map_column := VBoxContainer.new()
	map_column.add_theme_constant_override("separation", 7)
	map_card.add_child(map_column)
	map_column.add_child(_label("MAPA DO BRASIL", 12, GREEN))
	map_column.add_child(_label("Clique em um estado para mudar o foco geográfico.", 13, MUTED))
	var map := BrasilMapScript.new()
	map.custom_minimum_size = Vector2(420, 300)
	map.set_selected_uf(sim.state_uf)
	map.state_selected.connect(_on_map_state_selected)
	map_column.add_child(map)
	map_column.add_child(_label("Limites estaduais: malha geográfica simplificada do IBGE.", 11, MUTED))
	var right := VBoxContainer.new()
	right.custom_minimum_size = Vector2(280, 0)
	right.add_theme_constant_override("separation", 10)
	feature_row.add_child(right)
	var action_card := _card(GREEN_PALE)
	right.add_child(action_card)
	var action_column := VBoxContainer.new()
	action_column.add_theme_constant_override("separation", 8)
	action_card.add_child(action_column)
	action_column.add_child(_label("CICLO DE GESTÃO", 12, GREEN))
	action_column.add_child(_label("Cada trimestre atualiza receitas, despesas e a reação da população.", 14, INK))
	var advance := _button("Avançar um trimestre", GREEN, _advance_turn)
	action_column.add_child(advance)
	var location_button := _button("Escolher outro município", PAPER, Callable(self, "_show_page").bind("cities"))
	action_column.add_child(location_button)
	var community_card := _card()
	right.add_child(community_card)
	var community_col := VBoxContainer.new()
	community_col.add_theme_constant_override("separation", 7)
	community_card.add_child(community_col)
	community_col.add_child(_label("TERMÔMETRO DA COMUNIDADE", 12, GREEN))
	for group: Dictionary in sim.community_groups():
		community_col.add_child(_label(str(group.name) + " · " + str(group.need), 11, MUTED))
		community_col.add_child(_meter(float(group.satisfaction), GREEN))
	var powers_card := _card()
	_page_root.add_child(powers_card)
	var powers_row := HBoxContainer.new()
	powers_row.add_theme_constant_override("separation", 14)
	powers_card.add_child(powers_row)
	powers_row.add_child(_image_view(POWERS_ART, Vector2(250, 167)))
	var powers_copy := VBoxContainer.new()
	powers_copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	powers_copy.add_theme_constant_override("separation", 7)
	powers_row.add_child(powers_copy)
	powers_copy.add_child(_label("TRÊS PODERES, COMPETÊNCIAS DISTINTAS", 12, GREEN))
	powers_copy.add_child(_label("O Executivo administra e executa políticas; o Legislativo debate e fiscaliza; o Judiciário revisa conflitos com independência.", 14, INK))
	var branches := HBoxContainer.new()
	branches.add_theme_constant_override("separation", 10)
	_page_root.add_child(branches)
	var executive_name := "Presidência e ministérios"
	var legislative_name := "Congresso Nacional"
	var judicial_name := "Justiça federal e demais ramos"
	var judicial_detail := "Analisa conflitos conforme a competência de cada ramo judicial."
	if sim.current_level == "municipal":
		executive_name = "Prefeitura"
		legislative_name = "Câmara Municipal"
		judicial_name = "Justiça estadual/federal"
		judicial_detail = "Não há Judiciário municipal; órgãos estaduais ou federais podem apreciar atos locais."
	elif sim.current_level == "state":
		executive_name = "Governo estadual"
		legislative_name = "Assembleia Legislativa"
		judicial_name = "Justiça estadual/federal"
		judicial_detail = "Tribunais estaduais e ramos federais atuam dentro de suas competências."
	_add_branch(branches, "01", executive_name, "Implementa políticas, organiza serviços e administra orçamento.", "executive")
	_add_branch(branches, "02", legislative_name, "Debate e vota propostas, normas e prioridades.", "legislative")
	_add_branch(branches, "03", judicial_name, judicial_detail, "judiciary")
	var alert := _card(Color("f3e9dc"))
	_page_root.add_child(alert)
	var alert_col := VBoxContainer.new()
	alert_col.add_child(_label("ÚLTIMO ACONTECIMENTO", 11, CORAL))
	if sim.event_log.is_empty():
		alert_col.add_child(_label("A cidade começa um novo ciclo. Escolha uma política pública ou avance o trimestre para ver como a situação evolui.", 13, INK))
	else:
		var latest: Dictionary = sim.event_log[0]
		alert_col.add_child(_label(str(latest.title), 14, INK))
		alert_col.add_child(_label(str(latest.description), 13, MUTED))
	alert.add_child(alert_col)


func _add_stat(parent: HBoxContainer, caption: String, value: String, detail: String, accent: Color) -> void:
	var card := _card()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(card)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 3)
	card.add_child(column)
	column.add_child(_label(caption, 10, MUTED))
	column.add_child(_label(value, 22, accent))
	column.add_child(_label(detail, 11, MUTED))


func _add_branch(parent: HBoxContainer, number: String, title: String, detail: String, page: String) -> void:
	var card := _card()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(card)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	card.add_child(column)
	column.add_child(_label("PODER " + number, 10, GREEN))
	column.add_child(_label(title, 18, INK))
	column.add_child(_label(detail, 12, MUTED))
	column.add_child(_button("Abrir painel", GREEN, Callable(self, "_show_page").bind(page)))


func _build_executive() -> void:
	_heading("PODER EXECUTIVO", "Gestão de políticas públicas", "Escolha prioridades da esfera selecionada. As despesas afetam o orçamento local; os serviços e a confiança mudam ao longo do tempo.")
	var scope: Dictionary = sim.current_scope()
	var banner := _card(GREEN_PALE)
	_page_root.add_child(banner)
	banner.add_child(_label("Disponível: %s   ·   Confiança pública: %d%%" % [CivicSimulationScript.format_money(int(scope.budget)), roundi(float(scope.approval))], 15, INK))
	for policy: Dictionary in sim.policy_options():
		var card := _card()
		_page_root.add_child(card)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		card.add_child(row)
		var text_col := VBoxContainer.new()
		text_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		text_col.add_child(_label(str(policy.title), 17, INK))
		text_col.add_child(_label(str(policy.description), 12, MUTED))
		text_col.add_child(_label("Custo previsto: " + CivicSimulationScript.format_money(int(policy.cost)), 12, GREEN))
		row.add_child(text_col)
		var activate := _button("Executar ação", GREEN, Callable(self, "_execute_policy").bind(str(policy.id)))
		activate.custom_minimum_size = Vector2(150, 42)
		row.add_child(activate)
		for key: String in policy.effects:
			var service_name: String = str(SERVICE_LABELS.get(key, key))
			var stats_text := _label("Impacto pretendido: " + service_name, 11, MUTED)
			card.add_child(stats_text)
	_add_status()


func _build_legislative() -> void:
	_heading("PODER LEGISLATIVO", "Debate, votação e fiscalização", "Avalie propostas fictícias para a esfera atual. Aprovar uma norma consome parte do orçamento e cria uma pauta para a fiscalização pública.")
	var note := _card(GREEN_PALE)
	_page_root.add_child(note)
	note.add_child(_label("No Brasil, cada esfera tem competências próprias. Esta versão simplifica o processo deliberativo para tornar as escolhas compreensíveis.", 13, INK))
	var proposals := sim.pending_proposals()
	if proposals.is_empty():
		_page_root.add_child(_card())
		return
	for proposal: Dictionary in proposals:
		var card := _card()
		_page_root.add_child(card)
		var col := VBoxContainer.new()
		col.add_theme_constant_override("separation", 7)
		card.add_child(col)
		col.add_child(_label(str(proposal.title), 17, INK))
		col.add_child(_label(str(proposal.description), 13, MUTED))
		var row := HBoxContainer.new()
		row.add_child(_label("Impacto simulado: " + str(proposal.effect), 12, GREEN))
		col.add_child(row)
		col.add_child(_label("Compromete " + CivicSimulationScript.format_money(int(proposal.cost)) + " do orçamento atual.", 12, MUTED))
		col.add_child(_button("Debater e aprovar", GREEN, Callable(self, "_pass_proposal").bind(str(proposal.id))))
	var laws := sim.active_laws()
	if not laws.is_empty():
		_page_root.add_child(_label("NORMAS E PAUTAS", 12, GREEN))
		for law: Dictionary in laws:
			_page_root.add_child(_label("• %s — %s" % [law.title, law.status], 13, INK))
	_add_status()


func _build_judiciary() -> void:
	var eyebrow := "PODER JUDICIÁRIO"
	var page_title := "Revisão e solução de conflitos"
	var page_description := "A revisão simulada considera competência, processo e direitos. Ela não substitui os tribunais nem representa um julgamento jurídico real."
	var scope_message := "Na realidade, o Judiciário é independente: não administra o orçamento nem escolhe políticas do Executivo. Aqui você acompanha uma revisão educativa de normas em vigor."
	if sim.current_level == "municipal":
		eyebrow = "JUSTIÇA ESTADUAL/FEDERAL"
		page_title = "Revisão de atos municipais"
		page_description = "No Brasil não existe Poder Judiciário municipal; a atuação judicial local ocorre por órgãos estaduais ou federais, conforme a competência."
		scope_message = "Este painel municipal representa, de forma educativa, uma possível revisão por órgão judicial competente — não um tribunal da prefeitura."
	elif sim.current_level == "state":
		eyebrow = "JUSTIÇA ESTADUAL E FEDERAL"
		page_description = "A atuação de cada ramo depende de competência e matéria. A revisão aqui é uma simplificação educativa, não um julgamento real."
	_heading(eyebrow, page_title, page_description)
	var scope_note := _card(GREEN_PALE)
	_page_root.add_child(scope_note)
	scope_note.add_child(_label(scope_message, 13, INK))
	var laws := sim.active_laws()
	var found := false
	for law: Dictionary in laws:
		if str(law.status) != "Em vigor":
			continue
		found = true
		var card := _card()
		_page_root.add_child(card)
		var col := VBoxContainer.new()
		col.add_theme_constant_override("separation", 8)
		card.add_child(col)
		col.add_child(_label(str(law.title), 17, INK))
		col.add_child(_label("Pauta: examinar a compatibilidade da norma com a competência e os direitos envolvidos.", 13, MUTED))
		var row := HBoxContainer.new()
		col.add_child(row)
		row.add_child(_button("Manter após revisão", GREEN, Callable(self, "_review_law").bind(str(law.id), true)))
		row.add_child(_button("Suspender na simulação", Color("eadcd2"), Callable(self, "_review_law").bind(str(law.id), false)))
	if not found:
		var empty := _card()
		_page_root.add_child(empty)
		empty.add_child(_label("Não há norma em vigor aguardando revisão. Aprove uma proposta no Legislativo para abrir uma pauta.", 14, MUTED))
	_add_status()


func _build_community() -> void:
	_heading("VIDA PÚBLICA", "Demandas e confiança da população", "A comunidade não é um número só: diferentes grupos podem sentir efeitos distintos conforme os serviços, as leis e as escolhas de orçamento.")
	var community_intro := _card(GREEN_PALE)
	_page_root.add_child(community_intro)
	var community_row := HBoxContainer.new()
	community_row.add_theme_constant_override("separation", 14)
	community_intro.add_child(community_row)
	community_row.add_child(_image_view(COMMUNITY_ART, Vector2(260, 173)))
	var community_copy := VBoxContainer.new()
	community_copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	community_copy.add_theme_constant_override("separation", 7)
	community_row.add_child(community_copy)
	community_copy.add_child(_label("UMA COMUNIDADE, MUITAS PRIORIDADES", 12, GREEN))
	community_copy.add_child(_label("Os grupos têm necessidades e interesses próprios. As políticas e os serviços podem gerar impactos diferentes, acompanhados pela satisfação percebida.", 14, INK))
	for group: Dictionary in sim.community_groups():
		var card := _card()
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_page_root.add_child(card)
		var col := VBoxContainer.new()
		col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		col.add_theme_constant_override("separation", 6)
		card.add_child(col)
		var row := HBoxContainer.new()
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var group_name := _label(str(group.name), 16, INK)
		group_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(group_name)
		var spacer := Control.new()
		spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(spacer)
		var satisfaction := _label("%d%% de satisfação percebida" % roundi(float(group.satisfaction)), 12, GREEN)
		satisfaction.custom_minimum_size = Vector2(190, 0)
		satisfaction.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		row.add_child(satisfaction)
		col.add_child(row)
		col.add_child(_label("Prioridades: " + str(group.need), 12, MUTED))
		col.add_child(_meter(float(group.satisfaction), GREEN))
	var event_title := _label("JORNAL DA COMUNIDADE", 12, GREEN)
	_page_root.add_child(event_title)
	if sim.event_log.is_empty():
		var empty := _card()
		_page_root.add_child(empty)
		empty.add_child(_label("Os acontecimentos aparecem quando o tempo avança e quando leis ou políticas são colocadas em prática.", 13, MUTED))
	else:
		var first_event := true
		for event: Dictionary in sim.event_log:
			var card := _card()
			card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			_page_root.add_child(card)
			var row := HBoxContainer.new()
			row.add_theme_constant_override("separation", 12)
			if first_event:
				var illustration := VBoxContainer.new()
				illustration.add_child(_image_view(PUBLIC_CHALLENGE_ART, Vector2(220, 147)))
				illustration.add_child(_label("Cena ilustrativa fictícia", 10, MUTED))
				row.add_child(illustration)
				first_event = false
			var col := VBoxContainer.new()
			col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			col.add_child(_label(str(event.title) + " · %d/T%d" % [int(event.year), int(event.quarter)], 13, INK))
			col.add_child(_label(str(event.description), 12, MUTED))
			row.add_child(col)
			card.add_child(row)


func _build_elections() -> void:
	_heading("ELEIÇÕES FICTÍCIAS", "Pratique o voto na urna de demonstração", "Escolha uma esfera para iniciar a votação. Você poderá digitar um número, conferir a candidatura, corrigir, votar em branco e confirmar.")
	var notice := _card(Color("f3e9dc"))
	_page_root.add_child(notice)
	notice.add_child(_label("AVISO: esta é uma urna inventada para educação e entretenimento. Não coleta nem registra um voto eleitoral real; não é afiliada ou conectada ao TSE e não tem validade eleitoral.", 13, INK))
	var elections: Array[Dictionary] = [
		{"level": "municipal", "title": "Eleição municipal", "roles": "Vereador · Prefeito", "when": "Ciclo municipal fictício"},
		{"level": "state", "title": "Eleição estadual", "roles": "Deputado estadual · Governador · Senado", "when": "Ciclo geral fictício"},
		{"level": "federal", "title": "Eleição nacional", "roles": "Deputado federal · Senado · Presidente", "when": "Ciclo geral fictício"}
	]
	for election: Dictionary in elections:
		var card := _card()
		_page_root.add_child(card)
		var col := VBoxContainer.new()
		col.add_theme_constant_override("separation", 7)
		card.add_child(col)
		col.add_child(_label(str(election.title), 18, INK))
		col.add_child(_label(str(election.roles), 13, MUTED))
		col.add_child(_label(str(election.when) + " · Candidaturas e partidos inventados", 11, GREEN))
		col.add_child(_button("Começar votação fictícia", GREEN, Callable(self, "_start_ballot").bind(str(election.level))))
	if not sim.last_election.is_empty():
		var prev := _card(GREEN_PALE)
		_page_root.add_child(prev)
		prev.add_child(_label("ÚLTIMA APURAÇÃO", 11, GREEN))
		prev.add_child(_label(str(sim.last_election.get("title", "Eleição simulada concluída")), 14, INK))
		prev.add_child(_button("Ver resultados", PAPER, Callable(self, "_show_page").bind("results")))
	_add_status()


func _build_cities() -> void:
	_heading("MAPA E TERRITÓRIO", "Escolha um município real", "Os nomes de municípios e estados vêm da API oficial de localidades do IBGE e ficam salvos dentro do jogo para uso offline.")
	var card := _card()
	_page_root.add_child(card)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 9)
	card.add_child(col)
	col.add_child(_label("1. Estado", 13, INK))
	_city_state_filter = OptionButton.new()
	for state: Dictionary in _states:
		_city_state_filter.add_item("%s · %s" % [state.get("name", ""), state.get("uf", "")])
		_city_state_filter.set_item_metadata(_city_state_filter.item_count - 1, str(state.get("uf", "")))	
	var selected_index := 0
	for i: int in _states.size():
		if str(_states[i].get("uf", "")) == sim.state_uf:
			selected_index = i
	_city_state_filter.select(selected_index)
	_city_state_filter.item_selected.connect(_on_city_state_selected)
	col.add_child(_city_state_filter)
	col.add_child(_label("2. Digite o nome da cidade", 13, INK))
	_city_search = LineEdit.new()
	_city_search.placeholder_text = "Ex.: Campinas, Recife, Manaus..."
	_city_search.custom_minimum_size = Vector2(0, 42)
	_city_search.text_changed.connect(_refresh_city_results)
	col.add_child(_city_search)
	_search_results = VBoxContainer.new()
	_search_results.add_theme_constant_override("separation", 6)
	col.add_child(_search_results)
	_refresh_city_results(sim.municipality_name)
	_add_status()


func _refresh_city_results(query: String) -> void:
	if _search_results == null:
		return
	for child: Node in _search_results.get_children():
		_search_results.remove_child(child)
		child.queue_free()
	var term := query.strip_edges().to_lower()
	var uf := sim.state_uf
	if _city_state_filter != null and _city_state_filter.selected >= 0:
		uf = str(_city_state_filter.get_item_metadata(_city_state_filter.selected))
	var match_count := 0
	for city: Dictionary in _municipalities:
		if str(city.uf) != uf:
			continue
		if not term.is_empty() and not str(city.name).to_lower().contains(term):
			continue
		var display := "%s · %s" % [city.name, city.uf]
		_search_results.add_child(_button(display, PAPER, Callable(self, "_select_city").bind(int(city.id), str(city.name), str(city.uf))))
		match_count += 1
		if match_count >= 7:
			break
	if match_count == 0:
		_search_results.add_child(_label("Nenhum município encontrado nesse estado. Ajuste a busca ou o filtro.", 12, MUTED))


func _on_city_state_selected(_index: int) -> void:
	_refresh_city_results(_city_search.text if _city_search != null else "")


func _select_city(city_id: int, city_name: String, uf: String) -> void:
	sim.set_location(city_id, city_name, uf)
	if sim.current_level == "municipal":
		_show_page("dashboard")
	else:
		_render_page()


func _build_ballot() -> void:
	if _ballot_index >= _ballot_jobs.size():
		_finish_election()
		return
	var role := _ballot_jobs[_ballot_index]
	var digits_required := _digits_for_role(role)
	_heading("URNA DE DEMONSTRAÇÃO", "Voto para " + role, "Etapa %d de %d · Digite os números, confira a pessoa candidata e confirme. Use Corrige para recomeçar este cargo." % [_ballot_index + 1, _ballot_jobs.size()])
	var disclaimer := _card(Color("f3e9dc"))
	_page_root.add_child(disclaimer)
	disclaimer.add_child(_label("SIMULAÇÃO EDUCATIVA: urna fictícia, candidaturas inventadas, sem conexão ou afiliação ao TSE e sem validade eleitoral.", 12, INK))
	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 12)
	_page_root.add_child(columns)
	var input_card := _card()
	input_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columns.add_child(input_card)
	var input_col := VBoxContainer.new()
	input_col.add_theme_constant_override("separation", 9)
	input_card.add_child(input_col)
	input_col.add_child(_label("CARGO · " + role.to_upper(), 11, GREEN))
	input_col.add_child(_label("Número da candidatura fictícia · %d dígitos" % digits_required, 13, MUTED))
	_ballot_line_edit = LineEdit.new()
	_ballot_line_edit.max_length = digits_required
	_ballot_line_edit.custom_minimum_size = Vector2(0, 48)
	_ballot_line_edit.placeholder_text = "Digite o número"
	_ballot_line_edit.text_changed.connect(_on_ballot_text_changed)
	input_col.add_child(_ballot_line_edit)
	_ballot_number_label = _label("— — — — —", 22, INK)
	_ballot_number_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	input_col.add_child(_ballot_number_label)
	var pad := GridContainer.new()
	pad.columns = 3
	pad.add_theme_constant_override("h_separation", 7)
	pad.add_theme_constant_override("v_separation", 7)
	for digit: String in ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"]:
		var digit_button := _button(digit, Color("eaf0e9"), Callable(self, "_append_digit").bind(digit))
		digit_button.custom_minimum_size = Vector2(72, 42)
		pad.add_child(digit_button)
	input_col.add_child(pad)
	var action_row := HBoxContainer.new()
	input_col.add_child(action_row)
	action_row.add_child(_button("Corrige", Color("eadcd2"), _correct_ballot))
	action_row.add_child(_button("Voto em branco", Color("eaf0e9"), _blank_ballot))
	input_col.add_child(_button("CONFIRMAR VOTO", GREEN, _confirm_ballot))
	_ballot_status = _label("Aguardando digitação.", 12, MUTED)
	input_col.add_child(_ballot_status)
	var preview_card := _card(GREEN_PALE)
	preview_card.custom_minimum_size = Vector2(250, 0)
	columns.add_child(preview_card)
	var preview := VBoxContainer.new()
	preview.alignment = BoxContainer.ALIGNMENT_CENTER
	preview.add_theme_constant_override("separation", 8)
	preview_card.add_child(preview)
	var machine := TextureRect.new()
	machine.texture = BALLOT_MACHINE
	machine.custom_minimum_size = Vector2(180, 205)
	machine.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	preview.add_child(machine)
	preview.add_child(_label("CONFERÊNCIA DO VOTO", 11, GREEN))
	_ballot_portrait = TextureRect.new()
	_ballot_portrait.custom_minimum_size = Vector2(112, 112)
	_ballot_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	preview.add_child(_ballot_portrait)
	_ballot_candidate_label = _label("Aguardando número", 16, INK)
	_ballot_candidate_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	preview.add_child(_ballot_candidate_label)
	_ballot_candidate_detail = _label("Candidatura fictícia", 12, MUTED)
	_ballot_candidate_detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	preview.add_child(_ballot_candidate_detail)
	_add_status()


func _digits_for_role(role: String) -> int:
	if role == "Deputado federal":
		return 4
	if role == "Vereador" or role == "Deputado estadual":
		return 5
	if role == "Senador":
		return 3
	return 2


func _candidate_code(candidate: Dictionary, role: String) -> String:
	var prefix := str(candidate.prefix)
	if role == "Vereador" or role == "Deputado estadual" or role == "Deputado federal":
		if role == "Deputado federal":
			return prefix.left(1) + "123"
		return prefix + "123"
	if role == "Senador":
		return prefix + "1"
	return prefix


func _current_candidate() -> Dictionary:
	var role := _ballot_jobs[_ballot_index] if _ballot_index < _ballot_jobs.size() else ""
	for candidate: Dictionary in CANDIDATES:
		if _candidate_code(candidate, role) == _ballot_entry:
			return candidate
	return {}


func _on_ballot_text_changed(value: String) -> void:
	var filtered := ""
	for index: int in range(value.length()):
		var character := value.substr(index, 1)
		if "0123456789".contains(character):
			filtered += character
	if _ballot_line_edit != null and _ballot_line_edit.text != filtered:
		_ballot_line_edit.text = filtered
		_ballot_line_edit.caret_column = filtered.length()
	_ballot_entry = filtered
	_ballot_white_pending = false
	_refresh_ballot_preview()


func _append_digit(digit: String) -> void:
	if _ballot_line_edit == null:
		return
	var maximum := _digits_for_role(_ballot_jobs[_ballot_index])
	if _ballot_entry.length() >= maximum:
		return
	_ballot_line_edit.text = _ballot_entry + digit
	_ballot_line_edit.caret_column = _ballot_line_edit.text.length()
	_ballot_entry = _ballot_line_edit.text
	_refresh_ballot_preview()


func _correct_ballot() -> void:
	_ballot_entry = ""
	_ballot_white_pending = false
	if _ballot_line_edit != null:
		_ballot_line_edit.text = ""
	_refresh_ballot_preview()
	if _ballot_status != null:
		_ballot_status.text = "Número apagado. Digite novamente."


func _blank_ballot() -> void:
	_ballot_entry = ""
	_ballot_white_pending = true
	if _ballot_line_edit != null:
		_ballot_line_edit.text = ""
	_refresh_ballot_preview()
	if _ballot_status != null:
		_ballot_status.text = "Voto em branco selecionado. Confirme para registrar na simulação."


func _refresh_ballot_preview() -> void:
	if _ballot_number_label == null or _ballot_candidate_label == null:
		return
	var display := _ballot_entry
	while display.length() < 5:
		display += " ·"
	_ballot_number_label.text = display
	if _ballot_white_pending:
		_ballot_portrait.texture = null
		_ballot_candidate_label.text = "VOTO EM BRANCO"
		_ballot_candidate_detail.text = "Escolha fictícia"
		return
	var candidate := _current_candidate()
	if candidate.is_empty():
		_ballot_portrait.texture = null
		_ballot_candidate_label.text = "Aguardando número"
		_ballot_candidate_detail.text = "Confira o número e a candidatura"
		return
	_ballot_portrait.texture = candidate.texture
	_ballot_candidate_label.text = str(candidate.name)
	_ballot_candidate_detail.text = "%s\n%s" % [str(candidate.party), str(candidate.promise)]


func _confirm_ballot() -> void:
	if _ballot_white_pending:
		_ballot_choices[_ballot_jobs[_ballot_index]] = "BRANCO"
	elif not _current_candidate().is_empty():
		_ballot_choices[_ballot_jobs[_ballot_index]] = str(_current_candidate().name)
	else:
		if _ballot_status != null:
			_ballot_status.text = "Número não reconhecido. Corrija ou selecione voto em branco."
		return
	_ballot_index += 1
	_ballot_entry = ""
	_ballot_white_pending = false
	if _ballot_index >= _ballot_jobs.size():
		_finish_election()
	else:
		_render_page()


func _start_ballot(level: String) -> void:
	sim.set_level(level)
	match level:
		"municipal": _ballot_jobs = ["Vereador", "Prefeito"]
		"state": _ballot_jobs = ["Deputado estadual", "Senador", "Governador"]
		"federal": _ballot_jobs = ["Deputado federal", "Senador", "Presidente da República"]
	_ballot_index = 0
	_ballot_entry = ""
	_ballot_white_pending = false
	_ballot_choices.clear()
	_election_result.clear()
	_show_page("ballot")


func _finish_election() -> void:
	var jobs: Array = []
	var rng := RandomNumberGenerator.new()
	rng.seed = int((sim.year * 1009 + sim.quarter * 97 + sim.municipality_id + sim.current_level.hash()) & 0x7fffffff)
	var executive_winner := ""
	for role: String in _ballot_jobs:
		var entries: Array[Dictionary] = []
		var sum := 0.0
		var weights: Array[float] = []
		var human_choice := str(_ballot_choices.get(role, "BRANCO"))
		for candidate: Dictionary in CANDIDATES:
			var weight := float(candidate.strength) + (float(sim.current_scope().approval) - 50.0) * 0.10 + rng.randf_range(-4.0, 4.0)
			if str(candidate.name) == human_choice:
				weight += 3.5
			weights.append(maxf(2.0, weight))
			sum += maxf(2.0, weight)
		var winner := ""
		for index: int in CANDIDATES.size():
			var candidate: Dictionary = CANDIDATES[index]
			var share := weights[index] / sum * 100.0
			entries.append({"name": candidate.name, "party": candidate.party, "share": share})
			if index == 0 or share > float(entries[0].get("share", 0.0)):
				winner = str(candidate.name)
		if role in ["Prefeito", "Governador", "Presidente da República"] and executive_winner.is_empty():
			executive_winner = winner
		jobs.append({"role": role, "winner": winner, "candidates": entries, "turnout": rng.randi_range(72, 88)})
	_election_result = {"title": "Apuração fictícia · %s" % LEVEL_TEXT[sim.current_level], "offices": jobs, "executive_winner": executive_winner, "turnout": jobs[0].turnout if not jobs.is_empty() else 0}
	sim.record_election(_election_result)
	_ballot_choices.clear()
	_show_page("results")


func _build_results() -> void:
	_heading("APURAÇÃO SIMULADA", "Resultado da votação fictícia", "Os números abaixo foram calculados pelo jogo. A escolha individual não é salva: voto é secreto, e esta sessão não representa uma eleição real.")
	var header := _card(GREEN_PALE)
	_page_root.add_child(header)
	header.add_child(_label(str(_election_result.get("title", sim.last_election.get("title", "Eleição simulada"))), 16, INK))
	for office: Dictionary in _election_result.get("offices", sim.last_election.get("offices", [])):
		var card := _card()
		_page_root.add_child(card)
		var col := VBoxContainer.new()
		col.add_theme_constant_override("separation", 6)
		card.add_child(col)
		col.add_child(_label(str(office.role) + " · eleito na simulação: " + str(office.winner), 16, GREEN))
		for candidate: Dictionary in office.candidates:
			var row := HBoxContainer.new()
			row.add_child(_label(str(candidate.name) + " · " + str(candidate.party), 12, INK))
			var spacer := Control.new()
			spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			row.add_child(spacer)
			row.add_child(_label("%.1f%%" % float(candidate.share), 13, GREEN if str(candidate.name) == str(office.winner) else MUTED))
			col.add_child(row)
			col.add_child(_meter(float(candidate.share), GREEN if str(candidate.name) == str(office.winner) else BORDER))
		col.add_child(_label("Participação fictícia estimada: %d%%" % int(office.get("turnout", 0)), 11, MUTED))
	var actions := HBoxContainer.new()
	_page_root.add_child(actions)
	actions.add_child(_button("Nova votação de demonstração", GREEN, Callable(self, "_show_page").bind("elections")))
	actions.add_child(_button("Voltar ao painel", PAPER, Callable(self, "_show_page").bind("dashboard")))
	_add_status()


func _build_status_page(title: String, description: String) -> void:
	_heading("MUNDO CONECTADO", title, description)


func _add_status() -> void:
	if _status_label != null:
		_page_root.add_child(_status_label)


func _set_status(message: String, success: bool = true) -> void:
	if _status_label == null:
		_status_label = _label("", 13, GREEN if success else CORAL)
	_status_label.text = message
	_status_label.add_theme_color_override("font_color", GREEN if success else CORAL)


func _meter(value: float, color: Color) -> ProgressBar:
	var meter := ProgressBar.new()
	meter.custom_minimum_size = Vector2(0, 12)
	meter.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	meter.min_value = 0.0
	meter.max_value = 100.0
	meter.value = clampf(value, 0.0, 100.0)
	meter.show_percentage = false
	var background := StyleBoxFlat.new()
	background.bg_color = Color("e8ece4")
	background.set_corner_radius_all(6)
	var fill := StyleBoxFlat.new()
	fill.bg_color = color
	fill.set_corner_radius_all(6)
	meter.add_theme_stylebox_override("background", background)
	meter.add_theme_stylebox_override("fill", fill)
	return meter


func _on_scope_selected(index: int) -> void:
	if index >= 0 and index < LEVELS.size():
		sim.set_level(LEVELS[index])
		_render_page()


func _on_map_state_selected(uf: String, _name: String) -> void:
	sim.state_uf = uf
	sim.save_state()
	_location_label.text = _scope_title()
	if _page == "cities":
		_refresh_city_results(_city_search.text if _city_search != null else "")
	else:
		_render_page()


func _open_elections() -> void:
	_show_page("elections")


func _execute_policy(id: String) -> void:
	var result: Dictionary = sim.apply_policy(id)
	_set_status(str(result.message), bool(result.ok))
	_render_page()
	_set_status(str(result.message), bool(result.ok))


func _pass_proposal(id: String) -> void:
	var result: Dictionary = sim.pass_proposal(id)
	_render_page()
	_set_status(str(result.message), bool(result.ok))


func _review_law(id: String, keep: bool) -> void:
	var result: Dictionary = sim.judge_law(id, keep)
	_render_page()
	_set_status(str(result.message), bool(result.ok))


func _advance_turn() -> void:
	var result: Dictionary = sim.advance_quarter()
	_render_page()
	if result.messages is Array and not result.messages.is_empty():
		_set_status(str(result.messages[0]), true)


func _on_locale_changed(_locale: String) -> void:
	pass
