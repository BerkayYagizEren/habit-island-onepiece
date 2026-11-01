extends SceneTree

const OUT := "res://assets/theme/cartoon_theme.tres"
const SLATE := Color("#334155")
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
	t.set_color("font_disabled_color", type, Color("#94a3b8"))
	t.set_color("font_outline_color", type, outline)
	t.set_constant("outline_size", type, size)

func button_states(type: String, normal: StyleBox, hover: StyleBox, pressed: StyleBox, hover_pressed: StyleBox) -> void:
	t.set_stylebox("normal", type, normal)
	t.set_stylebox("hover", type, hover)
	t.set_stylebox("pressed", type, pressed)
	t.set_stylebox("hover_pressed", type, hover_pressed)
	t.set_stylebox("focus", type, StyleBoxEmpty.new())
	var d := flat("#e2e8f0", "#cbd5e1", 5)
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
func toggle(type, pastel, pastel_rim, vivid, rim, ink, flat_when_off := false, radius := 24) -> void:
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
	text_colors(type, Color(ink), Color(ink), 1, WHITE)
	# Seçili yazı beyaz olduğu için kalınlaştırma konturu görünmez kalır; ince tutulur.
	t.set_color("font_outline_color", type, Color(ink, 0.0))
	t.set_constant("outline_size", type, 0)

func panel(type, s: StyleBoxFlat) -> void:
	t.set_type_variation(type, "PanelContainer")
	t.set_stylebox("panel", type, s)

func floating(s: StyleBoxFlat) -> StyleBoxFlat:
	s.shadow_color = Color(0.12, 0.25, 0.4, 0.18)
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

	t.set_color("font_color", "Label", SLATE)
	t.set_color("font_outline_color", "Label", SLATE)
	t.set_constant("outline_size", "Label", 1)
	t.set_color("font_shadow_color", "Label", Color.TRANSPARENT)
	label("TimeLabel", "#0369a1")
	label("StreakLabel", "#ea580c")
	label("PriceLabel", "#b45309")
	label("BananaLabel", "#b45309")
	label("LevelLabel", "#15803d")
	label("HeadingLabel", "#0369a1")

	# Butonlar.
	chunky("Button", "#ffffff", "#f8fafc", "#f1f5f9", "#cbd5e1", SLATE, SLATE, 0, R, 16, 6)
	chunky("SkyButton", "#38bdf8", "#7dd3fc", "#0ea5e9", "#0284c7", WHITE, "#0369a1", 4)
	chunky("GreenButton", "#22c55e", "#4ade80", "#16a34a", "#15803d", WHITE, "#166534", 4)
	chunky("MintButton", "#bbf7d0", "#d1fae5", "#86efac", "#4ade80", "#166534", "#166534", 1)
	chunky("GoldButton", "#fbbf24", "#fcd34d", "#f59e0b", "#d97706", "#78350f", "#78350f", 0)
	chunky("SoftRedButton", "#fee2e2", "#fef2f2", "#fecaca", "#fca5a5", "#b91c1c", "#b91c1c", 1)
	chunky("RoundButton", "#ffffff", "#f8fafc", "#f1f5f9", "#cbd5e1", SLATE, SLATE, 0, 30, 6, 5)
	chunky("CloseButton", "#fee2e2", "#fef2f2", "#fecaca", "#fca5a5", "#b91c1c", "#b91c1c", 1, 34, 6, 5)

	# Devre dışı durumda kontur rengi değişmez; yazı konturla aynı renge geçer.
	t.set_color("font_disabled_color", "SkyButton", Color("#0369a1"))
	t.set_color("font_disabled_color", "GreenButton", Color("#166534"))

	toggle("PresetSky", "#e0f2fe", "#7dd3fc", "#38bdf8", "#0284c7", "#0369a1")
	toggle("PresetGreen", "#dcfce7", "#86efac", "#22c55e", "#15803d", "#166534")
	toggle("PresetOrange", "#ffedd5", "#fdba74", "#f97316", "#c2410c", "#c2410c")
	toggle("PresetPink", "#fce7f3", "#f9a8d4", "#ec4899", "#be185d", "#be185d")
	toggle("TabSky", "#e0f2fe", "#7dd3fc", "#38bdf8", "#0284c7", "#475569", true)
	toggle("TabGreen", "#dcfce7", "#86efac", "#22c55e", "#15803d", "#475569", true)
	toggle("TabOrange", "#ffedd5", "#fdba74", "#f97316", "#c2410c", "#475569", true)
	toggle("TabPurple", "#f3e8ff", "#d8b4fe", "#a855f7", "#7e22ce", "#475569", true)

	# Paneller.
	panel("FloatingPill", floating(flat("#fffdf7", "#e2e8f0", 4, 36, 12, 10)))
	panel("BananaChip", flat("#fffbeb", "#f59e0b", 0, 24, 14, 6, 3))
	panel("XpChip", flat("#f0fdf4", "#22c55e", 0, 24, 14, 6, 3))
	panel("HabitCard", flat("#ffffff", "#cbd5e1", 4, 16, 16, 14))
	panel("HabitCardDone", flat("#dcfce7", "#86efac", 4, 16, 16, 14))
	panel("StreakBadge", flat("#ffedd5", "#fdba74", 0, 14, 12, 3))
	panel("TimerBubble", floating(flat("#ffffff", "#bae6fd", 8, 56, 24, 28)))
	panel("ShopBox", floating(flat("#fff7ed", "#fb923c", 10, 32, 24, 24, 5)))
	panel("IconBubble", flat("#ffffff", "#e2e8f0", 4, 24, 8, 4))
	for entry: Array in [["Sky", "#e0f2fe", "#7dd3fc"], ["Mint", "#dcfce7", "#86efac"], ["Lemon", "#fef9c3", "#fde047"], ["Peach", "#ffedd5", "#fdba74"], ["Lilac", "#f3e8ff", "#d8b4fe"], ["Rose", "#fce7f3", "#f9a8d4"]]:
		panel("Pastel" + entry[0], flat(entry[1], entry[2], 5, 20, 16, 14))
	panel("BadgeEarned", flat("#fef3c7", "#f59e0b", 5, 20, 16, 14))
	panel("BadgeLocked", flat("#f1f5f9", "#cbd5e1", 5, 20, 16, 14))

	# XP çubuğu.
	var track := flat("#dcfce7", Color.TRANSPARENT, 0, 10, 0, 0)
	var fill := flat("#22c55e", Color.TRANSPARENT, 0, 10, 0, 0)
	t.set_stylebox("background", "ProgressBar", track)
	t.set_stylebox("fill", "ProgressBar", fill)

	# Kaydırma çubuğu.
	var grab := flat("#7dd3fc", Color.TRANSPARENT, 0, 6, 5, 5)
	var grab_on := flat("#38bdf8", Color.TRANSPARENT, 0, 6, 5, 5)
	var empty := StyleBoxEmpty.new()
	t.set_stylebox("scroll", "VScrollBar", empty)
	t.set_stylebox("scroll_focus", "VScrollBar", empty)
	t.set_stylebox("grabber", "VScrollBar", grab)
	t.set_stylebox("grabber_highlight", "VScrollBar", grab_on)
	t.set_stylebox("grabber_pressed", "VScrollBar", grab_on)

	# Metin girişi.
	var edit := flat("#f8fafc", "#7dd3fc", 0, 16, 14, 12, 3)
	t.set_stylebox("normal", "LineEdit", edit)
	t.set_stylebox("focus", "LineEdit", StyleBoxEmpty.new())
	t.set_color("font_color", "LineEdit", SLATE)
	t.set_color("font_placeholder_color", "LineEdit", Color("#94a3b8"))
	t.set_color("caret_color", "LineEdit", Color("#0284c7"))
	t.set_color("selection_color", "LineEdit", Color("#bae6fd"))

	# Diyaloglar: gökyüzü mavisi başlık, beyaz gövde.
	var win := StyleBoxFlat.new()
	win.bg_color = WHITE
	win.border_color = Color("#38bdf8")
	win.border_width_top = 44
	win.set_corner_radius_all(24)
	win.corner_detail = 10
	win.expand_margin_left = 12
	win.expand_margin_right = 12
	win.expand_margin_bottom = 12
	win.expand_margin_top = 44
	win.shadow_color = Color(0.12, 0.25, 0.4, 0.3)
	win.shadow_size = 16
	t.set_stylebox("embedded_border", "Window", win)
	t.set_stylebox("embedded_unfocused_border", "Window", win)
	t.set_color("title_color", "Window", WHITE)
	t.set_constant("title_height", "Window", 44)
	var dialog_panel := StyleBoxFlat.new()
	dialog_panel.bg_color = WHITE
	dialog_panel.set_content_margin_all(12)
	t.set_stylebox("panel", "AcceptDialog", dialog_panel)
	t.set_color("title_color", "AcceptDialog", WHITE)

	var err := ResourceSaver.save(t, OUT)
	print("saved ", err)
	quit(err)
