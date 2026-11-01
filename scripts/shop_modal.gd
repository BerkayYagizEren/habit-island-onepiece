extends CanvasLayer

const CARD_STYLES: Array[StringName] = [&"PastelMint", &"PastelPeach", &"PastelSky", &"PastelRose", &"PastelLemon", &"PastelLilac"]
const CREW_MONKEY := preload("res://scripts/crew_monkey.gd")
const MONKEY_ICON_SIZE := Vector2(64, 72)
const MONKEY_ICON_SCALE := Vector2(0.4, 0.4)
const MONKEY_ICON_OFFSET := Vector2(32, 44)
const BUY_BUTTON_SIZE := Vector2(190, 72)
const BUY_TEXT := "Satın Al"
const INSUFFICIENT_TEXT := "Yetersiz Muz"
const RECRUITED_TEXT := "Tayfada ✓"
const EXPAND_TEXT := "Genişlet"
const EXPAND_TITLE := "🏝️ Ada Genişletme"
const EXPAND_LEVEL_TEXT := "Ada Seviyesi: %d/%d"
const EXPAND_MAX_TEXT := "Maksimum Seviye 🏆"

var _buy_buttons: Dictionary[String, Button] = {}
var _expand_level_label: Label
var _expand_price_label: Label
var _expand_button: Button

@onready var _dim: ColorRect = %Dim
@onready var _list: VBoxContainer = %List
@onready var _balance_label: Label = %BalanceLabel


func _ready() -> void:
	%CloseButton.pressed.connect(SoundManager.play_click)
	%CloseButton.pressed.connect(close)
	_dim.gui_input.connect(_on_dim_gui_input)
	_list.add_child(_create_expansion_card())
	for item_type: String in DataManager.ISLAND_ITEMS:
		var style: StringName = CARD_STYLES[_list.get_child_count() % CARD_STYLES.size()]
		_list.add_child(_create_card(item_type, DataManager.ISLAND_ITEMS[item_type], style))
	# Sayaç mağaza açıkken bitip muz kazandırabilir.
	DataManager.bananas_changed.connect(_refresh_affordability)
	# Başlangıç hediyeleri ve satın alınan korsanlar buradan yansır.
	DataManager.island_updated.connect(_on_island_updated)
	_refresh_affordability(DataManager.data.bananas)


func open() -> void:
	visible = true


func close() -> void:
	visible = false


func _create_expansion_card() -> PanelContainer:
	var card := PanelContainer.new()
	card.theme_type_variation = &"PastelSky"
	card.mouse_filter = Control.MOUSE_FILTER_PASS

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	card.add_child(column)

	var title := Label.new()
	title.text = EXPAND_TITLE
	title.theme_type_variation = &"HeadingLabel"
	title.add_theme_font_size_override("font_size", 32)
	column.add_child(title)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	column.add_child(row)

	var text_column := VBoxContainer.new()
	text_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_column.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(text_column)

	_expand_level_label = Label.new()
	_expand_level_label.add_theme_font_size_override("font_size", 24)
	text_column.add_child(_expand_level_label)

	_expand_price_label = Label.new()
	_expand_price_label.theme_type_variation = &"PriceLabel"
	_expand_price_label.add_theme_font_size_override("font_size", 26)
	text_column.add_child(_expand_price_label)

	_expand_button = Button.new()
	_expand_button.custom_minimum_size = BUY_BUTTON_SIZE
	_expand_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_expand_button.focus_mode = Control.FOCUS_NONE
	_expand_button.theme_type_variation = &"GoldButton"
	_expand_button.pressed.connect(_expand)
	row.add_child(_expand_button)

	return card


func _create_card(item_type: String, item: Dictionary, style: StringName) -> PanelContainer:
	var card := PanelContainer.new()
	card.theme_type_variation = style
	# Kartın üzerinden başlayan parmak sürüklemesi listeyi kaydırabilsin.
	card.mouse_filter = Control.MOUSE_FILTER_PASS

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	card.add_child(row)

	var icon_bubble := PanelContainer.new()
	icon_bubble.theme_type_variation = &"IconBubble"
	icon_bubble.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icon_bubble.mouse_filter = Control.MOUSE_FILTER_PASS
	row.add_child(icon_bubble)

	icon_bubble.add_child(_create_monkey_icon(item.variant) if item.has("variant") else _create_emoji_icon(item.icon))

	var text_column := VBoxContainer.new()
	text_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_column.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(text_column)

	var title := Label.new()
	title.text = item.name
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.add_theme_font_size_override("font_size", 24)
	text_column.add_child(title)

	var price := Label.new()
	price.text = "🍌 %d" % item.price
	price.theme_type_variation = &"PriceLabel"
	price.add_theme_font_size_override("font_size", 22)
	text_column.add_child(price)

	var buy_button := Button.new()
	buy_button.custom_minimum_size = BUY_BUTTON_SIZE
	buy_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	buy_button.focus_mode = Control.FOCUS_NONE
	buy_button.theme_type_variation = &"GoldButton"
	buy_button.pressed.connect(_buy.bind(item_type))
	row.add_child(buy_button)
	_buy_buttons[item_type] = buy_button

	return card


func _create_emoji_icon(emoji: String) -> Label:
	var icon := Label.new()
	icon.text = emoji
	icon.add_theme_font_size_override("font_size", 52)
	return icon


func _create_monkey_icon(variant: String) -> Control:
	var holder := Control.new()
	holder.custom_minimum_size = MONKEY_ICON_SIZE
	holder.mouse_filter = Control.MOUSE_FILTER_PASS
	var monkey: Node2D = CREW_MONKEY.create(variant)
	monkey.position = MONKEY_ICON_OFFSET
	monkey.scale = MONKEY_ICON_SCALE
	holder.add_child(monkey)
	holder.gui_input.connect(_on_monkey_icon_gui_input.bind(monkey))
	return holder


func _refresh_affordability(bananas: int) -> void:
	_balance_label.text = "🍌 %d" % bananas
	for item_type: String in _buy_buttons:
		if _is_recruited(item_type):
			_buy_buttons[item_type].disabled = true
			_buy_buttons[item_type].text = RECRUITED_TEXT
			continue
		var can_afford: bool = bananas >= DataManager.ISLAND_ITEMS[item_type].price
		_buy_buttons[item_type].disabled = not can_afford
		_buy_buttons[item_type].text = BUY_TEXT if can_afford else INSUFFICIENT_TEXT
	_refresh_expansion()


# Korsanlar benzersizdir; dekorlar sınırsız alınır.
func _is_recruited(item_type: String) -> bool:
	return DataManager.ISLAND_ITEMS[item_type].has("variant") and DataManager.has_island_item(item_type)


func _on_island_updated() -> void:
	_refresh_affordability(DataManager.data.bananas)


func _refresh_expansion() -> void:
	var cost := DataManager.get_next_expansion_cost()
	var maxed := cost < 0
	_expand_level_label.text = EXPAND_LEVEL_TEXT % [DataManager.data.island_level, DataManager.MAX_ISLAND_LEVEL]
	_expand_price_label.text = EXPAND_MAX_TEXT if maxed else "🍌 %d" % cost
	_expand_button.visible = not maxed
	if not maxed:
		var can_afford: bool = DataManager.data.bananas >= cost
		_expand_button.disabled = not can_afford
		_expand_button.text = EXPAND_TEXT if can_afford else INSUFFICIENT_TEXT


func _buy(item_type: String) -> void:
	if _is_recruited(item_type):
		return
	if not DataManager.spend_bananas(DataManager.ISLAND_ITEMS[item_type].price):
		return
	SoundManager.play_banana()
	DataManager.place_island_item(item_type, DataManager.find_free_island_spot())
	close()


# Ses ve animasyon adadadır; mağaza kapanır ki genişleme görülsün.
func _expand() -> void:
	if DataManager.expand_island():
		close()


func _on_monkey_icon_gui_input(event: InputEvent, monkey: Node2D) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		SoundManager.play_pop()
		monkey.play_bounce()


func _on_dim_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		close()
