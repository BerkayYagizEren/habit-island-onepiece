extends PanelContainer

signal tab_selected(tab_name: String)

@onready var _buttons: Dictionary[String, Button] = {
	"island": %IslandButton,
	"habits": %HabitsButton,
	"timer": %TimerButton,
	"stats": %StatsButton,
}


func _ready() -> void:
	for tab_name: String in _buttons:
		_buttons[tab_name].pressed.connect(tab_selected.emit.bind(tab_name))
		_buttons[tab_name].pressed.connect(SoundManager.play_click)


func select_tab(tab_name: String) -> void:
	_buttons[tab_name].button_pressed = true
	tab_selected.emit(tab_name)
