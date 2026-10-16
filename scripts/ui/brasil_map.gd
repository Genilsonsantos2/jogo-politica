extends Control
class_name BrasilMapView

signal state_selected(uf: String, state_name: String)

const GEOJSON_PATH := "res://data/brazil_states.geojson"
const BASEMAP := preload("res://assets/game/brazil_states_basemap.png")
const SEA := Color("e8ede6")
const SELECTED := Color("6fb9a4")
const INK := Color("28443d")

var selected_uf := "SP"
var _features: Array[Dictionary] = []
var _bounds := Rect2(-74.0, -34.0, 40.0, 40.0)


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_load_features()
	resized.connect(queue_redraw)
	queue_redraw()


func set_selected_uf(uf: String) -> void:
	selected_uf = uf
	queue_redraw()


func _load_features() -> void:
	var file := FileAccess.open(GEOJSON_PATH, FileAccess.READ)
	if file == null:
		push_error("BrasilMapView: não foi possível abrir a malha de estados do IBGE.")
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if not parsed is Dictionary:
		push_error("BrasilMapView: GeoJSON inválido.")
		return
	var raw_features: Variant = parsed.get("features", [])
	if not raw_features is Array:
		return
	var min_x := 180.0
	var max_x := -180.0
	var min_y := 90.0
	var max_y := -90.0
	for raw: Variant in raw_features:
		if not raw is Dictionary:
			continue
		var feature: Dictionary = raw
		var geometry: Dictionary = feature.get("geometry", {})
		var rings := _rings(geometry)
		if rings.is_empty():
			continue
		var normalized: Array = []
		for ring: Array in rings:
			var points: Array[Vector2] = []
			for point: Variant in ring:
				if point is Array and point.size() >= 2:
					var geo := Vector2(float(point[0]), float(point[1]))
					points.append(geo)
					min_x = minf(min_x, geo.x)
					max_x = maxf(max_x, geo.x)
					min_y = minf(min_y, geo.y)
					max_y = maxf(max_y, geo.y)
			if points.size() > 3 and points[0].distance_to(points[points.size() - 1]) < 0.000001:
				points.pop_back()
			if points.size() >= 3:
				normalized.append(points)
		if normalized.is_empty():
			continue
		var properties: Dictionary = feature.get("properties", {})
		_features.append({"uf": str(properties.get("uf", "")), "name": str(properties.get("name", "")), "rings": normalized})
	if not _features.is_empty():
		_bounds = Rect2(min_x, min_y, maxf(0.01, max_x - min_x), maxf(0.01, max_y - min_y))


func _rings(geometry: Dictionary) -> Array:
	var result: Array = []
	var kind := str(geometry.get("type", ""))
	var coordinates: Variant = geometry.get("coordinates", [])
	if kind == "Polygon" and coordinates is Array:
		for ring: Variant in coordinates:
			if ring is Array:
				result.append(ring)
	elif kind == "MultiPolygon" and coordinates is Array:
		for polygon: Variant in coordinates:
			if polygon is Array:
				for ring: Variant in polygon:
					if ring is Array:
						result.append(ring)
	return result


func _map_transform() -> Dictionary:
	var margin := Vector2(20.0, 18.0)
	var available := Vector2(maxf(1.0, size.x - margin.x * 2.0), maxf(1.0, size.y - margin.y * 2.0))
	var scale_x := available.x / _bounds.size.x
	var scale_y := available.y / _bounds.size.y
	var scale := minf(scale_x, scale_y)
	var drawn := Vector2(_bounds.size.x * scale, _bounds.size.y * scale)
	var offset := (size - drawn) * 0.5
	return {"scale": scale, "offset": offset}


func _project(point: Vector2, transform: Dictionary) -> Vector2:
	var scale := float(transform.scale)
	var offset: Vector2 = transform.offset
	return Vector2(offset.x + (point.x - _bounds.position.x) * scale, offset.y + (_bounds.end.y - point.y) * scale)


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), SEA, true)
	if _features.is_empty():
		draw_string(ThemeDB.fallback_font, Vector2(16, 28), "Mapa indisponível", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, INK)
		return
	var transform := _map_transform()
	var map_scale := float(transform.scale)
	var map_offset: Vector2 = transform.offset
	var map_size := Vector2(_bounds.size.x * map_scale, _bounds.size.y * map_scale)
	draw_texture_rect(BASEMAP, Rect2(map_offset, map_size), false)
	for feature: Dictionary in _features:
		var is_selected := str(feature.uf) == selected_uf
		for ring: Array in feature.rings:
			var points := PackedVector2Array()
			for geo: Vector2 in ring:
				points.append(_project(geo, transform))
			if points.size() >= 3 and is_selected:
				var closed := points.duplicate()
				closed.append(points[0])
				draw_polyline(closed, SELECTED, 3.0, true)
		var center := _feature_center(feature, transform)
		var uf_text := str(feature.uf)
		if not uf_text.is_empty():
			draw_string(ThemeDB.fallback_font, center + Vector2(-8, 4), uf_text, HORIZONTAL_ALIGNMENT_LEFT, 30.0, 11, INK)


func _feature_center(feature: Dictionary, transform: Dictionary) -> Vector2:
	var largest: Array = []
	for ring: Array in feature.rings:
		if ring.size() > largest.size():
			largest = ring
	if largest.is_empty():
		return Vector2.ZERO
	var total := Vector2.ZERO
	for point: Vector2 in largest:
		total += _project(point, transform)
	return total / float(largest.size())


func _gui_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed):
		return
	var mouse_event := event as InputEventMouseButton
	var transform := _map_transform()
	var local_point: Vector2 = mouse_event.position
	for feature: Dictionary in _features:
		for ring: Array in feature.rings:
			var polygon := PackedVector2Array()
			for geo: Vector2 in ring:
				polygon.append(_project(geo, transform))
			if polygon.size() >= 3 and Geometry2D.is_point_in_polygon(local_point, polygon):
				selected_uf = str(feature.uf)
				queue_redraw()
				state_selected.emit(selected_uf, str(feature.name))
				accept_event()
				return
