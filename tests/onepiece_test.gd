# Çalıştırma (gerçek kaydı ezmemesi için HOME geçici dizine yönlendirilir):
#   HOME=$(mktemp -d) godot --headless --path . --script res://tests/onepiece_test.gd
extends SceneTree

const MAIN_SCENE := "res://scenes/main.tscn"
const SONIC_MONKEY := preload("res://scripts/sonic_monkey.gd")
const CREW_MONKEY := preload("res://scripts/crew_monkey.gd")
const CREW_PRICES := {"zoro": 100, "sanji": 100, "chopper": 90, "gear5": 250, "nami": 90, "usopp": 85, "robin": 110, "franky": 115, "brook": 95, "jinbe": 120}
const FULL_CREW: Array[String] = ["nami", "usopp", "robin", "franky", "brook", "jinbe"]
const LEGACY_VARIANTS: Array[String] = ["knuckles", "tails", "shadow", "super"]
const DECOR_ICONS := {"meat": "🍖", "jolly_roger": "🏴‍☠", "gomu_fruit": "🍈", "chest": "📦"}
const BUBBLES := {"monkey": "🍖!", "zoro": "⚔!", "sanji": "🔥!", "chopper": "🦌!", "gear5": "⚡!", "nami": "🍊!", "usopp": "🎯!", "robin": "🌸!", "franky": "⭐!", "brook": "🎵!", "jinbe": "🌊!"}
const FLAG_SEQUENCE := "🏴‍☠"

var _failures := 0
var _checks := 0
var _dm: Node
var _sm: Node


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	_dm = root.get_node("DataManager")
	_sm = root.get_node("SoundManager")
	var home := OS.get_environment("HOME")
	if not OS.get_user_data_dir().begins_with(home) or not ("/tmp" in home or "/var/folders" in home):
		printerr("HOME geçici dizin olmalı; gerçek kayıt ezilmesin diye test durduruldu.")
		quit(2)
		return
	_dm.data = _dm._default_data()
	_dm.save_data()
	root.size = Vector2i(720, 1280)

	var main: Control = load(MAIN_SCENE).instantiate()
	root.add_child(main)
	await _frames(3)

	_test_catalog()
	_test_font(main)
	await _test_luffy(main)
	await _test_crew(main)
	await _test_decor(main)
	await _test_merry(main)
	await _test_focus(main)
	await _test_daily(main)

	root.remove_child(main)
	main.free()
	await _frames(2)

	print("SONUÇ: %d kontrol, %d hata" % [_checks, _failures])
	quit(1 if _failures > 0 else 0)


func _test_catalog() -> void:
	for type: String in CREW_PRICES:
		_check(_dm.ISLAND_ITEMS[type].price == CREW_PRICES[type], "%s fiyatı" % type)
		_check(_dm.ISLAND_ITEMS[type].variant == type, "%s varyasyonu" % type)
		_check(CREW_MONKEY.CREW_VARIANTS.has(type), "%s çizimi var" % type)
	for type: String in DECOR_ICONS:
		_check(_dm.ISLAND_ITEMS[type].icon == DECOR_ICONS[type], "%s simgesi" % type)
	for variant: String in LEGACY_VARIANTS:
		_check(SONIC_MONKEY.VARIANTS.has(variant), "%s geriye dönük kalır" % variant)
		_check(_dm.ISLAND_ITEMS.has("monkey_" + variant), "monkey_%s geriye dönük kalır" % variant)
		var legacy: Node2D = CREW_MONKEY.create(variant)
		_check(legacy.get_script() == SONIC_MONKEY and legacy.variant == variant, "%s eski çizimle açılır" % variant)
		legacy.free()
	var fallback: Node2D = CREW_MONKEY.new("yok-boyle-biri")
	_check(CREW_MONKEY.CREW_VARIANTS.has(fallback.variant), "bilinmeyen tayfa üyesi geçerli varyasyona döner")
	fallback.free()


func _test_font(main: Control) -> void:
	for type: String in BUBBLES:
		_check(main.EMOJI_FONT.has_char(BUBBLES[type].unicode_at(0)), "%s balonu gömülü fontta" % type)
	for type: String in FULL_CREW:
		_check(main.EMOJI_FONT.has_char(_dm.ISLAND_ITEMS[type].icon.unicode_at(0)), "%s simgesi gömülü fontta" % type)
	# ZWJ dizisi tek bir bayrağa birleşmezse korsan bayrağı iki ayrı emoji olarak görünür.
	var flag: float = main.EMOJI_FONT.get_string_size(FLAG_SEQUENCE, HORIZONTAL_ALIGNMENT_LEFT, -1, 48).x
	var pirate_flag_parts: float = main.EMOJI_FONT.get_string_size("🏴☠", HORIZONTAL_ALIGNMENT_LEFT, -1, 48).x
	_check(flag > 0.0 and flag < pirate_flag_parts, "korsan bayrağı tek karakter çizilir (%.0f / %.0f)" % [flag, pirate_flag_parts])


func _test_luffy(main: Control) -> void:
	var island := await _open_island(main)
	var item := _item_of_type(island, "monkey")
	var luffy: Node2D = item._monkey
	_check(luffy.get_script() == SONIC_MONKEY and luffy.variant == SONIC_MONKEY.LUFFY_VARIANT, "başlangıç maymunu Luffy")
	for feature: String in ["straw_hat", "scar", "grin", "rubber"]:
		_check(luffy._look.get(feature) == true, "Luffy: %s" % feature)
	_check(luffy._look.shirt == Color("#dc2626") and luffy._look.waist == Color("#2563eb"), "kırmızı yelek, mavi şort")

	var before: Transform2D = luffy._body_transform()
	await _wait(0.2)
	_check(not luffy._body_transform().is_equal_approx(before), "Luffy nefes alır")
	luffy._next_blink = 0.01
	luffy._process(0.02)
	_check(luffy._next_blink >= luffy.BLINK_MIN_GAP, "Luffy göz kırpar")

	await _click(item.global_position)
	await _wait(0.1)
	_check(luffy._hop < 0.0, "Gomu Gomu: yukarı zıplar")
	_check(luffy._action > 0.0, "Gomu Gomu: kollar uzar")
	_check(is_instance_valid(item._bubble) and item._bubble.get_child(1).text == "🍖!", "Korsan Eti balonu")
	await _wait(0.5)
	_check(is_zero_approx(luffy._action), "kollar geri toplanır")
	await _wait(1.3)


func _test_crew(main: Control) -> void:
	var island := await _open_island(main)
	var modal: CanvasLayer = island.get_node("%ShopModal")
	var hairs := {}
	for type: String in CREW_PRICES:
		_check(modal._buy_buttons.has(type), "%s mağazada" % type)
		_dm.data.bananas = CREW_PRICES[type]
		modal._buy(type)
		_check(_dm.data.bananas == 0, "%s satın alınır" % type)
		await _frames(2)
		var item := _item_of_type(island, type)
		_check(item != null and item._monkey.get_script() == CREW_MONKEY, "%s adada çizilir" % type)
		_check(item.get_node("%Emoji").text.is_empty(), "%s emoji kullanmaz" % type)
		hairs[item._monkey._look.quills] = true
		item._monkey.play_bounce()
		await _wait(0.1)
		_check(item._monkey._action > 0.0, "%s dokunma hareketi" % type)
		item._show_bubble()
		_check(item._bubble.get_child(1).text == BUBBLES[type], "%s balonu" % type)
		await _wait(0.5)
		item._bubble.queue_free()
	_check(hairs.size() == CREW_PRICES.size(), "her tayfa üyesinin saçı farklı")

	var sanji: Node2D = _item_of_type(island, "sanji")._monkey
	_check(sanji._front_foot_offset() == Vector2.ZERO, "Sanji dururken yerde")
	sanji._action = 1.0
	_check(sanji._front_foot_offset().y < 0.0, "Sanji tekmede ayağını kaldırır")
	sanji._action = 0.0
	var zoro: Node2D = _item_of_type(island, "zoro")._monkey
	_check(zoro.KATANA_HANDLES.size() == 3, "Zoro'nun üç kılıcı")
	_check(_item_of_type(island, "gear5")._monkey._look.iris == Color("#dc2626"), "Gear 5 kırmızı gözler")
	_check(_item_of_type(island, "gear5")._monkey._look.has("aura"), "Gear 5 aurası")
	await _wait(0.5)
	await _test_full_crew(island)


func _test_full_crew(island: Control) -> void:
	await _wait(CREW_MONKEY.MOVE_SECONDS)
	for type: String in FULL_CREW:
		var item := _item_of_type(island, type)
		var monkey: Node2D = item._monkey
		_check(is_zero_approx(monkey._move_pose()), "%s dinlenirken poz almaz" % type)

		var before: Transform2D = monkey._body_transform()
		await _wait(0.1)
		_check(not monkey._body_transform().is_equal_approx(before), "%s nefes alır" % type)
		monkey._next_blink = 0.01
		monkey._process(0.02)
		_check(monkey._next_blink >= monkey.BLINK_MIN_GAP, "%s göz kırpar" % type)

		# Dokunuş: basıp hemen bırakmak özel hareketi başlatır.
		var rest_arms: Array[Vector2] = monkey._arm_points()
		var start: Vector2 = item.position
		item._on_hit_area_gui_input(_item_press(true))
		item._on_hit_area_gui_input(_item_press(false))
		await _wait(CREW_MONKEY.MOVE_SECONDS * 0.4)
		_check(is_equal_approx(monkey._move_pose(), 1.0), "%s özel hareketin tepesinde" % type)
		_check(monkey._arm_points() != rest_arms, "%s kolları özel poza geçer" % type)
		_check(item._bubble.get_child(1).text == BUBBLES[type], "%s dokunuş balonu" % type)
		await _wait(CREW_MONKEY.MOVE_SECONDS * 0.7)
		_check(is_zero_approx(monkey._move_pose()), "%s hareketi biter" % type)
		_check(monkey._arm_points() == rest_arms, "%s kolları geri döner" % type)

		# Sürükleme: bırakılan yer kayda geçer, dokunma hareketi başlamaz.
		item._on_hit_area_gui_input(_item_press(true))
		var motion := InputEventMouseMotion.new()
		motion.position = Vector2(-20, 0)
		item._on_hit_area_gui_input(motion)
		_check(not item.position.is_equal_approx(start), "%s sürüklenir" % type)
		item._on_hit_area_gui_input(_item_press(false))
		await _wait(0.3)
		var saved: Dictionary = _dm.data.island_items.filter(func(entry: Dictionary) -> bool: return entry.type == type)[0]
		_check(Vector2(saved.x, saved.y).is_equal_approx(item.position), "%s yeni yeri kaydedilir" % type)


func _item_press(pressed: bool) -> InputEventMouseButton:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = pressed
	return event


func _test_decor(main: Control) -> void:
	var island := await _open_island(main)
	var modal: CanvasLayer = island.get_node("%ShopModal")
	for type: String in DECOR_ICONS:
		_dm.data.bananas = _dm.ISLAND_ITEMS[type].price
		modal._buy(type)
		await _frames(2)
		var item := _item_of_type(island, type)
		_check(item.get_node("%Emoji").text == DECOR_ICONS[type], "%s adada görünür" % type)
	_check(_item_of_type(island, "jolly_roger").is_processing(), "bayrak dalgalanır")
	_check(not _item_of_type(island, "meat").is_processing(), "et durur")


func _test_merry(main: Control) -> void:
	var island := await _open_island(main)
	_check(island.has_method("_draw_going_merry") and island.has_method("_draw_sheep_head"), "Going Merry çizilir")
	_check(island.has_method("_draw_jolly_roger"), "yelkende korsan amblemi")
	_check(not island.has_method("_draw_boat"), "eski tekne kalktı")
	_check(island.BARRELS.size() >= 3, "denizde fıçılar")
	var center: Vector2 = island._world.position + island.WORLD_CENTER
	for barrel: Vector3 in island.BARRELS:
		_check(not island._is_inside(Vector2(barrel.x, barrel.y), island.SAND_RADII), "fıçı suda")
		_check(center.x + barrel.x < island.size.x, "fıçı ekranda")
	await _wait(0.1)


func _test_focus(main: Control) -> void:
	await _click(main.get_node("%BottomNav").get_node("%TimerButton").get_global_rect().get_center())
	await _frames(2)
	var timer: Control = main.get_node("%TimerView")
	var title: String = timer.get_node("Margin/Column/Title").text
	_check(title == "Focus With Luffy", "odak başlığı")
	_check(timer.get_node("%SonicMonkey").variant == SONIC_MONKEY.LUFFY_VARIANT, "odakta Luffy")
	_check(timer.get_node("%SonicMonkey").pose == SONIC_MONKEY.Pose.WRITING, "defterine çalışır")
	timer.get_node("%StartButton").pressed.emit()
	await _frames(2)
	_check(timer.get_node("%StatusLabel").text == "Luffy is locked in. Training his Haki on Rusukaina!", "Haki alt yazısı")
	_check(timer.get_node("%FocusScene")._locked_in, "Haki halkaları açılır")
	var stop: BaseButton = timer.get_node("%StopButton")
	_check(stop.visible and stop.caption == "STOP" and stop.fill_color == Color("#dc2626"), "kırmızı STOP")
	_check(timer.get_node("%TimeLabel").get_theme_font_size("font_size") >= 100, "büyük sayaç")
	var status: Label = timer.get_node("%StatusLabel")
	_check(status.get_global_rect().end.x <= root.size.x and status.get_line_count() >= 1, "alt yazı ekrana sığar")
	stop.pressed.emit()
	await _frames(2)
	_check(not timer.get_node("%FocusScene")._locked_in, "STOP ile Haki kapanır")


func _test_daily(main: Control) -> void:
	await _click(main.get_node("%BottomNav").get_node("%HabitsButton").get_global_rect().get_center())
	await _frames(2)
	var view: Control = main.get_node("%HabitsView")
	var card: Control = view.get_node("Margin/Column/DailyQuestCard")
	var title: Label = card.get_node("Column/Heading/Title")
	_check(title.text == "Günün Korsan Görevi: Grand Line'da zafer kazan!", "görev başlığı")
	_check(card.get_node("%RewardLabel").text == "+20 🍖", "görev ödülü")
	_check(card.get_global_rect().end.x <= root.size.x, "görev kartı ekrana sığar")
	var button: BaseButton = view.get_node("%CheckInButton")
	_dm.data.last_check_in_date = ""
	view._update_check_in()
	_check("SET SAIL!" in button.caption and FLAG_SEQUENCE in button.caption and "+15" in button.caption, "SET SAIL düğmesi")
	var bananas: int = _dm.data.bananas
	await _click(button.get_global_rect().get_center())
	_check(_dm.data.bananas == bananas + 15, "SET SAIL ödül verir")
	_check(_sm._players["celebrate"].playing, "zafer sesi")
	_check(button.disabled, "günde bir kez")
	await _wait(0.4)
	await _click(button.get_global_rect().get_center())
	_check(_dm.data.bananas == bananas + 15, "ikinci basış ödül vermez")


func _open_island(main: Control) -> Control:
	await _click(main.get_node("%BottomNav").get_node("%IslandButton").get_global_rect().get_center())
	await _frames(2)
	return main.get_node("%IslandView")


func _item_of_type(island: Control, type: String) -> Node2D:
	for entry: Dictionary in _dm.data.island_items:
		if entry.type == type:
			return island._item_nodes[entry.id]
	return null


func _click(pos: Vector2) -> void:
	_push_button(pos, true)
	await _frames(1)
	_push_button(pos, false)
	await _frames(1)


func _push_button(pos: Vector2, pressed: bool) -> void:
	var event := InputEventMouseButton.new()
	event.position = pos
	event.global_position = pos
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = pressed
	event.button_mask = MOUSE_BUTTON_MASK_LEFT if pressed else 0
	root.push_input(event)


func _frames(count: int) -> void:
	for i: int in count:
		await process_frame


func _wait(seconds: float) -> void:
	await create_timer(seconds).timeout


func _check(condition: bool, label: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
		printerr("HATA: %s" % label)
