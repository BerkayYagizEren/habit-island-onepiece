# Çalıştırma (gerçek kaydı ezmemesi için HOME geçici dizine yönlendirilir):
#   HOME=$(mktemp -d) godot --headless --path . --script res://tests/phase7_test.gd
extends SceneTree

const MAIN_SCENE := "res://scenes/main.tscn"
const SONIC_MONKEY := preload("res://scripts/sonic_monkey.gd")
const MONKEY_PRICES := {"monkey": 80, "monkey_knuckles": 100, "monkey_tails": 90, "monkey_shadow": 140, "monkey_super": 250}
const MONKEY_VARIANTS := {"monkey": "sonic", "monkey_knuckles": "knuckles", "monkey_tails": "tails", "monkey_shadow": "shadow", "monkey_super": "super"}

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

	_test_data()
	_test_sanitize()
	_dm.data = _dm._default_data()
	_dm.save_data()

	var main: Control = load(MAIN_SCENE).instantiate()
	root.add_child(main)
	await _frames(3)
	await _click(main.get_node("%BottomNav").get_node("%IslandButton").get_global_rect().get_center())
	await _frames(2)

	var island: Control = main.get_node("%IslandView")
	var modal: CanvasLayer = island.get_node("%ShopModal")
	await _test_variants_in_shop(modal)
	await _test_variants_on_island(island, modal)
	await _test_expansion(island, modal)
	await _test_reload_level(main)

	print("SONUÇ: %d kontrol, %d hata" % [_checks, _failures])
	quit(1 if _failures > 0 else 0)


func _test_data() -> void:
	_check(_dm.data.island_level == 1, "ada 1. seviyede başlar")
	_check(_dm.ISLAND_BOUNDS == Rect2(80, 150, 560, 700), "eski sabit korunur")
	_check(_dm.get_island_bounds() == _dm.ISLAND_BOUNDS, "1. seviye temel boyutta")

	var updates := [0]
	var count_update := func() -> void: updates[0] += 1
	_dm.island_updated.connect(count_update)

	_dm.data.bananas = 199
	_check(not _dm.expand_island(), "199 muzla genişlemez")
	_check(_dm.data.bananas == 199 and _dm.data.island_level == 1 and updates[0] == 0, "reddedilince değişmez")

	var previous: Rect2 = _dm.get_island_bounds()
	var costs := {2: 200, 3: 450, 4: 800}
	for level: int in costs:
		_dm.data.bananas = costs[level] + 7
		_check(_dm.get_next_expansion_cost() == costs[level], "%d. seviye fiyatı" % level)
		_check(_dm.expand_island(), "%d. seviyeye genişler" % level)
		_check(_dm.data.bananas == 7 and _dm.data.island_level == level, "%d. seviye muzu düşer" % level)
		_check(updates[0] == level - 1, "%d. seviye sinyal yayar" % level)
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(_dm.SAVE_PATH))
		_check(int(parsed.island_level) == level, "%d. seviye kaydedilir" % level)

		var bounds: Rect2 = _dm.get_island_bounds()
		var growth := bounds.size.x / previous.size.x
		_check(growth >= 1.18 and growth <= 1.20, "%d. seviye %%18-20 geniş (%s)" % [level, growth])
		_check(bounds.get_center().is_equal_approx(_dm.ISLAND_BOUNDS.get_center()), "ada merkezden büyür")
		previous = bounds

	_dm.data.bananas = 5000
	_check(_dm.get_next_expansion_cost() == -1, "son seviyede fiyat yok")
	_check(not _dm.expand_island() and _dm.data.island_level == 4 and _dm.data.bananas == 5000, "4. seviyeyi geçmez")
	_dm.island_updated.disconnect(count_update)

	var bounds: Rect2 = _dm.get_island_bounds()
	var far_spot := Vector2(bounds.position.x + 2.0, bounds.position.y + 2.0)
	_check(not _dm.ISLAND_BOUNDS.has_point(far_spot), "yeni alan eski sınırın dışında")
	_check(_dm.clamp_to_island(far_spot).is_equal_approx(far_spot), "yeni alana eşya konur")
	_check(_dm.clamp_to_island(Vector2(-9000, 9000)).is_equal_approx(Vector2(bounds.position.x, bounds.end.y)), "sınır dışı yeni sınıra çekilir")
	_check(bounds.grow(0.01).has_point(_dm.find_free_island_spot()), "boş nokta yeni sınırda")


func _test_sanitize() -> void:
	_check(_dm._sanitized({}).island_level == 1, "eski kayıt 1. seviye")
	_check(_dm._sanitized({"island_level": 3.0}).island_level == 3, "seviye okunur")
	_check(_dm._sanitized({"island_level": 99}).island_level == 4, "aşırı seviye kısılır")
	_check(_dm._sanitized({"island_level": -2}).island_level == 1, "negatif seviye kısılır")
	_check(_dm._sanitized({"island_level": "x"}).island_level == 1, "bozuk seviye yok sayılır")


func _test_variants_in_shop(modal: CanvasLayer) -> void:
	for type: String in MONKEY_PRICES:
		_check(_dm.ISLAND_ITEMS[type].price == MONKEY_PRICES[type], "%s fiyatı" % type)
		_check(_dm.ISLAND_ITEMS[type].variant == MONKEY_VARIANTS[type], "%s varyasyonu" % type)
		_check(modal._buy_buttons.has(type), "%s mağazada" % type)

	var monkeys: Array[Node2D] = []
	_collect_monkeys(modal, monkeys)
	var shown := {}
	for monkey: Node2D in monkeys:
		shown[monkey.variant] = monkey
	_check(monkeys.size() == 5 and shown.size() == 5, "mağazada her varyasyon bir kez")

	modal.open()
	await _frames(2)
	for variant: String in shown:
		var monkey: Node2D = shown[variant]
		var time: float = monkey._time
		await _frames(2)
		_check(monkey._time > time, "%s mağazada canlı" % variant)

	# Görünür ilk maymun simgesine dokunmak zıplatır.
	var sonic: Node2D = shown["sonic"]
	var scroll: ScrollContainer = modal.get_node("Dim/Center/Panel/Column/Scroll")
	scroll.ensure_control_visible(sonic.get_parent())
	await _frames(2)
	var saved_bananas: int = _dm.data.bananas
	await _click(sonic.get_parent().get_global_rect().get_center())
	await _wait(0.1)
	_check(sonic._hop < 0.0, "mağazada dokununca zıplar")
	_check(_dm.data.bananas == saved_bananas, "simgeye dokunmak satın almaz")
	await _wait(0.8)
	scroll.scroll_vertical = 0
	await _frames(2)
	modal.close()


func _test_variants_on_island(island: Control, modal: CanvasLayer) -> void:
	for type: String in MONKEY_PRICES:
		if type != "monkey":
			_dm.data.bananas = MONKEY_PRICES[type]
			modal._buy(type)
			_check(_dm.data.bananas == 0, "%s fiyatı düşer" % type)
	await _frames(2)
	_check(not modal.visible, "satın alınca mağaza kapanır")

	var looks := {}
	var quills := {}
	for type: String in MONKEY_PRICES:
		var item := _item_of_type(island, type)
		_check(item != null, "%s adada" % type)
		_check(item.get_node("%Emoji").text.is_empty(), "%s emoji kullanmaz" % type)
		var monkey: Node2D = item._monkey
		_check(monkey.variant == MONKEY_VARIANTS[type], "%s doğru çizilir" % type)
		looks[monkey._look.fur] = true
		quills[monkey._look.quills] = true

		var before: Transform2D = monkey._body_transform()
		await _wait(0.2)
		_check(not monkey._body_transform().is_equal_approx(before), "%s nefes alır" % type)
		monkey._next_blink = 0.01
		monkey._process(0.02)
		_check(monkey._next_blink >= monkey.BLINK_MIN_GAP, "%s göz kırpar" % type)
		monkey.play_bounce()
		await _wait(0.1)
		_check(monkey._hop < 0.0, "%s zıplar" % type)
	_check(looks.size() == 5, "her varyasyonun kürkü farklı")
	_check(quills.size() == 5, "her varyasyonun dikenleri farklı")

	var unknown: Node2D = SONIC_MONKEY.new("yok-boyle-biri")
	_check(unknown.variant == SONIC_MONKEY.DEFAULT_VARIANT, "bilinmeyen varyasyon varsayılana döner")
	unknown.free()
	var plain: Node2D = SONIC_MONKEY.new()
	_check(plain.variant == "sonic", "varsayılan varyasyon sonic")
	plain.free()

	var palette: Dictionary = SONIC_MONKEY.VARIANTS
	_check(palette.tails.quills != palette.sonic.quills and palette.super.iris == Color("#be123c"), "süper maymunun gözü yakut")
	await _wait(0.6)


func _test_expansion(island: Control, modal: CanvasLayer) -> void:
	_dm.data.bananas = 199
	_dm.bananas_changed.emit(199)
	modal.open()
	await _frames(2)
	_check(modal._list.get_child(0).is_ancestor_of(modal._expand_button), "kart en üstte")
	_check(modal._expand_level_label.text == "Ada Seviyesi: 1/4", "seviye yazar")
	_check(modal._expand_price_label.text == "🍌 200", "fiyat yazar")
	_check(modal._expand_button.disabled and modal._expand_button.text == "Yetersiz Muz", "muz yetmezse kapalı")
	await _click(modal._expand_button.get_global_rect().get_center())
	_check(_dm.data.island_level == 1 and modal.visible, "kapalı düğme genişletmez")

	_dm.add_bananas(1)
	await _frames(1)
	_check(not modal._expand_button.disabled and modal._expand_button.text == "Genişlet", "muz yetince açılır")

	var item := _item_of_type(island, "monkey_super")
	var start_scale: float = island._island_scale
	_sm._players["timer_finish"].stop()
	await _click(modal._expand_button.get_global_rect().get_center())
	_check(_dm.data.island_level == 2 and _dm.data.bananas == 0, "düğme genişletir")
	_check(not modal.visible, "genişletince mağaza kapanır")
	_check(_sm._players["timer_finish"].playing, "genişleme sesi çalar")
	_check(island._shake_strength > 0.0, "ada sallanır")
	_check(island._foam_ring_progress < 1.0, "köpük halkası çıkar")
	_check(island._island_scale < _dm.get_island_scale(), "büyüme animasyonlu")
	await _wait(0.3)
	_check(island._island_scale > start_scale, "ada büyümeye başlar")
	await _wait(1.4)
	_check(is_equal_approx(island._island_scale, _dm.get_island_scale()), "büyüme hedefte biter")
	_check(island._shake_strength == 0.0 and island._items.position == Vector2.ZERO, "sallantı biter")
	_check(island._foam_ring_progress >= 1.0, "köpük söner")
	_check(island._pebbles.size() > island.PEBBLE_COUNT, "büyüyen adaya süs eklenir")

	var last_diameter: float = island.SAND_RADII.x * 2.0
	_check_view(island, 2)
	last_diameter = island.scaled_radii(island.SAND_RADII).y * island._view_zoom * 2.0
	_check(last_diameter > island.SAND_RADII.y * 2.0, "2. seviye ekranda daha büyük")

	for level: int in [3, 4]:
		_dm.data.bananas = _dm.get_next_expansion_cost()
		modal.open()
		await _frames(1)
		_check(modal._expand_level_label.text == "Ada Seviyesi: %d/4" % (level - 1), "%d. seviye öncesi yazı" % level)
		_check(modal._expand_price_label.text == "🍌 %d" % _dm.get_next_expansion_cost(), "%d. seviye fiyat yazısı" % level)
		modal._expand()
		await _wait(1.6)
		_check(_dm.data.island_level == level, "%d. seviyeye çıkar" % level)
		var diameter: float = island.scaled_radii(island.SAND_RADII).y * island._view_zoom * 2.0
		_check(diameter > last_diameter, "%d. seviye ekranda daha büyük" % level)
		last_diameter = diameter
		_check_view(island, level)

	modal.open()
	await _frames(1)
	_check(modal._expand_price_label.text == "Maksimum Seviye 🏆", "son seviye yazısı")
	_check(modal._expand_level_label.text == "Ada Seviyesi: 4/4", "son seviye sayısı")
	_check(not modal._expand_button.visible, "son seviyede düğme yok")
	modal.close()
	await _frames(1)

	# Yeni alana taşınan eşya orada kalır ve parmağın altında durur.
	var bounds: Rect2 = _dm.get_island_bounds()
	var world_target := Vector2(bounds.position.x + 10.0, bounds.position.y + 10.0)
	var screen_target: Vector2 = island._world.get_global_transform() * world_target
	await _press(item.get_global_transform().origin)
	await _move(screen_target)
	await _release(screen_target)
	await _wait(0.25)
	_check(item.position.distance_to(world_target) < 2.0, "zoom altında sürükleme parmağı izler (%s)" % item.position)
	var entry := _entry_of_type("monkey_super")
	_check(Vector2(entry.x, entry.y).distance_to(world_target) < 2.0, "yeni alandaki konum kaydedilir")


func _check_view(island: Control, level: int) -> void:
	var bounds: Rect2 = _dm.get_island_bounds()
	var world_to_screen: Transform2D = island._world.get_global_transform()
	var top_left: Vector2 = world_to_screen * bounds.position
	var bottom_right: Vector2 = world_to_screen * bounds.end
	_check(top_left.x >= 0.0 and bottom_right.x <= island.size.x, "%d. seviye eşya alanı ekran genişliğinde" % level)
	_check(top_left.y >= 0.0 and bottom_right.y <= island.size.y, "%d. seviye eşya alanı ekran yüksekliğinde" % level)
	var radii: Vector2 = island.scaled_radii(island.SAND_RADII)
	var half: Vector2 = bounds.size / 2.0
	_check(island._is_inside(half, radii), "%d. seviye sınır köşesi kumsalda" % level)
	var boat_top: Vector2 = island._boat_offset() + Vector2(0, -56) * island._view_zoom
	var center: Vector2 = island._world.position + island.WORLD_CENTER
	_check(not island._is_inside(boat_top, radii * island._view_zoom), "%d. seviye tekne denizde (%s)" % [level, boat_top])
	_check(center.x + island._boat_offset().x > 20.0, "%d. seviye tekne ekranda" % level)
	island._crab_x = island.CRAB_RANGE
	var crab: Vector2 = island._crab_offset() * island._island_scale
	_check(island._is_inside(crab, radii) and not island._is_inside(crab, island.scaled_radii(island.GRASS_RADII)), "%d. seviye yengeç kumsalda" % level)


func _test_reload_level(main: Control) -> void:
	root.remove_child(main)
	main.free()
	_dm.load_data()
	_check(_dm.data.island_level == 4, "seviye yeniden açılışta korunur")
	var fresh: Control = load(MAIN_SCENE).instantiate()
	root.add_child(fresh)
	await _frames(2)
	var island: Control = fresh.get_node("%IslandView")
	_check(is_equal_approx(island._island_scale, _dm.get_island_scale()), "yeniden açılışta ada büyük")
	_check(is_equal_approx(island._view_zoom, island.VIEW_ZOOMS[3]), "yeniden açılışta kamera yerinde")
	_check(island._foam_ring_progress >= 1.0, "yeniden açılışta animasyon oynamaz")
	var entry := _entry_of_type("monkey_super")
	_check(island._item_nodes[entry.id].position.distance_to(Vector2(entry.x, entry.y)) < 0.01, "yeni alandaki eşya kırpılmaz")
	root.remove_child(fresh)
	fresh.free()
	await _frames(2)


func _collect_monkeys(node: Node, into: Array[Node2D]) -> void:
	if node.get_script() == SONIC_MONKEY:
		into.append(node)
	for child: Node in node.get_children():
		_collect_monkeys(child, into)


func _entry_of_type(type: String) -> Dictionary:
	for entry: Dictionary in _dm.data.island_items:
		if entry.type == type:
			return entry
	return {}


func _item_of_type(island: Control, type: String) -> Node2D:
	var entry := _entry_of_type(type)
	return null if entry.is_empty() else island._item_nodes[entry.id]


func _click(pos: Vector2) -> void:
	await _press(pos)
	await _release(pos)


func _press(pos: Vector2) -> void:
	_push_button(pos, true)
	await _frames(1)


func _release(pos: Vector2) -> void:
	_push_button(pos, false)
	await _frames(1)


func _move(pos: Vector2) -> void:
	var event := InputEventMouseMotion.new()
	event.position = pos
	event.global_position = pos
	event.button_mask = MOUSE_BUTTON_MASK_LEFT
	root.push_input(event)
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
