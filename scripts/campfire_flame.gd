extends Node2D

# Adadaki kamp ateşi: dalgalanan üç katman alev, yükselen kıvılcım ve duman. Tamamı kodla
# çizilir; orijin ateşin tabanıdır, böylece esneme animasyonunda taban yerde kalır.

const INK := Color("#0f172a")
const FLAME_OUTER := Color("#ef4444")
const FLAME_MIDDLE := Color("#f97316")
const FLAME_INNER := Color("#fde047")
const GLOW_COLOR := Color(1.0, 0.55, 0.15, 0.06)
const SPARK_COLOR := Color("#fde047")
const SMOKE_COLOR := Color(0.45, 0.45, 0.5, 0.3)
const LOG_COLOR := Color("#6b3f1d")

const GLOW_RADII: Array[float] = [54.0, 44.0, 34.0]
const GLOW_CENTER := Vector2(0, -22)
const FLICKER_SPEED := 11.0
const SPARK_COUNT := 6
const SPARK_RISE := 92.0
const SPARK_SPEED := 0.55
const SMOKE_COUNT := 3
const SMOKE_RISE := 112.0
const SMOKE_SPEED := 0.22

var _time := randf() * TAU


func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	_time += delta
	queue_redraw()


func _draw() -> void:
	var pulse := 1.0 + sin(_time * FLICKER_SPEED * 0.5) * 0.08
	for radius: float in GLOW_RADII:
		draw_circle(GLOW_CENTER, radius * pulse, GLOW_COLOR, true, -1.0, true)
	_draw_smoke()

	var flicker := sin(_time * FLICKER_SPEED)
	var flutter := sin(_time * FLICKER_SPEED * 1.7 + 1.0)
	var sway := sin(_time * FLICKER_SPEED * 0.6) * 5.0
	_draw_flame(Vector2(27, 66 + flicker * 6.0), sway + flutter * 2.0, FLAME_OUTER)
	_draw_flame(Vector2(19, 46 - flicker * 5.0 + flutter * 2.0), -sway, FLAME_MIDDLE)
	_draw_flame(Vector2(10, 26 + flutter * 4.0), sway * 0.5, FLAME_INNER)
	_draw_logs()
	_draw_sparks()


func _draw_flame(flame_size: Vector2, sway: float, color: Color) -> void:
	draw_colored_polygon(PackedVector2Array([
		Vector2(-flame_size.x, 0),
		Vector2(-flame_size.x * 1.05, -flame_size.y * 0.32),
		Vector2(-flame_size.x * 0.55 + sway * 0.4, -flame_size.y * 0.62),
		Vector2(sway, -flame_size.y),
		Vector2(flame_size.x * 0.6 + sway * 0.4, -flame_size.y * 0.58),
		Vector2(flame_size.x * 1.05, -flame_size.y * 0.3),
		Vector2(flame_size.x, 0),
		Vector2(0, flame_size.x * 0.25),
	]), color)


func _draw_logs() -> void:
	for angle: float in [0.26, -0.26]:
		var offset := Vector2(36, 0).rotated(angle)
		draw_line(-offset, offset, INK, 13.0, true)
		draw_line(-offset, offset, LOG_COLOR, 8.0, true)


func _draw_sparks() -> void:
	for spark: int in SPARK_COUNT:
		var progress := fmod(_time * SPARK_SPEED + spark * 0.37, 1.0)
		var drift := sin(progress * 6.0 + spark) * 12.0
		var spot := Vector2(drift + (spark - 2.5) * 4.0, -24.0 - progress * SPARK_RISE)
		draw_circle(spot, 2.2 * (1.0 - progress * 0.5), Color(SPARK_COLOR, 1.0 - progress), true, -1.0, true)


func _draw_smoke() -> void:
	for puff: int in SMOKE_COUNT:
		var progress := fmod(_time * SMOKE_SPEED + float(puff) / SMOKE_COUNT, 1.0)
		var spot := Vector2(sin(progress * 5.0 + puff) * 10.0, -48.0 - progress * SMOKE_RISE)
		draw_circle(spot, 5.0 + progress * 9.0, Color(SMOKE_COLOR, SMOKE_COLOR.a * sin(progress * PI)), true, -1.0, true)
