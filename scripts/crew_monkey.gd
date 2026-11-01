extends "res://scripts/sonic_monkey.gd"

# Hasır Şapka tayfasının diğer üyeleri: saç, aksesuar ve dokunma hareketleri burada çizilir.
# Luffy ve eski varyasyonlar sonic_monkey.gd'de kalır; create ikisi arasında seçim yapar.

const SONIC_MONKEY := preload("res://scripts/sonic_monkey.gd")

const ZORO_HAIR: Array[Vector2] = [
	Vector2(26, -22), Vector2(14, -42), Vector2(4, -32), Vector2(-10, -44), Vector2(-14, -30), Vector2(-30, -34), Vector2(-34, -6), Vector2(4, 6),
]
const ZORO_HAIR_CAP: Array[Vector2] = [
	Vector2(-30, -2), Vector2(-27, -22), Vector2(-10, -33), Vector2(12, -33), Vector2(28, -20), Vector2(30, -13), Vector2(12, -21), Vector2(-8, -20), Vector2(-20, -12),
]
const SANJI_HAIR: Array[Vector2] = [
	Vector2(26, -20), Vector2(0, -38), Vector2(-28, -24), Vector2(-40, 2), Vector2(-30, 22), Vector2(-14, 14), Vector2(4, 8),
]
# Saç tek gözü örter.
const SANJI_FRINGE: Array[Vector2] = [
	Vector2(-30, 4), Vector2(-30, -20), Vector2(-12, -33), Vector2(14, -33), Vector2(30, -18), Vector2(29, -11), Vector2(13, -19), Vector2(11, 7), Vector2(0, 12), Vector2(-14, 6),
]
const CHOPPER_FUR: Array[Vector2] = [
	Vector2(22, -20), Vector2(-24, -24), Vector2(-40, -6), Vector2(-34, 16), Vector2(-14, 18), Vector2(6, 8),
]
const GEAR5_HAIR: Array[Vector2] = [
	Vector2(26, -24), Vector2(0, -44), Vector2(-30, -30), Vector2(-46, -4), Vector2(-34, 20), Vector2(-14, 14), Vector2(6, 8),
]
# x, y: bulut saçın topları; z: yarıçap.
const GEAR5_CLOUDS: Array[Vector3] = [
	Vector3(-38, -8, 13), Vector3(-28, -26, 16), Vector3(-8, -38, 18), Vector3(14, -36, 17), Vector3(31, -22, 13),
]
const NAMI_HAIR: Array[Vector2] = [
	Vector2(28, -18), Vector2(8, -38), Vector2(-20, -34), Vector2(-38, -12), Vector2(-46, 16), Vector2(-40, 34), Vector2(-48, 50), Vector2(-28, 54), Vector2(-22, 38), Vector2(-8, 24), Vector2(10, 14),
]
const NAMI_FRINGE: Array[Vector2] = [
	Vector2(-30, 0), Vector2(-28, -20), Vector2(-10, -34), Vector2(14, -33), Vector2(30, -18), Vector2(31, -11), Vector2(20, -18), Vector2(6, -21), Vector2(-10, -16), Vector2(-22, -4),
]
const USOPP_HAIR: Array[Vector2] = [
	Vector2(26, -20), Vector2(18, -38), Vector2(4, -34), Vector2(-8, -44), Vector2(-20, -34), Vector2(-36, -34), Vector2(-36, -18), Vector2(-48, -10), Vector2(-40, 6), Vector2(-44, 20), Vector2(-26, 22), Vector2(-14, 12), Vector2(6, 8),
]
const USOPP_BANDANA: Array[Vector2] = [
	Vector2(-29, -6), Vector2(-26, -26), Vector2(-8, -35), Vector2(12, -34), Vector2(28, -20), Vector2(30, -14), Vector2(10, -20), Vector2(-10, -19),
]
const ROBIN_HAIR: Array[Vector2] = [
	Vector2(28, -18), Vector2(10, -36), Vector2(-16, -34), Vector2(-36, -14), Vector2(-42, 20), Vector2(-44, 54), Vector2(-26, 62), Vector2(-14, 40), Vector2(-4, 22), Vector2(10, 14),
]
const ROBIN_FRINGE: Array[Vector2] = [
	Vector2(-30, 2), Vector2(-30, -18), Vector2(-14, -33), Vector2(10, -33), Vector2(28, -20), Vector2(30, -13), Vector2(14, -18), Vector2(0, -20), Vector2(-12, -14), Vector2(-22, -2),
]
const FRANKY_HAIR: Array[Vector2] = [
	Vector2(24, -24), Vector2(0, -40), Vector2(-26, -30), Vector2(-34, -8), Vector2(-22, 12), Vector2(4, 8),
]
const FRANKY_POMPADOUR: Array[Vector2] = [
	Vector2(-26, -22), Vector2(-22, -42), Vector2(0, -58), Vector2(34, -62), Vector2(54, -46), Vector2(48, -30), Vector2(26, -24), Vector2(0, -22),
]
const FRANKY_NOSE: Array[Vector2] = [Vector2(6, 0), Vector2(22, 0), Vector2(25, 11), Vector2(3, 11)]
const BROOK_AFRO: Array[Vector2] = [
	Vector2(30, -26), Vector2(34, -42), Vector2(22, -56), Vector2(6, -66), Vector2(-14, -68), Vector2(-34, -60), Vector2(-50, -46), Vector2(-60, -26), Vector2(-62, -4), Vector2(-54, 14), Vector2(-38, 26), Vector2(-20, 22), Vector2(-6, 10), Vector2(8, 2),
]
const BROOK_HAT: Array[Vector2] = [Vector2(-24, -60), Vector2(-22, -100), Vector2(18, -100), Vector2(20, -60)]
const JINBE_HAIR: Array[Vector2] = [
	Vector2(24, -22), Vector2(6, -36), Vector2(-16, -36), Vector2(-22, -50), Vector2(-36, -54), Vector2(-38, -40), Vector2(-32, -28), Vector2(-38, -6), Vector2(-24, 10), Vector2(4, 8),
]
const CLOUD_DRIFT := 2.0
const CLOUD_DRIFT_SPEED := 3.0

const CREW_VARIANTS := {
	"zoro": {
		"fur": Color("#b98a57"), "fur_dark": Color("#8f6538"), "iris": INK, "brow": INK,
		"shoe": Color("#27272a"), "strap": Color("#3f3f46"), "buckle": Color("#a1a1aa"), "sole": Color("#18181b"),
		"quills": ZORO_HAIR, "hair": Color("#16a34a"), "hand": SKIN,
		"shirt": WHITE, "chest": WHITE, "waist": Color("#1f2937"), "sash": Color("#15803d"),
	},
	"sanji": {
		"fur": Color("#d9a066"), "fur_dark": Color("#b98144"), "iris": Color("#1d4ed8"), "brow": INK,
		"shoe": Color("#18181b"), "strap": Color("#3f3f46"), "buckle": Color("#a1a1aa"), "sole": Color("#09090b"),
		"quills": SANJI_HAIR, "hair": Color("#facc15"), "hand": SKIN,
		"shirt": Color("#18181b"), "chest": WHITE, "waist": Color("#18181b"),
		"sleeve": Color("#27272a"), "sleeve_dark": Color("#18181b"),
	},
	"chopper": {
		"fur": Color("#a16232"), "fur_dark": Color("#7c4720"), "iris": INK, "brow": INK,
		"shoe": Color("#7c4720"), "strap": Color("#a16232"), "buckle": Color("#fde68a"), "sole": Color("#451a03"),
		"quills": CHOPPER_FUR, "hand": Color("#fde2b8"),
	},
	"gear5": {
		"fur": Color("#f8fafc"), "fur_dark": Color("#cbd5e1"), "iris": Color("#dc2626"), "brow": INK,
		"shoe": WHITE, "strap": Color("#e2e8f0"), "buckle": Color("#a78bfa"), "sole": Color("#cbd5e1"),
		"quills": GEAR5_HAIR, "hair": WHITE, "hand": WHITE,
		"shirt": Color("#f1f5f9"), "waist": Color("#e2e8f0"), "sash": Color("#a78bfa"),
		"scar": true, "grin": true, "rubber": true, "aura": Color(1, 1, 1, 0.16),
	},
	"nami": {
		"fur": Color("#fcd9b0"), "fur_dark": Color("#e8b98a"), "iris": Color("#92400e"), "brow": Color("#c2410c"),
		"shoe": Color("#f97316"), "strap": Color("#fdba74"), "buckle": Color("#fde68a"), "sole": Color("#9a3412"),
		"quills": NAMI_HAIR, "hair": Color("#f97316"), "hand": SKIN,
		"shirt": Color("#38bdf8"), "chest": WHITE, "waist": Color("#1d4ed8"),
	},
	"usopp": {
		"fur": Color("#a86f3d"), "fur_dark": Color("#85542a"), "iris": INK, "brow": INK,
		"shoe": Color("#78350f"), "strap": Color("#a16207"), "buckle": Color("#fde68a"), "sole": Color("#451a03"),
		"quills": USOPP_HAIR, "hair": Color("#3f2a14"), "hand": Color("#c48a54"), "muzzle": Color("#c48a54"),
		"shirt": Color("#a16207"), "chest": Color("#fef3c7"), "waist": Color("#78350f"),
	},
	"robin": {
		"fur": Color("#e0a877"), "fur_dark": Color("#c48a54"), "iris": Color("#1e3a8a"), "brow": INK,
		"shoe": Color("#312e81"), "strap": Color("#6d28d9"), "buckle": Color("#facc15"), "sole": Color("#1e1b4b"),
		"quills": ROBIN_HAIR, "hair": Color("#111827"), "hand": Color("#f0c49a"), "muzzle": Color("#f0c49a"),
		"shirt": Color("#6d28d9"), "chest": Color("#f0c49a"), "waist": Color("#312e81"), "sash": Color("#2563eb"),
	},
	"franky": {
		"fur": Color("#d99a62"), "fur_dark": Color("#b97c47"), "iris": INK, "brow": Color("#0284c7"),
		"shoe": Color("#475569"), "strap": Color("#94a3b8"), "buckle": Color("#facc15"), "sole": Color("#1e293b"),
		"quills": FRANKY_HAIR, "hair": Color("#0ea5e9"), "hand": Color("#cbd5e1"), "arm_scale": 1.6,
		"shirt": Color("#ea580c"), "chest": Color("#e8b07a"), "waist": Color("#1d4ed8"),
		"sleeve": Color("#94a3b8"), "sleeve_dark": Color("#64748b"),
	},
	"brook": {
		"fur": Color("#f5f5f4"), "fur_dark": Color("#d6d3d1"), "iris": INK, "brow": Color("#f5f5f4"),
		"shoe": Color("#18181b"), "strap": Color("#3f3f46"), "buckle": Color("#facc15"), "sole": Color("#09090b"),
		"quills": BROOK_AFRO, "hair": Color("#18181b"), "hand": Color("#f5f5f4"), "muzzle": Color("#f5f5f4"), "ears": false,
		"shirt": Color("#27272a"), "chest": WHITE, "waist": Color("#18181b"),
		"sleeve": Color("#27272a"), "sleeve_dark": Color("#18181b"),
	},
	"jinbe": {
		"fur": Color("#60a5fa"), "fur_dark": Color("#3b82f6"), "iris": INK, "brow": Color("#facc15"),
		"shoe": Color("#78350f"), "strap": Color("#a16207"), "buckle": Color("#fde68a"), "sole": Color("#451a03"),
		"quills": JINBE_HAIR, "hair": Color("#111827"), "hand": Color("#60a5fa"), "muzzle": Color("#bfdbfe"),
		"shirt": Color("#1e3a8a"), "chest": Color("#60a5fa"), "waist": Color("#1e3a8a"), "sash": Color("#facc15"),
		"sleeve": Color("#1e3a8a"), "sleeve_dark": Color("#172554"),
	},
}

const KATANA_LENGTH := 72.0
const KATANA_REST_ANGLE := -1.1
const KATANA_SWING_ANGLE := 2.2
const SLASH_MIN_ACTION := 0.15
const SLASH_COLOR := Color(1, 1, 1, 0.85)
const STEEL_COLOR := Color("#e2e8f0")
const KATANA_HANDLES: Array[Color] = [Color("#f8fafc"), Color("#dc2626"), Color("#111827")]
const KICK_REACH := Vector2(40, -34)
const KICK_FLAME_OUTER := Color("#ef4444")
const KICK_FLAME_INNER := Color("#fde047")
const CHOPPER_HAT_COLOR := Color("#f472b6")
const CHOPPER_NOSE_COLOR := Color("#2563eb")
const ANTLER_COLOR := Color("#92400e")
const SCAR_DARK := Color("#7f1d1d")
const EARRING_COLOR := Color("#facc15")

# Özel hareketler zıplamadan uzun sürer: _move 0'dan 1'e ilerler, poz başta açılıp sonda toplanır.
const MOVE_SECONDS := 1.3
const MOVE_RISE := 0.12
const MOVE_FALL := 0.2
# Hareketin tepesinde kolların aldığı yer: arka dirsek, arka el, ön dirsek, ön el.
const MOVE_ARMS := {
	"nami": [BACK_ELBOW, BACK_HAND, Vector2(58, -30), Vector2(72, -82)],
	"usopp": [Vector2(-38, -6), Vector2(34, -8), Vector2(52, -14), Vector2(80, -22)],
	"robin": [Vector2(-30, 14), Vector2(18, -2), Vector2(30, 16), Vector2(-16, -6)],
	"franky": [Vector2(-56, -40), Vector2(-10, -120), Vector2(56, -40), Vector2(10, -120)],
	"brook": [BACK_ELBOW, BACK_HAND, Vector2(56, -24), Vector2(66, -82)],
	"jinbe": [Vector2(-44, 6), Vector2(-26, 20), Vector2(52, -8), Vector2(90, -8)],
}
const MOVE_SHOUTS := {"robin": "Mil Fleur!", "franky": "SUUUUPER!", "brook": "Yohohoho!"}
const SHOUT_POSITION := Vector2(-120, 92)
const SHOUT_WIDTH := 240.0
const SHOUT_FONT_SIZE := 24
const SHOUT_OUTLINE := 6

const PETAL_COUNT := 14
const PETAL_CENTER := Vector2(0, -14)
const PETAL_REACH := Vector2(34, 118)
const PETAL_COLORS: Array[Color] = [Color("#f9a8d4"), Color("#ec4899")]
const STAR_COLOR := Color("#facc15")
const STAR_COUNT := 10
const STAR_CENTER := Vector2(0, -130)
const STAR_REACH := 96.0
const STAR_POINT_RATIO := 0.45
const FRANKY_RIVET := Color("#475569")
const CLIMA_COLOR := Color("#2563eb")
const CLIMA_BALL := Color("#7dd3fc")
const CLIMA_LENGTH := 70.0
const CLIMA_TAIL := 16.0
const CLIMA_ANGLE := -1.2
const BOLT_COLOR := Color("#fde047")
const BOLT_COUNT := 4
const BOLT_LENGTH := 74.0
const BOLT_SEGMENTS := 5
const BOLT_JITTER := 10.0
const BOLT_SPEED := 18.0
const SLING_COLOR := Color("#92400e")
const SLING_BAND := Color("#78716c")
const SLING_FORK := Vector2(10, -16)
const SLING_PRONG := 8.0
const SHOT_MOMENT := 0.4
const SHOT_REACH := 170.0
const SMOKE_COLOR := Color("#d6d3d1")
const SMOKE_PUFFS := 6
const BANDANA_COLOR := Color("#65a30d")
const GOGGLE_LENS := Color("#fde047")
const SUNGLASS_FRAME := Color("#facc15")
const SUNGLASS_LENS := Color("#4c1d95")
const CANE_COLOR := Color("#78350f")
const CANE_LENGTH := 66.0
const CANE_ANGLE := -1.3
const HAT_RIBBON := Color("#7c3aed")
const NOTE_COLORS: Array[Color] = [Color("#7c3aed"), Color("#0f172a"), Color("#db2777")]
const NOTE_COUNT := 8
const NOTE_RISE := 170.0
const NOTE_SWAY := 72.0
const WAVE_COUNT := 4
const WAVE_REACH := 130.0
const WAVE_ARC := 1.0
const WAVE_COLORS: Array[Color] = [Color("#38bdf8"), Color("#e0f2fe")]
const DROPLET_COUNT := 8

var _move := 0.0
var _move_tween: Tween


static func create(monkey_variant: String) -> Node2D:
	var script: GDScript = load("res://scripts/crew_monkey.gd") if CREW_VARIANTS.has(monkey_variant) else SONIC_MONKEY
	return script.new(monkey_variant)


func _variant_table() -> Dictionary:
	return CREW_VARIANTS


func play_bounce() -> void:
	super()
	if not MOVE_ARMS.has(variant):
		return
	if _move_tween:
		_move_tween.kill()
	_move = 0.0
	_move_tween = create_tween()
	_move_tween.tween_property(self, "_move", 1.0, MOVE_SECONDS)


func _move_pose() -> float:
	return clampf(minf(_move / MOVE_RISE, (1.0 - _move) / MOVE_FALL), 0.0, 1.0)


func _arm_points() -> Array[Vector2]:
	var arms: Array[Vector2] = super()
	if MOVE_ARMS.has(variant):
		var target: Array = MOVE_ARMS[variant]
		for i: int in arms.size():
			arms[i] = arms[i].lerp(target[i], _move_pose())
	return arms


func _front_foot_offset() -> Vector2:
	return KICK_REACH * _action if variant == "sanji" else Vector2.ZERO


func _draw_behind_body() -> void:
	if variant == "zoro":
		# Belde taşınan diğer iki kılıç.
		for i: int in 2:
			var grip := Vector2(-16, 10 + i * 8)
			_draw_katana(grip, grip + Vector2(-46, 24 + i * 6), KATANA_HANDLES[i + 1], INK)


func _draw_held_item(hand: Vector2) -> void:
	match variant:
		"zoro":
			_draw_zoro_katana(hand)
		"nami":
			_draw_clima_tact(hand)
		"usopp":
			_draw_slingshot(hand)
		"brook":
			var tip := hand + Vector2.from_angle(CANE_ANGLE) * CANE_LENGTH
			_draw_katana(hand, tip, CANE_COLOR, CANE_COLOR.lerp(STEEL_COLOR, _move_pose()))


func _draw_zoro_katana(hand: Vector2) -> void:
	var angle := KATANA_REST_ANGLE + KATANA_SWING_ANGLE * _action
	_draw_katana(hand, hand + Vector2.from_angle(angle) * KATANA_LENGTH, KATANA_HANDLES[0], STEEL_COLOR)
	if _action > SLASH_MIN_ACTION:
		var slash := Color(SLASH_COLOR, SLASH_COLOR.a * _action)
		draw_arc(hand, KATANA_LENGTH, KATANA_REST_ANGLE, angle, 14, slash, 5.0, true)


func _draw_action_effects() -> void:
	if variant == "sanji" and _action > 0.0:
		var foot := Vector2(14, 47) + _front_foot_offset() + Vector2(24, 6)
		var flicker := sin(_time * 30.0) * 5.0
		_draw_kick_flame(foot, 72.0 * _action + flicker, KICK_FLAME_OUTER)
		_draw_kick_flame(foot, 40.0 * _action, KICK_FLAME_INNER)
	if variant == "franky":
		var arms := _arm_points()
		_shape(_star(arms[0].lerp(arms[1], 0.5), 9.0, 0.0), STAR_COLOR)
		_shape(_star(arms[2].lerp(arms[3], 0.5), 10.0, 0.0), STAR_COLOR)
	var pose := _move_pose()
	if pose <= 0.0:
		return
	match variant:
		"nami":
			_draw_lightning(pose)
		"usopp":
			_draw_slingshot_shot(pose)
		"robin":
			_draw_petals(pose)
		"franky":
			_draw_star_burst(pose)
		"brook":
			_draw_music_notes(pose)
		"jinbe":
			_draw_water_punch(pose)
	if MOVE_SHOUTS.has(variant):
		_draw_shout(MOVE_SHOUTS[variant], pose)


func _draw_shout(text: String, pose: float) -> void:
	var font := ThemeDB.fallback_font
	draw_string_outline(font, SHOUT_POSITION, text, HORIZONTAL_ALIGNMENT_CENTER, SHOUT_WIDTH, SHOUT_FONT_SIZE, SHOUT_OUTLINE, Color(INK, pose))
	draw_string(font, SHOUT_POSITION, text, HORIZONTAL_ALIGNMENT_CENTER, SHOUT_WIDTH, SHOUT_FONT_SIZE, Color(WHITE, pose))


func _draw_clima_tact(hand: Vector2) -> void:
	var direction := Vector2.from_angle(CLIMA_ANGLE)
	var tail := hand - direction * CLIMA_TAIL
	var tip := hand + direction * CLIMA_LENGTH
	_draw_limb(tail, tip, 5.0, CLIMA_COLOR)
	for ratio: float in [0.0, 0.5, 1.0]:
		_shape(_ellipse(tail.lerp(tip, ratio), Vector2(6, 6)), CLIMA_BALL)


func _draw_lightning(pose: float) -> void:
	var tip := _arm_points()[3] + Vector2.from_angle(CLIMA_ANGLE) * CLIMA_LENGTH
	var flicker := floori(_time * BOLT_SPEED)
	for i: int in BOLT_COUNT:
		var angle := TAU * (i + 0.5) / BOLT_COUNT + flicker * 0.4
		var bolt := PackedVector2Array([tip])
		for step: int in range(1, BOLT_SEGMENTS + 1):
			var along := Vector2.from_angle(angle) * BOLT_LENGTH * pose * step / BOLT_SEGMENTS
			bolt.append(tip + along + Vector2.from_angle(angle + PI / 2.0) * sin(float(flicker + step * 3 + i)) * BOLT_JITTER)
		draw_polyline(bolt, INK, 7.0, true)
		draw_polyline(bolt, BOLT_COLOR, 4.0, true)
	draw_circle(tip, 10.0 * pose, WHITE, true, -1.0, true)


func _draw_slingshot(hand: Vector2) -> void:
	var fork := hand + SLING_FORK
	draw_line(hand, fork, INK, 8.0, true)
	draw_line(hand, fork, SLING_COLOR, 5.0, true)
	for side: float in [-1.0, 1.0]:
		var prong := fork + Vector2(SLING_PRONG, side * SLING_PRONG)
		draw_line(fork, prong, INK, 7.0, true)
		draw_line(fork, prong, SLING_COLOR, 4.0, true)


func _draw_slingshot_shot(pose: float) -> void:
	var arms := _arm_points()
	var fork := arms[3] + SLING_FORK + Vector2(SLING_PRONG, 0)
	if _move < SHOT_MOMENT:
		# Kayış geride, nişan alınıyor.
		for side: float in [-1.0, 1.0]:
			draw_line(fork + Vector2(0, side * SLING_PRONG), arms[1], SLING_BAND, 3.0, true)
		_shape(_ellipse(arms[1], Vector2(5, 5)), SLING_COLOR)
		return
	var shot := (_move - SHOT_MOMENT) / (1.0 - SHOT_MOMENT)
	_shape(_ellipse(fork + Vector2(SHOT_REACH * shot, -10.0 * shot), Vector2(5, 5)), SLING_COLOR)
	for i: int in SMOKE_PUFFS:
		var drift := Vector2(18.0 + 10.0 * i, -6.0 * i) * shot
		var radius := (7.0 + 3.0 * i) * (0.5 + shot)
		draw_circle(fork + drift, radius, Color(SMOKE_COLOR, 0.7 * pose), true, -1.0, true)


func _draw_petals(pose: float) -> void:
	for i: int in PETAL_COUNT:
		var outer := 1.0 if i % 2 == 0 else 0.72
		var angle := TAU * i / PETAL_COUNT + _move * 2.0
		var offset := Vector2.from_angle(angle) * lerpf(PETAL_REACH.x, PETAL_REACH.y, sqrt(_move)) * outer
		var color := Color(PETAL_COLORS[i % PETAL_COLORS.size()], pose)
		var petal := PackedVector2Array()
		for point: Vector2 in _ellipse(Vector2.ZERO, Vector2(11, 6)):
			petal.append(PETAL_CENTER + offset + point.rotated(angle + _time * 3.0))
		draw_colored_polygon(petal, color)


func _draw_star_burst(pose: float) -> void:
	draw_colored_polygon(_star(STAR_CENTER, 26.0 * pose, _time * 2.0), STAR_COLOR)
	for i: int in STAR_COUNT:
		var angle := TAU * i / STAR_COUNT
		var offset := Vector2.from_angle(angle) * STAR_REACH * sqrt(_move)
		var color := Color(STAR_COLOR.lerp(WHITE, i % 2), pose)
		draw_colored_polygon(_star(STAR_CENTER + offset, 9.0 + 3.0 * (i % 2), _time * 4.0 + i), color)


func _star(center: Vector2, radius: float, spin: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i: int in 10:
		var reach := radius if i % 2 == 0 else radius * STAR_POINT_RATIO
		points.append(center + Vector2.from_angle(spin - PI / 2.0 + TAU * i / 10.0) * reach)
	return points


func _draw_music_notes(pose: float) -> void:
	for i: int in NOTE_COUNT:
		var rise := fmod(_move * 1.5 + float(i) / NOTE_COUNT, 1.0)
		var note := Vector2(sin(i * 2.4 + rise * 4.0) * NOTE_SWAY, -rise * NOTE_RISE - 10.0)
		var color := Color(NOTE_COLORS[i % NOTE_COLORS.size()], pose)
		draw_circle(note, 6.0, color, true, -1.0, true)
		draw_line(note + Vector2(5, 0), note + Vector2(5, -20), color, 3.0, true)
		draw_line(note + Vector2(5, -20), note + Vector2(14, -14), color, 3.0, true)


func _draw_water_punch(pose: float) -> void:
	var fist := _arm_points()[3]
	draw_circle(fist, 18.0, Color(WAVE_COLORS[0], 0.45 * pose), true, -1.0, true)
	for i: int in WAVE_COUNT:
		var spread := fmod(_move * 1.6 + float(i) / WAVE_COUNT, 1.0)
		draw_arc(fist, 16.0 + spread * WAVE_REACH, -WAVE_ARC, WAVE_ARC, 18, Color(WAVE_COLORS[i % WAVE_COLORS.size()], pose * (1.0 - spread)), 8.0, true)
	for i: int in DROPLET_COUNT:
		var angle := -WAVE_ARC + 2.0 * WAVE_ARC * i / (DROPLET_COUNT - 1)
		draw_circle(fist + Vector2.from_angle(angle) * WAVE_REACH * sqrt(_move), 4.0, Color(WAVE_COLORS[0], pose), true, -1.0, true)


func _draw_kick_flame(foot: Vector2, length: float, color: Color) -> void:
	draw_colored_polygon(PackedVector2Array([
		foot + Vector2(-8, -14), foot + Vector2(length * 0.5, -20), foot + Vector2(length, -2),
		foot + Vector2(length * 0.5, 16), foot + Vector2(-8, 14),
	]), color)


func _draw_katana(grip: Vector2, tip: Vector2, handle: Color, blade: Color) -> void:
	var guard := grip.lerp(tip, 0.22)
	draw_line(grip, tip, INK, 7.0, true)
	draw_line(guard, tip, blade, 3.5, true)
	draw_line(grip, guard, handle, 4.5, true)
	draw_circle(guard, 5.0, INK, true, -1.0, true)
	draw_circle(guard, 3.0, EARRING_COLOR, true, -1.0, true)


func _draw_outfit(corners: PackedVector2Array) -> void:
	super(corners)
	if variant == "franky":
		_shape(_star(corners[0].lerp(corners[2], 0.42), 11.0, 0.0), STAR_COLOR)
	elif variant == "robin" and _move_pose() > 0.0:
		# Kavuşturulan kollardan arkadaki de göğsün üzerinden geçer.
		var arms := _arm_points()
		_draw_limb(arms[0], arms[1], 13.0, _look.fur_dark)
		_shape(_ellipse(arms[1], Vector2(9, 9)), _look.hand)
	elif variant == "sanji":
		var knot := corners[0].lerp(corners[1], 0.5) + Vector2(0, 4)
		_shape(PackedVector2Array([knot + Vector2(-4, 0), knot + Vector2(4, 0), knot + Vector2(3, 18), knot + Vector2(0, 23), knot + Vector2(-3, 18)]), Color("#facc15"))


func _draw_head_costume() -> void:
	super()
	match variant:
		"zoro":
			_draw_zoro_head()
		"sanji":
			_draw_sanji_head()
		"chopper":
			_draw_chopper_head()
		"gear5":
			_draw_gear5_head()
		"nami":
			_shape(PackedVector2Array(NAMI_FRINGE), _look.hair)
		"usopp":
			_draw_usopp_head()
		"robin":
			_draw_robin_head()
		"franky":
			_draw_franky_head()
		"brook":
			_draw_brook_head()
		"jinbe":
			_draw_jinbe_head()


# Gözlük alına alınmıştır; gözler görünür kalır ve kırpılabilir.
func _draw_robin_head() -> void:
	_shape(PackedVector2Array(ROBIN_FRINGE), _look.hair)
	draw_line(Vector2(-16, -26), Vector2(28, -26), SUNGLASS_FRAME, 3.0, true)
	_shape(_ellipse(Vector2(2, -26), Vector2(9, 6)), SUNGLASS_LENS)
	_shape(_ellipse(Vector2(20, -26), Vector2(8, 6)), SUNGLASS_LENS)


func _draw_usopp_head() -> void:
	# Uzun burun.
	_draw_limb(Vector2(14, 7), Vector2(48, 4), 8.0, _look.muzzle)
	for tail: Vector2 in [Vector2(-46, -18), Vector2(-48, -4)]:
		_draw_limb(Vector2(-28, -12), tail, 5.0, BANDANA_COLOR)
	_shape(PackedVector2Array(USOPP_BANDANA), BANDANA_COLOR)
	# Keskin nişancı gözlüğü de alındadır.
	for lens: Vector2 in [Vector2(2, -26), Vector2(19, -26)]:
		_shape(_ellipse(lens, Vector2(8, 8)), SLING_COLOR)
		_shape(_ellipse(lens, Vector2(5, 5)), GOGGLE_LENS)


func _draw_franky_head() -> void:
	_shape(PackedVector2Array(FRANKY_POMPADOUR), _look.hair)
	_shape(PackedVector2Array(FRANKY_NOSE), STEEL_COLOR)
	for rivet: Vector2 in [Vector2(9, 3), Vector2(19, 3), Vector2(7, 8), Vector2(21, 8)]:
		draw_circle(rivet, 1.5, FRANKY_RIVET, true, -1.0, true)


func _draw_brook_head() -> void:
	# Burun deliği ve dişler kafatasını belli eder.
	_shape(PackedVector2Array([Vector2(12, 3), Vector2(8, 10), Vector2(16, 10)]), INK)
	var jaw := _move_pose() * 8.0
	_shape(PackedVector2Array([Vector2(-4, 14), Vector2(26, 12), Vector2(24, 20 + jaw), Vector2(-2, 22 + jaw)]), INK if jaw > 0.0 else WHITE)
	for x: float in [2.0, 8.0, 14.0, 20.0]:
		draw_line(Vector2(x, 14), Vector2(x, 21), INK if jaw <= 0.0 else WHITE, 2.0, true)
	_shape(_ellipse(Vector2(-4, -60), Vector2(38, 7)), INK)
	_shape(PackedVector2Array(BROOK_HAT), INK)
	draw_rect(Rect2(-23, -72, 42, 8), HAT_RIBBON)


func _draw_jinbe_head() -> void:
	# Şimşek kaşlar.
	for brow: PackedVector2Array in [
		PackedVector2Array([Vector2(-10, -15), Vector2(-3, -21), Vector2(0, -13), Vector2(9, -9)]),
		PackedVector2Array([Vector2(28, -16), Vector2(21, -21), Vector2(18, -12), Vector2(11, -9)]),
	]:
		draw_polyline(brow, INK, 7.0, true)
		draw_polyline(brow, _look.brow, 4.0, true)
	# Balinaköpekbalığı dişleri.
	for x: float in [3.0, 16.0]:
		_shape(PackedVector2Array([Vector2(x, 25), Vector2(x + 6, 24), Vector2(x + 3, 17)]), WHITE)


func _draw_eyes() -> void:
	if variant != "brook":
		super()
		return
	# İskeletin göz çukurları vardır; kırpınca incelir.
	var height := 2.0 if _next_blink < BLINK_SECONDS else 11.0
	_shape(_ellipse(Vector2(1, -5), Vector2(10, height)), INK)
	_shape(_ellipse(Vector2(18, -5), Vector2(9, height)), INK)


func _draw_zoro_head() -> void:
	_shape(PackedVector2Array(ZORO_HAIR_CAP), _look.hair)
	# Yaralı göz kapalıdır.
	_shape(_ellipse(Vector2(18, -5), Vector2(9, 11)), _look.fur)
	draw_line(Vector2(11, -3), Vector2(25, -3), INK, 3.0, true)
	draw_line(Vector2(19, -17), Vector2(16, 8), SCAR_DARK, 2.5, true)
	for i: int in 3:
		draw_circle(Vector2(33, -6 + i * 6), 2.5, EARRING_COLOR, true, -1.0, true)


func _draw_sanji_head() -> void:
	_shape(PackedVector2Array(SANJI_FRINGE), _look.hair)
	# Kıvrık kaş.
	draw_arc(Vector2(22, -15), 4.0, 0.0, 1.7 * TAU / 2.0, 10, INK, 2.5, true)


func _draw_chopper_head() -> void:
	draw_circle(Vector2(12, 7), 6.5, INK, true, -1.0, true)
	draw_circle(Vector2(12, 7), 4.5, CHOPPER_NOSE_COLOR, true, -1.0, true)
	for side: float in [-1.0, 1.0]:
		var root := Vector2(side * 18, -38)
		var tip := root + Vector2(side * 22, -32)
		_draw_limb(root, tip, 5.0, ANTLER_COLOR)
		_draw_limb(root.lerp(tip, 0.55), root.lerp(tip, 0.55) + Vector2(side * 16, -2), 4.0, ANTLER_COLOR)
	_shape(PackedVector2Array([Vector2(-25, -20), Vector2(-21, -54), Vector2(21, -54), Vector2(25, -20)]), CHOPPER_HAT_COLOR)
	_shape(_ellipse(Vector2(0, -19), Vector2(38, 8)), CHOPPER_HAT_COLOR)
	draw_rect(Rect2(-4, -48, 8, 20), WHITE)
	draw_rect(Rect2(-10, -42, 20, 8), WHITE)


func _draw_gear5_head() -> void:
	for i: int in GEAR5_CLOUDS.size():
		var puff := GEAR5_CLOUDS[i]
		var drift := sin(_time * CLOUD_DRIFT_SPEED + i) * CLOUD_DRIFT
		_shape(_ellipse(Vector2(puff.x, puff.y + drift), Vector2(puff.z, puff.z)), _look.hair)
