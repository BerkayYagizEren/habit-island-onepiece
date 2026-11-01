extends SceneTree

const OUT := "res://assets/theme/cartoon_theme.tres"
const INK := Color("#78350f")
const WOOD := Color("#92400e")
const PARCHMENT := Color("#fffbeb")
const WHITE := Color("#ffffff")
const R := 20
var t := Theme.new()

func flat(bg, rim := Color.TRANSPARENT, rim_w := 0, radius := R, mx := 16, my := 10, border := 0) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(bg)
	s.border_color = Color(rim)
	s.set_border_width_all(border)
	s.border_width_bottom = max(rim_w, border)
	s.set_corner_radius_all(radius)
	s.content_margin_left = mx
	s.content_margin_right = mx
	s.content_margin_top = my
	s.content_margin_bottom = my + rim_w
	s.corner_detail = 10
	s.anti_aliasing = true
	return s

func sunk(s: StyleBoxFlat, bg, rim_w := 2) -> StyleBoxFlat:
	var p: StyleBoxFlat = s.duplicate()
	var shift := s.border_width_bottom - rim_w
	p.bg_color = Color(bg)
	p.border_width_bottom = rim_w
	p.content_margin_top += shift
	p.content_margin_bottom -= shift
	return p

func text_colors(type: String, normal: Color, outline: Color, size: int, pressed := Color.TRANSPARENT) -> void:
	var on := normal if pressed == Color.TRANSPARENT else pressed
	t.set_color("font_color", type, normal)
	t.set_color("font_hover_color", type, normal)
	t.set_color("font_focus_color", type, normal)
	t.set_color("font_pressed_color", type, on)
	t.set_color("font_hover_pressed_color", type, on)
	t.set_color("font_disabled_color", type, Color("#a8a29e"))
	t.set_color("font_outline_color", type, outline)
	t.set_constant("outline_size", type, size)

func button_states(type: String, normal: StyleBox, hover: StyleBox, pressed: StyleBox, hover_pressed: StyleBox) -> void:
	t.set_stylebox("normal", type, normal)
	t.set_stylebox("hover", type, hover)
	t.set_stylebox("pressed", type, pressed)
	t.set_stylebox("hover_pressed", type, hover_pressed)
	t.set_stylebox("focus", type, StyleBoxEmpty.new())
	var d := flat("#f5efdc", "#d6c9a8", 5)
	if normal is StyleBoxFlat:
		d.set_corner_radius_all(normal.corner_radius_top_left)
		d.content_margin_left = normal.content_margin_left
		d.content_margin_right = normal.content_margin_right
		d.content_margin_top = normal.content_margin_top
		d.content_margin_bottom = normal.content_margin_bottom
	t.set_stylebox("disabled", type, d)

func chunky(type, bg, hover, down, rim, ink, outline, outline_size := 2, radius := R, m := 16, rim_w := 6, base := "Button") -> void:
	if type != base:
		t.set_type_variation(type, base)
	var n := flat(bg, rim, rim_w, radius, m, 10)
	var h: StyleBoxFlat = n.duplicate()
	h.bg_color = Color(hover)
	var p := sunk(n, down)
	button_states(type, n, h, p, p)
	text_colors(type, Color(ink), Color(outline), outline_size)

# Seçilebilen hap: seçiliyken doygun renk ve 3D taban, seçili değilken pastel ya da düz.
func toggle(type, pastel, pastel_rim, vivid, rim, ink, flat_when_off := false, radius := 24, on_ink := WHITE) -> void:
	t.set_type_variation(type, "Button")
	var on := flat(vivid, rim, 6, radius, 8, 10)
	var off: StyleBox
	var hover: StyleBoxFlat
	if flat_when_off:
		var e := StyleBoxEmpty.new()
		e.content_margin_left = 8
		e.content_margin_right = 8
		e.content_margin_top = 10
		e.content_margin_bottom = 16
		off = e
		hover = flat(pastel, pastel_rim, 6, radius, 8, 10)
	else:
		off = flat(pastel, pastel_rim, 6, radius, 8, 10)
		hover = off.duplicate()
		hover.bg_color = Color(pastel).lightened(0.3)
	button_states(type, off, hover, on, on)
	text_colors(type, Color(ink), Color(ink), 1, on_ink)
	# Seçili yazı beyaz olduğu için kalınlaştırma konturu görünmez kalır; ince tutulur.
	t.set_color("font_outline_color", type, Color(ink, 0.0))
	t.set_constant("outline_size", type, 0)

func panel(type, s: StyleBoxFlat) -> void:
	t.set_type_variation(type, "PanelContainer")
	t.set_stylebox("panel", type, s)

func floating(s: StyleBoxFlat) -> StyleBoxFlat:
	s.shadow_color = Color(0.27, 0.1, 0.01, 0.25)
	s.shadow_size = 14
	s.shadow_offset = Vector2(0, 6)
	return s

func label(type, color) -> void:
	t.set_type_variation(type, "Label")
	t.set_color("font_color", type, Color(color))
	t.set_color("font_outline_color", type, Color(color))
	t.set_constant("outline_size", type, 2)

func _initialize() -> void:
	t.default_font_size = 24

	t.set_color("font_color", "Label", INK)
	t.set_color("font_outline_color", "Label", INK)
	t.set_constant("outline_size", "Label", 1)
	t.set_color("font_shadow_color", "Label", Color.TRANSPARENT)
	label("TimeLabel", "#0369a1")
	label("StreakLabel", "#dc2626")
	label("PriceLabel", "#92400e")
	label("BananaLabel", "#92400e")
	label("LevelLabel", "#15803d")
	label("HeadingLabel", "#0369a1")
	# Kart dışında, doğrudan okyanus zemininde duran başlıklar.
	label("SeaLabel", PARCHMENT)

	# Butonlar.
	chunky("Button", "#fffbeb", "#fffdf5", "#fef3c7", "#d97706", INK, INK, 0, R, 16, 6)
	chunky("SkyButton", "#0284c7", "#0ea5e9", "#0369a1", "#075985", WHITE, "#075985", 4)
	chunky("GreenButton", "#16a34a", "#22c55e", "#15913f", "#15803d", WHITE, "#166534", 4)
	chunky("MintButton", "#d1fae5", "#ecfdf5", "#a7f3d0", "#059669", "#166534", "#166534", 1)
	chunky("GoldButton", "#eab308", "#facc15", "#ca8a04", "#854d0e", INK, INK, 0)
	chunky("SoftRedButton", "#fee2e2", "#fef2f2", "#fecaca", "#dc2626", "#991b1b", "#991b1b", 1)
	chunky("RoundButton", "#fde68a", "#fef3c7", "#facc15", "#b45309", INK, INK, 0, 30, 6, 5)
	chunky("CloseButton", "#dc2626", "#ef4444", "#b91c1c", "#991b1b", WHITE, "#991b1b", 1, 34, 6, 5)

	# Devre dışı durumda kontur rengi değişmez; yazı konturla aynı renge geçer.
	t.set_color("font_disabled_color", "SkyButton", Color("#075985"))
	t.set_color("font_disabled_color", "GreenButton", Color("#166534"))

	toggle("PresetSky", "#e0f2fe", "#0284c7", "#0284c7", "#075985", "#0369a1")
	toggle("PresetGreen", "#ecfdf5", "#16a34a", "#16a34a", "#15803d", "#15803d")
	toggle("PresetOrange", "#fef9c3", "#eab308", "#eab308", "#854d0e", INK, false, 24, INK)
	toggle("PresetPink", "#fee2e2", "#dc2626", "#dc2626", "#991b1b", "#991b1b")
	# Tüm sekmeler aynı hasır şapka kırmızısı hapla vurgulanır.
	for tab: String in ["TabSky", "TabGreen", "TabOrange", "TabPurple"]:
		toggle(tab, "#fef3c7", "#eab308", "#dc2626", "#991b1b", INK, true)

	# Paneller.
	panel("FloatingPill", floating(flat(PARCHMENT, "#dc2626", 4, 36, 12, 10, 3)))
	panel("DeckPill", floating(flat(PARCHMENT, WOOD, 6, 36, 12, 10, 3)))
	panel("BananaChip", flat("#fef9c3", "#eab308", 0, 24, 14, 6, 3))
	panel("XpChip", flat("#fef3c7", "#b45309", 0, 24, 14, 6, 3))
	panel("HabitCard", flat("#fffdf5", "#b45309", 4, 16, 16, 14, 2))
	panel("HabitCardDone", flat("#ecfdf5", "#059669", 4, 16, 16, 14, 2))
	panel("StreakBadge", flat("#fee2e2", "#dc2626", 0, 14, 12, 3))
	panel("TimerBubble", floating(flat(PARCHMENT, "#eab308", 8, 56, 24, 28, 4)))
	panel("ShopBox", floating(flat("#fef3c7", WOOD, 10, 32, 24, 24, 5)))
	panel("IconBubble", flat(PARCHMENT, "#d97706", 4, 24, 8, 4))
	for entry: Array in [["Sky", "#e0f2fe", "#0284c7"], ["Mint", "#ecfdf5", "#059669"], ["Lemon", "#fef9c3", "#eab308"], ["Peach", "#fef3c7", "#d97706"], ["Lilac", "#fffbeb", "#92400e"], ["Rose", "#fee2e2", "#dc2626"]]:
		panel("Pastel" + entry[0], flat(entry[1], entry[2], 5, 20, 16, 14))
	panel("BadgeEarned", flat("#fef9c3", "#eab308", 5, 20, 16, 14))
	panel("BadgeLocked", flat("#f5efdc", "#d6c9a8", 5, 20, 16, 14))

	# XP çubuğu.
	var track := flat("#fef3c7", Color.TRANSPARENT, 0, 10, 0, 0)
	var fill := flat("#eab308", Color.TRANSPARENT, 0, 10, 0, 0)
	t.set_stylebox("background", "ProgressBar", track)
	t.set_stylebox("fill", "ProgressBar", fill)

	# Kaydırma çubuğu.
	var grab := flat("#b45309", Color.TRANSPARENT, 0, 6, 5, 5)
	var grab_on := flat("#78350f", Color.TRANSPARENT, 0, 6, 5, 5)
	var empty := StyleBoxEmpty.new()
	t.set_stylebox("scroll", "VScrollBar", empty)
	t.set_stylebox("scroll_focus", "VScrollBar", empty)
	t.set_stylebox("grabber", "VScrollBar", grab)
	t.set_stylebox("grabber_highlight", "VScrollBar", grab_on)
	t.set_stylebox("grabber_pressed", "VScrollBar", grab_on)

	# Metin girişi.
	var edit := flat("#fffdf5", "#d97706", 0, 16, 14, 12, 3)
	t.set_stylebox("normal", "LineEdit", edit)
	t.set_stylebox("focus", "LineEdit", StyleBoxEmpty.new())
	t.set_color("font_color", "LineEdit", INK)
	t.set_color("font_placeholder_color", "LineEdit", Color("#a8a29e"))
	t.set_color("caret_color", "LineEdit", Color("#dc2626"))
	t.set_color("selection_color", "LineEdit", Color("#fde68a"))

	# Diyaloglar: gemi ahşabı başlık, parşömen gövde.
	var win := StyleBoxFlat.new()
	win.bg_color = PARCHMENT
	win.border_color = WOOD
	win.border_width_top = 44
	win.set_corner_radius_all(24)
	win.corner_detail = 10
	win.expand_margin_left = 12
	win.expand_margin_right = 12
	win.expand_margin_bottom = 12
	win.expand_margin_top = 44
	win.shadow_color = Color(0.27, 0.1, 0.01, 0.35)
	win.shadow_size = 16
	t.set_stylebox("embedded_border", "Window", win)
	t.set_stylebox("embedded_unfocused_border", "Window", win)
	t.set_color("title_color", "Window", WHITE)
	t.set_constant("title_height", "Window", 44)
	var dialog_panel := StyleBoxFlat.new()
	dialog_panel.bg_color = PARCHMENT
	dialog_panel.set_content_margin_all(12)
	t.set_stylebox("panel", "AcceptDialog", dialog_panel)
	t.set_color("title_color", "AcceptDialog", WHITE)

	var err := ResourceSaver.save(t, OUT)
	print("saved ", err)
	quit(err)
