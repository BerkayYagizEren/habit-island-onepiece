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


static func create(monkey_variant: String) -> Node2D:
	var script: GDScript = load("res://scripts/crew_monkey.gd") if CREW_VARIANTS.has(monkey_variant) else SONIC_MONKEY
	return script.new(monkey_variant)


func _variant_table() -> Dictionary:
	return CREW_VARIANTS


func _front_foot_offset() -> Vector2:
	return KICK_REACH * _action if variant == "sanji" else Vector2.ZERO


func _draw_behind_body() -> void:
	if variant == "zoro":
		# Belde taşınan diğer iki kılıç.
		for i: int in 2:
			var grip := Vector2(-16, 10 + i * 8)
			_draw_katana(grip, grip + Vector2(-46, 24 + i * 6), KATANA_HANDLES[i + 1], INK)


func _draw_held_item(hand: Vector2) -> void:
	if variant != "zoro":
		return
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
	if variant == "sanji":
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
