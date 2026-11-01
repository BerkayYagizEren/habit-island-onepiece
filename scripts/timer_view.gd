extends Control

const DEFAULT_MINUTES := 25
const SECONDS_PER_MINUTE := 60
const SOUND_ON_ICON := "🔊"
const SOUND_OFF_ICON := "🔇"
const LOCKED_IN_TEXT := "Luffy is locked in. Training his Haki on Rusukaina!"
const READY_TEXT := "Luffy is ready to train."

var _selected_minutes := DEFAULT_MINUTES
var _remaining_seconds := DEFAULT_MINUTES * SECONDS_PER_MINUTE
var _end_unix_time := 0.0

@onready var _time_label: Label = %TimeLabel
@onready var _status_label: Label = %StatusLabel
@onready var _tick_timer: Timer = %TickTimer
@onready var _start_button: Button = %StartButton
@onready var _stop_button: BaseButton = %StopButton
@onready var _sound_button: Button = %FocusSoundButton
@onready var _presets: Control = %Presets
@onready var _focus_scene: Control = %FocusScene
@onready var _stage: Control = %Stage
@onready var _completed_dialog: AcceptDialog = %CompletedDialog
@onready var _preset_buttons: Dictionary[int, Button] = {
	15: %Preset15Button,
	25: %Preset25Button,
	45: %Preset45Button,
	60: %Preset60Button,
}


func _ready() -> void:
	for minutes: int in _preset_buttons:
		_preset_buttons[minutes].pressed.connect(_select_minutes.bind(minutes))
		_preset_buttons[minutes].pressed.connect(SoundManager.play_click)
	_preset_buttons[DEFAULT_MINUTES].button_pressed = true
	_start_button.pressed.connect(_start)
	_stop_button.pressed.connect(_reset)
	for button: BaseButton in [_start_button, _stop_button]:
		button.pressed.connect(SoundManager.play_click)
	_sound_button.pressed.connect(SoundManager.toggle_mute)
	SoundManager.mute_changed.connect(_update_sound_icon.unbind(1))
	_tick_timer.timeout.connect(_on_tick)
	_stage.resized.connect(_sync_stage)
	_completed_dialog.get_ok_button().theme_type_variation = &"GreenButton"
	_sync_stage()
	_update_sound_icon()
	_update_display()


func _exit_tree() -> void:
	DisplayServer.screen_set_keep_on(false)


func _select_minutes(minutes: int) -> void:
	_selected_minutes = minutes
	_reset()


func _start() -> void:
	_end_unix_time = Time.get_unix_time_from_system() + _remaining_seconds
	_tick_timer.start()
	DisplayServer.screen_set_keep_on(true)
	_update_display()


func _reset() -> void:
	_tick_timer.stop()
	DisplayServer.screen_set_keep_on(false)
	_remaining_seconds = _selected_minutes * SECONDS_PER_MINUTE
	_update_display()


func _on_tick() -> void:
	# Timer uygulama arka plandayken işlemez; kalan süre saatten hesaplanınca
	# telefon kilitlenip açıldığında sayaç geride kalmaz.
	var remaining := roundi(_end_unix_time - Time.get_unix_time_from_system())
	_remaining_seconds = clampi(remaining, 0, _remaining_seconds)
	if _remaining_seconds == 0:
		_finish_session()
	else:
		_update_display()


func _finish_session() -> void:
	var minutes := _selected_minutes
	_reset()
	DataManager.record_focus_session(minutes)
	SoundManager.play_timer_finish()
	_completed_dialog.dialog_text = "Tebrikler! %d dakika odaklandın! 🍌 +%d Muz, +%d XP kazandın!" % [minutes, minutes, minutes]
	_completed_dialog.popup_centered(Vector2i(560, 0))


func _update_display() -> void:
	_time_label.text = "%02d:%02d" % [_remaining_seconds / SECONDS_PER_MINUTE, _remaining_seconds % SECONDS_PER_MINUTE]

	var is_running := not _tick_timer.is_stopped()
	_status_label.text = LOCKED_IN_TEXT if is_running else READY_TEXT
	_start_button.visible = not is_running
	_stop_button.visible = is_running
	# Oturum sürerken süre değişirse ödül, odaklanılan süreyle uyuşmaz.
	_presets.visible = not is_running
	_focus_scene.set_locked_in(is_running)


func _sync_stage() -> void:
	_focus_scene.stage_rect = Rect2(_stage.get_global_position() - get_global_position(), _stage.size)


func _update_sound_icon() -> void:
	_sound_button.text = SOUND_OFF_ICON if SoundManager.is_muted() else SOUND_ON_ICON
