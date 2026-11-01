extends PanelContainer

const SOUND_ON_ICON := "🔊"
const SOUND_OFF_ICON := "🔇"

@onready var _bananas_label: Label = %BananasLabel
@onready var _level_label: Label = %LevelLabel
@onready var _xp_bar: ProgressBar = %XpBar
@onready var _xp_label: Label = %XpLabel
@onready var _sound_button: Button = %SoundButton


func _ready() -> void:
	_sound_button.pressed.connect(SoundManager.toggle_mute)
	SoundManager.mute_changed.connect(_update_sound_icon.unbind(1))
	_update_sound_icon()
	DataManager.bananas_changed.connect(_on_bananas_changed)
	DataManager.xp_changed.connect(_on_xp_changed)
	# DataManager ilk sinyallerini bu sahne yüklenmeden önce yaydı.
	_on_bananas_changed(DataManager.data.bananas)
	_on_xp_changed(DataManager.data.xp, DataManager.data.level)


func _on_bananas_changed(amount: int) -> void:
	_bananas_label.text = "🍌 %d" % amount


func _on_xp_changed(xp: int, level: int) -> void:
	var xp_to_next_level := level * DataManager.XP_PER_LEVEL
	_level_label.text = "Lv. %d" % level
	_xp_bar.max_value = xp_to_next_level
	_xp_bar.value = xp
	_xp_label.text = "%d/%d XP" % [xp, xp_to_next_level]


func _update_sound_icon() -> void:
	_sound_button.text = SOUND_OFF_ICON if SoundManager.is_muted() else SOUND_ON_ICON
