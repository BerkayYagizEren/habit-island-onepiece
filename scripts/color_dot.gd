extends Control

const OUTLINE_COLOR := Color("#475569")
const OUTLINE_WIDTH := 2.5
const RADIUS := 12.0

@export var color := Color.WHITE
@export var radius := RADIUS


func _draw() -> void:
	draw_circle(size / 2.0, radius, color, true, -1.0, true)
	draw_circle(size / 2.0, radius, OUTLINE_COLOR, false, OUTLINE_WIDTH, true)
