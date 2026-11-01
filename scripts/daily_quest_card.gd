extends PanelContainer

const SECONDS_PER_MINUTE := 60
const MINUTES_PER_HOUR := 60

@onready var _quest_label: Label = %QuestLabel
@onready var _countdown_label: Label = %CountdownLabel
@onready var _reward_label: Label = %RewardLabel
@onready var _change_button: Button = %ChangeButton
@onready var _complete_button: Button = %CompleteButton
@onready var _countdown_timer: Timer = %CountdownTimer


func _ready() -> void:
	_change_button.pressed.connect(_on_change_pressed)
	_complete_button.pressed.connect(_on_complete_pressed)
	# Süre gece yarısı dolduğunda görev, uygulama açıkken de yenilensin.
	_countdown_timer.timeout.connect(_on_countdown_tick)
	DataManager.today_updated.connect(_refresh)
	_refresh()


func _on_change_pressed() -> void:
	SoundManager.play_click()
	DataManager.reroll_daily_quest()


func _on_complete_pressed() -> void:
	if DataManager.complete_daily_quest():
		SoundManager.play_complete()
		SoundManager.play_banana()


func _on_countdown_tick() -> void:
	DataManager.check_day_reset()
	_update_countdown()


func _refresh() -> void:
	var quest: Dictionary = DataManager.data.daily_quest
	_quest_label.text = quest.text
	_reward_label.text = "+%d 🍌" % quest.reward
	_change_button.disabled = quest.completed
	_complete_button.disabled = quest.completed
	_complete_button.text = "✅ Tamamlandı" if quest.completed else "Tamamla"
	_update_countdown()


func _update_countdown() -> void:
	# Yukarı yuvarlanır; son dakikada "0h 0m" yazıp görev hâlâ açık görünmesin.
	var minutes := ceili(DataManager.get_daily_quest_seconds_left() / float(SECONDS_PER_MINUTE))
	_countdown_label.text = "⏳ %dh %dm" % [minutes / MINUTES_PER_HOUR, minutes % MINUTES_PER_HOUR]
