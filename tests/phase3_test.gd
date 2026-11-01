# Çalıştırma (gerçek kaydı ezmemesi için HOME geçici dizine yönlendirilir):
#   HOME=$(mktemp -d) godot --headless --path . --script res://tests/phase3_test.gd
extends SceneTree

const MAIN_SCENE := "res://scenes/main.tscn"

var _failures := 0
var _checks := 0
var _dm: Node


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	_dm = root.get_node("DataManager")
	var home := OS.get_environment("HOME")
	if not OS.get_user_data_dir().begins_with(home) or not ("/tmp" in home or "/var/folders" in home):
		printerr("HOME geçici dizin olmalı; gerçek kayıt ezilmesin diye test durduruldu.")
		quit(2)
		return
	_dm.data = _dm._default_data()
	_dm.save_data()

	# Headless pencere 64x64 açılır; olaylar pencere koordinatıyla gönderilir.
	root.size = Vector2i(720, 1280)

	var main: Control = load(MAIN_SCENE).instantiate()
	root.add_child(main)
	await _frames(3)

	await _test_starter_gift(main)
	await _test_tabs(main)
	await _test_drag(main)
	await _test_shop(main)
	await _test_stats(main)
	_test_best_streak()
	await _test_scaled_window_drag(main)
	await _test_reload_restores_positions(main)

	print("SONUÇ: %d kontrol, %d hata" % [_checks, _failures])
	quit(1 if _failures > 0 else 0)


func _test_starter_gift(main: Control) -> void:
	var types: Array = _dm.data.island_items.map(func(i: Dictionary) -> String: return i.type)
	_check(types.size() == 2 and "monkey" in types and "palm" in types, "başlangıç hediyesi maymun + palmiye")
	_check(main.get_node("%IslandView")._items.get_child_count() == 2, "hediyeler sahnede")


func _test_tabs(main: Control) -> void:
	var views := {"island": "%IslandView", "habits": "%HabitsView", "timer": "%TimerView", "stats": "%StatsView"}
	var buttons := {"island": "%IslandButton", "habits": "%HabitsButton", "timer": "%TimerButton", "stats": "%StatsButton"}
	var nav: Control = main.get_node("%BottomNav")
	_check(main.get_node("%HabitsView").visible, "varsayılan sekme açık")
	for tab: String in ["island", "stats", "timer", "habits", "stats", "island"]:
		await _click(nav.get_node(buttons[tab]).get_global_rect().get_center())
		for other: String in views:
			_check(main.get_node(views[other]).visible == (other == tab), "tıklama %s -> %s görünürlüğü" % [tab, other])
		_check(main.get_node("%IslandView").is_processing() == (tab == "island"), "dalga animasyonu yalnızca adada: %s" % tab)


func _test_drag(main: Control) -> void:
	var island: Control = main.get_node("%IslandView")
	var entry: Dictionary = _dm.data.island_items[0]
	var item: Node2D = island._item_nodes[entry.id]
	var world_origin: Vector2 = island._world.get_global_rect().position

	# İçeri bırakma; dokunma noktası merkezden kaçık olsa da eşya sıçramamalı.
	var grab_offset := Vector2(10, -8)
	var start: Vector2 = item.global_position + grab_offset
	await _press(start)
	_check(item.z_index > 0, "sürüklerken z_index yükselir")
	await _wait(0.2)
	_check(item.scale.is_equal_approx(Vector2(1.15, 1.15)), "sürüklerken scale 1.15")
	_check(item.position.is_equal_approx(Vector2(entry.x, entry.y)), "basınca eşya sıçramaz")
	var inside := Vector2(200, 300)
	await _move(world_origin + inside + grab_offset)
	_check(item.position.distance_to(inside) < 1.0, "eşya imleci takip eder (%s)" % item.position)
	await _release(world_origin + inside + grab_offset)
	await _wait(0.2)
	_check(item.z_index == 0 and item.scale.is_equal_approx(Vector2.ONE), "bırakınca z_index ve scale döner")
	_check(Vector2(entry.x, entry.y).distance_to(inside) < 1.0, "bırakınca konum kaydedilir")
	_check(item.position.distance_to(inside) < 1.0, "bırakınca konum sabit")

	# Sınır dışına bırakma, her köşe için en yakın güvenli noktaya çekilmeli.
	var cases := {
		Vector2(5, 300): Vector2(80, 300),
		Vector2(700, 300): Vector2(640, 300),
		Vector2(300, 100): Vector2(300, 150),
		Vector2(300, 950): Vector2(300, 850),
		Vector2(10, 60): Vector2(80, 150),
	}
	for outside: Vector2 in cases:
		await _press(item.global_position)
		await _move(world_origin + outside)
		await _release(world_origin + outside)
		await _wait(0.3)
		var expected: Vector2 = cases[outside]
		_check(item.position.distance_to(expected) < 1.0, "%s dışarı -> %s (%s)" % [outside, expected, item.position])
		_check(Vector2(entry.x, entry.y).distance_to(expected) < 1.0, "%s kayıtlı konum güvenli" % outside)
	var saved: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(_dm.SAVE_PATH))
	_check(Vector2(saved.island_items[0].x, saved.island_items[0].y).distance_to(Vector2(80, 150)) < 1.0, "konum dosyaya yazıldı")

	# Ada köşesinden sürüklerken de ölçek konum hesabını bozmamalı.
	await _press(item.global_position)
	await _wait(0.2)
	await _move(world_origin + Vector2(400, 400))
	await _release(world_origin + Vector2(400, 400))
	await _wait(0.2)
	_check(item.position.distance_to(Vector2(400, 400)) < 1.0, "büyütülmüş eşya doğru konumda")

	# Önde duran eşya öne çizilir: y'si büyük olan ağaçta sonda olmalı.
	var other: Dictionary = _dm.data.island_items[1]
	_dm.update_item_position(other.id, Vector2(400, 700))
	var children: Array[Node] = island._items.get_children()
	_check(children[-1] == island._item_nodes[other.id], "y sırası ağaç sırasına yansır")


func _test_shop(main: Control) -> void:
	var island: Control = main.get_node("%IslandView")
	var modal: CanvasLayer = island.get_node("%ShopModal")
	_check(not modal.visible, "mağaza başta kapalı")
	await _click(island.get_node("%ShopButton").get_global_rect().get_center())
	_check(modal.visible, "mağaza butonu açar")

	_check(_dm.data.bananas == 50, "başlangıç 50 muz")
	_check(modal._buy_buttons.size() == 18, "18 ürün")
	for type: String in ["palm", "campfire", "tent", "flower"]:
		_check(not modal._buy_buttons[type].disabled, "%s alınabilir" % type)
	for type: String in ["chest", "ship", "monkey", "monkey_knuckles", "monkey_tails", "monkey_shadow", "monkey_super"]:
		_check(modal._buy_buttons[type].disabled and modal._buy_buttons[type].text == "Yetersiz Muz", "%s yetersiz" % type)

	# Açık modal alttaki sekmeyi engellemeli.
	var nav_point: Vector2 = main.get_node("%BottomNav").get_node("%HabitsButton").get_global_rect().get_center()
	var nav_panel_rect: Rect2 = modal.get_node("Dim/Center/Panel").get_global_rect()
	await _click(nav_point)
	_check(island.visible, "modal açıkken sekme tıklanamaz (panel: %s)" % nav_panel_rect)
	if not modal.visible:
		await _click(island.get_node("%ShopButton").get_global_rect().get_center())

	# Parasız satın alma reddedilir.
	var before: int = _dm.data.island_items.size()
	var chest_button: Button = modal._buy_buttons["chest"]
	await _click(chest_button.get_global_rect().get_center())
	_check(_dm.data.bananas == 50 and _dm.data.island_items.size() == before, "yetersiz muzla satın alınamaz")
	modal._buy("chest")
	_check(_dm.data.bananas == 50 and _dm.data.island_items.size() == before, "doğrudan çağrı da reddedilir")

	if not modal.visible:
		modal.open()
	await _frames(2)
	await _click(modal._buy_buttons["palm"].get_global_rect().get_center())
	_check(_dm.data.bananas == 30, "palmiye 20 muz düşer")
	_check(_dm.data.island_items.size() == before + 1, "eşya eklendi")
	_check(not modal.visible, "satın alınca kapanır")
	var added: Dictionary = _dm.data.island_items[-1]
	_check(added.type == "palm" and island._item_nodes.has(added.id), "island_updated ile anında sahnede")
	_check(_dm.ISLAND_BOUNDS.grow(0.01).has_point(Vector2(added.x, added.y)), "ada içinde")
	await _wait(0.4)
	_check(island._item_nodes[added.id].scale.is_equal_approx(Vector2.ONE), "pop animasyonu biter")

	# Boş alan: mevcut eşyalardan uzak ve merkeze yakın.
	var spot: Vector2 = _dm.find_free_island_spot()
	_check(_dm._distance_to_nearest_item(spot) >= _dm.FREE_SPOT_MIN_DISTANCE, "boş nokta çakışmaz")
	_check(spot.distance_to(_dm.ISLAND_BOUNDS.get_center()) <= _dm.FREE_SPOT_MAX_RADIUS, "boş nokta merkeze yakın")

	# Ada tamamen dolsa da nokta üretilir ve sınır dışına çıkmaz.
	var saved_items: Array = _dm.data.island_items
	_dm.data.island_items = []
	for i: int in 400:
		_dm.data.island_items.append({"id": "x%d" % i, "type": "palm", "x": 80.0 + i % 20 * 29.0, "y": 150.0 + i / 20 * 36.0})
	_check(_dm.ISLAND_BOUNDS.grow(0.01).has_point(_dm.find_free_island_spot()), "dolu adada da geçerli nokta")
	_dm.data.island_items = saved_items

	# Tüm kataloğun fiyatları.
	var prices := {"palm": 20, "campfire": 30, "tent": 40, "flower": 15, "chest": 60, "ship": 100, "monkey": 80, "monkey_knuckles": 100, "monkey_tails": 90, "monkey_shadow": 140, "monkey_super": 250}
	for type: String in prices:
		_check(_dm.ISLAND_ITEMS[type].price == prices[type], "%s fiyatı" % type)

	# Karartmaya tıklayınca kapanır.
	modal.open()
	await _frames(2)
	await _click(Vector2(5, 5))
	_check(not modal.visible, "karartmaya tıklayınca kapanır")


func _test_stats(main: Control) -> void:
	var view: Control = main.get_node("%StatsView")
	await _click(main.get_node("%BottomNav").get_node("%StatsButton").get_global_rect().get_center())

	_dm.record_focus_session(90)
	await _frames(2)
	var text := _all_text(view)
	_check("1 sa 30 dk" in text, "odak süresi sekme açıkken anında güncellenir")
	_check(("%d" % _dm.data.bananas) in text, "muz bakiyesi")
	_check("Seviye 1" in text, "seviye (90 XP)")

	_dm.add_xp(250)
	await _frames(2)
	text = _all_text(view)
	_check(_dm.get_total_xp() == 340, "toplam XP seviye atlayınca korunur (%d)" % _dm.get_total_xp())
	_check("Seviye 3" in text and "Toplam: 340 XP" in text, "seviye ve toplam XP ekranda")

	var habit_id: String = _dm.add_habit("Test")
	_dm.toggle_habit(habit_id)
	await _frames(2)
	text = _all_text(view)
	_check("1 gün" in text and "Kazanıldı" in text, "seri ve rozet")
	_dm.delete_habit(habit_id)

	# Gizliyken güncellenen veri sekme açılınca görünür.
	await _click(main.get_node("%BottomNav").get_node("%HabitsButton").get_global_rect().get_center())
	_dm.record_focus_session(30)
	await _click(main.get_node("%BottomNav").get_node("%StatsButton").get_global_rect().get_center())
	await _frames(2)
	_check("2 sa 0 dk" in _all_text(view), "gizliyken değişen veri sekme açılınca güncel")


func _test_best_streak() -> void:
	_dm.data.stats.best_streak = 0
	_dm.data.habits = []
	var a: String = _dm.add_habit("A")
	_dm.toggle_habit(a)
	_check(_dm.data.stats.best_streak == 1, "rekor 1")
	_dm.toggle_habit(a)
	_check(_dm.data.stats.best_streak == 0, "geri alma rekoru geri alır")
	_dm.toggle_habit(a)
	var kept: Dictionary = _dm.data.duplicate(true)
	_dm.delete_habit(a)
	_check(_dm.data.stats.best_streak == 1, "alışkanlık silinse de rekor kalır")

	var migrated: Dictionary = _dm._sanitized({"habits": [{"id": "h", "streak": 6.0}], "stats": {}})
	_check(migrated.stats.best_streak == 6, "eski kayıt mevcut seriden rekor alır")
	_check(_dm._sanitized(kept).stats.best_streak == 1, "rekor kayıttan okunur")


# Pencere içeriği ölçeklenince (ör. yüksek çözünürlüklü telefon) konum sapmamalı.
func _test_scaled_window_drag(main: Control) -> void:
	await _click_nav(main, "%IslandButton")
	root.size = Vector2i(1440, 2560)
	await _frames(2)
	var island: Control = main.get_node("%IslandView")
	var item: Node2D = island._item_nodes[_dm.data.island_items[0].id]
	var factor: Vector2 = root.get_final_transform().get_scale()
	_check(factor.is_equal_approx(Vector2(2, 2)), "pencere 2x ölçekli (%s)" % factor)
	var world_origin: Vector2 = island._world.get_global_rect().position
	var target := Vector2(250, 350)
	await _press(item.global_position * factor)
	await _move((world_origin + target) * factor)
	await _release((world_origin + target) * factor)
	await _wait(0.2)
	_check(item.position.distance_to(target) < 1.0, "2x pencerede sürükleme doğru (%s)" % item.position)
	root.size = Vector2i(720, 1280)
	await _frames(2)


func _click_nav(main: Control, button: String) -> void:
	await _click(main.get_node("%BottomNav").get_node(button).get_global_rect().get_center())


func _test_reload_restores_positions(main: Control) -> void:
	var expected := {}
	for item: Dictionary in _dm.data.island_items:
		expected[item.id] = Vector2(item.x, item.y)
	_dm.save_data()

	root.remove_child(main)
	main.free()
	_dm.load_data()
	var fresh: Control = load(MAIN_SCENE).instantiate()
	root.add_child(fresh)
	await _frames(2)
	var island: Control = fresh.get_node("%IslandView")
	_check(island._item_nodes.size() == expected.size(), "yeniden açılışta eşya sayısı (hediye eklenmez)")
	for id: String in expected:
		_check(island._item_nodes[id].position.is_equal_approx(expected[id]), "%s kayıtlı konumda" % id)

	# Bozuk koordinat ulaşılamayacak yere koymaz.
	_dm.place_island_item("palm", Vector2(-5000, 9000))
	var bad: Dictionary = _dm.data.island_items[-1]
	_check(_dm.ISLAND_BOUNDS.grow(0.01).has_point(island._item_nodes[bad.id].position), "bozuk koordinat adaya çekilir")
	root.remove_child(fresh)
	fresh.free()


func _all_text(node: Node) -> String:
	var text := ""
	if node is Label:
		text = node.text + "\n"
	for child: Node in node.get_children():
		text += _all_text(child)
	return text


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
