extends Node2D

# Hasır Şapka tayfasının maymunları; variant renkleri, saçı ve kıyafeti belirler. Ana karakter
# Luffy'dir: eski kayıtlardaki "monkey" eşyaları bozulmasın diye kimliği "sonic" olarak kalır.
# Diğer tayfa üyelerine özgü çizimler crew_monkey.gd'dedir.
# Tamamı kodla çizilir; koordinatlar gövdeye göredir ve yüz sağa bakar.

enum Pose { STANDING, WRITING }

const INK := Color("#0f172a")
const SKIN := Color("#fde2b8")
const WHITE := Color("#ffffff")
const STRAW_COLOR := Color("#facc15")
const HAT_BAND_COLOR := Color("#dc2626")
const SCAR_COLOR := Color("#7f1d1d")
const PAPER := Color("#f8fafc")
const PAPER_LINE := Color("#94a3b8")
const COVER := Color("#7c3aed")
const PENCIL := Color("#fbbf24")

const OUTLINE := 3.0
const ELLIPSE_POINTS := 24
const LUFFY_HAIR: Array[Vector2] = [
	Vector2(24, -20), Vector2(-30, -22), Vector2(-42, -8), Vector2(-32, -4), Vector2(-40, 10),
	Vector2(-28, 8), Vector2(-30, 22), Vector2(-14, 14), Vector2(6, 8),
]
# Dread'ler ayrı parçalardır; başın arkasından aşağı sarkar.
const DREAD_CAP: Array[Vector2] = [
	Vector2(20, -24), Vector2(-4, -36), Vector2(-28, -26), Vector2(-38, -2), Vector2(-26, 14), Vector2(4, 8),
]
# x, y: başlangıç; z, w: uç.
const DREADS: Array[Vector4] = [
	Vector4(-20, -22, -48, 8), Vector4(-28, -10, -54, 26), Vector4(-26, 2, -46, 44), Vector4(-16, 14, -28, 50),
]
const DREAD_WIDTH := 13.0
const TUFT: Array[Vector2] = [
	Vector2(18, -22), Vector2(14, -48), Vector2(2, -32), Vector2(-12, -52), Vector2(-14, -30),
	Vector2(-34, -38), Vector2(-26, -14), Vector2(-14, 12), Vector2(6, 6),
]
const UP_SPIKES: Array[Vector2] = [
	Vector2(22, -22), Vector2(16, -62), Vector2(2, -34), Vector2(-10, -70), Vector2(-14, -34),
	Vector2(-34, -58), Vector2(-30, -20), Vector2(-22, 10), Vector2(10, 0),
]
const SPIKE_STRIPES: Array[Vector4] = [
	Vector4(15, -56, 11, -36), Vector4(-9, -62, -7, -38), Vector4(-31, -52, -24, -32),
]
const SPIKE_STRIPE_WIDTH := 4.0
const FLAME_SPIKES: Array[Vector2] = [
	Vector2(24, -20), Vector2(26, -58), Vector2(10, -36), Vector2(4, -82), Vector2(-10, -40),
	Vector2(-26, -72), Vector2(-28, -32), Vector2(-48, -46), Vector2(-32, -6), Vector2(-18, 12), Vector2(10, 4),
]
const FLAME_TIPS: Array[int] = [1, 3, 5, 7]
const FLAME_FLICKER := 4.0
const FLAME_SPEED := 9.0
const AURA_CENTER := Vector2(0, -22)
const AURA_RADII: Array[float] = [96.0, 80.0, 66.0]
const AURA_COLOR := Color(1.0, 0.82, 0.2, 0.16)
const AURA_PULSE := 5.0
const AURA_SPEED := 3.0
const TWIN_TAIL_WIDTH := 13.0
const TWIN_TAIL_SPREAD := 0.42
const TWIN_TAIL_SWAY := 0.12
const TWIN_TAIL_SPEED := 5.0
const HOVER_JET_COLOR := Color("#f97316")
const HOVER_JET_LENGTH := 10.0
const HOVER_JET_FLICKER := 4.0
const HOVER_JET_SPEED := 14.0

const LUFFY_VARIANT := "sonic"
const DEFAULT_VARIANT := LUFFY_VARIANT
const VARIANTS := {
	LUFFY_VARIANT: {
		"fur": Color("#b5773f"), "fur_dark": Color("#8a5629"), "iris": INK, "brow": INK,
		"shoe": Color("#a16207"), "strap": Color("#fde68a"), "buckle": Color("#a16207"), "sole": Color("#78350f"),
		"quills": LUFFY_HAIR, "hair": INK, "hand": SKIN, "shirt": Color("#dc2626"), "waist": Color("#2563eb"),
		"thigh": Color("#2563eb"), "thigh_dark": Color("#1d4ed8"),
		"straw_hat": true, "scar": true, "grin": true, "rubber": true,
	},
	"knuckles": {
		"fur": Color("#dc2626"), "fur_dark": Color("#b91c1c"), "iris": Color("#7c3aed"), "brow": INK,
		"shoe": Color("#facc15"), "strap": Color("#22c55e"), "buckle": WHITE, "sole": Color("#15803d"),
		"quills": DREAD_CAP,
	},
	"tails": {
		"fur": Color("#fbbf24"), "fur_dark": Color("#f97316"), "iris": Color("#0284c7"), "brow": INK,
		"shoe": Color("#dc2626"), "strap": WHITE, "buckle": Color("#facc15"), "sole": WHITE,
		"quills": TUFT,
	},
	"shadow": {
		"fur": Color("#27272a"), "fur_dark": Color("#18181b"), "iris": Color("#dc2626"), "brow": Color("#ef4444"),
		"shoe": WHITE, "strap": Color("#dc2626"), "buckle": Color("#facc15"), "sole": Color("#dc2626"),
		"quills": UP_SPIKES,
	},
	"super": {
		"fur": Color("#fde047"), "fur_dark": Color("#f59e0b"), "iris": Color("#be123c"), "brow": INK,
		"shoe": Color("#dc2626"), "strap": WHITE, "buckle": Color("#facc15"), "sole": WHITE,
		"quills": FLAME_SPIKES, "aura": AURA_COLOR,
	},
}

const WRITE_SPEED := 9.0
const WRITE_REACH := 4.0
const BREATH_SPEED := 2.4
const BREATH_AMOUNT := 0.028
# Nefes ve esneme ayak hizasına göre yapılır; ayakkabılar yerde kalır.
const FEET_Y := 62.0
const BLINK_SECONDS := 0.13
const BLINK_MIN_GAP := 2.0
const BLINK_MAX_GAP := 5.5
const HOP_HEIGHT := 48.0
const HOP_SECONDS := 0.17
const SQUASH_SCALE := Vector2(1.18, 0.82)
const STRETCH_SCALE := Vector2(0.88, 1.14)
const SETTLE_SECONDS := 0.35
# Gomu Gomu: kauçuk kollar zıplarken yukarı uzar. Anahtarlar kolun dinlenme ve uzamış halidir.
const BACK_ELBOW := Vector2(-40, 12)
const BACK_ELBOW_STRETCHED := Vector2(-70, -40)
const BACK_HAND := Vector2(-31, 26)
const BACK_HAND_STRETCHED := Vector2(-92, -110)
const FRONT_ELBOW := Vector2(46, -10)
const FRONT_ELBOW_STRETCHED := Vector2(72, -50)
const FRONT_HAND := Vector2(44, -36)
const FRONT_HAND_STRETCHED := Vector2(96, -130)
const OUTFIT_WAIST_RATIO := 0.62

@export var pose := Pose.STANDING:
	set(value):
		pose = value
		queue_redraw()

@export var variant := DEFAULT_VARIANT:
	set(value):
		var table := _variant_table()
		variant = value if table.has(value) else table.keys()[0]
		_look = table[variant]
		queue_redraw()

var _look: Dictionary = VARIANTS[DEFAULT_VARIANT]
var _time := 0.0
var _next_blink := randf_range(BLINK_MIN_GAP, BLINK_MAX_GAP)
var _hop := 0.0
var _squash := Vector2.ONE
# Dokunma hareketinin ilerleyişi: 0 dinlenme, 1 hareketin tepesi.
var _action := 0.0
var _body := Transform2D.IDENTITY
var _bounce_tween: Tween

var writing := false:
	set(value):
		writing = value
		queue_redraw()


func _init(initial_variant := DEFAULT_VARIANT) -> void:
	variant = initial_variant


func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	_time += delta
	_next_blink -= delta
	if _next_blink <= 0.0:
		_next_blink = randf_range(BLINK_MIN_GAP, BLINK_MAX_GAP)
	queue_redraw()


func play_bounce() -> void:
	if _bounce_tween:
		_bounce_tween.kill()
	_hop = 0.0
	_action = 0.0
	_bounce_tween = create_tween()
	_bounce_tween.tween_property(self, "_hop", -HOP_HEIGHT, HOP_SECONDS).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_bounce_tween.parallel().tween_property(self, "_squash", STRETCH_SCALE, HOP_SECONDS)
	_bounce_tween.parallel().tween_property(self, "_action", 1.0, HOP_SECONDS)
	_bounce_tween.tween_property(self, "_hop", 0.0, HOP_SECONDS).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_bounce_tween.parallel().tween_property(self, "_action", 0.0, HOP_SECONDS)
	_bounce_tween.tween_property(self, "_squash", SQUASH_SCALE, HOP_SECONDS / 2.0)
	_bounce_tween.tween_property(self, "_squash", Vector2.ONE, SETTLE_SECONDS).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


# Kendi scale değeri yerleşimi kuran sahnelere aittir; esneme yalnızca çizime uygulanır.
func _body_transform() -> Transform2D:
	var breath := sin(_time * BREATH_SPEED) * BREATH_AMOUNT
	var stretch := _squash * Vector2(1.0 - breath, 1.0 + breath)
	return Transform2D(0.0, stretch, 0.0, Vector2(0.0, FEET_Y * (1.0 - stretch.y) + _hop))


func _draw() -> void:
	_body = _body_transform()
	draw_set_transform_matrix(_body)
	if _look.has("aura"):
		_draw_aura()
	if pose == Pose.WRITING:
		_draw_writing()
	else:
		_draw_standing()


func _draw_standing() -> void:
	_draw_tail(PackedVector2Array([Vector2(-12, 16), Vector2(-34, 22), Vector2(-48, 8), Vector2(-42, -8), Vector2(-30, -6)]))
	_draw_behind_body()
	var kick := _front_foot_offset()
	var arms := _arm_points()
	var back_elbow := arms[0]
	var back_hand := arms[1]
	var front_elbow := arms[2]
	var front_hand := arms[3]
	var arm_scale: float = _look.get("arm_scale", 1.0)
	_draw_limb(Vector2(-9, 22), Vector2(-15, 44), 15.0, _look.fur_dark)
	_draw_limb(Vector2(9, 22), Vector2(15, 44) + kick, 15.0, _look.fur)
	_draw_sneaker(Vector2(-16, 47))
	_draw_sneaker(Vector2(14, 47) + kick)
	if _look.has("waist"):
		_draw_limb(Vector2(-9, 22), Vector2(-12, 33), 18.0, _look.waist)
		_draw_limb(Vector2(9, 22), Vector2(9, 22).lerp(Vector2(15, 44) + kick, 0.5), 18.0, _look.waist)
	_draw_limb(Vector2(-25, -8), back_elbow, 15.0 * arm_scale, _look.get("sleeve_dark", _look.fur_dark))
	_draw_limb(back_elbow, back_hand, 13.0 * arm_scale, _look.get("sleeve_dark", _look.fur_dark))
	_shape(_ellipse(back_hand + Vector2(0, 2), Vector2(9, 9) * arm_scale), _look.get("hand", WHITE))
	_draw_torso(PackedVector2Array([Vector2(-28, -18), Vector2(28, -18), Vector2(14, 26), Vector2(-14, 26)]), Vector2(0, -2))
	# Kaldırılmış kol kasları gösterir.
	_draw_limb(Vector2(25, -8), front_elbow, 17.0 * arm_scale, _look.get("sleeve", _look.fur))
	_draw_limb(front_elbow, front_hand, 14.0 * arm_scale, _look.get("sleeve", _look.fur))
	_shape(_ellipse(Vector2(25, -8).lerp(front_elbow, 0.5), Vector2(11, 8) * arm_scale), _look.get("sleeve_dark", _look.fur_dark))
	_draw_held_item(front_hand)
	_shape(_ellipse(front_hand + Vector2(0, -2), Vector2(10, 10) * arm_scale), _look.get("hand", WHITE))
	_draw_head(Vector2(0, -46), 0.0)
	_draw_action_effects()


func _draw_writing() -> void:
	var stroke := sin(_time * WRITE_SPEED) * WRITE_REACH if writing else 0.0
	_draw_tail(PackedVector2Array([Vector2(-20, -6), Vector2(-46, -6), Vector2(-62, -22), Vector2(-54, -38), Vector2(-42, -34)]))
	# Arkadaki bacak ve defteri tutan kol.
	_draw_limb(Vector2(0, -8), Vector2(58, -16), 16.0, _look.get("thigh_dark", _look.fur_dark))
	_draw_limb(Vector2(58, -16), Vector2(70, 32), 14.0, _look.fur_dark)
	_draw_sneaker(Vector2(72, 36))
	_draw_limb(Vector2(16, -50), Vector2(50, -36), 12.0, _look.fur_dark)
	_draw_torso(PackedVector2Array([Vector2(-24, -4), Vector2(16, -4), Vector2(26, -56), Vector2(-20, -60)]), Vector2(6, -32))
	# Öndeki bacak.
	_draw_limb(Vector2(-4, -6), Vector2(40, -12), 18.0, _look.get("thigh", _look.fur))
	_draw_limb(Vector2(40, -12), Vector2(38, 34), 15.0, _look.fur)
	_draw_sneaker(Vector2(38, 38))
	_draw_notebook(stroke)
	# Yazan kol.
	var hand := Vector2(40 + stroke, -40)
	_draw_limb(Vector2(4, -48), Vector2(14, -24), 15.0, _look.fur)
	_shape(_ellipse(Vector2(7, -38), Vector2(9, 12)), _look.fur_dark)
	_draw_limb(Vector2(14, -24), hand, 13.0, _look.fur)
	_draw_pencil(hand)
	_shape(_ellipse(hand, Vector2(9, 9)), _look.get("hand", WHITE))
	_draw_head(Vector2(10, -88), 0.16)


func _draw_torso(points: PackedVector2Array, chest: Vector2) -> void:
	if _look.has("shirt"):
		# Köşeler pozdan bağımsız olarak üst sol, üst sağ, alt sağ, alt sol sırasına getirilir.
		_draw_outfit(points if pose == Pose.STANDING else PackedVector2Array([points[3], points[2], points[1], points[0]]))
		return
	_shape(points, _look.fur)
	_shape(_ellipse(chest + Vector2(-9, -3), Vector2(10, 9)), SKIN)
	_shape(_ellipse(chest + Vector2(9, -3), Vector2(10, 9)), SKIN)
	_shape(_ellipse(chest + Vector2(0, 15), Vector2(10, 10)), SKIN)


func _draw_outfit(corners: PackedVector2Array) -> void:
	var left_waist := corners[0].lerp(corners[3], OUTFIT_WAIST_RATIO)
	var right_waist := corners[1].lerp(corners[2], OUTFIT_WAIST_RATIO)
	_shape(corners, _look.shirt)
	_shape(PackedVector2Array([
		corners[0].lerp(corners[1], 0.3), corners[0].lerp(corners[1], 0.7), left_waist.lerp(right_waist, 0.5),
	]), _look.get("chest", SKIN))
	_shape(PackedVector2Array([left_waist, right_waist, corners[2], corners[3]]), _look.waist)
	if _look.has("sash"):
		_shape(PackedVector2Array([
			left_waist, right_waist, right_waist.lerp(corners[2], 0.45), left_waist.lerp(corners[3], 0.45),
		]), _look.sash)


func _draw_head(center: Vector2, tilt: float) -> void:
	draw_set_transform_matrix(_body * Transform2D(tilt, center))
	_draw_quills()
	var muzzle: Color = _look.get("muzzle", SKIN)
	var has_ears: bool = _look.get("ears", true)
	if has_ears:
		_shape(_ellipse(Vector2(-29, 2), Vector2(12, 12)), _look.fur)
		_shape(_ellipse(Vector2(-29, 2), Vector2(6, 6)), muzzle)
	_shape(_ellipse(Vector2.ZERO, Vector2(30, 30)), _look.fur)
	if has_ears:
		_shape(_ellipse(Vector2(29, 0), Vector2(9, 11)), _look.fur)
		_shape(_ellipse(Vector2(29, 0), Vector2(4, 6)), muzzle)
	_shape(_ellipse(Vector2(8, 12), Vector2(19, 14)), muzzle)
	_draw_eyes()
	# Kararlı bakış: içe doğru inen kaşlar.
	draw_line(Vector2(-9, -15), Vector2(9, -9), _look.brow, 4.0, true)
	draw_line(Vector2(27, -15), Vector2(11, -9), _look.brow, 4.0, true)
	draw_circle(Vector2(12, 7), 3.0, INK, true, -1.0, true)
	if _look.get("grin", false):
		_draw_grin()
	else:
		draw_polyline(PackedVector2Array([Vector2(0, 17), Vector2(8, 20), Vector2(17, 18), Vector2(23, 13)]), INK, 2.5, true)
	_draw_head_costume()
	draw_set_transform_matrix(_body)


func _draw_head_costume() -> void:
	if _look.get("scar", false):
		_draw_scar()
	if _look.get("straw_hat", false):
		_draw_straw_hat()


func _draw_grin() -> void:
	_shape(PackedVector2Array([Vector2(-5, 13), Vector2(26, 9), Vector2(22, 20), Vector2(12, 26), Vector2(1, 23)]), WHITE)
	draw_line(Vector2(-2, 17), Vector2(24, 15), INK, 1.5, true)


# Sol gözün altındaki dikişli yara izi.
func _draw_scar() -> void:
	draw_line(Vector2(16, 6), Vector2(27, 6), SCAR_COLOR, 2.0, true)
	for x: float in [19.0, 24.0]:
		draw_line(Vector2(x, 3), Vector2(x, 9), SCAR_COLOR, 1.5, true)


func _draw_straw_hat() -> void:
	_shape(PackedVector2Array([Vector2(-24, -22), Vector2(-20, -46), Vector2(-8, -52), Vector2(10, -52), Vector2(22, -46), Vector2(26, -22)]), STRAW_COLOR)
	_shape(PackedVector2Array([Vector2(-24, -22), Vector2(-22, -33), Vector2(24, -33), Vector2(26, -22)]), HAT_BAND_COLOR)
	_shape(_ellipse(Vector2(1, -20), Vector2(46, 9)), STRAW_COLOR)


func _draw_quills() -> void:
	if variant == "knuckles":
		for dread: Vector4 in DREADS:
			_draw_limb(Vector2(dread.x, dread.y), Vector2(dread.z, dread.w), DREAD_WIDTH, _look.fur_dark)
	var points := PackedVector2Array(_look.quills)
	if variant == "super":
		for tip: int in FLAME_TIPS:
			points[tip].x += sin(_time * FLAME_SPEED + tip) * FLAME_FLICKER
			points[tip].y += cos(_time * FLAME_SPEED * 1.3 + tip) * FLAME_FLICKER
	_shape(points, _look.get("hair", _look.fur_dark))
	if variant == "shadow":
		for stripe: Vector4 in SPIKE_STRIPES:
			draw_line(Vector2(stripe.x, stripe.y), Vector2(stripe.z, stripe.w), _look.strap, SPIKE_STRIPE_WIDTH, true)


func _draw_aura() -> void:
	var pulse := sin(_time * AURA_SPEED) * AURA_PULSE
	for radius: float in AURA_RADII:
		draw_circle(AURA_CENTER, radius + pulse, _look.aura, true, -1.0, true)


func _draw_eyes() -> void:
	if _next_blink < BLINK_SECONDS:
		_shape(_ellipse(Vector2(1, -5), Vector2(10, 11)), _look.fur)
		_shape(_ellipse(Vector2(18, -5), Vector2(9, 11)), _look.fur)
		draw_line(Vector2(-7, -3), Vector2(9, -3), _look.brow, 3.0, true)
		draw_line(Vector2(11, -3), Vector2(25, -3), _look.brow, 3.0, true)
		return
	_shape(_ellipse(Vector2(1, -5), Vector2(10, 11)), WHITE)
	_shape(_ellipse(Vector2(18, -5), Vector2(9, 11)), WHITE)
	draw_circle(Vector2(5, -3), 4.5, _look.iris, true, -1.0, true)
	draw_circle(Vector2(21, -3), 4.5, _look.iris, true, -1.0, true)
	draw_circle(Vector2(6, -3), 2.2, INK, true, -1.0, true)
	draw_circle(Vector2(22, -3), 2.2, INK, true, -1.0, true)


func _draw_tail(points: PackedVector2Array) -> void:
	if variant == "tails":
		var sway := sin(_time * TWIN_TAIL_SPEED) * TWIN_TAIL_SWAY
		_draw_fluffy_tail(points, -TWIN_TAIL_SPREAD + sway)
		_draw_fluffy_tail(points, TWIN_TAIL_SPREAD - sway)
		return
	draw_polyline(points, INK, 9.0 + OUTLINE * 2.0, true)
	draw_polyline(points, _look.fur_dark, 9.0, true)


func _draw_fluffy_tail(points: PackedVector2Array, angle: float) -> void:
	var turned := PackedVector2Array()
	for point: Vector2 in points:
		turned.append(points[0] + (point - points[0]).rotated(angle))
	draw_polyline(turned, INK, TWIN_TAIL_WIDTH + OUTLINE * 2.0, true)
	draw_polyline(turned, _look.fur_dark, TWIN_TAIL_WIDTH, true)
	_shape(_ellipse(turned[-1], Vector2(9, 9)), WHITE)


func _draw_limb(from: Vector2, to: Vector2, width: float, color: Color) -> void:
	var outer := width / 2.0 + OUTLINE
	draw_line(from, to, INK, outer * 2.0, true)
	draw_circle(from, outer, INK, true, -1.0, true)
	draw_circle(to, outer, INK, true, -1.0, true)
	draw_line(from, to, color, width, true)
	draw_circle(from, width / 2.0, color, true, -1.0, true)
	draw_circle(to, width / 2.0, color, true, -1.0, true)


func _draw_sneaker(ankle: Vector2) -> void:
	_shape(PackedVector2Array([ankle + Vector2(-13, -8), ankle + Vector2(8, -8), ankle + Vector2(26, 2), ankle + Vector2(32, 10), ankle + Vector2(-14, 10)]), _look.shoe)
	_shape(PackedVector2Array([ankle + Vector2(-1, -8), ankle + Vector2(8, -8), ankle + Vector2(14, -4), ankle + Vector2(6, 9), ankle + Vector2(-5, 9)]), _look.strap)
	_shape(_ellipse(ankle + Vector2(3, 0), Vector2(4, 3)), _look.buckle)
	_shape(PackedVector2Array([ankle + Vector2(-15, 9), ankle + Vector2(33, 9), ankle + Vector2(34, 15), ankle + Vector2(-15, 15)]), _look.sole)
	if variant == "shadow":
		var jet := HOVER_JET_LENGTH + sin(_time * HOVER_JET_SPEED + ankle.x) * HOVER_JET_FLICKER
		_shape(PackedVector2Array([ankle + Vector2(-8, 16), ankle + Vector2(20, 16), ankle + Vector2(6, 16 + jet)]), HOVER_JET_COLOR)


func _draw_notebook(stroke: float) -> void:
	var corners := PackedVector2Array([Vector2(24, -36), Vector2(70, -46), Vector2(76, -20), Vector2(30, -12)])
	var pages := PackedVector2Array([Vector2(27, -38), Vector2(69, -47), Vector2(74, -24), Vector2(32, -16)])
	_shape(corners, COVER)
	_shape(pages, PAPER)
	for i: int in 3:
		var from := pages[0].lerp(pages[3], 0.25 + i * 0.25)
		var to := pages[1].lerp(pages[2], 0.25 + i * 0.25)
		draw_line(from, from.lerp(to, 0.8 + stroke * 0.02), PAPER_LINE, 1.5, true)


func _draw_pencil(hand: Vector2) -> void:
	var tip := hand + Vector2(16, 12)
	draw_line(hand + Vector2(-8, -10), tip, INK, 7.0, true)
	draw_line(hand + Vector2(-8, -10), tip, PENCIL, 4.0, true)


# Alt sınıfların (tayfa üyeleri) doldurduğu çizim kancaları.
func _variant_table() -> Dictionary:
	return VARIANTS


func _front_foot_offset() -> Vector2:
	return Vector2.ZERO


# Sırasıyla arka dirsek, arka el, ön dirsek, ön el.
func _arm_points() -> Array[Vector2]:
	var stretch: float = _action if _look.get("rubber", false) else 0.0
	return [
		BACK_ELBOW.lerp(BACK_ELBOW_STRETCHED, stretch), BACK_HAND.lerp(BACK_HAND_STRETCHED, stretch),
		FRONT_ELBOW.lerp(FRONT_ELBOW_STRETCHED, stretch), FRONT_HAND.lerp(FRONT_HAND_STRETCHED, stretch),
	]


func _draw_behind_body() -> void:
	pass


func _draw_held_item(_hand: Vector2) -> void:
	pass


func _draw_action_effects() -> void:
	pass


func _shape(points: PackedVector2Array, fill: Color) -> void:
	draw_colored_polygon(points, fill)
	var line := points.duplicate()
	line.append(points[0])
	draw_polyline(line, INK, OUTLINE, true)


func _ellipse(center: Vector2, radii: Vector2) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i: int in ELLIPSE_POINTS:
		var angle := TAU * i / ELLIPSE_POINTS
		points.append(center + Vector2(cos(angle), sin(angle)) * radii)
	return points
