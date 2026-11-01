extends BaseButton

const DOODLE := preload("res://scripts/doodle.gd")

const INK_COLOR := Color("#1f1208")
const SHADOW_COLOR := Color(0, 0, 0, 0.35)
const DISABLED_FILL_COLOR := Color("#cbd5e1")
const DISABLED_CAPTION_COLOR := Color("#475569")
const HOVER_LIGHTEN := 0.12
const HIGHLIGHT_ALPHA := 0.35
const OUTLINE_WIDTH := 5.0
const SKETCH_WIDTH := 2.0
const WOBBLE := 2.5
const INSET := 8.0
const SHADOW_OFFSET := Vector2(0, 7)
const PRESSED_OFFSET := Vector2(0, 5)
const CAPTION_OUTLINE := 2
const POP_SCALE := Vector2(1.08, 1.08)
const POP_SECONDS := 0.14

@export var caption := "":
	set(value):
		caption = value
		queue_redraw()
@export var fill_color := Color("#dc2626")
@export var rim_color := Color("#991b1b")
@export var caption_color := Color.WHITE
@export var font_size := 48
@export_range(-0.2, 0.2) var tilt := -0.015
@export var stroke_seed := 1.7


func play_pop() -> void:
	pivot_offset = size / 2.0
	var tween := create_tween()
	tween.tween_property(self, "scale", POP_SCALE, POP_SECONDS).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2.ONE, POP_SECONDS)


func _draw() -> void:
	var offset := PRESSED_OFFSET if get_draw_mode() == DRAW_PRESSED else Vector2.ZERO
	var rect := Rect2(Vector2.ONE * INSET, size - Vector2.ONE * INSET * 2.0)
	var fill := DISABLED_FILL_COLOR if disabled else fill_color
	if get_draw_mode() == DRAW_HOVER:
		fill = fill.lightened(HOVER_LIGHTEN)

	draw_set_transform(size / 2.0, tilt, Vector2.ONE)
	rect.position -= size / 2.0
	var body := DOODLE.wobbly_rect(Rect2(rect.position + offset, rect.size), WOBBLE, stroke_seed)
	if offset == Vector2.ZERO:
		draw_set_transform(size / 2.0 + SHADOW_OFFSET, tilt, Vector2.ONE)
		draw_colored_polygon(body, SHADOW_COLOR if disabled else rim_color)
		draw_set_transform(size / 2.0, tilt, Vector2.ONE)
	draw_colored_polygon(body, fill)
	var shine := Rect2(rect.position + offset + Vector2(14, 8), Vector2(rect.size.x - 28, rect.size.y * 0.28))
	draw_colored_polygon(DOODLE.wobbly_rect(shine, 1.0, stroke_seed), Color(1, 1, 1, HIGHLIGHT_ALPHA))
	# İkinci, biraz kaçık çizgi kalemle iki kez üzerinden geçilmiş gibi görünür.
	draw_polyline(DOODLE.closed(body), INK_COLOR, OUTLINE_WIDTH, true)
	draw_polyline(DOODLE.closed(DOODLE.wobbly_rect(Rect2(rect.position + offset, rect.size).grow(2.0), WOBBLE, stroke_seed + 2.1)), INK_COLOR, SKETCH_WIDTH, true)
	_draw_caption(rect.position + offset, rect.size)
	draw_set_transform(Vector2.ZERO)


func _draw_caption(origin: Vector2, area: Vector2) -> void:
	var font := get_theme_default_font()
	var baseline := origin.y + (area.y + font.get_ascent(font_size) - font.get_descent(font_size)) / 2.0
	var text_origin := Vector2(origin.x, baseline)
	var color := DISABLED_CAPTION_COLOR if disabled else caption_color
	draw_string(font, text_origin, caption, HORIZONTAL_ALIGNMENT_CENTER, area.x, font_size, color)
	draw_string_outline(font, text_origin, caption, HORIZONTAL_ALIGNMENT_CENTER, area.x, font_size, CAPTION_OUTLINE, color)
