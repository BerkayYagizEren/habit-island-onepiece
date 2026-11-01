extends PanelContainer

@onready var _habits_label: Label = %HabitsLabel
@onready var _focus_label: Label = %FocusLabel
@onready var _bananas_label: Label = %BananasLabel


func _ready() -> void:
	DataManager.today_updated.connect(_refresh)
	DataManager.habits_updated.connect(_refresh)
	_refresh()


func _refresh() -> void:
	var stats: Dictionary = DataManager.data.today_stats
	_habits_label.text = "%d/%d habits" % [stats.habits_completed, DataManager.data.habits.size()]
	_focus_label.text = "⏱ %dm focused" % stats.focus_minutes
	_bananas_label.text = "🍌 %d acquired" % stats.bananas_earned
