extends RefCounted

const POINT_COUNT := 48
const ROUNDNESS := 5.0


# Köşeleri yuvarlak, kenarları hafif titrek bir kapalı şekil: el çizimi görünümü verir.
# Aynı "stroke" değeri her karede aynı şekli üretir, böylece çizim titremez.
static func wobbly_rect(rect: Rect2, wobble: float, stroke: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	var center := rect.get_center()
	var exponent := 2.0 / ROUNDNESS
	for i: int in POINT_COUNT:
		var angle := TAU * i / POINT_COUNT
		var direction := Vector2(cos(angle), sin(angle))
		var edge := Vector2(
			signf(direction.x) * pow(absf(direction.x), exponent) * rect.size.x / 2.0,
			signf(direction.y) * pow(absf(direction.y), exponent) * rect.size.y / 2.0
		)
		var noise := sin(angle * 5.0 + stroke) + sin(angle * 11.0 + stroke * 2.3) * 0.5
		points.append(center + edge + direction * noise * wobble)
	return points


static func closed(points: PackedVector2Array) -> PackedVector2Array:
	var line := points.duplicate()
	line.append(points[0])
	return line
