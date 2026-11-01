extends Control

# Açık renkli kartlarda parlatma görünmez; altın tonundan beyaza dönülür.
const FLASH_COLOR := Color(1.0, 0.85, 0.35)
const FLASH_SECONDS := 0.4
const COMPLETE_BUTTON_SIZE := Vector2(92, 84)
const DELETE_BUTTON_SIZE := Vector2(68, 68)
const PRIORITY_BUTTON_SIZE := Vector2(48, 48)
const COLOR_DOT := preload("res://scripts/color_dot.gd")
const PRIORITY_COLORS: Dictionary[String, Color] = {
	"high": Color("#ef4444"),
	"medium": Color("#facc15"),
	"low": Color("#f8fafc"),
}
const CHECK_IN_TEXT := "SET SAIL! 🏴‍☠  +%d 🍖"
const CHECKED_IN_TEXT := "SET SAIL! ✅"

var _just_toggled_id := ""
var _pending_delete_id := ""

@onready var _scroll: ScrollContainer = %Scroll
@onready var _list: VBoxContainer = %List
@onready var _empty_label: Label = %EmptyLabel
@onready var _add_dialog: ConfirmationDialog = %AddDialog
@onready var _title_edit: LineEdit = %TitleEdit
@onready var _delete_dialog: ConfirmationDialog = %DeleteDialog
@onready var _notice_dialog: AcceptDialog = %NoticeDialog
@onready var _check_in_button: BaseButton = %CheckInButton


func _ready() -> void:
	%AddButton.pressed.connect(SoundManager.play_click)
	%AddButton.pressed.connect(_on_add_pressed)
	_add_dialog.get_ok_button().theme_type_variation = &"GreenButton"
	_delete_dialog.get_ok_button().theme_type_variation = &"SoftRedButton"
	_notice_dialog.get_ok_button().theme_type_variation = &"SkyButton"
	_add_dialog.confirmed.connect(_on_add_confirmed)
	_add_dialog.register_text_enter(_title_edit)
	_title_edit.text_changed.connect(_update_add_confirm_state)
	_delete_dialog.confirmed.connect(_on_delete_confirmed)
	_check_in_button.pressed.connect(_on_check_in_pressed)
	DataManager.habits_updated.connect(_rebuild_list)
	DataManager.today_updated.connect(_update_check_in)
	_rebuild_list()
	_update_check_in()


func _rebuild_list() -> void:
	for child: Node in _list.get_children():
		_list.remove_child(child)
		child.queue_free()

	var habits: Array = DataManager.data.habits
	_scroll.visible = not habits.is_empty()
	_empty_label.visible = habits.is_empty()

	for habit: Dictionary in habits:
		var card := _create_card(habit)
		_list.add_child(card)
		if habit.id == _just_toggled_id and habit.completed_today:
			card.modulate = FLASH_COLOR
			card.create_tween().tween_property(card, "modulate", Color.WHITE, FLASH_SECONDS)


func _create_card(habit: Dictionary) -> PanelContainer:
	var card := PanelContainer.new()
	card.theme_type_variation = &"HabitCardDone" if habit.completed_today else &"HabitCard"
	# Kartın üzerinden başlayan parmak sürüklemesi listeyi kaydırabilsin.
	card.mouse_filter = Control.MOUSE_FILTER_PASS

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	card.add_child(row)

	var text_column := VBoxContainer.new()
	text_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_column.alignment = BoxContainer.ALIGNMENT_CENTER
	text_column.add_theme_constant_override("separation", 8)
	row.add_child(text_column)

	var title_row := HBoxContainer.new()
	title_row.add_theme_constant_override("separation", 4)
	text_column.add_child(title_row)
	title_row.add_child(_create_priority_button(habit))

	var title := Label.new()
	title.text = habit.title
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.add_theme_font_size_override("font_size", 26)
	title_row.add_child(title)

	var streak_badge := PanelContainer.new()
	streak_badge.theme_type_variation = &"StreakBadge"
	streak_badge.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	streak_badge.mouse_filter = Control.MOUSE_FILTER_PASS
	text_column.add_child(streak_badge)

	var streak := Label.new()
	streak.text = "🔥 %d gün" % habit.streak
	streak.theme_type_variation = &"StreakLabel"
	streak.add_theme_font_size_override("font_size", 20)
	streak_badge.add_child(streak)

	var complete_button := _create_card_button("✅" if habit.completed_today else "⬜", COMPLETE_BUTTON_SIZE)
	complete_button.theme_type_variation = &"MintButton" if habit.completed_today else &"GreenButton"
	complete_button.add_theme_font_size_override("font_size", 36)
	complete_button.pressed.connect(_on_complete_pressed.bind(habit.id))
	row.add_child(complete_button)

	var delete_button := _create_card_button("🗑️", DELETE_BUTTON_SIZE)
	delete_button.theme_type_variation = &"SoftRedButton"
	delete_button.pressed.connect(_on_delete_pressed.bind(habit.id, habit.title))
	row.add_child(delete_button)

	return card


func _create_priority_button(habit: Dictionary) -> Button:
	var button := Button.new()
	button.flat = true
	button.custom_minimum_size = PRIORITY_BUTTON_SIZE
	button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(SoundManager.play_click)
	button.pressed.connect(DataManager.cycle_habit_priority.bind(habit.id))

	var dot := COLOR_DOT.new()
	dot.color = PRIORITY_COLORS[habit.priority]
	dot.set_anchors_preset(Control.PRESET_FULL_RECT)
	dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(dot)
	return button


func _create_card_button(text: String, minimum_size: Vector2) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = minimum_size
	button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	button.focus_mode = Control.FOCUS_NONE
	return button


func _on_complete_pressed(habit_id: String) -> void:
	# Gece yarısı geçtiyse önce sıfırlanır; aksi halde aşağıdaki karşılaştırma
	# yeni günün tamamlanmasını reddedilmiş geri alma sanırdı.
	DataManager.check_day_reset()
	var was_completed := _is_completed(habit_id)

	_just_toggled_id = habit_id
	DataManager.toggle_habit(habit_id)
	_just_toggled_id = ""

	if not was_completed:
		SoundManager.play_complete()
		SoundManager.play_banana()
	elif _is_completed(habit_id):
		_notice_dialog.popup_centered(Vector2i(560, 0))
	else:
		SoundManager.play_click()


func _is_completed(habit_id: String) -> bool:
	for habit: Dictionary in DataManager.data.habits:
		if habit.id == habit_id:
			return habit.completed_today
	return false


func _on_check_in_pressed() -> void:
	if DataManager.check_in_daily():
		SoundManager.play_celebrate()
		_check_in_button.play_pop()


func _update_check_in() -> void:
	var checked_in := DataManager.has_checked_in_today()
	_check_in_button.disabled = checked_in
	_check_in_button.caption = CHECKED_IN_TEXT if checked_in else CHECK_IN_TEXT % DataManager.CHECK_IN_REWARD


func _on_add_pressed() -> void:
	_title_edit.clear()
	_update_add_confirm_state("")
	_add_dialog.popup_centered(Vector2i(560, 0))
	_title_edit.grab_focus()


func _update_add_confirm_state(text: String) -> void:
	_add_dialog.get_ok_button().disabled = text.strip_edges().is_empty()


func _on_add_confirmed() -> void:
	DataManager.add_habit(_title_edit.text)


func _on_delete_pressed(habit_id: String, title: String) -> void:
	SoundManager.play_click()
	_pending_delete_id = habit_id
	_delete_dialog.dialog_text = "\"%s\" ve serisi silinsin mi?" % title
	_delete_dialog.popup_centered(Vector2i(560, 0))


func _on_delete_confirmed() -> void:
	DataManager.delete_habit(_pending_delete_id)
