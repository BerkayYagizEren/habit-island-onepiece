extends Control

const DEFAULT_TAB := "habits"
# Android'in sistem emoji fontu Godot'un çizemediği COLRv1 biçiminde olabilir; arayüzdeki
# emojiler bu yüzden CBDT biçiminde gömülür. Kullanıcının yazdığı diğer emojiler sistem
# fontuna düşer. Arayüze yeni emoji eklenirse alt küme yeniden üretilmelidir.
const EMOJI_FONT := preload("res://assets/fonts/NotoColorEmoji-subset.ttf")

@onready var _bottom_nav: PanelContainer = %BottomNav
@onready var _views: Dictionary[String, Control] = {
	"island": %IslandView,
	"habits": %HabitsView,
	"timer": %TimerView,
	"stats": %StatsView,
}


func _enter_tree() -> void:
	ThemeDB.fallback_font.fallbacks = [EMOJI_FONT]


func _ready() -> void:
	_bottom_nav.tab_selected.connect(_on_tab_selected)
	_bottom_nav.select_tab(DEFAULT_TAB)


func _on_tab_selected(tab_name: String) -> void:
	# Görünümler serbest bırakılmaz; sayaç başka sekmedeyken de çalışmaya devam eder.
	for view_name: String in _views:
		_views[view_name].visible = view_name == tab_name
