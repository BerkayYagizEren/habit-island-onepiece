extends Control

# Odak ekranının arka planı: gece, kütük ve kamp ateşi. Sahne tüm ekranı boyar;
# karakter ve ateş stage_rect içine yerleşir, yazılar koyu zeminin üstünde okunur.

const SKY_TOP := Color("#0b1026")
const SKY_BOTTOM := Color("#27306b")
const HILL_COLOR := Color("#111c3a")
const TREE_COLOR := Color("#0c1530")
const GROUND_COLOR := Color("#14241c")
const GROUND_TOP_COLOR := Color("#1f3a2a")
const GRASS_COLOR := Color("#3f7d4e")
const STAR_COLOR := Color("#fef9c3")
const MOON_COLOR := Color("#fef3c7")
const BARK_COLOR := Color("#6b3f1d")
const BARK_DARK_COLOR := Color("#3f2410")
const BARK_END_COLOR := Color("#c79a6b")
const INK := Color("#0f172a")
const STONE_COLOR := Color("#64748b")
const FLAME_OUTER := Color("#ef4444")
const FLAME_MIDDLE := Color("#f97316")
const FLAME_INNER := Color("#fde047")
const GLOW_COLOR := Color(1.0, 0.55, 0.15, 0.035)

const STAR_COUNT := 36
const STAR_SEED := 11
const GROUND_RATIO := 0.8
const DESIGN_HEIGHT := 440.0
const MIN_ART_SCALE := 0.75
const MAX_ART_SCALE := 1.35
const MONKEY_SCALE := 1.45
const MONKEY_OFFSET := Vector2(-150, -62)
const LOG_OFFSET := Vector2(-20, 34)
const MOON_OFFSET := Vector2(-70, 50)
const FIRE_OFFSET := Vector2(165, -10)
const SPARK_COUNT := 7
const SPARK_RISE := 150.0
const GLOW_RADII: Array[float] = [150.0, 135.0, 120.0, 105.0, 90.0, 75.0, 60.0, 45.0]
const FLICKER_SPEED := 9.0
const GRASS_TUFTS: Array[float] = [0.04, 0.17, 0.33, 0.47, 0.58, 0.82, 0.95]
# Luffy odaklanırken çevresinde yavaşça nabız atan Haki halkaları.
const HAKI_COLOR := Color(0.62, 0.25, 0.95, 0.5)
const HAKI_CENTER := Vector2(10, -40)
const HAKI_RING_COUNT := 3
const HAKI_RADIUS := 150.0
const HAKI_SPEED := 0.35
const HAKI_WIDTH := 4.0

var stage_rect := Rect2():
	set(value):
		stage_rect = value
		_layout()

var _time := 0.0
var _stars: Array[Vector3] = []
var _locked_in := false

@onready var _monkey: Node2D = %SonicMonkey


func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = STAR_SEED
	for i: int in STAR_COUNT:
		_stars.append(Vector3(rng.randf(), rng.randf(), rng.randf() * TAU))
	visibility_changed.connect(_update_processing)
	_update_processing()
	_layout()


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func set_locked_in(locked_in: bool) -> void:
	_locked_in = locked_in
	_monkey.writing = locked_in


func _layout() -> void:
	if _monkey == null:
		return
	var art_scale := _art_scale()
	_monkey.position = _ground_center() + MONKEY_OFFSET * art_scale
	_monkey.scale = Vector2.ONE * MONKEY_SCALE * art_scale
	queue_redraw()


func _art_scale() -> float:
	return clampf(stage_rect.size.y / DESIGN_HEIGHT, MIN_ART_SCALE, MAX_ART_SCALE)


func _ground_center() -> Vector2:
	return Vector2(stage_rect.get_center().x, stage_rect.position.y + stage_rect.size.y * GROUND_RATIO)


func _draw() -> void:
	var center := _ground_center()
	var art_scale := _art_scale()
	_draw_sky(center.y)
	_draw_ground(center.y)
	var fire := center + FIRE_OFFSET * art_scale
	_draw_glow(fire + Vector2(0, -30) * art_scale, art_scale)
	if _locked_in:
		_draw_haki(center + (MONKEY_OFFSET + HAKI_CENTER) * art_scale, art_scale)
	_draw_log(center + (MONKEY_OFFSET + LOG_OFFSET) * art_scale, art_scale)
	_draw_campfire(fire, art_scale)
	_draw_grass(center.y)


func _draw_sky(horizon: float) -> void:
	var rect := Rect2(0, 0, size.x, horizon)
	draw_polygon(
		PackedVector2Array([rect.position, Vector2(rect.end.x, 0), rect.end, Vector2(0, rect.end.y)]),
		PackedColorArray([SKY_TOP, SKY_TOP, SKY_BOTTOM, SKY_BOTTOM])
	)
	for star: Vector3 in _stars:
		var alpha := 0.45 + 0.45 * sin(_time * 1.3 + star.z)
		draw_circle(Vector2(star.x * size.x, star.y * horizon * 0.8), 1.2 + star.z * 0.15, Color(STAR_COLOR, alpha), true, -1.0, true)
	# Başlıkla çakışmaması için ay, sahne alanına göre yerleşir.
	var moon := Vector2(size.x, stage_rect.position.y) + MOON_OFFSET
	draw_circle(moon, 34.0, Color(MOON_COLOR, 0.15), true, -1.0, true)
	draw_circle(moon, 24.0, MOON_COLOR, true, -1.0, true)
	draw_circle(moon + Vector2(-9, -5), 20.0, SKY_TOP.lerp(SKY_BOTTOM, 0.3), true, -1.0, true)
	draw_colored_polygon(PackedVector2Array([
		Vector2(0, horizon), Vector2(0, horizon - 70), Vector2(size.x * 0.22, horizon - 110),
		Vector2(size.x * 0.48, horizon - 60), Vector2(size.x * 0.74, horizon - 100),
		Vector2(size.x, horizon - 55), Vector2(size.x, horizon),
	]), HILL_COLOR)
	var tree_gap := size.x / 9.0
	for i: int in 10:
		var height := 46.0 + 30.0 * absf(sin(i * 1.9))
		var base := Vector2(i * tree_gap, horizon)
		draw_colored_polygon(PackedVector2Array([base + Vector2(-20, 0), base + Vector2(0, -height), base + Vector2(20, 0)]), TREE_COLOR)


func _draw_ground(horizon: float) -> void:
	draw_rect(Rect2(0, horizon, size.x, size.y - horizon), GROUND_COLOR)
	var ridge := PackedVector2Array([Vector2(0, horizon + 26), Vector2(0, horizon - 4)])
	for i: int in 13:
		var x := size.x * i / 12.0
		ridge.append(Vector2(x, horizon - 8.0 + sin(i * 1.7) * 5.0))
	ridge.append(Vector2(size.x, horizon + 26))
	draw_colored_polygon(ridge, GROUND_TOP_COLOR)


func _draw_glow(center: Vector2, art_scale: float) -> void:
	var pulse := 1.0 + sin(_time * FLICKER_SPEED) * 0.03
	for radius: float in GLOW_RADII:
		draw_circle(center, radius * art_scale * pulse, GLOW_COLOR, true, -1.0, true)


func _draw_haki(center: Vector2, art_scale: float) -> void:
	for ring: int in HAKI_RING_COUNT:
		var progress := fmod(_time * HAKI_SPEED + float(ring) / HAKI_RING_COUNT, 1.0)
		var color := Color(HAKI_COLOR, HAKI_COLOR.a * (1.0 - progress))
		draw_arc(center, HAKI_RADIUS * progress * art_scale, 0.0, TAU, 40, color, HAKI_WIDTH * art_scale, true)


func _draw_log(center: Vector2, art_scale: float) -> void:
	var half := Vector2(95, 24) * art_scale
	var body := Rect2(center - half, half * 2.0)
	draw_rect(body, BARK_COLOR)
	draw_rect(Rect2(body.position + Vector2(0, half.y * 1.2), Vector2(body.size.x, half.y * 0.8)), BARK_DARK_COLOR)
	draw_line(body.position, body.position + Vector2(body.size.x, 0), INK, 3.0, true)
	draw_line(body.position + Vector2(0, body.size.y), body.end, INK, 3.0, true)
	draw_circle(body.position + Vector2(0, half.y), half.y, INK, true, -1.0, true)
	draw_circle(body.position + Vector2(0, half.y), half.y - 3.0, BARK_COLOR, true, -1.0, true)
	var end_center := body.position + Vector2(body.size.x, half.y)
	draw_circle(end_center, half.y, INK, true, -1.0, true)
	draw_circle(end_center, half.y - 3.0, BARK_END_COLOR, true, -1.0, true)
	draw_arc(end_center, half.y * 0.55, 0.0, TAU, 20, BARK_DARK_COLOR, 2.0, true)


func _draw_campfire(base: Vector2, art_scale: float) -> void:
	for spark: int in SPARK_COUNT:
		var progress := fmod(_time * 0.45 + spark * 0.37, 1.0)
		var drift := sin(progress * 6.0 + spark) * 18.0
		var spot := base + Vector2(drift + (spark - 3) * 5.0, -30.0 - progress * SPARK_RISE) * art_scale
		draw_circle(spot, 2.5 * art_scale, Color(FLAME_INNER, 1.0 - progress), true, -1.0, true)

	var flicker := sin(_time * FLICKER_SPEED)
	var sway := sin(_time * FLICKER_SPEED * 0.6) * 6.0
	_draw_flame(base + Vector2(0, -8) * art_scale, Vector2(46, 118 + flicker * 8.0) * art_scale, sway * art_scale, FLAME_OUTER)
	_draw_flame(base + Vector2(0, -8) * art_scale, Vector2(32, 84 - flicker * 6.0) * art_scale, -sway * art_scale, FLAME_MIDDLE)
	_draw_flame(base + Vector2(0, -8) * art_scale, Vector2(18, 50 + flicker * 4.0) * art_scale, sway * 0.5 * art_scale, FLAME_INNER)

	for angle: float in [0.28, -0.28]:
		var offset := Vector2(62, 0).rotated(angle) * art_scale
		draw_line(base - offset, base + offset, INK, 20.0 * art_scale, true)
		draw_line(base - offset, base + offset, BARK_COLOR, 14.0 * art_scale, true)
	for i: int in 5:
		var stone := base + Vector2(-68 + i * 34, 16 + absf(i - 2) * -3.0) * art_scale
		draw_circle(stone, 12.0 * art_scale, INK, true, -1.0, true)
		draw_circle(stone, 9.5 * art_scale, STONE_COLOR, true, -1.0, true)


func _draw_flame(base: Vector2, flame_size: Vector2, sway: float, color: Color) -> void:
	var tip := base + Vector2(sway, -flame_size.y)
	var points := PackedVector2Array([
		base + Vector2(-flame_size.x, 0),
		base + Vector2(-flame_size.x * 1.05, -flame_size.y * 0.32),
		base + Vector2(-flame_size.x * 0.55 + sway * 0.4, -flame_size.y * 0.62),
		tip,
		base + Vector2(flame_size.x * 0.6 + sway * 0.4, -flame_size.y * 0.58),
		base + Vector2(flame_size.x * 1.05, -flame_size.y * 0.3),
		base + Vector2(flame_size.x, 0),
		base + Vector2(0, flame_size.x * 0.25),
	])
	draw_colored_polygon(points, color)


func _draw_grass(horizon: float) -> void:
	for ratio: float in GRASS_TUFTS:
		var base := Vector2(size.x * ratio, horizon + 10.0)
		for blade: float in [-9.0, -3.0, 3.0, 9.0]:
			draw_line(base, base + Vector2(blade, -20.0 + absf(blade)), GRASS_COLOR, 3.0, true)


func _update_processing() -> void:
	set_process(is_visible_in_tree())
