extends Control

const DRAGGABLE_ITEM_SCENE := preload("res://scenes/draggable_item.tscn")

const OCEAN_COLOR := Color("#38bdf8")
const WAVE_COLOR := Color(1, 1, 1, 0.22)
const WAVE_RING_COLOR := Color(1, 1, 1, 0.45)
const FOAM_COLOR := Color(1, 1, 1, 0.75)
const SAND_RIM_COLOR := Color("#eab308")
const SAND_COLOR := Color("#fde047")
const SAND_LIGHT_COLOR := Color("#fef08a")
const GRASS_RIM_COLOR := Color("#22c55e")
const GRASS_COLOR := Color("#4ade80")
const GRASS_SHADE_COLOR := Color("#86efac")

const WORLD_CENTER := Vector2(360, 500)
# Köşeli daire (süperelips): ISLAND_BOUNDS'un dört köşesi de kumsalın içinde kalır.
const SAND_RADII := Vector2(345, 420)
const SAND_LIGHT_RADII := Vector2(325, 398)
const GRASS_RADII := Vector2(295, 365)
const GRASS_SHADE_RADII := Vector2(200, 250)
const ISLAND_ROUNDNESS := 4.0
const ISLAND_POINT_COUNT := 72

const FOAM_PULSE := 0.018
const FOAM_BASE_SCALE := 1.025
const FOAM_SPEED := 1.2
# Ada önden hafif görülsün diye kumsal ve çimen, koyu kenarlarının üstüne biner.
const SAND_RIM_OFFSET := Vector2(0, 14)
const GRASS_RIM_OFFSET := Vector2(0, 8)
# Köpük çizgileri açıkta doğar, kıyıya yaklaşırken belirir ve kumda söner.
const SURF_LINE_COUNT := 3
const SURF_FAR_SCALE := 1.15
const SURF_NEAR_SCALE := 1.02
const SURF_SPEED := 0.22
const SURF_WIDTH := 4.0
const SURF_RIPPLES := 9
const SURF_RIPPLE_SIZE := 0.006
const WAVE_ROW_GAP := 92.0
const WAVE_SEGMENT_LENGTH := 24.0
const WAVE_HEIGHT := 7.0
const WAVE_LENGTH := 130.0
const WAVE_SPEED := 0.8
const WAVE_WIDTH := 3.0

# Ada, ekran genişliğini 1. seviyede dolduruyor. Kamera geri çekilirken ada yine de
# ekranda büyür; kumsal yanlardan taşabilir ama eşya sınırları ekranda kalır.
const VIEW_ZOOMS: Array[float] = [1.0, 0.92, 0.8, 0.68]
const GROW_SECONDS := 1.1
const SHAKE_STRENGTH := 10.0
const SHAKE_SECONDS := 0.7
const SHAKE_SPEED_X := 47.0
const SHAKE_SPEED_Y := 59.0
const FOAM_RING_SECONDS := 1.4
const FOAM_RING_COUNT := 3
const FOAM_RING_SPREAD := 0.22
const FOAM_RING_LAG := 0.25
const FOAM_RING_WIDTH := 7.0

const INK := Color("#0f172a")

const CLOUD_COLOR := Color(1, 1, 1, 0.92)
const CLOUD_SHADE_COLOR := Color("#bae6fd")
const CLOUD_MARGIN := 110.0
# Büyük adada bulutlar üst çubuğun arkasına kaçmasın.
const CLOUD_MIN_Y := 125.0
# x: başlangıç, y: adanın üst ucundan yükseklik, z: hız; w: boyut.
const CLOUDS: Array[Vector4] = [
	Vector4(60, 62, 15, 1.0),
	Vector4(420, 88, 10, 0.75),
	Vector4(690, 44, 19, 0.85),
]
const CLOUD_PUFFS: Array[Vector3] = [
	Vector3(-44, 4, 20), Vector3(-18, -10, 28), Vector3(16, -14, 32), Vector3(46, 2, 22), Vector3(0, 8, 26),
]

const BOAT_OFFSET := Vector2(-240, 490)
const BOAT_CORNER_PULL := 2.0
const BOAT_BOB := 4.0
const BOAT_BOB_SPEED := 1.5
const BOAT_ROLL := 0.08
const BOAT_ROLL_SPEED := 1.1
const HULL_COLOR := Color("#c28a3c")
const HULL_DARK_COLOR := Color("#78350f")
const MAST_COLOR := Color("#57300f")
const SAIL_COLOR := Color("#fff7ed")
const RAIL_COLOR := Color("#f8fafc")
const SHEEP_WOOL_COLOR := Color("#fefce8")
const SHEEP_FACE_COLOR := Color("#fde2b8")
const SHEEP_HORN_COLOR := Color("#a16207")
const STRAW_COLOR := Color("#facc15")
const HAT_BAND_COLOR := Color("#dc2626")
# x, y: pruvadaki yün topları; z: yarıçap.
const SHEEP_WOOL: Array[Vector3] = [
	Vector3(58, -24, 9), Vector3(70, -32, 10), Vector3(82, -24, 9), Vector3(56, -12, 8), Vector3(68, -14, 9),
]

# x, y: adanın merkezine göre konum; z: sallanma evresi.
const BARRELS: Array[Vector3] = [
	Vector3(-85, 478, 0.0), Vector3(50, 488, 1.7), Vector3(300, -432, 3.1),
]
const BARREL_COLOR := Color("#a16207")
const BARREL_BAND_COLOR := Color("#57534e")

const DECOR_SEED := 23
const SHORE_INNER_RADII := Vector2(304, 380)
const SHORE_OUTER_RADII := Vector2(334, 408)
const GROUND_RADII := Vector2(270, 340)
const PEBBLE_COUNT := 34
const SHELL_COUNT := 10
const TUFT_COUNT := 30
const FLOWER_COUNT := 16
const PEBBLE_COLORS: Array[Color] = [Color("#a8a29e"), Color("#d6d3d1"), Color("#ca8a04")]
const SHELL_COLOR := Color("#fda4af")
const SHELL_LINE_COLOR := Color("#e11d48")
const TUFT_COLOR := Color("#16a34a")
const TUFT_SWAY := 1.6
const TUFT_SWAY_SPEED := 1.8
const FLOWER_COLORS: Array[Color] = [Color("#f472b6"), Color("#fb923c"), Color("#a78bfa"), Color("#ffffff"), Color("#f87171")]
const FLOWER_CENTER_COLOR := Color("#facc15")

# Yengeç kumsalın alt kısmında, kıyı kavisini izleyerek yanlamasına yürür.
const CRAB_PATH_RADII := Vector2(320, 394)
const CRAB_RANGE := 170.0
const CRAB_SPEED := 36.0
const CRAB_WALK_MIN := 0.8
const CRAB_WALK_MAX := 2.2
const CRAB_REST_MIN := 1.2
const CRAB_REST_MAX := 3.8
const CRAB_STEP_SPEED := 20.0
const CRAB_COLOR := Color("#ef4444")
const CRAB_DARK_COLOR := Color("#b91c1c")

const RIPPLE_SECONDS := 0.9
const RIPPLE_RADIUS := 62.0
const RIPPLE_SQUASH := Vector2(1.0, 0.6)
const RIPPLE_COLOR := Color(1, 1, 1, 0.85)
const RIPPLE_WIDTH := 4.0
const RIPPLE_LIMIT := 8

const STARTER_ITEMS: Array[Dictionary] = [
	{"type": "monkey", "position": Vector2(310, 510)},
	{"type": "palm", "position": Vector2(420, 470)},
]

var _item_nodes: Dictionary[String, Node2D] = {}
var _time := 0.0
var _sand_points := _island_points(SAND_RADII)
var _sand_light_points := _island_points(SAND_LIGHT_RADII)
var _grass_points := _island_points(GRASS_RADII)
var _grass_shade_points := _island_points(GRASS_SHADE_RADII)
var _pebbles: Array[Vector2] = []
var _shells: Array[Vector2] = []
var _tufts: Array[Vector2] = []
var _flowers: Array[Vector2] = []
var _crab_x := -60.0
var _crab_direction := 1.0
var _crab_walking := false
var _crab_timer := 1.0
# x, y: dokunulan yer; z: geçen süre.
var _ripples: Array[Vector3] = []
var _shown_level := DataManager.MIN_ISLAND_LEVEL
var _island_scale := 1.0
var _view_zoom := 1.0
var _shake_strength := 0.0
var _foam_ring_progress := 1.0
var _growth_tween: Tween

@onready var _world: Control = %World
@onready var _items: Node2D = %Items
@onready var _shop_modal: CanvasLayer = %ShopModal


func _ready() -> void:
	_world.pivot_offset = WORLD_CENTER
	_shown_level = DataManager.data.island_level
	_set_growth(1.0, 0.0, 0.0, DataManager.get_island_scale(), _level_zoom())
	_scatter_decor()
	%ShopButton.pressed.connect(SoundManager.play_click)
	%ShopButton.pressed.connect(_shop_modal.open)
	visibility_changed.connect(_update_processing)
	_update_processing()

	if DataManager.data.island_items.is_empty():
		for starter: Dictionary in STARTER_ITEMS:
			DataManager.place_island_item(starter.type, starter.position)
	_sync_items(false)
	DataManager.island_updated.connect(_sync_items.bind(true))
	DataManager.island_updated.connect(_sync_level)


func _process(delta: float) -> void:
	_time += delta
	_update_crab(delta)
	_update_ripples(delta)
	_items.position = _shake_offset() / _view_zoom
	queue_redraw()


# Eşyalar ve mağaza düğmesi dokunuşu kendileri yakalar; buraya yalnızca boş yerler düşer.
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if _ripples.size() >= RIPPLE_LIMIT:
			_ripples.pop_front()
		_ripples.append(Vector3(event.position.x, event.position.y, 0.0))


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), OCEAN_COLOR)
	_draw_waves()

	var center := _world.position + WORLD_CENTER + _shake_offset()
	var island_scale := _island_scale * _view_zoom
	_draw_clouds(center)
	var foam_scale := FOAM_BASE_SCALE + sin(_time * FOAM_SPEED) * FOAM_PULSE
	_draw_surf_lines(center)
	_draw_foam_rings(center)
	_draw_going_merry(center + _boat_offset())
	_draw_barrels(center)
	var sand_rim := center + SAND_RIM_OFFSET * _view_zoom
	var size_scale := Vector2(island_scale, island_scale)
	draw_set_transform(sand_rim, 0.0, size_scale * foam_scale)
	draw_colored_polygon(_sand_points, FOAM_COLOR)
	draw_set_transform(sand_rim, 0.0, size_scale)
	draw_colored_polygon(_sand_points, SAND_RIM_COLOR)
	draw_set_transform(center, 0.0, size_scale)
	draw_colored_polygon(_sand_points, SAND_COLOR)
	draw_colored_polygon(_sand_light_points, SAND_LIGHT_COLOR)
	draw_set_transform(center + GRASS_RIM_OFFSET * _view_zoom, 0.0, size_scale)
	draw_colored_polygon(_grass_points, GRASS_RIM_COLOR)
	draw_set_transform(center, 0.0, size_scale)
	draw_colored_polygon(_grass_points, GRASS_COLOR)
	draw_colored_polygon(_grass_shade_points, GRASS_SHADE_COLOR)
	_draw_ground_decor(center)
	_draw_crab(center + _crab_offset() * island_scale)
	draw_set_transform(Vector2.ZERO)
	_draw_ripples()


func _draw_surf_lines(center: Vector2) -> void:
	var island_scale := _island_scale * _view_zoom
	var origin := center + SAND_RIM_OFFSET * _view_zoom
	var count := _sand_points.size()
	var line := PackedVector2Array()
	line.resize(count + 1)
	for i: int in SURF_LINE_COUNT:
		var progress := fmod(_time * SURF_SPEED + float(i) / SURF_LINE_COUNT, 1.0)
		var line_scale := lerpf(SURF_FAR_SCALE, SURF_NEAR_SCALE, progress)
		for j: int in count:
			var ripple := sin(TAU * SURF_RIPPLES * j / count + _time * 2.0 + i) * SURF_RIPPLE_SIZE
			line[j] = origin + _sand_points[j] * island_scale * (line_scale + ripple)
		line[count] = line[0]
		draw_polyline(line, Color(FOAM_COLOR, FOAM_COLOR.a * sin(progress * PI)), SURF_WIDTH, true)


# Genişleme anında kıyıdan açığa yayılan köpük halkaları.
func _draw_foam_rings(center: Vector2) -> void:
	if _foam_ring_progress >= 1.0:
		return
	var origin := center + SAND_RIM_OFFSET * _view_zoom
	var island_scale := _island_scale * _view_zoom
	var count := _sand_points.size()
	var line := PackedVector2Array()
	line.resize(count + 1)
	for i: int in FOAM_RING_COUNT:
		var progress := clampf(_foam_ring_progress * (1.0 + FOAM_RING_LAG * FOAM_RING_COUNT) - FOAM_RING_LAG * i, 0.0, 1.0)
		if progress <= 0.0 or progress >= 1.0:
			continue
		for j: int in count:
			line[j] = origin + _sand_points[j] * island_scale * (1.0 + FOAM_RING_SPREAD * progress)
		line[count] = line[0]
		draw_polyline(line, Color(Color.WHITE, 1.0 - progress), FOAM_RING_WIDTH * (1.0 - progress * 0.5), true)


func _draw_clouds(center: Vector2) -> void:
	var span := size.x + CLOUD_MARGIN * 2.0
	var top := center.y - scaled_radii(SAND_RADII).y * _view_zoom
	for cloud: Vector4 in CLOUDS:
		var x := fmod(cloud.x + _time * cloud.z, span) - CLOUD_MARGIN
		var spot := Vector2(x, maxf(top - cloud.y, CLOUD_MIN_Y))
		for puff: Vector3 in CLOUD_PUFFS:
			draw_circle(spot + Vector2(puff.x, puff.y + 6.0) * cloud.w, puff.z * cloud.w, CLOUD_SHADE_COLOR, true, -1.0, true)
		for puff: Vector3 in CLOUD_PUFFS:
			draw_circle(spot + Vector2(puff.x, puff.y) * cloud.w, puff.z * cloud.w, CLOUD_COLOR, true, -1.0, true)


func _draw_going_merry(anchor: Vector2) -> void:
	var bob := sin(_time * BOAT_BOB_SPEED) * BOAT_BOB
	var roll := sin(_time * BOAT_ROLL_SPEED) * BOAT_ROLL
	var zoom := Vector2(_view_zoom, _view_zoom)
	draw_set_transform(anchor, 0.0, zoom)
	draw_arc(Vector2(0, -8), 44.0 + bob, 0.15 * PI, 0.85 * PI, 14, FOAM_COLOR, 3.0, true)
	draw_set_transform(anchor + Vector2(0, bob) * _view_zoom, roll, zoom)
	draw_line(Vector2(0, 8), Vector2(0, -74), INK, 7.0, true)
	draw_line(Vector2(0, 8), Vector2(0, -74), MAST_COLOR, 4.0, true)
	_draw_outlined(PackedVector2Array([Vector2(0, -74), Vector2(-22, -80), Vector2(0, -86)]), INK)
	_draw_outlined(PackedVector2Array([Vector2(-32, -66), Vector2(32, -66), Vector2(38, -14), Vector2(-38, -14)]), SAIL_COLOR)
	_draw_jolly_roger(Vector2(0, -40))
	_draw_outlined(PackedVector2Array([Vector2(-58, -8), Vector2(58, -2), Vector2(44, 26), Vector2(-44, 26)]), HULL_COLOR)
	draw_line(Vector2(-51, 5), Vector2(51, 9), HULL_DARK_COLOR, 3.0, true)
	draw_line(Vector2(-56, -12), Vector2(50, -7), INK, 5.0, true)
	draw_line(Vector2(-56, -12), Vector2(50, -7), RAIL_COLOR, 2.5, true)
	_draw_sheep_head()
	draw_set_transform(Vector2.ZERO)


func _draw_jolly_roger(center: Vector2) -> void:
	for side: float in [-1.0, 1.0]:
		draw_line(center + Vector2(-side * 20, -6), center + Vector2(side * 20, 18), INK, 5.0, true)
	draw_circle(center + Vector2(0, 4), 13.0, INK, true, -1.0, true)
	draw_rect(Rect2(center + Vector2(-7, 12), Vector2(14, 8)), INK)
	for side: float in [-1.0, 1.0]:
		draw_circle(center + Vector2(side * 5, 4), 3.0, SAIL_COLOR, true, -1.0, true)
	_draw_outlined(PackedVector2Array([center + Vector2(-9, -6), center + Vector2(-7, -19), center + Vector2(7, -19), center + Vector2(9, -6)]), STRAW_COLOR)
	draw_rect(Rect2(center + Vector2(-8, -10), Vector2(16, 3)), HAT_BAND_COLOR)
	draw_line(center + Vector2(-18, -6), center + Vector2(18, -6), INK, 5.0, true)
	draw_line(center + Vector2(-17, -6), center + Vector2(17, -6), STRAW_COLOR, 2.5, true)


# Going Merry'nin koyun başlı pruvası.
func _draw_sheep_head() -> void:
	for puff: Vector3 in SHEEP_WOOL:
		draw_circle(Vector2(puff.x, puff.y), puff.z + 2.5, INK, true, -1.0, true)
	for puff: Vector3 in SHEEP_WOOL:
		draw_circle(Vector2(puff.x, puff.y), puff.z, SHEEP_WOOL_COLOR, true, -1.0, true)
	draw_arc(Vector2(60, -30), 7.0, 0.3 * PI, 2.0 * PI, 14, INK, 5.0, true)
	draw_arc(Vector2(60, -30), 7.0, 0.3 * PI, 2.0 * PI, 14, SHEEP_HORN_COLOR, 3.0, true)
	draw_circle(Vector2(78, -20), 10.0, INK, true, -1.0, true)
	draw_circle(Vector2(78, -20), 8.0, SHEEP_FACE_COLOR, true, -1.0, true)
	draw_circle(Vector2(80, -23), 2.0, INK, true, -1.0, true)
	draw_arc(Vector2(79, -18), 4.0, 0.1 * PI, 0.8 * PI, 8, INK, 1.5, true)


func _draw_barrels(center: Vector2) -> void:
	var pull := pow(_island_scale * _view_zoom, BOAT_CORNER_PULL)
	for barrel: Vector3 in BARRELS:
		var bob := sin(_time * BOAT_BOB_SPEED + barrel.z) * BOAT_BOB
		var anchor := center + Vector2(barrel.x * pull, barrel.y)
		var zoom := Vector2(_view_zoom, _view_zoom)
		draw_set_transform(anchor, 0.0, zoom)
		draw_arc(Vector2(0, -4), 22.0 + bob * 0.5, 0.15 * PI, 0.85 * PI, 10, FOAM_COLOR, 2.5, true)
		draw_set_transform(anchor + Vector2(0, bob) * _view_zoom, sin(_time * BOAT_ROLL_SPEED + barrel.z) * BOAT_ROLL * 2.0, zoom)
		_draw_outlined(PackedVector2Array([
			Vector2(-11, -17), Vector2(11, -17), Vector2(16, -6), Vector2(16, 6), Vector2(11, 15), Vector2(-11, 15), Vector2(-16, 6), Vector2(-16, -6),
		]), BARREL_COLOR)
		for y: float in [-9.0, 7.0]:
			draw_line(Vector2(-15, y), Vector2(15, y), BARREL_BAND_COLOR, 3.0, true)
	draw_set_transform(Vector2.ZERO)


# Ada büyüdükçe altta su şeridi daralır; tekne kumsalın kavisli köşesine doğru kayar ve
# alt menünün arkasına girmez.
func _boat_offset() -> Vector2:
	return Vector2(BOAT_OFFSET.x * pow(_island_scale * _view_zoom, BOAT_CORNER_PULL), BOAT_OFFSET.y)


func _draw_outlined(points: PackedVector2Array, fill: Color) -> void:
	draw_colored_polygon(points, fill)
	var line := points.duplicate()
	line.append(points[0])
	draw_polyline(line, INK, 2.5, true)


# Süslerin yeri adayla açılır ama kendileri eşyalarla aynı kamera ölçeğinde çizilir.
func _draw_ground_decor(center: Vector2) -> void:
	draw_set_transform(center, 0.0, Vector2(_view_zoom, _view_zoom))
	for i: int in _pebbles.size():
		var color := PEBBLE_COLORS[i % PEBBLE_COLORS.size()]
		draw_circle(_pebbles[i] * _island_scale, 2.0 + i % 3, color, true, -1.0, true)
	for spot: Vector2 in _shells:
		_draw_shell(spot * _island_scale)
	var sway := sin(_time * TUFT_SWAY_SPEED) * TUFT_SWAY
	for i: int in _tufts.size():
		var base := _tufts[i] * _island_scale
		var tip_sway := sway if i % 2 == 0 else -sway
		for blade: float in [-5.0, 0.0, 5.0]:
			# Dipleri ayrı başlar; tek noktada birleşen çizgiler ok gibi görünürdü.
			draw_line(base + Vector2(blade, 0), base + Vector2(blade * 1.5 + tip_sway, -12.0 + absf(blade)), TUFT_COLOR, 3.0, true)
	for i: int in _flowers.size():
		_draw_flower(_flowers[i] * _island_scale, FLOWER_COLORS[i % FLOWER_COLORS.size()])


func _draw_shell(spot: Vector2) -> void:
	draw_circle(spot, 6.0, SHELL_COLOR, true, -1.0, true)
	for angle: float in [-0.7, 0.0, 0.7]:
		draw_line(spot + Vector2(0, 5), spot + Vector2(sin(angle), -cos(angle)) * 5.5, SHELL_LINE_COLOR, 1.2, true)


func _draw_flower(spot: Vector2, petal: Color) -> void:
	for i: int in 5:
		draw_circle(spot + Vector2(4.0, 0).rotated(TAU * i / 5.0), 3.2, petal, true, -1.0, true)
	draw_circle(spot, 2.4, FLOWER_CENTER_COLOR, true, -1.0, true)


func _draw_crab(anchor: Vector2) -> void:
	draw_set_transform(anchor, 0.0, Vector2(_view_zoom, _view_zoom))
	var step := sin(_time * CRAB_STEP_SPEED) if _crab_walking else 0.0
	for side: float in [-1.0, 1.0]:
		for leg: int in 3:
			# Karşılıklı bacaklar sırayla kalkar; yürüyüş minik adımlı görünür.
			var lift := step * (1.0 if leg % 2 == 0 else -1.0) * 2.5
			var knee := Vector2(side * (13.0 + leg * 2.0), leg * 3.0 - 1.0 + lift)
			draw_line(Vector2(side * 8.0, leg * 2.0), knee, INK, 2.5, true)
		var claw := Vector2(side * 19.0, -9.0 + step)
		draw_line(Vector2(side * 10.0, -3.0), claw, CRAB_DARK_COLOR, 3.5, true)
		draw_circle(claw, 5.0, INK, true, -1.0, true)
		draw_circle(claw, 3.5, CRAB_COLOR, true, -1.0, true)
		var eye := Vector2(side * 5.0, -14.0)
		draw_line(Vector2(side * 4.0, -7.0), eye, INK, 2.0, true)
		draw_circle(eye, 3.0, Color.WHITE, true, -1.0, true)
		draw_circle(eye, 1.5, INK, true, -1.0, true)
	draw_set_transform(anchor, 0.0, Vector2(_view_zoom, _view_zoom * 0.72))
	draw_circle(Vector2.ZERO, 14.0, INK, true, -1.0, true)
	draw_circle(Vector2.ZERO, 12.0, CRAB_COLOR, true, -1.0, true)
	draw_set_transform(Vector2.ZERO)


func _draw_ripples() -> void:
	for ripple: Vector3 in _ripples:
		var progress := ripple.z / RIPPLE_SECONDS
		var color := Color(RIPPLE_COLOR, RIPPLE_COLOR.a * (1.0 - progress))
		draw_set_transform(Vector2(ripple.x, ripple.y), 0.0, RIPPLE_SQUASH)
		draw_arc(Vector2.ZERO, RIPPLE_RADIUS * progress, 0.0, TAU, 28, color, RIPPLE_WIDTH, true)
		draw_arc(Vector2.ZERO, RIPPLE_RADIUS * progress * 0.55, 0.0, TAU, 20, color, RIPPLE_WIDTH * 0.6, true)
	draw_set_transform(Vector2.ZERO)


func _update_crab(delta: float) -> void:
	_crab_timer -= delta
	if _crab_timer <= 0.0:
		_crab_walking = not _crab_walking
		if _crab_walking:
			_crab_direction = -_crab_direction if randf() < 0.5 else _crab_direction
			_crab_timer = randf_range(CRAB_WALK_MIN, CRAB_WALK_MAX)
		else:
			_crab_timer = randf_range(CRAB_REST_MIN, CRAB_REST_MAX)
	if _crab_walking:
		_crab_x += _crab_direction * CRAB_SPEED * delta
		if absf(_crab_x) >= CRAB_RANGE:
			_crab_x = clampf(_crab_x, -CRAB_RANGE, CRAB_RANGE)
			_crab_direction = -_crab_direction


func _crab_offset() -> Vector2:
	var along := pow(absf(_crab_x) / CRAB_PATH_RADII.x, ISLAND_ROUNDNESS)
	return Vector2(_crab_x, CRAB_PATH_RADII.y * pow(1.0 - along, 1.0 / ISLAND_ROUNDNESS))


func _update_ripples(delta: float) -> void:
	for i: int in range(_ripples.size() - 1, -1, -1):
		_ripples[i].z += delta
		if _ripples[i].z >= RIPPLE_SECONDS:
			_ripples.remove_at(i)


# Sabit tohum: süsler her açılışta ve her karede aynı yerde kalır. Listeler ayrı tohumlanır;
# büyüyen adada eski süsler yerinde kalır, yoğunluk korunsun diye yenileri eklenir.
func _scatter_decor() -> void:
	var density := pow(DataManager.get_island_scale(), 2.0)
	_pebbles = _scatter(_seeded_rng(0), roundi(PEBBLE_COUNT * density), SHORE_INNER_RADII, SHORE_OUTER_RADII)
	_shells = _scatter(_seeded_rng(1), roundi(SHELL_COUNT * density), SHORE_INNER_RADII, SHORE_OUTER_RADII)
	_tufts = _scatter(_seeded_rng(2), roundi(TUFT_COUNT * density), Vector2.ZERO, GROUND_RADII)
	_flowers = _scatter(_seeded_rng(3), roundi(FLOWER_COUNT * density), Vector2.ZERO, GROUND_RADII)


func _seeded_rng(list_index: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = DECOR_SEED + list_index
	return rng


func _scatter(rng: RandomNumberGenerator, count: int, inner: Vector2, outer: Vector2) -> Array[Vector2]:
	var points: Array[Vector2] = []
	while points.size() < count:
		var spot := Vector2(rng.randf_range(-outer.x, outer.x), rng.randf_range(-outer.y, outer.y))
		if _is_inside(spot, outer) and not _is_inside(spot, inner):
			points.append(spot)
	return points


func _is_inside(spot: Vector2, radii: Vector2) -> bool:
	if radii == Vector2.ZERO:
		return false
	return pow(absf(spot.x) / radii.x, ISLAND_ROUNDNESS) + pow(absf(spot.y) / radii.y, ISLAND_ROUNDNESS) < 1.0


func _draw_waves() -> void:
	var points := PackedVector2Array()
	points.resize(ceili(size.x / WAVE_SEGMENT_LENGTH) + 1)
	var row := 0
	var y := WAVE_ROW_GAP / 2.0
	while y < size.y:
		for i: int in points.size():
			var x := i * WAVE_SEGMENT_LENGTH
			# Satırlar farklı yönde kayınca dalgalar tek parça görünmez.
			var phase := x / WAVE_LENGTH * TAU + _time * WAVE_SPEED * (1 if row % 2 == 0 else -1) + row
			points[i] = Vector2(x, y + sin(phase) * WAVE_HEIGHT)
		draw_polyline(points, WAVE_COLOR, WAVE_WIDTH, true)
		y += WAVE_ROW_GAP
		row += 1


func _sync_level() -> void:
	var level: int = DataManager.data.island_level
	if level == _shown_level:
		return
	var grew := level > _shown_level
	_shown_level = level
	_scatter_decor()
	if _growth_tween:
		_growth_tween.kill()
	if grew:
		_play_expansion()
	else:
		_shake_strength = 0.0
		_foam_ring_progress = 1.0
		_set_growth(1.0, 0.0, 0.0, DataManager.get_island_scale(), _level_zoom())


func _play_expansion() -> void:
	SoundManager.play_timer_finish()
	_shake_strength = SHAKE_STRENGTH
	_foam_ring_progress = 0.0
	var grow := _set_growth.bind(_island_scale, _view_zoom, DataManager.get_island_scale(), _level_zoom())
	_growth_tween = create_tween()
	_growth_tween.tween_method(grow, 0.0, 1.0, GROW_SECONDS).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_growth_tween.parallel().tween_property(self, "_shake_strength", 0.0, SHAKE_SECONDS)
	_growth_tween.parallel().tween_property(self, "_foam_ring_progress", 1.0, FOAM_RING_SECONDS)


func _set_growth(weight: float, from_scale: float, from_zoom: float, to_scale: float, to_zoom: float) -> void:
	_island_scale = lerpf(from_scale, to_scale, weight)
	_view_zoom = lerpf(from_zoom, to_zoom, weight)
	_world.scale = Vector2(_view_zoom, _view_zoom)


func _level_zoom() -> float:
	return VIEW_ZOOMS[DataManager.data.island_level - DataManager.MIN_ISLAND_LEVEL]


func _shake_offset() -> Vector2:
	return Vector2(sin(_time * SHAKE_SPEED_X), cos(_time * SHAKE_SPEED_Y)) * _shake_strength


func scaled_radii(radii: Vector2) -> Vector2:
	return radii * _island_scale


func _sync_items(animate_new_items: bool) -> void:
	# Yalnızca fark uygulanır; yeniden kurmak süren sürükleme ve kayma animasyonlarını keserdi.
	var entries: Array = DataManager.data.island_items.duplicate()
	var live_ids := {}
	for entry: Dictionary in entries:
		live_ids[entry.id] = true
		if not _item_nodes.has(entry.id):
			var node := _create_item(entry)
			if animate_new_items:
				node.play_pop_animation()

	for item_id: String in _item_nodes.keys():
		if not live_ids.has(item_id):
			_item_nodes[item_id].queue_free()
			_item_nodes.erase(item_id)

	# Hem çizim hem dokunma sırası ağaç sırasını izler: önde duran eşya öne çizilir ve
	# önce yakalanır. y_sort yalnızca çizimi sıraladığı için kullanılmaz.
	entries.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.y < b.y)
	for entry: Dictionary in entries:
		_items.move_child(_item_nodes[entry.id], -1)


func _create_item(entry: Dictionary) -> Node2D:
	var node: Node2D = DRAGGABLE_ITEM_SCENE.instantiate()
	node.item_id = entry.id
	node.item_type = entry.type
	# Elle bozulmuş bir kayıt eşyayı ulaşılamayacak bir yere koymasın.
	node.position = DataManager.clamp_to_island(Vector2(entry.x, entry.y))
	_items.add_child(node)
	_item_nodes[entry.id] = node
	return node


func _update_processing() -> void:
	set_process(is_visible_in_tree())


func _island_points(radii: Vector2) -> PackedVector2Array:
	var points := PackedVector2Array()
	var exponent := 2.0 / ISLAND_ROUNDNESS
	for i: int in ISLAND_POINT_COUNT:
		var angle := TAU * i / ISLAND_POINT_COUNT
		var direction := Vector2(cos(angle), sin(angle))
		points.append(Vector2(
			signf(direction.x) * pow(absf(direction.x), exponent) * radii.x,
			signf(direction.y) * pow(absf(direction.y), exponent) * radii.y
		))
	return points
