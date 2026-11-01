extends Control

const MINUTES_PER_HOUR := 60

const BADGES: Array[Dictionary] = [
	{"icon": "🌱", "title": "İlk Adım", "stat": "tasks", "target": 1, "unit": "görev"},
	{"icon": "🎯", "title": "Görev Avcısı", "stat": "tasks", "target": 50, "unit": "görev"},
	{"icon": "🔥", "title": "Bir Hafta Seri", "stat": "streak", "target": 7, "unit": "gün"},
	{"icon": "⏳", "title": "Derin Odak", "stat": "focus", "target": 300, "unit": "dakika"},
	{"icon": "🏅", "title": "Usta Kaşif", "stat": "level", "target": 5, "unit": "seviye"},
	{"icon": "🏝️", "title": "Ada Sakini", "stat": "items", "target": 10, "unit": "eşya"},
]

@onready var _list: VBoxContainer = %List


func _ready() -> void:
	DataManager.bananas_changed.connect(_refresh.unbind(1))
	DataManager.xp_changed.connect(_refresh.unbind(2))
	DataManager.habits_updated.connect(_refresh)
	DataManager.island_updated.connect(_refresh)
	visibility_changed.connect(_refresh)
	_refresh()


func _refresh() -> void:
	# Tek işlem birden çok sinyal yaydığı için gizliyken yeniden kurulmaz;
	# sekme açılınca visibility_changed ekranı günceller.
	if not is_visible_in_tree():
		return

	for child: Node in _list.get_children():
		_list.remove_child(child)
		child.queue_free()

	var stats: Dictionary = DataManager.data.stats
	_list.add_child(_create_level_card())
	_list.add_child(_create_stat_card("⏱️", "Toplam Odaklanma", _format_minutes(stats.total_focus_minutes), &"PastelSky"))
	_list.add_child(_create_stat_card("✅", "Tamamlanan Görev", str(stats.habits_completed_total), &"PastelMint"))
	_list.add_child(_create_stat_card("🍌", "Muz Bakiyesi", str(DataManager.data.bananas), &"PastelLemon"))
	_list.add_child(_create_stat_card("🔥", "En Uzun Seri", "%d gün" % stats.best_streak, &"PastelPeach"))

	var badges_title := Label.new()
	badges_title.text = "🎖️ Rozetler"
	badges_title.theme_type_variation = &"HeadingLabel"
	badges_title.add_theme_font_size_override("font_size", 28)
	_list.add_child(badges_title)
	for badge: Dictionary in BADGES:
		_list.add_child(_create_badge_card(badge))


func _create_level_card() -> PanelContainer:
	var level: int = DataManager.data.level
	var xp: int = DataManager.data.xp
	var xp_to_next_level := level * DataManager.XP_PER_LEVEL

	var card := _create_card(&"PastelLilac")
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	card.add_child(column)

	column.add_child(_create_label("🏆 Seviye %d" % level, 32))

	var bar := ProgressBar.new()
	bar.custom_minimum_size = Vector2(0, 20)
	bar.show_percentage = false
	bar.max_value = xp_to_next_level
	bar.value = xp
	bar.mouse_filter = Control.MOUSE_FILTER_PASS
	column.add_child(bar)

	column.add_child(_create_label("Sonraki seviye: %d/%d XP  •  Toplam: %d XP" % [xp, xp_to_next_level, DataManager.get_total_xp()], 20))
	return card


func _create_stat_card(icon: String, title: String, value: String, style: StringName) -> PanelContainer:
	var card := _create_card(style)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	card.add_child(row)

	row.add_child(_create_label(icon, 36))
	var title_label := _create_label(title, 24)
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(title_label)
	row.add_child(_create_label(value, 28))
	return card


func _create_badge_card(badge: Dictionary) -> PanelContainer:
	var progress := _badge_progress(badge.stat)
	var earned: bool = progress >= badge.target
	var card := _create_card(&"BadgeEarned" if earned else &"BadgeLocked")
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	card.add_child(row)

	var icon := _create_label(badge.icon, 36)
	icon.modulate.a = 1.0 if earned else 0.4
	row.add_child(icon)
	var title_label := _create_label(badge.title, 24)
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(title_label)
	var status := "Kazanıldı" if earned else "%d/%d %s" % [progress, badge.target, badge.unit]
	row.add_child(_create_label(status, 20))
	return card


func _badge_progress(stat: String) -> int:
	match stat:
		"tasks":
			return DataManager.data.stats.habits_completed_total
		"streak":
			return DataManager.data.stats.best_streak
		"focus":
			return DataManager.data.stats.total_focus_minutes
		"level":
			return DataManager.data.level
		"items":
			return DataManager.data.island_items.size()
	return 0


func _format_minutes(total_minutes: int) -> String:
	if total_minutes < MINUTES_PER_HOUR:
		return "%d dk" % total_minutes
	return "%d sa %d dk" % [total_minutes / MINUTES_PER_HOUR, total_minutes % MINUTES_PER_HOUR]


func _create_card(style: StringName) -> PanelContainer:
	var card := PanelContainer.new()
	card.theme_type_variation = style
	# Kartın üzerinden başlayan parmak sürüklemesi listeyi kaydırabilsin.
	card.mouse_filter = Control.MOUSE_FILTER_PASS
	return card


func _create_label(text: String, font_size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	return label
