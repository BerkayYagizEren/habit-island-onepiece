extends Node2D

const DRAG_SCALE := Vector2(1.15, 1.15)
const DRAG_Z_INDEX := 100
const SCALE_SECONDS := 0.12
const SNAP_SECONDS := 0.2
const POP_SECONDS := 0.3
const SHADOW_CENTER := Vector2(0, 42)
const SHADOW_SCALE := Vector2(1.0, 0.3)
const SHADOW_RADIUS := 42.0
const SHADOW_COLOR := Color(0.05, 0.2, 0.15, 0.32)
# Tutulan eşyanın gölgesi aşağı kayar ve solar; eşya havalanmış görünür.
const LIFTED_SHADOW_OFFSET := Vector2(0, 18)
const LIFTED_SHADOW_COLOR := Color(0.05, 0.2, 0.15, 0.18)
const UNKNOWN_ICON := "❓"
const CREW_MONKEY := preload("res://scripts/crew_monkey.gd")
const MONKEY_SCALE := Vector2(0.72, 0.72)
const CAMPFIRE_FLAME := preload("res://scripts/campfire_flame.gd")
const CAMPFIRE_OFFSET := Vector2(0, 34)
# Etiket döndürülür ve esnetilir; tabanı yerde kalır, HitArea ve dokunma sınırı değişmez.
const EMOJI_PIVOT := Vector2(56, 100)
const SWAY_ITEMS: Array[String] = ["palm", "jolly_roger"]
const SWAY_ANGLE := 0.07
const SWAY_SPEED := 1.5
# Bu kadar az oynayıp kısa sürede bırakılan basış sürükleme değil dokunuştur.
const TAP_MAX_MOVE := 12.0
const TAP_MAX_MSEC := 400
const WOBBLE_SQUASH := Vector2(1.22, 0.8)
const WOBBLE_STRETCH := Vector2(0.88, 1.15)
const WOBBLE_STEP_SECONDS := 0.08
const WOBBLE_SETTLE_SECONDS := 0.4
const BUBBLE_TEXT := "🍌!"
const BUBBLE_START := Vector2(0, -88)
const BUBBLE_RISE := 42.0
const BUBBLE_POP_SECONDS := 0.16
const BUBBLE_RISE_SECONDS := 1.1
const BUBBLE_FADE_SECONDS := 0.4
const BUBBLE_RECT := Rect2(-52, -56, 104, 56)
const BUBBLE_CORNER := 26
const BUBBLE_BORDER := 3
const BUBBLE_FONT_SIZE := 30
const BUBBLE_Z_INDEX := 50
const BUBBLE_INK := Color("#0f172a")

@export var item_id := ""
@export var item_type := ""

var _is_dragging := false
var _drag_offset := Vector2.ZERO
var _scale_tween: Tween
var _snap_tween: Tween
var _wobble_tween: Tween
var _visual: CanvasItem
var _monkey: Node2D
var _bubble: Node2D
var _press_position := Vector2.ZERO
var _press_msec := 0
var _sway_time := randf() * TAU

@onready var _hit_area: Control = %HitArea
@onready var _emoji: Label = %Emoji


func _ready() -> void:
	var entry: Dictionary = DataManager.ISLAND_ITEMS.get(item_type, {})
	_emoji.pivot_offset = EMOJI_PIVOT
	_visual = _emoji
	if entry.has("variant"):
		_add_monkey(entry.variant)
	elif item_type == "campfire":
		_add_campfire()
	else:
		_emoji.text = entry.get("icon", UNKNOWN_ICON)
	set_process(item_type in SWAY_ITEMS)
	_hit_area.gui_input.connect(_on_hit_area_gui_input)


func _process(delta: float) -> void:
	_sway_time += delta
	_emoji.rotation = sin(_sway_time * SWAY_SPEED) * SWAY_ANGLE


func _draw() -> void:
	var center := SHADOW_CENTER + LIFTED_SHADOW_OFFSET if _is_dragging else SHADOW_CENTER
	draw_set_transform(center, 0.0, SHADOW_SCALE)
	draw_circle(Vector2.ZERO, SHADOW_RADIUS, LIFTED_SHADOW_COLOR if _is_dragging else SHADOW_COLOR, true, -1.0, true)


func _notification(what: int) -> void:
	# Uygulama sürükleme sırasında arka plana giderse bırakma olayı hiç gelmeyebilir.
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_APPLICATION_PAUSED:
		_finish_drag()


func _add_monkey(variant: String) -> void:
	_monkey = CREW_MONKEY.create(variant)
	_monkey.scale = MONKEY_SCALE
	add_child(_monkey)
	_visual = _monkey


func _add_campfire() -> void:
	var flame: Node2D = CAMPFIRE_FLAME.new()
	flame.position = CAMPFIRE_OFFSET
	add_child(flame)
	_visual = flame


func play_pop_animation() -> void:
	scale = Vector2.ZERO
	_animate_scale(Vector2.ONE, POP_SECONDS).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


# Dokunmatik olaylar emulate_mouse_from_touch ile fare olayı olarak gelir; ScreenTouch
# ayrıca işlenirse tek dokunuş iki kez sayılır.
func _on_hit_area_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_start_drag(event.position)
		else:
			# Odak kaybıyla biten sürükleme burada zaten bitmiş olur; sessiz kalır.
			if _is_dragging:
				SoundManager.play_pop()
				if _is_tap():
					_play_tap_reaction()
			_finish_drag()
		_hit_area.accept_event()
	elif event is InputEventMouseMotion and _is_dragging:
		position = _to_parent_space(event.position) + _drag_offset
		_hit_area.accept_event()


# Olayın konumu eşyanın o anki ölçeğine göre yereldir; global_position ise pencere
# ölçeklemesinden etkilenir.
func _to_parent_space(hit_area_point: Vector2) -> Vector2:
	return transform * _hit_area.get_transform() * hit_area_point


func _is_tap() -> bool:
	return position.distance_to(_press_position) < TAP_MAX_MOVE and Time.get_ticks_msec() - _press_msec < TAP_MAX_MSEC


func _play_tap_reaction() -> void:
	if _monkey:
		_monkey.play_bounce()
		_show_bubble()
	else:
		_play_wobble()


func _play_wobble() -> void:
	if _wobble_tween:
		_wobble_tween.kill()
	_wobble_tween = create_tween()
	_wobble_tween.tween_property(_visual, "scale", WOBBLE_SQUASH, WOBBLE_STEP_SECONDS)
	_wobble_tween.tween_property(_visual, "scale", WOBBLE_STRETCH, WOBBLE_STEP_SECONDS)
	_wobble_tween.tween_property(_visual, "scale", Vector2.ONE, WOBBLE_SETTLE_SECONDS).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


func _show_bubble() -> void:
	if is_instance_valid(_bubble):
		_bubble.queue_free()
	_bubble = _create_bubble()
	_bubble.position = BUBBLE_START
	_bubble.scale = Vector2.ZERO
	add_child(_bubble)
	var tween := _bubble.create_tween()
	tween.tween_property(_bubble, "scale", Vector2.ONE, BUBBLE_POP_SECONDS).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(_bubble, "position:y", BUBBLE_START.y - BUBBLE_RISE, BUBBLE_RISE_SECONDS)
	tween.tween_property(_bubble, "modulate:a", 0.0, BUBBLE_FADE_SECONDS)
	tween.tween_callback(_bubble.queue_free)


# Konuşma balonu kodla kurulur: gömülü emoji fontu yalnızca arayüzde kullanılanları içerir.
func _create_bubble() -> Node2D:
	var bubble := Node2D.new()
	bubble.z_index = BUBBLE_Z_INDEX

	var tail_outline := Polygon2D.new()
	tail_outline.polygon = PackedVector2Array([Vector2(-14, -4), Vector2(14, -4), Vector2(0, 18)])
	tail_outline.color = BUBBLE_INK
	bubble.add_child(tail_outline)

	var style := StyleBoxFlat.new()
	style.bg_color = Color.WHITE
	style.border_color = BUBBLE_INK
	style.set_border_width_all(BUBBLE_BORDER)
	style.set_corner_radius_all(BUBBLE_CORNER)

	var label := Label.new()
	label.text = DataManager.ISLAND_ITEMS.get(item_type, {}).get("bubble", BUBBLE_TEXT)
	label.position = BUBBLE_RECT.position
	label.size = BUBBLE_RECT.size
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_stylebox_override("normal", style)
	label.add_theme_font_size_override("font_size", BUBBLE_FONT_SIZE)
	label.add_theme_color_override("font_color", BUBBLE_INK)
	label.add_theme_constant_override("outline_size", 0)
	bubble.add_child(label)

	var tail := Polygon2D.new()
	tail.polygon = PackedVector2Array([Vector2(-9, -5), Vector2(9, -5), Vector2(0, 12)])
	tail.color = Color.WHITE
	bubble.add_child(tail)
	return bubble


func _start_drag(pointer: Vector2) -> void:
	if _snap_tween:
		_snap_tween.kill()
	_is_dragging = true
	_press_position = position
	_press_msec = Time.get_ticks_msec()
	queue_redraw()
	_drag_offset = position - _to_parent_space(pointer)
	z_index = DRAG_Z_INDEX
	_animate_scale(DRAG_SCALE, SCALE_SECONDS)


func _finish_drag() -> void:
	if not _is_dragging:
		return
	_is_dragging = false
	queue_redraw()
	z_index = 0
	_animate_scale(Vector2.ONE, SCALE_SECONDS)

	var target := DataManager.clamp_to_island(position)
	if target != position:
		_snap_tween = create_tween()
		_snap_tween.tween_property(self, "position", target, SNAP_SECONDS).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	DataManager.update_item_position(item_id, target)


func _animate_scale(target: Vector2, seconds: float) -> PropertyTweener:
	if _scale_tween:
		_scale_tween.kill()
	_scale_tween = create_tween()
	return _scale_tween.tween_property(self, "scale", target, seconds)
